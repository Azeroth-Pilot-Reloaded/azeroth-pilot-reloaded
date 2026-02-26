local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.event = APR:NewModule("Event")

-- Called when addon is disabled - cleanup all event handlers
function APR.event:OnDisable()
    self:CleanupEvents()
end

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
    adventureMapClose = "ADVENTURE_MAP_CLOSE",
    buffsAndCooldown = "UNIT_AURA",
    dead = { "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" },
    detail = "QUEST_DETAIL",
    done = { "QUEST_AUTOCOMPLETE", "QUEST_COMPLETE", "QUEST_PROGRESS" },
    criteria = { "CRITERIA_UPDATE", "CRITERIA_EARNED" },
    emote = { "CHAT_MSG_MONSTER_SAY", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT" },
    getFP = { "TAXIMAP_OPENED", "UI_INFO_MESSAGE" },
    gossip = { "GOSSIP_CLOSED", "GOSSIP_SHOW" },
    greeting = "QUEST_GREETING",
    group = { "GROUP_JOINED", "GROUP_LEFT" },
    learnProfession = "LEARNED_SPELL_IN_SKILL_LINE",
    leaveCombat = "PLAYER_REGEN_ENABLED",
    lootItems = { "CHAT_MSG_LOOT", "CURRENCY_DISPLAY_UPDATE" }, -- item , quest Item, currenies( honor, ressources, ...)
    lvlUp = "PLAYER_LEVEL_UP",
    merchant = { "CHAT_MSG_LOOT", "MERCHANT_SHOW" },
    party = "CHAT_MSG_ADDON",
    partyData = "PLAYER_ENTERING_WORLD",
    petCombatUI = { "PET_BATTLE_OPENING_START", "PET_BATTLE_CLOSE" },
    playerChoice = "PLAYER_CHOICE_UPDATE",
    targetChanged = "PLAYER_TARGET_CHANGED",
    nameplate = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" },
    remove = "QUEST_REMOVED",
    scenario = { "SCENARIO_COMPLETED", "SCENARIO_CRITERIA_UPDATE", "ZONE_CHANGED_NEW_AREA" },
    setHS = "HEARTHSTONE_BOUND",
    spell = "UNIT_SPELLCAST_SUCCEEDED",
    spec = "PLAYER_SPECIALIZATION_CHANGED",
    treasure = "CHAT_MSG_COMBAT_XP_GAIN",
    updateQuest = { "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED" },
    vehicle = "UNIT_ENTERED_VEHICLE",
    zone = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "WAYPOINT_UPDATE" },
}

---------------------------------------------------------------------------------------
-------------------------------------- DATA -------------------------------------------
---------------------------------------------------------------------------------------

local autoAccept, autoAcceptRoute, step = nil, nil, nil

local pendingQuestUpdateTimer
local questShareQueue = {}
local adventureMapRetryToken = 0

local function CancelAdventureMapRetries()
    adventureMapRetryToken = adventureMapRetryToken + 1
end

-- track instance status to avoid repeatedly toggling the addon
local lastIsInstanceWithUI = nil

---------------------------------------------------------------------------------------
---------------------------------- Events register ------------------------------------
---------------------------------------------------------------------------------------

function APR.event:MyRegisterEvent()
    for tag, event in pairs(events) do
        local container = self.framePool[tag] or CreateFrame("Frame")
        container.tag = tag
        container.callback = self.functions[tag]

        -- Save container to framePool for later cleanup
        self.framePool[tag] = container

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
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.enableAddon then
        return
    end


    local isInstanceWithUI = APR:IsInstanceWithUI()
    if isInstanceWithUI ~= lastIsInstanceWithUI then
        APR:Debug("APR: Event - IsInstanceWithUI : ", isInstanceWithUI)
        APR.settings:ToggleAddon()
        lastIsInstanceWithUI = isInstanceWithUI
    end

    if not isInstanceWithUI then
        return
    end

    if self.callback and self.tag then
        APR:DebugEvent("Callback Event", event)
        -- update Local variables before calling the callback
        autoAccept = profile.autoAccept
        autoAcceptRoute = profile.autoAcceptQuestRoute
        step = APR:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)

        pcall(self.callback, event, ...)
    else
        APR:DebugEvent("Unregister Event", event)
        self.callback = nil
        self:UnregisterEvent(event)
    end
