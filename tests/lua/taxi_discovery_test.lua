-- Names come from LibTaxiData; saved state only tracks character discovery.
local function noop() end
function LibStub()
    return { GetLocale = function() return {} end }
end

function CreateFrame()
    return { RegisterEvent = noop, SetScript = function(self, _, callback) self.callback = callback end }
end

UNKNOWN = "Unknown"
APR = { PlayerID = "player", settings = { profile = { enableAddon = true, autoFlight = true } } }
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
function APR:NewModule() return {} end

dofile("APR-Core/features/navigation/NavigationTaxi.lua")
dofile("APR-Core/utils/NavigationUtils.lua")

APRTaxiNodes = {
    player = { [2] = "Old English name", [3] = true, [4] = false },
    other = { [5] = "Another old name" },
}
APR:InitializeTaxiNodes()
APR:InitializeTaxiNodes()
assert(APRTaxiNodes.player[2] == true and APRTaxiNodes.player[3] == true)
assert(APRTaxiNodes.other[5] == true, "Migrate names for all saved characters")
assert(APR:HasTaxiNode(2) and not APR:HasTaxiNode(4) and not APR:HasTaxiNode(5))
APR.PlayerID = "new"
APR:InitializeTaxiNodes()
assert(next(APRTaxiNodes.new) == nil and not APR:HasTaxiNode(2))
APR.PlayerID = "player"

local names = { [2] = "Nom localise", [8] = "Undiscovered destination" }
local reads = 0
LibTaxiData_API = {
    GetNodeName = function(id)
        reads = reads + 1
        return names[id]
    end,
}
for _, method in ipairs({
    "GetAllNodes",
    "GetNode",
    "GetNodeDetails",
    "GetNodeWorldPosition",
    "GetNodeAPRWorldPosition",
    "GetNodeMapPosition",
    "MapToWorld",
    "WorldToMap",
    "FindNearestNodeFromWorld",
    "FindNearestNodeFromAPRWorld",
    "FindNearestNodeFromMap",
    "FindNearestNodeToPlayer",
    "IsNodeAvailable",
    "IsNodeVisible",
    "SetWaypointToNode",
}) do
    LibTaxiData_API[method] = function() error("Name resolution must not query other taxi data") end
end
assert(APR:GetTaxiNodeName({ NodeID = 2, Name = "Route fallback" }) == names[2])
assert(APR:GetTaxiNodeName({ NodeID = 8 }) == names[8] and not APR:HasTaxiNode(8))
names[2] = "Updated locale"
assert(APR:GetTaxiNodeName({ NodeID = 2 }) == names[2] and reads == 3)
assert(APR:GetTaxiNodeName({ NodeID = 999, Name = "Custom destination" }) == "Custom destination")
assert(APR:GetTaxiNodeName({}) == UNKNOWN and APR:GetTaxiNodeName(nil) == UNKNOWN)
LibTaxiData_API = nil
assert(APR:GetTaxiNodeName({ NodeID = 2 }) == UNKNOWN, "Never display a discovery boolean as a name")
assert(APR:GetTaxiNodeName({ NodeID = 2, Name = "Fallback" }) == "Fallback")

Enum = { FlightPathState = { Current = 0, Reachable = 1, Unreachable = 2 } }
function GetTaxiMapID() return 1415 end
function GetMoney() return 100 end
function TaxiNodeCost() return 10 end
function APR:GetGameVersion() return "forever" end

C_TaxiMap = {
    GetAllTaxiNodes = function()
        return {
            { nodeID = 6, name = "Departure", state = 0, slotIndex = 1 },
            { nodeID = 7, name = "Arrival", state = 1, slotIndex = 2 },
            { nodeID = 8, name = "Unavailable", state = 2, slotIndex = 3 },
        }
    end,
}
local taken, advanced = nil, 0
function IsModifierKeyDown() return false end

function TakeTaxiNode(slot) taken = slot end

function APR:NextQuestStep() advanced = advanced + 1 end

APRData = { player = { route = 1 } }
APR.ActiveRoute = "route"
local step = { UseFlightPath = 404, NodeID = 7 }
function APR:GetStep() return step end

dofile("APR-Core/features/navigation/FlightPath.lua")
local frame = APR.flightPath.eventFrame
frame.callback(frame, "TAXIMAP_OPENED")
assert(APR:HasTaxiNode(6) and APR:HasTaxiNode(7) and not APR:HasTaxiNode(8))
assert(taken == 2 and advanced == 0, "Boolean discovery must preserve automatic flight selection")
for _, playerNodes in pairs(APRTaxiNodes) do
    for _, value in pairs(playerNodes) do
        assert(type(value) == "boolean")
    end
end
step.NodeID = 6
frame.callback(frame, "TAXIMAP_OPENED")
assert(advanced == 1, "A flight step at its destination still completes")
step.NodeID, taken = 8, nil
frame.callback(frame, "TAXIMAP_OPENED")
assert(taken == nil, "An unreachable destination must never be selected automatically")
assert(APR.flightPath.unavailableNodes[8] and not APR.flightPath.unavailableNodes[7])
assert(APR.flightPath.unavailableNodes[999] == nil, "An unobserved node has unknown availability")
frame.callback(frame, "TAXIMAP_CLOSED")
assert(next(APR.flightPath.unavailableNodes) == nil, "Availability at one flight master must not persist elsewhere")
assert(APR:HasTaxiNode(7), "Closing the map preserves discovered nodes")
local guidance = { kind = "verify_taxi", fromNodeID = 8, toNodeID = 7, contextKey = "discover" }
APR.taxiData:SetProbeContext(guidance.contextKey)
local replans = 0
APR.navigation = {
    IsNavigating = function() return true end,
    GetActiveStep = function() return guidance end,
    InvalidatePathCache = noop,
    RequestUpdate = function() replans = replans + 1 end,
}
frame.callback(frame, "TAXIMAP_OPENED")
assert(not APR.taxiData.probeAttempts["8:7"] and not APR:HasTaxiNode(8),
    "Opening a different master's map cannot consume the planned discovery detour")
guidance.fromNodeID = 6
APRTaxiNodes.player[6] = nil
local beforeReplan = replans
frame.callback(frame, "TAXIMAP_OPENED")
assert(APR.taxiData.probeAttempts["6:7"] and APR:HasTaxiNode(6) and taken == nil and replans == beforeReplan + 1,
    "Interacting with the intended master records discovery and triggers replanning without buying a flight")
guidance.discoverTaxiNode, guidance.toNodeID, guidance.contextKey = true, nil, "onward-walk"
APR.taxiData:SetProbeContext(guidance.contextKey)
APRTaxiNodes.player[6] = nil
beforeReplan = replans
frame.callback(frame, "TAXIMAP_OPENED")
assert(APR:HasTaxiNode(6) and not next(APR.taxiData.probeAttempts) and taken == nil and replans == beforeReplan + 1,
    "An incidental stop learns the node and resumes planning without offering or buying a flight")
APR.flightPath.unavailableNodes[8] = true
APR.settings.profile.enableAddon = false
frame.callback(frame, "TAXIMAP_CLOSED")
assert(next(APR.flightPath.unavailableNodes) == nil, "Disabled addons must still expire flight-master observations")
print("Taxi discovery: name migration, character isolation, library names, fallbacks and flight selection passed")
