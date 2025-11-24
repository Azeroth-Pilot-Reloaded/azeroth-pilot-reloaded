local L = LibStub("AceLocale-3.0"):GetLocale("APR")

--[[
    Quest-centric helpers kept away from technical utilities to make the responsibilities explicit.
]]

function APR:AcceptQuest()
    AcceptQuest()
end

function APR:CloseQuest()
    CloseQuest()
end

--- Check if at least one quest in the list is completed on this character.
-- This allows step handlers to gate progress on any-quest-complete conditions.
function APR:IsOneOfQuestsCompleted(questIds)
    if not questIds or #questIds == 0 then
        return false
    end
    for i = 1, #questIds do
        if C_QuestLog.IsQuestFlaggedCompleted(questIds[i]) then
            return true
        end
    end

    return false
end

--- Check that every quest in the list is completed on this character.
-- Used for strict gating when multiple prerequisites must be met.
function APR:IsQuestsCompleted(questIds)
    if not questIds or #questIds == 0 then
        return false
    end
    for i = 1, #questIds do
        if not C_QuestLog.IsQuestFlaggedCompleted(questIds[i]) then
            return false
        end
    end

    return true
end

--- Check if at least one quest is completed on the account (cross-character).
function APR:IsOneOfQuestsCompletedOnAccount(questIds)
    if not questIds or #questIds == 0 then
        return false
    end
    for i = 1, #questIds do
        if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questIds[i]) then
            return true
        end
    end

    return false
end

--- Check that every quest is completed on the account (cross-character check).
function APR:IsQuestsCompletedOnAccount(questIds)
    if not questIds or #questIds == 0 then
        return false
    end
    for i = 1, #questIds do
        if not C_QuestLog.IsQuestFlaggedCompletedOnAccount(questIds[i]) then
            return false
        end
    end

    return true
end

--- Split a composite quest string into quest ID and objective index (when available).
function APR:SplitQuestAndObjective(questID)
    local id, objective = questID:match("([^%-]+)%-([^%-]+)")
    if id and objective then
        return tonumber(id), tonumber(objective)
    end
    return tonumber(questID)
end

--- Notify the player that an interaction is not available yet.
function APR:NotYet()
    APR:PrintInfo(L["NOT_YET"])
    UIErrorsFrame:AddMessage(L["NOT_YET"], 1, 153 / 255, 102 / 255, 1, 5)
end

--- Add a quest to the watch list and super-track it for clarity.
function APR:TrackQuest(questID)
    C_QuestLog.AddQuestWatch(questID) -- add to the quest log
    C_SuperTrack.SetSuperTrackedQuestID(questID) -- highlight the quest
end

--- Detect if the provided questID belongs to a campaign quest line.
function APR:IsCampaignQuest(questID)
    local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if not questIndex then return false end
    local questInfo = C_QuestLog.GetInfo(questIndex)
    return questInfo and questInfo.campaignID ~= nil
end

--- Remove a quest from the log.
-- This function wraps the abandonment flow to keep call sites concise.
function APR:LeaveQuest(questIds)
    C_QuestLog.SetSelectedQuest(questIds)
    C_QuestLog.AbandonQuest()
end

--- Returns quest/objective ids for the active step so consumers can branch on type.
function APR:GetQuestAndStepIds()
    if not APR.RouteQuestStepList[APR.ActiveRoute] then
        return
    end

    local step = APR:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    if not step then return end
    if step.PickUp then
        return step.PickUp, "PickUp"
    elseif step.Qpart then
        return step.Qpart, "Qpart"
    elseif step.Done then
        return step.Done, "Done"
    end
end

--- Helper to detect whether a set of gossip options has all been validated.
function APR:hasEveryGossipsCompleted(tbl)
    local isCompleted = true
    local list = APRGossipValidated[APR.PlayerID]

    for _, id in ipairs(tbl) do
        if not list[id] then
            isCompleted = false
            break
        end
    end
    return isCompleted
end

--- Queue a missing quest message to show the player they need to pick it up.
function APR:MissingQuest(questId, objectiveId)
    local questTextToAdd
    questId = questId or UNKNOWN
    if APR:Contains(APR.BonusObj, questId) then
        questTextToAdd = L["DO_BONUS_OBJECTIVE"] .. ": " .. questId
    else
        questTextToAdd = L["ERROR"] .. " - " .. L["MISSING_Q"] .. ": " .. questId
    end
    APR.currentStep:AddQuestSteps(questId, questTextToAdd, objectiveId, false, true)
end

--- Reset the local missing quest cache.
function APR:ResetMissingQuests()
    for k in pairs(self.MissingQuests) do
        self.MissingQuests[k] = nil
    end
end

--- Only log a missing quest once to avoid chat spam.
function APR:HandleMissingQuest(questId, objectiveId)
    if not self.MissingQuests[questId] then
        self:MissingQuest(questId, objectiveId)
        self.MissingQuests[questId] = true
    end
end

--- Step through QpartPart steps and advance when the objective text matches expected triggers.
function APR:UpdateQpartPart()
    local step = APR:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil) or {}
    local IdList = step.QpartPart or {}

    for questId, objectives in pairs(IdList) do
        local quest = APR.ActiveQuests[tonumber(questId)]
        if quest and quest.objectives then
            for _, objectiveId in ipairs(objectives) do
                local objective = quest.objectives[tonumber(objectiveId)]
                if objective and objective.text then
                    -- search in the TrigText+ keys
                    for key, value in pairs(step) do
                        if string.match(key, "TrigText+") then
                            if value and string.find(objective.text, value) then
                                self:UpdateNextStep()
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

--- Advance QpartPart steps when the quest text from the UI matches trigger values.
function APR:UpdateQpartPartWithQuesText(step, questText)
    for key, value in pairs(step) do
        if string.match(key, "TrigText+") then
            if value and questText and string.find(questText, value) then
                self:UpdateNextStep()
                return
            end
        end
    end
end