end

-- Cleanup function to properly unregister events and clear handlers
function APR.event:CleanupEvents()
    for tag, container in pairs(self.framePool) do
        if container then
            -- Unregister all events for this container
            container:UnregisterAllEvents()
            -- Clear script handlers
            container:SetScript("OnEvent", nil)
            -- Clear references
            container.tag = nil
            container.callback = nil
        end
    end
    -- Clear the event timer if running
    if pendingQuestUpdateTimer then
        C_Timer.Cancel(pendingQuestUpdateTimer)
        pendingQuestUpdateTimer = nil
    end

    CancelAdventureMapRetries()
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
                APR.coordinate:RefreshFrameAnchor()
                APR:UpdateStep()

                APR:Debug("Caller: Event.lua load handler -> GetCurrentRouteMapIDsAndName")
                local routeZoneMapIDs, mapID, routeFileName, expansion = APR:GetCurrentRouteMapIDsAndName()
                APR:CheckCurrentRouteUpToDate(routeFileName)
                -- Ensure the active route is set on load so the current step frame can populate without waiting
                if routeFileName and routeFileName ~= "" then
                    APR.ActiveRoute = routeFileName

                    -- Trigger zone detection after reload - use longer delay to ensure quest log is fully synced
                    -- This prevents false "wrong zone" message that appears before quests are loaded
                    C_Timer.After(0.5, function()
                        APR:InvalidatePlayerZoneCache()
                        local profile = APR:GetSettingsProfile()
                        if profile and profile.enableAddon then
                            APR:UpdateMapId()
                            APR:UpdateStep()
                        end
                    end)
                end

                local versionText = APR:WrapTextInColorCode(APR.version, "00ff00")
                local interfaceText = APR:WrapTextInColorCode(APR.interfaceVersion, "00ff00")
                APR:PrintInfo("APR " .. L["LOADED"] .. " - Version: " .. versionText .. " | Interface: " ..
                    interfaceText)
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
        local profile = APR:GetSettingsProfile()

        local function queueQuestShare()
            if not profile or not profile.autoShareQuestWithFriend or not IsInGroup() then
                return
            end
            if not (C_QuestLog.IsPushableQuest and C_QuestLog.IsPushableQuest(questID)) then
                return
            end
            if not APR.party:CheckIfPartyMemberIsFriend() then
                return
            end

            for i = 1, #questShareQueue do
                if questShareQueue[i] == questID then
                    return
                end
            end

            table.insert(questShareQueue, questID)
        end

        if profile and profile.firstAutoShareQuestWithFriend and IsInGroup() then
            APR.questionDialog:CreateQuestionPopup("SHOW_GROUP_SHAREWITHFRIEND_FIRSTTIME",
                L["SHOW_GROUP_SHAREWITHFRIEND_FIRSTTIME"], function()
                    profile.autoShareQuestWithFriend = true
                    queueQuestShare()
                end)
            profile.firstAutoShareQuestWithFriend = false
        end
        queueQuestShare()

        APR:HandleTemporaryRouteTriggerQuestAccepted(questID)

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
    if not APR:IsPickupStep() and (step and not step.IsAdventureMap) then
        C_AdventureMap.Close();
        CancelAdventureMapRetries()
        APR:NotYet()
        return
    end

    -- Ensure the quest pool is built before checking adventure map quests
    APR:EnsureQuestPool()

    local MAX_RETRIES = 10
    local RETRY_DELAY = 0.3
    local attempt = 0

    local function IsAdventureMapOpen()
        local adventureMapFrame = rawget(_G, "AdventureMapFrame")
        return adventureMapFrame and adventureMapFrame:IsShown() or false
    end

    CancelAdventureMapRetries()
    local retryToken = adventureMapRetryToken

    local function tryAcceptAdventureMapQuests()
        if retryToken ~= adventureMapRetryToken or not IsAdventureMapOpen() then
            return
        end

        attempt = attempt + 1
        local numChoices = C_AdventureMap.GetNumZoneChoices()
        APR:Debug("AdventureMap attempt " .. attempt .. "/" .. MAX_RETRIES .. " - choices: " .. numChoices)

        local questStarted = false
        for choiceIndex = 1, numChoices do
            local questID, textureKit, name, zoneDescription, normalizedX, normalizedY = C_AdventureMap
                .GetZoneChoiceInfo(choiceIndex);
            if AdventureMap_IsQuestValid(questID, normalizedX, normalizedY) then
                if APR:IsQuestInPool(tonumber(questID)) then
                    C_AdventureMap.StartQuest(questID)
                    questStarted = true
                end
            end
        end

        -- Retry if no choices were available or no quest was started
        if not questStarted and attempt < MAX_RETRIES and IsAdventureMapOpen() and retryToken == adventureMapRetryToken then
            C_Timer.After(RETRY_DELAY, tryAcceptAdventureMapQuests)
        end
    end

    if IsAdventureMapOpen() and retryToken == adventureMapRetryToken then
        C_Timer.After(RETRY_DELAY, tryAcceptAdventureMapQuests)
    end
