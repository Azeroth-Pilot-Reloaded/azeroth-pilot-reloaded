-- Reported 2026-10-22 Custom (2) objective, using real catalogue definitions.
-- Native map scales are fitted to Mapzeroth's dumped same-map yard distances
-- (rms < 0.04 yd). Hallowfall is anchored to the report; Azj-Kahet uses binding
-- 14958 near Wildcamp Or'lay's flight master. The latter is an approximate
-- translation, not a captured client map rectangle. Other map translations
-- only align the retained portal landings; same-map walking costs cancel them.
-- This deliberately retains the complete relevant HS chain and four TWW
-- crossings, not unrelated catalogue maps without verified test projections.
-- It reproduces the wrong choice, not the report's exact 95.16348-second sum.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 2215
fixture.player = { x = 2252.6000976562, y = -975.40002441406, instanceID = 2601, uiMapID = 2215 }
fixture.items[6948] = 1
fixture.translations = setmetatable({}, { __index = function(_, key) return key end })
local scales = {
    [2214] = { 2601, 8296.7406946, 5531.9960935, 4119, 808 },
    [2215] = { 2601, 9544.9786983, 6363.3898167, 5342.662095, 5204.01521 },
    [2255] = { 2601, 7913.4190383, 5275.6467669, 1913.001615, 2706.517824 },
    [2339] = { 2552, 2415.0302921, 1610.1306268, 3357.550425, -1403.194100 },
    [2393] = { 0, 3227.1840939, 2151.3518387, 10000, -3000 },
    [85] = { 1, 2000.3091930, 1333.5106467, 2645.904, -3353.208 },
    -- Only its world-space observed bind/portal points enter this test.
    [2512] = { 0, 1000, 1000, 6500, -11500 },
}
fixture.maps[2274] = { mapID = 2274, mapType = 2, parentMapID = 947 }
for _, map in ipairs({ 2214, 2215, 2255 }) do
    fixture.maps[map] = { mapID = map, mapType = 3, parentMapID = 2274 }
end
fixture.maps[2248] = { mapID = 2248, mapType = 3, parentMapID = 2274 }
fixture.maps[2339] = { mapID = 2339, mapType = 3, parentMapID = 2248 }
fixture.maps[85] = { mapID = 85, mapType = 3, parentMapID = 12 }
fixture.maps[2512] = { mapID = 2512, mapType = 3, parentMapID = 13 }
fixture.maps[2213] = { mapID = 2213, mapType = 3, parentMapID = 2255 }
fixture.maps[2256] = { mapID = 2256, mapType = 3, parentMapID = 2274 }
fixture.maps[99001] = { mapID = 99001, mapType = 5, parentMapID = 2255 }
local hearthUsable, coiledOpen, azjOpen = true, true, true
C_QuestLog.IsQuestFlaggedCompleted = function(id)
    if id == 96525 then return coiledOpen end
    if id == 78248 or id == 79573 then return azjOpen end
    return false
end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsOnQuest = function() return false end
C_Map.GetWorldPosFromMapPos = function(map, point)
    local s = scales[map]
    if not s then return nil end
    return s[1], { x = s[4] - point.y * s[3], y = s[5] - point.x * s[2] }
end
C_Map.GetMapPosFromWorldPos = function(instance, point)
    -- Only world-only endpoints of the retained Orgrimmar/Dornogal record
    -- need inference. No unknown world point receives a fictitious region.
    if instance == 1 then return 85, {} end
    if instance == 2552 then return 2339, {} end
end
local data = fixture:Load()
function APR:GetRouteActionUsability(kind, id) return kind == "item" and id == 6948 and hearthUsable end
data.env.getActionCastSeconds = function() return 10 end
local bind = { instanceID = 0, uiMapID = 2512, x = 6098.5200195312, y = -12045.799804688, z = 152.48699951172 }
data.env.getDynamicPosition = function(kind) if kind == "bind" then return bind end end
data.config.IsolatedAreas[99001] = "test-interior"

-- The copied route is not the shipped world tour's Dornogal step 2. Resolve
-- the report itself through actual StepUtils and Navigation:GetDestination.
function APR:NewModule() return {} end
function APR:GetCurrentRouteMapIDsAndName() return { 2339 }, 2339 end
function APR:GetScenarioStepTarget() end
function APR:GetPlayerParentMapID() return fixture.currentMap end
function APR:GetContinent(map)
    return (map == 2214 or map == 2215 or map == 2255 or map == 2339) and 2274 or 13
end
C_Timer = { NewTimer = function() return { Cancel = function() end } end }
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local reported = { Coord = { x = 881.3, y = -805.7 }, Zone = 2255, Range = 20, Waypoint = 1,
    NonSkippableWaypoint = true, ZoneStepTrigger = { x = 881.3, y = -805.7, Range = 20 }, _index = 2 }
local goal, map = APR.navigation:GetDestination(reported)
assert(map == 2255 and goal.uiMapID == 2255 and goal.instanceID == 2601
    and goal.x == -805.7 and goal.y == 881.3,
    "A legacy copied trigger without mapID retains its step zone and APR/lib axis conversion")
goal = assert(data:NormalizeLocation(goal))
local start = assert(data:NormalizeLocation(fixture.player))
assert(start.region == "2601:2274:area:2215" and goal.region == "2601:2274:area:2255")
assert(not data:CanWalk(start, goal), "Nearby cavern coordinates must not invent a direct cross-region edge")

