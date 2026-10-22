-- Preparation must yield before route search starts, including a cold DB2 index.
local function noop() end
function LibStub()
    return { GetText = function(_, key) assert(key == "USE_FLIGHTPATH"); return "Fly to %s" end, GetLocale = function()
        return { USE_FLIGHTPATH = "Fly to %s", NAVIGATION_CONSULT_TAXI = "Consult the flight master" }
    end }
end
function CreateFrame() return { SetScript = noop } end
APR = { PlayerID = "budget-test" }
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
APRData = { [APR.PlayerID] = {} }

local discovered, unavailable, paths = {}, {}, {}
local positionReads, availabilityReads, nameReads = 0, 0, 0
local source = { profile = "retail", build = "test", paths = { fingerprint = "first" } }
for id = 1, 200 do discovered[id] = true end
for id = 1, 4000 do
    local from = ((id - 1) % 200) + 1
    local offset = math.floor((id - 1) / 200) + 1
    paths[id] = {
        fromNodeID = from, toNodeID = ((from + offset - 1) % 200) + 1,
        durationSeconds = 30, basePriceCopper = 50,
    }
end
function APR:HasTaxiNode(nodeID) return discovered[nodeID] == true end
LibTaxiData_API = {
    GetSource = function() return source end,
    GetAllPaths = function() return paths end,
    GetNodeWorldPosition = function(nodeID)
        positionReads = positionReads + 1
        return { x = nodeID * 100, y = 0, z = 0, instanceID = 0, uiMapID = 100 }
    end,
    GetNodeName = function(nodeID)
        nameReads = nameReads + 1
        return "Node " .. nodeID
    end,
    IsNodeAvailable = function(nodeID)
        availabilityReads = availabilityReads + 1
        return not unavailable[nodeID]
    end,
}
dofile("APR-Core/features/navigation/NavigationTaxi.lua")
local taxi = APR.taxiData

local function Complete(job, maxOperations)
    local state, result, metadata
    local slices, maximumMilliseconds = 0, 0
    repeat
        local started = os.clock()
        state, result, metadata = job:Step(maxOperations or 64, 1)
        maximumMilliseconds = math.max(maximumMilliseconds, (os.clock() - started) * 1000)
        slices = slices + 1
        assert(slices < 20000, "A bounded job must eventually finish")
    until state ~= "planning"
    assert(state == "ready", "The fixture must finish without cancellation")
    return result, metadata, slices, maximumMilliseconds
end

local clockMilliseconds = 0
local fakeClock = function()
    clockMilliseconds = clockMilliseconds + 0.25
    return clockMilliseconds
end
local job = taxi:CreateEdgeBuild({ clock = fakeClock })
assert(job.operations == 0 and positionReads == 0 and availabilityReads == 0,
    "Creating a job must not scan or project the network")
assert(job:Step(1000, 0) == "planning" and job.operations == 0,
    "An exhausted shared budget must not start another operation")
assert(job:Step(1000, 1) == "planning" and job.operations <= 3,
    "The cold index must honor the clock even when the operation allowance is large")
job:Cancel()
assert(job:Step(1000, 1) == "cancelled", "Cancellation must stop preparation immediately")