end

function APR.event.functions.adventureMapClose(event, ...)
    CancelAdventureMapRetries()
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
    local profile = APR:GetSettingsProfile()
    if IsModifierKeyDown() then return end
    if profile and profile.autoHandIn then
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
            -- Normalize weapon types to "WEAPON" for easier comparison
            if not itemEquipLoc then return nil end
            if WeaponInventoryTypes[Enum.InventoryType[itemEquipLoc]] then
                return "WEAPON"
            end
            return itemEquipLoc
        end

        local function getPlayerGearIlvlList()
            -- Build a table of the player's current ilvl per equip slot
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
                        -- Store the lowest ilvl found for each slot
                        gearIlvlList[itemEquipLoc] = math.min(gearIlvlList[itemEquipLoc] or itemLevel, itemLevel)
                    end
                end
            end
            return gearIlvlList
        end

        local function isCosmeticKnown(itemLink)
            -- Check if the cosmetic appearance is already collected by the player
            if not itemLink then return false end
            local itemID = C_Item.GetItemInfoInstant(itemLink)
            if itemID then
                -- Modern method
                local itemAppearanceID = C_TransmogCollection.GetItemInfo(itemID)
                if itemAppearanceID then
                    return C_TransmogCollection.PlayerHasTransmog(itemAppearanceID)
                end
                -- Alternate method (for some builds)
                local itemModifiedAppearanceID = select(2, C_TransmogCollection.GetItemInfo(itemID))
                if itemModifiedAppearanceID then
                    return C_TransmogCollection.PlayerHasTransmog(itemModifiedAppearanceID)
                end
            end
            return false
        end

        local function buildQuestRewardData(gearIlvlList)
            -- Gather all relevant information for each quest reward choice
            local data = {}
            for i = 1, GetNumQuestChoices() do
                local itemLink = GetQuestItemLink("choice", i)
                if itemLink then
                    local _, _, _, _, _, _, _, _, equipLoc, _, vendorPrice, classID, subClassID = C_Item.GetItemInfo(
                        itemLink)
                    local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
                    equipLoc = normalizeEquipLoc(equipLoc)
                    vendorPrice = vendorPrice or 0

                    local isCosmetic = (classID == COSMETIC_CLASSID and subClassID == COSMETIC_SUBCLASSID)
                    local isKnownCosmetic = isCosmeticKnown(itemLink)
                    local isTransmog = not isCosmetic and not isKnownCosmetic
                    local isUpgrade = false
                    local ilvlDiff = nil

                    if gearIlvlList[equipLoc] and itemLevel then
                        ilvlDiff = itemLevel - gearIlvlList[equipLoc]
                        if ilvlDiff > 0 then isUpgrade = true end
                    end

                    data[i] = {
                        index = i,
                        link = itemLink,
                        isCosmetic = isCosmetic,
                        isUnknownCosmetic = isCosmetic and not isKnownCosmetic,
                        isUnknownTransmog = isTransmog and not isKnownCosmetic,
                        vendorPrice = vendorPrice,
                        ilvlDiff = ilvlDiff or -999,
                        isUpgrade = isUpgrade,
                    }
                end
            end
            return data
        end

        local function chooseQuestRewardByPriority()
            -- Select the quest reward based on user-defined priority order
            local gearIlvlList = getPlayerGearIlvlList()
            local rewards = buildQuestRewardData(gearIlvlList)

            if not profile then
                return
            end

            local prioList = {
                profile.rewardPriority1,
                profile.rewardPriority2,
                profile.rewardPriority3,
                profile.rewardPriority4,
            }

            -- Define the logic for each priority type
            local priorityFuncs = {
                ilvl = function()
                    -- Find the best ilvl upgrade
                    local best, bestDiff = nil, -9999
                    for _, data in pairs(rewards) do
                        if data.isUpgrade and (not best or data.ilvlDiff > bestDiff) then
                            best = data.index
                            bestDiff = data.ilvlDiff
                        end
                    end
                    return best
                end,
                cosmetic = function()
                    -- Pick any unknown cosmetic
                    local list = {}
                    for _, data in pairs(rewards) do
                        if data.isUnknownCosmetic then
                            table.insert(list, data.index)
                        end
                    end
                    if profile.autoCosmeticMulti then
                        return list[1]
                    end
                    return -1
                end,
                transmog = function()
                    -- Pick any unknown transmog
                    local list = {}
                    for _, data in pairs(rewards) do
                        if data.isUnknownTransmog then
                            table.insert(list, data.index)
                        end
                    end
                    if profile.autoTransmogMulti then
                        return list[1]
                    end
                    return -1
                end,
                price = function()
                    -- Pick the highest vendor price item
                    local best, bestPrice = nil, 0
                    for _, data in pairs(rewards) do
                        if (not best) or data.vendorPrice > bestPrice then
                            best = data.index
                            bestPrice = data.vendorPrice
                        end
                    end
                    return best
                end
            }

            -- Try each priority in order until a reward is found
            for _, prio in ipairs(prioList) do
                if prio and priorityFuncs[prio] then
                    local index = priorityFuncs[prio]()
                    if index and index == -1 then -- -1 means to skip reward
                        return
                    elseif index then
                        GetQuestReward(index)
                        return
                    end
                    -- continue to next priority if no valid/skippable reward found
                end
            end

            -- Fallback: always pick the first reward if nothing matched
            GetQuestReward(1)
        end

        -- Main auto reward selection logic (use where appropriate)
        if profile and profile.autoHandIn then
            if GetNumQuestChoices() > 1 then
                if profile.autoHandInChoice then
                    chooseQuestRewardByPriority()
                end
            else
                -- Only one choice available, just select it
                GetQuestReward(1)
            end
        end
    end
