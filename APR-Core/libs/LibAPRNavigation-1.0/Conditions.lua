local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("conditions", 7) then return end
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
        elseif key == "questActive" then
            if self.env.isQuestActive then result = self.env.isQuestActive(value) end
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