local wallClock = function() return os.clock() * 1000 end
local started = os.clock()
local edges, metadata, slices, maximum = Complete(taxi:CreateEdgeBuild({ clock = wallClock }))
assert(#edges == 4000 and not metadata.taxiUnavailable)
assert(positionReads == 200 and availabilityReads == 200 and nameReads == 200,
    "Shared endpoints should be projected, checked and named once per node")
print(string.format("Taxi cold build: 4000 paths, %.2fms total, %d slices, %.3fms largest slice",
    (os.clock() - started) * 1000, slices, maximum))

local positionsBefore, namesBefore = positionReads, nameReads
started = os.clock()
local warmEdges, _, warmSlices, warmMaximum = Complete(taxi:CreateEdgeBuild({ clock = wallClock }))
assert(warmEdges == edges, "An unchanged character graph should reuse its edge tables")
assert(positionReads == positionsBefore and nameReads == namesBefore,
    "Replanning must not repeat static map projection or name API calls")
assert(availabilityReads == 400, "Discovery and access must still be checked before reusing a graph")
print(string.format("Taxi warm build: %.2fms total, %d slices, %.3fms largest slice",
    (os.clock() - started) * 1000, warmSlices, warmMaximum))

discovered[2] = nil
local fewerEdges = Complete(taxi:CreateEdgeBuild())
assert(#fewerEdges < #edges and fewerEdges ~= edges, "Discovery changes invalidate graph reuse")
for _, edge in ipairs(fewerEdges) do
    assert(edge.fromNodeID ~= 2 and edge.toNodeID ~= 2, "Undiscovered nodes cannot remain in cached edges")
end
discovered[2], unavailable[3] = true, true
fewerEdges = Complete(taxi:CreateEdgeBuild())
for _, edge in ipairs(fewerEdges) do
    assert(edge.fromNodeID ~= 3 and edge.toNodeID ~= 3, "Changed client restrictions must also invalidate reuse")
end
unavailable[3] = nil

local data = taxi:GetCharacterData()
data.durations["1>2"] = { seconds = 45 }
taxi:InvalidateEdges()
local measuredEdges = Complete(taxi:CreateEdgeBuild())
local measured
for _, edge in ipairs(measuredEdges) do if edge.pathID == 1 then measured = edge end end
assert(measured and measured.seconds == 60, "A new confirmed measurement must replace its estimate")
assert(positionReads == positionsBefore, "A duration correction must preserve valid static positions")

local stale = taxi:CreateEdgeBuild()
stale:Step(1)
paths[1].basePriceCopper = 99
source.paths.fingerprint = "same-build-price-change"
assert(stale:Step(1) == "cancelled", "A changed data snapshot must cancel an unfinished graph")
local corrected = Complete(taxi:CreateEdgeBuild())
for _, edge in ipairs(corrected) do
    if edge.pathID == 1 then
        assert(edge.copper == 99 and edge.seconds == 45,
            "Same-build imports refresh fares and isolate measurements by fingerprint")
    end
end

-- A partially built pair index must survive cancellation without double counts.
taxi:InvalidateStaticCache()
local interrupted = taxi:CreateEdgeBuild()
interrupted:Step(1)
interrupted:Cancel()
data = taxi:GetCharacterData()
data.durations["1>2"] = { seconds = 40 }
local resumed = Complete(taxi:CreateEdgeBuild())
for _, edge in ipairs(resumed) do
    if edge.pathID == 1 then assert(edge.seconds == 55, "Resuming an index must preserve unique-path measurements") end
end

local walkChecks = 0
local options = {
    contextKey = "probe-budget", walkSpeed = 7, clock = fakeClock,
    canWalk = function() walkChecks = walkChecks + 1; return true end,
}
local start, goal = { x = 100, y = 0, instanceID = 0 }, { x = 20000, y = 0, instanceID = 0 }
local probe = taxi:CreateProbeSearch(start, goal, math.huge, options)
assert(probe.operations == 0, "Probe creation must not scan the network")
assert(probe:Step(1000, 1) == "planning" and probe.operations <= 3,
    "Exploratory fallback must obey the same clock budget as graph preparation")
local candidate = Complete(probe, 64)
assert(candidate and candidate.kind == "verify_taxi")
assert(walkChecks <= 400, "Approach and exit access should be computed once per node, not per flight")

Enum = { FlightPathState = { Current = 0, Reachable = 1, Unreachable = 2 } }
local price = 25
function TaxiNodeCost() return price end
function GetNumRoutes() return 1 end
function TaxiGetNodeSlot() return 2 end
local liveNodes = { { nodeID = 1, slotIndex = 1, state = 0 }, { nodeID = 2, slotIndex = 2, state = 1 } }
taxi:ObserveTaxiMap(liveNodes)
local firstFare = Complete(taxi:CreateEdgeBuild())
price = 10
local secondFare = Complete(taxi:CreateEdgeBuild())
assert(secondFare ~= firstFare, "Live fares must never reuse a previous prepared graph")
for _, edge in ipairs(secondFare) do if edge.pathID == 1 then assert(edge.copper == 10) end end
local closing = taxi:CreateEdgeBuild()
closing:Step(1)
taxi:CloseTaxiMap()
assert(closing:Step(1) == "cancelled", "Closing a taxi map invalidates unfinished quote-based work")

assert(not taxi:CanProbeBeat(0) and not taxi:CanProbeBeat(15) and taxi:CanProbeBeat(15.01)
    and taxi:CanProbeBeat(math.huge) and taxi:CanProbeBeat(nil),
    "Only routes longer than boarding, or a missing route, need exploratory taxi work")
local availableBefore = availabilityReads
local shortProbe = taxi:CreateProbeSearch(start, goal, 15, options)
assert(Complete(shortProbe) == nil and shortProbe.operations == 1 and availabilityReads == availableBefore,
    "A route within boarding time must finish without checking any taxi nodes")

-- Only the closest master can beat this short route. Its 20 outgoing paths
-- are enough; the other 3,980 paths have already lost on approach time.
walkChecks = 0
local nearbyGoal = { x = 200, y = 0, instanceID = 0 }
local nearProbe = taxi:CreateProbeSearch(start, nearbyGoal, 20, options)
assert(Complete(nearProbe) == nil)
assert(nearProbe.operations <= 225,
    "Near an objective, probe work must scale with masters rather than every DB2 path")
assert(availabilityReads - availableBefore <= 200 and walkChecks <= 220,
    "Origin groups and shared destinations must not repeat discovery or ground-access checks")
print(string.format("Taxi near-objective probe: %d operations for 4000 paths", nearProbe.operations))

-- Missing fares and timings still deserve a visit when they could improve
-- the journey. Pruning is based on a lower bound, not complete static data.
paths[1].basePriceCopper, paths[1].durationSeconds = nil, nil
taxi:GetCharacterData().durations["1>2"] = nil
taxi:InvalidateStaticCache()
Complete(taxi:CreateEdgeBuild())
local unknown = taxi:CreateProbeSearch(start, nearbyGoal, 25, options)
local unknownCandidate = assert(Complete(unknown))
assert(unknownCandidate.fromNodeID == 1 and unknownCandidate.toNodeID == 2 and unknown.operations <= 225,
    "An unknown-fare path must remain eligible without scanning unrelated departures")
taxi:MarkProbeAttempt(1, 2, options.contextKey)
assert(Complete(taxi:CreateProbeSearch(start, nearbyGoal, 25, options)) == nil,
    "The grouped search must still suppress repeated visits to an already tried offer")
options.contextKey = "inaccessible-probe"
options.canWalk = function() return false end
local inaccessible = taxi:CreateProbeSearch(start, nearbyGoal, math.huge, options)
assert(Complete(inaccessible) == nil and inaccessible.operations <= 201,
    "Inaccessible masters must reject their entire outgoing groups")
print("Taxi preparation budgets, cancellation, reuse and invalidation: OK")
