-- Use the observed Astalor portal position and the real catalogue definitions.
-- Map projections are deterministic fixtures; exact loading times remain estimates.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 2512
fixture.maps[2512] = { mapID = 2512, mapType = 3, parentMapID = 13 }
fixture.maps[2541] = { mapID = 2541, mapType = 5, parentMapID = 2393 }
fixture.maps[2600] = { mapID = 2600, mapType = 5, parentMapID = 2512 }
local usable, open = true, true
PlayerHasToy = function(id) return id == 253629 end
C_QuestLog.IsQuestFlaggedCompleted = function() return open end
C_QuestLog.IsOnQuest = function() return false end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return open end
C_Map.GetWorldPosFromMapPos = function(map, p)
    if map == 2541 then return 999, { x = p.x * 100, y = p.y * 100 } end
    if map == 2393 then return 0, { x = 8016.7 + (p.x - 0.5683) * 1000, y = -4577.6 + (p.y - 0.6738) * 1000 } end
    return 0, { x = p.x * 10000, y = p.y * 10000 }
end
local data = fixture:Load()
data.config.IsolatedAreas[2600] = "test-crypt"
local kept = {}
for _, record in ipairs(data.connections) do
    if record.id == "coiled-isle-to-astalor" or record.id == "arcantina-silvermoon"
        or record.id == "item-253629-to-arcantina" then kept[#kept + 1] = record end
end
assert(#kept == 3, "Exercise the real portal, toy and Arcantina exit records")
data.connections = kept
function APR:GetRouteActionUsability(kind, id) return kind == "item" and id == 253629 and usable end
data.env.getActionCastSeconds = function() return 3 end
local goal = data:NormalizeLocation({ instanceID = 0, uiMapID = 2395, x = 8016.7, y = -4577.6 })
local function Route(distance, map)
    local start = data:NormalizeLocation({ instanceID = 0, uiMapID = map or 2512,
        x = 5949.6 + distance, y = -12070 })
    local edges, metadata = data:BuildEdges({ start = start, playerPosition = start, walkSpeed = 60 })
    local search = data:CreateSearch({ start = start, goal = goal, edges = edges,
        resources = metadata.resources, walkSpeed = 60, walkingIsTransitive = true,
        canWalk = function(a, b) return data:CanWalk(a, b) end,
        walkSpeedFor = function(a, b)
            return math.min(data:GetWalkingSpeed(a, 60, 7), data:GetWalkingSpeed(b, 60, 7))
        end })
    local status, result
    repeat status, result = search:Step(64) until status ~= "planning"
    assert(status == "ready")
    local transports = {}
    for _, segment in ipairs(result.segments) do
        if segment.kind ~= "walk" then transports[#transports + 1] = segment end
    end
    return transports, result
end
local route, result = Route(1)
assert(#route == 1 and route[1].id == "retail:coiled-isle-to-astalor:forward" and result.totalSeconds < 11,
    "A nearby Astalor portal beats the roughly 7,774-yard direct flight")
route = Route(2000)
assert(#route == 2 and route[1].action.data == 253629, "A remote portal loses to the usable personal key")
usable = false
route = Route(2000)
assert(#route == 1 and route[1].kind == "portal", "A toy on cooldown leaves the physical portal eligible")
usable, open = true, false
route = Route(1)
assert(#route == 2 and route[1].action.data == 253629, "A locked physical portal must not suppress an available toy")
open = true
route = Route(1, 2600)
assert(#route == 2 and route[1].action.data == 253629,
    "Matching XY above a crypt does not make its outside portal reachable without an exit")
usable = false
route = Route(1)
assert(#route == 1 and route[1].kind == "portal")
usable, open = false, false
route, result = Route(1)
assert(#route == 0 and result.totalSeconds > 100, "Direct travel remains a fallback only when both shortcuts are unavailable")
print("Coiled Isle: near/far portal, key cooldown, portal unlock, interior isolation and direct fallback passed")
