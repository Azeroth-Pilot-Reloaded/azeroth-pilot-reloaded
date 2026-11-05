-- Declarative travel data. Names are resolved through the game client.
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "geography", {
    config = {
        -- Classic exposes world instance 369 in the tram, but no native UI map.
        -- Retain the legacy guide identity; coordinates remain world yards.
        UnmappedAreas = { [499] = { instanceID = 369, areaID = 2257 } },
        -- Vanilla PvP halls have world positions but no native/legacy UI map.
        UnmappedInstances = { [449] = true, [450] = true },
        -- Both platforms share the tram's world/UI map. Name the city served
        -- by each arrival platform, including nearby quest givers.
        TransportDestinations = { tram = {
            { instanceID = 369, x = 69.22769927979, y = 10.39319992065, radius = 150, mapID = 1455 },
            { instanceID = 369, x = 45.09560012817, y = 2490.5200195312, radius = 150, mapID = 1453 },
        } },
        ContinentMapOverrides = {},
        IsolatedAreas = {
            [1441] = "forever:thousand-needles",
            [1452] = "forever:winterspring",
            [1458] = "forever:undercity",
            [2521] = "forever:zephras",
            [2548] = "forever:powderfuse",
        },
        IsolatedContinents = {},
        MapTypeOverrides = {},
        actionLoadingSeconds = 5,
        defaultItemCastSeconds = 10,
        defaultSpellCastSeconds = 10,
        threshold = 2000,
    },
}, 34)
