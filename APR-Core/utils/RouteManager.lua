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

--- Return the steps array for a route key.
--- Handles both the new format (routeData.steps) and legacy flat arrays
--- that external addons (e.g. AprRC) might inject directly into RouteQuestStepList.
---@param routeKey string
---@return table steps (empty table if not found)
function APR:GetRouteSteps(routeKey)
    local routeData = self:GetRouteData(routeKey)
    if not routeData then return {} end
    -- New format: routeData is { steps = {...}, label = ..., ... }
    if routeData.steps then return routeData.steps end
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
    if not conditions or not conditions.Level then
        return true
    end
    local playerLevel = APR.Level or UnitLevel("player") or 0
    return playerLevel >= conditions.Level
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
    if not routeData or not routeData.conditions then return {} end

    local conditions = routeData.conditions
    local unmet = {}

    -- Level
    if conditions.Level then
        local playerLevel = self.Level or UnitLevel("player") or 0
        if playerLevel < conditions.Level then
            tinsert(unmet, string.format(
                "%s >= %d (%s: %d)",
                L["CONDITION_LEVEL"],
                conditions.Level,
                L["CONDITION_CURRENT_LEVEL"],
                playerLevel
            ))
        end
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

    local conditions = routeData.conditions
    if not conditions or not next(conditions) then
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
