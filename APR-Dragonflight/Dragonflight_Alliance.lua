if (APR.Faction == "Alliance") then
    -- Stormwind
    APR.RouteQuestStepList["DF01A-84-Stormwind"] = {
        { -- Step 1
            Done = {
                65436,
            },
        },
        { -- Step 2
            PickUp = {
                66577,
            },
        },
        { -- Step 3
            Qpart = {
                [66577] = {
                    1,
                },
            },
            Gossip = 1,
        },
        { -- Step 4
            Done = {
                66577,
            },
        },
        { -- Step 5
            PickUp = {
                72240,
            },
        },
        { -- Step 6
            PickUp = {
                66589,
            },
        },
        { -- Step 7
            Qpart = {
                [66589] = {
                    1,
                },
            },
            Coord = {
                y = -8426.9,
                x = 608.6,
            },
            Range = 2,
            ExtraLineText = "RECRUIT_ARTISANS",
            Gossip = 1,
        },
        { -- Step 8
            Qpart = {
                [66589] = {
                    3,
                },
            },
            Coord = {
                y = -8805.9,
                x = 622.4,
            },
            Range = 2,
            ExtraLineText = "RECRUIT_SCHOLARS",
            Gossip = 1,
        },
        { -- Step 9
            Qpart = {
                [72240] = {
                    1,
                },
            },
            Coord = {
                y = -8776.5,
                x = 838.6,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 10
            Qpart = {
                [66589] = {
                    2,
                },
            },
            Coord = {
                y = -8521.4,
                x = 1058.5,
            },
            Range = 2,
            ExtraLineText = "RECRUIT_EXPLORERS",
            Gossip = 1,
        },
        { -- Step 11
            Done = {
                66589,
            },
            Coord = {
                y = -8640.6,
                x = 1328.2,
            },
        },
        { -- Step 12
            Done = {
                72240,
            },
            Coord = {
                y = -8640.6,
                x = 1328.2,
            },
        },
        { -- Step 13
            PickUp = {
                66596,
            },
            Coord = {
                y = -8646,
                x = 1323.4,
            },
        },
        { -- Step 14
            Qpart = {
                [66596] = {
                    1,
                },
            },
            Coord = {
                y = -8646,
                x = 1323.4,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 15
            Done = {
                66596,
            },
            Coord = {
                y = -8644.4,
                x = 1324.4,
            },
        },
        { -- Step 16
            PickUp = {
                67700,
            },
            Coord = {
                y = -8640.6,
                x = 1328.2,
            },
        },
        { -- Step 17
            Waypoint = 67700,
            Coord = {
                y = -8640.6,
                x = 1328.2,
            },
            Range = 10,
            ExtraLineText = "WAIT_FOR_SHIP",
        },
        { -- Step 18
            Qpart = {
                [67700] = {
                    1,
                },
            },
            Coord = {
                y = -8640.6,
                x = 1328.2,
            },
            Range = 0.5,
            ExtraLineText = "WAIT_FOR_SHIP",
        },
        { -- Step 19
            Qpart = {
                [67700] = {
                    2,
                },
            },
        },
        { -- Step 20
            Done = {
                67700,
            },
        },
        { -- Step 21
            ZoneDoneSave = 1,
        },
    }

    APR.RouteQuestStepList["DF03A-2022-WakingShores"] = {
        { -- Step 1
            Qpart = {
                [67700] = {
                    1,
                },
            },
            Coord = {
                y = -8640.6,
                x = 1328.2,
            },
            Range = 0.5,
            ExtraLineText = "WAIT_FOR_SHIP",
        },
        { -- Step 2
            Done = {
                67700,
            },
            Coord = {
                y = 3676.8,
                x = -1898.5,
            },
        },
        { -- Step 3
            PickUp = {
                70122,
            },
            Coord = {
                y = 3676.8,
                x = -1898.5,
            },
        },
        { -- Step 4
            PickUp = {
                70123,
            },
            Coord = {
                y = 3678.4,
                x = -1901.0,
            },
        },
        { -- Step 5
            PickUp = {
                70124,
            },
            Coord = {
                y = 3676.3,
                x = -1896.0,
            },
        },
        { -- Step 6
            Qpart = {
                [70122] = {
                    1,
                },
            },
            Coord = {
                y = 3584.3,
                x = -2012.9,
            },
            Range = 5,
            Fillers = { [70123] = { 1, }, [70124] = { 1, }, },
        },
        { -- Step 7
            Qpart = {
                [70122] = {
                    2,
                },
            },
            Coord = {
                y = 3453.1,
                x = -1972.4,
            },
            Range = 10,
            Fillers = { [70123] = { 1, }, [70124] = { 1, }, },
        },
        { -- Step 8
            Qpart = {
                [70122] = {
                    3,
                },
            },
            Coord = {
                y = 3491.6,
                x = -1693.5,
            },
            Range = 10,
            Fillers = { [70123] = { 1, }, [70124] = { 1, }, },
        },
        { -- Step 9
            Qpart = {
                [70123] = {
                    1,
                },
            },
            Coord = {
                y = 3571.0,
                x = -1830.2,
            },
            Range = 180,
        },
        { -- Step 10
            Qpart = {
                [70124] = {
                    1,
                },
            },
            Coord = {
                y = 3571.0,
                x = -1830.2,
            },
            Range = 180,
        },
        { -- Step 11
            Done = {
                70122,
            },
            Coord = {
                y = 3583.6,
                x = -1459.9,
            },
        },
        { -- Step 12
            PickUp = {
                70125,
            },
            Coord = {
                y = 3583.6,
                x = -1459.9,
            },
        },
        { -- Step 13
            Qpart = {
                [70125] = {
                    1,
                },
            },
            Coord = {
                y = 3581.5,
                x = -1455.9,
            },
            Range = 5,
            ExtraLineText = "CHOOSE_WHY_ARENT_DRAGONS_HERE_MEET_US",
            Gossip = 1,
        },
        { -- Step 14
            Done = {
                70125,
            },
            Coord = {
                y = 3581.5,
                x = -1455.9,
            },
        },
        { -- [step X
            PickUp = {
                72293,
            },
            Coord = {
                y = 3581.8,
                x = -1456.2,
            },
            HasAchievement = 16326,
        },
        { -- [step X
            Qpart = {
                [72293] = {
                    1,
                },
            },
            Coord = {
                y = 3552.0,
                x = -1452.5,
            },
            Range = 5,
            ExtraLineText = "CHOOSE_ZONE",
            HasAchievement = 16326,
        },
        { -- [step X
            Done = {
                72293,
            },
            Coord = {
                y = 3552.0,
                x = -1452.5,
            },
            HasAchievement = 16326,
        },
        { -- [step X
            PickUp = {
                72266,
            },
            Coord = {
                y = 3552.0,
                x = -1452.5,
            },
            ExtraLineText = "CHOOSE_ZONE",
            ["ExtraLineText2"] = "CHOOSE_ZONE_DF_WS",
            HasAchievement = 16326,
        },
        { -- [step X
            PickUp = {
                72267,
            },
            Coord = {
                y = 3552.0,
                x = -1452.5,
            },
            ExtraLineText = "CHOOSE_ZONE",
            ["ExtraLineText2"] = "CHOOSE_ZONE_DF_OP",
            HasAchievement = 16326,
        },
        { -- [step X
            PickUp = {
                72268,
            },
            Coord = {
                y = 3552.0,
                x = -1452.5,
            },
            ExtraLineText = "CHOOSE_ZONE",
            ["ExtraLineText2"] = "CHOOSE_ZONE_DF_AS",
            HasAchievement = 16326,
        },
        { -- [step X
            PickUp = {
                72269,
            },
            Coord = {
                y = 3552.0,
                x = -1452.5,
            },
            ExtraLineText = "CHOOSE_ZONE",
            ["ExtraLineText2"] = "CHOOSE_ZONE_DF_THAL",
            HasAchievement = 16326,
        },
        { -- [step X
            Done = {
                72266,
            },
            Coord = {
                y = 3581.8,
                x = -1456.2,
            },
            HasAchievement = 16326,
        },
        { -- Step 15
            PickUp = {
                69911,
            },
            Coord = {
                y = 3581.5,
                x = -1455.9,
            },
        },
        { -- Step 16
            Done = {
                70123,
            },
            Coord = {
                y = 3541.6,
                x = -1469.2,
            },
        },
        { -- Step 17
            PickUp = {
                67053,
            },
            Coord = {
                y = 3534.3,
                x = -1467.8,
            },
        },
        { -- Step 18
            Done = {
                70124,
            },
            Coord = {
                y = 3544.3,
                x = -1447.8,
            },
        },
        { -- Step 19
            Done = {
                67053,
            },
            Coord = {
                y = 3612.6,
                x = -1438.4,
            },
        },
        { -- Step 20
            PickUp = {
                70135,
            },
            Coord = {
                y = 3612.6,
                x = -1438.4,
            },
        },
        { -- Step 21
            PickUp = {
                66101,
            },
            Coord = {
                y = 3591.7,
                x = -1397.9,
            },
        },
        { -- Step 22
            Qpart = {
                [66101] = {
                    1,
                },
            },
            Coord = {
                y = 3587.0,
                x = -1401.7,
            },
            Range = 5,
            ExtraLineText = "CLICK_SURVEYORS_DISC",
        },
        { -- Step 23
            Qpart = {
                [66101] = {
                    2,
                },
            },
            Coord = {
                y = 3587.0,
                x = -1401.7,
            },
            Range = 5,
            ExtraLineText = "PRESS_1",
        },
        { -- Step 24
            Qpart = {
                [66101] = {
                    3,
                },
            },
            Coord = {
                y = 3587.0,
                x = -1401.7,
            },
            Range = 5,
            ExtraLineText = "PRESS_2",
        },
        { -- Step 25
            Qpart = {
                [66101] = {
                    4,
                },
            },
            Coord = {
                y = 3587.0,
                x = -1401.7,
            },
            Range = 5,
            ExtraLineText = "PRESS_3",
        },
        { -- Step 26
            Done = {
                66101,
            },
            Coord = {
                y = 3591.7,
                x = -1397.9,
            },
        },
        { -- Step 27
            PickUp = {
                69965,
            },
            Coord = {
                y = 3539.8,
                x = -1442.4,
            },
        },
        { -- Step 28
            PickUp = {
                66112,
            },
            Coord = {
                y = 3529.3,
                x = -1437.9,
            },
        },
        { -- Step 29
            Qpart = {
                [69911] = {
                    1,
                },
            },
            Coord = {
                y = 3478.8,
                x = -1435.5,
            },
            Range = 5,
            Gossip = 2,
            RaidIcon = 193393,
        },
        { -- Step 30
            Qpart = {
                [69911] = {
                    2,
                },
            },
            Coord = {
                y = 3479.0,
                x = -1432.9,
            },
            Range = 1,
            ExtraLineText = "CLICK_BOOK_CHOICES_DONT_MATTER",
            Gossip = 1,
        },
        { -- Step 31
            GetFP = 2805,
            Coord = {
                y = 3508.2,
                x = -1411.7,
            },
            Range = 1,
        },
        { -- Step 32
            Qpart = {
                [69911] = {
                    3,
                },
            },
            Coord = {
                y = 3556.1,
                x = -1378.8,
            },
            Range = 5,
            ExtraLineText = "CLICK_STONE_TABLET",
        },
        { -- Step 33
            Qpart = {
                [69911] = {
                    4,
                },
            },
            Coord = {
                y = 3680.3,
                x = -1602.4,
            },
            Range = 5,
            ExtraLineText = "CLICK_BRAZIER",
        },
        { -- Step 34
            Done = {
                69911,
            },
            Coord = {
                y = 3582.1,
                x = -1456.0,
            },
        },
        { -- Step 35
            PickUp = {
                69912,
            },
            Coord = {
                y = 3582.1,
                x = -1456.0,
            },
        },
        { -- Step 36
            Qpart = {
                [69912] = {
                    1,
                },
            },
            Coord = {
                y = 3582.1,
                x = -1456.0,
            },
            Range = 1,
            ExtraLineText = "SPEAK_SENDRAX_SEND_SIGNAL_FLARES",
            Gossip = 1,
        },
        { -- Step 37
            Waypoint = 66112,
            Coord = {
                y = 3418.8,
                x = -1379.0,
            },
            Range = 10,
            ExtraLineText = "HEAD_CAVE",
        },
        { -- Step 38
            Qpart = {
                [66112] = {
                    2,
                },
            },
            Coord = {
                y = 3281.2,
                x = -1327.9,
            },
            Range = 10,
            Fillers = { [69965] = { 1, }, [66111] = { 1, }, },
            ExtraLineText = "ITEM_DROPS_FROM_BARON_CRUSTCORE_AT_BACK_OF_THE_CAVE",
            RaidIcon = 192266,
        },
        { -- Step 39
            Qpart = {
                [66112] = {
                    1,
                },
            },
            Coord = {
                y = 3618.9,
                x = -1165.1,
            },
            Range = 10,
            Fillers = { [69965] = { 1, }, [66111] = { 1, }, },
            ExtraLineText = "ITEM_DROPS_FROM_BARON_ASHFLOW_AT_TOP_OF_THE_LAVA_FLOW",
            RaidIcon = 192274,
        },
        { -- Step 40
            Qpart = {
                [69965] = {
                    1,
                },
            },
            Coord = {
                y = 3448.3,
                x = -1313.7,
            },
            Range = 200,
        },
        { -- Step 41
            Qpart = {
                [70135] = {
                    1,
                },
            },
            Coord = {
                y = 3448.3,
                x = -1313.7,
            },
            Range = 200,
        },
        { -- Step 42
            Done = {
                66112,
            },
            Coord = {
                y = 3529.3,
                x = -1437.9,
            },
        },
        { -- Step 43
            Done = {
                69965,
            },
            Coord = {
                y = 3539.8,
                x = -1442.4,
            },
        },
        { -- Step 44
            Done = {
                70135,
            },
            Coord = {
                y = 3534.4,
                x = -1467.4,
            },
        },
        { -- Step 45
            Done = {
                69912,
            },
            Coord = {
                y = 3537.5,
                x = -1424.7,
            },
        },
        { -- Step 46
            ZoneDoneSave = 1,
        },
    }

    -- Thaldraszus
    APR.RouteQuestStepList["DF06A-2025-Thaldraszus"] = {
        { -- Step 1
            Qpart = {
                [66244] = {
                    1,
                },
            },
            Coord = {
                y = 338.8,
                x = -1099.5,
            },
            Range = 2,
            ExtraLineText = "GET_INSIDE_AND_USE_PORTAL_TOP",
        },
        { -- Step 2
            Done = {
                66244,
            },
            Coord = {
                y = 306.5,
                x = -1042.4,
            },
        },
        { -- Step 3
            PickUp = {
                66159,
            },
            Coord = {
                y = 306.5,
                x = -1042.4,
            },
        },
        { -- Step 4
            Qpart = {
                [66159] = {
                    1,
                },
            },
            Coord = {
                y = 306.5,
                x = -1042.4,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 5
            Done = {
                66159,
            },
            Coord = {
                y = 306.5,
                x = -1042.4,
            },
        },
        { -- Step 6
            PickUp = {
                66163,
            },
            Coord = {
                y = 313.3,
                x = -1061.9,
            },
        },
        { -- Step 7
            PickUp = {
                66166,
            },
            Coord = {
                y = 313.3,
                x = -1061.9,
            },
        },
        { -- Step 8
            Qpart = {
                [66163] = {
                    1,
                },
            },
            Coord = {
                y = 313.3,
                x = -1061.9,
            },
            ExtraLineText = "USE_REVEALING_DRAGONS_EYE",
            Button = {
                ["66163-1"] = 198859,
            },
        },
        { -- Step 9
            Qpart = {
                [66166] = {
                    3,
                },
            },
            Coord = {
                y = 186.6,
                x = -880.5,
            },
            Range = 2,
            Fillers = { [66163] = { 2, }, },
            ExtraLineText = "INSIDE_INN",
        },
        { -- Step 10
            Qpart = {
                [66166] = {
                    2,
                },
            },
            Coord = {
                y = 118.3,
                x = -1058.4,
            },
            Range = 2,
            Fillers = { [66163] = { 2, }, },
            ExtraLineText = "INSIDE_BANK",
        },
        { -- Step 11
            Qpart = {
                [66166] = {
                    1,
                },
            },
            Coord = {
                y = 54.5,
                x = -701.7,
            },
            Range = 2,
            Fillers = { [66163] = { 2, }, },
            ExtraLineText = "ON_TOP_OF_BOX",
        },
        { -- Step 12
            Qpart = {
                [66163] = {
                    2,
                },
            },
            Coord = {
                y = 99.4,
                x = -918.4,
            },
            Range = 300,
            ExtraLineText = "INFILTRATORS_ARE_ACROSS_CITY_THEY_GLOW_RED_WHEN_YOU_ARE_CLOSE",
            Gossip = 1,
        },
        { -- Step 13
            Done = {
                66163,
            },
            Coord = {
                y = 191.1,
                x = -994.1,
            },
        },
        { -- Step 14
            Done = {
                66166,
            },
            Coord = {
                y = 191.1,
                x = -994.1,
            },
        },
        { -- Step 15
            PickUp = {
                66167,
            },
            Coord = {
                y = 191.1,
                x = -994.1,
            },
        },
        { -- Step 16
            Qpart = {
                [66167] = {
                    1,
                },
            },
            Coord = {
                y = -1366.2,
                x = -511.3,
            },
            Range = 2,
            ExtraLineText = "FLY_GUARDIAN_VELOMIR",
        },
        { -- Step 17
            Qpart = {
                [66167] = {
                    2,
                },
            },
            Coord = {
                y = -1366.2,
                x = -511.3,
            },
            Range = 2,
            ExtraLineText = "AID_GUARDIAN",
        },
        { -- Step 18
            Done = {
                66167,
            },
            Coord = {
                y = -1366.2,
                x = -511.3,
            },
        },
        { -- Step 19
            PickUp = {
                66169,
            },
            Coord = {
                y = -1366.2,
                x = -511.3,
            },
        },
        { -- Step 20
            PickUp = {
                66246,
            },
            Coord = {
                y = -1366.2,
                x = -511.3,
            },
        },
        { -- Step 21
            Qpart = {
                [66246] = {
                    1,
                },
            },
            Coord = {
                y = -1493.0,
                x = -550.2,
            },
            Range = 125,
            Fillers = { [66169] = { 1, }, },
            ExtraLineText = "VELOMIRS_UNITS_ARE_MARKED_ON_MINIMAP",
            Gossip = 1,
        },
        { -- Step 22
            Qpart = {
                [66169] = {
                    1,
                },
            },
            Coord = {
                y = -1493.0,
                x = -550.2,
            },
            Range = 125,
        },
        { -- Step 23
            Done = {
                66169,
            },
            Coord = {
                y = -1401.9,
                x = -691.2,
            },
        },
        { -- Step 24
            Done = {
                66246,
            },
            Coord = {
                y = -1401.9,
                x = -691.2,
            },
            Gossip = 1,
        },
        { -- Step 25
            PickUp = {
                66245,
            },
            Coord = {
                y = -1401.9,
                x = -691.2,
            },
            Gossip = 1,
        },
        { -- Step 26
            PickUp = {
                66247,
            },
            Coord = {
                y = -1414.0,
                x = -713.7,
            },
            Gossip = 1,
        },
        { -- Step 27
            PickUp = {
                66248,
            },
            Coord = {
                y = -1424.0,
                x = -784.6,
            },
        },
        { -- Step 28
            Qpart = {
                [66247] = {
                    1,
                },
            },
            Coord = {
                y = -1428.9,
                x = -819.5,
            },
            Range = 200,
            Fillers = { [66248] = { 1, }, [66245] = { 1, }, },
        },
        { -- Step 29
            Qpart = {
                [66248] = {
                    1,
                },
            },
            Coord = {
                y = -1428.9,
                x = -819.5,
            },
            Range = 200,
            Fillers = { [66245] = { 1, }, },
        },
        { -- Step 30
            Qpart = {
                [66245] = {
                    1,
                },
            },
            Coord = {
                y = -1428.9,
                x = -819.5,
            },
            Range = 200,
        },
        { -- Step 31
            Done = {
                66247,
            },
            Coord = {
                y = -1401.9,
                x = -691.2,
            },
        },
        { -- Step 32
            Done = {
                66248,
            },
            Coord = {
                y = -1401.9,
                x = -691.2,
            },
        },
        { -- Step 33
            Done = {
                66245,
            },
            Coord = {
                y = -1401.9,
                x = -691.2,
            },
        },
        { -- Step 34
            PickUp = {
                66249,
            },
            Coord = {
                y = -1401.9,
                x = -691.2,
            },
        },
        { -- Step 35
            Qpart = {
                [66249] = {
                    1,
                },
            },
            Coord = {
                y = -1459.9,
                x = -1020.2,
            },
            Range = 2,
            ExtraLineText = "SHOOT_DRAGONS",
        },
        { -- Step 36
            Qpart = {
                [66249] = {
                    2,
                },
            },
            Coord = {
                y = -1459.9,
                x = -1020.2,
            },
            Range = 2,
            ExtraLineText = "SHOOT_DRAGONS",
        },
        { -- Step 37
            Done = {
                66249,
            },
            Coord = {
                y = -1563.0,
                x = -987.0,
            },
        },
        { -- Step 38
            PickUp = {
                66250,
            },
            Coord = {
                y = -1563.0,
                x = -987.0,
            },
        },
        { -- Step 39
            Qpart = {
                [66250] = {
                    1,
                },
            },
            Coord = {
                y = -1563.0,
                x = -987.0,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 40
            Done = {
                66250,
            },
            Coord = {
                y = -1539.8,
                x = -946.7,
            },
        },
        { -- Step 41
            PickUp = {
                66251,
            },
            Coord = {
                y = -1539.8,
                x = -946.7,
            },
        },
        { -- Step 42
            Qpart = {
                [66251] = {
                    1,
                },
            },
            Coord = {
                y = -1639.2,
                x = -941.9,
            },
            Range = 2,
        },
        { -- Step 43
            Done = {
                66251,
            },
            Coord = {
                y = -1539.8,
                x = -946.7,
            },
        },
        { -- Step 44
            PickUp = {
                66252,
            },
            Coord = {
                y = -1539.8,
                x = -946.7,
            },
        },
        { -- Step 45
            Waypoint = 1,
            Coord = {
                y = 164.0,
                x = -902.5,
            },
            Range = 2,
        },
        { -- Step 46
            SetHS = 66252,
            Coord = {
                y = 200.9,
                x = -887.5,
            },
        },
        { -- Step 47
            Waypoint = 66252,
            Coord = {
                y = 338.3,
                x = -1099.7,
            },
            Range = 5,
            ExtraLineText = "TAKE_TELEPORTER_SEAT_OF_ASPECTS",
        },
        { -- Step 48
            Done = {
                66252,
            },
            Coord = {
                y = 261.3,
                x = -1012.9,
            },
            ExtraLineText = "ON_TOP_OF_TOWER",
        },
        { -- Step 49
            PickUp = {
                66320,
            },
            Coord = {
                y = 267.6,
                x = -1085.0,
            },
        },
        { -- Step 50
            Qpart = {
                [66320] = {
                    1,
                },
            },
            Coord = {
                y = -1120.5,
                x = -2699.0,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 51
            Done = {
                66320,
            },
            Coord = {
                y = -1120.5,
                x = -2699.0,
            },
        },
        { -- Step 52
            GetFP = 2816,
            Coord = {
                y = -1127.2,
                x = -2716.1,
            },
            Range = 2,
        },
        { -- Step 53
            PickUp = {
                66080,
            },
            Coord = {
                y = -1112.5,
                x = -2705.4,
            },
        },
        { -- Step 54
            Qpart = {
                [66080] = {
                    1,
                },
            },
            Coord = {
                y = -899.2,
                x = -2446.5,
            },
            Range = 2,
            ExtraLineText = "COMPLETES_WHEN_YOU_GET_CLOSE",
        },
        { -- Step 55
            Done = {
                66080,
            },
            Coord = {
                y = -899.2,
                x = -2446.5,
            },
            Gossip = 1,
        },
        { -- Step 56
            PickUp = {
                70136,
            },
            Coord = {
                y = -899.2,
                x = -2446.5,
            },
        },
        { -- Step 57
            Qpart = {
                [70136] = {
                    2,
                },
            },
            Coord = {
                y = -1016.9,
                x = -2266.5,
            },
            Range = 5,
        },
        { -- Step 58
            Qpart = {
                [70136] = {
                    3,
                },
            },
            Coord = {
                y = -980.1,
                x = -2221.0,
            },
            Range = 5,
            ExtraLineText = "INSIDE_CAVE",
        },
        { -- Step 59
            Qpart = {
                [70136] = {
                    1,
                },
            },
            Coord = {
                y = -980.1,
                x = -2221.0,
            },
            Range = 5,
            ExtraLineText = "LOOT_STAFF",
        },
        { -- Step 60
            Done = {
                70136,
            },
            Coord = {
                y = -899.2,
                x = -2446.5,
            },
        },
        { -- Step 61
            PickUp = {
                66081,
            },
            Coord = {
                y = -899.2,
                x = -2446.5,
            },
        },
        { -- Step 62
            PickUp = {
                66082,
            },
            Coord = {
                y = -899.2,
                x = -2446.5,
            },
        },
        { -- Step 63
            Qpart = {
                [66081] = {
                    1,
                },
            },
            Coord = {
                y = -1012.2,
                x = -2391.5,
            },
            Range = 125,
            Fillers = { [66082] = { 1, }, },
        },
        { -- Step 64
            Qpart = {
                [66082] = {
                    1,
                },
            },
            Coord = {
                y = -1012.2,
                x = -2391.5,
            },
            Range = 125,
        },
        { -- Step 65
            Done = {
                66081,
            },
            Coord = {
                y = -1120.5,
                x = -2699.0,
            },
        },
        { -- Step 66
            Done = {
                66082,
            },
            Coord = {
                y = -1120.5,
                x = -2699.0,
            },
        },
        { -- Step 67
            PickUp = {
                66083,
            },
            Coord = {
                y = -1111.8,
                x = -2705.8,
            },
        },
        { -- Step 68
            Qpart = {
                [66083] = {
                    1,
                },
            },
            Coord = {
                y = -1084.3,
                x = -2718.0,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 69
            Qpart = {
                [66083] = {
                    2,
                },
            },
            Coord = {
                y = -1085.0,
                x = -2718.8,
            },
            Range = 2,
        },
        { -- Step 70
            Qpart = {
                [66083] = {
                    3,
                },
            },
            Coord = {
                y = -1085.0,
                x = -2718.8,
            },
            Range = 2,
        },
        { -- Step 71
            Qpart = {
                [66083] = {
                    4,
                },
            },
            Coord = {
                y = -1085.0,
                x = -2718.8,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 72
            Done = {
                66083,
            },
            Coord = {
                y = -1111.8,
                x = -2705.8,
            },
        },
        { -- Step 73
            PickUp = {
                66084,
            },
            Coord = {
                y = -1111.8,
                x = -2705.8,
            },
        },
        { -- Step 74
            PickUp = {
                66085,
            },
            Coord = {
                y = -1120.0,
                x = -2698.6,
            },
        },
        { -- Step 75
            Qpart = {
                [66085] = {
                    1,
                },
            },
            Coord = {
                y = -1072.5,
                x = -2810.0,
            },
            Range = 2,
            Fillers = { [66084] = { 1, }, },
        },
        { -- Step 76
            Qpart = {
                [66085] = {
                    2,
                },
            },
            Coord = {
                y = -1147.9,
                x = -2937.8,
            },
            Range = 2,
            Fillers = { [66084] = { 1, }, },
            Gossip = 1,
        },
        { -- Step 77
            Qpart = {
                [66085] = {
                    3,
                },
            },
            Coord = {
                y = -1147.7,
                x = -2957.4,
            },
            Range = 2,
            Fillers = { [66084] = { 1, }, },
        },
        { -- Step 78
            Qpart = {
                [66085] = {
                    4,
                },
            },
            Coord = {
                y = -1005.0,
                x = -2953.1,
            },
            Range = 2,
            Fillers = { [66084] = { 1, }, },
        },
        { -- Step 79
            Qpart = {
                [66085] = {
                    5,
                },
            },
            Coord = {
                y = -1005.0,
                x = -2953.1,
            },
            Range = 2,
            Fillers = { [66084] = { 1, }, },
            Gossip = 1,
        },
        { -- Step 80
            Qpart = {
                [66084] = {
                    1,
                },
            },
            Coord = {
                y = -1090.4,
                x = -2891.1,
            },
            Range = 80,
        },
        { -- Step 81
            Done = {
                66084,
            },
            Coord = {
                y = -1111.8,
                x = -2705.8,
            },
        },
        { -- Step 82
            Done = {
                66085,
            },
            Coord = {
                y = -1120.0,
                x = -2698.6,
            },
        },
        { -- Step 83
            PickUp = {
                66087,
            },
            Coord = {
                y = -1117.3,
                x = -2708.0,
            },
        },
        { -- Step 84
            Qpart = {
                [66087] = {
                    1,
                },
            },
            Coord = {
                y = -1385.4,
                x = -2660.1,
            },
            Range = 225,
            SpellButton = {
                ["66087-1"] = 376679,
            },
        },
        { -- Step 85
            Done = {
                66087,
            },
            Coord = {
                y = -1117.3,
                x = -2708.0,
            },
        },
        { -- Step 86
            PickUp = {
                65935,
            },
            Coord = {
                y = -1112.7,
                x = -2705.6,
            },
        },
        { -- Step 87
            Qpart = {
                [65935] = {
                    1,
                },
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
            Range = 2,
            ExtraLineText = "COMPLETES_ONCE_YOU_REACH_CHROMIE",
        },
        { -- Step 88
            Done = {
                65935,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 89
            PickUp = {
                65947,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 90
            PickUp = {
                65948,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 91
            PickUp = {
                66646,
            },
            Coord = {
                y = -1373.0,
                x = -2911.3,
            },
        },
        { -- Step 92
            Qpart = {
                [65948] = {
                    1,
                },
            },
            Coord = {
                y = -1401.0,
                x = -2811.1,
            },
            Range = 2,
            Fillers = { [65947] = { 1, }, [66646] = { 1, }, },
        },
        { -- Step 93
            Qpart = {
                [65948] = {
                    2,
                },
            },
            Coord = {
                y = -1226.7,
                x = -3024.6,
            },
            Range = 2,
            Fillers = { [65947] = { 1, }, [66646] = { 1, }, },
        },
        { -- Step 94
            Qpart = {
                [65947] = {
                    1,
                },
                [66646] = {
                    1,
                },
                [65948] = {
                    3,
                },
            },
            Coord = {
                y = -1286.9,
                x = -2902.9,
            },
            Range = 180,
        },
        { -- Step 95
            Done = {
                65948,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 96
            Done = {
                65947,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 97
            Done = {
                66646,
            },
            Coord = {
                y = -1373.0,
                x = -2911.3,
            },
        },
        { -- Step 98
            PickUp = {
                65938,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 99
            Qpart = {
                [65938] = {
                    1,
                },
            },
            Coord = {
                y = -1422.7,
                x = -3014.4,
            },
            Range = 2,
            SpellButton = {
                ["65938-1"] = 372959,
            },
        },
        { -- Step 100
            Qpart = {
                [65938] = {
                    2,
                },
            },
            Coord = {
                y = -1450.0,
                x = -3017.6,
            },
            Range = 2,
            ExtraLineText = "KILL_ELEMENTAL",
        },
        { -- Step 101
            Done = {
                65938,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 102
            PickUp = {
                65962,
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
        },
        { -- Step 103
            Qpart = {
                [65962] = {
                    1,
                },
            },
            Coord = {
                y = -1308.0,
                x = -2913.4,
            },
            Range = 2,
            Gossip = 6,
        },
        { -- Step 104
            Done = {
                65962,
            },
            Coord = {
                y = -1358.4,
                x = -2961.0,
            },
        },
        { -- Step 105
            PickUp = {
                70040,
            },
            Coord = {
                y = -1358.4,
                x = -2961.0,
            },
        },
        { -- Step 106
            Qpart = {
                [70040] = {
                    2,
                },
            },
            Coord = {
                y = -1312.9,
                x = -2975.5,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 107
            Qpart = {
                [70040] = {
                    1,
                },
            },
            Coord = {
                y = -1363.8,
                x = -2907.1,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 108
            Qpart = {
                [70040] = {
                    3,
                },
            },
            Coord = {
                y = -1339.5,
                x = -2885.6,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 109
            Qpart = {
                [70040] = {
                    4,
                },
            },
            Coord = {
                y = -1358.4,
                x = -2961.0,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 110
            Done = {
                70040,
            },
            Coord = {
                y = -1358.4,
                x = -2961.0,
            },
        },
        { -- Step 111
            PickUp = {
                66028,
            },
            Coord = {
                y = -1358.4,
                x = -2961.0,
            },
        },
        { -- Step 112
            PickUp = {
                66029,
            },
            Coord = {
                y = -1358.4,
                x = -2961.0,
            },
        },
        { -- Step 113
            Qpart = {
                [66028] = {
                    1,
                },
            },
            Coord = {
                y = -1344.9,
                x = -2938.6,
            },
            Range = 2,
            ExtraLineText = "USE_PORTAL",
        },
        { -- Step 114
            Done = {
                66028,
            },
            Coord = {
                y = -1341.3,
                x = -2937.1,
            },
        },
        { -- Step 115
            PickUp = {
                66030,
            },
            Coord = {
                y = -1341.3,
                x = -2937.1,
            },
        },
        { -- Step 116
            PickUp = {
                66031,
            },
            Coord = {
                y = -1332.3,
                x = -2945.3,
            },
        },
        { -- Step 117
            Qpart = {
                [66029] = {
                    1,
                },
            },
            Coord = {
                y = -1202.3,
                x = -2626.3,
            },
            Range = 2,
            Button = {
                ["66029-1"] = 192749,
            },
        },
        { -- Step 118
            Qpart = {
                [66031] = {
                    1,
                },
            },
            Coord = {
                y = -1093.0,
                x = -2617.6,
            },
            Range = 2,
            Fillers = { [66030] = { 1, }, },
            SpellButton = {
                ["66031-1"] = 372520,
            },
        },
        { -- Step 119
            Qpart = {
                [66030] = {
                    1,
                },
            },
            Coord = {
                y = -1093.0,
                x = -2617.6,
            },
            Range = 2,
        },
        { -- Step 120
            Done = {
                66030,
            },
            Coord = {
                y = -1341.3,
                x = -2937.1,
            },
        },
        { -- Step 121
            Done = {
                66031,
            },
            Coord = {
                y = -1332.3,
                x = -2945.3,
            },
        },
        { -- Step 122
            PickUp = {
                66032,
            },
            Coord = {
                y = -1341.3,
                x = -2937.1,
            },
        },
        { -- Step 123
            Done = {
                66032,
            },
            Coord = {
                y = -1359.2,
                x = -2961.9,
            },
            ExtraLineText = "LEAVE_PORTAL",
        },
        { -- Step 124
            Done = {
                66029,
            },
            Coord = {
                y = -1359.2,
                x = -2961.9,
            },
        },
        { -- Step 125
            PickUp = {
                72519,
            },
            Coord = {
                y = -1359.2,
                x = -2961.9,
            },
        },
        { -- Step 126
            PickUp = {
                66033,
            },
            Coord = {
                y = -1359.2,
                x = -2961.9,
            },
        },
        { -- Step 127
            Qpart = {
                [66033] = {
                    1,
                },
            },
            Coord = {
                y = -1334.2,
                x = -2953.8,
            },
            Range = 2,
        },
        { -- Step 128
            Done = {
                66033,
            },
            Coord = {
                y = 3101.4,
                x = 272.0,
            },
        },
        { -- Step 129
            PickUp = {
                66035,
            },
            Coord = {
                y = 3101.4,
                x = 272.0,
            },
        },
        { -- Step 130
            PickUp = {
                66036,
            },
            Coord = {
                y = 3108.0,
                x = 263.5,
            },
        },
        { -- Step 131
            Qpart = {
                [72519] = {
                    1,
                },
            },
            Coord = {
                y = 3260.6,
                x = 170.6,
            },
            Range = 2,
        },
        { -- Step 132
            Qpart = {
                [66035] = {
                    1,
                },
            },
            Coord = {
                y = 3130.0,
                x = 224.1,
            },
            Range = 250,
            ExtraLineText = "MOTES_CAN_BE_SEEN_ON_MINIMAP",
        },
        { -- Step 133
            Qpart = {
                [66036] = {
                    1,
                },
            },
            Coord = {
                y = 3130.0,
                x = 224.1,
            },
            Range = 250,
        },
        { -- Step 134
            Done = {
                66036,
            },
            Coord = {
                y = 3107.9,
                x = 263.2,
            },
        },
        { -- Step 135
            Done = {
                66035,
            },
            Coord = {
                y = 3101.9,
                x = 271.5,
            },
        },
        { -- Step 136
            PickUp = {
                70373,
            },
            Coord = {
                y = 3107.9,
                x = 263.2,
            },
        },
        { -- Step 137
            Qpart = {
                [70373] = {
                    1,
                },
            },
            Coord = {
                y = 3118.1,
                x = 273.5,
            },
            Range = 2,
            ExtraLineText = "ENTER_PLANE",
        },
        { -- Step 138
            Done = {
                70373,
            },
            Coord = {
                y = 3107.9,
                x = 263.2,
            },
        },
        { -- Step 139
            PickUp = {
                66037,
            },
            Coord = {
                y = 3101.9,
                x = 271.5,
            },
        },
        { -- Step 140
            Qpart = {
                [66037] = {
                    1,
                },
            },
            Coord = {
                y = 3102.9,
                x = 277.3,
            },
            Range = 2,
            ExtraLineText = "ENTER_PORTAL",
        },
        { -- Step 141
            Done = {
                72519,
            },
            Coord = {
                y = -1359.0,
                x = -2961.6,
            },
        },
        { -- Step 142
            Done = {
                66037,
            },
            Coord = {
                y = -1359.0,
                x = -2961.6,
            },
        },
        { -- Step 143
            PickUp = {
                66660,
            },
            Coord = {
                y = -1359.0,
                x = -2961.6,
            },
        },
        { -- Step 144
            Qpart = {
                [66660] = {
                    1,
                },
            },
            Coord = {
                y = -1341.5,
                x = -2948.3,
            },
            Range = 2,
            ExtraLineText = "ENTER_PORTAL",
        },
        { -- Step 145
            Done = {
                66660,
            },
            Coord = {
                y = 15534.9,
                x = 15512.9,
            },
        },
        { -- Step 146
            PickUp = {
                66038,
            },
            Coord = {
                y = 15534.9,
                x = 15512.9,
            },
        },
        { -- Step 147
            Done = {
                66038,
            },
            Coord = {
                y = -1309.7,
                x = 7427.0,
            },
        },
        { -- Step 148
            PickUp = {
                66039,
            },
            Coord = {
                y = -1309.7,
                x = 7427.0,
            },
        },
        { -- Step 149
            Qpart = {
                [66039] = {
                    1,
                },
            },
            Coord = {
                y = -949.1,
                x = 7409.8,
            },
            Range = 2,
            Button = {
                ["66039-1"] = 192749,
            },
        },
        { -- Step 150
            Done = {
                66039,
            },
            Coord = {
                y = -946.7,
                x = 7407.1,
            },
        },
        { -- Step 151
            PickUp = {
                66040,
            },
            Coord = {
                y = -946.7,
                x = 7407.1,
            },
        },
        { -- Step 152
            Qpart = {
                [66040] = {
                    1,
                },
            },
            Coord = {
                y = -946.7,
                x = 7407.1,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 153
            Qpart = {
                [66040] = {
                    2,
                },
            },
            Coord = {
                y = -1356.7,
                x = -2964.0,
            },
            Range = 2,
            Gossip = 1,
        },
        { -- Step 154
            Done = {
                66040,
            },
            Coord = {
                y = -1359.0,
                x = -2962.0,
            },
        },
        { -- Step 155
            PickUp = {
                66221,
            },
            Coord = {
                y = -1359.0,
                x = -2962.0,
            },
        },
        { -- Step 156
            UseHS = 66221,
            Button = {
                ["22345678-1"] = 6948,
            },
        },
        { -- Step 157
            Qpart = {
                [66221] = {
                    1,
                },
            },
            Coord = {
                y = 308.2,
                x = -1041.0,
            },
            Range = 2,
            ExtraLineText = "ON_TOP_OF_TOWER",
            Gossip = 1,
        },
        { -- Step 158
            Done = {
                66221,
            },
            Coord = {
                y = 308.2,
                x = -1041.0,
            },
        },
        { -- Step 159
            ZoneDoneSave = 1,
        },
    }

    --Dracthyr
    APR.RouteQuestStepList["2118-DracthyrStart-A"] = {
        { -- Step 1
            PickUp = {
                64864,
            },
            Coord = {
                y = 5787.2,
                x = -3073.3,
            },
        },
        { -- Step 2
            Qpart = {
                [64864] = {
                    1,
                },
            },
            Coord = {
                y = 5787.2,
                x = -3073.3,
            },
            Range = 1,
            ExtraLineText = "INTERACT_WITH_DERVISHIAN",
            RaidIcon = 181494,
        },
        { -- Step 3
            Qpart = {
                [64864] = {
                    3,
                },
            },
            Coord = {
                y = 5779.8349609375,
                x = -3038.6650390625,
            },
            Range = 1,
            ExtraLineText = "JUMP_DOWN_AND_INTERACT_WITH_TETHALASH",
            RaidIcon = 181680,
        },
        { -- Step 4
            Qpart = {
                [64864] = {
                    2,
                },
            },
            Coord = {
                y = 5820.435059,
                x = -3077.706055,
            },
            Range = 1,
            ExtraLineText = "CLICK_ON_BONES_ON_THE_BED",
        },
        { -- Step 5
            Waypoint = 64864,
            Coord = {
                y = 5806.732421875,
                x = -3065.5263671875,
            },
            Range = 5,
        },
        { -- Step 6
            Waypoint = 64864,
            Coord = {
                y = 5804.7026367188,
                x = -2982.3325195312,
            },
            Range = 5,
        },
        { -- Step 7
            Waypoint = 64864,
            Coord = {
                y = 5812.169921875,
                x = -2928.8276367188,
            },
            Range = 5,
        },
        { -- Step 8
            Qpart = {
                [64864] = {
                    4,
                },
            },
            Coord = {
                y = 5800.20752,
                x = -2905.881348,
            },
            Range = 1,
            ExtraLineText = "INTERACT_WITH_AZURATHEL",
            RaidIcon = 183380,
        },
        { -- Step 9
            Done = {
                64864,
            },
            Coord = {
                y = 5808.617676,
                x = -2914.254883,
            },
        },
        { -- Step 10
            PickUp = {
                64865,
            },
            Coord = {
                y = 5808.617676,
                x = -2914.254883,
            },
        },
        { -- Step 11
            PickUp = {
                64863,
            },
            Coord = {
                y = 5815.142578125,
                x = -2915.9951171875,
            },
        },
        { -- Step 12
            Waypoint = 66010,
            Coord = {
                y = 5862.2,
                x = -2945.5,
            },
            Range = 1,
            ExtraLineText = "BONUS_BUFF_INTERACT_WITH_CRYSTAL_KEY_AND_PLACE_IT_INTO_THE_CRYSTAL_FOCUS_NEXT_IT",
        },
        { -- Step 13
            Done = {
                66010,
            },
            Coord = {
                y = 5859.7299804688,
                x = -2972.6538085938,
            },
            ExtraLineText = "BONUS_BUFF_PICK_UP_MYSTERIOUS_WAND_ON_THE_TABLE",
        },
        { -- Step 14
            Qpart = {
                [64865] = {
                    1,
                },
            },
            Coord = {
                y = 5919.8325195312,
                x = -3046.0600585938,
            },
            Range = 1,
            Fillers = { [64863] = { 1, }, },
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS",
        },
        { -- Step 15
            Qpart = {
                [64865] = {
                    3,
                },
            },
            Coord = {
                y = 5957.025390625,
                x = -2928.71875,
            },
            Range = 1,
            Fillers = { [64863] = { 1, }, },
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS",
        },
        { -- Step 16
            Qpart = {
                [64865] = {
                    2,
                },
            },
            Coord = {
                y = 6027.7124023438,
                x = -2977.982421875,
            },
            Range = 1,
            Fillers = { [64863] = { 1, }, },
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS",
        },
        { -- Step 17
            Qpart = {
                [64863] = {
                    1,
                },
            },
            Coord = {
                y = 5955.4301757812,
                x = -2952.6437988281,
            },
            Range = 20,
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS",
        },
        { -- Step 18
            Waypoint = 64865,
            Coord = {
                y = 6001.3950195312,
                x = -2988.53125,
            },
            Range = 5,
        },
        { -- Step 19
            Done = {
                64863,
                64865,
            },
            Coord = {
                y = 5971.2348632812,
                x = -3033.5537109375,
            },
            Range = 5,
        },
        { -- Step 20
            PickUp = {
                64866,
            },
            Coord = {
                y = 5975.4399414062,
                x = -3054.5424804688,
            },
            Range = 1,
        },
        { -- Step 21
            Qpart = {
                [64866] = {
                    1,
                },
            },
            Coord = {
                y = 6102.3,
                x = -3221.8,
            },
            Range = 15,
            ExtraLineText = "GLIDE_DOWN",
        },
        { -- Step 22
            QpartPart = {
                [64866] = {
                    2,
                },
            },
            Coord = {
                y = 6116.8876953125,
                x = -3137.6274414062,
            },
            Range = 5,
            SpellButton = {
                ["64866-2"] = 361469,
            },
            TrigText = "1/5",
        },
        { -- Step 23
            QpartPart = {
                [64866] = {
                    2,
                },
            },
            Coord = {
                y = 6033.3671875,
                x = -3200.1586914062,
            },
            Range = 5,
            SpellButton = {
                ["64866-2"] = 361469,
            },
            TrigText = "2/5",
        },
        { -- Step 24
            QpartPart = {
                [64866] = {
                    2,
                },
            },
            Coord = {
                y = 6035.3974609375,
                x = -3238.4387207031,
            },
            Range = 5,
            SpellButton = {
                ["64866-2"] = 361469,
            },
            TrigText = "3/5",
        },
        { -- Step 25
            QpartPart = {
                [64866] = {
                    2,
                },
            },
            Coord = {
                y = 6087.59765625,
                x = -3253.2290039062,
            },
            Range = 5,
            SpellButton = {
                ["64866-2"] = 361469,
            },
            TrigText = "4/5",
        },
        { -- Step 26
            QpartPart = {
                [64866] = {
                    2,
                },
            },
            Coord = {
                y = 6101.2275390625,
                x = -3190.2624511719,
            },
            Range = 5,
            SpellButton = {
                ["64866-2"] = 361469,
            },
            TrigText = "5/5",
        },
        { -- Step 27
            Done = {
                64866,
            },
            Coord = {
                y = 6137.1875,
                x = -3230.2827148438,
            },
        },
        { -- Step 28
            PickUp = {
                64871,
            },
            Coord = {
                y = 6136.0278320312,
                x = -3234.1975097656,
            },
        },
        { -- Step 29
            Qpart = {
                [64871] = {
                    1,
                },
            },
            Coord = {
                y = 6322.498046875,
                x = -3278.3500976562,
            },
            Range = 1,
            ExtraLineText = "MAKE_SURE_COMPLETE_THIS_STEP_BEFORE_KILLING_DRAGON",
        },
        { -- Step 30
            Qpart = {
                [64871] = {
                    2,
                },
            },
            Coord = {
                y = 6322.498046875,
                x = -3278.3500976562,
            },
            Range = 1,
        },
        { -- Step 31
            Done = {
                64871,
            },
            Coord = {
                y = 6393.9462890625,
                x = -3304.0788574219,
            },
            ExtraLineText = "CANCEL_CHOCKING_BUFF_INCREASE_MOVEMENT_SPEED",
        },
        { -- Step 32
            PickUp = {
                64872,
            },
            Coord = {
                y = 6393.9462890625,
                x = -3304.0788574219,
            },
        },
        { -- Step 33
            PickUp = {
                65615,
            },
            Coord = {
                y = 6396.296875,
                x = -3296.2124023438,
            },
        },
        { -- Step 34
            Qpart = {
                [64872] = {
                    3,
                },
            },
            Coord = {
                y = 6397.9243164062,
                x = -3287.5322265625,
            },
            Range = 1,
            ExtraLineText = "RESET_COOLDOWN_BY_CLICKING_ON_THE_FIRE_BREATH_INFUSERS",
            ["ExtraLineText2"] = "HOLD_IT_UNTIL_YOU_REACH_LAST_EMPOWEREMENT_SECTION",
            SpellButton = {
                ["64872-3"] = 363898,
            },
        },
        { -- Step 35
            Qpart = {
                [64872] = {
                    2,
                },
            },
            Coord = {
                y = 6397.9243164062,
                x = -3287.5322265625,
            },
            Range = 1,
            ExtraLineText = "RESET_COOLDOWN_BY_CLICKING_ON_THE_FIRE_BREATH_INFUSERS",
            ["ExtraLineText2"] = "HOLD_IT_UNTIL_YOU_REACH_SECOND_EMPOWEREMENT_SECTION",
            SpellButton = {
                ["64872-2"] = 363898,
            },
        },
        { -- Step 36
            Qpart = {
                [65615] = {
                    1,
                },
            },
            Coord = {
                y = 6534.99609375,
                x = -3332.0173339844,
            },
            Range = 1,
        },
        { -- Step 37
            Qpart = {
                [64872] = {
                    1,
                },
            },
            Coord = {
                y = 6464.109375,
                x = -3304.62109375,
            },
            Range = 1,
            ExtraLineText = "RESET_COOLDOWN_BY_CLICKING_ON_THE_FIRE_BREATH_INFUSERS",
            ["ExtraLineText2"] = "DONT_HOLD_DOWN_BUTTON",
            SpellButton = {
                ["64872-1"] = 363898,
            },
        },
        { -- Step 38
            Done = {
                64872,
            },
            Coord = {
                y = 6394.126953125,
                x = -3304.3500976562,
            },
            Range = 1,
        },
        { -- Step 39
            Done = {
                65615,
            },
            Coord = {
                y = 6396.658203125,
                x = -3295.94140625,
            },
            Range = 1,
        },
        { -- Step 40
            SetHS = 64873,
            Coord = {
                y = 6406.78515625,
                x = -3277.767578125,
            },
        },
        { -- Step 41
            PickUp = {
                64873,
            },
            Coord = {
                y = 6402.083984375,
                x = -3308.1474609375,
            },
        },
        { -- Step 42
            Qpart = {
                [64873] = {
                    1,
                },
            },
            Coord = {
                y = 6463.748046875,
                x = -3313.3012695312,
            },
            Range = 2,
            ExtraLineText = "USE_BUTTON_TELEPORT_RIGHT_INFRONT_OF_THE_NPC",
            Button = {
                ["64873-1"] = 195044,
            },
        },
        { -- Step 43
            Qpart = {
                [64873] = {
                    2,
                },
            },
            Coord = {
                y = 6463.748046875,
                x = -3313.3012695312,
            },
            Range = 2,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["64873-2"] = 369536,
            },
        },
        { -- Step 44
            Qpart = {
                [64873] = {
                    3,
                },
            },
            Coord = {
                y = 6687.2573242188,
                x = -3470.6259765625,
            },
            Range = 1,
        },
        { -- Step 45
            Done = {
                65909,
            },
            Coord = {
                y = 6884.9072265625,
                x = -3242.5048828125,
            },
            ExtraLineText = "PICK_UP_BAG_OF_ENCHANTED_WIND_FOR_A_MOVEMENT_SPEED_BUFF",
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["65909"] = 369536,
            },
        },
        { -- Step 46
            Qpart = {
                [64873] = {
                    4,
                },
            },
            Coord = {
                y = 6634.4541015625,
                x = -3223.517578125,
            },
            Range = 1,
            ExtraLineText = "USE_BUTTON_TELEPORT_RIGHT_INFRONT_OF_THE_NPC",
            Button = {
                ["64873-4"] = 195044,
            },
        },
        { -- Step 47
            Qpart = {
                [64873] = {
                    5,
                },
            },
            Coord = {
                y = 6609.6796875,
                x = -3038.25390625,
            },
            Range = 1,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["64873-5"] = 369536,
            },
        },
        { -- Step 48
            Qpart = {
                [64873] = {
                    6,
                },
            },
            Coord = {
                y = 6463.9287109375,
                x = -3312.7587890625,
            },
            Range = 1,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["64873-6"] = 369536,
            },
        },
        { -- Step 49
            Qpart = {
                [64873] = {
                    7,
                },
            },
            Coord = {
                y = 6862.6655273438,
                x = -3531.6574707031,
            },
            Range = 1,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["64873-7"] = 369536,
            },
        },
        { -- Step 50
            Done = {
                64873,
            },
            Coord = {
                y = 6464.109375,
                x = -3312.758,
            },
        },
        { -- Step 51
            PickUp = {
                65036,
            },
            Coord = {
                y = 6464.109375,
                x = -3312.7587890625,
            },
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["65036"] = 369536,
            },
        },
        { -- Step 52
            Qpart = {
                [65036] = {
                    1,
                },
            },
            Coord = {
                y = 6464.109,
                x = -3312.7587890625,
            },
            Range = 1,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["65036-1"] = 369536,
            },
        },
        { -- Step 53
            Done = {
                65036,
            },
            Coord = {
                y = 6400.275390625,
                x = -3299.7387695312,
            },
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["65036"] = 369536,
            },
        },
        { -- Step 54
            PickUp = {
                65060,
            },
            Coord = {
                y = 6400.275390625,
                x = -3299.7387695312,
            },
        },
        { -- Step 55
            Qpart = {
                [65060] = {
                    1,
                },
            },
            Coord = {
                y = 6917.8193359375,
                x = -3088.9775390625,
            },
            Range = 1,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["65060-1"] = 369536,
            },
            Gossip = 1,
        },
        { -- Step 56
            Done = {
                65060,
            },
            Coord = {
                y = 7220.171875,
                x = -2610.2211914062,
            },
            Range = 1,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["65060"] = 369536,
            },
        },
        { -- Step 57
            PickUp = {
                65063,
            },
            Coord = {
                y = 7220.171875,
                x = -2610.2211914062,
            },
        },
        { -- Step 58
            Qpart = {
                [65063] = {
                    1,
                },
            },
            Coord = {
                y = 7236.998046875,
                x = -2597.1850585938,
            },
            Range = 1,
            ExtraActionB = 1,
        },
        { -- Step 59
            Done = {
                65063,
            },
            Coord = {
                y = 7161.220703125,
                x = -2644.669921875,
            },
        },
        { -- Step 60
            PickUp = {
                65073,
            },
            Coord = {
                y = 7161.220703125,
                x = -2644.669921875,
            },
        },
        { -- Step 61
            PickUp = {
                65074,
            },
            Coord = {
                y = 7162.6669921875,
                x = -2648.4675292969,
            },
        },
        { -- Step 62
            Qpart = {
                [65073] = {
                    1,
                },
            },
            Coord = {
                y = 7062.84765625,
                x = -3055.0712890625,
            },
            Range = 30,
            Fillers = { [65074] = { 1, }, },
            ExtraLineText = "JUMP_AND_FLY",
        },
        { -- Step 63
            Qpart = {
                [65074] = {
                    1,
                },
            },
            Coord = {
                y = 7057.96484375,
                x = -2949.826171875,
            },
            Range = 30,
        },
        { -- Step 64
            Waypoint = 65074,
            Coord = {
                y = 7190.877441406,
                x = -2658.5036621094,
            },
            Range = 5,
            ["ExtraLineText2"] = "CAST_SOAR",
            SpellButton = {
                ["65074-1"] = 369536,
            },
        },
        { -- Step 65
            Done = {
                65074,
            },
            Coord = {
                y = 7162.486328125,
                x = -2648.7387695312,
            },
        },
        { -- Step 66
            Done = {
                65073,
            },
            Coord = {
                y = 7161.220703,
                x = -2644.398926,
            },
        },
        { -- Step 67
            PickUp = {
                65307,
            },
            Coord = {
                y = 7161.220703,
                x = -2644.398926,
            },
        },
        { -- Step 68
            Qpart = {
                [65307] = {
                    3,
                },
            },
            Coord = {
                y = 7260.4975585938,
                x = -2775.4125976562,
            },
            Range = 1,
            Fillers = { [65307] = { 2, }, },
            SpellButton = {
                ["65307-3"] = 361469,
            },
        },
        { -- Step 69
            Qpart = {
                [65307] = {
                    2,
                },
            },
            Coord = {
                y = 7260.4975585938,
                x = -2775.4125976562,
            },
            Range = 5,
            SpellButton = {
                ["65307-2"] = 361469,
            },
        },
        { -- Step 70
            Waypoint = 65307,
            Coord = {
                y = 7185.271484375,
                x = -2799.0112304688,
            },
            Range = 15,
            Fillers = { [65307] = { 1, }, },
            SpellButton = {
                ["65307-1"] = 361469,
            },
        },
        { -- Step 71
            Waypoint = 65307,
            Coord = {
                y = 7170.8046875,
                x = -2802.2661132812,
            },
            Range = 15,
            Fillers = { [65307] = { 1, }, },
            SpellButton = {
                ["65307-1"] = 361469,
            },
        },
        { -- Step 72
            Waypoint = 65307,
            Coord = {
                y = 7105.5244140625,
                x = -2751.8137207031,
            },
            Range = 15,
            Fillers = { [65307] = { 1, }, },
            SpellButton = {
                ["65307-1"] = 361469,
            },
        },
        { -- Step 73
            Waypoint = 65307,
            Coord = {
                y = 7104.6201171875,
                x = -2693.7661132812,
            },
            Range = 15,
            Fillers = { [65307] = { 1, }, },
            SpellButton = {
                ["65307-1"] = 361469,
            },
        },
        { -- Step 74
            Waypoint = 65307,
            Coord = {
                y = 7174.2407226562,
                x = -2690.240234375,
            },
            Fillers = { [65307] = { 1, }, },
        },
        { -- Step 75
            Qpart = {
                [65307] = {
                    1,
                },
            },
            Coord = {
                y = 7191.419921875,
                x = -2659.0463867188,
            },
        },
        { -- Step 76
            Done = {
                65307,
            },
            Coord = {
                y = 7160.8588867188,
                x = -2644.1274414062,
            },
        },
        { -- Step 77
            PickUp = {
                66324,
            },
            Coord = {
                y = 7160.8588867188,
                x = -2644.1274414062,
            },
        },
        { -- Step 78
            Qpart = {
                [66324] = {
                    2,
                },
            },
            Coord = {
                y = 7258.6987304688,
                x = -2533.205078125,
            },
            Range = 1,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = {
                ["66324-2"] = 191729,
            },
        },
        { -- Step 79
            QpartPart = {
                [66324] = {
                    1,
                },
            },
            Coord = {
                y = 7349.6083984375,
                x = -2438.0048828125,
            },
            Range = 2,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = {
                ["66324-1"] = 191729,
            },
            TrigText = "1/3",
        },
        { -- Step 80
            QpartPart = {
                [66324] = {
                    1,
                },
            },
            Coord = {
                y = 7326.6005859375,
                x = -2420.7150878906,
            },
            Range = 2,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = {
                ["66324-1"] = 191729,
            },
            TrigText = "2/3",
        },
        { -- Step 81
            QpartPart = {
                [66324] = {
                    1,
                },
            },
            Coord = {
                y = 7297.9931640625,
                x = -2365.3100585938,
            },
            Range = 2,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = {
                ["66324-1"] = 191729,
            },
            TrigText = "3/3",
        },
        { -- Step 82
            Waypoint = 66324,
            Coord = {
                y = 7310.103515625,
                x = -2397.08984375,
            },
            Range = 1,
            Fillers = { [66324] = { 3, }, },
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            ["ExtraLineText2"] = "PICK_UP_CRYSTAL_KEY_ON_THE_GROUND",
        },
        { -- Step 83
            Qpart = {
                [66324] = {
                    3,
                },
            },
            Coord = {
                y = 7337.89453125,
                x = -2389.6000976562,
            },
            Range = 5,
            ExtraLineText = "ONLY_USE_ITEM_STAY_AT_LIKE_5060",
            ["ExtraLineText2"] = "PLACE_CRYSTAL_KEY_IN_THE_CRYSTAL_LOCK",
            Button = {
                ["66324-3"] = 191729,
            },
        },
        { -- Step 84
            Waypoint = 66324,
            Coord = {
                y = 7321.607421875,
                x = -2413.6101074219,
            },
            Range = 2,
            ExtraLineText = "STOP_USING_ITEM_STEP_INTO_A_GASCLOUD_GENERATE_MORE_TOXICITY",
        },
        { -- Step 85
            Done = {
                66324,
            },
            Coord = {
                y = 7161.220703125,
                x = -2644.3989257812,
            },
        },
        { -- Step 86
            PickUp = {
                65075,
            },
            Coord = {
                y = 7161.220703125,
                x = -2644.3989257812,
            },
        },
        { -- Step 87
            Waypoint = 65075,
            Coord = {
                y = 7151.8173828125,
                x = -2653.3500976562,
            },
            Range = 1,
        },
        { -- Step 88
            Done = {
                65075,
            },
            Coord = {
                y = 6400.0947265625,
                x = -3300.0102539062,
            },
        },
        { -- Step 89
            PickUp = {
                65045,
            },
            Coord = {
                y = 6400.0947265625,
                x = -3300.0102539062,
            },
        },
        { -- Step 90
            Done = {
                72263,
            },
            Coord = {
                y = 6397.0205078125,
                x = -3329.0336914062,
            },
        },
        { -- Step 91
            Done = {
                65045,
            },
            Coord = {
                y = 6342.58984375,
                x = -4010.4135742188,
            },
            ["ExtraLineText2"] = "CAST_SOAR_AND_FOLLOW_ARROW",
            SpellButton = {
                ["65045"] = 369536,
            },
        },
        { -- Step 92
            PickUp = {
                65049,
                65050,
            },
            Coord = {
                y = 6342.58984375,
                x = -4010.4135742188,
            },
        },
        { -- Step 93
            PickUp = {
                65046,
            },
            Coord = {
                y = 6337.8876953125,
                x = -4008.5148925781,
            },
        },
        { -- Step 94
            Qpart = {
                [65046] = {
                    1,
                },
            },
            Coord = {
                y = 6417.6352539062,
                x = -4049.4736328125,
            },
            Range = 2,
            Fillers = { [65050] = { 1, }, [65049] = { 1, }, },
        },
        { -- Step 95
            Qpart = {
                [65046] = {
                    3,
                },
            },
            Coord = {
                y = 6520.3486328125,
                x = -4051.1010742188,
            },
            Range = 2,
            Fillers = { [65050] = { 1, }, [65049] = { 1, }, },
        },
        { -- Step 96
            Qpart = {
                [65046] = {
                    2,
                },
            },
            Coord = {
                y = 6304.2529296875,
                x = -4222.53125,
            },
            Range = 2,
            Fillers = { [65050] = { 1, }, [65049] = { 1, }, },
            ["ExtraLineText2"] = "CAST_SOAR_AND_FOLLOW_ARROW",
            SpellButton = {
                ["65046-2"] = 369536,
            },
        },
        { -- Step 97
            Qpart = {
                [65049] = {
                    1,
                },
            },
            Coord = {
                y = 6316.0068359375,
                x = -4093.4162597656,
            },
            Range = 30,
            Fillers = { [65050] = { 1, }, },
        },
        { -- Step 98
            Qpart = {
                [65050] = {
                    1,
                },
            },
            Coord = {
                y = 6479.2993164062,
                x = -4131.9340820312,
            },
            Range = 10,
        },
        { -- Step 99
            Done = {
                65046,
                65049,
                65050,
            },
            Coord = {
                y = 6384.1811523438,
                x = -4254.267578125,
            },
        },
        { -- Step 100
            PickUp = {
                65052,
            },
            Coord = {
                y = 6384.1811523438,
                x = -4254.267578125,
            },
        },
        { -- Step 101
            Qpart = {
                [65052] = {
                    1,
                },
            },
            Coord = {
                y = 6478.9375,
                x = -4305.8046875,
            },
            Range = 1,
            ExtraLineText = "USE_YOU_EXTRA_BUTTON_REPORT_IT",
        },
        { -- Step 102
            Done = {
                65052,
            },
            Coord = {
                y = 6530.4750976562,
                x = -4303.0927734375,
            },
        },
        { -- Step 103
            PickUp = {
                65057,
            },
            Coord = {
                y = 6530.4750976562,
                x = -4303.0927734375,
            },
        },
        { -- Step 104
            UseHS = 65057,
            Button = {
                ["22345678-1"] = 6948,
            },
            Coord = {
                y = 6400.0947265625,
                x = -3299.4672851562,
            },
        },
        { -- Step 105
            Done = {
                65057,
            },
            Coord = {
                y = 6400.0947265625,
                x = -3299.4672851562,
            },
        },
        { -- Step 106
            PickUp = {
                65701,
            },
            Coord = {
                y = 6463.0244140625,
                x = -3316.013671875,
            },
        },
        { -- Step 107
            Qpart = {
                [65701] = {
                    1,
                },
            },
            Coord = {
                y = 6463.0244140625,
                x = -3316.013671875,
            },
            Range = 1,
            ExtraLineText = "CHOOSE_DEVASTATION_DPS_OR_PRESERVATION_HEAL",
        },
        { -- Step 108
            Done = {
                65701,
            },
            Coord = {
                y = 6463.0244140625,
                x = 3316.013671875,
            },
        },
        { -- Step 109
            PickUp = {
                65084,
            },
            Coord = {
                y = 6463.0244140625,
                x = 3316.013671875,
            },
        },
        { -- Step 110
            Done = {
                65084,
            },
            Coord = {
                y = 6996.662109375,
                x = -3638.5297851562,
            },
            ["ExtraLineText2"] = "CAST_SOAR_AND_FOLLOW_ARROW",
            SpellButton = {
                ["65084"] = 369536,
            },
        },
        { -- Step 111
            PickUp = {
                65087,
            },
            Coord = {
                y = 6996.662109375,
                x = -3638.5297851562,
            },
        },
        { -- Step 112
            Qpart = {
                [65087] = {
                    1,
                },
            },
            Coord = {
                y = 6934.0942382812,
                x = -3578.8549804688,
            },
            Range = 5,
            ExtraLineText = "USE_EMERALD_BLOSSOM_AND_LIVING_FLAME_HEAL_NPCS_AND_KILL_ENEMIES",
        },
        { -- Step 113
            Done = {
                65087,
            },
            Coord = {
                y = 6986.3549804688,
                x = -3628.4936523438,
            },
        },
        { -- Step 114
            PickUp = {
                65097,
            },
            Coord = {
                y = 6921.6171875,
                x = -3567.4624023438,
            },
            ExtraLineText = "IMMEDIATELY_START_RUNNING_AND_GET_WRATHION",
        },
        { -- Step 115
            Qpart = {
                [65097] = {
                    1,
                },
            },
            Coord = {
                y = 6863.931640625,
                x = -3375.4174804688,
            },
            Range = 2,
            ExtraLineText = "IMMEDIATELY_START_RUNNING_AND_GET_WRATHION",
            ["ExtraLineText2"] = "SPAMMING_SPACE_IS_FASTER_THAN_WALKING_NORMALLY",
        },
        { -- Step 116
            Qpart = {
                [65097] = {
                    2,
                },
            },
            Coord = {
                y = 6878.9404296875,
                x = -3395.21875,
            },
            Range = 2,
        },
        { -- Step 117
            Qpart = {
                [65097] = {
                    3,
                },
            },
            Coord = {
                y = 6866.462890625,
                x = -3377.31640625,
            },
            SpellButton = {
                ["65097-3"] = 361469,
            },
        },
        { -- Step 118
            Done = {
                65087,
            },
            Coord = {
                y = 6864.8354492188,
                x = -3375.9599609375,
            },
        },
        { -- Step 119
            PickUp = {
                65098,
            },
            Coord = {
                y = 6864.8354492188,
                x = -3375.9599609375,
            },
        },
        { -- Step 120
            Qpart = {
                [65098] = {
                    1,
                },
            },
            Coord = {
                y = 6778.2163085938,
                x = -3346.6650390625,
            },
            Range = 2,
            ExtraLineText = "AVOID_PULLING_MOBS",
        },
        { -- Step 121
            Qpart = {
                [65098] = {
                    2,
                },
            },
            Coord = {
                y = 6814.3828125,
                x = -3272.3427734375,
            },
            Range = 1,
            ExtraLineText = "HEAL_HIM_ABOVE_90_HP",
            SpellButton = {
                ["65098-2"] = 361469,
            },
        },
        { -- Step 122
            Done = {
                65098,
            },
            Coord = {
                y = 6701.181640625,
                x = -3230.5698242188,
            },
        },
        { -- Step 123
            PickUp = {
                65100,
            },
            Coord = {
                y = 6701.181640625,
                x = -3230.5698242188,
            },
        },
        { -- Step 124
            Qpart = {
                [65100] = {
                    1,
                },
            },
            Coord = {
                y = 6539.8784179688,
                x = -3233.5537109375,
            },
        },
        { -- Step 125
            Waypoint = 65100,
            Coord = {
                y = 6427.9428710938,
                x = -3265.8325195312,
            },
            Range = 5,
        },
        { -- Step 126
            Qpart = {
                [65100] = {
                    2,
                },
            },
            Coord = {
                y = 6427.0385742188,
                x = -3281.8361816406,
            },
            Range = 1,
        },
        { -- Step 127
            Qpart = {
                [65100] = {
                    4,
                },
            },
            Coord = {
                y = 6527.0390625,
                x = -3279.1240234375,
            },
            Range = 1,
            Gossip = 1,
        },
        { -- Step 128
            Qpart = {
                [65100] = {
                    3,
                },
            },
            Coord = {
                y = 6495.7548828125,
                x = -3376.5024414062,
            },
            Range = 1,
            Gossip = 1,
        },
        { -- Step 129
            Done = {
                65100,
            },
            Coord = {
                y = 6508.775390625,
                x = -3310.8601074219,
            },
        },
        { -- Step 130
            PickUp = {
                65286,
            },
            Coord = {
                y = -9089.4833984375,
                x = 415.72698974609,
            },
            Zone = 37,
        },
        { -- Step 131
            Done = {
                65286,
            },
            Coord = {
                y = -9093.880859375,
                x = 415.72698974609,
            },
            Zone = 37,
        },
        { -- Step 132
            PickUp = {
                66513,
            },
            Coord = {
                y = -9093.880859375,
                x = 415.72698974609,
            },
            Zone = 37,
        },
        { -- Step 133
            Qpart = {
                [66513] = {
                    2,
                },
            },
            Coord = {
                y = -8895.279296875,
                x = 634.72015380859,
            },
            Range = 2,
            Zone = 84,
        },
        { -- Step 134
            Qpart = {
                [66513] = {
                    1,
                },
            },
            Coord = {
                y = -8833.1923828125,
                x = 652.61645507812,
            },
            Range = 2,
            Zone = 84,
        },
        { -- Step 135
            Qpart = {
                [66513] = {
                    4,
                },
            },
            Coord = {
                y = -9004.857421875,
                x = 870.67279052734,
            },
            Range = 2,
            Zone = 84,
        },
        { -- Step 136
            Qpart = {
                [66513] = {
                    3,
                },
            },
            Coord = {
                y = -8156.03125,
                x = 812.64025878906,
            },
            Range = 2,
            Zone = 84,
        },
        { -- Step 137
            Done = {
                66513,
            },
            Coord = {
                y = -8307.6572265625,
                x = 334.13244628906,
            },
            Zone = 84,
        },
        { -- Step 138
            PickUp = {
                66577,
            },
            Coord = {
                y = -8309.1630859375,
                x = 335.69622802734,
            },
            Zone = 84,
        },
        { -- Step 139
            Done = {
                66577,
            },
            Coord = {
                y = -8309.1630859375,
                x = 335.69622802734,
            },
            Zone = 84,
        },
        { -- Step 140
            PickUp = {
                65101,
            },
            Coord = {
                y = -8309.1630859375,
                x = 335.69622802734,
            },
            Zone = 84,
        },
        { -- Step 141
            Qpart = {
                [65101] = {
                    1,
                },
            },
            Coord = {
                y = -8309.1630859375,
                x = 335.69622802734,
            },
            Range = 1,
            Zone = 84,
        },
        { -- Step 142
            Qpart = {
                [65101] = {
                    2,
                },
            },
            Coord = {
                y = -8273.138671875,
                x = 287.56744384766,
            },
            Range = 1,
            ETA = 15,
            Zone = 84,
        },
        { -- Step 143
            Qpart = {
                [65101] = {
                    3,
                },
            },
            Coord = {
                y = -8273.138671875,
                x = 287.56744384766,
            },
            Range = 1,
            ExtraLineText = "CLICK_EXTRAACTIONBUTTON",
            Zone = 84,
        },
        { -- Step 144
            Done = {
                65101,
            },
            Coord = {
                y = -8273.486328125,
                x = 288.08868408203,
            },
            Zone = 84,
        },
        { -- Step 145
            ZoneDoneSave = 1,
        },
    }
end
