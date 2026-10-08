-- Displays bounded APR instrumentation with a live peak chart, sortable aggregates and slow-call context.
-- Only a visible dashboard refreshes, once per second; capturing itself creates no ticker or graph frames.

APR.PerformanceDashboard = { mode = "summary", sort = "totalMs", query = "", graphMetric = "maxMs" }
local Dashboard, UI = APR.PerformanceDashboard, APR.UI
local function T(key) return APR:LocalizeUI(key) end

-- One hover target covers all seconds, including empty buckets; it allocates no per-bar frames.
function Dashboard:UpdateGraphTooltip(force)
    if not self.graphHovered or not self.timeline or #self.timeline == 0 then return end
    local cursorX = GetCursorPosition()
    local left = self.plot:GetLeft()
    if not left then return end
    local width = math.max(1, self.plot:GetWidth() - 8)
    local x = cursorX / self.plot:GetEffectiveScale() - left - 4
    local index = math.max(1, math.min(120, math.floor(x / width * 120) + 1))
    if not force and self.hoverIndex == index then return end
    self.hoverIndex = index
    local details = APR:GetPerformanceBucketDetails(self.timeline[index], self.timeline[#self.timeline].second)
    self.hoverLine:ClearAllPoints()
    self.hoverLine:SetPoint("TOPLEFT", self.plot, "TOPLEFT", 4 + (index - 0.5) * width / 120, -4)
    self.hoverLine:SetHeight(math.max(1, self.plot:GetHeight() - 8))
    self.hoverLine:Show()
    GameTooltip:SetOwner(self.plot, "ANCHOR_CURSOR")
    APR:SetTooltipText(GameTooltip, APR:LocalizeUI("PERF_SECOND", details.offset), "general", "accent")
    local function line(key, value)
        APR:AddTooltipDoubleLine(GameTooltip, T(key), tostring(value), "general", "muted", "base")
    end
    line("CALLS", details.count)
    line("TOTAL", string.format("%.3f", details.totalMs))
    line("AVERAGE", string.format("%.3f", details.average))
    line("MAX", string.format("%.3f", details.maxMs))
    if details.count == 0 then
        APR:AddTooltipLine(GameTooltip, T("PERF_EMPTY_SECOND"), "general", "muted", true)
    else
        line("PERF_SLOW_COUNT", details.slowCount or T("DATA_UNAVAILABLE"))
        line("PERF_PEAK_CALL", details.peakName or T("DATA_UNAVAILABLE"))
        if details.route then APR:AddTooltipLine(GameTooltip, details.route, "general", "base", true) end
        if details.step then line("STATUS_STEP", details.step) end
    end
    APR:AddTooltipLine(GameTooltip, T(self.frozenTimeline and "PERF_GRAPH_FROZEN" or "PERF_GRAPH_LIVE"), "general", "muted", true)
    GameTooltip:Show()
end

function Dashboard:RefreshGraph()
    self.timeline = self.frozenTimeline or APR:GetPerformanceTimeline()
    local maximum, metric = 1, self.graphMetric
    for _, bucket in ipairs(self.timeline) do maximum = math.max(maximum, bucket[metric] or 0) end
    self.axis:SetText(metric == "count" and string.format("%d\n\n\n0", maximum) or string.format("%.2f ms\n\n\n0", maximum))
    local width, height = math.max(1, self.plot:GetWidth() - 8), math.max(1, self.plot:GetHeight() - 8)
    for index = 1, 120 do
        local bar, bucket = self.bars[index], self.timeline[index]
        local value = bucket and bucket[metric] or 0
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOMLEFT", self.plot, "BOTTOMLEFT", 4 + (index - 1) * width / 120, 4)
        bar:SetSize(math.max(1, width / 120 - 1), math.max(1, value / maximum * height))
        bar:SetColorTexture(unpack(APR:GetThemeColor(bucket and bucket.maxMs >= 10 and "warning" or "accent")))
        bar:SetShown(value > 0)
    end
    self.freeze:SetText(T(self.frozenTimeline and "PERF_RESUME_GRAPH" or "PERF_FREEZE_GRAPH"))
    self.graphHint:SetText(T(self.frozenTimeline and "PERF_GRAPH_FROZEN" or "PERF_GRAPH_LIVE"))
    self:UpdateGraphTooltip(true)
end

function Dashboard:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    local log = APRData.PerformanceLog
    self.capture:SetText(APR.performanceLogging and T("STOP") or T("CAPTURE"))
    local calls, total, peak = 0, 0, 0
    for _, summary in pairs(log and log.summary or {}) do
        calls, total = calls + summary.count, total + summary.totalMs
        peak = math.max(peak, summary.maxMs)
    end
    self.overview:SetText(string.format("%s: %d   |   %s: %.2f ms   |   %s: %.2f ms", T("CALLS"), calls, T("TOTAL"), total, T("MAX"), peak))
    self:RefreshGraph()
    local rows = APR:GetPerformanceRows(self.mode, self.sort, self.query)
    self.list:SetItems(rows, true)
    self.empty:SetShown(#rows == 0)
end

function Dashboard:Create()
    local frame = UI:Window("APRPerformanceDashboard", T("PERFORMANCE"), 1040, 780)
    frame:SetResizeBounds(math.min(680, UIParent:GetWidth() - 40), math.min(660, UIParent:GetHeight() - 60))
    self.frame, self.bars = frame, {}
    local root = frame.content
    self.capture = UI:Button(root, T("CAPTURE"), 180, function()
        self.frozenTimeline = nil
        APR:SetPerformanceCapture(not APR.performanceLogging); self:Refresh()
    end)
    self.capture:SetPoint("TOPLEFT")
    local clear = UI:Button(root, T("CLEAR"), 140, function()
        self.frozenTimeline = nil
        APR:ResetPerformanceCapture(); self:Refresh()
    end)
    clear:SetPoint("LEFT", self.capture, "RIGHT", 10, 0)
    local export = UI:Button(root, T("EXPORT"), 140, function()
        UI:ShowTextReport(T("PERFORMANCE"), APR:FormatDebugTable(APRData.PerformanceLog or {}))
    end)
    export:SetPoint("LEFT", clear, "RIGHT", 10, 0)
    self.overview = UI:Label(root, "", 14)
    self.overview:SetPoint("TOPLEFT", 0, -46)
    self.overview:SetPoint("TOPRIGHT", 0, -46)
    local graphMode = UI:Select(root, 250, function(value) self.graphMetric = value; self:RefreshGraph() end)
    graphMode:SetPoint("TOPLEFT", 0, -76)
    graphMode:SetOptions({{value = "maxMs", label = T("PERF_METRIC_MAX")},
        {value = "totalMs", label = T("PERF_METRIC_TOTAL")}, {value = "count", label = T("PERF_METRIC_CALLS")}}, self.graphMetric)
    self.freeze = UI:Button(root, T("PERF_FREEZE_GRAPH"), 220, function()
        self.frozenTimeline = not self.frozenTimeline and APR:DeepCopyTable(self.timeline) or nil
        self:RefreshGraph()
    end)
    self.freeze:SetPoint("LEFT", graphMode, "RIGHT", 10, 0)
    self.graphHint = UI:Label(root, "", 11, "muted")
    self.graphHint:SetPoint("TOPLEFT", 0, -113)
    self.graphHint:SetPoint("TOPRIGHT", 0, -113)
    self.plot = UI:Panel(root)
    self.plot:SetPoint("TOPLEFT", 75, -139)
    self.plot:SetPoint("TOPRIGHT", 0, -139)
    self.plot:SetHeight(108)
    self.plot:EnableMouse(true)
    for index = 1, 3 do
        local grid = self.plot:CreateTexture(nil, "BACKGROUND")
        grid:SetPoint("TOPLEFT", 4, -4 - index * 25)
        grid:SetPoint("TOPRIGHT", -4, -4 - index * 25)
        grid:SetHeight(1)
        grid:SetColorTexture(0.6, 0.5, 0.3, 0.25)
    end
    for index = 1, 120 do self.bars[index] = self.plot:CreateTexture(nil, "ARTWORK") end
    self.hoverLine = self.plot:CreateTexture(nil, "OVERLAY")
    self.hoverLine:SetWidth(1)
    self.hoverLine:SetColorTexture(1, 1, 1, 0.8)
    self.hoverLine:Hide()
    self.plot:SetScript("OnEnter", function() self.graphHovered = true; self:UpdateGraphTooltip(true) end)
    self.plot:SetScript("OnLeave", function()
        self.graphHovered, self.hoverIndex = nil, nil
        self.hoverLine:Hide()
        GameTooltip:Hide()
    end)
    self.axis = UI:Label(root, "", 11, "muted")
    self.axis:SetPoint("TOPLEFT", 0, -142)
    local interval = UI:Label(root, "-119 s", 11, "muted")
    interval:SetPoint("TOPLEFT", self.plot, "BOTTOMLEFT", 0, -4)
    local now = UI:Label(root, "0 s", 11, "muted")
    now:SetPoint("TOPRIGHT", self.plot, "BOTTOMRIGHT", 0, -4)
    local mode = UI:Select(root, 220, function(value) self.mode = value; self:Refresh() end)
    mode:SetPoint("TOPLEFT", 0, -280)
    mode:SetOptions({ {value = "summary", label = T("OVERVIEW")}, {value = "slow", label = T("SLOW_CALLS")},
        {value = "counters", label = T("COUNTERS")} }, self.mode)
    local sort = UI:Select(root, 190, function(value) self.sort = value; self:Refresh() end)
    sort:SetPoint("LEFT", mode, "RIGHT", 10, 0)
    sort:SetOptions({ {value = "totalMs", label = T("TOTAL")}, {value = "maxMs", label = T("MAX")},
        {value = "average", label = T("AVERAGE")}, {value = "count", label = T("CALLS")} }, self.sort)
    self.search = UI:SearchBox(root, 200, T("SEARCH"), function(query) self.query = query; self:Refresh() end)
    self.search:SetPoint("TOPLEFT", 0, -320)
    self.search:SetPoint("TOPRIGHT", 0, -320)
    local scroll = UI:Scroll(root)
    scroll:SetPoint("TOPLEFT", 0, -362)
    scroll:SetPoint("BOTTOMRIGHT", -26, 38)
    self.list = APR.VirtualList:New(scroll, function(parent)
        local row = UI:Panel(parent)
        row.title = UI:Label(row, "", 13, "accent")
        row.title:SetPoint("TOPLEFT", 10, -7)
        row.title:SetPoint("TOPRIGHT", -10, -7)
        row.detail = UI:Label(row, "", 11)
        row.detail:SetPoint("TOPLEFT", 10, -29)
        row.detail:SetPoint("BOTTOMRIGHT", -10, 4)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(control)
            local histogram = control.item and control.item.histogram
            if not histogram then return end
            GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
            APR:SetTooltipText(GameTooltip, control.item.name, "general", "accent")
            APR:AddTooltipLine(GameTooltip, string.format("<1 ms: %d\n1–3 ms: %d\n3–10 ms: %d\n≥10 ms: %d", unpack(histogram)), "general", "base", true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return row
    end, function(row, record)
        row.title:SetText(record.name)
        if self.mode == "slow" then
            row.detail:SetText(string.format("%.2f ms   |   %s   |   %s %s", record.ms, record.route or T("NO_ROUTE"), T("STEPS"), tostring(record.step or "?")))
        elseif self.mode == "counters" then row.detail:SetText(T("CALLS") .. ": " .. record.count)
        else
            row.detail:SetText(string.format("%s: %d   |   %s: %.2f ms   |   %s: %.3f ms   |   %s: %.2f ms", T("CALLS"), record.count,
                T("TOTAL"), record.totalMs, T("AVERAGE"), record.average, T("MAX"), record.maxMs))
        end
    end, 62)
    self.empty = UI:Label(root, T("NO_CAPTURE"), 13, "muted")
    self.empty:SetPoint("TOPLEFT", 12, -378)
    self.empty:SetPoint("TOPRIGHT", -26, -378)
    local note = UI:Label(root, T("PERF_LIMITS"), 11, "muted")
    note:SetPoint("BOTTOMLEFT")
    note:SetPoint("BOTTOMRIGHT")
    frame:HookScript("OnShow", function()
        self.elapsed = 0
        self.hoverElapsed = 0
        frame:SetScript("OnUpdate", function(_, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 1 then self.elapsed = 0; self:Refresh() end
            if self.graphHovered then
                self.hoverElapsed = self.hoverElapsed + elapsed
                if self.hoverElapsed >= 0.05 then self.hoverElapsed = 0; self:UpdateGraphTooltip() end
            end
        end)
        self:Refresh()
    end)
    frame:HookScript("OnHide", function()
        frame:SetScript("OnUpdate", nil)
        self.graphHovered, self.hoverIndex = nil, nil
        self.hoverLine:Hide()
    end)
    self.plot:HookScript("OnSizeChanged", function() self:Refresh() end)
end

function Dashboard:Show()
    if not self.frame then self:Create() end
    self.frame:Show()
    self:Refresh()
end
