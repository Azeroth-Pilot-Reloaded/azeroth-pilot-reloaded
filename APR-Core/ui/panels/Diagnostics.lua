-- Presents the full status in readable sections, with optional formatted Lua in the same window.
-- Copying freezes the current text while focused; visible event updates are coalesced and cancelled on hide.

local UI = APR.UI
local function T(key) return APR:LocalizeUI(key) end

local function LayoutSections(frame)
    local width = math.max(260, frame:GetWidth() - 58)
    frame.body:SetWidth(width)
    local columns = width >= 780 and 2 or 1
    local columnWidth = (width - (columns - 1) * 12) / columns
    local y, rowHeight = 0, 0
    for index, section in ipairs(frame.sections) do
        local column = (index - 1) % columns
        if column == 0 and index > 1 then y, rowHeight = y + rowHeight + 12, 0 end
        section:ClearAllPoints()
        section:SetPoint("TOPLEFT", frame.body, "TOPLEFT", column * (columnWidth + 12), -y)
        section:SetWidth(columnWidth)
        section.heading:SetWidth(columnWidth - 24)
        section.text:SetWidth(columnWidth - 24)
        local headingHeight = section.heading:GetStringHeight()
        section.text:ClearAllPoints()
        section.text:SetPoint("TOPLEFT", 12, -20 - headingHeight)
        local height = math.max(80, headingHeight + section.text:GetStringHeight() + 34)
        section:SetHeight(height)
        rowHeight = math.max(rowHeight, height)
    end
    frame.body:SetHeight(math.max(1, y + rowHeight))
end

local function SetReportShown(frame, shown)
    frame.reportShown = shown == true
    frame.reportScroll:SetShown(frame.reportShown)
    frame.reportLabel:SetShown(frame.reportShown)
    frame.toggleReport:SetText(T(frame.reportShown and "HIDE_LUA" or "SHOW_LUA"))
    local reportHeight = math.min(260, math.max(140, (frame:GetHeight() - 74) * 0.38))
    frame.reportScroll:SetHeight(reportHeight)
    frame.reportLabel:ClearAllPoints()
    frame.reportLabel:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 0, reportHeight + 94)
    frame.infoScroll:ClearAllPoints()
    frame.infoScroll:SetPoint("TOPLEFT")
    frame.infoScroll:SetPoint("BOTTOMRIGHT", -26, frame.reportShown and reportHeight + 126 or 88)
    if frame.reportShown and frame.snapshot then
        if not frame.report then
            frame.report = APR:FormatDebugTable(frame.snapshot)
            frame.text:SetText(frame.report)
            frame.text:SetCursorPosition(0)
        end
    else
        frame.text:ClearFocus()
    end
end

function APR:RefreshDiagnostics(resetFocus)
    local frame = self.DiagnosticsFrame
    if not frame or not frame:IsShown() then return end
    if not resetFocus and frame.text.HasFocus and frame.text:HasFocus() then return end
    frame.snapshot = self:BuildDiagnosticSnapshot(frame.includeIdentity)
    frame.report = nil
    local models = self:BuildDiagnosticSections(frame.snapshot)
    for index, model in ipairs(models) do
        local section = frame.sections[index]
        if not section then
            section = UI:Panel(frame.body)
            section.heading = UI:Label(section, "", 15, "accent")
            section.heading:SetPoint("TOPLEFT", 12, -10)
            section.text = UI:Label(section, "", 12)
            section.text:SetWordWrap(true)
            frame.sections[index] = section
        end
        section.heading:SetText(model.title)
        section.text:SetText(table.concat(model.lines, "\n"))
    end
    LayoutSections(frame)
    if frame.reportShown then
        frame.report = self:FormatDebugTable(frame.snapshot)
        frame.text:SetText(frame.report)
        if resetFocus then frame.text:SetCursorPosition(0); frame.text:ClearFocus() end
    end
    frame.undo:SetEnabled(frame.snapshot.canUndo and not InCombatLockdown())
