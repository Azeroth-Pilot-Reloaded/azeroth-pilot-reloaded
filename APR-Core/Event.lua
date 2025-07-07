local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.event = APR:NewModule("Event")

-- global event framePool for register
APR.event.framePool = {}
APR.event.functions = {}

---------------------------------------------------------------------------------------
------------------------------------- EVENTS ------------------------------------------
---------------------------------------------------------------------------------------

local events = {
    load = "ADDON_LOADED",
    accept = { "QUEST_ACCEPTED", "QUEST_ACCEPT_CONFIRM" },
    detail = "QUEST_DETAIL",
    gossip = { "GOSSIP_CLOSED", "GOSSIP_SHOW" },
    greeting = "QUEST_GREETING",
    remove = "QUEST_REMOVED",
    group = { "GROUP_JOINED", "GROUP_LEFT" },

    ------------------------- TODO
    -- done = "QUEST_TURNED_IN",
    -- setHS = "HEARTHSTONE_BOUND",
    -- spell = "UNIT_SPELLCAST_SUCCEEDED",
    -- raidIcon = "RAID_TARGET_UPDATE",
    -- pet = { "PET_BATTLE_CLOSE", "PET_BATTLE_OPENING_START" },
    -- emote = "CHAT_MSG_TEXT_EMOTE",
    -- taxi = { "TAXIMAP_OPENED", "TAXIMAP_CLOSED" },
    -- fly = { "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED" },
    -- buy = "MERCHANT_SHOW",
    -- qpart = "QUEST_WATCH_UPDATE",
    -- loot = "CHAT_MSG_LOOT",
    -- target = "PLAYER_TARGET_CHANGED",
    -- scenario = "SCENARIO_CRITERIA_UPDATE",
    -- portal = { "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD" },
    -- learnProfession = "LEARNED_SPELL_IN_SKILL_LINE",
    -- buff = "UNIT_AURA",
    -- lvlUp = "PLAYER_LEVEL_UP",
    -- rotateMinimap = "CVAR_UPDATE",
    -- party = "CHAT_MSG_ADDON",
    -- zoneChanged = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "WAYPOINT_UPDATE", "PLAYER_ENTERING_WORLD" },
    -- MinimapZoneChange = { "MINIMAP_UPDATE_ZOOM", "NEW_WMO_CHUNK" }


}

---------------------------------------------------------------------------------------
-------------------------------------- DATA -------------------------------------------
---------------------------------------------------------------------------------------

local autoAccept, autoAcceptRoute, step = nil, nil, nil
local gossipCounter = 0

---------------------------------------------------------------------------------------
---------------------------------- Events register ------------------------------------
---------------------------------------------------------------------------------------
---
function APR.event:MyRegisterEvent()
    for tag, event in pairs(events) do
        local container = self.framePool[tag] or CreateFrame("Frame")
        container.tag = tag
        container.callback = self.functions[tag]

        if type(event) == "string" then
            container:RegisterEvent(event)
            container:SetScript("OnEvent", self.EventHandler)
        elseif type(event) == "table" then
            for _, e in ipairs(event) do
                container:RegisterEvent(e)
                container:SetScript("OnEvent", self.EventHandler)
            end
        end
    end
end

function APR.event.EventHandler(self, event, ...)
    if not APR.settings.profile.enableAddon then
        return
    end

    if not APR:IsInstanceWithUI() then
        APR:Debug("APR: Event - IsInstanceWithUI : " .. APR:IsInstanceWithUI())
        APR.settings:ToggleAddon()
        return
    end

    if self.callback and self.tag then
        APR:DebugEvent("Callback Event", event)
        -- update Local variables before calling the callback
        autoAccept = APR.settings.profile.autoAccept
        autoAcceptRoute = APR.settings.profile.autoAcceptQuestRoute
        step = APR:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)

        pcall(self.callback, event, ...)
    else
        APR:DebugEvent("Unregister Event", event)
        self.callback = nil
        self:UnregisterEvent(event)
    end
