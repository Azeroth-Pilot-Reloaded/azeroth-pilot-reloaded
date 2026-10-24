local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
local Lib = LibStub("LibAPRNavigation-1.0")
local completed, unknown, queryIDs = {}, {}, {}
local env = {
    getCharacter = function() return { faction = "Horde", level = 90 } end,
    isQuestCompleted = function(id) queryIDs[id] = true; if not unknown[id] then return completed[id] == true end end,
    getItemCount = function() error("Physical zone routing cannot poll optional items") end,
    getMapInfo = function(id) return { mapType = 2, parentMapID = 0, name = "Map " .. id } end,
}
local function point(id, x)
    return { space = "world", instanceID = 0, uiMapID = id, region = "zone:" .. id, x = x or 0, y = 0 }
end
local function connection(id, from, to, requirements, copper)
    return { id = id, kind = "portal", from = from, to = to, seconds = 5,
        requirements = requirements, copper = copper or 0 }
end
local function makeData(name, connections)
    Lib:RegisterData(name, "physical", { connections = connections }, 1)
    return Lib:New({ profile = name, environment = env })
end
local function walk(_, from, to) return { kind = "walk", from = from, to = to, seconds = 1, copper = 0 } end
local function finish(job)
    local work, slices = 0, 0
    while job.status == "planning" do
        job:Step(8, 1)
        assert((job.workLastStep or 0) <= 8)
        work, slices = work + (job.workLastStep or 0), slices + 1
        assert(slices < 3000)
    end
    return job, work
