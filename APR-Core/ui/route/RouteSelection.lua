-- The empty-route prompt belongs to Current step; route browsing stays in the APR workspace.
-- Existing lifecycle callers can refresh it without creating a second movable window.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.RouteSelection = APR:NewModule("RouteSelection")
local Selection = APR.RouteSelection

function Selection:IsEmptyRouteState()
    if APR.ActiveRoute and APR.ActiveRoute ~= "" then return false end
    -- Activation can lag behind saved-path loading or pause while a route is locked.
    local path = APRCustomPath and APR.PlayerID and APRCustomPath[APR.PlayerID]
    return not path or not next(path)
end

function Selection:Create()
    if self.frame then return self.frame end
    local UI = APR.UI
    local frame = UI:Panel(CurrentStepFrame_StepHolder, "borderedPanel", "inset", "currentStep", {nativeWoW = true})
    self.frame = frame
    APR.currentStep.emptyRoutePrompt = frame
    frame:SetPoint("TOPLEFT", CurrentStepFrame_StepHolder, "TOPLEFT", 8, -8)
    frame.title = UI:Label(frame, L["UI_ROUTE_SELECT"], 12, "accent", "currentStep")
    frame.title:SetPoint("TOPLEFT", 10, -10)
    frame.title:SetWordWrap(true)
    frame.button = UI:Button(frame, L["ROUTE_SELECTION"], 1, function()
        APR.settings:OpenSettings(L["ROUTE"])
    end, nil, "currentStep", {nativeWoW = true})
    frame.button:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -8)
    frame.button:GetFontString():SetWordWrap(true)
    APR:RegisterFontString(frame.title, "currentStep", {role = "accent", onApplied = function() self:Layout() end})
    APR:RegisterFontString(frame.button:GetFontString(), "currentStep", {role = "base", onApplied = function() self:Layout() end})
    return frame
end

function Selection:Layout()
    local frame = self.frame
    if not frame or not frame.button or self.layingOut or InCombatLockdown() then return end
    self.layingOut = true
    local width = APR.currentStep.layout.width - 16
    frame:SetWidth(width)
    frame.title:SetWidth(width - 20)
    frame.button:SetWidth(width - 20)
    local height = math.max(30, frame.button:GetFontString():GetStringHeight() + 12)
    frame.button:SetHeight(height)
    frame:SetHeight(10 + frame.title:GetStringHeight() + 8 + height + 10)
    self.layingOut = nil
end

function Selection:UpdateTextAppearance()
    self:Layout()
    if self.frame and APR.currentStep.emptyRoutePromptActive then APR.currentStep:ReOrderQuestSteps() end
end

function Selection:RefreshFrameAnchor()
    if InCombatLockdown() then self.pendingRefresh = true; return end
    self.pendingRefresh = nil
    local profile = APR:GetSettingsProfile()
    if not profile then return end
    local step = APR.currentStep
    local empty = self:IsEmptyRouteState()
    local visible = empty and not APR:ShouldHideFrames() and not CurrentStepScreenPanel.collapsed
    step.emptyRoutePromptActive = empty
    local frame = self.frame or (visible and self:Create())
    if frame then self:Layout(); frame:SetShown(visible) end
    if step.progressBar then step.progressBar:SetShown(not empty and not CurrentStepScreenPanel.collapsed) end
    if empty then
        if step.ButtonHide then step:ButtonHide() end
    elseif step.ButtonShow then step:ButtonShow() end
    step:ReOrderQuestSteps()
end

function Selection:RouteSelectionOnInit() self:RefreshFrameAnchor() end
function Selection:SetDefaultDisplay() self:RefreshFrameAnchor() end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function()
    if Selection.pendingRefresh then
        Selection:RefreshFrameAnchor()
        APR.currentStep:RefreshCurrentStepFrameAnchor()
    end
end)
