local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function APR:GetStepString(step)
    local stepMappings = {
        ExitTutorial = L["SKIP_TUTORIAL"],
        PickUp = L["PICK_UP_Q"],
        DropQuest = L["Q_DROP"],
        Qpart = L["Q_PART"],
        Treasure = L["GET_TREASURE"],
        Group = L["GROUP_Q"],
        Done = L["TURN_IN_Q"],
        Waypoint = L["RUN_WAYPOINT"],
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

function APR:HasAchievement(achievementID)
    local id, name, _, completed = _G.GetAchievementInfo(achievementID)
    return completed
end

function APR:HasAura(spellID)
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    return aura ~= nil
end

function APR:UpdateQuestAndStep()
    APR.BookingList["UpdateQuest"] = true
    APR.BookingList["UpdateStep"] = true
end

function APR:UpdateNextQuest()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    APR.BookingList["UpdateQuest"] = true
end

function APR:UpdateNextStep()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    APR.BookingList["UpdateStep"] = true
end

function APR:NextQuestStep()
    APRData[APR.PlayerID][APR.ActiveRoute] = APRData[APR.PlayerID][APR.ActiveRoute] + 1
    self:UpdateQuestAndStep()
end

function APR:PreviousQuestStep()
    local userMapData = APRData[APR.PlayerID]
    local activeMap = APR.ActiveRoute
    local questStepList = APR.RouteQuestStepList[activeMap]
    local faction = APR.Faction
    local race = APR.Race
    local gender = APR.Gender
    local className = APR.ClassName

    while true do
        userMapData[activeMap] = userMapData[activeMap] - 1
        local step = questStepList[userMapData[activeMap]]

        if not ((step.Faction and step.Faction ~= faction) or
                (step.Race and step.Race ~= race) or
                (step.Gender and step.Gender ~= gender) or
                (step.Class and step.Class ~= className) or
                (step.HasAchievement and not self:HasAchievement(step.HasAchievement)) or
                (step.DontHaveAchievement and self:HasAchievement(step.DontHaveAchievement)) or
                (step.HasAura and not self:HasAura(step.HasAura)) or
                (step.DontHaveAura and self:HasAura(step.DontHaveAura)) or
                step.Waypoint) then
            break
        end
    end

    -- Update the quest and step
    self:UpdateQuestAndStep()
end

function APR:GetTotalSteps(route)
    route = route or APR.ActiveRoute
    local stepIndex = 0
    for id, step in pairs(APR.RouteQuestStepList[route]) do
        -- Hide step for Faction, Race, Class, Achievement
        if (
                (not step.Faction or step.Faction == APR.Faction) and
                (not step.Race or step.Race == APR.Race) and
                (not step.Gender or step.Gender == APR.Gender) and
                (not step.Class or step.Class == APR.ClassName) and
                (not step.HasAchievement or self:HasAchievement(step.HasAchievement)) and
                (not step.DontHaveAchievement or not self:HasAchievement(step.DontHaveAchievement)) and
                (not step.HasAura or self:HasAura(step.HasAura)) and
                (not step.DontHaveAura or not self:HasAura(step.DontHaveAura))
            ) then
            stepIndex = stepIndex + 1
        end
    end
    APRData[APR.PlayerID][route .. '-TotalSteps'] = stepIndex
    return stepIndex
end

function APR:CheckIsInRouteZone()
    if (APR.settings.profile.debug) then
        print("Function: APR step helper- CheckIsInRouteZone()")
    end
    if not APR.ActiveRoute then
        return
    end
    local routeZoneMapIDs, mapid, routeName, expansion = APR.transport:GetRouteMapIDsAndName()
    local parentContinentMapID = APR:GetPlayerParentMapID(Enum.UIMapType.Continent)
    local parenttMapID = APR:GetPlayerParentMapID()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local step = self:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)
    if not currentMapID or not step then
        return false
    end
    local isSameContinent, nextContinent = APR.transport:IsSameContinent(step.Zone or mapid)
    if not isSameContinent then
        return false
    end

    local mapIDs = { parentContinentMapID, currentMapID, parenttMapID }

    if step and APR:Contains({ parentContinentMapID, currentMapID, parenttMapID }, step.Zone) then
        return true
    end

    for _, mapID in ipairs(mapIDs) do
        if APR:IsInExpansionRouteMaps(routeZoneMapIDs, mapID) then
            return true
        end
    end

    if parentContinentMapID then
        local childrenMap = C_Map.GetMapChildrenInfo(parentContinentMapID)
        if not childrenMap then
            return false
        end

        for _, map in ipairs(childrenMap) do
            if APR:IsInExpansionRouteMaps(routeZoneMapIDs, map.mapID) or (step and step.Zone == map.mapID) then
                return true
            end
        end
    end

    return false
