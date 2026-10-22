-- Declarative travel data. Names are resolved through the game client.
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "zeppelins", {
    connections = {
        {
            id = "zeppelin-forever-transport-4015",
            kind = "zeppelin",
            bidirectional = true,
            from = { space = "map", uiMapID = 1420, x = 0.607, y = 0.588, areaID = 1497 },
            to = { space = "map", uiMapID = 1411, x = 0.508, y = 0.137, areaID = 1637 },
            requirements = { faction = "Horde" },
            seconds = 300,
        },
        {
            id = "zeppelin-forever-transport-4016",
            kind = "zeppelin",
            bidirectional = true,
            from = { space = "map", uiMapID = 1411, x = 0.507, y = 0.128, areaID = 1637 },
            to = { space = "map", uiMapID = 1434, x = 0.313, y = 0.301, areaID = 117 },
            requirements = { faction = "Horde" },
            seconds = 250,
        },
        {
            id = "zeppelin-forever-transport-4017",
            kind = "zeppelin",
            bidirectional = true,
            from = { space = "map", uiMapID = 1420, x = 0.619, y = 0.591, areaID = 1497 },
            to = { space = "map", uiMapID = 1434, x = 0.316, y = 0.292, areaID = 117 },
            requirements = { faction = "Horde" },
            seconds = 240,
        },
    },
}, 30)
