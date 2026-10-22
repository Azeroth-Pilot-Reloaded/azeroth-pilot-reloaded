-- Compare the search with exhaustive simple-path enumeration on small graphs.
-- Positive costs and consumable-only resources mean an optimal path needs no cycle.
local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local seed = 1729
local function random(limit)
    seed = (seed * 48271) % 2147483647
    return seed % limit + 1
end
local points = {}
for index = 1, 6 do points[index] = { instanceID = 0, uiMapID = 1, x = index * 100, y = 0, z = index % 2 * 100 } end
local function NeverWalk() return false end
for scenario = 1, 200 do
    local edges, outgoing = {}, {}
    local budget, reagent = random(15) - 1, random(3) - 1
    for from = 1, 6 do
        outgoing[from] = {}
        for to = 1, 6 do
            if from ~= to and random(3) == 1 then
                local resource = random(4) == 1 and { reagent = 1 } or nil
                local edge = { id = from .. ":" .. to, kind = random(2) == 1 and "portal" or "elevator",
                    from = points[from], to = points[to], seconds = random(15), copper = random(6) - 1,
                    resources = resource, targetIndex = to }
                edges[#edges + 1] = edge
                outgoing[from][#outgoing[from] + 1] = edge
            end
        end
    end
    local best, visited = math.huge, {}
    local function Enumerate(node, seconds, copper, used)
        if copper > budget or used > reagent or seconds >= best then return end
        if node == 6 then best = seconds; return end
        visited[node] = true
        for _, edge in ipairs(outgoing[node]) do
            if not visited[edge.targetIndex] then
                Enumerate(edge.targetIndex, seconds + edge.seconds, copper + edge.copper,
                    used + (edge.resources and 1 or 0))
            end
        end
        visited[node] = nil
    end
    Enumerate(1, 0, 0, 0)
    local search = engine:CreateSearch({ start = points[1], goal = points[6], edges = edges,
        budget = budget, resources = { reagent = reagent }, canWalk = NeverWalk })
    local status, result, slices = nil, nil, 0
    repeat
        status, result = search:Step(3, 1)
        slices = slices + 1
        assert(slices < 2000, "Every finite graph must finish in bounded batches")
    until status ~= "planning"
    if best == math.huge then
        assert(status == "no_path", "A route cannot spend missing money or reagents")
    else
        assert(status == "ready" and result.totalSeconds == best,
            "Scenario " .. scenario .. ": the chosen journey must match exhaustive enumeration")
        assert(result.totalCopper <= budget and (result.resourcesUsed.reagent or 0) <= reagent)
    end
end
print("Fastest path oracle: 200 directed graphs, exhaustive feasible paths, budgets, consumables, stacked heights and three-operation slices passed")
