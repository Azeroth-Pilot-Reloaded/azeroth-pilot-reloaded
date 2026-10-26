-- Controlled geometry compares complete journeys independently of live portals.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, map in ipairs({ 101, 102, 103 }) do
    fixture.maps[map] = { mapID = map, mapType = 3, parentMapID = 13 }
end
fixture.currentMap, fixture.items[11], fixture.spells[12] = 101, 1, true
local function point(map, x) return { instanceID = 0, uiMapID = map, x = x, y = 0 } end
local unlocked, itemUsable = true, true
C_QuestLog.IsQuestFlaggedCompleted = function() return unlocked end
local data = fixture:Load({ config = { actionLoadingSeconds = 5, IsolatedAreas = { [102] = "goal", [103] = "interior" } },
    connections = {
        { id = "nearby-portal", kind = "portal", from = point(101, 100), to = point(102, 0), requirements = { quest = 1 } },
        { id = "personal-item", kind = "item", from = { dynamic = "player" }, to = point(103, 0), seconds = 8,
            actions = { { type = "item", id = 11 } } },
        { id = "interior-exit", kind = "portal", from = point(103, 0), to = point(102, 0), seconds = 5,
            bidirectional = false },
        { id = "teleport-detour", kind = "spell", from = { dynamic = "player" }, to = point(103, 0), seconds = 20,
            actions = { { type = "spell", id = 12 } } },
    } })
function APR:GetRouteActionUsability(kind, id)
    return kind == "item" and itemUsable and fixture.items[id] ~= nil or kind == "spell" and fixture.spells[id] == true
end
local function route(x, speed)
    local start, goal = data:NormalizeLocation(point(101, x)), data:NormalizeLocation(point(102, 0))
    local edges, meta = data:BuildEdges({ start = start, playerPosition = start, walkSpeed = speed or 10 })
    local job = data:CreateSearch({ start = start, goal = goal, edges = edges, resources = meta.resources,
        walkSpeed = speed or 10, canWalk = function(a, b) return data:CanWalk(a, b) end })
    for _ = 1, 1000 do if job:Step(32) ~= "planning" then return job:GetResult(), job.status end end
    error("Small shortcut graph did not finish")
end
local function transports(result)
    local chain = {}
    for _, step in ipairs(result.segments) do if step.kind ~= "walk" then chain[#chain + 1] = step end end
    return chain
end
local result = assert(route(90))
assert(result.totalSeconds == 6 and #transports(result) == 1,
    "A nearby physical portal wins after charging its approach and loading")
result = assert(route(-1000))
local chain = transports(result)
assert(result.totalSeconds == 13 and #chain == 2 and chain[1].action.data == 11,
    "A remote portal loses to the usable item plus the interior exit")
assert(not data:CanWalk(chain[1].to, chain[2].to), "An interior requires its physical exit")
itemUsable = false
result = assert(route(-1000))
assert(result.totalSeconds == 25 and transports(result)[1].action.data == 12)
fixture.spells[12] = nil
result = assert(route(-1000))
assert(result.totalSeconds == 115 and #transports(result) == 1, "Physical travel survives unusable personal shortcuts")
unlocked = false
assert(select(2, route(90)) == "no_path", "No unlocked or usable connection cannot invent a journey")
unlocked, itemUsable = true, true
-- Changing speed changes the winner, without hardwiring a preferred transport.
assert(assert(route(-1000, 1000)).totalSeconds == 6.1)

-- Same-region long journeys must still compare shortcuts in APR's planner.
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
data.config.IsolatedAreas[102] = nil
data.config.threshold = 500
data:InvalidatePositionCache()
local start, goal = data:NormalizeLocation(point(101, -1000)), data:NormalizeLocation(point(101, 1000))
data.connections = { { id = "same-region-shortcut", kind = "portal", from = point(101, -1000), to = goal, seconds = 5 } }
local preparationCalls, taxiCalls = 0, 0
local function plan(destination)
    local job = APR.NavigationPlanner:Create({ preferZoneAccess = true, data = data, engine = data,
        start = start, playerPosition = start, goal = destination or goal, walkSpeed = 10,
        canWalk = function(a, b) return data:CanWalk(a, b) end, walkingIsTransitive = true,
        adapter = { CreatePreparation = function()
            preparationCalls = preparationCalls + 1
            return { Step = function() return "ready" end }
        end },
        taxiData = { BuildEdges = function() taxiCalls = taxiCalls + 1; return {} end },
        prepareSegment = function(step) return step end })
    for _ = 1, 1000 do if job:Step(128, 1) ~= "planning" then break end end
    assert(job.status == "ready")
    return job
end
local job = plan()
assert(job.status == "ready" and job.result.totalSeconds == 5,
    "A same-region destination cannot bypass the faster available shortcut")
assert(job.zoneFallback and preparationCalls == 1 and taxiCalls == 1)
data.connections[1].disabled = true
assert(plan().result.totalSeconds == 200, "Direct travel remains the fallback when shortcuts are unavailable")
local previousPreparation, previousTaxi = preparationCalls, taxiCalls
assert(plan(data:NormalizeLocation(point(101, start.x + 500))).zoneRouted)
assert(preparationCalls == previousPreparation and taxiCalls == previousTaxi, "The local threshold bypasses all global preparation")
assert(plan(data:NormalizeLocation(point(101, start.x + 501))).zoneFallback)
assert(preparationCalls == previousPreparation + 1 and taxiCalls == previousTaxi + 1)
