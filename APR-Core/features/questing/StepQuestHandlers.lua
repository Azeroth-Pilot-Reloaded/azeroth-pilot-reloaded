-- Evaluates pickup, turn-in and objective actions against the quest cache. True means the current pass must stop.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local handlers = APR.stepHandlers

function handlers.Qpart(step, showStepDetails, currentStepIndex)
    APR:Debug("Qpart step detected")
    local questIDs = step.Qpart
    local questToHighlight = nil

    if (step.QpartDB) then
        APR:Debug("QpartDB detected")
        local wantedQuestId = 0
        for index = 1, getn(step.QpartDB) do
            local qPartDBQuestId = step.QpartDB[index]
            APR:Debug("QpartDB index: " .. index .. ", questID: " .. tostring(qPartDBQuestId))
            if (C_QuestLog.IsQuestFlaggedCompleted(qPartDBQuestId) or APR.ActiveQuests[qPartDBQuestId]) then
                wantedQuestId = qPartDBQuestId
                APR:Debug("QpartDB wantedQuestId set: " .. tostring(wantedQuestId))
                break
            end
        end
        local newList = questIDs[1]
        questIDs = {}
        questIDs[wantedQuestId] = newList
        APR:Debug("QpartDB questIDs updated: " .. tostring(wantedQuestId))
    end

    local flagged = 0
    local total = 0
    for questID, objectives in pairs(questIDs) do
        questID = tonumber(questID)
        APR:Debug("Processing Qpart questID: " .. tostring(questID))
        local questData = APR.ActiveQuests[questID]
        for _, objectiveIndex in pairs(objectives) do
            objectiveIndex = tonumber(objectiveIndex)
            total = total + 1
            APR:Debug("Qpart objectiveIndex: " .. tostring(objectiveIndex))

            if C_QuestLog.IsQuestFlaggedCompleted(questID)
                or ((UnitLevel("player") == APR.MaxLevel) and APR:Contains(APR.BonusObj, questID))
                or APRData[APR.PlayerID].BonusSkips[questID]
            then
                flagged = flagged + 1
                APR:Debug("Qpart flagged: " ..
                    tostring(flagged) .. "/" .. tostring(total) .. " for questID: " .. tostring(questID))
            elseif questData and questData.objectives and questData.objectives[objectiveIndex]
                and questData.objectives[objectiveIndex].status == APR.QUEST_STATUS.COMPLETE
            then
                flagged = flagged + 1
                APR:Debug("Qpart objective complete: " ..
                    tostring(objectiveIndex) .. " for questID: " .. tostring(questID))
            elseif questData and questData.objectives and questData.objectives[objectiveIndex] then
                if showStepDetails then
                    local questText = APR:GetQuestTextForProgressBar(questID, objectiveIndex)

                    APR:Debug("Qpart adding quest step: " ..
                        tostring(questID) ..
                        " obj: " .. tostring(objectiveIndex) .. " text: " .. tostring(questText))

                    APR.currentStep:AddQuestSteps(questID, questText, objectiveIndex)
                end
                questToHighlight = questToHighlight or questID
            elseif not questData then
                if showStepDetails then
                    APR:Debug("Qpart missing quest: " ..
                        tostring(questID) .. " obj: " .. tostring(objectiveIndex))
                    APR:HandleMissingQuest(questID, objectiveIndex)
                end
            end
        end
    end
    APR:Debug("Qpart flagged/total: " .. tostring(flagged) .. "/" .. tostring(total))
    if flagged == total and (flagged > 0 or total == 0) then
        APR:Debug("Qpart all flagged, updating next step")
        APR:UpdateNextStep()
        return true
    end

    if questToHighlight then
        APR:Debug("Qpart tracking quest: " .. tostring(questToHighlight))
        APR:TrackQuest(questToHighlight)
    end
end

