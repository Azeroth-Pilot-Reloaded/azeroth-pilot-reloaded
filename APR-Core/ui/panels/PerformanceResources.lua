-- Task-manager-style APR CPU and memory charts, with capture-wide growth and retained-data counts.
-- Resource graphs share a time window; freezing affects presentation only, never the sampler.

APR.PerformanceResources = {}
local View, UI = APR.PerformanceResources, APR.UI
View.__index = View
local function T(key, ...) return APR:LocalizeUI(key, ...) end
local function Memory(kb) return kb and T("MEMORY_MIB_FORMAT", kb / 1024) or "—" end
local function SignedMemory(kb) return kb and T("MEMORY_CHANGE_FORMAT", kb / 1024) or "—" end
local function Count(value) return value and (value >= 10000 and "10000+" or tostring(value)) or "—" end

function View:Tooltip(frame, point, key)
    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    APR:SetTooltipText(GameTooltip, T(key == "cpuPercent" and "RESOURCE_CPU" or "RESOURCE_MEMORY"), "general", "accent")
    local function line(label, value)
        APR:AddTooltipDoubleLine(GameTooltip, T(label), tostring(value), "general", "muted", "base")
    end
    line("RESOURCE_TIME", T("TIME_RANGE_FORMAT", point.from - self.view.finish, point.to - self.view.finish))
    local sample = key == "cpuPercent" and point.cpuSample or point.memorySample
    if not sample or point[key] == nil then
        APR:AddTooltipLine(GameTooltip, T("DATA_UNAVAILABLE"), "general", "muted", true)
    elseif key == "cpuPercent" then
        line("RESOURCE_CPU_SHARE", T("PERCENT_FORMAT", sample.cpuPercent))
        line("RESOURCE_CPU_TIME", T("TIME_MS_PRECISE_FORMAT", sample.cpuMs))
        line("RESOURCE_FRAME_TIME", T("TIME_MS_PRECISE_FORMAT", sample.frameMs))
        if sample.fps then line("RESOURCE_FPS", string.format("%.0f", sample.fps)) end
    else
        line("RESOURCE_MEMORY", Memory(sample.memoryKB))
        line("RESOURCE_MEMORY_AGE", T("SECONDS_FORMAT", sample.time - sample.memoryAt))
        if sample.memoryScanMs then line("RESOURCE_SCAN_TIME", T("TIME_MS_FORMAT", sample.memoryScanMs)) end
    end
    if sample then
        if sample.route then APR:AddTooltipLine(GameTooltip, sample.route, "general", "base", true) end
        if sample.step then line("STATUS_STEP", sample.step) end
    end
    APR:AddTooltipLine(GameTooltip, T(key == "cpuPercent" and "RESOURCE_CPU_HELP" or "RESOURCE_MEMORY_HELP"), "general", "muted", true)
    GameTooltip:Show()
end

local function CreateCard(view, title, color)
    local card = UI:Panel(view.frame)
    card.title = UI:Label(card, title, 14, "accent")
    card.title:SetPoint("TOPLEFT", 12, -12)
    card.value = UI:Label(card, "—", 24)
    card.value:SetPoint("TOPLEFT", 12, -38)
    card.detail = UI:Label(card, "", 11, "muted")
    card.detail:SetPoint("TOPLEFT", 12, -70)
    card.detail:SetPoint("TOPRIGHT", -12, -70)
    card.graph = APR.TimeSeriesGraph:New(card, color, function(...) view:Tooltip(...) end)
    card.graph.frame:SetPoint("TOPLEFT", 12, -105)
    card.graph.frame:SetPoint("BOTTOMRIGHT", -12, 35)
    card.interval = UI:Label(card, "", 11, "muted")
    card.interval:SetPoint("BOTTOMLEFT", 12, 12)
    card.now = UI:Label(card, T("SECONDS_FORMAT", 0), 11, "muted")
    card.now:SetPoint("BOTTOMRIGHT", -12, 12)
    return card
end

