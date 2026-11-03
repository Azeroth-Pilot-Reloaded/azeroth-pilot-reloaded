local F = dofile("tests/lua/navigation_v2/fixture.lua")
local graph = F.Graph()
local planner = F.New(graph)
local job = planner:Plan({ from = "start", to = "goal", via = { "gate", "far" } })
local first = job:Step(1)
assert(first.status == "running" and first.diagnostics.operations == 1)
local result = F.Finish(job, 1)
assert(result.status == "complete" and result.optimal == true)
assert(result.estimatedSeconds == 9, "Mandatory passage must defeat the cheap bypass")
assert(#result.segments == 3 and #result.nodes == 4)
assert(result.segments[1].edgeId == "approach")
assert(result.segments[2].edgeId == "passage")
assert(result.segments[3].edgeId == "finish")
assert(result.nodes[1] == "start" and result.nodes[4] == "goal")
assert(result.diagnostics.relaxed > 0 and result.diagnostics.slices > 1)
assert(job:Step() == result, "Completed job must not restart")
assert(F.Finish(planner:Plan({ from = "start", to = "goal" })).estimatedSeconds == 1)
assert(F.Finish(planner:Plan({ from = "goal", to = "goal" })).estimatedSeconds == 0)
local impossible = F.Finish(planner:Plan({ from = "goal", to = "start" }))
assert(impossible.status == "no_path" and impossible.reason == "disconnected")
assert(impossible.objective.to == "start" and not impossible.estimatedSeconds)

-- Caller edits after validation/request capture cannot change a job's graph or objective.
local request = { from = "start", to = "goal", via = { "gate" } }
local captured = planner:Plan(request)
graph.edges[2].seconds = 1000
request.via[1] = "goal"
assert(F.Finish(captured).estimatedSeconds == 9)

-- Required visits are ordered, including revisiting a node after a cycle.
local cyclic = F.New({ complete = true, nodes = { "a", "b", "c" }, edges = {
    { id = "ab", from = "a", to = "b", seconds = 0 },
    { id = "ba", from = "b", to = "a", seconds = 0 },
    { id = "ac", from = "a", to = "c", seconds = 2 },
} })
local cycle = F.Finish(cyclic:Plan({ from = "a", to = "c", via = { "a", "a", "b", "a" } }))
assert(cycle.status == "complete" and cycle.estimatedSeconds == 2 and #cycle.segments == 3)
