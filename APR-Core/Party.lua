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
local MAX_MSG_LENGTH = 250 -- 255 is the max, we keep a bit for the header


-- Init list
APR.party.teamList = {}
APR.party.GroupListSteps = {}
APR.party.LastSent = 0
APR.party.incomingFragments = APR.party.incomingFragments or {}


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
    APR:Debug("Function: APR.party:RefreshPartyFrameAnchor()")
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

local AddTeamMate = function(playerData, isSameRoute, color)
    local container = CreateFrame("Frame", nil, PartyFrame_TeamHolder, "BackdropTemplate")
    -- Create a font for mate information
    local fontName = container:CreateFontString("fontName", "OVERLAY", "GameFontHighlight")
    container.playerData = playerData
    fontName:SetWordWrap(true)
    fontName:SetWidth(FRAME_WIDTH)
    fontName:SetPoint("TOPLEFT", 5, -5)
    fontName:SetText(playerData.username)
    fontName:SetJustifyH("LEFT")

    local fontIndex = container:CreateFontString("fontIndex", "OVERLAY", "GameFontHighlight")
    fontIndex:SetPoint("TOPRIGHT", 0, -2)
    fontIndex:SetText(isSameRoute and playerData.currentStep or '-')
    if isSameRoute then
        fontIndex:SetTextColor(unpack(APR.Color[color]))
    else
        fontIndex:SetTextColor(unpack(APR.Color.gray))
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

    container:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        local data = self.playerData

        GameTooltip:ClearLines()

        -- Titre du joueur
        GameTooltip:AddLine(data.username or UNKNOWN, 1, 0.82, 0)
        GameTooltip:AddLine(" ")

        if data.noAddon then
            GameTooltip:AddLine(L["NO_ADDON"], 1, 0, 0)
        elseif not data.route then
            GameTooltip:AddLine(L["NO_ROUTE"], 1, 1, 0)
        else
            -- Route info
            GameTooltip:AddDoubleLine(L["ROUTE"] .. ":", data.route, 0.8, 0.8, 0.8, 1, 1, 1)

            -- Progression
            if data.currentStep and data.totalSteps then
                GameTooltip:AddDoubleLine(L["CURRENT_STEP"] .. ":", data.currentStep .. " / " .. data.totalSteps, 0.8,
                    0.8, 0.8, 0.3, 1, 0.3)
            end

            -- Description
            local stepText = APR.party:GetStepDescription(data.routeFileName, data.currentStep)
            if stepText and stepText ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(DESCRIPTION .. ":", 0.4, 0.8, 1)
                GameTooltip:AddLine(stepText, 1, 1, 1, true)
            end

            -- details
            if data.stepFrameDetails.extraLines or data.stepFrameDetails.questSteps then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(OBJECTIVES_LABEL, 0.4, 0.8, 1)

                -- Extra Lines
                if data.stepFrameDetails.extraLines then
                    for _, extra in ipairs(data.stepFrameDetails.extraLines) do
                        GameTooltip:AddLine("• " .. extra.text, 0.9, 0.9, 0.6, true)
                    end
                end

                -- Quest steps
                if data.stepFrameDetails.questSteps then
                    for _, step in ipairs(data.stepFrameDetails.questSteps) do
                        GameTooltip:AddLine("• " .. step.text, 0.8, 0.8, 0.8, true)
                    end
                end
            end
        end

        GameTooltip:Show()
    end)

    container:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return container
end


function APR.party:GetStepDescription(route, stepIndex)
    if not route or not stepIndex then return '' end

    local routeTable = APR.RouteQuestStepList[route]
    if not routeTable then return '' end

    local step = routeTable[stepIndex]
    if not step then return '' end

    local text = APR:GetStepString(step)
    local questIDs = {}
    local added = {}

    -- Helper to add a quest ID to the list
    local function AddQuestID(qid)
        if qid and not added[qid] then
            table.insert(questIDs, qid)
            added[qid] = true
        end
    end

    -- PickUp
    if step.PickUp then
        if type(step.PickUp) == 'table' then
            for _, qid in ipairs(step.PickUp) do AddQuestID(qid) end
        else
            AddQuestID(step.PickUp)
        end
    end

    -- Done
    if step.Done then
        if type(step.Done) == 'table' then
            for _, qid in ipairs(step.Done) do AddQuestID(qid) end
        else
            AddQuestID(step.Done)
        end
    end

    -- Qpart / QpartPart
    local qpartSource = step.Qpart or step.QpartPart
    if qpartSource then
        for qid, _ in pairs(qpartSource) do
            AddQuestID(qid)
        end
    end

    local questNames = {}
    for _, qid in ipairs(questIDs) do
        local name = C_QuestLog.GetTitleForQuestID(qid)
        if name then
            table.insert(questNames, name)
        end
    end

    if #questNames == 1 then
        text = text .. ": " .. questNames[1]
    elseif #questNames > 1 then
        text = text .. ": " .. table.concat(questNames, ", ")
    end

    return text
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
    local container = AddTeamMate(playerData, isSameRoute, color)
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

