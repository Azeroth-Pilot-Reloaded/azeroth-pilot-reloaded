local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.ConditionalRouteRegistry = {
    spec = {
        ArtifactWeapon = {
            prefix = "Artifact Weapon",
        },
    },

    class = { ... },
    race = { ... },
    covenant = { ... },
}

function APR:assignRoutes(routes)
    if not routes then return end

    if routes.expansion and routes.key and routes.label then
        APR.RouteList[routes.expansion][routes.key] = routes.label
    elseif type(routes) == "table" then
        for _, route in ipairs(routes) do
            if route.expansion and route.key and route.label then
                APR.RouteList[route.expansion][route.key] = route.label
            end
        end
    end
end

function APR:MergeExpansionRoutes(routesByExpansion)
    -- merge expansion route tables in APR.RouteList[expansion]
    for expansion, routes in pairs(routesByExpansion) do
        self.RouteList[expansion] = self.RouteList[expansion] or {}

        for routeKey, label in pairs(routes) do
            self.RouteList[expansion][routeKey] = label
        end
    end
end

function APR:ResetRoute(targetedRoute)
    self:Debug("Function: APR:ResetRoute()", targetedRoute)
    APRData[self.PlayerID][targetedRoute] = 1
    APRData[self.PlayerID][targetedRoute .. '-SkippedStep'] = 0
    self:GetTotalSteps(targetedRoute)
    APRData[self.PlayerID][targetedRoute .. '-RawTotalSteps'] = self:GetRawStepCount(targetedRoute)
    -- Force refresh: reset throttle for ResetRoute
    self.transport._routingForceRefresh = true
    if self.transport._routingThrottle then
        self.transport._routingThrottle.count = 0
    end
    self.transport:GetMeToRightZone()
    self:PrintInfo(L["RESET_ROUTE"])
end

function APR:UpdateMapId()
    self:Debug("Function: APR:UpdateMapId()")
    self:OverrideRouteData() -- Lumbermill Wod route
    self.transport:GetMeToRightZone()
end

--- Evaluate if a step should be skipped based on filters (race, class, achievements...).
-- Step filters remain centralized to avoid duplicating the skip counter logic elsewhere.
function APR:SkipStepCondition(step)
    if self:StepFilterQuestHandler(step) then
        APRData[self.PlayerID][self.ActiveRoute .. '-SkippedStep'] = (APRData[self.PlayerID]
            [self.ActiveRoute .. '-SkippedStep'] or 0) + 1
        self:UpdateNextStep()
        return true
    end
    return false
end

--- Count the number of visible steps for a route, optionally caching the total for reuse.
function APR:GetTotalSteps(route, updateTotal)
    route = route or self.ActiveRoute
    updateTotal = updateTotal == nil -- default to true if not specified
    local stepIndex = 0
    for _, step in pairs(self.RouteQuestStepList[route] or {}) do
        -- Hide step for Faction, Race, Class, Achievement,...
        if self:StepFilterQoL(step) then
            stepIndex = stepIndex + 1
        end
    end
    if updateTotal then
        APRData[self.PlayerID][route .. '-TotalSteps'] = stepIndex
    end
    return stepIndex
end

--- Return the raw (unfiltered) number of steps in a route definition.
--- This count only changes when the route file itself is modified, making it
--- safe for change-detection comparisons that must survive /reload and different
--- player states (quest log not yet synced, achievements, auras, etc.).
function APR:GetRawStepCount(route)
    local steps = self.RouteQuestStepList[route]
    if not steps then return 0 end
    return #steps
end

