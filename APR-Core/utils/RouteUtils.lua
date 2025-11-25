local L = LibStub("AceLocale-3.0"):GetLocale("APR")

function APR:ResetRoute(targetedRoute)
    APR:Debug("Function: APR:ResetRoute()", targetedRoute)
    APRData[APR.PlayerID][targetedRoute] = 1
    APRData[APR.PlayerID][targetedRoute .. '-SkippedStep'] = 0
    APR:GetTotalSteps(targetedRoute)
    APR.transport:GetMeToRightZone()
    APR:PrintInfo(L["RESET_ROUTE"])
end

function APR:UpdateMapId()
    APR:Debug("Function: APR:UpdateMapId()")
    APR:OverrideRouteData() -- Lumbermill Wod route
    APR.transport:GetMeToRightZone()
end

--- Evaluate if a step should be skipped based on filters (race, class, achievements...).
-- Step filters remain centralized to avoid duplicating the skip counter logic elsewhere.
function APR:SkipStepCondition(step)
    if APR:StepFilterQuestHandler(step) then
        APRData[APR.PlayerID][APR.ActiveRoute .. '-SkippedStep'] = (APRData[APR.PlayerID]
            [APR.ActiveRoute .. '-SkippedStep'] or 0) + 1
        APR:UpdateNextStep()
        return true
    end
    return false
end

--- Count the number of visible steps for a route, optionally caching the total for reuse.
function APR:GetTotalSteps(route, updateTotal)
    route = route or APR.ActiveRoute
    updateTotal = updateTotal == nil -- default to true if not specified
    local stepIndex = 0
    for _, step in pairs(APR.RouteQuestStepList[route] or {}) do
        -- Hide step for Faction, Race, Class, Achievement,...
        if APR:StepFilterQoL(step) then
            stepIndex = stepIndex + 1
        end
    end
    if updateTotal then
        APRData[APR.PlayerID][route .. '-TotalSteps'] = stepIndex
    end
    return stepIndex
end

--- Decide if the player is currently in a zone relevant to the active route.
-- This short-circuits navigation helpers when the character is far away.
function APR:CheckIsInRouteZone()
    APR:Debug("Function: APR step helper- CheckIsInRouteZone()")
    if not APR.ActiveRoute then
        return
    end
    local routeZoneMapIDs, mapid = APR:GetCurrentRouteMapIDsAndName()
    local parentContinentMapID = APR:GetPlayerParentMapID(Enum.UIMapType.Continent)
    local parenttMapID = APR:GetPlayerParentMapID()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local step = self:GetStep(APR.ActiveRoute and APRData[APR.PlayerID][APR.ActiveRoute] or nil)
    if not currentMapID or not step then
        return false
    end
    local isSameContinent = APR.transport:IsSameContinent(step.Zone or mapid)
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

--- Helper for routes with branch-specific data (e.g., Lumbermill versus other choices).
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

--- Add custom routes stored in saved variables to the live route table.
function APR:LoadCustomRoutes()
    for name, steps in pairs(APRData.CustomRoute) do
        APR.RouteQuestStepList[name] = steps
        APR.RouteList.Custom[name] = name:match("%d+-(.*)")
    end
end

