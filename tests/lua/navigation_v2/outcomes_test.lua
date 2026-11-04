local F = dofile("tests/lua/navigation_v2/fixture.lua")
local graph = { complete = true, nodes = { "a", "b", "c", "island" }, edges = {
    { id = "unknown", from = "a", to = "b", seconds = 1, access = "unknown" },
    { id = "known", from = "a", to = "c", seconds = 8 },
    { id = "continuation", from = "b", to = "c", seconds = 1 },
} }
local planner = F.New(graph)
assert(F.Finish(planner:Plan({ from = "a", to = "c" })).estimatedSeconds == 8,
    "Known usable travel takes priority over uncertain shortcuts")
local unknown = F.Finish(planner:Plan({ from = "a", to = "b" }))
assert(unknown.status == "unknown" and unknown.reason == "unknown_access")
assert(not unknown.optimal and not unknown.segments and unknown.objective.to == "b")
assert(F.Finish(planner:Plan({ from = "a", to = "island" })).status == "no_path",
    "An unrelated unknown edge cannot hide a proved disconnection")
graph.edges[1].access = "unavailable"
planner = F.New(graph)
assert(F.Finish(planner:Plan({ from = "a", to = "b" })).status == "no_path")
graph.complete = false
planner = F.New(graph)
local uncovered = F.Finish(planner:Plan({ from = "a", to = "b" }))
assert(uncovered.status == "unknown" and uncovered.reason == "incomplete_graph")

planner = F.New(F.Graph())
local cancelled = planner:Plan({ from = "start", to = "goal" })
cancelled:Step(1)
local result = cancelled:Cancel()
assert(result.status == "cancelled" and result.reason == "cancelled")
assert(cancelled:Step() == result and cancelled:Cancel() == result)
assert(not planner:IsCurrent(result))
local active = planner:Plan({ from = "start", to = "goal" })
local complete = F.Finish(planner:Plan({ from = "start", to = "goal" }))
assert(planner:IsCurrent(complete))
planner:Invalidate()
assert(not planner:IsCurrent(complete))
assert(active:Step().status == "stale")
assert(F.Finish(planner:Plan({ from = "start", to = "goal" })).status == "complete")
