-- Travel labels use localized destinations and only endorse a matching hearth bind.
local L = setmetatable({
    GET_FLIGHTPATH = "Learn flight path", USE_FLIGHTPATH = "Fly to %s",
    USE_BOAT = "Boat to %s", USE_ZEPPELIN_TO = "Zeppelin to %s",
    USE_PORTAL_TO = "Portal to %s", ENTER_TRAM = "Take tram", USE_HEARTHSTONE = "Use hearthstone",
    HS_BIND_MISMATCH = "Current bind: %s; expected zone: %s",
}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
UNKNOWN = "Unknown"
local names = { [2] = "Hurlevent", [8] = "Comte-du-Lac" }
APR = { stepHandlers = {}, ActiveRoute = "route", taxiData = {
    GetNodeName = function(_, id) return names[id] end,
} }
dofile("APR-Core/utils/NavigationUtils.lua")
dofile("APR-Core/utils/StepUtils.lua")
local maps = {
    [10] = { name = "Foret", parentMapID = 100 },
    [11] = { name = "Auberge", parentMapID = 10 },
    [20] = { name = "Desert", parentMapID = 100 },
    [100] = { name = "Continent", parentMapID = 0 },
}
function APR:GetMapInfoCached(id) return maps[id] end
assert(APR:GetFlightPathDiscoveryText({ GetFP = 2, NodeID = 8 }) == "Learn flight path - Hurlevent")
assert(APR:GetFlightPathDiscoveryText({ GetFP = 999 }) == "Learn flight path")
assert(APR:GetStepString({ GetFP = 8 }) == "Learn flight path - Comte-du-Lac")
assert(APR:GetStepString({ UseFlightPath = 42, NodeID = 8 }) == "Fly to Comte-du-Lac")
assert(APR:GetTransportStepText({ UseFlightPath = 42, NodeID = 8,
    ZoneStepTrigger = { mapID = 10 } }) == "Fly to Comte-du-Lac")
assert(APR:GetTransportStepText({ UseFlightPath = 42, NodeID = 999,
    ZoneStepTrigger = { mapID = 10 } }) == "Fly to Foret")
assert(APR:GetTransportStepText({ Boat = true, ZoneStepTrigger = { mapID = 10 } }) == "Boat to Foret")
assert(APR:GetTransportStepText({ Zeppelin = true, NodeID = 8,
    ZoneStepTrigger = { mapID = 10 } }) == "Zeppelin to Comte-du-Lac")
assert(APR:GetTransportStepText({ Boat = true, NodeID = 999,
    ZoneStepTrigger = { mapID = 10 } }) == "Boat to Foret")
assert(APR:GetTransportStepText({ Boat = true, UseFlightPath = 42, Name = "Port" }) == "Boat to Port")
assert(APR:GetTransportStepText({ Zeppelin = true, TakePortal = { mapID = 20 } }) == "Zeppelin to Desert")
assert(APR:GetTransportStepText({ Tram = true, TakePortal = { mapID = 20 } }) == "Take tram - Desert")
assert(APR:GetTransportStepText({ TakePortal = { mapID = 20 } }) == "Portal to Desert")

local bindName, bindMap = "Auberge", 11
function GetBindLocation() return bindName end
function CreateVector2D(x, y) return { x = x, y = y } end
APR.NavigationData = { GetBindLocationMapID = function() return bindMap end }
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone - Auberge")
assert(APR:GetHearthstoneStepText({ Zone = 11 }) == "Use hearthstone - Auberge")
assert(APR:GetHearthstoneStepText({ Zones = { 20, 10 } }) == "Use hearthstone - Auberge")
assert(APR:GetHearthstoneStepText({ Zone = 20 }) == "Use hearthstone\nCurrent bind: Auberge; expected zone: Desert")
assert(APR:GetHearthstoneStepText(nil) == "Use hearthstone")
assert(APR:GetHearthstoneStepText({}) == "Use hearthstone", "No route-zone fallback")
assert(APR:GetHearthstoneStepText({ Boat = true, Zone = 20,
    ZoneStepTrigger = { mapID = 10 } }) == "Use hearthstone\nCurrent bind: Auberge; expected zone: Desert",
    "Compare the next step's departure zone")
assert(APR:GetStepString({ UseHS = 42 }, false, { Zone = 10 }) == "Use hearthstone - Auberge")
bindMap = 20
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone\nCurrent bind: Auberge; expected zone: Foret",
    "Never reuse an old matching bind")
maps[20].mapType = 2
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone", "A continent is too broad to prove a mismatch")
maps[20].mapType = nil
bindMap = nil
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone")
APR.NavigationData = nil
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone")
bindName = "Foret"
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone - Foret")
bindName = ""
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone")
GetBindLocation = nil
assert(APR:GetHearthstoneStepText({ Zone = 10 }) == "Use hearthstone")

-- The live handler reads the following route entry and preserves secure action identity.
function GetBindLocation() return "Foret" end
local steps = { { UseHS = 42 }, { Zone = 10 } }
function APR:GetRouteSteps() return steps end
function APR:GetHearthstoneItemID() return 6948 end
local displayed, button
APR.currentStep = {
    AddQuestSteps = function(_, _, text) displayed = text end,
    AddStepButton = function(_, _, id, kind) button = { id, kind } end,
}
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
APR.stepHandlers.UseHS(steps[1], true, 1)
assert(displayed == "Use hearthstone - Foret" and button[1] == 6948 and button[2] == "item")
steps[2].Zone = 20
APR.stepHandlers.UseHS(steps[1], true, 1)
assert(displayed == "Use hearthstone")
APR.stepHandlers.UseFlightPath({ UseFlightPath = 42, NodeID = 8 }, true, 1)
assert(displayed == "Fly to Comte-du-Lac")
print("Travel labels: localized nodes, transport destinations, matching/missing/mismatched binds and live actions passed")