function View:New(parent)
    local view = setmetatable({frame = CreateFrame("Frame", nil, parent), duration = 120}, self)
    view.frame:SetAllPoints()
    view.cpu = CreateCard(view, T("RESOURCE_CPU"), {0.25, 0.72, 1})
    view.memory = CreateCard(view, T("RESOURCE_MEMORY"), {0.73, 0.48, 1})
    view.range = UI:Select(view.frame, 165, function(value)
        view.duration, view.frozenView = value, nil
        view:Refresh()
    end)
    view.range:SetOptions({{value = 120, label = T("RESOURCE_RANGE", 2)},
        {value = 300, label = T("RESOURCE_RANGE", 5)}, {value = 600, label = T("RESOURCE_RANGE", 10)}}, 120)
    view.freeze = UI:Button(view.frame, T("PERF_FREEZE_GRAPH"), 225, function()
        view.frozenView = not view.frozenView and view.view or nil
        view:Refresh()
    end)
    view.state = UI:Label(view.frame, "", 11, "muted")
    view.state:SetJustifyH("RIGHT")
    view.summary = UI:Label(view.frame, "", 12)
    view.summary:SetJustifyV("TOP")
    view.counts = UI:Label(view.frame, "", 12)
    view.counts:SetJustifyV("TOP")
    view.note = UI:Label(view.frame, T("RESOURCE_MEMORY_HELP"), 11, "muted")
    view.note:SetPoint("BOTTOMLEFT")
    view.note:SetPoint("BOTTOMRIGHT")
    view.frame:HookScript("OnSizeChanged", function() view:Layout() end)
    view:Layout()
    return view
end

function View:Layout()
    local width, height = math.max(1, self.frame:GetWidth()), math.max(1, self.frame:GetHeight())
    local cardWidth, cardHeight = (width - 12) / 2, math.max(260, math.min(365, height - 220))
    self.cpu:ClearAllPoints(); self.memory:ClearAllPoints()
    self.cpu:SetPoint("TOPLEFT")
    self.memory:SetPoint("TOPRIGHT")
    self.cpu:SetSize(cardWidth, cardHeight)
    self.memory:SetSize(cardWidth, cardHeight)
    self.range:ClearAllPoints()
    self.range:SetPoint("TOPLEFT", 0, -cardHeight - 12)
    self.freeze:ClearAllPoints()
    self.freeze:SetPoint("LEFT", self.range, "RIGHT", 10, 0)
    self.state:ClearAllPoints()
    self.state:SetPoint("LEFT", self.freeze, "RIGHT", 12, 0)
    self.state:SetPoint("RIGHT", self.frame, "TOPRIGHT", -4, -cardHeight - 27)
    self.summary:ClearAllPoints(); self.counts:ClearAllPoints()
    self.summary:SetPoint("TOPLEFT", 4, -cardHeight - 60)
    self.summary:SetWidth(cardWidth - 8)
    self.counts:SetPoint("TOPLEFT", cardWidth + 16, -cardHeight - 60)
    self.counts:SetWidth(cardWidth - 8)
end

function View:Refresh()
    local log = APRData and APRData.PerformanceLog
    if self.log ~= log then self.log, self.frozenView = log, nil end
    local view = self.frozenView or APR.ResourceMonitor:GetView(self.duration)
    self.view = view
    local sample = view.latest or {}
    self.cpu.graph:SetData(view.points, "cpuPercent", 100, function(value) return T("PERCENT_AXIS_FORMAT", value) end)
    self.memory.graph:SetData(view.points, "memoryKB", 1024, Memory)
    self.cpu.value:SetText(sample.cpuPercent and T("PERCENT_FORMAT", sample.cpuPercent) or "—")
    self.memory.value:SetText(Memory(sample.memoryKB))
    local fps = sample.fps and string.format("%.0f", sample.fps) or "—"
    self.cpu.detail:SetText(sample.cpuMs and T("RESOURCE_CPU_DETAIL", sample.cpuMs, fps)
        or T(view.latest and "RESOURCE_CPU_UNAVAILABLE" or "RESOURCE_WAITING"))
    self.memory.detail:SetText(sample.memoryKB and T("RESOURCE_MEMORY_DETAIL", Memory(view.peakMemoryKB),
        math.max(0, view.finish - sample.memoryAt)) or T(view.latest and "RESOURCE_MEMORY_UNAVAILABLE" or "RESOURCE_WAITING"))
    local delta = sample.memoryKB and view.firstMemoryKB and sample.memoryKB - view.firstMemoryKB
    local elapsed = sample.memoryAt and view.firstMemoryAt and sample.memoryAt - view.firstMemoryAt
    local rate = delta and elapsed and elapsed > 0 and SignedMemory(delta * 60 / elapsed) or "—"
    self.summary:SetText(T("RESOURCE_MEMORY_SUMMARY", Memory(view.firstMemoryKB), SignedMemory(delta), rate))
    self.counts:SetText(T("RESOURCE_RETAINED", Count(sample.routeCache), Count(sample.mapCache), Count(sample.stepModels)))
    self.freeze:SetText(T(self.frozenView and "PERF_RESUME_GRAPH" or "PERF_FREEZE_GRAPH"))
    self.state:SetText(T(self.frozenView and "RESOURCE_FROZEN" or APR.performanceLogging and "RESOURCE_LIVE" or "RESOURCE_STOPPED"))
    self.cpu.interval:SetText(T("RESOURCE_RANGE", self.duration / 60))
    self.memory.interval:SetText(T("RESOURCE_RANGE", self.duration / 60))
end
