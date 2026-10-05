-- FarstriderLibData~Connections.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

local L = FarstriderLibData.L

---@enum SpecialLocaId
local SpecialLocaId = {
    TravelTo = 1000,
    FlightpathTo = 1001,
    PortalTo = 1002,
    BoatTo = 1003,
    ZeppelinTo = 1004,
    ItemTo = 1005,
    SpellTo = 1006,
    DalaranArgusPortalStart = 2000,
    DalaranArgusPortalEnd = 2001,
    HearthstoneStart = 3000,
    HearthstoneEnd = 3001,
    DalaranHearthstoneStart = 3002,
    DalaranHearthstoneEnd = 3003,
    GarrisonHearthstoneAllianceStart = 3004,
    GarrisonHearthstoneAllianceEnd = 3005,
    GarrisonHearthstoneHordeStart = 3006,
    GarrisonHearthstoneHordeEnd = 3007,
}

local Connections = {
    helpfulItems = {}
}
FarstriderLibData.Connections = Connections

---@param id number
---@param from WaypointLocation
---@param to WaypointLocation
---@param bidirectional boolean
---@param cost number
local function addEntry(id, from, to, bidirectional, cost)
    local entry = { id = id, from = from, to = to, bidirectional = bidirectional, cost = cost } ---@type Waypoint
    table.insert(FarstriderLibData.Waypoints, entry)
end

local flightpathCount = 0

local function addFlightpath(fromMapId, fromPos, fromIsUI, fromAreaId, toMapId, toPos, toIsUI, toAreaId, cost, condition)
    local from = { unknown1 = 0, flags = 0, loc = { mapId = fromMapId, pos = fromPos, isUI = fromIsUI }, condition = condition, type = 1, important = true, locaId = SpecialLocaId.FlightpathTo, locaArgs = function() return { C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId] } end } ---@type WaypointLocation
    local to = { unknown1 = 0, flags = 0, loc = { mapId = toMapId, pos = toPos, isUI = toIsUI }, condition = condition, type = 1, important = true, locaId = SpecialLocaId.FlightpathTo, locaArgs = function() return { C_Map.GetAreaInfo(fromAreaId) or L["Area_" .. fromAreaId] } end } ---@type WaypointLocation
    addEntry(SpecialLocaId.FlightpathTo + flightpathCount, from, to, true, cost)
    flightpathCount = flightpathCount + 1
end

-- TBC
if GetExpansionLevel() >= 2 then
    -- Both
    addFlightpath(122, { x = 0.4756, y = 0.2590, z = 0 }, true, 4085, 23, { x = 0.7556, y = 0.5412, z = 0 }, true, 139, 60)   -- Shattered Sun Staging Area ↔ Light's Hope Chapel, Eastern Plaguelands
    addFlightpath(122, { x = 0.4756, y = 0.2590, z = 0 }, true, 4085, 95, { x = 0.7403, y = 0.6803, z = 0 }, true, 15947, 30) -- Shattered Sun Staging Area ↔ Zul'Aman, Ghostlands
    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addFlightpath(122, { x = 0.4756, y = 0.2590, z = 0 }, true, 4085, 94, { x = 0.5467, y = 0.5061, z = 0 }, true, 3430, 30) -- Shattered Sun Staging Area ↔ Silvermoon City
    end
end

-- Shadowlands
if GetExpansionLevel() >= 8 then
    -- Both
    addFlightpath(2222, { x = -1902.4399414062, y = 1214.7600097656, z = 5450.8701171875 }, false, 10565, 2222, { x = -3387.6999511719, y = 5461.4599609375, z = 4275.7202148438 }, false, 10982, 10) -- Oribos to Pridefall Hamlet, Revendreth
    addFlightpath(2222, { x = -1902.4399414062, y = 1214.7600097656, z = 5450.8701171875 }, false, 10565, 2222, { x = -6143.7797851562, y = -207.12800598145, z = 5581.919921875 }, false, 11515, 10) -- Oribos to Tirna Vaal, Ardenweald
    addFlightpath(2222, { x = -1902.4399414062, y = 1214.7600097656, z = 5450.8701171875 }, false, 10565, 2222, { x = -4160.75, y = -4629.7700195312, z = 6534.1499023438 }, false, 11473, 10)        -- Oribos to Aspirant's Rest, Bastion
    addFlightpath(2222, { x = -1902.4399414062, y = 1214.7600097656, z = 5450.8701171875 }, false, 10565, 2222, { x = 2580.4699707031, y = -2520.7600097656, z = 3307.5200195312 }, false, 11465, 10) -- Oribos to Theater of Pain, Maldraxxus
    addFlightpath(2222, { x = -1902.4399414062, y = 1214.7600097656, z = 5450.8701171875 }, false, 10565, 2222, { x = -5895.6401367188, y = 4810.740234375, z = 4789.990234375 }, false, 13672, 10)   -- Oribos to Tazavesh, the Veiled Market
end

local boatCount = 0

local function addBoat(fromMapId, fromPos, fromIsUI, fromAreaId, toMapId, toPos, toIsUI, toAreaId, cost, condition)
    local from = { unknown1 = 0, flags = 0, loc = { mapId = fromMapId, pos = fromPos, isUI = fromIsUI }, condition = condition, type = 1, important = true, locaId = SpecialLocaId.BoatTo, locaArgs = function() return { C_Map.GetAreaInfo(fromAreaId) or L["Area_" .. fromAreaId], C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId] } end }
    local to = { unknown1 = 0, flags = 0, loc = { mapId = toMapId, pos = toPos, isUI = toIsUI }, condition = condition, type = 1, important = true, locaId = SpecialLocaId.BoatTo, locaArgs = function() return { C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId], C_Map.GetAreaInfo(fromAreaId) or L["Area_" .. fromAreaId] } end }
    addEntry(SpecialLocaId.BoatTo + boatCount, from, to, true, cost)
    boatCount = boatCount + 1
end

-- Pre-Cataclysm boats (Classic Only - routes removed in the Shattering)
if GetExpansionLevel() < 3 and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addBoat(0, { x = -3831, y = -611, z = 4 }, false, 150, 1, { x = 6448, y = 835, z = 5 }, false, 442, 600)                                  -- Menethil Harbor to Auberdine
        addBoat(1, { x = 6448, y = 835, z = 5 }, false, 442, 1, { x = 8177.5600585938, y = 1002.6599731445, z = 6.66929006577 }, false, 702, 600) -- Auberdine to Rut'theran Village

        if GetExpansionLevel() >= 1 then
            addBoat(1, { x = 6448, y = 835, z = 5 }, false, 442, 530, { x = -4284, y = -11194, z = 13 }, false, 3574, 600) -- Auberdine to Valaar's Berth (Azuremyst Isle)
        end
    end
end

-- Cataclysm+ boats (Classic Only - added in the Shattering)
if GetExpansionLevel() >= 3 and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addBoat(0, { x = -8645.5400390625, y = 1308.25, z = 5.23483991623 }, false, 1519, 1, { x = 8177.5600585938, y = 1002.6599731445, z = 6.66929006577 }, false, 702, 600) -- Stormwind to Rut'theran Village
    end
end

local zeppelinCount = 0

local function addZeppelin(fromMapId, fromPos, fromIsUI, fromAreaId, toMapId, toPos, toIsUI, toAreaId, cost, condition)
    local from = { unknown1 = 0, flags = 0, loc = { mapId = fromMapId, pos = fromPos, isUI = fromIsUI }, condition = condition, type = 1, important = true, locaId = SpecialLocaId.ZeppelinTo, locaArgs = function() return { C_Map.GetAreaInfo(fromAreaId) or L["Area_" .. fromAreaId], C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId] } end }
    local to = { unknown1 = 0, flags = 0, loc = { mapId = toMapId, pos = toPos, isUI = toIsUI }, condition = condition, type = 1, important = true, locaId = SpecialLocaId.ZeppelinTo, locaArgs = function() return { C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId], C_Map.GetAreaInfo(fromAreaId) or L["Area_" .. fromAreaId] } end }
    addEntry(SpecialLocaId.ZeppelinTo + zeppelinCount, from, to, true, cost)
    zeppelinCount = zeppelinCount + 1
end

-- Undercity zeppelins (Classic Only - UC destroyed on retail in BfA)
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addZeppelin(0, { x = 2070.5122070312, y = 289.15798950195, z = 97.03157806396 }, false, 1497, 1, { x = 1842.1899414062, y = -4389.0400390625, z = 135.23300170898 }, false, 1637, 600)     --  Undercity to Orgrimmar
        addZeppelin(0, { x = 2059.9340820312, y = 235.90972900391, z = 99.76524353027 }, false, 1497, 0, { x = -12396.400390625, y = 217.47999572754, z = 1.69035005569 }, false, 117, 600)        --  Undercity to Grom'gol Base Camp
        if GetExpansionLevel() >= 2 then
            addZeppelin(0, { x = 2063.2448730469, y = 364.23959350586, z = 82.50442504883 }, false, 1497, 571, { x = 1950.8000488281, y = -6174.2299804688, z = 24.30380058289 }, false, 495, 600) --  Undercity to Howling Fjord
        end
    end
end

-- Pre-Cataclysm Classic shared routes (zones unchanged between pre-Cata and Cata+)
if GetExpansionLevel() < 3 and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addBoat(56, { x = 0.0637, y = 0.6224, z = 0 }, true, 150, 70, { x = 0.7151, y = 0.5634, z = 0 }, true, 513, 600)        -- Menethil Harbor to Theramore
        if GetExpansionLevel() >= 2 then
            addBoat(56, { x = 0.0510, y = 0.5572, z = 0 }, true, 150, 117, { x = 0.6133, y = 0.6260, z = 0 }, true, 3981, 600)  -- Menethil Harbor to Valgarde
            addBoat(84, { x = 0.1802, y = 0.2584, z = 0 }, true, 1519, 114, { x = 0.5968, y = 0.6941, z = 0 }, true, 3537, 177) -- Stormwind to Borean Tundra
        end
    end
    -- Turtle boats (WotLK+)
    if GetExpansionLevel() >= 2 then
        addBoat(114, { x = 0.7892, y = 0.5365, z = 0 }, true, 4113, 115, { x = 0.4794, y = 0.7876, z = 0 }, true, 4152, 600) -- Unu'pe to Moa'ki Harbor
        addBoat(115, { x = 0.4964, y = 0.7843, z = 0 }, true, 4152, 117, { x = 0.2346, y = 0.5775, z = 0 }, true, 3988, 600) -- Moa'ki Harbor to Kamagua
    end
end

