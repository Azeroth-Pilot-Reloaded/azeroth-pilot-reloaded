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
    adventureMapAccept = "ADVENTURE_MAP_OPEN",
    buffsAndCooldown = "UNIT_AURA",
    dead = { "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" },
    detail = "QUEST_DETAIL",
    done = { "QUEST_AUTOCOMPLETE", "QUEST_COMPLETE", "QUEST_PROGRESS" },
    dropQuest = "UPDATE_MOUSEOVER_UNIT",
    emote = { "CHAT_MSG_MONSTER_SAY", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT" },
    getFP = { "TAXIMAP_OPENED", "UI_INFO_MESSAGE" },
    gossip = { "GOSSIP_CLOSED", "GOSSIP_SHOW" },
    greeting = "QUEST_GREETING",
    group = { "GROUP_JOINED", "GROUP_LEFT" },
    learnProfession = "LEARNED_SPELL_IN_SKILL_LINE",
    lootItem = "ENCOUNTER_LOOT_RECEIVED",
    lvlUp = "PLAYER_LEVEL_UP",
    merchant = { "CHAT_MSG_LOOT", "MERCHANT_SHOW" },
    party = "CHAT_MSG_ADDON",
    petCombatUI = { "PET_BATTLE_OPENING_START", "PET_BATTLE_CLOSE" },
    playerChoice = "PLAYER_CHOICE_UPDATE",
    raidIcon = "UPDATE_MOUSEOVER_UNIT",
    remove = "QUEST_REMOVED",
    scenario = { "SCENARIO_COMPLETED", "SCENARIO_CRITERIA_UPDATE", "ZONE_CHANGED_NEW_AREA" },
    setHS = "HEARTHSTONE_BOUND",
    spell = "UNIT_SPELLCAST_SUCCEEDED",
    treasure = "CHAT_MSG_COMBAT_XP_GAIN",
    updateQuest = { "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED" },
    vehicle = "UNIT_ENTERED_VEHICLE",
}

---------------------------------------------------------------------------------------
-------------------------------------- DATA -------------------------------------------
---------------------------------------------------------------------------------------

local autoAccept, autoAcceptRoute, step = nil, nil, nil
local gossipCounter = 0
local pendingQuestUpdateTimer

---------------------------------------------------------------------------------------
---------------------------------- Events register ------------------------------------
---------------------------------------------------------------------------------------

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

function APR.event.functions.adventureMapAccept(event, followerTypeID)
    if IsModifierKeyDown() or (not autoAcceptRoute and not autoAccept) then return end
    if not APR:IsPickupStep() then
        C_AdventureMap.Close();
        APR:NotYet()
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

function APR.event.functions.buffsAndCooldown(event, unitTarget, updateInfo)
    if step and step.Buffs then
        if updateInfo.addedAuras then
            for _, aura in pairs(updateInfo.addedAuras) do
                APR.Buff:UpdateBuffIcon(aura)
            end
        end
        if updateInfo.updatedAuraInstanceIDs then
            for _, auraId in pairs(updateInfo.updatedAuraInstanceIDs) do
                local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, auraId)
                APR.Buff:UpdateBuffIcon(aura)
            end
        end
        if updateInfo.removedAuraInstanceIDs then
            for _, auraId in pairs(updateInfo.removedAuraInstanceIDs) do
                APR.Buff:DisableBuffIcon(auraId)
            end
        end
    end
    if step and step.Button then
        APR.currentStep:UpdateStepButtonCooldowns()
    end
end

function APR.event.functions.dead(event, ...)
    APR:UpdateStep()
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

