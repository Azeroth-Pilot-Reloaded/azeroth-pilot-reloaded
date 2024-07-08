local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Route Selection module
APR.RouteSelection = APR:NewModule("RouteSelection")

---------------------------------------------------------------------------------------
--------------------------------- Route Selection Frame ------------------------------
---------------------------------------------------------------------------------------

local RouteSelectionFrame = CreateFrame("Frame", "RouteSelectionPanel", UIParent, "BackdropTemplate")
RouteSelectionFrame:SetSize(250, 55)
RouteSelectionFrame:SetFrameStrata("LOW")
RouteSelectionFrame:SetClampedToScreen(true)
RouteSelectionFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    tile = true,
    tileSize = 16
})
RouteSelectionFrame:SetBackdropColor(unpack(APR.Color.defaultLightBackdrop))

-- Create the frame header
local RouteSelectionFrameHeader = CreateFrame("Frame", "RouteSelectionFrameHeader", RouteSelectionFrame,
    "ObjectiveTrackerContainerHeaderTemplate")
RouteSelectionFrameHeader:SetPoint("bottom", RouteSelectionFrame, "top", 0, -1)
RouteSelectionFrameHeader.Text:SetText(L["ROUTE_SELECTION"])
RouteSelectionFrameHeader.MinimizeButton:GetNormalTexture():SetAtlas("redbutton-exit")
RouteSelectionFrameHeader.MinimizeButton:GetPushedTexture():SetAtlas("redbutton-exit-pressed")
RouteSelectionFrameHeader.MinimizeButton:SetScript("OnClick", function(self)
    RouteSelectionPanel:Hide()
    APRData[APR.PlayerID].FirstLoad = false
end)
RouteSelectionFrameHeader:SetScript("OnMouseDown", function(self, button)
    self:GetParent():StartMoving()
end)

RouteSelectionFrameHeader:SetScript("OnMouseUp", function(self, button)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(RouteSelectionPanel)
end)

-- Open settings button
local openSettingsButton = CreateFrame("Button", "OpenSettingsButton", RouteSelectionFrame, "UIPanelButtonTemplate")
openSettingsButton:SetSize(150, 25)
openSettingsButton:SetPoint("center", RouteSelectionFrame, "center", 0, 0)
openSettingsButton:SetText(L["OPEN_ROUTE_OPTIONS"])

openSettingsButton.Text:SetWordWrap(true)
openSettingsButton.Text:SetWidth(140)

local textHeight = openSettingsButton.Text:GetStringHeight()
openSettingsButton:SetHeight(textHeight + 15)

openSettingsButton:SetScript("OnClick", function()
    APR.settings:OpenSettings(L["ROUTE"])
    RouteSelectionPanel:Hide()
    APRData[APR.PlayerID].FirstLoad = false
end)


---------------------------------------------------------------------------------------
--------------------------------- Route Selection func --------------------------------
---------------------------------------------------------------------------------------

-- Initialize the Route Selection frame
function APR.RouteSelection:RouteSelectionOnInit()
    LibWindow.RegisterConfig(RouteSelectionPanel, APR.settings.profile.routeSelectionFrame)
    RouteSelectionPanel.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(RouteSelectionPanel)

    -- Set default display
    self:SetDefaultDisplay()
    self:RefreshFrameAnchor()
end

function APR.RouteSelection:SetDefaultDisplay()
    RouteSelectionPanel:SetPoint("center", UIParent, "center", 0, 0)
    RouteSelectionFrame:Show()
    RouteSelectionFrameHeader:Show()
end

function APR.RouteSelection:RefreshFrameAnchor()
    if not APR.settings.profile.enableAddon or C_PetBattles.IsInBattle() or not APRData[APR.PlayerID].FirstLoad then
        RouteSelectionPanel:Hide()
        return
    end
    RouteSelectionPanel:EnableMouse(true)
    LibWindow.RestorePosition(RouteSelectionPanel)
    RouteSelectionPanel:Show()
end
