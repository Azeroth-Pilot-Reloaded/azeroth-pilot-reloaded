-- Renders standalone item, spell, achievement and interaction actions. True means the current pass must stop.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local handlers = APR.stepHandlers

function handlers.LootMoney(step, showStepDetails, currentStepIndex)
    local cash, resale, required = APR:GetLootMoneyProgress(step.LootMoney)
    if cash + resale >= required then
        APR:NextQuestStep()
        return true
    elseif showStepDetails then
        APR.currentStep:AddLootMoneyStep(step.LootMoney, cash, resale, required)
    end
end

function handlers.ExitTutorial(step, showStepDetails, currentStepIndex)
    if C_QuestLog.IsOnQuest(step.ExitTutorial) then
        APR:NextQuestStep()
        return true
    end
end

function handlers.Treasure(step, showStepDetails, currentStepIndex)
    local questID = step.Treasure.questID
    local itemID = step.Treasure.itemID or nil

    if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then
        APR:Debug("APR.UpdateStep:Treasure:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])

        APR:NextQuestStep()
        return true
    elseif showStepDetails then
        APR:GetQuestTitle(questID)
        if itemID then
            local itemName = C_Item.GetItemInfo(itemID) or UNKNOWN
            APR.currentStep:AddQuestStepsWithDetails("Treasure" .. tostring(questID or itemID),
                L["GET_TREASURE"], {
                    {
                        questID = questID,
                        itemID = itemID,
                        itemName = itemName,
                    }
                })
        else
            APR.currentStep:AddQuestSteps(questID, L["GET_TREASURE"], "Treasure")
        end
    end
end

function handlers.UseItem(step, showStepDetails, currentStepIndex)
    local questID = step.UseItem.questID
    local itemID = step.UseItem.itemID
    local questKey = questID or ("ITEM_" .. itemID)
    local itemName = C_Item.GetItemInfo(itemID)
    local questText = string.format(L["USE_ITEM"], itemName or UNKNOWN)
    if showStepDetails then
        APR.currentStep:AddQuestSteps(questKey, questText, "UseItem", false, not questID)
        APR.currentStep:AddStepButton(questKey .. "-UseItem", itemID, 'item')
    end

    if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then
        APR:UpdateNextStep()
        return true
    end
end

function handlers.UseSpell(step, showStepDetails, currentStepIndex)
    local questID = step.UseSpell.questID
    local spellID = step.UseSpell.spellID
    local questKey = questID or ("SPELL_" .. spellID)
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local questText = string.format(L["USE_SPELL"], (spellInfo and spellInfo.name) or UNKNOWN)
    if showStepDetails then
        APR.currentStep:AddQuestSteps(questKey, questText, "UseSpell", false, not questID)
        APR.currentStep:AddStepButton(questKey .. "-UseSpell", spellID, 'spell')
    end

    if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then
        APR:UpdateNextStep()
        return true
    end
end

function handlers.Group(step, showStepDetails, currentStepIndex)
    if (C_QuestLog.IsQuestFlaggedCompleted(step.Group.questID)) then
        APR:UpdateNextStep()
        return true
    else
        handlers.GroupQuestPopup()
    end
end

function handlers.Achievement(step, showStepDetails, currentStepIndex)
    local achievementData = step.Achievement
    if achievementData and achievementData.achievementID then
        local isCompleted, progressText = APR:IsAchievementStepComplete(step)
        if isCompleted then
            APR:UpdateNextStep()
            return true
        end

        if showStepDetails then
            local objectiveKey = "Achievement-" ..
                tostring(achievementData.achievementID) .. "-" .. tostring(achievementData.criteriaIndex or 0)
            APR.currentStep:AddQuestSteps(objectiveKey, progressText,
                achievementData.criteriaIndex or achievementData.achievementID)
        end
    end
end

function handlers.GossipOptionIDs(step, showStepDetails, currentStepIndex)
    local alreadyTalked = APR:hasEveryGossipsCompleted(step.GossipOptionIDs)

    if alreadyTalked then
        APR:UpdateNextStep()
    end

    if showStepDetails then
        APR.currentStep:AddQuestSteps("GOSSIP_ONLY", L["TALK_NPC"], next(step.GossipOptionIDs))
    end
end
