local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

APR.XPBuffOverlay = APR:NewModule("XPBuffOverlay")
local overlay = APR.XPBuffOverlay
local rows = {}
local frame
local HEADER_HEIGHT = 26
local PANEL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function CreateRow(itemID)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(290, 36)
    local button = CreateFrame("Button", nil, row, itemID and "SecureActionButtonTemplate" or nil)
    button:SetSize(30, 30)
    button:SetPoint("LEFT", 3, 0)
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
    label:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    label:SetJustifyH("LEFT")
    APR:RegisterFontString(label, "general")
    row.label, row.icon = label, icon
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
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        local header = CreateFrame("Frame", "APRXPBuffOverlayHeader", frame, "BackdropTemplate")
        frame.Header = header
        header:SetPoint("TOPLEFT")
        header:SetPoint("TOPRIGHT")
        header:SetHeight(HEADER_HEIGHT)
        header:SetBackdrop(PANEL_BACKDROP)
        header:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        header:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        header:EnableMouse(true)
        local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header.Text = title
        title:SetPoint("LEFT", 10, 0)
        title:SetPoint("RIGHT", -10, 0)
        title:SetJustifyH("LEFT")
        title:SetText(L["XP_BUFF_OVERLAY"])
        APR:RegisterFontString(title, "general", { role = "accent" })
        header:SetScript("OnMouseDown", function()
            if not InCombatLockdown() then frame:StartMoving() end
        end)
        header:SetScript("OnMouseUp", function()
            if not InCombatLockdown() then
                frame:StopMovingOrSizing()
                LibWindow.SavePosition(frame)
            end
        end)
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
    local function ShowRow(key, itemID, text)
        local row = rows[key] or CreateRow(itemID)
        rows[key] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -HEADER_HEIGHT - 5 - count * 36)
        row.label:SetText(text)
        if itemID then row.icon:SetTexture(C_Item.GetItemIconByID(itemID)) end
        row:Show()
        count = count + 1
    end
    if not C_PvP.IsWarModeActive() and not C_PvP.IsWarModeDesired() and
        UnitLevel("player") >= 20 then
        ShowRow("WarMode", nil, L["TURN_ON_WARMODE"])
    end
    for _, itemID in ipairs(APR:GetLevelConsumableReminders()) do
        local name = C_Item.GetItemInfo(itemID) or ("item:" .. itemID)
        ShowRow(itemID, itemID, string.format(L["USE_ITEM"], name))
    end
    frame:SetHeight(HEADER_HEIGHT + math.max(40, count * 36 + 10))
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
