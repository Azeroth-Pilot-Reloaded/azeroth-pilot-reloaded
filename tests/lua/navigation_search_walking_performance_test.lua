local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local function finish(search)
    local operations = 0
    while search.status == "planning" do
        search:Step(32)
        assert(search.workLastStep <= 32)
        operations = operations + search.workLastStep
        assert(operations < 100000)
    end
    return search:GetResult(), operations
end

-- A dense mainland with a distant exit used to expand every pair of points,
-- spending hundreds of thousands of scheduled operations on walking alone.
local points, edges = {}, {}
for i = 1, 601 do
    points[i] = { x = i * 10, y = i % 7, instanceID = 0, region = "mainland" }
end
local goal = { x = 0, y = 0, instanceID = 1, region = "island" }
for i = 1, 600 do
    edges[i] = { id = i, from = points[i], to = points[i + 1], seconds = 300, kind = "portal" }
end
edges[601] = { id = "exit", from = points[601], to = goal, seconds = 1, kind = "portal" }
local speedReads = 0
local search = engine:CreateSearch({ start = points[1], goal = goal, edges = edges,
    walkingIsTransitive = true, canWalk = function(a, b) return a.region == b.region end,
    walkSpeedAt = function() speedReads = speedReads + 1; return 7 end })
assert(speedReads == 0, "Search creation cannot invoke synchronous host speed queries")
local result, operations = finish(search)
local dx, dy = points[601].x - points[1].x, points[601].y - points[1].y
assert(result.totalSeconds == math.sqrt(dx * dx + dy * dy) / 7 + 1)
assert(search.walkingExpansionsSkipped == 600 and search.walkChecks <= 601 and operations < 6000,
    "Uniform transitive walking must not expand a quadratic clique")
