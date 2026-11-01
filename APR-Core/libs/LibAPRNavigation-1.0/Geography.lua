-- Project endpoints into world coordinates and identify their access regions.
-- A shared position alone does not permit walking through a required entrance.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("geography", 9) then return end
local Instance = Lib.Instance
-- These defaults are read-only, including CheckRequirements' character input.
-- Reuse them across walking checks and retries of unavailable map ancestry.
local EMPTY = {}

local function Finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Instance:GetMapAncestryInfo(mapID)
    if not mapID then return nil end
    self.mapInfos = self.mapInfos or {}
    local cached = self.mapInfos[mapID]
    if cached then return cached end
    local info = self.env.getMapInfo and self.env.getMapInfo(mapID)
    -- Map ancestry is static within a client session. Missing records during
    -- loading must remain retryable; InvalidatePositionCache clears successes.
    if info and type(info.mapType) == "number" and type(info.parentMapID) == "number" then
        self.mapInfos[mapID] = info
    end
    return info
end

function Instance:GetWorldInstanceID(instanceID)
    local overrides = self.config.WorldInstanceOverrides
    return (overrides and overrides[instanceID]) or instanceID
end

local function WorldRegion(region, source, target)
    if type(region) == "string" and source ~= nil and source ~= target then
        local prefix = tostring(source) .. ":"
        if region:sub(1, #prefix) == prefix then return tostring(target) .. ":" .. region:sub(#prefix + 1) end
    end
    -- Explicit regions supplied by the host are access boundaries, not caches.
    return region
end

function Instance:NormalizeLocation(location, hint)
    if type(location) ~= "table" then return nil end
    local x, y = location.x, location.y
    local instanceID, mapID = self:GetWorldInstanceID(location.instanceID), location.uiMapID
    if not Finite(x) or not Finite(y) then return nil end
    if location.space == "map" then
        if not self.env.mapToWorld or not mapID or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
        instanceID, x, y = self.env.mapToWorld(mapID, x, y)
    elseif instanceID == nil and mapID and self.env.mapToWorld then
        -- A recorded world point may omit its instance ID. Ask the client for
        -- that coordinate space without replacing the observed X/Y position.
        instanceID = self.env.mapToWorld(mapID, 0.5, 0.5)
    elseif not mapID and self.env.worldToMap and instanceID ~= nil then
        mapID = self.env.worldToMap(instanceID, x, y, hint)
    end
    instanceID = self:GetWorldInstanceID(instanceID)
    if not Finite(instanceID) or not Finite(x) or not Finite(y) then return nil end
    local position = {
        instanceID = instanceID,
        uiMapID = mapID,
        x = x,
        y = y,
        z = location.z,
        floor = location.floor,
        areaID = location.areaID,
        nameGlobal = location.nameGlobal,
        accessKey = location.accessKey,
        noAutoconnect = location.noAutoconnect,
        phaseAgnostic = location.phaseAgnostic,
        isInstance = location.isInstance,
        region = WorldRegion(location.region, location.instanceID, instanceID),
    }
    position.region = self:GetPositionRegion(position)
    return position
end

function Instance:GetPositionRegion(position)
    if not position then return nil end
    local instanceID = self:GetWorldInstanceID(position.instanceID)
    if position.region then return WorldRegion(position.region, position.instanceID, instanceID) end
    local mapID = position.uiMapID
    if not mapID and self.env.worldToMap and position.instanceID ~= nil then
        mapID = self.env.worldToMap(instanceID, position.x, position.y)
    end
    if not mapID then return nil end
    self.regions = self.regions or {}
    local cacheKey = tostring(instanceID) .. ":" .. mapID .. ":" .. tostring(position.isInstance == true)
    local cached = self.regions[cacheKey]
    if cached then return cached end

    local config = self.config
    local isolatedAreas = config.IsolatedAreas or EMPTY
    local mapTypeOverrides = config.MapTypeOverrides or EMPTY
    local continentOverrides = config.ContinentMapOverrides or EMPTY
    local isolatedContinents = config.IsolatedContinents or EMPTY
    local current, outer = mapID, mapID
    local seen, isolation = {}, nil
    -- The nearest isolated ancestor wins. Two points can share world
    -- coordinates while still requiring a portal or an instance entrance.
    for _ = 1, 50 do
        if not current or current == 0 or seen[current] then return nil end
        seen[current] = true
        local info = self:GetMapAncestryInfo(current)
        if not info then return nil end
        if isolation == nil then isolation = isolatedAreas[current] end
        local override = mapTypeOverrides[current]
        local mapType = override and override.mapType or info.mapType
        local continent = continentOverrides[current]
        local region
        if mapType == 2 or continent then
            if isolatedContinents[current] and isolation == nil then
                isolation = "area:" .. outer
            end
            region = tostring(instanceID) .. ":" .. tostring(continent or current) .. ":" .. tostring(isolation or "outdoor")
        elseif mapType == 4 or (self.entranceMaps and self.entranceMaps[current]) then
            -- Native interior maps remain isolated even when the host has no
            -- IsInInstance observation (for example an authored destination).
            -- All verified floors of one instance share its explicit identity.
            local entrances = self.entranceMaps and self.entranceMaps[current]
            local identity = entrances and entrances[1].interiorMapIDs[1] or current
            region = tostring(instanceID) .. ":instance:" .. identity .. ":" .. tostring(isolation or "interior")
        end
        if region then
            self.regions[cacheKey] = region
            return region
        end
        outer, current = current, info.parentMapID
    end
end

function Instance:IsSameAccessRegion(from, to)
    if not from or not to or self:GetWorldInstanceID(from.instanceID) ~= self:GetWorldInstanceID(to.instanceID) then return false end
    if from.accessKey ~= to.accessKey or from.floor ~= to.floor then return false end
    local source, target = self:GetPositionRegion(from), self:GetPositionRegion(to)
    return source ~= nil and source == target
end

function Instance:CanWalk(from, to)
    if not from or not to or from.noAutoconnect or to.noAutoconnect then return false end
    if not to.phaseAgnostic and self.config.MapRequirements then
        local requirements = self:GetMapAccessRequirements(to.uiMapID)
        if requirements and self:CheckRequirements(requirements, EMPTY) ~= true then return false end
    end
    return self:IsSameAccessRegion(from, to)
end

function Instance:GetWalkingSpeed(position, travelSpeed, groundSpeed)
    local mapID = position and position.uiMapID
    if not mapID then return travelSpeed end
    self.groundMaps = self.groundMaps or {}
    local groundOnly = self.groundMaps[mapID]
    if groundOnly == nil then
        local current, restrictions = mapID, self.config.GroundOnlyAreas or EMPTY
        for _ = 1, 50 do
            if restrictions[current] then groundOnly = true; break end
            local info = self:GetMapAncestryInfo(current)
            if not info then return groundSpeed end -- Retry incomplete map data later.
            current = info.parentMapID
            if not current or current == 0 then groundOnly = false; break end
        end
        if groundOnly == nil then return groundSpeed end
        self.groundMaps[mapID] = groundOnly
    end
    return groundOnly and math.min(travelSpeed, groundSpeed) or travelSpeed
end

function Instance:GetDisplayMapName(position)
    -- Some interiors have a client GlobalString but no separate UI map.
    -- Keep only its key in the catalogue and fall back to area/map names.
    local name = position and position.nameGlobal and self.env.getGlobalText and self.env.getGlobalText(position.nameGlobal)
    if type(name) == "string" and name ~= "" then return name end
    name = position and position.areaID and self.env.getAreaName and self.env.getAreaName(position.areaID)
    if type(name) == "string" and name ~= "" then return name end
    -- Names may become available after the map record itself. Read through the
    -- environment; an edge build may memoize this answer for its own lifetime.
    local info = position and position.uiMapID and self.env.getMapInfo and self.env.getMapInfo(position.uiMapID)
    if info and type(info.name) == "string" and info.name ~= "" then return info.name end
    return self:GetText("UNKNOWN", "UNKNOWN")
end

function Instance:ResolvePosition(definition, context)
    if not definition then return nil end
    if definition.dynamic then
        local snapshot = self.dynamicPositions
        if snapshot and snapshot[definition.dynamic] ~= nil then
            return snapshot[definition.dynamic] or nil
        end
        local position
        if definition.dynamic == "player" then
            position = context.playerPosition or context.start
        elseif self.env.getDynamicPosition then
            position = self.env.getDynamicPosition(definition.dynamic)
        end
        position = position and self:NormalizeLocation(position) or nil
        -- Only an edge builder supplies this cache. Ordinary API calls still
        -- read the current bind, house or player position.
        if snapshot then snapshot[definition.dynamic] = position or false end
        return position
    end
    local cached = self.positions[definition]
    if cached then return cached end
    local position = self:NormalizeLocation(definition)
    -- Failed lookups during loading are deliberately not cached.
    if position and position.region then self.positions[definition] = position end
    return position
end
