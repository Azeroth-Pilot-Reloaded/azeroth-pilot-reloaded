local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

APR.XPBuffOverlay = APR:NewModule("XPBuffOverlay")
local overlay = APR.XPBuffOverlay
local rows = {}
local frame
local PANEL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 16,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

function overlay:IsBonusEnabled(sourceName)
    local profile = APR.settings and APR.settings.profile
    return not (profile and profile.hiddenXPBonuses and profile.hiddenXPBonuses[sourceName])
end

function overlay:SetBonusEnabled(sourceName, enabled)
    local profile = APR.settings.profile
    profile.hiddenXPBonuses = profile.hiddenXPBonuses or {}
    profile.hiddenXPBonuses[sourceName] = not enabled or nil
    self:Refresh()
end

function overlay:HideOverlay()
    APR.settings.profile.showXPBuffOverlay = false
    self:Refresh()
end

function overlay:GetBonusOptions()
    local options = { WarMode = L["XP_BUFF_WAR_MODE"] }
    for name, source in pairs(APR.LevelBonusSources) do
        if source.items then
            local spellID = source.auras and source.auras[1]
            local spell = spellID and C_Spell.GetSpellInfo(spellID)
            options[name] = spell and spell.name or C_Item.GetItemInfo(source.items[1]) or name
        end
    end
    return options
end

local function GetItemBonusSource(itemID)
    for name, source in pairs(APR.LevelBonusSources) do
        for _, candidate in ipairs(source.items or {}) do
            if candidate == itemID then return name end
        end
    end
end

local function SetDismissTooltip(button, message)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L[message], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function CreateRow(itemID)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(290, 36)
    local button = CreateFrame("Button", nil, row, itemID and "SecureActionButtonTemplate" or nil)
    button:SetSize(30, 30)
    button:SetPoint("LEFT", 6, 0)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(itemID and C_Item.GetItemIconByID(itemID) or 132272)
    if itemID then
        button:RegisterForClicks("AnyUp", "AnyDown")
        button:SetAttribute("type", "item")
        button:SetAttribute("item", "item:" .. itemID)
    end
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if itemID then
            GameTooltip:SetItemByID(itemID)
        else
            GameTooltip:SetText(L["TURN_ON_WARMODE"])
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", button, "RIGHT", 8, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -28, 0)
    label:SetJustifyH("LEFT")
    APR:RegisterFontString(label, "general")
    row.label, row.icon = label, icon
    local dismiss = CreateFrame("Button", nil, row, "UIPanelCloseButton")
    dismiss:SetSize(20, 20)
    dismiss:SetPoint("RIGHT", row, "RIGHT", -3, 0)
    dismiss:SetScript("OnClick", function()
        overlay:SetBonusEnabled(row.bonusSource, false)
    end)
    SetDismissTooltip(dismiss, "XP_BUFF_HIDE_BONUS_DESC")
    row.dismissButton = dismiss
    button.Icon = icon
    if APR.RegisterSkinTarget then
        APR:RegisterSkinTarget(button, "icon", { texture = icon })
        APR:RegisterSkinTarget(dismiss, "close")
    end
    row:Hide()
    return row
end

