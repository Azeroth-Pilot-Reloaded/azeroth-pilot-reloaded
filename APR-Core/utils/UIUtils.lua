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
