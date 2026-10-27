local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("conditions", 9) then return end
local Instance = Lib.Instance

local function Contains(values, wanted)
    for _, value in ipairs(values) do
        if value == wanted then return true end
    end
    return false
end

local function CheckQuestList(environment, questIDs, requireAll)
    local pending = false
    for _, questID in ipairs(questIDs) do
        local completed = environment.isQuestCompleted and environment.isQuestCompleted(questID)
        if requireAll and completed == false then return false end
        if not requireAll and completed == true then return true end
        if completed == nil then pending = true end
    end
    if pending then return nil end
    return requireAll
end

-- Different UI maps can each retain their own artwork even while the other
-- timeline is active. Only the actual player map disambiguates those groups;
-- never substitute the simulated departure map of a later journey leg.
function Instance:GetWorldPhase(group)
    local definition = (self.config.PhaseGroups or {})[group]
    if not definition then return nil end
    local mapID
    if self.phaseCharacter then mapID = self.phaseCharacter.mapID
    elseif self.env.getCurrentMapID then mapID = self.env.getCurrentMapID()
    else
        local current = self.env.getCharacter and self.env.getCharacter()
        mapID = current and current.mapID
    end
    if definition.localMaps then
        local seen = {}
        for _ = 1, 50 do
            if not mapID or mapID == 0 or seen[mapID] then break end
            seen[mapID] = true
            local localPhase = definition.localMaps[mapID]
            if localPhase then return localPhase end
            local info = self:GetMapAncestryInfo(mapID)
            mapID = info and info.parentMapID
        end
    end
    local phase
    for _, side in ipairs(definition.sides or {}) do
        local art = self.env.getMapArtID and self.env.getMapArtID(side.mapID)
        if art == nil then return nil end
        if art == side.artID then
            if phase and phase ~= side.phase then return nil end
            phase = side.phase
        end
    end
    return phase
end

-- Map-wide access rules apply to every transport type, including personal
-- teleports and projected world coordinates. Geometry itself stays reusable.
function Instance:GetMapAccessRequirements(mapID)
    local rules = self.config.MapRequirements
    if not rules or not mapID then return nil end
    self.mapAccessRequirements = self.mapAccessRequirements or {}
    local cached = self.mapAccessRequirements[mapID]
    if cached ~= nil then return cached or nil end
    local original, seen = mapID, {}
    for _ = 1, 50 do
        if not mapID or mapID == 0 or seen[mapID] then
            self.mapAccessRequirements[original] = false
            return nil
        end
        seen[mapID] = true
        if rules[mapID] then self.mapAccessRequirements[original] = rules[mapID]; return rules[mapID] end
        local info = self:GetMapAncestryInfo(mapID)
        if not info then return nil end -- Retry incomplete ancestry later.
        mapID = info.parentMapID
    end
end

