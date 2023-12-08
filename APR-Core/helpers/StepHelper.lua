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
            return stepMappings[key], key
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
    APRData[APR.Realm][APR.Username][APR.ActiveRoute] = APRData[APR.Realm][APR.Username][APR.ActiveRoute] + 1
    APR.BookingList["UpdateQuest"] = true
end

function UpdateNextStep()
    APRData[APR.Realm][APR.Username][APR.ActiveRoute] = APRData[APR.Realm][APR.Username][APR.ActiveRoute] + 1
    APR.BookingList["UpdateStep"] = true
end

function NextQuestStep()
    APRData[APR.Realm][APR.Username][APR.ActiveRoute] = APRData[APR.Realm][APR.Username][APR.ActiveRoute] + 1
    UpdateQuestAndStep()
end

function PreviousQuestStep()
    local userMapData = APRData[APR.Realm][APR.Username]
    local activeMap = APR.ActiveRoute
    local questStepList = APR.QuestStepList[activeMap]
    local faction = APR.Faction
    local race = APR.Race
    local className = APR.ClassName

    while true do
        userMapData[activeMap] = userMapData[activeMap] - 1
        local steps = questStepList[userMapData[activeMap]]

        if not ((steps["Faction"] and steps["Faction"] ~= faction) or
                (steps["Race"] and steps["Race"] ~= race) or
                (steps["Class"] and steps["Class"] ~= className) or
                (steps["HasAchievement"] and not _G.HasAchievement(steps["HasAchievement"])) or
                (steps["DontHaveAchievement"] and _G.HasAchievement(steps["DontHaveAchievement"])) or
                steps["CRange"]) then
            break
        end
    end

    -- Update the quest and step
    UpdateQuestAndStep()
end

function GetTotalSteps(route)
    route = route or APR.ActiveRoute
    local stepIndex = 0
    for id, step in pairs(APR.QuestStepList[route]) do
        -- Hide step for Faction, Race, Class, Achievement
        if (
                (not step.Faction or step.Faction == APR.Faction) and
                (not step.Race or step.Race == APR.Race) and
                (not step.Class or step.Class == APR.ClassName) and
                (not step.HasAchievement or _G.HasAchievement(step.HasAchievement)) and
                (not step.DontHaveAchievement or not _G.HasAchievement(step.DontHaveAchievement))
            ) then
            stepIndex = stepIndex + 1
        end
    end
    APRData[APR.Realm][APR.Username][route .. '-TotalSteps'] = stepIndex
    return stepIndex
end

function CheckIsInRouteZone()
    if APR.transport.GoToZone then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then
            return false
        end
        local parentMapID = C_Map.GetMapInfo(currentMapID).parentMapID
        local childrenMap = C_Map.GetMapChildrenInfo(parentMapID)
        if not childrenMap then
            if currentMapID == APR.transport.GoToZone then
                return true
            end
            return false
        end

        local isPresent = false
        for _, map in ipairs(childrenMap) do
            if map.mapID == APR.transport.GoToZone then
                isPresent = true
                break
            end
        end
        return isPresent
    end
    return true
end

function GetSteps(CurStep)
    if (CurStep and APR.QuestStepList and APR.QuestStepList[APR.ActiveRoute]) then
        return APR.QuestStepList[APR.ActiveRoute][CurStep]
    end
    return nil
end

function IsARouteQuest(questId)
    local steps = GetSteps(APRData[APR.Realm][APR.Username][APR.ActiveRoute])
    if (steps) then
        if Contains(steps["PickUp"], questId) or Contains(steps["PickUpDB"], questId) then
            return true
        end
    end
    return false
end

function IsPickupStep()
    local steps = GetSteps(APRData[APR.Realm][APR.Username][APR.ActiveRoute])
    if (steps) then
        if steps["PickUp"] or steps["PickUpDB"] then
            return true
        end
    end
    return false
end

function HasTaxiNode(nodeID)
    for id, name in pairs(APRTaxiNodes[APR.Username .. "-" .. APR.Realm]) do
        if id == nodeID then
            return true
        end
    end
    return false
end
