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
    self.farstrider:ForceRefresh()
    self.farstrider:GetMeToRightZone()
    self:PrintInfo(L["RESET_ROUTE"])
end

function APR:UpdateMapId()
    self:Debug("Function: APR:UpdateMapId()")
    self:OverrideRouteData() -- Lumbermill Wod route
    self.farstrider:GetMeToRightZone()
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
    local profileStart = self:StartPerformanceSample()
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
    self:FinishPerformanceSample("CountTotalSteps", profileStart, #steps)
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
    local profileStart = self:StartPerformanceSample()
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
    self:FinishPerformanceSample("CountSkippedSteps", profileStart, math.min(beforeIndex - 1, #stepList))
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

    -- The scenario ID is the authoritative location signal for an active delve route.
    -- Its steps intentionally reference the exterior zone, which otherwise produces a
    -- false out-of-zone result while the player is inside the matching delve instance.
    if self:IsInDelveRouteContext(self.ActiveRoute) then
        self:PrintZoneDebug("Matched active delve scenario - returning TRUE")
        self._lastRouteZoneCheck = GetTime()
        self._lastRouteZoneResult = true
        return true
    end

    local _, fallbackMapID = self:GetCurrentRouteMapIDsAndName()

    -- Get step zones
    local stepZones = self:GetStepZoneList(step, fallbackMapID)
    if #stepZones == 0 then
        self._lastRouteZoneCheck = now
        self._lastRouteZoneResult = false
        return false
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
    }

    -- Execute continent-filtered checks
    for index, checkFunc in ipairs(continentChecks) do
        local checkNames = {
            "DirectMatch", "HierarchyMatch", "DescendantMatch"
        }

        self:PrintZoneDebug("Running Check #" .. index .. " (" .. (checkNames[index] or UNKNOWN) .. ")...")

        local result = checkFunc()

        self:PrintZoneDebug("Check #" .. index .. " (" .. (checkNames[index] or UNKNOWN) .. "): " .. tostring(result))

        if result then
            self:PrintZoneDebug("Match at check #" .. index .. " (" .. (checkNames[index] or UNKNOWN) .. ")")
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

function APR:GetLevelProfileTarget(name, refresh)
    self.levelProfileCache = self.levelProfileCache or {}
    self.levelProfileCacheLevels = self.levelProfileCacheLevels or {}
    local playerLevel = UnitLevel("player") or self.Level or 0
    if self.levelProfileCache[name] and self.levelProfileCacheLevels[name] == playerLevel and not refresh then
        return self.levelProfileCache[name]
    end
    local profile = self.LevelRequirementProfiles and self.LevelRequirementProfiles[name]
    assert(profile and profile.levels and profile.levels[0], "Unknown or invalid level profile: " .. tostring(name))
    local bonus = 0
    local seen = {}
    for _, sourceName in ipairs(profile.bonuses or {}) do
        local source = self.LevelBonusSources and self.LevelBonusSources[sourceName]
        assert(source, "Unknown level bonus source: " .. tostring(sourceName))
        local inLevelRange = (not source.minLevel or playerLevel >= source.minLevel) and
            (not source.maxLevelExclusive or playerLevel < source.maxLevelExclusive)
        if not seen[sourceName] and inLevelRange then
            seen[sourceName] = true
            local active = source.isActive and source.isActive()
            local auraBonus = 0
            for spellID, value in pairs(source.auraBonuses or {}) do
                local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
                if aura then
                    active = true
                    local amount = value
                    if type(value) == "table" then
                        local stacks = aura.applications
                        -- Do not compare restricted aura values; assume only one known application.
                        if (issecretvalue and issecretvalue(stacks)) or type(stacks) ~= "number" then
                            stacks = 1
                        end
                        stacks = math.max(1, stacks)
                        amount = 0
                        for count, percent in pairs(value) do
                            if stacks >= count then amount = math.max(amount, percent) end
                        end
                    end
                    auraBonus = math.max(auraBonus, amount)
                end
            end
            for _, aura in ipairs(source.auras or {}) do
                if self:HasAura(aura) then
                    active = true
                    break
                end
            end
            if active then
                local amount = math.max(source.bonus or 0, auraBonus)
                for achievement, percent in pairs(source.achievementBonuses or {}) do
                    if self:HasAchievement(achievement) then amount = math.max(amount, percent) end
                end
                bonus = bonus + amount
            end
        end
    end
    local breakpoint, target = 0, profile.levels[0]
    for percent, requiredLevel in pairs(profile.levels) do
        if percent <= bonus and percent > breakpoint then
            breakpoint, target = percent, requiredLevel
        end
    end
    self.levelProfileCache[name] = target
    self.levelProfileCacheLevels[name] = playerLevel
    return target
end

-- Return at most one usable bag item per missing bonus source, in profile order.
function APR:GetLevelConsumableReminders(profileName)
    local result, seen = {}, {}
    local profile = profileName and self.LevelRequirementProfiles[profileName]
    if profileName then assert(profile, "Unknown level profile: " .. tostring(profileName)) end
    local sources = profile and profile.bonuses or {}
    if not profileName then
        for name in pairs(self.LevelBonusSources) do sources[#sources + 1] = name end
        table.sort(sources)
    end
    local level = UnitLevel("player")
    if level >= GetMaxLevelForPlayerExpansion() then return result end
    for _, name in ipairs(sources) do
        local source = self.LevelBonusSources[name]
        assert(source, "Unknown level bonus source: " .. tostring(name))
        if not seen[name] and source.items and
            (not source.minLevel or level >= source.minLevel) and
            (not source.maxLevelExclusive or level < source.maxLevelExclusive) then
            seen[name] = true
            local active = source.isActive and source.isActive()
            for _, id in ipairs(source.auras or {}) do
                if self:HasAura(id) then
                    active = true; break
                end
            end
            for id in pairs(source.auraBonuses or {}) do
                if self:HasAura(id) then
                    active = true; break
                end
            end
            if not active then
                for _, itemID in ipairs(source.items) do
                    -- Exclude bank, reagent bank and Warband bank contents.
                    if C_Item.GetItemCount(itemID, false, false, false, false) > 0 and
                        C_Item.IsUsableItem(itemID) then
                        result[#result + 1] = itemID
                        break
                    end
                end
            end
        end
    end
    return result
end

function APR:RefreshLevelProfileTargets()
    -- Only evaluate profiles already used; coalesce all changes into one refresh.
    local changed = false
    for name, previous in pairs(self.levelProfileCache or {}) do
        if self:GetLevelProfileTarget(name, true) ~= previous then changed = true end
    end
    if changed and self.ActiveRoute then
        self:UpdateStep()
        if changed then self.questOrderList:DelayedUpdate(true) end
        return true
    end
    return false
end

function APR:ResolveLevelRequirement(value)
    local numeric = tonumber(value)
    if numeric or type(value) ~= "string" then return numeric end
    return self:GetLevelProfileTarget(value)
end

function APR:GetGrindStepText(value)
    local target = self:ResolveLevelRequirement(value)
    local text = string.format(L["GRIND"], math.floor(target))
    local progress = (target - math.floor(target)) * 100
    if progress > 0 then text = text .. string.format(" + %g%% XP", progress) end
    return text
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

function APR:IsInterfaceVersion(requiredInterfaceVersion)
    local expectedVersion = tonumber(requiredInterfaceVersion)
    local currentVersion = tonumber(self.interfaceVersion)

    if not currentVersion and GetBuildInfo then
        currentVersion = tonumber(select(4, GetBuildInfo()))
    end

    return expectedVersion ~= nil and currentVersion == expectedVersion
end

function APR:AreConditionalFiltersMet(conditions)
    -- Legacy route instructions are now optional global XP overlay reminders.
    -- Keep their slots in the definition so saved step indexes remain valid.
    if conditions and conditions.WarMode then return false end
    if conditions and conditions.AnyOf then
        local matched = false
        for _, alternative in ipairs(conditions.AnyOf) do
            if self:AreConditionalFiltersMet(alternative) then
                matched = true; break
            end
        end
        if not matched then return false end
    end
    if not conditions then
        return true
    end

    local playerLevel = self:GetPlayerEffectiveLevel()
    local skipForLvl = self:ResolveLevelRequirement(conditions.SkipForLvl)
    local level = self:ResolveLevelRequirement(conditions.Level)
    local minLevel = self:ResolveLevelRequirement(conditions.MinLevel)
    local maxLevel = self:ResolveLevelRequirement(conditions.MaxLevel)

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
        (not conditions.OnlyInZones or (playerMapID and tContains(conditions.OnlyInZones, playerMapID))) and
        (not conditions.SkipInZones or not (playerMapID and tContains(conditions.SkipInZones, playerMapID))) and
        (conditions.AlliedRace == nil or self:IsAlliedRace() == conditions.AlliedRace) and
        (not conditions.Event or (conditions.Event ~= APR.EVENTS.Remix or self:IsRemixCharacter())) and
        (not conditions.InterfaceVersion or self:IsInterfaceVersion(conditions.InterfaceVersion)) and
        (not conditions.HasAchievement or self:HasAchievement(conditions.HasAchievement)) and
        (not conditions.DontHaveAchievement or not self:HasAchievement(conditions.DontHaveAchievement)) and
        (not conditions.HasAura or self:HasAura(conditions.HasAura)) and
        (not conditions.DontHaveAura or not self:HasAura(conditions.DontHaveAura)) and
        (not conditions.HasSpell or self:IsSpellKnown(conditions.HasSpell)) and
        (not conditions.DontHaveSpell or not self:IsAnySpellKnown(conditions.DontHaveSpell)) and
        (not conditions.IsQuestReadyForTurnIn or self:IsQuestReadyForTurnIn(conditions.IsQuestReadyForTurnIn)) and
        (not conditions.IsQuestOnQuest or C_QuestLog.IsOnQuest(conditions.IsQuestOnQuest)) and
        (not conditions.IsQuestNotOnQuest or not C_QuestLog.IsOnQuest(conditions.IsQuestNotOnQuest)) and
        (not conditions.ReputationLevel or self:IsReputationLevelReached(conditions.ReputationLevel)) and
        (not conditions.SkipForReputation or not self:IsReputationLevelReached(conditions.SkipForReputation)) and
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

local function RouteMatchesDisplayName(routeData, displayName)
    if type(routeData) ~= "table" or not displayName then
        return false
    end

    if routeData.label == displayName then
        return true
    end

    if type(routeData.legacyLabels) == "table" then
        for _, legacyLabel in ipairs(routeData.legacyLabels) do
            if legacyLabel == displayName then
                return true
            end
        end
    end

    return false
end

--- Get Route zone mapID and name
---@return Array<number> routeZoneMapIDs MapIDs declared by the route
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
        local routeMapIDs = {}
        local seenMapIDs = {}

        local function AddMapID(value)
            if type(value) == "number" and value ~= 0 and not seenMapIDs[value] then
                seenMapIDs[value] = true
                tinsert(routeMapIDs, value)
            end
        end

        AddMapID(mapID)
        local conditionZones = routeData.conditions and routeData.conditions.Zones or nil
        if type(conditionZones) == "table" then
            for _, zoneID in ipairs(conditionZones) do
                AddMapID(zoneID)
            end
        end

        return routeMapIDs, mapID or 0, routeFileName, expansion
    end

    -- Fast path: route key provided directly.
    local directRouteData = self.RouteQuestStepList[targetedRoute]
    if type(directRouteData) == "table" and directRouteData.expansion and directRouteData.label then
        return BuildRouteResult(targetedRoute, directRouteData)
    end

    -- Display names can be duplicated (e.g. Exile's Reach A/H), so resolve deterministically.
    local matchingRouteKeys = {}
    for routeFileName, routeData in pairs(self.RouteQuestStepList) do
        if type(routeData) == "table" and routeData.expansion and routeData.label and
            RouteMatchesDisplayName(routeData, targetedRoute) then
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
---@return Array<number> routeZoneMapIDs MapIDs declared by the route
---@return number mapID  the main mapid for the route
---@return string routeFileName Route File Name
---@return string expansion expansion name
function APR:GetCurrentRouteMapIDsAndName()
    if self.ActiveRoute and self:GetRouteData(self.ActiveRoute) and self:IsTemporaryRoute(self.ActiveRoute) then
        return self:GetRouteMapIDsAndName(self.ActiveRoute)
    end

    local customPath = APRCustomPath and APRCustomPath[self.PlayerID] or nil
    local currentRouteIndex, currentRouteName
    if customPath then
        currentRouteIndex, currentRouteName = next(customPath)
    end

    local currentRouteKey = self:GetPrimaryCustomPathRouteKey()
    if not currentRouteKey and self.ActiveRoute and self:GetRouteData(self.ActiveRoute) then
        local playerData = APRData and APRData[self.PlayerID] or nil
        local activeStepIndex = playerData and playerData[self.ActiveRoute] or nil
        local activeStep = activeStepIndex and self:GetRouteSteps(self.ActiveRoute)[activeStepIndex] or nil

        -- During the same session the stable route key survives a display-name change.
        -- Do not restore an already completed route when the next saved entry is invalid.
        if activeStep and not activeStep.RouteCompleted then
            currentRouteKey = self.ActiveRoute
        end
    end

    if not currentRouteKey then
        if currentRouteName then
            table.remove(customPath, currentRouteIndex)

            self._missingCustomPathRouteWarnings = self._missingCustomPathRouteWarnings or {}
            if not self._missingCustomPathRouteWarnings[currentRouteName] then
                self._missingCustomPathRouteWarnings[currentRouteName] = true
                local message = string.format(L["ROUTE_NO_LONGER_EXISTS"], currentRouteName)

                if self.PrintError then
                    self:PrintError(message)
                end
                if self.questionDialog and self.questionDialog.CreateRouteTriggerPopup then
                    self.questionDialog:CreateRouteTriggerPopup(message, {}, nil, nil, nil)
                end
            end

            if self.routeconfig then
                self.routeconfig:CheckIsCustomPathEmpty()
            end

            -- Keep a later valid route usable instead of leaving the current-step frame empty.
            if next(customPath) then
                return self:GetCurrentRouteMapIDsAndName()
            end
        elseif not APRCustomPath or not APRCustomPath[self.PlayerID] then
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

    local routeData = self:GetRouteData(routeFileName)
    if currentRouteIndex and routeData and routeData.label and currentRouteName ~= routeData.label then
        customPath[currentRouteIndex] = routeData.label
        self:Debug("APR:GetCurrentRouteMapIDsAndName - migrated route label", currentRouteName, routeData.label)
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
        if RouteMatchesDisplayName(routeData, displayName) then
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
    playerData[routeFileName .. '-ParallelStepsState'] = nil

    local routeSignatures = playerData.RouteSignatures
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
                    APR.farstrider:GetMeToRightZone()
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

    -- Progress and its fingerprints must belong to the same character.
    -- Legacy profile fingerprints may have been overwritten by another character.
    playerData.RouteSignatures = playerData.RouteSignatures or {}
    local routeSignatures = playerData.RouteSignatures

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
