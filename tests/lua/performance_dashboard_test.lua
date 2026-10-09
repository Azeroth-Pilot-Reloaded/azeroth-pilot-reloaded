local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "enUS" end
UIParent:SetSize(1920, 1080)
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/foundations/TimeSeriesGraph.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/core/Performance.lua")
dofile("APR-Core/core/ResourceMonitor.lua")
dofile("APR-Core/ui/panels/PerformanceResources.lua")
dofile("APR-Core/ui/panels/PerformanceDashboard.lua")
C_Timer = {NewTicker = function() return {Cancel = function() end} end}
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
local dashboard = APR.PerformanceDashboard
assert(dashboard.page == "resources" and dashboard.resourcesPanel:IsShown())
dashboard:SetPage("calls")
dashboard.plot:SetSize(1208, 108)
function dashboard.plot:GetLeft() return 100 end
function dashboard.plot:GetEffectiveScale() return 2 end
local cursorX = (100 + 4 + 1195) * 2
function GetCursorPosition() return cursorX, 0 end
function APR:SetTooltipText(_, text) GameTooltip.title, GameTooltip.lines = text, {} end
function APR:AddTooltipDoubleLine(_, label, value) GameTooltip.lines[label] = value end
function APR:AddTooltipLine(_, text) GameTooltip.note = text end
dashboard:RefreshGraph()
dashboard.plot.scripts.OnEnter()
assert(dashboard.hoverIndex == 120)
local details = APR:GetPerformanceBucketDetails(dashboard.timeline[120], 1000)
assert(details.count == 1001 and details.peakName == "Render" and details.slowCount == 1)
cursorX = (100 + 4 + 5) * 2
dashboard:UpdateGraphTooltip()
assert(dashboard.hoverIndex == 1 and dashboard.timeline[1].count == 1)
dashboard.freeze.scripts.OnClick()
local frozenLast = dashboard.timeline[120].second
seconds = seconds + 1
APR:FinishPerformanceSample("New call", milliseconds)
dashboard:Refresh()
assert(dashboard.timeline[120].second == frozenLast and APR.performanceLogging)
dashboard.graphMetric = "count"
dashboard:RefreshGraph()
assert(dashboard.bars[120]:GetHeight() <= dashboard.plot:GetHeight() - 8)
dashboard.freeze.scripts.OnClick()
assert(dashboard.timeline[120].second == 1001)
cursorX = (100 + 4 + 1195) * 2
dashboard:UpdateGraphTooltip(true)
assert(APR:GetPerformanceBucketDetails(dashboard.timeline[120], 1001).peakName == "Other")
dashboard.plot.scripts.OnLeave()
assert(not GameTooltip:IsShown() and not dashboard.hoverLine:IsShown())
APR.PerformanceDashboard.mode = "slow"
APR.PerformanceDashboard:Refresh()
assert(#APR.PerformanceDashboard.list.items == 100)
APR.PerformanceDashboard.frame:Hide()
assert(APR.PerformanceDashboard.frame.scripts.OnUpdate == nil and APR.performanceLogging)
APR:SetPerformanceCapture(false)
APR:FinishPerformanceSample("Render", milliseconds)
assert(log.summary.Render.count == 1000)
seconds = 2000
assert(APR:GetPerformanceTimeline()[120].second == 1001, "Stopped timeline must remain fixed")
APR:ResetPerformanceCapture()
assert(not APR.performanceLogging and next(APRData.PerformanceLog.summary) == nil)
assert(APR:GetPerformanceBucketDetails({second = 1, count = 0, totalMs = 0, maxMs = 0}, 10).average == 0)

Enum = {AddOnProfilerMetric = {RecentAverageTime = 1}}
C_AddOnProfiler = {IsEnabled = function() return true end,
    GetAddOnMetric = function() return 2 end, GetApplicationMetric = function() return 20 end}
function UpdateAddOnMemoryUsage() end
function GetAddOnMemoryUsage() return 4096 end
APR:SetPerformanceCapture(true)
assert(APR.ResourceMonitor:GetView(120).latest.memoryKB == nil)
dashboard.frame:Show()
dashboard:SetPage("resources")
local resources = dashboard.resources
resources.scanMemory.scripts.OnClick()
assert(resources.view.latest.cpuPercent == 10 and resources.view.latest.memoryKB == 4096)
assert(resources.scanMemory.enabled and APRData.PerformanceLog.summary.ResourceMemoryScan.count == 1)
local graph = resources.cpu.graph
graph.frame:SetSize(500, 180)
function graph.frame:GetLeft() return 100 end
function graph.frame:GetEffectiveScale() return 2 end
cursorX = (100 + 6 + 487) * 2
graph.frame.scripts.OnEnter()
assert(graph.hoverIndex == 120 and resources.view.latest.cpuMs == 2)
graph.frame.scripts.OnLeave()
assert(not graph.marker:IsShown() and graph.frame.scripts.OnUpdate == nil)
resources.freeze.scripts.OnClick()
local previousView = resources.view
seconds = seconds + 1
APR.ResourceMonitor:Sample()
resources:Refresh()
assert(resources.view == previousView and resources.view.finish < seconds)
resources.freeze.scripts.OnClick()
assert(resources.view.finish == seconds)
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 20 do resources:Refresh() end
assert(env.frames() == frames and env.fonts() == fonts and #graph.lines == 120 and #graph.fills == 120)
local points = {}
for i = 1, 120 do points[i] = {} end
points[118].cpuPercent, points[120].cpuPercent = 10, 20
graph:SetData(points, "cpuPercent", 100, tostring)
assert(not graph.lines[119]:IsShown() and not graph.fills[119]:IsShown(), "No line or area for missing data")
assert(graph.lines[120].startPoint[4] == graph.lines[120].endPoint[4], "An isolated reading cannot bridge a gap")
assert(graph.fills[120]:GetHeight() <= graph.frame:GetHeight() - 12)
resources:Tooltip(graph.frame, resources.view.points[120], "memoryKB")
resources.freeze.scripts.OnClick()
dashboard.capture.scripts.OnClick()
assert(not APR.performanceLogging and not resources.frozenView, "Stop shows the final captured resource values")
assert(not resources.scanMemory.enabled, "Memory measurement is disabled after capture stops")

print("Performance: bounded capture, peak context, scaled graph hover, frozen graph, metric selection and cleanup passed")
