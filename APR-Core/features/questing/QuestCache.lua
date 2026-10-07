-- Synchronizes quest-log objectives and completion state; cache refreshes are coalesced before rendering.

function APR:UpdateQuest(deferStepUpdate)
    APR:Debug("Function: APR_UpdateQuest()")

    local updateStep = false

    local numQuestLogEntries = C_QuestLog.GetNumQuestLogEntries()
    for questIndex = 1, numQuestLogEntries do
        local questInfo = C_QuestLog.GetInfo(questIndex)

        if questInfo and questInfo.questID > 0 and not questInfo.isHeader then
            local questID = questInfo.questID
            local questTitle = APR:GetQuestTitle(questID)
            local isQuestComplete = C_QuestLog.IsComplete(questID)
            local numObjectives = C_QuestLog.GetNumQuestObjectives(questID)
            local questStatus = isQuestComplete and APR.QUEST_STATUS.COMPLETE or APR.QUEST_STATUS.PROGRESS

            APR.ActiveQuests[questID] = APR.ActiveQuests[questID] or {
                status = questStatus,
                title = questTitle,
                objectives = {},
            }

            if APR.ActiveQuests[questID].status ~= questStatus then
                APR:Debug(("Quest [%s] status updated: %s"):format(questTitle, questStatus))
                updateStep = true
            end
            -- Update quest status if it has changed
            APR.ActiveQuests[questID].status = questStatus

            -- Handle objectives
            local questObjectives = (numObjectives > 0) and C_QuestLog.GetQuestObjectives(questID) or nil
            if not questObjectives then
                -- Quest without objectives
                APR.ActiveQuests[questID].objectives[1] = {
                    text = questTitle,
                    status = questStatus,
                }
            else
                for i, objectiveInfo in ipairs(questObjectives) do
                    local status = objectiveInfo.finished and APR.QUEST_STATUS.COMPLETE or APR.QUEST_STATUS.PROGRESS
                    local text = objectiveInfo.text or ""

                    -- Update only if changed
                    local objEntry = APR.ActiveQuests[questID].objectives[i]
                    if not objEntry or objEntry.text ~= text or objEntry.status ~= status then
                        updateStep = true
                        APR:Debug(("Objective [%s] - Step %d: %s (%s)"):format(
                            questTitle, i, text, status))
                    end

                    APR.ActiveQuests[questID].objectives[i] = {
                        text = text,
                        status = status,
                    }

                    -- // todo check le refresh pourquoi
                    APR.currentStep:UpdateQuestStep(questID, text, i)
                    APR.fillersFrame:UpdateFillerStep(questID, text, i)
                end
            end
        end
    end
    -- Combined refresh callers render once, after the quest cache is synchronized.
    -- UpdateStep also evaluates QpartPart text triggers against that cache.
    if deferStepUpdate then return end
    APR:UpdateQpartPart()
    if updateStep then
        APR:UpdateStep()
    else
        -- update for group if not a new step
        APR.party:SendGroupMessage(true)
        APR.party:RefreshPartyFrameAnchor()
    end
end

function APR:RemoveQuest(questID)
    if not questID then return end

    APR.ActiveQuests[questID] = nil

    local questIDs, StepP = APR:GetQuestAndStepIds()
    if StepP == "Done" then
        local nrLeft = 0
        for _, id in pairs(questIDs) do
            if not C_QuestLog.IsQuestFlaggedCompleted(id) and questID ~= id then
                nrLeft = nrLeft + 1
            end
        end
        if nrLeft == 0 then
            self:UpdateQuest(true)
            self:Debug("APR - RemoveQuest", APRData[APR.PlayerID][APR.ActiveRoute])
        end
    end

    -- A quest removal does not change the player's location. UpdateStep schedules
    -- navigation when its step token changes; avoid a synchronous routing refresh
    -- here, which also rebuilds the quest tracker and the current step.
    self:OverrideRouteData()
    self:UpdateStep()
end

function APR:PopupAutocompleteQuest()
    if (GetNumAutoQuestPopUps() > 0) then
        local questID, popUpType = GetAutoQuestPopUp(1)
        if (popUpType == "OFFER") then
            ShowQuestOffer(1)
            ShowQuestOffer(questID)
        elseif (popUpType == "COMPLETE") then
            ShowQuestOffer(1)
            ShowQuestComplete(questID)
        end
    else
        C_Timer.After(1, function() APR:PopupAutocompleteQuest() end)
    end
end
