-- A guide can cross disconnected zones without annotating every world point.
for _, profile in ipairs({ "retail", "forever" }) do
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile = profile
fixture.currentMap = 101
fixture.maps[101] = { mapID = 101, mapType = 3, parentMapID = 13 }
fixture.maps[102] = { mapID = 102, mapType = 3, parentMapID = 13 }
fixture.maps[103] = { mapID = 103, mapType = 4, parentMapID = 13 }
fixture.player = { x = 50, y = 50, instanceID = 7 }
local available, reads = true, 0
C_Map.GetWorldPosFromMapPos = function(map, p)
    return 7, { x = (map == 102 and 1000 or 0) + p.x * 100, y = p.y * 100 }
end
C_Map.GetMapPosFromWorldPos = function(instance, p, hint)
    reads = reads + 1
    if not available or instance ~= 7 then return nil end
    local map = hint or (p.x >= 1000 and 102 or 101)
    return map, { x = (p.x - (map == 102 and 1000 or 0)) / 100, y = p.y / 100 }
end
local data = fixture:Load({ config = { IsolatedContinents = { [13] = true } } })
function APR:NewModule() return {} end
function APR:IsTransportStep() return false end
function APR:GetScenarioStepTarget() end
function APR:GetPlayerParentMapID() return fixture.currentMap end
function APR:GetContinent() return 13 end
function APR:Contains(list, value)
    for _, candidate in ipairs(list) do if candidate == value then return true end end
    return false
end
function APR:GetCurrentRouteMapIDsAndName() return { 101 }, 101 end
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
local step = { Done = { 1 }, Coord = { x = 50, y = 1050 } }
local coord, map = APR:GetStepCoord(step, 101)
assert(coord == step.Coord and map == 102, "World coordinates outside the guide map resolve to their actual zone")
local goal = assert(nav:GetDestination(step))
assert(goal.uiMapID == 102 and goal.x == 1050 and goal.y == 50 and goal.instanceID == 7)
assert(APR:GetStepZoneList(step, 101)[1] == 102, "Zone checks and navigation share the inferred destination")
assert(not data:CanWalk(data:NormalizeLocation({ x = 50, y = 50, instanceID = 7, uiMapID = 101 }), goal),
    "Inferring the target must not allow walking between disconnected islands")
assert(step.Zone == nil and step.Coord.mapID == nil, "Resolution never rewrites the guide")
local before = reads
for _ = 1, 100 do APR:GetStepCoord(step, 101) end
assert(reads == before, "An unchanged objective does not repeat map projections")
fixture.currentMap = 102
assert(select(2, APR:GetStepCoord(step, 101)) == 102, "The target is independent of the player's current zone")
assert(select(2, APR:GetStepCoord({ Coord = step.Coord, Zone = 101 }, 101)) == 101,
    "Explicit step zones remain authoritative even for overlapping or extended coordinates")
assert(select(2, APR:GetStepCoord({ Coord = { x = 50, y = 1050, mapID = 101 } }, 102)) == 101)
assert(select(2, APR:GetStepCoord({ Coord = { x = 50, y = 1050 } }, 103)) == 103,
    "Interior identities cannot be replaced by an overlapping outdoor projection")
assert(select(2, APR:GetStepCoord({ Coord = { x = 50, y = 50 } }, 101)) == 101)
available = false
local pending = { Coord = { x = 60, y = 1060 } }
assert(select(2, APR:GetStepCoord(pending, 101)) == 101, "Missing projection data retains the existing fallback")
available = true
assert(select(2, APR:GetStepCoord(pending, 101)) == 102, "Unavailable data is retried when it becomes readable")
local previousReads = reads
APR.navigationGeometryRevision = 1
assert(select(2, APR:GetStepCoord(pending, 101)) == 102 and reads > previousReads,
    "A geometry revision discards the cached inference")
local project = data.env.worldToMap
data.env.worldToMap = nil
local unsupported = { Coord = { x = 70, y = 1070 } }
assert(select(2, APR:GetStepCoord(unsupported, 101)) == 101, "Clients without projection support keep the fallback")
data.env.worldToMap = project
assert(select(2, APR:GetStepCoord(unsupported, 101)) == 102)
local secret = {}
function issecretvalue(value) return value == secret end
local beforeSecret = reads
assert(select(2, APR:GetStepCoord({ Coord = { x = secret, y = 1050 } }, 101)) == 101 and reads == beforeSecret,
    "Unreadable coordinates never reach native projection APIs")
issecretvalue = nil
step.Coord.y = 50
assert(select(2, APR:GetStepCoord(step, 101)) == 101, "A changed coordinate invalidates its inferred map")
end
print("Implicit destinations: cross-zone guides, explicit boundaries, caching and missing-data recovery passed")