-- Retail and Cata+ Classic boats and zeppelins (same zone maps)
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE or GetExpansionLevel() >= 3 then
    -- Neutral
    addBoat(210, { x = 0.3902, y = 0.6701, z = 0 }, true, 35, 10, { x = 0.7016, y = 0.7327, z = 0 }, true, 392, 600) -- Booty Bay to Ratchet

    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addBoat(56, { x = 0.0637, y = 0.6224, z = 0 }, true, 150, 70, { x = 0.7151, y = 0.5634, z = 0 }, true, 513, 600)        -- Menethil Harbor to Theramore
        if GetExpansionLevel() >= 2 then
            addBoat(56, { x = 0.0510, y = 0.5572, z = 0 }, true, 150, 117, { x = 0.6133, y = 0.6260, z = 0 }, true, 3981, 600)  -- Menethil Harbor to Valgarde
            addBoat(84, { x = 0.1802, y = 0.2584, z = 0 }, true, 1519, 114, { x = 0.5968, y = 0.6941, z = 0 }, true, 3537, 177) -- Stormwind to Borean Tundra
        end
        if GetExpansionLevel() >= 9 then
            addBoat(84, { x = 0.2251, y = 0.5618, z = 0 }, true, 1519, 2022, { x = 0.8216, y = 0.3076, z = 0 }, true, 13644, 150) -- Stormwind to The Waking Shores
        end
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addZeppelin(85, { x = 0.4300, y = 0.6499, z = 0 }, true, 1637, 88, { x = 0.1528, y = 0.2570, z = 0 }, true, 1638, 600)      -- Orgrimmar to Thunder Bluff
        addZeppelin(85, { x = 0.5252, y = 0.5315, z = 0 }, true, 1637, 50, { x = 0.3717, y = 0.5249, z = 0 }, true, 117, 600)       -- Orgrimmar to Grom'gol Base Camp
        if GetExpansionLevel() >= 2 then
            addZeppelin(85, { x = 0.4475, y = 0.6230, z = 0 }, true, 1637, 114, { x = 0.4138, y = 0.5361, z = 0 }, true, 3537, 600) -- Orgrimmar to Borean Tundra
        end
        if GetExpansionLevel() >= 7 then
            addZeppelin(463, { x = 0.7093, y = 0.3823, z = 0 }, true, 368, 862, { x = 0.5803, y = 0.6505, z = 0 }, true, 8499, 600) -- Echo Isles to Zuldazar
        end
        if GetExpansionLevel() >= 9 then
            addZeppelin(1, { x = 0.5598, y = 0.1322, z = 0 }, true, 14, 2022, { x = 0.8165, y = 0.2796, z = 0 }, true, 13644, 150) -- Durotar to The Waking Shores
        end
    end

    -- Turtle boats (WotLK+)
    if GetExpansionLevel() >= 2 then
        addBoat(114, { x = 0.7892, y = 0.5365, z = 0 }, true, 4113, 115, { x = 0.4794, y = 0.7876, z = 0 }, true, 4152, 600) -- Unu'pe to Moa'ki Harbor
        addBoat(115, { x = 0.4964, y = 0.7843, z = 0 }, true, 4152, 117, { x = 0.2346, y = 0.5775, z = 0 }, true, 3988, 600) -- Moa'ki Harbor to Kamagua
    end
end

local portalCount = 0

local function addPortal(bidirectional, fromMapId, fromPos, fromIsUI, fromAreaId, toMapId, toPos, toIsUI, toAreaId, cost, condition)
    local from = { unknown1 = 0, flags = 0, loc = { mapId = fromMapId, pos = fromPos, isUI = fromIsUI }, condition = condition, type = 1, important = true, locaId = SpecialLocaId.PortalTo, locaArgs = function() return { C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId] } end }
    local to = { unknown1 = 0, flags = 0, loc = { mapId = toMapId, pos = toPos, isUI = toIsUI }, condition = bidirectional and condition or nil, type = 1, important = true, locaId = SpecialLocaId.PortalTo, locaArgs = function() return { C_Map.GetAreaInfo(fromAreaId) or L["Area_" .. fromAreaId] } end }
    addEntry(SpecialLocaId.PortalTo + portalCount, from, to, bidirectional, cost)
    portalCount = portalCount + 1
end

-- Wrath of the Lich King
if GetExpansionLevel() >= 2 then
    -- Both
    addPortal(true, 119, { x = 0.4035, y = 0.8309, z = 0 }, true, 4300, 78, { x = 0.5055, y = 0.0773, z = 0 }, true, 4381, 10, function() return C_QuestLog.IsQuestFlaggedCompleted(12546) end) -- Sholazar Basin to Un'Goro Crater
end

-- Pandaria (Retail Only)
if GetExpansionLevel() >= 4 and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addPortal(true, 388, { x = 0.4975, y = 0.6866, z = 0 }, true, 5842, 504, { x = 0.6470, y = 0.7348, z = 0 }, true, 6507, 10) -- Townlong Steppes to Isle of Thunder
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addPortal(true, 388, { x = 0.5065, y = 0.7340, z = 0 }, true, 5842, 504, { x = 0.3315, y = 0.3285, z = 0 }, true, 6507, 10) -- Townlong Steppes to Isle of Thunder
    end
end

-- TBC+ city portals (Classic Only - different positions than retail portal rooms)
if GetExpansionLevel() >= 1 and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Dalaran to Caverns of Time (Wrath+)
    if GetExpansionLevel() >= 2 then
        addPortal(true, 125, { x = 0.2543, y = 0.5155, z = 661 }, true, 4613, 74, { x = 0.5460, y = 0.2830, z = 0 }, true, 2300, 10) -- Dalaran to Caverns of Time

        -- Silver Enclave / Sunreaver's Sanctuary portals to capitals
        if UnitFactionGroup("player") == "Alliance" then
            addPortal(false, 571, { x = 5718.9501953125, y = 719.59997558594, z = 641.72698974609 }, false, 4613, 87, { x = 0.27, y = 0.07, z = 0 }, true, 1537, 10)  -- Silver Enclave to Ironforge
            addPortal(false, 571, { x = 5718.9501953125, y = 719.59997558594, z = 641.72698974609 }, false, 4613, 89, { x = 0.44, y = 0.78, z = 0 }, true, 1657, 10)  -- Silver Enclave to Darnassus
            addPortal(false, 571, { x = 5718.9501953125, y = 719.59997558594, z = 641.72698974609 }, false, 4613, 103, { x = 0.26, y = 0.46, z = 0 }, true, 3557, 10) -- Silver Enclave to Exodar
        end
        if UnitFactionGroup("player") == "Horde" then
            addPortal(false, 571, { x = 5925.7900390625, y = 593.60400390625, z = 640.59301757813 }, false, 4613, 998, { x = 0.85, y = 0.17, z = 0 }, true, 1497, 10) -- Sunreaver's Sanctuary to Undercity
            addPortal(false, 571, { x = 5925.7900390625, y = 593.60400390625, z = 640.59301757813 }, false, 4613, 88, { x = 0.22, y = 0.19, z = 0 }, true, 1638, 10)  -- Sunreaver's Sanctuary to Thunder Bluff
            addPortal(false, 571, { x = 5925.7900390625, y = 593.60400390625, z = 640.59301757813 }, false, 4613, 110, { x = 0.56, y = 0.22, z = 0 }, true, 3487, 10) -- Sunreaver's Sanctuary to Silvermoon
        end
    end

    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addPortal(false, 103, { x = 0.4757, y = 0.6216, z = -138 }, true, 3557, 89, { x = 0.4347, y = 0.7868, z = 0 }, true, 1657, 10)                                               -- Exodar to Darnassus
        addPortal(false, 103, { x = 0.4815, y = 0.6302, z = -138 }, true, 3557, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end) -- Exodar to Blasted Lands

        addPortal(false, 84, { x = 0.4897, y = 0.8736, z = 100 }, true, 1519, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end)   -- Stormwind to Blasted Lands

        addPortal(false, 87, { x = 0.2726, y = 0.0708, z = 501 }, true, 1537, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end)   -- Ironforge to Blasted Lands

        addPortal(false, 89, { x = 0.4399, y = 0.7814, z = 0 }, true, 1657, 103, { x = 0.2627, y = 0.4559, z = -138 }, true, 3557, 10)                                               -- Darnassus to Exodar
        addPortal(false, 89, { x = 0.4422, y = 0.7870, z = 0 }, true, 1657, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end)     -- Darnassus to Blasted Lands

        -- Shattrath portals to capitals
        addPortal(false, 530, { x = -1894.2399902344, y = 5387.8500976562, z = -12.42669963837 }, false, 3703, 87, { x = 0.27, y = 0.07, z = 0 }, true, 1537, 10)  -- Shattrath to Ironforge
        addPortal(false, 530, { x = -1894.2399902344, y = 5387.8500976562, z = -12.42669963837 }, false, 3703, 89, { x = 0.44, y = 0.78, z = 0 }, true, 1657, 10)  -- Shattrath to Darnassus
        addPortal(false, 530, { x = -1894.2399902344, y = 5387.8500976562, z = -12.42669963837 }, false, 3703, 103, { x = 0.26, y = 0.46, z = 0 }, true, 3557, 10) -- Shattrath to Exodar
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addPortal(false, 0, { x = 1949, y = -98, z = 41 }, false, 153, 110, { x = 0.56, y = 0.22, z = 0 }, true, 3487, 30)                                                         -- Ruins of Lordaeron Orb of Translocation to Silvermoon

        addPortal(false, 110, { x = 0.5870, y = 0.2052, z = 48 }, true, 3487, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end) -- Silvermoon to Blasted Lands

        addPortal(false, 86, { x = 0.4648, y = 0.6689, z = 0 }, true, 1637, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end)   -- Orgrimmar to Blasted Lands

        addPortal(false, 88, { x = 0.2297, y = 0.1360, z = 111 }, true, 1638, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end) -- Thunder Bluff to Blasted Lands

        addPortal(false, 998, { x = 0.8527, y = 0.1727, z = 0 }, true, 1497, 17, { x = 0.5390, y = 0.4608, z = 0 }, true, 4, 10, function() return UnitLevel("player") >= 56 end)  -- Undercity to Blasted Lands

        -- Shattrath portals to capitals
        addPortal(false, 530, { x = -1899.6800537109, y = 5392.7299804688, z = -12.42640018463 }, false, 3703, 998, { x = 0.85, y = 0.17, z = 0 }, true, 1497, 10) -- Shattrath to Undercity
        addPortal(false, 530, { x = -1899.6800537109, y = 5392.7299804688, z = -12.42640018463 }, false, 3703, 88, { x = 0.22, y = 0.19, z = 0 }, true, 1638, 10)  -- Shattrath to Thunder Bluff
        addPortal(false, 530, { x = -1899.6800537109, y = 5392.7299804688, z = -12.42640018463 }, false, 3703, 110, { x = 0.56, y = 0.22, z = 0 }, true, 3487, 10) -- Shattrath to Silvermoon
    end
end

