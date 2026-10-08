-- Displays bounded APR instrumentation with a live peak chart, sortable aggregates and slow-call context.
-- Only a visible dashboard refreshes, once per second; capturing itself creates no ticker or graph frames.

APR.PerformanceDashboard = { mode = "summary", sort = "totalMs", query = "" }
local Dashboard, UI = APR.PerformanceDashboard, APR.UI
local function T(key) return APR:LocalizeUI(key) end

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
    local timeline, maximum = APR:GetPerformanceTimeline(), 1
    for _, bucket in ipairs(timeline) do maximum = math.max(maximum, bucket.maxMs) end
    self.axis:SetText(string.format("%.2f ms\n\n\n0", maximum))
    local width, height = math.max(1, self.plot:GetWidth()), math.max(1, self.plot:GetHeight())
    for index = 1, 120 do
        local bar = self.bars[index]
        local value = timeline[index] and timeline[index].maxMs or 0
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOMLEFT", self.plot, "BOTTOMLEFT", (index - 1) * width / 120, 0)
        bar:SetSize(math.max(1, width / 120 - 1), math.max(1, value / maximum * height))
        bar:SetColorTexture(unpack(APR:GetThemeColor(value >= 10 and "warning" or "accent")))
        bar:SetShown(value > 0)
    end
    local rows = APR:GetPerformanceRows(self.mode, self.sort, self.query)
    self.list:SetItems(rows, true)
    self.empty:SetShown(#rows == 0)
end

function Dashboard:Create()
    local frame = UI:Window("APRPerformanceDashboard", T("PERFORMANCE"), 1040, 780)
    self.frame, self.bars = frame, {}
    local root = frame.content
    self.capture = UI:Button(root, T("CAPTURE"), 180, function()
        APR:SetPerformanceCapture(not APR.performanceLogging); self:Refresh()
    end)
    self.capture:SetPoint("TOPLEFT")
    local clear = UI:Button(root, T("CLEAR"), 140, function() APR:ResetPerformanceCapture(); self:Refresh() end)
    clear:SetPoint("LEFT", self.capture, "RIGHT", 10, 0)
    local export = UI:Button(root, T("EXPORT"), 140, function()
        UI:ShowTextReport(T("PERFORMANCE"), APR:TableToDebugString(APRData.PerformanceLog or {}, true))
    end)
    export:SetPoint("LEFT", clear, "RIGHT", 10, 0)
    self.overview = UI:Label(root, "", 14)
    self.overview:SetPoint("TOPLEFT", 0, -46)
    self.overview:SetPoint("TOPRIGHT", 0, -46)
    local graphTitle = UI:Label(root, T("PERF_GRAPH"), 12, "muted")
    graphTitle:SetPoint("TOPLEFT", 0, -76)
    self.plot = UI:Panel(root)
    self.plot:SetPoint("TOPLEFT", 75, -101)
    self.plot:SetPoint("TOPRIGHT", 0, -101)
    self.plot:SetHeight(92)
    for index = 1, 120 do self.bars[index] = self.plot:CreateTexture(nil, "ARTWORK") end
    self.axis = UI:Label(root, "", 11, "muted")
    self.axis:SetPoint("TOPLEFT", 0, -104)
    local interval = UI:Label(root, "-119 s", 11, "muted")
    interval:SetPoint("TOPLEFT", self.plot, "BOTTOMLEFT", 0, -4)
    local now = UI:Label(root, "0 s", 11, "muted")
    now:SetPoint("TOPRIGHT", self.plot, "BOTTOMRIGHT", 0, -4)
    local mode = UI:Select(root, 220, function(value) self.mode = value; self:Refresh() end)
    mode:SetPoint("TOPLEFT", 0, -226)
    mode:SetOptions({ {value = "summary", label = T("OVERVIEW")}, {value = "slow", label = T("SLOW_CALLS")},
        {value = "counters", label = T("COUNTERS")} }, self.mode)
    local sort = UI:Select(root, 190, function(value) self.sort = value; self:Refresh() end)
    sort:SetPoint("LEFT", mode, "RIGHT", 10, 0)
    sort:SetOptions({ {value = "totalMs", label = T("TOTAL")}, {value = "maxMs", label = T("MAX")},
        {value = "average", label = T("AVERAGE")}, {value = "count", label = T("CALLS")} }, self.sort)
    self.search = UI:SearchBox(root, 200, T("SEARCH"), function(query) self.query = query; self:Refresh() end)
    self.search:SetPoint("TOPLEFT", 0, -266)
    self.search:SetPoint("TOPRIGHT", 0, -266)
    local scroll = UI:Scroll(root)
    scroll:SetPoint("TOPLEFT", 0, -308)
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
    self.empty:SetPoint("TOPLEFT", 12, -324)
    self.empty:SetPoint("TOPRIGHT", -26, -324)
    local note = UI:Label(root, T("PERF_LIMITS"), 11, "muted")
    note:SetPoint("BOTTOMLEFT")
    note:SetPoint("BOTTOMRIGHT")
    frame:HookScript("OnShow", function()
        self.elapsed = 0
        frame:SetScript("OnUpdate", function(_, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 1 then self.elapsed = 0; self:Refresh() end
        end)
        self:Refresh()
    end)
    frame:HookScript("OnHide", function() frame:SetScript("OnUpdate", nil) end)
    self.plot:HookScript("OnSizeChanged", function() self:Refresh() end)
end

function Dashboard:Show()
    if not self.frame then self:Create() end
    self.frame:Show()
    self:Refresh()
end
