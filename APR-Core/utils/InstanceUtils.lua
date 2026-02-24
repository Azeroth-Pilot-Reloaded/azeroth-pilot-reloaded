function APR:IsInstanceWithUI()
    local step = APR.ActiveRoute and self:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    local isInstance, instanceType = IsInInstance()
    local hideType = { "pvp", "arena" }

    if isInstance then
        if not tContains(hideType, instanceType) then
            return true
        end
        -- other instances need InstanceQuest flag for UI
        return (step and step.InstanceQuest) or false
    end

    return true
end

function APR:IsScenarioInstance()
    local isIntance, type = IsInInstance()
    return type == "scenario"
end

--- Check whether a scenario objective is already recorded so we do not double count progress.
function APR:ContainsScenarioStepCriteria(table, stepID, criteriaID, criteriaIndex)
    table = table or {}
    for _, v in ipairs(table) do
        if v.stepID == stepID and v.criteriaID == criteriaID and v.criteriaIndex == criteriaIndex then
            return true
        end
    end
    return false
end
