-- Lua 5.1 regression test for repeated Farstrider pathfinding during a zone transition.
local function noop() end
local locale = setmetatable({}, { __index = function(_, key) return key end })
locale.DELVE = "delve"
locale.MUST_BE_IN_SCENARIO = "You must be in %s: %s"
locale.ENTER_IN = "Enter %s: %s"
locale.TRANSPORT_DESTINATION_ERROR = "%s | %s | %s | %s"
local seconds, profileMs = 100, 0
local playerMapID, findTrailCalls = 2393, 0
local metrics = {}
local retryCallbacks = {}
UNKNOWN = "Unknown"

function LibStub()
    return { GetLocale = function() return locale end }
end

function GetTime() return seconds end

function UnitPosition() return nil end

function IsInInstance() return false end

function CreateVector2D(x, y) return { x = x, y = y } end

function CreateFrame()
    return { RegisterEvent = noop, SetScript = noop }
end

APR = {
    ActiveRoute = "2393-Midnight-Speedrun-alt",
    PlayerID = "test",
    HEXColor = { red = "ff3333" },
    Arrow = { MaxDistanceWrongZone = 1000, SetArrowActive = noop },
}
function APR:NewModule() return {} end

function APR:Debug() end

function APR:StartPerformanceSample() return profileMs end

function APR:FinishPerformanceSample(name, started)
    local summary = metrics[name] or { count = 0, totalMs = 0 }
    metrics[name] = summary
    summary.count = summary.count + 1
    summary.totalMs = summary.totalMs + profileMs - started
end

local step = { Zone = 2405, _index = 122 }
local routeSteps = { [122] = step }
APRData = { test = { [APR.ActiveRoute] = 122 } }
APRCustomPath = { test = {} }
C_Map = { GetBestMapForUnit = function() return playerMapID end }
C_Timer = { After = function(_, callback) retryCallbacks[#retryCallbacks + 1] = callback end }

function APR:ResolvePlayerZoneContext() return { allRelevant = { playerMapID } } end

function APR:GetCurrentRouteMapIDsAndName() return { 2405 }, 2405, self.ActiveRoute end

function APR:IsInstanceWithUI() return true end

function APR:UpdateQuestAndStep() end

function APR:UpdateStep() end

function APR:GetRouteSteps() return routeSteps end

function APR:IsInDelveRouteContext() return false end

function APR:GetPreferredStepZone() return 2405 end

function APR:GetStepCoord() return nil end

function APR:GetScenarioMapIDForStep() return nil end

function APR:GetScenarioZoneInfo() return nil end

function APR:GetPlayerParentMapID() return nil end

function APR:CheckIsInRouteZone() return false end

function APR:GetMapInfoCached(mapID) return { name = tostring(mapID) } end

APR.currentStep = {
    IsShown = function() return true end,
    AddExtraLineText = noop,
    AddQuestSteps = noop,
    AddQuestDivider = noop,
}
APR.routeconfig = {
    HasRouteInCustomPaht = function() return true end,
    CheckIsCustomPathEmpty = noop,
}

FarstriderLib_API = {
    DATA = { WAYPOINTS = { test = true } },
    FindTrailTo = function()
        findTrailCalls = findTrailCalls + 1
        profileMs = profileMs + 180
        return { { loc = {}, completionLoc = {} } }
    end,
}

dofile("APR-Core/integrations/Farstrider.lua")
local realShowPathStep = APR.farstrider.ShowPathStep
APR.farstrider.showOutOfZoneStepContent = true
APR.farstrider.ClearNavigationUiLines = noop
APR.farstrider.ShowPathStep = function(self)
    self.activePathStep = {}
    return true
end

for _ = 1, 10 do
    APR.farstrider:ForceRefresh()
    APR.farstrider:GetMeToRightZone(true)
    seconds = seconds + 0.5
end

assert(findTrailCalls == 1,
    "Ten identical transition retries must reuse one Dijkstra result")
assert(metrics.FarstriderFindTrailTo.count == 1 and metrics.FarstriderFindTrailTo.totalMs == 180,
    "Only the real pathfinder invocation is measured")
assert(metrics.ZoneRoutingContext.count == 10 and metrics.ZoneRoutingQuestSync.count == 10
    and metrics.ZoneRoutingZoneCheck.count == 10,
    "Cheap routing phases remain individually observable")

playerMapID = 2395
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == 2, "Changing the player map invalidates the cached key")

step._index = 123
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == 3, "Changing the active route step invalidates the cached key")