end

function APR.event.functions.criteria(event, ...)
    if not step or not step.Glyph then
        return
    end

    local glyphData = APR:GetGlyphStepData(step)
    if not glyphData then
        return
    end

    if event == "CRITERIA_EARNED" then
        local achievementID = tonumber((...))
        if not achievementID then
            return
        end

        if achievementID ~= glyphData.achievementID then
            return
        end
    elseif event == "CRITERIA_UPDATE" then
        -- Event has no stable payload in modern API docs; re-evaluate the active glyph step.
    else
        return
    end

    APR:UpdateStep()
end

function APR.event.functions.emote(event, ...)
    if event == "CHAT_MSG_MONSTER_SAY" then
        local text = ...;
        local npc_id, name = APR:GetTargetID(), APR:SafeUnitName("target")
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
                    if APR:ContainsText(text, message) then
                        APR:Debug("APR: " .. L["DOING_EMOTE"] .. ": ", emote)

                        APR:PerformEmote(emote)
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
        APR.gossip.counter = 0
    end

    if event == "GOSSIP_SHOW" then
        -- Exit function if you press Ctrl/shift/alt key before the
        if IsModifierKeyDown() then
            return
        end

        -- Deny NPC
        APR.event:TalkToDenyNpcLogic(step)

        APR.gossip:HandleGossip(step)

        --PICKUP / HANDIN
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        local activeQuests = C_GossipInfo.GetActiveQuests()
        -- Handin
        local profile = APR:GetSettingsProfile()
        if profile and profile.autoHandIn then
            if activeQuests then
                for _, questInfo in ipairs(activeQuests) do
                    if questInfo.title and questInfo.isComplete then
                        if questInfo.questID then
                            APR:Debug("Selecting active quest for handin: ", tostring(questInfo.questID))
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
                    APR:Debug("AvailableQuest: ", tostring(questInfo.questID))
                    if questInfo.questID then
                        local isARouteQuest = APR:IsARouteQuest(questInfo.questID)
                        if (autoAcceptRoute and isARouteQuest) or autoAccept then
                            APR:Debug("Selecting available quest for pickup: ", tostring(questInfo.questID))
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
        APR.gossip:HandleGossip(step)
    end

    -- Done (Handin)
    local profile = APR:GetSettingsProfile()
    if profile and profile.autoHandIn then
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
        APR.party:Delete()
    end
