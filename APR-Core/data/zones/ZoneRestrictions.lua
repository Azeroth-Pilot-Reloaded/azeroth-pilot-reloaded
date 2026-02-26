-----------------------------------------------------------
-- Zone Restrictions Data
-- Contains map-specific restrictions and limitations
-----------------------------------------------------------

APR.ZoneRestrictions = {}

-----------------------------------------------------------
-- NO-FLY ZONES
-----------------------------------------------------------
-- Maps where flying mounts are disabled or restricted

APR.ZoneRestrictions.NoFlyMaps = {
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
-- ISOLATED ZONES (NO DIRECT FLYING ACCESS)
-----------------------------------------------------------
-- Zones that require taxi/item/portal/spell access.

APR.ZoneRestrictions.IsolatedMaps = {
    [207] = true,  -- Deepholm
    [245] = true,  -- Tol Barad
    [89] = true,   -- Teldrassil
    [407] = true,  -- Darkmoon Island
    [464] = true,  -- Teldrassil (Exodar/Darnassus area)
    [110] = true,  -- Quel'Thalas (Silvermoon City)
    [95] = true,   -- Quel'Thalas (Ghostlands)
    [94] = true,   -- Quel'Thalas (Eversong Woods)
    [974] = true,  -- Tol Dagor
    [504] = true,  -- Isle of Thunder
    [554] = true,  -- Timeless Isle
    [1282] = true, -- Death Knight Hall
    [2351] = true, -- Razorwind Shores
    [122] = true,  -- Isle of Quel'Danas
    [1355] = true, -- Nazjatar
    [1462] = true, -- Mechagon
    [1670] = true, -- Oribos
    [1671] = true, -- Oribos (upper ring)
    [1533] = true, -- Bastion
    [1536] = true, -- Maldraxxus
    [1525] = true, -- Revendreth
    [1565] = true, -- Ardenweald
    [1543] = true, -- The Maw
    [1961] = true, -- Korthia
    [1970] = true, -- Zereth Mortis
    [830] = true,  -- Argus: Krokuun
    [831] = true,  -- Argus: Vindicaar
    [882] = true,  -- Argus: Eredath
    [885] = true,  -- Argus: Antoran Wastes
    [2200] = true, -- Emerald Dream
    [2214] = true, -- TWW - Ringing-Deeps
    [2215] = true, -- TWW - hallowfall
    [2255] = true, -- TWW - Azj kahet
    [2369] = true, -- TWW - Siren
    [2346] = true, -- Undermine
    [2472] = true, -- K'aresh
    [2413] = true, -- Harandar
    [2405] = true, -- Voidstorm
}

-----------------------------------------------------------
-- ZONE EXCEPTIONS
-----------------------------------------------------------
-- Zones requiring special handling for continent/hierarchy detection
-- Used by ZoneDetectionUtils for correct zone matching


APR.ZoneRestrictions.ZoneExceptions = {
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
    local exception = APR.ZoneRestrictions.ZoneExceptions[mapID]
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

--- Check if a map ID is an isolated zone (no direct flying access)
---@param mapID number Map ID to check
---@return boolean isIsolated
function APR.ZoneRestrictions.IsIsolatedMap(mapID)
    if not mapID then return false end
    return APR.ZoneRestrictions.IsolatedMaps[mapID] == true
end

--- Get all Exile's Reach map IDs
---@return table exilesReachMaps Array of map IDs
function APR.ZoneRestrictions.GetExilesReachMaps()
    return { 1409, 1726, 1727, 1728 }
end
