local ms, seconds = 0, 0
function GetTime() return seconds end
function debugprofilestop() return ms end
APR, APRData = {PlayerID = "player", ActiveRoute = "route"}, {player = {route = 4}}
dofile("APR-Core/core/Diagnostics.lua")
dofile("APR-Core/core/Performance.lua")
dofile("APR-Core/core/PerformanceScopes.lua")
local D = APRInstrumentation
APR.GetStep = D.Wrap("GetStep", function(self, value)
    assert(value == 7)
    self:RecordPerformanceBreadcrumb("render clue")
    ms = ms + 4
    return nil, value, nil, false
end)
APR.UpdateStep = D.Wrap("UpdateStep", function(self)
    ms = ms + 2
    return self:GetStep(7)
end)
local cachedCallback = APR.UpdateStep
APR:SetPerformanceCapture(true)
local function checkResults(...)
    assert(select("#", ...) == 4)
    local a, b, c, d = ...
    assert(a == nil and b == 7 and c == nil and d == false)
end
checkResults(cachedCallback(APR))
local log = APRData.PerformanceLog
assert(log.diagnosticRevision == D.revision and log.debugCallsDuringCapture == false)
assert(log.summary.GetStep.maxMs == 4 and log.summary.UpdateStep.selfMs == 2)
assert(log.frameWork.ms == 6 and log.frameWork.count == 1 and log.frameWork.source == "UpdateStep",
    "Frame work counts only the outer call, not overlapping children")
assert(log.slow[1].parent == "UpdateStep" and log.slow[1].breadcrumb == "render clue")
assert(log.slow[1].step == 4 and D.CurrentName() == nil)
APR:SetPerformanceCapture(false)
assert(APR.UpdateStep == cachedCallback and not D.enabled)
APR:GetStep(7)
assert(log.summary.GetStep.count == 1)
local errorObject = {}
local fail = D.Wrap("Failure", function() ms = ms + 11; error(errorObject) end)
APR:SetPerformanceCapture(true)
local ok, err = pcall(fail)
assert(not ok and err == errorObject and D.CurrentName() == nil)
assert(APRData.PerformanceLog.summary.Failure.maxMs == 11)
assert(APRData.PerformanceLog.summary.Failure.errors == 1)
APR:ResetPerformanceCapture()
checkResults(APR:UpdateStep())
assert(APRData.PerformanceLog.summary.GetStep.count == 1)