--- Calculate the number of skipped/filtered steps BEFORE a given step index.
-- This accounts for steps that are filtered out by QoL conditions (race, class, achievements...).
-- Waypoint steps are visible and actionable, so they are NOT excluded from the count.
-- @param route The route name (optional, defaults to active route)
-- @param beforeIndex The step index to calculate before (optional, defaults to current step)
-- @return number The count of filtered steps before the given index
function APR:CountSkippedStepsBefore(route, beforeIndex)
    route = route or self.ActiveRoute
    beforeIndex = beforeIndex or (APRData[self.PlayerID] and APRData[self.PlayerID][route]) or 1

    local skippedCount = 0
    local stepList = self.RouteQuestStepList[route]
    if stepList then
        for i = 1, math.min(beforeIndex - 1, #stepList) do
            local step = stepList[i]
            -- Count only steps that are filtered (should be skipped/hidden)
            if self:StepFilterQuestHandler(step) then
                skippedCount = skippedCount + 1
            end
        end
    end
    return skippedCount
end

--- Decide if the player is currently in a zone relevant to the active route.
-- This short-circuits navigation helpers when the character is far away.
function APR:CheckIsInRouteZone()
    self:Debug("Function: APR step helper- CheckIsInRouteZone()")

    -- Throttle: avoid recalculating if already checked in last 0.1 seconds
    local now = GetTime()
    if self._lastRouteZoneCheck and (now - self._lastRouteZoneCheck) < 0.1 then
        return self._lastRouteZoneResult or false
    end

    -- Precheck: route and step validity
    if not self.ActiveRoute then
        self._lastRouteZoneCheck = now
        self._lastRouteZoneResult = false
        return false
    end

    local step = self:GetStep(self.ActiveRoute and APRData[self.PlayerID][self.ActiveRoute] or nil)
    if not step then
        self._lastRouteZoneCheck = now
        self._lastRouteZoneResult = false
        return false
    end

    local routeZoneMapIDs, fallbackMapID, routeName, expansion = self:GetCurrentRouteMapIDsAndName()

    -- Get step zones
    local stepZones = self:GetStepZoneList(step, fallbackMapID)
    if #stepZones == 0 then
        self._lastRouteZoneCheck = now
        self._lastRouteZoneResult = false
        return false
    end

    -- Handle special zone exceptions (Isle of Dorn, etc)
    local exception = self:GetZoneException(self:ResolvePlayerZoneContext().current)
    if exception then
        self:DebugZoneDetection("Zone Exception",
            self:ResolvePlayerZoneContext(), stepZones, true)
        self._lastRouteZoneCheck = now
        self._lastRouteZoneResult = true
        return true
    end

    -- Resolve player zone context (with caching)
    local playerContext = self:ResolvePlayerZoneContext()

    self:PrintZoneDebug("=== CheckIsInRouteZone START ===")
    self:PrintZoneDebug("StepZones: {" ..
        table.concat(stepZones, ", ") ..
        "} | AllRelevant: {" .. table.concat(playerContext.allRelevant or {}, ", ") .. "}")

    -- Early return if player context is invalid (loading screen, dead, etc)
    -- Do NOT cache this result: the context will become valid once the transition ends,
    -- and we want a fresh check on the very next call.
    if not playerContext.allRelevant or #playerContext.allRelevant == 0 then
        self:PrintZoneDebug("Player context empty (loading/transitioning) - skipping checks (not cached)")
        return false
    end


    -- Continent check - GATING CHECK (if fails, stop here)
    if not self:CheckContinentMatch(playerContext, stepZones) then
        self:PrintZoneDebug("Failed continent check - returning FALSE")
        if self.ZoneDetection and self.ZoneDetection.debug then
            self:DebugZoneDetection("Failed continent match", playerContext, stepZones, false)
        end
        self:PrintZoneDebug("=== CheckIsInRouteZone END (FALSE) ===")
        self._lastRouteZoneCheck = GetTime()
        self._lastRouteZoneResult = false
        return false
    end

    -- Only continue with other checks if same continent
    local continentChecks = {
        -- 1. Direct match - quickest (player in step zones or step in route zones)
        function()
            return self:CheckDirectMatch(playerContext, stepZones)
        end,
        -- 2. Hierarchy match - player is parent/ancestor of step zones
        function()
            return self:CheckHierarchyMatch(playerContext, stepZones)
        end,

        -- 3. Descendant match - player is child of step zones (caves, buildings, etc)
        function()
            return self:CheckDescendantMatch(playerContext, stepZones)
        end,

        -- 4. Sibling match - player and step zones share a common parent (neighbors)
        function()
            return self:CheckSiblingMatch(playerContext, stepZones)
        end,

        -- 5. Route zone validation - step zone in route zones
        function()
            if APR.ZoneRestrictions and APR.ZoneRestrictions.HasIsolatedMap then
                if APR.ZoneRestrictions.HasIsolatedMap(playerContext.current, stepZones) then
                    return false
                end
            end

            return self:ContainsAny(routeZoneMapIDs, stepZones)
        end,
    }

    -- Execute continent-filtered checks
    for index, checkFunc in ipairs(continentChecks) do
        local checkNames = {
            "DirectMatch", "HierarchyMatch", "DescendantMatch", "SiblingMatch", "RouteValidation"
        }

        self:PrintZoneDebug("Running Check #" .. index .. " (" .. (checkNames[index] or "Unknown") .. ")...")

        local result = checkFunc()

        self:PrintZoneDebug("Check #" .. index .. " (" .. (checkNames[index] or "Unknown") .. "): " .. tostring(result))

        if result then
            self:PrintZoneDebug("Match at check #" .. index .. " (" .. (checkNames[index] or "Unknown") .. ")")
            if self.ZoneDetection and self.ZoneDetection.debug then
                self:DebugZoneDetection(
                    string.format("Match at check #%d", index),
                    playerContext, stepZones, true
                )
            end
            self:PrintZoneDebug("=== CheckIsInRouteZone END (TRUE) ===")
            self._lastRouteZoneCheck = GetTime()
            self._lastRouteZoneResult = true
            return true
        end
    end

    -- No match found
    if self.ZoneDetection and self.ZoneDetection.debug then
        self:DebugZoneDetection("No Match", playerContext, stepZones, false)
    end
    self:PrintZoneDebug("=== CheckIsInRouteZone END (FALSE) ===")

    self._lastRouteZoneCheck = GetTime()
    self._lastRouteZoneResult = false
    return false
end

--- Helper for routes with branch-specific data (e.g., Lumbermill versus other choices).
function APR:OverrideRouteData()
    if self.ActiveRoute and string.match(self.ActiveRoute, "DesMephisto%-Gorgrond") then
        if C_QuestLog.IsQuestFlaggedCompleted(35049) then
            self.RouteQuestStepList["543-DesMephisto-Gorgrond"] = nil
            self.RouteQuestStepList["543-DesMephisto-Gorgrond"] = self.RouteQuestStepList
                ["543-DesMephisto-Gorgrond-Lumbermill"]
        end
        if C_QuestLog.IsQuestFlaggedCompleted(34992) then
            self.RouteQuestStepList["543-DesMephisto-Gorgrond"] = nil
            self.RouteQuestStepList["543-DesMephisto-Gorgrond"] = self.RouteQuestStepList
                ["543-DesMephisto-Gorgrond-Lumbermill"]
        end
    end
end

--- Add custom routes stored in saved variables to the live route table.
function APR:LoadCustomRoutes()
    for name, steps in pairs(APRData.CustomRoute) do
        self.RouteQuestStepList[name] = steps
        self.RouteList.Custom[name] = name:match("%d+-(.*)")
    end
end

--- Evaluate skip/visibility conditions for a step.
function APR:StepFilterQuestHandler(step)
    local playerLevel = self.Level or UnitLevel("player") or 0
    local skipForLvl = tonumber(step.SkipForLvl)

    return (step.Faction and step.Faction ~= self.Faction) or
        (step.Race and not tContains(step.Race, self.Race)) or
        (step.Gender and step.Gender ~= self.Gender) or
        (step.Class and not tContains(step.Class, self.ClassName)) or
        (skipForLvl and playerLevel >= skipForLvl) or
        (step.HasAchievement and not self:HasAchievement(step.HasAchievement)) or
        (step.DontHaveAchievement and self:HasAchievement(step.DontHaveAchievement)) or
        (step.HasAura and not self:HasAura(step.HasAura)) or
        (step.DontHaveAura and self:HasAura(step.DontHaveAura)) or
        (step.HasSpell and not self:IsSpellKnown(step.HasSpell)) or
        (step.IsOneOfQuestsCompleted and not self:IsOneOfQuestsCompleted(step.IsOneOfQuestsCompleted)) or
        (step.IsOneOfQuestsUncompleted and self:IsOneOfQuestsCompleted(step.IsOneOfQuestsUncompleted)) or
        (step.IsOneOfQuestsCompletedOnAccount and not self:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsCompletedOnAccount))
        or
        (step.IsOneOfQuestsUncompletedOnAccount and self:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsUncompletedOnAccount))
        or
        (step.IsQuestsCompleted and not self:IsQuestsCompleted(step.IsQuestsCompleted)) or
        (step.IsQuestsUncompleted and self:IsQuestsCompleted(step.IsQuestsUncompleted)) or
        (step.IsQuestsCompletedOnAccount and not self:IsQuestsCompletedOnAccount(step.IsQuestsCompletedOnAccount)) or
        (step.IsQuestsUncompletedOnAccount and self:IsQuestsCompletedOnAccount(step.IsQuestsUncompletedOnAccount))
