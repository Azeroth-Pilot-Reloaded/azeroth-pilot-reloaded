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
    end
end

function APR:getStatus()
    APR.settings:CloseSettings()
    APR:showStatusReport()
end