seconds = seconds + 11
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == 4, "An old path is recalculated after the bounded cache TTL")

APR.farstrider:InvalidatePathCache()
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == 5, "Explicit invalidation recalculates the path")

APR.farstrider:ClearActivePath()
seconds = seconds + 0.5
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(false)
assert(#retryCallbacks == 1 and APR.farstrider:IsNavigating(),
    "The initial result exposes an active navigation path")
retryCallbacks[1]()
assert(findTrailCalls == 5,
    "The fallback retry stops when a valid navigation path is already active")

function APR:GetScenarioMapIDForStep(scenarioStep)
    local scenario = scenarioStep.EnterScenario or scenarioStep.DoScenario
    return scenario and scenario.mapID or nil
end

function APR:GetScenarioZoneInfo(mapID)
    return mapID == 2528 and {
        type = "DELVE",
        zone = 2405,
        Coord = { x = -768.6, y = 2450.5 },
    } or nil
end

function APR:GetMapInfoCached(mapID)
    return { name = mapID == 2528 and "The Darkway" or tostring(mapID) }
end

playerMapID = 2405
assert(not APR.farstrider:RequiresScenarioNavigation({ EnterScenario = { mapID = 2528 } }),
    "EnterScenario expects the player to be outside and must not report a wrong zone")
local doScenarioStep = { DoScenario = { mapID = 2528 } }
assert(APR.farstrider:RequiresScenarioNavigation(doScenarioStep),
    "DoScenario still requires the player to be inside the delve")
assert(APR.farstrider:GetScenarioNavigationRequirement(doScenarioStep) ==
    "You must be in delve: The Darkway",
    "The wrong-zone reason names the delve map")

local navigationErrors = {}
APR.currentStep.AddExtraLineText = function(_, _, message)
    navigationErrors[#navigationErrors + 1] = message
end
function APR:CheckIsInRouteZone() return true end

step.EnterScenario, step.DoScenario, step._index = { mapID = 2528 }, nil, 124
APR.farstrider:ClearActivePath()
APR.farstrider.showOutOfZoneStepContent = true
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(#navigationErrors == 0,
    "EnterScenario keeps the normal entrance arrow without adding a wrong-zone error")

step.EnterScenario, step.DoScenario, step._index = nil, { mapID = 2528 }, 125
APR.farstrider:ClearActivePath()
APR.farstrider.showOutOfZoneStepContent = true
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(#navigationErrors == 1 and string.find(navigationErrors[1], "The Darkway", 1, true),
    "DoScenario reports that the named delve must be entered")

local shownStepKeys = {}
local arrowActive, arrowX, arrowY
APR.farstrider.ShowPathStep = realShowPathStep
APR.currentStep.AddQuestSteps = function(_, key)
    shownStepKeys[#shownStepKeys + 1] = key
end
APR.Arrow.SetArrowActive = function(_, activeState, x, y)
    arrowActive, arrowX, arrowY = activeState, x, y
end
FarstriderLib_API.FindTrailTo = function()
    findTrailCalls = findTrailCalls + 1
    return {}
end
function APR:CheckIsInRouteZone() return false end

step.EnterScenario, step.DoScenario, step._index = nil, { mapID = 2528 }, 126
APR.farstrider:InvalidatePathCache()
APR.farstrider:ClearActivePath()
APR.farstrider.showOutOfZoneStepContent = true
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(APR.farstrider.activePathStep and APR.farstrider.activePathStep.isScenarioEntranceFallback,
    "An unresolved Farstrider path falls back to the recorded scenario entrance")
assert(arrowActive and arrowX == -768.6 and arrowY == 2450.5,
    "The fallback arrow uses the ScenarioEntrances world coordinate")
assert(#shownStepKeys == 1 and shownStepKeys[1] == APR.farstrider.NavigationStepKey,
    "The entrance fallback replaces the 404 path-not-found step")

print(
"Farstrider routing: 10 identical retries reused 1 Dijkstra result; map, step, TTL and explicit invalidation passed")