end

--- Quality-of-life variant of the step filter that returns true when the step should be shown.
function APR:StepFilterQoL(step)
    local playerLevel = self.Level or UnitLevel("player") or 0
    local skipForLvl = tonumber(step.SkipForLvl)

    return (not step.Faction or step.Faction == self.Faction) and
        (not step.Race or tContains(step.Race, self.Race)) and
        (not step.Gender or step.Gender == self.Gender) and
        (not step.Class or tContains(step.Class, self.ClassName)) and
        (not skipForLvl or playerLevel < skipForLvl) and
        (not step.HasAchievement or self:HasAchievement(step.HasAchievement)) and
        (not step.DontHaveAchievement or not self:HasAchievement(step.DontHaveAchievement)) and
        (not step.HasAura or self:HasAura(step.HasAura)) and
        (not step.DontHaveAura or not self:HasAura(step.DontHaveAura)) and
        (not step.HasSpell or self:IsSpellKnown(step.HasSpell)) and
        (not step.IsOneOfQuestsCompleted or self:IsOneOfQuestsCompleted(step.IsOneOfQuestsCompleted)) and
        (not step.IsOneOfQuestsUncompleted or not self:IsOneOfQuestsCompleted(step.IsOneOfQuestsUncompleted)) and
        (not step.IsOneOfQuestsCompletedOnAccount or self:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsCompletedOnAccount))
        and
        (not step.IsOneOfQuestsUncompletedOnAccount or not self:IsOneOfQuestsCompletedOnAccount(step.IsOneOfQuestsUncompletedOnAccount))
        and
        (not step.IsQuestsCompleted or self:IsQuestsCompleted(step.IsQuestsCompleted)) and
        (not step.IsQuestsUncompleted or not self:IsQuestsCompleted(step.IsQuestsUncompleted)) and
        (not step.IsQuestsCompletedOnAccount or self:IsQuestsCompletedOnAccount(step.IsQuestsCompletedOnAccount)) and
        (not step.IsQuestsUncompletedOnAccount or not self:IsQuestsCompletedOnAccount(step.IsQuestsUncompletedOnAccount))
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

    for expansion, routeList in pairs(self.RouteList) do
        for routeFileName, routeName in pairs(routeList) do
            if routeName == targetedRoute or routeFileName == targetedRoute then
                local mapID = string.match(routeFileName, "^(.-)-")
                return self.ZonesData.ExtensionRouteMaps[self.Faction][expansion] or {}, tonumber(mapID, 10),
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
    if not APRCustomPath or not APRCustomPath[self.PlayerID] then
        self:PrintError('No APRCustomPath')
        return nil, 0, '', ''
    end
    -- Get the current Route wanted MapIDs and Route File
    local _, currentRouteName = next(APRCustomPath[self.PlayerID])
    local routeZoneMapIDs, mapID, routeFileName, expansion = self:GetRouteMapIDsAndName(currentRouteName)

    -- Clean up invalid saved entries so the current step frame can show content.
    if routeFileName == '' then
        self:Debug("APR:GetCurrentRouteMapIDsAndName - invalid route in custom path", currentRouteName)
        table.remove(APRCustomPath[self.PlayerID], 1)
        self.routeconfig:CheckIsCustomPathEmpty()
        return nil, 0, '', ''
    end

    return routeZoneMapIDs, mapID, routeFileName, expansion
