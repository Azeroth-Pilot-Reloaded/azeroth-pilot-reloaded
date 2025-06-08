local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR_QH_EventFrame = CreateFrame("Frame")
APR_QH_EventFrame:RegisterEvent("ADVENTURE_MAP_OPEN")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_LOOT")
APR_QH_EventFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
APR_QH_EventFrame:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
APR_QH_EventFrame:RegisterEvent("GOSSIP_CLOSED")
APR_QH_EventFrame:RegisterEvent("GOSSIP_SHOW")
APR_QH_EventFrame:RegisterEvent("GROUP_JOINED")
APR_QH_EventFrame:RegisterEvent("GROUP_LEFT")
APR_QH_EventFrame:RegisterEvent("HEARTHSTONE_BOUND")
APR_QH_EventFrame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
APR_QH_EventFrame:RegisterEvent("MERCHANT_SHOW")
APR_QH_EventFrame:RegisterEvent("PET_BATTLE_CLOSE")
APR_QH_EventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
APR_QH_EventFrame:RegisterEvent("PLAYER_CHOICE_UPDATE")
APR_QH_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
APR_QH_EventFrame:RegisterEvent("QUEST_ACCEPTED")
APR_QH_EventFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM")
APR_QH_EventFrame:RegisterEvent("QUEST_AUTOCOMPLETE")
APR_QH_EventFrame:RegisterEvent("QUEST_COMPLETE")
APR_QH_EventFrame:RegisterEvent("QUEST_DETAIL")
APR_QH_EventFrame:RegisterEvent("QUEST_GREETING")
APR_QH_EventFrame:RegisterEvent("QUEST_LOG_UPDATE")
APR_QH_EventFrame:RegisterEvent("QUEST_PROGRESS")
APR_QH_EventFrame:RegisterEvent("QUEST_REMOVED")
APR_QH_EventFrame:RegisterEvent("REQUEST_CEMETERY_LIST_RESPONSE")
APR_QH_EventFrame:RegisterEvent("SCENARIO_COMPLETED")
APR_QH_EventFrame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
APR_QH_EventFrame:RegisterEvent("TAXIMAP_OPENED")
APR_QH_EventFrame:RegisterEvent("UI_INFO_MESSAGE")
APR_QH_EventFrame:RegisterEvent("UNIT_AURA")
APR_QH_EventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
APR_QH_EventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
APR_QH_EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
APR_QH_EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
APR_QH_EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

