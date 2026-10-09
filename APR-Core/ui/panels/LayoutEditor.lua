-- Moves independent previews, including hidden panels, without changing gameplay frames before Save.
-- Linked previews move as a group and keep their attachments on Save.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local Window = LibStub("LibWindow-1.1")
local UI = APR.UI
APR.LayoutEditor = { previews = {} }
local Editor = APR.LayoutEditor
function Editor:InitializeOnboarding()
    if not self.firstUsePending or self.onboarding then return end
    local watcher = CreateFrame("Frame")
    self.onboarding = watcher
    local function queue()
        if self.onboardingQueued or not self.firstUsePending then return end
        self.onboardingQueued = true
        C_Timer.After(1, function()
            self.onboardingQueued = nil
            if not self.firstUsePending or InCombatLockdown() or (IsLoggedIn and not IsLoggedIn()) or
                (APR.IsPetBattleActive and APR:IsPetBattleActive()) then return end
            if self:Show() then watcher:UnregisterAllEvents() end
        end)
    end
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PET_BATTLE_CLOSE"}) do
        APR:RegisterSupportedEvent(watcher, event)
    end
    watcher:SetScript("OnEvent", queue)
    queue()
end

function Editor:LayoutSnappedPreviews()
    local stack = APR:GetSnappedStack(self.previews)
    local root = self.previews[1]
    for i = 2, #stack do
        local entry, previous = stack[i], stack[i - 1]
        entry.frame:SetWidth(root:GetWidth())
        APR:SnapFrameToAnchor(entry.frame, previous.frame, previous.height, entry.gap)
    end
    for _, preview in ipairs(self.previews) do
        preview.body:SetText(PREVIEW .. "\n" .. string.format("%d × %d", preview:GetWidth(), preview:GetHeight()))
    end
    if self.trackerPreview and self.trackerPreview:IsShown() then
        self.trackerPreview:ClearAllPoints()
        if APR.QuestTracker:GetSide(self.profile) == "above" then
            local last = stack[#stack]
            self.trackerPreview:SetPoint("TOP", last.frame, "TOP", 0, -(last.height + APR.QuestTracker:GetGap()))
        else
            self.trackerPreview:SetPoint("BOTTOM", root, "TOP", 0, APR.QuestTracker:GetBelowOffset())
        end
    end
end

function Editor:DragTarget(preview)
    if preview ~= self.previews[1] and preview.definition.linked and self.profile[preview.definition.linked] then
        return self.previews[1]
    end
    return preview
end
Editor.definitions = {
    {frame = "CurrentStepScreenPanel", key = "currentStepFrame", label = "CURRENT_STEP", linked = "currentStepAttachFrameToQuestLog", width = 300, height = 90},
    {frame = "FillersScreenPanel", key = "fillersFrame", label = "STEP_FILLERS", linked = "fillersFrameSnapToCurrentStep", width = 300, height = 70},
    {frame = "AfkFrameScreen", key = "afkFrame", label = "AFK", linked = "afkSnapToCurrentStep", width = 300, height = 20},
    {frame = "QuestOrderListPanel", key = "questOrderListFrame", label = "QUEST_ORDER_LIST", linked = "questOrderListSnapToCurrentStep", width = 300, height = 220},
    {frame = "PartyScreenPanel", key = "groupFrame", label = "GROUP", width = 230, height = 100},
    {frame = "CoordinateScreenPanel", key = "coordinateFrame", label = "UI_STATUS_COORDINATES", width = 180, height = 30},
    {frame = "BuffFrameScreen", key = "buffFrame", label = "BUFF", width = 230, height = 60},
    {frame = "APRXPBuffOverlay", key = "xpBuffFrame", label = "XP_BUFF_OVERLAY", width = 300, height = 80},
    {frame = "HeirloomPanel", key = "heirloomFrame", label = "HEIRLOOM", width = 230, height = 60},
    {frame = "RouteSelectionPanel", key = "routeSelectionFrame", label = "ROUTE_SELECTION", width = 250, height = 55},
    {key = "arrow", label = "SHOW_ARROW", arrow = true, width = 100, height = 90},
}

function Editor:Hide(reopenSettings)
    local returnToSettings = self.returnToSettings
    self.returnToSettings = nil
    self.active = false
    for _, preview in pairs(self.previews) do
        preview:StopMovingOrSizing()
        preview.isMoving = false
        preview.dragTarget = nil
        preview:Hide()
    end
    if self.trackerPreview then self.trackerPreview:Hide() end
    if self.frame then self.frame:Hide() end
    if returnToSettings and reopenSettings ~= false and self.profile == APR:GetSettingsProfile() then
        APR.settings:OpenSettings()
    end
end

function Editor:Save()
    if InCombatLockdown() or not self.active or self.profile ~= APR:GetSettingsProfile() then return false end
    for _, preview in pairs(self.previews) do
        if preview.changed then
            preview:StopMovingOrSizing()
            local definition, target = preview.definition, preview.target
            if definition.arrow then
                self.profile.arrowleft = preview:GetLeft() * preview:GetScale()
                self.profile.arrowtop = preview:GetTop() * preview:GetScale() - UIParent:GetHeight()
                if target then
                    target:ClearAllPoints()
                    target:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.profile.arrowleft, self.profile.arrowtop)
                end
            elseif definition.linked and self.profile[definition.linked] then
                if preview == self.previews[1] and APR.QuestTracker then APR.QuestTracker:SavePreviewPosition(preview) end
            else
                -- Save a top-left reference: a preview can be taller than the live
                -- panel (empty rows, inactive timer), so bottom/center anchors drift.
                local scale = preview:GetScale()
                preview.position.x = preview:GetLeft() * scale
                preview.position.y = preview:GetTop() * scale - UIParent:GetHeight()
                preview.position.point, preview.position.scale = "TOPLEFT", scale
                local saved = self.profile[definition.key] or {}
                self.profile[definition.key] = saved
                -- LibWindow and the gameplay panel retain this table, so update it in place.
                for key, value in pairs(preview.position) do saved[key] = value end
                if target then
                    Window.RegisterConfig(target, saved)
                    Window.RestorePosition(target)
                end
            end
        end
    end
    APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR.fillersFrame:RefreshFillersFrame()
    APR.AFK:RefreshFrameAnchor()
    APR.questOrderList:RefreshFrameAnchor()
    if APR.QuestTracker and self.profile.currentStepAttachFrameToQuestLog then APR.currentStep:RefreshQuestTrackerAnchor() end
    self:Hide()
    return true
