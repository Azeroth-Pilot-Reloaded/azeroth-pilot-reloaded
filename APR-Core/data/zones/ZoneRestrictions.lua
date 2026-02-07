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
    [1727] = {
        name = "exile's Reach",
        continentOverride = 0,
        reason = "Special starting zone"
    },
}
