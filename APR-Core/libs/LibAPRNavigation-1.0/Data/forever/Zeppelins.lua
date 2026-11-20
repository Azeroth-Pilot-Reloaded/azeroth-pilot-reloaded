-- Declarative travel data. Names are resolved through the game client.
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "zeppelins", {
    connections = {
        {
            id = "zeppelin-forever-transport-4015",
            kind = "zeppelin",
            bidirectional = true,
            -- The transfer includes getting up to the boarding deck and back down.
            -- Join the walking graph at the outdoor approaches to the towers.
            from = {
                space = "world", instanceID = 0, uiMapID = 1420, x = 2089.5833333333, y = 281.25, z = 58, areaID = 1497,
            },
            to = { space = "world", instanceID = 1, uiMapID = 1411, x = 1333, y = -4624, z = 24, areaID = 1637 },
            requirements = { faction = "Horde" },
            arrivalRadius = 10,
            seconds = 300,
        },
        {
            id = "zeppelin-forever-transport-4016",
            kind = "zeppelin",
            bidirectional = true,
            from = { space = "map", uiMapID = 1411, x = 0.507, y = 0.128, z = 54, areaID = 1637 },
            to = { space = "map", uiMapID = 1434, x = 0.313, y = 0.301, z = 32, areaID = 117 },
            requirements = { faction = "Horde" },
            seconds = 250,
        },
        {
            id = "zeppelin-forever-transport-4017",
            kind = "zeppelin",
            bidirectional = true,
            -- Route to the tower approach. Boarding includes climbing to the deck.
            from = { space = "map", uiMapID = 1420, x = 0.619, y = 0.591, z = 52.1, areaID = 1497 },
            to = { space = "map", uiMapID = 1434, x = 0.316, y = 0.292, z = 32, areaID = 117 },
            requirements = { faction = "Horde" },
            seconds = 240,
        },
        {
            id = "boat-forever-transport-4014",
            kind = "zeppelin",
            bidirectional = true,
            from = { space = "map", uiMapID = 2521, x = 0.6581, y = 0.8341, z = 644, areaID = 16628 },
            to = { space = "map", uiMapID = 1416, x = 0.1262, y = 0.5203, z = 110 },
            requirements = { faction = "Alliance" },
            seconds = 290,
        },
        {
            id = "boat-forever-transport-4013",
            kind = "zeppelin",
            bidirectional = true,
            from = { space = "map", uiMapID = 2521, x = 0.5791, y = 0.8078, z = 663, areaID = 16628 },
            to = { space = "map", uiMapID = 1412, x = 0.343, y = 0.2576, z = 190 },
            requirements = { faction = "Horde" },
            seconds = 310,
        },
    },
}, 34)
