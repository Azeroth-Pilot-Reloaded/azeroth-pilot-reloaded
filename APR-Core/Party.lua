local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Party  module
APR.party = APR:NewModule("Party")
local AceSerializer = _G.LibStub("AceSerializer-3.0")

--Local constant
local FRAME_WIDTH = 250
local FRAME_HEIGHT = 100
local FRAME_OFFSET = -18
local FRAME_MATE_HOLDER_HEIGHT = -18

-- Init list
APR.party.teamList = {}
APR.party.GroupListSteps = {}
APR.party.LastSent = 0

---------------------------------------------------------------------------------------
--------------------------------- Party Frames ----------------------------------------
---------------------------------------------------------------------------------------

local PartyFrame = CreateFrame("Frame", "PartyScreenPanel", UIParent, "BackdropTemplate")
PartyFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
PartyFrame:SetFrameStrata("LOW")
PartyFrame:SetClampedToScreen(true)


-- Create the mate holder frame
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
    LibWindow.SetScale(PartyScreenPanel, APR.settings.profile.groupScale)
end

function APR.party:RefreshPartyFrameAnchor()
    if (not APR.settings.profile.showGroup or not APR.settings.profile.enableAddon) or not IsInGroup() or C_PetBattles.IsInBattle() then
        self:RemoveTeam()
        PartyScreenPanel:Hide()
        return
    end
    self:UpdateFrameScale()
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

local AddTeamMate = function(name, stepIndex, color)
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
    if color == 'red' then
        fontIndex:SetTextColor(1, 0, 0)
    elseif color == 'gray' then
        fontIndex:SetTextColor(105 / 255, 105 / 255, 105 / 255)
    else
        fontIndex:SetTextColor(0, 1, 0)
    end
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

function APR.party:UpdateTeamMate(username, currentStep, totalSteps, color)
    if not next(self.teamList) then
        FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET
    end
    local existingContainer = self.teamList[username]

    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
        self.teamList[username] = nil
    end
    local container = AddTeamMate(username, currentStep, color)
    container:SetPoint("TOPLEFT", PartyFrame, "TOPLEFT", 0, FRAME_MATE_HOLDER_HEIGHT)
    self.teamList[username] = container
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
    self:RefreshPartyFrameAnchor()
end

function APR.party:RemoveMateByName(name)
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

function APR.party:IsShowFrame()
    return PartyScreenPanel:IsShown()
end

function APR.party:CheckIfPartyMemberIsFriend()
    -- If Player is NOT in a Group (not instance), do nothing
    if not IsInGroup("LE_PARTY_CATEGORY_HOME") then
        return false
    end

    -- Get FriendLists (WoW and BNet)
    local FriendListTable = self:GetFriendsList()

    -- Check if a party member is a BNet or WoW friend
    for groupindex = 1, 5 do
        local nameOfPartyMember = UnitName("party" .. groupindex)
        if (nameOfPartyMember) then
            if Contains(FriendListTable, nameOfPartyMember) then
                return true
            end
        end
    end

    return false
end

function APR.party:GetFriendsList()
    -- Get Number of Friends online (WoW and BNet)
    local friendsOnlineWoW = C_FriendList.GetNumFriends()
    local _, friendsOnlineBNet = BNGetNumFriends()

    local FriendListTable = {}

    -- add WoW friend
    for i = 1, friendsOnlineWoW do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo and friendInfo.name then
            tinsert(FriendListTable, friendInfo.name)
        end
    end

    -- add BNet friend
    for i = 1, friendsOnlineBNet do
        local bnetFriendInfo = C_BattleNet.GetFriendAccountInfo(i)
        if bnetFriendInfo and bnetFriendInfo.gameAccountInfo and bnetFriendInfo.gameAccountInfo.characterName then
            tinsert(FriendListTable, bnetFriendInfo.gameAccountInfo.characterName)
        end
    end

    return FriendListTable
end

function APR.party:SendGroupMessage(forceSend)
    forceSend = forceSend or false
    if ((IsInGroup(LE_PARTY_CATEGORY_HOME) and APRData[APR.PlayerID][APR.ActiveRoute] and (self.LastSent ~= APRData[APR.PlayerID][APR.ActiveRoute])) or forceSend) and not IsInInstance() then
        local dataToSend = {
            route = APR.ActiveRoute,
            currentStep = APRData[APR.PlayerID][APR.ActiveRoute],
            totalSteps = APRData[APR.PlayerID][APR.ActiveRoute .. '-TotalSteps'],
            username = APR.Username
        }
        local serializedData = AceSerializer:Serialize(dataToSend)
        -- Send the serialized data over the addon communication channel
        C_ChatInfo.SendAddonMessage("APRChat", serializedData, "PARTY")
        self.LastSent = APRData[APR.PlayerID][APR.ActiveRoute]
    end
end

local function UpdateGroupStep(playerData)
    local highestStep = 0
    for _, groupData in pairs(APR.party.GroupListSteps) do
        if groupData.currentStep then
            highestStep = math.max(highestStep, groupData.currentStep)
        end
    end

    local sortedGroup = APR.party.GroupListSteps
    table.sort(sortedGroup, function(a, b)
        return string.lower(a.username) < string.lower(b.username)
    end)


    for _, groupData in pairs(sortedGroup) do
        if groupData.currentStep then
            local color = playerData.route == APR.ActiveRoute and
                (groupData.currentStep < highestStep and 'red' or 'green') or                                -- Same route diff step color
                'gray'                                                                                       -- other route color
            APR.party:UpdateTeamMate(groupData.username, groupData.currentStep, groupData.totalSteps, color) -- //TODO: add a color legend in the footer
        end
    end
    APR.party:RefreshPartyFrameAnchor()
end

function APR.party:UpdateGroupListing(message)
    -- Deserialize the received data
    local success, dataReceived = AceSerializer:Deserialize(message)
    local username = dataReceived.username
    if success then
        -- Update or add member
        APR.party.GroupListSteps[username] = dataReceived
        UpdateGroupStep(dataReceived)
    else
        APR.PrintError(dataReceived)
    end
end

---------------------------------------------------------------------------------------
--------------------------------- Party Event -----------------------------------------
---------------------------------------------------------------------------------------


APR.party.EventFrame = CreateFrame("Frame")
APR.party.EventFrame:RegisterEvent("CHAT_MSG_ADDON")
APR.party.EventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event == "CHAT_MSG_ADDON") then
        local prefix, message, channel = ...;
        if (prefix == "APRChat" and message and channel == "PARTY") then
            APR.party:UpdateGroupListing(message)
        end
    end
end
)