end

function Editor:Recover()
    -- Recovery is also a draft; Cancel leaves the original positions and attachments intact.
    for index, preview in ipairs(self.previews) do
        if self:DragTarget(preview) == preview then
            local column, row = (index - 1) % 3, math.floor((index - 1) / 3)
            preview:ClearAllPoints()
            preview:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (30 + column * (UIParent:GetWidth() - 60) / 3) / preview:GetScale(),
                -(180 + row * (UIParent:GetHeight() - 210) / 4) / preview:GetScale())
            preview.changed = true
        end
    end
    self:LayoutSnappedPreviews()
end

function Editor:Create()
    local frame = UI:Window("APRLayoutEditor", L["UI_LAYOUT_TITLE"], 780, 190)
    self.frame = frame
    frame:SetResizeBounds(600, 180)
    frame:SetHeight(190)
    frame.resize:Hide()
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", 0, -20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    local help = UI:Label(frame.content, L["UI_LAYOUT_HELP"], 12)
    help:SetPoint("TOPLEFT")
    help:SetPoint("TOPRIGHT")
    local save = UI:Button(frame.content, SAVE, 135, function() self:Save() end)
    save:SetPoint("BOTTOMRIGHT")
    local cancel = UI:Button(frame.content, CANCEL, 135, function() self:Hide() end)
    cancel:SetPoint("RIGHT", save, "LEFT", -8, 0)
    local recover = UI:Button(frame.content, L["RESET_POSITION"], 230, function() self:Recover() end)
    recover:SetPoint("BOTTOMLEFT")
    frame:HookScript("OnHide", function() if self.active then self:Hide() end end)
    APR:RegisterSupportedEvent(frame, "PLAYER_REGEN_DISABLED")
    APR:RegisterSupportedEvent(frame, "PET_BATTLE_OPENING_START")
    frame:SetScript("OnEvent", function() self:Hide(false) end)
end

function Editor:CreatePreview(definition)
    local preview = UI:Panel(UIParent)
    preview.definition = definition
    preview:SetFrameStrata("DIALOG")
    preview:SetClampedToScreen(true)
    preview:EnableMouse(true)
    preview.title = UI:Label(preview, L[definition.label], 12, "accent")
    preview.title:SetPoint("BOTTOMLEFT", preview, "TOPLEFT", 0, 2)
    preview.body = UI:Label(preview, PREVIEW, 12, "muted")
    preview.body:SetPoint("CENTER")
    if definition.frame == "AfkFrameScreen" then
        preview.title:ClearAllPoints()
        preview.title:SetPoint("CENTER")
        preview.body:Hide()
    end
    UI:Tooltip(preview, L[definition.label], function()
        return L[definition.linked and self.profile[definition.linked] and "UI_LAYOUT_LINKED" or "UI_LAYOUT_FREE"]
    end)
    APR:SetupFrameDrag(preview, function()
        return self.active and not InCombatLockdown() and self.profile == APR:GetSettingsProfile()
    end, function()
        self:DragTarget(preview).changed = true
        self:LayoutSnappedPreviews()
    end)
    -- Dragging any member moves the root; no saved snap preference is changed.
    preview:SetScript("OnDragStart", function()
        if not self.active or InCombatLockdown() or self.profile ~= APR:GetSettingsProfile() then return end
        local target = self:DragTarget(preview)
        preview.dragTarget = target
        target:StartMoving()
        target.isMoving = true
    end)
    preview:SetScript("OnDragStop", function()
        local target = preview.dragTarget
        preview.dragTarget = nil
        if not target then return end
        target:StopMovingOrSizing()
        target.isMoving, target.changed = false, true
        self:LayoutSnappedPreviews()
    end)
    return preview
