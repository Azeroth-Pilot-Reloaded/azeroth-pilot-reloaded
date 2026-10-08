-- Opt-in timings and counters with bounded metric names, 100 slow calls and 120 one-second buckets.
-- Timings are inclusive: nested operations must not be interpreted as total addon CPU usage.

local METRIC_LIMIT, SLOW_LIMIT, TIMELINE_SECONDS = 64, 100, 120
local function Now() return GetTime and GetTime() or debugprofilestop() / 1000 end

function APR:ResetPerformanceCapture()
    APRData.PerformanceLog = { summary = {}, slow = {}, timeline = {}, counters = {}, startedAt = Now() }
end

function APR:SetPerformanceCapture(enabled)
    if enabled then self:ResetPerformanceCapture() end
    self.performanceLogging = enabled == true
    if not enabled and APRData.PerformanceLog then APRData.PerformanceLog.stoppedAt = Now() end
end

function APR:StartPerformanceSample()
    if not self.performanceLogging then return nil end
    return debugprofilestop()
end

local function BoundedName(collection, name)
    if collection[name] then return name end
    local count = 0
    for _ in pairs(collection) do count = count + 1 end
    return count < METRIC_LIMIT and name or "Other"
end

function APR:CountPerformanceEvent(name)
    if not self.performanceLogging or not APRData or not APRData.PerformanceLog then return end
    local log = APRData.PerformanceLog
    log.counters = log.counters or {}
    name = BoundedName(log.counters, name)
    log.counters[name] = (log.counters[name] or 0) + 1
end

function APR:FinishPerformanceSample(name, started, steps)
    if not self.performanceLogging or not started or not APRData then return end
    local log = APRData.PerformanceLog
    if not log then return end
    local elapsed, now = math.max(0, debugprofilestop() - started), Now()
    name = BoundedName(log.summary, name)
    local summary = log.summary[name] or { count = 0, totalMs = 0, maxMs = 0 }
    log.summary[name] = summary
    summary.count = summary.count + 1
    summary.totalMs = summary.totalMs + elapsed
    summary.maxMs = math.max(summary.maxMs, elapsed)
    summary.histogram = summary.histogram or {0, 0, 0, 0}
    local band = elapsed < 1 and 1 or elapsed < 3 and 2 or elapsed < 10 and 3 or 4
    summary.histogram[band] = summary.histogram[band] + 1
    log.lastAt = now
    log.timeline = log.timeline or {}
    local second = math.floor(now)
    local slot = second % TIMELINE_SECONDS + 1
    local bucket = log.timeline[slot]
    if not bucket or bucket.second ~= second then
        bucket = {second = second, count = 0, totalMs = 0, maxMs = 0}
        log.timeline[slot] = bucket
    end
    bucket.count, bucket.totalMs = bucket.count + 1, bucket.totalMs + elapsed
    bucket.maxMs = math.max(bucket.maxMs, elapsed)
    if elapsed >= 10 then
        log.cursor = (log.cursor or 0) % SLOW_LIMIT + 1
        log.slow[log.cursor] = {
            name = name, ms = elapsed, time = now, route = self.ActiveRoute, steps = steps,
            step = self.PlayerID and APRData[self.PlayerID] and APRData[self.PlayerID][self.ActiveRoute],
        }
    end
end

function APR:GetPerformanceTimeline()
    local log, result = APRData and APRData.PerformanceLog, {}
    if not log then return result end
    local final = math.floor(self.performanceLogging and Now() or log.stoppedAt or log.lastAt or Now())
    for second = final - TIMELINE_SECONDS + 1, final do
        local bucket = log.timeline and log.timeline[second % TIMELINE_SECONDS + 1]
        result[#result + 1] = bucket and bucket.second == second and bucket or
            {second = second, count = 0, totalMs = 0, maxMs = 0}
    end
    return result
end

function APR:GetPerformanceRows(mode, sortKey, query)
    local log, rows = APRData and APRData.PerformanceLog, {}
    if not log then return rows end
    query = string.lower(query or "")
    if mode == "slow" then
        for offset = 0, #log.slow - 1 do
            local entry = log.slow[((log.cursor or #log.slow) - offset - 1) % SLOW_LIMIT + 1]
            if entry and string.lower(entry.name):find(query, 1, true) then rows[#rows + 1] = entry end
        end
    elseif mode == "counters" then
        for name, count in pairs(log.counters or {}) do
            if string.lower(name):find(query, 1, true) then rows[#rows + 1] = {name = name, count = count} end
        end
    else
        for name, summary in pairs(log.summary) do
            if string.lower(name):find(query, 1, true) then
                rows[#rows + 1] = {name = name, count = summary.count, totalMs = summary.totalMs,
                    maxMs = summary.maxMs, average = summary.totalMs / math.max(1, summary.count), histogram = summary.histogram}
            end
        end
    end
    if mode ~= "slow" then
        sortKey = mode == "counters" and "count" or sortKey or "totalMs"
        table.sort(rows, function(a, b)
            if a[sortKey] == b[sortKey] then return a.name < b.name end
            return (a[sortKey] or 0) > (b[sortKey] or 0)
        end)
    end
    return rows
end