--- Evaluate skip/visibility conditions for a step.
function APR:StepFilterQuestHandler(step)
    return (step.Faction and step.Faction ~= APR.Faction) or
        (step.Race and not tContains(step.Race, APR.Race)) or
        (step.Gender and step.Gender ~= APR.Gender) or
        (step.Class and not tContains(step.Class, APR.ClassName)) or
        (step.HasAchievement and not APR:HasAchievement(step.HasAchievement)) or
        (step.DontHaveAchievement and APR:HasAchievement(step.DontHaveAchievement)) or
        (step.HasAura and not APR:HasAura(step.HasAura)) or
        (step.DontHaveAura and APR:HasAura(step.DontHaveAura)) or
        (step.HasSpell and not APR:IsSpellKnown(step.HasSpell)) or
        (step.IsOneOfQuestsCompleted and not APR:IsOneOfQuestsCompleted(step.IsOneOfQuestsCompleted)) or
        (step.IsOneOfQuestsUncompleted and APR:IsOneOfQuestsCompleted(step.IsOneOfQuestsUncompleted)) or
        (step.IsOneOfQuestsCompletedOnAccount and not APR:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsCompletedOnAccount))
        or
        (step.IsOneOfQuestsUncompletedOnAccount and APR:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsUncompletedOnAccount))
        or
        (step.IsQuestsCompleted and not APR:IsQuestsCompleted(step.IsQuestsCompleted)) or
        (step.IsQuestsUncompleted and APR:IsQuestsCompleted(step.IsQuestsUncompleted)) or
        (step.IsQuestsCompletedOnAccount and not APR:IsQuestsCompletedOnAccount(step.IsQuestsCompletedOnAccount)) or
        (step.IsQuestsUncompletedOnAccount and APR:IsQuestsCompletedOnAccount(step.IsQuestsUncompletedOnAccount))
end

--- Quality-of-life variant of the step filter that returns true when the step should be shown.
function APR:StepFilterQoL(step)
    return (not step.Faction or step.Faction == APR.Faction) and
        (not step.Race or tContains(step.Race, APR.Race)) and
        (not step.Gender or step.Gender == APR.Gender) and
        (not step.Class or tContains(step.Class, APR.ClassName)) and
        (not step.HasAchievement or APR:HasAchievement(step.HasAchievement)) and
        (not step.DontHaveAchievement or not APR:HasAchievement(step.DontHaveAchievement)) and
        (not step.HasAura or APR:HasAura(step.HasAura)) and
        (not step.DontHaveAura or not APR:HasAura(step.DontHaveAura)) and
        (not step.HasSpell or APR:IsSpellKnown(step.HasSpell)) and
        (not step.IsOneOfQuestsCompleted or APR:IsOneOfQuestsCompleted(step.IsOneOfQuestsCompleted)) and
        (not step.IsOneOfQuestsUncompleted or not APR:IsOneOfQuestsCompleted(step.IsOneOfQuestsUncompleted)) and
        (not step.IsOneOfQuestsCompletedOnAccount or APR:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsCompletedOnAccount))
        and
        (not step.IsOneOfQuestsUncompletedOnAccount or not APR:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsUncompletedOnAccount))
        and
        (not step.IsQuestsCompleted or APR:IsQuestsCompleted(step.IsQuestsCompleted)) and
        (not step.IsQuestsUncompleted or not APR:IsQuestsCompleted(step.IsQuestsUncompleted)) and
        (not step.IsQuestsCompletedOnAccount or APR:IsQuestsCompletedOnAccount(step.IsQuestsCompletedOnAccount)) and
        (not step.IsQuestsUncompletedOnAccount or not APR:IsQuestsCompletedOnAccount(step.IsQuestsUncompletedOnAccount))
end

--- Get Route zone mapID and name
---@return Array<number> routeZoneMapIDs MapIDs list of the mapid for the route
---@return number mapID  the main mapid for the route
---@return string routeFileName Route File Name
---@return string expansion expansion name
function APR:GetRouteMapIDsAndName(targetedRoute)
    if not targetedRoute or targetedRoute == '' then
        return nil, 0, '', ''
    end

    for expansion, routeList in pairs(APR.RouteList) do
        for routeFileName, routeName in pairs(routeList) do
            if routeName == targetedRoute or routeFileName == targetedRoute then
                local mapID = string.match(routeFileName, "^(.-)-")
                return APR.ZonesData.ExtensionRouteMaps[APR.Faction][expansion] or {}, tonumber(mapID, 10),
                    routeFileName, expansion
            end
        end
    end
    return nil, 0, '', ''
