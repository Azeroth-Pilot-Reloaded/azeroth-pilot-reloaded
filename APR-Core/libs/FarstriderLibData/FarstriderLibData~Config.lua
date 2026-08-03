-- FarstriderLibData~Config.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

local Config = {}
FarstriderLibData.Config = Config

-- Elevation overrides: mapId -> z coordinate
Config.ElevationOverrides = {
    -- Shadowlands
    [1525] = 4275, -- Revendreth
    [1688] = 4275, -- Revendreth

    [1533] = 6534, -- Bastion

    [1536] = 3307, -- Maldraxxus
    [1689] = 3307, -- Maldraxxus

    [1543] = 4870, -- The Maw
    [1648] = 4870, -- The Maw
    [1911] = 4870, -- Torghast - Entrance
    [1960] = 4870, -- The Maw
    [1961] = 4870, -- Korthia

    [1550] = 5270, -- Shadowlands

    [1565] = 5581, -- Ardenweald
    [1603] = 5581, -- Ardenweald
    [1709] = 5581, -- Ardenweald
    [2005] = 5581, -- Ardenweald

    [1670] = 5270, -- Ring of Fates
    [1671] = 5450, -- Ring of Transference
    [1672] = 5250, -- The Broker's Den
    [1673] = 5630, -- The Crucible

    [2016] = 4789, -- Tazavesh, the Veiled Market

    -- Dragonflight
    [2023] = 200, -- Ohn'ahran Plains
    [2024] = 446, -- The Azure Span
    [2025] = 888, -- Thaldraszus
    [2112] = 888, -- Valdrakken
}

-- Map type overrides: mapId -> { mapType = Enum.UIMapType.* }
Config.MapTypeOverrides = {
    [125] = { mapType = 3 },  -- Dalaran: Northrend (Dungeon -> Zone)
    [627] = { mapType = 3 },  -- Dalaran: Broken Isles (Dungeon -> Zone)
    [1670] = { mapType = 3 }, -- Oribos (Dungeon -> Zone)
    [1671] = { mapType = 3 }, -- Oribos (Dungeon -> Zone)
    [1672] = { mapType = 3 }, -- Oribos (Dungeon -> Zone)
    [1673] = { mapType = 3 }, -- Oribos (Dungeon -> Zone)
    [2305] = { mapType = 3 }, -- Dalaran (Dungeon -> Zone)
    [2537] = { mapType = 3 }, -- Quel'Thalas (Continent -> Zone)
}

Config.ContinentMapOverrides = {
    [2537] = 13, -- Quel'Thalas -> Eastern Kingdoms
}

local isolatedAreasCounter = -1
local function _i() return isolatedAreasCounter end
local function _I()
    isolatedAreasCounter = isolatedAreasCounter + 1
    return isolatedAreasCounter
end

-- Isolated area groups: mapId -> groupId (same groupId = same isolated area)
Config.IsolatedAreas = {
    -- Eastern Kingdom
    [94] = _I(),   -- Eversong Woods (Pandaria and newer)
    [95] = _i(),   -- Ghostlands (Pandaria and newer)
    [110] = _i(),  -- Silvermoon City (Pandaria and newer)
    [1941] = _i(), -- Eversong Woods (Cataclysm and older)
    [1942] = _i(), -- Ghostlands (Cataclysm and older)
    [1954] = _i(), -- Silvermoon City (Cataclysm and older)

    [97] = _I(),   -- Azuremyth Isle (Pandaria and newer)
    [103] = _i(),  -- The Exodar (Pandaria and newer)
    [106] = _i(),  -- Bloodmyst Isle (Pandaria and newer)
    [1943] = _i(), -- Azuremyth Isle (Cataclysm and older)
    [1947] = _i(), -- The Exodar (Cataclysm and older)
    [1950] = _i(), -- Bloodmyst Isle (Cataclysm and older)

    [122] = _I(),  -- Isle of Quel'Danas (Pandaria and newer)
    [1957] = _i(), -- Isle of Quel'Danas (Cataclysm and older)

    [201] = _I(),  -- Kelp'thar Forest
    [203] = _i(),  -- Vashj'ir
    [204] = _i(),  -- Abyssal Depths
    [205] = _i(),  -- Shimmering Expanse

    [244] = _I(),  -- Tol Barad
    [245] = _i(),  -- Tol Barad Peninsula

    -- Pandaria
    [504] = _I(), -- Isle of Thunder

    -- Kul Tiras / Zandalar
    [1355] = _I(), -- Nazjatar

    -- Shadowlands
    [1525] = _I(), -- Revendreth
    [1688] = _i(), -- Revendreth

    [1533] = _I(), -- Bastion

    [1536] = _I(), -- Maldraxxus
    [1689] = _i(), -- Maldraxxus

    [1543] = _I(), -- The Maw
    [1648] = _i(), -- The Maw
    [1911] = _i(), -- Torghast - Entrance
    [1960] = _i(), -- The Maw
    [1961] = _i(), -- Korthia

    [1565] = _I(), -- Ardenweald
    [1603] = _i(), -- Ardenweald
    [1709] = _i(), -- Ardenweald
    [2005] = _i(), -- Ardenweald

    [1670] = _I(), -- Ring of Fates
    [1671] = _i(), -- Ring of Transference
    [1672] = _i(), -- The Broker's Den
    [1673] = _i(), -- The Crucible

    [1970] = _I(), -- Zereth Mortis

    [2016] = _I(), -- Tazavesh, the Veiled Market

    -- Dragonflight
    [2133] = _I(), -- Zaralek Cavern

    [2200] = _I(), -- Emerald Dream

    -- Midnight
    [2351] = _I(), -- Razorwind Shores

    [2352] = _I(), -- Founder's Point

    [2405] = _I(), -- Voidstorm

    [2413] = _I(), -- Harandar

    [2541] = _I(), -- Arcantina
}

-- Isolated continents: mapId -> boolean (true = continent is isolated, all areas must match exactly)
Config.IsolatedContinents = {
    [2274] = true, -- Khaz Algar
}
