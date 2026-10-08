local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "enUS" end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/core/Performance.lua")
dofile("APR-Core/ui/panels/PerformanceDashboard.lua")
APRData = {}
local milliseconds, seconds = 0, 0
function GetTime() return seconds end
function debugprofilestop() return milliseconds end
assert(APR:StartPerformanceSample() == nil)
APR:SetPerformanceCapture(true)
for index = 1, 1000 do
    seconds = index
    local started = APR:StartPerformanceSample()
    milliseconds = milliseconds + 11
    APR:FinishPerformanceSample("Render", started)
    APR:CountPerformanceEvent("CacheHit")
end
local log = APRData.PerformanceLog
assert(log.summary.Render.count == 1000 and #log.slow == 100 and #log.timeline == 120)
assert(log.summary.Render.histogram[4] == 1000 and log.counters.CacheHit == 1000)
local rows = APR:GetPerformanceRows("slow")
assert(rows[1].time == 1000 and rows[100].time == 901)
assert(APR:GetPerformanceTimeline()[1].second == 881)
for index = 1, 1000 do
    APR:CountPerformanceEvent("Name" .. index)
    APR:FinishPerformanceSample("Name" .. index, milliseconds)
end
local metrics, counters = 0, 0
for _ in pairs(log.summary) do metrics = metrics + 1 end
for _ in pairs(log.counters) do counters = counters + 1 end
assert(metrics <= 65 and counters <= 65)
APR.PerformanceDashboard:Show()
assert(#APR.PerformanceDashboard.bars == 120)
APR.PerformanceDashboard.mode = "slow"
APR.PerformanceDashboard:Refresh()
assert(#APR.PerformanceDashboard.list.items == 100)
APR.PerformanceDashboard.frame:Hide()
assert(APR.PerformanceDashboard.frame.scripts.OnUpdate == nil and APR.performanceLogging)
APR:SetPerformanceCapture(false)
APR:FinishPerformanceSample("Render", milliseconds)
assert(log.summary.Render.count == 1000)
seconds = 2000
assert(APR:GetPerformanceTimeline()[120].second == 1000, "Stopped timeline must remain fixed")
APR:ResetPerformanceCapture()
assert(not APR.performanceLogging and next(APRData.PerformanceLog.summary) == nil)
print("Performance: bounded names/rings, chronological slow calls, fixed stopped chart and lazy dashboard passed")
