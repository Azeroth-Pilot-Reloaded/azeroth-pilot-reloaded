local Engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine

local function Point(index, instance, region, map)
    return { x = index * 10, y = 0, instanceID = instance or 0, region = region or "mainland", uiMapID = map }
end

local function Edge(id, from, to, seconds, copper, resources)
    return { id = id, from = from, to = to, seconds = seconds or 1,
        copper = copper or 0, resources = resources, kind = "portal" }
end

local function NeverWalk() return false end

local function Finish(search)
    local work, steps = 0, 0
    while search.status == "planning" do
        search:Step(32)
        assert(search.workLastStep <= 32, "Every phase obeys the same operation allowance")
        work, steps = work + search.workLastStep, steps + 1
        assert(steps < 10000, "The test search did not finish")
    end
    return search:GetResult(), work
end

-- Creation must not touch the edge array. Deferring only node expansion would
-- still leave the complete catalogue scan on the caller's frame.
local first, last = Point(0), Point(10)
local reads = 0
local lazyEdges = setmetatable({}, { __index = function(_, index)
    reads = reads + 1
    if index == 1 then return Edge("lazy", first, last) end
end })
local lazy = Engine:CreateSearch({ start = first, goal = last, edges = lazyEdges, canWalk = NeverWalk })
assert(reads == 0 and lazy.ingestedEdges == 0 and lazy.expansions == 0)
assert(Finish(lazy).segments[1].id == "lazy" and reads == 2)

local nodes, edges = {}, {}
for index = 1, 2001 do nodes[index] = Point(index) end
for index = 1, 2000 do edges[index] = Edge(index, nodes[index], nodes[index + 1]) end
local large = Engine:CreateSearch({ start = nodes[1], goal = nodes[2001], edges = edges,
    resources = { rune = 5 }, canWalk = NeverWalk })
