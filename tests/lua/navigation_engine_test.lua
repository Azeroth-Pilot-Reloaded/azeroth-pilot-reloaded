APR = {}
APR.NavigationEngine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local function point(x, region) return { x = x, y = 0, instanceID = 0, region = region or tostring(x) } end
local function edge(id, from, to, seconds, copper, resources)
    return { id = id, from = from, to = to, seconds = seconds, copper = copper, resources = resources, kind = "portal" }
end
local function finish(request)
    local search = APR.NavigationEngine:CreateSearch(request)
    local status, result
    repeat status, result = search:Step(1) until status ~= "planning"
    return status, result, search
end
local a, b, c, goal = point(0), point(1), point(2), point(3)
local neverWalk = function() return false end
local status, result = finish({ start = a, goal = goal, budget = 10, canWalk = neverWalk, edges = {
    edge("fast-expensive", a, b, 1, 9), edge("cheap", a, c, 2, 0), edge("cheap-arrival", c, b, 1, 0),
    edge("final-fare", b, goal, 1, 5) } })
assert(status == "ready" and result.totalSeconds == 4 and result.totalCopper == 5,
    "A slower arrival preserving enough money must survive the faster label")
status, result = finish({ start = a, goal = goal, budget = 0, resources = { rune = 1 }, canWalk = neverWalk,
    edges = { edge("fast-consumes", a, b, 1, 0, { rune = 1 }), edge("preserve", a, c, 2, 0),
        edge("preserved-arrival", c, b, 1, 0), edge("needs-rune", b, goal, 1, 0, { rune = 1 }) } })
assert(status == "ready" and result.totalSeconds == 4 and result.resourcesUsed.rune == 1,
    "Consumable dominance must retain a slower label with its reagent intact")
status = finish({ start = b, goal = a, edges = { edge("one-way", a, b, 1, 0) }, canWalk = neverWalk })
assert(status == "no_path", "Directed passages never imply a return route")
status = finish({ start = a, goal = goal, budget = 10, resources = { shared = 1 }, canWalk = neverWalk,
    edges = { edge("first", a, b, 1, 0, { shared = 1 }), edge("second", b, goal, 1, 0, { shared = 1 }) } })
assert(status == "no_path", "Shared hearthstone/cooldown resources cannot be reused")
local destination = point(700, "mainland")
local start = point(0, "mainland")
status, result = finish({ start = start, goal = destination, budget = 0, walkSpeed = 7 })
assert(status == "ready" and result.totalSeconds == 100 and result.segments[1].kind == "walk")
destination.region = "restricted"
status = finish({ start = start, goal = destination, walkSpeed = 7 })
assert(status == "no_path", "Physical proximity must not connect isolated access regions")
destination.instanceID = 1; destination.region = "mainland"
status = finish({ start = start, goal = destination, canWalk = function() return true end })
assert(status == "no_path", "Overlapping world coordinates in different instances never walk-connect")
local action = edge("personal-teleport", a, goal, 1, 0, { teleport = 1 })
action.sourceFree, action.action = true, { type = "spell", data = 3561 }
status, result = finish({ start = b, goal = goal, resources = { teleport = 1 }, canWalk = neverWalk, edges = { action } })
assert(status == "ready" and result.segments[1].from == b and result.segments[1].action.data == 3561,
    "Personal travel originates at the current search position, not the initial catalogue position")
local search = APR.NavigationEngine:CreateSearch({ start = a, goal = goal, canWalk = neverWalk,
    edges = { edge("ab", a, b, 1), edge("bg", b, goal, 1) } })
assert(search:Step(1) == "planning" and search.expansions == 0,
    "The first slice loads inputs before any graph expansion")
search:Cancel()
assert(search:Step(100) == "cancelled" and not search:GetResult())
assert(next(search.heap) == nil and next(search.labels) == nil and search.pending == nil,
    "Cancelling a queued search releases its labels and active expansion")
assert(a.x == 0 and goal.x == 3 and action.from == a, "Search never mutates caller graph positions or edges")
local manyEdges, nodes, checks = {}, {}, 0
for index = 1, 2001 do nodes[index] = point(index + 100) end
for index = 1, 2000 do manyEdges[index] = edge("large:" .. index, nodes[index], nodes[index + 1], 1, 0) end
local large = APR.NavigationEngine:CreateSearch({ start = nodes[1], goal = nodes[2001], edges = manyEdges,
    canWalk = function() checks = checks + 1; return false end })
for _ = 1, 3 do
    local before = checks
    assert(large:Step(64) == "planning")
    assert(large.workLastStep <= 64 and checks - before <= 64,
        "A dense graph must yield within its candidate-work budget, even inside one node expansion")
end
assert(large.expansions == 0 and large.ingestedEdges < #manyEdges,
    "Loading a large graph itself resumes across frames")
while large.phase ~= "search" do large:Step(64) end
large:Step(64)
assert(large.expansions == 1 and large.pending, "A large adjacency scan resumes across frames")
large:Cancel()
assert(large:Step(64) == "cancelled")
assert(next(large.heap) == nil and next(large.labels) == nil and large.pending == nil)
local ticks = 0
local timed = APR.NavigationEngine:CreateSearch({ start = nodes[1], goal = nodes[2001], edges = manyEdges,
    canWalk = neverWalk, clock = function() ticks = ticks + 1; return ticks end })
for _ = 1, 3 do
    assert(timed:Step(10000, 2) == "planning" and timed.workLastStep == 2,
        "An injected millisecond deadline yields before the larger operation allowance is exhausted")
end
assert(timed.expansions == 0 and timed.ingestedEdges > 0 and timed.ingestedEdges < #manyEdges,
    "The deadline also preserves the unfinished graph-loading cursor")
timed:Cancel()
local before = ticks
assert(timed:Step(10000, 2) == "cancelled" and ticks == before,
    "Cancelled searches perform no more work or clock reads")
print("Navigation engine: directed travel, Pareto money/resources, access regions, world instances, bounded work/time and cancellation release passed")
