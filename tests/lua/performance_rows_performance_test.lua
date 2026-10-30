-- Viewer-owned buffers reduce GC pressure without changing exported snapshots.
APR, APRData = {}, {}
dofile("APR-Core/core/Performance.lua")
APR:SetPerformanceCapture(true)
for index = 1, 1200 do
    APR:RecordPerformanceDuration("Metric" .. index, index, nil, nil, index / 2)
    APR:CountPerformanceEvent("Counter" .. index)
end
local rows = APR:GetPerformanceRows("summary", "totalMs")
assert(#rows == 1200 and rows[1].name == "Metric1200" and rows[1200].name == "Metric1")
local existing = {}
for _, row in ipairs(rows) do existing[row] = true end
local snapshot = APR:GetPerformanceRows("summary", "totalMs")
APR:RecordPerformanceDuration("Metric1", 5000, nil, nil, 7)
local refreshed = APR:GetPerformanceRows("summary", "totalMs", "", nil, rows)
assert(refreshed == rows and rows[1].name == "Metric1" and rows[1].count == 2 and rows[1].totalMs == 5001)
for _, row in ipairs(rows) do assert(existing[row], "Warm refreshes reuse every owned metric row") end
assert(snapshot[1].name == "Metric1200" and snapshot[1].count == 1,
    "Independent exports are not mutated when the live viewer updates its buffer")
local translationReads = 0
local function display(name) translationReads = translationReads + 1; return "Translated " .. name end
APR:GetPerformanceRows("summary", "totalMs", "", display, rows)
assert(translationReads == 0, "An empty query cannot translate every metric name")
APR:GetPerformanceRows("summary", "totalMs", "Translated Metric1200", display, rows)
assert(#rows == 1 and rows[1].name == "Metric1200")
APR:GetPerformanceRows("summary", "totalMs", "no matching metric", display, rows)
assert(#rows == 0, "Filtering removes stale rows from the reused tail")
rows = APR:GetPerformanceRows("summary", "totalMs", "Metric1", nil, rows)
assert(#rows == 312 and rows[1].name == "Metric1", "Filtering retains exactly the independently chosen name prefix")
local counterRows = APR:GetPerformanceRows("counters", nil, "Counter1200", nil, rows)
assert(counterRows == rows and #rows == 1 and rows[1].name == "Counter1200" and rows[1].count == 1)
assert(rows[1].totalMs == nil and rows[1].selfMs == nil and rows[1].average == nil and rows[1].histogram == nil,
    "Counter rows cannot display timing fields retained from summary mode")
APRData.PerformanceLog = nil
assert(APR:GetPerformanceRows("summary", nil, nil, nil, rows) == rows and #rows == 0)
print("Performance rows: 1,200 reused objects, independent snapshots, filtering and clean mode/reset transitions passed")