function handlers.PickUp(step, showStepDetails, currentStepIndex)
    local questIDs = step.PickUp
    local pickUpDB = step.PickUpDB
    APR:Debug("APR.UpdateStep:PickUp:" .. APRData[APR.PlayerID][APR.ActiveRoute])
    APR:EnsureQuestPool()

    if pickUpDB then
        local hasQuestCompleted = false
        local myQuestID = pickUpDB[1] or questIDs[1]

        for _, questID in ipairs(pickUpDB) do
            local questData = APR.ActiveQuests[questID]
            local questName = APR:GetQuestTitle(questID)
            if questName then
                myQuestID = questID
            end
            if C_QuestLog.IsQuestFlaggedCompleted(questID) or questData then
                hasQuestCompleted = true
                break
            end
        end
        if hasQuestCompleted then
            APR:ResetQuestPool()
            APR:NextQuestStep()
            return true
        elseif showStepDetails then
            APR.currentStep:AddQuestStepsWithDetails("PickUp", L["PICK_UP_Q"], { myQuestID })
        end
    else
        local completedCount = 0
        local uncompletedIDs = {}
        for _, questID in ipairs(questIDs) do
            local questData = APR.ActiveQuests[questID]
            if not (questData or C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                tinsert(uncompletedIDs, questID)
            end
            if C_QuestLog.IsQuestFlaggedCompleted(questID) or questData then
                completedCount = completedCount + 1
            end
        end
        if #questIDs == completedCount then
            APR:Debug("APR.UpdateStep:PickUp:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
            APR:ResetQuestPool()
            APR:NextQuestStep()
            return true
        elseif showStepDetails then
            APR.currentStep:AddQuestStepsWithDetails("PickUp", L["PICK_UP_Q"], uncompletedIDs)
        end
    end
end

function handlers.DropQuest(step, showStepDetails, currentStepIndex)
    local questID = step.DropQuest
    local questData = APR.ActiveQuests[questID]
    if (questID and C_QuestLog.IsQuestFlaggedCompleted(questID)) or questData then
        APR:Debug("APR.UpdateStep:DropQuest:Plus:" .. APRData[APR.PlayerID][APR.ActiveRoute])
        APR:NextQuestStep()
        return true
    end
    if showStepDetails then
        APR:GetQuestTitle(questID)
    end
end

function handlers.Done(step, showStepDetails, currentStepIndex)
    local doneList = step.Done
    local doneDBList = step.DoneDB
    local questToHighlight = nil

    if doneDBList then
        local hasQuestCompleted = false
        local myQuestID = nil

        APR:Debug("APR.UpdateStep:Done:" .. APRData[APR.PlayerID][APR.ActiveRoute])

        for _, questID in ipairs(doneDBList) do
            local questData = APR.ActiveQuests[questID]
            local questName = APR:GetQuestTitle(questID)
            if questName then
                myQuestID = questID
            elseif not questData and not C_QuestLog.IsQuestFlaggedCompleted(questID) then
                if showStepDetails then
                    APR:HandleMissingQuest(questID)
                end
            end
            if C_QuestLog.IsQuestFlaggedCompleted(questID) or questData then
                hasQuestCompleted = true
                break
            end
        end
        if hasQuestCompleted then
            APR:NextQuestStep()
            return true
        elseif showStepDetails then
            APR.currentStep:AddQuestStepsWithDetails("Done", L["TURN_IN_Q"], { myQuestID })
            questToHighlight = myQuestID
        end
    else
        local completedCount = 0
        local uncompletedIDs = {}
        for _, questID in ipairs(doneList) do
            local questData = APR.ActiveQuests[questID]
            if questData then
                tinsert(uncompletedIDs, questID)
                questToHighlight = questToHighlight or questID
            elseif not C_QuestLog.IsQuestFlaggedCompleted(questID) then
                if showStepDetails then
                    APR:HandleMissingQuest(questID)
                end
            end
            if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                completedCount = completedCount + 1
            end
        end

        if #doneList == completedCount then
            APR:UpdateNextStep()
            return true
        elseif showStepDetails then
            APR.currentStep:AddQuestStepsWithDetails("Done", L["TURN_IN_Q"], uncompletedIDs)
        end
    end
    if questToHighlight then
        APR:TrackQuest(questToHighlight)
    end
end

function handlers.QpartPart(step, showStepDetails, currentStepIndex)
    local questIDs = step.QpartPart
    local questToHighlight = nil

    for questID, objectives in pairs(questIDs) do
        questID = tonumber(questID)
        local questData = APR.ActiveQuests[questID]
        for _, objectiveIndex in ipairs(objectives) do
            objectiveIndex = tonumber(objectiveIndex)
            local questText, questStatus
            if questData and questData.objectives and questData.objectives[objectiveIndex] then
                questText = questData.objectives[objectiveIndex].text
                questStatus = questData.objectives[objectiveIndex].status
            end
            if questStatus == APR.QUEST_STATUS.COMPLETE or C_QuestLog.IsQuestFlaggedCompleted(questID) then
                APR:UpdateNextStep()
                return true
            end

            if showStepDetails then
                if questText then
                    APR.currentStep:AddQuestSteps(questID, questText, objectiveIndex)
                else
                    APR:HandleMissingQuest(questID, objectiveIndex)
                end
                questToHighlight = questToHighlight or questID
            end
            if APR:UpdateQpartPartWithQuestText(step, questText, questID) then
                return true
            end
        end
    end

    if questToHighlight then
        APR:TrackQuest(questToHighlight)
    end
end
