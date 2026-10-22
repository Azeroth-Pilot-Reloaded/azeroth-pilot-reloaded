-- Declarative travel data. Names are resolved through the game client.
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "additional_portals", {
    connections = {
        {
            id = "additional-darnassus-ruttheran",
            kind = "portal",
            bidirectional = false,
            from = { space = "world", instanceID = 1, x = 9947.48, y = 2630.04, z = 1318.6 },
            to = { space = "world", instanceID = 1, x = 8785.79, y = 966.983, z = 30.2 },
            seconds = 5,
        },
        {
            id = "additional-ruttheran-darnassus",
            kind = "portal",
            bidirectional = false,
            from = { space = "world", instanceID = 1, x = 8799.41, y = 969.787, z = 30.241 },
            to = { space = "world", instanceID = 1, x = 9946.25, y = 2612.97, z = 1316.49 },
            seconds = 5,
        },
    },
}, 30)
