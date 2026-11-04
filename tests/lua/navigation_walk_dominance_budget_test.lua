-- Zero optimistic walking costs are non-metric; proved arrivals still provide
-- a safe lower bound before invoking expensive permission/cost callbacks.
local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local function finish(search, bound)
    for slice = 1, bound or 50000 do
        local status = search:Step(4096, 1)
        assert(search.workLastStep <= 4096)
        if status ~= "planning" then return search:GetResult(), slice end
    end
    error("Synthetic walking search exceeded its finite work bound")
end
local function point(index, world, mode)
    return {x = index * 10, y = 0, instanceID = world or 0, region = "invented-mainland",
        movementMode = mode, index = index}
end
local start, goal = point(0), point(999, 1)
local nodes, edges, calls, now = {}, {}, 0, 0
for i = 1, 320 do
    nodes[i] = point(i)
    edges[#edges + 1] = {kind = "portal", from = start, to = nodes[i], seconds = 0}
end
edges[#edges + 1] = {kind = "portal", from = nodes[#nodes], to = goal, seconds = 5}
local search = engine:CreateSearch({start = start, goal = goal, edges = edges,
    walkingIsTransitive = false, clock = function() return now end,
    canWalk = function() calls = calls + 1; now = now + 0.25; return true end,
    walkSecondsFor = function() calls = calls + 1; now = now + 0.25; return 0 end})
local result, slices = finish(search)
assert(result.totalSeconds == 5 and #result.segments == 2)
assert(calls <= 2 and search.walkDominanceSkipped >= 320 * 320 and slices < 100,
    "Already proved zero-cost arrivals must avoid quadratic terrain callbacks without assuming transitive walking")
assert(search.walkingExpansionsSkipped == 0,
    "Dominance remains valid even when metric-clique pruning is disabled")

-- Different movement classes cannot walk into each other. Keep explicit
-- transitions while avoiding their inclusion in every automatic walk scan.
edges = {}
for _, mode in ipairs({"ground", "steady", "skyriding"}) do
    for i = 1, 120 do
        local node = point(i, 0, mode)
        edges[#edges + 1] = {kind = "portal", from = node, to = node, seconds = 0}
    end
end
search = engine:CreateSearch({start = start, goal = goal, edges = edges,
    canWalk = function() return false end})
result = finish(search)
assert(not result and search.walkChecks <= 120,
    "A ground source must not inspect steady-flight or skyriding destinations")
local air, airGoal = point(1, 0, "steady"), point(2, 0, "steady")
search = engine:CreateSearch({start = start, goal = airGoal,
    edges = {{kind = "portal", from = start, to = air, seconds = 2}}, walkSpeed = 1})
result = finish(search)
assert(result.totalSeconds == 12 and #result.segments == 2,
    "An explicit transition retains the following automatic walk in its movement class")

-- An earlier arrival that consumed the remaining reagent cannot suppress a
-- later reagent-preserving approach, even when its time lower bound is worse.
start, goal = point(0, 1), point(3, 2)
local hub, approach = point(1), point(2)
search = engine:CreateSearch({start = start, goal = goal, resources = {rune = 1},
    edges = {
        {kind = "portal", from = start, to = hub, seconds = 0, resources = {rune = 1}},
        {kind = "portal", from = start, to = approach, seconds = 2},
        {kind = "portal", from = hub, to = goal, seconds = 1, resources = {rune = 1}},
    }, canWalk = function(a, b) return a == approach and b == hub end,
    walkSecondsFor = function() return 0 end})
result = finish(search)
assert(result.totalSeconds == 3 and result.resourcesUsed.rune == 1 and #result.segments == 3,
    "A cheap target label with different future resources is not a dominance proof")
search = engine:CreateSearch({start = start, goal = goal, budget = 10,
    edges = {
        {kind = "portal", from = start, to = hub, seconds = 0, copper = 10},
        {kind = "portal", from = start, to = approach, seconds = 2},
        {kind = "portal", from = hub, to = goal, seconds = 1, copper = 10},
    }, canWalk = function(a, b) return a == approach and b == hub end,
    walkSecondsFor = function() return 0 end})
result = finish(search)
assert(result.totalSeconds == 3 and result.totalCopper == 10,
    "A faster target arrival cannot suppress the only affordable approach")

-- Origin-only cooldowns never constrain later legs. Different immutable usage
-- tables can share this proof, while the winner retains its actual usage.
calls = 0
search = engine:CreateSearch({start = start, goal = goal, resources = {first = 1, second = 1},
    edges = {
        {kind = "spell", sourceFree = true, from = start, to = hub, seconds = 0, resourceKey = "first"},
        {kind = "spell", sourceFree = true, from = start, to = approach, seconds = 2, resourceKey = "second"},
        {kind = "portal", from = hub, to = goal, seconds = 10},
    }, canWalk = function(a, b) calls = calls + 1; return a == approach and b == hub end,
    walkSecondsFor = function() return 0 end})
result = finish(search)
assert(result.totalSeconds == 10 and result.resourcesUsed.first == 1 and not result.resourcesUsed.second
    and search.walkDominanceSkipped > 0 and calls == 1,
    "Irrelevant consumed cooldowns permit pruning without losing the real winning resource receipt")

-- Independently enumerate arbitrary directed, non-metric walking costs, mode
-- changes, transport costs, money and a consumable. No maintained data is used.
local seed = 83021
local function random(n) seed = seed * 48271 % 2147483647; return seed % n + 1 end
for scenario = 1, 120 do
    local points, links, adjacency, walks = {}, {}, {}, {}
    for i = 1, 6 do
        points[i] = point(i, 0, (i == 1 or i == 6 or random(3) == 1) and "ground" or "steady")
        adjacency[i], walks[i] = {}, {}
    end
    for i = 1, 6 do
        links[#links + 1] = {kind = "portal", from = points[i], to = points[i], seconds = 0}
        for j = 1, 6 do
            if i ~= j then
                if points[i].movementMode == points[j].movementMode and random(3) ~= 1 then
                    local seconds = random(9) - 1
                    walks[i][j] = seconds
                    adjacency[i][#adjacency[i] + 1] = {target = j, seconds = seconds, copper = 0, rune = 0}
                end
                if random(3) == 1 then
                    local seconds, copper, rune = random(9) - 1, random(3) - 1, random(2) - 1
                    links[#links + 1] = {kind = "portal", from = points[i], to = points[j],
                        seconds = seconds, copper = copper, resources = {rune = rune}}
                    adjacency[i][#adjacency[i] + 1] = {target = j, seconds = seconds, copper = copper, rune = rune}
                end
            end
        end
    end
    local best, budget, capacity, visited = math.huge, random(5) - 1, random(3) - 1, {}
    local function enumerate(index, seconds, copper, rune)
        if copper > budget or rune > capacity or seconds >= best then return end
        if index == 6 then best = seconds; return end
        visited[index] = true
        for _, edge in ipairs(adjacency[index]) do
            if not visited[edge.target] then enumerate(edge.target, seconds + edge.seconds,
                copper + edge.copper, rune + edge.rune) end
        end
        visited[index] = nil
    end
    enumerate(1, 0, 0, 0)
    search = engine:CreateSearch({start = points[1], goal = points[6], edges = links,
        budget = budget, resources = {rune = capacity}, walkingIsTransitive = false,
        canWalk = function(a, b) return walks[a.index][b.index] ~= nil end,
        walkSecondsFor = function(a, b) return walks[a.index][b.index] end})
    result = finish(search)
    assert((best == math.huge and not result) or (result and result.totalSeconds == best),
        "Walking dominance oracle mismatch in synthetic scenario " .. scenario)
end
print("Walking lower bounds: bounded zero-cost callbacks, movement classes, resource-safe arrivals and 120 independent directed oracles passed")