function Instance:GetTravelRequirements(requirements, from, to)
    if not self.config.MapRequirements then return requirements end
    local additions, seen = {}, {}
    for _, point in ipairs({ from or false, to or false }) do
        local rule = point and not point.phaseAgnostic and self:GetMapAccessRequirements(point.uiMapID)
        if rule and not seen[rule] then
            seen[rule] = true
            additions[#additions + 1] = rule
        end
    end
    if #additions == 0 then return requirements end
    if requirements then table.insert(additions, 1, requirements) end
    return { all = additions }
end

-- Three outcomes: true, false, or nil (the client cannot currently answer).
-- Unknown requirements must never silently unlock a connection.
function Instance:CheckRequirements(requirements, character)
    if requirements == nil then return true end
    if type(requirements) ~= "table" or type(character) ~= "table" then return false, "invalid_requirements" end
    local pending = false
    for key, value in pairs(requirements) do
        local result
        if key == "all" or key == "any" then
            if type(value) ~= "table" then return false, "invalid_requirements" end
            result = key == "all"
            local unknown = false
            for _, child in ipairs(value) do
                local state, reason = self:CheckRequirements(child, character)
                if reason then return false, reason end
                if key == "all" and state == false then
                    result, unknown = false, false
                    break
                end
                if key == "any" and state == true then
                    result, unknown = true, false
                    break
                end
                if state == nil then unknown = true end
            end
            if unknown then result = nil end
        elseif key == "notCondition" then
            local reason
            result, reason = self:CheckRequirements(value, character)
            if reason then return false, reason end
            if result ~= nil then result = not result end
        elseif key == "faction" or key == "raceID" or key == "class" or key == "mapID" then
            if character[key] ~= nil then result = character[key] == value end
        elseif key == "minLevel" or key == "maxLevel" then
            if type(value) ~= "number" then return false, "invalid_requirements" end
            if type(character.level) == "number" then
                result = (key == "minLevel" and character.level >= value) or (key == "maxLevel" and character.level <= value)
            end
        elseif key == "quest" then
            if self.env.isQuestCompleted then result = self.env.isQuestCompleted(value) end
        elseif key == "questAccount" then
            if self.env.isQuestCompletedOnAccount then result = self.env.isQuestCompletedOnAccount(value) end
        elseif key == "achievement" then
            if self.env.isAchievementCompleted then result = self.env.isAchievementCompleted(value) end
        elseif key == "mapArt" then
            if type(value) ~= "table" or type(value.mapID) ~= "number" or type(value.artID) ~= "number" then
                return false, "invalid_requirements"
            end
            local artID = self.env.getMapArtID and self.env.getMapArtID(value.mapID)
            if artID ~= nil then result = artID == value.artID end
        elseif key == "phase" then
            if type(value) ~= "table" or type(value.group) ~= "string" or type(value.phase) ~= "string" then
                return false, "invalid_requirements"
            end
            local phase = self:GetWorldPhase(value.group)
            if phase ~= nil then result = phase == value.phase end
        elseif key == "holiday" then
            if type(value) ~= "string" or value == "" then return false, "invalid_requirements" end
            local active = self.env.isHolidayActive and self.env.isHolidayActive(value)
            if type(active) == "boolean" then result = active end
        elseif key == "housingInitiative" then
            if type(value) ~= "table" or type(value.id) ~= "number" or value.id <= 0 or value.id % 1 ~= 0
                or (value.cycleID ~= nil and type(value.cycleID) ~= "number")
                or (value.neighborhoodGUID ~= nil and type(value.neighborhoodGUID) ~= "string") then
                return false, "invalid_requirements"
            end
            local info = self.env.getHousingInitiative and self.env.getHousingInitiative(character.mapID)
            if type(info) == "table" and info.isLoaded == true and type(info.initiativeID) == "number" then
                result = info.initiativeID == value.id
                if value.cycleID then result = result and info.currentCycleID == value.cycleID end
                if value.neighborhoodGUID then result = result and info.neighborhoodGUID == value.neighborhoodGUID end
            end
        elseif key == "questActive" then
            if self.env.isQuestActive then result = self.env.isQuestActive(value) end
        elseif key == "reputation" then
            if type(value) ~= "table" or type(value.factionID or value.id) ~= "number" then return false, "invalid_requirements" end
            local id, standing = value.factionID or value.id, value.standing or value.minStanding
            local minimum = value.minNativeValue or value.minAmount or (standing == nil and value.amount or nil)
            local relative = value.minStandingAmount or (standing ~= nil and value.amount or nil)
            local maximum = value.maxNativeValue or value.maxAmount
            if standing == nil and relative ~= nil then return false, "invalid_requirements" end
            if standing == nil and minimum == nil and maximum == nil then return false, "invalid_requirements" end
            local unknown, actualStanding = false
            result = true
            if standing ~= nil then
                if type(standing) ~= "number" then return false, "invalid_requirements" end
                actualStanding = self.env.getReputationStanding and self.env.getReputationStanding(id)
                if type(actualStanding) ~= "number" then unknown = true
                elseif actualStanding < standing then result = false end
            end
            if minimum ~= nil then
                if type(minimum) ~= "number" then return false, "invalid_requirements" end
                local amount = self.env.getReputationAmount and self.env.getReputationAmount(id)
                if type(amount) ~= "number" then unknown = true
                elseif amount < minimum then result = false end
            end
            -- BtW's amount is relative to the required reaction rank. Higher
            -- ranks already satisfy it; ATT's native bounds are independent.
            if relative ~= nil then
                if type(relative) ~= "number" then return false, "invalid_requirements" end
                if actualStanding == standing then
                    local amount = self.env.getReputationProgressAmount and self.env.getReputationProgressAmount(id)
                    if type(amount) ~= "number" then unknown = true
                    elseif amount < relative then result = false end
                elseif actualStanding == nil then unknown = true end
            end
            if maximum ~= nil then
                if type(maximum) ~= "number" then return false, "invalid_requirements" end
                local amount = self.env.getReputationAmount and self.env.getReputationAmount(id)
                if type(amount) ~= "number" then unknown = true
                elseif amount > maximum then result = false end
            end
            if result ~= false and unknown then result = nil end
        elseif key == "currency" or key == "item" or key == "skill" then
            if type(value) ~= "table" then return false, "invalid_requirements" end
            local id = value.id
            local minimum
            if key == "currency" then minimum = value.amount or value.min
            elseif key == "item" then minimum = value.count or value.minCount or value.min
            elseif key == "skill" then minimum = value.min or value.level end
            if type(id) ~= "number" or type(minimum) ~= "number" then return false, "invalid_requirements" end
            local getter
            if key == "currency" then getter = self.env.getCurrencyQuantity
            elseif key == "item" then getter = self.env.getItemCount
            elseif key == "skill" then getter = self.env.getSkillLevel end
            local amount = getter and getter(id)
            if type(amount) == "number" then result = amount >= minimum end
        elseif key == "minTime" then
            if type(value) ~= "number" then return false, "invalid_requirements" end
            local now = self.env.getServerTime and self.env.getServerTime()
            if type(now) == "number" then result = now >= value end
        elseif key == "chromieTime" then
            if type(value) ~= "boolean" then return false, "invalid_requirements" end
            local active = self.env.isChromieTimeActive and self.env.isChromieTimeActive()
            if type(active) == "boolean" then result = active == value end
        elseif key == "chromieTimeID" then
            if type(value) ~= "number" then return false, "invalid_requirements" end
            local current = self.env.getChromieTimeID and self.env.getChromieTimeID()
            if type(current) == "number" then result = current == value end
        elseif key == "spellKnown" or key == "spell" then
            if type(value) ~= "number" then return false, "invalid_requirements" end
            if self.env.isSpellKnown then result = self.env.isSpellKnown(value) end
        elseif key == "auraSpellID" then
            if self.env.hasAura then result = self.env.hasAura(value) end
        elseif key == "toyID" then
            if self.env.hasToy then result = self.env.hasToy(value) end
        elseif key == "garrison" then
            if type(value) ~= "table" or type(value.minLevel) ~= "number" then return false, "invalid_requirements" end
            local level = self.env.getGarrisonLevel and self.env.getGarrisonLevel(value.type)
            if level ~= nil then result = level >= value.minLevel end
        elseif key == "questsAny" or key == "questsAll" then
            if type(value) ~= "table" then return false, "invalid_requirements" end
            -- Read the list directly. Building nested predicate tables here
            -- would allocate once for every quest on every route calculation.
            result = CheckQuestList(self.env, value, key == "questsAll")
        elseif key == "maps" or key == "notMaps" then
            if type(value) ~= "table" then return false, "invalid_requirements" end
            if character.mapID ~= nil then
                result = Contains(value, character.mapID)
                if key == "notMaps" then result = not result end
            end
        elseif key == "outdoors" then
            if character.indoors ~= nil then result = character.indoors ~= value end
        elseif key == "notInstance" then
            if character.inInstance ~= nil then result = character.inInstance ~= value end
        elseif key == "inGroup" then
            if character.inGroup ~= nil then result = character.inGroup == value end
        elseif key == "housing" then
            if self.env.getDynamicPosition then result = self.env.getDynamicPosition("housing") ~= nil end
        else
            return false, "unknown_requirement:" .. tostring(key)
        end
        if result == false then return false end
        if result == nil then pending = true end
    end
    if pending then return nil end
    return true
end

local mapListKeys = { "maps", "notMaps" }
local booleanListKeys = { "all", "any" }
local function CollectDepartureMaps(requirements, maps)
    if type(requirements) ~= "table" then return maps end
    if type(requirements.mapID) == "number" then
        maps = maps or {}
        maps[requirements.mapID] = true
    end
    for _, key in ipairs(mapListKeys) do
        if type(requirements[key]) == "table" then
            maps = maps or {}
            for _, mapID in ipairs(requirements[key]) do maps[mapID] = true end
        end
    end
    for _, key in ipairs(booleanListKeys) do
        if type(requirements[key]) == "table" then
            for _, child in ipairs(requirements[key]) do maps = CollectDepartureMaps(child, maps) end
        end
    end
    return CollectDepartureMaps(requirements.notCondition, maps)
end

function Instance:CheckPlanningRequirements(requirements, character)
    local allowed, reason = self:CheckRequirements(requirements, character)
    if allowed == true or reason then return allowed, reason end

    -- A later leg may depart from another map. Test the distinct map values in
    -- the predicate, plus a value outside those sets. This preserves all/any/not
    -- exactly; ignoring map clauses would incorrectly invert negated branches.
    local maps = CollectDepartureMaps(requirements)
    if not maps or not next(maps) then return allowed end
    maps[-1] = true
    local departure = setmetatable({}, { __index = character })
    local unknown = allowed == nil
    for mapID in pairs(maps) do
        departure.mapID = mapID
        local possible, invalid = self:CheckRequirements(requirements, departure)
        if invalid then return false, invalid end
        if possible == true then return true end
        if possible == nil then unknown = true end
    end
    if unknown then return nil end
    return false
end

function Instance:GetItemCount(id)
    return self.env.getItemCount and self.env.getItemCount(id)
end

-- Structured diagnostics keep client names/localisation in the host. Evaluate
-- the same predicates as routing, including alternatives, negation and unknowns.
function Instance:GetRequirementFailures(requirements, character, expected)
    if expected == nil then expected = true end
    local state = self:CheckRequirements(requirements, character)
    if state == expected then return nil end
    local children, keys = {}, {}
    for key in pairs(requirements or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local value = requirements[key]
        local actual = self:CheckRequirements({ [key] = value }, character)
        -- A table is an implicit conjunction. To make it false, any one
        -- satisfied clause may change; preserve that OR in the explanation.
        if actual ~= expected then
            local node
            if key == "notCondition" then
                node = self:GetRequirementFailures(value, character, not expected)
            elseif key == "all" or key == "any" or key == "questsAll" or key == "questsAny" then
                local alternatives = {}
                for _, child in ipairs(value) do
                    if key == "questsAll" or key == "questsAny" then child = { quest = child } end
                    local failure = self:GetRequirementFailures(child, character, expected)
                    if failure then alternatives[#alternatives + 1] = failure end
                end
                local conjunction = key == "all" or key == "questsAll"
                node = { key = conjunction == expected and "all" or "any", children = alternatives }
            else
                node = { key = key, value = value, unknown = actual == nil, negated = not expected }
            end
            if node then children[#children + 1] = node end
        end
    end
    return { key = expected and "all" or "any", children = children }
end

function Instance:GetActionUsability(kind, id, character, ignoreCooldown)
    -- The host checks ownership, cooldowns and client restrictions. Catalogue
    -- metadata adds the reagent and group requirements used by older clients.
    local query = ignoreCooldown and self.env.getActionUsabilityIgnoringCooldown or self.env.getActionUsability
    if not query then return false, "pending_data" end
    local usable, reason = query(kind, id)
    if not usable then return usable, reason end
    local definition = self.actionDefinitions[kind .. ":" .. tostring(id)]
    if definition then
        character = character or (self.env.getCharacter and self.env.getCharacter()) or {}
        local allowed = self:CheckRequirements(definition.requirements, character)
        if allowed ~= true then return false, allowed == nil and "pending_data" or "unavailable" end
        if definition.requiresGroup and not character.inGroup then return false, "requires_group" end
        if definition.reagentID then
            local count = self:GetItemCount(definition.reagentID)
            if count == nil then return false, "pending_data" end
            if count < (definition.reagentCount or 1) then return false, "reagent" end
        end
    end
    return true
end
