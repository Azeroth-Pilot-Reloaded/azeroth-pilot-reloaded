-- Edits independent preview outlines, then commits positions through the existing LibWindow storage.
-- Cancel, Escape and entering combat discard previews without moving protected gameplay frames.

APR.LayoutEditor = { previews = {} }
local Editor, UI = APR.LayoutEditor, APR.UI
local Window = LibStub("LibWindow-1.1")
local definitions = {
    { frame = "CurrentStepScreenPanel", key = "currentStepFrame", label = "SHOW_STEPS", linked = "currentStepAttachFrameToQuestLog" },
    { frame = "FillersScreenPanel", key = "fillersFrame", label = "BONUS_OBJECTIVES", linked = "fillersFrameSnapToCurrentStep" },
    { frame = "AfkFrameScreen", key = "afkFrame", label = "AFK", linked = "afkSnapToCurrentStep" },
    { frame = "QuestOrderListPanel", key = "questOrderListFrame", label = "SHOW_LIST", linked = "questOrderListSnapToCurrentStep" },
    { frame = "PartyScreenPanel", key = "groupFrame", label = "SHOW_GROUP" },
    { frame = "CoordinateScreenPanel", key = "coordinateFrame", label = "COORDINATES" },
    { frame = "BuffFrameScreen", key = "buffFrame", label = "BUFFS" },
    { frame = "APRXPBuffOverlay", key = "xpBuffFrame", label = "XP_BONUSES" },
    { frame = "HeirloomPanel", key = "heirloomFrame", label = "HEIRLOOMS" },
    { frame = "RouteSelectionPanel", key = "routeSelectionFrame", label = "ROUTES" },
    { key = "arrow", label = "SHOW_ARROW", arrow = true },
}

local function T(key) return APR:LocalizeUI(key) end

function Editor:Hide()
    for _, preview in pairs(self.previews) do preview:StopMovingOrSizing(); preview:Hide() end
    self.active = false
    if self.frame then self.frame:Hide() end
end

function Editor:Save()
    if InCombatLockdown() or not self.active then return false end
    local profile = APR.settings.profile
    for _, preview in pairs(self.previews) do
        if preview.changed and not preview.linked then
            local definition, target = preview.definition, preview.target
            preview:StopMovingOrSizing()
            if definition.arrow then
                profile.arrowleft = preview:GetLeft()
                profile.arrowtop = preview:GetTop() - GetScreenHeight()
                target:ClearAllPoints()
                target:SetPoint("TOPLEFT", UIParent, "TOPLEFT", profile.arrowleft, profile.arrowtop)
            else
                Window.SavePosition(preview)
                local saved = profile[definition.key]
                if not saved then saved = {}; profile[definition.key] = saved end
                -- Preserve the table identity retained by the gameplay panel.
                for key in pairs(saved) do saved[key] = nil end
                for key, value in pairs(preview.position) do saved[key] = value end
                Window.RegisterConfig(target, saved)
                target:SetClampedToScreen(true)
                Window.RestorePosition(target)
            end
        end
    end
    self:Hide()
    APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR.questOrderList:RefreshFrameAnchor()
    return true
end

function Editor:Create()
    self.frame = UI:Window("APRLayoutEditor", T("LAYOUT"), 760, 260)
    self.frame:SetResizeBounds(680, 220)
    self.frame.resize:Hide()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOP", UIParent, "TOP", 0, -35)
    local root = self.frame.content
    local help = UI:Label(root, T("LAYOUT_HELP"), 13)
    help:SetPoint("TOPLEFT")
    help:SetPoint("TOPRIGHT")
    local save = UI:Button(root, T("SAVE"), 160, function() self:Save() end)
    save:SetPoint("BOTTOMRIGHT")
    local cancel = UI:Button(root, T("CANCEL"), 160, function() self:Hide() end)
    cancel:SetPoint("RIGHT", save, "LEFT", -12, 0)
    local recover = UI:Button(root, T("RECOVER_WINDOWS"), 260, function()
        local index = 0
        for _, preview in pairs(self.previews) do
            if not preview.linked then
                index = index + 1
                preview:ClearAllPoints()
                preview:SetPoint("CENTER", UIParent, "CENTER", (index % 3 - 1) * 280, 80 - math.floor((index - 1) / 3) * 120)
                preview.changed = true
            end
        end
    end)
    recover:SetPoint("BOTTOMLEFT")
    self.frame:HookScript("OnHide", function() if self.active then self:Hide() end end)
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:SetScript("OnEvent", function() self:Hide() end)
end

function Editor:Show()
    if InCombatLockdown() then APR:PrintInfo(T("COMBAT_PENDING")); return false end
    if not self.frame then self:Create() end
    self.active = true
    local previousLinked
    for index, definition in ipairs(definitions) do
        local target = definition.arrow and APR.ArrowFrameM or _G[definition.frame]
        if target then
            local preview = self.previews[index]
            if not preview then
                preview = UI:Panel(UIParent)
                self.previews[index] = preview
                preview:SetFrameStrata("DIALOG")
                preview:SetClampedToScreen(true)
                preview:EnableMouse(true)
                preview.text = UI:Label(preview, "", 14, "accent")
                preview.text:SetPoint("TOPLEFT", 10, -10)
                preview.text:SetPoint("TOPRIGHT", -10, -10)
                APR:SetupFrameDrag(preview, function() return self.active and not preview.linked and not InCombatLockdown() end,
                    function() preview.changed = true end)
            end
            preview.target, preview.definition, preview.changed = target, definition, false
            preview.position = {}
            Window.RegisterConfig(preview, preview.position)
            preview.linked = definition.linked and APR.settings.profile[definition.linked]
            preview:SetScale(target:GetScale())
            preview:SetSize(math.max(180, target:GetWidth()), math.max(60, target:GetHeight()))
            preview:ClearAllPoints()
            preview:SetPoint("TOPLEFT", target, "TOPLEFT")
            if preview.linked and previousLinked then preview:SetPoint("TOPLEFT", previousLinked, "BOTTOMLEFT", 0, -10) end
            if definition.key == "currentStepFrame" or preview.linked then previousLinked = preview end
            preview.text:SetText(T(definition.label) .. (preview.linked and "\n" .. T("LINKED") or ""))
            preview:Show()
        end
    end
    self.frame:Show()
    self.frame:Raise()
    return true
end