assert(#large.nodes == 2 and next(large.resources) == nil)
large:Step(32)
assert(large.ingestedEdges > 0 and large.ingestedEdges < 32 and large.expansions == 0)
large:Cancel()
assert(large:Step(100000) == "cancelled" and large.sourceEdges == nil and large.sourceResources == nil)
assert(next(large.nodes) == nil and next(large.walkingCache) == nil and large.candidate == nil)

-- A deterministic clock verifies the default one-millisecond allowance without
-- relying on machine speed or operating-system timer resolution.
local ticks = 0
local timed = Engine:CreateSearch({ start = nodes[1], goal = nodes[2001], edges = edges,
    clock = function() ticks = ticks + 1; return ticks end, canWalk = NeverWalk })
assert(timed:Step(10000, 0) == "planning" and timed.workLastStep == 0 and ticks == 0)
assert(timed:Step(0, 1) == "planning" and timed.workLastStep == 0 and ticks == 0)
for _ = 1, 5 do
    assert(timed:Step(10000) == "planning" and timed.workLastStep == 1)
end
assert(timed.expansions == 0 and timed.ingestedEdges == 4)
timed:Step(10000, 2)
assert(timed.workLastStep == 2)
timed:Cancel()
local before = ticks
assert(timed:Step(10000) == "cancelled" and ticks == before)

-- Catalogues and taxi paths can stay in separate arrays. Invalid groups and
-- invalid edges are skipped without aborting the remaining valid input.
local a, b, c, goal = Point(0), Point(1), Point(2), Point(3)
local grouped = Engine:CreateSearch({ start = a, goal = goal, edges = { Edge("ab", a, b) },
    edgeGroups = { false, { false, Edge("bc", b, c) }, { Edge("cg", c, goal) } }, canWalk = NeverWalk })
local groupedResult = Finish(grouped)
assert(groupedResult.totalSeconds == 3 and #groupedResult.segments == 3 and grouped.ingestedEdges == 3)

-- A node never scans destinations in a different world instance. With one
-- node per instance, the amount of work is linear in this directed chain.
nodes, edges = {}, {}
for index = 1, 201 do nodes[index] = Point(index, index) end
for index = 1, 200 do edges[index] = Edge(index, nodes[index], nodes[index + 1]) end
local instanceChecks = 0
local separated = Engine:CreateSearch({ start = nodes[1], goal = nodes[201], edges = edges,
    canWalk = function() instanceChecks = instanceChecks + 1; return false end })
local separatedResult, separatedWork = Finish(separated)
assert(#separatedResult.segments == 200 and instanceChecks == 0 and separatedWork < 2500,
    "Unreachable worlds must not contribute walking candidates or quadratic scanning work")

-- Region pruning is safe for the built-in walking rule only. A custom rule is
-- allowed to open a connection between two differently named regions.
local red, blue = Point(0, 0, "red"), Point(1, 0, "blue")
local isolated = Engine:CreateSearch({ start = red, goal = blue })
assert(Finish(isolated) == nil and isolated.walkChecks == 0)
local open = Engine:CreateSearch({ start = red, goal = blue, canWalk = function() return true end })
assert(Finish(open).segments[1].kind == "walk")
blue.noAutoconnect = true
local closed = Engine:CreateSearch({ start = red, goal = blue, canWalk = function() return true end })
assert(Finish(closed) == nil and closed.walkChecks == 0)

-- Two useful arrivals at b differ in cost. Their walking checks are identical,
-- so a second expansion should reuse the first expansion's distances/refusals.
local pairChecks = {}
local pareto = Engine:CreateSearch({ start = a, goal = goal, budget = 10, edges = {
    Edge("fast", a, b, 1, 9), Edge("cheap", a, c, 2), Edge("transfer", c, b, 1), Edge("fare", b, goal, 1, 5),
}, canWalk = function(from, to)
    local key = from.x .. ":" .. to.x
    pairChecks[key] = (pairChecks[key] or 0) + 1
    return false
end })
local paretoResult = Finish(pareto)
assert(paretoResult.totalCopper == 5 and paretoResult.totalSeconds == 4 and pareto.walkingCacheHits > 0)
for _, count in pairs(pairChecks) do assert(count == 1, "A repeated label must reuse its origin's walking cache") end
assert(pareto.winner.used == pareto.winner.previous.used,
    "Resource-free travel should share immutable usage tables instead of copying them")
paretoResult.resourcesUsed.tainted = 10
local independent = Engine:CreateSearch({ start = a, goal = a })
assert(Finish(independent).resourcesUsed.tainted == nil, "Results never expose a resource table shared by separate searches")

-- A map-specific action may change the map layer without moving the player.
-- Those endpoints must remain distinct in the graph.
local lower, upper, exit = Point(0, 0, "mainland", 10), Point(0, 0, "mainland", 20), Point(1, 0, "mainland", 20)
local layers = Engine:CreateSearch({ start = lower, goal = exit,
    edges = { Edge("change-layer", lower, upper, 0) },
    canWalk = function(from, to) return from.uiMapID == 20 and to.uiMapID == 20 end })
local layeredResult = Finish(layers)
assert(#layeredResult.segments == 2 and layeredResult.segments[1].id == "change-layer")

-- Result assembly is also resumable: finding the goal must not synchronously
-- reverse a long itinerary before yielding to the caller.
local assembly = Engine:CreateSearch({ start = nodes[1], goal = nodes[201], edges = edges, canWalk = NeverWalk })
while not assembly.assembly do
    assert(assembly:Step(1) == "planning")
end
local copied = #assembly.assembly.segments
assembly:Step(1)
assert(assembly.status == "planning" and #assembly.assembly.segments == copied + 1)
local assembled = Finish(assembly)
assert(#assembled.segments == 200 and assembled.segments[1].id == 1 and assembled.segments[200].id == 200)
local cancelledAssembly = Engine:CreateSearch({ start = nodes[1], goal = nodes[201], edges = edges, canWalk = NeverWalk })
while not cancelledAssembly.assembly do cancelledAssembly:Step(1) end
cancelledAssembly:Cancel()
assert(cancelledAssembly.winner == nil and cancelledAssembly.assembly == nil and cancelledAssembly:GetResult() == nil,
    "Cancelling result assembly releases the previous-label chain as well as graph inputs")

-- A nearby free route provides a safe time bound before graph construction.
-- Slow transports must not add thousands of irrelevant walking destinations.
local nearbyStart, nearbyGoal = Point(0), Point(5)
local slowEdges = {}
for index = 1, 4000 do
    slowEdges[index] = Edge("slow:" .. index, Point(index * 10), Point(index * 10 + 5), 300)
end
local nearby = Engine:CreateSearch({ start = nearbyStart, goal = nearbyGoal, edges = slowEdges })
local began = os.clock()
local nearbyResult, nearbyWork = Finish(nearby)
assert(nearbyResult.totalSeconds == 50 / 7 and #nearby.nodes == 2 and nearby.ingestedEdges == 0
    and nearby.walkChecks == 1 and nearbyWork < 4100,
    "Known slower transports must contribute neither graph nodes nor walking candidates")
print(string.format("Navigation nearby 4000-edge search: %.2fms, %d operations, %d nodes, %d walking checks",
    (os.clock() - began) * 1000, nearbyWork, #nearby.nodes, nearby.walkChecks))

local directChecks = 0
local shortcutEdges = { Edge("nearby-portal", Point(0.1), Point(4.9), 1, 0, { rune = 1 }),
    Edge("equally-fast", nearbyStart, nearbyGoal, 50 / 7) }
local shortcut = Engine:CreateSearch({ start = nearbyStart, goal = nearbyGoal, edges = slowEdges,
    edgeGroups = { shortcutEdges }, resources = { rune = 1 }, walkingIsTransitive = true,
    canWalk = function(from, to)
        if from == nearbyStart and to == nearbyGoal then directChecks = directChecks + 1 end
        return true
    end })
assert(directChecks == 0, "The direct walking predicate must run inside scheduled work, never creation")
local shortcutResult = Finish(shortcut)
assert(shortcutResult.totalSeconds < nearbyResult.totalSeconds and shortcutResult.resourcesUsed.rune == 1
    and shortcut.ingestedEdges == 2 and directChecks == 1,
    "Faster shortcuts and equal-time alternatives remain eligible, with the direct permission reused")

-- Arbitrary host rules may be non-transitive. A discarded transport endpoint
-- can still be the only walking bridge to a faster portal, so keep that point.
local bridge, portalFrom, portalTo, remote = Point(1), Point(2), Point(4.9), Point(20)
local bridgeSearch = Engine:CreateSearch({ start = nearbyStart, goal = nearbyGoal, edges = {
    Edge("slow-bridge-transport", bridge, remote, 300), Edge("bridge-portal", portalFrom, portalTo, 1),
}, canWalk = function(from, to)
    return (from == nearbyStart and (to == nearbyGoal or to == bridge))
        or (from == bridge and to == portalFrom) or (from == portalTo and to == nearbyGoal)
end })
local bridgeResult = Finish(bridgeSearch)
assert(bridgeResult.totalSeconds < nearbyResult.totalSeconds and #bridgeSearch.nodes == 6
    and bridgeSearch.ingestedEdges == 1 and bridgeResult.segments[3].id == "bridge-portal",
    "Without an explicit transitive walking contract, slow-edge endpoints must stay available as bridges")

local mapAction = Edge("map-limited-item", nearbyStart, portalTo, 1)
local startActionChecks = 0
mapAction.sourceFree = true
mapAction.canStart = function(position)
    if position == nearbyStart then startActionChecks = startActionChecks + 1 end
    return position == bridge
end
local actionBridge = Engine:CreateSearch({ start = nearbyStart, goal = nearbyGoal,
    edges = { Edge("slow-action-origin", bridge, remote, 300), mapAction } })
local actionResult = Finish(actionBridge)
assert(actionResult.totalSeconds < nearbyResult.totalSeconds and #actionBridge.nodes == 5
    and actionResult.segments[2].id == "map-limited-item" and startActionChecks == 1,
    "Even transitive walking must retain an otherwise omitted point needed by a restricted action")

local restrictedStart, restrictedGoal = Point(0, 0, "inside"), Point(5, 0, "outside")
restrictedStart.noAutoconnect = true
local mandatory = Engine:CreateSearch({ start = restrictedStart, goal = restrictedGoal,
    edges = { Edge("required-exit", restrictedStart, restrictedGoal, 300) }, walkingIsTransitive = true,
    canWalk = function() error("A mandatory endpoint must never request an automatic walking link") end })
assert(Finish(mandatory).segments[1].id == "required-exit" and mandatory.directSeconds == nil,
    "A required passage must not be bounded by an imaginary direct walk")

print("Navigation search performance: deferred grouped ingestion, one-millisecond slices, indexed/cached walking, resource sharing and bounded result assembly passed")
