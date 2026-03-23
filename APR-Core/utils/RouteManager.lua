local L = LibStub("AceLocale-3.0"):GetLocale("APR")

---------------------------------------------------------------------------------------
--- RouteManager: centralized route logic for definitions, conditions, visibility,
--- steps access, and nextRoute suggestions.
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
--- Route Data Access
---------------------------------------------------------------------------------------

--- Return the full route data table for a key, or nil.
---@param routeKey string
---@return table|nil routeData
function APR:GetRouteData(routeKey)
    if not routeKey then return nil end
    local routeData = self.RouteQuestStepList[routeKey]
    if type(routeData) ~= "table" then return nil end
    return routeData
end

local function FlattenScenarioBlocks(blocks, scenarioID)
    local steps = {}
    for _, block in ipairs(blocks or {}) do
        if not scenarioID or tonumber(block.scenarioID) == tonumber(scenarioID) then
            for _, step in ipairs(block.steps or {}) do
                table.insert(steps, step)
            end
        end
    end
    return steps
end

local function GetActiveDelveScenarioID(routeKey)
    local playerData = APRData and APR.PlayerID and APRData[APR.PlayerID] or nil
    local temporaryRouteState = playerData and playerData.TemporaryRouteState or nil
    local scenarioID = temporaryRouteState and temporaryRouteState.routeKey == routeKey and temporaryRouteState.scenarioID or
        nil

    if routeKey == APR.ActiveRoute and APR.GetCurrentDelveContext then
        local context = APR:GetCurrentDelveContext()
        if context and context.scenarioID and APR.HasDelveScenarioBlock and APR:HasDelveScenarioBlock(routeKey, context.scenarioID) then
            scenarioID = context.scenarioID
        end
    end

    return scenarioID
end

local function GetBaseRouteSteps(routeData, routeKey)
    if not routeData then
        return {}
    end

    if routeKey and APR and APR.IsDelveRoute and APR:IsDelveRoute(routeKey) and APR.GetDelveScenarioBlocks then
        local blocks = APR:GetDelveScenarioBlocks(routeKey)
        if blocks then
            local scenarioID = GetActiveDelveScenarioID(routeKey)
            local matchedSteps = scenarioID and FlattenScenarioBlocks(blocks, scenarioID) or {}
            if #matchedSteps > 0 then
                return matchedSteps
            end

            return FlattenScenarioBlocks(blocks)
        end
    end

    if routeData.steps then
        return routeData.steps
    end

    if routeData[1] then
        return routeData
    end

    return {}
end

