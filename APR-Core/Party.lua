local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize APR Party  module
APR.party = APR:NewModule("Party")
local AceSerializer = _G.LibStub("AceSerializer-3.0")

--Local constant
local FRAME_WIDTH = 250
local FRAME_HEIGHT = 100
local FRAME_OFFSET = 1
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
local PartyFrameHeader = CreateFrame("Frame", "PartyFrameHeader", PartyFrame, "ObjectiveTrackerContainerHeaderTemplate")
PartyFrameHeader:SetPoint("bottom", PartyFrame, "top", 0, 0)
PartyFrameHeader.Text:SetText(L["GROUP"])

-- Create the minimize button
PartyFrameHeader.MinimizeButton:SetScript("OnClick", function(self)
    if PartyFrame.collapsed then
        APR.party:SetDefaultDisplay()
        self:GetNormalTexture():SetAtlas("ui-questtrackerbutton-collapse-all")
        self:GetPushedTexture():SetAtlas("ui-questtrackerbutton-collapse-all-pressed")
    else
        PartyFrame.collapsed = true
        PartyFrame_TeamHolder:Hide()
        self:GetNormalTexture():SetAtlas("ui-questtrackerbutton-expand-all")
        self:GetPushedTexture():SetAtlas("ui-questtrackerbutton-expand-all-pressed")
    end
end)

PartyFrameHeader:SetScript("OnMouseDown", function(self, button)
    self:GetParent():StartMoving()
end)

PartyFrameHeader:SetScript("OnMouseUp", function(self, button)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(PartyScreenPanel)
end)



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
    PartyScreenPanel:SetPoint("center", UIParent, "center", 0, 0)
    PartyFrame_TeamHolder:Show()
    PartyFrameHeader:Show()
end

-- Update the frame scale
function APR.party:UpdateFrameScale()
    LibWindow.SetScale(PartyScreenPanel, APR.settings.profile.groupScale)
end

function APR.party:RefreshPartyFrameAnchor()
    if not APR.settings.profile.showGroup or not APR.settings.profile.enableAddon or not IsInGroup() or C_PetBattles.IsInBattle() or not next(APR.party.GroupListSteps) then
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

local AddTeamMate = function(username, currentStep, totalSteps, isSameRoute, color)
    local container = CreateFrame("Frame", nil, PartyFrame_TeamHolder, "BackdropTemplate")
    -- Create a font for mate information
    local fontName = container:CreateFontString("fontName", "OVERLAY", "GameFontHighlight")
    fontName:SetWordWrap(true)
    fontName:SetWidth(FRAME_WIDTH)
    fontName:SetPoint("TOPLEFT", 5, -5)
    fontName:SetText(username)
    fontName:SetJustifyH("LEFT")

    local fontIndex = container:CreateFontString("fontIndex", "OVERLAY", "GameFontHighlight")
    fontIndex:SetPoint("TOPRIGHT", 0, -2)
    fontIndex:SetText(isSameRoute and currentStep or '-')
    if color == 'gray' or not isSameRoute then
        fontIndex:SetTextColor(unpack(APR.Color.gray))
    else
        fontIndex:SetTextColor(unpack(APR.Color.green))
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
    container:SetBackdropColor(unpack(APR.Color.defaultLightBackdrop))

    return container
end

function APR.party:UpdateTeamMate(playerData, isSameRoute, color)
    local username = playerData.username
    if not next(self.teamList) then
        FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET
    end
    local existingContainer = self.teamList[username]

    if existingContainer then
        existingContainer:Hide()
        existingContainer:ClearAllPoints()
        self.teamList[username] = nil
    end
    local container = AddTeamMate(username, playerData.currentStep, playerData.totalSteps, isSameRoute, color)
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
    self.GroupListSteps = {}
    FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET
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
            if APR:Contains(FriendListTable, nameOfPartyMember) then
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
    if not APR.ActiveRoute then return end
    local curStep = APRData[APR.PlayerID][APR.ActiveRoute]
    if ((IsInGroup(LE_PARTY_CATEGORY_HOME) and curStep and (self.LastSent ~= curStep)) or forceSend) or not APR:IsInstanceWithUI() then
        local dataToSend = {
            route = APR.ActiveRoute,
            currentStep = curStep,
            totalSteps = APRData[APR.PlayerID][APR.ActiveRoute .. '-TotalSteps'],
            username = APR.Username
        }
        local serializedData = AceSerializer:Serialize(dataToSend)
        C_ChatInfo.SendAddonMessage("APRPartyData", serializedData, "PARTY")
        self.LastSent = APRData[APR.PlayerID][APR.ActiveRoute]
    end
end

function APR.party:SendGroupMessageDelete()
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        C_ChatInfo.SendAddonMessage("APRPartyDelete", APR.Username, "PARTY")
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
            local color = groupData.currentStep < highestStep and 'gray' or 'green'
            local isSameRoute = playerData.route == groupData.route
            -- other route color
            APR.party:UpdateTeamMate(groupData, isSameRoute, color) -- //TODO: add a color legend in the footer
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
        if (prefix == "APRPartyData" and message and channel == "PARTY") then
            APR.party:UpdateGroupListing(message)
        end
        if (prefix == "APRPartyDelete" and message and channel == "PARTY") then
            APR.party:RemoveTeam()
            APR.party:SendGroupMessage()
            APR.party:RefreshPartyFrameAnchor()
        end
    end
end
)
