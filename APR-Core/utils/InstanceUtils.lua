--[[
    Instance and scenario helpers to keep route logic aware of the player's environment.
    Grouped separately so Utils.lua remains focused on technical helpers.
]]

--- Decide whether the addon UI should remain visible inside an instance.
-- We intentionally rely on the current step metadata to let route authors opt-in per step.
function APR:IsInstanceWithUI()
    local step = APR.ActiveRoute and self:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    local isInstance, instanceType = IsInInstance()

    if isInstance then
        return (step and step.InstanceQuest) or false
    end

    return true
end

function APR:IsScenarioInstance()
    local isIntance, type = IsInInstance()
    return isIntance and type == "scenario"
end

--- Check whether a scenario objective is already recorded so we do not double count progress.
function APR:ContainsScenarioStepCriteria(table, stepID, criteriaID, criteriaIndex)
    if not table then return false end
    for _, v in ipairs(table) do
        if v.stepID == stepID and v.criteriaID == criteriaID and v.criteriaIndex == criteriaIndex then
            return true
        end
    end
    return false
end