function APR.event.functions.done(event, ...)
    if IsModifierKeyDown() then return end
    if APR.settings.profile.autoHandIn then
        if event == "QUEST_PROGRESS" then
            APR.event:TalkToDenyNpcLogic(step)
            CompleteQuest()
        elseif event == "QUEST_AUTOCOMPLETE" then
            APR:PopupAutocompleteQuest()
        end
    end

    if event == "QUEST_COMPLETE" then
        -- Deny NPC
        APR.event:TalkToDenyNpcLogic(step)

        local HEIRLOOM_QUALITY = Enum.ItemQuality.Heirloom
        local COSMETIC_CLASSID = 4
        local COSMETIC_SUBCLASSID = 5
        local WeaponInventoryTypes = {
            [Enum.InventoryType.IndexWeaponoffhandType] = true,
            [Enum.InventoryType.IndexWeaponmainhandType] = true,
            [Enum.InventoryType.IndexWeaponType] = true,
            [Enum.InventoryType.IndexShieldType] = true,
            [Enum.InventoryType.Index2HweaponType] = true,
            [Enum.InventoryType.IndexHoldableType] = true,
            [Enum.InventoryType.IndexRangedType] = true,
            [Enum.InventoryType.IndexThrownType] = true,
            [Enum.InventoryType.IndexRangedrightType] = true,
            [Enum.InventoryType.IndexRelicType] = true
        }


        local function normalizeEquipLoc(itemEquipLoc)
            if not itemEquipLoc then return nil end
            --  Regroup weapon types together for easier comparison
            if WeaponInventoryTypes[Enum.InventoryType[itemEquipLoc]] then
                return "WEAPON"
            end
            return itemEquipLoc
        end

        local function getPlayerGearIlvlList()
            local gearIlvlList = {}
            for playerSlot = 0, 18 do
                local itemLink = GetInventoryItemLink("player", playerSlot)
                if itemLink then
                    local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(itemLink)
                    if itemQuality == HEIRLOOM_QUALITY then
                        itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
                    end

                    itemEquipLoc = normalizeEquipLoc(itemEquipLoc)
                    if itemEquipLoc and itemLevel then
                        gearIlvlList[itemEquipLoc] = math.min(gearIlvlList[itemEquipLoc] or itemLevel, itemLevel)
                    end
                end
            end
            return gearIlvlList
        end


        local function isCosmeticKnown(itemLink)
            if not itemLink then return false end
            local itemID = C_Item.GetItemInfoInstant(itemLink)
            if itemID then
                -- Essaye la méthode WoW moderne
                local sources = C_TransmogCollection.GetItemInfo(itemID)
                if sources and sources.appearanceID then
                    local hasTransmog = C_TransmogCollection.PlayerHasTransmog(sources.appearanceID)
                    return hasTransmog
                end
                -- Méthode alternative (certaines builds)
                local sourceID = select(2, C_TransmogCollection.GetItemInfo(itemID))
                if sourceID then
                    return C_TransmogCollection.PlayerHasTransmog(sourceID)
                end
            end
            return false
        end


        local function getQuestRewardIlvlDifference(gearIlvlList)
            local rewardList = {}
            local unknownCosmeticIndex = nil
            local bestVendorValue, vendorIndex = 0, 1

            for i = 1, GetNumQuestChoices() do
                local itemLink = GetQuestItemLink("choice", i)
                if itemLink then
                    local _, _, _, _, _, _, _, _, equipLoc, _, vendorPrice, classID, subClassID = C_Item.GetItemInfo(
                        itemLink)
                    local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
                    equipLoc = normalizeEquipLoc(equipLoc)

                    -- check if quest reward is classID (armor) and subClassID (cosmetic)
                    if classID == COSMETIC_CLASSID and subClassID == COSMETIC_SUBCLASSID then
                        if not isCosmeticKnown(itemLink) and not unknownCosmeticIndex then
                            unknownCosmeticIndex = i
                        end
                    end

                    if gearIlvlList[equipLoc] and itemLevel then
                        rewardList[i] = itemLevel - gearIlvlList[equipLoc]
                    end

                    -- Track best vendor price (useful if everything is cosmetic or non-upgrade)
                    if vendorPrice and vendorPrice > bestVendorValue then
                        bestVendorValue = vendorPrice
                        vendorIndex = i
                    end
                end
            end
            return rewardList, unknownCosmeticIndex, vendorIndex
        end




        local function chooseQuestReward()
            local gearIlvlList = getPlayerGearIlvlList()
            local rewardDiff, unknownCosmeticIndex, vendorIndex = getQuestRewardIlvlDifference(gearIlvlList)

            -- Select the best upgrade
            local bestIndex, bestDiff = nil, -9999
            for index, diff in pairs(rewardDiff) do
                if diff > bestDiff then
                    bestIndex = index
                    bestDiff = diff
                end
            end

            -- take the best upgrade if it exists and is not cosmetic
            -- otherwise, the most valuable vendor item
            if bestIndex and not unknownCosmeticIndex and bestDiff > 0 then
                GetQuestReward(bestIndex)
            elseif unknownCosmeticIndex then
                GetQuestReward(unknownCosmeticIndex)
            else
                GetQuestReward(vendorIndex)
            end
        end

        if APR.settings.profile.autoHandIn then
            if GetNumQuestChoices() > 1 then
                if APR.settings.profile.autoHandInChoice then
                    chooseQuestReward()
                end
            else
                -- if there is only one choice, we can just get the reward
                GetQuestReward(1)
            end
        end
    end
