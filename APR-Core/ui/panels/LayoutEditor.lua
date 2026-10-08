-- Moves independent previews, including hidden panels, without changing gameplay frames before Save.
-- Cancel, Escape, profile changes and combat discard the draft; dragging a linked panel detaches it on Save.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local Window = LibStub("LibWindow-1.1")
local UI = APR.UI
APR.LayoutEditor = { previews = {} }
local Editor = APR.LayoutEditor
Editor.definitions = {
    {frame = "CurrentStepScreenPanel", key = "currentStepFrame", label = "CURRENT_STEP", linked = "currentStepAttachFrameToQuestLog", width = 300, height = 90},
    {frame = "FillersScreenPanel", key = "fillersFrame", label = "STEP_FILLERS", linked = "fillersFrameSnapToCurrentStep", width = 300, height = 70},
    {frame = "AfkFrameScreen", key = "afkFrame", label = "AFK", linked = "afkSnapToCurrentStep", width = 300, height = 30},
    {frame = "QuestOrderListPanel", key = "questOrderListFrame", label = "QUEST_ORDER_LIST", linked = "questOrderListSnapToCurrentStep", width = 300, height = 220},
    {frame = "PartyScreenPanel", key = "groupFrame", label = "GROUP", width = 230, height = 100},
    {frame = "CoordinateScreenPanel", key = "coordinateFrame", label = "UI_STATUS_COORDINATES", width = 180, height = 30},
    {frame = "BuffFrameScreen", key = "buffFrame", label = "BUFF", width = 230, height = 60},
    {frame = "APRXPBuffOverlay", key = "xpBuffFrame", label = "XP_BUFF_OVERLAY", width = 300, height = 80},
    {frame = "HeirloomPanel", key = "heirloomFrame", label = "HEIRLOOM", width = 230, height = 60},
    {frame = "RouteSelectionPanel", key = "routeSelectionFrame", label = "ROUTE_SELECTION", width = 250, height = 55},
    {key = "arrow", label = "SHOW_ARROW", arrow = true, width = 100, height = 90},
}

function Editor:Hide()
    self.active = false
    for _, preview in pairs(self.previews) do
        preview:StopMovingOrSizing()
        preview.isMoving = false
        preview:Hide()
    end
    if self.frame then self.frame:Hide() end
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
            else
                Window.SavePosition(preview)
                local saved = self.profile[definition.key] or {}
                self.profile[definition.key] = saved
                -- LibWindow and the gameplay panel retain this table, so update it in place.
                for key, value in pairs(preview.position) do saved[key] = value end
                if definition.linked then self.profile[definition.linked] = false end
                if target then
                    Window.RegisterConfig(target, saved)
                    Window.RestorePosition(target)
                end
            end
        end
    end
    self:Hide()
    APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR.fillersFrame:RefreshFillersFrame()
    APR.AFK:RefreshFrameAnchor()
    APR.questOrderList:RefreshFrameAnchor()
    return true
end

function Editor:Recover()
    -- Recovery is also a draft; Cancel leaves the original positions and attachments intact.
    for index, preview in ipairs(self.previews) do
        local column, row = (index - 1) % 3, math.floor((index - 1) / 3)
        preview:ClearAllPoints()
        preview:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (30 + column * (UIParent:GetWidth() - 60) / 3) / preview:GetScale(),
            -(180 + row * (UIParent:GetHeight() - 210) / 4) / preview:GetScale())
        preview.changed = true
    end
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
    local recover = UI:Button(frame.content, L["UI_LAYOUT_RECOVER"], 230, function() self:Recover() end)
    recover:SetPoint("BOTTOMLEFT")
    frame:HookScript("OnHide", function() if self.active then self:Hide() end end)
    APR:RegisterSupportedEvent(frame, "PLAYER_REGEN_DISABLED")
    APR:RegisterSupportedEvent(frame, "PET_BATTLE_OPENING_START")
    frame:SetScript("OnEvent", function() self:Hide() end)
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
    UI:Tooltip(preview, L[definition.label], function()
        return L[definition.linked and self.profile[definition.linked] and "UI_LAYOUT_LINKED" or "UI_LAYOUT_FREE"]
    end)
    APR:SetupFrameDrag(preview, function()
        return self.active and not InCombatLockdown() and self.profile == APR:GetSettingsProfile()
    end, function() preview.changed = true end)
    return preview
end

function Editor:Show()
    if InCombatLockdown() then APR:PrintInfo(L["UI_LAYOUT_COMBAT"]); return false end
    if not self.frame then self:Create() end
    if self.active then self.frame:Raise(); return true end
    self.profile, self.active = APR:GetSettingsProfile(), true
    for index, definition in ipairs(self.definitions) do
        local target = definition.arrow and APR.ArrowFrameM or _G[definition.frame]
        local preview = self.previews[index] or self:CreatePreview(definition)
        self.previews[index] = preview
        preview.target, preview.changed, preview.position = target, false, {}
        Window.RegisterConfig(preview, preview.position)
        preview:SetScale(target and target:GetScale() or 1)
        local width, height = target and target:GetWidth(), target and target:GetHeight()
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
        preview.body:SetText(PREVIEW .. "\n" .. string.format("%d × %d", preview:GetWidth(), preview:GetHeight()))
        if index > 1 and definition.linked and self.profile[definition.linked] then
            local primary = self.previews[1]
            if target and primary.target and target:GetLeft() and primary.target:GetLeft() then
                local scale = preview:GetScale()
                local dx = target:GetLeft() * scale - primary.target:GetLeft() * primary:GetScale()
                local dy = target:GetTop() * scale - primary.target:GetTop() * primary:GetScale()
                preview:ClearAllPoints()
                preview:SetPoint("TOPLEFT", primary, "TOPLEFT", dx / scale, dy / scale)
            end
        end
        preview:Show()
    end
    if APR.RouteBrowser and APR.RouteBrowser.frame then APR.RouteBrowser.frame:Hide() end
    if APR.settings.CloseSettings then APR.settings:CloseSettings() end
    self.frame:Show()
    self.frame:Raise()
    return true
end
