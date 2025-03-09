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
        RouteCompleted = L["ROUTE_COMPLETED"]
    }

    for key, _ in pairs(step) do
        if stepMappings[key] then
            return stepMappings[key], key
        end
    end

    return ''
end

function APR:IsQuestCompletedOnAccount(questIds)
    if not questIds or #questIds == 0 then
        return false
    end
    for i = 1, #questIds do
        if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questIds[i]) then
            return true
        end
    end

    return false
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

    while true do
        userMapData[activeMap] = userMapData[activeMap] - 1
        if userMapData[activeMap] <= 0 then
            userMapData[activeMap] = 1
            break
        end
        local step = questStepList[userMapData[activeMap]]

        if not (APR:StepFilterQuestHandler(step) or step.Waypoint) then
            break
        end
    end

    -- Update the quest and step
    self:UpdateQuestAndStep()
end

function APR:GetTotalSteps(route)
    route = route or APR.ActiveRoute
    local stepIndex = 0
    for id, step in pairs(APR.RouteQuestStepList[route] or {}) do
        -- Hide step for Faction, Race, Class, Achievement,...
        if APR:StepFilterQoL(step) then
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
    local routeZoneMapIDs, mapid, routeName, expansion = APR.transport:GetCurrentRouteMapIDsAndName()
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

    -- 1 - check if you are in the zone step or a direct child of zone step
    if step and APR:Contains(mapIDs, step.Zone) then
        return true
    end

    -- 2 - check if the zone step is in the zones for this route
    if step and APR:Contains(routeZoneMapIDs, step.Zone) then
        return true
    elseif parentContinentMapID == 2274 then -- handle tww zone for isle of dorn
        return false
    end

    -- 3 - check if your current current zone is in the zones for this route
    for _, mapID in ipairs(mapIDs) do
        if APR:Contains(routeZoneMapIDs, mapID) then
            return true
        end
    end

    -- 4 -  handle other case if like when you have in cave, building with diff mapID
    if parentContinentMapID then
        local childrenMap = C_Map.GetMapChildrenInfo(parentContinentMapID)
        if not childrenMap then
            return false
        end

        for _, map in ipairs(childrenMap) do
            if APR:Contains(routeZoneMapIDs, map.mapID) or (step and step.Zone == map.mapID) then
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

function APR:StepFilterQuestHandler(step)
    return (step.Faction and step.Faction ~= APR.Faction) or
        (step.Race and not tContains(step.Race, APR.Race)) or
        (step.Gender and step.Gender ~= APR.Gender) or
        (step.Class and not tContains(step.Class, APR.ClassName)) or
        (step.HasAchievement and not APR:HasAchievement(step.HasAchievement)) or
        (step.DontHaveAchievement and APR:HasAchievement(step.DontHaveAchievement)) or
        (step.HasAura and not APR:HasAura(step.HasAura)) or
        (step.DontHaveAura and APR:HasAura(step.DontHaveAura)) or
        (step.HasSpell and not IsSpellKnown(step.HasSpell)) or
        (step.IsQuestCompletedOnAccount and not APR:IsQuestCompletedOnAccount(step.IsQuestCompletedOnAccount)) or
        (step.IsQuestUncompletedOnAccount and APR:IsQuestCompletedOnAccount(step.IsQuestUncompletedOnAccount))
end

function APR:StepFilterQoL(step)
    return (not step.Faction or step.Faction == APR.Faction) and
        (not step.Race or tContains(step.Race, APR.Race)) and
        (not step.Gender or step.Gender == APR.Gender) and
        (not step.Class or tContains(step.Class, APR.ClassName)) and
        (not step.HasAchievement or APR:HasAchievement(step.HasAchievement)) and
        (not step.DontHaveAchievement or not APR:HasAchievement(step.DontHaveAchievement)) and
        (not step.HasAura or APR:HasAura(step.HasAura)) and
        (not step.DontHaveAura or not APR:HasAura(step.DontHaveAura)) and
        (not step.HasSpell or IsSpellKnown(step.HasSpell)) and
        (not step.IsQuestCompletedOnAccount or APR:IsQuestCompletedOnAccount(step.IsQuestCompletedOnAccount)) and
        (not step.IsQuestUncompletedOnAccount or not APR:IsQuestCompletedOnAccount(step.IsQuestUncompletedOnAccount))
end

--- Get Route zone mapID and name
---@return Array<number> routeZoneMapIDs MapIDs list of the mapid for the route
---@return number mapID  the main mapid for the route
---@return string routeFileName Route File Name
---@return string expansion expansion name
function APR:GetRouteMapIDsAndName(targetedRoute)
    for expansion, routeList in pairs(APR.RouteList) do
        for routeFileName, routeName in pairs(routeList) do
            if routeName == targetedRoute then
                local mapID = string.match(routeFileName, "^(.-)-")
                return APR.ZonesData.ExtensionRouteMaps[APR.Faction][expansion] or {}, tonumber(mapID, 10),
                    routeFileName, expansion
            end
        end
    end
    return nil, 0, '', ''
end

function APR:CheckRouteChanges(route)
    local currentRoute = route or APR.ActiveRoute or ''
    local savedTotalSteps = APRData[APR.PlayerID][currentRoute .. '-TotalSteps']
    local currentTotalSteps = APR:GetTotalSteps(currentRoute)
    local _, currentRouteName = next(APRCustomPath[APR.PlayerID])

    if currentRouteName and not APR.RouteQuestStepList[currentRoute] then
        APR.questionDialog:CreateMandatoryAction(
            L["ROUTE_DELETED_NEED_RESET"],
            function()
                APRZoneCompleted[APR.PlayerID][currentRoute] = nil
                APRData[APR.PlayerID][currentRoute .. '-SkippedStep'] = nill
                APRData[APR.PlayerID][currentRoute .. '-TotalSteps'] = nil
                APRData[APR.PlayerID][currentRoute] = nil

                APR.command:SlashCmd('route')
                APRCustomPath[APR.PlayerID] = {}
                APR.routeconfig:SendMessage("APR_Custom_Path_Update")
            end
        )
    elseif savedTotalSteps ~= currentTotalSteps then
        APR.questionDialog:CreateMandatoryAction(
            L["ROUTE_UPDATED_NEED_RESET"],
            function()
                APRData[APR.PlayerID][currentRoute] = 1
                APRData[APR.PlayerID][currentRoute .. '-SkippedStep'] = 0
                if currentRoute == APR.ActiveRoute then
                    APR.transport:GetMeToRightZone()
                    APR:PrintInfo(L["RESET_ROUTE"])
                end
            end
        )
    end
end

-- Check is the current route is up to date
function APR:CheckCurrentRouteUpToDate(routeName)
    if APR.version ~= APR.settings.profile.lastRecordedVersion then
        -- //TODO :  To be removed in the next version (v4.10.0 or v5.0.0)
        if string.match(APR.settings.profile.lastRecordedVersion, "^v4%.[8-9]%.[0-9]+$") then
            for route, _ in pairs(APRZoneCompleted[APR.PlayerID]) do
                if string.find(route, "Undermine") then
                    local _, _, routeName, _ = APR:GetRouteMapIDsAndName(route)
                    local currentTotalSteps = APR:GetTotalSteps(routeName)
                    if APRData[APR.PlayerID][routeName] < currentTotalSteps then
                        APRZoneCompleted[APR.PlayerID][route] = nil
                    end
                end
            end
        end
        APR:CheckRouteChanges(routeName)
        APR.settings.profile.lastRecordedVersion = APR.version
    end
end