-- Pandaria (Classic Only)
if GetExpansionLevel() >= 4 and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addPortal(false, 84, { x = 0.6871, y = 0.1717, z = 117 }, true, 1519, 371, { x = 0.4624, y = 0.8517, z = 63 }, true, 6516, 10, function() return C_QuestLog.IsQuestFlaggedCompleted(29548) end) -- Stormwind to Paw'don Village

        addPortal(false, 394, { x = 0.7086, y = 0.3040, z = 0 }, true, 6142, 103, { x = 0.2627, y = 0.4559, z = -138 }, true, 3557, 10)                                                                 -- Shrine of Seven Stars to Exodar
        addPortal(false, 394, { x = 0.7168, y = 0.3598, z = 0 }, true, 6142, 84, { x = 0.4867, y = 0.8815, z = 149 }, true, 1519, 10)                                                                   -- Shrine of Seven Stars to Stormwind
        addPortal(false, 394, { x = 0.7403, y = 0.4098, z = 0 }, true, 6142, 87, { x = 0.2551, y = 0.843, z = 501 }, true, 1537, 10)                                                                    -- Shrine of Seven Stars to Ironforge
        addPortal(false, 394, { x = 0.7724, y = 0.4350, z = 0 }, true, 6142, 89, { x = 0.4347, y = 0.7868, z = 0 }, true, 1657, 10)                                                                     -- Shrine of Seven Stars to Darnassus
        addPortal(false, 394, { x = 0.6848, y = 0.5298, z = 0 }, true, 6142, 111, { x = 0.5497, y = 0.4023, z = -12 }, true, 3703, 10)                                                                  -- Shrine of Seven Stars to Shattrath
        addPortal(false, 394, { x = 0.6165, y = 0.3960, z = 0 }, true, 6142, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 10)                                                                  -- Shrine of Seven Stars to Dalaran
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addPortal(false, 85, { x = 0.6883, y = 0.4057, z = 40 }, true, 1637, 371, { x = 0.2851, y = 0.1402, z = 248 }, true, 6521, 10, function() return C_QuestLog.IsQuestFlaggedCompleted(29690) end) -- Orgrimmar to Honeydew Village

        addPortal(false, 392, { x = 0.7625, y = 0.5261, z = 0 }, true, 6141, 110, { x = 0.5635, y = 0.2183, z = 48 }, true, 3487, 10)                                                                   -- Shrine of Two Moons to Silvermoon
        addPortal(false, 392, { x = 0.7332, y = 0.4270, z = 0 }, true, 6141, 86, { x = 0.4891, y = 0.5435, z = 0 }, true, 1637, 10)                                                                     -- Shrine of Two Moons to Orgrimmar
        addPortal(false, 392, { x = 0.7382, y = 0.3656, z = 0 }, true, 6141, 88, { x = 0.2238, y = 0.1877, z = 111 }, true, 1638, 10)                                                                   -- Shrine of Two Moons to Thunder Bluff
        addPortal(false, 392, { x = 0.7429, y = 0.4786, z = 0 }, true, 6141, 998, { x = 0.8409, y = 0.1718, z = 0 }, true, 1497, 10)                                                                    -- Shrine of Two Moons to Undercity
        addPortal(false, 392, { x = 0.6336, y = 0.5747, z = 0 }, true, 6141, 111, { x = 0.5497, y = 0.4023, z = -12 }, true, 3703, 10)                                                                  -- Shrine of Two Moons to Shattrath
        addPortal(false, 392, { x = 0.6154, y = 0.3651, z = 0 }, true, 6141, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 10)                                                                  -- Shrine of Two Moons to Dalaran
    end
end

if GetExpansionLevel() >= 6 then
    -- Both
    addPortal(false, 627, { x = 0.7427, y = 0.4930, z = 739 }, true, 7505, 1669, { x = 500.28100585938, y = 1469.6800537109, z = 742.44201660156 }, false, 8714, 10) -- Dalaran to Argus
end

local itemCount = 0
local helpfulItems = {}

local function addItem(itemId, toMapId, toPos, toIsUI, toAreaId, cost, condition)
    local from = { actionOptions = { { type = "item", data = itemId } }, condition = function() return (not condition or condition()) and FarstriderLibData.Util.CanUseItem(itemId) end, unknown1 = 0, dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end, flags = 8, type = 1, important = true, locaId = SpecialLocaId.ItemTo, locaArgs = function() return { FarstriderLibData.Util.GetItemNameSafe(itemId), C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId] } end }
    local to = { unknown1 = 0, flags = 0, loc = { mapId = toMapId, pos = toPos, isUI = toIsUI }, type = 2, locaId = SpecialLocaId.ItemTo, locaArgs = function() return { FarstriderLibData.Util.GetItemNameSafe(itemId), C_Map.GetAreaInfo(toAreaId) } end }
    addEntry(SpecialLocaId.ItemTo + itemCount, from, to, false, cost)
    itemCount = itemCount + 1
    if not helpfulItems[itemId] then
        helpfulItems[itemId] = true
        table.insert(Connections.helpfulItems, itemId)
    end
end

local function addDynamicItemWithMultipleIds(itemIds, dynLoc, dynLocaId, cost, condition)
    local finalActionOptions = {}
    for _, itemId in ipairs(itemIds) do
        table.insert(finalActionOptions, { type = "item", data = itemId, allowAny = true })
    end

    local finalCondition = function()
        if condition and not condition() then
            return false
        end

        for _, itemId in ipairs(itemIds) do
            if FarstriderLibData.Util.CanUseItem(itemId) then
                return true
            end
        end

        return false
    end

    local from = { actionOptions = finalActionOptions, condition = finalCondition, unknown1 = 0, dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end, flags = 8, type = 1, important = true, locaId = SpecialLocaId.ItemTo, locaArgs = function() return { FarstriderLibData.Util.GetItemNameSafe(itemIds[1]), dynLocaId() or L["Unknown Location"] } end }
    local to = { unknown1 = 0, flags = 0, dynLoc = dynLoc, type = 2, locaId = SpecialLocaId.ItemTo, locaArgs = function() return { FarstriderLibData.Util.GetItemNameSafe(itemIds[1]), dynLocaId() or L["Unknown Location"] } end }
    addEntry(SpecialLocaId.ItemTo + itemCount, from, to, false, cost)
    itemCount = itemCount + 1

    for _, itemId in ipairs(itemIds) do
        if not helpfulItems[itemId] then
            helpfulItems[itemId] = true
            table.insert(Connections.helpfulItems, itemId)
        end
    end
end

local spellCount = 0

local function addSpell(spellId, toMapId, toPos, toIsUI, toAreaId, cost, condition)
    local from = { actionOptions = { { type = "spell", data = spellId } }, condition = function() return (not condition or condition()) and FarstriderLibData.Util.CanUseSpell(spellId) end, unknown1 = 0, dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end, flags = 8, type = 1, important = true, locaId = SpecialLocaId.SpellTo, locaArgs = function() return { FarstriderLibData.Util.GetSpellNameSafe(spellId), C_Map.GetAreaInfo(toAreaId) or L["Area_" .. toAreaId] } end }
    local to = { unknown1 = 0, flags = 0, loc = { mapId = toMapId, pos = toPos, isUI = toIsUI }, type = 2, locaId = SpecialLocaId.SpellTo, locaArgs = function() return { FarstriderLibData.Util.GetSpellNameSafe(spellId), C_Map.GetAreaInfo(toAreaId) } end }
    addEntry(SpecialLocaId.SpellTo + spellCount, from, to, false, cost)
    spellCount = spellCount + 1
end

local hearthstones = {}

local function addHearthstone(itemId)
    table.insert(hearthstones, itemId)
end

-- Deeprun Tram (Stormwind <-> Ironforge)
addPortal(true, 84, { x = 0.6962, y = 0.3111, z = 0 }, true, 1519, 87, { x = 0.7693, y = 0.5125, z = 0 }, true, 1537, 30) -- Stormwind to Ironforge via Deeprun Tram

-- Allied Race Portals
-- Void Elf portals (Alliance, quest 79010)
if UnitFactionGroup("player") == "Alliance" then
    addPortal(false, 971, { x = 0.2799, y = 0.2148, z = 0 }, true, 9415, 84, { x = 0.5452, y = 0.1726, z = 0 }, true, 1519, 10)                                                                   -- Telogrus Rift to Stormwind
    addPortal(false, 84, { x = 0.5068, y = 0.0845, z = 0 }, true, 1519, 971, { x = 0.2769, y = 0.2810, z = 0 }, true, 9415, 10, function() return C_QuestLog.IsQuestFlaggedCompleted(79010) end)  -- Stormwind to Telogrus Rift
    addPortal(false, 971, { x = 0.2494, y = 0.2791, z = 0 }, true, 9415, 629, { x = 0.3593, y = 0.7475, z = 0 }, true, 7502, 10)                                                                  -- Telogrus Rift to Dalaran
    addPortal(false, 629, { x = 0.3372, y = 0.7888, z = 0 }, true, 7502, 971, { x = 0.2534, y = 0.2789, z = 0 }, true, 9415, 10, function() return C_QuestLog.IsQuestFlaggedCompleted(79010) end) -- Dalaran to Telogrus Rift
end

-- Lightforged Draenei (raceId=30) — Stormwind to/from Vindicaar
if select(3, UnitRace("player")) == 30 then
    addPortal(false, 84, { x = 0.4806, y = 0.1106, z = 0 }, true, 1519, 940, { x = 0.4995, y = 0.4623, z = 0 }, true, 8714, 10) -- Stormwind to Vindicaar (floor 1)
    addPortal(false, 941, { x = 0.4322, y = 0.2516, z = 0 }, true, 8714, 84, { x = 0.5452, y = 0.1726, z = 0 }, true, 1519, 10) -- Vindicaar (floor 2) to Stormwind
end

-- Dark Iron Dwarf (raceId=34)
if select(3, UnitRace("player")) == 34 then
    if UnitFactionGroup("player") == "Alliance" then
        addPortal(false, 84, { x = 0.4974, y = 0.1067, z = 0 }, true, 1519, 1186, { x = 0.6144, y = 0.2435, z = 0 }, true, 1584, 10) -- Stormwind to Shadowforge City
        addPortal(false, 1186, { x = 0.5930, y = 0.2643, z = 0 }, true, 1584, 84, { x = 0.5449, y = 0.1725, z = 0 }, true, 1519, 10) -- Shadowforge City to Stormwind
    end
end

-- Mechagnome (raceId=37)
if select(3, UnitRace("player")) == 37 then
    if UnitFactionGroup("player") == "Alliance" then
        addPortal(false, 84, { x = 0.4878, y = 0.0898, z = 0 }, true, 1519, 1573, { x = 0.2110, y = 0.6471, z = 0 }, true, 10290, 10) -- Stormwind to Mechagon City
        addPortal(false, 1573, { x = 0.2048, y = 0.6022, z = 0 }, true, 10290, 84, { x = 0.5411, y = 0.1648, z = 0 }, true, 1519, 10) -- Mechagon City to Stormwind
    end
end

-- Highmountain Tauren (raceId=28)
if select(3, UnitRace("player")) == 28 then
    if UnitFactionGroup("player") == "Horde" then
        addPortal(false, 652, { x = 0.4604, y = 0.6374, z = 0 }, true, 7731, 85, { x = 0.4024, y = 0.7812, z = 0 }, true, 1637, 10) -- Thunder Totem to Orgrimmar
        addPortal(false, 85, { x = 0.3815, y = 0.7528, z = 0 }, true, 1637, 652, { x = 0.4418, y = 0.6407, z = 0 }, true, 7731, 10) -- Orgrimmar to Thunder Totem
    end
end

-- Nightborne (raceId=27)
if select(3, UnitRace("player")) == 27 then
    if UnitFactionGroup("player") == "Horde" then
        addPortal(false, 680, { x = 0.5818, y = 0.8733, z = 0 }, true, 7637, 85, { x = 0.4024, y = 0.7812, z = 0 }, true, 1637, 10) -- Suramar to Orgrimmar
        addPortal(false, 85, { x = 0.3859, y = 0.7589, z = 0 }, true, 1637, 680, { x = 0.5955, y = 0.8529, z = 0 }, true, 7637, 10) -- Orgrimmar to Suramar
    end
end

