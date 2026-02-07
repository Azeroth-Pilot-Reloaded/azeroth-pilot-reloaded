local L = LibStub("AceLocale-3.0"):GetLocale("APR")

---=============================================================================
-- Zone Detection System v2.0
-- Improved zone detection with caching, hierarchy support, and exceptions handling
---=============================================================================

--- Initialize zone detector module
function APR:InitZoneDetectionCache()
    if self.ZoneDetection then return end

    self.ZoneDetection = {
        -- Cache: player zone context (TTL = 1 second)
        playerContextCache = {
            mapIDs = {},
            timestamp = 0,
            ttl = 1
        },
        -- Cache: map hierarchy data (persistent)
        hierarchyCache = {},
        -- Cache: map descendants (persistent)
        descendantsCache = {},
        -- Cache: map info (reduces API calls)
        mapInfoCache = {},
        -- Zone exceptions (loaded from ZoneRestrictions)
        exceptions = {},
        -- Debug flag (synchronized with settings)
        debug = (self.settings and self.settings.profile and self.settings.profile.zoneDetectionDebug) or false
    }

    -- Load zone exceptions from ZoneRestrictions
    if APR.ZoneRestrictions and APR.ZoneRestrictions.ZONE_EXCEPTIONS then
        self.ZoneDetection.exceptions = APR.ZoneRestrictions.ZONE_EXCEPTIONS
    end
end

---=============================================================================
-- CONTINENT & MAP INFO FUNCTIONS
---=============================================================================

