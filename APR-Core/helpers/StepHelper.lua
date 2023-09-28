local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function APR:GetStepString(step)
    local stepMappings = {
        ExitTutorial = L["SKIP_TUTORIAL"],
        PickUp = L["PICK_UP_Q"],
        DropQuest = L["Q_DROP"],
        Qpart = L["Q_PART"],
        Treasure = L["GET_TREASURE"],
        QaskPopup = L["GROUP_Q"],
        Done = L["TURN_IN_Q"],
        CRange = L["RUN_WAYPOINT"],
        SetHS = L["SET_HEARTHSTONE"],
        UseHS = L["USE_HEARTHSTONE"],
        UseDalaHS = L["USE_DALARAN_HEARTHSTONE"],
        UseGarrisonHS = L["USE_GARRISON_HEARTHSTONE"],
        GetFP = L["GET_FLIGHTPATH"],
        UseFlightPath = L["USE_FLIGHTPATH"],
        WarMode = L["TURN_ON_WARMODE"],
        ZoneDoneSave = L["ROUTE_COMPLETED"]
    }

    for key, _ in pairs(step) do
        if stepMappings[key] then
            return stepMappings[key]
        end
    end

    return ''
end

-- function APR:GetStepQuestID(step)
--     local stepTypes = {
--         "ExitTutorial",
--         "PickUp",
--         "DropQuest",
--         "Qpart",
--         "Treasure",
--         "QaskPopup",
--         "Done",
--         "CRange",
--         "SetHS",
--         "UseHS",
--         "UseDalaHS",
--         "UseGarrisonHS",
--         "GetFP",
--         "UseFlightPath",
--         "WarMode",
--         "ZoneDoneSave"
--     }

--     for _, stepType in ipairs(stepTypes) do
--         if step[stepType] then
--             if type(step[stepType]) == "table" then
--                 -- local _, questID = next(
--                 return step[stepType][1]
--             else
--                 return step[stepType]
--             end
--         end
--     end
-- end
