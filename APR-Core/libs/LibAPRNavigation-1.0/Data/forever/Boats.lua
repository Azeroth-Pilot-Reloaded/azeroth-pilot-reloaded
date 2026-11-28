-- Declarative travel data. Names are resolved through the game client.
-- The southern service calls at its three harbors in order. Heights identify
-- the dock deck where it overlaps the water in the terrain graph.
local auberdine = { space = "map", uiMapID = 1439, x = 0.3237, y = 0.4381, z = 6, areaID = 442 }
local menethil = { space = "map", uiMapID = 1437, x = 0.0464, y = 0.5716, z = 5, areaID = 150 }
local southshore = { space = "map", uiMapID = 1424, x = 0.5053, y = 0.6975, z = 6, areaID = 271 }

LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "boats", {
    connections = {
        {
            id = "boat-forever-transport-4001",
            kind = "boat",
            bidirectional = true,
            from = { space = "map", uiMapID = 1453, x = 0.2255, y = 0.5613, z = 6, areaID = 1519 },
            to = { space = "map", uiMapID = 1439, x = 0.3077, y = 0.4101, z = 6, areaID = 442 },
            requirements = { faction = "Alliance" },
            seconds = 170,
        },
        {
            id = "boat-forever-transport-4002",
            kind = "boat",
            bidirectional = false,
            from = auberdine,
            to = menethil,
            requirements = { faction = "Alliance" },
            seconds = 293,
        },
        {
            id = "boat-forever-transport-4003",
            kind = "boat",
            bidirectional = false,
            from = menethil,
            to = southshore,
            requirements = { faction = "Alliance" },
            seconds = 363,
        },
        {
            id = "boat-forever-transport-4004",
            kind = "boat",
            bidirectional = false,
            from = southshore,
            to = auberdine,
            requirements = { faction = "Alliance" },
            seconds = 303,
        },
        {
            id = "boat-forever-transport-4008",
            kind = "boat",
            bidirectional = true,
            from = { space = "map", uiMapID = 1446, x = 0.6858, y = 0.2299 },
            to = { space = "map", uiMapID = 2548, x = 0.806, y = 0.5461, areaID = 16727 },
            seconds = 90,
        },
        {
            id = "boat-forever-transport-44",
            kind = "boat",
            bidirectional = true,
            from = { space = "map", uiMapID = 1437, x = 0.0509, y = 0.6351, z = 5, areaID = 150 },
            to = { space = "map", uiMapID = 1445, x = 0.715, y = 0.5635, z = 5, areaID = 513 },
            requirements = { faction = "Alliance" },
            seconds = 370,
        },
        {
            id = "boat-forever-transport-4010",
            kind = "boat",
            bidirectional = true,
            from = { space = "map", uiMapID = 1439, x = 0.3318, y = 0.4013, z = 6, areaID = 442 },
            to = { space = "map", uiMapID = 1438, x = 0.5488, y = 0.9671, z = 6, areaID = 702 },
            requirements = { faction = "Alliance" },
            seconds = 190,
        },
        {
            id = "boat-forever-transport-46",
            kind = "boat",
            bidirectional = true,
            from = { space = "map", uiMapID = 1434, x = 0.2595, y = 0.7316, z = 7, areaID = 35 },
            to = { space = "map", uiMapID = 1413, x = 0.6362, y = 0.3863, z = 6, areaID = 392 },
            seconds = 250,
        },
        {
            id = "boat-forever-transport-4012",
            kind = "boat",
            bidirectional = true,
            from = { space = "map", uiMapID = 1444, x = 0.3101, y = 0.3951 },
            to = { space = "map", uiMapID = 1444, x = 0.4313, y = 0.4276 },
            requirements = { faction = "Alliance" },
            seconds = 60,
        },
    },
}, 33)