local function GetParallelGroups(routeData)
    if not routeData or type(routeData.parallelSteps) ~= "table" then
        return nil
    end

    local groups = {}
    for _, group in ipairs(routeData.parallelSteps) do
        if type(group) == "table" and type(group.steps) == "table" and #group.steps > 0 then
            groups[#groups + 1] = group
        end
    end

    if #groups == 0 then
        return nil
    end

    return groups
end

local function GetRouteParallelState(self, routeKey, create)
    if not routeKey or not APRData or not self.PlayerID then
        return nil
    end

    local playerData = APRData[self.PlayerID]
    if not playerData then
        return nil
    end

    local stateKey = routeKey .. '-ParallelStepsState'
    local state = playerData[stateKey]
    if not state and create then
        state = {
            activationSequence = 0,
            groups = {},
        }
        playerData[stateKey] = state
    end

    return state
end

local function BuildEffectiveRouteCacheKey(baseSteps, groups, state)
    local parts = { tostring(#baseSteps) }

    for _, group in ipairs(groups or {}) do
        parts[#parts + 1] = tostring(#group.steps)
    end

    local activeGroups = state and state.groups or nil
    if activeGroups then
        local orderedEntries = {}
        for groupIndex, entry in pairs(activeGroups) do
            if type(entry) == "table" then
                orderedEntries[#orderedEntries + 1] = {
                    groupIndex = groupIndex,
                    activationOrder = entry.activationOrder or 0,
                    effectiveBeforeIndex = entry.effectiveBeforeIndex or 0,
                }
            end
        end

        table.sort(orderedEntries, function(left, right)
            if left.activationOrder == right.activationOrder then
                return left.groupIndex < right.groupIndex
            end
            return left.activationOrder < right.activationOrder
        end)

        for _, entry in ipairs(orderedEntries) do
            parts[#parts + 1] = string.format("%d@%d@%d", entry.groupIndex, entry.activationOrder,
                entry.effectiveBeforeIndex)
        end
    end

    return table.concat(parts, "|")
end

function APR:InvalidateEffectiveRouteStepsCache(routeKey)
    self._effectiveRouteStepsCache = self._effectiveRouteStepsCache or {}
    if routeKey then
        self._effectiveRouteStepsCache[routeKey] = nil
        return
    end

    wipe(self._effectiveRouteStepsCache)
end

function APR:BuildEffectiveRouteSteps(routeKey)
    local routeData = self:GetRouteData(routeKey)
    local baseSteps = GetBaseRouteSteps(routeData, routeKey)
    local groups = GetParallelGroups(routeData)
    local state = GetRouteParallelState(self, routeKey, false)
    local activeGroups = state and state.groups or nil

    if not groups or not activeGroups or not next(activeGroups) then
        return baseSteps
    end

    self._effectiveRouteStepsCache = self._effectiveRouteStepsCache or {}
    local cacheKey = BuildEffectiveRouteCacheKey(baseSteps, groups, state)
    local cached = self._effectiveRouteStepsCache[routeKey]
    if cached and cached.key == cacheKey then
        return cached.steps
    end

    local effectiveSteps = {}
    for index = 1, #baseSteps do
        effectiveSteps[index] = baseSteps[index]
    end

    local orderedEntries = {}
    for groupIndex, entry in pairs(activeGroups) do
        local group = groups[groupIndex]
        if group and type(entry) == "table" then
            orderedEntries[#orderedEntries + 1] = {
                groupIndex = groupIndex,
                entry = entry,
                steps = group.steps,
            }
        end
    end

    table.sort(orderedEntries, function(left, right)
        local leftOrder = left.entry.activationOrder or 0
        local rightOrder = right.entry.activationOrder or 0
        if leftOrder == rightOrder then
            return left.groupIndex < right.groupIndex
        end
        return leftOrder < rightOrder
    end)

    for _, item in ipairs(orderedEntries) do
        local insertIndex = math.max(1,
            math.min(item.entry.effectiveBeforeIndex or (#effectiveSteps + 1), #effectiveSteps + 1))
        for offset, step in ipairs(item.steps) do
            table.insert(effectiveSteps, insertIndex + offset - 1, step)
        end
    end

    self._effectiveRouteStepsCache[routeKey] = {
        key = cacheKey,
        steps = effectiveSteps,
    }

    return effectiveSteps
end

function APR:GetParallelStepsInsertionIndex(currentStepIndex, effectiveSteps)
    if not effectiveSteps or #effectiveSteps == 0 then
        return 1
    end

    currentStepIndex = tonumber(currentStepIndex) or 1
    if currentStepIndex < 1 then
        currentStepIndex = 1
    end

    if currentStepIndex > #effectiveSteps then
        return #effectiveSteps + 1
    end

    local currentStep = effectiveSteps[currentStepIndex]
    if not (currentStep and currentStep.InstanceQuest) then
        return currentStepIndex
    end

    local insertionIndex = currentStepIndex + 1
    for index = currentStepIndex + 1, #effectiveSteps do
        local step = effectiveSteps[index]
        if not (step and step.InstanceQuest) then
            break
        end
        insertionIndex = index + 1
    end

    return insertionIndex
end

function APR:EnsureRouteParallelStepsActivated(routeKey)
    if routeKey ~= self.ActiveRoute then
        return
    end

    local routeData = self:GetRouteData(routeKey)
    local groups = GetParallelGroups(routeData)
    if not groups then
        return
    end

    local playerData = APRData and self.PlayerID and APRData[self.PlayerID] or nil
    local currentStepIndex = playerData and playerData[routeKey] or nil
    if not currentStepIndex then
        return
    end

    local state = GetRouteParallelState(self, routeKey, true)
    if not state then
        return
    end

    state.groups = state.groups or {}
    local pendingGroups = {}
    for groupIndex, group in ipairs(groups) do
        if not state.groups[groupIndex] and self:AreConditionalFiltersMet(group.conditions or {}) then
            pendingGroups[#pendingGroups + 1] = {
                groupIndex = groupIndex,
                steps = group.steps,
            }
        end
    end

    if #pendingGroups == 0 then
        return
    end

    local effectiveSteps = self:BuildEffectiveRouteSteps(routeKey)
    local insertionIndex = self:GetParallelStepsInsertionIndex(currentStepIndex, effectiveSteps)
    local insertedSteps = 0

    for _, pendingGroup in ipairs(pendingGroups) do
        state.activationSequence = (state.activationSequence or 0) + 1
        state.groups[pendingGroup.groupIndex] = {
            activationOrder = state.activationSequence,
            effectiveBeforeIndex = insertionIndex + insertedSteps,
        }
        insertedSteps = insertedSteps + #pendingGroup.steps
    end

    self:InvalidateEffectiveRouteStepsCache(routeKey)
end

--- Return the steps array for a route key.
--- Handles both the new format (routeData.steps) and legacy flat arrays
--- that external addons (e.g. AprRC) might inject directly into RouteQuestStepList.
---@param routeKey string
---@return table steps (empty table if not found)
function APR:GetRouteSteps(routeKey)
    local routeData = self:GetRouteData(routeKey)
    if not routeData then return {} end
    -- New format: routeData is { steps = {...}, label = ..., ... }.
    -- Delves also support { scenarios = {...}, label = ..., ... }.
    if routeData.steps or routeData.scenarios or self:IsDelveRoute(routeKey) then
        self:EnsureRouteParallelStepsActivated(routeKey)
        return self:BuildEffectiveRouteSteps(routeKey)
    end
    -- Legacy fallback: routeData IS the flat step array (ipairs-iterable table with numeric keys)
    if routeData[1] then return routeData end
    return {}
end

--- Return the expansion display string for a route key.
---@param routeKey string
---@return string|nil expansion
function APR:GetRouteExpansion(routeKey)
    local routeData = self:GetRouteData(routeKey)
    return routeData and routeData.expansion or nil
end

--- Return the category display string for a route key.
---@param routeKey string
---@return string|nil category
function APR:GetRouteCategory(routeKey)
    local routeData = self:GetRouteData(routeKey)
    return routeData and routeData.category or nil
end

--- Return the mapID defined in the route, or extract it from the key as fallback.
---@param routeKey string
---@return number|nil mapID
function APR:GetRouteMapID(routeKey)
    local routeData = self:GetRouteData(routeKey)
    if routeData and routeData.mapID then
        return routeData.mapID
    end
    -- Fallback: parse from key prefix (e.g. "2393-Midnight-Speedrun" -> 2393)
    if routeKey then
        local id = string.match(routeKey, "^(%d+)")
        return id and tonumber(id) or nil
    end
    return nil
end

---------------------------------------------------------------------------------------
--- Condition Evaluation
---------------------------------------------------------------------------------------

local function IsRouteCompletedByKey(routeKey)
    if not routeKey or not APRZoneCompleted or not APR.PlayerID then
        return false
    end

    local routeData = APR:GetRouteData(routeKey)
    local routeLabel = routeData and routeData.label or nil
    if not routeLabel then
        return false
    end

    local completedForPlayer = APRZoneCompleted[APR.PlayerID]
    return completedForPlayer and completedForPlayer[routeLabel] == true or false
end

function APR:GetRouteRequiredRouteKeys(routeKey)
    local routeData = self:GetRouteData(routeKey)
    if not routeData then
        return {}
    end

    local required = routeData.requiredRoute
    if type(required) == "string" then
        return { required }
    end

    if type(required) == "table" then
        local result = {}
        local seen = {}
        for _, requiredRouteKey in ipairs(required) do
            if type(requiredRouteKey) == "string" and requiredRouteKey ~= "" and not seen[requiredRouteKey] then
                seen[requiredRouteKey] = true
                table.insert(result, requiredRouteKey)
            end
        end
        return result
    end

    return {}
end

--- Add a route to custom path and automatically prepend unmet required routes.
--- Required routes are read from routeData.requiredRoute.
---@param routeKey string
---@return boolean addedAny
function APR:AddRouteToCustomPathByKey(routeKey)
    if not routeKey or not self.PlayerID then
        return false
    end

    APRCustomPath[self.PlayerID] = APRCustomPath[self.PlayerID] or {}
    local customPath = APRCustomPath[self.PlayerID]
    local visiting = {}
    local addedAny = false

    local function addRouteRecursive(targetRouteKey)
        if visiting[targetRouteKey] then
            return
        end
        visiting[targetRouteKey] = true

        local targetRouteData = self:GetRouteData(targetRouteKey)
        if not targetRouteData or not targetRouteData.label then
            visiting[targetRouteKey] = nil
            return
        end

        local requiredRouteKeys = self:GetRouteRequiredRouteKeys(targetRouteKey)
        for _, requiredRouteKey in ipairs(requiredRouteKeys) do
            if not IsRouteCompletedByKey(requiredRouteKey) then
                addRouteRecursive(requiredRouteKey)
            end
        end

        if not self:Contains(customPath, targetRouteData.label) then
            table.insert(customPath, targetRouteData.label)
            addedAny = true
        end

        visiting[targetRouteKey] = nil
    end

    addRouteRecursive(routeKey)
    return addedAny
end

--- Allied race check: RaceIDs >= 23 are allied races in WoW.
---@return boolean
function APR:IsAlliedRace()
    return (self.RaceID or 0) >= 23
end

--- Evaluate all "hard" conditions (everything except Level).
--- Returns true only if ALL non-Level conditions pass.
---@param conditions table
---@return boolean allHardMet
local function EvaluateHardConditions(conditions)
    if not conditions then return true end

    -- Faction
    if conditions.Faction then
        if conditions.Faction ~= APR.Faction then
            return false
        end
    end

    -- Race (single string comparison, e.g. APR.RACES.Worgen)
    if conditions.Race then
        if conditions.Race ~= APR.Race then
            return false
        end
    end

    -- Class (numeric classId, e.g. APR.Classes["Death Knight"] = 6)
    if conditions.Class then
        if conditions.Class ~= APR.ClassId then
            return false
        end
    end

    -- ClassNot (numeric classId - route is excluded for this class)
    if conditions.ClassNot then
        if conditions.ClassNot == APR.ClassId then
            return false
        end
    end

    -- NOTE: ClassSpec is NOT checked here — it is a "soft" condition evaluated
    -- separately (like Level), so that failing it results in "disabled" not "hidden".

    -- Event (e.g. APR.EVENTS.Remix)
    if conditions.Event then
        if conditions.Event == APR.EVENTS.Remix then
            if not APR:IsRemixCharacter() then
                return false
            end
        end
        -- Future events can be added here
    end

    -- AlliedRace (boolean: true = must be allied, false = must NOT be allied)
    if conditions.AlliedRace ~= nil then
        local isAllied = APR:IsAlliedRace()
        if conditions.AlliedRace == true and not isAllied then
            return false
        elseif conditions.AlliedRace == false and isAllied then
            return false
        end
    end

    -- IsQuestCompleted (single questID)
    if conditions.IsQuestCompleted then
        if not C_QuestLog.IsQuestFlaggedCompleted(conditions.IsQuestCompleted) then
            return false
        end
    end

    -- IsQuestUncompleted (single questID - must NOT be completed)
    if conditions.IsQuestUncompleted then
        if C_QuestLog.IsQuestFlaggedCompleted(conditions.IsQuestUncompleted) then
            return false
        end
    end

    return true
end

--- Evaluate the Level condition.
---@param conditions table
---@return boolean levelMet
local function EvaluateLevelCondition(conditions)
    if not conditions then
        return true
    end
    local playerLevel = APR:GetPlayerEffectiveLevel()

    if conditions.Level and playerLevel < tonumber(conditions.Level) then
        return false
    end

    if conditions.MinLevel and playerLevel < tonumber(conditions.MinLevel) then
        return false
    end

    if conditions.MaxLevel and playerLevel > tonumber(conditions.MaxLevel) then
        return false
    end

    if conditions.BeLvl and not APR:IsPlayerWithinExactLevel(conditions.BeLvl, playerLevel) then
        return false
    end

    return true
end

--- Evaluate the Zones condition (soft condition, like Level).
--- Checks if the player is currently in one of the required map zones.
--- Failing Zones results in "disabled" rather than "hidden".
---@param conditions table
---@return boolean zonesMet
local function EvaluateZonesCondition(conditions)
    if not conditions or not conditions.Zones then
        return true
    end
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then return false end
    for _, mapID in ipairs(conditions.Zones) do
        if playerMapID == mapID then
            return true
        end
    end
    return false
end

--- Evaluate the ClassSpec condition (soft condition, like Level).
--- Failing ClassSpec results in "disabled" rather than "hidden".
---@param conditions table
---@return boolean specMet
local function EvaluateClassSpecCondition(conditions)
    if not conditions or not conditions.ClassSpec then
        return true
    end
    local currentSpecId = nil
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        local specIndex = C_SpecializationInfo.GetSpecialization()
        if specIndex then
            currentSpecId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
        end
    end
    return currentSpecId == conditions.ClassSpec
end


--- Evaluate ALL conditions for a route. Returns true if every condition passes.
---@param conditions table
---@return boolean met
function APR:EvaluateRouteConditions(conditions)
    if not conditions or not next(conditions) then
        return true
    end
    return EvaluateHardConditions(conditions) and EvaluateLevelCondition(conditions) and
        EvaluateClassSpecCondition(conditions) and EvaluateZonesCondition(conditions)
end

---------------------------------------------------------------------------------------
--- Unmet Conditions (for tooltips in Config_Route)
---------------------------------------------------------------------------------------

--- Return a list of human-readable strings describing each unmet soft condition for a route.
--- Only checks Level, ClassSpec and Zones — the conditions that can lead to "disabled" state.
--- Routes with unmet hard conditions (Race, Class, Event, etc.) are "hidden" and never
--- reach this function in the UI flow.
---@param routeKey string
---@return table unmetConditions Array of description strings
function APR:GetUnmetConditions(routeKey)
    local routeData = self:GetRouteData(routeKey)
    if not routeData then return {} end

    local conditions = routeData.conditions or {}
    local unmet = {}
    local playerLevel = self:GetPlayerEffectiveLevel()

    -- Level
    if conditions.Level then
        local requiredLevel = tonumber(conditions.Level)
        if requiredLevel and playerLevel < requiredLevel then
            tinsert(unmet, string.format(
                "%s >= %s (%s: %.2f)",
                L["CONDITION_LEVEL"],
                tostring(conditions.Level),
                L["CONDITION_CURRENT_LEVEL"],
                playerLevel
            ))
        end
    end

    if conditions.MinLevel then
        local minLevel = tonumber(conditions.MinLevel)
        if minLevel and playerLevel < minLevel then
            tinsert(unmet, string.format(
                "%s >= %s (%s: %.2f)",
                L["CONDITION_LEVEL"],
                tostring(conditions.MinLevel),
                L["CONDITION_CURRENT_LEVEL"],
                playerLevel
            ))
        end
    end

    if conditions.MaxLevel then
        local maxLevel = tonumber(conditions.MaxLevel)
        if maxLevel and playerLevel > maxLevel then
            tinsert(unmet, string.format(
                "%s <= %s (%s: %.2f)",
                L["CONDITION_LEVEL"],
                tostring(conditions.MaxLevel),
                L["CONDITION_CURRENT_LEVEL"],
                playerLevel
            ))
        end
    end

    if conditions.BeLvl and not self:IsPlayerWithinExactLevel(conditions.BeLvl, playerLevel) then
        tinsert(unmet, string.format(
            "%s = %s (%s: %.2f)",
            L["CONDITION_LEVEL"],
            tostring(conditions.BeLvl),
            L["CONDITION_CURRENT_LEVEL"],
            playerLevel
        ))
    end

    -- ClassSpec
    if conditions.ClassSpec then
        local currentSpecId = nil
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
            local specIndex = C_SpecializationInfo.GetSpecialization()
            if specIndex then
                currentSpecId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
            end
        end
        if currentSpecId ~= conditions.ClassSpec then
            local specName = tostring(conditions.ClassSpec)
            if GetSpecializationInfoByID then
                local _, name = GetSpecializationInfoByID(conditions.ClassSpec)
                if name then specName = name end
            end
            tinsert(unmet, string.format("%s: %s", L["CONDITION_SPEC"], specName))
        end
    end

    -- Zones
    if conditions.Zones then
        local playerMapID = C_Map.GetBestMapForUnit("player")
        local inZone = false
        if playerMapID then
            for _, mapID in ipairs(conditions.Zones) do
                if playerMapID == mapID then
                    inZone = true
                    break
                end
            end
        end
        if not inZone then
            -- Build list of required zone names
            local zoneNames = {}
            for _, mapID in ipairs(conditions.Zones) do
                local mapInfo = C_Map.GetMapInfo(mapID)
                tinsert(zoneNames, mapInfo and mapInfo.name or tostring(mapID))
            end
            -- Deduplicate zone names (multiple mapIDs can share the same zone name)
            local seen = {}
            local uniqueNames = {}
            for _, name in ipairs(zoneNames) do
                if not seen[name] then
                    seen[name] = true
                    tinsert(uniqueNames, name)
                end
            end
            tinsert(unmet, string.format("%s: %s", L["CONDITION_ZONE"], table.concat(uniqueNames, ", ")))
        end
    end

    return unmet
end

---------------------------------------------------------------------------------------
--- Route Visibility (for Config_Route selection UI)
---------------------------------------------------------------------------------------

--- Determine the visibility state of a route in the selection UI.
---@param routeKey string
---@return string "visible"|"disabled"|"hidden"
function APR:GetRouteVisibility(routeKey)
    local routeData = self:GetRouteData(routeKey)
    if not routeData then return "hidden" end

    if routeData.hiddenFromSelection or self:IsDelveRoute(routeKey) then
        return "hidden"
    end

    local conditions = routeData.conditions or {}
    if not next(conditions) then
        return "visible"
    end

    local hardMet = EvaluateHardConditions(conditions)
    local levelMet = EvaluateLevelCondition(conditions)
    local specMet = EvaluateClassSpecCondition(conditions)
    local zonesMet = EvaluateZonesCondition(conditions)

    if not hardMet then
        return "hidden"
    end

    if not levelMet or not specMet or not zonesMet then
        -- Hard conditions passed, only soft conditions (Level, ClassSpec, Zones) failed
        return "disabled"
    end

    return "visible"
end

--- Return true when at least one route exists for the given expansion display string
--- and is not hidden for the current player.
---@param expansion string  expansion display value (e.g. APR.EXPANSIONS.Midnight)
---@return boolean
function APR:HasVisibleRoutesForExpansion(expansion)
    for routeKey, routeData in pairs(self.RouteQuestStepList) do
        if type(routeData) == "table" and routeData.expansion == expansion then
            local vis = self:GetRouteVisibility(routeKey)
            if vis == "visible" or vis == "disabled" then
                return true
            end
        end
    end
    return false
end

---------------------------------------------------------------------------------------
--- Next Route Suggestions
---------------------------------------------------------------------------------------

--- Get the list of valid next routes after completing a route.
--- Filters out routes whose conditions are not fully met, and excludes the just-completed route.
---@param completedRouteKey string
---@return table validRoutes  Array of { key = routeKey, label = displayName }
function APR:GetNextRouteSuggestions(completedRouteKey)
    local routeData = self:GetRouteData(completedRouteKey)
    if not routeData or not routeData.nextRoute then
        return {}
    end

    local completedLabel = routeData.label
    local suggestions = {}

    for _, nextKey in ipairs(routeData.nextRoute) do
        local nextData = self:GetRouteData(nextKey)
        if nextData and nextData.label then
            -- Only include routes whose conditions are fully met
            if self:EvaluateRouteConditions(nextData.conditions) then
                -- Exclude the just-completed route itself
                if nextKey ~= completedRouteKey then
                    table.insert(suggestions, {
                        key = nextKey,
                        label = nextData.label,
                    })
                end
            end
        end
    end

    return suggestions
end

--- Show a next-route suggestion popup when a route is completed.
--- If a suggestion is already the next route in the custom path, skip the popup.
--- Calls onComplete when done (after selection, cancel, or immediate skip).
--- Called from QuestHandler when RouteCompleted step fires.
---@param completedRouteKey string
---@param onComplete function|nil  Callback to run after the popup is resolved
function APR:SuggestNextRoutes(completedRouteKey, onComplete)
    local suggestions = self:GetNextRouteSuggestions(completedRouteKey)

    -- Check if any suggestion is already queued in the remaining custom path
    -- (skip index 1 which is the route being completed right now)
    local customPath = APRCustomPath[self.PlayerID] or {}
    for _, suggestion in ipairs(suggestions) do
        for i = 2, #customPath do
            if customPath[i] == suggestion.label then
                -- A suggested route is already in the path, no popup needed
                if onComplete then onComplete() end
                return
            end
        end
    end

    if #suggestions == 0 then
        if onComplete then onComplete() end
        return
    end

    -- Use the existing route trigger popup to present choices
    self.questionDialog:CreateRouteTriggerPopup(
        L["NEXT_ROUTE_SUGGESTION"],
        suggestions,
        function(route)
            -- Add the selected route's display name to the custom path
            APRCustomPath[self.PlayerID] = APRCustomPath[self.PlayerID] or {}
            tinsert(APRCustomPath[self.PlayerID], route.label)
            -- NOTE: Do NOT send APR_Custom_Path_Update here — it triggers UpdateStep()
            -- which re-enters RouteCompleted and double-calls finalizeRouteCompletion.
            if onComplete then onComplete() end
        end,
        function() -- onCancel
            if onComplete then onComplete() end
        end,
        nil
    )
end