end

--- Resolve a route file name into a friendly display name.
function APR:GetRouteDisplayName(routeFileName)
    if not routeFileName then
        return nil
    end

    for _, routeList in pairs(self.RouteList or {}) do
        local label = routeList[routeFileName]
        if label then
            return label
        end
    end

    return nil
end

--- Resolve a route display name into a route file name.
function APR:GetRouteKeyFromDisplayName(displayName)
    if not displayName then return nil end

    for _, routeList in pairs(self.RouteList or {}) do
        for routeKey, routeLabel in pairs(routeList) do
            if routeLabel == displayName then
                return routeKey
            end
        end
    end

    -- fallback routes custom
    if self.RouteQuestStepList and self.RouteQuestStepList[displayName] then
        return displayName
    end

    return nil
end

--- Clear all saved state for a route.
function APR:ClearSavedRouteData(routeFileName)
    if not routeFileName or not APRData or not self.PlayerID then
        return
    end

    local playerData = APRData[self.PlayerID]
    if not playerData then
        return
    end

    playerData[routeFileName] = nil
    playerData[routeFileName .. '-SkippedStep'] = nil
    playerData[routeFileName .. '-TotalSteps'] = nil
    playerData[routeFileName .. '-RawTotalSteps'] = nil

    local routeSignatures = self.settings and self.settings.profile and self.settings.profile.routeSignatures
    if routeSignatures then
        routeSignatures[routeFileName] = nil
    end
