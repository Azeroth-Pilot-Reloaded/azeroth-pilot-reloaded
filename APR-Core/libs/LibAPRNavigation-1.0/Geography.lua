-- Project endpoints into world coordinates and identify their access regions.
-- A shared position alone does not permit walking through a required entrance.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("geography", 17) then return end
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

local function BoundedMaplessSpace(space)
    return space and space.bounds ~= nil and space.mapIDs and #space.mapIDs == 0
end

function Instance:CanObserveWithoutUiMap(position)
    if not position or position.uiMapID ~= nil or not self.ResolveNavigationSpace then return false end
    local space, reason = self:ResolveNavigationSpace(position)
    if space and space.known and BoundedMaplessSpace(space) then return true, space, reason end
    if reason ~= "ambiguous_navigation_space" then return false, nil, reason end
    -- Retain raw world observations during an ambiguous floor lookup, but only
    -- when one of the actual candidates is a declared bounded mapless space.
    local query = {}
    for key, value in pairs(position) do query[key] = value end
    for _, candidate in ipairs(self.config.NavigationSpaces or EMPTY) do
        if BoundedMaplessSpace(candidate) and candidate.worldID == self:GetWorldInstanceID(position.instanceID) then
            query.spaceID = candidate.id
            local matched, pending = self:ResolveNavigationSpace(query)
            if (matched and matched.known) or pending == "navigation_space_identity_unavailable" then return true, nil, reason end
        end
    end
    return false, nil, reason
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
        local definition = location.spaceID and self.GetNavigationSpace and self:GetNavigationSpace(location.spaceID)
        if not BoundedMaplessSpace(definition) and not self:CanObserveWithoutUiMap(location) then
            mapID = self.env.worldToMap(instanceID, x, y, hint)
        end
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
        terrainNodeKey = location.terrainNodeKey,
        movementMode = location.movementMode,
        positionSource = location.positionSource,
        observedZ = location.observedZ,
        heightSource = location.heightSource,
        indoors = location.indoors,
        airborne = location.airborne,
        spaceID = location.spaceID,
        spaceKind = location.spaceKind,
        groundOnly = location.groundOnly,
        noFly = location.noFly,
        requiresExit = location.requiresExit,
        region = WorldRegion(location.region, location.instanceID, instanceID),
    }
    if self.ResolveNavigationSpace then
        local space = self:ResolveNavigationSpace(position)
        if space then
            position.spaceID, position.spaceKind = space.id, space.kind
            position.floor, position.accessKey = position.floor or space.floor, position.accessKey or space.accessKey
            position.groundOnly = position.groundOnly or space.groundOnly
            position.requiresExit = space.requiresExit
        end
    end
    position.region = self:GetPositionRegion(position)
    return position
end

function Instance:GetNativePositionRegion(position)
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
        elseif mapType == 6 or (info.parentMapID == 0 and (mapType == 3 or mapType == 5)) then
            -- Native Orphan maps are their own walking roots, even with a UI
            -- parent. Standalone zones/micro maps likewise bound local access,
            -- including descendants, without connecting separate roots.
            region = tostring(instanceID) .. ":map:" .. current .. ":" .. tostring(isolation or "outdoor")
        end
        if region then
            self.regions[cacheKey] = region
            return region
        end
        outer, current = current, info.parentMapID
    end
end

function Instance:GetPositionRegion(position)
    if not position then return nil end
    if self.ResolveNavigationSpace then
        local space, reason = self:ResolveNavigationSpace(position)
        if space and space.known then
            if space.region then return space.region end
            if position.uiMapID == nil and BoundedMaplessSpace(space) then
                return tostring(self:GetWorldInstanceID(position.instanceID)) .. ":space:" .. space.id
            end
        end
        if not space and (reason ~= "navigation_space_unavailable" or position.spaceID ~= nil) then return nil end
    end
    return self:GetNativePositionRegion(position)
end

function Instance:IsSameAccessRegion(from, to)
    if not from or not to or self:GetWorldInstanceID(from.instanceID) ~= self:GetWorldInstanceID(to.instanceID) then return false end
    if from.accessKey ~= to.accessKey or from.floor ~= to.floor then return false end
    if self.ResolveNavigationSpace then
        local sourceSpace, targetSpace = self:ResolveNavigationSpace(from), self:ResolveNavigationSpace(to)
        if sourceSpace and targetSpace and sourceSpace.id ~= targetSpace.id
            and (sourceSpace.requiresExit or targetSpace.requiresExit) then return false end
    end
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

local NativeCanWalk, NativeSameAccess = Instance.CanWalk, Instance.IsSameAccessRegion
local NativeRegion, NativeWorldRegion = Instance.GetPositionRegion, Instance.GetNativePositionRegion
local NativeWorld, NativeMapInfo = Instance.GetWorldInstanceID, Instance.GetMapAncestryInfo
local WALK_POSITION_FIELDS = { "x", "y", "z", "instanceID", "uiMapID", "spaceID", "region",
    "accessKey", "floor", "areaID", "positionSource", "heightSource", "isInstance", "noAutoconnect", "phaseAgnostic" }
local WALK_CONFIG_FIELDS = { "WorldInstanceOverrides", "IsolatedAreas", "MapTypeOverrides", "ContinentMapOverrides",
    "IsolatedContinents", "NavigationSpaces" }
