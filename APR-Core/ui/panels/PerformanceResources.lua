-- Task-manager-style APR CPU and memory charts, with capture-wide growth and retained-data counts.
-- Resource graphs share a time window; freezing affects presentation only, never the sampler.

APR.PerformanceResources = {}
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local View, UI = APR.PerformanceResources, APR.UI
View.__index = View
local function Memory(kb, signed)
    return kb and string.format(signed and "%+.2f" or "%.2f", kb / 1024) .. " " .. L["UI_MEMORY_UNIT"] or "—"
end
local function Count(value) return value and (value >= 10000 and "10000+" or tostring(value)) or "—" end

function View:Tooltip(frame, point, key)
    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    APR:SetTooltipText(GameTooltip, key == "cpuPercent" and "CPU · APR" or L["UI_RESOURCE_MEMORY"], "general", "accent")
    local function line(label, value)
        APR:AddTooltipDoubleLine(GameTooltip, label, tostring(value), "general", "muted", "base")
    end
    line(L["UI_RESOURCE_TIME"], APR:FormatSeconds(point.from - self.view.finish) .. " – " .. APR:FormatSeconds(point.to - self.view.finish))
    local sample = key == "cpuPercent" and point.cpuSample or point.memorySample
    if not sample or point[key] == nil then
        APR:AddTooltipLine(GameTooltip, UNAVAILABLE, "general", "muted", true)
    elseif key == "cpuPercent" then
        line(L["UI_RESOURCE_CPU_SHARE"], string.format("%.2f %%", sample.cpuPercent))
        line(L["UI_RESOURCE_CPU_TIME"], APR:FormatMilliseconds(sample.cpuMs, true))
        line(L["UI_RESOURCE_FRAME_TIME"], APR:FormatMilliseconds(sample.frameMs, true))
        if sample.fps then line(FRAMERATE_LABEL, string.format("%.0f", sample.fps)) end
    else
        line(L["UI_RESOURCE_MEMORY"], Memory(sample.memoryKB))
        line(L["UI_RESOURCE_MEMORY_AGE"], APR:FormatSeconds(sample.time - sample.memoryAt))
        if sample.memoryScanMs then line(L["UI_RESOURCE_SCAN_TIME"], APR:FormatMilliseconds(sample.memoryScanMs)) end
    end
    if sample then
        if sample.route then APR:AddTooltipLine(GameTooltip, sample.route, "general", "base", true) end
        if sample.step then line(L["CURRENT_STEP"], sample.step) end
    end
    APR:AddTooltipLine(GameTooltip, key == "cpuPercent" and L["UI_RESOURCE_CPU_HELP"] or L["UI_RESOURCE_MEMORY_HELP"], "general", "muted", true)
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
    card.now = UI:Label(card, APR:FormatSeconds(0), 11, "muted")
    card.now:SetPoint("BOTTOMRIGHT", -12, 12)
    return card
end

function View:New(parent)
    local view = setmetatable({frame = CreateFrame("Frame", nil, parent), duration = 120}, self)
    view.frame:SetAllPoints()
    view.cpu = CreateCard(view, "CPU · APR", {0.25, 0.72, 1})
    view.memory = CreateCard(view, L["UI_RESOURCE_MEMORY"], {0.73, 0.48, 1})
    view.range = UI:Select(view.frame, 165, function(value)
        view.duration, view.frozenView = value, nil
        view:Refresh()
    end)
    view.range:SetOptions({{value = 120, label = string.format(D_MINUTES, 2)},
        {value = 300, label = string.format(D_MINUTES, 5)}, {value = 600, label = string.format(D_MINUTES, 10)}}, 120)
    view.freeze = UI:Button(view.frame, L["UI_PERF_FREEZE_GRAPH"], 225, function()
        view.frozenView = not view.frozenView and view.view or nil
        view:Refresh()
    end)
    view.state = UI:Label(view.frame, "", 11, "muted")
    view.state:SetJustifyH("RIGHT")
    view.summary = UI:Label(view.frame, "", 12)
    view.summary:SetJustifyV("TOP")
    view.counts = UI:Label(view.frame, "", 12)
    view.counts:SetJustifyV("TOP")
    view.note = UI:Label(view.frame, L["UI_RESOURCE_MEMORY_HELP"], 11, "muted")
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
    self.cpu.graph:SetData(view.points, "cpuPercent", 100, function(value) return string.format("%.0f %%", value) end)
    self.memory.graph:SetData(view.points, "memoryKB", 1024, Memory)
    self.cpu.value:SetText(sample.cpuPercent and string.format("%.2f %%", sample.cpuPercent) or "—")
    self.memory.value:SetText(Memory(sample.memoryKB))
    local fps = sample.fps and string.format("%.0f", sample.fps) or "—"
    self.cpu.detail:SetText(sample.cpuMs and (L["UI_RESOURCE_CPU_TIME"] .. ": " .. APR:FormatMilliseconds(sample.cpuMs, true)
        .. "\n" .. FRAMERATE_LABEL .. " " .. fps)
        or (view.latest and L["UI_RESOURCE_CPU_UNAVAILABLE"] or L["UI_RESOURCE_WAITING"]))
    self.memory.detail:SetText(sample.memoryKB and string.format(L["UI_RESOURCE_MEMORY_DETAIL"], Memory(view.peakMemoryKB),
        math.max(0, view.finish - sample.memoryAt)) or (view.latest and L["UI_RESOURCE_MEMORY_UNAVAILABLE"] or L["UI_RESOURCE_WAITING"]))
    local delta = sample.memoryKB and view.firstMemoryKB and sample.memoryKB - view.firstMemoryKB
    local elapsed = sample.memoryAt and view.firstMemoryAt and sample.memoryAt - view.firstMemoryAt
    local rate = delta and elapsed and elapsed > 0 and Memory(delta * 60 / elapsed, true) or "—"
    self.summary:SetText(string.format(L["UI_RESOURCE_MEMORY_SUMMARY"], Memory(view.firstMemoryKB), Memory(delta, true), rate))
    self.counts:SetText(string.format(L["UI_RESOURCE_RETAINED"], Count(sample.routeCache), Count(sample.mapCache), Count(sample.stepModels)))
    self.freeze:SetText(self.frozenView and L["UI_PERF_RESUME_GRAPH"] or L["UI_PERF_FREEZE_GRAPH"])
    self.state:SetText(self.frozenView and L["UI_RESOURCE_FROZEN"] or APR.performanceLogging and L["UI_RESOURCE_LIVE"] or L["UI_RESOURCE_STOPPED"])
    self.cpu.interval:SetText(string.format(D_MINUTES, self.duration / 60))
    self.memory.interval:SetText(string.format(D_MINUTES, self.duration / 60))
end
