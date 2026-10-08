-- Creates a copyable, redacted-by-default snapshot with wait reasons, transitions and runtime health.
-- Refreshes only on request and on relevant events while visible; opening it never changes route progress.

local UI = APR.UI
local function T(key) return APR:LocalizeUI(key) end

function APR:BuildDiagnosticSnapshot(includeIdentity)
    local _, index = self:PeekCurrentStep()
    local reasons, action = self:DescribeStepWait()
    local profile = self:GetSettingsProfile() or {}
    local version, build, _, interface = GetBuildInfo()
    local zone = self.ZoneDetection and self.ZoneDetection.playerContextCache
    local snapshot = {
        addon = self.version, client = version, build = build, interface = interface, locale = GetLocale(),
        route = self.ActiveRoute, step = index, action = action, revision = self.stepRevision,
        reasons = reasons, transitions = self:GetRecentTransitions(), canUndo = self:CanUndoManualSkip(),
        theme = profile.uiTheme or "wow", skin = self:GetSkinProviderName() or "APR",
        combat = InCombatLockdown(), inRouteZone = self.IsInRouteZone,
        routing = { updatePending = self.stepUpdateTimer ~= nil,
            renderPending = self.questOrderList and self.questOrderList.renderRequest ~= nil,
            renderFailed = self.questOrderList and self.questOrderList.renderFailed or false,
            zoneCacheAge = zone and zone.timestamp and math.max(0, GetTime() - zone.timestamp) },
        party = { rejected = self.party and self.party.rejectedMessages or 0,
            lastRejectReason = self.party and self.party.lastRejectReason },
        performance = APRData and APRData.PerformanceLog and APRData.PerformanceLog.summary,
    }
    if includeIdentity then snapshot.player, snapshot.realm = self.Username, GetRealmName() end
    return snapshot
end

function APR:RefreshDiagnostics()
    local frame = self.DiagnosticsFrame
    if not frame or not frame:IsShown() then return end
    local snapshot = self:BuildDiagnosticSnapshot(frame.includeIdentity)
    frame.report = self:TableToDebugString(snapshot, true)
    local heading = T("EXPLAIN") .. "\n\n" .. table.concat(snapshot.reasons, "\n\n")
    frame.explanation:SetText(heading)
    frame.explanationBody:SetHeight(math.max(156, frame.explanation:GetStringHeight() + 12))
    frame.text:SetText(frame.report)
    frame.text:SetCursorPosition(0)
    frame.text:ClearFocus()
    frame.undo:SetEnabled(snapshot.canUndo and not InCombatLockdown())
end

function APR:ShowDiagnostics()
    local frame = self.DiagnosticsFrame
    if not frame then
        frame = UI:Window("APRDiagnostics", T("DIAGNOSTICS"), 980, 700)
        self.DiagnosticsFrame = frame
        local root = frame.content
        local explanationScroll = UI:Scroll(root)
        explanationScroll:SetPoint("TOPLEFT")
        explanationScroll:SetPoint("TOPRIGHT", -26, 0)
        explanationScroll:SetHeight(156)
        local explanationBody = CreateFrame("Frame", nil, explanationScroll)
        explanationBody:SetSize(850, 156)
        explanationScroll:SetScrollChild(explanationBody)
        frame.explanation = UI:Label(explanationBody, "", 14)
        frame.explanation:SetPoint("TOPLEFT", 8, -4)
        frame.explanation:SetPoint("TOPRIGHT", -8, -4)
        local scroll, edit = UI:CopyBox(root)
        scroll:SetPoint("TOPLEFT", 0, -166)
        scroll:SetPoint("BOTTOMRIGHT", -26, 84)
        frame.text = edit
        explanationScroll:HookScript("OnSizeChanged", function(owner)
            explanationBody:SetWidth(owner:GetWidth())
            explanationBody:SetHeight(math.max(156, frame.explanation:GetStringHeight() + 12))
        end)
        frame.explanationBody = explanationBody
        frame.undo = UI:Button(root, T("UNDO"), 300, function() self:UndoManualSkip(); self:RefreshDiagnostics() end)
        frame.undo:SetPoint("BOTTOMLEFT", 0, 42)
        local refresh = UI:Button(root, T("REFRESH"), 140, function() self:RefreshDiagnostics() end)
        refresh:SetPoint("LEFT", frame.undo, "RIGHT", 10, 0)
        local redact = UI:Button(root, "", 300, function(button)
            frame.includeIdentity = not frame.includeIdentity
            button:SetText((frame.includeIdentity and "[ ] " or "[x] ") .. T("REDACT"))
            self:RefreshDiagnostics()
        end)
        redact:SetText("[x] " .. T("REDACT"))
        redact:SetPoint("BOTTOMLEFT")
        local copy = UI:Button(root, T("EXPORT"), 140, function()
            edit:SetFocus(); edit:HighlightText()
        end)
        copy:SetPoint("BOTTOMRIGHT")
        UI:Tooltip(copy, T("COPY_HINT"))
        frame:RegisterEvent("QUEST_LOG_UPDATE")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:SetScript("OnEvent", function()
            if not frame:IsShown() or frame.refreshTimer then return end
            frame.refreshTimer = C_Timer.NewTimer(0.3, function()
                frame.refreshTimer = nil
                self:RefreshDiagnostics()
            end)
        end)
        frame:HookScript("OnHide", function()
            if frame.refreshTimer then frame.refreshTimer:Cancel(); frame.refreshTimer = nil end
        end)
    end
    frame:Show()
    self:RefreshDiagnostics()
    frame.explanationBody:SetHeight(math.max(156, frame.explanation:GetStringHeight() + 12))
end

function APR:CreateDiagnosticsEntryPoint()
    local anchor = _G.CurrentStepFrameSettingsButton
    if not anchor or self.diagnosticsButton then return end
    local button = UI:Button(anchor:GetParent(), "?", 22, function() self:ShowDiagnostics() end)
    button:SetHeight(22)
    button:SetPoint("RIGHT", anchor, "LEFT", -3, 0)
    UI:Tooltip(button, T("EXPLAIN"))
    self.diagnosticsButton = button
end