end

function APR:GetStep(index)
    if (index and APR.RouteQuestStepList and APR.RouteQuestStepList[APR.ActiveRoute]) then
        return APR.RouteQuestStepList[APR.ActiveRoute][index]
    end
    return nil
end

function APR:IsARouteQuest(questId)
    local step = self:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    if (step) then
        if self:Contains(step.PickUp, questId) or self:Contains(step.PickUpDB, questId) then
            return true
        end
    end
    return false
end

function APR:IsPickupStep()
    local step = self:GetStep(APRData[APR.PlayerID][APR.ActiveRoute])
    if (step) then
        if step.PickUp or step.PickUpDB then
            return true
        end
    end
    return false
end

function APR:HasTaxiNode(nodeID)
    for id, name in pairs(APRTaxiNodes[APR.PlayerID]) do
        if id == nodeID then
            return true
        end
    end
    return false
end

function APR:OverrideRouteData()
    if APR.ActiveRoute and string.match(APR.ActiveRoute, "DesMephisto%-Gorgrond") then
        if C_QuestLog.IsQuestFlaggedCompleted(35049) then
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond"] = nil
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond"] = APR.RouteQuestStepList
                ["543-DesMephisto-Gorgrond-Lumbermill"]
        end
        if C_QuestLog.IsQuestFlaggedCompleted(34992) then
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond-p1"] = nil
            APR.RouteQuestStepList["543-DesMephisto-Gorgrond-p1"] = APR.RouteQuestStepList
                ["543-DesMephisto-Gorgrond-Lumbermill"]
        end
    end
end

function APR:GetTaxiNodeName(step)
    -- First, try to get the node name from the player's specific nodes
    local playerNodes = APRTaxiNodes[APR.PlayerID]
    if playerNodes and playerNodes[step.NodeID] then
        return playerNodes[step.NodeID]
    end

    -- Fallback to the name directly from the step object
    if step.Name then
        return step.Name
    end

    -- Check global faction nodes
    for _, factionNodes in pairs(APR.TaxiNodes) do
        for _, continentNode in pairs(factionNodes) do
            if continentNode[step.NodeID] then
                return continentNode[step.NodeID].Name
            end
        end
    end

    -- If no name found, return nil
    return nil
end

function APR:LoadCustomRoutes()
    for name, steps in pairs(APRData.CustomRoute) do
        APR.RouteQuestStepList[name] = steps
        APR.RouteList.Custom[name] = name:match("%d+-(.*)")
    end
end

function APR:MissingQuest(questId, objectiveId)
    local questTextToAdd
    questId = questId or UNKNOWN
    if APR:Contains(APR.BonusObj, questId) then
        questTextToAdd = L["DO_BONUS_OBJECTIVE"] .. ": " .. questId
    else
        questTextToAdd = L["ERROR"] .. " - " .. L["MISSING_Q"] .. ": " .. questId
    end
    APR.currentStep:AddQuestSteps(questId, questTextToAdd, objectiveId, false, true)
end

function APR:UpdateQpartPart()
    local step = self:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil) or {}
    local IdList = step.QpartPart or {}
    for questId, objectives in pairs(IdList) do
        for _, objectiveId in ipairs(objectives) do
            local qid = questId .. "-" .. objectiveId
            local questText = APR.ActiveQuests[qid]
            if not questText then return end

            for key, value in pairs(step) do
                if string.match(key, "TrigText+") then
                    if value and string.find(questText, value) then
                        self:UpdateNextStep()
                        return
                    end
                end
            end
        end
    end
end

function APR:UpdateQpartPartWithQuesText(step, questText)
    for key, value in pairs(step) do
        if string.match(key, "TrigText+") then
            if value and questText and string.find(questText, value) then
                self:UpdateNextStep()
                return
            end
        end
    end
end

function APR:TrackQuest(questID)
    C_QuestLog.AddQuestWatch(questID)            -- to add to the quest log
    C_SuperTrack.SetSuperTrackedQuestID(questID) -- to serlect the quest to highlight
end

function APR:IsCampaignQuest(questID)
    local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if not questIndex then return false end
    local questInfo = C_QuestLog.GetInfo(questIndex)
    return questInfo and questInfo.campaignID ~= nil
end