end

function APR.event.functions.learnProfession(event, spellID, skillLineIndex, isGuildPerkSpell)
    if step and step.LearnProfession then
        if spellID == step.LearnProfession then
            APR:UpdateNextStep()
        end
    end
end

function APR.event.functions.leaveCombat(event, ...)
    APR.currentStep:FlushPendingContainers()
    APR.currentStep:ProcessPendingStepButtons()

    -- If a full Reset was deferred during combat, run it now
    if APR.currentStep._pendingFullReset then
        APR.currentStep._pendingFullReset = false
        APR.currentStep:Reset()
        APR:UpdateStep()
    end

    APR:UpdateQuest()
end

function APR.event.functions.lootItems(event, ...)
    -- ITEM LOOT (quest items + normal items)
    if event == "CHAT_MSG_LOOT" then
        local message = ...
        local itemLink = message and message:match("|Hitem:.-|h.-|h")
        if not itemLink then return end

        local itemID = select(1, C_Item.GetItemInfoInstant(itemLink))
        if not itemID then return end
        local quantity = APR:GetQuantityfromLootMessage(message) or 1

        C_Timer.After(1, function()
            APR.lootUtils:OnItemLooted(itemID, quantity)
            APR:RefreshLootStepDisplay(step)
        end)
        return
    end

    -- -- MONEY (gold/silver/copper)
    -- if event == "PLAYER_MONEY" then
    --     local currentMoney = GetMoney()
    --     local delta = currentMoney - (APR._lastMoney or currentMoney)
    --     APR._lastMoney = currentMoney

    --     if delta > 0 then
    --         APR.lootUtils:OnMoneyLooted(delta)
    --     end
    --     return
    -- end

    -- CURRENCIES (Honor, Resources, etc.)
    if event == "CURRENCY_DISPLAY_UPDATE" then
        local currencyID, quantityChange = ...
        if currencyID and quantityChange and quantityChange > 0 then
            C_Timer.After(1, function()
                APR.lootUtils:OnCurrencyGained(currencyID, quantityChange)
                -- TODO add RefreshLootCurrenciesStepDisplay
            end)
        end
        return
    end
