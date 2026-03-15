local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local function AddRouteToCustomPath(routeName)
    if not routeName or not APR.PlayerID then
        return
    end

    APRCustomPath[APR.PlayerID] = APRCustomPath[APR.PlayerID] or {}

    local _, _, routeFileName = APR:GetRouteMapIDsAndName(routeName)
    local playerData = APRData[APR.PlayerID]

    if routeFileName and playerData then
        if playerData[routeFileName]
            or playerData[routeFileName .. '-TotalSteps']
            or playerData[routeFileName .. '-SkippedStep'] then
            APR:CheckRouteChanges(routeFileName)
        end
    end

    tinsert(APRCustomPath[APR.PlayerID], routeName)
end

local function GetExpansionDisplayName(expansion)
    return APR.EXPANSIONS[expansion] or expansion
end

local function BuildLockedLabel(expansion, requiredLevel)
    return GetExpansionDisplayName(expansion) .. " " .. string.format(L["LVL_LOCK"], requiredLevel)
end

-- Central registry for prefab popup content and option composition.
local PREFAB_POPUP_DEFINITIONS = {
    all_quests = {
        prefabType = APR.PREFAB_TYPES.AllQuests,
        title = string.format(L["PREFAB_TITLE"], L["ALL_QUESTS"]),
        description = L["ALL_QUESTS_DESC"],
        unavailableMessage = L["ROUTE_NOT_AVAILABLE_YET"],
        expansions = {
            APR.EXPANSIONS.MistsOfPandaria,
            APR.EXPANSIONS.TheWarWithin,
            APR.EXPANSIONS.Midnight,
        },
        showUnavailable = true,
        requiredLevels = {
            [APR.EXPANSIONS.TheWarWithin] = 70,
            [APR.EXPANSIONS.Midnight] = 80,
        },
    },
    leveling = {
        prefabType = APR.PREFAB_TYPES.Leveling,
        title = string.format(L["PREFAB_TITLE"], L["LEVELING_PREFAB"]),
        description = L["LEVELING_DESC"],
        unavailableMessage = L["ROUTE_NOT_AVAILABLE_YET"],
        expansions = {
            APR.EXPANSIONS.WarlordsOfDraenor,
            APR.EXPANSIONS.BattleForAzeroth,
            APR.EXPANSIONS.MistsOfPandaria,
            APR.EXPANSIONS.Shadowlands,
            APR.EXPANSIONS.Dragonflight,
            APR.EXPANSIONS.TheWarWithin,
            APR.EXPANSIONS.Midnight,
        },
        showUnavailable = true,
        requiredLevels = {
            [APR.EXPANSIONS.TheWarWithin] = 70,
            [APR.EXPANSIONS.Midnight] = 80,
        },
    },
}

APR.routeconfig.PREFAB_POPUP_DEFINITIONS = PREFAB_POPUP_DEFINITIONS

local function GetRoutePrefabEntry(routeData, prefabType)
    if type(routeData) ~= "table" or type(routeData.prefab) ~= "table" or not prefabType then
        return nil
    end

    local entry = routeData.prefab[prefabType]
    if type(entry) == "number" then
        return { index = entry }
    end
    if type(entry) == "table" and type(entry.index) == "number" then
        return entry
    end

    return nil
end

local function HasRouteForExpansionAndPrefab(expansionName, prefabType)
    for _, routeData in pairs(APR.RouteQuestStepList or {}) do
        if type(routeData) == "table"
            and routeData.expansion == expansionName
            and routeData.label
            and GetRoutePrefabEntry(routeData, prefabType) then
            return true
        end
    end

    return false
end

local function IsExpansionInPopupDefinition(definition, expansionName)
    for _, expansion in ipairs(definition.expansions or {}) do
        if expansion == expansionName then
            return true
        end
    end
    return false
end

local function BuildExpansionPrefabFromRoutes(routeConfig, expansionName, prefabType, suppressUpdate)
    local routeCandidates = {}

    for routeKey, routeData in pairs(APR.RouteQuestStepList or {}) do
        if type(routeData) == "table" and routeData.expansion == expansionName and routeData.label then
            local prefabEntry = GetRoutePrefabEntry(routeData, prefabType)
            if prefabEntry and APR:GetRouteVisibility(routeKey) ~= "hidden" then
                tinsert(routeCandidates, {
                    routeKey = routeKey,
                    routeName = routeData.label,
                    index = prefabEntry.index,
                })
            end
        end
    end

    if #routeCandidates == 0 then
        return false
    end

    table.sort(routeCandidates, function(a, b)
        if a.index == b.index then
            return a.routeKey < b.routeKey
        end
        return a.index < b.index
    end)

    for _, route in ipairs(routeCandidates) do
        AddRouteToCustomPath(route.routeName)
    end

    routeConfig:SendCustomPathUpdate(suppressUpdate)
    return true
end

