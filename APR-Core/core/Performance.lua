-- Opt-in timings and counters with bounded metric names, 100 slow calls and 120 one-second buckets.
-- Timings are inclusive: nested operations must not be interpreted as total addon CPU usage.

local METRIC_LIMIT, SLOW_LIMIT, TIMELINE_SECONDS = 8192, 100, 120
APR.performanceSlowThresholdMs = 3
local function Now() return GetTime and GetTime() or debugprofilestop() / 1000 end

function APR:ResetPerformanceCapture()
    APRData.PerformanceLog = { summary = {}, slow = {}, timeline = {}, counters = {}, startedAt = Now(),
        slowThresholdMs = self.performanceSlowThresholdMs, metricLimit = METRIC_LIMIT,
        diagnosticRevision = APRInstrumentation and APRInstrumentation.revision,
        debugCallsDuringCapture = APRInstrumentation and APRInstrumentation.debug == true }
    self.performanceBreadcrumb, self.performanceBreadcrumbAt = nil, nil
    if APRInstrumentation then APRInstrumentation.ResetLog() end
    if self.ResourceMonitor then self.ResourceMonitor:Reset() end
    if self.SetPerformanceScopes then self:SetPerformanceScopes(self.performanceLogging) end
end

function APR:SetPerformanceCapture(enabled)
    self.performanceLogging = enabled == true
    if enabled then self:ResetPerformanceCapture() end
    if not enabled and self.SetPerformanceScopes then self:SetPerformanceScopes(false) end
    if not enabled and self.ResourceMonitor then self.ResourceMonitor:Stop() end
    if not enabled and APRData.PerformanceLog then APRData.PerformanceLog.stoppedAt = Now() end
end

function APR:StartPerformanceSample()
    if not self.performanceLogging then return nil end
    return debugprofilestop()
end

local function BoundedName(collection, name, log, counterKey)
    if collection[name] then return name end
    local count = log[counterKey] or 0
    if count >= METRIC_LIMIT then return "Other" end
    log[counterKey] = count + ²
    return name
end

function APR:CountPerformanceEvent(name)
    if not self.performanceLogging or not APRData or not APRData.PerformanceLog then return end
    local log = APRData.PerformanceLog
    log.counters = log.counters or {}
    name = BoundedName(log.counters, name, log, "counterNames")
    log.counters[name] = (log.counters[name] or 0) + 1
end

function APR:FinishPerformanceSample(name, started, steps, parent)
    if not self.performanceLogging or not started or not APRData then return end
    return self:RecordPerformanceDuration(name, math.max(0, debugprofilestop() - started), steps, parent)
end

-- Only completed main-thread roots contribute. Nested scopes overlap; coroutine
-- workers can span several frames and are measured through their resume caller.
-- Two timestamp buckets suffice for the observer regardless of OnUpdate order.
function APR:RecordPerformanceFrameWork(name, elapsed)
    local log = APRData and APRData.PerformanceLog
    if not self.performanceLogging or not log then return end
    local now = Now()
    local current = log.frameWork
    if not current or current.time ~= now then
        local recycled = log.previousFrameWork
        log.previousFrameWork = current
        -- The observer copies scalar values; only these two working frames stay live.
        current = recycled or {}
        current.time, current.ms, current.count, current.peakMs, current.source = now, 0, 0, 0, nil
        log.frameWork = current
    end
    current.ms, current.count = current.ms + elapsed, current.count + 1
    if elapsed >= current.peakMs then current.peakMs, current.source = elapsed, name end
end

