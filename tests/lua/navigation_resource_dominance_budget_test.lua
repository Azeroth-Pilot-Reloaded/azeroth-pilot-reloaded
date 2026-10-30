-- A comparison between two resource-heavy arrivals is part of the frame budget,
-- not one indivisible operation. No authored route/catalogue is loaded here.
local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local environment = getfenv(engine.CreateSearch)
local nativeNext = environment.next
local state = { clock = 0, reads = 0, largest = 0 }
environment.next = function(values, cursor)
    local key, value = nativeNext(values, cursor)
    if type(key) == "string" and key:sub(1, 2) == "r:" then
        state.clock, state.reads = state.clock + 0.25, state.reads + 1
    end
    return key, value
end
environment.pairs = function(values) return environment.next, values, nil end
local function point(world) return { instanceID = world, x = 0, y = 0 } end
local start, hub, goal = point(1), point(2), point(3)
local capacities, common = {}, {}
for index = 1, 500 do capacities["r:" .. index], common["r:" .. index] = 1, 1 end
capacities["r:fuel"] = 1
local function edge(id, from, to, seconds, resources)
    return { id = id, kind = "portal", from = from, to = to, seconds = seconds, resources = resources }
end
local function request(edges)
    return { start = start, goal = goal, edges = edges, resources = capacities,
        canWalk = function() return false end, clock = function() return state.clock end }
end
local function finish(search)
    local slices = 0
    repeat
        local before = state.clock
        local status = search:Step(10000, 1)
        state.largest = math.max(state.largest, state.clock - before)
        slices = slices + 1
        assert(slices < 5000, "Incremental resource comparisons must eventually complete")
    until status ~= "planning"
    assert(state.largest <= 1.25,
        "A 1 ms slice cannot hide a full 500-resource dominance comparison: " .. state.largest)
    assert(search.status == "ready")
    return search:GetResult()
end

local search = engine:CreateSearch(request({
    edge("first", start, hub, 1, common), edge("equivalent", start, hub, 1, common),
    edge("finish", hub, goal, 1),
}))
assert(search:Step(0, 1) == "planning" and state.reads == 0)
assert(search:Step(1, 0) == "planning" and state.reads == 0)
local result = finish(search)
assert(result.totalSeconds == 2 and #result.segments == 2 and result.segments[1].id == "first",
    "An equivalent arrival is discarded without changing deterministic route selection")
assert(result.resourcesUsed["r:1"] == 1 and result.resourcesUsed["r:500"] == 1)

state.largest = 0
result = finish(engine:CreateSearch(request({
    edge("expensive", start, hub, 3, common), edge("better", start, hub, 1, common),
    edge("finish", hub, goal, 1),
})))
assert(result.totalSeconds == 2 and result.segments[1].id == "better",
    "The reverse comparison can remove an earlier, strictly slower arrival")

local consumesFuel = {}
for key, count in pairs(common) do consumesFuel[key] = count end
consumesFuel["r:fuel"] = 1
state.largest = 0
result = finish(engine:CreateSearch(request({
    edge("fast-wastes-fuel", start, hub, 1, consumesFuel), edge("preserves-fuel", start, hub, 2, common),
    edge("fuel-crossing", hub, goal, 1, { ["r:fuel"] = 1 }),
})))
assert(result.totalSeconds == 3 and result.segments[1].id == "preserves-fuel"
    and result.resourcesUsed["r:fuel"] == 1,
    "An incomparable slower arrival survives when its preserved resource is required later")

local fastAction = edge("fast-action", start, hub, 1, consumesFuel)
local preservingAction = edge("preserving-action", start, hub, 2, common)
fastAction.sourceFree, preservingAction.sourceFree = true, true
state.largest = 0
result = finish(engine:CreateSearch(request({ fastAction, preservingAction,
    edge("fuel-crossing", hub, goal, 1, { ["r:fuel"] = 1 }),
})))
assert(result.totalSeconds == 3 and result.segments[1].id == "preserving-action",
    "Incremental comparisons retain a relevant reagent while ignoring origin-only resources")

search = engine:CreateSearch(request({
    edge("first", start, hub, 1, common), edge("equivalent", start, hub, 1, common),
    edge("finish", hub, goal, 1),
}))
local operations = 0
while not (search.candidate and search.candidate.stage == "dominance"
    and search.candidate.resourceCursor ~= nil) do
    local reads = state.reads
    assert(search:Step(1, 1) == "planning")
    assert(state.reads - reads <= 2, "One operation reads at most one resource and its bounded lookahead")
    operations = operations + 1
    assert(operations < 10000, "The fixture must reach a suspended comparison")
end
local before = state.reads
search:Cancel()
assert(search:Step(10000, 100) == "cancelled" and state.reads == before
    and search.candidate == nil and search.pending == nil,
    "Cancelling a suspended comparison releases it without reading remaining resources")
print("Resource dominance: 500-key equivalent, better and incomparable arrivals obey time slices and cancellation")