end

function APR.event.functions.lvlUp(event, level, healthDelta, powerDelta, numNewTalents, numNewPvpTalentSlots,
                                   strengthDelta, agilityDelta, staminaDelta, intellectDelta)
    APR.Level = level
    APR.routeconfig:CheckRouteResetOnLvlUp()
    APR:UpdateStep()
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
        local profile = APR:GetSettingsProfile()
        if profile and profile.autoRepair then
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
        if profile and profile.autoVendor then
            local totalPrices = 0

            for myBags = Enum.BagIndex.Backpack, APR.MaxBagSlots do
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
    local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...;
    APR.party:GroupUpdateHandler(prefix, text, channel, sender)
end

function APR.event.functions.partyData(event, ...)
    -- To request the group data from the party members
    APR.party:RequestData()
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

function APR.event.functions.nameplate(event, unitToken)
    if unitToken then
        APR:ScanUnitForNPC(unitToken, "NAMEPLATE")
    end
    if APR.currentStep and APR.currentStep.UpdateRaidIconButtonMacro then
        APR.currentStep:UpdateRaidIconButtonMacro()
    end
end

function APR.event.functions.targetChanged()
    if APR.currentStep then
        APR.currentStep:UpdateRaidIconButtonMacro()
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
            tinsert(APRScenarioMapIDCompleted[APR.PlayerID], step.DoScenario)
            APR:UpdateNextStep()
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
        if step and (step.LeaveScenario or step.LeaveInstance) then
            local mapID = C_Map.GetBestMapForUnit('player')
            if step.LeaveScenario then
                local scenarioMapID = step.LeaveScenario
                local IsScenarioInstance = APR:IsScenarioInstance()
                if scenarioMapID ~= mapID and not IsScenarioInstance then
                    APR:UpdateNextStep()
                end
            end
            if step.LeaveInstance then
                local instanceMapID = step.LeaveInstance
                local isInstance, instanceType = IsInInstance()
                if instanceMapID ~= mapID and not isInstance then
                    APR:UpdateNextStep()
                end
            end
        end
    end
end

function APR.event.functions.setHS(event, ...)
    if step and step.SetHS then
        APR:UpdateNextStep()
    end
end

function APR.event.functions.spec(event, unit)
    if unit ~= "player" then return end

    local currentSpec = APR:GetClassSpecName()
    if not currentSpec then return end

    local foundRoutes = APR:FindAllSpecRoutesInCustomPath()
    if #foundRoutes == 0 then return end

    local replacements = APR:ResolveSpecRouteReplacements(currentSpec, foundRoutes)
    if #replacements == 0 then return end

    local i = 1
    local function ShowNextPopup()
        local data = replacements[i]
        if not data then
            if APR.routeconfig then
                APR.routeconfig:SendMessage("APR_Custom_Path_Update")
            end
            return
        end


        APR.questionDialog:CreateQuestionPopup("SPEC_ROUTE_CHANGE_PROMPT" .. i,
            string.format(
                L["SPEC_ROUTE_CHANGE_PROMPT"],
                data.oldDisplay,
                data.newDisplay
            ),
            function()
                -- accept
                APRCustomPath[APR.PlayerID][data.index] = data.newDisplay

                -- Reset route if is you active route
                if data.index == 1 then
                    local newRouteKey = data.newRouteKey
                    if newRouteKey then
                        APR.ActiveRoute = newRouteKey
                        APR:ResetRoute(APR.ActiveRoute)
                    end
                end
                i = i + 1
                ShowNextPopup()
            end,
            function()
                -- cancel
                i = i + 1
                ShowNextPopup()
            end
        )
    end

    ShowNextPopup()
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
        if (APR:Contains(APR.hearthStoneSpellID, spellID) and step.UseHS) or
            (step.SpellTrigger and spellID == step.SpellTrigger) or
            (step.UseSpell.spellID and spellID == step.UseSpell.spellID) or
            (step.UseItem.itemSpellID and spellID == step.UseSpell.itemSpellID)
        then
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
        if not InCombatLockdown() then
            for index = #questShareQueue, 1, -1 do
                local questID = questShareQueue[index]
                local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
                if questLogIndex then
                    -- Ensure the correct quest is selected before pushing
                    C_QuestLog.SetSelectedQuest(questID)

                    -- QuestLogPushQuest works on the currently selected quest; do not pass an index
                    local ok, pushed = pcall(QuestLogPushQuest)
                    if ok and pushed then
                        table.remove(questShareQueue, index)
                    end
                else
                    -- Quest no longer in log; remove from queue to avoid infinite retries
                    table.remove(questShareQueue, index)
                end
            end
        end
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

