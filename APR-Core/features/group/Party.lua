-- Owns group-progress presentation, throttled snapshots and incoming fragment reassembly.
-- Pooled rows retain APR ownership; incomplete messages expire without retaining a permanent ticker.

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
local MAX_FRAGMENT_COUNT = 128 -- Bound an incomplete group snapshot to 23 KiB.
local GROUP_SEND_THROTTLE = 0.5
local MAX_PENDING_MESSAGES = 80 -- Two snapshots per raid member, at most.
local FRAGMENT_TTL = 10
local FRAGMENT_SWEEP_INTERVAL = 5
local UpdateGroupStep


-- Init list
APR.party.teamList = {}
APR.party.GroupListSteps = {}
APR.party.incomingFragments = APR.party.incomingFragments or {}
APR.party.fragmentExpiry = APR.party.fragmentExpiry or {}
APR.party.containerPool = APR.party.containerPool or {}

local function GetGroupChannel()
    return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
end


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
APR:RegisterFontString(PartyFrameHeader.Text, "party", { role = "accent", sizeDelta = 2 })

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

    if APR.settings.profile.groupFrame.point then
        LibWindow.RestorePosition(PartyScreenPanel)
    end

    self:RefreshPartyFrameAnchor()
end

function APR.party:SetDefaultDisplay()
    PartyFrame.collapsed = false
    PartyFrame_TeamHolder:Show()
    PartyFrameHeader:Show()
end

-- Update the frame scale
function APR.party:UpdateFrameScale()
    LibWindow.SetScale(PartyScreenPanel, APR.settings.profile.groupScale)
end

function APR.party:RefreshPartyFrameAnchor(forceShow)
    APR:Debug("Function: APR.party:RefreshPartyFrameAnchor()")
    local hasData = next(APR.party.GroupListSteps)

    local profile = APR:GetSettingsProfile()
    if not profile or not profile.enableAddon then
        PartyScreenPanel:Hide()
        return
    end

    local allowTestVisibility = forceShow
    if not allowTestVisibility then
        if not profile.showGroup or not profile.receiveGroupData then
            PartyScreenPanel:Hide()
            return
        end
    end

    if not allowTestVisibility and (not IsInGroup() or APR:IsPetBattleActive() or not hasData) then
        PartyScreenPanel:Hide()
        return
    end

    if not hasData then
        PartyScreenPanel:Hide()
        return
    end

    if APR:IsPetBattleActive() then
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

function APR.party:HandleReceiveGroupDataToggle(isEnabled)
    local enabled = isEnabled
    if enabled == nil and APR.settings and APR.settings.profile then
        enabled = APR.settings.profile.receiveGroupData
    end

    if not enabled then
        self:RemoveTeam()
        PartyScreenPanel:Hide()
    else
        self:RequestData()
        self:RefreshPartyFrameAnchor()
    end
end

local function TeamContainerOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    local data = self.playerData
    GameTooltip:ClearLines()

    if not data then
        return GameTooltip:Show()
    end

    APR:AddTooltipLine(GameTooltip, data.username or UNKNOWN, "party", "accent")
    GameTooltip:AddLine(" ")

    if data.noAddon then
        APR:AddTooltipLine(GameTooltip, L["NO_ADDON"], "party", "error")
    elseif not data.route then
        APR:AddTooltipLine(GameTooltip, L["NO_ROUTE"], "party", "warning")
    else
        APR:AddTooltipDoubleLine(GameTooltip, L["ROUTE_LABEL"], data.route, "party", "muted", "base")

        if data.currentStep and data.totalSteps then
            APR:AddTooltipDoubleLine(GameTooltip, L["CURRENT_STEP_LABEL"],
                data.currentStep .. " / " .. data.totalSteps, "party", "muted", "success")
        end

        local stepText = APR.party:GetStepDescription(data.routeFileName,
            data.stepFrameDetails and data.stepFrameDetails.progress and data.stepFrameDetails.progress.index)
        if stepText and stepText ~= "" then
            GameTooltip:AddLine(" ")
            APR:AddTooltipLine(GameTooltip, DESCRIPTION, "party", "accent")
            APR:AddTooltipLine(GameTooltip, stepText, "party", "base", true)
        end

        if data.stepFrameDetails and (data.stepFrameDetails.extraLines or
                (data.stepFrameDetails.questSteps and not skipQuestSteps)) then
            GameTooltip:AddLine(" ")
            APR:AddTooltipLine(GameTooltip, OBJECTIVES_LABEL, "party", "accent")

            if data.stepFrameDetails.extraLines then
                for _, extra in ipairs(data.stepFrameDetails.extraLines) do
                    APR:AddTooltipLine(GameTooltip, extra.text, "party", "warning", true)
                end
            end

            if data.stepFrameDetails.questSteps then
                for _, step in ipairs(data.stepFrameDetails.questSteps) do
                    APR:AddTooltipLine(GameTooltip, step.text, "party", "muted", true)
                    if step.subSteps then
                        for _, sub in ipairs(step.subSteps) do
                            APR:AddTooltipLine(GameTooltip, "" .. sub.text, "party", "muted", true)
                        end
                    end
                end
            end
        end
    end

    GameTooltip:Show()