end

function APR.event.functions.dropQuest(event, ...)
    if step and step.DroppableQuest then
        if UnitGUID("mouseover") and UnitName("mouseover") then
            local targetGUID, targetName = UnitGUID("mouseover"), UnitName("mouseover")
            local targetID = select(6, strsplit("-", targetGUID))
            if targetID and step.DroppableQuest.MobId == tonumber(targetID) then
                APRData.NPCList[targetID] = targetName
            end
        end
    end
end

function APR.event.functions.emote(event, ...)
    if event == "CHAT_MSG_MONSTER_SAY" then
        local text = ...;
        local npc_id, name = APR:GetTargetID(), UnitName("target")
        if npc_id and name then
            if npc_id == 159477 then -- quest 57870 -- Giggling Basket
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
                        APR:Debug("APR: " .. L["DOING_EMOTE"] .. ": ", emote)

                        DoEmote(emote)
                        break
                    end
                end
            end
        end
    else
        APR:DoEmote(step)
    end
end

function APR.event.functions.getFP(event, ...)
    if event == "TAXIMAP_OPENED" then
        if IsModifierKeyDown() then return end
        if step and step.GetFP then
            APR:UpdateNextStep()
            CloseTaxiMap() -- auto Close the taxi map after getting the FP
        end
    end
    if event == "UI_INFO_MESSAGE" then
        local errorType, msg = ...;
        if step and step.GetFP and (msg == _G.ERR_NEWTAXIPATH or msg == _G.ERR_TAXINOPATHS) then
            APR:UpdateNextStep()
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

function APR.event.functions.learnProfession(event, spellID, skillLineIndex, isGuildPerkSpell)
    if step and step.LearnProfession then
        if spellID == step.LearnProfession then
            APR:UpdateNextStep()
        end
    end
end

function APR.event.functions.lootItem(event, encounterID, itemID, itemLink, quantity, playerName, classFileName)
    if step and step.LootItem then
        local stepItemID = step.LootItem
        if stepItemID == itemID then
            tinsert(APRItemLooted[APR.PlayerID], itemID)
            APR:UpdateNextStep()
        end
    end
end

function APR.event.functions.lvlUp(event, level, healthDelta, powerDelta, numNewTalents, numNewPvpTalentSlots,
                                   strengthDelta, agilityDelta, staminaDelta, intellectDelta)
    APR.Level = level
    APR.routeconfig:CheckRouteResetOnLvlUp()
end

function APR.event.functions.merchant(event, ...)
    if event == "CHAT_MSG_LOOT" then
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

    if event == "MERCHANT_SHOW" then
        if IsModifierKeyDown() then return end
        if step and step.BuyMerchant then
            APR:StartPurchaseTracking(step.BuyMerchant)
            APR:BuyItemFromMerchant(step.BuyMerchant)
        end
        if APR.settings.profile.autoRepair then
            if CanMerchantRepair() then
                local repairAllCost, canRepair = GetRepairAllCost();
                if canRepair and repairAllCost > 0 then
                    local repaired = false
                    if IsInGuild() and CanGuildBankRepair() then
                        local guildWithdrawLimit = GetGuildBankWithdrawMoney()
                        local guildMoney = GetGuildBankMoney()
                        local available = guildWithdrawLimit == -1 and guildMoney or
                            math.min(guildWithdrawLimit, guildMoney)

                        if available >= repairAllCost then
                            RepairAllItems(true);
                            repaired = true
                            APR:PrintInfo("Equipment has been repaired by your Guild")
                        end
                    end
                    if not repaired and repairAllCost <= GetMoney() then
                        RepairAllItems(false);
                        APR:PrintInfo(L["REPAIR_EQUIPEMENT"] .. " " .. C_CurrencyInfo.GetCoinTextureString(repairAllCost))
                    end
                end
            end
        end
        if APR.settings.profile.autoVendor then
            local totalPrices = 0

            for myBags = Enum.BagIndex.Backpack, NUM_TOTAL_BAG do
                for bagSlots = 1, C_Container.GetContainerNumSlots(myBags) do
                    local CurrentItemId = C_Container.GetContainerItemID(myBags, bagSlots)
                    if CurrentItemId then
                        local _, _, itemQuality, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(CurrentItemId)
                        local itemInfo = C_Container.GetContainerItemInfo(myBags, bagSlots)
                        if itemQuality == 0 and sellPrice > 0 and itemInfo.stackCount > 0 then
                            totalPrices = totalPrices + (sellPrice * itemInfo.stackCount)
                            C_Container.UseContainerItem(myBags, bagSlots)
                        end
                    end
                end
            end
            if totalPrices ~= 0 then
                APR:PrintInfo(L["ITEM_SOLD"] .. " " .. C_CurrencyInfo.GetCoinTextureString(totalPrices))
            end
        end
    end
