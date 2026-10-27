-- Personal actions can leave a phased world, then walk through a dense mainland.
-- Keep every cooldown in the result without multiplying equivalent frontiers.
local engine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
local function point(id, x, world)
    return { x = x or 0, y = 0, instanceID = world or id, uiMapID = id, region = "outdoor" }
end
local function finish(request, bound)
    local search = engine:CreateSearch(request)
    local operations = 0
    while search.status == "planning" do
        search:Step(32)
        assert(search.workLastStep <= 32)
        operations = operations + search.workLastStep
        assert(operations < (bound or 100000), "Personal actions must not multiply the frontier without bound")
    end
    return search:GetResult(), search, operations
end
local start, goal = point(9), point(10, 10000, 0)
local points, edges, resources, checks = {}, {}, {}, 0
for i = 1, 80 do points[i] = point(10, i * 100, 0) end
for i = 1, 18 do
    local key = "cooldown:" .. i
    resources[key] = 1
    edges[#edges + 1] = { id = "teleport" .. i, kind = "spell", from = start, to = points[i],
        sourceFree = true, seconds = 10, resources = { [key] = 1 },
        canStart = function() checks = checks + 1; return true end }
end
for i = 19, 80 do
    edges[#edges + 1] = { from = points[i], to = points[i], kind = "portal", seconds = 999 }
end
local result, search, work = finish({ start = start, goal = goal, edges = edges,
    resources = resources, walkSpeed = 60 }, 8000)
assert(result and math.abs(result.totalSeconds - (10 + 8200 / 60)) < 0.000001)
assert(#result.segments == 2 and result.segments[1].id == "teleport18"
    and result.resourcesUsed["cooldown:18"] == 1)
local used = 0
for _ in pairs(result.resourcesUsed) do used = used + 1 end
assert(used == 1 and checks == 18 and search.expansions < 100,
    "Actions usable at the origin are checked once; their unused future cooldowns do not create separate labels")

-- A reagent also needed by a later crossing remains relevant to dominance.
local hub, target = point(2), point(3)
for _, legacyKey in ipairs({ false, true }) do
    local last = { from = hub, to = target, kind = "portal", seconds = 1 }
    if legacyKey then last.resourceKey = "charge" else last.resources = { charge = 1 } end
    result = finish({ start = start, goal = target, canWalk = function() return false end,
        resources = { charge = 1, other = 1 }, edges = {
            { id = "fast", from = start, to = hub, sourceFree = true, kind = "spell", seconds = 1,
                resources = { charge = 1 } },
            { id = "preserve", from = start, to = hub, sourceFree = true, kind = "spell", seconds = 4,
                resources = { other = 1 } }, last,
        } })
    assert(result.totalSeconds == 5 and result.segments[1].id == "preserve"
        and result.resourcesUsed.charge == 1 and result.resourcesUsed.other == 1,
        "A slower arrival that preserves a shared resource must remain usable")
end

-- A spell unavailable at the origin must still become usable after a real leg.
result = finish({ start = start, goal = target, canWalk = function() return false end,
    resources = { first = 1, second = 1 }, edges = {
        { from = start, to = hub, sourceFree = true, kind = "spell", seconds = 3, resources = { first = 1 } },
        { from = start, to = target, sourceFree = true, kind = "spell", seconds = 2, resources = { second = 1 },
            canStart = function(at) return at.uiMapID == 2 end },
    } })
assert(result.totalSeconds == 5 and #result.segments == 2
    and result.segments[2].from.uiMapID == 2 and result.resourcesUsed.first == 1)

-- Compare with exhaustive feasible simple paths, independently expanding each
-- action at every allowed origin. Costs are positive and resources never grow,
-- so revisiting a node cannot improve a feasible route.
local seed = 87132
local function random(n) seed = seed * 48271 % 2147483647; return seed % n + 1 end
for scenario = 1, 160 do
    local nodes, links, adjacency = {}, {}, {}
    local capacities = { shared = random(2), a = 1, b = 1 }
    local budget = random(7) - 1
    for i = 1, 5 do nodes[i], adjacency[i] = point(i), {} end
    local function register(edge, origins)
        links[#links + 1] = edge
        for _, from in ipairs(origins) do
            adjacency[from][#adjacency[from] + 1] = edge
        end
    end
    for action = 1, 2 do
        local permitted, origins = {}, {}
        for from = 1, 5 do
            if random(3) ~= 1 then permitted[from] = true; origins[#origins + 1] = from end
        end
        local key, destination = action == 1 and "a" or "b", random(4) + 1
        register({ from = nodes[1], to = nodes[destination], targetIndex = destination,
            sourceFree = true, kind = "spell", seconds = random(8), copper = random(3) - 1,
            resources = { [key] = 1, shared = random(2) - 1 },
            canStart = function(at) return permitted[at.uiMapID] == true end }, origins)
    end
    for from = 1, 5 do
        for to = 1, 5 do
            if from ~= to and random(3) == 1 then
                register({ from = nodes[from], to = nodes[to], targetIndex = to, kind = "portal",
                    seconds = random(9), copper = random(3) - 1,
                    resources = { shared = random(2) - 1, a = random(3) == 1 and 1 or 0 } }, { from })
            end
        end
    end
    local best, visited = math.huge, { [1] = true }
    local function enumerate(at, seconds, copper, usage)
        if at == 5 then best = math.min(best, seconds); return end
        for _, edge in ipairs(adjacency[at]) do
            local destination, nextCopper = edge.targetIndex, copper + edge.copper
            if not visited[destination] and nextCopper <= budget then
                local nextUsage, allowed = {}, true
                for key, capacity in pairs(capacities) do
                    nextUsage[key] = (usage[key] or 0) + (edge.resources[key] or 0)
                    if nextUsage[key] > capacity then allowed = false end
                end
                if allowed then
                    visited[destination] = true
                    enumerate(destination, seconds + edge.seconds, nextCopper, nextUsage)
                    visited[destination] = nil
                end
            end
        end
    end
    enumerate(1, 0, 0, {})
    local actual = finish({ start = nodes[1], goal = nodes[5], edges = links,
        resources = capacities, budget = budget, canWalk = function() return false end })
    if best == math.huge then assert(not actual, "An infeasible action graph must stay unreachable")
    else
        assert(actual and actual.totalSeconds == best, "Action pruning must match exhaustive feasible paths")
        for key, amount in pairs(actual.resourcesUsed) do assert(amount <= capacities[key]) end
    end
end
print("Personal action search: bounded phased-world exit, preserved resource usage, shared reagents, later-map spells and 160 exhaustive oracles passed")
