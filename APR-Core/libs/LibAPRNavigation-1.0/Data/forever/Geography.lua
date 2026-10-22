-- Declarative travel data. Names are resolved through the game client.
LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "geography", {
    config = {
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
}, 31)