function APR.event.functions.zone(event, ...)
    if step and step.TakePortal then
        local portalData = step.TakePortal
        local zoneId = portalData.ZoneId
        local currentMapID = C_Map.GetBestMapForUnit("player")
        local parentMapID = APR:GetPlayerParentMapID()
        if currentMapID == zoneId or parentMapID == zoneId then
            APR:UpdateNextStep()
        end
    end

    -- Transport logic
    if event == "PLAYER_ENTERING_WORLD" then
        -- Invalidate cache after teleportation to ensure fresh zone detection
        APR:InvalidatePlayerZoneCache()
        -- Reset routing throttle after teleport/loading
        if APR.transport._routingThrottle then
            APR.transport._routingThrottle.count = 0
            APR.transport._routingThrottle.firstCall = GetTime()
        end
        APR.transport._routingForceRefresh = true
        -- Flag that we are transitioning (loading screen / instance exit / teleport).
        -- Zone change events that fire during this window should NOT call GetMeToRightZone
        -- immediately because the map API is not yet reliable.
        APR.transport._worldTransitionTime = GetTime()
        C_Timer.After(0.5, function()
            APR.transport._worldTransitionTime = nil
            local profile = APR:GetSettingsProfile()
            if APR.ActiveRoute and profile and profile.enableAddon then
                -- Invalidate caches one more time now that the map API should be stable
                APR:InvalidatePlayerZoneCache()
                APR._lastRouteZoneCheck = nil
                APR._lastRouteZoneResult = nil
                APR.transport:GetMeToRightZone()
            end
        end)
    end
    if event == "ZONE_CHANGED" or
        event == "ZONE_CHANGED_INDOORS" or
        event == "ZONE_CHANGED_NEW_AREA" or
        event == "WAYPOINT_UPDATE"
    then
        -- Invalidate cache when zone changes
        APR:InvalidatePlayerZoneCache()
        -- Also invalidate the CheckIsInRouteZone throttle cache to ensure fresh detection
        APR._lastRouteZoneCheck = nil
        APR._lastRouteZoneResult = nil

        -- Reset GetMeToRightZone throttle so zone events always get through
        if APR.transport._routingThrottle then
            APR.transport._routingThrottle.count = 0
            APR.transport._routingThrottle.firstCall = GetTime()
        end
        APR.transport._routingForceRefresh = true

        if IsInInstance() and not APR:IsInstanceWithUI() then
            return
        end

        -- If we are still in the PLAYER_ENTERING_WORLD transition window (instance exit,
        -- teleport, loading screen), skip the immediate check.  The delayed timer from
        -- PLAYER_ENTERING_WORLD will handle it once the map API is stable.
        if APR.transport._worldTransitionTime and (GetTime() - APR.transport._worldTransitionTime) < 0.5 then
            return
        end

        if not APR.IsInRouteZone and APR.ActiveRoute then
            APR.transport:GetMeToRightZone()
        end
    end
end

---------------------------------------------------------------------------------------
---------------------------------- Events utils ---------------------------------------
---------------------------------------------------------------------------------------


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
