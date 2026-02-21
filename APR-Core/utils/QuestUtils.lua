local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.QuestPool = APR.QuestPool or { ids = {} }

function APR:AcceptQuest()
    AcceptQuest()
end

function APR:CloseQuest()
    CloseQuest()
end

local function AddQuestToPool(pool, questID)
    questID = tonumber(questID)
    if questID and not APR:Contains(pool.ids, questID) then
        table.insert(pool.ids, questID)
    end
end

local function GetQuestProgressPercentSafe(questID)
    if not questID or not GetQuestProgressBarPercent then
        return nil
    end

    local ok, percent = pcall(GetQuestProgressBarPercent, questID)
    if not ok then
        return nil
    end

    local numeric = tonumber(percent)
    if not numeric then
        return nil
    end

    return math.floor(numeric)
end

function APR:ResetQuestPool()
    self.QuestPool = {
        ids = {},
        route = nil,
        stepIndex = nil,
        lookahead = nil,
    }
end

--- Builds a quest pool for pickup based on the specified step index and lookahead distance.
---
--- @param stepIndex number The index of the current step in the quest sequence.
--- @param lookahead number The number of steps to look ahead when building the quest pool.
---
--- @return table questPool A table containing the quests available for pickup.
function APR:BuildQuestPoolForPickup(stepIndex, lookahead)
    local activeRoute = self.ActiveRoute
    local stepList = activeRoute and self.RouteQuestStepList[activeRoute] or nil

    if not stepList or not stepIndex then
        self:ResetQuestPool()
        return self.QuestPool
    end

    local pool = {
        ids = {},
        route = activeRoute,
        stepIndex = stepIndex,
        lookahead = lookahead,
    }

    local lastIndex = math.min(#stepList, stepIndex + lookahead)
    for i = stepIndex, lastIndex do
        local step = stepList[i]
        if step then
            local pickUp = step.PickUp or {}
            for _, questID in ipairs(pickUp) do
                AddQuestToPool(pool, questID)
            end

            local pickUpDB = step.PickUpDB or {}
            for _, questID in ipairs(pickUpDB) do
                AddQuestToPool(pool, questID)
            end
        end
    end

    self.QuestPool = pool
    return pool
end

--- Ensures that the quest pool is initialized and ready for use.
--- Initializes the quest pool if it hasn't been created yet, or validates
--- the existing quest pool structure. This should be called before performing
--- any quest-related operations to guarantee the pool exists.
---
--- @function EnsureQuestPool
--- @return table|nil questPool A table containing the quests available for pickup.
function APR:EnsureQuestPool()
    local activeRoute = self.ActiveRoute
    local playerData = APRData and APRData[self.PlayerID] or nil
    local stepIndex = playerData and activeRoute and playerData[activeRoute] or nil

    if not activeRoute or not stepIndex then
        self:ResetQuestPool()
        return nil
    end

    if not self:IsPickupStep() then
        self:ResetQuestPool()
        return nil
    end

    local lookahead = tonumber(self.settings and self.settings.profile and self.settings.profile.pickupQuestLookahead)
    if lookahead < 0 then
        lookahead = 0
    end

    local pool = self.QuestPool
    if not pool or pool.route ~= activeRoute or pool.stepIndex ~= stepIndex or pool.lookahead ~= lookahead then
        pool = self:BuildQuestPoolForPickup(stepIndex, lookahead)
    end

    return pool
end

--- Determines if a quest is part of a quest pool.
--- @param questID number The ID of the quest to check
--- @return boolean true if the quest is in a pool, false otherwise
function APR:IsQuestInPool(questID)
    local pool = self.QuestPool
    if not pool or not pool.ids or not questID then
        return false
    end
    return self:Contains(pool.ids, questID)
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
    local message = L["NOT_YET"] .. "\n\n" .. L["BYPASS_AUTO"]
    APR:PrintInfo(message)
    UIErrorsFrame:AddMessage(message, 1, 153 / 255, 102 / 255, 1, 5)
end

--- Add a quest to the watch list and super-track it for clarity.
function APR:TrackQuest(questID)
    C_QuestLog.AddQuestWatch(questID)            -- add to the quest log
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
                    if self:QpartPart_TrigTextMatch(step, tonumber(questId), objective.text) then
                        self:UpdateNextStep()
                        return
                    end
                end
            end
        end
    end
end

--- Advance QpartPart steps when the quest text from the UI matches trigger values.
--- @return boolean true if the step was advanced, false otherwise.
function APR:UpdateQpartPartWithQuesText(step, questText, questID)
    if self:QpartPart_TrigTextMatch(step, questID, questText) then
        self:UpdateNextStep()
        return true
    end
    return false
end

--- Compare a single TrigText value against an objective text.
-- Supports percentage thresholds ("50%"), ratio comparisons ("2/6"), and plain substring matching.
-- @param trigValue string The trigger value from the step (e.g. "1/3", "50%", or literal text).
-- @param objectiveText string The current objective text from the quest log.
-- @param currentPercent number|nil Optional progress bar percentage for threshold triggers.
-- @return boolean True if the objective text satisfies the trigger condition.
function APR:TrigTextValueMatch(trigValue, objectiveText, currentPercent)
    if not trigValue or not objectiveText then return false end

    local trigStr = tostring(trigValue)

    -- Percentage threshold: "50%"
    local wanted = trigStr:match("(%d+)%s*%%")
    if wanted and currentPercent then
        wanted = tonumber(wanted)
        if wanted and currentPercent >= wanted then
            return true
        end
    end

    -- Ratio comparison: "X/Y" matches when objective shows "A/Y" with A >= X
    local trigNum, trigDenom = trigStr:match("^(%d+)/(%d+)$")
    if trigNum and trigDenom then
        trigNum = tonumber(trigNum)
        trigDenom = tonumber(trigDenom)
        for currentNum, currentDenom in tostring(objectiveText):gmatch("(%d+)/(%d+)") do
            if tonumber(currentDenom) == trigDenom and tonumber(currentNum) >= trigNum then
                return true
            end
        end
    end

    -- Plain substring match
    return self:ContainsText(objectiveText, trigValue)
end

--- Checks if the provided objective text matches the trigger text for a specific quest part.
-- @param step The current step or stage in the quest sequence.
-- @param questID The unique identifier for the quest.
-- @param objectiveText The text of the quest objective to be matched.
-- @return boolean True if the objective text matches the trigger, false otherwise.
function APR:QpartPart_TrigTextMatch(step, questID, objectiveText)
    if not step then return false end

    local currentPercent = GetQuestProgressPercentSafe(questID)

    for key, value in pairs(step) do
        if string.match(key, "TrigText+") and value and objectiveText then
            if self:TrigTextValueMatch(value, objectiveText, currentPercent) then
                return true
            end
        end
    end

    return false
end

--- Retrieves the quest text associated with a specific progress bar objective.
-- @param questId number The unique identifier of the quest.
-- @param objectiveId number The identifier of the specific objective within the quest.
-- @return string The text description for the progress bar objective, or nil if not found.
function APR:GetQuestTextForProgressBar(questId, objectiveId)
    if not questId or not objectiveId then
        return
    end

    local questData = APR.ActiveQuests[questId]
    if not questData then
        return
    end

    local objective = questData.objectives[objectiveId]
    if not objective then
        return
    end

    local checkpbar = C_QuestLog.GetQuestObjectives(questId)
    local questText = objective.text
    if not string.find(questText, "%d") and checkpbar and checkpbar[objectiveId] and checkpbar[objectiveId].type == "progressbar" then
        local progress = GetQuestProgressPercentSafe(questId)
        if progress then
            questText = questText .. " (" .. progress .. "%)"
        end
    end
    return questText
end
