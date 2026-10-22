-- Instance entrances are destinations outside an instance, never fabricated
-- teleport edges to an interior map's centre or a guessed return landing.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("entrances", 1) then return end
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

function Instance:ResolveEntranceDefinitions(entries, character)
    if not entries then return {}, "unknown_entrance" end
    character = character or (self.env.getCharacter and self.env.getCharacter()) or {}
    local result, reason = {}, "candidate"
    for _, definition in ipairs(entries) do
        if definition.reviewStatus == "confirmed" then
            local allowed, invalid = self:CheckRequirements(definition.requirements, character)
            if allowed == nil then reason = "pending_data"
            elseif not allowed then
                if reason ~= "pending_data" then reason = invalid or "requirements_unmet" end
            else
                local position = self:ResolvePosition(definition.exterior, {})
                if position and position.region then
                    local entry = Lib.Copy(definition)
                    entry.position = Lib.Copy(position)
                    result[#result + 1] = entry
                else reason = "pending_data" end
            end
        end
    end
    return result, #result == 0 and reason or nil
end

function Instance:GetEntrancesForMap(mapID, character)
    return self:ResolveEntranceDefinitions(self:GetEntranceDefinitionsForMap(mapID), character)
end

function Instance:GetEntrancesForInstance(instanceID, character)
    return self:ResolveEntranceDefinitions(self.entranceInstances and self.entranceInstances[instanceID], character)
end

local function ChooseClosest(self, entries, reason, character)
    local best, bestDistance
    local position = character and (character.position or character.playerPosition)
    if not position and #entries > 1 and self.env.getPlayerPosition then position = self.env.getPlayerPosition() end
    for _, entry in ipairs(entries) do
        local target = entry.position
        local distance = math.huge
        if position and position.instanceID == target.instanceID then
            distance = (target.x - position.x)^2 + (target.y - position.y)^2
        end
        if not best or distance < bestDistance then best, bestDistance = entry, distance end
    end
    return best, reason
end

function Instance:GetEntranceForMap(mapID, character)
    local entries, reason = self:GetEntrancesForMap(mapID, character)
    return ChooseClosest(self, entries, reason, character)
end

function Instance:GetEntranceForInstance(instanceID, character)
    local entries, reason = self:GetEntrancesForInstance(instanceID, character)
    return ChooseClosest(self, entries, reason, character)
end