APR_QH_EventFrame:SetScript("OnEvent", function(self, event, ...)
    if not APR:IsInstanceWithUI() then
        if APR.settings.profile.debug then
            print("APR: EventFrame - IsInstanceWithUI : ", APR:IsInstanceWithUI())
        end
        APR.settings:ToggleAddon()
        return
    end

    if APR.settings.profile.showEvent then
        print("EVENT: QuestHandler - ", event)
    end

    if not APR.settings.profile.enableAddon then
        return
    end
    local autoAccept = APR.settings.profile.autoAccept
    local autoAcceptRoute = APR.settings.profile.autoAcceptQuestRoute
    local step = APR:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)

    if event == "ADVENTURE_MAP_OPEN" then
        if IsModifierKeyDown() or (not autoAcceptRoute and not autoAccept) then return end
        if not APR:IsPickupStep() then
            C_AdventureMap.Close();
            print("APR: " .. L["NOT_YET"])
            return
        end
        C_Timer.After(0.3, function()
            local numChoices = C_AdventureMap.GetNumZoneChoices()
            for choiceIndex = 1, numChoices do
                local questID, textureKit, name, zoneDescription, normalizedX, normalizedY = C_AdventureMap
                    .GetZoneChoiceInfo(choiceIndex);
                if AdventureMap_IsQuestValid(questID, normalizedX, normalizedY) then
                    if step and (APR:Contains(step.PickUp, questID) or APR:Contains(step.PickUpDB, questID)) then
                        C_AdventureMap.StartQuest(questID)
                    end
                end
            end
        end)
    end

    if (event == "CHAT_MSG_COMBAT_XP_GAIN") then
        if (step and step.Treasure) then
            C_Timer.After(0.2, function() APR:UpdateQuestAndStep() end)
        end
    end

    if (event == "CHAT_MSG_LOOT") then
        if step and step.BuyMerchant and not step.Qpart then
            local message = ...
            local itemLink = string.match(message, "|Hitem:.-|h.-|h")
            local quantity = APR:GetQuantityfromLootMessage(message)
            if itemLink then
                local itemID, _, _, _, _, _, _ = C_Item.GetItemInfoInstant(itemLink)
                APR:UpdatePurchaseTracking(itemID, quantity)
            end
        end
    end

    if (event == "CHAT_MSG_MONSTER_SAY") then
        local text = ...;
        local npc_id, name = APR:GetTargetID(), UnitName("target")
        if npc_id and name then
            if npc_id == 159477 then -- quest 57870
                local gigglingBasket = {
                    ["GIGGLING_BASKET_ONE_TIME"] = "cheer",
                    ["GIGGLING_BASKET_SPRIGGANS"] = "flex",
                    ["GIGGLING_BASKET_MANY"] = "thank",
                    ["GIGGLING_BASKET_FAE"] = "introduce",
                    ["GIGGLING_BASKET_FEET"] = "dance",
                    ["GIGGLING_BASKET_HELP"] = "praise",
                }
                for key, emote in pairs(gigglingBasket) do
                    local message = L[key]
                    if string.find(text, message) then
                        if APR.settings.profile.debug then
                            print("APR: " .. L["DOING_EMOTE"] .. ": " .. emote)
                        end
                        DoEmote(emote)
                        break
                    end
                end
            end
        end
    end

    if event == "ENCOUNTER_LOOT_RECEIVED" then
        local encounterID, itemID, itemLink, quantity, playerName, classFileName = ...
        do
            if step and step.LootItem then
                local stepItemID = step.LootItem
                if stepItemID == itemID then
                    tinsert(APRItemLooted[APR.PlayerID], itemID)
                    APR:UpdateNextStep()
                end
            end
        end
    end

    if (event == "GOSSIP_CLOSED") then
        APR.GossipCount = 0
    end

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

    if (event == "HEARTHSTONE_BOUND") then
        if (step and step.SetHS) then
            APR:UpdateNextStep()
        end
    end

    if (event == "LEARNED_SPELL_IN_SKILL_LINE") then
        local spellID, skillLineIndex = ...
        if step and step.LearnProfession then
            if spellID == step.LearnProfession then
                APR:UpdateNextStep()
            end
        end
    end

    if (event == "MERCHANT_SHOW") then
        if IsModifierKeyDown() then return end
        if (step and step.BuyMerchant) then
            APR:StartPurchaseTracking(step.BuyMerchant)
            APR:BuyMerchFunc(step.BuyMerchant)
        end
        if (APR.settings.profile.autoRepair) then
            if (CanMerchantRepair()) then
                local repairAllCost, canRepair = GetRepairAllCost();
                if (canRepair and repairAllCost > 0) then
                    local guildRepairedItems = false
                    if (IsInGuild() and CanGuildBankRepair()) then
                        local amount = GetGuildBankWithdrawMoney()
                        local guildBankMoney = GetGuildBankMoney()
                        amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                        if (amount >= repairAllCost) then
                            RepairAllItems(true);
                            guildRepairedItems = true
                            DEFAULT_CHAT_FRAME:AddMessage("APR: Equipment has been repaired by your Guild")
                        end
                    end
                    if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                        RepairAllItems(false);
                        print("APR: " ..
                            L["REPAIR_EQUIPEMENT"] .. " " .. C_CurrencyInfo.GetCoinTextureString(repairAllCost))
                    end
                end
            end
        end
        if (APR.settings.profile.autoVendor) then
            local APRtotal = 0
            for myBags = 0, 4 do
                for bagSlots = 1, C_Container.GetContainerNumSlots(myBags) do
                    local CurrentItemId = C_Container.GetContainerItemID(myBags, bagSlots)
                    if CurrentItemId then
                        local _, _, itemQuality, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(CurrentItemId)
                        local itemInfo = C_Container.GetContainerItemInfo(myBags, bagSlots)
                        if itemQuality == 0 and sellPrice > 0 and itemInfo.stackCount > 0 then
                            APRtotal = APRtotal + (sellPrice * itemInfo.stackCount)
                            C_Container.UseContainerItem(myBags, bagSlots)
                        end
                    end
                end
            end
            if APRtotal ~= 0 then
                print("APR:" .. L["ITEM_SOLD"] .. " " .. C_CurrencyInfo.GetCoinTextureString(APRtotal))
            end
        end
    end

    if event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then
        APR.currentStep:RefreshCurrentStepFrameAnchor()
        APR.party:RefreshPartyFrameAnchor()
        APR.questOrderList:RefreshFrameAnchor()
        APR.heirloom:RefreshFrameAnchor()
        APR.RouteSelection:RefreshFrameAnchor()
        APR.Buff:RefreshFrameAnchor()
    end

    if (event == "PLAYER_CHOICE_UPDATE") then
        local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
        if (choiceInfo and step) then
            if (step.Brewery or step.SparringRing) then
                for i, option in ipairs(choiceInfo.options) do
                    if (step.Brewery == option.id or step.SparringRing == option.id) then
                        C_PlayerChoice.SendPlayerChoiceResponse(option.buttons[1].id)
                        APR:NextQuestStep()
                        break
                    end
                end
            end
        end
    end

    if (event == "PLAYER_TARGET_CHANGED") then
        APR:DoEmoteStep(step)
    end

    if (event == "QUEST_ACCEPTED") then
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
        if (APR.settings.profile.debug) then
            print(L["Q_ACCEPTED"] .. ": " .. questID)
        end
        C_Timer.After(0.2, function() APR:UpdateMapId() end)
    end

    if (event == "QUEST_ACCEPT_CONFIRM") then -- escort quest
        if IsModifierKeyDown() then return end
        if (autoAccept or autoAcceptRoute) then
            C_Timer.After(0.2, function() APR:AcceptQuest() end)
        end
    end

    if (event == "QUEST_AUTOCOMPLETE") then
        if IsModifierKeyDown() then return end
        if (APR.settings.profile.autoHandIn) then
            APR:PopupAutocompleteQuest()
        end
    end

    if (event == "QUEST_COMPLETE") then
        if IsModifierKeyDown() then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)

        local function getItemEquipLoc(itemEquipLoc)
            local weaponsAndShields = {
                "INVTYPE_WEAPONOFFHAND",
                "INVTYPE_WEAPONMAINHAND",
                "INVTYPE_WEAPON",
                "INVTYPE_SHIELD",
                "INVTYPE_2HWEAPON",
                "INVTYPE_HOLDABLE",
                "INVTYPE_RANGED",
                "INVTYPE_THROWN",
                "INVTYPE_RANGEDRIGHT",
                "INVTYPE_RELIC"
            }
            return APR:Contains(weaponsAndShields, itemEquipLoc) and "INVTYPE_WEAPON" or itemEquipLoc
        end

        local function getPlayerGearIlvlList()
            local gearIlvlList = {}
            for playerSlot = 0, 18 do
                local inventoryItemLink = GetInventoryItemLink("player", playerSlot)
                if inventoryItemLink then
                    local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(inventoryItemLink)
                    if itemQuality == 7 then --Heirloom
                        itemLevel = C_Item.GetDetailedItemLevelInfo(inventoryItemLink)
                    end
                    if itemEquipLoc and itemLevel then
                        itemEquipLoc = getItemEquipLoc(itemEquipLoc)
                        gearIlvlList[itemEquipLoc] = math.min(gearIlvlList[itemEquipLoc] or itemLevel, itemLevel)
                    end
                end
            end
            return gearIlvlList
        end

        local function getQuestRewardIlvlDifference(gearIlvlList)
            local gearIlvlListDiff = {}
            local isCosmetic = false
            for i = 1, GetNumQuestChoices() do
                local questItemLink = GetQuestItemLink("choice", i)
                if questItemLink then
                    local _, _, _, _, _, _, _, _, itemEquipLoc, _, _, classID, subclassID = C_Item.GetItemInfo(
                        questItemLink)

                    -- check if quest reward is classID 4 (armor) and subClassID 5 (cosmetic), then we dont want to pick anything
                    if classID == 4 and subclassID == 5 then
                        isCosmetic = true
                    end
                    local itemLevel = C_Item.GetDetailedItemLevelInfo(questItemLink)
                    itemEquipLoc = getItemEquipLoc(itemEquipLoc)
                    if gearIlvlList[itemEquipLoc] then
                        gearIlvlListDiff[i] = itemLevel - gearIlvlList[itemEquipLoc]
                    end
                end
            end
            return gearIlvlListDiff, isCosmetic
        end

        local function chooseQuestReward()
            local gearIlvlList = getPlayerGearIlvlList()
            local gearIlvlListDiff, isCosmetic = getQuestRewardIlvlDifference(gearIlvlList)

            local highestIlvlDiff = -99999
            local choiceIndex = 0
            for index, ilvlDiff in pairs(gearIlvlListDiff) do
                if ilvlDiff > highestIlvlDiff then
                    choiceIndex = index
                    highestIlvlDiff = ilvlDiff
                end
            end

            if choiceIndex > 0 and not isCosmetic then
                GetQuestReward(choiceIndex)
            end
        end

        if APR.settings.profile.autoHandIn then
            if GetNumQuestChoices() > 1 then
                if APR.settings.profile.autoHandInChoice then
                    chooseQuestReward()
                end
            else
                local npc_id = APR:GetTargetID()
                if not (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 45400) or (npc_id == 25809) or (npc_id == 87391))) then
                    GetQuestReward(1)
                end
            end
        end
    end

    if (event == "QUEST_DETAIL") then -- Fired when the player is given a more detailed view of his quest.
        if IsModifierKeyDown() or (not autoAcceptRoute and not autoAccept) then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)
        local hasNoRouteMap = not APR.RouteQuestStepList[APR.ActiveRoute]
        local function handleQuestDetail()
            local questID = GetQuestID()
            if questID then
                if QuestGetAutoAccept() then
                    C_Timer.After(0.2, function() APR:CloseQuest() end)
                elseif (autoAcceptRoute and APR:IsARouteQuest(questID)) or autoAccept then
                    C_Timer.After(0.2, function() APR:CloseQuest() end)
                elseif APR:IsPickupStep() then
                    C_Timer.After(0.2, function() APR:CloseQuest() end)
                    print("APR: " .. L["NOT_YET"])
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

    if (event == "QUEST_GREETING" or event == "GOSSIP_SHOW") then
        -- Exit function if you press Ctrl/shift/alt key before the
        if IsModifierKeyDown() then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)
        local npc_id = APR:GetTargetID()
        if (npc_id and (npc_id == 43733) and (npc_id == 45312)) then
            Dismount()
        end
        if (npc_id and ((npc_id == 141584) or (npc_id == 142063) or (npc_id == 25809) or (npc_id == 45400) or (npc_id == 87391))) then
            return
        end
        if step and APR.settings.profile.autoGossip then
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
                    APR.GossipCount = APR.GossipCount + 1
                    if (APR.GossipCount == 1) then
                        C_GossipInfo.SelectOptionByIndex(1)
                    elseif (APR.GossipCount == 2) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        end
                    elseif (APR.GossipCount == 3) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        end
                    elseif (APR.GossipCount == 4) then
                        if (APR.Race == "Gnome") then
                            C_GossipInfo.SelectOptionByIndex(4)
                        elseif (APR.Race == "Human" or APR.Race == "Dwarf") then
                            C_GossipInfo.SelectOptionByIndex(2)
                        elseif (APR.Race == "NightElf") then
                            C_GossipInfo.SelectOptionByIndex(1)
                        elseif (APR.Race == "Draenei" or APR.Race == "Worgen") then
                            C_GossipInfo.SelectOptionByIndex(3)
                        end
                    elseif (APR.GossipCount == 5) then
                        APR:UpdateNextStep()
                    end
                else
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
                        local target = APR:GetTargetID()
                        if (target == 167032) then
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
        --PICKUP / HANDIN
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        local activeQuests = C_GossipInfo.GetActiveQuests()
        -- Handin
        if (APR.settings.profile.autoHandIn) then
            if (event == "QUEST_GREETING") then
                for i = 1, GetNumActiveQuests() do
                    local title, isComplete = GetActiveTitle(i)
                    if title and isComplete then
                        return SelectActiveQuest(i)
                    end
                end
            elseif activeQuests then
                for titleIndex, questInfo in ipairs(activeQuests) do
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
            local hasNoRouteMap = not APR.RouteQuestStepList[APR.ActiveRoute]
            if (event == "QUEST_GREETING") then
                local numAvailableQuests = GetNumAvailableQuests()
                for i = 1, numAvailableQuests do
                    local _, _, _, _, questID = GetAvailableQuestInfo(i)
                    if (autoAcceptRoute and APR:IsARouteQuest(questID)) or autoAccept then
                        return SelectAvailableQuest(i)
                    elseif (i == numAvailableQuests and APR:IsPickupStep()) then
                        C_Timer.After(0.2, function() APR:CloseQuest() end)
                    end
                end
            elseif availableQuests then
                for titleIndex, questInfo in ipairs(availableQuests) do
                    if questInfo.questID then
                        if (autoAcceptRoute and APR:IsARouteQuest(questInfo.questID)) or autoAccept then
                            return C_GossipInfo.SelectAvailableQuest(questInfo.questID)
                        end
                    end
                end
            end
        end
    end

    if (event == "QUEST_LOG_UPDATE") then
        C_Timer.After(0.2, function() APR:UpdQuestThing() end)
    end

    if (event == "QUEST_PROGRESS") then
        if IsModifierKeyDown() then return end
        -- Deny NPC
        APR:CheckDenyNPC(step)
        if (APR.settings.profile.autoHandIn) then
            CompleteQuest()
        end
    end

    if (event == "QUEST_REMOVED") then
        if (APR.settings.profile.debug) then
            print(L["Q_REMOVED"])
        end
        local questID = ...;
        APR:RemoveQuest(questID)
        if (APR.ActiveRoute == questID) then
            APRData[APR.PlayerID][questID] = nil
            APR.map:RemoveMapLine()
            APR:UpdateMapId()
        end
        APRData[APR.PlayerID].QuestCounter2 = APRData[APR.PlayerID].QuestCounter2 + 1
    end

    if (event == "REQUEST_CEMETERY_LIST_RESPONSE") then
        APR.Arrow.currentStep = 0
        APR.Arrow:SetCoord()
        APR:UpdateMapId()
    end
    if event == "SCENARIO_COMPLETED" then
        local currentMapID = C_Map.GetBestMapForUnit('player')
        tinsert(APRScenarioMapIDCompleted[APR.PlayerID], currentMapID)
        if step and step.DoScenario then
            if step.DoScenario == currentMapID then
                APR:UpdateNextStep()
            end
        end
    end

    if event == "SCENARIO_CRITERIA_UPDATE" then
        local criteriaID = ...
        if step and step.Scenario then
            local isCompleted = false
            local scenario = step.Scenario
            local stepInfo = C_ScenarioInfo.GetScenarioStepInfo()
            if not stepInfo then return end
            for i = 1, stepInfo.numCriteria do
                local criteria = C_ScenarioInfo.GetCriteriaInfoByStep(stepInfo.stepID, i)
                if criteria.criteriaID == criteriaID then
                    if criteria.completed then
                        APRScenarioCompleted[APR.PlayerID][scenario.scenarioID] = APRScenarioCompleted[APR.PlayerID]
                            [scenario.scenarioID] or {}
                        if not APR:ContainsScenarioStepCriteria(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID], stepInfo.stepID, criteriaID, i) then
                            tinsert(APRScenarioCompleted[APR.PlayerID][scenario.scenarioID],
                                { stepID = stepInfo.stepID, criteriaID = criteriaID, criteriaIndex = i })
                            isCompleted = true
                        end
                    end
                end
            end
            if isCompleted then
                APR:UpdateStep()
            end
        end
    end

    if (event == "TAXIMAP_OPENED") then
        if IsModifierKeyDown() then return end
        if (step and step.GetFP) then
            APR:UpdateNextStep()
            CloseTaxiMap() -- auto Close the taxi map after getting the FP
        end
    end

    if (event == "UI_INFO_MESSAGE") then
        local errorType, msg = ...;
        if step and step.GetFP and (msg == _G.ERR_NEWTAXIPATH or msg == _G.ERR_TAXINOPATHS) then
            APR:UpdateNextStep()
        end
    end

    if (event == "UNIT_AURA") then
        if step and step.Button then
            APR.currentStep:UpdateStepButtonCooldowns()
        end
    end

    if (event == "UNIT_ENTERED_VEHICLE") then
        local unitTarget = ...;
        if (unitTarget == "player") then
            if (step and step.InVehicle) then
                APR:UpdateStep()
            end
        end
        if (step and step.MountVehicle) then
            APR:NextQuestStep()
        end
    end

    if (event == "UNIT_QUEST_LOG_CHANGED") then
        local unitTarget = ...;
        if (unitTarget == "player" and APR.Updateblock == 0) then
            APR.Updateblock = 1
            C_Timer.After(1, function() APR:UpdQuestThing() end)
        end
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...

        if (unitTarget == "player") and step then
            if (step.UseGarrisonHS and spellID == APR.garrisonHSSpellID) then
                APR:UpdateNextStep()
                return
            end
            if (step.UseDalaHS and spellID == APR.dalaHSSpellID) then
                APR:UpdateNextStep()
                return
            end
            if (APR:Contains(APR.hearthStoneSpellID, spellID) and step.UseHS) or (step.SpellTrigger and spellID == step.SpellTrigger) then
                APR:UpdateNextStep()
            end
        end
    end

    if (event == "UPDATE_MOUSEOVER_UNIT") then
        if (step and step.RaidIcon) then
            local targetGUID = UnitGUID("mouseover")
            if (targetGUID) then
                local targetID = select(6, strsplit("-", targetGUID))
                if (targetID and tonumber(step.RaidIcon) == tonumber(targetID)) then
                    if (not GetRaidTargetIndex("mouseover")) then
                        SetRaidTarget("mouseover", 8)
                    end
                end
            end
        elseif (step and step.DroppableQuest) then
            if (UnitGUID("mouseover") and UnitName("mouseover")) then
                local targetGUID, targetName = UnitGUID("mouseover"), UnitName("mouseover")
                local targetID = select(6, strsplit("-", targetGUID))
                if (targetID and step.DroppableQuest.MobId == tonumber(targetID)) then
                    APRData.NPCList[targetID] = targetName
                end
            end
        end

        APR:DoEmoteStep(step)
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        if step and step.LeaveScenario then
            local scenarioMapID = step.LeaveScenario
            local mapID = C_Map.GetBestMapForUnit('player')
            local isCompleted = tContains(APRScenarioMapIDCompleted[APR.PlayerID], scenarioMapID)
            if scenarioMapID ~= mapID and isCompleted then
                APR:UpdateNextStep()
            end
        end
    end
end)