end

---------------------------------------------------------------------------------------
---------------------------------- Events always sub ----------------------------------
---------------------------------------------------------------------------------------
---
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent(events.load)
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == events.load then
        local addOnName, containsBindings = ...
        if addOnName == "APR" then
            C_Timer.After(2, function()
                APR:UpdateMapId()
                APR.RouteSelection:RefreshFrameAnchor()
                APR.heirloom:RefreshFrameAnchor()
                APR:UpdateStep()

                APR:PrintInfo("APR " ..
                    L["LOADED"] ..
                    " - Version: |cff00ff00" ..
                    APR.version .. "|r | Interface: |cff00ff00" .. APR.interfaceVersion .. "|r")
            end)
        end
    end
end)


---------------------------------------------------------------------------------------
---------------------------------- Events functions -----------------------------------
---------------------------------------------------------------------------------------
---
function APR.event.functions.accept(event, ...)
    if event == "QUEST_ACCEPTED" then
        local questID = ...;
        if APR.settings.profile.firstAutoShareQuestWithFriend and IsInGroup() then
            APR.questionDialog:CreateQuestionPopup(L["SHOW_GROUP_SHAREWITHFRIEND_FIRSTTIME"], function()
                APR.settings.profile.autoShareQuestWithFriend = true
                if APR.party:CheckIfPartyMemberIsFriend() then
                    C_QuestLog.SetSelectedQuest(questID)
                    QuestLogPushQuest();
                end
            end)
            APR.settings.profile.firstAutoShareQuestWithFriend = false
        end
        if APR.settings.profile.autoShareQuestWithFriend then
            if APR.party:CheckIfPartyMemberIsFriend() then
                C_QuestLog.SetSelectedQuest(questID)
                QuestLogPushQuest();
            end
        end
        APR:Debug(L["Q_ACCEPTED"] .. ": ", questID)
        C_Timer.After(0.2, function() APR:UpdateMapId() end)
    end

    if event == "QUEST_ACCEPT_CONFIRM" then -- escort quest
        if IsModifierKeyDown() then return end
        if autoAccept or autoAcceptRoute then
            C_Timer.After(0.2, function() APR:AcceptQuest() end)
        end
    end
end

function APR.event.functions.gossip(event, ...)
    if event == "GOSSIP_CLOSED" then
        gossipCounter = 0
    end

    if event == "GOSSIP_SHOW" then
        -- Exit function if you press Ctrl/shift/alt key before the
        if IsModifierKeyDown() then return end

        -- Deny NPC
        APR.event:TalkToDenyNpcLogic(step)

        APR.event:HandleGossipLogic(step)
        --PICKUP / HANDIN
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        local activeQuests = C_GossipInfo.GetActiveQuests()
        -- Handin
        if (APR.settings.profile.autoHandIn) then
            if activeQuests then
                for _, questInfo in ipairs(activeQuests) do
                    if questInfo.title and questInfo.isComplete then
                        if questInfo.questID then
                            return C_GossipInfo.SelectActiveQuest(questInfo.questID)
                        end
                    end
                end
            end
        end
        -- Pickup
        if autoAcceptRoute or autoAccept then
            if availableQuests then
                for _, questInfo in ipairs(availableQuests) do
                    if questInfo.questID then
                        if (autoAcceptRoute and APR:IsARouteQuest(questInfo.questID)) or autoAccept then
                            return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
                        end
                    end
                end
            end
        end
    end
end