local function BuildPrefabPopupOptions(definition)
    local options = {}

    for _, expansionName in ipairs(definition.expansions or {}) do
        local hasRoute = HasRouteForExpansionAndPrefab(expansionName, definition.prefabType)
        local requiredLevel = definition.requiredLevels and definition.requiredLevels[expansionName]
        local isLevelLocked = requiredLevel and APR.Level < requiredLevel

        if definition.showUnavailable or hasRoute then
            local option = {
                key = expansionName,
                label = GetExpansionDisplayName(expansionName),
                enabled = hasRoute and not isLevelLocked,
            }

            if requiredLevel then
                if isLevelLocked then
                    option.label = BuildLockedLabel(expansionName, requiredLevel)
                    option.tooltip = "Requires level " .. requiredLevel .. "."
                else
                    option.label = GetExpansionDisplayName(expansionName) .. " (Level " .. requiredLevel .. "+)"
                end
            end

            if not hasRoute and definition.showUnavailable then
                option.label = option.label .. " - Unavailable"
                option.tooltip = definition.unavailableMessage
            end

            tinsert(options, option)
        end
    end

    return options
end

local function RouteHasZoneCondition(routeData, parentMapID)
    local conditions = type(routeData) == "table" and routeData.conditions
    if type(conditions) ~= "table" or type(conditions.Zones) ~= "table" or not parentMapID then
        return false
    end

    for _, mapID in ipairs(conditions.Zones) do
        if mapID == parentMapID then
            return true
        end
    end

    return false
end

local function BuildStartingZonePrefabFromRoutes(routeConfig, prefabType, parentMapID, suppressUpdate)
    local routeCandidates = {}
    local startingZonePrefabType = prefabType or APR.PREFAB_TYPES.StartingZone

    for routeKey, routeData in pairs(APR.RouteQuestStepList or {}) do
        if type(routeData) == "table" and routeData.label and APR:GetRouteVisibility(routeKey) ~= "hidden" then
            local prefabEntry = GetRoutePrefabEntry(routeData, startingZonePrefabType)
            if prefabEntry then
                tinsert(routeCandidates, {
                    routeKey = routeKey,
                    routeName = routeData.label,
                    index = prefabEntry.index,
                    mapMatch = parentMapID and
                        (routeData.mapID == parentMapID or RouteHasZoneCondition(routeData, parentMapID)) or false,
                })
            end
        end
    end

    if #routeCandidates == 0 then
        return false
    end

    local hasMapMatchedCandidates = false
    if parentMapID then
        for _, candidate in ipairs(routeCandidates) do
            if candidate.mapMatch then
                hasMapMatchedCandidates = true
                break
            end
        end
    end

    table.sort(routeCandidates, function(a, b)
        if hasMapMatchedCandidates and a.mapMatch ~= b.mapMatch then
            return a.mapMatch and not b.mapMatch
        end
        if a.index == b.index then
            return a.routeKey < b.routeKey
        end
        return a.index < b.index
    end)

    local addedAny = false
    local addedRouteNames = {}
    for _, candidate in ipairs(routeCandidates) do
        if (not hasMapMatchedCandidates or candidate.mapMatch)
            and not addedRouteNames[candidate.routeName] then
            AddRouteToCustomPath(candidate.routeName)
            addedRouteNames[candidate.routeName] = true
            addedAny = true
        end
    end

    if not addedAny then
        return false
    end

    routeConfig:SendCustomPathUpdate(suppressUpdate)
    return true
end

local function FindConditionBasedStartingRouteKey(parentMapID, requireMapMatch)
    local bestRouteKey = nil
    local bestScore = nil

    for routeKey, routeData in pairs(APR.RouteQuestStepList or {}) do
        if type(routeData) == "table"
            and routeData.label
            and routeData.category == APR.CATEGORIES.Leveling
            and APR:GetRouteVisibility(routeKey) ~= "hidden" then
            local conditions = type(routeData.conditions) == "table" and routeData.conditions or nil
            local hasStarterConditions = conditions and
                (conditions.Race ~= nil or conditions.Class ~= nil or conditions.AlliedRace ~= nil)
            local isStarter = routeData.notSkippable or hasStarterConditions

            if isStarter then
                local mapMatch = parentMapID and
                    (routeData.mapID == parentMapID or RouteHasZoneCondition(routeData, parentMapID)) or false
                if not requireMapMatch or mapMatch then
                    local score = 0
                    if mapMatch then score = score + 1000 end
                    if routeData.notSkippable then score = score + 300 end
                    if hasStarterConditions then score = score + 200 end
                    if conditions then
                        if conditions.AlliedRace ~= nil then score = score + 60 end
                        if conditions.Class ~= nil then score = score + 40 end
                        if conditions.Race ~= nil then score = score + 20 end
                    end

                    if bestScore == nil or score > bestScore or (score == bestScore and routeKey < bestRouteKey) then
                        bestRouteKey = routeKey
                        bestScore = score
                    end
                end
            end
        end
    end

    return bestRouteKey
end

