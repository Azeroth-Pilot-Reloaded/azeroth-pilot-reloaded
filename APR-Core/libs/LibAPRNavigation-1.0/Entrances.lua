-- Instance entrances are destinations outside an instance, never fabricated
-- teleport edges to an interior map's centre or a guessed return landing.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("entrances", 3) then return end
local Instance = Lib.Instance

function Instance:GetEntrances()
    return Lib.Copy(self.entrances or {})
end

function Instance:GetEntranceDefinitionsForMap(mapID)
    if type(mapID) ~= "number" or mapID <= 0 then return nil end
    self.entranceLookup = self.entranceLookup or {}
    local cached = self.entranceLookup[mapID]
    if cached ~= nil then return cached or nil end
    local current, seen = mapID, {}
    for _ = 1, 50 do
        if not current or current == 0 or seen[current] then
            self.entranceLookup[mapID] = false
            return nil
        end
        seen[current] = true
        local entries = self.entranceMaps and self.entranceMaps[current]
        if entries then self.entranceLookup[mapID] = entries; return entries end
        local info = self:GetMapAncestryInfo(current)
        if not info then return nil end -- Loading failures remain retryable.
        current = info.parentMapID
    end
end

-- Metadata stays available when a quest is locked or projection is loading.
-- Consumers use it to recognise an instance step without dropping its arrow.
function Instance:GetEntranceDefinitionForMap(mapID)
    local entries = self:GetEntranceDefinitionsForMap(mapID)
    local fallback
    for _, definition in ipairs(entries or {}) do
        if definition.reviewStatus == "confirmed" then return definition end
        fallback = fallback or definition
    end
    return fallback
end

function Instance:GetEntranceDefinitionForInstance(instanceID)
    local entries = self.entranceInstances and self.entranceInstances[instanceID]
    local fallback
    for _, definition in ipairs(entries or {}) do
        if definition.reviewStatus == "confirmed" then return definition end
        fallback = fallback or definition
    end
    return fallback
end

local function CopyEntrance(definition, position)
    local entry = Lib.Copy(definition)
    entry.position = Lib.Copy(position)
    return entry
end

local function ChooseClosest(self, entries, positions, count, character)
    local best, bestPosition, bestDistance
    local position = character and (character.position or character.playerPosition)
    if not position and count > 1 and self.env.getPlayerPosition then position = self.env.getPlayerPosition() end
    for index, definition in ipairs(entries) do
        local target = positions[index]
        if target then
            local distance = math.huge
            if position and position.instanceID == target.instanceID then
                distance = (target.x - position.x)^2 + (target.y - position.y)^2
            end
            if not best or distance < bestDistance then
                best, bestPosition, bestDistance = definition, target, distance
            end
        end
    end
    if best then return CopyEntrance(best, bestPosition) end
end

local function ResolveEntrances(self, entries, character, closest)
    if not entries then
        if closest then return nil, "unknown_entrance" end
        return {}, "unknown_entrance"
    end
    local suppliedCharacter = character
    character = character or (self.env.getCharacter and self.env.getCharacter()) or {}
    local result, reason, count = {}, "candidate", 0
    for index, definition in ipairs(entries) do
        if definition.reviewStatus == "confirmed" then
            local requirements = self:GetTravelRequirements(definition.requirements, definition.exterior)
            local allowed, invalid = self:CheckRequirements(requirements, character)
            if allowed == nil then reason = "pending_data"
            elseif not allowed then
                if reason ~= "pending_data" then reason = invalid or "requirements_unmet" end
            else
                local position = self:ResolvePosition(definition.exterior, {})
                if position and position.region then
                    count = count + 1
                    if closest then
                        -- Keep only borrowed positions until selection. Copying
                        -- every candidate's approach/metadata discards all but
                        -- one deep copy on the ordinary singular lookup path.
                        result[index] = position
                    else
                        result[count] = CopyEntrance(definition, position)
                    end
                else reason = "pending_data" end
            end
        end
    end
    reason = count == 0 and reason or nil
    if closest then return ChooseClosest(self, entries, result, count, suppliedCharacter), reason end
    return result, reason
end

function Instance:ResolveEntranceDefinitions(entries, character)
    return ResolveEntrances(self, entries, character, false)
end

function Instance:GetEntrancesForMap(mapID, character)
    return self:ResolveEntranceDefinitions(self:GetEntranceDefinitionsForMap(mapID), character)
end

function Instance:GetEntrancesForInstance(instanceID, character)
    return self:ResolveEntranceDefinitions(self.entranceInstances and self.entranceInstances[instanceID], character)
end

function Instance:GetEntranceForMap(mapID, character)
    return ResolveEntrances(self, self:GetEntranceDefinitionsForMap(mapID), character, true)
end

function Instance:GetEntranceForInstance(instanceID, character)
    return ResolveEntrances(self, self.entranceInstances and self.entranceInstances[instanceID], character, true)
end
