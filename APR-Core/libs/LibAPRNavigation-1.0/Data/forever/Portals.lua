-- Declarative travel data. Names are resolved through the game client.
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "portals", {
    connections = {
        {
            id = "portal-eastern-kingdoms-to-eastern-kingdoms",
            kind = "portal",
            bidirectional = false,
            from = {
                space = "world",
                instanceID = 0,
                x = -9077.9599609375,
                y = 873.26397705078,
                z = 68.18419647217,
                accessKey = "wizards-sanctum",
            },
            to = { space = "world", instanceID = 0, x = -9004.4443359375, y = 870.625, z = 64.86025238037, accessKey = "wizards-sanctum" },
            requirements = { faction = "Alliance" },
            seconds = 10,
        },
        {
            id = "portal-eastern-kingdoms-to-eastern-kingdoms-at-minus-9042-917-arrive-minus-9004-871",
            kind = "portal",
            bidirectional = false,
            from = { space = "world", instanceID = 0, x = -9041.6103515625, y = 917.32000732422, z = 66.68699645996 },
            to = { space = "world", instanceID = 0, x = -9004.4443359375, y = 870.625, z = 64.86025238037, accessKey = "wizards-sanctum" },
            requirements = { faction = "Alliance" },
            seconds = 10,
        },
        {
            id = "portal-stormwind-to-ironforge",
            kind = "portal",
            bidirectional = true,
            from = { space = "map", uiMapID = 1453, x = 0.6962, y = 0.3111 },
            to = { space = "map", uiMapID = 1455, x = 0.7693, y = 0.5125, areaID = 1537 },
            seconds = 30,
        },
    },
}, 30)
