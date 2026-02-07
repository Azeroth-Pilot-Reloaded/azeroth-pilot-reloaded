-----------------------------------------------------------
-- Zone Restrictions Data
-- Contains map-specific restrictions and limitations
-----------------------------------------------------------

APR.ZoneRestrictions = {}

-----------------------------------------------------------
-- NO-FLY ZONES
-----------------------------------------------------------
-- Maps where flying mounts are disabled or restricted

APR.ZoneRestrictions.NO_FLY_MAPS = {
    -- Burning Crusade
    [94] = true,  -- Eversong Woods
    [95] = true,  -- Ghostlands
    [110] = true, -- Silvermoon City
    [122] = true, -- Isle of Quel'Danas

    -- Shadowlands
    [1670] = true, -- Oribos
    [1671] = true, -- Oribos (Ring)
    [1543] = true, -- The Maw

    -- Legion (Argus)
    [830] = true, -- Krokuun
    [882] = true, -- Eredath
    [883] = true, -- Vindicaar, Argus
    [885] = true, -- Antoran Wastes

    -- Mists of Pandaria
    [554] = true, -- Timeless Isle

    -- The War Within
    [2346] = true, -- Undermine (11.1)

    -- Misc
    [407] = true, -- Darkmoon Island
}

-----------------------------------------------------------
-- ZONE EXCEPTIONS
-----------------------------------------------------------
-- Zones requiring special handling for continent/hierarchy detection
-- Used by ZoneDetectionUtils for correct zone matching


APR.ZoneRestrictions.ZONE_EXCEPTIONS = {
    -- The War Within - Isle of Dorn
    [2274] = {
        name = "Isle of Dorn",
        continentOverride = 2274,
        reason = "Multi-level underground structure"
    },

    -- Pandaren Starting Zone
    [378] = {
        name = "The Wandering Isle",
        continentOverride = 378,
        reason = "Special starting zone"
    },

    -- Exile's Reach (all variants)
    [1409] = {
        name = "Exile's Reach (Base)",
        continentOverride = 0,
        reason = "Special starting zone",
        isExilesReach = true
    },
    [1726] = {
        name = "Exile's Reach (Alliance)",
        continentOverride = 0,
        reason = "Special starting zone",
        isExilesReach = true
    },
    [1727] = {
        name = "Exile's Reach (Horde)",
        continentOverride = 0,
        reason = "Special starting zone",
        isExilesReach = true
    },
    [1728] = {
        name = "Exile's Reach (Ship)",
        continentOverride = 0,
        reason = "Special starting zone",
        isExilesReach = true
    },

    -- Legacy/Special zones (deprecated map IDs or special handling)
    [905] = {
        name = "Legacy Zone ID",
        continentOverride = 0,
        reason = "Legacy map ID requiring special handling"
    },
    [948] = {
        name = "Legacy Zone ID",
        continentOverride = 0,
        reason = "Legacy map ID requiring special handling"
    },
}

-----------------------------------------------------------
-- HELPER FUNCTIONS
-----------------------------------------------------------

--- Check if a map ID is Exile's Reach
---@param mapID number Map ID to check
---@return boolean isExilesReach
function APR.ZoneRestrictions.IsExilesReachMap(mapID)
    if not mapID then return false end
    local exception = APR.ZoneRestrictions.ZONE_EXCEPTIONS[mapID]
    return exception and exception.isExilesReach == true
end

--- Check if a map ID is Returning Player zone (TWW - Arathi Highlands)
---@param mapID number Map ID to check
---@return boolean isReturningPlayer
function APR.ZoneRestrictions.IsReturningPlayerMap(mapID)
    if not mapID then return false end
    return mapID == 2451
end

--- Check if a map ID requires special handling (has no valid position)
---@param mapID number Map ID to check
---@return boolean needsSpecialHandling
function APR.ZoneRestrictions.IsSpecialHandlingMap(mapID)
    if not mapID then return false end
    -- Exile's Reach and legacy zones
    return mapID == 1409 or mapID == 1726 or mapID == 1727 or mapID == 1728
        or mapID == 905 or mapID == 948
end

--- Get all Exile's Reach map IDs
---@return table exilesReachMaps Array of map IDs
function APR.ZoneRestrictions.GetExilesReachMaps()
    return { 1409, 1726, 1727, 1728 }
end
