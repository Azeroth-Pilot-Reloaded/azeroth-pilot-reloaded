-- Resource samples must be truthful, bounded and independent from the dashboard lifetime.
local seconds, cpu, frame, memory, memoryReads = 0, 2, 20, 2048, 0
local enabled, failMemory, restricted = true, false, false
local profileMs = 0
local timers = {}
APR = {PlayerID = "player", ActiveRoute = "route", _effectiveRouteStepsCache = {route = {}},
    ZoneDetection = {mapInfoCache = {[1] = {}}}, questOrderList = {stepList = {{}, {}}}}
APRData = {player = {route = 42}}
function APR:CanAccessValue(value) return type(value) ~= "table" or not value.restricted end
function GetTime() return seconds end
function debugprofilestop() return seconds * 1000 + profileMs end
function GetFramerate() return 50 end
Enum = {AddOnProfilerMetric = {RecentAverageTime = 1}}
C_AddOnProfiler = {
    IsEnabled = function() return enabled end,
    GetAddOnMetric = function(name, metric)
        assert(name == "APR" and metric == 1)
        return restricted and {restricted = true} or cpu
    end,
    GetApplicationMetric = function() return frame end,
}
function UpdateAddOnMemoryUsage()
    memoryReads = memoryReads + 1
    profileMs = profileMs + 280 -- Reproduce the expensive native scan from the client capture.
    if failMemory then error("Memory API unavailable") end
end
function GetAddOnMemoryUsage(name) assert(name == "APR"); return memory end
C_Timer = {NewTicker = function(interval, callback)
    assert(interval == 1)
    local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
    timers[#timers + 1] = timer
    return timer
end}
dofile("APR-Core/core/Performance.lua")
dofile("APR-Core/core/ResourceMonitor.lua")
local monitor = APR.ResourceMonitor
monitor:Sample()
assert(memoryReads == 0 and #timers == 0, "Inactive monitoring has no work")
APR:SetPerformanceCapture(true)
assert(#timers == 1 and memoryReads == 0, "Starting CPU capture never scans memory")
local view = monitor:GetView(120)
assert(view.latest.cpuPercent == 10 and view.latest.cpuMs == 2 and view.latest.memoryKB == nil)
assert(view.latest.step == 42 and view.latest.routeCache == 1 and view.latest.stepModels == 2)
assert(view.points[1].cpuPercent == nil and view.points[120].cpuPercent == 10)
monitor:Sample()
assert(APRData.PerformanceLog.resources.count == 1)
monitor:ScanMemory()
assert(memoryReads == 1 and monitor:GetView(120).latest.memoryKB == 2048)
seconds, cpu, memory = 1, 4, 3072
timers[1].callback()
view = monitor:GetView(120)
assert(view.latest.cpuPercent == 20 and view.latest.memoryKB == 2048 and view.latest.memoryAt == 0)
assert(memoryReads == 1, "CPU ticks cannot trigger a full memory scan each second")
seconds = 5; timers[1].callback()
assert(memoryReads == 1 and monitor:GetView(120).latest.memoryAt == 0,
    "Five-second ticks retain the timestamp of the requested reading without rescanning")
monitor:ScanMemory()
view = monitor:GetView(120)
assert(view.latest.memoryKB == 3072 and view.firstMemoryKB == 2048 and view.peakMemoryKB == 3072)
assert(view.points[119].cpuPercent == nil, "Missed ticks remain gaps")
local frozen = monitor:GetView(600)
seconds, memory = 10, 1024; timers[1].callback()
monitor:ScanMemory()
view = monitor:GetView(120)
assert(view.latest.memoryKB == 1024 and view.peakMemoryKB == 3072, "Memory drops remain visible")
assert(frozen.latest.memoryKB == 3072, "Frozen views cannot change under the sampler")
enabled, seconds = false, 11; timers[1].callback()
assert(monitor:GetView(120).latest.cpuPercent == nil, "Disabled profiling is unavailable, not zero")
enabled, restricted, seconds = true, true, 12; timers[1].callback()
assert(monitor:GetView(120).latest.cpuMs == nil)
restricted, frame, seconds = false, 0, 13; timers[1].callback()
assert(monitor:GetView(120).latest.cpuPercent == nil, "Do not divide by zero frame time")
failMemory, seconds = true, 15; timers[1].callback()
monitor:ScanMemory()
assert(monitor:GetView(120).latest.memoryKB == nil, "Failed scans cannot masquerade as fresh readings")
assert(APRData.PerformanceLog.summary.ResourceMemoryScan.count == 4,
    "Manual scan overhead, including failed scans, is visible in the performance summary")
assert(APRData.PerformanceLog.summary.ResourceMemoryScan.maxMs == 280 and
    APRData.PerformanceLog.summary.ResourceMemoryScan.totalMs == 1120,
    "The actual blocking scan cost is recorded rather than the cheap memory read")
frame, failMemory = 20, false
for index = 16, 1000 do seconds = index; timers[1].callback() end
local resources = APRData.PerformanceLog.resources
assert(resources.count == 600 and #resources.samples == 600 and memoryReads == 4,
    "Long CPU captures never perform additional full memory scans")
view = monitor:GetView(600)
assert(#view.points == 120 and view.latest.time == 1000)
-- The exported ten-minute history must survive the bounded formatter without truncation.
function LibStub() return {GetLocale = function() return {} end} end
dofile("APR-Core/utils/Utils.lua")
for index = 1, 65 do
    APRData.PerformanceLog.summary["Scope" .. index] = {count = 20, totalMs = 100, maxMs = 12, histogram = {1, 2, 3, 4}}
end
for index = 1, 100 do
    APRData.PerformanceLog.slow[index] = {name = "Scope1", ms = 12, time = index, route = "route", steps = 20, step = 42}
end
for index = 1, 120 do
    APRData.PerformanceLog.timeline[index] = {second = index, count = 20, totalMs = 100, maxMs = 12,
        peakName = "Scope1", peakRoute = "route", peakStep = 42, slowCount = 1}
end
local exported = APR:FormatDebugTable(APRData.PerformanceLog, 20000)
assert(not exported:find("<entry-limit>", 1, true))
local restored = assert(loadstring("return " .. exported))()
assert(restored.resources.count == 600 and restored.resources.samples[resources.cursor].time == 1000)
APR:SetPerformanceCapture(false)
assert(timers[1].cancelled)
monitor:ScanMemory()
assert(memoryReads == 4, "Stopped capture cannot trigger a memory scan")
seconds = 1100; timers[1].callback()
assert(resources.lastAt == 1000 and monitor:GetView(120).finish == 1000)
APR:ResetPerformanceCapture()
assert(not APRData.PerformanceLog.resources and #timers == 1)
APR:SetPerformanceCapture(true)
assert(#timers == 2 and APRData.PerformanceLog.resources.count == 1)
APR:ResetPerformanceCapture()
assert(timers[2].cancelled and #timers == 3, "Reset replaces the sampler rather than leaking tickers")
C_AddOnProfiler, GetAddOnMemoryUsage, GetFramerate = nil, nil, nil
seconds = 1200; timers[3].callback()
monitor:ScanMemory()
view = monitor:GetView(120)
assert(not view.latest.cpuPercent and not view.latest.memoryKB and not view.latest.fps)
print("Resource monitor: scan-free CPU capture, explicit memory scans/drops, unavailable APIs, gaps, freeze and lifecycle passed")