end
local a, b, c = point(10), point(20), point(30)
local backwards = connection("backwards", c, b)
backwards.bidirectional = true
local connections = {
    connection("gate", a, b, { quest = 1 }), backwards,
    connection("wrong-faction", a, c, { faction = "Alliance", quest = 999 }),
    { id = "optional-item", kind = "item", from = { dynamic = "player" }, to = c,
        actions = { { type = "item", id = 1 } } },
}
for id = 1, 1200 do
    connections[#connections + 1] = connection("unrelated:" .. id, point(1000 + id), point(3000 + id), { quest = 1000 + id })
end
local data = makeData("zone-graph", connections)
local context = { start = a, goal = c, budget = 0 }
local blocked, coldWork = finish(data:CreateZoneGraphRoute(context, walk))
assert(blocked.status == "no_path" and #blocked.metadata.blockers == 1
    and blocked.metadata.blockers[1].id == "zone-graph:gate:forward")
assert(blocked.checkedLinks == 3 and blocked.indexedConnections == #connections and coldWork < 1300,
    "Cold indexing is linear and character queries are limited to reached region links")
assert(queryIDs[1] and not queryIDs[999])
for id in pairs(queryIDs) do assert(id == 1, "Unrelated campaigns must never be polled") end
local graph = data.zoneGraph
completed[1] = true
local ready, warmWork = finish(data:CreateZoneGraphRoute(context, walk))
assert(ready.status == "ready" and #ready.result.segments == 5 and ready.indexedConnections == 0 and warmWork < 30,
    "Every subsequent objective reuses the region index without walking pairs or another catalogue scan")
assert(data.zoneGraph == graph and ready.result.segments[2].id == "zone-graph:gate:forward"
    and ready.result.segments[4].id == "zone-graph:backwards:reverse",
    "Reverse travel preserves the real directed connection and departure validation")

completed[1] = nil
unknown[1] = true
local pending = finish(data:CreateZoneGraphRoute(context, walk))
assert(pending.status == "no_path" and pending.metadata.waitingData,
    "The geometry cache cannot retain another request's character observations")
unknown[1], completed[1] = nil, true
assert(finish(data:CreateZoneGraphRoute({ start = c, goal = a }, walk)).status == "fallback",
    "An explicit one-way portal never implies a return route")

local d = point(40)
local priced = makeData("zone-prices", {
    connection("fast-expensive", a, b, nil, 9), connection("cheap-detour", a, d),
    connection("cheap-arrival", d, b), connection("last-fare", b, c, nil, 5),
})
local affordable = finish(priced:CreateZoneGraphRoute({ start = a, goal = c, budget = 10 }, walk))
assert(affordable.status == "ready" and affordable.result.totalCopper == 5 and #affordable.result.segments == 7,
    "A later cheaper arrival must remain available to pay the final crossing")
assert(finish(priced:CreateZoneGraphRoute({ start = a, goal = c, budget = 4 }, walk)).status == "fallback")

local lockedPoint = point(20, 20)
lockedPoint.noAutoconnect = true
local mandatory = makeData("zone-mandatory", {
    connection("enter", a, lockedPoint), connection("exit", lockedPoint, c),
    connection("wrong-bridge", b, point(99)),
})
assert(#finish(mandatory:CreateZoneGraphRoute(context, walk)).result.segments == 5)
local sealed = makeData("zone-sealed", { connection("enter", a, lockedPoint), connection("wrong-exit", b, c) })
assert(finish(sealed:CreateZoneGraphRoute(context, walk)).status == "fallback",
    "An isolated mandatory point cannot autoconnect to the surrounding region")

local timedTicks = 0
local timed = data:CreateZoneGraphRoute({ start = a, goal = c, clock = function()
    timedTicks = timedTicks + 1; return timedTicks
end }, walk)
assert(timed:Step(0, 1) == "planning" and timedTicks == 0)
assert(timed:Step(1000, 0) == "planning" and timedTicks == 0)
assert(timed:Step(1000, 1) == "planning" and timed.workLastStep == 1)
timed:Cancel()
assert(timed:Step(1000, 1) == "cancelled")
local stale = data:CreateZoneGraphRoute(context, walk)
data:InvalidatePositionCache()
assert(stale:Step(1000, 1) == "cancelled", "Geometry changes invalidate an in-flight topology job")
assert(finish(data:CreateZoneGraphRoute(context, walk)).indexedConnections == #connections)

local available = false
local retryEnv = setmetatable({ mapToWorld = function(_, x, y)
    if available then return 0, x, y end
end }, { __index = env })
Lib:RegisterData("zone-retry", "physical", { connections = {
    connection("late-map", { space = "map", uiMapID = 10, region = "zone:10", x = 0.5, y = 0.5 }, c),
} }, 1)
local retry = Lib:New({ profile = "zone-retry", environment = retryEnv })
assert(finish(retry:CreateZoneGraphRoute(context, walk)).status == "fallback")
local partialGraph = retry.zoneGraph
available = true
local recovered = finish(retry:CreateZoneGraphRoute(context, walk))
assert(recovered.status == "ready" and recovered.indexedConnections == 0 and retry.zoneGraph == partialGraph
    and #partialGraph.pending == 0, "Late geometry retries only unresolved links in the existing index")

local seed = 7291
local function random(n) seed = seed * 48271 % 2147483647; return seed % n + 1 end
for scenario = 1, 60 do
    local points, links, outgoing = {}, {}, {}
    for i = 1, 6 do points[i], outgoing[i] = point(i), {} end
    for from = 1, 6 do
        for to = 1, 6 do
            if from ~= to and random(3) == 1 then
                local fare = random(5) - 1
                links[#links + 1] = connection(from .. ":" .. to, points[from], points[to], nil, fare)
                outgoing[from][#outgoing[from] + 1] = { target = to, copper = fare }
            end
        end
    end
    local budget, best, visited = random(12) - 1, math.huge, {}
    local function enumerate(node, transfers, copper)
        if copper > budget or transfers >= best then return end
        if node == 6 then best = transfers; return end
        visited[node] = true
        for _, link in ipairs(outgoing[node]) do
            if not visited[link.target] then enumerate(link.target, transfers + 1, copper + link.copper) end
        end
        visited[node] = nil
    end
    enumerate(1, 0, 0)
    local sample = makeData("zone-oracle:" .. scenario, links)
    local actual = finish(sample:CreateZoneGraphRoute({ start = points[1], goal = points[6], budget = budget }, walk))
    assert((best == math.huge and actual.status == "fallback") or (actual.status == "ready"
        and (#actual.result.segments - 1) / 2 == best and actual.result.totalCopper <= budget),
        "Transfer oracle mismatch in scenario " .. scenario)
end

-- The host's general zone path must complete without invoking either expensive
-- provider, for both accessible travel and the actual unlock explanation.
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local function plan()
    return finish(APR.NavigationPlanner:Create({ data = data, preferZoneAccess = true, start = a, goal = c,
        budget = 0, walkSpeed = 7, prepareSegment = function(edge) return edge end,
        adapter = { CreatePreparation = function() error("Unexpected inn scan") end },
        taxiData = { BuildEdges = function() error("Unexpected taxi scan") end },
        engine = { CreateSearch = function() error("Unexpected coordinate graph search") end } }))
end
assert(plan().status == "ready")
completed[1] = nil
assert(plan().status == "no_path")
local localRoute = finish(data:CreateZoneRoute({ start = a, goal = point(10, 100), walkSpeed = 7 }))
assert(localRoute.status == "ready" and #localRoute.result.segments == 1,
    "Every local objective uses direct guidance, not only the two manually listed zones")
print("General zone graph: 1204 connections indexed once, <30 warm operations, live gates, reverse links, money labels, mandatory points, budget/cancellation and zero taxi/world/inn scans passed")