end

--- Get Current Route zone mapID and name
---@return Array<number> routeZoneMapIDs MapIDs list of the mapid for the route
---@return number mapID  the main mapid for the route
---@return string routeFileName Route File Name
---@return string expansion expansion name
function APR:GetCurrentRouteMapIDsAndName()
    APR:Debug("APR.transport:GetRouteMapIDAndName")

    if not APRCustomPath or not APRCustomPath[APR.PlayerID] then
        APR:PrintError('No APRCustomPath')
        return nil, 0, '', ''
    end
    -- Get the current Route wanted MapIDs and Route File
    local _, currentRouteName = next(APRCustomPath[APR.PlayerID])
    local routeZoneMapIDs, mapID, routeFileName, expansion = APR:GetRouteMapIDsAndName(currentRouteName)

    -- Clean up invalid saved entries so the current step frame can show content.
    if routeFileName == '' then
        APR:Debug("APR:GetCurrentRouteMapIDsAndName - invalid route in custom path", currentRouteName)
        table.remove(APRCustomPath[APR.PlayerID], 1)
        APR.routeconfig:CheckIsCustomPathEmpty()
        return nil, 0, '', ''
    end

    -- 1) Pre-escape: Are we currently in an instance? mapID (instance mapID) = 0
    if C_Map.GetBestMapForUnit("player") then
        -- 2) Build a list of default zone IDs for the detected expansion
        -- for ex if we use "The root", we return dragon isles map IDs
        if APR.CFrame:GetActiveRouteMainMapID() == 0 then
            mapID = APR.CFrame:GetActiveRouteMainMapID()
        end
        return APR.ZonesData.ExtensionRouteMaps[APR.Faction][expansion] or {}, mapID, routeFileName, expansion
    end
    return nil, 0, '', ''
end

--- Resolve a route file name into a friendly display name.
function APR:GetRouteDisplayName(routeFileName)
    local routeName = nil
    for _, routeList in pairs(APR.RouteList) do
        for key, value in pairs(routeList) do
            if key == routeFileName then
                routeName = value
            end
        end
    end
    return routeName
end

--- Clear all saved state for a route.
function APR:ClearSavedRouteData(routeFileName)
    local playerData = APRData[APR.PlayerID]
    playerData[routeFileName] = nil
    playerData[routeFileName .. '-TotalSteps'] = nil
    playerData[routeFileName .. '-SkippedStep'] = nil
    APRCompletedRoutes[APR.PlayerID][routeFileName] = nil
end