function APR:RecordPerformanceDuration(name, elapsed, steps, parent, ownMs, failure)
    if not self.performanceLogging or not APRData then return end
    local log = APRData.PerformanceLog
    if not log then return end
    local now = Now()
    name = BoundedName(log.summary, name, log, "metricNames")
    local summary = log.summary[name] or { count = 0, totalMs = 0, maxMs = 0 }
    log.summary[name] = summary
    summary.count = summary.count + 1
    summary.totalMs = summary.totalMs + elapsed
    summary.maxMs = math.max(summary.maxMs, elapsed)
    if ownMs then summary.selfMs = (summary.selfMs or 0) + ownMs end
    if failure then summary.errors = (summary.errors or 0) + 1 end
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
    if bucket.count == 0 or elapsed > bucket.maxMs then
        bucket.peakName, bucket.peakRoute = name, self.ActiveRoute
        bucket.peakStep = self.PlayerID and APRData[self.PlayerID] and APRData[self.PlayerID][self.ActiveRoute]
    end
    bucket.count, bucket.totalMs = bucket.count + 1, bucket.totalMs + elapsed
    bucket.maxMs = math.max(bucket.maxMs, elapsed)
    if elapsed >= (log.slowThresholdMs or 10) then
        bucket.slowCount = (bucket.slowCount or 0) + 1
        log.cursor = (log.cursor or 0) % SLOW_LIMIT + 1
        log.slow[log.cursor] = {
            name = name, ms = elapsed, time = now, route = self.ActiveRoute, steps = steps,
            step = self.PlayerID and APRData[self.PlayerID] and APRData[self.PlayerID][self.ActiveRoute],
            parent = parent or (APRInstrumentation and APRInstrumentation.CurrentName()) or self.performanceScope,
            selfMs = ownMs, failure = failure,
            breadcrumb = self.performanceBreadcrumb, breadcrumbAt = self.performanceBreadcrumbAt,
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

-- Tooltip data is derived from the displayed bucket, which may belong to a frozen graph.
function APR:GetPerformanceBucketDetails(bucket, finalSecond)
    if not bucket then return end
    local count = bucket.count or 0
    return {
        offset = bucket.second - finalSecond, count = count, totalMs = bucket.totalMs or 0,
        maxMs = bucket.maxMs or 0, average = (bucket.totalMs or 0) / math.max(1, count),
        slowCount = bucket.slowCount, peakName = bucket.peakName, route = bucket.peakRoute, step = bucket.peakStep,
        slowThresholdMs = APRData.PerformanceLog and APRData.PerformanceLog.slowThresholdMs or 10,
    }
end

-- The live viewer may reuse its own row buffer; exports still receive independent snapshots.
function APR:GetPerformanceRows(mode, sortKey, query, displayName, reusableRows)
    if mode == "logs" then return self:GetDiagnosticRows(query) end
    local log = APRData and APRData.PerformanceLog
    local rows = mode ~= "slow" and reusableRows or nil
    rows = rows or {}
    if not log then
        for index = #rows, 1, -1 do rows[index] = nil end
        return rows
    end
    local count = 0
    local function nextRow()
        count = count + 1
        local row = rows[count] or {}
        rows[count] = row
        return row
    end
    query = string.lower(query or "")
    -- Search translated display labels while keeping saved metric identifiers stable.
    local function matches(name)
        return query == "" or string.lower(name):find(query, 1, true)
            or (displayName and string.lower(displayName(name)):find(query, 1, true))
    end
    if mode == "slow" then
        for offset = 0, #log.slow - 1 do
            local entry = log.slow[((log.cursor or #log.slow) - offset - 1) % SLOW_LIMIT + 1]
            if entry and matches(entry.name) then rows[#rows + 1] = entry end
        end
    elseif mode == "counters" then
        for name, count in pairs(log.counters or {}) do
            if matches(name) then
                local row = nextRow()
                row.name, row.count = name, count
                row.totalMs, row.maxMs, row.selfMs, row.errors = nil, nil, nil, nil
                row.average, row.histogram = nil, nil
            end
        end
    else
        for name, summary in pairs(log.summary) do
            if matches(name) then
                local row = nextRow()
                row.name, row.count, row.totalMs = name, summary.count, summary.totalMs
                row.maxMs, row.selfMs, row.errors = summary.maxMs, summary.selfMs, summary.errors
                row.average = summary.totalMs / math.max(1, summary.count)
                local source = summary.histogram
                if source then
                    -- Keep histogram bands consistent with this row's captured count.
                    local histogram = row.histogram or {}
                    histogram[1], histogram[2], histogram[3], histogram[4] = source[1], source[2], source[3], source[4]
                    row.histogram = histogram
                else
                    row.histogram = nil
                end
            end
        end
    end
    if mode ~= "slow" then
        for index = #rows, count + 1, -1 do rows[index] = nil end
        sortKey = mode == "counters" and "count" or sortKey or "totalMs"
        table.sort(rows, function(a, b)
            if a[sortKey] == b[sortKey] then return a.name < b.name end
            return (a[sortKey] or 0) > (b[sortKey] or 0)
        end)
    end
    return rows
end
