local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")
local DF = _G["DetailsFramework"]

-- Initialize APR Party  module
APR.party = APR:NewModule("Party")

--Local constant
local FRAME_WIDTH = 250
local FRAME_HEIGHT = 100
local FRAME_OFFSET = -18
local FRAME_MATE_HOLDER_HEIGHT = -18

-- Init list
APR.party.teamList = {}
---------------------------------------------------------------------------------------
--------------------------------- Party Frames ----------------------------------------
---------------------------------------------------------------------------------------

local PartyFrame = CreateFrame("Frame", "PartyScreenPanel", UIParent, "BackdropTemplate")
PartyFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
PartyFrame:SetFrameStrata("LOW")


-- Create the step holder frame
local PartyFrame_TeamHolder = CreateFrame("Frame", "PartyFrame_TeamHolder", PartyFrame,
    "BackdropTemplate")
PartyFrame_TeamHolder:SetAllPoints()

-- Create the frame header
local PartyFrameHeader = CreateFrame("Frame", "PartyFrameHeader", PartyFrame, "ObjectiveTrackerHeaderTemplate")
PartyFrameHeader:SetPoint("bottom", PartyFrame, "top", 0, -20)
PartyFrameHeader.Text:SetText(L["GROUP"])

-- Create the minimize button
local minimizeButton = CreateFrame("Button", "PartyFrameHeaderMinimizeButton", PartyFrame, "BackdropTemplate")
local minimizeButtonText = minimizeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")

PartyFrameHeader.MinimizeButton:Hide()
minimizeButtonText:SetText(L["GROUP"])
minimizeButtonText:SetPoint("right", minimizeButton, "left", -3, 1)
minimizeButtonText:Hide()

PartyFrame.MinimizeButton = minimizeButton
minimizeButton:SetSize(16, 16)
minimizeButton:SetPoint("topright", PartyFrameHeader, "topright", 0, -4)
minimizeButton:SetScript("OnClick", function()
    if (PartyFrame.collapsed) then
        APR.party:SetDefaultDisplay()
    else
        PartyFrame.collapsed = true
        minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
        minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0, 0.5)
        PartyFrame_TeamHolder:Hide()
        PartyFrameHeader:Hide()
        minimizeButtonText:Show()
        minimizeButtonText:SetText(L["GROUP"])
    end
end)

minimizeButton:SetNormalTexture([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 1)
minimizeButton:SetPushedTexture([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0.5, 1)
minimizeButton:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
minimizeButton:SetDisabledTexture([[Interface\Buttons\UI-Panel-QuestHideButton-disabled]])

---------------------------------------------------------------------------------------
------------------------------ Function Party Frames ----------------------------------
---------------------------------------------------------------------------------------

-- Initialize the Party frame
function APR.party:PartyFrameOnInit()
    LibWindow.RegisterConfig(PartyScreenPanel, APR.settings.profile.groupFrame)
    PartyScreenPanel.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(PartyScreenPanel)

    -- Set default display
    self:SetDefaultDisplay()

    self:RefreshPartyFrameAnchor()
    self:UpdateFrameScale()
end

function APR.party:SetDefaultDisplay()
    PartyFrame.collapsed = false
    minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 1)
    minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0.5, 1)
    minimizeButtonText:Hide()
    PartyScreenPanel:SetPoint("center", UIParent, "center", 0, 0)
    PartyFrame_TeamHolder:Show()
    PartyFrameHeader:Show()
end

-- Update the frame scale
function APR.party:UpdateFrameScale()
    PartyFrame:SetScale(APR.settings.profile.groupScale)
end

function APR.party:RefreshPartyFrameAnchor()
    if (not APR.settings.profile.showGroup or not APR.settings.profile.enableAddon) then
        PartyScreenPanel:Hide()
        return
    end
    PartyScreenPanel:EnableMouse(true)
    LibWindow.RestorePosition(PartyScreenPanel)
    PartyScreenPanel:Show()
end

-- Reset the frame position
function APR.party:ResetPosition()
    PartyScreenPanel:ClearAllPoints()
    PartyScreenPanel:SetPoint("center", UIParent, "center", 0, 0)
    LibWindow.SavePosition(PartyScreenPanel)
end

local AddTeamMate = function(name, stepIndex)
    local container = CreateFrame("Frame", nil, PartyFrame_TeamHolder, "BackdropTemplate")
    -- Create a font for mate information
    local fontName = container:CreateFontString("fontName", "OVERLAY", "GameFontHighlight")
    fontName:SetWordWrap(true)
    fontName:SetWidth(FRAME_WIDTH)
    fontName:SetPoint("TOPLEFT", 5, -5)
    fontName:SetText(name)
    fontName:SetJustifyH("LEFT")

    local fontIndex = container:CreateFontString("fontIndex", "OVERLAY", "GameFontHighlight")
    fontIndex:SetPoint("TOPRIGHT", 0, -2)
    fontIndex:SetText(stepIndex)
    fontIndex:SetTextColor(1, 1, 0)
    fontIndex:SetFontObject("GameFontNormalLarge")

    -- Set the size of the container based on the text length
    container:SetWidth(FRAME_WIDTH)
    container:SetHeight(fontIndex:GetStringHeight() + 10)
    container:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 16
    })
    container:SetBackdropColor(0, 0, 0, 0.75)

    return container
end

function APR.party:UpdateTeamMate(name, stepIndex)
    if not next(self.teamList) then
        FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET
    end
    local existingContainer = self.teamList[name]

    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
        self.teamList[name] = nil
    end
    local container = AddTeamMate(name, stepIndex)
    container:SetPoint("TOPLEFT", PartyFrame, "TOPLEFT", 0, FRAME_MATE_HOLDER_HEIGHT)
    self.teamList[name] = container
    FRAME_MATE_HOLDER_HEIGHT = FRAME_MATE_HOLDER_HEIGHT - container:GetHeight()
    self:ReOrderTeam()
end

function APR.party:ReOrderTeam()
    FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET
    for id, container in pairs(self.teamList) do
        container:Hide()
        container:ClearAllPoints()
        container:SetPoint("TOPLEFT", PartyFrame, "TOPLEFT", 0, FRAME_MATE_HOLDER_HEIGHT)
        container:Show()
        FRAME_MATE_HOLDER_HEIGHT = FRAME_MATE_HOLDER_HEIGHT - container:GetHeight()
    end
end

function APR.party:RemoveMate(name)
    local existingMate = self.teamList[name]
    if not existingMate then
        return
    end
    existingMate:Hide()
    existingMate:ClearAllPoints()
    self.teamList[name] = nil
    self:ReOrderTeam()
end

function APR.party:RemoveTeam()
    for id, container in pairs(self.teamList) do
        container:Hide()
        container:ClearAllPoints()
        container = nil
    end
    self.teamList = {}
    FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET
end

function APR.party:HideFrame()
    PartyScreenPanel:Hide()
end

function APR.party:ShowFrame()
    PartyScreenPanel:Show()
end