function APR.party:PopulateMissingGroupMembers()
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
        self:RemoveTeam()
        return
    end
    local known = {}
    for name, _ in pairs(self.GroupListSteps) do
        known[name] = true
    end
    for i = 1, 4 do
        local name = UnitName("party" .. i)
        if name and name ~= APR.Username and not known[name] then
            self:UpdateTeamMate({ username = name, noAddon = true }, false, 'gray')
        end
    end
    for name, _ in pairs(self.teamList) do
        if name ~= APR.Username and not UnitInParty(name) then
            self:RemoveMateByName(name)
            self.GroupListSteps[name] = nil
        end
    end
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
    local routeFileName = APR.ActiveRoute
    local curStep = routeFileName and APRData[APR.PlayerID][routeFileName]
    if ((IsInGroup(LE_PARTY_CATEGORY_HOME) and (self.LastSent ~= curStep)) or forceSend) or not APR:IsInstanceWithUI() then
        local _, _, _, expansion = APR:GetCurrentRouteMapIDsAndName()
        local stepDetails = APR.currentStep:GetCurrentStepDetails()
        local dataToSend = {
            route = APR.RouteList[expansion][routeFileName] or routeFileName,
            routeFileName = routeFileName,
            currentStep = stepDetails and stepDetails.progress.step or 0,
            totalSteps = stepDetails and stepDetails.progress.total or 0,
            username = APR.Username,
            stepFrameDetails = stepDetails
        }

        APR:Debug("Sending group data", dataToSend)

        local serializedData = AceSerializer:Serialize(dataToSend)
        APR:SendAddonMessageSplit("APRPartyData", serializedData, "PARTY")
        self.LastSent = curStep
        self:PopulateMissingGroupMembers()
    end
end

function APR.party:SendGroupMessageDelete()
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        C_ChatInfo.SendAddonMessage("APRPartyDelete", APR.Username, "PARTY")
    end
end

local function UpdateGroupStep()
    local sortedGroup = {}
    local highestStepOnSameRoute = 0
    local playerData = APR.party.GroupListSteps[APR.Username]
    local currentRoute = playerData.route

    for _, groupData in pairs(APR.party.GroupListSteps) do
        table.insert(sortedGroup, groupData)
        -- We only take players on the same route to compare the step
        if groupData.route == currentRoute and groupData.currentStep then
            highestStepOnSameRoute = math.max(highestStepOnSameRoute, groupData.currentStep)
        end
    end

    -- Username alphabetical sorting
    table.sort(sortedGroup, function(a, b)
        return string.lower(a.username) < string.lower(b.username)
    end)

    for _, groupData in ipairs(sortedGroup) do
        local isSameRoute = groupData.route == currentRoute
        local color = "gray"

        if isSameRoute then
            color = groupData.currentStep == highestStepOnSameRoute and "green" or "yellow"
        end

        APR.party:UpdateTeamMate(groupData, isSameRoute, color)
    end

    APR.party:PopulateMissingGroupMembers()
    APR.party:RefreshPartyFrameAnchor()
end


function APR.party:UpdateGroupListing(message)
    APR:Debug("Received serialized message", message)

    -- Deserialize the received data
    local success, dataReceived = AceSerializer:Deserialize(message)
    local username = dataReceived.username
    if success then
        -- Update or add member
        self.GroupListSteps[username] = dataReceived
        UpdateGroupStep()
    else
        APR.PrintError(dataReceived)
    end
end

function APR.party:GroupUpdateHandler(prefix, message, channel, sender)
    if channel == "PARTY" and message then
        if prefix == "APRPartyRequest" then
            APR:Debug("Received APRPartyRequestData, sending group data", message)
            self:SendGroupMessage(true)
        end

        if prefix == "APRPartyData" then
            APR:Debug("Received APRPartyData, updating group listing", message)
            self:SplitedMessageHandler(message)
        end

        if prefix == "APRPartyDelete" then
            APR:Debug("Received APRPartyDelete, removing team member", message)
            self:RemoveTeam()
            self:SendGroupMessage(true)
            self:RefreshPartyFrameAnchor()
        end
    end
end

function APR:SendAddonMessageSplit(prefix, fullMessage, channel, target)
    local msgID = tostring(math.random(100000, 999999)) .. "-" .. GetTime() -- Unique message ID with timestamp
    local total = math.ceil(#fullMessage / MAX_MSG_LENGTH)
    APR:Debug("Splitting message", { msgID = msgID, totalParts = total })

    for i = 1, total do
        local startIdx = (i - 1) * MAX_MSG_LENGTH + 1
        local endIdx = math.min(i * MAX_MSG_LENGTH, #fullMessage)
        local part = fullMessage:sub(startIdx, endIdx)

        -- Format: <msgID>|<index>|<total>|<data>
        local fragment = msgID .. "|" .. i .. "|" .. total .. "|" .. part
        C_ChatInfo.SendAddonMessage(prefix, fragment, channel, target)
    end
end

function APR.party:SplitedMessageHandler(message)
    local msgID, index, total, part = message:match("([^|]+)|([^|]+)|([^|]+)|(.+)")

    if not msgID or not index or not total or not part then
        APR:PrintError("Malformed fragment received")
        return
    end

    index = tonumber(index)
    total = tonumber(total)

    APR:Debug("Fragment received", { msgID = msgID, index = index, total = total })


    self.incomingFragments[msgID] = self.incomingFragments[msgID] or {}
    self.incomingFragments[msgID][index] = part

    -- Timeout to clean up fragments after 10 seconds, to avoird memory leaks
    C_Timer.After(10, function()
        APR:Debug("Cleaning expired fragments", msgID)
        self.incomingFragments[msgID] = nil
    end)

    -- Check if we have received all parts
    local receivedParts = self.incomingFragments[msgID]
    local count = 0
    for _, _ in pairs(receivedParts) do count = count + 1 end

    if count == total then
        APR:Debug("All fragments received, reconstructing", msgID)

        -- Concat fragments in right order
        local fullMessage = ""
        for i = 1, total do
            fullMessage = fullMessage .. (receivedParts[i] or "")
        end

        -- Clean
        self.incomingFragments[msgID] = nil

        self:UpdateGroupListing(fullMessage)
    end
end