local wanted = {
    ["item-hearthstone-alternatives"] = true,
    ["coiled-isle-to-astalor"] = true,
    ["portal-silvermoon-city-to-orgrimmar"] = true,
    ["portal-kalimdor-to-isle-of-dorn"] = true,
    ["additional-dornogal-azj-kahet"] = true,
    ["passage-ringing-deeps-hallowfall"] = true,
    ["passage-hallowfall-azj-kahet-east"] = true,
    ["passage-ringing-deeps-azj-kahet"] = true,
    ["passage-hallowfall-azj-kahet-west"] = true,
}
local relevant, originalCount = {}, #data.connections
for _, record in ipairs(data.connections) do
    if wanted[record.id] then relevant[#relevant + 1] = record end
end
assert(#relevant == 9 and originalCount > #relevant, "Retain native definitions without recreating their requirements or costs")
local function distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end
local function route(from, to, crossings)
    data.connections = {}
    for _, record in ipairs(relevant) do
        if crossings or record.kind ~= "passage" then data.connections[#data.connections + 1] = record end
    end
    local context = { start = from, playerPosition = from, walkSpeed = 60, walkSpeedFor = function() return 60 end }
    local edges, metadata = data:BuildEdges(context)
    local byID = {}; for _, edge in ipairs(edges) do byID[edge.id] = edge end
    local search = data:CreateSearch({ start = from, goal = to, edges = edges, resources = metadata.resources,
        walkSpeed = 60, walkingIsTransitive = true, canWalk = function(a, b) return data:CanWalk(a, b) end })
    while search:Step(64) == "planning" do end
    local result, actions, total = search:GetResult(), {}, 0
    if not result then return nil, nil, search.status end
    for _, segment in ipairs(result.segments) do
        total = total + segment.seconds
        if segment.kind == "walk" then
            assert(data:CanWalk(segment.from, segment.to), "Every approach/final walk obeys native access regions")
            assert(math.abs(segment.seconds - distance(segment.from, segment.to) / 60) < 0.000001)
        else
            actions[#actions + 1] = segment
            local edge = assert(byID[segment.id], "Every transport leg comes from a real retained catalogue edge")
            assert(segment.mandatory and segment.seconds == edge.seconds)
            if segment.kind == "passage" then
                assert(segment.from.instanceID == segment.to.instanceID)
                assert(math.abs(segment.seconds - math.max(1, distance(segment.from, segment.to) / 60)) < 0.000001,
                    "A physical border pays its entire endpoint-to-endpoint travel time")
            end
        end
    end
    assert(math.abs(total - result.totalSeconds) < 0.000001, "Audit the full itinerary, including every intermediate approach")
    return result, actions, search.status
end

local before, chain = route(start, goal, false)
local expected = { "item-hearthstone-alternatives", "coiled-isle-to-astalor", "portal-silvermoon-city-to-orgrimmar",
    "portal-kalimdor-to-isle-of-dorn", "additional-dornogal-azj-kahet" }
assert(before and #chain == #expected, "The missing physical borders reproduce the complete five-action HS detour")
for index, id in ipairs(expected) do assert(chain[index].id == "retail:" .. id .. ":forward") end
assert(chain[1].action.data == 6948 and chain[1].seconds == 15 and chain[1].to.uiMapID == 2512)
local after, passages = route(start, goal, true)
assert(after and after.totalSeconds < before.totalSeconds and #passages == 1
    and passages[1].id == "retail:passage-hallowfall-azj-kahet-west:forward",
    "The accessible western passage beats the entire HS/Coiled/Silvermoon/Org/Dornogal detour")
assert(after.totalSeconds > distance(start, goal) / 60, "The mandatory entrance is retained rather than drawing a direct line")

local reverse, back = route(goal, start, true)
assert(reverse and #back == 1 and back[1].id == "retail:passage-hallowfall-azj-kahet-west:reverse",
    "The reverse search preserves the same physical hole")
local child = assert(data:NormalizeLocation({ instanceID = 2601, uiMapID = 2213, x = goal.x, y = goal.y }))
local childRoute, childPassages = route(start, child, true)
assert(childRoute and #childPassages == 1, "An ordinary child map inherits its outdoor cavern's entrance")
local lowerFloor = assert(data:NormalizeLocation({ instanceID = 2601, uiMapID = 2256, x = goal.x, y = goal.y }))
assert(select(3, route(start, lowerFloor, true)) == "no_path", "Azj-Kahet's lower map remains a separate cavern region")
local interior = assert(data:NormalizeLocation({ instanceID = 2601, uiMapID = 99001, x = goal.x, y = goal.y }))
assert(select(3, route(start, interior, true)) == "no_path", "An isolated interior never inherits an invented entrance")
local far = assert(data:NormalizeLocation({ instanceID = 2601, uiMapID = 2215, x = start.x + 15000, y = start.y }))
local farRoute, farChain = route(far, goal, true)
assert(farRoute and farChain[1].action and farChain[1].action.data == 6948,
    "Personal travel still wins when the entire accessible passage itinerary is slower")
hearthUsable = false
local cooldown, cooldownPassages = route(far, goal, true)
assert(cooldown and #cooldownPassages == 1 and cooldownPassages[1].kind == "passage", "An unusable HS leaves the physical entrance eligible")
hearthUsable, coiledOpen = true, false
local locked, lockedPassages = route(start, goal, true)
assert(locked and #lockedPassages == 1 and lockedPassages[1].kind == "passage", "The locked Coiled Isle portal cannot authorize its short detour")
coiledOpen, azjOpen = true, false
locked, lockedPassages = route(far, goal, true)
assert(locked and #lockedPassages == 1 and lockedPassages[1].kind == "passage", "Dornogal's Azj-Kahet quest restriction remains required")
print(string.format("Hallowfall report: full HS detour %.2fs; mandatory western passage %.2fs; reverse, child/interior, cooldown and unlocks passed",
    before.totalSeconds, after.totalSeconds))
