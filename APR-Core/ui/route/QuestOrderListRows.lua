local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local QuestOrderListUtils = APR.questOrderListUtils

local function colorByCompletion(isCompleted, currentStep, stepIndex)
    return (isCompleted or (currentStep and currentStep > stepIndex)) and "green" or "gray"
end

local function getQuestName(questID)
    return C_QuestLog.GetTitleForQuestID(questID) or UNKNOWN
end

-- Translate route entries into rows in the hidden render buffer. The window owns
-- scheduling, cancellation and publishing; route-specific presentation stays here.
function APR.questOrderList:CreateRouteRenderer(layout, activeRouteSteps, currentStepIndex, target)
    local sojournerSkipActive = APR:IsSojournerSkipActive()
    local function isStepVisible(step)
        return APR:StepFilterQoL(step) and not (sojournerSkipActive and APR:IsStepCampaignQuest(step))
    end
    local playerID = APR.PlayerID
    local playerData = playerID and APRData and APRData[playerID] or nil

    local function safeTContains(list, value)
        return list ~= nil and tContains(list, value) or false
    end

    local displayStepIndex = 1
    target.currentDisplayIndex = nil
    local visibilityParts = target.visibilityParts
    local function renderRows()
        for rawIndex, step in ipairs(activeRouteSteps) do
            -- Hide step for Faction, Race, Class, Achievement
            -- Also hide sojourner-skipped campaign steps
            local visible = isStepVisible(step)
            visibilityParts[rawIndex] = visible and "1" or "0"
            if visible then
                local container
                local activeQuestId
                local isCurrentStep = rawIndex == currentStepIndex

                if step.ExitTutorial then
                    local questID = step.ExitTutorial
                    local color = colorByCompletion(C_QuestLog.IsOnQuest(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["SKIP_TUTORIAL"],
                        color, isCurrentStep)
                elseif step.BuyMerchant and not step.Qpart then
                    local buyMerchant = step.BuyMerchant
                    local questInfo = {}
                    local flagged = 0
                    for _, item in ipairs(buyMerchant) do
                        if C_QuestLog.IsQuestFlaggedCompleted(item.questID) or currentStepIndex > rawIndex then
                            flagged = flagged + 1
                        else
                            local itemName = C_Item.GetItemInfo(item.itemID) or UNKNOWN
                            table.insert(questInfo, { questID = item.quantity, questName = itemName })
                        end
                    end
                    if #buyMerchant == flagged then
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["BUY"],
                            "green",
                            isCurrentStep)
                    else
                        container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                            L["BUY"],
                            questInfo, "gray", isCurrentStep)
                    end
                elseif step.PickUp then
                    local idList = step.PickUp
                    local dbList = step.PickUpDB or {}
                    local questInfo = {}
                    local flagged = 0

                    for _, questID in pairs(idList) do
                        if QuestOrderListUtils:IsQuestCompletedOrActive(questID) then
                            flagged = flagged + 1
                        else
                            for _, dbQuestID in pairs(dbList) do
                                if QuestOrderListUtils:IsQuestCompletedOrActive(dbQuestID) then
                                    flagged = flagged + 1
                                    break
                                end
                            end
                            if flagged == 0 then
                                table.insert(questInfo,
                                    { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) })
                            end
                        end
                    end

                    if #idList == flagged then
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["PICK_UP_Q"],
                            "green", isCurrentStep)
                    else
                        container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                            L["PICK_UP_Q"], questInfo, "gray", isCurrentStep)
                    end
                elseif step.DropQuest then
                    local questData = step.DroppableQuest
                    local questID = questData and questData.Qid or 1
                    local MobId = questData and questData.MobId or 1
                    local MobName = APRData.NPCList[MobId] or (questData and questData.Text or UNKNOWN)
                    local questText = format(L["Q_DROP"], MobName)
                    local questInfo = { { questID = questID, questName = getQuestName(questID) } }
                    local color = QuestOrderListUtils:IsQuestCompletedOrActive(questID) and "green" or "gray"
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex, questText,
                        questInfo, color, isCurrentStep)
                elseif step.Qpart then
                    local idList = step.Qpart
                    local dbList = step.QpartDB or {}
                    local questInfo = {}
                    local flagged = 0
                    local total = 0

                    local isMaxLevel = UnitLevel("player") == APR.MaxLevel

                    local function isObjectiveCompleted(questID, objectiveIndex)
                        -- 1- quest completed
                        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                            return true
                        end

                        -- 2- questB Bonus or skipped
                        local questObjectiveId = questID .. '-' .. objectiveIndex
                        local bonusSkips = playerData and playerData.BonusSkips or nil
                        if (isMaxLevel and APR.BonusObj and APR:Contains(APR.BonusObj, questObjectiveId)) or
                            (bonusSkips and bonusSkips[questID]) then
                            return true
                        end

                        -- 3- quest objective completed
                        local quest = APR.ActiveQuests[questID]
                        if quest and quest.objectives and quest.objectives[objectiveIndex] then
                            return quest.objectives[objectiveIndex].status == APR.QUEST_STATUS.COMPLETE
                        end
                        return false
                    end

                    for questID, objectives in pairs(idList) do
                        for _, objectiveIndex in pairs(objectives) do
                            total = total + 1
                            if isObjectiveCompleted(questID, objectiveIndex) then
                                flagged = flagged + 1
                            else
                                for _, dbQuestID in pairs(dbList) do
                                    if dbQuestID == questID or isObjectiveCompleted(dbQuestID, objectiveIndex) then
                                        flagged = flagged + 1
                                        break
                                    end
                                end
                                if flagged == 0 then
                                    table.insert(questInfo,
                                        {
                                            questID = questID .. '-' .. objectiveIndex,
                                            questName = getQuestName(questID)
                                        })
                                end
                            end
                        end
                    end

                    if total == flagged then
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["Q_PART"],
                            "green", isCurrentStep)
                    else
                        container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                            L["Q_PART"], questInfo, "gray", isCurrentStep)
                    end
                elseif step.QpartPart then
                    local idList = step.QpartPart
                    local questInfo = {}
                    local flagged = 0
                    local total = 0
                    for questID, objectives in pairs(idList) do
                        for _, objectiveIndex in pairs(objectives) do
                            total = total + 1
                            local questObjectiveId = questID .. '-' .. objectiveIndex
                            local quest = APR.ActiveQuests[questID]
                            local questObjective = quest and quest.objectives and quest.objectives[objectiveIndex] or nil
                            local text = questObjective and questObjective.text or nil
                            local status = questObjective and questObjective.status or nil
                            for key, value in pairs(step) do
                                if string.match(key, "TrigText+") and value and text then
                                    if APR:TrigTextValueMatch(value, text) then
                                        flagged = flagged + 1
                                    end
                                end
                            end
                            local objective = C_QuestLog.GetQuestObjectives(questID)
                            if C_QuestLog.IsQuestFlaggedCompleted(questID) or (objective and objective[objectiveIndex] and objective[objectiveIndex].finished) or (status == APR.QUEST_STATUS.COMPLETE) then
                                flagged = flagged + 1
                            else
                                table.insert(questInfo,
                                    { questID = questObjectiveId, questName = getQuestName(questID) })
                            end
                        end
                    end
                    if total == flagged then
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["Q_PART"],
                            "green", isCurrentStep)
                    else
                        container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                            L["Q_PART"], questInfo, "gray", isCurrentStep)
                    end
                elseif step.Treasure then
                    local questID = step.Treasure.questID
                    local itemID = step.Treasure.itemID or nil
                    local displayName = (itemID and C_Item.GetItemInfo(itemID)) or getQuestName(questID)
                    local questInfo = { { questID = itemID or questID, questName = displayName } }
                    local color = colorByCompletion(questID and C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex,
                        rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                        L["GET_TREASURE"], questInfo, color, isCurrentStep)
                elseif step.Group then
                    local questID = step.Group.questID
                    local questInfo = { { questID = questID, questName = getQuestName(questID) } }
                    local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                        L["GROUP_Q"],
                        questInfo, color, isCurrentStep)
                elseif step.Done then
                    local idList = step.Done
                    local dbList = step.DoneDB or {}
                    local questInfo = {}
                    local flagged = 0

                    for _, questID in pairs(idList) do
                        if QuestOrderListUtils:IsQuestCompleted(questID) then
                            flagged = flagged + 1
                        else
                            for _, dbQuestID in pairs(dbList) do
                                if QuestOrderListUtils:IsQuestCompleted(dbQuestID) then
                                    flagged = flagged + 1
                                    break
                                end
                            end
                            if flagged == 0 then
                                table.insert(questInfo,
                                    { questID = questID, questName = C_QuestLog.GetTitleForQuestID(questID) })
                            end
                        end
                    end

                    if #idList == flagged then
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["TURN_IN_Q"],
                            "green", isCurrentStep)
                    else
                        container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                            L["TURN_IN_Q"], questInfo, "gray", isCurrentStep)
                    end
                elseif step.Scenario then
                    local scenario = step.Scenario
                    local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
                    local questID = scenario.questID
                    if not scenarioInfo then
                        if currentStepIndex > rawIndex then
                            container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                                L["SCENARIO"],
                                "green", isCurrentStep)
                        else
                            local scenarioStepInfo = C_ScenarioInfo.GetScenarioStepInfo(scenario.stepID)
                            local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario
                                .criteriaIndex)
                            local questInfo = { { questID = scenarioStepInfo.title, questName = criteriaInfo.description } }
                            container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                                L["SCENARIO"], questInfo, "gray", isCurrentStep)
                        end
                    else
                        local criteriaInfo = C_ScenarioInfo.GetCriteriaInfoByStep(scenario.stepID, scenario.criteriaIndex)
                        local isDelveRoute = APR:IsDelveRoute(APR.ActiveRoute)
                        local canUseScenarioQuestCompletion = questID and (not isDelveRoute) and tonumber(questID) ~= 1
                        local completed = criteriaInfo.completed or
                            (canUseScenarioQuestCompletion and C_QuestLog.IsQuestFlaggedCompleted(questID)) or
                            currentStepIndex > rawIndex
                        local color = completed and "green" or "gray"
                        local questInfo = { { questID = scenario.criteriaIndex, questName = criteriaInfo.description } }
                        container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                            L["SCENARIO"] .. " - " .. scenarioInfo.name, questInfo, color, isCurrentStep)
                    end
                elseif step.EnterScenario or step.EnterInstance then
                    local scenarioMapID = step.EnterScenario and step.EnterScenario.mapID or step.EnterInstance.mapID
                    local questID = step.EnterScenario and step.EnterScenario.questID or step.EnterInstance.questID
                    local currentMapID = C_Map.GetBestMapForUnit('player')
                    local mapInfo = APR:GetMapInfoCached(scenarioMapID)
                    local mapName = mapInfo and mapInfo.name or UNKNOWN
                    local scenarioInfo = APR:GetScenarioZoneInfo(scenarioMapID)
                    local isDelveScenario = scenarioInfo and scenarioInfo.type == "DELVE"
                    local isCompleted = ((not isDelveScenario) and safeTContains(
                        APRScenarioMapIDCompleted and playerID and APRScenarioMapIDCompleted[playerID] or nil,
                        scenarioMapID)) or (questID and C_QuestLog.IsQuestFlaggedCompleted(questID))
                    local scenarioTypeLabel = (scenarioInfo and scenarioInfo.type and L[scenarioInfo.type]) or L["SCENARIO"] or
                        UNKNOWN

                    local color = (scenarioMapID == currentMapID or isCompleted or currentStepIndex > rawIndex) and "green" or
                        "gray";
                    local questInfo = { { questID = mapName } }
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                        format(L["ENTER_IN"], scenarioTypeLabel, mapName), questInfo, color, isCurrentStep)
                elseif step.DoScenario then
                    local scenarioMapID = step.DoScenario.mapID
                    local scenarioQuestID = step.DoScenario.questID
                    local mapInfo = APR:GetMapInfoCached(scenarioMapID)
                    local mapName = mapInfo and mapInfo.name or UNKNOWN
                    local scenarioInfo = APR:GetScenarioZoneInfo(scenarioMapID)
                    local isDelveScenario = scenarioInfo and scenarioInfo.type == "DELVE"
                    local isCompleted = ((not isDelveScenario) and safeTContains(
                        APRScenarioMapIDCompleted and playerID and APRScenarioMapIDCompleted[playerID] or nil,
                        scenarioMapID)) or (scenarioQuestID and C_QuestLog.IsQuestFlaggedCompleted(scenarioQuestID))
                    local scenarioTypeLabel = (scenarioInfo and scenarioInfo.type and L[scenarioInfo.type]) or L["SCENARIO"] or
                        UNKNOWN
                    local hasQpartCompleted = false

                    local qpart = step.Qpart
                    if qpart and type(qpart) == "table" then
                        local questID = next(qpart)
                        if questID then
                            local quest = APR.ActiveQuests[questID]
                            if (quest and quest.status == APR.QUEST_STATUS.COMPLETE) and isCompleted then
                                hasQpartCompleted = true
                            end
                        end
                    end

                    local color = (hasQpartCompleted and isCompleted) or currentStepIndex > rawIndex and "green" or "gray";
                    local questInfo = { { questID = mapName } }
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                        format(L["COMPLETE_SOMETHING"], scenarioTypeLabel, mapName), questInfo, color, isCurrentStep)
                elseif step.LeaveScenario or step.LeaveInstance then
                    local scenarioMapID      = step.LeaveScenario and step.LeaveScenario.mapID or step.LeaveInstance.mapID
                    local questID            = step.LeaveScenario and step.LeaveScenario.questID or
                        step.LeaveInstance.questID
                    local currentMapID       = C_Map.GetBestMapForUnit('player')
                    local mapInfo            = APR:GetMapInfoCached(scenarioMapID)
                    local mapName            = mapInfo and mapInfo.name or UNKNOWN
                    local scenarioInfo       = APR:GetScenarioZoneInfo(scenarioMapID)
                    local isDelveScenario    = scenarioInfo and scenarioInfo.type == "DELVE"
                    local isCompleted        = ((not isDelveScenario) and safeTContains(
                        APRScenarioMapIDCompleted and playerID and APRScenarioMapIDCompleted[playerID] or nil,
                        scenarioMapID)) or (questID and C_QuestLog.IsQuestFlaggedCompleted(questID))

                    local color              = ((scenarioMapID ~= currentMapID and isCompleted) or currentStepIndex > rawIndex) and
                        "green" or "gray";
                    local questInfo          = { { questID = mapName } }
                    local leaveKey           = scenarioInfo and scenarioInfo.type and ("LEAVE_" .. scenarioInfo.type) or
                        nil
                    local leaveText          = (leaveKey and L[leaveKey]) or L["SCENARIO"] or UNKNOWN
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                        leaveText, questInfo, color, isCurrentStep)
                elseif step.TakePortal then
                    local portalData = step.TakePortal
                    local questID = portalData.questID
                    local mapID = portalData.mapID
                    local currentMapID = C_Map.GetBestMapForUnit("player")
                    local parentMapID = APR:GetPlayerParentMapID()
                    local arrived = mapID and (currentMapID == mapID or parentMapID == mapID)
                    local completed = (questID and C_QuestLog.IsQuestFlaggedCompleted(questID)) or arrived
                    local color = colorByCompletion(completed, currentStepIndex, rawIndex)
                    local mapInfo = APR:GetMapInfoCached(mapID)
                    local zoneName = (mapInfo and mapInfo.name) or UNKNOWN
                    local stepText = string.format(L["USE_PORTAL_TO"], zoneName)
                    local questInfo = { { questID = zoneName } }
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                        stepText, questInfo, color, isCurrentStep)
                elseif step.Waypoint then
                    local questID = step.Waypoint
                    local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["RUN_WAYPOINT"],
                        color, isCurrentStep)
                elseif step.SetHS then
                    local questID = step.SetHS
                    local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        L["SET_HEARTHSTONE"],
                        color, isCurrentStep)
                elseif step.UseHS or step.UseDalaHS or step.UseGarrisonHS then
                    local questID = step.UseHS or step.UseDalaHS or step.UseGarrisonHS
                    local questText = step.UseHS and L["USE_HEARTHSTONE"] or
                        (step.UseDalaHS and L["USE_DALARAN_HEARTHSTONE"] or L["USE_GARRISON_HEARTHSTONE"])
                    local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, questText, color,
                        isCurrentStep)
                elseif step.UseItem then
                    local questID = step.UseItem.questID
                    local itemID = step.UseItem.itemID
                    local itemName = C_Item.GetItemInfo(itemID)
                    local questText = string.format(L["USE_ITEM"], itemName or UNKNOWN)
                    local color = colorByCompletion(questID and C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, questText, color,
                        isCurrentStep)
                elseif step.UseSpell then
                    local questID = step.UseSpell.questID
                    local spellID = step.UseSpell.spellID
                    local spellInfo = C_Spell.GetSpellInfo(spellID)
                    local questText = string.format(L["USE_SPELL"], (spellInfo and spellInfo.name) or UNKNOWN)
                    local color = colorByCompletion(questID and C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, questText, color,
                        isCurrentStep)
                elseif step.GetFP then
                    local nodeID = step.GetFP
                    local color = (APR:HasTaxiNode(nodeID) or currentStepIndex > rawIndex) and "green" or "gray"
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L
                        ["GET_FLIGHTPATH"],
                        color, isCurrentStep)
                elseif step.UseFlightPath then
                    local questID = step.UseFlightPath
                    local questText = step.Boat and L["USE_BOAT"] or L["USE_FLIGHTPATH"]
                    local questInfo = { { questID = APR:GetTaxiNodeName(step) } }
                    local color = colorByCompletion(C_QuestLog.IsQuestFlaggedCompleted(questID), currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex, questText,
                        questInfo, color, isCurrentStep)
                elseif step.Achievement then
                    local achievementData = step.Achievement
                    if achievementData and achievementData.achievementID then
                        local isCompleted, progressText = APR:IsAchievementStepComplete(step)
                        local color = colorByCompletion(isCompleted, currentStepIndex, rawIndex)
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                            progressText, color, isCurrentStep)
                    end
                elseif step.LearnProfession then
                    local spellID = step.LearnProfession
                    local spellInfo = C_Spell.GetSpellInfo(spellID)
                    local name = (spellInfo and spellInfo.name) or UNKNOWN
                    local questInfo = { { questID = name } }
                    local color = APR:IsSpellKnown(spellID) and "green" or "gray"
                    container, activeQuestId = QuestOrderListUtils:AddStepFrameWithQuest(layout, displayStepIndex,
                        L["LEARN_PROFESSION"], questInfo, color, isCurrentStep)
                elseif step.LootMoney then
                    local cash, resale, required = APR:GetLootMoneyProgress(step.LootMoney)
                    local color = colorByCompletion(cash + resale >= required, currentStepIndex, rawIndex)
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        APR:GetLootMoneyStepText(step.LootMoney), color, isCurrentStep)
                elseif step.LootItems then
                    local title = L["LOOT_ITEM"]
                    local itemsInfo = {}
                    local completed = 0

                    for _, item in ipairs(step.LootItems) do
                        local itemID = item.itemID
                        local questID = item.questID
                        local requiredQuantity = math.max(item.quantity or 1, 1)

                        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                            completed = completed + 1
                        elseif itemID then
                            local bagCount = C_Item.GetItemCount(itemID, true) or 0
                            local virtualCount = APR.QuestVirtualItemCount[itemID] or 0
                            local currentQuantity = math.max(bagCount, virtualCount)

                            local isDone =
                                currentQuantity >= requiredQuantity
                                or APR.lootUtils:IsLootDone(step, "ITEM", itemID)
                                or currentStepIndex > rawIndex

                            if isDone then
                                completed = completed + 1
                            else
                                local itemName = C_Item.GetItemInfo(itemID) or UNKNOWN
                                table.insert(itemsInfo, {
                                    questID = requiredQuantity,
                                    questName = itemName,
                                })
                            end
                        end
                    end

                    if completed == #step.LootItems then
                        container, activeQuestId =
                            QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, title, "green", isCurrentStep)
                    else
                        container, activeQuestId =
                            QuestOrderListUtils:AddStepFrameWithQuest(
                                layout,
                                displayStepIndex,
                                title,
                                itemsInfo,
                                "gray",
                                isCurrentStep
                            )
                    end
                elseif step.WarMode then
                    local color = C_PvP.IsWarModeDesired() and "green" or "gray"
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        L["TURN_ON_WARMODE"],
                        color, isCurrentStep)
                elseif step.Grind then
                    local color = APR:GetPlayerEffectiveLevel() >= APR:ResolveLevelRequirement(step.Grind) and "green" or "gray"
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        APR:GetGrindStepText(step.Grind), color, isCurrentStep)
                elseif step.Reputation then
                    local completed = APR:IsReputationLevelReached(step.Reputation) or currentStepIndex > rawIndex
                    local color = completed and "green" or "gray"
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        APR:GetReputationStepText(step.Reputation), color, isCurrentStep)
                elseif step.EquipItem then
                    local rule = step.EquipItem
                    local completed = GetInventoryItemID("player", rule.slot) == rule.itemID
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        APR:GetRouteActionText("EquipItem", rule),
                        colorByCompletion(completed, currentStepIndex, rawIndex), isCurrentStep)
                elseif step.Emote then
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        string.format(L["PERFORM_EMOTE"], step.Emote.emote),
                        colorByCompletion(false, currentStepIndex, rawIndex), isCurrentStep)
                elseif step.Note then
                    local previewText = nil
                    if type(step.Note) == "table" then
                        local firstMessage = APR:ResolveStepText(step.Note[1])
                        if firstMessage and firstMessage ~= "" then
                            previewText = firstMessage
                            if #step.Note > 1 then
                                previewText = previewText .. " ..."
                            end
                        end
                    else
                        previewText = APR:ResolveStepText(step.Note)
                    end

                    if previewText and previewText ~= "" then
                        if #previewText > 50 then
                            previewText = string.sub(previewText, 1, 50) .. "..."
                        end
                        local color = colorByCompletion(false, currentStepIndex, rawIndex)
                        container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                            "Note: " .. previewText, color, isCurrentStep)
                    end
                elseif step.GossipOptionIDs and not APR:HasAnyMainStepOption(step) then
                    local alreadyTalked = APR:hasEveryGossipsCompleted(step.GossipOptionIDs)
                    local color = (alreadyTalked or currentStepIndex > rawIndex) and "green" or "gray"
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex, L["TALK_NPC"],
                        color,
                        isCurrentStep)
                elseif step.RouteCompleted then
                    container, activeQuestId = QuestOrderListUtils:AddStepFrame(layout, displayStepIndex,
                        L["ROUTE_COMPLETED"],
                        "gray", isCurrentStep)
                end
                if container then
                    if isCurrentStep then target.currentDisplayIndex = displayStepIndex end
                    target.stepList[displayStepIndex] = container
                    target.rawStepContainers[rawIndex] = container
                    container.rawIndex = rawIndex
                    container.displayIndex = displayStepIndex
                    container.collapseWhenPassed = (step.BuyMerchant and not step.Qpart) or step.PickUp or step.Qpart or
                        step.QpartPart or step.Done or step.LootItems or false
                    if activeQuestId then
                        target.questID = activeQuestId
                    end
                    displayStepIndex = displayStepIndex + 1
                end
            end
            coroutine.yield()
        end
    end
    return renderRows
end