end

--- Compare saved step totals and signatures to the live route to detect changes.
function APR:CheckRouteChanges(route)
    self:Debug("Function: APR:CheckRouteChanges()", route)
    local currentRoute = route or self.ActiveRoute or ''
    -- Use raw (unfiltered) step count for change detection to avoid false positives
    -- from filter state changes (quest log not synced after /reload, achievements, etc.)
    local savedTotalSteps = APRData[self.PlayerID][currentRoute .. '-RawTotalSteps']
    local currentTotalSteps = self:GetRawStepCount(currentRoute)
    local _, currentRouteName = next(APRCustomPath[self.PlayerID])

    if currentRouteName and not self.RouteQuestStepList[currentRoute] then
        self.questionDialog:CreateMandatoryAction(
            L["ROUTE_DELETED_NEED_RESET"],
            function()
                APRZoneCompleted[APR.PlayerID][currentRoute] = nil
                APR:ClearSavedRouteData(currentRoute)

                APR.command:SlashCmd('route')
                APRCustomPath[APR.PlayerID] = {}
                APR.routeconfig:SendMessage("APR_Custom_Path_Update")
            end
        )
    elseif savedTotalSteps and savedTotalSteps ~= currentTotalSteps then
        self.questionDialog:CreateMandatoryAction(
            L["ROUTE_UPDATED_NEED_RESET"],
            function()
                APRData[APR.PlayerID][currentRoute] = 1
                APRData[APR.PlayerID][currentRoute .. '-SkippedStep'] = 0
                APRData[APR.PlayerID][currentRoute .. '-RawTotalSteps'] = currentTotalSteps
                if currentRoute == APR.ActiveRoute then
                    APR.transport:GetMeToRightZone()
                    APR:PrintInfo(L["RESET_ROUTE"])
                end
            end
        )
    else
        -- Ensure raw total is persisted even if no change detected
        APRData[APR.PlayerID][currentRoute .. '-RawTotalSteps'] = currentTotalSteps
    end
