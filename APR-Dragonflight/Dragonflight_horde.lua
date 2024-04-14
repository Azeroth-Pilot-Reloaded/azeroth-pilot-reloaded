if APR.Faction == "Horde" then
    APR.RouteQuestStepList["85-DF01H-Orgrimmar"] = {
        { Done = { 65435 },            Coord = { y = 2046.2, x = -4273.0 }, Zone = 85 },
        { PickUp = { 65437 },          Coord = { y = 2046.2, x = -4273.0 }, Zone = 85 },
        { Qpart = { [65437] = { 1 } }, Coord = { y = 2046.2, x = -4273.0 }, Range = 0.5, Gossip = 1, Zone = 85 },
        { Done = { 65437 },            Coord = { y = 2046.2, x = -4273.0 }, Zone = 85 },
        { PickUp = { 65443 },          Coord = { y = 2048.6, x = -4274.9 }, Zone = 85 },
        { PickUp = { 72256 },          Coord = { y = 2043.0, x = -4272.0 }, Zone = 85 },
        {
            Qpart = { [65443] = { 2 } },
            Coord = { y = 1826.4, x = -4177.5 },
            Range = 0.5,
            ExtraLineText = "ON_TOP_OF_A_ROCK",
            Gossip = 1,
            Zone = 85
        },
        { Qpart = { [65443] = { 1 } }, Coord = { y = 1859.0, x = -4499.6 }, Range = 0.5,                           Gossip = 1,                          Zone = 85 },
        {
            Waypoint = 65443,
            Coord = { y = 1920.5, x = -4726.4 },
            Range = 10,
            ExtraLineText = "HEAD_WYVERNS_TAIL_INN",
            Zone = 85
        },
        {
            Qpart = { [65443] = { 3 } },
            Coord = { y = 1899.5, x = -4749.1 },
            Range = 0.5,
            ExtraLineText = "UPSTAIRS",
            Gossip = 1,
            Zone = 85
        },
        { Qpart = { [72256] = { 1 } }, Coord = { y = 1447.5, x = -4464.4 }, Range = 0.5,                           Gossip = 1,                          Zone = 85 },
        { Done = { 65443, 72256 },     Coord = { y = 1362.0, x = -4913.5 }, ExtraLineText = "HEAD_ZEPPELIN_TOWER", Zone = 1 },
        { PickUp = { 65439 },          Coord = { y = 1363.9, x = -4919.0 }, Zone = 1 },
        { Qpart = { [65439] = { 1 } }, Coord = { y = 1363.9, x = -4919.0 }, Range = 0.5,                           Gossip = 1,                          Zone = 1 },
        { Done = { 65439 },            Coord = { y = 1359.8, x = -4915.3 }, Zone = 1 },
        { PickUp = { 65444 },          Coord = { y = 1362.0, x = -4913.5 }, Zone = 1 },
        { Waypoint = 65444,            Coord = { y = 1343.4, x = -4922.5 }, Range = 10,                            ExtraLineText = "WAIT_FOR_ZEPPELIN", Zone = 1 },
        {
            Qpart = { [65444] = { 1 } },
            Coord = { y = 1343.4, x = -4922.5 },
            Range = 0.5,
            ExtraLineText = "WAIT_FOR_ZEPPELIN",
            Zone = 1
        },
        { Qpart = { [65444] = { 2 } }, Coord = { y = 3895.3, x = -1792.7 }, Zone = 2022, Range = 5 },
        { Done = { 65444 },            Coord = { y = 3903.7, x = -1778.3 }, Zone = 2022 },
        { ZoneDoneSave = 1 }
    }
    APR.RouteQuestStepList["2022-DF03H-WakingShores"] = {
        { Qpart = { [65444] = { 2 } }, Coord = { y = 3895.3, x = -1792.7 }, Range = 5 },
        { Done = { 65444 },            Coord = { y = 3903.7, x = -1778.3 } },
        { PickUp = { 65452 },          Coord = { y = 3903.7, x = -1778.3 } },
        { PickUp = { 65453 },          Coord = { y = 3904.6, x = -1780.9 } },
        { PickUp = { 65451 },          Coord = { y = 3901.4, x = -1777.3 } },
        {
            Qpart = { [65452] = { 1 } },
            Coord = { y = 3970.7, x = -1758.3 },
            Range = 5,
            Fillers = { [65453] = { 1 }, [65451] = { 1 } }
        },
        {
            Qpart = { [65452] = { 2 } },
            Coord = { y = 4075.0, x = -1624.0 },
            Range = 10,
            Fillers = { [65453] = { 1 }, [65451] = { 1 } }
        },
        {
            Qpart = { [65452] = { 3 } },
            Coord = { y = 3783.7, x = -1514.2 },
            Range = 10,
            Fillers = { [65453] = { 1 }, [65451] = { 1 } }
        },
        { Qpart = { [65453] = { 1 } }, Coord = { y = 3736.0, x = -1607.0 }, Range = 180 },
        { Qpart = { [65451] = { 1 } }, Coord = { y = 3736.0, x = -1607.0 }, Range = 180 },
        { Done = { 65452 },            Coord = { y = 3585.5, x = -1458.6 } },
        { PickUp = { 69910 },          Coord = { y = 3585.5, x = -1458.6 } },
        {
            Qpart = { [69910] = { 1 } },
            Coord = { y = 3581.8, x = -1456.2 },
            Range = 5,
            ExtraLineText = "CHOOSE_WHY_ARENT_DRAGONS_HERE_MEET_US",
            Gossip = 1
        },
        { Done = { 69910 },   Coord = { y = 3581.8, x = -1456.2 } },
        { PickUp = { 72293 }, Coord = { y = 3581.8, x = -1456.2 }, HasAchievement = 16326 },
        {
            Qpart = { [72293] = { 1 } },
            Coord = { y = 3552.0, x = -1452.5 },
            Range = 5,
            ExtraLineText = "CHOOSE_ZONE",
            HasAchievement = 16326
        },
        { Done = { 72293 },            Coord = { y = 3552.0, x = -1452.5 }, HasAchievement = 16326 },
        {
            PickUp = { 72266 },
            Coord = { y = 3552.0, x = -1452.5 },
            ExtraLineText = "CHOOSE_ZONE",
            ExtraLineText2 = "CHOOSE_ZONE_DF_WS",
            HasAchievement = 16326
        },
        {
            PickUp = { 72267 },
            Coord = { y = 3552.0, x = -1452.5 },
            ExtraLineText = "CHOOSE_ZONE",
            ExtraLineText2 = "CHOOSE_ZONE_DF_OP",
            HasAchievement = 16326
        },
        {
            PickUp = { 72268 },
            Coord = { y = 3552.0, x = -1452.5 },
            ExtraLineText = "CHOOSE_ZONE",
            ExtraLineText2 = "CHOOSE_ZONE_DF_AS",
            HasAchievement = 16326
        },
        {
            PickUp = { 72269 },
            Coord = { y = 3552.0, x = -1452.5 },
            ExtraLineText = "CHOOSE_ZONE",
            ExtraLineText2 = "CHOOSE_ZONE_DF_THAL",
            HasAchievement = 16326
        },
        { Done = { 72266 },            Coord = { y = 3581.8, x = -1456.2 }, HasAchievement = 16326 },
        { PickUp = { 69911 },          Coord = { y = 3581.8, x = -1456.2 } },
        { PickUp = { 66110 },          Coord = { y = 3612.7, x = -1438.4 } },
        { Done = { 65453 },            Coord = { y = 3615.7, x = -1432.3 } },
        { Done = { 65451 },            Coord = { y = 3604.0, x = -1405.0 } },
        { PickUp = { 66101 },          Coord = { y = 3591.7, x = -1397.9 } },
        { Qpart = { [66101] = { 1 } }, Coord = { y = 3587.0, x = -1401.7 }, Range = 5,             ExtraLineText = "CLICK_SURVEYORS_DISC" },
        { Qpart = { [66101] = { 2 } }, Coord = { y = 3587.0, x = -1401.7 }, Range = 5,             ExtraLineText = "PRESS_1" },
        { Qpart = { [66101] = { 3 } }, Coord = { y = 3587.0, x = -1401.7 }, Range = 5,             ExtraLineText = "PRESS_2" },
        { Qpart = { [66101] = { 4 } }, Coord = { y = 3587.0, x = -1401.7 }, Range = 5,             ExtraLineText = "PRESS_3" },
        { Done = { 66101 },            Coord = { y = 3591.7, x = -1397.9 } },
        { Done = { 66110 },            Coord = { y = 3534.4, x = -1467.4 } },
        { PickUp = { 66111 },          Coord = { y = 3534.4, x = -1467.4 } },
        {
            PickUp = { 69965 },
            Coord = { y = 3539.8, x = -1442.4 },
            ExtraLineText = "IF_HAEPHESTA_IS_NOT_THERE_LOG_OUT_AND_BACK_IN_BLIZZARD_BUG"
        },
        { PickUp = { 66112 },          Coord = { y = 3529.3, x = -1437.9 } },
        { Qpart = { [69911] = { 1 } }, Coord = { y = 3478.8, x = -1435.5 }, Range = 5, Gossip = 3, RaidIcon = 193393 },
        {
            Qpart = { [69911] = { 2 } },
            Coord = { y = 3479.0, x = -1432.9 },
            Range = 1,
            ExtraLineText = "CLICK_BOOK_CHOICES_DONT_MATTER",
            Gossip = 1
        },
        { GetFP = 2805,                Coord = { y = 3508.2, x = -1411.7 }, Range = 1 },
        { Qpart = { [69911] = { 3 } }, Coord = { y = 3556.1, x = -1378.8 }, Range = 5, ExtraLineText = "CLICK_STONE_TABLET" },
        { Qpart = { [69911] = { 4 } }, Coord = { y = 3680.3, x = -1602.4 }, Range = 5, ExtraLineText = "CLICK_BRAZIER" },
        { Done = { 69911 },            Coord = { y = 3582.1, x = -1456.0 } },
        { PickUp = { 69912 },          Coord = { y = 3582.1, x = -1456.0 } },
        {
            Qpart = { [69912] = { 1 } },
            Coord = { y = 3582.1, x = -1456.0 },
            Range = 1,
            ExtraLineText = "SPEAK_SENDRAX_SEND_SIGNAL_FLARES",
            Gossip = 2
        },
        { Waypoint = 66112,            Coord = { y = 3418.8, x = -1379.0 }, Range = 10, ExtraLineText = "HEAD_CAVE" },
        {
            Qpart = { [66112] = { 2 } },
            Coord = { y = 3281.2, x = -1327.9 },
            Range = 10,
            Fillers = { [69965] = { 1 }, [66111] = { 1 } },
            ExtraLineText = "ITEM_DROPS_FROM_BARON_CRUSTCORE_AT_BACK_OF_THE_CAVE",
            RaidIcon = 192266
        },
        {
            Qpart = { [66112] = { 1 } },
            Coord = { y = 3618.9, x = -1165.1 },
            Range = 10,
            Fillers = { [69965] = { 1 }, [66111] = { 1 } },
            ExtraLineText = "ITEM_DROPS_FROM_BARON_ASHFLOW_AT_TOP_OF_THE_LAVA_FLOW",
            RaidIcon = 192274
        },
        { Qpart = { [69965] = { 1 } }, Coord = { y = 3448.3, x = -1313.7 }, Range = 200 },
        { Qpart = { [66111] = { 1 } }, Coord = { y = 3448.3, x = -1313.7 }, Range = 200 },
        { Done = { 66112 },            Coord = { y = 3529.3, x = -1437.9 } },
        { Done = { 69965 },            Coord = { y = 3539.8, x = -1442.4 } },
        { Done = { 66111 },            Coord = { y = 3534.4, x = -1467.4 } },
        { Done = { 69912 },            Coord = { y = 3537.5, x = -1424.7 } },
        { ZoneDoneSave = 1 }
    }
    APR.RouteQuestStepList["2025-DF06H-Thaldraszus"] = {
        {
            Qpart = { [66244] = { 1 } },
            Coord = { y = 338.8, x = -1099.5 },
            Range = 2,
            ExtraLineText = "GET_INSIDE_AND_USE_PORTAL_TOP"
        },
        { Done = { 66244 },            Coord = { y = 306.5, x = -1042.4 }, ExtraLineText = "GET_INSIDE_AND_USE_PORTAL_TOP" },
        { PickUp = { 66159 },          Coord = { y = 306.5, x = -1042.4 } },
        { Qpart = { [66159] = { 1 } }, Coord = { y = 306.5, x = -1042.4 }, Range = 2,                                      Gossip = 1 },
        { Done = { 66159 },            Coord = { y = 306.5, x = -1042.4 } },
        { PickUp = { 66163 },          Coord = { y = 313.3, x = -1061.9 } },
        { PickUp = { 66166 },          Coord = { y = 313.3, x = -1061.9 } },
        {
            Qpart = { [66163] = { 1 } },
            Coord = { y = 313.3, x = -1061.9 },
            ExtraLineText = "USE_REVEALING_DRAGONS_EYE",
            Button = { ["66163-1"] = 198859 }
        },
        {
            Qpart = { [66166] = { 3 } },
            Coord = { y = 186.6, x = -880.5 },
            Range = 2,
            Fillers = { [66163] = { 2 } },
            ExtraLineText = "INSIDE_INN"
        },
        {
            Qpart = { [66166] = { 2 } },
            Coord = { y = 118.3, x = -1058.4 },
            Range = 2,
            Fillers = { [66163] = { 2 } },
            ExtraLineText = "INSIDE_BANK"
        },
        {
            Qpart = { [66166] = { 1 } },
            Coord = { y = 54.5, x = -701.7 },
            Range = 2,
            Fillers = { [66163] = { 2 } },
            ExtraLineText = "ON_TOP_OF_BOX"
        },
        {
            Qpart = { [66163] = { 2 } },
            Coord = { y = 99.4, x = -918.4 },
            Range = 300,
            ExtraLineText = "INFILTRATORS_ARE_ACROSS_CITY_THEY_GLOW_RED_WHEN_YOU_ARE_CLOSE",
            Gossip = 1
        },
        { Done = { 66163 },            Coord = { y = 191.1, x = -994.1 } },
        { Done = { 66166 },            Coord = { y = 191.1, x = -994.1 } },
        { PickUp = { 66167 },          Coord = { y = 191.1, x = -994.1 } },
        { Qpart = { [66167] = { 1 } }, Coord = { y = -1366.2, x = -511.3 }, Range = 2, ExtraLineText = "FLY_GUARDIAN_VELOMIR" },
        { Qpart = { [66167] = { 2 } }, Coord = { y = -1366.2, x = -511.3 }, Range = 2, ExtraLineText = "AID_GUARDIAN" },
        { Done = { 66167 },            Coord = { y = -1366.2, x = -511.3 } },
        { PickUp = { 66169 },          Coord = { y = -1366.2, x = -511.3 } },
        { PickUp = { 66246 },          Coord = { y = -1366.2, x = -511.3 } },
        {
            Qpart = { [66246] = { 1 } },
            Coord = { y = -1493.0, x = -550.2 },
            Range = 125,
            Fillers = { [66169] = { 1 } },
            ExtraLineText = "VELOMIRS_UNITS_ARE_MARKED_ON_MINIMAP",
            Gossip = 1
        },
        { Qpart = { [66169] = { 1 } }, Coord = { y = -1493.0, x = -550.2 }, Range = 125 },
        { Done = { 66169 },            Coord = { y = -1401.9, x = -691.2 } },
        { Done = { 66246 },            Coord = { y = -1401.9, x = -691.2 }, Gossip = 1 },
        { PickUp = { 66245 },          Coord = { y = -1401.9, x = -691.2 }, Gossip = 1 },
        { PickUp = { 66247 },          Coord = { y = -1414.0, x = -713.7 }, Gossip = 1 },
        { PickUp = { 66248 },          Coord = { y = -1424.0, x = -784.6 } },
        {
            Qpart = { [66247] = { 1 } },
            Coord = { y = -1428.9, x = -819.5 },
            Range = 200,
            Fillers = { [66248] = { 1 }, [66245] = { 1 } }
        },
        { Qpart = { [66248] = { 1 } }, Coord = { y = -1428.9, x = -819.5 },  Range = 200, Fillers = { [66245] = { 1 } } },
        { Qpart = { [66245] = { 1 } }, Coord = { y = -1428.9, x = -819.5 },  Range = 200 },
        { Done = { 66247 },            Coord = { y = -1401.9, x = -691.2 } },
        { Done = { 66248 },            Coord = { y = -1401.9, x = -691.2 } },
        { Done = { 66245 },            Coord = { y = -1401.9, x = -691.2 } },
        { PickUp = { 66249 },          Coord = { y = -1401.9, x = -691.2 } },
        { Qpart = { [66249] = { 1 } }, Coord = { y = -1459.9, x = -1020.2 }, Range = 2,   ExtraLineText = "SHOOT_DRAGONS" },
        { Qpart = { [66249] = { 2 } }, Coord = { y = -1459.9, x = -1020.2 }, Range = 2,   ExtraLineText = "SHOOT_DRAGONS" },
        { Done = { 66249 },            Coord = { y = -1563.0, x = -987.0 } },
        { PickUp = { 66250 },          Coord = { y = -1563.0, x = -987.0 } },
        { Qpart = { [66250] = { 1 } }, Coord = { y = -1563.0, x = -987.0 },  Range = 2,   Gossip = 1 },
        { Done = { 66250 },            Coord = { y = -1539.8, x = -946.7 } },
        { PickUp = { 66251 },          Coord = { y = -1539.8, x = -946.7 } },
        { Qpart = { [66251] = { 1 } }, Coord = { y = -1639.2, x = -941.9 },  Range = 2 },
        { Done = { 66251 },            Coord = { y = -1539.8, x = -946.7 } },
        { PickUp = { 66252 },          Coord = { y = -1539.8, x = -946.7 } },
        { Waypoint = 1,                Coord = { y = 164.0, x = -902.5 },    Range = 2 },
        { SetHS = 66252,               Coord = { y = 200.9, x = -887.5 } },
        {
            Waypoint = 66252,
            Coord = { y = 338.3, x = -1099.7 },
            Range = 5,
            ExtraLineText = "TAKE_TELEPORTER_SEAT_OF_ASPECTS"
        },
        { Done = { 66252 },            Coord = { y = 261.3, x = -1012.9 },   ExtraLineText = "ON_TOP_OF_TOWER" },
        { PickUp = { 66320 },          Coord = { y = 267.6, x = -1085.0 } },
        { Qpart = { [66320] = { 1 } }, Coord = { y = -1120.5, x = -2699.0 }, Range = 2,                        Gossip = 1 },
        { Done = { 66320 },            Coord = { y = -1120.5, x = -2699.0 } },
        { GetFP = 2816,                Coord = { y = -1127.2, x = -2716.1 }, Range = 2 },
        { PickUp = { 66080 },          Coord = { y = -1112.5, x = -2705.4 } },
        {
            Qpart = { [66080] = { 1 } },
            Coord = { y = -899.2, x = -2446.5 },
            Range = 2,
            ExtraLineText = "COMPLETES_WHEN_YOU_GET_CLOSE"
        },
        { Done = { 66080 },            Coord = { y = -899.2, x = -2446.5 },  Gossip = 1 },
        { PickUp = { 70136 },          Coord = { y = -899.2, x = -2446.5 } },
        { Qpart = { [70136] = { 2 } }, Coord = { y = -1016.9, x = -2266.5 }, Range = 5 },
        { Qpart = { [70136] = { 3 } }, Coord = { y = -980.1, x = -2221.0 },  Range = 5,   ExtraLineText = "INSIDE_CAVE" },
        { Qpart = { [70136] = { 1 } }, Coord = { y = -980.1, x = -2221.0 },  Range = 5,   ExtraLineText = "LOOT_STAFF" },
        { Done = { 70136 },            Coord = { y = -899.2, x = -2446.5 } },
        { PickUp = { 66081 },          Coord = { y = -899.2, x = -2446.5 } },
        { PickUp = { 66082 },          Coord = { y = -899.2, x = -2446.5 } },
        { Qpart = { [66081] = { 1 } }, Coord = { y = -1012.2, x = -2391.5 }, Range = 125, Fillers = { [66082] = { 1 } } },
        { Qpart = { [66082] = { 1 } }, Coord = { y = -1012.2, x = -2391.5 }, Range = 125 },
        { Done = { 66081 },            Coord = { y = -1120.5, x = -2699.0 } },
        { Done = { 66082 },            Coord = { y = -1120.5, x = -2699.0 } },
        { PickUp = { 66083 },          Coord = { y = -1111.8, x = -2705.8 } },
        { Qpart = { [66083] = { 1 } }, Coord = { y = -1084.3, x = -2718.0 }, Range = 2,   Gossip = 1 },
        { Qpart = { [66083] = { 2 } }, Coord = { y = -1085.0, x = -2718.8 }, Range = 2 },
        { Qpart = { [66083] = { 3 } }, Coord = { y = -1085.0, x = -2718.8 }, Range = 2 },
        { Qpart = { [66083] = { 4 } }, Coord = { y = -1085.0, x = -2718.8 }, Range = 2,   Gossip = 1 },
        { Done = { 66083 },            Coord = { y = -1111.8, x = -2705.8 } },
        { PickUp = { 66084 },          Coord = { y = -1111.8, x = -2705.8 } },
        { PickUp = { 66085 },          Coord = { y = -1120.0, x = -2698.6 } },
        { Qpart = { [66085] = { 1 } }, Coord = { y = -1072.5, x = -2810.0 }, Range = 2,   Fillers = { [66084] = { 1 } } },
        { Qpart = { [66085] = { 2 } }, Coord = { y = -1147.9, x = -2937.8 }, Range = 2,   Fillers = { [66084] = { 1 } },         Gossip = 1 },
        { Qpart = { [66085] = { 3 } }, Coord = { y = -1147.7, x = -2957.4 }, Range = 2,   Fillers = { [66084] = { 1 } } },
        { Qpart = { [66085] = { 4 } }, Coord = { y = -1005.0, x = -2953.1 }, Range = 2,   Fillers = { [66084] = { 1 } } },
        { Qpart = { [66085] = { 5 } }, Coord = { y = -1005.0, x = -2953.1 }, Range = 2,   Fillers = { [66084] = { 1 } },         Gossip = 1 },
        { Qpart = { [66084] = { 1 } }, Coord = { y = -1090.4, x = -2891.1 }, Range = 80 },
        { Done = { 66084 },            Coord = { y = -1111.8, x = -2705.8 } },
        { Done = { 66085 },            Coord = { y = -1120.0, x = -2698.6 } },
        { PickUp = { 66087 },          Coord = { y = -1117.3, x = -2708.0 } },
        { Qpart = { [66087] = { 1 } }, Coord = { y = -1385.4, x = -2660.1 }, Range = 225, SpellButton = { ["66087-1"] = 376679 } },
        { Done = { 66087 },            Coord = { y = -1117.3, x = -2708.0 } },
        { PickUp = { 65935 },          Coord = { y = -1112.7, x = -2705.6 } },
        {
            Qpart = { [65935] = { 1 } },
            Coord = { y = -1308.0, x = -2913.4 },
            Range = 2,
            ExtraLineText = "COMPLETES_ONCE_YOU_REACH_CHROMIE"
        },
        { Done = { 65935 },   Coord = { y = -1308.0, x = -2913.4 } },
        { PickUp = { 65947 }, Coord = { y = -1308.0, x = -2913.4 } },
        { PickUp = { 65948 }, Coord = { y = -1308.0, x = -2913.4 } },
        { PickUp = { 66646 }, Coord = { y = -1373.0, x = -2911.3 } },
        {
            Qpart = { [65948] = { 1 } },
            Coord = { y = -1401.0, x = -2811.1 },
            Range = 2,
            Fillers = { [65947] = { 1 }, [66646] = { 1 }, [65948] = { 3 } }
        },
        {
            Qpart = { [65948] = { 2 } },
            Coord = { y = -1226.7, x = -3024.6 },
            Range = 2,
            Fillers = { [65947] = { 1 }, [66646] = { 1 }, [65948] = { 3 } }
        },
        { Qpart = { [65947] = { 1 }, [66646] = { 1 }, [65948] = { 3 } }, Coord = { y = -1286.9, x = -2902.9 }, Range = 180 },
        { Done = { 65948 },                                              Coord = { y = -1308.0, x = -2913.4 } },
        { Done = { 65947 },                                              Coord = { y = -1308.0, x = -2913.4 } },
        { Done = { 66646 },                                              Coord = { y = -1373.0, x = -2911.3 } },
        { PickUp = { 65938 },                                            Coord = { y = -1308.0, x = -2913.4 } },
        { Qpart = { [65938] = { 1 } },                                   Coord = { y = -1422.7, x = -3014.4 }, Range = 2,  SpellButton = { ["65938-1"] = 372959 } },
        { Qpart = { [65938] = { 2 } },                                   Coord = { y = -1450.0, x = -3017.6 }, Range = 2,  ExtraLineText = "KILL_ELEMENTAL" },
        { Done = { 65938 },                                              Coord = { y = -1308.0, x = -2913.4 } },
        { PickUp = { 65962 },                                            Coord = { y = -1308.0, x = -2913.4 } },
        { Qpart = { [65962] = { 1 } },                                   Coord = { y = -1308.0, x = -2913.4 }, Range = 2,  Gossip = 6 },
        { Done = { 65962 },                                              Coord = { y = -1358.4, x = -2961.0 } },
        { PickUp = { 70040 },                                            Coord = { y = -1358.4, x = -2961.0 } },
        { Qpart = { [70040] = { 2 } },                                   Coord = { y = -1312.9, x = -2975.5 }, Range = 2,  Gossip = 1 },
        { Qpart = { [70040] = { 1 } },                                   Coord = { y = -1363.8, x = -2907.1 }, Range = 2,  Gossip = 1 },
        { Qpart = { [70040] = { 3 } },                                   Coord = { y = -1339.5, x = -2885.6 }, Range = 2,  Gossip = 1 },
        { Qpart = { [70040] = { 4 } },                                   Coord = { y = -1358.4, x = -2961.0 }, Range = 2,  Gossip = 1 },
        { Done = { 70040 },                                              Coord = { y = -1358.4, x = -2961.0 } },
        { PickUp = { 66028 },                                            Coord = { y = -1358.4, x = -2961.0 } },
        { PickUp = { 66029 },                                            Coord = { y = -1358.4, x = -2961.0 } },
        { Qpart = { [66028] = { 1 } },                                   Coord = { y = -1344.9, x = -2938.6 }, Range = 2,  ExtraLineText = "USE_PORTAL" },
        { Done = { 66028 },                                              Coord = { y = -1341.3, x = -2937.1 }, Zone = 2028 },
        { PickUp = { 66030 },                                            Coord = { y = -1341.3, x = -2937.1 }, Zone = 2028 },
        { PickUp = { 66031 },                                            Coord = { y = -1332.3, x = -2945.3 }, Zone = 2028 },
        {
            Qpart = { [66029] = { 1 } },
            Coord = { y = -1202.3, x = -2626.3 },
            Range = 2,
            Button = { ["66029-1"] = 192749 },
            Zone = 2028
        },
        {
            Qpart = { [66031] = { 1 } },
            Coord = { y = -1093.0, x = -2617.6 },
            Range = 2,
            Fillers = { [66030] = { 1 } },
            SpellButton = { ["66031-1"] = 372520 },
            Zone = 2028
        },
        { Qpart = { [66030] = { 1 } }, Coord = { y = -1093.0, x = -2617.6 },          Range = 2,                     Zone = 2028 },
        { Done = { 66030 },            Coord = { y = -1341.3, x = -2937.1 },          Zone = 2028 },
        { Done = { 66031 },            Coord = { y = -1332.3, x = -2945.3 },          Zone = 2028 },
        { PickUp = { 66032 },          Coord = { y = -1341.3, x = -2937.1 },          Zone = 2028 },
        { Done = { 66032 },            Coord = { y = -1359.2, x = -2961.9 },          ExtraLineText = "LEAVE_PORTAL" },
        { Done = { 66029 },            Coord = { y = -1359.2, x = -2961.9 } },
        { PickUp = { 72519 },          Coord = { y = -1359.2, x = -2961.9 } },
        { PickUp = { 66033 },          Coord = { y = -1359.2, x = -2961.9 } },
        { Qpart = { [66033] = { 1 } }, Coord = { y = -1334.2, x = -2953.8 },          Range = 2 },
        { Done = { 66033 },            Coord = { y = 3101.4, x = 272.0, Zone = 2092 } },
        { PickUp = { 66035 },          Coord = { y = 3101.4, x = 272.0 },             Zone = 2092 },
        { PickUp = { 66704 },          Coord = { y = 3108.0, x = 263.5 },             Zone = 2092 },
        { Qpart = { [72519] = { 1 } }, Coord = { y = 3260.6, x = 170.6 },             Range = 2,                     Zone = 2092 },
        {
            Qpart = { [66035] = { 1 } },
            Coord = { y = 3130.0, x = 224.1 },
            Range = 250,
            ExtraLineText = "MOTES_CAN_BE_SEEN_ON_MINIMAP",
            Fillers = { [66704] = { 1, 2 } },
            Zone = 2092
        },
        { Qpart = { [66704] = { 1, 2 } }, Coord = { y = 3130.0, x = 224.1 }, Range = 250, Zone = 2092 },
        { Done = { 66704 },               Coord = { y = 3107.9, x = 263.2 }, Zone = 2092 },
        { Done = { 66035 },               Coord = { y = 3101.9, x = 271.5 }, Zone = 2092 },
        { PickUp = { 70371 },             Coord = { y = 3107.9, x = 263.2 }, Zone = 2092 },
        {
            Qpart = { [70371] = { 1 } },
            Coord = { y = 3118.1, x = 273.5 },
            Range = 2,
            ExtraLineText = "ENTER_PLANE",
            Zone = 2092
        },
        { Qpart = { [70371] = { 2 } }, Coord = { y = 3345.0, x = 260.0 },    Range = 250, Zone = 2092 },
        { Done = { 70371 },            Coord = { y = 3107.9, x = 263.2 },    Zone = 2092 },
        { PickUp = { 66037 },          Coord = { y = 3101.9, x = 271.5 },    Zone = 2092 },
        { Qpart = { [66037] = { 1 } }, Coord = { y = 3102.9, x = 277.3 },    Range = 2,   ExtraLineText = "ENTER_PORTAL" },
        { Done = { 72519 },            Coord = { y = -1359.0, x = -2961.6 } },
        { Done = { 66037 },            Coord = { y = -1359.0, x = -2961.6 } },
        { PickUp = { 66660 },          Coord = { y = -1359.0, x = -2961.6 } },
        { Qpart = { [66660] = { 1 } }, Coord = { y = -1341.5, x = -2948.3 }, Range = 2,   ExtraLineText = "ENTER_PORTAL" },
        { Done = { 66660 },            Coord = { y = 15534.9, x = 15512.9 }, Zone = 2090 },
        { PickUp = { 66038 },          Coord = { y = 15534.9, x = 15512.9 }, Zone = 2090 },
        { Waypoint = 66038,            Coord = { y = 15966.0, x = 15877.4 }, Range = 10,  Zone = 2090 },
        { Waypoint = 66038,            Coord = { y = -7949.9, x = 1374.5 },  Range = 10,  Zone = 2091 },
        { Waypoint = 66038,            Coord = { y = 960.3, x = 2092.3 },    Range = 10,  Zone = 2088 },
        { Done = { 66038 },            Coord = { y = -1309.7, x = 7427.0 },  Zone = 2089 },
        { PickUp = { 66039 },          Coord = { y = -1309.7, x = 7427.0 },  Zone = 2089 },
        {
            Qpart = { [66039] = { 1 } },
            Coord = { y = -949.1, x = 7409.8 },
            Range = 2,
            Button = { ["66039-1"] = 192749 },
            Zone = 2089
        },
        { Done = { 66039 },            Coord = { y = -946.7, x = 7407.1 },   Zone = 2089 },
        { PickUp = { 66040 },          Coord = { y = -946.7, x = 7407.1 },   Zone = 2089 },
        { Qpart = { [66040] = { 1 } }, Coord = { y = -946.7, x = 7407.1 },   Range = 2,  Gossip = 1, Zone = 2089 },
        { Qpart = { [66040] = { 2 } }, Coord = { y = -1356.7, x = -2964.0 }, Range = 2,  Gossip = 1, GossipOptionID = 55119 },
        { Done = { 66040 },            Coord = { y = -1359.0, x = -2962.0 } },
        { PickUp = { 66221 },          Coord = { y = -1359.0, x = -2962.0 } },
        { UseHS = 66221,               Button = { ["22345678-1"] = 6948 } },
        {
            Qpart = { [66221] = { 1 } },
            Coord = { y = 308.2, x = -1041.0 },
            Range = 2,
            ExtraLineText = "ON_TOP_OF_TOWER",
            Gossip = 1
        },
        { Done = { 66221 }, Coord = { y = 308.2, x = -1041.0 } },
        { ZoneDoneSave = 1 }
    }
    APR.RouteQuestStepList["2118-DracthyrStart-H"] = {
        { PickUp = { 64864 }, Coord = { y = 5787.2, x = -3073.3 } },
        {
            Qpart = { [64864] = { 1 } },
            Coord = { y = 5787.2, x = -3073.3 },
            Range = 1,
            ExtraLineText = "INTERACT_WITH_KODETHI",
            RaidIcon = 187223
        },
        {
            Qpart = { [64864] = { 3 } },
            Coord = { y = 5779.8349609375, x = -3038.6650390625 },
            Range = 1,
            ExtraLineText = "JUMP_DOWN_AND_INTERACT_WITH_TETHALASH",
            RaidIcon = 181680
        },
        {
            Qpart = { [64864] = { 2 } },
            Coord = { y = 5820.435059, x = -3077.706055 },
            Range = 1,
            ExtraLineText = "CLICK_ON_BONES_ON_THE_BED"
        },
        { Waypoint = 64864,   Coord = { y = 5806.732421875, x = -3065.5263671875 },  Range = 5 },
        { Waypoint = 64864,   Coord = { y = 5804.7026367188, x = -2982.3325195312 }, Range = 5 },
        { Waypoint = 64864,   Coord = { y = 5812.169921875, x = -2928.8276367188 },  Range = 5 },
        {
            Qpart = { [64864] = { 4 } },
            Coord = { y = 5800.20752, x = -2905.881348 },
            Range = 1,
            ExtraLineText = "INTERACT_WITH_AZURATHEL",
            RaidIcon = 183380
        },
        { Done = { 64864 },   Coord = { y = 5808.617676, x = -2914.254883 } },
        { PickUp = { 64865 }, Coord = { y = 5808.617676, x = -2914.254883 } },
        { PickUp = { 64863 }, Coord = { y = 5815.142578125, x = -2915.9951171875 } },
        {
            Waypoint = 66010,
            Coord = { y = 5862.2, x = -2945.5 },
            Range = 1,
            ExtraLineText = "BONUS_BUFF_INTERACT_WITH_CRYSTAL_KEY_AND_PLACE_IT_INTO_THE_CRYSTAL_FOCUS_NEXT_IT"
        },
        {
            Done = { 66010 },
            Coord = { y = 5859.7299804688, x = -2972.6538085938 },
            ExtraLineText = "BONUS_BUFF_PICK_UP_MYSTERIOUS_WAND_ON_THE_TABLE"
        },
        {
            Qpart = { [64865] = { 1 } },
            Coord = { y = 5919.8325195312, x = -3046.0600585938 },
            Range = 1,
            Fillers = { [64863] = { 1 } },
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS"
        },
        {
            Qpart = { [64865] = { 3 } },
            Coord = { y = 5957.025390625, x = -2928.71875 },
            Range = 1,
            Fillers = { [64863] = { 1 } },
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS"
        },
        {
            Qpart = { [64865] = { 2 } },
            Coord = { y = 6027.7124023438, x = -2977.982421875 },
            Range = 1,
            Fillers = { [64863] = { 1 } },
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS"
        },
        {
            Qpart = { [64863] = { 1 } },
            Coord = { y = 5955.4301757812, x = -2952.6437988281 },
            Range = 20,
            ExtraLineText = "RUN_AWAY_WHEN_THEY_HIT_40_THEYRE_SPLIT_INTO_TWO_SMALL_ADDS"
        },
        { Waypoint = 64865,            Coord = { y = 6001.3950195312, x = -2988.53125 },      Range = 5 },
        { Done = { 64863, 64865 },     Coord = { y = 5971.2348632812, x = -3033.5537109375 }, Range = 5 },
        { PickUp = { 64866 },          Coord = { y = 5975.4399414062, x = -3054.5424804688 }, Range = 1 },
        { Qpart = { [64866] = { 1 } }, Coord = { y = 6102.3, x = -3221.8 },                   Range = 15, ExtraLineText = "GLIDE_DOWN" },
        {
            QpartPart = { [64866] = { 2 } },
            Coord = { y = 6116.8876953125, x = -3137.6274414062 },
            Range = 5,
            SpellButton = { ["64866-2"] = 361469 },
            TrigText = "1/5"
        },
        {
            QpartPart = { [64866] = { 2 } },
            Coord = { y = 6033.3671875, x = -3200.1586914062 },
            Range = 5,
            SpellButton = { ["64866-2"] = 361469 },
            TrigText = "2/5"
        },
        {
            QpartPart = { [64866] = { 2 } },
            Coord = { y = 6035.3974609375, x = -3238.4387207031 },
            Range = 5,
            SpellButton = { ["64866-2"] = 361469 },
            TrigText = "3/5"
        },
        {
            QpartPart = { [64866] = { 2 } },
            Coord = { y = 6087.59765625, x = -3253.2290039062 },
            Range = 5,
            SpellButton = { ["64866-2"] = 361469 },
            TrigText = "4/5"
        },
        {
            QpartPart = { [64866] = { 2 } },
            Coord = { y = 6101.2275390625, x = -3190.2624511719 },
            Range = 5,
            SpellButton = { ["64866-2"] = 361469 },
            TrigText = "5/5"
        },
        { Done = { 64866 },   Coord = { y = 6137.1875, x = -3230.2827148438 } },
        { PickUp = { 64871 }, Coord = { y = 6136.0278320312, x = -3234.1975097656 } },
        {
            Qpart = { [64871] = { 1 } },
            Coord = { y = 6322.498046875, x = -3278.3500976562 },
            Range = 1,
            ExtraLineText = "MAKE_SURE_COMPLETE_THIS_STEP_BEFORE_KILLING_DRAGON"
        },
        { Qpart = { [64871] = { 2 } }, Coord = { y = 6322.498046875, x = -3278.3500976562 }, Range = 1 },
        {
            Done = { 64871 },
            Coord = { y = 6393.9462890625, x = -3304.0788574219 },
            ExtraLineText = "CANCEL_CHOCKING_BUFF_INCREASE_MOVEMENT_SPEED"
        },
        { PickUp = { 64872 },          Coord = { y = 6393.9462890625, x = -3304.0788574219 } },
        { PickUp = { 65615 },          Coord = { y = 6396.296875, x = -3296.2124023438 } },
        {
            Qpart = { [64872] = { 3 } },
            Coord = { y = 6397.9243164062, x = -3287.5322265625 },
            Range = 1,
            ExtraLineText = "RESET_COOLDOWN_BY_CLICKING_ON_THE_FIRE_BREATH_INFUSERS",
            ExtraLineText2 = "HOLD_IT_UNTIL_YOU_REACH_LAST_EMPOWEREMENT_SECTION",
            SpellButton = { ["64872-3"] = 363898 }
        },
        {
            Qpart = { [64872] = { 2 } },
            Coord = { y = 6397.9243164062, x = -3287.5322265625 },
            Range = 1,
            ExtraLineText = "RESET_COOLDOWN_BY_CLICKING_ON_THE_FIRE_BREATH_INFUSERS",
            ExtraLineText2 = "HOLD_IT_UNTIL_YOU_REACH_SECOND_EMPOWEREMENT_SECTION",
            SpellButton = { ["64872-2"] = 363898 }
        },
        { Qpart = { [65615] = { 1 } }, Coord = { y = 6534.99609375, x = -3332.0173339844 },  Range = 1 },
        {
            Qpart = { [64872] = { 1 } },
            Coord = { y = 6464.109375, x = -3304.62109375 },
            Range = 1,
            ExtraLineText = "RESET_COOLDOWN_BY_CLICKING_ON_THE_FIRE_BREATH_INFUSERS",
            ExtraLineText2 = "DONT_HOLD_DOWN_BUTTON",
            SpellButton = { ["64872-1"] = 363898 }
        },
        { Done = { 64872 },            Coord = { y = 6394.126953125, x = -3304.3500976562 }, Range = 1 },
        { Done = { 65615 },            Coord = { y = 6396.658203125, x = -3295.94140625 },   Range = 1 },
        { SetHS = 64873,               Coord = { y = 6406.78515625, x = -3277.767578125 } },
        { PickUp = { 64873 },          Coord = { y = 6402.083984375, x = -3308.1474609375 } },
        {
            Qpart = { [64873] = { 1 } },
            Coord = { y = 6463.748046875, x = -3313.3012695312 },
            Range = 2,
            ExtraLineText = "USE_BUTTON_TELEPORT_RIGHT_INFRONT_OF_THE_NPC",
            Button = { ["64873-1"] = 195044 }
        },
        {
            Qpart = { [64873] = { 2 } },
            Coord = { y = 6463.748046875, x = -3313.3012695312 },
            Range = 2,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["64873-2"] = 369536 }
        },
        { Qpart = { [64873] = { 3 } }, Coord = { y = 6687.2573242188, x = -3470.6259765625 }, Range = 1 },
        {
            Done = { 65909 },
            Coord = { y = 6884.9072265625, x = -3242.5048828125 },
            ExtraLineText = "PICK_UP_BAG_OF_ENCHANTED_WIND_FOR_A_MOVEMENT_SPEED_BUFF",
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["65909"] = 369536 }
        },
        {
            Qpart = { [64873] = { 4 } },
            Coord = { y = 6634.4541015625, x = -3223.517578125 },
            Range = 1,
            ExtraLineText = "USE_BUTTON_TELEPORT_RIGHT_INFRONT_OF_THE_NPC",
            Button = { ["64873-4"] = 195044 }
        },
        {
            Qpart = { [64873] = { 5 } },
            Coord = { y = 6609.6796875, x = -3038.25390625 },
            Range = 1,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["64873-5"] = 369536 }
        },
        {
            Qpart = { [64873] = { 6 } },
            Coord = { y = 6463.9287109375, x = -3312.7587890625 },
            Range = 1,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["64873-6"] = 369536 }
        },
        {
            Qpart = { [64873] = { 7 } },
            Coord = { y = 6862.6655273438, x = -3531.6574707031 },
            Range = 1,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["64873-7"] = 369536 }
        },
        { Done = { 64873 },            Coord = { y = 6464.109375, x = -3312.758 } },
        {
            PickUp = { 65036 },
            Coord = { y = 6464.109375, x = -3312.7587890625 },
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["65036"] = 369536 }
        },
        {
            Qpart = { [65036] = { 1 } },
            Coord = { y = 6464.109, x = -3312.7587890625 },
            Range = 1,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["65036-1"] = 369536 }
        },
        {
            Done = { 65036 },
            Coord = { y = 6400.275390625, x = -3299.7387695312 },
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["65036"] = 369536 }
        },
        { PickUp = { 65060 },          Coord = { y = 6400.275390625, x = -3299.7387695312 } },
        {
            Qpart = { [65060] = { 1 } },
            Coord = { y = 6917.8193359375, x = -3088.9775390625 },
            Range = 1,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["65060-1"] = 369536 },
            Gossip = 1
        },
        {
            Done = { 65060 },
            Coord = { y = 7220.171875, x = -2610.2211914062 },
            Range = 1,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["65060"] = 369536 }
        },
        { PickUp = { 65063 },          Coord = { y = 7220.171875, x = -2610.2211914062 } },
        { Qpart = { [65063] = { 1 } }, Coord = { y = 7236.998046875, x = -2597.1850585938 }, Range = 1, ExtraActionB = 1 },
        { Done = { 65063 },            Coord = { y = 7161.220703125, x = -2644.669921875 } },
        { PickUp = { 65073 },          Coord = { y = 7161.220703125, x = -2644.669921875 } },
        { PickUp = { 65074 },          Coord = { y = 7162.6669921875, x = -2648.4675292969 } },
        {
            Qpart = { [65073] = { 1 } },
            Coord = { y = 7062.84765625, x = -3055.0712890625 },
            Range = 30,
            Fillers = { [65074] = { 1 } },
            ExtraLineText = "JUMP_AND_FLY"
        },
        { Qpart = { [65074] = { 1 } }, Coord = { y = 7057.96484375, x = -2949.826171875 },  Range = 30 },
        {
            Waypoint = 65074,
            Coord = { y = 7190.877441406, x = -2658.5036621094 },
            Range = 5,
            ExtraLineText2 = "CAST_SOAR",
            SpellButton = { ["65074-1"] = 369536 }
        },
        { Done = { 65074 },            Coord = { y = 7162.486328125, x = -2648.7387695312 } },
        { Done = { 65073 },            Coord = { y = 7161.220703, x = -2644.398926 } },
        { PickUp = { 65307 },          Coord = { y = 7161.220703, x = -2644.398926 } },
        {
            Qpart = { [65307] = { 3 } },
            Coord = { y = 7260.4975585938, x = -2775.4125976562 },
            Range = 1,
            Fillers = { [65307] = { 2 } },
            SpellButton = { ["65307-3"] = 361469 }
        },
        {
            Qpart = { [65307] = { 2 } },
            Coord = { y = 7260.4975585938, x = -2775.4125976562 },
            Range = 5,
            SpellButton = { ["65307-2"] = 361469 }
        },
        {
            Waypoint = 65307,
            Coord = { y = 7185.271484375, x = -2799.0112304688 },
            Range = 15,
            Fillers = { [65307] = { 1 } },
            SpellButton = { ["65307-1"] = 361469 }
        },
        {
            Waypoint = 65307,
            Coord = { y = 7170.8046875, x = -2802.2661132812 },
            Range = 15,
            Fillers = { [65307] = { 1 } },
            SpellButton = { ["65307-1"] = 361469 }
        },
        {
            Waypoint = 65307,
            Coord = { y = 7105.5244140625, x = -2751.8137207031 },
            Range = 15,
            Fillers = { [65307] = { 1 } },
            SpellButton = { ["65307-1"] = 361469 }
        },
        {
            Waypoint = 65307,
            Coord = { y = 7104.6201171875, x = -2693.7661132812 },
            Range = 15,
            Fillers = { [65307] = { 1 } },
            SpellButton = { ["65307-1"] = 361469 }
        },
        { Waypoint = 65307,            Coord = { y = 7174.2407226562, x = -2690.240234375 }, Fillers = { [65307] = { 1 } } },
        { Qpart = { [65307] = { 1 } }, Coord = { y = 7191.419921875, x = -2659.0463867188 } },
        { Done = { 65307 },            Coord = { y = 7160.8588867188, x = -2644.1274414062 } },
        { PickUp = { 66324 },          Coord = { y = 7160.8588867188, x = -2644.1274414062 } },
        {
            Qpart = { [66324] = { 2 } },
            Coord = { y = 7258.6987304688, x = -2533.205078125 },
            Range = 1,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = { ["66324-2"] = 191729 }
        },
        {
            QpartPart = { [66324] = { 1 } },
            Coord = { y = 7349.6083984375, x = -2438.0048828125 },
            Range = 2,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = { ["66324-1"] = 191729 },
            TrigText = "1/3"
        },
        {
            QpartPart = { [66324] = { 1 } },
            Coord = { y = 7326.6005859375, x = -2420.7150878906 },
            Range = 2,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = { ["66324-1"] = 191729 },
            TrigText = "2/3"
        },
        {
            QpartPart = { [66324] = { 1 } },
            Coord = { y = 7297.9931640625, x = -2365.3100585938 },
            Range = 2,
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            Button = { ["66324-1"] = 191729 },
            TrigText = "3/3"
        },
        {
            Waypoint = 66324,
            Coord = { y = 7310.103515625, x = -2397.08984375 },
            Range = 1,
            Fillers = { [66324] = { 3 } },
            ExtraLineText = "USE_ITEM_ON_COOLDOWN_REDUCE_TOXICITY",
            ExtraLineText2 = "PICK_UP_CRYSTAL_KEY_ON_THE_GROUND"
        },
        {
            Qpart = { [66324] = { 3 } },
            Coord = { y = 7337.89453125, x = -2389.6000976562 },
            Range = 5,
            ExtraLineText = "ONLY_USE_ITEM_STAY_AT_LIKE_5060",
            ExtraLineText2 = "PLACE_CRYSTAL_KEY_IN_THE_CRYSTAL_LOCK",
            Button = { ["66324-3"] = 191729 }
        },
        {
            Waypoint = 66324,
            Coord = { y = 7321.607421875, x = -2413.6101074219 },
            Range = 2,
            ExtraLineText = "STOP_USING_ITEM_STEP_INTO_A_GASCLOUD_GENERATE_MORE_TOXICITY"
        },
        { Done = { 66324 },   Coord = { y = 7161.220703125, x = -2644.3989257812 } },
        { PickUp = { 65075 }, Coord = { y = 7161.220703125, x = -2644.3989257812 } },
        { Waypoint = 65075,   Coord = { y = 7151.8173828125, x = -2653.3500976562 }, Range = 1 },
        { Done = { 65075 },   Coord = { y = 6400.0947265625, x = -3300.0102539062 } },
        { PickUp = { 65045 }, Coord = { y = 6400.0947265625, x = -3300.0102539062 } },
        { Done = { 72263 },   Coord = { y = 6397.0205078125, x = -3329.0336914062 } },
        {
            Done = { 65045 },
            Coord = { y = 6342.58984375, x = -4010.4135742188 },
            ExtraLineText2 = "CAST_SOAR_AND_FOLLOW_ARROW",
            SpellButton = { ["65045"] = 369536 }
        },
        { PickUp = { 65049, 65050 }, Coord = { y = 6342.58984375, x = -4010.4135742188 } },
        { PickUp = { 65046 },        Coord = { y = 6337.8876953125, x = -4008.5148925781 } },
        {
            Qpart = { [65046] = { 1 } },
            Coord = { y = 6417.6352539062, x = -4049.4736328125 },
            Range = 2,
            Fillers = { [65050] = { 1 }, [65049] = { 1 } }
        },
        {
            Qpart = { [65046] = { 3 } },
            Coord = { y = 6520.3486328125, x = -4051.1010742188 },
            Range = 2,
            Fillers = { [65050] = { 1 }, [65049] = { 1 } }
        },
        {
            Qpart = { [65046] = { 2 } },
            Coord = { y = 6304.2529296875, x = -4222.53125 },
            Range = 2,
            Fillers = { [65050] = { 1 }, [65049] = { 1 } },
            ExtraLineText2 = "CAST_SOAR_AND_FOLLOW_ARROW",
            SpellButton = { ["65046-2"] = 369536 }
        },
        {
            Qpart = { [65049] = { 1 } },
            Coord = { y = 6316.0068359375, x = -4093.4162597656 },
            Range = 30,
            Fillers = { [65050] = { 1 } }
        },
        { Qpart = { [65050] = { 1 } },    Coord = { y = 6479.2993164062, x = -4131.9340820312 }, Range = 10 },
        { Done = { 65046, 65049, 65050 }, Coord = { y = 6384.1811523438, x = -4254.267578125 } },
        { PickUp = { 65052 },             Coord = { y = 6384.1811523438, x = -4254.267578125 } },
        {
            Qpart = { [65052] = { 1 } },
            Coord = { y = 6478.9375, x = -4305.8046875 },
            Range = 1,
            ExtraLineText = "USE_YOU_EXTRA_BUTTON_REPORT_IT"
        },
        { Done = { 65052 },   Coord = { y = 6530.4750976562, x = -4303.0927734375 } },
        { PickUp = { 65057 }, Coord = { y = 6530.4750976562, x = -4303.0927734375 } },
        { UseHS = 65057,      Button = { ["22345678-1"] = 6948 },                   Coord = { y = 6400.0947265625, x = -3299.4672851562 } },
        { Done = { 65057 },   Coord = { y = 6400.0947265625, x = -3299.4672851562 } },
        { PickUp = { 65701 }, Coord = { y = 6463.0244140625, x = -3316.013671875 } },
        {
            Qpart = { [65701] = { 1 } },
            Coord = { y = 6463.0244140625, x = -3316.013671875 },
            Range = 1,
            ExtraLineText = "CHOOSE_DEVASTATION_DPS_OR_PRESERVATION_HEAL"
        },
        { Done = { 65701 },   Coord = { y = 6463.0244140625, x = 3316.013671875 } },
        { PickUp = { 65084 }, Coord = { y = 6463.0244140625, x = 3316.013671875 } },
        {
            Done = { 65084 },
            Coord = { y = 6996.662109375, x = -3638.5297851562 },
            ExtraLineText2 = "CAST_SOAR_AND_FOLLOW_ARROW",
            SpellButton = { ["65084"] = 369536 }
        },
        { PickUp = { 65087 }, Coord = { y = 6996.662109375, x = -3638.5297851562 } },
        {
            Qpart = { [65087] = { 1 } },
            Coord = { y = 6934.0942382812, x = -3578.8549804688 },
            Range = 5,
            ExtraLineText = "USE_EMERALD_BLOSSOM_AND_LIVING_FLAME_HEAL_NPCS_AND_KILL_ENEMIES"
        },
        { Done = { 65087 },   Coord = { y = 6986.3549804688, x = -3628.4936523438 } },
        {
            PickUp = { 65097 },
            Coord = { y = 6921.6171875, x = -3567.4624023438 },
            ExtraLineText = "IMMEDIATELY_START_RUNNING_AND_GET_WRATHION"
        },
        {
            Qpart = { [65097] = { 1 } },
            Coord = { y = 6863.931640625, x = -3375.4174804688 },
            Range = 2,
            ExtraLineText = "IMMEDIATELY_START_RUNNING_AND_GET_WRATHION",
            ExtraLineText2 = "SPAMMING_SPACE_IS_FASTER_THAN_WALKING_NORMALLY"
        },
        { Qpart = { [65097] = { 2 } }, Coord = { y = 6878.9404296875, x = -3395.21875 },     Range = 2 },
        {
            Qpart = { [65097] = { 3 } },
            Coord = { y = 6866.462890625, x = -3377.31640625 },
            SpellButton = { ["65097-3"] = 361469 }
        },
        { Done = { 65087 },            Coord = { y = 6864.8354492188, x = -3375.9599609375 } },
        { PickUp = { 65098 },          Coord = { y = 6864.8354492188, x = -3375.9599609375 } },
        {
            Qpart = { [65098] = { 1 } },
            Coord = { y = 6778.2163085938, x = -3346.6650390625 },
            Range = 2,
            ExtraLineText = "AVOID_PULLING_MOBS"
        },
        {
            Qpart = { [65098] = { 2 } },
            Coord = { y = 6814.3828125, x = -3272.3427734375 },
            Range = 1,
            ExtraLineText = "HEAL_HIM_ABOVE_90_HP",
            SpellButton = { ["65098-2"] = 361469 }
        },
        { Done = { 65098 },            Coord = { y = 6701.181640625, x = -3230.5698242188 } },
        { PickUp = { 65100 },          Coord = { y = 6701.181640625, x = -3230.5698242188 } },
        { Qpart = { [65100] = { 1 } }, Coord = { y = 6539.8784179688, x = -3233.5537109375 } },
        { Waypoint = 65100,            Coord = { y = 6427.9428710938, x = -3265.8325195312 }, Range = 5 },
        { Qpart = { [65100] = { 2 } }, Coord = { y = 6427.0385742188, x = -3281.8361816406 }, Range = 1 },
        { Qpart = { [65100] = { 4 } }, Coord = { y = 6527.0390625, x = -3279.1240234375 },    Range = 1,         Gossip = 1 },
        { Qpart = { [65100] = { 3 } }, Coord = { y = 6495.7548828125, x = -3376.5024414062 }, Range = 1,         Gossip = 1 },
        { Done = { 65100 },            Coord = { y = 6508.775390625, x = -3310.8601074219 } },
        { PickUp = { 66237 },          Coord = { y = 1353.9573974609, x = -4374.6572265625 }, Zone = 1 },
        { Done = { 66237 },            Coord = { y = 1351.8422851562, x = -4371.4848632812 }, Zone = 1 },
        { PickUp = { 66534 },          Coord = { y = 1351.8422851562, x = -4371.4848632812 }, Zone = 1 },
        { Qpart = { [66534] = { 4 } }, Coord = { y = 1442.9255371094, x = -4476.4033203125 }, Range = 2,         Zone = 1 },
        { Qpart = { [66534] = { 2 } }, Coord = { y = 1528.0391845703, x = -4358.1259765625 }, Range = 2,         Zone = 85 },
        { Qpart = { [66534] = { 1 } }, Coord = { y = 1625.6760253906, x = -4436.0498046875 }, Range = 2,         Zone = 85 },
        { Qpart = { [66534] = { 3 } }, Coord = { y = 1550.6510009766, x = -4171.8388671875 }, Range = 2,         Zone = 85 },
        { Done = { 66534 },            Coord = { y = 2043.3579101562, x = -4272.0268554688 }, Zone = 85 },
        { PickUp = { 65437 },          Coord = { y = 2046.8366699219, x = -4272.72265625 },   RaidIcon = 190239, Zone = 85 },
        {
            Qpart = { [65437] = { 1 } },
            Coord = { y = 2046.8366699219, x = -4272.72265625 },
            Range = 1,
            Gossip = 1,
            RaidIcon = 190239,
            Zone = 85
        },
        { Done = { 65437 },            Coord = { y = 2046.4887695312, x = -4272.896484375 }, Zone = 85 },
        { PickUp = { 65613 },          Coord = { y = 2046.4887695312, x = -4272.896484375 }, Zone = 85 },
        { Qpart = { [65613] = { 1 } }, Coord = { y = 2046.4887695312, x = -4272.896484375 }, Range = 1, Gossip = 1, Zone = 85 },
        { Qpart = { [65613] = { 2 } }, Coord = { y = 2046.4887695312, x = -4272.896484375 }, Range = 1, ETA = 15,   Zone = 85 },
        {
            Qpart = { [65613] = { 3 } },
            Coord = { y = 2046.4887695312, x = -4272.896484375 },
            Range = 1,
            ExtraLineText = "CLICK_EXTRAACTIONBUTTON",
            Zone = 85
        },
        { Done = { 65613 }, Coord = { y = 2046.2570800781, x = -4273.244140625 }, Zone = 85 },
        { ZoneDoneSave = 1 }
    }
end
