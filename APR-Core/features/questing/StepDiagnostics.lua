-- Explains observed waits from the current runtime snapshot without running the step dispatcher.
-- Missing quest data is distinct from an unfinished objective; generic actions retain their guide text.

function APR:DescribeStepWait()
    local function T(key, ...) return self:LocalizeUI(key, ...) end
    local profile = self:GetSettingsProfile()
    if not profile or not profile.enableAddon then return { T("PAUSED") } end
    if not self.ActiveRoute then return { T("NO_ROUTE") } end
    local step = self:PeekCurrentStep()
    if not step then return { T("STEP_DATA_PENDING") } end
    local reasons = {}
    if UnitIsDeadOrGhost("player") then reasons[#reasons + 1] = T("DEAD_PENDING") end
    if self.IsInRouteZone == false then reasons[#reasons + 1] = T("OUT_OF_ZONE") end
    local function questState(id, objective)
        if C_QuestLog.IsQuestFlaggedCompleted(id) then return end
        local quest = self.ActiveQuests and self.ActiveQuests[id]
        if not quest then
            reasons[#reasons + 1] = T(C_QuestLog.IsOnQuest(id) and "QUEST_DATA_PENDING" or "MISSING_QUEST", id)
        elseif objective then
            local data = quest.objectives and quest.objectives[objective]
            if not data then reasons[#reasons + 1] = T("QUEST_DATA_PENDING", id)
            elseif data.status ~= self.QUEST_STATUS.COMPLETE then
                reasons[#reasons + 1] = T("OBJECTIVE_PENDING", id .. " / " .. objective .. " — " .. (data.text or ""))
            end
        elseif step.Done then
            reasons[#reasons + 1] = T("TURNIN_PENDING", id)
        end
    end
    if step.QpartDB then
        -- The engine selects one alternative at runtime; don't diagnose every alternative as missing.
        local id
        for _, candidate in ipairs(step.QpartDB) do
            if C_QuestLog.IsQuestFlaggedCompleted(candidate) or self.ActiveQuests[candidate] then id = candidate; break end
        end
        if id then for _, objective in ipairs(step.Qpart[1] or {}) do questState(id, tonumber(objective)) end
        else reasons[#reasons + 1] = T("QUEST_ALTERNATIVE_PENDING") end
    elseif step.Qpart or step.QpartPart then
        for id, objectives in pairs(step.Qpart or step.QpartPart) do
            for _, objective in ipairs(objectives) do questState(tonumber(id), tonumber(objective)) end
        end
    elseif step.Done and not step.DoneDB then
        for _, id in ipairs(step.Done) do questState(id) end
    elseif step.PickUp and not step.PickUpDB then
        for _, id in ipairs(step.PickUp) do
            if not (self.ActiveQuests and self.ActiveQuests[id]) and not C_QuestLog.IsQuestFlaggedCompleted(id) then
                reasons[#reasons + 1] = T("PICKUP_PENDING", id)
            end
        end
    end
    if #reasons == 0 then reasons[1] = T("ACTION_PENDING") end
    local text, action = self:GetStepString(step)
    if text then reasons[#reasons + 1] = text end
    if InCombatLockdown() and (self.secureReconcilePending or self.skinRefreshPending) then
        reasons[#reasons + 1] = T("COMBAT_PENDING")
    end
    return reasons, action
end
