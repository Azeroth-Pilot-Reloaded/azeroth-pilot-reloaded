-- Consultations are optional prefixes; they cannot displace a proved faster trip.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile = "forever"

local function scenario(options)
    options = options or {}
    local data = fixture:Load({connections = {}})
    local lib = LibStub("LibAPRNavigation-1.0")
    local function point(x, y)
        return data:NormalizeLocation({instanceID = 0, uiMapID = 501, x = x, y = y})
    end
    local state = {revision = 1, roadSeconds = 100, cancellations = 0, probes = 0, preparations = 0}
    state.start, state.goal, state.master = point(0, 0), point(100, 0), point(20, 0)
    data.HasRoadData = function(_, from, to)
        return from == nil or from.instanceID == 0 and (not to or to.instanceID == 0)
    end
    data.GetRoadRevision = function() return state.revision end
    data.CreateRoadRoute = function(_, request)
        local revision, ticks = state.revision, 0
        local consultation = request.goal.x == state.master.x and request.goal.y == state.master.y
        local seconds = consultation and (options.masterSeconds or 10) or state.roadSeconds
        return {
            Step = function(self)
                assert(revision == state.revision, "An obsolete road job must be cancelled before resuming")
                ticks = ticks + 1
                if ticks < 3 then return "planning" end
                if consultation and options.missingMaster then
                    self.reason = "unproved_master_approach"
                    return "missing_data"
                end
                return "ready", {totalSeconds = seconds, segments = {{
                    kind = "walk", road = true, movementMode = "ground", from = request.start,
                    to = request.goal, seconds = seconds, polyline = {request.start, request.goal},
                }}}
            end,
            Cancel = function() state.cancellations = state.cancellations + 1 end,
        }
    end
    local portal = {kind = "portal", id = "invented-alternative", from = state.start, to = state.goal, seconds = 50}
    data.CreateEdgeBuild = function()
        return {Step = function() return "ready", {portal}, {resources = {}} end}
    end
    local taxiData = {BuildEdges = function() return {} end}
    if options.probe then
        taxiData.CreateProbeSearch = function()
            state.probes = state.probes + 1
            return {Step = function()
                return "ready", {from = state.master, fromNodeID = 7, toNodeID = 9,
                    estimatedSeconds = 40, approachSeconds = 20}
            end}
        end
    end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local request = {
        data = data, engine = lib.Engine, taxiData = taxiData,
        start = state.start, goal = state.goal, walkSpeed = 1, walkingIsTransitive = true,
        canWalk = function(from, to) return data:CanWalk(from, to) end,
        prepareSegment = function(segment) return segment end,
        probeSegments = function(probe)
            return {
                {kind = "walk", from = state.start, to = probe.from},
                {kind = "verify_taxi", from = probe.from, to = probe.from,
                    fromNodeID = probe.fromNodeID, toNodeID = probe.toNodeID},
            }
        end,
    }
    if options.prepare then
        request.adapter = {CreatePreparation = function()
            state.preparations = state.preparations + 1
            local ticks = 0
            return {
                Step = function() ticks = ticks + 1; return ticks < 3 and "planning" or "ready" end,
                Cancel = function() state.cancellations = state.cancellations + 1 end,
            }
        end}
    end
    state.job = APR.NavigationPlanner:Create(request)
    return state
end

local function finish(state)
    for _ = 1, 20000 do
        local status, result = state.job:Step(2, 1)
        if status ~= "planning" then return status, result end
    end
    error("Road consultation planning did not finish")
end

local function provedAlternative(state)
    local status, result = finish(state)
    assert(status == "ready", "A failed optional consultation cannot fail a reachable objective")
    assert(result.totalSeconds == 50 and #result.queue == 1 and result.queue[1].kind == "portal",
        "Retain the proved faster journey after rejecting a consultation")
    return result
end

local state = scenario({probe = true, missingMaster = true})
provedAlternative(state)
assert(not state.job.waitingData and state.probes == 1,
    "An unavailable optional master must not turn a complete itinerary into waiting_data")

state = scenario({probe = true, masterSeconds = 500})
provedAlternative(state)
assert(state.probes == 1)

-- Recheck the whole optimistic estimate, not only whether approaching the
-- master costs less than the complete alternative: 30 + 20 ties the portal.
state = scenario({probe = true, masterSeconds = 30})
provedAlternative(state)

state = scenario({probe = true, masterSeconds = 10})
local status, result = finish(state)
assert(status == "ready" and result.totalSeconds == 10)
assert(#result.queue == 2 and result.queue[1].road and result.queue[1].seconds == 10)
assert(result.queue[2].kind == "verify_taxi" and result.queue[2].fromNodeID == 7
    and result.queue[2].toNodeID == 9, "Preserve consultation identity after refining its approach")
assert(state.job.request.goal == state.goal and state.goal.x == 100,
    "A consultation prefix does not replace the original objective")

-- A registration can change before the first scheduler slice, before any
-- catalogue or taxi metadata exists.
state = scenario()
state.revision = 2
result = provedAlternative(state)
assert(result.roadRevision == 2)

-- A source change during preparation must restart that cancelled preparation,
-- rather than entering road/terrain work before providers have been built.
state = scenario({prepare = true})
assert(state.job:Step(1, 1) == "planning" and state.preparations == 1)
state.revision = 2
result = provedAlternative(state)
assert(result.roadRevision == 2 and state.preparations == 2 and state.cancellations >= 1)

-- Retire the consultation flag as well as the corridor. Otherwise a new
-- ordinary road leg bypasses comparison with the faster portal.
state = scenario({probe = true, masterSeconds = 500})
for _ = 1, 20000 do
    assert(state.job:Step(1, 1) == "planning")
    if state.job.roadProbe and state.job.phase == "road_verify" and state.job.active then break end
end
assert(state.job.roadProbe and state.job.active)
state.revision, state.roadSeconds = 2, 80
result = provedAlternative(state)
assert(result.roadRevision == 2 and state.probes == 2 and state.cancellations >= 1,
    "Source replacement must cancel the old approach and repeat consultation eligibility")

-- Newly available native collision coverage takes authority over a previously
-- accepted road corridor. A road cache must not bypass that new managed scope.
state = scenario()
state.roadSeconds = 30
local data = state.job.request.data
local native, terrainRevision = false, 1
data.HasTerrainData = function() return true end
data.GetTerrainRevision = function() return terrainRevision end
data.RequiresTerrainRoute = function() return native end
data.GetRequiredTerrainScopes = function()
    return native and {[0] = {sealed = true}} or {}, {}
end
data.GetTerrainScopeNeighbors = function() return {} end
data.CreateTerrainEdgeBuild = function()
    local observed = terrainRevision
    return {Step = function()
        return "ready", {}, {revision = observed,
            canWalk = function(from, to) return not native and data:CanWalk(from, to) end}
    end}
end
data.CreateLocalExitCheck = function() return {Step = function() return "ready", {} end} end
state.job = APR.NavigationPlanner:Create(state.job.request)
for _ = 1, 20000 do
    assert(state.job:Step(1, 1) == "planning")
    if state.job.phase == "queue" then break end
end
assert(state.job.phase == "queue" and state.job.result.totalSeconds == 30)
native, terrainRevision = true, 2
result = provedAlternative(state)
assert(result.terrainRevision == 2 and not result.queue[1].road,
    "Replace an old road proof when native terrain no longer permits its walk")

print("Road consultations: unavailable/slow approaches, estimate ties, valid prefixes, early/road/native replacement and cancellation passed")
