-- Completing consecutive routes must not run navigation/catalog rebuilds inside a step pass.
local noop = function() end
local milliseconds, renders, uiRefreshes, requests = 0, 0, 0, 0
local timers, messages = {}, {}
local L = setmetatable({}, {__index = function(_, key) return key end})
function LibStub() return {GetLocale = function() return L end} end
function GetTime() return milliseconds / 1000 end
function debugprofilestop() return milliseconds end
C_Timer = {NewTimer = function(_, callback)
    local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
    timers[#timers + 1] = timer
    return timer
end}
APR = {
    PlayerID = "player", performanceLogging = true,
    RouteQuestStepList = {a = {}, b = {}, c = {}},
    currentStep = {Reset = noop, BeginContentUpdate = noop, EndContentUpdate = noop},
    Buff = {RemoveAllBuffIcon = noop}, XPBuffOverlay = {QueueRefresh = noop},
    RouteBrowser = {Refresh = function()
        assert(not APR.stepUpdateRunning, "Catalog rebuilds must happen outside the step transaction")
        uiRefreshes = uiRefreshes + 1
        milliseconds = milliseconds + 50
    end},
    farstrider = {
        RequestRouteCheck = function() requests = requests + 1 end,
        GetMeToRightZone = function() error("Route selection cannot run inline pathfinding") end,
    },
    Debug = noop, OverrideRouteData = noop, InvalidatePlayerZoneCache = noop,
}
function APR:NewModule()
    return {RegisterMessage = function(_, name, callback) messages[name] = callback end}
end
function APR:GetSettingsProfile() return {enableAddon = true} end
APRData = {player = {a = 1, b = 1, c = 1}, PerformanceLog = {summary = {}, slow = {}, startedAt = 0}}
APRCustomPath = {player = {"a"}}
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/core/Performance.lua")
dofile("APR-Core/features/questing/QuestHandler.lua")
dofile("APR-Core/config/Config_Route.lua")
function APR:GetCurrentRouteMapIDsAndName() return {1}, 1, APRCustomPath.player[1] end
APR.OverrideRouteData = noop
function APR:RenderCurrentStep()
    renders = renders + 1
    milliseconds = milliseconds + 1
    if self.ActiveRoute ~= "c" then
        APRCustomPath.player[1] = self.ActiveRoute == "a" and "b" or "c"
        messages.APR_Custom_Path_Update()
    end
end
APR.routeconfig:InitRouteConfig()
messages.APR_Custom_Path_Update()
assert(APR.ActiveRoute == "c" and renders == 3 and requests == 3,
    "Consecutive completions activate the final route and request deferred navigation")
assert(uiRefreshes == 0 and APRData.PerformanceLog.summary.UpdateStepPass.maxMs == 1,
    "Expensive catalog rebuilds no longer inflate current-step passes")
for _, timer in ipairs(timers) do timer.callback() end
assert(uiRefreshes == 1 and APRData.PerformanceLog.summary.RoutePathUiRefresh.totalMs == 50,
    "A burst publishes one catalog refresh and exposes its own measured cost")
assert(APRData.PerformanceLog.summary.StepRenderContent.count == 3 and
    APRData.PerformanceLog.summary.StepRenderCommit.count == 3,
    "Step content and layout commit costs remain separately observable")
print("Route path: consecutive completions defer navigation and coalesce one measured catalog rebuild")