function APR.event.functions.greeting(event, ...)
    -- Exit function if you press Ctrl/shift/alt key before the
    if IsModifierKeyDown() then return end
    -- Deny NPC
    APR.event:TalkToDenyNpcLogic(step)


    -- Handle gossip logic if gossip is available for this greeting frame
    if C_GossipInfo and C_GossipInfo.GetOptions and next(C_GossipInfo.GetOptions()) then
        gossipCounter = APR.event:HandleGossipLogic(step)
    end

    -- Done (Handin)
    if (APR.settings.profile.autoHandIn) then
        for i = 1, GetNumActiveQuests() do
            local title, isComplete = GetActiveTitle(i)
            if title and isComplete then
                return SelectActiveQuest(i)
            end
        end
    end
    -- Pickup
    if autoAcceptRoute or autoAccept then
        local numAvailableQuests = GetNumAvailableQuests()
        for i = 1, numAvailableQuests do
            local _, _, _, _, questID = GetAvailableQuestInfo(i)
            if (autoAcceptRoute and APR:IsARouteQuest(questID)) or autoAccept then
                return SelectAvailableQuest(i)
            elseif (i == numAvailableQuests and APR:IsPickupStep()) then
                C_Timer.After(0.2, function() APR:CloseQuest() end)
            end
        end
    end
end

function APR.event.functions.detail(event, questStartItemID)
    -- Fired when the player is given a more detailed view of his quest.
    if IsModifierKeyDown() or (not autoAcceptRoute and not autoAccept) then return end
    -- Deny NPC
    APR.event:TalkToDenyNpcLogic(step)

    -- Check if the quest is a route quest
    -- Implement a retry mechanism to handle quest detail
    local function handleQuestDetail()
        local questID = GetQuestID()
        if questID then
            if QuestGetAutoAccept() then
                C_Timer.After(0.2, function() APR:CloseQuest() end)
            elseif (autoAcceptRoute and APR:IsARouteQuest(questID)) or autoAccept then
                C_Timer.After(0.2, function() APR:AcceptQuest() end)
            elseif APR:IsPickupStep() then
                C_Timer.After(0.2, function() APR:CloseQuest() end)
                APR:NotYet()
            else
                -- Retry
                C_Timer.After(0.2, handleQuestDetail)
            end
            return
        end
        C_Timer.After(0.2, handleQuestDetail)
    end

    handleQuestDetail()
end

function APR.event.functions.group(event, category, partyGUID)
    if event == "GROUP_JOINED" then
        APR.party:SendGroupMessage()
    end

    if event == "GROUP_LEFT" then
        -- remove all the teammate then resend name + step to the group
        -- because wow don't send the username of the leaver
        APR.party:RemoveTeam()
        APR.party:SendGroupMessage()
        APR.party:RefreshPartyFrameAnchor()
    end
end

function APR.event.functions.remove(event, questID, wasReplayQuest)
    APR:Debug(L["Q_REMOVED"], questID)
    APR:RemoveQuest(questID)
    if (APR.ActiveRoute == questID) then
        APRData[APR.PlayerID][questID] = nil
        APR.map:RemoveMapLine()
        APR:UpdateMapId()
    end
    APR:UpdateStep()
end

