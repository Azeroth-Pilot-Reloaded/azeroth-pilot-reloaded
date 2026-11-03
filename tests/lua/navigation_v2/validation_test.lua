local F = dofile("tests/lua/navigation_v2/fixture.lua")
local Library = F.Library
local clocks = { clock = function() return 0 end, profileClock = function() return 0 end }
local function Reject(graph, reason, options)
    local planner, actual = Library.New(graph, options or clocks)
    if planner then
        local result = F.Finish(planner:Plan({ from = "example", to = "example" }))
        assert(result.status == "invalid")
        actual, planner = result.reason, nil
    end
    assert(not planner and actual == reason, tostring(actual) .. " should be " .. reason)
end
Reject({}, "invalid_graph")
Reject({ complete = true, nodes = {}, edges = {} }, "invalid_graph")
Reject({ complete = true, nodes = { "a", "a" }, edges = {} }, "invalid_node")
Reject({ complete = true, nodes = { [2] = "a" }, edges = {} }, "invalid_graph")
local graph = F.Graph()
graph.edges[1].to = "missing"
Reject(graph, "invalid_edge")
for _, bad in ipairs({ -1, math.huge, -math.huge, 0 / 0, "1", false }) do
    graph = F.Graph()
    graph.edges[1].seconds = bad
    Reject(graph, "invalid_edge")
end
graph = F.Graph()
graph.edges[2].id = graph.edges[1].id
Reject(graph, "invalid_edge")
graph = F.Graph()
graph.edges[1].access = "sometimes"
Reject(graph, "invalid_edge")
graph.edges[1].access = false
Reject(graph, "invalid_edge")
Reject(F.Graph(), "invalid_clocks", {})
Reject(F.Graph(), "clock_unavailable", { clock = function() return nil end, profileClock = clocks.profileClock })
Reject(F.Graph(), "invalid_budgets", { clock = clocks.clock, profileClock = clocks.profileClock,
    budgets = { cpuMs = 0 } })
Reject(F.Graph(), "invalid_budgets", { clock = clocks.clock, profileClock = clocks.profileClock,
    budgets = { unrecognised = 1 } })
local planner, time = F.New(F.Graph())
for _, request in ipairs({ {}, { from = "start", to = "absent" },
    { from = "start", to = "goal", via = { "absent" } },
    { from = "start", to = "goal", via = false },
    { from = "start", to = "goal", via = { [2] = "gate" } } }) do
    local result = F.Finish(planner:Plan(request))
    assert(result.status == "invalid" and result.reason == "invalid_request")
end
local many = {}
for i = 1, 65 do many[i] = "start" end
assert(planner:Plan({ from = "start", to = "goal", via = many }):Step().status == "invalid")
local valid = planner:Plan({ from = "start", to = "goal" })
assert(select(2, valid:Step(false)) == "invalid_step_budget")
assert(select(2, valid:Step(1, false)) == "invalid_step_budget")
assert(F.Finish(valid).status == "complete")
local job = planner:Plan({ from = "start", to = "goal" })
time.wall = false
assert(job:Step().reason == "clock_unavailable")
time.wall = 0
local other = F.New(F.Graph())
assert(not other:IsCurrent(F.Finish(planner:Plan({ from = "start", to = "goal" }))),
    "Equal revision numbers from different planners do not establish ownership")

-- A bad graph is diagnosed once. Fixing source data requires a new planner;
-- an existing partial index cannot silently mix old and edited declarations.
local invalidGraph = F.Graph()
invalidGraph.edges[5].to = "missing"
local invalidPlanner = F.New(invalidGraph)
assert(F.Finish(invalidPlanner:Plan({ from = "start", to = "goal" })).reason == "invalid_edge")
invalidGraph.edges[5].to = "goal"
local cached = F.Finish(invalidPlanner:Plan({ from = "start", to = "goal" }))
assert(cached.status == "invalid" and cached.reason == "invalid_edge")
assert(cached.diagnostics.preparedNodes == 0 and cached.diagnostics.preparedEdges == 0)
assert(F.Finish(F.New(invalidGraph):Plan({ from = "start", to = "goal" })).status == "complete")