-- Vanilla
-- Both
addHearthstone(6948)                                                  -- Hearthstone
addItem(18984, 83, { x = 0.5985, y = 0.4976, z = 0 }, true, 2255, 60) -- Dimensional Ripper - Everlook
addItem(18986, 71, { x = 0.5151, y = 0.3025, z = 0 }, true, 976, 60)  -- Ultrasafe Transporter: Gadgetzan
addItem(22631, 42, { x = 0.4735, y = 0.7532, z = 0 }, true, 2562, 5)  -- Atiesh, Greatstaff of the Guardian
addItem(22589, 42, { x = 0.4735, y = 0.7532, z = 0 }, true, 2562, 5)  -- Atiesh, Greatstaff of the Guardian (Warlock)
addItem(22630, 42, { x = 0.4735, y = 0.7532, z = 0 }, true, 2562, 5)  -- Atiesh, Greatstaff of the Guardian (Priest)
addItem(22632, 42, { x = 0.4735, y = 0.7532, z = 0 }, true, 2562, 5)  -- Atiesh, Greatstaff of the Guardian (Druid)
-- Druid Teleport
addSpell(18960, 80, { x = 0.44, y = 0.46, z = 0 }, true, 493, 10)     -- Teleport: Moonglade
-- Shaman: Astral Recall (teleports to hearthstone bind location)
do
    local from = { actionOptions = { { type = "spell", data = 556 } }, condition = function() return FarstriderLibData.Util.CanUseSpell(556) and FarstriderLibData.AreaL[GetBindLocation()] end, unknown1 = 0, dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end, flags = 8, type = 1, important = true, locaId = SpecialLocaId.SpellTo, locaArgs = function() return { FarstriderLibData.Util.GetSpellNameSafe(556), GetBindLocation() or L["Unknown Location"] } end }
    local to = { unknown1 = 0, flags = 0, dynLoc = FarstriderLibData.Util.GetBindingLocation, type = 2, locaId = SpecialLocaId.SpellTo, locaArgs = function() return { FarstriderLibData.Util.GetSpellNameSafe(556), GetBindLocation() or L["Unknown Location"] } end }
    addEntry(SpecialLocaId.SpellTo + spellCount, from, to, false, 10)
    spellCount = spellCount + 1
end
addItem(21711, 80, { x = 0.44, y = 0.46, z = 0 }, true, 493, 60)      -- Lunar Festival Invitation
-- Mage Teleports
addSpell(3561, 84, { x = 0.49, y = 0.87, z = 0 }, true, 1519, 10)     -- Teleport: Stormwind
addSpell(3562, 87, { x = 0.27, y = 0.07, z = 0 }, true, 1537, 10)     -- Teleport: Ironforge
addSpell(3565, 89, { x = 0.44, y = 0.78, z = 0 }, true, 1657, 10)     -- Teleport: Darnassus
addSpell(3563, 998, { x = 0.85, y = 0.17, z = 0 }, true, 1497, 10)    -- Teleport: Undercity
addSpell(3566, 88, { x = 0.22, y = 0.19, z = 0 }, true, 1638, 10)     -- Teleport: Thunder Bluff
if GetExpansionLevel() < 3 and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    addSpell(3567, 85, { x = 0.50, y = 0.50, z = 0 }, true, 1637, 10) -- Teleport: Orgrimmar (pre-Cata, map center approximation)
else
    addSpell(3567, 85, { x = 0.57, y = 0.90, z = 0 }, true, 1637, 10) -- Teleport: Orgrimmar
end

