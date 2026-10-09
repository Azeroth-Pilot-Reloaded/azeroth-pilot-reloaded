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
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
function APR:NewModule() return {} end

function APR:Debug() end
function APR:GetSettingsProfile() return {enableAddon = true} end

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
    RemoveQuestStepsAndExtraLineTexts = noop,
}
APR.routeconfig = {
    HasRouteInCustomPath = function() return true end,
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

APR.RouteQuestStepList = { [APR.ActiveRoute] = { steps = routeSteps } }
step = APR:GetCurrentStep()
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

-- A direct same-zone result must survive MarkRouteReady, otherwise every zone event
-- defeats the ten-second cache even though neither the step nor the goal changed.
step.EnterScenario, step.DoScenario, step._index = nil, nil, 127
function APR:GetStep() return step end
function APR:CheckIsInRouteZone() return true end
FarstriderLib_API.FindTrailTo = function()
    findTrailCalls = findTrailCalls + 1
    return { { loc = {}, completionLoc = {} } }
end
APR.farstrider:InvalidatePathCache()
local before = findTrailCalls
for _ = 1, 10 do
    APR.farstrider:ForceRefresh()
    APR.farstrider:GetMeToRightZone(true)
    seconds = seconds + 0.5
end
assert(findTrailCalls == before + 1 and APR.IsInRouteZone,
    "Repeated ready-zone checks reuse the cached direct result")
APR:SetRouteProgress(APR.ActiveRoute, 123, "reset")
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == before + 2, "Progress revisions invalidate a result even with the same runtime step index")

-- Sharing a map does not prove direct access: a path containing transport edges
-- must still take over the guide. Keep the solver check on a fresh context.
FarstriderLib_API.FindTrailTo = function()
    findTrailCalls = findTrailCalls + 1
    return { { loc = {} }, { loc = {} } }
end
APR.farstrider.ShowPathStep = function(self) self.activePathStep = {}; return true end
APR.farstrider:InvalidatePathCache()
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(not APR.IsInRouteZone and APR.farstrider:IsNavigating(),
    "Same-map routes requiring transport still enable navigation")

local timers = {}
C_Timer.NewTimer = function(_, callback)
    local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
    timers[#timers + 1] = timer
    return timer
end
local function activeTimer()
    local result
    for _, timer in ipairs(timers) do
        if not timer.cancelled and timer == APR.farstrider._stepCheckTimer then
            assert(not result, "A request burst keeps only one active routing timer")
            result = timer
        end
    end
    return assert(result)
end

-- A routing pass renders the step itself, so that render must not enqueue a
-- second route pass; requests from inside the pass must not recurse either.
function APR:UpdateQuestAndStep()
    self.farstrider:ScheduleRouteCheck(self:GetCurrentStepToken(self.ActiveRoute, APRData.test[self.ActiveRoute]))
    self.farstrider:GetMeToRightZone(true)
end
APR.farstrider:InvalidatePathCache()
before = findTrailCalls
for _ = 1, 10 do APR.farstrider:RequestRouteCheck() end
activeTimer().callback()
assert(findTrailCalls == before + 1 and not APR.farstrider._stepCheckTimer,
    "A burst and its own step render produce one solver call with no follow-up timer")

-- If an immediate zone check wins the race, it cancels the already scheduled check.
APR.farstrider:RequestRouteCheck()
local replaced = activeTimer()
local passes = metrics.ZoneRoutingQuestSync.count
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
replaced.callback()
assert(replaced.cancelled and metrics.ZoneRoutingQuestSync.count == passes + 1,
    "An immediate route check supersedes the deferred check without a second render")

APR.farstrider:RequestRouteCheck()
local stale = activeTimer()
APR:SetRouteProgress(APR.ActiveRoute, 124, "manual_skip")
passes = metrics.ZoneRoutingQuestSync.count
stale.callback()
assert(metrics.ZoneRoutingQuestSync.count == passes, "A stale step callback does no routing work")

-- Route changes during a render wait for the transaction to end before pathfinding.
APR.stepUpdateRunning = true
before = findTrailCalls
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == before, "Pathfinding cannot run inside a step render")
APR.stepUpdateRunning = false
activeTimer().callback()
assert(findTrailCalls == before + 1)

-- A yielded progression batch has not chosen the final goal yet.
function APR:UpdateQuestAndStep() end
APR.stepUpdateTimer = {}
APR.farstrider:InvalidatePathCache()
before = findTrailCalls
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == before, "Yielded progression does not calculate an intermediate destination")
APR.stepUpdateTimer = nil
activeTimer().callback()
assert(findTrailCalls == before + 1, "The final destination is routed after progression settles")

-- Becoming ready can render/complete another step. That final render's request is
-- suppressed during routing, but its changed context must get a fresh deferred check.
FarstriderLib_API.FindTrailTo = function()
    findTrailCalls = findTrailCalls + 1
    return { { loc = {}, completionLoc = {} } }
end
function APR:UpdateStep()
    self:SetRouteProgress(self.ActiveRoute, APRData.test[self.ActiveRoute] + 1, "automatic")
end
APR.farstrider.showOutOfZoneStepContent, APR.IsInRouteZone = true, false
APR.farstrider:InvalidatePathCache()
before = findTrailCalls
APR.farstrider:ForceRefresh()
APR.farstrider:GetMeToRightZone(true)
assert(findTrailCalls == before + 1 and APR.farstrider._stepCheckTimer,
    "A step completed by the ready-zone render schedules navigation for its successor")
activeTimer().callback()
assert(findTrailCalls == before + 2 and not APR.farstrider._stepCheckTimer)

function APR:UpdateStep() error("navigation render failed") end
APR.farstrider._suppressScheduledRouteCheck = true
assert(not pcall(APR.farstrider.RefreshStepForNavigation, APR.farstrider))
assert(APR.farstrider._suppressScheduledRouteCheck,
    "Navigation rendering preserves an enclosing suppression guard on failure")
APR.farstrider._suppressScheduledRouteCheck = nil

function APR:UpdateQuestAndStep() error("render failed") end
APR.farstrider:ForceRefresh()
assert(not pcall(APR.farstrider.GetMeToRightZone, APR.farstrider, true))
assert(not APR.farstrider._routingInProgress and not APR.farstrider._suppressScheduledRouteCheck,
    "A failed route pass releases its reentrancy and scheduling guards")
print("Farstrider: ready-zone cache, same-map transports, request bursts, stale steps and render deferral passed")

print(
    "Farstrider routing: 10 identical retries reused 1 Dijkstra result; map, step, TTL and explicit invalidation passed")
