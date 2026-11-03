-- Refine competitive walks before comparing them with transport costs.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile = "forever"
local data = fixture:Load({connections = {}})
local lib = LibStub("LibAPRNavigation-1.0")
local function point(x, y)
    return data:NormalizeLocation({instanceID = 0, uiMapID = 501, x = x, y = y})
end
local a, b = point(0, 0), point(100, 0)
local revision, roadSeconds, calls, cancelled = 1, 300, 0, 0
data.HasRoadData = function(_, first, last)
    return first == nil or first.instanceID == 0 and (not last or last.instanceID == 0)
end
data.GetRoadRevision = function() return revision end
local unavailable
data.CreateRoadRoute = function(_, request)
    calls = calls + 1
    local ticks, duration, sourceRevision = 0, roadSeconds, revision
    return {
        Step = function(self)
            ticks = ticks + 1
            if ticks < 3 then return "planning" end
            if unavailable then self.reason = "unknown_road_attachment"; return "missing_data" end
            assert(sourceRevision == revision, "The planner must cancel a route from an obsolete registration")
            return "ready", {segments = {{kind = "walk", road = true, movementMode = "ground",
                from = request.start, to = request.goal, seconds = duration,
                polyline = {request.start, point(0, 100), point(100, 100), request.goal}}}, totalSeconds = duration}
        end,
        Cancel = function() cancelled = cancelled + 1 end,
    }
end
local portal = {kind = "portal", from = a, to = b, id = "invented-portal", seconds = 150}
data.CreateEdgeBuild = function()
    return {Step = function() return "ready", portal and {portal} or {}, {resources = {}} end}
end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local function job()
    return APR.NavigationPlanner:Create({data = data, engine = lib.Engine,
        start = a, goal = b, walkSpeed = 1, walkingIsTransitive = true,
        taxiData = {BuildEdges = function() return {} end},
        canWalk = function(from, to) return data:CanWalk(from, to) end,
        prepareSegment = function(segment) return segment end})
end
local function finish(value)
    for _ = 1, 20000 do
        local status = value:Step(4, 1)
        if status ~= "planning" then return status, value:GetResult() end
    end
    error("Road refinement failed to finish")
end
local planning = job()
revision = revision + 1 -- A source may arrive before preparation's first slice.
local status, result = finish(planning)
assert(status == "ready" and result.totalSeconds == 150)
assert(calls == 1 and result.segments[1].kind == "portal",
    "The real 300-second road detour must lose to the 150-second portal")

portal.seconds = 400
planning = job()
status, result = finish(planning)
assert(status == "ready" and result.totalSeconds == 300)
assert(#result.segments == 1 and result.segments[1].road and #result.segments[1].polyline == 4)
assert(result.roadRevision == revision and result.queue[1].road,
    "Preserve the actual corridor in the prepared guidance queue")

-- Replacement during a coroutine cannot publish a previous source revision.
planning = job()
while planning.phase ~= "road_verify" or not planning.active do
    assert(planning:Step(1, 1) == "planning")
end
revision, roadSeconds = revision + 1, 80
status, result = finish(planning)
assert(status == "ready" and result.totalSeconds == 80 and result.roadRevision == revision)
assert(cancelled > 0)

-- An unknown attachment is never silently converted to a straight walk.
portal, unavailable = nil, true
planning = job()
status = finish(planning)
assert(status == "no_path" and planning.waitingData and planning.roadReason == "unknown_road_attachment")

unavailable = false
planning = job()
while planning.phase ~= "road_verify" or not planning.active do
    assert(planning:Step(1, 1) == "planning")
end
local before = cancelled
planning:Cancel()
assert(planning:Step(100, 1) == "cancelled" and cancelled == before + 1)
print("Road planner: true directed costs, transport competition, corridor preservation, source replacement and cancellation passed")
