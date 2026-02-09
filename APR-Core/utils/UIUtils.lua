--[[
    UI-related helpers and lightweight cosmetic utilities.
    Keeping them isolated prevents the base Utils.lua from mixing display logic with technical helpers.
]]

--- Performs the "Love" action for the APR module.
-- Updates APR color scheme for Saint Valentin (Feb 14th).
function APR:Love()
    local currentDate = C_DateAndTime.GetCurrentCalendarTime()
    if currentDate.month == 2 and currentDate.monthDay == 14 then
        APR.Color.blue = APR.Color.pink
        APR.Color.yellow = APR.Color.pink
        self.loveColorsPending = true
        self:ApplyLoveColors()
    end
end

-- Apply Love day color overrides to live widgets
function APR:ApplyLoveColors()
    if not self.loveColorsPending then
        return
    end

    local profile = APR.settings and APR.settings.profile
    if not profile then
        return
    end

    local pink = APR.Color.pink or { 1, 0, 1, 1 }
    local function copyWithAlpha(existing)
        local alpha = (existing and existing[4]) or 1
        return { pink[1], pink[2], pink[3], alpha }
    end

    profile.afkBarColor = copyWithAlpha(profile.afkBarColor)
    profile.currentStepProgressBarColor = copyWithAlpha(profile.currentStepProgressBarColor)

    if APR.AFK and APR.AFK.UpdateBarColor then
        APR.AFK:UpdateBarColor()
    end
    if APR.currentStep and APR.currentStep.UpdateProgressBarColor then
        APR.currentStep:UpdateProgressBarColor()
    end

    self.loveColorsPending = false
end

function APR:getStatus()
    APR.settings:CloseSettings()
    APR:showStatusReport()
end

---------------------------------------------------------------------------------------
---------------------------- Frame Management Utilities ------------------------------
---------------------------------------------------------------------------------------

--- Check if frames should be hidden based on various conditions
--- Centralizes frame hiding logic to avoid duplication across multiple frame modules
---@return boolean true if frames should be hidden
function APR:ShouldHideFrames()
    return not self.settings.profile.currentStepShow or
        not self.settings.profile.enableAddon or
        C_PetBattles.IsInBattle() or
        not self:IsInstanceWithUI()
end

--- Check if AFK frame is visible, active (timer running), and should snap
--- Implements proper state verification for safe anchor frame selection
---@return boolean true if AFK frame should be used as anchor
function APR:IsAFKFrameActiveShouldSnap()
    -- Quick exit if AFK module or settings not loaded
    if not self.AFK or not self.settings or not self.settings.profile then
        return false
    end

    -- Check if snapping is enabled in settings
    if not self.settings.profile.afkSnapToCurrentStep then
        return false
    end

    -- Check if AFK frame exists and is shown
    local afkFrame = _G.AfkFrameScreen
    if not afkFrame or not afkFrame:IsShown() then
        return false
    end

    -- Check if AFK timer is actually active (fake timer)
    if not self.AFK.fakeTimerActive then
        return false
    end

    return true
end

--- Get the proper snap anchor frame implementing the snap hierarchy
--- Other frames can anchor to this in order: Fillers > AFK > CurrentStep
--- FillersFrame calls with excludeFillers=true to avoid anchoring to itself
---@param excludeFillers boolean|nil If true, skip Fillers in the hierarchy (used by FillersFrame)
---@return table|nil anchorFrame The frame to anchor to, or nil if unavailable
---@return number|nil anchorHeight Height of the anchor frame, or nil if unavailable
function APR:GetSnapAnchorFrame(excludeFillers)
    -- Default to CurrentStep panel
    local currentStepPanel = _G.CurrentStepScreenPanel
    if not currentStepPanel or not currentStepPanel:IsShown() then
        return nil, nil
    end

    -- Hierarchy: Fillers (highest, optional) -> AFK (medium) -> CurrentStep (fallback)

    -- 1. Check Fillers frame (highest priority, unless explicitly excluded)
    if not excludeFillers and self.fillersFrame and self.settings and self.settings.profile then
        local fillersFrame = self.fillersFrame.Frame
        if fillersFrame and fillersFrame:IsShown() and self.settings.profile.fillersFrameSnapToCurrentStep then
            return fillersFrame, fillersFrame:GetHeight()
        end
    end

    -- 2. Check AFK frame (medium priority)
    if self:IsAFKFrameActiveShouldSnap() then
        local afkFrame = _G.AfkFrameScreen
        return afkFrame, afkFrame:GetHeight()
    end

    -- 3. Default to CurrentStep frame (always available as fallback)
    local contentHeight = (self.currentStep and self.currentStep.GetContentHeight) and
        self.currentStep:GetContentHeight(false) or 0

    if not contentHeight or contentHeight <= 0 then
        contentHeight = currentStepPanel:GetHeight() or 300
    end

    return currentStepPanel, contentHeight
end