--- Compare saved step totals and signatures to the live route to detect changes.
function APR:CheckRouteChanges(route)
    local routeFileName
    local playerData = APRData[APR.PlayerID]
    local routeSignatures = APR.settings.profile.routeSignature
    if not routeSignatures then
        routeSignatures = {}
        APR.settings.profile.routeSignature = routeSignatures
    end
    local completedRoutes = APRCompletedRoutes[APR.PlayerID]
    local trackedRoutes = {}

    -- 0) Optionally constrain the check to a single route
    if route then
        routeFileName = route
    end

    -- 1) Record the active route and any completed routes so we can check them later
    if APR.ActiveRoute then
        trackedRoutes[APR.ActiveRoute] = true
    end

    -- 2) Add routes listed as completed (display names) by resolving their file names
    for routeName in pairs(completedRoutes) do
        local _, _, resolvedRouteFileName = APR:GetRouteMapIDsAndName(routeName)
        if resolvedRouteFileName and resolvedRouteFileName ~= '' then
            trackedRoutes[resolvedRouteFileName] = true
        end
    end

    -- 3) If a specific currentRoute was passed in, include it
    if routeFileName then
        trackedRoutes[routeFileName] = true
    end

    -- 4) Build a lookup for the player's custom paths (APRCustomPath)
    local customPathLookup = {}
    if APRCustomPath[APR.PlayerID] then
        for _, routeName in ipairs(APRCustomPath[APR.PlayerID]) do
            customPathLookup[routeName] = true
        end
    end

    local completedResetNames = {}
    local customPathResetNames = {}
    local previousVersion = APR.settings.profile.lastRecordedVersion

    -- 5) For each tracked route, compare saved data with the live route definition
    for trackedRoute in pairs(trackedRoutes) do
        local displayName = APR:GetRouteDisplayName(trackedRoute) or trackedRoute

        -- hasSavedProgress: true if any saved state exists for this route
        local hasSavedProgress = playerData[trackedRoute] ~= nil
            or playerData[trackedRoute .. '-TotalSteps'] ~= nil
            or playerData[trackedRoute .. '-SkippedStep'] ~= nil
            or completedRoutes[displayName]

        if hasSavedProgress then
            local routeExists = APR.RouteQuestStepList[trackedRoute] ~= nil
            local savedTotal = playerData[trackedRoute .. '-TotalSteps']
            local currentTotal = routeExists and APR:GetTotalSteps(trackedRoute, false) or 0
            local savedSignature = routeSignatures[trackedRoute]
            local currentSignature = routeExists and APR:GetRouteSignature(trackedRoute) or nil
            local isCustomPath = customPathLookup[displayName]
            local wasCompleted = completedRoutes[displayName]

            local routeChanged = not routeExists
                or (savedTotal and savedTotal ~= currentTotal)
                or (savedSignature and currentSignature and savedSignature ~= currentSignature)

            -- When we upgrade versions without a stored signature, still refresh custom path/completed routes to avoid stale data
            if not routeChanged and not savedSignature and previousVersion and previousVersion ~= APR.version then
                routeChanged = isCustomPath or wasCompleted
            end

            if routeChanged then
                APR:ClearSavedRouteData(trackedRoute)
                routeSignatures[trackedRoute] = currentSignature

                if wasCompleted then
                    completedRoutes[displayName] = nil
                    table.insert(completedResetNames, displayName)
                end

                -- If it was a custom path, remember it to notify user/UI later
                if isCustomPath then
                    table.insert(customPathResetNames, displayName)
                end
            else
                routeSignatures[trackedRoute] = currentSignature
            end
        end
    end

    -- 6) If custom paths were reset, notify the user and send a config update message
    if #customPathResetNames > 0 then
        APR:PrintInfo(L["ROUTE_UPDATED_NEED_RESET"] .. ": " .. table.concat(customPathResetNames, ", "))
        if APR.routeconfig then
            APR.routeconfig:SendMessage("APR_Custom_Path_Update")
        end
    end

    -- 7) If completed routes were reset, inform the user
    if #completedResetNames > 0 then
        APR:PrintInfo(L["ROUTE_UPDATED_NEED_RESET"] .. ": " .. table.concat(completedResetNames, ", "))
    end

    -- 8) Record current addon version to detect upgrades later
    APR.settings.profile.lastRecordedVersion = APR.version
end

--- When resuming, make sure the tracked route is still valid.
function APR:CheckCurrentRouteUpToDate(currentRoute)
    local routeSignature = APR.settings.profile.routeSignature[currentRoute]
    local isCustomPath = APR:IsInCurrentPlayerCustomRoutesList(currentRoute)
    if not routeSignature then
        APR:CheckRouteChanges(currentRoute)
        return
    end

    local currentRouteSignature = APR:GetRouteSignature(currentRoute)
    if routeSignature ~= currentRouteSignature or isCustomPath then
        if not isCustomPath then
            APR.settings.profile.routeSignature[currentRoute] = currentRouteSignature
        end
        if APR.settings.profile.autoResetRoute then
            APR:ResetRoute(currentRoute)
        else
            APR:PrintInfo(L["ROUTE_UPDATED_NEED_RESET"])
            APR:CheckRouteChanges(currentRoute)
        end
    end
end
