local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")


-- Initialize APR Party  module
APR.coordinate = APR:NewModule("Coordinate")

--Local constant
local FRAME_WIDTH = 150
local FRAME_HEIGHT = 32
local frequency = 0.2
local fpsCounter = 0
-- local OnUpdate
---------------------------------------------------------------------------------------
------------------------------- Coordinate Frames -------------------------------------
---------------------------------------------------------------------------------------

local CoordinateFrame = CreateFrame("Frame", "CoordinateScreenPanel", UIParent, "BackdropTemplate")
CoordinateFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
CoordinateFrame:SetFrameStrata("MEDIUM")
CoordinateScreenPanel:EnableMouse(true)
CoordinateFrame:SetClampedToScreen(true)
CoordinateFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    tile = true,
    tileSize = 16,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
CoordinateFrame:SetBackdropColor(0, 0, 0, 0.4)
CoordinateFrame:SetBackdropBorderColor(1, 0.8, 0, 0.8)

CoordinateFrame.Text = CoordinateFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CoordinateFrame.Text:SetJustifyH("CENTER")
CoordinateFrame.Text:SetPoint("CENTER", 0, 0)

CoordinateFrame:SetScript("OnUpdate", function(self, elapsed)
    fpsCounter = fpsCounter + elapsed
    if fpsCounter > frequency then
        fpsCounter = fpsCounter - frequency

        local y, x = UnitPosition("player")
        if not x or not y then
            local blank = ("-"):rep(8)
            self.Text:SetText(blank)
        else
            self.Text:SetFormattedText("%s", APR.coordinate:RoundCoords(x, y, 2))
        end
    end
end)
CoordinateFrame:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        APR.questionDialog:CreateEditBoxPopup('Coordinate X,Y', nil, CoordinateFrame.Text:GetText())
    end
end)
---------------------------------------------------------------------------------------
----------------------------- Function Coordinate Frames ------------------------------
---------------------------------------------------------------------------------------

function APR.coordinate:PartyFrameOnInit()
    LibWindow.RegisterConfig(CoordinateScreenPanel, APR.settings.profile.coordinateFrame)
    CoordinateScreenPanel.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(CoordinateScreenPanel)
    CoordinateScreenPanel:SetPoint("center", UIParent, "center", 0, 0)

    self:RefreshFrameAnchor()
end

function APR.coordinate:RefreshFrameAnchor()
    if (not APR.settings.profile.coordinateShow or not APR.settings.profile.enableAddon) then
        CoordinateScreenPanel:Hide()
        return
    end
    LibWindow.RestorePosition(CoordinateScreenPanel)
    CoordinateScreenPanel:Show()
end

function APR.coordinate:RoundCoords(x, y, prec)
    local coord_fmt = "%%.%df, %%.%df"
    local fmt = coord_fmt:format(prec, prec)
    if not x or not y then
        return "---"
    end
    return fmt:format(x, y)
end
