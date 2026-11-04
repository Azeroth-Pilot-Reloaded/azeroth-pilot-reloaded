local F = dofile("tests/lua/navigation_v2/fixture.lua")
local graph = { complete = true, nodes = {}, edges = {} }
for i = 1, 20000 do
    graph.nodes[i] = "node-" .. i
    if i > 1 then
        graph.edges[i - 1] = { id = "edge-" .. i, from = "node-1", to = "node-" .. i, seconds = i }
    end
end

-- New and Plan must not hide a graph-wide pass outside Step. Count Lua VM
-- instructions rather than measuring machine speed; fixture creation is excluded.
local instructions = 0
debug.sethook(function() instructions = instructions + 100 end, "", 100)
local planner, time = F.New(graph)
local job = planner:Plan({ from = "node-1", to = "node-2" })
debug.sethook()
assert(instructions < 10000, "New/Plan scanned a large graph outside the job budget")
time.tick = 0.6
local result = job:Step(100000)
assert(result.status == "running" and result.diagnostics.phase == "prepare_nodes")
assert(result.diagnostics.operations <= 2 and result.diagnostics.preparedNodes <= 2)
assert(result.diagnostics.expanded == 0 and result.diagnostics.cpuMs >= 1)
time.tick = 0
result = F.Finish(job, 128)
assert(result.status == "complete" and result.estimatedSeconds == 2)
assert(result.diagnostics.preparedNodes == 20000 and result.diagnostics.preparedEdges == 19999)

-- The compiled index belongs to the planner and is reused, including after
-- invalidation. Later plans must not touch the source declarations at all.
graph.nodes, graph.edges = false, false
planner:Invalidate()
local second = F.Finish(planner:Plan({ from = "node-1", to = "node-3" }), 128)
assert(second.status == "complete" and second.estimatedSeconds == 3)
assert(second.diagnostics.preparedNodes == 0 and second.diagnostics.preparedEdges == 0)

local limited, clock = F.New(F.Graph(), { cpuMs = 2 })
job = limited:Plan({ from = "start", to = "goal" })
clock.tick = 1
result = F.Finish(job, 1)
assert(result.status == "budget_exceeded" and result.reason == "cpu_budget")
assert(result.diagnostics.phase == "prepare_nodes" and result.diagnostics.expanded == 0)
assert(result.diagnostics.preparedNodes == 2)

-- Partial preparation survives cancellation; only the cancelled job stops.
local reusable = F.New(F.Graph())
local cancelled = reusable:Plan({ from = "start", to = "goal" })
assert(cancelled:Step(1).diagnostics.preparedNodes == 1)
assert(cancelled:Cancel().status == "cancelled")
local resumed = F.Finish(reusable:Plan({ from = "start", to = "goal" }))
assert(resumed.status == "complete" and resumed.estimatedSeconds == 1)
assert(resumed.diagnostics.preparedNodes == 3 and resumed.diagnostics.preparedEdges == 5)

-- Edge validation/copying uses the same slice limit as node preparation.
local edgePlanner, edgeClock = F.New(F.Graph())
local edgeJob = edgePlanner:Plan({ from = "start", to = "goal" })
assert(edgeJob:Step(5).diagnostics.phase == "prepare_edges")
edgeClock.tick = 0.6
local edges = edgeJob:Step(10000)
assert(edges.status == "running" and edges.diagnostics.preparedEdges == 2)
assert(edges.diagnostics.operations == 7 and edges.diagnostics.expanded == 0)