end

function APR:ShowDiagnostics()
    local frame = self.DiagnosticsFrame
    if not frame then
        frame = UI:Window("APRDiagnostics", T("DIAGNOSTICS"), 980, 780)
        frame:SetResizeBounds(math.min(740, UIParent:GetWidth() - 40), math.min(660, UIParent:GetHeight() - 60))
        self.DiagnosticsFrame = frame
        frame.sections = {}
        local root = frame.content
        frame.infoScroll = UI:Scroll(root)
        frame.body = CreateFrame("Frame", nil, frame.infoScroll)
        frame.body:SetSize(900, 1)
        frame.infoScroll:SetScrollChild(frame.body)
        frame.reportScroll, frame.text = UI:CopyBox(root)
        frame.reportScroll:SetPoint("BOTTOMLEFT", 0, 88)
        frame.reportScroll:SetPoint("BOTTOMRIGHT", -26, 88)
        frame.reportLabel = UI:Label(root, T("LUA_REPORT"), 13, "accent")
        frame.undo = UI:Button(root, T("UNDO"), 280, function() self:UndoManualSkip(); self:RefreshDiagnostics(true) end)
        frame.undo:SetPoint("BOTTOMLEFT", 0, 42)
        local refresh = UI:Button(root, T("REFRESH"), 120, function() self:RefreshDiagnostics(true) end)
        refresh:SetPoint("LEFT", frame.undo, "RIGHT", 10, 0)
        frame.toggleReport = UI:Button(root, T("SHOW_LUA"), 230, function()
            SetReportShown(frame, not frame.reportShown)
        end)
        frame.toggleReport:SetPoint("LEFT", refresh, "RIGHT", 10, 0)
        frame.redact = UI:Button(root, "[x] " .. T("REDACT"), 310, function(button)
            frame.includeIdentity = not frame.includeIdentity
            button:SetText((frame.includeIdentity and "[ ] " or "[x] ") .. T("REDACT"))
            self:RefreshDiagnostics(true)
        end)
        frame.redact:SetPoint("BOTTOMLEFT")
        frame.copy = UI:Button(root, T("EXPORT"), 160, function()
            SetReportShown(frame, true)
            frame.text:SetFocus()
            frame.text:HighlightText()
        end)
        frame.copy:SetPoint("BOTTOMRIGHT")
        UI:Tooltip(frame.copy, T("COPY_HINT"))
        frame:HookScript("OnSizeChanged", function()
            SetReportShown(frame, frame.reportShown)
            LayoutSections(frame)
        end)
        frame:RegisterEvent("QUEST_LOG_UPDATE")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:SetScript("OnEvent", function()
            -- Combat must disable undo immediately, even while a report is being copied.
            frame.undo:SetEnabled(self:CanUndoManualSkip() and not InCombatLockdown())
            if not frame:IsShown() or frame.refreshTimer then return end
            frame.refreshTimer = C_Timer.NewTimer(0.5, function()
                frame.refreshTimer = nil
                self:RefreshDiagnostics()
            end)
        end)
        frame:HookScript("OnHide", function()
            if frame.refreshTimer then frame.refreshTimer:Cancel(); frame.refreshTimer = nil end
            frame.text:ClearFocus()
        end)
        SetReportShown(frame, false)
    end
    frame:Show()
    self:RefreshDiagnostics(true)
end

function APR:CreateDiagnosticsEntryPoint()
    local anchor = _G.CurrentStepFrameSettingsButton
    if not anchor or self.diagnosticsButton then return end
    local button = UI:Button(anchor:GetParent(), "?", 22, function() self:ShowDiagnostics() end)
    button:SetHeight(22)
    button:SetPoint("RIGHT", anchor, "LEFT", -3, 0)
    local title = anchor:GetParent().Text
    if title then title:SetPoint("RIGHT", button, "LEFT", -6, 0) end
    UI:Tooltip(button, T("EXPLAIN"))
    self.diagnosticsButton = button
end
