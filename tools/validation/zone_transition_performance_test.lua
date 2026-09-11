-- Lua 5.1 regression test for zone-event bursts and their routing cost.
local noop = function() end
local now, routeCalls, forceRefreshes, delveRefreshes = 10, 0, 0, 0
local navigating = false
local timers = {}

function LibStub()
    return { GetLocale = function() return {} end }
end
function CreateFrame()
    return { RegisterEvent = noop, SetScript = noop }
end

APR = {
    ActiveRoute = "performance-route",
    PlayerID = "test",
    performanceLogging = true,
}
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return { enableAddon = true } end
function APR:RefreshLevelProfileTargets() return false end
function APR:InvalidatePlayerZoneCache() end
function APR:IsInstanceWithUI() return true end
function APR:ScheduleDelveRouteRefresh() delveRefreshes = delveRefreshes + 1 end
function APR:Debug() end

APR.farstrider = {
    ForceRefresh = function() forceRefreshes = forceRefreshes + 1 end,
    GetMeToRightZone = function()
        routeCalls = routeCalls + 1
        now = now + 25 -- Simulate an expensive path calculation.
    end,
    IsNavigating = function() return navigating end,
}

APRData = {
    test = { ["performance-route"] = 404 },
    PerformanceLog = { summary = {}, slow = {} },
}
C_Map = { GetBestMapForUnit = function() return 2393 end }
C_Timer = {
    NewTimer = function(delay, callback)
        local timer = { delay = delay, callback = callback, cancelled = false }
        function timer:Cancel() self.cancelled = true end
        timers[#timers + 1] = timer
        return timer
    end,
    Cancel = function(timer) timer:Cancel() end,
}
function GetTime() return now end
function debugprofilestop() return now end
function IsInInstance() return false end

dofile("APR-Core/core/Commands.lua")
dofile("APR-Core/core/Event.lua")

for index = 1, 100 do
    local event = index % 3 == 0 and "ZONE_CHANGED_NEW_AREA"
        or index % 2 == 0 and "ZONE_CHANGED_INDOORS"
        or "ZONE_CHANGED"
    APR.event.functions.zone(event)
end

assert(routeCalls == 0 and forceRefreshes == 0,
    "A zone-event burst must not calculate a route synchronously")

local activeTimers = {}
for _, timer in ipairs(timers) do
    if not timer.cancelled then activeTimers[#activeTimers + 1] = timer end
end
assert(#activeTimers == 1, "One hundred zone events must coalesce into one routing timer")
activeTimers[1].callback()

assert(routeCalls == 1 and forceRefreshes == 1,
    "The coalesced transition performs exactly one fresh routing calculation")
local summary = APRData.PerformanceLog.summary.ZoneTransitionRouting
assert(summary and summary.count == 1 and summary.totalMs == 25 and summary.maxMs == 25,
    "The delayed routing cost must be captured by /apr perf")
assert(#APRData.PerformanceLog.slow == 1 and APRData.PerformanceLog.slow[1].name == "ZoneTransitionRouting",
    "A slow zone calculation must appear in the bounded slow-operation log")
assert(APRData.PerformanceLog.slow[1].step == 404,
    "The slow-operation record must identify the active route step")
assert(delveRefreshes == 100,
    "Delve refreshes remain safe because their scheduler owns its own debounce timer")

print("Zone transition: 100 events coalesced into 1 route calculation; 25 ms sample captured")

-- PLAYER_ENTERING_WORLD keeps safety retries for unavailable map data, but once the
-- first pass confirms the route zone, the later timers must be cheap no-ops.
timers, routeCalls, forceRefreshes = {}, 0, 0
APR.IsInRouteZone = nil
APR.farstrider.GetMeToRightZone = function()
    routeCalls = routeCalls + 1
    now = now + 25
    APR.IsInRouteZone = true
end

APR.event.functions.zone("PLAYER_ENTERING_WORLD")
assert(#timers == 4 and routeCalls == 0,
    "Entering the world schedules bounded retries without routing synchronously")
for _, timer in ipairs(timers) do timer.callback() end
assert(routeCalls == 1 and forceRefreshes == 2,
    "A successful first post-load route check skips the three remaining safety retries")
summary = APRData.PerformanceLog.summary.ZoneTransitionRouting
assert(summary.count == 2 and summary.totalMs == 50 and #APRData.PerformanceLog.slow == 2,
    "Post-load routing contributes one measured sample")

print("World transition: first successful route check skipped 3 redundant safety retries")

-- Finding a valid travel path is also a settled result while the destination zone
-- is still ahead. Safety retries must not repeatedly solve that same path.
timers, routeCalls, forceRefreshes = {}, 0, 0
APR.IsInRouteZone, navigating = nil, false
APR.farstrider.GetMeToRightZone = function()
    routeCalls = routeCalls + 1
    now = now + 25
    navigating = true
end

APR.event.functions.zone("PLAYER_ENTERING_WORLD")
for _, timer in ipairs(timers) do timer.callback() end
assert(routeCalls == 1 and forceRefreshes == 2,
    "A valid navigation path skips the three remaining post-load retries")

print("World transition: active navigation skipped 3 redundant path calculations")