---------------------------------------------------------------------------------------
---------------------------------- Events utils ---------------------------------------
---------------------------------------------------------------------------------------
function APR.event:HandleGossipLogic(step)
    if step and APR.settings.profile.autoGossip then
        print("APR: HandleGossipLogic")
        local function PickGossipByIcon(iconId)
            local gossipOption = C_GossipInfo.GetOptions()
            if next(gossipOption) then
                for _, gossip in pairs(gossipOption) do
                    if gossip.icon == iconId then
                        C_GossipInfo.SelectOption(gossip.gossipOptionID)
                    end
                end
            end
        end
        ------------------------------------
        -- SetHS
        if step.SetHS then
            PickGossipByIcon(136458)
        end
        ------------------------------------
        -- FlightPath
        if (step.UseFlightPath or step.GetFP) and not step.NoAutoFlightMap and not (step.GossipOptionID or step.GossipOptionIDs) then
            PickGossipByIcon(132057)
        end
        -- BuyMerchant
        if step.BuyMerchant and not (step.GossipOptionID or step.GossipOptionIDs) then
            PickGossipByIcon(132060)
        end
        ------------------------------------
        -- GOSSIP
        if step.Gossip or step.GossipOptionID or step.GossipOptionIDs then
            if (step.Gossip == 28202) then -- GOSSIP HARDCODED
                -- //TODO Remove this when all hardcoded gossip are removed
                -- This is a hardcoded gossip for the quest https://www.wowhead.com/quest=28205/a-perfect-costume
                gossipCounter = APR:HandleHardcodedGossip(step, gossipCounter)
            else
                print("APR: HandleGossipLogic - Gossip")
                local info = C_GossipInfo.GetOptions()
                if next(info) then
                    if step.GossipOptionID then
                        C_GossipInfo.SelectOption(step.GossipOptionID)
                    elseif step.GossipOptionIDs then
                        for _, g in pairs(step.GossipOptionIDs) do
                            C_GossipInfo.SelectOption(g)
                        end
                    else
                        for _, v in pairs(info) do
                            if (v.orderIndex + 1 == step.Gossip) then
                                C_GossipInfo.SelectOption(v.gossipOptionID)
                            end
                        end
                    end
                end

                --CHROMIE
                if (step.ChromiePick) then
                    local targetID = APR:GetTargetID()
                    if (targetID == 167032) then
                        local extraText = L["SWITCH_TO_CHROMIE"] ..
                            " " .. C_ChromieTime.GetChromieTimeExpansionOption(step.ChromiePick).name
                        APR.currentStep:AddExtraLineText('ChromiePick', extraText)
                        C_Timer.After(1,
                            function() C_ChromieTime.SelectChromieTimeOption(step.ChromiePick) end)
                    end
                end
            end
        end
    end
end

function APR.event:TalkToDenyNpcLogic(step)
    APR:CheckDenyNPC(step)
    local npcId = APR:GetTargetID()
    if step and step.NpcDismount == npcId then
        Dismount()
    end
end

-- Map

-- QUEST_LOG_UPDATE


-- transport
-- TAXIMAP_OPENED
-- PLAYER_CONTROL_LOST

-- ZONE_CHANGED
-- ZONE_CHANGED_INDOORS
-- ZONE_CHANGED_NEW_AREA
-- PLAYER_ENTERING_WORLD
-- WAYPOINT_UPDATE

-- sceneCutter
-- CINEMATIC_START


-- questhandler
-- ADVENTURE_MAP_OPEN
-- CHAT_MSG_COMBAT_XP_GAIN
-- CHAT_MSG_LOOT
-- CHAT_MSG_MONSTER_SAY
-- ENCOUNTER_LOOT_RECEIVED
-- GOSSIP_CLOSED
-- GOSSIP_SHOW
-- GROUP_JOINED
-- GROUP_LEFT
-- HEARTHSTONE_BOUND
-- LEARNED_SPELL_IN_SKILL_LINE
-- MERCHANT_SHOW
-- PET_BATTLE_CLOSE
-- PET_BATTLE_OPENING_START
-- PLAYER_CHOICE_UPDATE
-- PLAYER_TARGET_CHANGED
-- QUEST_ACCEPTED
-- QUEST_ACCEPT_CONFIRM
-- QUEST_AUTOCOMPLETE
-- QUEST_COMPLETE
-- QUEST_DETAIL
-- QUEST_GREETING
-- QUEST_LOG_UPDATE
-- QUEST_PROGRESS
-- QUEST_REMOVED
-- REQUEST_CEMETERY_LIST_RESPONSE
-- SCENARIO_COMPLETED
-- SCENARIO_CRITERIA_UPDATE
-- TAXIMAP_OPENED
-- UI_INFO_MESSAGE
-- UNIT_AURA
-- UNIT_ENTERED_VEHICLE
-- UNIT_QUEST_LOG_CHANGED
-- UNIT_SPELLCAST_SUCCEEDED
-- UPDATE_MOUSEOVER_UNIT
-- ZONE_CHANGED_NEW_AREA