function overlay:Refresh()
    -- Secure item buttons and their parents cannot be relaid out in combat.
    -- PLAYER_REGEN_ENABLED always applies the latest aura/bag state afterwards.
    if InCombatLockdown() then return end
    local profile = APR.settings and APR.settings.profile
    if not profile then return end
    if not frame then
        frame = CreateFrame("Frame", "APRXPBuffOverlay", UIParent, "BackdropTemplate")
        frame:SetSize(300, 40)
        frame:SetPoint("CENTER", UIParent, "CENTER", 280, 0)
        frame:SetClampedToScreen(true)
        frame:SetMovable(true)
        frame:SetFrameStrata("LOW")
        frame:SetBackdrop(PANEL_BACKDROP)
        frame:SetBackdropBorderColor(1, 0.8, 0, 0.8)
        local header = APR:CreateFrameHeader("APRXPBuffOverlayHeader", frame, L["XP_BUFF_OVERLAY"],
            "ObjectiveTrackerContainerHeaderTemplate", "general")
        frame.Header = header
        header:SetPoint("BOTTOM", frame, "TOP", 0, -1)
        header:SetWidth(300)
        header:EnableMouse(true)
        header.MinimizeButton:GetNormalTexture():SetAtlas("redbutton-exit")
        header.MinimizeButton:GetPushedTexture():SetAtlas("redbutton-exit-pressed")
        header.MinimizeButton:SetScript("OnClick", function() overlay:HideOverlay() end)
        SetDismissTooltip(header.MinimizeButton, "XP_BUFF_HIDE_OVERLAY_DESC")
        header:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "LeftButton" and not InCombatLockdown() then frame:StartMoving() end
        end)
        header:SetScript("OnMouseUp", function(_, mouseButton)
            if mouseButton == "LeftButton" and not InCombatLockdown() then
                frame:StopMovingOrSizing()
                LibWindow.SavePosition(frame)
            end
        end)
    end
    if APR.RegisterSkinTarget then
        APR:RegisterSkinTarget(frame, "borderedPanel")
        APR:RegisterSkinTarget(frame.Header, "header")
        APR:RegisterSkinTarget(frame.Header.MinimizeButton, "close")
    end
    if self.positionConfig ~= profile.xpBuffFrame then
        profile.xpBuffFrame = profile.xpBuffFrame or { x = 280, y = 0, point = "CENTER" }
        self.positionConfig = profile.xpBuffFrame
        LibWindow.RegisterConfig(frame, profile.xpBuffFrame)
        LibWindow.RestorePosition(frame)
    end
    frame:SetBackdropColor(unpack(profile.currentStepbackgroundColorAlpha))
    for _, row in pairs(rows) do row:Hide() end
    if not profile.enableAddon or profile.showXPBuffOverlay == false or C_PetBattles.IsInBattle() or
        UnitLevel("player") >= GetMaxLevelForPlayerExpansion() then
        frame:Hide()
        return
    end
    local count = 0
    local function ShowRow(key, itemID, text, sourceName)
        if not self:IsBonusEnabled(sourceName) then return end
        local row = rows[key] or CreateRow(itemID)
        rows[key] = row
        row.bonusSource = sourceName
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -8 - count * 36)
        row.label:SetText(text)
        if itemID then row.icon:SetTexture(C_Item.GetItemIconByID(itemID)) end
        row:Show()
        count = count + 1
    end
    if not C_PvP.IsWarModeActive() and not C_PvP.IsWarModeDesired() and
        UnitLevel("player") >= 20 then
        ShowRow("WarMode", nil, L["TURN_ON_WARMODE"], "WarMode")
    end
    for _, itemID in ipairs(APR:GetLevelConsumableReminders()) do
        local name = C_Item.GetItemInfo(itemID) or ("item:" .. itemID)
        ShowRow(itemID, itemID, string.format(L["USE_ITEM"], name), GetItemBonusSource(itemID))
    end
    frame:SetHeight(math.max(40, count * 36 + 16))
    frame:SetShown(count > 0)
end

function overlay:QueueRefresh()
    if self.refreshPending then return end
    self.refreshPending = true
    C_Timer.After(0.1, function()
        self.refreshPending = false
        self:Refresh()
    end)
end

-- These events are independent of the active route and the route event dispatcher.
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "UNIT_AURA", "BAG_UPDATE_DELAYED",
    "GET_ITEM_INFO_RECEIVED", "SPELL_UPDATE_USABLE", "PLAYER_LEVEL_UP", "WAR_MODE_STATUS_UPDATE",
    "PLAYER_FLAGS_CHANGED", "PLAYER_REGEN_ENABLED", "PET_BATTLE_OPENING_START", "PET_BATTLE_CLOSE" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" and ((issecretvalue and issecretvalue(unit)) or unit ~= "player") then return end
    overlay:QueueRefresh()
end)