-- Suspended coroutine time must not become an enormous CPU spike.
local worker = D.Wrap("Worker", function()
    ms = ms + 3
    D.Yield("pause", nil, 9)
    ms = ms + 2
    return "done", nil, 5
end)
local thread = coroutine.create(worker)
local ok, result, missing, number = D.Resume(thread)
assert(ok and result == "pause" and missing == nil and number == 9)
ms = ms + 10000
ok, result, missing, number = D.Resume(thread)
assert(ok and result == "done" and missing == nil and number == 5)
assert(APRData.PerformanceLog.summary.Worker.totalMs == 5)
thread = coroutine.create(D.Wrap("CoroutineError", function() ms = ms + 2; error("broken") end))
ok, result = D.Resume(thread)
assert(not ok and result:find("broken") and D.CurrentName() == nil)
assert(APRData.PerformanceLog.summary.CoroutineError.errors == 1)
local caught = D.Wrap("Caught", function() ms = ms + 2; error("caught") end)
thread = coroutine.create(D.Wrap("Catcher", function()
    local success = D.PCall(caught)
    assert(not success)
    ms = ms + 100
end))
assert(D.Resume(thread))
assert(APRData.PerformanceLog.summary.Caught.totalMs == 2)
assert(APRData.PerformanceLog.summary.Catcher.selfMs == 100)
APR:SetDebugCapture(true)
assert(APRData.PerformanceLog.debugCallsDuringCapture == true)
APR:SetPerformanceCapture(false)
assert(D.enabled and D.debug, "Debug can run independently of performance")
D.Message("DEBUG", "Readable", {value = false, text = "a\nb"})
D.Message("DEBUG", "Readable", {value = false, text = "a\nb"})
local rows = APR:GetDiagnosticRows("Readable")
assert(#rows == 1 and rows[1].count == 2 and rows[1].data:find("value=false", 1, true))
assert(not rows[1].data:find("\n"))
local cycle = {}; cycle.self = cycle
assert(D.Value(cycle):find("<cycle>", 1, true))
local secret = {}
function canaccessvalue(value) return value ~= secret end
assert(D.Value(secret) == "<unavailable>")
local dangerous = setmetatable({}, {__tostring = function() error("must not call") end})
assert(D.Value(dangerous) == "{}")
for i = 1, 1200 do D.Message("DEBUG", "message " .. i) end
rows = APR:GetDiagnosticRows()
assert(#rows == 1000 and rows[1].message == "message 1200" and rows[1000].message == "message 201")
APR:SetDebugCapture(false)
local total = APRData.DebugLog.total
APR:UpdateStep()
assert(not D.enabled and APRData.DebugLog.total == total)
local locale = setmetatable({UI_DIAGNOSTIC_COVERAGE = "%d functions / %d files / %d exclusions",
    UI_DIAGNOSTIC_RETAINED = "%d retained / %d events"}, {__index = function(_, key) return key end})
function LibStub() return {GetLocale = function() return locale end} end
dofile("APR-Core/core/DiagnosticReport.lua")
D.ResetLog()
D.Message("DEBUG", "Readable", {value = false, text = "line\nbreak"}, false, true)
D.Message("DEBUG", "Readable", {value = false, text = "line\nbreak"}, false, true)
local report = APR:BuildDiagnosticReport()
assert(report:find("GetStep", 1, true) and report:find("self ms", 1, true))
assert(report:find("value=false", 1, true) and report:find("×2", 1, true))
assert(report:find("route / 4", 1, true) and not report:find("table: 0x", 1, true))
assert(report:find("1 retained / 2 events", 1, true))
assert(report:find("Diagnostics revision: " .. D.revision, 1, true))
assert(report:find("Capture revision: " .. D.revision .. " | debug calls during capture: yes", 1, true))
APRData.PerformanceLog.diagnosticRevision, APRData.PerformanceLog.debugCallsDuringCapture = nil, nil
report = APR:BuildDiagnosticReport()
assert(report:find("Capture revision: unknown (older capture) | debug calls during capture: unknown", 1, true),
    "Exporting an old saved capture must not attribute it to the newly loaded revision")
print("Full diagnostics: cached callbacks, exclusive timings, nil returns, errors, coroutines, bounded readable logs and shutdown passed")

-- Interleaved hot functions must not allocate/overwrite the journal per call.
D.ResetLog()
D.Record("EVENT", "dispatch", "BAG_UPDATE_DELAYED")
for i = 1, 10000 do
    D.Record("CALL", "HotA", nil, nil, 0.1, 0.05, false)
    D.Record("CALL", "HotB", nil, nil, 0.2, 0.1, false)
end
assert(APRData.DebugLog.count == 3 and APRData.DebugLog.total == 20001)
assert(APRData.DebugLog.aggregatedCalls == 19998)
assert(APR:GetDiagnosticRows("HotA")[1].count == 10000)
assert(#APR:GetDiagnosticRows("BAG_UPDATE_DELAYED") == 1)
seconds = seconds + 1
D.Record("CALL", "HotA", nil, nil, 0.1, 0.05, false)
assert(APRData.DebugLog.count == 4, "The aggregation window expires")
APRData.player.route = 5
D.Record("CALL", "HotA", nil, nil, 0.1, 0.05, false)
assert(APRData.DebugLog.count == 5, "Step changes remain separate")
D.Record("CALL", "HotA", nil, nil, 8, 4, false)
D.Record("CALL", "HotA", nil, nil, 9, 5, false)
assert(APRData.DebugLog.count == 7, "Slow calls always keep separate timestamps")
for i = 1, 1100 do D.Record("DEBUG", "source", "overwrite " .. i) end
D.Record("CALL", "HotA", nil, nil, 0.1, 0.05, false)
assert(APR:GetDiagnosticRows("HotA")[1].count == 1, "Evicted entries are never reused")
local retained = 0
for _ in pairs(APRData.DebugLog.calls) do retained = retained + 1 end
assert(retained == 1, "Aggregation retains only live journal entries")
print("Diagnostic aggregation: 20,000 hot calls use two entries; events, timing windows, steps and slow calls preserved")