end

--- Check saved routes (progress, custom paths, completed routes) against the current
--- live route definitions and clear/refresh stored data if definitions changed.
--- Parameter: currentRoute (optional) - a route file name to force into the check.
function APR:CheckCurrentRouteUpToDate(currentRoute)
    local playerID = self.PlayerID
    local playerData = APRData[playerID]
    if not playerData then
        return
    end

    -- Ensure route signatures table exists in the profile settings
    self.settings.profile.routeSignatures = self.settings.profile.routeSignatures or {}
    local routeSignatures = self.settings.profile.routeSignatures

    local completedRoutes = APRZoneCompleted[playerID] or {}
    APRZoneCompleted[playerID] = completedRoutes
    local trackedRoutes = {}

    -- 1) Scan playerData keys to find entries tied to routes.
    for key in pairs(playerData) do
        local routeFileName = key:match("^(.-)-TotalSteps$") or key:match("^(.-)-SkippedStep$") or
            key:match("^(.-)-RawTotalSteps$")
        if routeFileName then
            trackedRoutes[routeFileName] = true
        elseif self.RouteQuestStepList[key] then
            -- Key matches a route file name (saved progress)
            trackedRoutes[key] = true
        end
    end

    -- 2) Add routes listed as completed (display names) by resolving their file names
    for routeName in pairs(completedRoutes) do
        local _, _, routeFileName = APR:GetRouteMapIDsAndName(routeName)
        if routeFileName and routeFileName ~= '' then
            trackedRoutes[routeFileName] = true
        end
    end

    -- 3) If a specific currentRoute was passed in, include it
    if currentRoute then
        trackedRoutes[currentRoute] = true
    end

    -- 4) Build a lookup for the player's custom paths (APRCustomPath)
    local customPathLookup = {}
    if APRCustomPath[playerID] then
        for _, routeName in ipairs(APRCustomPath[playerID]) do
            customPathLookup[routeName] = true
        end
    end

    local completedResetNames = {}
    local customPathResetNames = {}
    local previousVersion = self.settings.profile.lastRecordedVersion

    -- 5) For each tracked route, compare saved data with the live route definition
    for routeFileName in pairs(trackedRoutes) do
        local displayName = self:GetRouteDisplayName(routeFileName) or routeFileName

        -- hasSavedProgress: true if any saved state exists for this route
        local hasSavedProgress = playerData[routeFileName] ~= nil
            or playerData[routeFileName .. '-TotalSteps'] ~= nil
            or playerData[routeFileName .. '-RawTotalSteps'] ~= nil
            or playerData[routeFileName .. '-SkippedStep'] ~= nil
            or completedRoutes[displayName]

        if hasSavedProgress then
            local routeExists = self.RouteQuestStepList[routeFileName] ~= nil
            -- Use raw (unfiltered) step count for change detection.
            -- The filtered count depends on dynamic player state (quest log, achievements,
            -- auras...) which may not be ready after /reload, causing false positives.
            local savedTotal = playerData[routeFileName .. '-RawTotalSteps']
            local currentTotal = routeExists and self:GetRawStepCount(routeFileName) or 0
            local savedSignature = routeSignatures[routeFileName]
            local currentSignature = routeExists and self:GetRouteSignature(routeFileName) or nil
            local isCustomPath = customPathLookup[displayName]
            local wasCompleted = completedRoutes[displayName]

            local routeChanged = not routeExists
                or (savedTotal and savedTotal ~= currentTotal)
                or (savedSignature and currentSignature and savedSignature ~= currentSignature)

            -- When upgrading versions with no stored signature, force a refresh to avoid stale data
            if not routeChanged and not savedSignature and previousVersion and previousVersion ~= self.version then
                routeChanged = true
            end

            if routeChanged then
                self:ClearSavedRouteData(routeFileName)
                -- Persist the new raw total so future comparisons work correctly
                playerData[routeFileName .. '-RawTotalSteps'] = currentTotal
                routeSignatures[routeFileName] = currentSignature

                if wasCompleted then
                    completedRoutes[displayName] = nil
                    table.insert(completedResetNames, displayName)
                end

                -- If it was a custom path, remember it to notify user/UI later
                if isCustomPath then
                    table.insert(customPathResetNames, displayName)
                end
            else
                -- No change: store raw total + signature for next comparison
                playerData[routeFileName .. '-RawTotalSteps'] = currentTotal
                routeSignatures[routeFileName] = currentSignature
            end
        else
            -- Even if we had no saved progress, persist a lightweight signature so future version upgrades can detect changes.
            if self.RouteQuestStepList[routeFileName] then
                routeSignatures[routeFileName] = self:GetRouteSignature(routeFileName)
                playerData[routeFileName .. '-RawTotalSteps'] = self:GetRawStepCount(routeFileName)
            end
        end
    end

    -- 6) Build a single notification (chat + popup) for resets.
    --    Only show the popup if:
    --      a) The active route was reset, OR
    --      b) It's the first login after a version upgrade (previousVersion ~= current)
    --    Data cleanup above already happened silently for all routes regardless.
    local isVersionUpgrade = previousVersion and previousVersion ~= self.version
    local activeRouteDisplay = self.ActiveRoute and self:GetRouteDisplayName(self.ActiveRoute)

    local combinedResetLines, seenNames = {}, {}
    local activeRouteWasReset = false

    for _, name in ipairs(customPathResetNames) do
        if not seenNames[name] then
            table.insert(combinedResetLines, name)
            seenNames[name] = true
            if name == activeRouteDisplay then
                activeRouteWasReset = true
            end
        end
    end

    for _, name in ipairs(completedResetNames) do
        if not seenNames[name] then
            table.insert(combinedResetLines, name)
            seenNames[name] = true
            if name == activeRouteDisplay then
                activeRouteWasReset = true
            end
        end
    end

    if #combinedResetLines > 0 and (activeRouteWasReset or isVersionUpgrade) then
        local msg = L["ROUTE_UPDATED_NEED_RESET"] .. ":\n\n" .. table.concat(combinedResetLines, "\n - ")
        self.questionDialog:CreateMessagePopup(msg)
    end

    -- 7) If custom paths were reset, send a config update message (UI refresh)
    if #customPathResetNames > 0 and self.routeconfig then
        self.routeconfig:SendMessage("APR_Custom_Path_Update")
    end

    -- 8) Record current addon version to detect upgrades later
    self.settings.profile.lastRecordedVersion = self.version
