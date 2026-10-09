-- Samples WoW's APR CPU attribution every second; memory scans are explicitly requested.
-- UpdateAddOnMemoryUsage can block for hundreds of milliseconds, so never run it on a ticker.

APR.ResourceMonitor = {}
local Monitor = APR.ResourceMonitor
local SAMPLE_LIMIT, COUNT_INTERVAL = 600, 5

local function Read(api, ...)
    if type(api) ~= "function" then return end
    local ok, value = pcall(api, ...)
    if ok and (not APR.CanAccessValue or APR:CanAccessValue(value)) then return value end
end

local function Number(value)
    if type(value) == "number" and value == value and value >= 0 and value < math.huge then return value end
end

local function CountEntries(entries)
    local count = 0
    for _ in pairs(entries or {}) do
        count = count + 1
        if count == 10000 then break end
    end
    return count
end

function Monitor:ScanMemory()
    if not APR.performanceLogging or not APRData or not APRData.PerformanceLog then return end
    self.memoryKB, self.memoryAt, self.scanMs = nil, nil, nil
    if type(UpdateAddOnMemoryUsage) == "function" and type(GetAddOnMemoryUsage) == "function" then
        local started = debugprofilestop()
        local ok = pcall(UpdateAddOnMemoryUsage)
        self.scanMs = math.max(0, debugprofilestop() - started)
        APR:FinishPerformanceSample("ResourceMemoryScan", started)
        if ok then self.memoryKB = Number(Read(GetAddOnMemoryUsage, "APR")) end
    end
    if self.memoryKB then self.memoryAt = GetTime() end
    self:Sample(true)
end

function Monitor:Sample(force)
    if not APR.performanceLogging then return end
    local log = APRData and APRData.PerformanceLog
    if not log then return end
    local now = GetTime()
    local resources = log.resources
    if not resources then
        resources = {samples = {}, cursor = 0, count = 0}
        log.resources = resources
    end
    if not force and resources.lastAt and now - resources.lastAt < 1 then return end
    local sample = {time = now, route = APR.ActiveRoute,
        step = APRData[APR.PlayerID] and APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute]}
    local profiler, metric = C_AddOnProfiler, Enum and Enum.AddOnProfilerMetric
    if profiler and metric and Read(profiler.IsEnabled) == true then
        sample.cpuMs = Number(Read(profiler.GetAddOnMetric, "APR", metric.RecentAverageTime))
        sample.frameMs = Number(Read(profiler.GetApplicationMetric, metric.RecentAverageTime))
        if sample.cpuMs and sample.frameMs and sample.frameMs > 0 then
            sample.cpuPercent = sample.cpuMs / sample.frameMs * 100
        end
    end
    sample.fps = Number(Read(GetFramerate))
    if self.memoryKB then
        resources.firstMemoryKB = resources.firstMemoryKB or self.memoryKB
        resources.firstMemoryAt = resources.firstMemoryAt or self.memoryAt
        resources.peakMemoryKB = math.max(resources.peakMemoryKB or 0, self.memoryKB)
    end
    if not self.lastCountAt or now - self.lastCountAt >= COUNT_INTERVAL then
        self.lastCountAt = now
        -- Counts help correlate retained data with memory growth; they are not byte estimates.
        self.counts = {
            routes = CountEntries(APR._effectiveRouteStepsCache),
            maps = CountEntries(APR.ZoneDetection and APR.ZoneDetection.mapInfoCache),
            steps = CountEntries(APR.questOrderList and APR.questOrderList.stepList),
        }
    end
    sample.memoryKB, sample.memoryAt, sample.memoryScanMs = self.memoryKB, self.memoryAt, self.scanMs
    sample.routeCache, sample.mapCache, sample.stepModels = self.counts.routes, self.counts.maps, self.counts.steps
    resources.cursor = resources.cursor % SAMPLE_LIMIT + 1
    resources.samples[resources.cursor] = sample
    resources.count = math.min(resources.count + 1, SAMPLE_LIMIT)
    resources.lastAt = now
end

function Monitor:Stop()
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
end

function Monitor:Reset()
    self:Stop()
    self.lastCountAt, self.memoryKB, self.memoryAt, self.scanMs, self.counts = nil, nil, nil, nil, nil
    if APR.performanceLogging then
        self:Sample()
        self.ticker = C_Timer.NewTicker(1, function() self:Sample() end)
    end
end

-- Build a fixed 120-point view. Wider windows retain CPU peaks and the last memory reading
-- in each time slice; absent samples remain gaps rather than fabricated zeros.
function Monitor:GetView(duration)
    local resources = APRData and APRData.PerformanceLog and APRData.PerformanceLog.resources
    local view = {points = {}, duration = duration, finish = resources and resources.lastAt or GetTime()}
    local start, interval = view.finish - duration, duration / 120
    for index = 1, 120 do view.points[index] = {from = start + (index - 1) * interval, to = start + index * interval} end
    if not resources then return view end
    view.firstMemoryKB, view.firstMemoryAt, view.peakMemoryKB = resources.firstMemoryKB, resources.firstMemoryAt, resources.peakMemoryKB
    for offset = resources.count - 1, 0, -1 do
        local sample = resources.samples[(resources.cursor - offset - 1) % SAMPLE_LIMIT + 1]
        if sample.time > start and sample.time <= view.finish then
            local index = math.max(1, math.min(120, math.ceil((sample.time - start) / interval)))
            local point = view.points[index]
            if sample.cpuPercent and (not point.cpuPercent or sample.cpuPercent >= point.cpuPercent) then
                point.cpuPercent, point.cpuSample = sample.cpuPercent, sample
            end
            point.memoryKB, point.memorySample = sample.memoryKB, sample
            view.latest = sample
        end
    end
    return view
end