end

-- AceConfig still reads the clicked widget's userdata after its callback returns.
-- Closing settings on the next frame avoids releasing that widget during the callback.
function Editor:ShowFromSettings()
    if self.openPending then return end
    self.openPending = true
    C_Timer.After(0, function()
        self.openPending = nil
        if self:Show() then self.returnToSettings = true end
    end)
end

function Editor:Show()
    if InCombatLockdown() then APR:PrintInfo(L["UI_LAYOUT_COMBAT"]); return false end
    if not self.frame then self:Create() end
    if self.active then self.frame:Raise(); return true end
    self.profile, self.active = APR:GetSettingsProfile(), true
    if self.firstUsePending then
        self.firstUsePending = nil
        APR.settings.db.global.layoutEditorSeen = true
    end
    local workspace = APR.Workspace
    self.returnToSettings = workspace and workspace.active == "options" and workspace.frame and workspace.frame:IsShown()
    if self.profile.currentStepAttachFrameToQuestLog then APR.currentStep:RefreshQuestTrackerAnchor() end
    for index, definition in ipairs(self.definitions) do
        local target = definition.arrow and APR.ArrowFrameM or _G[definition.frame]
        local preview = self.previews[index] or self:CreatePreview(definition)
        self.previews[index] = preview
        preview.target, preview.changed, preview.position = target, false, {}
        Window.RegisterConfig(preview, preview.position)
        preview:SetScale(target and target:GetScale() or 1)
        local width, height = target and target:GetWidth(), target and target:GetHeight()
        if index == 1 and APR.currentStep.GetContentHeight then height = APR.currentStep:GetContentHeight(false) end
        -- Empty/hidden panels still reserve representative content in the draft.
        if not target or (height or 0) < 2 then
            height = definition.height
        elseif (index == 1 or index == 2) and not target:IsShown() then
            height = math.max(height, definition.height)
        end
        preview:SetSize(width and width > 1 and width or definition.width, height and height > 1 and height or definition.height)
        preview:ClearAllPoints()
        if target and target:GetLeft() and target:GetTop() then
            -- A stationary screen anchor keeps live quest updates from shifting the draft.
            preview:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", target:GetLeft(), target:GetTop())
        elseif self.profile[definition.key] and self.profile[definition.key].point then
            preview.position = APR:DeepCopyTable(self.profile[definition.key])
            Window.RegisterConfig(preview, preview.position)
            Window.RestorePosition(preview)
        else
            preview:SetPoint("CENTER", UIParent, "CENTER", ((index - 1) % 3 - 1) * 290, 120 - math.floor((index - 1) / 3) * 120)
        end
        preview:Show()
    end
    if self.profile.currentStepAttachFrameToQuestLog and APR.QuestTracker then
        local target, bounds, provider = APR.QuestTracker:Resolve()
        if target and bounds and bounds:GetHeight() then
            if not self.trackerPreview then
                self.trackerPreview = UI:Panel(UIParent)
                self.trackerPreview:SetFrameStrata("DIALOG")
                self.trackerPreview.label = UI:Label(self.trackerPreview, "", 12, "muted")
                self.trackerPreview.label:SetPoint("CENTER")
            end
            local scale = bounds:GetEffectiveScale() / UIParent:GetEffectiveScale()
            self.trackerPreview:SetSize(bounds:GetWidth() * scale, bounds:GetHeight() * scale)
            self.trackerPreview.label:SetText((provider == "kaliel" and "Kaliel’s Tracker" or
                provider == "questie" and "Questie" or "Blizzard") .. "\n" .. PREVIEW)
            self.trackerPreview:Show()
        end
    end
    self:LayoutSnappedPreviews()
    if APR.RouteBrowser and APR.RouteBrowser.frame then APR.RouteBrowser.frame:Hide() end
    if APR.settings.CloseSettings then APR.settings:CloseSettings() end
    self.frame:Show()
    self.frame:Raise()
    return true
end