function APR.routeconfig:GetSpeedRunPrefab()
    self._isBuildingSpeedrunPrefab = true

    self:GetStartingZonePrefab()

    -- Don't add other route if the player is neutral
    if APR.Faction == "Neutral" then
        self._isBuildingSpeedrunPrefab = nil
        self:SendMessage("APR_Custom_Path_Update")
        return
    end

    if APR.Level < APR.MaxLevelChromie then
        BuildExpansionPrefabFromRoutes(self, APR.EXPANSIONS.Dragonflight, APR.PREFAB_TYPES.Leveling, true)
        BuildExpansionPrefabFromRoutes(self, APR.EXPANSIONS.WarlordsOfDraenor, APR.PREFAB_TYPES.Leveling, true)
    end

    if APR.Level < APR.PreviousMaxLvl then
        BuildExpansionPrefabFromRoutes(self, APR.EXPANSIONS.TheWarWithin, APR.PREFAB_TYPES.Leveling, true)
    end

    BuildExpansionPrefabFromRoutes(self, APR.EXPANSIONS.Midnight, APR.PREFAB_TYPES.Speedrun, true)

    self._isBuildingSpeedrunPrefab = nil
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:BuildAllQuestsPrefab(expansion)
    local definition = PREFAB_POPUP_DEFINITIONS.all_quests
    if not IsExpansionInPopupDefinition(definition, expansion) then
        APR.questionDialog:CreateMessagePopup(definition.unavailableMessage, OKAY)
        return
    end

    APRCustomPath[APR.PlayerID] = {}
    self:GetStartingZonePrefab(true)

    if not BuildExpansionPrefabFromRoutes(self, expansion, definition.prefabType, true) then
        APR.questionDialog:CreateMessagePopup(definition.unavailableMessage, OKAY)
        return
    end

    self:SendCustomPathUpdate(false)
end

function APR.routeconfig:BuildLevelingPrefab(expansion)
    local definition = PREFAB_POPUP_DEFINITIONS.leveling
    local requiredLevel = definition.requiredLevels and definition.requiredLevels[expansion]
    if requiredLevel and APR.Level < requiredLevel then
        APR.questionDialog:CreateMessagePopup("Requires level " .. requiredLevel .. ".", OKAY)
        return
    end

    if not IsExpansionInPopupDefinition(definition, expansion) then
        APR.questionDialog:CreateMessagePopup(definition.unavailableMessage, OKAY)
        return
    end

    APRCustomPath[APR.PlayerID] = {}
    self:GetStartingZonePrefab(true)

    if not BuildExpansionPrefabFromRoutes(self, expansion, definition.prefabType, true) then
        APR.questionDialog:CreateMessagePopup(definition.unavailableMessage, OKAY)
        return
    end

    self:SendCustomPathUpdate(false)
end

function APR.routeconfig:OpenAllQuestsPopup()
    local definition = PREFAB_POPUP_DEFINITIONS.all_quests
    local options = BuildPrefabPopupOptions(definition)

    if #options == 0 then
        APR.questionDialog:CreateMessagePopup(definition.unavailableMessage, OKAY)
        return
    end

    APR.questionDialog:CreateSelectionPopup(
        definition.title,
        definition.description,
        options,
        function(option)
            self:BuildAllQuestsPrefab(option.key)
        end
    )
end

function APR.routeconfig:OpenLevelingPopup()
    local definition = PREFAB_POPUP_DEFINITIONS.leveling
    local options = BuildPrefabPopupOptions(definition)

    APR.questionDialog:CreateSelectionPopup(
        definition.title,
        definition.description,
        options,
        function(option)
            self:BuildLevelingPrefab(option.key)
        end
    )
end

function APR.routeconfig:GetStartingZonePrefab(suppressUpdate, prefabType)
    local parentMapID = APR:GetPlayerParentMapID()
    prefabType = prefabType or APR.PREFAB_TYPES.StartingZone

    local isNewCharacterStartFlow = not (C_QuestLog.IsQuestFlaggedCompleted(59926) or C_QuestLog.IsQuestFlaggedCompleted(56775))
        and (APR.Level < APR.MinBoostLvl or APR.Level < 10)

    local shouldResolveStartingZone = (parentMapID and (APR.ZoneRestrictions.IsExilesReachMap(parentMapID)
            or APR.ZoneRestrictions.IsReturningPlayerMap(parentMapID)))
        or isNewCharacterStartFlow

    if shouldResolveStartingZone and BuildStartingZonePrefabFromRoutes(self, prefabType, parentMapID, suppressUpdate) then
        return
    end

    if shouldResolveStartingZone then
        local routeKey = FindConditionBasedStartingRouteKey(parentMapID, parentMapID ~= nil)
            or FindConditionBasedStartingRouteKey(parentMapID, false)
        local routeData = routeKey and APR:GetRouteData(routeKey)
        if routeData and routeData.label then
            AddRouteToCustomPath(routeData.label)
            self:SendCustomPathUpdate(suppressUpdate)
            return
        end
    end

    self:SendCustomPathUpdate(suppressUpdate)
end

function APR.routeconfig:GetPlayerSpecRoute(prefix)
    local routeKey = prefix .. " - " .. APR:GetClassSpecName()
    if APR.RouteQuestStepList[routeKey] then
        AddRouteToCustomPath(L[routeKey])
    end
end

function APR.routeconfig:GetRemixPrefab()
    self:SendCustomPathUpdate(false)
end
