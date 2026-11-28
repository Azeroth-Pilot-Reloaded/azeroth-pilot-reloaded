local library = dofile("tests/lua/navigation_engine_fixture.lua")
function LibStub() return library end
dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")
dofile("APR-Core/libs/LibAPRNavigation-1.0/ZoneRouting.lua")
dofile("APR-Core/libs/LibAPRNavigation-1.0/ZoneGraph.lua")
APR = {}
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local a = {x = 0, y = 0, instanceID = 1, uiMapID = 1, region = "outside"}
local b = {x = 1, y = 0, instanceID = 1, uiMapID = 1, region = "outside"}
local c = {x = 4, y = 0, instanceID = 1, uiMapID = 1, region = "outside"}
local p = {batches = 0, paths = 0}
function p:CreateCostJob(from, targets)
    self.batches = self.batches + 1
    local costs = {}
    for i, target in ipairs(targets) do
        costs[i] = {state = "ready", seconds = target.x == 1 and 80 or 4, yards = 100}
    end
    return {Step = function() return "ready", {costs = costs} end}
end
function p:CreatePathJob(from, to)
    self.paths = self.paths + 1
    return {Step = function() return "ready", {path = {from, {x = 0, y = 20, instanceID = 1}, to}} end}
end
local function finish(job)
    for _ = 1, 3000 do
        local status, result = job:Step(4, 1)
        if status ~= "planning" then return status, result end
    end
    error("Planner pipeline did not finish")
end
local data = setmetatable({env = {}, config = {}}, {__index = library.Instance})
function data:CanWalk() return true end
function data:CreateEdgeBuild() return {Step = function() return "ready", {}, {resources = {}} end} end
local taxi = {CreateEdgeBuild = data.CreateEdgeBuild}
local zoneCalls, probes = 0, 0
local zone = data.CreateZoneRoute
function data:CreateZoneRoute(request) zoneCalls = zoneCalls + 1; return zone(self, request) end
function taxi:CreateProbeSearch(_, _, _, options)
    probes = probes + 1
    assert(options.walkingProvider == p, "Taxi exploration retains terrain context")
    return {Step = function() return "ready" end}
end
local request = {start = a, goal = b, data = data, taxiData = taxi, engine = library.Engine,
    preferZoneAccess = true, walkingProvider = p, canWalk = function() return true end,
    prepareSegment = function(segment) return segment end}
local status, result = finish(APR.NavigationPlanner:Create(request))
assert(status == "ready" and result.totalSeconds == 80 and #result.queue[1].path == 3,
    "Nearby authored objectives go through terrain costs and path materialization")
assert(zoneCalls == 0 and probes == 1, "Provider requests bypass zone shortcuts and retain terrain-aware taxi exploration")
assert(data:CreateZoneRoute(request):Step(1, 1) == "fallback",
    "A direct zone API caller cannot receive an unpriced nearby walk")
assert(data:CreateZoneGraphRoute(request):Step(1, 1) == "fallback",
    "The region topology shortcut cannot collapse terrain-connected endpoints")
local probePath = {a, {x = 0, y = 20, instanceID = 1}, b}
function taxi:CreateProbeSearch(_, _, baseline, options)
    assert(baseline == 80 and options.walkingProvider == p)
    return {Step = function() return "ready", {from = b, estimatedSeconds = 40,
        approachSeconds = 10, approachPath = probePath} end}
end
request.probeSegments = function(probe)
    return {{kind = "walk", from = a, to = probe.from}, {kind = "verify_taxi", from = probe.from, to = probe.from}}
end
status, result = finish(APR.NavigationPlanner:Create(request))
assert(status == "ready" and result.totalSeconds == 40 and result.queue[1].seconds == 10
    and result.queue[1].path == probePath and result.queue[2].kind == "verify_taxi",
    "A winning taxi probe publishes its physical approach polyline through the normal planner queue")
function taxi:CreateProbeSearch()
    return {Step = function() return "ready", {from = b, estimatedSeconds = 40} end}
end
request.probeSegments = function(probe)
    return {{kind = "walk", from = a, to = probe.from, seconds = 11, path = probePath}}
end
status, result = finish(APR.NavigationPlanner:Create(request))
assert(status == "ready" and result.queue[1].seconds == 11 and result.queue[1].path == probePath,
    "External probes without physical fields preserve their existing converted approach metadata")

-- Service selection is based on physical travel: the nearby service has an
-- eighty-second detour, while a farther service takes four seconds.
data.profile = "forever"
data.serviceLocations = {
    {service = "inn", npcID = 1, mapID = 1, x = 1, y = 0},
    {service = "inn", npcID = 2, mapID = 1, x = 4, y = 0},
}
function data:NormalizeLocation(value)
    return {x = value.x * 100, y = value.y * 100, instanceID = 1, uiMapID = 1, region = "outside"}
end
local function find(options)
    options.start, options.query, options.walkSpeed = a, {service = "inn"}, 1
    return finish(data:CreateServiceSearch(options))
end
status, result = find({walkingProvider = p})
assert(status == "ready" and result.record.npcID == 2 and result.totalSeconds == 4
    and #result.itinerary.segments[1].path == 3, "Service ranking retains terrain provider and winning polyline")
function data:GetWalkingProvider() return p end
status, result = find({})
assert(status == "ready" and result.record.npcID == 2,
    "Service consumers obtain the active data provider when no explicit request provider is supplied")
data.GetWalkingProvider = nil
status, result = find({})
assert(status == "ready" and result.record.npcID == 1 and result.totalSeconds == 1,
    "Service behavior stays unchanged when no terrain provider exists")

-- Diagnostic searches must not manufacture a reachable locked gate across a
-- proven terrain disconnect.
local seen = {}
local failingEngine = {CreateSearch = function(_, options)
    seen[#seen + 1] = options.walkingProvider
    return {Step = function() return "no_path" end, GetResult = function() end}
end}
request = {start = a, goal = c, data = {
    CreateEdgeBuild = function() return {Step = function() return "ready", {}, {blockedEdges = {{id = "locked"}}} end} end,
}, taxiData = {CreateEdgeBuild = data.CreateEdgeBuild}, engine = failingEngine, walkingProvider = p}
assert(finish(APR.NavigationPlanner:Create(request)) == "no_path")
assert(#seen == 2 and seen[1] == p and seen[2] == p, "Normal and relaxed blocker searches share terrain permissions")
print("Terrain planner pipeline: zone bypass, diagnostics, service ranking, implicit provider and unchanged fallback passed")