assert(speedReads == #search.nodes, "Endpoint speeds are resolved once per unique node")

-- APR's custom walking predicate has the same region/access/floor boundaries
-- as the library. Supplying that partition must prevent cross-region callbacks
-- even when every point shares one world instance.
local isolatedEdges, isolatedPoints, checks = {}, {}, 0
for i = 1, 201 do
    isolatedPoints[i] = { x = i, y = 0, instanceID = 0, region = "region" .. i }
    if i > 1 then isolatedEdges[#isolatedEdges + 1] = {
        from = isolatedPoints[i - 1], to = isolatedPoints[i], kind = "portal", seconds = 1 } end
end
local partitioned = engine:CreateSearch({ start = isolatedPoints[1], goal = isolatedPoints[201], edges = isolatedEdges,
    walkingRegionFor = function(p) return p.region end,
    canWalk = function(a, b) checks = checks + 1; return a.region == b.region end })
local partitionResult, partitionWork = finish(partitioned)
assert(#partitionResult.segments == 200 and checks <= 1 and partitionWork < 2500,
    "A supplied region partition must not visit unrelated walking destinations")

points[1].z = 0
local liveHeight = engine:CreateSearch({ start = points[1], goal = goal, edges = edges })
local liveResult, liveOperations = finish(liveHeight)
assert(liveResult.totalSeconds == result.totalSeconds and liveOperations < 7000 and liveHeight.walkChecks < 1300
    and liveHeight.walkingExpansionsNarrowed == 600,
    "A live player height with mostly heightless catalogue points must also avoid the quadratic clique")

-- The min-endpoint speed model is not a metric across mixed speed classes:
-- a fast intermediate point can shorten the slow final approach.
local a = { x = 0, y = 0, instanceID = 0, region = "mainland", speed = 100 }
local b = { x = 90, y = 0, instanceID = 0, region = "mainland", speed = 100 }
local c = { x = 100, y = 0, instanceID = 0, region = "mainland", speed = 1 }
local mixed = engine:CreateSearch({ start = a, goal = c,
    edges = { { from = b, to = b, kind = "portal", seconds = 0 } },
    walkSpeedAt = function(p) return p.speed end })
assert(finish(mixed).totalSeconds == 10.9 and mixed.walkingExpansionsSkipped == 0,
    "Mixed endpoint speeds must retain the faster two-walk itinerary")

local pairDependent = engine:CreateSearch({ start = a, goal = c,
    edges = { { from = b, to = b, kind = "portal", seconds = 0 } },
    walkSpeedFor = function(from, to) return from == a and to == c and 1 or 100 end })
assert(finish(pairDependent).totalSeconds == 1 and pairDependent.walkingExpansionsSkipped == 0,
    "An arbitrary pair-speed callback must keep all walking links")

a.z, b.z, c.z = 0, nil, 1000
local partialHeights = engine:CreateSearch({ start = a, goal = c,
    edges = { { from = b, to = b, kind = "portal", seconds = 0 } } })
assert(finish(partialHeights).totalSeconds == 100 / 7 and partialHeights.walkingExpansionsSkipped == 0,
    "Incomplete heights do not obey the triangle inequality of the 3D distance model")

-- Compare with exhaustive feasible simple paths, including walking, portals,
-- money and consumables. Exercise both metric and non-metric speed models.
local seed = 22117
local function random(n) seed = seed * 48271 % 2147483647; return seed % n + 1 end
for mode = 1, 4 do
    for scenario = 1, 60 do
        local nodes, links, adjacency, pairSpeeds = {}, {}, {}, {}
        for i = 1, 6 do
            nodes[i] = { x = random(100), y = random(100), z = random(10), instanceID = 0,
                region = "mainland", speed = mode == 1 and 7 or random(20), index = i }
            if scenario % 2 == 0 and random(2) == 1 then nodes[i].z = nil end
            adjacency[i], pairSpeeds[i] = {}, {}
            for j = 1, 6 do pairSpeeds[i][j] = random(20) end
        end
        local function canWalk(from, to)
            return mode ~= 4 or to.index == from.index + 1
        end
        local function speed(from, to)
            if mode == 3 then return pairSpeeds[from.index][to.index] end
            return math.min(from.speed, to.speed)
        end
        for i = 1, 6 do
            for j = 1, 6 do
                if i ~= j then
                    if canWalk(nodes[i], nodes[j]) then
                        local dx, dy = nodes[i].x - nodes[j].x, nodes[i].y - nodes[j].y
                        local dz = nodes[i].z and nodes[j].z and nodes[i].z - nodes[j].z or 0
                        adjacency[i][#adjacency[i] + 1] = { target = j,
                            seconds = math.sqrt(dx * dx + dy * dy + dz * dz) / speed(nodes[i], nodes[j]), copper = 0, used = 0 }
                    end
                    if random(3) == 1 then
                        local edge = { from = nodes[i], to = nodes[j], seconds = random(20) - 1,
                            copper = random(4) - 1, resources = { rune = random(2) - 1 }, kind = "portal" }
                        links[#links + 1] = edge
                        adjacency[i][#adjacency[i] + 1] = { target = j, seconds = edge.seconds,
                            copper = edge.copper, used = edge.resources.rune }
                    end
                end
            end
            -- Keep every point present, independently of the random transports.
            links[#links + 1] = { from = nodes[i], to = nodes[i], kind = "portal", seconds = 0 }
        end
        local best, visited, budget, runes = math.huge, {}, random(8) - 1, random(3) - 1
        local function enumerate(node, seconds, copper, used)
            if copper > budget or used > runes or seconds >= best then return end
            if node == 6 then best = seconds; return end
            visited[node] = true
            for _, link in ipairs(adjacency[node]) do
                if not visited[link.target] then
                    enumerate(link.target, seconds + link.seconds, copper + link.copper, used + link.used)
                end
            end
            visited[node] = nil
        end
        enumerate(1, 0, 0, 0)
        local job = engine:CreateSearch({ start = nodes[1], goal = nodes[6], edges = links,
            budget = budget, resources = { rune = runes }, canWalk = canWalk,
            walkingIsTransitive = mode ~= 4,
            walkSpeedAt = mode ~= 3 and function(p) return p.speed end or nil,
            walkSpeedFor = mode == 3 and speed or nil })
        local actual = finish(job)
        assert((best == math.huge and not actual) or (actual and math.abs(actual.totalSeconds - best) < 1e-8),
            "Walking oracle mismatch in mode " .. mode .. ", scenario " .. scenario)
    end
end
print("Walking optimization: linear dense expansion, cached speeds, mixed/pair-speed safety and 240 exhaustive resource-constrained oracles passed")