--- Get the continent map ID for a given zone (defaults to the player's current zone).
-- Walks the map parents until reaching the continent level to keep logic unified across expansions.
---@param mapId number|nil Zone MapID (defaults to player's current zone)
---@return number continentID The continent MapID (0 if not found)
function APR:GetContinent(mapId)
    self:Debug("Function: APR:GetContinent()", mapId)
    mapId = mapId or C_Map.GetBestMapForUnit("player")

    -- Special case: The Wandering Isle
    if mapId == 378 or mapId == 1727 then
        return 378
    end

    if mapId then
        local info = C_Map.GetMapInfo(mapId)
        if info then
            -- Walk up parent chain until we find continent (mapType == 2)
            while info and info.mapType and info.mapType > 2 do
                info = C_Map.GetMapInfo(info.parentMapID)
            end
            if info and info.mapType == 2 then
                return info.mapID
            end
        end
    end

    return 0
end

--- Return the parent map for the player (zone by default) at a given hierarchy level
---@param mapType Enum.UIMapType|nil Map type to find (defaults to Zone)
---@return number|nil parentMapID The parent map ID
function APR:GetPlayerParentMapID(mapType)
    mapType = mapType or Enum.UIMapType.Zone
    local playerMapId
    local currentMapId = C_Map.GetBestMapForUnit('player')
    if currentMapId and Enum and Enum.UIMapType then
        playerMapId = MapUtil.GetMapParentInfo(currentMapId, mapType, true)
        playerMapId = playerMapId and playerMapId.mapID or currentMapId
    end
    return playerMapId
end

--- Check if two maps are on the same continent
---@param mapID1 number First map ID
---@param mapID2 number|nil Second map ID (defaults to player's current map)
---@return boolean isSameContinent
function APR:IsSameContinent(mapID1, mapID2)
    if not mapID1 then return false end
    mapID2 = mapID2 or C_Map.GetBestMapForUnit("player")

    local continent1 = self:GetContinent(mapID1)
    local continent2 = self:GetContinent(mapID2)

    return continent1 == continent2 and continent1 ~= nil
end

--- Get map info with caching to reduce API calls
---@param mapID number Zone MapID
---@return table|nil mapInfo Map information table
function APR:GetMapInfoCached(mapID)
    if not mapID then return nil end

    local cache = self.ZoneDetection.mapInfoCache
    if not cache[mapID] then
        cache[mapID] = C_Map.GetMapInfo(mapID)
    end

    return cache[mapID]
end

--- Invalidate map info cache (call on significant map changes)
function APR:InvalidateMapInfoCache()
    if self.ZoneDetection and self.ZoneDetection.mapInfoCache then
        wipe(self.ZoneDetection.mapInfoCache)
    end
end

---=============================================================================
-- CACHE MANAGEMENT
---=============================================================================

--- Reset player context cache (called on zone change)
function APR:InvalidatePlayerZoneCache()
    if self.ZoneDetection then
        self.ZoneDetection.playerContextCache.timestamp = 0
    end
    -- Also invalidate route zone check throttle
    self._lastRouteZoneCheck = nil
    self._lastRouteZoneResult = nil
    -- Invalidate map info cache
    self:InvalidateMapInfoCache()
end

--- Check if cache is still valid
local function IsCacheValid(cache)
    if not cache.timestamp or cache.timestamp == 0 then
        return false
    end
    local elapsed = GetTime() - cache.timestamp
    return elapsed < cache.ttl
end

---=============================================================================
-- CORE HIERARCHY FUNCTIONS
---=============================================================================

--- Get the complete parent hierarchy of a map (bottom-up)
--- Returns: list of mapIDs from current to continent root
---@param mapID number Zone MapID to start from
---@return table parentChain List of parent mapIDs (including mapID itself)
function APR:GetMapParentChain(mapID)
    if not mapID or mapID == 0 then return {} end

    local chain = {}
    local current = mapID
    local maxDepth = 50 -- Prevent infinite loops
    local depth = 0

    while current and current ~= 0 and depth < maxDepth do
        table.insert(chain, current)

        local mapInfo = C_Map.GetMapInfo(current)
        if not mapInfo or not mapInfo.parentMapID or mapInfo.parentMapID == current then
            break
        end

        current = mapInfo.parentMapID
        depth = depth + 1
    end

    return chain
end

--- Get all descendants of a map recursively
--- Returns: flat list of all child mapIDs at any depth
---@param parentMapID number Parent MapID to search from
---@param maxDepth number Maximum recursion depth (default: 10)
---@return table descendants List of all child mapIDs
function APR:GetAllMapDescendants(parentMapID, maxDepth)
    if not parentMapID or parentMapID == 0 then return {} end

    local cached = self.ZoneDetection.descendantsCache[parentMapID]
    if cached then
        return cached
    end

    maxDepth = maxDepth or 10
    local descendants = {}
    local processed = {}

    local function recurse(currentMapID, depth)
        if depth >= maxDepth or processed[currentMapID] then
            return
        end
        processed[currentMapID] = true

        local children = C_Map.GetMapChildrenInfo(currentMapID)
        if not children or #children == 0 then
            return
        end

        for _, childInfo in ipairs(children) do
            if childInfo.mapID and childInfo.mapID ~= 0 then
                table.insert(descendants, childInfo.mapID)
                recurse(childInfo.mapID, depth + 1)
            end
        end
    end

    recurse(parentMapID, 0)

    -- Cache the result
    self.ZoneDetection.descendantsCache[parentMapID] = descendants

    return descendants
end

---=============================================================================
-- PLAYER CONTEXT RESOLUTION
---=============================================================================

--- Get complete zone context for player
--- Returns all relevant mapIDs: current, parent, continent, and full hierarchy
---@return table context { current, parent, continent, hierarchy, allRelevant }
function APR:ResolvePlayerZoneContext()
    -- Check cache validity
    if IsCacheValid(self.ZoneDetection.playerContextCache) then
        return self.ZoneDetection.playerContextCache.mapIDs
    end

    local context = {}

    -- Get current map (best map for player)
    context.current = C_Map.GetBestMapForUnit("player")

    -- Get parent map (zone level)
    context.parent = self:GetPlayerParentMapID()

    -- Get continent
    context.continent = self:GetContinent()

    -- Get full parent chain (hierarchy from current to root)
    context.hierarchy = self:GetMapParentChain(context.current)

    -- Build comprehensive list
    context.allRelevant = {}
    if context.current then table.insert(context.allRelevant, context.current) end
    if context.parent then table.insert(context.allRelevant, context.parent) end
    if context.continent then table.insert(context.allRelevant, context.continent) end
    for _, mapID in ipairs(context.hierarchy or {}) do
        if not self:Contains(context.allRelevant, mapID) then
            table.insert(context.allRelevant, mapID)
        end
    end

    -- Update cache (FIX: actually store the context!)
    self.ZoneDetection.playerContextCache.mapIDs = context
    self.ZoneDetection.playerContextCache.timestamp = GetTime()

    return context
end

---=============================================================================
-- ZONE MATCHING FUNCTIONS
---=============================================================================

--- Check if any of player maps match step zones (simple)
---@param playerContext table Player zone context
---@param stepZones table Zone mapIDs for step
---@return boolean
function APR:CheckDirectMatch(playerContext, stepZones)
    if not playerContext or not stepZones or #stepZones == 0 then
        return false
    end

    for _, playerMapID in ipairs(playerContext.allRelevant or {}) do
        if self:Contains(stepZones, playerMapID) then
            return true
        end
    end

    return false
end

--- Check if player ancestry matches step zones (hierarchy climbing)
---@param playerContext table Player zone context
---@param stepZones table Zone mapIDs for step
---@return boolean
function APR:CheckHierarchyMatch(playerContext, stepZones)
    if not playerContext or not playerContext.hierarchy or not stepZones then
        return false
    end

    for _, mapID in ipairs(playerContext.hierarchy) do
        if self:Contains(stepZones, mapID) then
            return true
        end
    end

    return false
end

--- Check if any player map is child of step zones (hierarchy descending)
---@param playerContext table Player zone context
---@param stepZones table Zone mapIDs for step
---@return boolean
function APR:CheckDescendantMatch(playerContext, stepZones)
    if not playerContext or not stepZones or #stepZones == 0 then
        return false
    end

    for _, stepMapID in ipairs(stepZones) do
        local descendants = self:GetAllMapDescendants(stepMapID, 10)
        if self:ContainsAny(descendants, playerContext.allRelevant) then
            return true
        end
    end

    return false
end

--- Check if player is on same continent as step zones
---@param playerContext table Player zone context
---@param stepZones table Zone mapIDs for step
---@return boolean
function APR:CheckContinentMatch(playerContext, stepZones)
    if not playerContext or not stepZones or #stepZones == 0 then
        return false
    end

    local playerContinent = playerContext.continent
    if not playerContinent then
        return false
    end

    for _, stepMapID in ipairs(stepZones) do
        local stepContinent = self:GetContinent(stepMapID)
        if stepContinent == playerContinent then
            return true
        end
    end

    return false
end

--- Check if player is near step coordinates (last resort fallback)
---@param step table Current step data
---@param stepZones table Zone mapIDs for step
---@param threshold number Distance threshold in yards (default: 200)
---@return boolean
function APR:CheckCoordinateProximity(step, stepZones, threshold)
    if not step or not stepZones or #stepZones == 0 then
        return false
    end

    threshold = threshold or 200

    local playerY, playerX = UnitPosition("player")
    if not playerY or not playerX then
        return false
    end

    local stepCoord = self:GetStepCoord(step, nil, stepZones[1])
    if not stepCoord then
        return false
    end

    -- Check if player is within threshold of step coordinate
    local dx = playerX - stepCoord.x
    local dy = playerY - stepCoord.y
    local distance = (dx * dx + dy * dy) ^ 0.5

    return distance < threshold
end

---=============================================================================
-- EXCEPTION HANDLING
---=============================================================================

--- Get zone exception configuration if it exists
---@param mapID number Zone mapID
---@return table|nil exception info or nil
function APR:GetZoneException(mapID)
    if not mapID then return nil end

    return self.ZoneDetection.exceptions[mapID]
end

--- Register custom zone exception
---@param mapID number Zone mapID
---@param exception table Exception config { name, continentOverride, ... }
function APR:RegisterZoneException(mapID, exception)
    if not mapID or not exception then return end

    self.ZoneDetection.exceptions[mapID] = exception
end

--- Check if player is in special instance content
---@return boolean
function APR:IsInSpecialContent()
    local mapID = C_Map.GetBestMapForUnit("player")
    local exception = self:GetZoneException(mapID)

    if exception then
        return true
    end

    -- Also check for actual instances
    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance then
            return instanceType == "scenario" or instanceType == "party"
                or instanceType == "raid"
        end
    end

    return false
end

---=============================================================================
-- DEBUGGING & DIAGNOSTICS
---=============================================================================

--- Enable/disable debug mode for zone detection
---@param enabled boolean
function APR:SetZoneDetectionDebug(enabled)
    if self.settings and self.settings.profile then
        self.settings.profile.zoneDetectionDebug = enabled
    end
    if self.ZoneDetection then
        self.ZoneDetection.debug = enabled
    end
end

--- Log detailled zone detection information
---@param context string Context label
---@param playerContext table Player zone context
---@param stepZones table Step zone mapIDs
---@param result boolean Detection result
function APR:DebugZoneDetection(context, playerContext, stepZones, result)
    if not self.settings or not self.settings.profile or not self.settings.profile.zoneDetectionDebug then
        return
    end

    local msg = string.format(
        "%s - Player: {%s} | Step: {%s} | Result: %s",
        context,
        table.concat(playerContext.allRelevant or {}, ","),
        table.concat(stepZones or {}, ","),
        tostring(result)
    )

    self:PrintZoneDebug(msg)
end

--- Get complete zone detection report
---@return table report Detailed diagnostic info
function APR:GetZoneDetectionReport()
    local playerContext = self:ResolvePlayerZoneContext()

    return {
        playerCurrent = playerContext.current,
        playerParent = playerContext.parent,
        playerContinent = playerContext.continent,
        playerHierarchy = playerContext.hierarchy,
        allRelevantMaps = playerContext.allRelevant,
        cacheValid = IsCacheValid(self.ZoneDetection.playerContextCache),
        specialContent = self:IsInSpecialContent(),
        timestamp = GetTime()
    }
end

---=============================================================================
-- INITIALIZATION
---=============================================================================

-- Hook into zone change event to invalidate cache
local zoneChangeFrame = CreateFrame("Frame")
zoneChangeFrame:RegisterEvent("ZONE_CHANGED")
zoneChangeFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneChangeFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneChangeFrame:SetScript("OnEvent", function(self, event)
    if APR and APR.InvalidatePlayerZoneCache then
        APR:InvalidatePlayerZoneCache()
    end
end)