end

local function AcquireTeamContainer()
    local container = table.remove(APR.party.containerPool)
    if not container then
        container = CreateFrame("Frame", nil, PartyFrame_TeamHolder, "BackdropTemplate")
        container:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            tile = true,
            tileSize = 16
        })
        APR:SetPanelColor(container, APR.Color.defaultLightBackdrop)

        container.fontName = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        container.fontName:SetWordWrap(true)
        container.fontName:SetWidth(FRAME_WIDTH)
        container.fontName:SetPoint("TOPLEFT", 5, -5)
        container.fontName:SetJustifyH("LEFT")
        APR:RegisterFontString(container.fontName, "party", { role = "base" })

        container.fontIndex = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        container.fontIndex:SetPoint("TOPRIGHT", 0, -2)
        APR:RegisterFontString(container.fontIndex, "party", { role = "base", sizeDelta = 4 })

        container:SetScript("OnEnter", TeamContainerOnEnter)
        container:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    else
        container:SetParent(PartyFrame_TeamHolder)
        APR:SetPanelColor(container, APR.Color.defaultLightBackdrop)
        container:Show()
    end

    container:SetWidth(FRAME_WIDTH)
    return container
end

local function ReleaseTeamContainer(container)
    if not container then return end
    container:Hide()
    container:ClearAllPoints()
    container.playerData = nil
    if container.fontName then container.fontName:SetText("") end
    if container.fontIndex then container.fontIndex:SetText("") end
    table.insert(APR.party.containerPool, container)
end

local AddTeamMate = function(playerData, isSameRoute, color, container)
    container = container or AcquireTeamContainer()
    container.playerData = playerData

    container.fontName:SetText(playerData.username or UNKNOWN)

    if playerData.currentStep then
        container.fontIndex:SetText(playerData.currentStep)
    else
        container.fontIndex:SetText('-')
    end
    if isSameRoute then
        APR:SetFontStringRole(container.fontIndex, color == "green" and "success" or "warning")
    else
        APR:SetFontStringRole(container.fontIndex, "muted")
    end

    APR:SetPanelColor(container, APR.Color.defaultLightBackdrop)
    container:SetWidth(FRAME_WIDTH)
    local height = math.max(container.fontIndex:GetStringHeight(), container.fontName:GetStringHeight()) + 10
    container:SetHeight(height)
    container:Show()

    return container
end


function APR.party:GetStepDescription(route, stepIndex)
    if not route or not stepIndex then return '' end

    local routeData = APR.RouteQuestStepList[route]
    if not routeData then return '' end

    local routeTable = APR:GetRouteSteps(route)
    local step = routeTable[stepIndex]
    if not step then return '' end

    local stepText = APR:GetStepString(step)
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
        local name = APR:GetQuestTitle(qid)
        if name then
            table.insert(questNames, "- " .. name)
        end
    end

    if #questNames > 0 then
        stepText = stepText .. "\n" .. table.concat(questNames, "\n")
    end

    return stepText
end