-- M+ Dungeon Teleports (learned by completing a timed Mythic+ for each dungeon, 8hr cooldown)
if GetExpansionLevel() >= 6 then
    -- MoP
    addSpell(131204, 870, { x = 957.34899902344, y = -2475.7099609375, z = 188 }, false, 5974, 480)             -- Path of the Jade Serpent (Temple of the Jade Serpent)
    addSpell(131205, 870, { x = -575.95, y = 1465.17, z = 0 }, false, 5805, 480)                                -- Path of the Stout Brew (Stormstout Brewery)
    addSpell(131206, 870, { x = 2966.44, y = 1562.72, z = 0 }, false, 5841, 480)                                -- Path of the Shado-Pan (Shado-Pan Monastery)
    addSpell(131222, 870, { x = 1624.43, y = 770.74, z = 0 }, false, 5840, 480)                                 -- Path of the Mogu King (Mogu'shan Palace)
    addSpell(131225, 870, { x = 389.51, y = 598.22, z = 0 }, false, 5840, 480)                                  -- Path of the Setting Sun (Gate of the Setting Sun)
    addSpell(131228, 870, { x = 2063.63, y = 5999.34, z = 0 }, false, 5842, 480)                                -- Path of the Black Ox (Siege of Niuzao Temple)
    -- WoD
    addSpell(159895, 1116, { x = 6231.16, y = 2917.87, z = 0 }, false, 6720, 480)                               -- Path of the Bloodmaul (Bloodmaul Slag Mines)
    addSpell(159896, 1116, { x = 8850.5751953125, y = 1338.0764160156, z = 98.26377105713 }, false, 7411, 480)  -- Path of the Iron Prow (Iron Docks)
    addSpell(159897, 1116, { x = 2312.48, y = 4281.29, z = 0 }, false, 6662, 480)                               -- Path of the Vigilant (Auchindoun)
    addSpell(159898, 1116, { x = -1220.58, y = 667.43, z = 0 }, false, 6722, 480)                               -- Path of the Skies (Skyreach)
    addSpell(159899, 1116, { x = 752.61285400391, y = 138.52604675293, z = 7.53106021881 }, false, 6872, 480)   -- Path of the Crescent Moon (Shadowmoon Burial Grounds)
    addSpell(159900, 1116, { x = 7890.1674804688, y = 569.22570800781, z = 126.06169891357 }, false, 6901, 480) -- Path of the Dark Rail (Grimrail Depot)
    addSpell(159901, 1116, { x = 7080.8969726562, y = 187.48957824707, z = 144.96086120606 }, false, 7320, 480) -- Path of the Verdant (The Everbloom)
    addSpell(159902, 0, { x = -8466.13, y = -2414.46, z = 0 }, false, 46, 480)                                  -- Path of the Burning Mountain (Upper Blackrock Spire)
    -- Classic
    addSpell(131232, 0, { x = 2489.76, y = -742.61, z = 0 }, false, 28, 480)                                    -- Path of the Necromancer (Scholomance)
    -- Raid Teleports - WoD
    addSpell(169771, 1116, { x = 6944.70, y = -829.01, z = 0 }, false, 6721, 480)                               -- Blackrock Foundry Teleport

    if GetExpansionLevel() >= 8 then
        -- Shadowlands
        addSpell(354462, 2222, { x = -3316.6354980469, y = -4094.1596679688, z = 6605.7768554688 }, false, 10534, 480) -- Path of the Courageous (The Necrotic Wake)
        addSpell(354463, 2222, { x = 2081.96875, y = -3118.6076660156, z = 3273.7973632812 }, false, 11462, 480)       -- Path of the Plagued (Plaguefall)
        addSpell(354464, 2222, { x = -6935.8505859375, y = 1789.1180419922, z = 5552.4487304688 }, false, 11510, 480)  -- Path of the Misty Forest (Mists of Tirna Scithe)
        addSpell(354465, 2222, { x = -2196.8332519531, y = 4987.9204101562, z = 4079.8605957031 }, false, 10413, 480)  -- Path of the Sinful Soul (Halls of Atonement)
        addSpell(354466, 2222, { x = -2130.6752929688, y = -5327.3403320312, z = 6549.6108398438 }, false, 10534, 480) -- Path of the Ascendant (Spires of Ascension)
        addSpell(354467, 2222, { x = 2605.5087890625, y = -2709.59375, z = 3299.7175292969 }, false, 11462, 480)       -- Path of the Undefeated (Theater of Pain)
        addSpell(354468, 2222, { x = -7544.2709960938, y = -583.31427001953, z = 5454.0190429688 }, false, 11510, 480) -- Path of the Scheming Loa (De Other Side)
        addSpell(354469, 2222, { x = -1487.15625, y = 6543.4174804688, z = 4186.3671875 }, false, 10413, 480)          -- Path of the Stone Warden (Sanguine Depths)
        addSpell(367416, 2222, { x = -5905.9633789062, y = 4861.5615234375, z = 4790.7368164062 }, false, 13672, 480)  -- Path of the Streetwise Merchant (Tazavesh, the Veiled Market)
        -- Legacy dungeons (spells added in Shadowlands)
        addSpell(373262, 0, { x = -11044.357421875, y = -1992.6997070312, z = 92.97105407715 }, false, 41, 480)        -- Path of the Fallen Guardian (Return to Karazhan)
        addSpell(373274, 1462, { x = 0.735, y = 0.364, z = 0 }, true, 10290, 480)                                      -- Path of the Scrappy Prince (Operation: Mechagon)
        -- Raid Teleports - Shadowlands
        addSpell(373190, 2222, { x = -2377.38, y = 6113.57, z = 0 }, false, 10413, 480)                                -- Return to Castle Nathria
        addSpell(373191, 2222, { x = 4882.30, y = 5875.35, z = 0 }, false, 11400, 480)                                 -- Return to the Sanctum of Domination
        addSpell(373192, 2374, { x = -3704.53, y = 344.43, z = 0 }, false, 13536, 480)                                 -- Return to the Sepulcher
    end

    if GetExpansionLevel() >= 9 then
        -- Dragonflight
        addSpell(393222, 0, { x = -6063.392578125, y = -3157.1545410156, z = 280.97717285156 }, false, 3, 480)         -- Path of the Watcher's Legacy (Uldaman: Legacy of Tyr)
        addSpell(393256, 2444, { x = 1364.5660400391, y = -160.13542175293, z = 115.10043334961 }, false, 13644, 480)  -- Path of the Clutch Defender (Ruby Life Pools)
        addSpell(393262, 2444, { x = -545.31768798828, y = 2212.3820800781, z = 430.02130126953 }, false, 13645, 480)  -- Path of the Windswept Plains (The Nokhud Offensive)
        addSpell(393267, 2444, { x = -4478.2900390625, y = 4245.3134765625, z = 6.59790039063 }, false, 13837, 480)    -- Path of the Rotting Woods (Brackenhide Hollow)
        addSpell(393273, 2444, { x = 1353.7916259766, y = -2781.515625, z = 731.53930664063 }, false, 13647, 480)      -- Path of the Draconic Diploma (Algeth'ar Academy)
        addSpell(393276, 2444, { x = 2350.5087890625, y = 2627.7985839844, z = 244.04164123535 }, false, 13644, 480)   -- Path of the Obsidian Hoard (Neltharus)
        addSpell(393279, 2444, { x = -5650.2275390625, y = 1273.4947509766, z = 810.103515625 }, false, 13646, 480)    -- Path of Arcane Secrets (The Azure Vault)
        addSpell(393283, 2444, { x = 129.22743225098, y = -2865.4426269531, z = 1227.0003662109 }, false, 13647, 480)  -- Path of the Titanic Reservoir (Halls of Infusion)
        addSpell(393764, 1220, { x = 2454.9721679688, y = 812.42535400391, z = 252.92573547363 }, false, 7541, 480)    -- Path of Proven Worth (Halls of Valor)
        addSpell(393766, 1220, { x = 1017.819519043, y = 3828.6337890625, z = 8.69951534271 }, false, 8148, 480)       -- Path of the Grand Magistrix (Court of Stars)
        -- BfA
        addSpell(410071, 1643, { x = -1606.0538330078, y = -1229.234375, z = 36.98764419556 }, false, 8567, 480)       -- Path of the Freebooter (Freehold)
        addSpell(410074, 1642, { x = 1275.6545410156, y = 762.94964599609, z = -269.123046875 }, false, 8500, 480)     -- Path of Festering Rot (The Underrot)
        addSpell(410078, 1220, { x = 3716.4643554688, y = 4184.9912109375, z = 891.53601074219 }, false, 7503, 480)    -- Path of the Earth-Warder (Neltharion's Lair)
        addSpell(410080, 1, { x = -11522.099609375, y = -2317.4299316406, z = 616.5 }, false, 5034, 480)               -- Path of Wind's Domain (The Vortex Pinnacle)
        -- Cata (spells added in Dragonflight)
        addSpell(424142, 0, { x = -5582.1899414062, y = 5396.8999023438, z = -1797.1700439453 }, false, 5047, 480)     -- Path of the Tidehunter (Throne of the Tides)
        addSpell(424153, 1220, { x = 3122.0278320312, y = 7561.7084960938, z = 32.32332611084 }, false, 7558, 480)     -- Path of Ancient Horrors (Black Rook Hold)
        addSpell(424163, 1220, { x = 3826.4582519531, y = 6359.8271484375, z = 186.68576049805 }, false, 7558, 480)    -- Path of the Nightmare Lord (Darkheart Thicket)
        addSpell(424167, 1643, { x = 796.65802001953, y = 3371.5920410156, z = 234.56396484375 }, false, 8721, 480)    -- Path of Heart's Bane (Waycrest Manor)
        addSpell(424187, 1642, { x = -847.35241699219, y = 2044.3559570312, z = 735.61944580078 }, false, 8499, 480)   -- Path of the Golden Tomb (Atal'Dazar)
        addSpell(424197, 2444, { x = -1512.7795410156, y = -3086.5104980469, z = 1238.9659423828 }, false, 13647, 480) -- Path of Twisted Time (Dawn of the Infinite)
        -- Raid Teleports - Dragonflight
        addSpell(432254, 2444, { x = 2364.85, y = -1308.91, z = 0 }, false, 13647, 480)                                -- Return to the Vault
        addSpell(432257, 2444, { x = -1163.75, y = 115.68, z = 0 }, false, 14022, 480)                                 -- Return to Aberrus
        addSpell(432258, 2548, { x = -1174.16, y = 6040.54, z = 0 }, false, 14529, 480)                                -- Return to Amirdrassil
    end

    if GetExpansionLevel() >= 10 then
        -- The War Within
        addSpell(445269, 2601, { x = 3440.2700195312, y = -2730.2673339844, z = 336.60205078125 }, false, 14795, 480)   -- Path of the Corrupted Foundry (The Stonevault)
        addSpell(445414, 2601, { x = 1445.2951660156, y = -162.24653625488, z = -46.08894729614 }, false, 14838, 480)   -- Path of the Arathi Flagship (The Dawnbreaker)
        addSpell(445416, 2601, { x = -1631.9670410156, y = -751.94268798828, z = -1335.8000488281 }, false, 14753, 480) -- Path of Nerubian Ascension (City of Threads)
        addSpell(445417, 2601, { x = -2177.90625, y = -931.4375, z = -1348.8780517578 }, false, 14753, 480)             -- Path of the Ruined City (Ara-Kara, City of Echoes)
        addSpell(445418, 1643, { x = -212.04513549805, y = -1562.2673339844, z = 6.06085443497 }, false, 8567, 480)     -- Path of the Besieged Harbor (Siege of Boralus)
        addSpell(445424, 0, { x = -4042.3898925781, y = -3444.4499511719, z = 295 }, false, 1037, 480)                  -- Path of the Twilight Fortress (Grim Batol)
        addSpell(445440, 2552, { x = 2647.640625, y = -4896.2534179688, z = 100.88966369629 }, false, 14717, 480)       -- Path of the Flaming Brewery (Cinderbrew Meadery)
        addSpell(445441, 2601, { x = 2800.9270019531, y = -3656.7258300781, z = 368.94158935547 }, false, 14795, 480)   -- Path of the Warding Candles (Darkflame Cleft)
        addSpell(445443, 2552, { x = 2799.9914550781, y = -2186.7534179688, z = 266.83657836914 }, false, 14771, 480)   -- Path of the Fallen Stormriders (The Rookery)
        addSpell(445444, 2215, { x = 0.41, y = 0.34, z = 0 }, true, 14918, 480)                                         -- Path of the Light's Reverence (Priory of the Sacred Flame)
        addSpell(467546, 2601, { x = 1935.0086669922, y = -2683.2846679688, z = 358.87258911133 }, false, 14795, 480)   -- Path of the Waterworks (Operation: Floodgate)
        addSpell(467553, 862, { x = 0.393, y = 0.714, z = 0 }, true, 8499, 480)                                         -- Path of the Azerite Refinery (The MOTHERLODE!!)
        addSpell(1216786, 1462, { x = 0.735, y = 0.364, z = 0 }, true, 10290, 480)                                      -- Path of the Circuit Breaker (Mechagon Workshop)
        addSpell(1237215, 2601, { x = 1935.0086669922, y = -2683.2846679688, z = 358.87258911133 }, false, 14795, 480)  -- Path of the Eco-Dome (Operation: Floodgate)
        -- Alt dungeon teleports
        addSpell(464256, 1643, { x = -212.04513549805, y = -1562.2673339844, z = 6.06085443497 }, false, 8567, 480)     -- Path of the Besieged Harbor (Siege of Boralus, Horde)
        addSpell(467555, 862, { x = 0.393, y = 0.714, z = 0 }, true, 8499, 480)                                         -- Path of the Azerite Refinery (The MOTHERLODE!!, alt)
        -- Raid Teleports - The War Within
        addSpell(1226482, 2706, { x = -54.90, y = 390.63, z = 0 }, false, 15347, 480)                                   -- Return to Undermine
        addSpell(1239155, 2738, { x = 457.29, y = 1100.00, z = 0 }, false, 15336, 480)                                  -- Return to Manaforge Omega
    end

    if GetExpansionLevel() >= 11 then
        -- Midnight
        addSpell(1254572, 2424, { x = 0.60, y = 0.50, z = 0 }, true, 15829, 480)        -- Path of Devoted Magistry (Magisters' Terrace)
        addSpell(1254400, 2395, { x = 0.60, y = 0.80, z = 0 }, true, 15808, 480)        -- Path of the Windrunners (Windrunner Spire)
        addSpell(1254563, 2405, { x = 0.50, y = 0.45, z = 0 }, true, 15954, 480)        -- Path of the Fractured Core (Nexus-Point Xenas)
        addSpell(1254559, 2437, { x = 0.45, y = 0.55, z = 0 }, true, 16395, 480)        -- Path of Cavernous Depths (Maisara Caverns)
        -- Legacy dungeons (spells added in Midnight)
        addSpell(1254551, 1669, { x = -2669.95, y = 9907.29, z = 0 }, false, 8882, 480) -- Path of Dark Dereliction (Seat of the Triumvirate)
        addSpell(1254555, 571, { x = 7091.85, y = 2389.85, z = 0 }, false, 210, 480)    -- Path of Unyielding Blight (Pit of Saron)
        -- Alt dungeon teleports
        addSpell(1254557, 1116, { x = -1220.58, y = 667.43, z = 0 }, false, 6722, 480)  -- Path of the Crowning Pinnacle (Skyreach, alt)
    end
end

-- The Burning Crusade
if GetExpansionLevel() >= 1 then
    -- Both
    addHearthstone(28585)                                                   -- Ruby Slippers
    addItem(30542, 109, { x = 0.3355, y = 0.6767, z = 0 }, true, 3712, 60)  -- Dimensional Ripper - Area 52
    addItem(30544, 105, { x = 0.6091, y = 0.7008, z = 0 }, true, 3918, 60)  -- Ultrasafe Transporter: Toshley's Station
    addItem(32757, 104, { x = 0.6621, y = 0.4398, z = 0 }, true, 3840, 15)  -- Blessed Medallion of Karabor
    addItem(151016, 104, { x = 0.6621, y = 0.4398, z = 0 }, true, 3840, 60) -- Fractured Necrolyte Skull
    -- Mage Teleports
    addSpell(32271, 103, { x = 0.26, y = 0.46, z = 0 }, true, 3557, 10)     -- Teleport: Exodar
    addSpell(32272, 110, { x = 0.56, y = 0.22, z = 0 }, true, 3487, 10)     -- Teleport: Silvermoon
    addSpell(33690, 111, { x = 0.55, y = 0.40, z = 0 }, true, 3703, 10)     -- Teleport: Shattrath (Alliance)
    addSpell(35715, 111, { x = 0.55, y = 0.40, z = 0 }, true, 3703, 10)     -- Teleport: Shattrath (Horde)
end

-- Wrath of the Lich King
if GetExpansionLevel() >= 2 then
    -- Both
    addHearthstone(37118)                                                     -- Scroll of Recall
    addHearthstone(44314)                                                     -- Scroll of Recall II
    addHearthstone(44315)                                                     -- Scroll of Recall III
    addItem(46874, 118, { x = 0.6938, y = 0.2264, z = 0 }, true, 4658, 30)    -- Argent Crusader's Tabard
    addItem(40585, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Signet of the Kirin Tor
    addItem(40586, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Band of the Kirin Tor
    addItem(44934, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Loop of the Kirin Tor
    addItem(44935, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Ring of the Kirin Tor
    addItem(45688, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Inscribed Band of the Kirin Tor
    addItem(45689, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Inscribed Loop of the Kirin Tor
    addItem(45690, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Inscribed Ring of the Kirin Tor
    addItem(45691, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Inscribed Signet of the Kirin Tor
    addItem(48954, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Etched Band of the Kirin Tor
    addItem(48955, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Etched Loop of the Kirin Tor
    addItem(48956, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Etched Ring of the Kirin Tor
    addItem(48957, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Etched Signet of the Kirin Tor
    addItem(50287, 224, { x = 0.3692, y = 0.7599, z = 9 }, true, 35, 30)      -- Boots of the Bay
    addItem(51557, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Runed Signet of the Kirin Tor
    addItem(51558, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Runed Loop of the Kirin Tor
    addItem(51559, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Runed Ring of the Kirin Tor
    addItem(51560, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Runed Band of the Kirin Tor
    addItem(52251, 125, { x = 0.5592, y = 0.4679, z = 661 }, true, 4613, 30)  -- Jaina's Locket
    addItem(48933, 114, { x = 0.50, y = 0.50, z = 0 }, true, 3537, 30)        -- Wormhole Generator: Northrend
    addItem(37863, 0, { x = -8466.13, y = -2414.46, z = 0 }, false, 1584, 60) -- Direbrew's Remote
    -- Mage Teleports
    addSpell(53140, 125, { x = 0.56, y = 0.47, z = 0 }, true, 4613, 10)       -- Teleport: Dalaran - Northrend
    addSpell(49358, 51, { x = 0.47, y = 0.55, z = 0 }, true, 75, 10)          -- Teleport: Stonard
    addSpell(49359, 70, { x = 0.67, y = 0.51, z = 0 }, true, 513, 10)         -- Teleport: Theramore
end

-- Cataclysm
if GetExpansionLevel() >= 3 then
    -- Both
    addHearthstone(54452)                                                    -- Ethereal Portal
    addHearthstone(64488)                                                    -- The Innkeeper's Daughter
    addItem(58587, 207, { x = 0.4873, y = 0.5356, z = -48 }, true, 5042, 10) -- Potion of Deepholm

    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addItem(63206, 84, { x = 0.4637, y = 0.9028, z = 67 }, true, 1519, 30) -- Wrap of Unity
        addItem(63352, 84, { x = 0.4637, y = 0.9028, z = 67 }, true, 1519, 30) -- Shroud of Cooperation
        addItem(65360, 84, { x = 0.4637, y = 0.9028, z = 67 }, true, 1519, 30) -- Cloak of Coordination
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addItem(63207, 85, { x = 0.5710, y = 0.8981, z = 18 }, true, 1637, 30) -- Wrap of Unity
        addItem(63353, 85, { x = 0.5710, y = 0.8981, z = 18 }, true, 1637, 30) -- Shroud of Cooperation
        addItem(65274, 85, { x = 0.5710, y = 0.8981, z = 18 }, true, 1637, 30) -- Cloak of Coordination
    end

    -- Tol Barad
    if UnitFactionGroup("player") == "Alliance" then
        addItem(63378, 245, { x = 0.5, y = 0.5, z = 0 }, true, 5095, 30) -- Baradin's Wardens Tabard
    end
    if UnitFactionGroup("player") == "Horde" then
        addItem(63379, 245, { x = 0.5, y = 0.5, z = 0 }, true, 5095, 30) -- Hellscream's Reach Tabard
    end

    -- Worgen
    if select(3, UnitRace("player")) == 22 then
        addItem(211788, 202, { x = 0.50, y = 0.50, z = 0 }, true, 4714, 480) -- Tess's Peacebloom
    end
    -- Mage Teleports
    addSpell(88342, 245, { x = 0.50, y = 0.50, z = 0 }, true, 5389, 10) -- Teleport: Tol Barad (Alliance)
    addSpell(88344, 245, { x = 0.50, y = 0.50, z = 0 }, true, 5389, 10) -- Teleport: Tol Barad (Horde)
end

-- Mists of Pandaria
if GetExpansionLevel() >= 4 then
    -- Both
    addHearthstone(93672)                                                   -- Dark Portal
    addItem(103678, 554, { x = 0.3451, y = 0.5550, z = 0 }, true, 6757, 10) -- Time-Lost Artifact
    addItem(219222, 554, { x = 0.3451, y = 0.5550, z = 0 }, true, 6757, 10) -- Time-Lost Artifact (Reissued)
    addItem(87215, 418, { x = 0.50, y = 0.50, z = 0 }, true, 6134, 30)      -- Wormhole Generator: Pandaria

    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addItem(95567, 504, { x = 0.6470, y = 0.7348, z = 0 }, true, 6507, 10, function() return C_Map.GetBestMapForUnit("player") == 504 end) -- Kirin Tor Beacon (Isle of Thunder only)
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addItem(95568, 504, { x = 0.3315, y = 0.3285, z = 0 }, true, 6507, 10, function() return C_Map.GetBestMapForUnit("player") == 504 end) -- Sunreaver Beacon (Isle of Thunder only)
    end

    -- Brawler's Guild
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addItem(95051, 84, { x = 0.63, y = 0.49, z = 0 }, true, 6618, 480)  -- The Brassiest Knuckle
        addItem(118907, 84, { x = 0.63, y = 0.49, z = 0 }, true, 6618, 480) -- Pit Fighter's Punching Ring
        addItem(144391, 84, { x = 0.63, y = 0.49, z = 0 }, true, 6618, 480) -- Pugilist's Powerful Punching Ring
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addItem(95050, 85, { x = 0.50, y = 0.60, z = 0 }, true, 6298, 480)  -- The Brassiest Knuckle
        addItem(118908, 85, { x = 0.50, y = 0.60, z = 0 }, true, 6298, 480) -- Pit Fighter's Punching Ring
        addItem(144392, 85, { x = 0.50, y = 0.60, z = 0 }, true, 6298, 480) -- Pugilist's Powerful Punching Ring
    end
    -- Mage Teleports
    addSpell(132621, 390, { x = 0.86, y = 0.63, z = 0 }, true, 6142, 10) -- Teleport: Vale of Eternal Blossoms (Alliance)
    addSpell(132627, 390, { x = 0.63, y = 0.22, z = 0 }, true, 6141, 10) -- Teleport: Vale of Eternal Blossoms (Horde)
    addSpell(120145, 25, { x = 0.31, y = 0.30, z = 0 }, true, 279, 10)   -- Ancient Teleport: Dalaran
end

-- Warlords of Draenor
if GetExpansionLevel() >= 5 then
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addItem(110560, 582, { x = 0.2992, y = 0.3392, z = 0 }, true, 6790, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(34586) end) -- Garrison Hearthstone
        addItem(118663, 1116, { x = 602.698, y = -1710.45, z = 26.484 }, false, 6931, 240)                                                       -- Relic of Karabor
        addItem(128353, 582, { x = 0.35, y = 0.25, z = 0 }, true, 7706, 480)                                                                     -- Admiral's Compass
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addItem(110560, 590, { x = 0.5, y = 0.5, z = 0 }, true, 7004, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(34378) end) -- Garrison Hearthstone
        addItem(118662, 1116, { x = 6754.56, y = 6012.54, z = 250.034 }, false, 6864, 240)                                                 -- Bladespire Relic
        addItem(128353, 590, { x = 0.55, y = 0.70, z = 0 }, true, 7703, 480)                                                               -- Admiral's Compass
    end
    addItem(112059, 525, { x = 0.50, y = 0.50, z = 0 }, true, 6720, 30)                                                                    -- Wormhole Centrifuge
    -- Mage Teleports
    addSpell(176242, 624, { x = 0.50, y = 0.39, z = 0 }, true, 7333, 10)                                                                   -- Teleport: Warspear
    addSpell(176248, 622, { x = 0.41, y = 0.73, z = 0 }, true, 7332, 10)                                                                   -- Teleport: Stormshield

    -- Ever Shifting Mirror (toy 129929) — portals between Draenor and Outland
    local mirrorCond = function() return PlayerHasToy(129929) and UnitLevel("player") >= 40 end
    addPortal(true, 550, { x = 0.5035, y = 0.5721, z = 0 }, true, 6755, 107, { x = 0.4127, y = 0.5904, z = 0 }, true, 3518, 15, mirrorCond) -- Nagrand D to Nagrand (1)
    addPortal(true, 550, { x = 0.8836, y = 0.2284, z = 0 }, true, 6755, 102, { x = 0.6820, y = 0.8846, z = 0 }, true, 3521, 15, mirrorCond) -- Nagrand D to Zangarmarsh (1)
    addPortal(true, 550, { x = 0.7141, y = 0.2194, z = 0 }, true, 6755, 107, { x = 0.6036, y = 0.2556, z = 0 }, true, 3518, 15, mirrorCond) -- Nagrand D to Nagrand (2)
    addPortal(true, 550, { x = 0.8113, y = 0.0897, z = 0 }, true, 6755, 102, { x = 0.4919, y = 0.5537, z = 0 }, true, 3521, 15, mirrorCond) -- Nagrand D to Zangarmarsh (2)
    addPortal(true, 525, { x = 0.2182, y = 0.4531, z = 0 }, true, 6720, 105, { x = 0.4640, y = 0.6405, z = 0 }, true, 3522, 15, mirrorCond) -- Frostfire Ridge to Blade's Edge (1)
    addPortal(true, 525, { x = 0.3753, y = 0.6071, z = 0 }, true, 6720, 105, { x = 0.3963, y = 0.7739, z = 0 }, true, 3522, 15, mirrorCond) -- Frostfire Ridge to Blade's Edge (2)
    addPortal(true, 543, { x = 0.4941, y = 0.7366, z = 0 }, true, 6721, 105, { x = 0.5911, y = 0.7169, z = 0 }, true, 3522, 15, mirrorCond) -- Gorgrond to Blade's Edge (1)
    addPortal(true, 543, { x = 0.5082, y = 0.3143, z = 0 }, true, 6721, 105, { x = 0.6620, y = 0.2633, z = 0 }, true, 3522, 15, mirrorCond) -- Gorgrond to Blade's Edge (2)
    addPortal(true, 534, { x = 0.7030, y = 0.5453, z = 0 }, true, 6723, 100, { x = 0.8038, y = 0.5160, z = 0 }, true, 3483, 15, mirrorCond) -- Tanaan Jungle to Hellfire Peninsula (1)
    addPortal(true, 534, { x = 0.4956, y = 0.5073, z = 0 }, true, 6723, 100, { x = 0.5498, y = 0.4887, z = 0 }, true, 3483, 15, mirrorCond) -- Tanaan Jungle to Hellfire Peninsula (2)
    addPortal(true, 534, { x = 0.5634, y = 0.2683, z = 0 }, true, 6723, 100, { x = 0.6404, y = 0.2173, z = 0 }, true, 3483, 15, mirrorCond) -- Tanaan Jungle to Hellfire Peninsula (3)
    addPortal(true, 539, { x = 0.6002, y = 0.4837, z = 0 }, true, 6719, 104, { x = 0.6153, y = 0.4607, z = 0 }, true, 3520, 15, mirrorCond) -- Shadowmoon Valley D to Shadowmoon Valley (1)
    addPortal(true, 539, { x = 0.3233, y = 0.2876, z = 0 }, true, 6719, 104, { x = 0.2710, y = 0.3336, z = 0 }, true, 3520, 15, mirrorCond) -- Shadowmoon Valley D to Shadowmoon Valley (2)
    addPortal(true, 542, { x = 0.4740, y = 0.1245, z = 0 }, true, 6722, 108, { x = 0.7078, y = 0.7588, z = 0 }, true, 3519, 15, mirrorCond) -- Spires of Arak to Terokkar Forest
    addPortal(true, 535, { x = 0.5785, y = 0.8053, z = 0 }, true, 6662, 108, { x = 0.4537, y = 0.4753, z = 0 }, true, 3519, 15, mirrorCond) -- Talador to Terokkar Forest (1)
    addPortal(true, 535, { x = 0.5041, y = 0.3519, z = 0 }, true, 6662, 108, { x = 0.3526, y = 0.1251, z = 0 }, true, 3519, 15, mirrorCond) -- Talador to Terokkar Forest (2)
    addPortal(true, 535, { x = 0.6842, y = 0.0932, z = 0 }, true, 6662, 102, { x = 0.8259, y = 0.6613, z = 0 }, true, 3521, 15, mirrorCond) -- Talador to Zangarmarsh
end

-- Classic class teleports (pre-Legion destinations)
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
    -- Death Knight: Death Gate to original Acherus over Eastern Plaguelands (WotLK+)
    if GetExpansionLevel() >= 2 then
        addSpell(50977, 23, { x = 0.84, y = 0.50, z = 0 }, true, 4281, 10) -- Death Gate
    end
    -- Monk: Zen Pilgrimage to Peak of Serenity in Kun-Lai Summit (MoP+)
    if GetExpansionLevel() >= 4 then
        addSpell(126892, 379, { x = 0.49, y = 0.42, z = 0 }, true, 5956, 10) -- Zen Pilgrimage
    end
end

-- Legion
if GetExpansionLevel() >= 6 then
    -- Both
    addItem(139599, 627, { x = 0.6092, y = 0.4472, z = 739 }, true, 7502, 30)                                                                                                               -- Empowered Ring of the Kirin Tor
    addHearthstone(142298)                                                                                                                                                                  -- Astonishingly Scarlet Slippers
    addHearthstone(142542)                                                                                                                                                                  -- Tome of Town Portal
    addItem(140192, 627, { x = 0.6092, y = 0.4472, z = 739 }, true, 7502, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(44184) or C_QuestLog.IsQuestFlaggedCompleted(44663) end) -- Dalaran Hearthstone
    addItem(142469, 42, { x = 0.4735, y = 0.7532, z = 0 }, true, 2562, 30)                                                                                                                  -- Violet Seal of the Grand Magus
    addItem(138448, 627, { x = 0.50, y = 0.26, z = 0 }, true, 8270, 60)                                                                                                                     -- Emblem of Margoss
    addItem(140324, 680, { x = 0.37, y = 0.59, z = 0 }, true, 7928, 15, function() return C_Map.GetBestMapForUnit("player") == 680 end)                                                     -- Mobile Telemancy Beacon (Suramar only)
    addItem(151652, 885, { x = 0.50, y = 0.50, z = 0 }, true, 8899, 30)                                                                                                                     -- Wormhole Generator: Argus
    addItem(144341, 627, { x = 0.50, y = 0.50, z = 0 }, true, 7502, 30)                                                                                                                     -- Rechargeable Reaves Battery
    addItem(139590, 25, { x = 0.73, y = 0.24, z = 0 }, true, 3486, 480)                                                                                                                     -- Scroll of Teleport: Ravenholdt
    -- Mage Teleport
    addSpell(224869, 627, { x = 0.61, y = 0.45, z = 0 }, true, 7502, 10)                                                                                                                    -- Teleport: Dalaran - Broken Isles
    addSpell(193759, 734, { x = 0.5763, y = 0.8613, z = 0 }, true, 7879, 10)                                                                                                                -- Teleport: Hall of the Guardian
    -- Death Knight
    addSpell(50977, 647, { x = 0.50, y = 0.50, z = 0 }, true, 7679, 10)                                                                                                                     -- Death Gate
    -- Monk
    addSpell(126892, 709, { x = 0.50, y = 0.50, z = 0 }, true, 7902, 10)                                                                                                                    -- Zen Pilgrimage
    -- Druid
    addSpell(193753, 715, { x = 0.50, y = 0.50, z = 0 }, true, 7979, 10)                                                                                                                    -- Dreamwalk
    -- Zone-locked Items
    addItem(153226, 882, { x = 0.50, y = 0.50, z = 0 }, true, 8701, 15, function() return C_Map.GetBestMapForUnit("player") == 885 end)                                                     -- Observer's Locus Resonator
end

-- Battle for Azeroth
if GetExpansionLevel() >= 7 then
    -- Both
    addHearthstone(168907) -- Holographic Digitalization Hearthstone

    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addItem(166560, 1161, { x = 0.668, y = 0.256, z = 0 }, true, 8718, 30) -- Captain's Signet of Command
    end

    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addItem(166559, 862, { x = 0.512, y = 0.952, z = 0 }, true, 8665, 30) -- Commander's Signet of Battle
    end
    addHearthstone(169064)                                                    -- Mountebank's Colorful Cloak
    addHearthstone(162973)                                                    -- Greatfather Winter's Hearthstone
    addHearthstone(163045)                                                    -- Headless Horseman's Hearthstone
    addHearthstone(165669)                                                    -- Lunar Elder's Hearthstone
    addHearthstone(165670)                                                    -- Peddlefeet's Lovely Hearthstone
    addHearthstone(165802)                                                    -- Noble Gardener's Hearthstone
    addHearthstone(166746)                                                    -- Fire Eater's Hearthstone
    addHearthstone(166747)                                                    -- Brewfest Reveler's Hearthstone
    addItem(168807, 942, { x = 0.50, y = 0.50, z = 0 }, true, 9042, 30)       -- Wormhole Generator: Kul Tiras
    addItem(168808, 864, { x = 0.50, y = 0.50, z = 0 }, true, 8501, 30)       -- Wormhole Generator: Zandalar
    -- Mage Teleports
    addSpell(281403, 1161, { x = 0.67, y = 0.26, z = 0 }, true, 8568, 10)     -- Teleport: Boralus
    addSpell(281404, 862, { x = 0.51, y = 0.95, z = 0 }, true, 8670, 10)      -- Teleport: Dazar'alor

    -- Mole Machine (Dark Iron Dwarf racial, spell 265225)
    if select(3, UnitRace("player")) == 34 then
        local function moleCond(questId)
            if questId then
                return function() return not IsIndoors() and C_QuestLog.IsQuestFlaggedCompleted(questId) end
            else
                return function() return not IsIndoors() end
            end
        end
        -- Default destinations (no quest required)
        addSpell(265225, 84, { x = 0.6333, y = 0.3734, z = 0 }, true, 1519, 90, moleCond())         -- Mole Machine: Stormwind City
        addSpell(265225, 27, { x = 0.6129, y = 0.3718, z = 0 }, true, 809, 90, moleCond())          -- Mole Machine: Ironforge
        addSpell(265225, 1186, { x = 0.6144, y = 0.2435, z = 0 }, true, 1584, 90, moleCond())       -- Mole Machine: Shadowforge City
        -- Kalimdor
        addSpell(265225, 198, { x = 0.5718, y = 0.7711, z = 0 }, true, 616, 90, moleCond(53601))    -- Mole Machine: Throne of Flame (Mount Hyjal)
        addSpell(265225, 199, { x = 0.3911, y = 0.0930, z = 0 }, true, 4709, 90, moleCond(53600))   -- Mole Machine: The Great Divide (Southern Barrens)
        addSpell(265225, 78, { x = 0.5288, y = 0.5576, z = 0 }, true, 4381, 90, moleCond(53591))    -- Mole Machine: Fire Plume Ridge (Un'Goro Crater)
        -- Eastern Kingdoms
        addSpell(265225, 17, { x = 0.6197, y = 0.1280, z = 0 }, true, 4, 90, moleCond(53594))       -- Mole Machine: Nethergarde Keep (Blasted Lands)
        addSpell(265225, 26, { x = 0.1353, y = 0.4680, z = 0 }, true, 348, 90, moleCond(53585))     -- Mole Machine: Aerie Peak (The Hinterlands)
        addSpell(265225, 36, { x = 0.3330, y = 0.2480, z = 0 }, true, 46, 90, moleCond(53587))      -- Mole Machine: The Masonary (Burning Steppes)
        -- Outland
        addSpell(265225, 104, { x = 0.5077, y = 0.3530, z = 0 }, true, 3520, 90, moleCond(53599))   -- Mole Machine: Fel Pits (Shadowmoon Valley)
        addSpell(265225, 105, { x = 0.7242, y = 0.1764, z = 0 }, true, 3866, 90, moleCond(53597))   -- Mole Machine: Skald (Blade's Edge Mountains)
        -- Northrend
        addSpell(265225, 115, { x = 0.4535, y = 0.4992, z = 0 }, true, 4168, 90, moleCond(53596))   -- Mole Machine: Ruby Dragonshrine (Dragonblight)
        addSpell(265225, 118, { x = 0.7697, y = 0.1866, z = 0 }, true, 4658, 90, moleCond(53586))   -- Mole Machine: Argent Tournament Grounds (Icecrown)
        -- Pandaria
        addSpell(265225, 376, { x = 0.3151, y = 0.7359, z = 0 }, true, 6001, 90, moleCond(53598))   -- Mole Machine: Stormstout Brewery (Valley of the Four Winds)
        addSpell(265225, 379, { x = 0.5768, y = 0.6281, z = 0 }, true, 6085, 90, moleCond(53595))   -- Mole Machine: One Keg (Kun-Lai Summit)
        -- Draenor
        addSpell(265225, 543, { x = 0.4669, y = 0.3876, z = 0 }, true, 6892, 90, moleCond(53588))   -- Mole Machine: Blackrock Foundry Overlook (Gorgrond)
        addSpell(265225, 550, { x = 0.6575, y = 0.0825, z = 0 }, true, 7139, 90, moleCond(53590))   -- Mole Machine: Elemental Plateau (Nagrand Draenor)
        -- Broken Isles
        addSpell(265225, 650, { x = 0.4466, y = 0.7290, z = 0 }, true, 7806, 90, moleCond(53593))   -- Mole Machine: Neltharion's Vault (Highmountain)
        addSpell(265225, 646, { x = 0.7169, y = 0.4799, z = 0 }, true, 7543, 90, moleCond(53589))   -- Mole Machine: Broken Shore
        -- Zandalar
        addSpell(265225, 863, { x = 0.3434, y = 0.4513, z = 0 }, true, 8500, 90, moleCond(80099))   -- Mole Machine: Zalamar Invasion (Nazmir)
        addSpell(265225, 862, { x = 0.3824, y = 0.7237, z = 0 }, true, 8965, 90, moleCond(80100))   -- Mole Machine: Xibala Incursion (Zuldazar)
        -- Kul Tiras
        addSpell(265225, 942, { x = 0.6422, y = 0.2944, z = 0 }, true, 9623, 90, moleCond(80102))   -- Mole Machine: Tidebreak Summit (Stormsong Valley)
        addSpell(265225, 895, { x = 0.8822, y = 0.7153, z = 0 }, true, 9135, 90, moleCond(80101))   -- Mole Machine: Wailing Tideways (Tiragarde Sound)
        -- Shadowlands
        addSpell(265225, 1533, { x = 0.5175, y = 0.1312, z = 0 }, true, 11412, 90, moleCond(80105)) -- Mole Machine: The Eternal Forge (Bastion)
        addSpell(265225, 1565, { x = 0.6646, y = 0.5057, z = 0 }, true, 13455, 90, moleCond(80106)) -- Mole Machine: Soryn's Meadow (Ardenweald)
        addSpell(265225, 1525, { x = 0.1991, y = 0.3878, z = 0 }, true, 11438, 90, moleCond(80104)) -- Mole Machine: Scorched Crypt (Revendreth)
        addSpell(265225, 1536, { x = 0.5351, y = 0.5978, z = 0 }, true, 13406, 90, moleCond(80103)) -- Mole Machine: Valley of a Thousand Legs (Maldraxxus)
        -- Dragon Isles
        addSpell(265225, 2133, { x = 0.5271, y = 0.2767, z = 0 }, true, 14655, 90, moleCond(80109)) -- Mole Machine: Obsidian Rest (Zaralek Cavern)
        addSpell(265225, 2024, { x = 0.8009, y = 0.3897, z = 0 }, true, 14017, 90, moleCond(80108)) -- Mole Machine: Vakthros Summit (The Azure Span)
        addSpell(265225, 2022, { x = 0.3236, y = 0.5490, z = 0 }, true, 14012, 90, moleCond(80107)) -- Mole Machine: The Slagmire (The Waking Shores)
    end

    -- Alluring Bloom (zone-locked to Stormsong Valley)
    addItem(169862, 942, { x = 0.6289, y = 0.2652, z = 0 }, true, 9042, 15, function() return C_Map.GetBestMapForUnit("player") == 942 end) -- Alluring Bloom

    -- BFA ship NPC routes (talk to NPC to sail between continents)
    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addBoat(1161, { x = 0.6795, y = 0.2669, z = 0 }, true, 8568, 862, { x = 0.4068, y = 0.7086, z = 0 }, true, 8499, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(51308) end) -- Boralus to Zuldazar
        addBoat(1161, { x = 0.6795, y = 0.2669, z = 0 }, true, 8568, 863, { x = 0.6195, y = 0.3992, z = 0 }, true, 8500, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(51571) end) -- Boralus to Nazmir
        addBoat(1161, { x = 0.6795, y = 0.2669, z = 0 }, true, 8568, 864, { x = 0.3560, y = 0.3317, z = 0 }, true, 8501, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(51572) end) -- Boralus to Vol'dun
    end
    -- Horde
    if UnitFactionGroup("player") == "Horde" then
        addBoat(862, { x = 0.5846, y = 0.6299, z = 0 }, true, 8499, 896, { x = 0.2061, y = 0.4369, z = 0 }, true, 8721, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(51801) or C_QuestLog.IsQuestFlaggedCompleted(51340) end) -- Zuldazar to Drustvar
        addBoat(862, { x = 0.5846, y = 0.6299, z = 0 }, true, 8499, 942, { x = 0.5198, y = 0.2449, z = 0 }, true, 9042, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(51802) or C_QuestLog.IsQuestFlaggedCompleted(51532) end) -- Zuldazar to Stormsong Valley
        addBoat(862, { x = 0.5846, y = 0.6299, z = 0 }, true, 8499, 895, { x = 0.8820, y = 0.5116, z = 0 }, true, 8567, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(51800) or C_QuestLog.IsQuestFlaggedCompleted(51421) end) -- Zuldazar to Tiragarde Sound
        addBoat(1165, { x = 0.4175, y = 0.8743, z = 0 }, true, 8670, 1462, { x = 0.7549, y = 0.2266, z = 0 }, true, 10290, 30, function() return C_QuestLog.IsQuestFlaggedCompleted(55651) end)                                           -- Dazar'alor to Mechagon
    end
end

-- Shadowlands
if GetExpansionLevel() >= 8 then
    -- Both
    addHearthstone(180290)                                                 -- Night Fae Hearthstone
    addHearthstone(182773)                                                 -- Necrolord Hearthstone
    addHearthstone(183716)                                                 -- Venthyr Sinstone
    addHearthstone(184353)                                                 -- Kyrian Hearthstone
    addHearthstone(188952)                                                 -- Dominated Hearthstone
    addHearthstone(190196)                                                 -- Enlightened Hearthstone
    addHearthstone(190237)                                                 -- Broker Translocation Matrix
    addHearthstone(172179)                                                 -- Eternal Traveler's Hearthstone
    addItem(172924, 1565, { x = 0.50, y = 0.50, z = 0 }, true, 11510, 30)  -- Wormhole Generator: Shadowlands
    addItem(181163, 1536, { x = 0.50, y = 0.55, z = 0 }, true, 11462, 480) -- Scroll of Teleport: Theater of Pain
    addItem(173523, 18, { x = 0.60, y = 0.60, z = 0 }, true, 85, 480)      -- Tirisfal Camp Scroll
    -- Cypher of Relocation (zone-locked to The Maw / Korthia)
    addItem(180817, 1543, { x = 0.4622, y = 0.4125, z = 0 }, true, 11400, 30, function()
        local m = C_Map.GetBestMapForUnit("player"); return m == 1543 or m == 1823 or m == 1822 or m == 1821 or m == 1820
    end)                                                                   -- Cypher of Relocation
    -- Mage Teleport
    addSpell(344587, 1670, { x = 0.50, y = 0.50, z = 0 }, true, 10565, 10) -- Teleport: Oribos
end

-- Dragonflight
if GetExpansionLevel() >= 9 then
    -- Both
    addHearthstone(206195)                                                                                                                     -- Path of the Naaru
    addHearthstone(193588)                                                                                                                     -- Timewalker's Hearthstone
    addHearthstone(200630)                                                                                                                     -- Ohn'ir Windsage's Hearthstone
    addItem(198156, 2024, { x = 0.50, y = 0.50, z = 0 }, true, 13646, 30)                                                                      -- Wormhole Generator: Dragon Isles
    addItem(202046, 942, { x = 0.40, y = 0.36, z = 0 }, true, 9042, 480)                                                                       -- Lucky Tortollan Charm
    -- Niffen Diggin' Mitts (zone-locked to Zaralek Cavern)
    addItem(205255, 2133, { x = 0.5645, y = 0.5580, z = 0 }, true, 14022, 15, function() return C_Map.GetBestMapForUnit("player") == 2133 end) -- Niffen Diggin' Mitts
    -- Mage Teleport
    addSpell(395277, 2112, { x = 0.58, y = 0.35, z = 0 }, true, 13862, 10)                                                                     -- Teleport: Valdrakken
end

-- The War Within
if GetExpansionLevel() >= 10 then
    -- Both
    addHearthstone(208704) -- Deepdweller's Earthen Hearthstone
    addHearthstone(209035) -- Hearthstone of the Flame
    addHearthstone(212337) -- Stone of the Hearth
    addHearthstone(228940) -- Notorious Thread's Hearthstone
    addHearthstone(235016) -- Redeployment Module
    addHearthstone(236687) -- Explosive Hearthstone
    addHearthstone(246565) -- Cosmic Hearthstone
    addHearthstone(245970) -- P.O.S.T. Master's Express Hearthstone
    addHearthstone(250411) -- Timerunner's Hearthstone
    addHearthstone(257736) -- Lightcalled Hearthstone
    addHearthstone(260221) -- Naaru's Embrace
    addHearthstone(263489) -- Naaru's Enfold
    addHearthstone(263933) -- Preyseeker's Hearthstone
    addHearthstone(265100) -- Corewarden's Hearthstone

    -- Draenei and Lightforged Draenei
    if select(3, UnitRace("player")) == 11 or select(3, UnitRace("player")) == 30 then
        addHearthstone(210455)                                              -- Draenic Hologem
    end
    addItem(221966, 2214, { x = 0.50, y = 0.50, z = 0 }, true, 14795, 30)   -- Wormhole Generator: Khaz Algar
    addItem(243056, 2552, { x = 2400, y = -3600, z = 0 }, false, 14771, 30) -- Delver's Mana-Bound Ethergate
    -- Mage Teleport
    addSpell(446540, 2339, { x = 0.48, y = 0.63, z = 0 }, true, 14771, 10)  -- Teleport: Dornogal
end

-- Midnight
if GetExpansionLevel() >= 11 then
    -- Both
    addItem(248485, 2537, { x = 0.50, y = 0.50, z = 0 }, true, 2037, 30)                                                                                                                            -- Wormhole Generator: Quel'Thalas
    addItem(266370, 2537, { x = 0.50, y = 0.50, z = 0 }, true, 2037, 30)                                                                                                                            -- Dundun's Abundant Travel Method
    addItem(253629, 2393, { x = 0.50, y = 0.50, z = 0 }, true, 10473, 60)                                                                                                                           -- Personal Key to the Arcantina
    addPortal(true, 2393, { x = 0.4566, y = 0.6973, z = 0 }, true, 3487, 2541, { x = 0.5061, y = 0.8888, z = 0 }, true, 10473, 15, function() return C_QuestLog.IsQuestFlaggedCompleted(86903) end) -- Silvermoon City <-> Arcantina portal

    -- Alliance
    if UnitFactionGroup("player") == "Alliance" then
        addPortal(true, 2393, { x = 0.5260, y = 0.6457, z = 0 }, true, 3487, 84, { x = 0.5450, y = 0.1726, z = 0 }, true, 1519, 15) -- Silvermoon City <-> Stormwind (portal room)
    end
    -- Mage Teleport
    addSpell(1259190, 2393, { x = 0.50, y = 0.50, z = 0 }, true, 3487, 10)                                                                                                                          -- Teleport: Silvermoon City
end

if GetExpansionLevel() >= 10 then
    -- Housing: Teleport to Plot
    do
        local from = {
            actionOptions = { { type = "housing" } },
            condition = function()
                local m = C_Map.GetBestMapForUnit("player"); return C_Housing and FarstriderLibData.HousingData and m ~= 2351 and m ~= 2352
            end,
            unknown1 = 0,
            dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
            flags = 8,
            type = 1,
            important = true,
            locaId = SpecialLocaId.PortalTo,
            locaArgs = function() return { C_Map.GetAreaInfo(15524) or "Razorwind Shores" } end
        }
        local to = { unknown1 = 0, flags = 0, loc = { mapId = 2351, pos = { x = 0.5431, y = 0.4932, z = 0 }, isUI = true }, type = 2, locaId = SpecialLocaId.PortalTo, locaArgs = function() return { C_Map.GetAreaInfo(15524) or "Razorwind Shores" } end }
        addEntry(SpecialLocaId.PortalTo + portalCount, from, to, false, 30)
        portalCount = portalCount + 1
    end
    do
        local from = {
            actionOptions = { { type = "housing" } },
            condition = function()
                local m = C_Map.GetBestMapForUnit("player"); return C_Housing and FarstriderLibData.HousingData and m ~= 2351 and m ~= 2352
            end,
            unknown1 = 0,
            dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
            flags = 8,
            type = 1,
            important = true,
            locaId = SpecialLocaId.PortalTo,
            locaArgs = function() return { C_Map.GetAreaInfo(16105) or "Founder's Point" } end
        }
        local to = { unknown1 = 0, flags = 0, loc = { mapId = 2352, pos = { x = 0.5743, y = 0.2662, z = 0 }, isUI = true }, type = 2, locaId = SpecialLocaId.PortalTo, locaArgs = function() return { C_Map.GetAreaInfo(16105) or "Founder's Point" } end }
        addEntry(SpecialLocaId.PortalTo + portalCount, from, to, false, 30)
        portalCount = portalCount + 1
    end
    -- Housing: Return from Plot
    do
        if not FarstriderLibData_CharacterSettings then
            FarstriderLibData_CharacterSettings = {}
        end

        local function getHousingExitLocation()
            return FarstriderLibData_CharacterSettings.housingExitLocation or FarstriderLibData.Util.GetBindingLocation()
        end
        local function getHousingExitAreaName()
            local saved = FarstriderLibData_CharacterSettings.housingExitLocation
            if saved then
                local info = C_Map.GetMapInfo(saved.mapId)
                return info and info.name or L["Unknown Location"]
            end
            return GetBindLocation() or L["Unknown Location"]
        end
        local from = {
            actionOptions = { { type = "housing_return" } },
            condition = function()
                local m = C_Map.GetBestMapForUnit("player"); return C_Housing and FarstriderLibData.HousingData and (m == 2351 or m == 2352)
            end,
            unknown1 = 0,
            dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
            flags = 8,
            type = 1,
            important = true,
            locaId = SpecialLocaId.PortalTo,
            locaArgs = function() return { getHousingExitAreaName() } end
        }
        local to = { unknown1 = 0, flags = 0, dynLoc = getHousingExitLocation, type = 2, locaId = SpecialLocaId.PortalTo, locaArgs = function() return { getHousingExitAreaName() } end }
        addEntry(SpecialLocaId.PortalTo + portalCount, from, to, false, 30)
        portalCount = portalCount + 1
    end
end

addDynamicItemWithMultipleIds(hearthstones, FarstriderLibData.Util.GetBindingLocation, GetBindLocation, (select(3, UnitRace("player")) == 1 and GetExpansionLevel() >= 10) and 12.5 or 30, function() return FarstriderLibData.AreaL[GetBindLocation()] end) -- Hearthstones

table.sort(Connections.helpfulItems, function(a, b) return a < b end)

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_HOUSE_LIST_UPDATED")
    f:SetScript("OnEvent", function(_, _, ...)
        local houses = ...
        if houses then
            for _, house in ipairs(houses) do
                FarstriderLibData.HousingData = house
                break
            end
        end
    end)
end