end

function APR:BuildSpecRouteKey(prefix, specName)
    if not prefix or not specName then return nil end
    return prefix .. " - " .. specName
end

function APR:FindAllSpecRoutesInCustomPath()
    local results = {}

    if not APRCustomPath or not APRCustomPath[self.PlayerID] then
        return results
    end

    for index, routeDisplay in ipairs(APRCustomPath[self.PlayerID]) do
        local routeKey = self:GetRouteKeyFromDisplayName(routeDisplay)

        if routeKey then
            for providerName, provider in pairs(self.ConditionalRouteRegistry.spec or {}) do
                if string.find(routeKey, provider.prefix, 1, true) == 1 then
                    table.insert(results, {
                        index = index,
                        provider = providerName,
                        prefix = provider.prefix,
                        oldRouteKey = routeKey,
                        oldDisplay = routeDisplay,
                    })
                end
            end
        end
    end

    return results
end

function APR:ResolveSpecRouteReplacements(specName, foundRoutes)
    local replacements = {}

    for _, entry in ipairs(foundRoutes or {}) do
        local newRouteKey = self:BuildSpecRouteKey(entry.prefix, specName)

        if self.RouteQuestStepList and self.RouteQuestStepList[newRouteKey] then
            table.insert(replacements, {
                index = entry.index,
                oldDisplay = entry.oldDisplay,
                oldRouteKey = entry.oldRouteKey,
                newRouteKey = newRouteKey,
                newDisplay = L[newRouteKey],
            })
        end
    end

    return replacements
end
