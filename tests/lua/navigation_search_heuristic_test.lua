-- A scheduled relaxed graph provides lower bounds without changing exact
-- money/resource labels, permissions, hidden zero edges or personal actions.
local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local function point(x, world)
    return {x = x, y = 0, instanceID = world or 1, region = "invented-region"}
end
local function finish(search, maximum)
    for slice = 1, maximum or 10000 do
        local status = search:Step(64, 1)
        assert(search.workLastStep <= 64)
        if status ~= "planning" then return search:GetResult(), slice end
    end
    error("Relaxed-graph search exceeded its finite work bound")
end
local start, arrival, goal = point(0), point(0, 2), point(1000, 2)
local edges = {}
for index = 1, 600 do
    edges[#edges + 1] = {kind = "portal", from = start, to = point(index), seconds = 0.1}
end
edges[#edges + 1] = {kind = "portal", from = start, to = arrival, seconds = 1}
local queries, permissions, now = {}, 0, 0
local function request()
    return {start = start, goal = goal, edges = edges, walkSpeed = 10,
        clock = function() now = now + 0.001; return now end,
        canWalk = function(a, b) permissions = permissions + 1; return a.instanceID == 2 and b.instanceID == 2 end,
        walkingHeuristic = {euclideanWorld = function(world)
            queries[world] = (queries[world] or 0) + 1
            if world == 2 then return true end -- Unknown worlds collapse.
        end}}
end
local search = engine:CreateSearch(request())
assert(next(queries) == nil and permissions == 0, "Creation cannot classify or explore a relaxed graph")
local result, slices = finish(search)
assert(result.totalSeconds == 101 and #result.segments == 2 and search.expansions == 3,
    "Goal approach cost prevents expansion of hundreds of cheap irrelevant arrivals")
assert(queries[1] == 1 and queries[2] == 1 and #search.heuristic.vertices == 3 and slices < 100,
    "Uncertain worlds collapse once and heuristic construction obeys scheduled work limits")
assert(search:HeuristicSeconds(search.startNode) == 101 and search:HeuristicSeconds(search.goalNode) == 0)

-- Resource-restricted personal travel may be usable only away from the start.
-- The relaxed global action must include it even if ordinary start actions do
-- not. Conversely an action usable at start is included there as well.
local remote = edges[1].to
edges[#edges + 1] = {kind = "item", from = remote, to = goal, seconds = 5, sourceFree = true,
    resources = {charge = 1}, canStart = function(p) return p == remote end}
local options = request()
options.resources = {charge = 1}
search = engine:CreateSearch(options)
result = finish(search)
assert(result.totalSeconds == 5.1 and result.resourcesUsed.charge == 1,
    "A globally relaxed map-restricted action must not hide the affordable exact departure")
assert(search:HeuristicSeconds(search.startNode) == 5)
edges[#edges].canStart = nil
options = request(); options.resources = {charge = 1}
search = engine:CreateSearch(options)
result = finish(search)
assert(result.totalSeconds == 5 and search:HeuristicSeconds(search.startNode) == 5,
    "Origin-only personal actions are retained in the heuristic")

-- A high-speed endpoint sets the whole world's safe speed upper bound. Never
-- infer it from the fallback speed or from just the departure and goal.
local fast = point(500, 2)
search = engine:CreateSearch({start = arrival, goal = goal, walkSpeed = 1,
    walkSpeedAt = function(p) return p == fast and 1000 or 10 end,
    edges = {{kind = "portal", from = fast, to = fast, seconds = 0}},
    walkingHeuristic = {euclideanWorld = function() return true end}})
result = finish(search)
assert(result.totalSeconds == 100 and search:HeuristicSeconds(search.startNode) == 1,
    "The maximum cached endpoint speed bounds every native min-endpoint walking cost")

local dense = {}
for index = 1, 600 do
    local p = point(index, 2)
    dense[#dense + 1] = {kind = "portal", from = p, to = p, seconds = 0}
end
search = engine:CreateSearch({start = arrival, goal = goal, edges = dense, walkSpeed = 10,
    walkingHeuristic = {euclideanWorld = function() return true end}})
result = finish(search, 200)
assert(result.totalSeconds == 100 and search.heuristic.operations < 12000,
    "A relaxed walk cannot expand another complete Euclidean walking row")

local tunnel = point(500, 2)
tunnel.noAutoconnect = true
search = engine:CreateSearch({start = arrival, goal = goal, walkSpeed = 1,
    edges = {{kind = "walk", terrain = true, from = arrival, to = tunnel, seconds = 0},
        {kind = "walk", terrain = true, from = tunnel, to = goal, seconds = 0}},
    walkingHeuristic = {euclideanWorld = function() return true end}})
result = finish(search)
assert(result.totalSeconds == 0 and search:HeuristicSeconds(search.startNode) == 0,
    "Certifying ordinary walks must retain arbitrary zero-cost explicit terrain transitions")

-- Arbitrary pair speeds have no safe maximum from node preparation. The
-- opt-in is ignored in that case, without invoking its classifier.
search = engine:CreateSearch({start = arrival, goal = goal, walkSpeedFor = function() return 1000 end,
    walkingHeuristic = {euclideanWorld = function() error("Pair-only speeds cannot certify this heuristic") end}})
result = finish(search)
assert(result.totalSeconds == 1 and search.heuristic == nil)

-- Retire incremental preparation as well as the ordinary frontier.
search = engine:CreateSearch(request())
while search.phase ~= "heuristic_nodes" do search:Step(1, 1) end
search:Step(1, 1)
search:Cancel()
local before = queries[1] or 0
assert(search:Step(64, 1) == "cancelled" and search.heuristic == nil and (queries[1] or 0) == before)

-- Independent exhaustive state search over invented directed walks and
-- transports. World 1 allows hidden non-metric zero legs; clear worlds use
-- endpoint-dependent Euclidean speeds. Money and shared charges constrain
-- the winner, but are deliberately ignored by the relaxed graph.
local seed = 9347
local function random(maximum)
    seed = seed * 16807 % 2147483647
    return seed % maximum + 1
end
for case = 1, 100 do
    local nodes, graph, speeds, allowed, walking = {}, {}, {}, {}, {}
    for i = 1, 7 do
        nodes[i] = point(random(40) + i / 100, random(3))
        nodes[i].id, speeds[i], graph[i], allowed[i], walking[i] = i, random(9), {}, {}, {}
    end
    for a = 1, #nodes do
        for b = 1, #nodes do
            if a ~= b and nodes[a].instanceID == nodes[b].instanceID and random(3) ~= 1 then
                allowed[a][b] = true
                walking[a][b] = nodes[a].instanceID == 1 and random(4) - 1
                    or math.abs(nodes[a].x - nodes[b].x) / math.min(speeds[a], speeds[b])
            end
        end
    end
    for _ = 1, 18 do
        local a, b = random(#nodes), random(#nodes)
        if a ~= b then
            local edge = {kind = "portal", from = nodes[a], to = nodes[b], seconds = random(8) - 1,
                copper = random(3) - 1, resources = random(3) == 1 and {charge = 1} or nil}
            graph[a][#graph[a] + 1] = edge
        end
    end
    local all = {}
    for _, list in ipairs(graph) do for _, edge in ipairs(list) do all[#all + 1] = edge end end
    local best, visited = math.huge, {}
    local function explore(node, seconds, copper, used)
        if seconds >= best or copper > 4 or used > 1 then return end
        if node == #nodes then best = seconds; return end
        local key = node .. ":" .. copper .. ":" .. used
        if visited[key] and visited[key] <= seconds then return end
        visited[key] = seconds
        for other, cost in pairs(walking[node]) do explore(other, seconds + cost, copper, used) end
        for _, edge in ipairs(graph[node]) do
            explore(edge.to.id, seconds + edge.seconds, copper + edge.copper,
                used + (edge.resources and edge.resources.charge or 0))
        end
    end
    explore(1, 0, 0, 0)
    search = engine:CreateSearch({start = nodes[1], goal = nodes[#nodes], edges = all, budget = 4, resources = {charge = 1},
        walkSpeedAt = function(p) return speeds[p.id] end,
        canWalk = function(a, b) return allowed[a.id][b.id] end,
        walkSecondsFor = function(a, b) return walking[a.id][b.id] end,
        walkingHeuristic = {euclideanWorld = function(world) return world ~= 1 end}})
    result = finish(search)
    assert(best == math.huge and result == nil or result and math.abs(result.totalSeconds - best) < 0.0000001,
        "A* must preserve the independently enumerated fastest affordable route in case " .. case)
end
print("Search heuristic: scheduled relaxed worlds, exact goal approaches, personal actions, speed bounds and 100 independent resource oracles passed")
