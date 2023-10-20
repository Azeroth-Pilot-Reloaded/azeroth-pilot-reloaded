local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function GetStepString(step)
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

function HasAchievement(achievementID)
    local id, name, _, completed = _G.GetAchievementInfo(achievementID)
    return completed
end

function UpdateQuestAndStep()
    APR.BookingList["UpdateQuest"] = true
    APR.BookingList["UpdateStep"] = true
end

function UpdateNextQuest()
    APRData[APR.Realm][APR.Username][APR.ActiveMap] = APRData[APR.Realm][APR.Username][APR.ActiveMap] + 1
    APR.BookingList["UpdateQuest"] = true
end

function UpdateNextStep()
    APRData[APR.Realm][APR.Username][APR.ActiveMap] = APRData[APR.Realm][APR.Username][APR.ActiveMap] + 1
    APR.BookingList["UpdateStep"] = true
end

function NextQuestStep()
    APRData[APR.Realm][APR.Username][APR.ActiveMap] = APRData[APR.Realm][APR.Username][APR.ActiveMap] + 1
    UpdateQuestAndStep()
end

function PreviousQuestStep()
    local previous = true
    while previous do
        APRData[APR.Realm][APR.Username][APR.ActiveMap] = APRData[APR.Realm][APR.Username][APR.ActiveMap] - 1
        local steps = APR.QuestStepList[APR.ActiveMap][APRData[APR.Realm][APR.Username][APR.ActiveMap]]
        previous = false

        if (
                (steps["Faction"] and steps["Faction"] ~= APR.Faction) or
                (steps["Race"] and steps["Race"] ~= APR.Race) or
                (steps["Class"] and steps["Class"] ~= APR.ClassName) or
                (steps["HasAchievement"] and not _G.HasAchievement(steps["HasAchievement"])) or
                (steps["DontHaveAchievement"] and _G.HasAchievement(steps["DontHaveAchievement"]))
            ) then
            previous = true
        end
    end

    -- Update the quest and step
    UpdateQuestAndStep()
end