local WEAK_KEYS = { __mode = "k" }

local function SameWalkPosition(point, snapshot)
    for _, key in ipairs(WALK_POSITION_FIELDS) do if point[key] ~= snapshot[key] then return false end end
    return true
end

local function CompleteWalkMap(owner, point, space)
    if point.uiMapID == nil then
        return space and space.known and (space.region ~= nil or BoundedMaplessSpace(space)) or false
    end
    local current, seen, config = point.uiMapID, {}, owner.config
    for _ = 1, 50 do
        if not current or current == 0 or seen[current] then return false end
        seen[current] = true
        local info = owner:GetMapAncestryInfo(current)
        if not info then return false end
        local override = config.MapTypeOverrides and config.MapTypeOverrides[current]
        local mapType = override and override.mapType or info.mapType
        if mapType == 2 or mapType == 4 or mapType == 6 or info.parentMapID == 0
            or (config.ContinentMapOverrides and config.ContinentMapOverrides[current])
            or (owner.entranceMaps and owner.entranceMaps[current]) then return true end
        current = info.parentMapID
    end
    return false
end

-- Only endpoint geography is reused; target-map requirements remain live.
-- Default queries detect reused/mutated point tables. A search which owns its
-- immutable inputs may explicitly skip those comparisons for this request's
-- lifetime. Public predicates and custom policies keep resolving live data.
function Instance:CreateWalkingPermissionQuery(options)
    local owner, resolver = self, Instance.ResolveNavigationSpace
    local immutable = type(options) == "table" and options.immutablePositions == true
    local cache, epoch = setmetatable({}, WEAK_KEYS), {}
    local function nativePolicy()
        return owner.CanWalk == NativeCanWalk and owner.IsSameAccessRegion == NativeSameAccess
            and owner.GetPositionRegion == NativeRegion and owner.GetNativePositionRegion == NativeWorldRegion
            and owner.GetWorldInstanceID == NativeWorld and owner.GetMapAncestryInfo == NativeMapInfo
            and owner.ResolveNavigationSpace == resolver and Instance.ResolveNavigationSpace == resolver
    end
    local function refresh()
        local config = owner.config
        local spaces = config.NavigationSpaces
        local changed = epoch.config ~= config or epoch.maps ~= owner.mapInfos or epoch.positions ~= owner.positions
            or epoch.regions ~= owner.regions or epoch.entrances ~= owner.entranceMaps
            or epoch.spaceCount ~= #(spaces or EMPTY)
        for _, key in ipairs(WALK_CONFIG_FIELDS) do
            if epoch[key] ~= config[key] then changed = true end
        end
        if not changed then return end
        cache = setmetatable({}, WEAK_KEYS)
        epoch.config, epoch.maps, epoch.positions = config, owner.mapInfos, owner.positions
        epoch.regions, epoch.entrances, epoch.spaceCount = owner.regions, owner.entranceMaps, #(spaces or EMPTY)
        for _, key in ipairs(WALK_CONFIG_FIELDS) do epoch[key] = config[key] end
    end
    local function classify(point)
        local current = cache[point]
        if current and (immutable or SameWalkPosition(point, current.snapshot)) then return current end
        -- Probe completeness before resolving: a map can become available
        -- during these callbacks. Never memoize an earlier partial result just
        -- because a final retry happened to obtain the missing map record.
        local complete = point.uiMapID ~= nil and CompleteWalkMap(owner, point)
        local region = owner:GetPositionRegion(point)
        local space = resolver and owner:ResolveNavigationSpace(point)
        current = { region = region, spaceID = space and space.id, requiresExit = space and space.requiresExit }
        -- Do not retain a negative lookup or a partially loaded native map.
        -- Its next query must be able to observe newly available map metadata.
        if region ~= nil and ((not resolver and point.region ~= nil) or complete
            or (point.uiMapID == nil and CompleteWalkMap(owner, point, space))) then
            if not immutable then
                local snapshot = {}
                for _, key in ipairs(WALK_POSITION_FIELDS) do snapshot[key] = point[key] end
                current.snapshot = snapshot
            end
            cache[point] = current
        else cache[point] = nil end
        return current
    end
    return function(from, to)
        if not nativePolicy() then return owner:CanWalk(from, to) end
        if not from or not to or from.noAutoconnect or to.noAutoconnect then return false end
        if not to.phaseAgnostic and owner.config.MapRequirements then
            local requirements = owner:GetMapAccessRequirements(to.uiMapID)
            if requirements and owner:CheckRequirements(requirements, EMPTY) ~= true then return false end
        end
        if owner:GetWorldInstanceID(from.instanceID) ~= owner:GetWorldInstanceID(to.instanceID)
            or from.accessKey ~= to.accessKey or from.floor ~= to.floor then return false end
        refresh()
        local source, target = classify(from), classify(to)
        if source.spaceID and target.spaceID and source.spaceID ~= target.spaceID
            and (source.requiresExit or target.requiresExit) then return false end
        return source.region ~= nil and source.region == target.region
    end
end

function Instance:GetWalkingSpeed(position, travelSpeed, groundSpeed)
    if position and (position.groundOnly or position.noFly) then return math.min(travelSpeed,groundSpeed) end
    local space = position and self.ResolveNavigationSpace and self:ResolveNavigationSpace(position)
    if space and space.groundOnly then return math.min(travelSpeed,groundSpeed) end
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