end

function APR.event.functions.party(event, ...)
    local prefix, message, channel = ...;
    APR.party:GroupUpdateHandler(prefix, message, channel)
end

function APR.event.functions.petCombatUI(event, ...)
    APR.currentStep:RefreshCurrentStepFrameAnchor()
    APR.party:RefreshPartyFrameAnchor()
    APR.questOrderList:RefreshFrameAnchor()
    APR.heirloom:RefreshFrameAnchor()
    APR.RouteSelection:RefreshFrameAnchor()
    APR.Buff:RefreshFrameAnchor()
end

function APR.event.functions.playerChoice(event, ...)
    local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
    if choiceInfo and step then
        if step.Brewery or step.SparringRing then
            for i, option in ipairs(choiceInfo.options) do
                if step.Brewery == option.id or step.SparringRing == option.id then
                    C_PlayerChoice.SendPlayerChoiceResponse(option.buttons[1].id)
                    APR:NextQuestStep()
                    break
                end
            end
        end
    end
end

function APR.event.functions.raidIcon(event, ...)
    if step and step.RaidIcon then
        local targetGUID = UnitGUID("mouseover")
        if targetGUID then
            local targetID = select(6, strsplit("-", targetGUID))
            if targetID and tonumber(step.RaidIcon) == tonumber(targetID) then
                if (not GetRaidTargetIndex("mouseover")) then
                    SetRaidTarget("mouseover", 8)
                end
            end
        end
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

function APR.event.functions.scenario(event, ...)
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
end

function APR.event.functions.setHS(event, ...)
    if step and step.SetHS then
        APR:UpdateNextStep()
    end
end

function APR.event.functions.spell(event, unitTarget, castGUID, spellID)
    if unitTarget == "player" and step then
        if step.UseGarrisonHS and spellID == APR.garrisonHSSpellID then
            APR:UpdateNextStep()
            return
        end
        if step.UseDalaHS and spellID == APR.dalaHSSpellID then
            APR:UpdateNextStep()
            return
        end
        if (APR:Contains(APR.hearthStoneSpellID, spellID) and step.UseHS) or (step.SpellTrigger and spellID == step.SpellTrigger) then
            APR:UpdateNextStep()
        end
    end
end

function APR.event.functions.treasure(event, ...)
    if step and step.Treasure then
        C_Timer.After(0.2, function() APR:UpdateQuestAndStep() end)
    end
end

function APR.event.functions.updateQuest(event, ...)
    if event == "QUEST_LOG_UPDATE" then
        APR.event:DebouncedUpdateQuest(0.2)
    elseif event == "UNIT_QUEST_LOG_CHANGED" then
        local unitTarget = ...
        if unitTarget == "player" then
            APR.event:DebouncedUpdateQuest(1)
        end
    end
end

function APR.event.functions.vehicle(event, unitTarget, showVehicleFrame, isControlSeat, vehicleUIIndicatorID,
                                     vehicleGUID, mayChooseExit, hasPitch)
    if unitTarget == "player" then
        if step and step.InVehicle then
            APR:UpdateStep()
        end
    end
    if step and step.MountVehicle then
        APR:NextQuestStep()
    end
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

function APR.event:DebouncedUpdateQuest(delay)
    if pendingQuestUpdateTimer then
        pendingQuestUpdateTimer:Cancel()
    end
    pendingQuestUpdateTimer = C_Timer.NewTimer(delay, function()
        APR:UpdateQuest()
        APR:Debug("Extra UpdQuestThing (debounced)")
        pendingQuestUpdateTimer = nil
    end)
end
