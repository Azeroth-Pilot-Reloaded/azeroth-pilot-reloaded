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

function APR:ResetRoute(targetedRoute)
    self:Debug("Function: APR:ResetRoute()", targetedRoute)
    APRData[self.PlayerID][targetedRoute] = 1
    APRData[self.PlayerID][targetedRoute .. '-SkippedStep'] = 0
    APRData[self.PlayerID][targetedRoute .. '-ParallelStepsState'] = nil
    self:GetTotalSteps(targetedRoute)
    APRData[self.PlayerID][targetedRoute .. '-RawTotalSteps'] = self:GetRawStepCount(targetedRoute)
    if self.InvalidateEffectiveRouteStepsCache then
        self:InvalidateEffectiveRouteStepsCache(targetedRoute)
    end
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
    local steps = self:GetRouteSteps(route)
    local sojournerSkipActive = self:IsSojournerSkipActive(route)
    for _, step in pairs(steps) do
        -- Hide step for Faction, Race, Class, Achievement,...
        if self:StepFilterQoL(step) then
            -- Also hide sojourner-skipped campaign steps
            if not (sojournerSkipActive and self:IsStepCampaignQuest(step)) then
                stepIndex = stepIndex + 1
            end
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
    local routeData = self:GetRouteData(route)
    if not routeData then
        return 0
    end

    local rawStepCount = 0
    local delveScenarioBlocks = self.GetDelveScenarioBlocks and self:GetDelveScenarioBlocks(route) or nil
    if delveScenarioBlocks then
        for _, block in ipairs(delveScenarioBlocks) do
            rawStepCount = rawStepCount + #(block.steps or {})
        end
    else
        local steps = routeData.steps or routeData
        rawStepCount = #steps
    end

    if type(routeData.parallelSteps) == "table" then
        for _, group in ipairs(routeData.parallelSteps) do
            if type(group) == "table" and type(group.steps) == "table" then
                rawStepCount = rawStepCount + #group.steps
            end
        end
    end

    return rawStepCount
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
    local stepList = self:GetRouteSteps(route)
    local sojournerSkipActive = self:IsSojournerSkipActive(route)
    if #stepList > 0 then
        for i = 1, math.min(beforeIndex - 1, #stepList) do
            local step = stepList[i]
            -- Count only steps that are filtered (should be skipped/hidden)
            if self:StepFilterQuestHandler(step) then
                skippedCount = skippedCount + 1
            elseif sojournerSkipActive and self:IsStepCampaignQuest(step) then
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
    if not self.ActiveRoute or not string.match(self.ActiveRoute, "DesMephisto%-Gorgrond") then
        return
    end

    if not (C_QuestLog.IsQuestFlaggedCompleted(35049) or C_QuestLog.IsQuestFlaggedCompleted(34992)) then
        return
    end

    -- Faction-specific base/lumbermill route key pairs
    local overrides = {
        { base = "543-DesMephisto-Gorgrond",     lumbermill = "543-DesMephisto-Gorgrond-Lumbermill" },
        { base = "543-DesMephisto-Gorgrond - A", lumbermill = "543-DesMephisto-Gorgrond-Lumbermill - A" },
    }

    for _, pair in ipairs(overrides) do
        local baseData = self.RouteQuestStepList[pair.base]
        local lumbermillData = self.RouteQuestStepList[pair.lumbermill]
        if baseData and lumbermillData then
            baseData.steps = lumbermillData.steps
        end
    end
end

--- Add custom routes stored in saved variables to the live route table.
--- AprRC (Route Recorder) stores flat step arrays in APRData.CustomRoute.
--- This wraps them into the new self-describing format.
function APR:LoadCustomRoutes()
    for name, data in pairs(APRData.CustomRoute) do
        -- Guard: if data is already wrapped (has .steps), use it directly
        if type(data) == "table" and data.steps then
            self.RouteQuestStepList[name] = {
                label = data.label or name:match("%d+%-(.*)") or name,
                expansion = data.expansion or APR.EXPANSIONS.Custom,
                category = data.category or APR.CATEGORIES.Miscellaneous,
                conditions = data.conditions or {},
                parallelSteps = data.parallelSteps,
                steps = data.steps,
            }
        else
            -- Legacy flat step array from AprRC
            self.RouteQuestStepList[name] = {
                label = name:match("%d+%-(.*)") or name,
                expansion = APR.EXPANSIONS.Custom,
                category = APR.CATEGORIES.Miscellaneous,
                conditions = {},
                steps = data,
            }
        end
    end
end

--- Evaluate skip/visibility conditions for a step.
function APR:StepFilterQuestHandler(step)
    return not self:AreConditionalFiltersMet(step)
end

--- Quality-of-life variant of the step filter that returns true when the step should be shown.
function APR:StepFilterQoL(step)
    return self:AreConditionalFiltersMet(step)
end

function APR:GetPlayerEffectiveLevel()
    local level = UnitLevel("player") or self.Level or 0
    local currentXP = UnitXP and UnitXP("player") or 0
    local maxXP = UnitXPMax and UnitXPMax("player") or 0

    if maxXP and maxXP > 0 then
        return level + (currentXP / maxXP)
    end

    return level
end

function APR:IsPlayerWithinExactLevel(targetLevel, playerLevel)
    local exactLevel = tonumber(targetLevel)
    if not exactLevel then
        return false
    end

    playerLevel = playerLevel or self:GetPlayerEffectiveLevel()
    local upperBound = math.floor(exactLevel) + 1
    return playerLevel >= exactLevel and playerLevel < upperBound
end

local function MatchesConditionValue(expectedValue, actualValue, alternateValue)
    if type(expectedValue) == "table" then
        return tContains(expectedValue, actualValue) or
            (alternateValue ~= nil and tContains(expectedValue, alternateValue))
    end

    return expectedValue == actualValue or (alternateValue ~= nil and expectedValue == alternateValue)
end

function APR:AreConditionalFiltersMet(conditions)
    if not conditions then
        return true
    end

    local playerLevel = self:GetPlayerEffectiveLevel()
    local skipForLvl = tonumber(conditions.SkipForLvl)
    local level = tonumber(conditions.Level)
    local minLevel = tonumber(conditions.MinLevel)
    local maxLevel = tonumber(conditions.MaxLevel)

    local currentSpecId = nil
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        local specIndex = C_SpecializationInfo.GetSpecialization()
        if specIndex then
            currentSpecId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
        end
    end

    local playerMapID = C_Map.GetBestMapForUnit("player")

    return (not conditions.Faction or conditions.Faction == self.Faction) and
        (not conditions.Race or MatchesConditionValue(conditions.Race, self.Race, self.RaceID)) and
        (not conditions.Gender or conditions.Gender == self.Gender) and
        (not conditions.Class or MatchesConditionValue(conditions.Class, self.ClassName, self.ClassId)) and
        (not conditions.ClassNot or not MatchesConditionValue(conditions.ClassNot, self.ClassName, self.ClassId)) and
        (not level or playerLevel >= level) and
        (not minLevel or playerLevel >= minLevel) and
        (not maxLevel or playerLevel <= maxLevel) and
        (not conditions.BeLvl or self:IsPlayerWithinExactLevel(conditions.BeLvl, playerLevel)) and
        (not skipForLvl or playerLevel < skipForLvl) and
        (not conditions.ClassSpec or currentSpecId == conditions.ClassSpec) and
        (not conditions.Zones or (playerMapID and tContains(conditions.Zones, playerMapID))) and
        (conditions.AlliedRace == nil or self:IsAlliedRace() == conditions.AlliedRace) and
        (not conditions.Event or (conditions.Event ~= APR.EVENTS.Remix or self:IsRemixCharacter())) and
        (not conditions.HasAchievement or self:HasAchievement(conditions.HasAchievement)) and
        (not conditions.DontHaveAchievement or not self:HasAchievement(conditions.DontHaveAchievement)) and
        (not conditions.HasAura or self:HasAura(conditions.HasAura)) and
        (not conditions.DontHaveAura or not self:HasAura(conditions.DontHaveAura)) and
        (not conditions.HasSpell or self:IsSpellKnown(conditions.HasSpell)) and
        (not conditions.IsQuestCompleted or C_QuestLog.IsQuestFlaggedCompleted(conditions.IsQuestCompleted)) and
        (not conditions.IsQuestUncompleted or not C_QuestLog.IsQuestFlaggedCompleted(conditions.IsQuestUncompleted)) and
        (not conditions.IsOneOfQuestsCompleted or self:IsOneOfQuestsCompleted(conditions.IsOneOfQuestsCompleted)) and
        (not conditions.IsOneOfQuestsUncompleted or not self:IsOneOfQuestsCompleted(conditions.IsOneOfQuestsUncompleted)) and
        (not conditions.IsOneOfQuestsCompletedOnAccount or self:IsOneOfQuestsCompletedOnAccount(conditions.IsOneOfQuestsCompletedOnAccount)) and
        (not conditions.IsOneOfQuestsUncompletedOnAccount or not self:IsOneOfQuestsCompletedOnAccount(conditions.IsOneOfQuestsUncompletedOnAccount)) and
        (not conditions.IsQuestsCompleted or self:IsQuestsCompleted(conditions.IsQuestsCompleted)) and
        (not conditions.IsQuestsUncompleted or not self:IsQuestsCompleted(conditions.IsQuestsUncompleted)) and
        (not conditions.IsQuestsCompletedOnAccount or self:IsQuestsCompletedOnAccount(conditions.IsQuestsCompletedOnAccount)) and
        (not conditions.IsQuestsUncompletedOnAccount or not self:IsQuestsCompletedOnAccount(conditions.IsQuestsUncompletedOnAccount))
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

    local function BuildRouteResult(routeFileName, routeData)
        local expansion = self:GetEnumKeyByValue(APR.EXPANSIONS, routeData.expansion)
        local mapID = routeData.mapID or tonumber(string.match(routeFileName, "^(%d+)"), 10)
        return self.ZonesData.ExtensionRouteMaps[self.Faction][expansion] or {}, mapID or 0, routeFileName, expansion
    end

    -- Fast path: route key provided directly.
    local directRouteData = self.RouteQuestStepList[targetedRoute]
    if type(directRouteData) == "table" and directRouteData.expansion and directRouteData.label then
        return BuildRouteResult(targetedRoute, directRouteData)
    end

    -- Display names can be duplicated (e.g. Exile's Reach A/H), so resolve deterministically.
    local matchingRouteKeys = {}
    for routeFileName, routeData in pairs(self.RouteQuestStepList) do
        if type(routeData) == "table" and routeData.expansion and routeData.label and routeData.label == targetedRoute then
            tinsert(matchingRouteKeys, routeFileName)
        end
    end

    table.sort(matchingRouteKeys)

    -- Prefer route variants that are not hidden for current character (faction/race/class/event).
    for _, routeFileName in ipairs(matchingRouteKeys) do
        if self:GetRouteVisibility(routeFileName) ~= "hidden" then
            return BuildRouteResult(routeFileName, self.RouteQuestStepList[routeFileName])
        end
    end

    -- Fallback to first match to avoid breaking legacy/custom edge cases.
    if #matchingRouteKeys > 0 then
        local fallbackRouteKey = matchingRouteKeys[1]
        return BuildRouteResult(fallbackRouteKey, self.RouteQuestStepList[fallbackRouteKey])
    end

    return nil, 0, '', ''
end

--- Get Current Route zone mapID and name
---@return Array<number> routeZoneMapIDs MapIDs list of the mapid for the route
---@return number mapID  the main mapid for the route
---@return string routeFileName Route File Name
---@return string expansion expansion name
function APR:GetCurrentRouteMapIDsAndName()
    if self.ActiveRoute and self:GetRouteData(self.ActiveRoute) and self:IsTemporaryRoute(self.ActiveRoute) then
        return self:GetRouteMapIDsAndName(self.ActiveRoute)
    end

    local currentRouteKey = self:GetPrimaryCustomPathRouteKey()
    if not currentRouteKey and self.ActiveRoute and self:GetRouteData(self.ActiveRoute) then
        currentRouteKey = self.ActiveRoute
    end

    if not currentRouteKey then
        if not APRCustomPath or not APRCustomPath[self.PlayerID] then
            self:PrintError('No APRCustomPath')
        end
        return nil, 0, '', ''
    end

    local routeZoneMapIDs, mapID, routeFileName, expansion = self:GetRouteMapIDsAndName(currentRouteKey)

    -- Clean up invalid saved entries so the current step frame can show content.
    if routeFileName == '' then
        self:Debug("APR:GetCurrentRouteMapIDsAndName - invalid active route", currentRouteKey)
        if APRCustomPath and APRCustomPath[self.PlayerID] and next(APRCustomPath[self.PlayerID]) then
            table.remove(APRCustomPath[self.PlayerID], 1)
        end
        if self.routeconfig then
            self.routeconfig:CheckIsCustomPathEmpty()
        end
        return nil, 0, '', ''
    end

    return routeZoneMapIDs, mapID, routeFileName, expansion
end

--- Resolve a route file name into a friendly display name.
function APR:GetRouteDisplayName(routeFileName)
    if not routeFileName then
        return nil
    end

    local routeData = self.RouteQuestStepList[routeFileName]
    if routeData and routeData.label then
        return routeData.label
    end

    return nil
end

--- Resolve a route display name into a route file name.
function APR:GetRouteKeyFromDisplayName(displayName)
    if not displayName then return nil end

    local routeByKey = self.RouteQuestStepList and self.RouteQuestStepList[displayName]
    if type(routeByKey) == "table" then
        return displayName
    end

    local matchingRouteKeys = {}
    for routeKey, routeData in pairs(self.RouteQuestStepList or {}) do
        if type(routeData) == "table" and routeData.label == displayName then
            tinsert(matchingRouteKeys, routeKey)
        end
    end

    table.sort(matchingRouteKeys)

    for _, routeKey in ipairs(matchingRouteKeys) do
        if self:GetRouteVisibility(routeKey) ~= "hidden" then
            return routeKey
        end
    end

    if #matchingRouteKeys > 0 then
        return matchingRouteKeys[1]
    end

    -- fallback: key used directly as display name (custom routes)
    if self.RouteQuestStepList and self.RouteQuestStepList[displayName] then
        return displayName
    end

    return nil
end

-- ---------------------------------------------------------------------------
-- Note-step seen tracking
-- Note-only steps (steps with only a Note field, no quest-action content) are
-- purely informational.  Once the player has seen such a step, it should be
-- auto-skipped on subsequent route resets so it does not block progress.
-- The seen set is keyed by note content (not step index) so it stays valid
-- even after steps are inserted or removed in the route definition.
-- SeenNotes is intentionally NOT cleared by ClearSavedRouteData / ResetRoute;
-- it is only cleared entry-by-entry when the player manually navigates through
-- Note steps via skip / rollback.
-- ---------------------------------------------------------------------------

--- Marks a Note-only step as seen for the given route.
function APR:MarkNoteStepSeen(route, step)
    local key = self:GetNoteStepKey(step)
    if not key then return end
    local playerData = APRData[self.PlayerID]
    if not playerData then return end
    local seenKey = route .. '-SeenNotes'
    playerData[seenKey] = playerData[seenKey] or {}
    playerData[seenKey][key] = true
end

--- Returns true when a Note-only step was previously seen for the given route.
function APR:IsNoteStepSeen(route, step)
    local key = self:GetNoteStepKey(step)
    if not key then return false end
    local playerData = APRData[self.PlayerID]
    if not playerData then return false end
    local seenNotes = playerData[route .. '-SeenNotes']
    return seenNotes ~= nil and seenNotes[key] == true
end

--- Clears the seen flag for a Note-only step (called when the player rolls back to it).
function APR:UnmarkNoteStepSeen(route, step)
    local key = self:GetNoteStepKey(step)
    if not key then return end
    local playerData = APRData[self.PlayerID]
    if not playerData then return end
    local seenNotes = playerData[route .. '-SeenNotes']
    if seenNotes then
        seenNotes[key] = nil
    end
end

--- Clears the seen flag for every Note step between two indices (inclusive).
--- Manual skip / rollback use this so note previews can be revisited reliably.
function APR:ResetNoteStepsSeenInRange(route, startIndex, endIndex)
    if not route then
        return
    end

    local firstIndex = tonumber(startIndex)
    local lastIndex = tonumber(endIndex)
    if not firstIndex or not lastIndex then
        return
    end

    if firstIndex > lastIndex then
        firstIndex, lastIndex = lastIndex, firstIndex
    end

    local steps = self:GetRouteSteps(route)
    if not steps or #steps == 0 then
        return
    end

    for index = math.max(firstIndex, 1), math.min(lastIndex, #steps) do
        local step = steps[index]
        if step and step.Note then
            self:UnmarkNoteStepSeen(route, step)
        end
    end
end

--- Returns true when the steps immediately before and after a Note-only step at
--- stepIndex are effectively quest-complete, meaning the note no longer blocks
--- meaningful progression and can be auto-skipped after a route reset.
function APR:IsNoteStepSurroundingCompleted(route, stepIndex)
    local steps = self:GetRouteSteps(route)
    if not steps or #steps == 0 then return false end

    local function isStepEffectivelyDone(step)
        if not step then return true end
        -- Filtered steps (race/class/conditions) count as done
        if self:StepFilterQuestHandler(step) then return true end
        -- Another Note step is transparent (skip over it)
        if step.Note then return true end
        -- Waypoint: done when its anchor quest is completed
        if step.Waypoint then
            return C_QuestLog.IsQuestFlaggedCompleted(step.Waypoint)
        end
        -- Done/TurnIn: done when all quest IDs are flagged completed
        if step.Done then
            if type(step.Done) == "table" then
                for _, questID in ipairs(step.Done) do
                    if not C_QuestLog.IsQuestFlaggedCompleted(tonumber(questID)) then
                        return false
                    end
                end
                return true
            end
            return C_QuestLog.IsQuestFlaggedCompleted(tonumber(step.Done))
        end
        -- PickUp: done when all quest IDs are in the journal or flagged completed
        if step.PickUp then
            if type(step.PickUp) == "table" then
                for _, questID in ipairs(step.PickUp) do
                    questID = tonumber(questID)
                    if not (self.ActiveQuests[questID] or C_QuestLog.IsQuestFlaggedCompleted(questID)) then
                        return false
                    end
                end
                return true
            end
            local questID = tonumber(step.PickUp)
            return (self.ActiveQuests[questID] ~= nil) or C_QuestLog.IsQuestFlaggedCompleted(questID)
        end
        -- TakePortal: done when its quest is flagged completed or player is in the target zone
        if step.TakePortal then
            local questID = step.TakePortal.questID
            if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then return true end
        end
        -- Treasure: done when its anchor quest is flagged completed
        if step.Treasure then
            local questID = step.Treasure.questID
            if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then return true end
        end
        return false
    end

    -- Walk backward to find the first non-Note step before this one
    local prevDone = true
    for i = stepIndex - 1, 1, -1 do
        local s = steps[i]
        if s and not s.Note then
            prevDone = isStepEffectivelyDone(s)
            break
        end
    end

    -- Walk forward to find the first non-Note step after this one
    local nextDone = true
    for i = stepIndex + 1, #steps do
        local s = steps[i]
        if s and not s.Note then
            nextDone = isStepEffectivelyDone(s)
            break
        end
    end

    return prevDone and nextDone
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

    -- Before wiping the progress index, snapshot any Note-only steps that were
    -- before the player's current position into SeenNotes.  This ensures that
    -- Note-only steps newly inserted by a route update are still auto-skipped
    -- when the surrounding quest content was already completed.
    local currentProgress = playerData[routeFileName]
    if currentProgress and currentProgress > 1 then
        local steps = self:GetRouteSteps(routeFileName)
        if steps and #steps > 0 then
            local seenKey = routeFileName .. '-SeenNotes'
            local seenNotes = playerData[seenKey] or {}
            for i = 1, math.min(currentProgress - 1, #steps) do
                local s = steps[i]
                if s and s.Note then
                    local key = self:GetNoteStepKey(s)
                    if key then seenNotes[key] = true end
                end
            end
            if next(seenNotes) then
                playerData[seenKey] = seenNotes
            end
        end
    end

    playerData[routeFileName] = nil
    playerData[routeFileName .. '-SkippedStep'] = nil
    playerData[routeFileName .. '-TotalSteps'] = nil
    playerData[routeFileName .. '-RawTotalSteps'] = nil
    playerData[routeFileName .. '-ParallelStepsState'] = nil
    -- NOTE: routeFileName .. '-SeenNotes' is intentionally preserved across resets.

    local routeSignatures = self.settings and self.settings.profile and self.settings.profile.routeSignatures
    if routeSignatures then
        routeSignatures[routeFileName] = nil
    end

    if self.InvalidateEffectiveRouteStepsCache then
        self:InvalidateEffectiveRouteStepsCache(routeFileName)
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
        local msg = L["ROUTE_UPDATED_NEED_RESET"] .. "\n\n" .. table.concat(combinedResetLines, "\n - ")
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
