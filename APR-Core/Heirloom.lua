local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

APR.heirloom = APR:NewModule("Heirloom")

APR.heirloom.buttons = {}
APR.heirloom._pendingCombatRefresh = false
APR.heirloom._combatWatcher = nil

---------------------------------------------------------------------------------------
--------------------------------- Heirloom Frame --------------------------------------
---------------------------------------------------------------------------------------

local HeirloomFrame = CreateFrame("Frame", "HeirloomPanel", UIParent, "BackdropTemplate")
HeirloomFrame:SetSize(250, 75)
HeirloomFrame:SetFrameStrata("LOW")
HeirloomFrame:SetClampedToScreen(true)
HeirloomFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    tile = true,
    tileSize = 16
})
HeirloomFrame:SetBackdropColor(unpack(APR.Color.defaultLightBackdrop))


-- Create the body frame
local HeirloomFrame_body = CreateFrame("Frame", "HeirloomFrame_body", HeirloomFrame,
    "BackdropTemplate")
HeirloomFrame_body:SetAllPoints()

-- Create the frame header
local HeirloomFrameHeader = CreateFrame("Frame", "HeirloomFrameHeader", HeirloomFrame,
    "ObjectiveTrackerContainerHeaderTemplate")
HeirloomFrameHeader:SetPoint("bottom", HeirloomFrame, "top", 0, -1)
HeirloomFrameHeader.Text:SetText(L["HEIRLOOM"])
HeirloomFrameHeader:SetScript("OnMouseDown", function(self, button)
    self:GetParent():StartMoving()
end)

HeirloomFrameHeader:SetScript("OnMouseUp", function(self, button)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(HeirloomPanel)
end)

HeirloomFrameHeader.MinimizeButton:GetNormalTexture():SetAtlas("redbutton-exit")
HeirloomFrameHeader.MinimizeButton:GetPushedTexture():SetAtlas("redbutton-exit-pressed")
HeirloomFrameHeader.MinimizeButton:SetScript("OnClick", function(self)
    HeirloomPanel:Hide()
    APR.settings.profile.heirloomWarning = true
end)

---------------------------------------------------------------------------------------
------------------------------ Function Party Frames ----------------------------------
---------------------------------------------------------------------------------------

local function EnsureHeirloomCombatWatcher()
    if APR.heirloom._combatWatcher then
        return
    end
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function()
        if APR.heirloom._pendingCombatRefresh then
            APR.heirloom._pendingCombatRefresh = false
            APR.heirloom:RefreshFrameAnchor()
        end
    end)
    APR.heirloom._combatWatcher = frame
end

-- Initialize the frame
function APR.heirloom:HeirloomOnInit()
    LibWindow.RegisterConfig(HeirloomPanel, APR.settings.profile.heirloomFrame)
    HeirloomPanel.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(HeirloomPanel)
    -- Set default display
    self:SetDefaultDisplay()
    self:RefreshFrameAnchor()
end

function APR.heirloom:SetDefaultDisplay()
    HeirloomPanel:SetPoint("center", UIParent, "center", 0, 0)
    HeirloomFrame_body:Show()
    HeirloomFrameHeader:Show()
    HeirloomPanel:Show()
end

function APR.heirloom:RefreshFrameAnchor()
    if InCombatLockdown() then
        self._pendingCombatRefresh = true
        EnsureHeirloomCombatWatcher()
        return
    end
    self._pendingCombatRefresh = false

    if APR.settings.profile.heirloomWarning or not APR.settings.profile.enableAddon or C_PetBattles.IsInBattle() or APR:IsRemixCharacter() then
        HeirloomPanel:Hide()
        return
    end

    APR.heirloom:AddHeirloomIcons()
    HeirloomPanel:EnableMouse(true)
    LibWindow.RestorePosition(HeirloomPanel)
    HeirloomPanel:Show()
end

local function CreateHeirloomButton(parentFrame, iconTexture)
    local button = CreateFrame("Button", nil, parentFrame, "ActionButtonTemplate")
    button:SetSize(50, 50)
    button:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    button:SetNormalTexture(iconTexture)
    button:SetScript("OnClick", function()
        ToggleCollectionsJournal(4)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["HEIRLOOM"])
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    return button
end
local function CreateMapButton(parentFrame, itemID)
    local id, toyName, icon, isFavorite, hasFanfare, itemQuality = C_ToyBox.GetToyInfo(itemID)


    -- Use an unnamed secure button to prevent global name taint
    local button = CreateFrame("Button", nil, parentFrame,
        "SecureActionButtonTemplate, BackdropTemplate")
    button:SetSize(50, 50)
    button:SetNormalTexture(icon or [[Interface/icons/inv_misc_questionmark]])
    button:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("type1", "item")
    button:SetAttribute("item", "item:" .. tostring(itemID))

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    return button
end

function APR.heirloom:AddHeirloomIcons()
    if InCombatLockdown() then
        self._pendingCombatRefresh = true
        EnsureHeirloomCombatWatcher()
        return
    end
    local mapId = C_Map.GetBestMapForUnit("player")
    if not mapId or APR.settings.profile.heirloomWarning then
        return
    end
    local heirlooms = {
        {
            -- icon = "interface\\icons\\inv_misc_map09",
            name = "map",
            id = 150744,
            faction = "Horde"
        },
        {
            name = "map",
            id = 150745,
            faction = "Horde"
        },
        {
            name = "map",
            id = 150743,
            faction = "Alliance"
        },
        {
            name = "map",
            id = 150746,
            faction = "Alliance"
        },
        {
            name = "map",
            id = 187869,
            faction = "Neutral"
        },
        {
            name = "map",
            id = 187875,
            faction = "Neutral"
        },
        {
            name = "map",
            id = 187895,
            faction = "Neutral"
        },
        {
            name = "map",
            id = 187896,
            faction = "Neutral"
        },
        {
            name = "map",
            id = 187897,
            faction = "Neutral"
        },
        {
            name = "map",
            id = 187898,
            faction = "Neutral"
        },
        {
            name = "map",
            id = 187899,
            faction = "Neutral"
        },
        {
            name = "map",
            id = 187900,
            faction = "Neutral"
        },
        {
            icon = "Interface\\Icons\\inv_icon_heirloomtoken_armor01",
            name = "heirloom",
            id = 0,
        }
    }

    local xOffset = 5
    local yOffset = -5
    local maxElementsPerLine = 4
    local elementsCount = 0

    if next(self.buttons) then
        for _, btn in ipairs(self.buttons) do
            btn:Hide()
            btn:ClearAllPoints()
            btn = nil
        end
    end

    for _, heirloom in ipairs(heirlooms) do
        local button
        if heirloom.name == "map" and PlayerHasToy(heirloom.id) and
            (APR.Faction == heirloom.faction or heirloom.faction == "Neutral") and
            not APR:Contains({ 1409, 1726, 1727, 1728 }, APR:GetPlayerParentMapID()) then -- heirloom not availble in the tuto zone
            button = CreateMapButton(HeirloomFrame_body, heirloom.id)
        elseif heirloom.name == "heirloom" then
            button = CreateHeirloomButton(HeirloomFrame_body, heirloom.icon)
        end
        if button then
            button:SetPoint("TOPLEFT", xOffset, yOffset)
            table.insert(self.buttons, button)
            xOffset = xOffset + 62.5
            elementsCount = elementsCount + 1
            if elementsCount % maxElementsPerLine == 0 then
                xOffset = 5
                yOffset = yOffset - 52.5
            end
        end
    end

    HeirloomFrame:SetSize(250, 55 + (-yOffset))
end