function APR.party:UpdateTeamMate(playerData, isSameRoute, color)
    local username = playerData.username
    APR:Debug("Function: APR.party:UpdateTeamMate() for", username)
    local existingContainer = self.teamList[username]

    local container = AddTeamMate(playerData, isSameRoute, color, existingContainer)
    self.teamList[username] = container
end

function APR.party:ReOrderTeam(order)
    FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET

    local orderedNames = {}
    local added = {}

    if order then
        for _, entry in ipairs(order) do
            local name = type(entry) == "table" and entry.username or entry
            if name and self.teamList[name] then
                table.insert(orderedNames, name)
                added[name] = true
            end
        end
    end

    for name in pairs(self.teamList) do
        if not added[name] then
            table.insert(orderedNames, name)
        end
    end

    table.sort(orderedNames, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    for _, name in ipairs(orderedNames) do
        local container = self.teamList[name]
        if container then
            container:ClearAllPoints()
            container:SetPoint("TOPLEFT", PartyFrame, "TOPLEFT", 0, FRAME_MATE_HOLDER_HEIGHT)
            container:Show()
            FRAME_MATE_HOLDER_HEIGHT = FRAME_MATE_HOLDER_HEIGHT - container:GetHeight()
        end
    end

    self:RefreshPartyFrameAnchor()
end

function APR.party:RefreshTextLayout()
    for _, container in pairs(self.teamList) do
        local height = math.max(container.fontIndex:GetStringHeight(), container.fontName:GetStringHeight()) + 10
        container:SetHeight(height)
    end
    self:ReOrderTeam()
end

function APR.party:RemoveMateByName(name, skipReorder)
    local existingMate = self.teamList[name]
    if not existingMate then
        return
    end
    ReleaseTeamContainer(existingMate)
    self.teamList[name] = nil
    if not skipReorder then
        self:ReOrderTeam()
    end
end

function APR.party:RemoveTeam()
    APR:Debug("Function: APR.party:RemoveTeam()")
    for id, container in pairs(self.teamList) do
        ReleaseTeamContainer(container)
    end
    wipe(self.teamList)
    wipe(self.GroupListSteps)
    wipe(self.incomingFragments)
    wipe(self.fragmentExpiry)
    if self.fragmentCleanupTicker then
        self.fragmentCleanupTicker:Cancel()
        self.fragmentCleanupTicker = nil
    end
    FRAME_MATE_HOLDER_HEIGHT = FRAME_OFFSET
end


function APR.party:PopulateMissingGroupMembers(skipReorder)
    if not IsInGroup() then
        self:RemoveTeam()
        return
    end
    local known = {}
    for name, _ in pairs(self.GroupListSteps) do
        known[name] = true
    end
    for i = 1, 4 do
        local name = APR:SafeUnitName("party" .. i)
        if name and name ~= APR.Username and not known[name] then
            self:UpdateTeamMate({ username = name, noAddon = true }, false, 'gray')
        end
    end
    for name, _ in pairs(self.teamList) do
        if name ~= APR.Username and not UnitInParty(name) then
            self:RemoveMateByName(name, true)
            self.GroupListSteps[name] = nil
        end
    end
    if not skipReorder then
        self:ReOrderTeam()
    end
end

function APR.party:CheckIfPartyMemberIsFriend()
    -- If Player is NOT in a Group (not instance), do nothing
    if not IsInGroup() then
        return false
    end

    -- Get FriendLists (WoW and BNet)
    local FriendListTable = self:GetFriendsList()

    -- Check if a party member is a BNet or WoW friend
    for groupindex = 1, 5 do
        local nameOfPartyMember = APR:SafeUnitName("party" .. groupindex)
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

function APR.party:SendGroupMessage(force)
    self:QueueGroupMessage(force)
end

function APR.party:BuildGroupPayload(username)
    local routeFileName = APR.ActiveRoute
    local _, _, _, expansion = APR:GetCurrentRouteMapIDsAndName()
    local stepDetails = APR.currentStep:GetCurrentStepDetails()
    local route
    if routeFileName then
        route = APR:GetRouteDisplayName(routeFileName) or routeFileName
    else
        route = routeFileName
    end

    return {
        route = route,
        routeFileName = routeFileName,
        currentStep = stepDetails and stepDetails.progress.step or nil,
        totalSteps = stepDetails and stepDetails.progress.total or 0,
        username = username or APR.Username,
        stepFrameDetails = stepDetails,
        sojournerSkipCampaign = APR.settings and APR.settings.profile
            and APR.settings.profile.sojournerSkipCampaign or false,
    }
end

function APR.party:SendGroupMessageNow()
    self.pendingGroupSend = false

    local dataToSend = self:BuildGroupPayload(APR.Username)
    if IsInGroup() and APR.settings.profile.enableAddon then
        local routeFileName = APR.ActiveRoute
        APR:Debug("Sending group data", dataToSend)

        -- Keep local cache in sync without round-tripping through CHAT_MSG_ADDON
        self.GroupListSteps[APR.Username] = dataToSend

        local serializedData = AceSerializer:Serialize(dataToSend)
        APR:SendAddonMessageSplit("APRPartyData", serializedData, GetGroupChannel())
        self:PopulateMissingGroupMembers()
        UpdateGroupStep()
    end
end

function APR.party:QueueGroupMessage(force)
    if force then
        self.pendingGroupSend = false
        if self.groupSendTimer then
            self.groupSendTimer:Cancel()
            self.groupSendTimer = nil
        end
        self:SendGroupMessageNow()
        return
    end

    if not IsInGroup() or not APR.settings.profile.enableAddon then return end

    self.pendingGroupSend = true

    if self.groupSendTimer then
        return
    end

    self.groupSendTimer = C_Timer.NewTimer(GROUP_SEND_THROTTLE, function()
        self.groupSendTimer = nil
        if self.pendingGroupSend then
            self:SendGroupMessageNow()
            self.pendingGroupSend = false
        end
    end)
end

function APR.party:SendGroupMessageDelete()
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage("APRPartyDelete", APR.Username, GetGroupChannel())
    end
end

UpdateGroupStep = function()
    APR:Debug("Function: APR.party:UpdateGroupStep()")
    local sortedGroup = {}
    local highestStepOnSameRoute = 0
    local playerData = APR.party.GroupListSteps[APR.Username]
    local currentRoute = playerData and playerData.route

    for _, groupData in pairs(APR.party.GroupListSteps) do
        table.insert(sortedGroup, groupData)
        -- We only take players on the same route to compare the step
        if currentRoute and groupData.route == currentRoute and groupData.currentStep then
            highestStepOnSameRoute = math.max(highestStepOnSameRoute, groupData.currentStep)
        end
    end

    -- Username alphabetical sorting
    table.sort(sortedGroup, function(a, b)
        return string.lower(a.username) < string.lower(b.username)
    end)

    for _, groupData in ipairs(sortedGroup) do
        local isSameRoute = currentRoute and groupData.route == currentRoute
        local color = "gray"

        if isSameRoute then
            color = groupData.currentStep == highestStepOnSameRoute and "green" or "yellow"
        end

        APR.party:UpdateTeamMate(groupData, isSameRoute, color)
    end

    APR.party:PopulateMissingGroupMembers(true)
    APR.party:ReOrderTeam(sortedGroup)
end


function APR.party:UpdateGroupListing(message, sender)
    APR:Debug("Message to deserialize", message)

    if type(message) ~= "string" or #message > MAX_FRAGMENT_COUNT * 180 then return false end
    local started = APR:StartPerformanceSample()
    local success, received = AceSerializer:Deserialize(message)
    local data, reason
    if success then data, reason = APR.PartyProtocol.NormalizeSnapshot(received, sender) end
    APR:FinishPerformanceSample("PartyValidate", started)
    if not data then
        self.rejectedMessages = (self.rejectedMessages or 0) + 1
        self.lastRejectReason = reason or "deserialize"
        return false
    end
    self.GroupListSteps[data.username] = data
    UpdateGroupStep()
    return true
end

function APR.party:GroupUpdateHandler(prefix, message, channel, sender)
    if not APR.settings.profile.enableAddon then return end
    if APR.PartyProtocol.PlayerKey(sender) == APR.PartyProtocol.PlayerKey(APR.Username) then return end
    if not sender or not ((UnitInParty and UnitInParty(sender)) or (UnitInRaid and UnitInRaid(sender))) then return end

    local allowIncomingData = APR.settings.profile.receiveGroupData

    if (channel == "PARTY" or channel == "INSTANCE_CHAT" or channel == "RAID") and message then
        if prefix == "APRVersionCheck" then
            if message and #message <= 32 then
                APR.versionCheck:HandleVersionMessage(message)
            end
        end

        if prefix == "APRPartyRequest" then
            APR:Debug("Received APRPartyRequestData, sending group data", message)
            self:SendGroupMessage(true)
        end

        if prefix == "APRPartyData" then
            if not allowIncomingData then
                APR:Debug("Ignoring APRPartyData because reception is disabled", sender)
                return
            end
            APR:Debug("Received APRPartyData, updating group listing", message)
            self:HandleMessageFragment(message, sender)
        end

        if prefix == "APRPartyDelete" then
            if not allowIncomingData then
                APR:Debug("Ignoring APRPartyDelete because reception is disabled", sender)
                return
            end
            APR:Debug("Received APRPartyDelete, removing team member", message)
            self:Delete()
        end
    end
end


function APR.party:StartFragmentCleanupTicker()
    if self.fragmentCleanupTicker then
        return
    end

    self.fragmentCleanupTicker = C_Timer.NewTicker(FRAGMENT_SWEEP_INTERVAL, function()
        self:CleanupExpiredFragments()
    end)
end

function APR.party:CleanupExpiredFragments()
    local now = GetTime()
    for msgID, expireAt in pairs(self.fragmentExpiry) do
        if expireAt <= now then
            self.incomingFragments[msgID] = nil
            self.fragmentExpiry[msgID] = nil
        end
    end

    if not next(self.fragmentExpiry) and self.fragmentCleanupTicker then
        self.fragmentCleanupTicker:Cancel()
        self.fragmentCleanupTicker = nil
    end
end

-- Fragments can arrive out of order or be duplicated. Sender-scoped keys prevent
-- two group members with the same message ID from mixing their snapshots.
function APR.party:HandleMessageFragment(message, sender)
    if not APR.settings.profile.receiveGroupData or type(message) ~= "string" then return end
    local messageID, index, total, part = message:match("^([^|]+)|(%d+)|(%d+)|(.*)$")
    index, total = tonumber(index), tonumber(total)
    if not messageID or #messageID > 64 or not index or not total
        or index < 1 or index > total or total > MAX_FRAGMENT_COUNT or #part > 180 then
        return
    end

    local key = (sender or "") .. "|" .. messageID
    local fragments = self.incomingFragments[key]
    if fragments and fragments.total ~= total then return end
    if not fragments then
        local pending, fromSender = 0, 0
        for _, record in pairs(self.incomingFragments) do
            pending = pending + 1
            if record.sender == sender then fromSender = fromSender + 1 end
        end
        if pending >= MAX_PENDING_MESSAGES or fromSender >= 2 then return end
        fragments = { total = total, count = 0, parts = {}, sender = sender }
        self.incomingFragments[key] = fragments
    end
    if fragments.parts[index] then return end
    fragments.parts[index] = part
    fragments.count = fragments.count + 1
    self.fragmentExpiry[key] = GetTime() + FRAGMENT_TTL

    if fragments.count == total then
        self.incomingFragments[key] = nil
        self.fragmentExpiry[key] = nil
        self:CleanupExpiredFragments()
        self:UpdateGroupListing(table.concat(fragments.parts), sender)
    else
        self:StartFragmentCleanupTicker()
    end
end

function APR.party:Delete()
    self:RemoveTeam()
    self:SendGroupMessage(true)
    self:RefreshPartyFrameAnchor()
end

function APR.party:RequestData()
    if not APR.settings.profile.receiveGroupData then
        return
    end
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage("APRPartyRequest", "APRPartyRequest", GetGroupChannel())
    end
end
