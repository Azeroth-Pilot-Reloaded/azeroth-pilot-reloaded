local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local provider = F.provider(lib, F.map({ wall = true }))
local a, b = F.point(1, 1, 0), F.point(6, 1, 0)
local status, result = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 }))
assert(status == "ready" and result.yards > 5 * F.cellSize)
local crossed = false
for _, p in ipairs(result.path) do
    if p.y > 6 * F.cellSize then crossed = true end
end
assert(crossed, "The route must travel through the opening in the invented wall")
local middleX = result.path[2].x
result.path[2].x = -999
local freshStatus, fresh = F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 }))
assert(freshStatus == "ready" and fresh.path[2].x == middleX,
    "Consumer edits to intermediate graph points may not alter cached terrain")
F.provider(lib, F.map({ wall = true, disconnected = true }), 2)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "no_path")
local _, costs = F.finish(provider:CreateCostJob(a, { b }, { walkSpeed = 7 }))
assert(costs.costs[1].state == "no_path")
local bad = F.map()
bad.height[1] = "!"
F.provider(lib, bad, 3)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "unavailable")
local badStatus, badCosts = F.finish(provider:CreateCostJob(a, { b, a }, { walkSpeed = 7 }))
assert(badStatus == "ready" and badCosts.costs[1].state == "unavailable"
    and badCosts.costs[2].state == "unavailable", "A corrupt batch still returns an ordered state for every target")
local partial = F.map()
partial.packed, partial.counts = { grid = {} }, { grid = 1 }
F.provider(lib, partial, 4)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "unavailable")
local future = F.map()
future.format = 5
F.provider(lib, future, 5)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "unavailable")
F.provider(lib, F.map(), 6)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "ready",
    "A corrected higher revision recovers after corrupt data")
local outside = F.point(20, 1, 0)
assert(F.finish(provider:CreatePathJob(a, outside, { walkSpeed = 7 })) == "unavailable")
local floors = F.map()
local cell = 6 * 8 + 1
floors.floor[1] = F.number(1, 3) .. F.number(cell, 3) .. F.number(1, 1)
    .. F.number(1, 1) .. F.number(2068, 2) .. "AA" .. "AAA"
F.provider(lib, floors, 7)
assert(F.finish(provider:CreatePathJob(a, F.point(6, 1), { walkSpeed = 7 })) == "unavailable",
    "Unknown height may not silently choose between overlapping disconnected floors")
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "ready")
assert(F.finish(provider:CreatePathJob(a, F.point(6, 1, 20), { walkSpeed = 7 })) == "no_path",
    "Known disconnected overlapping floors must retain their actual graph separation")
local high = F.point(6, 1, 1000)
assert(F.finish(provider:CreatePathJob(a, high, { walkSpeed = 7 })) == "unavailable",
    "A known high floor cannot be silently snapped down to the ground")
-- The same surface refusal must reach ordinary planner requests through both
-- terrain job types. A later observation can identify the lower floor.
local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
APR = {}
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local edges = {CreateEdgeBuild = function()
    return {Step = function() return "ready", {}, {} end}
end}
local function plan(start, goal, catalogue, speedCeiling)
    local job = APR.NavigationPlanner:Create({start = start, goal = goal, data = catalogue or edges, taxiData = edges,
        engine = engine, walkingProvider = provider, walkingSpeedCeiling = speedCeiling, canWalk = function() return true end,
        prepareSegment = function(segment) return segment end})
    for _ = 1, 20000 do
        local state, itinerary = job:Step(16, 10)
        if state ~= "planning" then return state, itinerary, job.unresolvedSurface, job.otherDataPending end
    end
    error("Terrain planner did not finish")
end
for _, origin in ipairs({F.point(6, 1), F.point(6, 1, 10)}) do
    local pathState, refusal = F.finish(provider:CreatePathJob(origin, a, {}))
    assert(pathState == "unavailable" and refusal.unresolvedSurface)
    local _, batch = F.finish(provider:CreateCostJob(origin, {a}, {}))
    assert(batch.costs[1].unresolvedSurface)
    local planState, itinerary, unresolved = plan(origin, a)
    assert(planState == "waiting_data" and itinerary == nil and unresolved)
end
assert(plan(F.point(6, 1), F.point(6, 1, 0)) == "waiting_data",
    "An unknown departure height cannot alias a known goal at zero elevation")
assert(plan(F.point(6, 1), F.point(6, 1)) == "waiting_data",
    "Matching XY cannot establish arrival across stacked floors")
assert(plan(F.point(1, 1), F.point(1, 1)) == "ready",
    "Matching XY on a unique surface still completes")
local alternate = {CreateEdgeBuild = function()
    return {Step = function()
        return "ready", {{kind = "boat", id = "crossing", seconds = 2, from = F.point(6, 1), to = a}}, {}
    end}
end}
assert(plan(a, F.point(6, 1, 20), alternate) == "no_path",
    "An ambiguous unrelated waypoint cannot turn a disconnected route into a terrain wait")
local stackedGoal = F.point(6, 1)
assert(plan(a, stackedGoal, alternate, 7) == "waiting_data",
    "Transport elsewhere cannot make an unidentified destination surface walkable")
local landing = {CreateEdgeBuild = function()
    return {Step = function()
        return "ready", {{kind = "portal", id = "landing", seconds = 2, from = a, to = stackedGoal}}, {}
    end}
end}
local transitState, transit = plan(a, stackedGoal, landing, 7)
assert(transitState == "ready" and transit.queue[1].kind == "portal",
    "A transport can still land at an exact goal that won't accept a walking edge")
local pending = {CreateEdgeBuild = function()
    return {Step = function() return "ready", {}, {waitingData = true} end}
end}
local pendingState, _, terrainPending, otherPending = plan(F.point(6, 1), a, pending)
assert(pendingState == "waiting_data" and terrainPending and otherPending)
local nearby = F.point(6, 1)
nearby.x = nearby.x + F.cellSize / 4
assert(provider:IsSameWalkingCell(b, nearby))
assert(provider:IsSameWalkingCell(b, a) == false)
assert(provider:IsSameWalkingCell(b, outside) == nil)
local resolvedState, itinerary = plan(b, a)
assert(resolvedState == "ready" and itinerary.queue[1].path[1].z == 0)
assert(plan(outside, a) == "ready", "Outside terrain coverage the authorized estimate remains available")
local extra = F.map()
extra.grid[1] = extra.grid[1] .. "A"
F.provider(lib, extra, 8)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "unavailable",
    "A tile with extra grid cells is malformed rather than a complete graph")
extra = F.map()
extra.height[1] = extra.height[1] .. "X"
F.provider(lib, extra, 9)
assert(F.finish(provider:CreatePathJob(a, b, { walkSpeed = 7 })) == "unavailable",
    "A height stream with unused records is malformed")
print("terrain runtime failures: detours, disconnects, corrupt/partial/unsupported data and unknown floors passed")
