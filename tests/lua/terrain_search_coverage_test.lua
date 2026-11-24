local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Search.lua")
local walker = F.provider(lib)
local jobs, lookups = {}, {}
for _, name in ipairs({ "CreateCostJob", "CreatePathJob" }) do
    local create = walker[name]
    walker[name] = function(self, from, ...)
        local world = from.instanceID
        jobs[world] = (jobs[world] or 0) + 1
        return create(self, from, ...)
    end
end
local hasMap = walker.HasMap
function walker:HasMap(world)
    lookups[world] = (lookups[world] or 0) + 1
    return hasMap(self, world)
end

local function finish(request)
    request.walkingProvider = walker
    request.walkSpeed = 7
    request.walkingSpeedCeiling = 7
    request.clock = function() return 0 end
    local search = lib.Engine:CreateSearch(request)
    local work = 0
    while search.status == "planning" do
        search:Step(32)
        assert(search.workLastStep <= 32)
        work = work + search.workLastStep
        assert(work < 200000)
    end
    local result, status = search:GetResult()
    return result, status, work
end

local function station(x, y, access)
    return { instanceID = 800, x = x, y = y, region = "station", accessKey = access or "east" }
end

local start, boarding = station(0, 0), station(700, 0)
local landing, goal = F.point(1, 1, 0), F.point(3, 1, 0)
landing.region, goal.region = "city", "city"
local edges = { { id = "exit", kind = "passage", from = boarding, to = landing, seconds = 5 } }
for index = 1, 100 do
    local point = station(index * 6, index % 7)
    edges[#edges + 1] = { from = point, to = point, kind = "portal", seconds = 500 }
end
for _, batch in ipairs({ false, true }) do
    jobs, lookups = {}, {}
    local result, status, work = finish({ start = start, goal = goal, edges = edges, batchTerrainWork = batch })
    assert(status == "ready" and #result.segments == 3)
    F.near(result.totalSeconds, 105 + 2 * F.cellSize / 7)
    assert(result.segments[1].to == boarding and not result.segments[1].path)
    assert(result.segments[2].id == "exit")
    local path = result.segments[3].path
    assert(path and path[1].x == landing.x and path[#path].x == goal.x)
    assert(not jobs[start.instanceID] and jobs[landing.instanceID], "Only the covered world needs terrain jobs")
    assert(lookups[start.instanceID] == 1, "Coverage is observed once per world per search")
    assert(work < 2000, "The estimated approach must skip redundant walks in a dense station")
end

jobs = {}
local result = finish({
    start = start,
    goals = { station(1, 0, "west"), station(14, 0) },
    batchTerrainWork = true,
    serviceWalking = true,
})
assert(result.goalIndex == 2 and result.totalSeconds == 2 and not jobs[start.instanceID],
    "A nearer service across a separate access area cannot use the estimated walk")

local _, status = finish({ start = start, goal = station(14, 0), requireVerifiedWalks = true })
assert(status == "waiting_data" and jobs[start.instanceID],
    "An explicit proof requirement must still refuse unverified walks")
