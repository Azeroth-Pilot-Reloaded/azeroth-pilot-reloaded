local F = assert(loadfile("tests/lua/navigation_v2_scheduled/fixture.lua"))()
local root = "APR-Core/libs/LibAPRNavigation-2.0/"
for _, file in ipairs({ "Search.lua", "Navigation.lua" }) do
    assert(loadfile(root .. file))("synthetic", F.namespace)
end
local route = F.Route()
route.access = "available"
local catalog = assert(F.Scheduled.NewCatalog({ route }))
local edge = assert(catalog:Edge("west pier", 1, 100))
local graph = { complete = true, nodes = { "start", "west pier", "east pier", "goal" }, edges = {
    { id = "approach", from = "start", to = "west pier", seconds = 5 },
    { id = edge.id, from = edge.from, to = edge.to, seconds = edge.seconds, access = edge.access },
    { id = "exit", from = "east pier", to = "goal", seconds = 3 },
    { id = "walk", from = "start", to = "goal", seconds = 80 },
} }
local planner = assert(F.namespace.LibAPRNavigationV2.New(graph, {
    clock = function() return 100 end, profileClock = function() return 0 end,
}))
local function Finish(job)
    for _ = 1, 1000 do
        local result = assert(job:Step(5))
        if result.status ~= "running" then return result end
    end
    error("Synthetic planner did not stop")
end
local result = Finish(planner:Plan({ from = "start", to = "goal" }))
assert(result.status == "complete" and result.estimatedSeconds == 70 and result.optimal == true)
assert(result.segments[2].edgeId == "scheduled:river crossing")
assert(Finish(planner:Plan({ from = "east pier", to = "west pier" })).status == "no_path")

-- Fixed estimated wait is a real edge cost; a cheaper walk wins independently.
graph.edges[4].seconds = 69
planner = assert(F.namespace.LibAPRNavigationV2.New(graph, {
    clock = function() return 100 end, profileClock = function() return 0 end,
}))
result = Finish(planner:Plan({ from = "start", to = "goal" }))
assert(result.status == "complete" and result.estimatedSeconds == 69)
assert(#result.segments == 1 and result.segments[1].edgeId == "walk")

-- This exercises the existing planner for fixed costs only. Periodic relaxation
-- and runtime XML/host action integration require NAV-10's shared seam.
