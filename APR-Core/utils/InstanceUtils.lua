-- Decides when guide UI is allowed in instances and manages the one-time character preference prompt.
-- An explicit InstanceQuest step can keep the guide visible in party/raid content.

local partyRaidTypes = {
    party = true,
    raid = true,
}

local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local hiddenInstanceTypes = {
    pvp = true,
    arena = true,
}

local function HasActiveRoute()
    return APR.ActiveRoute and APRData and APRData[APR.PlayerID] and APRData[APR.PlayerID][APR.ActiveRoute]
end

function APR:RefreshInstanceUIVisibility()
    if self.currentStep and self.currentStep.RefreshCurrentStepFrameAnchor then
        self.currentStep:RefreshCurrentStepFrameAnchor()
    end

    if self.fillersFrame and self.fillersFrame.RefreshFillersFrame then
        self.fillersFrame:RefreshFillersFrame(true)
    end

    if self.questOrderList and self.questOrderList.RefreshFrameAnchor then
        self.questOrderList:RefreshFrameAnchor()
    end
end

function APR:MaybePromptInstanceUIPreference()
    local profile = self:GetSettingsProfile()
    local charDB = APR:GetCharacterSettings()
    if not profile or not charDB or charDB.instanceUiPromptShown then
        return
    end

    local isInstance, instanceType = IsInInstance()
    if not isInstance or not partyRaidTypes[instanceType] then
        return
    end

    if not HasActiveRoute() then
        return
    end

    local step = APR:GetCurrentStep()
    if step and step.InstanceQuest then
        return
    end

    charDB.instanceUiPromptShown = true

    self.questionDialog:CreateQuestionPopup(
        "APR_INSTANCE_UI_PREFERENCE",
        L["INSTANCE_UI_PROMPT"],
        function()
            profile.forceHideUiInPartyRaid = false
            APR:RefreshInstanceUIVisibility()
        end,
        function()
            profile.forceHideUiInPartyRaid = true
            APR:RefreshInstanceUIVisibility()
        end
    )
end

function APR:IsInstanceWithUI()
    local isInstance, instanceType = IsInInstance()
    if not isInstance then
        return true
    end

    if hiddenInstanceTypes[instanceType] then
        return false
    end

    if partyRaidTypes[instanceType] then
        local step = APR:GetCurrentStep()
        if step and step.InstanceQuest then
            return true
        end

        if not HasActiveRoute() then
            return false
        end

        local profile = self:GetSettingsProfile()
        return not (profile and profile.forceHideUiInPartyRaid)
    end

    return true
end

function APR:IsScenarioInstance()
    local _, instanceType = IsInInstance()
    return instanceType == "scenario"
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
