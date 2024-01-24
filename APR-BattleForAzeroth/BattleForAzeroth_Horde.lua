-- Orgrimmar part of intro
APR.RouteQuestStepList["1-Orgrimmar"] = {
    {
        PickUp = {
            51443,
        },
        PickUpDB = {
            51443,
            60361,
        },
        Coord = {
            x = -4365.8,
            y = 1598.5,
        },
    },
    {
        Qpart = {
            [51443] = {
                1,
            },
        },
        QpartDB = {
            51443,
            60361,
        },
        Range = 7.73,
        Coord = {
            x = -4347.9,
            y = 1659.8,
        },
    },
    {
        Waypoint = 51443,
        Range = 11.65,
        Coord = {
            x = -4375.5,
            y = 1610.3,
        },
    },
    {
        Waypoint = 51443,
        Range = 7.36,
        Coord = {
            x = -4432.7,
            y = 1573.7,
        },
    },
    {
        Qpart = {
            [51443] = {
                2,
            },
        },
        QpartDB = {
            51443,
            60361,
        },
        Range = 0.69,
        Coord = {
            x = -4455.2,
            y = 1577,
        },
    },
    {
        Done = {
            51443,
        },
        DoneDB = {
            51443,
            60361,
        },
        Coord = {
            x = -4452.4,
            y = 1577.3,
        },
    },
    {
        PickUp = {
            50769,
        },
        Coord = {
            x = -4452.4,
            y = 1577.3,
        },
    },
    {
        Qpart = {
            [50769] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -4455.3,
            y = 1578.4,
        },
    },
    {
        ExtraLineText = "SCENARIO",
        Qpart = {
            [50769] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = -4394.8,
            y = 1517.4,
        },
    },
    {
        ZoneDoneSave = 1,
    },
}
-- Zuldazar part of intro
APR.RouteQuestStepList["862-Zuldazar"] = {
    {
        Done = {
            50769,
        },
        Coord = {
            x = 804.7,
            y = -2162.2,
        },
    },
    {
        PickUp = {
            46957,
        },
        Coord = {
            x = 804.4,
            y = -2144.9,
        },
    },
    {
        Qpart = {
            [46957] = {
                1,
            },
        },
        RaidIcon = 132661,
        Range = 90.35,
        Coord = {
            x = 803.7,
            y = -1808.7,
        },
    },
    {
        Done = {
            46957,
        },
        Coord = {
            x = 803.7,
            y = -1808.7,
        },
    },
    {
        PickUp = {
            46930,
        },
        Coord = {
            x = 803.7,
            y = -1808.7,
        },
    },
    {
        Qpart = {
            [46930] = {
                1,
            },
        },
        Range = 0.69,
        Gossip = 1,
        Coord = {
            x = 803.2,
            y = -1804.0,
        },
    },
    {
        Qpart = {
            [46930] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.61,
        Coord = {
            x = 837.7,
            y = -1099.9,
        },
    },
    {
        Done = {
            46930,
        },
        Coord = {
            x = 806.1,
            y = -1063.5,
        },
    },
    {
        PickUp = {
            46931,
        },
        Coord = {
            x = 806.1,
            y = -1063.5,
        },
    },
    {
        SayTriggerStartH = 1,
        ExtraLineText = "FOLLOW_ZOLANI",
        Waypoint = 46931,
        Range = 5,
        Coord = {
            x = 816.6,
            y = -1096.5,
        },
    },
    {
        SayTriggerStartH = 1,
        ExtraLineText = "USE_ELEVATOR",
        Waypoint = 46931,
        Range = 2,
        Coord = {
            x = 852.2,
            y = -1126.4,
        },
    },
    {
        SayTriggerStartH = 1,
        Waypoint = 46931,
        Range = 5,
        Coord = {
            x = 819.7,
            y = -1111.7,
        },
    },
    {

        Qpart = {
            [46931] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 805.7,
            y = -1005.3,
        },
    },
    {
        Qpart = {
            [46931] = {
                3,
            },
        },
        Range = 1.15,
        Coord = {
            x = 804.7,
            y = -1124.8,
        },
    },
    {
        Qpart = {
            [46931] = {
                4,
            },
        },
        Range = 0.69,
        Coord = {
            x = 775.9,
            y = -1124.3,
        },
    },
    {
        Qpart = {
            [46931] = {
                5,
            },
        },
        Range = 0.69,
        Coord = {
            x = 832.9,
            y = -1124.0,
        },
    },
    {
        Range = 5.14,
        Waypoint = 46931,
        Coord = {
            x = 812.4,
            y = -1124.9,
        },
    },
    {
        Range = 5.21,
        Waypoint = 46931,
        Coord = {
            x = 814,
            y = -1090.7,
        },
    },
    {
        Coord = {
            x = 818.5,
            y = -1120.0,
        },
        Done = {
            46931,
        },
    },
    {
        PickUp = {
            47514,
        },
        ExtraLineText = "SCOUTING_MAP",
        Coord = {
            x = 818.9,
            y = -1119,
        },
    },
    {
        Done = {
            47514,
        },
        Coord = {
            x = 818.9,
            y = -1119,
        },
    },
    {
        ZoneDoneSave = 1,
    },
}
-- Zuldazar
APR.RouteQuestStepList["862-Zuldazar-1"] = {
    {
        PickUp = {
            49615,
        },
        Coord = {
            x = 819.2,
            y = -1120.3,
        },
    },
    {
        SetHS = 49615,
        Coord = {
            x = 805.7,
            y = -1125.5,
        },
        Gossip = 1,
        GossipOptionID = 47953,
    },
    {
        Waypoint = 49615,
        Range = 5,
        Coord = {
            x = 815.9,
            y = -1138.9,
        },
    },
    {
        ExtraLineText = "UP_ELEVATOR",
        Waypoint = 49615,
        Range = 5,
        Coord = {
            x = 852.4,
            y = -1126.1,
        },
    },
    {
        ExtraLineText = "UP_ELEVATOR",
        Waypoint = 49615,
        Range = 5,
        Coord = {
            x = 836.5,
            y = -1101.5,
        },
    },
    {
        Done = {
            49615,
        },
        Coord = {
            x = 805.5,
            y = -1135,
        },
    },
    {
        PickUp = {
            49488,
        },
        Coord = {
            x = 807.6,
            y = -1134.8,
        },
    },
    {
        Qpart = {
            [49488] = {
                1,
            },
        },
        Coord = {
            x = 804.9,
            y = -1072.4,
        },
        Range = 5,
    },
    {
        Qpart = {
            [49488] = {
                2,
            },
        },
        Coord = {
            x = 394.2,
            y = -459.2,
        },
        Range = 5,
    },
    {
        Done = {
            49488,
        },
        Coord = {
            x = 393.3,
            y = -458.2,
        },
    },
    {
        PickUp = {
            49489,
            49490,
        },
        Coord = {
            x = 394.8,
            y = -458.2,
        },
    },
    {
        PickUp = {
            49491,
        },
        Coord = {
            x = 326.8,
            y = -412.9,
        },
    },
    {
        Waypoint = 49489,
        Range = 17.54,
        Coord = {
            x = 297.5,
            y = -453.2,
        },
        Fillers = {
            [49491] = {
                1,
            },
            [49490] = {
                1,
            },
        },
    },
    {
        QpartPart = {
            [49489] = {
                1,
            },
        },
        Fillers = {
            [49491] = {
                1,
            },
            [49490] = {
                1,
            },
        },
        TrigText = "1/2",
        Range = 0.69,
        Coord = {
            x = 207.3,
            y = -480.9,
        },
    },
    {
        Waypoint = 49489,
        Range = 10.7,
        Coord = {
            x = 297.8,
            y = -451.2,
        },
        Fillers = {
            [49491] = {
                1,
            },
            [49490] = {
                1,
            },
        },
    },
    {
        QpartPart = {
            [49489] = {
                1,
            },
        },
        Fillers = {
            [49490] = {
                1,
            },
            [49491] = {
                1,
            },
        },
        TrigText = "2/2",
        Range = 5.95,
        Coord = {
            x = 366.8,
            y = -259.9,
        },
    },
    {
        Qpart = {
            [49491] = {
                1,
            },
            [49490] = {
                1,
            },
        },
        Range = 22.26,
        Coord = {
            x = 361.5,
            y = -259.9,
        },
    },
    {
        Coord = {
            x = 399.8,
            y = -226.5,
        },
        Done = {
            49491,
        },
    },

    {
        Coord = {
            x = 390.8,
            y = -215.4,
        },
        Done = {
            49489,
            49490,
        },
    },
    {
        PickUp = {
            49492,
        },
        Coord = {
            x = 390.8,
            y = -215.4,
        },
    },
    {
        Qpart = {
            [49492] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 388.6,
            y = -201.7,
        },
    },
    {
        Qpart = {
            [49492] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = 338.8,
            y = -205.2,
        },
    },
    {
        Qpart = {
            [49492] = {
                3,
            },
        },
        Range = 0.75,
        Coord = {
            x = 285.6,
            y = -221,
        },
    },
    {
        ETA = 19,
        Coord = {
            x = 263.2,
            y = -231.5,
        },
        Done = {
            49492,
        },
    },
    {
        PickUp = {
            49493,
            49494,
        },
        Coord = {
            x = 263.2,
            y = -231.5,
        },
    },
    {
        PickUp = {
            51663,
        },
        Coord = {
            x = 184.5,
            y = -213,
        },
        Fillers = {
            [49493] = {
                1,
            },
        },
        Button = {
            ["49493-1"] = 155458,
        },
        ButtonSpellId = {
            [257795] = "49493-1",
        },
        ButtonCooldown = {
            [257795] = 3,
        },
    },
    {
        Qpart = {
            [49494] = {
                1,
            },
        },
        Fillers = {
            [51663] = {
                1,
            },
            [49493] = {
                1,
            },
        },
        Button = {
            ["49493-1"] = 155458,
        },
        ButtonSpellId = {
            [257795] = "49493-1",
        },
        ButtonCooldown = {
            [257795] = 3,
        },
        Range = 11.15,
        Coord = {
            x = 217.6,
            y = -143.9,
        },
    },
    {
        Qpart = {
            [51663] = {
                1,
            },
            [49493] = {
                1,
            },
        },
        Button = {
            ["49493-1"] = 155458,
        },
        ButtonSpellId = {
            [257795] = "49493-1",
        },
        ButtonCooldown = {
            [257795] = 3,
        },
        Range = 19.4,
        Coord = {
            x = 198.4,
            y = -216.2,
        },
    },

    {
        Waypoint = 49494,
        Range = 15.26,
        Coord = {
            x = 173.6,
            y = -253.7,
        },
    },
    {
        Done = {
            49493,
            49494,
            51663,
        },
        Coord = {
            x = 147.6,
            y = -323.7,
        },
    },
    {
        PickUp = {
            49495,
        },
        Coord = {
            x = 147.6,
            y = -323.7,
        },
    },
    {
        Qpart = {
            [49495] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 133.4,
            y = -373.5,
        },
    },
    {
        Qpart = {
            [49495] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 137,
            y = -349.3,
        },
    },
    {
        Qpart = {
            [49495] = {
                3,
            },
        },
        Range = 0.69,
        Coord = {
            x = 137.8,
            y = -350.2,
        },
    },
    {
        Qpart = {
            [49495] = {
                4,
            },
        },
        Range = 0.69,
        Coord = {
            x = 162.1,
            y = -384.4,
        },
    },
    {
        Done = {
            49495,
        },
        Coord = {
            x = 147.6,
            y = -324.7,
        },
    },
    {
        PickUp = {
            49905,
        },
        Coord = {
            x = 148.9,
            y = -324.7,
        },
    },
    {
        Qpart = {
            [49905] = {
                1,
            },
        },
        Range = 11.64,
        Coord = {
            x = 155.6,
            y = -352.2,
        },
    },

    {
        Bloodlust = 1,
        Qpart = {
            [49905] = {
                2,
            },
        },
        Range = 7.91,
        Coord = {
            x = 152.5,
            y = -362.4,
        },
    },
    {
        Done = {
            49905,
        },
        Coord = {
            x = 157.5,
            y = -342.5,
        },
    },
    {
        PickUp = {
            49663,
        },
        Coord = {
            x = 157.5,
            y = -342.5,
        },
    },
    {
        UseHS = 49810,
        Coord = {
            x = 157.5,
            y = -342.5,
        },
    },
    {
        Waypoint = 49615,
        Coord = {
            x = 810.6,
            y = -1139.1,
        },
        Range = 5,
        ExtraLineText = "UP_ELEVATOR",
    },
    {
        Waypoint = 49615,
        Coord = {
            x = 852.4,
            y = -1126.1,
        },
        Range = 5,
        ExtraLineText = "UP_ELEVATOR",
    },
    {
        Waypoint = 49615,
        Coord = {
            x = 836.5,
            y = -1101.5,
        },
        Range = 5,
        ExtraLineText = "UP_ELEVATOR",
    },
    {
        Done = {
            49663,
        },
        Coord = {
            x = 806,
            y = -1134.5,
        },
    },
    {
        PickUp = {
            47445,
            50835,
        },
        Coord = {
            x = 807.6,
            y = -1134.8,
        },
    },



    {
        Waypoint = 50835,
        Range = 5.42,
        Coord = {
            x = 836.5,
            y = -1101.5,
        },
    },
    {
        ExtraLineText = "DOWN_ELEVATOR",
        Waypoint = 50835,
        Range = 2.33,
        Coord = {
            x = 852.4,
            y = -1126.1,
        },
    },
    {
        ExtraLineText = "DOWN_ELEVATOR",
        Waypoint = 50835,
        Range = 5.33,
        Coord = {
            x = 819.6,
            y = -1110.7,
        },
    },

    {
        Waypoint = 50835,
        Range = 5.33,
        Coord = {
            x = 802.9,
            y = -1049.3,
        },
    },
    {
        UseFlightPath = 50835,
        ETA = 38,
        Name = "Port of Zandalar, Zuldazar",
        NodeID = 1957,
        Coord = {
            x = 751.1,
            y = -1035.4,
        },
    },
    {
        Waypoint = 50835,
        Range = 10,
        Coord = {
            x = 744.5,
            y = -1950.9,
        },
    },
    {
        Coord = {
            x = 803.2,
            y = -1858.9,
        },
        Done = {
            50835,
        },
    },
    {
        PickUp = {
            46926,
            46846,
        },
        Coord = {
            x = 802.2,
            y = -1855,
        },
    },
    {
        PickUp = {
            48452,
        },
        Coord = {
            x = 965.4,
            y = -1804,
        },
        Fillers = {
            [46926] = {
                1,
            },
        },
    },
    {
        Waypoint = 48452,
        Range = 9,
        Coord = {
            x = 1026,
            y = -1801.5,
        },
    },
    {
        ExtraLineText = "JUMP_OFF_BRIDGE",
        Waypoint = 48452,
        Range = 13.72,
        Coord = {
            x = 1024,
            y = -1826.9,
        },
    },
    {
        Qpart = {
            [48452] = {
                2,
            },
        },
        Coord = {
            x = 998.4,
            y = -1822.6,
        },
        Range = 9.75,
        Fillers = {
            [48452] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48452] = {
                1,
            },
        },
        Coord = {
            x = 1034.7,
            y = -1811.1,
        },
        Range = 88,
    },
    {
        Waypoint = 48452,
        Range = 8.95,
        Coord = {
            x = 1014.1,
            y = -1734.1,
        },
    },

    {
        Done = {
            48452,
        },
        Coord = {
            x = 965.2,
            y = -1804.8,
        },
    },
    {
        PickUp = {
            48454,
        },
        Coord = {
            x = 964.7,
            y = -1803.4,
        },
    },
    {
        Qpart = {
            [46846] = {
                3,
            },
        },
        Gossip = 1,
        Fillers = {
            [46926] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = 935.2,
            y = -1760.9,
        },
    },
    {
        Range = 10.45,
        Waypoint = 46846,
        Coord = {
            x = 775.7,
            y = -1874,
        },
        Fillers = {
            [46926] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [46846] = {
                1,
            },
        },
        Gossip = 1,
        Fillers = {
            [46926] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 761.2,
            y = -1971,
        },
    },
    {
        Range = 8,
        Waypoint = 46846,
        Coord = {
            x = 758.4,
            y = -1954,
        },
    },
    {
        ExtraLineText = "JUMP_OFF",
        Range = 16.2,
        Waypoint = 46846,
        Coord = {
            x = 679.7,
            y = -1948.9,
        },
    },
    {
        Qpart = {
            [46846] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.61,
        Coord = {
            x = 691.7,
            y = -1972.9,
        },
        Fillers = {
            [46926] = {
                1,
            },
        },
    },
    {
        Range = 9.66,
        Waypoint = 46926,
        Coord = {
            x = 793,
            y = -1941.5,
        },
    },
    {
        Qpart = {
            [46926] = {
                1,
            },
        },
        Range = 325.14,
        Coord = {
            x = 805.2,
            y = -1856.1,
        },
    },
    {
        Coord = {
            x = 805.2,
            y = -1856.1,
        },
        Done = {
            48454,
            46846,
            46926,
        },
        Fillers = {
            [48404] = {
                1,
            },
        },
    },
    {
        PickUp = {
            46928,
            46927,
            46929,
        },
        Coord = {
            x = 802.7,
            y = -1857,
        },
        Fillers = {
            [48404] = {
                1,
            },
        },
    },
    {
        Range = 9.66,
        Waypoint = 46929,
        Coord = {
            x = 810.5,
            y = -1740.8,
        },
        Fillers = {
            [48404] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [46928] = {
                1,
            },
        },
        Fillers = {
            [46929] = {
                2,
            },
            [48404] = {
                1,
            },
        },
        Range = 15.31,
        Coord = {
            x = 898.9,
            y = -1649.8,
        },
    },
    {
        Qpart = {
            [46929] = {
                2,
            },
        },
        Range = 63.25,
        Coord = {
            x = 858.2,
            y = -1724,
        },
        Fillers = {
            [48404] = {
                1,
            },
        },
    },
    {
        Waypoint = 46927,
        Range = 18,
        Fillers = {
            [46929] = {
                1,
            },
            [48404] = {
                1,
            },
        },
        Coord = {
            x = 751.7,
            y = -1728.4,
        },
    },
    {
        Waypoint = 46927,
        Range = 25,
        Coord = {
            x = 631.7,
            y = -1782.8,
        },
        Fillers = {
            [46929] = {
                1,
            },
            [48404] = {
                1,
            },
        },
    },
    {
        Bloodlust = 1,
        Qpart = {
            [46927] = {
                1,
            },
        },
        Fillers = {
            [46929] = {
                1,
            },
            [48404] = {
                1,
            },
        },
        Range = 10.76,
        Coord = {
            x = 629.1,
            y = -1903,
        },
    },
    {
        Qpart = {
            [46929] = {
                1,
            },
        },
        Range = 26.35,
        Coord = {
            x = 629,
            y = -1784.6,
        },
        Fillers = {
            [48404] = {
                1,
            },
        },
    },
    {
        Waypoint = 46927,
        Range = 5,
        Coord = {
            x = 632.6,
            y = -1769,
        },
    },
    {
        Waypoint = 46927,
        Range = 5,
        Coord = {
            x = 790.4,
            y = -1731.0,
        },
    },
    {
        Done = {
            46928,
            46927,
            46929,
        },
        Coord = {
            x = 801.4,
            y = -1856,
        },
        Fillers = {
            [48404] = {
                1,
            },
        },
    },
    {
        PickUp = {
            50881,
        },
        Coord = {
            x = 801.4,
            y = -1857.6,
        },
        Fillers = {
            [48404] = {
                1,
            },
        },
    },
    {
        ExtraLineText = "TALK_TO_NPC_TO_RIDE_BOAT",
        Waypoint = 49284,
        Range = 5,
        Coord = {
            x = 723.1,
            y = -2059.1,
        },
    },
    {
        ExtraLineText = "TAKE_BOAT_TO_SEEKERS_OUTPOST",
        GetFP = 2075,
        Range = 5.91,
        Coord = {
            x = -253.2,
            y = -2304.5,
        },
    },
    {
        ExtraLineText = "GIVERS_AROUND_AREA",
        PickUp = {
            49284,
            49285,
        },
        Coord = {
            x = -253.2,
            y = -2304.5,
        },
    },
    {
        Qpart = {
            [49284] = {
                1,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -314.8,
            y = -2264.7,
        },
    },
    {
        Qpart = {
            [49285] = {
                1,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = -355.4,
            y = -2241.9,
        },
    },
    {
        Qpart = {
            [49285] = {
                2,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = -484.2,
            y = -2412.7,
        },
    },
    {
        Qpart = {
            [49285] = {
                3,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -475.5,
            y = -2277.2,
        },
    },
    {
        Qpart = {
            [49284] = {
                2,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -438,
            y = -2178,
        },
    },
    {
        Qpart = {
            [49284] = {
                3,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -553.3,
            y = -2123.2,
        },
    },
    {
        Coord = {
            x = -524.3,
            y = -2063,
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Done = {
            49285,
            49284,
        },
    },
    {
        PickUp = {
            49286,
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Coord = {
            x = -524.3,
            y = -2063,
        },
    },
    {
        ExtraLineText = "INSIDE_CAVE",
        Qpart = {
            [49286] = {
                1,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 19.7,
        Coord = {
            x = -584.8,
            y = -1994.9,
        },
    },
    {
        Qpart = {
            [49286] = {
                2,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -523.5,
            y = -2058.2,
        },
    },
    {
        Coord = {
            x = -523.2,
            y = -2059.7,
        },
        Done = {
            49286,
        },
    },
    {
        PickUp = {
            49287,
            49288,
        },
        Coord = {
            x = -523.2,
            y = -2059.7,
        },
    },
    {
        Qpart = {
            [49287] = {
                1,
            },
        },
        Fillers = {
            [49315] = {
                1,
            },
            [49288] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = -549.3,
            y = -2333,
        },
    },
    {
        Qpart = {
            [49287] = {
                2,
            },
        },
        Fillers = {
            [49288] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = -649.7,
            y = -2373.5,
        },
    },

    {
        Qpart = {
            [49287] = {
                3,
            },
        },
        Fillers = {
            [49288] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -810.8,
            y = -2369,
        },
    },
    {
        ExtraLineText = "BEWARE_TWO_LEVEL",
        Qpart = {
            [49287] = {
                4,
            },
        },
        Fillers = {
            [49288] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -833.3,
            y = -2252.4,
        },
    },
    {
        Qpart = {
            [49288] = {
                1,
            },
        },
        Range = 29.68,
        Coord = {
            x = -827.3,
            y = -2256,
        },
    },
    {
        Coord = {
            x = -657.2,
            y = -2088.7,
        },
        Done = {
            49287,
            49288,
        },
    },
    {
        PickUp = {
            49289,
        },
        Coord = {
            x = -657,
            y = -2088.2,
        },
    },
    {
        Qpart = {
            [49289] = {
                1,
                2,
            },
        },
        Button = {
            ["49289-1"] = 157539,
        },
        Range = 15.71,
        Coord = {
            x = -772.3,
            y = -2086,
        },
    },
    {
        Coord = {
            x = -656.5,
            y = -2089.5,
        },
        Done = {
            49289,
        },
    },
    {
        PickUp = {
            51407,
        },
        Coord = {
            x = -657,
            y = -2089.2,
        },
    },
    {
        ExtraLineText = "PORTAL_WILL_APPEAR",
        Done = {
            51407,
        },
        Coord = {
            x = -262,
            y = -2281.5,
        }
    },
    {
        PickUp = {
            50331,
        },
        Coord = {
            x = -261.3,
            y = -2280.5,
        },
    },

    {
        Qpart = {
            [50331] = {
                1,
            },
        },
        Gossip = 999,
        Range = 14.12,
        Coord = {
            x = -171.9,
            y = -2399.4,
        },
    },
    {
        Qpart = {
            [50331] = {
                1,
            },
        },
        Range = 14.12,
        Coord = {
            x = -1175,
            y = -1203.6,
        },
    },
    {
        Coord = {
            x = -1175,
            y = -1203.6,
        },
        Done = {
            50331,
        },
    },
    {
        PickUp = {
            48015,
            48014,
        },
        Coord = {
            x = -1175,
            y = -1203.6,
        },
    },
    {
        Qpart = {
            [48015] = {
                1,
            },
        },
        Fillers = {
            [48014] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -1104.8,
            y = -1159.6,
        },
    },
    {
        Qpart = {
            [48015] = {
                3,
            },
        },
        Fillers = {
            [48014] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -1124.9,
            y = -1062,
        },
    },
    {
        Qpart = {
            [48015] = {
                2,
            },
        },
        Fillers = {
            [48014] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = -1060.9,
            y = -1127.8,
        },
    },
    {
        Qpart = {
            [48014] = {
                1,
            },
        },
        Range = 13.35,
        Coord = {
            x = -1124.9,
            y = -1063.5,
        },
    },
    {
        Coord = {
            x = -993.8,
            y = -1000.8,
        },
        Done = {
            48015,
            48014,
        },
    },
    {
        PickUp = {
            49969,
            48025,
        },
        Coord = {
            x = -993.8,
            y = -1000.5,
        },
    },

    {
        ExtraLineText = "USE_FLIGHTPATH",
        GetFP = 2066,
        Waypoint = 49969,
        Range = 6.58,
        Coord = {
            x = -1057.9,
            y = -955.7,
        },
    },
    {
        Qpart = {
            [48025] = {
                1,
            },
        },
        Fillers = {
            [49969] = {
                1,
            },
        },
        Button = {
            ["48025-1"] = 151859,
        },
        Range = 0.69,
        Coord = {
            x = -917.7,
            y = -712.2,
        },
    },
    {
        Qpart = {
            [48025] = {
                2,
            },
        },
        Fillers = {
            [49969] = {
                1,
            },
        },
        Button = {
            ["48025-2"] = 151859,
        },
        Range = 0.75,
        Coord = {
            x = -1032.1,
            y = -693.8,
        },
    },
    {
        Qpart = {
            [48025] = {
                3,
            },
        },
        Fillers = {
            [49969] = {
                1,
            },
        },
        Button = {
            ["48025-3"] = 151859,
        },
        Range = 0.69,
        Coord = {
            x = -1177.1,
            y = -821.3,
        },
    },
    {
        Qpart = {
            [48025] = {
                5,
            },
        },
        Fillers = {
            [49969] = {
                1,
            },
        },
        Button = {
            ["48025-5"] = 151859,
        },
        Range = 0.61,
        Coord = {
            x = -1357,
            y = -871.2,
        },
    },
    {
        Qpart = {
            [48025] = {
                4,
            },
        },
        Fillers = {
            [49969] = {
                1,
            },
        },
        Button = {
            ["48025-4"] = 151859,
        },
        Range = 0.61,
        Coord = {
            x = -1208.9,
            y = -945,
        },
    },
    {
        Qpart = {
            [49969] = {
                1,
            },
        },
        Range = 18.23,
        Coord = {
            x = -1208.9,
            y = -945,
        },
    },
    {
        Coord = {
            x = -1293.6,
            y = -1006.5,
        },
        Done = {
            49969,
        },
    },
    {
        PickUp = {
            48026,
        },
        Coord = {
            x = -1293.6,
            y = -1006.5,
        },
    },
    {
        Qpart = {
            [48026] = {
                1,
            },
        },
        Range = 5.13,
        Coord = {
            x = -1370,
            y = -1116,
        },
    },

    {
        Qpart = {
            [48026] = {
                1,
            },
        },
        Range = 6.57,
        Coord = {
            x = -1370,
            y = -1116,
        },
    },
    {
        ExtraLineText = "BENEATH_HANDIN",
        Coord = {
            x = -1370.5,
            y = -1116.6,
        },
        Done = {
            48026,
        },
    },
    {
        PickUp = {
            51538,
        },
        Coord = {
            x = -1370.5,
            y = -1116.6,
        },
    },
    {
        Coord = {
            x = -992.7,
            y = -997.3,
        },
        Done = {
            48025,
            51538,
        },
    },
    {
        PickUp = {
            51539,
        },
        Coord = {
            x = -992.7,
            y = -997.3,
        },
    },
    {
        Waypoint = 50881,
        Range = 17.66,
        Coord = {
            x = -1005.8,
            y = -1168.5,
        },
    },
    {
        Waypoint = 50881,
        Range = 27.69,
        Coord = {
            x = -932.2,
            y = -1279.3,
        },
    },
    {
        PickUp = {
            51246,
            51247,
        },
        Coord = {
            x = -774.5,
            y = -1358.9,
        },
    },
    {
        PickUp = {
            51249,
            51248,
        },
        Coord = {
            x = -756.5,
            y = -1370.3,
        },
    },
    {
        Qpart = {
            [51247] = {
                2,
            },
        },
        Fillers = {
            [51248] = {
                1,
            },
            [51249] = {
                1,
            },
            [51246] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = -782.3,
            y = -1496.1,
        },
    },
    {
        Qpart = {
            [51247] = {
                1,
            },
        },
        Fillers = {
            [51248] = {
                1,
            },
            [51246] = {
                1,
            },
            [51249] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -774.2,
            y = -1589,
        },
    },
    {
        Qpart = {
            [51247] = {
                3,
            },
        },
        Fillers = {
            [51248] = {
                1,
            },
            [51249] = {
                1,
            },
            [51246] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -599.5,
            y = -1537.3,
        },
    },
    {
        Qpart = {
            [51248] = {
                1,
            },
            [51249] = {
                1,
            },
            [51246] = {
                1,
            },
        },
        Range = 64.1,
        Coord = {
            x = -601,
            y = -1534.8,
        },
    },
    {
        Done = {
            51248,
            51247,
            51246,
            51249,
        },
        Coord = {
            x = -756.3,
            y = -1370.3,
        },
    },
    {
        PickUp = {
            51286,
        },
        Coord = {
            x = -774.6,
            y = -1359.9,
        },
    },
    {
        Qpart = {
            [51286] = {
                1,
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = -1058.3,
            y = -1851.3,
        },
    },
    {
        Done = {
            51286,
        },
        Coord = {
            x = -774.6,
            y = -1359.9,
        },
    },
    {
        UseFlightPath = 51539,
        ETA = 71,
        Name = "The Great Seal",
        NodeID = 1959,
        Coord = {
            x = -1058.4,
            y = -956.3,
        },
    },
    {
        Waypoint = 51539,
        Range = 6.46,
        Coord = {
            x = 800.4,
            y = -1046.8,
        },
    },
    {
        Waypoint = 51539,
        Range = 4.73,
        Coord = {
            x = 814.9,
            y = -1093,
        },
    },
    {
        Done = {
            51539,
        },
        Coord = {
            x = 819.5,
            y = -1124.4,
        },
    },
    {
        ExtraLineText = "USE_ELEVATOR",
        Waypoint = 50881,
        Range = 3.76,
        Coord = {
            x = 854.6,
            y = -1126.3,
        },
    },
    {
        ExtraLineText = "USE_ELEVATOR",
        Waypoint = 50881,
        Range = 3.76,
        Coord = {
            x = 851.2,
            y = -1126.4,
        },
    },
    {
        ExtraLineText = "USE_ELEVATOR",
        Waypoint = 50881,
        Range = 3.76,
        Coord = {
            x = 835.5,
            y = -1101.5,
        },
    },
    {
        Waypoint = 50881,
        Range = 3.76,
        Coord = {
            x = 815.1,
            y = -1103.7,
        },
    },
    {
        Done = {
            50881,
        },
        Coord = {
            x = 802.7,
            y = -1134.1,
        },
    },
    {
        UseGlider = 1,
        Coord = {
            x = 936.6,
            y = -712.7,
        },
        Done = {
            47445,
        },
    },
    {
        PickUp = {
            47423,
        },
        Coord = {
            x = 936.6,
            y = -712.7,
        },
    },
    {
        Qpart = {
            [47423] = {
                1,
            },
        },
        Button = {
            ["47423-1"] = 152627,
        },
        ButtonSpellId = {
            [251685] = "47423-1",
        },
        ButtonCooldown = {
            [251685] = 5,
        },
        Range = 159,
        Coord = {
            x = 887.1,
            y = -664.8,
        },
    },
    {
        Coord = {
            x = 752.2,
            y = -486.4,
        },
        Done = {
            47423,
        },
    },

    {
        PickUp = {
            47433,
        },
        Coord = {
            x = 752.2,
            y = -486.4,
        },
    },
    {
        Qpart = {
            [47433] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = 721,
            y = -481.5,
        },
    },
    {
        Qpart = {
            [47433] = {
                3,
            },
        },
        Range = 207.65,
        Coord = {
            x = 578.2,
            y = -383.3,
        },
    },
    {
        Done = {
            47433,
        },
        Coord = {
            x = 911.4,
            y = -623.7,
        },
    },
    {
        PickUp = {
            47435,
            47434,
        },
        Coord = {
            x = 989.6,
            y = -597.5,
        },
    },
    {
        Qpart = {
            [47435] = {
                1,
            },
            [47434] = {
                1,
            },
        },
        Range = 16.32,
        Coord = {
            x = 1003.6,
            y = -606.8,
        },
    },
    {
        Done = {
            47435,
            47434,
        },
        Coord = {
            x = 1059.5,
            y = -474.7,
        },
    },
    {
        PickUp = {
            47437,
        },
        Coord = {
            x = 1059.5,
            y = -474.7,
        },
    },
    {
        Qpart = {
            [47437] = {
                1,
            },
        },
        Range = 4.87,
        Coord = {
            x = 994.7,
            y = -470.9,
        },
    },
    {
        Waypoint = 47437,
        Range = 3.89,
        Coord = {
            x = 1047.4,
            y = -414.5,
        },
    },

    {
        Waypoint = 47437,
        Range = 4.3,
        Coord = {
            x = 1034.7,
            y = -401,
        },
    },
    {
        Waypoint = 47437,
        Range = 5.64,
        Coord = {
            x = 1008.2,
            y = -424.9,
        },
    },
    {
        Qpart = {
            [47437] = {
                2,
            },
        },
        Range = 9.43,
        Coord = {
            x = 962.5,
            y = -426.9,
        },
    },
    {
        Waypoint = 47437,
        Range = 4.11,
        Coord = {
            x = 960.6,
            y = -471.8,
        },
    },
    {
        Waypoint = 47437,
        Range = 4.04,
        Coord = {
            x = 926.7,
            y = -498.9,
        },
    },
    {
        Qpart = {
            [47437] = {
                3,
            },
        },
        Range = 6.07,
        Coord = {
            x = 963.4,
            y = -568.3,
        },
    },
    {
        Waypoint = 47437,
        Range = 8.08,
        Coord = {
            x = 917.7,
            y = -560,
        },
    },
    {
        Done = {
            47437,
        },
        Coord = {
            x = 912.5,
            y = -507.4,
        },
    },
    {
        PickUp = {
            47422,
        },
        Coord = {
            x = 914.2,
            y = -507.4,
        },
    },
    {
        Waypoint = 47422,
        Range = 10.08,
        Coord = {
            x = 913.7,
            y = -488.4,
        },
    },

    {
        ExtraLineText = "TOTEM_DAMAGE_BUFF",
        Qpart = {
            [47422] = {
                1,
            },
        },
        Range = 20.58,
        Coord = {
            x = 982.9,
            y = -404.4,
        },
    },
    {
        Done = {
            47422,
        },
        Coord = {
            x = 1019.7,
            y = -432.8,
        },
    },
    {
        PickUp = {
            47438,
        },
        Coord = {
            x = 1019.7,
            y = -432.8,
        },
    },
    {
        ExtraLineText = "LOA_INFO_1",
        ExtraLineText2 = "LOA_INFO_2",
        Qpart = {
            [47438] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1012.6,
            y = -433.2,
        },
    },
    {
        Done = {
            47438,
        },
        Coord = {
            x = 1019.6,
            y = -432.3,
        },
    },
    {
        PickedLoa = 1,
        PickUp = {
            47440,
        },
        Coord = {
            x = 1014.1,
            y = -438.8,
        },
    },
    {
        PickedLoa = 1,
        Qpart = {
            [47440] = {
                1,
            },
        },
        Range = 5.31,
        Coord = {
            x = 1014.7,
            y = -448.9,
        },
    },
    {
        PickedLoa = 1,
        Waypoint = 47440,
        Range = 4.88,
        Coord = {
            x = -320.7,
            y = -1361.3,
        },
    },
    {
        PickedLoa = 1,
        Qpart = {
            [47440] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = -338.5,
            y = -1401.3,
        },
    },
    {
        PickedLoa = 1,
        Qpart = {
            [47440] = {
                3,
            },
        },
        Range = 4.47,
        Coord = {
            x = -366.8,
            y = -1397.9,
        },
    },

    {
        PickedLoa = 1,
        Done = {
            47440,
        },
        ETA = 52,
        Coord = {
            x = 804.5,
            y = -893,
        },
    },
    {
        PickedLoa = 1,
        PickUp = {
            47432,
        },
        Coord = {
            x = 804.5,
            y = -893,
        },
    },
    {
        PickedLoa = 1,
        PickUp = {
            49768,
        },
        Coord = {
            x = 749.1,
            y = -1038,
        },
    },
    {
        PickedLoa = 1,
        Waypoint = 47432,
        Range = 11.03,
        Coord = {
            x = 799.2,
            y = -1047.5,
        },
    },
    {
        PickedLoa = 1,
        Waypoint = 47432,
        Range = 7.35,
        Coord = {
            x = 791.4,
            y = -1107.4,
        },
    },
    {
        PickedLoa = 1,
        PickUp = {
            50538,
        },
        Coord = {
            x = 773.6,
            y = -1124.5,
        },
    },
    {
        ExtraLineText = "UP_ELEVATOR",
        PickedLoa = 1,
        Waypoint = 47432,
        Range = 3.59,
        Coord = {
            x = 754.9,
            y = -1125.1,
        },
    },
    {
        ExtraLineText = "UP_ELEVATOR",
        PickedLoa = 1,
        Waypoint = 47432,
        Range = 6.54,
        Coord = {
            x = 790.2,
            y = -1101.5,
        },
    },
    {
        PickedLoa = 1,
        Done = {
            47432,
        },
        Coord = {
            x = 804.6,
            y = -1134.5,
        },
    },


    {
        PickedLoa = 2,
        PickUp = {
            47439,
        },
        Coord = {
            x = 1019.4,
            y = -432.9,
        },
    },
    {
        UseGlider = 1,
        PickedLoa = 2,
        Range = 38.05,
        Waypoint = 47439,
        Coord = {
            x = 1226.9,
            y = -353.7,
        },
    },
    {
        PickedLoa = 2,
        Qpart = {
            [47439] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.61,
        Coord = {
            x = 1631.5,
            y = -440.7,
        },
    },
    {
        PickedLoa = 2,
        UseHS = 47439,
        Coord = {
            x = 1631.5,
            y = -440.7,
        },
    },
    {
        PickedLoa = 2,
        Waypoint = 47439,
        Range = 7.35,
        Coord = {
            x = 801.7,
            y = -1136.5,
        },
    },
    {
        PickedLoa = 2,
        PickUp = {
            50538,
        },
        Coord = {
            x = 773.6,
            y = -1124.5,
        },
    },
    {
        PickedLoa = 2,
        Waypoint = 47439,
        Range = 7.35,
        Coord = {
            x = 790.7,
            y = -1108.1,
        },
    },
    {
        PickedLoa = 2,
        Waypoint = 47439,
        Range = 7.35,
        Coord = {
            x = 801.2,
            y = -1050.6,
        },
    },
    {
        PickedLoa = 2,
        PickUp = {
            49768,
        },
        Coord = {
            x = 749.1,
            y = -1038,
        },
    },
    {
        ExtraLineText = "DO_NOT_USE_GLIDER",
        PickedLoa = 2,
        Done = {
            47439,
        },
        Coord = {
            x = 804.5,
            y = -891.3,
        },
    },
    {
        PickedLoa = 2,
        PickUp = {
            48897,
        },
        Coord = {
            x = 804.5,
            y = -891.3,
        },
    },
    {
        Waypoint = 48897,
        Coord = {
            x = 805.9,
            y = -891.0,
        },
        Range = 10,
        PickedLoa = 2,
    },
    {
        Waypoint = 48897,
        Coord = {
            x = 759.0,
            y = -946.6,
        },
        Range = 10,
        PickedLoa = 2,
    },
    {
        Waypoint = 48897,
        Coord = {
            x = 798.7,
            y = -965.4,
        },
        Range = 10,
        PickedLoa = 2,
    },
    {
        Waypoint = 48897,
        Coord = {
            x = 778.7,
            y = -1021.6,
        },
        Range = 10,
        PickedLoa = 2,
    },
    {
        Waypoint = 48897,
        Coord = {
            x = 804.8,
            y = -1053.0,
        },
        Range = 10,
        PickedLoa = 2,
    },
    {
        Waypoint = 48897,
        Coord = {
            x = 757.6,
            y = -1126.3,
        },
        Range = 10,
        PickedLoa = 2,
    },
    {
        Waypoint = 48897,
        Coord = {
            x = 790.2,
            y = -1101.5,
        },
        Range = 6.54,
        PickedLoa = 2,
    },
    {
        Done = {
            48897,
        },
        Coord = {
            x = 806,
            y = -1134.5,
        },
        PickedLoa = 2,
    },
    {
        UseGlider = 1,
        PickUp = {
            49810,
        },
        Coord = {
            x = 284.3,
            y = -615.2,
        },
    },
    {
        Qpart = {
            [49810] = {
                1,
            },
        },
        Button = {
            ["49810-1"] = 155911,
        },
        ButtonSpellId = {
            [259041] = "49810-1",
        },
        ButtonCooldown = {
            [259041] = 10,
        },
        Range = 0.69,
        Coord = {
            x = 374,
            y = -700.7,
        },
    },
    {
        Qpart = {
            [49810] = {
                2,
            },
        },
        Button = {
            ["49810-2"] = 155911,
        },
        ButtonSpellId = {
            [259041] = "49810-2",
        },
        ButtonCooldown = {
            [259041] = 10,
        },
        Range = 0.69,
        Coord = {
            x = 285.5,
            y = -835.5,
        },
    },
    {
        Done = {
            49810,
        },
        Coord = {
            x = 285.1,
            y = -615,
        },
    },
    {
        PickUp = {
            49814,
            50154,
            49801,
        },
        Coord = {
            x = 285.1,
            y = -615,
        },
    },
    {
        Qpart = {
            [50154] = {
                1,
            },
            [49814] = {
                1,
            },
        },
        Range = 52.5,
        Coord = {
            x = 372.8,
            y = -641.5,
        },
    },

    {
        Qpart = {
            [49801] = {
                1,
            },
        },
        Range = 34.48,
        Coord = {
            x = 344.5,
            y = -970.8,
        },
    },
    {
        Coord = {
            x = 286,
            y = -618.8,
        },
        Done = {
            49814,
            49801,
            50154,
        },
    },
    {
        PickUp = {
            50074,
            50150,
        },
        Coord = {
            x = 286,
            y = -618.8,
        },
    },
    {
        Qpart = {
            [50074] = {
                1,
            },
        },
        Button = {
            ["50074-1"] = 156475,
        },
        Range = 0.61,
        Coord = {
            x = 371.3,
            y = -683.3,
        },
    },
    {
        Qpart = {
            [50150] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 292,
            y = -821.8,
        },
    },
    {
        Qpart = {
            [50150] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 269.7,
            y = -816,
        },
    },
    {
        Done = {
            50150,
            50074,
        },
        Coord = {
            x = 286,
            y = -618.7,
        },
    },
    {
        PickUp = {
            50252,
        },
        Coord = {
            x = 286.1,
            y = -619.3,
        },
    },
    {
        Qpart = {
            [50252] = {
                1,
                2,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 285,
            y = -618.3,
        },
    },
    {
        Coord = {
            x = 284.5,
            y = -617,
        },
        Done = {
            50252,
        },
    },
    {
        PickUp = {
            50268,
        },
        Coord = {
            x = 287,
            y = -620,
        },
    },
    {
        Qpart = {
            [50268] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 283.5,
            y = -613.5,
        },
    },
    {
        Coord = {
            x = 287.7,
            y = -619.8,
        },
        Done = {
            50268,
        },
    },
    {
        PickUp = {
            49870,
        },
        Coord = {
            x = 287.7,
            y = -619.8,
        },
    },
    {
        Qpart = {
            [49870] = {
                1,
            },
        },
        Button = {
            ["49870-1"] = 156867,
        },
        Range = 0.69,
        Coord = {
            x = 372.6,
            y = -710,
        },
    },
    {
        Qpart = {
            [49870] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = 269.6,
            y = -989.3,
        },
    },
    {
        Qpart = {
            [49870] = {
                3,
            },
        },
        Range = 11.22,
        Coord = {
            x = 214,
            y = -994.8,
        },
    },
    {
        Range = 15.65,
        Waypoint = 49870,
        Coord = {
            x = 311.5,
            y = -938.5,
        },
    },
    {
        Range = 44.2,
        Waypoint = 49870,
        Coord = {
            x = 299.8,
            y = -773.3,
        },
    },
    {
        Coord = {
            x = 284.3,
            y = -618,
        },
        Done = {
            49870,
        },
    },
    {
        PickUp = {
            50297,
        },
        Coord = {
            x = 284.3,
            y = -618,
        },
    },
    {
        Qpart = {
            [50297] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 275.3,
            y = -817.3,
        },
    },
    {
        Qpart = {
            [50297] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 279.8,
            y = -824.8,
        },
    },
    {
        Coord = {
            x = 284.8,
            y = -617.8,
        },
        Done = {
            50297,
        },
    },
    {
        Range = 35.07,
        Waypoint = 50538,
        Coord = {
            x = 138.8,
            y = -881.3,
        },
    },
    {
        Coord = {
            x = 161.5,
            y = -945.2,
        },
        Done = {
            50538,
        },
    },
    {
        PickUp = {
            47226,
        },
        Coord = {
            x = 155.3,
            y = -951.7,
        },
    },
    {
        Range = 20.58,
        Waypoint = 47226,
        Coord = {
            x = 174.9,
            y = -1047,
        },
    },
    {
        Range = 19.15,
        Waypoint = 47226,
        Coord = {
            x = 160.8,
            y = -1129.5,
        },
    },
    {
        Range = 13.69,
        Waypoint = 47226,
        Coord = {
            x = 87.3,
            y = -1097.4,
        },
    },

    {
        Coord = {
            x = 55.7,
            y = -1019.8,
        },
        Done = {
            47226,
        },
    },
    {
        PickUp = {
            47259,
            48527,
        },
        Coord = {
            x = 55.7,
            y = -1019.8,
        },
    },
    {
        Range = 6.28,
        GetFP = 1966,
        Coord = {
            x = 18.3,
            y = -1048.0,
        },
    },
    {
        Qpart = {
            [47259] = {
                1,
            },
            [48527] = {
                1,
            },
        },
        Range = 31.57,
        Coord = {
            x = -99.4,
            y = -1068.8,
        },
    },
    {
        Coord = {
            x = 55.4,
            y = -1018.5,
        },
        Done = {
            47259,
            48527,
        },
    },
    {
        PickUp = {
            47311,
            47272,
        },
        Coord = {
            x = 55.2,
            y = -1020.8,
        },
    },
    {
        PickUp = {
            47312,
            51980,
        },
        Coord = {
            x = -127.5,
            y = -917.3,
        },
    },
    {
        Waypoint = 51980,
        Range = 15.83,
        Coord = {
            x = -118.5,
            y = -875,
        },
    },
    {
        ExtraLineText = "ASSULT_SKIP",
        Qpart = {
            [51980] = {
                1,
            },
        },
        Range = 22.92,
        Coord = {
            x = 28.5,
            y = -722.3,
        },
    },
    {
        Qpart = {
            [47312] = {
                1,
            },
        },
        Fillers = {
            [47272] = {
                1,
            },
            [47311] = {
                1,
            },
        },
        Range = 12.95,
        Coord = {
            x = -311.7,
            y = -898.7,
        },
    },
    {
        Qpart = {
            [47272] = {
                1,
            },
            [47311] = {
                1,
            },
        },
        Coord = {
            x = -288.4,
            y = -865.3,
        },
        Range = 125,
    },
    {
        Done = {
            47312,
            51980,
        },
        Coord = {
            x = -131.2,
            y = -913.5,
        },
        ExtraLineText = "ASSULT_SKIP2",
    },
    {
        Done = {
            47311,
            47272,
        },
        Coord = {
            x = 53.7,
            y = -1021.6,
        },
    },
    {
        PickUp = {
            51990,
            51998,
        },
        Coord = {
            x = 53.7,
            y = -1021.6,
        },
    },
    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = 22.1,
            y = -1023.6,
        },
    },
    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = -78.8,
            y = -1003.7,
        },
    },
    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = -82.5,
            y = -775.2,
        },
    },
    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = -32.5,
            y = -560.1,
        },
    },
    {
        Qpart = {
            [51990] = {
                1,
            },
        },
        Coord = {
            x = 28.0,
            y = -497.9,
        },
        Fillers = {
            [51998] = {
                1,
            },
        },
        Range = 160,
    },
    {
        Qpart = {
            [51998] = {
                1,
            },
        },
        Coord = {
            x = 28.0,
            y = -497.9,
        },
        Range = 160,
    },
    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = -32.5,
            y = -560.1,
        },
    },

    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = -82.5,
            y = -775.2,
        },
    },
    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = -127,
            y = -882.7,
        },
    },
    {
        Waypoint = 51990,
        Range = 15.83,
        Coord = {
            x = 22.1,
            y = -1023.6,
        },
    },
    {
        Done = {
            51990,
            51998,
        },
        Coord = {
            x = 53.7,
            y = -1021.6,
        },
    },
    {
        PickUp = {
            47418,
        },
        Coord = {
            x = 53.7,
            y = -1021.6,
        },
    },
    {
        Qpart = {
            [47418] = {
                1,
            },
        },
        Range = 1,
        Coord = {
            x = 51.9,
            y = -1015.9,
        },
    },
    {
        Done = {
            47418,
        },
        Coord = {
            x = 53.7,
            y = -1021.6,
        },
    },
    {
        PickUp = {
            47261,
        },
        Coord = {
            x = 53.7,
            y = -1021.6,
        },
    },
    {
        Qpart = {
            [47261] = {
                1,
            },
        },
        Range = 1,
        Gossip = 1,
        Coord = {
            x = -6.3,
            y = -1072.5,
        },
    },
    {
        Qpart = {
            [47261] = {
                2,
            },
        },
        Coord = {
            x = -140.4,
            y = -1164.8,
        },
        Range = 1,
    },
    {
        Waypoint = 47261,
        Coord = {
            x = -192.8,
            y = -1093.9,
        },
        Range = 20,
    },
    {
        Waypoint = 47261,
        Coord = {
            x = -242.2,
            y = -1065.9,
        },
        Range = 20,
    },
    {
        Waypoint = 47261,
        Coord = {
            x = -252.8,
            y = -1132.2,
        },
        Range = 20,
    },
    {
        Waypoint = 47261,
        Coord = {
            x = -180.6,
            y = -1256.1,
        },
        Range = 20,
    },
    {
        Waypoint = 47261,
        Coord = {
            x = 16.7,
            y = -1249.4,
        },
        Range = 20,
    },
    {
        Done = {
            47261,
        },
        Coord = {
            x = -8.1,
            y = -1072.3,
        },
    },

    {
        PickUp = {
            48581,
        },
        Coord = {
            x = -8.1,
            y = -1072.3,
        },
    },
    {
        Qpart = {
            [48581] = {
                1,
            },
        },
        Range = 1,
        Coord = {
            x = -28.6,
            y = -1148.9,
        },
    },
    {
        Done = {
            48581,
        },
        Coord = {
            x = 55.2,
            y = -1019.1,
        },
    },
    {
        PickUp = {
            47310,
        },
        Coord = {
            x = 55.2,
            y = -1019.1,
        },
    },
    {
        Qpart = {
            [47310] = {
                1,
            },
        },
        Range = 1,
        Coord = {
            x = -64.7,
            y = -996.7,
        },
    },
    {
        Done = {
            47310,
        },
        Coord = {
            x = 55.2,
            y = -1019.1,
        },
    },
    {
        ExtraLineText = "FLY_GREAT_SEAL",
        UseFlightPath = 49122,
        ETA = 40,
        Name = "The Great Seal",
        NodeID = 1959,
        Coord = {
            x = 17.3,
            y = -1047.4,
        }
    },
    {
        Waypoint = 49122,
        Range = 7.86,
        Coord = {
            x = 802.7,
            y = -1047.5,
        },
    },
    {
        Waypoint = 49122,
        Range = 8.48,
        Coord = {
            x = 820.4,
            y = -1110.6,
        },
    },
    {
        ExtraLineText = "UP_ELEVATOR",
        Waypoint = 49122,
        Range = 4.07,
        Coord = {
            x = 854.2,
            y = -1125.6,
        },
    },

    {
        ExtraLineText = "UP_ELEVATOR",
        Waypoint = 49122,
        Range = 4.07,
        Coord = {
            x = 840.7,
            y = -1121.2,
        },
    },
    {
        Waypoint = 49122,
        Range = 5,
        Coord = {
            x = 833.2,
            y = -1101,
        },
    },
    {
        Waypoint = 49122,
        Range = 4.07,
        Coord = {
            x = 820.1,
            y = -1102.0,
        },
    },
    {
        PickUp = {
            49122,
        },
        Coord = {
            x = 806,
            y = -1134.5,
        },
    },
    {
        UseGlider = 1,
        PickUp = {
            51072,
            51071,
        },
        Coord = {
            x = 1339.5,
            y = -1184.3,
        },
    },
    {
        Qpart = {
            [51072] = {
                1,
            },
        },
        Range = 32.82,
        Coord = {
            x = 1292.3,
            y = -1140.5,
        },
    },
    {
        Qpart = {
            [51071] = {
                1,
            },
        },
        Range = 34.95,
        Coord = {
            x = 1288.5,
            y = -1304,
        },
    },
    {
        Coord = {
            x = 1339.5,
            y = -1468.8,
        },
        Done = {
            51071,
            51072,
        },
    },
    {
        PickUp = {
            49919,
            49922,
        },
        Coord = {
            x = 1343.4,
            y = -1472,
        },
    },

    {
        SetHS = 49919, -- Village in the Vines
        Coord = {
            x = 1369.7,
            y = -1509.8,
        },
    },
    {
        Waypoint = 49919,
        Range = 30.55,
        Coord = {
            x = 1290.8,
            y = -1545,
        },
    },
    {
        Waypoint = 49919,
        Coord = {
            x = 1359.7,
            y = -1645,
        },
        Range = 23.84,
    },
    {
        PickUp = {
            49920,
        },
        Coord = {
            x = 1460,
            y = -1698.5,
        },
        Fillers = {
            [49918] = { -- Bonus Objective
                1,
            },
        },
    },
    {
        ExtraLineText = "KAJAMITE",
        Qpart = {
            [49920] = {
                1,
            },
            [49919] = {
                1,
            },
        },
        Fillers = {
            [49918] = {
                1,
            },
        },
        Range = 34.31,
        Coord = {
            x = 1460,
            y = -1698.5,
        },
    },
    {
        ExtraLineText = "KAJAMITE",
        Qpart = {
            [49922] = {
                1,
            },
        },
        Fillers = {
            [49919] = {
                1,
            },
            [49918] = {
                1,
            },
            [49920] = {
                1,
            },
        },
        Range = 24.09,
        Coord = {
            x = 1741.5,
            y = -1511,
        },
    },
    {
        Done = {
            49920,
        },
        Coord = {
            x = 1697.0,
            y = -1577.8,
        },
    },
    {
        Qpart = {
            [49918] = {
                1,
            },
        },
        Range = 63.67,
        Coord = {
            x = 1689.5,
            y = -1553.9,
        },
    },
    {
        UseHS = 49919, -- to Village in the Vines
        HSSteps = 4,
        Coord = {
            x = 1689.5,
            y = -1553.9,
        },
    },
    {
        Done = {
            49919,
            49922,
        },
        Coord = {
            x = 1340.7,
            y = -1471.4,
        },
    },

    {
        Waypoint = 49122,
        Range = 55,
        Coord = {
            x = 1245,
            y = -1550.5,
        },
    },
    {
        Waypoint = 49122,
        Range = 21.67,
        Coord = {
            x = 1276.8,
            y = -1584,
        },
    },
    {
        Waypoint = 49122,
        Range = 21.67,
        Coord = {
            x = 1535,
            y = -1861.5,
        },
    },
    {
        GetFP = 2009,
        Range = 5.0,
        Coord = {
            x = 1630.5,
            y = -2023.3,
        },
    },
    {
        Done = {
            49122,
        },
        Coord = {
            x = 1654.2,
            y = -2030.8,
        },
    },
    {
        PickUp = {
            49144,
            49145,
        },
        Coord = {
            x = 1657,
            y = -2030.4,
        },
    },
    {
        PickUp = {
            49146,
        },
        Coord = {
            x = 1719,
            y = -2031.9,
        },
    },
    {
        Qpart = {
            [49146] = {
                1,
            },
        },
        Fillers = {
            [49145] = {
                1,
            },
            [49144] = {
                1,
            },
        },
        Button = {
            ["49145-1"] = 153524,
        },
        Range = 5.75,
        Coord = {
            x = 1852,
            y = -2025.6,
        },
    },
    {
        Qpart = {
            [49146] = {
                3,
            },
        },
        Fillers = {
            [49145] = {
                1,
            },
            [49144] = {
                1,
            },
        },
        Button = {
            ["49145-1"] = 153524,
        },
        Range = 0.69,
        Coord = {
            x = 1833,
            y = -2143.9,
        },
    },
    {
        Qpart = {
            [49146] = {
                2,
            },
        },
        Fillers = {
            [49145] = {
                1,
            },
            [49144] = {
                1,
            },
        },
        Button = {
            ["49145-1"] = 153524,
        },
        Range = 0.69,
        Coord = {
            x = 1750.3,
            y = -2112.5,
        },
    },

    {
        Qpart = {
            [49145] = {
                1,
            },
            [49144] = {
                1,
            },
        },
        Button = {
            ["49145-1"] = 153524,
        },
        Range = 24.29,
        Coord = {
            x = 1751.5,
            y = -2112.7,
        },
    },
    {
        Waypoint = 49144,
        Range = 18.47,
        Coord = {
            x = 1715.3,
            y = -2030.6,
        },
    },
    {
        Done = {
            49145,
            49144,
            49146,
        },
        Coord = {
            x = 1652.7,
            y = -2029,
        },
    },
    {
        PickUp = {
            49148,
            49147,
            49149,
        },
        Coord = {
            x = 1653.9,
            y = -2029.5,
        },
    },
    {
        QpartPart = {
            [49149] = {
                1,
            },
        },
        TrigText = "1/5",
        Fillers = {
            [49148] = {
                1,
            },
        },
        Range = 0.5,
        Coord = {
            x = 1713.8,
            y = -2109.2,
        },
    },
    {
        QpartPart = {
            [49149] = {
                1,
            },
        },
        TrigText = "2/5",
        Fillers = {
            [49148] = {
                1,
            },
            [49147] = {
                1,
            },
        },
        Range = 0.5,
        Coord = {
            x = 1650.2,
            y = -2178.2,
        },
    },
    {
        QpartPart = {
            [49149] = {
                1,
            },
        },
        TrigText = "3/5",
        Fillers = {
            [49148] = {
                1,
            },
            [49147] = {
                1,
            },
        },
        Range = 0.5,
        Coord = {
            x = 1751.5,
            y = -2209.7,
        },
    },
    {
        QpartPart = {
            [49149] = {
                1,
            },
        },
        TrigText = "4/5",
        Fillers = {
            [49148] = {
                1,
            },
            [49147] = {
                1,
            },
        },
        Range = 0.5,
        Coord = {
            x = 1695.2,
            y = -2294.7,
        },
    },
    {
        Qpart = {
            [49147] = {
                1,
            },
        },
        Fillers = {
            [49148] = {
                1,
            },
            [49149] = {
                1,
            },
        },
        Range = 18.13,
        Coord = {
            x = 1637.7,
            y = -2258.9,
        },
    },
    {
        Waypoint = 49147,
        Range = 15.03,
        Coord = {
            x = 1664.2,
            y = -2420.2,
        },
        Fillers = {
            [49148] = {
                1,
            },
            [49149] = {
                1,
            },
        },
    },
    {
        QpartPart = {
            [49149] = {
                1,
            },
        },
        TrigText = "5/5",
        Fillers = {
            [49148] = {
                1,
            },
        },
        Range = 0.06,
        Coord = {
            x = 1692.2,
            y = -2388,
        },
    },
    {
        Qpart = {
            [49147] = {
                2,
            },
        },
        Fillers = {
            [49148] = {
                1,
            },
            [49149] = {
                1,
            },
        },
        Range = 13.46,
        Coord = {
            x = 1820.3,
            y = -2370,
        },
    },
    {
        Qpart = {
            [49149] = {
                1,
            },
            [49148] = {
                1,
            },
        },
        Range = 33.69,
        Coord = {
            x = 1815.2,
            y = -2374.7,
        },
    },
    {
        Done = {
            49148,
            49147,
            49149,
        },
        Coord = {
            x = 1512.9,
            y = -2258.5,
        },
    },
    {
        PickUp = {
            49309,
        },
        Coord = {
            x = 1512.9,
            y = -2258.5,
        },
    },
    {
        Waypoint = 49309,
        Range = 11.1,
        Coord = {
            x = 1469.4,
            y = -2266.5,
        },
    },
    {
        Qpart = {
            [49309] = {
                1,
            },
        },
        Range = 9.13,
        Coord = {
            x = 1465,
            y = -2305.2,
        },
    },
    {
        Done = {
            49309,
        },
        Coord = {
            x = 1511.4,
            y = -2258,
        },
    },
    {
        PickUp = {
            49310,
        },
        Coord = {
            x = 1511.4,
            y = -2258,
        },
    },
    {
        Qpart = {
            [49310] = {
                1,
            },
        },
        Range = 7.46,
        Coord = {
            x = 1522,
            y = -2250.7,
        },
    },
    {
        Coord = {
            x = 819.2,
            y = -1124.5,
        },
        Done = {
            49310,
        },
    },
    {
        PickUp = {
            51101,
            47509,
        },
        Coord = {
            x = 819.7,
            y = -1125.6,
        },
    },
    {
        SetHS = 47509,
        Coord = {
            x = 805.7,
            y = -1125.5,
        },
    },
    {
        Waypoint = 47509,
        Range = 8.68,
        Coord = {
            x = 808.7,
            y = -1049.9,
        },
    },
    {
        UseGlider = 1,
        Done = {
            47509,
        },
        Coord = {
            x = 1011.2,
            y = -667.3,
        },
    },
    {
        PickUp = {
            47897,
            47915,
        },
        Coord = {
            x = 1011.2,
            y = -667.3,
        },
    },
    {
        Waypoint = 47915,
        Coord = {
            x = 1042,
            y = -605.5,
        },
        Range = 16.56,
        Fillers = {
            [47897] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47915] = {
                1,
            },
        },
        Fillers = {
            [47897] = {
                1,
            },
        },
        Range = 6.9,
        Coord = {
            x = 987.4,
            y = -596.5,
        },
    },
    {
        Qpart = {
            [47897] = {
                1,
            },
        },
        Range = 22.6,
        Coord = {
            x = 994.4,
            y = -605,
        },
    },
    {
        Coord = {
            x = 1105,
            y = -520.5,
        },
        Done = {
            47897,
            47915,
        },
    },
    {
        PickUp = {
            47520,
            47518,
        },
        Coord = {
            x = 1105,
            y = -520.5,
        },
    },
    {
        Range = 12.12,
        Waypoint = 47518,
        Coord = {
            x = 1030.3,
            y = -438.5,
        },
        Fillers = {
            [47520] = {
                1,
            },
        },
    },
    {
        Range = 7.16,
        Waypoint = 47518,
        Coord = {
            x = 1045.7,
            y = -414.5,
        },
        Fillers = {
            [47520] = {
                1,
            },
        },
    },
    {
        Range = 4.97,
        Waypoint = 47518,
        Coord = {
            x = 1034,
            y = -402.4,
        },
        Fillers = {
            [47520] = {
                1,
            },
        },
    },
    {
        Range = 5.23,
        Waypoint = 47518,
        Coord = {
            x = 953.6,
            y = -478,
        },
        Fillers = {
            [47520] = {
                1,
            },
        },
    },
    {
        Range = 5.38,
        Waypoint = 47518,
        Coord = {
            x = 926.1,
            y = -498.4,
        },
        Fillers = {
            [47520] = {
                1,
            },
        },
    },
    {
        Range = 9.15,
        Waypoint = 47518,
        Coord = {
            x = 919.4,
            y = -567.8,
        },
        Fillers = {
            [47520] = {
                1,
            },
        },
    },
    {
        Range = 8.96,
        Waypoint = 47518,
        Coord = {
            x = 913.5,
            y = -510.8,
        },
        Fillers = {
            [47520] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47520] = {
                1,
            },
            [47518] = {
                1,
            },
        },
        Range = 12.85,
        Coord = {
            x = 984.2,
            y = -400.2,
        },
    },
    {
        Coord = {
            x = 982.4,
            y = -400.9,
        },
        Done = {
            47520,
            47518,
        },
    },
    {
        PickUp = {
            47521,
        },
        Coord = {
            x = 1012.7,
            y = -439.3,
        },
    },
    {
        Qpart = {
            [47521] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = 1014.2,
            y = -448.4,
        },
    },
    {
        Coord = {
            x = 1419.2,
            y = -292.9,
        },
        Done = {
            47521,
        },
    },
    {
        PickUp = {
            47522,
            47963,
        },
        Coord = {
            x = 1419.7,
            y = -290.7,
        },
    },
    {
        Range = 13.17,
        Waypoint = 47963,
        Coord = {
            x = 1436.3,
            y = -402.9,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Range = 12.29,
        Waypoint = 47963,
        Coord = {
            x = 1394.4,
            y = -434.4,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47963] = {
                1,
            },
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
        Range = 14.86,
        Coord = {
            x = 1303.7,
            y = -463.5,
        },
    },
    {
        Coord = {
            x = 1298,
            y = -467.5,
        },
        Done = {
            47963,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Range = 14.64,
        Waypoint = 47522,
        Coord = {
            x = 1419.7,
            y = -426.7,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47522] = {
                1,
            },
        },
        Range = 10.65,
        Coord = {
            x = 1615.8,
            y = -433.5,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Coord = {
            x = 1613,
            y = -430.8,
        },
        Done = {
            47522,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        PickUp = {
            47528,
        },
        Coord = {
            x = 1610.7,
            y = -432,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Range = 16.34,
        Waypoint = 47528,
        Coord = {
            x = 1594.8,
            y = -391.9,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Range = 6.81,
        Waypoint = 47528,
        Coord = {
            x = 1670,
            y = -253.4,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47528] = {
                1,
                2,
            },
        },
        Range = 11.87,
        Coord = {
            x = 1720.9,
            y = -194,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Range = 12.93,
        Waypoint = 47528,
        Coord = {
            x = 1668.4,
            y = -252.4,
        },
        Fillers = {
            [47527] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47527] = {
                1,
            },
        },
        Range = 56.49,
        Coord = {
            x = 1653,
            y = -269.2,
        },
    },
    {
        Coord = {
            x = 1601.4,
            y = -133,
        },
        Done = {
            47528,
        },
    },
    {
        GetFP = 2045,
        Range = 5.0,
        Coord = {
            x = 1502.8,
            y = -103.3,
        },
    },
    {
        PickUp = {
            49679,
            49678,
            49680,
        },
        Coord = {
            x = 1708.7,
            y = -33.8,
        },
    },
    {
        QpartPart = {
            [49678] = {
                1,
            },
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "1/4",
        Coord = {
            x = 1789.8,
            y = 2.5,
        },
    },
    {
        PickUp = {
            49681,
        },
        Coord = {
            x = 1799.3,
            y = 62.1,
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49681] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1799.3,
            y = 64.1,
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
    },
    {
        QpartPart = {
            [49678] = {
                1,
            },
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "2/4",
        Coord = {
            x = 1816.3,
            y = 93.4,
        },
    },
    {
        QpartPart = {
            [49678] = {
                1,
            },
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "3/4",
        Coord = {
            x = 1848.5,
            y = 83.2,
        },
    },
    {
        QpartPart = {
            [49678] = {
                1,
            },
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "4/4",
        Coord = {
            x = 1891.5,
            y = 21.8,
        },
    },
    {
        Qpart = {
            [49681] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1871.5,
            y = -109,
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
    },
    {
        Waypoint = 49678,
        Range = 7.88,
        Coord = {
            x = 1899.7,
            y = -91,
        },
        Fillers = {
            [49679] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49680] = {
                1,
            },
            [49679] = {
                1,
            },
        },
        Range = 4.7,
        Coord = {
            x = 1885.4,
            y = -108.4,
        },
    },
    {
        Done = {
            49679,
            49678,
            49680,
            49681,
        },
        Coord = {
            x = 1706.8,
            y = -35.3,
        },
    },
    {
        Range = 16.96,
        Waypoint = 49768,
        Coord = {
            x = 1558.2,
            y = -93.9,
        },
    },
    {
        Waypoint = 49768,
        Range = 17.43,
        Coord = {
            x = 1473,
            y = -149.7,
        },
    },
    {
        Waypoint = 49768,
        Range = 13.39,
        Coord = {
            x = 1409.5,
            y = -166.9,
        },
    },
    {
        UseGlider = 1,
        Waypoint = 49768,
        Range = 19.09,
        Coord = {
            x = 1336.4,
            y = -153.7,
        },
    },
    {
        UseGlider = 1,
        Waypoint = 49768,
        Range = 27.13,
        Coord = {
            x = 353.2,
            y = 119,
        },
    },
    {
        Waypoint = 49768,
        Range = 19.43,
        Coord = {
            x = 273.2,
            y = 162.1,
        },
    },
    {
        Waypoint = 49768,
        Range = 20.75,
        Coord = {
            x = 195.5,
            y = 317.8,
        },
    },
    {
        GetFP = 1965,
        Range = 5.0,
        Coord = {
            x = 106.8,
            y = 386.3,
        },
    },
    {
        PickUp = {
            47706,
            51091,
        },
        Coord = {
            x = 0.7,
            y = 368.8,
        },
    },
    {
        Done = {
            49768,
        },
        Coord = {
            x = -2.8,
            y = 378.7,
        },
    },
    {
        PickUp = {
            47584,
            50466,
            47583,
        },
        Coord = {
            x = -3.8,
            y = 380.7,
        },
    },
    {
        PickUp = {
            47585,
        },
        Coord = {
            x = -116.1,
            y = 284.2,
        },
    },
    {
        Qpart = {
            [47585] = {
                1,
            },
        },
        Fillers = {
            [47584] = {
                1,
            },
            [47583] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -269.3,
            y = 133.9,
        },
    },
    {
        Qpart = {
            [47706] = {
                1,
            },
        },
        Fillers = {
            [47584] = {
                1,
            },
            [47583] = {
                1,
            },
        },
        Range = 46.89,
        Coord = {
            x = -336.8,
            y = 199.6,
        },
    },
    {
        Waypoint = 50466,
        Range = 29.59,
        Coord = {
            x = -289.7,
            y = 40.7,
        },
    },
    {
        Qpart = {
            [50466] = {
                1,
            },
        },
        Fillers = {
            [47584] = {
                1,
            },
            [47583] = {
                1,
            },
        },
        Range = 27.4,
        Coord = {
            x = -288.8,
            y = -113.1,
        },
    },
    {
        Qpart = {
            [47585] = {
                2,
            },
        },
        Fillers = {
            [47584] = {
                1,
            },
            [47583] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -29.4,
            y = -33.8,
        },
    },
    {
        Qpart = {
            [51091] = {
                1,
                2,
            },
        },
        Fillers = {
            [47584] = {
                1,
            },
            [47583] = {
                1,
            },
        },
        Range = 22.98,
        Coord = {
            x = 482.8,
            y = -41.3,
        },
    },
    {
        Qpart = {
            [47584] = {
                1,
            },
            [47583] = {
                1,
            },
        },
        Range = 28.86,
        Coord = {
            x = 37.2,
            y = -28,
        },
    },
    {
        Done = {
            47583,
        },
        Coord = {
            x = -4.9,
            y = 313.8,
        },
    },
    {
        Done = {
            47584,
        },
        Coord = {
            x = -45.5,
            y = 362.1,
        },
    },
    {
        Done = {
            47585,
            50466,
            51091,
            47706,
        },
        Coord = {
            x = -2.5,
            y = 383.6,
        },
    },
    {
        PickUp = {
            47586,
        },
        Coord = {
            x = -2.5,
            y = 383.6,
        },
    },
    {
        Waypoint = 47586,
        Range = 12.66,
        Coord = {
            x = 107.7,
            y = 386.8,
        },
    },
    {
        Qpart = {
            [47586] = {
                1,
            },
        },
        Fillers = {
            [50178] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 424.2,
            y = 292.1,
        },
    },
    {
        Qpart = {
            [47586] = {
                2,
            },
        },
        Fillers = {
            [50178] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 506.3,
            y = 366.5,
        },
    },
    {
        Qpart = {
            [47586] = {
                3,
            },
        },
        Fillers = {
            [50178] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 435.8,
            y = 428.2,
        },
    },
    {
        Done = {
            47586,
        },
        Coord = {
            x = 340.8,
            y = 469.6,
        },
    },
    {
        PickUp = {
            47587,
        },
        Coord = {
            x = 337.6,
            y = 469,
        },
    },
    {
        Qpart = {
            [47587] = {
                1,
            },
        },
        Range = 9.76,
        Coord = {
            x = 375.6,
            y = 484.3,
        },
    },
    {
        Done = {
            47587,
        },
        Coord = {
            x = 337.6,
            y = 469,
        },
    },
    {
        Qpart = {
            [50178] = {
                1,
            },
        },
        Range = 67,
        Coord = {
            x = 375.1,
            y = 349,
        },
    },
    {
        Waypoint = 51101,
        Range = 7.57,
        Coord = {
            x = -248,
            y = 284.2,
        },
    },
    {
        UseGlider = 1,
        Waypoint = 51101,
        Range = 63.82,
        Coord = {
            x = -380.8,
            y = 183.6,
        },
    },
    {
        Waypoint = 51101,
        Range = 63.82,
        Coord = {
            x = -735.2,
            y = 283,
        },
    },
    {
        Waypoint = 51101,
        Range = 37.12,
        Coord = {
            x = -803.7,
            y = 455,
        },
    },
    {
        Done = {
            51101,
        },
        Coord = {
            x = -781,
            y = 463.7,
        },
    },
    {
        PickUp = {
            51680,
        },
        Coord = {
            x = -781,
            y = 463.7,
        },
    },
    {
        Qpart = {
            [51680] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        Qpart = {
            [51680] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        Done = {
            51680,
        },
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        PickUp = {
            47735,
            47739,
        },
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        PickUp = {
            50235,
        },
        Coord = {
            x = -780.7,
            y = 462.8,
        },
    },
    {
        GetFP = 1975,
        Range = 11.57,
        Coord = {
            x = -838,
            y = 514.5,
        },
    },
    {
        Qpart = {
            [47735] = {
                2,
            },
        },
        Fillers = {
            [50235] = {
                1,
            },
            [47739] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -940,
            y = 632.5,
        },
    },
    {
        Qpart = {
            [47735] = {
                1,
            },
        },
        Fillers = {
            [50235] = {
                1,
            },
            [47739] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -1043.5,
            y = 447.3,
        },
    },
    {
        PickUp = {
            47733,
        },
        Coord = {
            x = -1006.7,
            y = 434.6,
        },
        Fillers = {
            [50235] = {
                1,
            },
            [47739] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [50235] = {
                1,
            },
        },
        Coord = {
            x = -1005.9,
            y = 537.4,
        },
        Range = 168,
        Fillers = {
            [47739] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47733] = {
                1,
            },
        },
        Fillers = {
            [47739] = {
                1,
            },
        },
        Range = 20.54,
        Coord = {
            x = -938.3,
            y = 235.1,
        },
    },
    {
        Qpart = {
            [47735] = {
                3,
            },
        },
        Fillers = {
            [47739] = {
                1,
            },
        },
        Range = 10.41,
        Coord = {
            x = -1019,
            y = 160.6,
        },
    },
    {
        Qpart = {
            [47739] = {
                1,
            },
        },
        Range = 25.55,
        Coord = {
            x = -961.8,
            y = 333.8,
        },
    },
    {
        Waypoint = 47739,
        Range = 31.64,
        Coord = {
            x = -801.5,
            y = 462.3,
        },
    },
    {
        Done = {
            50235,
            47733,
        },
        Coord = {
            x = -782,
            y = 464.1,
        },
    },
    {
        Done = {
            47739,
            47735,
        },
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        PickUp = {
            51677,
        },
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        Qpart = {
            [51677] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        ExtraLineText = "JOLS_COMMANDS",
        Qpart = {
            [51677] = {
                2,
            },
        },
        Gossip = 1,
        Range = 5,
        Coord = {
            x = -769.5,
            y = 479.7,
        },
    },
    {
        Done = {
            51677,
        },
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        PickUp = {
            47738,
        },
        Coord = {
            x = -763.6,
            y = 471.7,
        },
    },
    {
        Range = 8.7,
        Waypoint = 47738,
        Coord = {
            x = -777.5,
            y = 473,
        },
    },
    {
        Qpart = {
            [47738] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = -794.5,
            y = 633.2,
        },
    },
    {
        Qpart = {
            [47738] = {
                2,
            },
        },
        Gossip = 1,
        GossipOptionID = 48358,
        Range = 0.69,
        Coord = {
            x = -808,
            y = 633,
        },
    },
    {
        ETA = 69,
        Qpart = {
            [47738] = {
                3,
            },
        },
        Range = 0.75,
        Coord = {
            x = -801.8,
            y = 632.1,
        },
    },
    {
        Range = 12.72,
        Waypoint = 47738,
        Coord = {
            x = -776.2,
            y = 473.8,
        },
    },
    {
        Qpart = {
            [47738] = {
                4,
            },
        },
        Range = 0.69,
        Coord = {
            x = -759.5,
            y = 474.8,
        },
    },
    {
        Coord = {
            x = -778.8,
            y = 469.7,
        },
        Done = {
            47738,
        },
    },
    {
        PickUp = {
            51678,
            47742,
            51679,
        },
        Coord = {
            x = -778.8,
            y = 469.7,
        },
    },
    {
        Range = 9.46,
        Waypoint = 51679,
        Coord = {
            x = -1128.5,
            y = 223,
        },
    },
    {
        Range = 7.07,
        Waypoint = 51679,
        Coord = {
            x = -1135,
            y = 229.1,
        },
    },
    {
        Range = 4.73,
        Waypoint = 51678,
        Coord = {
            x = -1154,
            y = 238.1,
        },
    },
    {
        Qpart = {
            [51679] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = -1167.9,
            y = 264.3,
        },
    },
    {
        Qpart = {
            [51679] = {
                2,
                3,
            },
        },
        Fillers = {
            [47742] = {
                1,
            },
        },
        Range = 30.75,
        Coord = {
            x = -1167.9,
            y = 264.3,
        },
    },
    {
        ExtraLineText = "TOP_BOAT",
        Qpart = {
            [51678] = {
                1,
            },
        },
        Range = 4.08,
        Coord = {
            x = -1170.8,
            y = 271.3,
        },
        Fillers = {
            [47742] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47742] = {
                1,
            },
        },
        Range = 17.87,
        Coord = {
            x = -1170.5,
            y = 270.5,
        },
    },
    {
        Coord = {
            x = -780.5,
            y = 468.2,
        },
        Done = {
            51679,
            51678,
            47742,
        },
    },
    {
        PickUp = {
            47737,
        },
        Coord = {
            x = -780.5,
            y = 468.2,
        },
    },
    {
        Range = 60.93,
        Waypoint = 47737,
        Coord = {
            x = -699.8,
            y = 251.6,
        },
    },
    {
        Coord = {
            x = -384.3,
            y = 192.5,
        },
        Done = {
            47737,
        },
    },
    {
        PickUp = {
            47736,
            47740,
        },
        Coord = {
            x = -387.7,
            y = 188.3,
        },
    },

    {
        Qpart = {
            [47740] = {
                1,
            },
        },
        Fillers = {
            [47736] = {
                1,
            },
            [47797] = {
                1,
            },
        },
        Range = 9.59,
        Coord = {
            x = -406.5,
            y = 31,
        },
    },
    {
        Qpart = {
            [47740] = {
                3,
            },
        },
        Fillers = {
            [47736] = {
                1,
            },
            [47797] = {
                1,
            },
        },
        Range = 10.75,
        Coord = {
            x = -537.3,
            y = 86.7,
        },
    },
    {
        Range = 12.33,
        Waypoint = 47740,
        Coord = {
            x = -472.7,
            y = 12.5,
        },
        Fillers = {
            [47736] = {
                1,
            },
            [47797] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47740] = {
                2,
            },
        },
        Fillers = {
            [47736] = {
                1,
            },
            [47797] = {
                1,
            },
        },
        Range = 8.62,
        Coord = {
            x = -529.7,
            y = -73.4,
        },
    },
    {
        Qpart = {
            [47736] = {
                1,
            },
            [47797] = {
                1,
            },
        },
        Range = 29.63,
        Coord = {
            x = -531.7,
            y = -75.9,
        },
    },
    {
        Done = {
            47740,
            47736,
        },
        Coord = {
            x = -623.2,
            y = -26.9,
        },
    },
    {
        PickUp = {
            47734,
        },
        Coord = {
            x = -624.8,
            y = -26.9,
        },
    },
    {
        Qpart = {
            [47734] = {
                1,
            },
        },
        Range = 7.95,
        Coord = {
            x = -651.5,
            y = 70,
        },
    },
    {
        Qpart = {
            [47734] = {
                2,
            },
        },
        Range = 6.06,
        Coord = {
            x = -648.5,
            y = -111,
        },
    },
    {
        Coord = {
            x = -627,
            y = -28.4,
        },
        Done = {
            47734,
        },
    },
    {
        PickUp = {
            47741,
        },
        Coord = {
            x = -627,
            y = -28.4,
        },
    },
    {
        ExtraLineText = "REDUCED_DAMAGE_INFO_1",
        Qpart = {
            [47741] = {
                1,
            },
        },
        Range = 8.39,
        Coord = {
            x = -717.8,
            y = -21.4,
        },
    },
    {
        Qpart = {
            [47741] = {
                2,
            },
        },
        Range = 0.5,
        Coord = {
            x = -725.7,
            y = -24.7,
        },
    },
    {
        Waypoint = 47741,
        Coord = {
            x = -727.2,
            y = -27.1,
        },
        Range = 0.5,
        Gossip = 1,
        GossipOptionID = 47761,
        ExtraLineText = "TALK_KING_RASTAKHAN",
    },
    {
        Waypoint = 47741,
        Range = 20.85,
        Coord = {
            x = -574.2,
            y = -159.7,
        },
    },
    {
        Waypoint = 47741,
        Range = 27.85,
        Coord = {
            x = -378.8,
            y = -277.4,
        },
    },
    {
        Done = {
            47741,
        },
        Coord = {
            x = -291.9,
            y = -305.7,
        },
    },
    {
        PickUp = {
            51111,
        },
        Coord = {
            x = -293.9,
            y = -306.9,
        },
    },
    {
        Coord = {
            x = -280.4,
            y = -290.7,
        },
        UseFlightPath = 51111,
        Name = "The Great Seal",
        NodeID = 1959,
    },
    {
        Waypoint = 51111,
        Range = 13.01,
        Coord = {
            x = 801.2,
            y = -1049,
        },
    },
    {
        Done = {
            51111,
        },
        Coord = {
            x = 819.4,
            y = -1124.5,
        },
    },
    {
        PickUp = {
            49421,
        },
        Coord = {
            x = 819.9,
            y = -1125,
        },
        LeaveQuest = 52210,
    },
    {
        LeaveQuest = 52210,
        Range = 8.86,
        Waypoint = 49421,
        Coord = {
            x = 809.2,
            y = -1052.6,
        },
    },
    {
        UseGlider = 1,
        LeaveQuest = 52210,
        Coord = {
            x = 1115.5,
            y = -771.3,
        },
        Done = {
            49421,
        },
    },
    {
        PickUp = {
            49965,
        },
        LeaveQuest = 52210,
        Coord = {
            x = 1115.5,
            y = -771.3,
        },
    },
    {
        ExtraLineText = "RUN_FOREST_RUN",
        LeaveQuest = 52210,
        Range = 14.92,
        Waypoint = 49965,
        Coord = {
            x = 1229.3,
            y = -878.8,
        },
    },
    {
        LeaveQuest = 52210,
        Range = 10.86,
        Waypoint = 49965,
        Coord = {
            x = 1331,
            y = -891,
        },
    },
    {
        LeaveQuest = 52210,
        Range = 20.73,
        Waypoint = 49965,
        Coord = {
            x = 1411.8,
            y = -1160,
        },
    },
    {
        LeaveQuest = 52210,
        Range = 8.37,
        Waypoint = 49965,
        Coord = {
            x = 1443.7,
            y = -1217.1,
        },
    },
    {
        LeaveQuest = 52210,
        Range = 19.01,
        Waypoint = 49965,
        Coord = {
            x = 1542.7,
            y = -1154.5,
        },
    },
    {
        Qpart = {
            [49965] = {
                1,
            },
        },
        Range = 2.61,
        Coord = {
            x = 1540.4,
            y = -1121.1,
        },
    },
    {
        Coord = {
            x = 1540,
            y = -1121.3,
        },
        Done = {
            49965,
        },
    },
    {
        PickUp = {
            49422,
            49424,
        },
        Coord = {
            x = 1536.9,
            y = -1122.6,
        },
    },
    {
        Range = 8.28,
        GetFP = 2027,
        Coord = {
            x = 1495.4,
            y = -1135.6,
        },
    },
    {
        Qpart = {
            [49424] = {
                3,
            },
        },
        Fillers = {
            [49422] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1578.7,
            y = -1032,
        },
    },
    {
        Range = 9.41,
        Waypoint = 49424,
        Coord = {
            x = 1498.5,
            y = -999.7,
        },
        Fillers = {
            [49422] = {
                1,
            },
        },
    },
    {
        Range = 8.69,
        Waypoint = 49422,
        Coord = {
            x = 1502.7,
            y = -959.2,
        },
        Fillers = {
            [49422] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49424] = {
                2,
            },
        },
        Fillers = {
            [49422] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1561.5,
            y = -911.3,
        },
    },
    {
        Range = 7.77,
        Waypoint = 49422,
        Coord = {
            x = 1504,
            y = -912.8,
        },
        Fillers = {
            [49422] = {
                1,
            },
        },
    },
    {
        Range = 6.69,
        Waypoint = 49422,
        Coord = {
            x = 1501.5,
            y = -868.7,
        },
        Fillers = {
            [49422] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49424] = {
                1,
            },
        },
        Fillers = {
            [49422] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1584.8,
            y = -843.8,
        },
    },
    {
        Qpart = {
            [49422] = {
                1,
            },
        },
        Range = 15.57,
        Coord = {
            x = 1575.5,
            y = -844.2,
        },
    },
    {
        Coord = {
            x = 1508,
            y = -763.8,
        },
        Done = {
            49422,
            49424,
        },
    },
    {
        PickUp = {
            49425,
        },
        Coord = {
            x = 1508,
            y = -764.8,
        },
    },
    {
        Qpart = {
            [49425] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = 1508,
            y = -760,
        },
    },
    {
        Qpart = {
            [49425] = {
                2,
            },
        },
        Range = 72.39,
        Coord = {
            x = 1524.3,
            y = -820.5,
        },
    },
    {
        Coord = {
            x = 2009.5,
            y = -838.5,
        },
        Done = {
            49425,
        },
    },
    {
        Qpart = {
            [49426] = {
                1,
            },
        },
        Range = 0.61,
        Coord = {
            x = 2152.6,
            y = -850,
        },
    },
    {
        Qpart = {
            [49426] = {
                2,
            },
        },
        Gossip = 1,
        GossipOptionID = 48457,
        Range = 0.69,
        Coord = {
            x = 2149.1,
            y = -850.5,
        },
    },
    {
        Qpart = {
            [49426] = {
                3,
            },
        },
        Gossip = 101,
        GossipOptionID = 48876,
        Range = 6.69,
        Coord = {
            x = 2158.8,
            y = -848.7,
        },
    },
    {
        Waypoint = 49426,
        Range = 8,
        Coord = {
            x = 2144.6,
            y = -754,
        },
    },
    {
        Qpart = {
            [49426] = {
                3,
            },
        },
        Range = 0.09,
        Coord = {
            x = 2093.9,
            y = -743.7,
        },
    },
    {
        Coord = {
            x = 2093.9,
            y = -743.7,
        },
        Done = {
            49426,
        },
    },
    {
        PickUp = {
            50963,
        },
        LeaveQuest = 49901,
        Coord = {
            x = 2093.9,
            y = -743.7,
        },
    },
    {
        UseHS = 50963,
        Coord = {
            x = 2093.9,
            y = -743.7,
        },
        LeaveQuest = 49901,
    },
    {
        Waypoint = 50963,
        Range = 4.36,
        Coord = {
            x = 810.6,
            y = -1137.5,
        },
    },
    {
        Done = {
            50963,
        },
        LeaveQuest = 52210,
        LeaveQuest = 49901,
        Coord = {
            x = 819.2,
            y = -1120.4,
        },
    },
    {
        PickUp = {
            47512,
        },
        LeaveQuest = 52210,
        LeaveQuest = 49901,
        Coord = {
            x = 820,
            y = -1122.8,
        },
    },
    {
        Done = {
            47512,
        },
        Coord = {
            x = 819,
            y = -1120.5,
        },
    },
    {
        PickUp = {
            47103,
        },
        Coord = {
            x = 819.2,
            y = -1120.9,
        },
    },
    {
        Waypoint = 47103,
        Range = 5.68,
        Coord = {
            x = 801.7,
            y = -1052.8,
        },
    },
    {
        Done = {
            47103,
        },
        Coord = {
            x = 757.7,
            y = -1037.4,
        },
    },
    {
        PickUp = {
            48535,
        },
        Coord = {
            x = 759,
            y = -1037.6,
        },
    },
    {
        Qpart = {
            [48535] = {
                1,
            },
        },
        Gossip = 2,
        GossipOptionID = 48274,
        Range = 5.69,
        Coord = {
            x = 751.9,
            y = -1034.9,
        },
    },
    {
        UseGlider = 1,
        Coord = {
            x = 1188.2,
            y = 514.5,
        },
        Done = {
            48535,
        },
        Zone = 863,
    },
    {
        ZoneDoneSave = 1,
    },
}
-- Nazmir
APR.RouteQuestStepList["863-Nazmir"] = {
    {
        Done = {
            48535,
        },
        Coord = {
            x = 1188.2,
            y = 514.5,
        },
        LeaveQuests = {
            52210,
            49901,
        },
    },
    {
        PickUp = {
            47105,
        },
        Coord = {
            x = 1188.2,
            y = 514.5,
        },
        LeaveQuests = {
            52210,
            49901,
        },
    },
    {
        ExtraLineText = "CLICK_BUFFS_IN_ZONE",
        Qpart = {
            [47105] = {
                1,
            },
        },
        Range = 7.2,
        Coord = {
            x = 967.2,
            y = 727.7,
        },
    },
    {
        ExtraLineText = "CLICK_BUFFS_IN_ZONE",
        Done = {
            47105,
        },
        Coord = {
            x = 965,
            y = 735.2,
        },
    },
    {
        PickUp = {
            47130,
            47264,
        },
        Coord = {
            x = 966.7,
            y = 733.2,
        },
    },
    {
        Qpart = {
            [47130] = {
                1,
            },
            [47264] = {
                1,
            },
        },
        Button = {
            ["47130-1"] = 154724,
        },
        ButtonSpellId = {
            [241992] = "47130-1",
        },
        ButtonCooldown = {
            [241992] = 5,
        },
        Range = 34.06,
        Coord = {
            x = 901.4,
            y = 719.4,
        },
    },
    {
        Coord = {
            x = 1048.3,
            y = 908.6,
        },
        Done = {
            47264,
            47130,
        },
    },
    {
        PickUp = {
            47262,
        },
        Coord = {
            x = 1048.3,
            y = 908.6,
        },
    },
    {
        Bloodlust = 1,
        Qpart = {
            [47262] = {
                1,
            },
        },
        Range = 10.37,
        Coord = {
            x = 1084.5,
            y = 1015.9,
        },
    },
    {
        Coord = {
            x = 1072.5,
            y = 1038,
        },
        Done = {
            47262,
        },
    },
    {
        PickUp = {
            47263,
        },
        Coord = {
            x = 1072.5,
            y = 1038,
        },
    },
    {
        Qpart = {
            [47263] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1053.5,
            y = 1122,
        },
    },
    {
        Range = 12.9,
        Waypoint = 47263,
        Coord = {
            x = 1349.7,
            y = 818.2,
        },
    },
    {
        PickUp = {
            51089,
        },
        Coord = {
            x = 1368,
            y = 726.9,
        },
    },
    {
        Coord = {
            x = 1390,
            y = 758.1,
        },
        Done = {
            47263,
        },
    },
    {
        PickUp = {
            47188,
        },
        Coord = {
            x = 1390.2,
            y = 757.5,
        },
    },
    {
        Gossip = 101,
        Qpart = {
            [47188] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1390.2,
            y = 757.5,
        },
    },
    {
        Qpart = {
            [47188] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1390.2,
            y = 757.5,
        },
    },
    {
        Coord = {
            x = 1390.2,
            y = 757.5,
        },
        Done = {
            47188,
        },
    },
    {
        PickUp = {
            47241,
        },
        Coord = {
            x = 1390.2,
            y = 757.5,
        },
    },
    {
        GetFP = 1953,
        Range = 0.91,
        Coord = {
            x = 1405.9,
            y = 791.2,
        },
    },
    {
        PickUp = {
            48669,
        },
        Coord = {
            x = 1406.2,
            y = 805.9,
        },
    },
    {
        Qpart = {
            [48669] = {
                1,
            },
        },
        Gossip = 1,
        Range = 5,
        Coord = {
            x = 1406.2,
            y = 805.9,
        },
    },
    {
        Coord = {
            x = 1407,
            y = 805.4,
        },
        Done = {
            48669,
        },
    },
    {
        PickUp = {
            48573,
            48574,
        },
        Coord = {
            x = 1407,
            y = 805.4,
        },
    },
    {
        Qpart = {
            [48574] = {
                1,
            },
            [48573] = {
                1,
            },
        },
        Button = {
            ["48573-1"] = 152596,
        },
        ButtonSpellId = {
            [251503] = "48573-1",
        },
        ButtonCooldown = {
            [251503] = 5,
        },
        Range = 32.45,
        Coord = {
            x = 1481.2,
            y = 827.1,
        },
    },
    {
        Coord = {
            x = 1656.4,
            y = 776.2,
        },
        Done = {
            48573,
            48574,
        },
    },
    {
        PickUp = {
            48578,
            48577,
            48576,
        },
        Coord = {
            x = 1656,
            y = 776.1,
        },
    },
    {
        Qpart = {
            [48578] = {
                1,
            },
        },
        Fillers = {
            [48576] = {
                1,
            },
            [48577] = {
                1,
            },
        },
        Button = {
            ["48576-1"] = 152610,
        },
        ButtonSpellId = {
            [251559] = "48576-1",
        },
        ButtonCooldown = {
            [251559] = 5,
        },
        Range = 15.15,
        Coord = {
            x = 1655,
            y = 516,
        },
    },
    {
        Qpart = {
            [48576] = {
                1,
            },
            [48577] = {
                1,
            },
        },
        Button = {
            ["48576-1"] = 152610,
        },
        ButtonSpellId = {
            [251559] = "48576-1",
        },
        ButtonCooldown = {
            [251559] = 5,
        },
        Range = 38.31,
        Coord = {
            x = 1639.4,
            y = 516,
        },
    },
    {
        UseGlider = 1,
        Done = {
            48578,
            48577,
            48576,
        },
        Coord = {
            x = 1655.7,
            y = 775.6,
        },
    },
    {
        PickUp = {
            48584,
            48590,
        },
        Coord = {
            x = 1655.4,
            y = 775.4,
        },
    },
    {
        Qpart = {
            [48590] = {
                3,
            },
        },
        Fillers = {
            [48584] = {
                1,
            },
            [48588] = {
                1,
            },
        },
        Button = {
            ["48584-1"] = 156618,
        },
        ButtonSpellId = {
            [260060] = "48584-1",
        },
        ButtonCooldown = {
            [260060] = 5,
        },
        Range = 0.75,
        Coord = {
            x = 1935.9,
            y = 839.1,
        },
    },
    {
        Qpart = {
            [48590] = {
                1,
            },
        },
        Fillers = {
            [48584] = {
                1,
            },
            [48588] = {
                1,
            },
        },
        Button = {
            ["48584-1"] = 156618,
        },
        ButtonSpellId = {
            [260060] = "48584-1",
        },
        ButtonCooldown = {
            [260060] = 5,
        },
        Range = 0.69,
        Coord = {
            x = 1785.7,
            y = 954.4,
        },
    },
    {
        Qpart = {
            [48590] = {
                2,
            },
        },
        Fillers = {
            [48584] = {
                1,
            },
            [48588] = {
                1,
            },
        },
        Button = {
            ["48584-1"] = 156618,
        },
        ButtonSpellId = {
            [260060] = "48584-1",
        },
        ButtonCooldown = {
            [260060] = 5,
        },
        Range = 0.75,
        Coord = {
            x = 1815.5,
            y = 1028,
        },
    },
    {
        Qpart = {
            [48584] = {
                1,
            },
        },
        Fillers = {
            [48588] = {
                1,
            },
        },
        Button = {
            ["48584-1"] = 156618,
        },
        ButtonSpellId = {
            [260060] = "48584-1",
        },
        ButtonCooldown = {
            [260060] = 5,
        },
        Range = 55.8,
        Coord = {
            x = 1932.2,
            y = 848,
        },
    },
    {
        Coord = {
            x = 1935.7,
            y = 983.6,
        },
        Done = {
            48584,
            48590,
        },
        Fillers = {
            [48588] = {
                1,
            },
        },
    },
    {
        PickUp = {
            48591,
        },
        Coord = {
            x = 1935.9,
            y = 983.9,
        },
        Fillers = {
            [48588] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48591] = {
                1,
            },
        },
        Fillers = {
            [48588] = {
                1,
            },
        },
        Range = 14.5,
        Coord = {
            x = 2079.4,
            y = 951,
        },
    },
    {
        Coord = {
            x = 1935.9,
            y = 984,
        },
        Done = {
            48591,
        },
        Fillers = {
            [48588] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [51089] = {
                1,
            },
        },
        Range = 21.46,
        Coord = {
            x = 2008,
            y = 1161,
        },
        Fillers = {
            [48588] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48588] = {
                1,
            },
        },
        Range = 36.67,
        Coord = {
            x = 1918.7,
            y = 994.7,
        },
    },
    {
        Qpart = {
            [47241] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1367.2,
            y = 1252,
        },
    },
    {
        Qpart = {
            [47241] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1475.9,
            y = 1318.5,
        },
    },
    {
        PickUp = {
            48468,
            48473,
        },
        Coord = {
            x = 1394.3,
            y = 1403.3,
        },
    },
    {
        Qpart = {
            [48473] = {
                1,
                2,
            },
            [48468] = {
                1,
            },
        },
        Button = {
            ["48468-1"] = 153178,
        },
        ButtonSpellId = {
            [250353] = "48468-1",
        },
        ButtonCooldown = {
            [250353] = 5,
        },
        Range = 22.74,
        Coord = {
            x = 1339.2,
            y = 1344,
        },
    },
    {
        Coord = {
            x = 1401.9,
            y = 1428.5,
        },
        Done = {
            48468,
            48473,
        },
    },
    {
        PickUp = {
            48478,
            48479,
        },
        Coord = {
            x = 1401.9,
            y = 1428.5,
        },
    },
    {
        Qpart = {
            [48478] = {
                2,
            },
        },
        Button = {
            ["48478-2"] = 154130,
        },
        ButtonSpellId = {
            [256697] = "48478-2",
        },
        ButtonCooldown = {
            [256697] = 5,
        },
        Fillers = {
            [48479] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1377.8,
            y = 1513.4,
        },
    },
    {
        Qpart = {
            [48478] = {
                3,
            },
        },
        Button = {
            ["48478-3"] = 154130,
        },
        ButtonSpellId = {
            [256697] = "48478-3",
        },
        ButtonCooldown = {
            [256697] = 5,
        },
        Fillers = {
            [48479] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1434.2,
            y = 1622.4,
        },
    },
    {
        Qpart = {
            [48478] = {
                1,
            },
        },
        Button = {
            ["48478-1"] = 154130,
        },
        ButtonSpellId = {
            [256697] = "48478-1",
        },
        ButtonCooldown = {
            [256697] = 5,
        },
        Fillers = {
            [48479] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1293.8,
            y = 1707,
        },
    },
    {
        Qpart = {
            [48479] = {
                1,
            },
        },
        Range = 44.5,
        Coord = {
            x = 1323.4,
            y = 1698.5,
        },
    },
    {
        Done = {
            48479,
            48478,
        },
        Coord = {
            x = 1400,
            y = 1428.8,
        },
    },
    {
        PickUp = {
            48480,
        },
        Coord = {
            x = 1401,
            y = 1428.8,
        },
    },
    {
        Waypoint = 48480,
        Range = 11.67,
        Coord = {
            x = 1319.2,
            y = 1510.8,
        },
        LeaveQuest = 52210,
    },
    {
        Qpart = {
            [48480] = {
                1,
            },
        },
        Range = 10.59,
        Coord = {
            x = 1231.7,
            y = 1515,
        },
    },
    {
        Done = {
            48480,
        },
        Coord = {
            x = 1402.8,
            y = 1429,
        },
    },
    {
        Qpart = {
            [47241] = {
                3,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1574,
            y = 1476.7,
        },
    },
    {
        Done = {
            47241,
        },
        Coord = {
            x = 1523,
            y = 1638.5,
        },
    },
    {
        PickUp = {
            47244,
        },
        Coord = {
            x = 1523,
            y = 1638.5,
        },
    },
    {
        Qpart = {
            [47244] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1422.5,
            y = 1768,
        },
    },
    {
        Done = {
            47244,
        },
        Coord = {
            x = 1370.5,
            y = 1991.7,
        },
    },
    {
        PickUp = {
            49278,
        },
        Coord = {
            x = 1370.5,
            y = 1991.7,
        },
    },
    {
        GetFP = 1954,
        Range = 5.91,
        Coord = {
            x = 1336,
            y = 2028,
        },
    },
    {
        Qpart = {
            [49278] = {
                1,
            },
        },
        Range = 38.31,
        Coord = {
            x = 1336,
            y = 2028,
        },
    },
    {
        Done = {
            49278,
        },
        Coord = {
            x = 1370,
            y = 1992,
        },
    },
    {
        PickUp = {
            49440,
            47868,
        },
        Coord = {
            x = 1366.7,
            y = 1990.8,
        },
    },
    {
        Qpart = {
            [49440] = {
                1,
            },
        },
        Gossip = 1,
        Range = 9.46,
        Coord = {
            x = 1367.4,
            y = 1997,
        },
    },
    {
        Qpart = {
            [49440] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 1365.7,
            y = 1991.5,
        },
    },
    {
        Coord = {
            x = 1364.5,
            y = 1991,
        },
        Done = {
            49440,
        },
    },
    {
        PickUp = {
            48699,
        },
        Coord = {
            x = 1364.5,
            y = 1991,
        },
    },
    {
        PickUp = {
            48854,
        },
        Coord = {
            x = 1820.3,
            y = 1700.3,
        },
    },
    {
        Qpart = {
            [48854] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1820.3,
            y = 1700.3,
        },
    },
    {
        Qpart = {
            [48854] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1819.2,
            y = 1702.8,
        },
    },
    {
        Coord = {
            x = 1816,
            y = 1703.7,
        },
        Done = {
            48854,
        },
    },
    {
        PickUp = {
            48823,
            48825,
        },
        Coord = {
            x = 1819.2,
            y = 1703.9,
        },
    },
    {
        Qpart = {
            [48823] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 1816,
            y = 1703.4,
        },
    },
    {
        Qpart = {
            [48825] = {
                1,
            },
        },
        Fillers = {
            [48823] = {
                2,
            },
            [48852] = {
                1,
            },
        },
        Button = {
            ["48823-2"] = 152727,
        },
        ButtonSpellId = {
            [252718] = "48823-2",
        },
        ButtonCooldown = {
            [252718] = 5,
        },
        Range = 13.42,
        Coord = {
            x = 1709.9,
            y = 1468.4,
        },
    },
    {
        Qpart = {
            [48823] = {
                2,
            },
        },
        Fillers = {
            [48852] = {
                1,
            },
        },
        Button = {
            ["48823-2"] = 152727,
        },
        ButtonSpellId = {
            [252718] = "48823-2",
        },
        ButtonCooldown = {
            [252718] = 5,
        },
        Range = 25.48,
        Coord = {
            x = 1714.3,
            y = 1480,
        },
    },
    {
        Done = {
            48823,
            48825,
        },
        Coord = {
            x = 1815.7,
            y = 1703.7,
        },
    },
    {
        PickUp = {
            48857,
            48856,
            48855,
        },
        Coord = {
            x = 1818.5,
            y = 1704,
        },
    },
    {
        Qpart = {
            [48857] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1822.3,
            y = 1705.5,
        },
    },
    {
        Qpart = {
            [48857] = {
                2,
            },
        },
        Fillers = {
            [48856] = {
                1,
            },
            [48855] = {
                1,
            },
        },
        Button = {
            ["48855-1"] = 153483,
        },
        Range = 6.59,
        Coord = {
            x = 1899.9,
            y = 1528.5,
        },
    },
    {
        Qpart = {
            [48856] = {
                1,
            },
            [48855] = {
                1,
            },
        },
        Button = {
            ["48855-1"] = 153483,
        },
        Range = 31.98,
        Coord = {
            x = 1892.2,
            y = 1523.5,
        },
    },
    {
        Coord = {
            x = 1819.9,
            y = 1702.2,
        },
        Done = {
            48857,
            48856,
            48855,
        },
    },
    {
        PickUp = {
            48869,
        },
        Coord = {
            x = 1819.9,
            y = 1702.2,
        },
    },
    {
        Qpart = {
            [48869] = {
                1,
            },
        },
        Fillers = {
            [48852] = {
                1,
            },
        },
        Range = 8.15,
        Coord = {
            x = 1792.7,
            y = 1506.8,
        },
    },
    {
        Qpart = {
            [48852] = {
                1,
            },
        },
        Range = 28.78,
        Coord = {
            x = 1801.5,
            y = 1507.5,
        },
    },
    {
        Coord = {
            x = 1819.5,
            y = 1702,
        },
        Done = {
            48869,
        },
    },
    {
        PickUp = {
            50933,
        },
        Coord = {
            x = 1910.8,
            y = 1705.3,
        },
    },
    {
        Done = {
            50933,
        },
        Coord = {
            x = 2180.1,
            y = 1664.4,
        },
    },
    {
        PickUp = {
            49777,
            49776,
            49774,
        },
        Coord = {
            x = 2179.3,
            y = 1665.8,
        },
    },
    {
        Qpart = {
            [49777] = {
                1,
            },
        },
        Gossip = 1,
        Fillers = {
            [49776] = {
                1,
            },
            [49774] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2314.1,
            y = 1600.3,
        },
    },
    {
        Qpart = {
            [49777] = {
                3,
            },
        },
        Gossip = 1,
        Fillers = {
            [49776] = {
                1,
            },
            [49774] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2326.6,
            y = 1761.9,
        },
    },
    {
        Qpart = {
            [49777] = {
                2,
            },
        },
        Gossip = 1,
        Fillers = {
            [49776] = {
                1,
            },
            [49774] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2207.5,
            y = 1858,
        },
    },
    {
        Qpart = {
            [49774] = {
                1,
            },
            [49776] = {
                1,
            },
        },
        Range = 41.99,
        Coord = {
            x = 2295,
            y = 1784,
        },
    },
    {
        Coord = {
            x = 2179.1,
            y = 1665.5,
        },
        Done = {
            49774,
            49776,
            49777,
        },
    },
    {
        PickUp = {
            49778,
        },
        Coord = {
            x = 2179.1,
            y = 1665.5,
        },
    },
    {
        Qpart = {
            [49778] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 2178.3,
            y = 1664.3,
        },
    },
    {
        Coord = {
            x = 2180.1,
            y = 1667.2,
        },
        Done = {
            49778,
        },
    },
    {
        PickUp = {
            49780,
            49779,
        },
        Coord = {
            x = 2179.3,
            y = 1665.9,
        },
    },
    {
        Qpart = {
            [49779] = {
                1,
            },
            [49780] = {
                1,
            },
        },
        Button = {
            ["49780-1"] = 156480,
        },
        Range = 21.41,
        Coord = {
            x = 2162.4,
            y = 1690.8,
        },
    },
    {
        Done = {
            49780,
            49779,
        },
        Coord = {
            x = 2178.6,
            y = 1666,
        },
    },
    {
        PickUp = {
            49781,
        },
        Coord = {
            x = 2178.6,
            y = 1666,
        },
    },
    {
        Qpart = {
            [49781] = {
                1,
            },
        },
        Range = 6.37,
        Coord = {
            x = 2176.1,
            y = 1658.7,
        },
    },
    {
        Done = {
            49781,
        },
        Coord = {
            x = 1957.5,
            y = 1704.7,
        },
    },
    {
        PickUp = {
            48492,
        },
        Coord = {
            x = 1943,
            y = 1995.2,
        },
    },
    {
        Qpart = {
            [48492] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1943.3,
            y = 1995.5,
        },
    },
    {
        Qpart = {
            [48492] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 1944.7,
            y = 1995,
        },
    },
    {

        Coord = {
            x = 1943.5,
            y = 1994.3,
        },
        Done = {
            48492,
        },
    },
    {

        PickUp = {
            48496,
            48497,
        },
        Coord = {
            x = 1943.5,
            y = 1994.3,
        },
    },
    {

        Qpart = {
            [48496] = {
                3,
            },
        },
        Fillers = {
            [48497] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2007.4,
            y = 2083.6,
        },
    },
    {

        Qpart = {
            [48496] = {
                1,
            },
        },
        Fillers = {
            [48497] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2072.6,
            y = 2110.6,
        },
    },
    {

        Qpart = {
            [48496] = {
                4,
            },
        },
        Fillers = {
            [48497] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2049.6,
            y = 2199.5,
        },
    },
    {

        PickUp = {
            48498,
        },
        Coord = {
            x = 2050.3,
            y = 2198.4,
        },
    },
    {

        Waypoint = 48498,
        Range = 6.94,
        Coord = {
            x = 2078,
            y = 2191.4,
        },
    },
    {

        Qpart = {
            [48498] = {
                1,
            },
        },
        Fillers = {
            [48497] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2109.6,
            y = 2207.5,
        },
    },
    {

        Qpart = {
            [48496] = {
                2,
            },
        },
        Fillers = {
            [48497] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2005.7,
            y = 2177.3,
        },
    },
    {

        Qpart = {
            [48497] = {
                1,
            },
        },
        Range = 36.75,
        Coord = {
            x = 2013,
            y = 2175.1,
        },
    },
    {

        Done = {
            48497,
            48496,
            48498,
        },
        Coord = {
            x = 2088.5,
            y = 2266.1,
        },
    },
    {

        PickUp = {
            49479,
        },
        Coord = {
            x = 2088.5,
            y = 2266.1,
        },
    },
    {

        Qpart = {
            [49479] = {
                1,
            },
        },
        Gossip = 1,
        Range = 36.75,
        Coord = {
            x = 2089.1,
            y = 2269.8,
        },
    },
    {

        Done = {
            49479,
        },
        Coord = {
            x = 2089.4,
            y = 2266.5,
        },
    },
    {

        PickUp = {
            48499,
        },
        Coord = {
            x = 2089.3,
            y = 2267,
        },
    },
    {
        ExtraActionB = 1,

        Qpart = {
            [48499] = {
                1,
            },
        },
        Range = 16.62,
        Coord = {
            x = 2058.3,
            y = 2242.6,
        },
    },
    {
        ExtraActionB = 1,

        Qpart = {
            [48499] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2012,
            y = 2144.9,
        },
    },
    {

        Done = {
            48499,
        },
        Coord = {
            x = 2089.1,
            y = 2266,
        },
    },
    {
        Qpart = {
            [48699] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1746.2,
            y = 1910,
        },
    },
    {
        Done = {
            48699,
        },
        Coord = {
            x = 1694.9,
            y = 1923,
        },
    },
    {
        PickUp = {
            48801,
            48890,
        },
        Coord = {
            x = 1694.9,
            y = 1923,
        },
    },
    {
        Waypoint = 48801,
        Range = 4.5,
        Coord = {
            x = 1704.5,
            y = 1909,
        },
    },
    {
        Qpart = {
            [48801] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.97,
        Coord = {
            x = 1592.5,
            y = 1887,
        },
    },
    {
        Qpart = {
            [48801] = {
                3,
            },
        },
        Gossip = 1,
        Fillers = {
            [48890] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1809.8,
            y = 1786.4,
        },
    },
    {
        Qpart = {
            [48801] = {
                1,
            },
        },
        Gossip = 1,
        Fillers = {
            [48890] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1789.7,
            y = 2010,
        },
    },
    {
        Qpart = {
            [48890] = {
                1,
            },
        },
        Range = 31.81,
        Coord = {
            x = 1764.4,
            y = 1979.5,
        },
    },
    {
        Done = {
            48890,
            48801,
        },
        Coord = {
            x = 1695.2,
            y = 1923.4,
        },
    },
    {
        PickUp = {
            49078,
            48800,
        },
        Coord = {
            x = 1694.4,
            y = 1924,
        },
    },
    {
        Qpart = {
            [48800] = {
                1,
            },
        },
        Fillers = {
            [49078] = {
                1,
            },
            [49406] = {
                1,
            },
        },
        Button = {
            ["49078-1"] = 153012,
        },
        ButtonSpellId = {
            [254104] = "49078-1",
        },
        ButtonCooldown = {
            [254104] = 2,
        },
        Range = 4.35,
        Coord = {
            x = 1679.5,
            y = 1801,
        },
    },
    {
        Qpart = {
            [48800] = {
                3,
            },
        },
        Fillers = {
            [49078] = {
                1,
            },
            [49406] = {
                1,
            },
        },
        Button = {
            ["49078-1"] = 153012,
        },
        ButtonSpellId = {
            [254104] = "49078-1",
        },
        ButtonCooldown = {
            [254104] = 2,
        },
        Range = 3.3,
        Coord = {
            x = 1732.5,
            y = 1797.8,
        },
    },
    {
        Qpart = {
            [48800] = {
                2,
            },
        },
        Fillers = {
            [49078] = {
                1,
            },
            [49406] = {
                1,
            },
        },
        Button = {
            ["49078-1"] = 153012,
        },
        ButtonSpellId = {
            [254104] = "49078-1",
        },
        ButtonCooldown = {
            [254104] = 2,
        },
        Range = 4.45,
        Coord = {
            x = 1822.9,
            y = 1944.2,
        },
    },
    {
        Qpart = {
            [49078] = {
                1,
            },
        },
        Fillers = {
            [49406] = {
                1,
            },
        },
        Button = {
            ["49078-1"] = 153012,
        },
        ButtonSpellId = {
            [254104] = "49078-1",
        },
        ButtonCooldown = {
            [254104] = 2,
        },
        Range = 9.51,
        Coord = {
            x = 1813.9,
            y = 1928.8,
        },
    },
    {
        Done = {
            48800,
            49078,
        },
        Coord = {
            x = 1694,
            y = 1923.4,
        },
    },
    {
        PickUp = {
            49079,
        },
        Coord = {
            x = 1694,
            y = 1923.4,
        },
    },
    {
        Qpart = {
            [49079] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1758.3,
            y = 1904.4,
        },
    },
    {
        Qpart = {
            [49079] = {
                2,
            },
        },
        Range = 51.91,
        Coord = {
            x = 1810.5,
            y = 1833.4,
        },
    },
    {
        Done = {
            49079,
        },
        Coord = {
            x = 1805.5,
            y = 1888.5,
        },
    },
    {
        PickUp = {
            49081,
        },
        Coord = {
            x = 1805.5,
            y = 1888.4,
        },
    },
    {
        Bloodlust = 1,
        Qpart = {
            [49081] = {
                1,
            },
        },
        Range = 7.51,
        Coord = {
            x = 1891.5,
            y = 1900.5,
        },
    },
    {
        Done = {
            49081,
        },
        Coord = {
            x = 1805.7,
            y = 1888.4,
        },
    },
    {
        PickUp = {
            49082,
        },
        Coord = {
            x = 1805.7,
            y = 1888.4,
        },
    },
    {
        Qpart = {
            [49082] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1803.9,
            y = 1891.9,
        },
    },
    {
        Qpart = {
            [49406] = {
                1,
            },
        },
        Range = 40.16,
        Coord = {
            x = 1644.3,
            y = 1857,
        },
    },
    {
        Qpart = {
            [49082] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1364.5,
            y = 1991.9,
        },
    },
    {
        Done = {
            49082,
        },
        Coord = {
            x = 1366.2,
            y = 1991.3,
        },
    },
    {
        Done = {
            47868,
        },
        Coord = {
            x = 1367.4,
            y = 2386.1,
        },
    },
    {
        PickUp = {
            47880,
        },
        Coord = {
            x = 1367.4,
            y = 2385.3,
        },
    },
    {
        Qpart = {
            [47880] = {
                1,
            },
        },
        Range = 11.55,
        Coord = {
            x = 1367,
            y = 2385.3,
        },
    },
    {
        Qpart = {
            [47880] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1367,
            y = 2411.6,
        },
    },
    {
        Waypoint = 47880,
        Range = 10.08,
        Coord = {
            x = 1371,
            y = 2503.1,
        },
    },
    {
        Done = {
            47880,
        },
        Coord = {
            x = 1368,
            y = 2663.1,
        },
    },
    {
        PickUp = {
            47491,
            47247,
            49348,
        },
        Coord = {
            x = 1367.5,
            y = 2663.1,
        },
    },
    {
        Waypoint = 49348,
        Range = 13.95,
        Coord = {
            x = 1368.4,
            y = 2574.4,
        },
    },
    {
        PickUp = {
            47248,
        },
        Coord = {
            x = 1521.7,
            y = 2568.9,
        },
        Fillers = {
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47247] = {
                2,
            },
        },
        Fillers = {
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
        Range = 9.61,
        Coord = {
            x = 1549.5,
            y = 2482.6,
        },
    },
    {
        Qpart = {
            [47247] = {
                1,
            },
        },
        Fillers = {
            [49348] = {
                1,
            },
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
        Range = 9.81,
        Coord = {
            x = 1162,
            y = 2476.5,
        },
    },
    {
        PickUp = {
            49432,
        },
        Coord = {
            x = 1209.5,
            y = 2426.8,
        },
        Fillers = {
            [49348] = {
                1,
            },
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49348] = {
                1,
            },
        },
        Range = 102.71,
        Coord = {
            x = 1209.5,
            y = 2426.8,
        },
        Fillers = {
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Range = 3.35,
        Waypoint = 49432,
        Coord = {
            x = 1367.5,
            y = 2423.9,
        },
        Fillers = {
            [49348] = {
                1,
            },
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49432] = {
                1,
            },
        },
        Fillers = {
            [47491] = {
                1,
            },
            [49348] = {
                1,
            },
            [48934] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1367.7,
            y = 2303.6,
        },
    },
    {
        Qpart = {
            [49432] = {
                2,
            },
        },
        Range = 4.27,
        Coord = {
            x = 1365,
            y = 2305.4,
        },
    },
    {
        Range = 14.25,
        Waypoint = 47248,
        Coord = {
            x = 1367,
            y = 2428.9,
        },
        Fillers = {
            [49348] = {
                1,
            },
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Range = 7.71,
        Waypoint = 47248,
        Coord = {
            x = 1326.5,
            y = 2517,
        },
        Fillers = {
            [49348] = {
                1,
            },
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47248] = {
                1,
            },
        },
        Fillers = {
            [47491] = {
                1,
            },
            [49348] = {
                1,
            },
            [48934] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1326,
            y = 2598.6,
        },
    },
    {
        Range = 6.77,
        Waypoint = 47248,
        Coord = {
            x = 1326.5,
            y = 2518.6,
        },
        Fillers = {
            [49348] = {
                1,
            },
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Coord = {
            x = 1521.3,
            y = 2568.5,
        },
        Done = {
            47248,
        },
        Fillers = {
            [49348] = {
                1,
            },
            [47491] = {
                1,
            },
            [48934] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47491] = {
                1,
            },
        },
        Fillers = {
            [48934] = {
                1,
            },
        },
        Range = 34.45,
        Coord = {
            x = 1518.5,
            y = 2549.9,
        },
    },
    {
        Qpart = {
            [49348] = {
                1,
            },
            [48934] = {
                1,
            },
        },
        Range = 102.71,
        Coord = {
            x = 1210.9,
            y = 2481.9,
        },
    },
    {
        Range = 8.99,
        Waypoint = 49348,
        Coord = {
            x = 1367.7,
            y = 2588.1,
        },
    },
    {
        Coord = {
            x = 1368.4,
            y = 2662,
        },
        Done = {
            49348,
            49432,
            47247,
            47491,
        },
    },
    {
        PickUp = {
            47249,
        },
        Coord = {
            x = 1368.4,
            y = 2662,
        },
    },
    {
        Qpart = {
            [47249] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 1367,
            y = 2475.5,
        },
    },
    {
        Qpart = {
            [47249] = {
                2,
            },
        },
        Range = 5.63,
        Coord = {
            x = 1369.9,
            y = 2470.9,
        },
    },
    {
        Coord = {
            x = 1368.7,
            y = 2469.6,
        },
        Done = {
            47249,
        },
    },
    {
        PickUp = {
            47250,
        },
        Coord = {
            x = 1368.7,
            y = 2469.6,
        },
    },
    {
        Waypoint = 47250,
        Range = 11.31,
        Coord = {
            x = 1402.2,
            y = 2448.9,
        },
    },
    {
        Waypoint = 47250,
        Range = 8.96,
        Coord = {
            x = 1401.5,
            y = 2412.3,
        },
    },
    {
        Waypoint = 47250,
        Range = 12.15,
        Coord = {
            x = 1375.4,
            y = 2377.6,
        },
    },
    {
        Coord = {
            x = 1370.3,
            y = 1991.3,
        },
        Done = {
            47250,
        },
    },
    {
        PickUp = {
            49185,
        },
        Coord = {
            x = 1376.3,
            y = 1986.4,
        },
    },
    {
        Qpart = {
            [49185] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1376.3,
            y = 1986.4,
        },
    },
    {
        Done = {
            49185,
        },
        Coord = {
            x = 1374.9,
            y = 1987.2,
        },
    },
    {
        PickUp = {
            49064,
        },
        Coord = {
            x = 1374.9,
            y = 1987.2,
        },
    },
    {
        Waypoint = 49064,
        Range = 15.25,
        Coord = {
            x = 1352.5,
            y = 1953.8,
        },
    },
    {
        Qpart = {
            [49064] = {
                1,
            },
        },
        Gossip = 1,
        Range = 01,
        Coord = {
            x = 523.6,
            y = 2146.8,
        },
    },
    {

        PickUp = {
            47924,
        },
        Coord = {
            x = 549.4,
            y = 2240.6,
        },
    },
    {

        Qpart = {
            [47924] = {
                1,
            },
        },
        Fillers = {
            [47996] = {
                1,
            },
        },
        Button = {
            ["47924-1"] = 151849,
        },
        ButtonSpellId = {
            [248193] = "47924-1",
        },
        ButtonCooldown = {
            [248193] = 5,
        },
        Range = 28.9,
        Coord = {
            x = 677.7,
            y = 2345.9,
        },
    },
    {

        Qpart = {
            [47996] = {
                1,
            },
        },
        Range = 28.9,
        Coord = {
            x = 677.7,
            y = 2345.9,
        },
    },
    {

        Done = {
            47924,
        },
        Coord = {
            x = 727,
            y = 2364.3,
        },
    },
    {

        PickUp = {
            47998,
            47919,
            47925,
        },
        Coord = {
            x = 727,
            y = 2364.3,
        },
    },
    {

        Qpart = {
            [47919] = {
                1,
            },
        },
        Fillers = {
            [47998] = {
                1,
            },
        },
        Range = 4.26,
        Coord = {
            x = 863.6,
            y = 2361.9,
        },
    },
    {

        Qpart = {
            [47919] = {
                2,
            },
        },
        Fillers = {
            [47998] = {
                1,
            },
        },
        Range = 2.93,
        Coord = {
            x = 788,
            y = 2280.9,
        },
    },
    {

        Range = 21.44,
        Waypoint = 47998,
        Coord = {
            x = 818.5,
            y = 2190.1,
        },
        Fillers = {
            [47998] = {
                1,
            },
        },
    },
    {

        Qpart = {
            [47919] = {
                3,
            },
        },
        Fillers = {
            [47998] = {
                1,
            },
        },
        Range = 7.02,
        Coord = {
            x = 839.4,
            y = 2183.3,
        },
    },
    {

        Qpart = {
            [47925] = {
                1,
            },
        },
        Gossip = 1,
        Fillers = {
            [47998] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 849.7,
            y = 2154.6,
        },
    },
    {

        Qpart = {
            [47998] = {
                1,
            },
        },
        Range = 26.22,
        Coord = {
            x = 849.2,
            y = 2162.6,
        },
    },
    {

        Coord = {
            x = 513.2,
            y = 2395.3,
        },
        Done = {
            47998,
            47925,
            47919,
        },
    },
    {
        Qpart = {
            [49064] = {
                2,
            },
        },
        Range = 6.76,
        Coord = {
            x = 520.7,
            y = 2542.9,
        },
    },
    {
        Done = {
            49064,
        },
        Coord = {
            x = 475.1,
            y = 2593.1,
        },
    },
    {
        PickUp = {
            49067,
        },
        Coord = {
            x = 475.1,
            y = 2593.1,
        },
    },
    {
        Qpart = {
            [49067] = {
                1,
            },
        },
        Gossip = 1,
        Range = 1,
        Coord = {
            x = 475.1,
            y = 2593.1,
        },
    },
    {
        Done = {
            49067,
        },
        Coord = {
            x = 476.3,
            y = 2592.5,
        },
    },
    {
        PickUp = {
            49070,
            49071,
            49080,
        },
        Coord = {
            x = 476.3,
            y = 2592.5,
        },
    },
    {
        Waypoint = 49070,
        Range = 9.51,
        Coord = {
            x = 365,
            y = 2658.9,
        },
    },
    {
        Qpart = {
            [49071] = {
                1,
            },
            [49070] = {
                1,
            },
        },
        Button = {
            ["49071-1"] = 153024,
        },
        ButtonSpellId = {
            [254180] = "49071-1",
        },
        ButtonCooldown = {
            [254180] = 5,
        },
        Range = 49.83,
        Coord = {
            x = 319.3,
            y = 2754.3,
        },
    },
    {
        Qpart = {
            [49080] = {
                1,
            },
        },
        Fillers = {
            [49071] = {
                1,
            },
            [49070] = {
                1,
            },
        },
        Button = {
            ["49071-1"] = 153024,
        },
        ButtonSpellId = {
            [254180] = "49071-1",
        },
        ButtonCooldown = {
            [254180] = 5,
        },
        Range = 5.04,
        Coord = {
            x = 241,
            y = 2893.6,
        },
    },
    {
        Coord = {
            x = 476.3,
            y = 2594.6,
        },
        Done = {
            49070,
            49071,
            49080,
        },
    },
    {
        PickUp = {
            49120,
        },
        Coord = {
            x = 475.2,
            y = 2594.6,
        },
    },
    {
        Qpart = {
            [49120] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 475.2,
            y = 2594.6,
        },
    },
    {
        Done = {
            49120,
        },
        Coord = {
            x = 475.2,
            y = 2594.6,
        },
    },
    {
        PickUp = {
            49125,
        },
        Coord = {
            x = 475.2,
            y = 2594.6,
        },
    },
    {
        Qpart = {
            [49125] = {
                2,
            },
        },
        Fillers = {
            [49125] = {
                1,
            },
            [51689] = {
                1,
            },
        },
        Button = {
            ["49125-1"] = 160559,
        },
        ButtonSpellId = {
            [272476] = "49125-1",
        },
        ButtonCooldown = {
            [272476] = 5,
        },
        Range = 0.75,
        Coord = {
            x = 176,
            y = 2667,
        },
    },
    {
        Qpart = {
            [49125] = {
                1,
            },
        },
        Fillers = {
            [51689] = {
                1,
            },
        },
        Button = {
            ["49125-1"] = 160559,
        },
        ButtonSpellId = {
            [272476] = "49125-1",
        },
        ButtonCooldown = {
            [272476] = 5,
        },
        Range = 12.28,
        Coord = {
            x = 179.4,
            y = 2669,
        },
    },
    {
        Qpart = {
            [51689] = {
                1,
            },
        },
        Range = 149.93,
        Coord = {
            x = 225.9,
            y = 2599.3,
        },
    },
    {
        Done = {
            49125,
        },
        Coord = {
            x = 9,
            y = 2898.6,
        },
    },
    {
        PickUp = {
            49126,
        },
        Coord = {
            x = -2.5,
            y = 2900.1,
        },
    },
    {
        ExtraActionB = 1,
        Qpart = {
            [49126] = {
                1,
            },
        },
        Range = 19.63,
        Coord = {
            x = 64.7,
            y = 2934.9,
        },
    },
    {
        Qpart = {
            [49126] = {
                2,
            },
        },
        Range = 19.63,
        Coord = {
            x = 64.7,
            y = 2934.9,
        },
    },
    {
        Done = {
            49126,
        },
        Coord = {
            x = 374.8,
            y = 3044.9,
        },
    },
    {
        PickUp = {
            49130,
            49132,
            49131,
        },
        Coord = {
            x = 373.6,
            y = 3043.4,
        },
    },
    {
        Qpart = {
            [49130] = {
                1,
            },
            [49132] = {
                1,
            },
            [49131] = {
                1,
            },
        },
        Range = 25.5,
        Coord = {
            x = 449,
            y = 2913.5,
        },
    },
    {
        Done = {
            49130,
            49132,
            49131,
        },
        Coord = {
            x = 476.8,
            y = 2591.8,
        },
    },
    {
        PickUp = {
            49136,
        },
        Coord = {
            x = 476.8,
            y = 2591.8,
        },
    },
    {
        Range = 21.44,
        Waypoint = 49136,
        Coord = {
            x = 368.2,
            y = 2654.3,
        },
    },
    {
        Bloodlust = 1,
        Qpart = {
            [49136] = {
                1,
            },
        },
        Range = 8.5,
        Coord = {
            x = 241.3,
            y = 2895.1,
        },
    },
    {
        Done = {
            49136,
        },
        Coord = {
            x = 474.8,
            y = 2593.4,
        },
    },
    {
        PickUp = {
            49160,
        },
        Coord = {
            x = 478,
            y = 2592.8,
        },
    },
    {
        Qpart = {
            [49160] = {
                1,
            },
        },
        Button = {
            ["49160-1"] = 153131,
        },
        ButtonSpellId = {
            [254396] = "49160-1",
        },
        ButtonCooldown = {
            [254396] = 60,
        },
        Range = 01,
        Coord = {
            x = 478,
            y = 2592.8,
        },
    },
    {
        Done = {
            49160,
        },
        Coord = {
            x = 475,
            y = 2591.1,
        },
    },
    {
        PickUp = {
            49902,
        },
        Coord = {
            x = 475,
            y = 2591.1,
        },
    },
    {
        QpartPart = {
            [49902] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        TrigText = "1/3",
        Coord = {
            x = 519.7,
            y = 2137,
        },
    },
    {
        QpartPart = {
            [49902] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        TrigText = "2/3",
        Coord = {
            x = 282.7,
            y = 1910.3,
        },
    },
    {
        QpartPart = {
            [49902] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        TrigText = "3/3",
        Coord = {
            x = 91.9,
            y = 1856.5,
        },
    },
    {
        Coord = {
            x = -93.5,
            y = 2045.7,
        },
        Done = {
            49902,
        },
    },
    {
        PickUp = {
            47245,
            47525,
        },
        Coord = {
            x = -94,
            y = 2048.6,
        },
    },
    {
        PickUp = {
            52477,
        },
        Coord = {
            x = -84.6,
            y = 2096.6,
        },
    },
    {
        Qpart = {
            [52477] = {
                1,
            },
        },
        Range = 29.87,
        Coord = {
            x = 396.2,
            y = 2348.6,
        },
    },
    {
        Done = {
            52477,
        },
        Coord = {
            x = -110.5,
            y = 2059.4,
        },
    },
    {
        ExtraLineText = "WAIT_FOR_NPC",
        SetHS = 47245,
        Coord = {
            x = -112.4,
            y = 2062,
        },
    },
    {

        Range = 5.87,
        GetFP = 1955,
        Coord = {
            x = -70.8,
            y = 1994.2,
        },
    },
    {
        Qpart = {
            [47245] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -151.9,
            y = 1991.9,
        },
    },
    {
        Qpart = {
            [47525] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -156.4,
            y = 1892.7,
        },
    },
    {
        Coord = {
            x = -156.4,
            y = 1892.7,
        },
        Done = {
            47525,
        },
    },
    {
        PickUp = {
            47659,
            47660,
        },
        Coord = {
            x = -155.2,
            y = 1892.7,
        },
    },
    {
        PickUp = {
            48402,
        },
        Coord = {
            x = -185.5,
            y = 1760.8,
        },
        Fillers = {
            [47660] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47659] = {
                1,
            },
        },
        Fillers = {
            [48402] = {
                1,
            },
            [47660] = {
                1,
            },
        },
        Range = 7.33,
        Coord = {
            x = -144.2,
            y = 1726.5,
        },
    },
    {
        Qpart = {
            [48402] = {
                1,
            },
            [47660] = {
                1,
            },
        },
        Range = 20.04,
        Coord = {
            x = -136.4,
            y = 1726,
        },
    },
    {
        Waypoint = 48402,
        Range = 14.18,
        Coord = {
            x = -397,
            y = 1653.4,
        },
    },
    {
        Done = {
            47660,
            47659,
            48402,
        },
        Coord = {
            x = -509.7,
            y = 1550,
        },
    },
    {
        PickUp = {
            47623,
        },
        Coord = {
            x = -509.7,
            y = 1550,
        },
    },
    {
        Qpart = {
            [47623] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = -502.9,
            y = 1543.2,
        },
    },
    {
        Qpart = {
            [47623] = {
                2,
            },
        },
        Range = 0.61,
        Coord = {
            x = -502.9,
            y = 1543.5,
        },
    },
    {
        Done = {
            47623,
        },
        Coord = {
            x = -507.4,
            y = 1546.5,
        },
    },
    {
        PickUp = {
            47621,
            47622,
        },
        Coord = {
            x = -507.4,
            y = 1546.5,
        },
    },
    {
        Waypoint = 47622,
        Range = 13.48,
        Coord = {
            x = -409.2,
            y = 1652.9,
        },
    },
    {
        Qpart = {
            [47621] = {
                1,
            },
            [47622] = {
                1,
            },
        },
        Button = {
            ["47622-1"] = 151237,
        },
        ButtonSpellId = {
            [246096] = "47622-1",
        },
        ButtonCooldown = {
            [246096] = 3,
        },
        Range = 58.44,
        Coord = {
            x = -419.8,
            y = 1853.9,
        },
    },
    {

        PickUp = {
            48090,
            48092,
        },
        Coord = {
            x = -635.5,
            y = 1664.8,
        },
    },
    {

        Qpart = {
            [48090] = {
                3,
            },
        },
        Fillers = {
            [48093] = {
                1,
            },
        },
        Button = {
            ["48090-3"] = 158071,
        },
        ButtonSpellId = {
            [248921] = "48090-3",
        },
        ButtonCooldown = {
            [248921] = 5,
        },
        Range = 0.61,
        Coord = {
            x = -722.7,
            y = 1643.5,
        },
    },
    {

        Qpart = {
            [48090] = {
                1,
            },
        },
        Fillers = {
            [48093] = {
                1,
            },
        },
        Button = {
            ["48090-1"] = 158071,
        },
        ButtonSpellId = {
            [248921] = "48090-1",
        },
        ButtonCooldown = {
            [248921] = 5,
        },
        Range = 0.69,
        Coord = {
            x = -878.8,
            y = 1573.3,
        },
    },
    {

        Qpart = {
            [48092] = {
                1,
            },
        },
        Fillers = {
            [48093] = {
                1,
            },
        },
        Range = 7.78,
        Coord = {
            x = -1033.5,
            y = 1604.9,
        },
    },
    {

        Qpart = {
            [48090] = {
                2,
            },
        },
        Fillers = {
            [48093] = {
                1,
            },
        },
        Button = {
            ["48090-2"] = 158071,
        },
        ButtonSpellId = {
            [248921] = "48090-2",
        },
        ButtonCooldown = {
            [248921] = 5,
        },
        Range = 0.69,
        Coord = {
            x = -774.7,
            y = 1764.9,
        },
    },
    {

        Qpart = {
            [48093] = {
                1,
            },
        },
        Range = 50.32,
        Coord = {
            x = -780.5,
            y = 1763.4,
        },
    },
    {

        Coord = {
            x = -637.2,
            y = 1664.3,
        },
        Done = {
            48090,
            48092,
        },
    },
    {

        Range = 8.69,
        Waypoint = 47622,
        Coord = {
            x = -574.8,
            y = 1591.5,
        },
    },
    {

        Range = 7.96,
        Waypoint = 47622,
        Coord = {
            x = -545.3,
            y = 1606.9,
        },
    },
    {

        Range = 30.7,
        Waypoint = 47622,
        Coord = {
            x = -511.4,
            y = 1609.3,
        },
    },
    {
        Coord = {
            x = -511.7,
            y = 1551,
        },
        Done = {
            47621,
            47622,
        },
    },
    {
        PickUp = {
            47540,
        },
        Coord = {
            x = -511.7,
            y = 1551,
        },
    },
    {
        Qpart = {
            [47540] = {
                1,
            },
        },
        Range = 8.82,
        Coord = {
            x = -518.5,
            y = 1556.3,
        },
    },
    {
        Done = {
            47540,
        },
        Coord = {
            x = -513,
            y = 1550,
        },
    },
    {
        PickUp = {
            47696,
        },
        Coord = {
            x = -513,
            y = 1550,
        },
    },
    {
        Waypoint = 47696,
        Range = 24.61,
        Coord = {
            x = -288.4,
            y = 1629.8,
        },
    },
    {
        Waypoint = 47696,
        Range = 19.23,
        Coord = {
            x = -88.5,
            y = 1558.4,
        },
    },
    {
        Qpart = {
            [47696] = {
                3,
                2,
            },
        },
        Gossip = 1,
        Range = 21.93,
        Coord = {
            x = -88.5,
            y = 1557.5,
        },
    },
    {
        Done = {
            47696,
        },
        Coord = {
            x = -507.8,
            y = 1548.3,
        },
    },
    {
        PickUp = {
            47697,
        },
        Coord = {
            x = -503.5,
            y = 1543.7,
        },
    },
    {
        UseHS = 47697,
        Coord = {
            x = -503.5,
            y = 1543.7,
        },
        Button = {
            ["22345678-1"] = 6948,
        },
    },
    {
        Done = {
            47697,
            47245,
        },
        Coord = {
            x = -92.6,
            y = 2047.5,
        },
    },
    {
        PickUp = {
            47631,
        },
        Coord = {
            x = -93,
            y = 2046.3,
        },
    },
    {
        PickUp = {
            50934,
        },
        Coord = {
            x = -66.5,
            y = 2057.6,
        },
    },
    {

        Waypoint = 50934,
        Range = 13.13,
        Coord = {
            x = -49.3,
            y = 2028.5,
        },
    },
    {

        Waypoint = 50934,
        Range = 10.99,
        Coord = {
            x = 100.7,
            y = 1849.5,
        },
    },
    {

        Done = {
            50934,
        },
        Coord = {
            x = 85.2,
            y = 1765.8,
        },
    },
    {

        PickUp = {
            49366,
        },
        Coord = {
            x = 83.9,
            y = 1765.4,
        },
    },
    {

        Qpart = {
            [49366] = {
                1,
            },
        },
        Button = {
            ["49366-1"] = 153676,
        },
        Range = 0.69,
        Coord = {
            x = 85.2,
            y = 1765.5,
        },
    },
    {

        Done = {
            49366,
        },
        Coord = {
            x = 129.1,
            y = 1682.2,
        },
    },
    {

        PickUp = {
            49370,
            49377,
            49380,
        },
        Coord = {
            x = 129.1,
            y = 1682.2,
        },
    },
    {

        Qpart = {
            [49370] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 160.3,
            y = 1652.9,
        },
    },
    {

        Done = {
            49370,
        },
        Coord = {
            x = 153.6,
            y = 1651.8,
        },
    },
    {

        PickUp = {
            49378,
            49379,
        },
        Coord = {
            x = 153.6,
            y = 1651.8,
        },
    },
    {

        Qpart = {
            [49378] = {
                1,
            },
        },
        Range = 15.05,
        Coord = {
            x = 182.3,
            y = 1679,
        },
    },
    {

        Qpart = {
            [49380] = {
                2,
            },
        },
        Fillers = {
            [49378] = {
                2,
            },
            [49379] = {
                1,
            },
        },
        Button = {
            ["49380-2"] = 153678,
        },
        Range = 0.75,
        Coord = {
            x = 180.3,
            y = 1623.4,
        },
    },
    {

        Qpart = {
            [49377] = {
                1,
            },
        },
        Fillers = {
            [49378] = {
                2,
            },
            [49379] = {
                1,
            },
        },
        Range = 10.53,
        Coord = {
            x = 182.4,
            y = 1524.4,
        },
    },
    {

        Qpart = {
            [49380] = {
                3,
            },
        },
        Fillers = {
            [49379] = {
                1,
            },
            [49378] = {
                2,
            },
        },
        Button = {
            ["49380-3"] = 153678,
        },
        Range = 8.85,
        Coord = {
            x = 268.7,
            y = 1571.4,
        },
    },
    {

        Qpart = {
            [49380] = {
                1,
            },
        },
        Fillers = {
            [49379] = {
                1,
            },
            [49378] = {
                2,
            },
        },
        Button = {
            ["49380-1"] = 153678,
        },
        Range = 2.46,
        Coord = {
            x = 285.2,
            y = 1655,
        },
    },
    {

        Qpart = {
            [49380] = {
                3,
            },
            [49378] = {
                2,
            },
            [49379] = {
                1,
            },
        },
        Range = 38.86,
        Coord = {
            x = 220.6,
            y = 1588.2,
        },
    },
    {

        Coord = {
            x = 128.6,
            y = 1681.3,
        },
        Done = {
            49379,
            49378,
            49380,
            49377,
        },
    },
    {

        PickUp = {
            49382,
        },
        Coord = {
            x = 128.6,
            y = 1681.3,
        },
    },
    {

        Range = 34.95,
        Waypoint = 49382,
        Coord = {
            x = -216.7,
            y = 1631,
        },
    },
    {

        Range = 15.99,
        Waypoint = 49382,
        Coord = {
            x = -379.2,
            y = 1644.9,
        },
    },
    {

        Qpart = {
            [49382] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = -508.9,
            y = 1549.7,
        },
    },
    {

        Coord = {
            x = -508.9,
            y = 1549.7,
        },
        Done = {
            49382,
        },
    },
    {
        Range = 5,
        Waypoint = 47631,
        Coord = {
            x = -404.8,
            y = 1657.9,
        },
    },
    {
        Qpart = {
            [47631] = {
                1,
            },
        },
        Range = 9.68,
        Coord = {
            x = -470.5,
            y = 2165.5,
        },
    },
    {
        Coord = {
            x = -470,
            y = 2165,
        },
        Done = {
            47631,
        },
    },
    {
        PickUp = {
            47597,
            47599,
        },
        Coord = {
            x = -476.4,
            y = 2161.5,
        },
    },
    {
        Waypoint = 47597,
        Range = 15.23,
        Coord = {
            x = -640.7,
            y = 2265,
        },
        Fillers = {
            [47599] = {
                1,
            },
            [47756] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [47597] = {
                2,
            },
        },
        Fillers = {
            [47599] = {
                1,
            },
            [47756] = {
                1,
            },
        },
        Button = {
            ["47599-1"] = 151363,
        },
        Range = 0.69,
        Coord = {
            x = -718.5,
            y = 2240.9,
        },
    },
    {
        Qpart = {
            [47597] = {
                3,
            },
        },
        Fillers = {
            [47599] = {
                1,
            },
            [47756] = {
                1,
            },
        },
        Button = {
            ["47599-1"] = 151363,
        },
        Range = 0.75,
        Coord = {
            x = -752.8,
            y = 2395.8,
        },
    },
    {
        Qpart = {
            [47597] = {
                1,
            },
        },
        Fillers = {
            [47599] = {
                1,
            },
            [47756] = {
                1,
            },
        },
        Button = {
            ["47599-1"] = 151363,
        },
        Range = 0.69,
        Coord = {
            x = -597.8,
            y = 2384.6,
        },
    },
    {
        Qpart = {
            [47599] = {
                1,
            },
        },
        Fillers = {
            [47756] = {
                1,
            },
        },
        Button = {
            ["47599-1"] = 151363,
        },
        Range = 35.67,
        Coord = {
            x = -597.8,
            y = 2384.6,
        },
    },
    {
        Qpart = {
            [47756] = {
                1,
            },
        },
        Range = 150.62,
        Coord = {
            x = -711.7,
            y = 2333.1,
        },
    },
    {
        Range = 9.39,
        Waypoint = 47597,
        Coord = {
            x = -860,
            y = 2589.8,
        },
    },
    {
        Coord = {
            x = -879.8,
            y = 2573.1,
        },
        Done = {
            47597,
            47599,
        },
    },
    {
        PickUp = {
            47711,
            47596,
            47598,
        },
        Coord = {
            x = -877,
            y = 2571.1,
        },
    },
    {
        GetFP = 1956,
        Range = 2,
        Coord = {
            x = -869.5,
            y = 2592.1,
        },
    },
    {
        Qpart = {
            [47596] = {
                2,
            },
        },
        Fillers = {
            [47598] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -711.2,
            y = 2568,
        },
    },
    {
        Bloodlust = 1,
        Qpart = {
            [47711] = {
                1,
            },
        },
        Fillers = {
            [47598] = {
                1,
            },
        },
        Range = 9.67,
        Coord = {
            x = -685.8,
            y = 2642.5,
        },
    },
    {
        Qpart = {
            [47596] = {
                1,
            },
        },
        Fillers = {
            [47598] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = -631,
            y = 2643.3,
        },
    },
    {
        Qpart = {
            [47596] = {
                3,
            },
        },
        Fillers = {
            [47598] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -732,
            y = 2748.1,
        },
    },
    {
        Qpart = {
            [47598] = {
                1,
            },
        },
        Range = 22.66,
        Coord = {
            x = -728.8,
            y = 2748.1,
        },
    },
    {
        Coord = {
            x = -877.2,
            y = 2572.6,
        },
        Done = {
            47711,
            47596,
            47598,
        },
    },
    {
        PickUp = {
            47601,
        },
        Coord = {
            x = -878.3,
            y = 2572.6,
        },
    },
    {
        Qpart = {
            [47601] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = -833.2,
            y = 2616,
        },
    },
    {
        Qpart = {
            [47601] = {
                3,
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = -831.3,
            y = 2616.5,
        },
    },
    {
        Coord = {
            x = -827.5,
            y = 2613.1,
        },
        Done = {
            47601,
        },
    },
    {
        PickUp = {
            47602,
        },
        Coord = {
            x = -827.5,
            y = 2613.1,
        },
    },
    {
        Qpart = {
            [47602] = {
                1,
            },
        },
        Gossip = 1,
        Range = 01,
        Coord = {
            x = -825,
            y = 2609.6,
        },
    },
    {
        Qpart = {
            [47602] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = -94.5,
            y = 2047,
        },
    },
    {
        Done = {
            47602,
        },
        Coord = {
            x = -94.3,
            y = 2047.8,
        },
    },
    {
        PickUp = {
            49932,
        },
        Coord = {
            x = -97.1,
            y = 2056.9,
        },
    },
    {
        Qpart = {
            [49932] = {
                1,
            },
        },
        Range = 01,
        Coord = {
            x = -70.7,
            y = 2167.1,
        },
    },
    {
        Qpart = {
            [49932] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = -70.7,
            y = 2167.1,
        },
    },
    {
        Qpart = {
            [49932] = {
                3,
            },
        },
        Range = 0.69,
        Coord = {
            x = -69.4,
            y = 2166.4,
        },
    },
    {
        Done = {
            49932,
        },
        Coord = {
            x = -70,
            y = 2165.1,
        },
    },
    {
        PickUp = {
            49937,
            49935,
            49938,
        },
        Coord = {
            x = -70,
            y = 2165.1,
        },
    },
    {
        Qpart = {
            [49935] = {
                1,
            },
        },
        Fillers = {
            [49938] = {
                1,
            },
            [49937] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = -188.2,
            y = 2135.8,
        },
    },
    {
        Qpart = {
            [49935] = {
                2,
            },
        },
        Fillers = {
            [49938] = {
                1,
            },
            [49937] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = -29.5,
            y = 2347.8,
        },
    },
    {
        Qpart = {
            [49938] = {
                1,
            },
            [49937] = {
                1,
            },
        },
        Range = 32.43,
        Coord = {
            x = -32,
            y = 2345.9,
        },
    },
    {
        Done = {
            49937,
            49935,
            49938,
        },
        Coord = {
            x = -163.6,
            y = 2295.8,
        },
    },
    {
        PickUp = {
            49941,
            49949,
        },
        Coord = {
            x = -163.6,
            y = 2295.8,
        },
    },
    {
        PickUp = {
            49950,
        },
        Coord = {
            x = -189.5,
            y = 2340.1,
        },
    },
    {
        Qpart = {
            [49949] = {
                1,
            },
            [49941] = {
                1,
            },
            [49950] = {
                1,
            },
        },
        Button = {
            ["49941-1"] = 156528,
        },
        Range = 20.06,
        Coord = {
            x = -219.5,
            y = 2349.1,
        },
    },
    {
        Done = {
            49949,
            49941,
            49950,
        },
        Coord = {
            x = -161.7,
            y = 2298.1,
        },
    },
    {
        PickUp = {
            49955,
            49957,
            49956,
        },
        Coord = {
            x = -161.7,
            y = 2298.1,
        },
    },
    {
        Qpart = {
            [49955] = {
                1,
            },
            [49957] = {
                1,
            },
            [49956] = {
                1,
            },
        },
        Button = {
            ["49956-1"] = 156542,
        },
        ButtonSpellId = {
            [259527] = "49956-1",
        },
        ButtonCooldown = {
            [259527] = 2,
        },
        Range = 21.05,
        Coord = {
            x = -262.8,
            y = 2399.6,
        },
    },
    {
        Done = {
            49955,
            49957,
            49956,
        },
        Coord = {
            x = -361.4,
            y = 2499.4,
        },
    },
    {
        PickUp = {
            49980,
        },
        Coord = {
            x = -365.6,
            y = 2500.6,
        },
    },
    {
        Qpart = {
            [49980] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = -365.6,
            y = 2500.6,
        },
    },
    {
        Qpart = {
            [49980] = {
                2,
            },
        },
        Range = 7.31,
        Coord = {
            x = -365.6,
            y = 2500.6,
        },
    },
    {
        Done = {
            49980,
        },
        Coord = {
            x = -365.6,
            y = 2500.6,
        },
    },
    {
        PickUp = {
            49985,
        },
        Coord = {
            x = -365.6,
            y = 2500.6,
        },
    },
    {
        Qpart = {
            [49985] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = -328.9,
            y = 2464.8,
        },
    },
    {
        Done = {
            49985,
        },
        Coord = {
            x = -94.6,
            y = 2048.8,
        },
    },
    {
        PickUp = {
            49569,
        },
        Coord = {
            x = -94.9,
            y = 2048.5,
        },
    },
    {
        Waypoint = 49569,
        Range = 13.34,
        Coord = {
            x = -48.5,
            y = 2026.5,
        },
    },
    {
        Qpart = {
            [49569] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.61,
        Coord = {
            x = -6.2,
            y = 1948.0,
        },
    },
    {
        ETA = 150,
        Qpart = {
            [49569] = {
                2,
            },
        },
        Range = 5.61,
        Coord = {
            x = -5,
            y = 1950,
        },
    },
    {
        Waypoint = 49569,
        Range = 12.73,
        Coord = {
            x = 1348.2,
            y = 687.2,
        },
    },
    {
        Done = {
            51089,
        },
        Coord = {
            x = 1391,
            y = 730.5,
        },
    },
    {
        Done = {
            49569,
        },
        Coord = {
            x = 1377,
            y = 791.2,
        },
    },
    {
        PickUp = {
            50076,
        },
        Coord = {
            x = 1377.2,
            y = 790.6,
        },
    },
    {
        Qpart = {
            [50076] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 1378.5,
            y = 814.1,
        },
    },
    {
        ETA = 33,
        Qpart = {
            [50076] = {
                2,
            },
        },
        Range = 19.19,
        Coord = {
            x = 1378,
            y = 806.4,
        },
    },
    {
        Done = {
            50076,
        },
        Coord = {
            x = 1379.5,
            y = 806.1,
        },
    },
    {
        PickUp = {
            50138,
        },
        Coord = {
            x = 1379.5,
            y = 806.1,
        },
    },
    {
        Waypoint = 50138,
        Range = 14.37,
        Coord = {
            x = 1347.8,
            y = 819.1,
        },
    },
    {
        Waypoint = 50138,
        Range = 7.12,
        Coord = {
            x = 1372,
            y = 845,
        },
    },
    {
        Qpart = {
            [50138] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 1223.9,
            y = 990.2,
        },
    },
    {
        PickUp = {
            50078,
        },
        Coord = {
            x = 1223.9,
            y = 990.2,
        },
    },
    {
        Qpart = {
            [50138] = {
                2,
            },
            [50078] = {
                1,
            },
        },
        Range = 18.27,
        Coord = {
            x = 1216.8,
            y = 991.9,
        },
    },
    {
        Qpart = {
            [50138] = {
                3,
            },
        },
        Range = 10.07,
        Coord = {
            x = 1097.5,
            y = 1123.5,
        },
    },
    {
        Done = {
            50138,
            50078,
        },
        Coord = {
            x = 1086.8,
            y = 1124,
        },
    },
    {
        PickUp = {
            50079,
            50081,
        },
        Coord = {
            x = 1085.5,
            y = 1129.9,
        },
    },
    {
        Qpart = {
            [50079] = {
                1,
            },
        },
        Fillers = {
            [50081] = {
                1,
            },
        },
        Button = {
            ["50079-1"] = 156847,
        },
        ButtonSpellId = {
            [261695] = "50079-1",
        },
        ButtonCooldown = {
            [261695] = 5,
        },
        Range = 11.83,
        Coord = {
            x = 1103.5,
            y = 1174,
        },
    },
    {
        Qpart = {
            [50079] = {
                2,
            },
        },
        Fillers = {
            [50081] = {
                1,
            },
        },
        Button = {
            ["50079-2"] = 156847,
        },
        ButtonSpellId = {
            [261695] = "50079-2",
        },
        ButtonCooldown = {
            [261695] = 5,
        },
        Range = 13.14,
        Coord = {
            x = 1123,
            y = 1238.5,
        },
    },
    {
        Qpart = {
            [50079] = {
                3,
            },
        },
        Fillers = {
            [50081] = {
                1,
            },
        },
        Button = {
            ["50079-3"] = 156847,
        },
        ButtonSpellId = {
            [261695] = "50079-3",
        },
        ButtonCooldown = {
            [261695] = 5,
        },
        Range = 11.21,
        Coord = {
            x = 1127.2,
            y = 1287,
        },
    },
    {
        Qpart = {
            [50081] = {
                1,
            },
        },
        Range = 18.87,
        Coord = {
            x = 1130.5,
            y = 1291.5,
        },
    },
    {
        Done = {
            50079,
            50081,
        },
        Coord = {
            x = 1124.9,
            y = 1324.4,
        },
    },
    {
        PickUp = {
            50082,
        },
        Coord = {
            x = 1124.9,
            y = 1324.4,
        },
    },
    {
        Qpart = {
            [50082] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1081.3,
            y = 1392.3,
        },
    },
    {
        Qpart = {
            [50082] = {
                2,
            },
        },
        Range = 11.4,
        Coord = {
            x = 1058.5,
            y = 1421.3,
        },
    },
    {
        Done = {
            50082,
        },
        Coord = {
            x = 1071,
            y = 1408.8,
        },
    },
    {
        PickUp = {
            52073,
        },
        Coord = {
            x = 1071,
            y = 1408.8,
        },
    },
    {

        PickUp = {
            50083,
        },
        Coord = {
            x = 1061.9,
            y = 1474,
        },
    },
    {

        Qpart = {
            [50083] = {
                1,
            },
        },
        Range = 17.7,
        Coord = {
            x = 997.7,
            y = 1589.7,
        },
    },
    {

        Range = 7.51,
        Waypoint = 50083,
        Coord = {
            x = 934.7,
            y = 1640.3,
        },
    },
    {

        Range = 5.83,
        Waypoint = 50083,
        Coord = {
            x = 948.5,
            y = 1643.4,
        },
    },
    {

        Qpart = {
            [50083] = {
                2,
            },
        },
        Button = {
            ["50083-2"] = 156868,
        },
        Range = 7.64,
        Coord = {
            x = 973.4,
            y = 1637.5,
        },
    },
    {

        Coord = {
            x = 911.7,
            y = 1652.3,
        },
        Done = {
            50083,
        },
    },
    {

        PickUp = {
            50085,
        },
        Coord = {
            x = 911.1,
            y = 1652.5,
        },
    },
    {

        Qpart = {
            [50085] = {
                1,
            },
        },
        Fillers = {
            [50080] = {
                1,
            },
        },
        Button = {
            ["50085-1"] = 156931,
        },
        ButtonSpellId = {
            [262125] = "50085-1",
        },
        ButtonCooldown = {
            [262125] = 5,
        },
        Range = 24.94,
        Coord = {
            x = 905.6,
            y = 1654.5,
        },
    },
    {

        Qpart = {
            [50080] = {
                1,
            },
        },
        Range = 52.77,
        Coord = {
            x = 1027.5,
            y = 1709.3,
        },
    },
    {

        Waypoint = 50085,
        Range = 19,
        Coord = {
            x = 1058,
            y = 1652.9,
        },
    },
    {

        Done = {
            50085,
        },
        Coord = {
            x = 1112.9,
            y = 1634.2,
        },
    },
    {

        Waypoint = 52073,
        Range = 25.81,
        Coord = {
            x = 1061.5,
            y = 1508.2,
        },
    },
    {
        Qpart = {
            [52073] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1072.8,
            y = 1403.2,
        },
    },
    {
        Qpart = {
            [52073] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 1072.8,
            y = 1403.2,
        },
    },
    {
        Coord = {
            x = 853.1,
            y = 1525.5,
        },
        Done = {
            52073,
        },
    },
    {
        PickUp = {
            50087,
        },
        Coord = {
            x = 853.1,
            y = 1525.5,
        },
    },
    {
        Bloodlust = 1,
        Qpart = {
            [50087] = {
                1,
            },
        },
        Range = 7.86,
        Coord = {
            x = 786.2,
            y = 1498.4,
        },
    },
    {
        Coord = {
            x = 804.2,
            y = 1480.9,
        },
        Done = {
            50087,
        },
    },
    {
        PickUp = {
            51244,
        },
        Coord = {
            x = 792.9,
            y = 1482.4,
        },
    },
    {
        ExtraLineText = "TALK_ROKHAN_RIDE_DOWN",
        Gossip = 1,
        Range = 14.61,
        Waypoint = 51244,
        Coord = {
            x = 792.9,
            y = 1482.4,
        },
    },
    {
        Range = 27.39,
        Waypoint = 51244,
        Coord = {
            x = 642.7,
            y = 1050.3,
        },
    },
    {
        Coord = {
            x = 738.7,
            y = 1237.4,
        },
        Done = {
            51244,
        },
    },
    {
        PickUp = {
            50808,
        },
        Coord = {
            x = 735.1,
            y = 1239.9,
        },
        LeaveQuest = 51302,
    },
    {
        ExtraLineText = "TALK_ROKHAN_RIDE_ZULJAN",
        Range = 5,
        Waypoint = 50808,
        Coord = {
            x = 735.1,
            y = 1239.9,
        },
        LeaveQuest = 51302,
    },
    {
        UseFlightPath = 50808,
        Name = "The Great Seal",
        NodeID = 1959,
        Coord = {
            x = 1403.8,
            y = 791.5,
        },
    },
    {
        ZoneDoneSave = 1
    },
}
--end of Nazmir start of Vol'dun
APR.RouteQuestStepList["862-Zuldazar-2"] = {
    {
        Range = 5,
        Waypoint = 50808,
        Coord = {
            x = 802.7,
            y = -1047.5,
        },
    },
    {
        Coord = {
            x = 818.6,
            y = -1124.3,
        },
        Done = {
            50808,
        },
        LeaveQuest = 52210,
    },
    {
        PickUp = {
            47513,

        },
        Coord = {
            x = 818.7,
            y = -1120.8,
        },
        LeaveQuest = 47199,
    },
    {
        Coord = {
            x = 819,
            y = -1120,
        },
        Done = {
            47513,
        },
        LeaveQuest = 52210,
    },
    {
        PickUp = {
            47313,
        },
        Coord = {
            x = 818.9,
            y = -1119.6,
        },
    },
    {
        Range = 5,
        Waypoint = 47313,
        Coord = {
            x = 800.9,
            y = -1046.8,
        },
    },
    {
        Range = 5,
        Waypoint = 47313,
        Coord = {
            x = 778.2,
            y = -1018.2,
        },
    },
    {
        QpartPart = {
            [47313] = {
                1,
            },
        },
        TrigText = "1/3",
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 799.7,
            y = -964.5,
        },
    },
    {
        Range = 5,
        Waypoint = 47313,
        Coord = {
            x = 753.6,
            y = -961.9,
        },
    },
    {
        Waypoint = 47313,
        Range = 6.93,
        Coord = {
            x = 744.7,
            y = -1001.6,
        },
    },
    {
        QpartPart = {
            [47313] = {
                1,
            },
        },
        TrigText = "2/3",
        Gossip = 1,
        Range = 1,
        Coord = {
            x = 741.4,
            y = -966.5,
        },
    },
    {
        Waypoint = 47313,
        Range = 6.93,
        Coord = {
            x = 676.5,
            y = -963.4,
        },
    },
    {
        QpartPart = {
            [47313] = {
                1,
            },
        },
        TrigText = "3/3",
        Gossip = 1,
        Range = 1,
        Coord = {
            x = 683.1,
            y = -934.7,
        },
    },
    {
        Waypoint = 47313,
        Range = 9.14,
        Coord = {
            x = 711.2,
            y = -878,
        },
    },
    {
        Done = {
            47313,
        },
        Coord = {
            x = 760.2,
            y = -859.3,
        },
    },
    {
        PickUp = {
            47314,
        },
        Coord = {
            x = 760.2,
            y = -859.3,
        },
    },
    {
        ETA = 40,
        ExtraLineText = "TALK_ROKHAN_RIDE_ZULJAN",
        --RaidIcon = 122320,
        Done = {
            47314,
        },
        Coord = {
            x = 803.4,
            y = -857.5,
        },
    },
    {
        PickUp = {
            47315,
        },
        Coord = {
            x = 803.4,
            y = -857.2,
        },
    },
    {
        Qpart = {
            [47315] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 799.6,
            y = -859,
        },
    },
    {
        ETA = 99,
        Qpart = {
            [47315] = {
                2,
            },
        },
        Range = 176.02,
        Coord = {
            x = 789.7,
            y = -675.7,
        },
    },
    {
        ZoneDoneSave = 1
    },
}
-- Vol'dun
APR.RouteQuestStepList["864-Vol'dun"] = {
    {
        Done = {
            47315,
        },
        Coord = {
            x = 2194.4,
            y = 2673.5,
        },
    },
    {
        PickUp = {
            51357,
        },
        Coord = {
            x = 2194.4,
            y = 2673.5,
        },
    },
    {
        ExtraLineText = "WEAPON_PICK_DOESNT_MATTER",
        Qpart = {
            [51357] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2197.1,
            y = 2673.6,
        },

    },
    {
        Done = {
            51357,
        },
        Coord = {
            x = 2195.1,
            y = 2673.5,
        },
    },
    {
        PickUp = {
            47327,
            49676,
        },
        Coord = {
            x = 2195.1,
            y = 2673.5,
        },
    },
    {
        Waypoint = 49676,
        Range = 8.78,
        Coord = {
            x = 2243.9,
            y = 2648.5,
        },
    },
    {
        Waypoint = 49676,
        Range = 5.61,
        Coord = {
            x = 2267.8,
            y = 2688.8,
        },
    },
    {
        Qpart = {
            [49676] = {
                1,
            },
        },
        Fillers = {
            [47327] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2283.4,
            y = 2797.5,
        },
    },
    {
        Qpart = {
            [49676] = {
                2,
            },
        },
        Fillers = {
            [47327] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2355.4,
            y = 2852,
        },
    },
    {
        Qpart = {
            [49676] = {
                3,
            },
        },
        Fillers = {
            [47327] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2475.1,
            y = 2804.4,
        },
    },
    {
        Coord = {
            x = 2495.1,
            y = 2831.6,
        },
        Done = {
            49676,
        },
    },
    {
        PickUp = {
            49677,
        },
        Coord = {
            x = 2495.1,
            y = 2831.6,
        },
    },
    {
        Qpart = {
            [49677] = {
                1,
            },
        },
        Fillers = {
            [47327] = {
                1,
            },
        },
        Range = 16.29,
        Coord = {
            x = 2539.6,
            y = 2857.1,
        },
    },
    {
        Qpart = {
            [47327] = {
                1,
            },
        },
        Range = 16.94,
        Coord = {
            x = 2539.6,
            y = 2857.1,
        },
    },
    {
        Coord = {
            x = 2541.6,
            y = 2878.8,
        },
        Done = {
            47327,
            49677,
        },
    },
    {
        PickUp = {
            51364,
        },
        Coord = {
            x = 2541.6,
            y = 2878.8,
        },
    },
    {
        Qpart = {
            [51364] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2595.9,
            y = 2769,
        },
    },
    {
        Qpart = {
            [51364] = {
                2,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2597.1,
            y = 2768.5,
        },
    },
    {
        ExtraLineText = "EXTRA_ACTION_BUTTON_NOT_NEEDED",
        ETA = 72,
        Qpart = {
            [51364] = {
                3,
            },
        },
        Range = 4.35,
        Coord = {
            x = 2798,
            y = 2044.9,
        },
    },
    {
        Done = {
            51364,
        },
        Coord = {
            x = 2821,
            y = 2042.5,
        },
    },
    {
        PickUp = {
            47319,
        },
        Coord = {
            x = 2821,
            y = 2042.5,
        },
    },
    {
        PickUp = {
            51574,
        },
        Coord = {
            x = 2822.6,
            y = 2043,
        },
    },
    {
        GetFP = 2117,
        Range = 3.37,
        Coord = {
            x = 2809.9,
            y = 2100.3,
        },
    },
    {
        PickUp = {
            50739,
        },
        Coord = {
            x = 2929.1,
            y = 2140.9,
        },
    },
    {
        Qpart = {
            [50739] = {
                1,
            },
            [51574] = {
                1,
            },
            [47319] = {
                1,
            },
        },
        Range = 18.73,
        Coord = {
            x = 2973.1,
            y = 2116,
        },
    },
    {
        Done = {
            50739,
        },
        Coord = {
            x = 2929.1,
            y = 2140.9,
        },
    },
    {
        Done = {
            51574,
            47319,
        },
        Coord = {
            x = 2822,
            y = 2042.8,
        },
    },
    {
        PickUp = {
            47320,
        },
        Coord = {
            x = 2822.1,
            y = 2044.4,
        },
    },
    {
        Qpart = {
            [47320] = {
                1,
            },
        },
        Button = {
            ["47320-1"] = 150759,
        },
        Range = 0.75,
        Coord = {
            x = 2818.3,
            y = 2044.3,
        },
    },
    {
        Done = {
            47320,
        },
        Coord = {
            x = 2818.1,
            y = 2044.4,
        },
    },
    {
        PickUp = {
            47321,
            47317,
            47316,
        },
        Coord = {
            x = 2820.4,
            y = 2043.9,
        },
    },
    {
        QpartPart = {
            [47316] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "1/4",
        Coord = {
            x = 2890.5,
            y = 2126.6,
        },
    },
    {
        QpartPart = {
            [47316] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "2/4",
        Coord = {
            x = 2852.6,
            y = 2342.9,
        },
    },
    {
        QpartPart = {
            [47316] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "3/4",
        Coord = {
            x = 3093.1,
            y = 2230.5,
        },
    },
    {
        QpartPart = {
            [47316] = {
                1,
            },
        },
        Range = 0.75,
        TrigText = "4/4",
        Coord = {
            x = 3094.3,
            y = 2439.1,
        },
    },
    {
        PickUp = {
            47322,
            50755,
        },
        Coord = {
            x = 2962.1,
            y = 2410.4,
        },
    },
    {
        Qpart = {
            [47322] = {
                2,
            },
        },
        Fillers = {
            [50755] = {
                1,
            },
            [47321] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2959.3,
            y = 2507.4,
        },
    },
    {
        Qpart = {
            [47317] = {
                1,
            },
        },
        Fillers = {
            [50755] = {
                1,
            },
            [47321] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2968.5,
            y = 2549.5,
        },
    },
    {
        Qpart = {
            [47322] = {
                1,
            },
        },
        Fillers = {
            [50755] = {
                1,
            },
            [47321] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 2847.5,
            y = 2554.6,
        },
    },
    {
        Qpart = {
            [47317] = {
                2,
            },
        },
        Fillers = {
            [50755] = {
                1,
            },
            [47321] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 2778.5,
            y = 2494,
        },
    },
    {
        Qpart = {
            [50755] = {
                1,
            },
            [47321] = {
                1,
            },
        },
        Range = 26.04,
        Coord = {
            x = 2784.5,
            y = 2501.4,
        },
    },
    {
        Done = {
            50755,
            47322,
        },
        Coord = {
            x = 2961.6,
            y = 2410.8,
        },
    },
    {
        Done = {
            47321,
            47317,
            47316,
        },
        Coord = {
            x = 2819.6,
            y = 2043,
        },
    },
    {
        PickUp = {
            47959,
        },
        Coord = {
            x = 2818.1,
            y = 2043.5,
        },
    },
    {
        Qpart = {
            [47959] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 2823.3,
            y = 2043.2,
        },
    },
    {
        Qpart = {
            [47959] = {
                2,
            },
        },
        ETA = 79,
        Range = 3.52,
        Coord = {
            x = 3051.1,
            y = 1344,
        },
    },
    {
        Done = {
            47959,
        },
        Coord = {
            x = 3081.1,
            y = 1316.8,
        },
    },
    {
        PickUp = {
            48549,
            48550,
        },
        Coord = {
            x = 3081.8,
            y = 1316.9,
        },
    },
    {
        PickUp = {
            51829,
        },
        Coord = {
            x = 3235.8,
            y = 1401.5,
        },
        Fillers = {
            [48550] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48549] = {
                1,
            },
        },
        Fillers = {
            [48550] = {
                1,
            },
        },
        Range = 18,
        Coord = {
            x = 3325.6,
            y = 1400.2,
        },
    },
    {
        Qpart = {
            [48550] = {
                1,
            },
        },
        Range = 30.47,
        Coord = {
            x = 3318.1,
            y = 1396.7,
        },
    },
    {
        UseGlider = 1,
        Coord = {
            x = 3020.5,
            y = 1186.9,
        },
        Done = {
            51829,
        },
    },
    {
        PickUp = {
            48551,
            48553,
            48555,
        },
        Coord = {
            x = 3021,
            y = 1187.5,
        },
    },
    {
        Qpart = {
            [48553] = {
                1,
            },
        },
        Fillers = {
            [48555] = {
                1,
            },
            [48551] = {
                1,
            },
        },
        Button = {
            ["48551-1"] = 152630,
        },
        Range = 0.69,
        Coord = {
            x = 3050.6,
            y = 1257.5,
        },
    },
    {
        Qpart = {
            [48553] = {
                2,
            },
        },
        Fillers = {
            [48555] = {
                1,
            },
            [48551] = {
                1,
            },
        },
        Button = {
            ["48551-1"] = 152630,
        },
        Range = 0.75,
        Coord = {
            x = 3084.1,
            y = 1071.9,
        },
    },
    {
        Qpart = {
            [48555] = {
                1,
            },
            [48551] = {
                1,
            },
        },
        Button = {
            ["48551-1"] = 152630,
        },
        Range = 37.87,
        Coord = {
            x = 3084.1,
            y = 1071.9,
        },
    },
    {
        Done = {
            48551,
            48553,
            48555,
        },
        Coord = {
            x = 3021.9,
            y = 1187.3,
        },
    },
    {
        PickUp = {
            48554,
        },
        Coord = {
            x = 3021.9,
            y = 1187.3,
        },
    },
    {
        Waypoint = 48554,
        Range = 8.68,
        Coord = {
            x = 3025.3,
            y = 1227.7,
        },
    },
    {
        Waypoint = 48554,
        Range = 8.86,
        Coord = {
            x = 2993.3,
            y = 1294.9,
        },
    },
    {
        Waypoint = 48554,
        Range = 13.27,
        Coord = {
            x = 2960.5,
            y = 1295.5,
        },
    },
    {
        Waypoint = 48554,
        Range = 15.05,
        Coord = {
            x = 2929.8,
            y = 1262.5,
        },
    },
    {
        Qpart = {
            [48554] = {
                1,
            },
        },
        Range = 7.07,
        Coord = {
            x = 2919.9,
            y = 1193,
        },
    },
    {
        Qpart = {
            [48554] = {
                2,
            },
        },
        Range = 16,
        Coord = {
            x = 2919.9,
            y = 1196.4,
        },
    },
    {
        Done = {
            48554,
        },
        Coord = {
            x = 3020,
            y = 1188.3,
        },
    },
    {
        Coord = {
            x = 3063.6,
            y = 1338.3,
        },
        Done = {
            48550,
            48549,
        },
    },
    {
        PickUp = {
            48684,
        },
        Coord = {
            x = 3065.5,
            y = 1337.8,
        },
    },
    {
        Qpart = {
            [48684] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 3065.5,
            y = 1337.8,
        },
    },
    {
        Qpart = {
            [48684] = {
                2,
            },
        },
        ETA = 127,
        Range = 11.05,
        Coord = {
            x = 3089.8,
            y = 286,
        },
    },
    {
        Done = {
            48684,
        },
        Coord = {
            x = 3091.5,
            y = 285.5,
        },
    },
    {
        PickUp = {
            48895,
        },
        Coord = {
            x = 3090.6,
            y = 285.3,
        },
    },
    {
        Done = {
            48895,
        },
        LeaveQuest = 49040,
        Coord = {
            x = 3067,
            y = 238.5,
        },
    },
    {
        PickUp = {
            48992,
            48991,
            48993,
        },
        LeaveQuest = 49040,
        Coord = {
            x = 3067,
            y = 238.5,
        },
    },
    {
        LeaveQuest = 49040,
        GetFP = 2118,
        Range = 10.72,
        Coord = {
            x = 3031.1,
            y = 287.3,
        },
        Fillers = {
            [48991] = {
                1,
            },
            [48992] = {
                1,
            },
        },
    },
    {
        Waypoint = 48993,
        Range = 9.27,
        Coord = {
            x = 2944.1,
            y = 422.2,
        },
        Fillers = {
            [48991] = {
                1,
            },
            [48992] = {
                1,
            },
        },
    },
    {
        Waypoint = 48993,
        Range = 6.13,
        Coord = {
            x = 2897.6,
            y = 430.3,
        },
        Fillers = {
            [48991] = {
                1,
            },
            [48992] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48993] = {
                1,
            },
        },
        Fillers = {
            [48991] = {
                1,
            },
            [48992] = {
                1,
            },
        },
        Range = 17.22,
        Coord = {
            x = 2869.5,
            y = 544.6,
        },
    },
    {
        Qpart = {
            [48991] = {
                1,
            },
            [48992] = {
                1,
            },
        },
        Range = 21.98,
        Coord = {
            x = 2889,
            y = 504.3,
        },
    },
    {
        Done = {
            48992,
            48991,
            48993,
        },
        Coord = {
            x = 3067.1,
            y = 237.9,
        },
    },
    {
        PickUp = {
            48888,
            48887,
        },
        Coord = {
            x = 3067.1,
            y = 237.9,
        },
    },
    {
        ExtraLineText = "DOTS_EXPIRE",
        Qpart = {
            [48887] = {
                1,
            },
        },
        Fillers = {
            [48888] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3136.3,
            y = 551.7,
        },
    },
    {
        Qpart = {
            [48887] = {
                2,
            },
        },
        Fillers = {
            [48888] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 3136,
            y = 551.7,
        },
    },
    {
        Qpart = {
            [48888] = {
                1,
            },
        },
        Range = 15.94,
        Coord = {
            x = 3134.1,
            y = 525.2,
        },
    },
    {
        Done = {
            48888,
            48887,
        },
        Coord = {
            x = 3066.9,
            y = 237.1,
        },
    },
    {
        PickUp = {
            48894,
        },
        Coord = {
            x = 3066.9,
            y = 237.1,
        },
    },
    {
        Qpart = {
            [48894] = {
                1,
            },
        },
        Gossip = 3,
        Range = 0.69,
        Coord = {
            x = 3066.9,
            y = 237.1,
        },
    },
    {
        Done = {
            48894,
        },
        Coord = {
            x = 3067.1,
            y = 238.1,
        },
    },
    {
        PickUp = {
            48715,
        },
        Coord = {
            x = 3068.6,
            y = 241.5,
        },
    },
    {
        Qpart = {
            [48715] = {
                1,
            },
        },
        Range = 3.27,
        Coord = {
            x = 3066.6,
            y = 184.4,
        },
    },
    {
        Done = {
            48715,
        },
        Coord = {
            x = 3040.1,
            y = 176.1,
        },
    },
    {
        PickUp = {
            48987,
        },
        Coord = {
            x = 3040.1,
            y = 188.6,
        },
    },
    {
        Waypoint = 48987,
        Range = 7.74,
        Coord = {
            x = 3062.4,
            y = 193.6,
        },
    },
    {
        Waypoint = 48987,
        Range = 11.03,
        Coord = {
            x = 3075.9,
            y = 267.1,
        },
    },
    {
        SetHS = 48987,
        Coord = {
            x = 3151.6,
            y = 260.7,
        },
    },
    {
        Waypoint = 48987,
        Range = 16.03,
        Coord = {
            x = 3082.3,
            y = 366.3,
        },
    },
    {
        UseGlider = 1,
        Waypoint = 48987,
        Range = 51.77,
        Coord = {
            x = 3037.5,
            y = 691.6,
        },
    },
    {
        Done = {
            48987,
        },
        Coord = {
            x = 3079,
            y = 760.9,
        },
    },
    {
        PickUp = {
            48988,
            49005,
        },
        Coord = {
            x = 3079,
            y = 760.9,
        },
    },
    {
        Qpart = {
            [48988] = {
                1,
            },
            [49005] = {
                1,
                2,
            },
        },
        Range = 27.77,
        Coord = {
            x = 3084,
            y = 814.4,
        },
    },
    {
        Done = {
            48988,
            49005,
        },
        Coord = {
            x = 3077.9,
            y = 761.2,
        },
    },
    {
        PickUp = {
            48889,
        },
        Coord = {
            x = 3077.9,
            y = 761.2,
        },
    },
    {
        RaidIcon = 127989,
        Waypoint = 48889,
        Range = 6.95,
        Coord = {
            x = 3107.4,
            y = 741.4,
        },
    },
    {
        Qpart = {
            [48889] = {
                1,
            },
        },
        Range = 12.65,
        Coord = {
            x = 3125,
            y = 718.2,
        },
    },
    {
        Done = {
            48889,
        },
        Coord = {
            x = 3128.1,
            y = 712.5,
        },
    },
    {
        PickUp = {
            48996,
        },
        Coord = {
            x = 3128.1,
            y = 712.5,
        },
    },
    {
        UseHS = 48996,
        Coord = {
            x = 3128.1,
            y = 712.5,
        },
        Button = {
            ["22345678-1"] = 6948,
        },
    },
    {
        Waypoint = 48996,
        Range = 11.47,
        Coord = {
            x = 3075.5,
            y = 268.8,
        },
    },
    {
        ExtraActionB = 1,
        Qpart = {
            [48996] = {
                1,
            },
        },
        Range = 12.05,
        Coord = {
            x = 3067.1,
            y = 203.9,
        },
    },
    {
        Done = {
            48996,
        },
        Coord = {
            x = 3067,
            y = 178.6,
        },
    },
    {
        PickUp = {
            50913,
        },
        Coord = {
            x = 3067.1,
            y = 180.6,
        },
    },
    {
        Qpart = {
            [50913] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 3066.9,
            y = 152.1,
        },
    },
    {
        Done = {
            50913,
        },
        Coord = {
            x = 3065.3,
            y = 177.8,
        },
    },
    {
        PickUp = {
            47874,
        },
        Coord = {
            x = 3038.8,
            y = 175.6,
        },
    },
    {
        RaidIcon = 130667,
        Coord = {
            x = 3093.1,
            y = 284.8,
        },
        ETA = 53,
        Done = {
            47874,
        },
    },
    {
        PickUp = {
            48896,
        },
        Coord = {
            x = 3093.1,
            y = 284.8,
        },
    },
    {
        Qpart = {
            [48896] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 3099.1,
            y = 282.5,
        },
    },
    {
        Qpart = {
            [48896] = {
                2,
            },
        },
        ETA = 59,
        Range = 7.33,
        Coord = {
            x = 3426.4,
            y = 596.6,
        },
    },
    {
        Qpart = {
            [48896] = {
                3,
            },
        },
        Range = 7.33,
        Coord = {
            x = 3426.4,
            y = 596.6,
        },
    },
    {
        Done = {
            48896,
        },
        Coord = {
            x = 3437.1,
            y = 609.2,
        },
    },
    {
        PickUp = {
            47716,
        },
        Coord = {
            x = 3437.1,
            y = 609.2,
        },
    },
    {
        Waypoint = 47716,
        Range = 11.68,
        Coord = {
            x = 3503.6,
            y = 817.7,
        },
    },
    {
        Qpart = {
            [47716] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 3513,
            y = 882.7,
        },
    },
    {
        Done = {
            47716,
        },
        Coord = {
            x = 3483.6,
            y = 901.2,
        },
    },
    {
        PickUp = {
            48314,
            48313,
        },
        Coord = {
            x = 3484.6,
            y = 903.9,
        },
    },
    {
        PickUp = {
            51573,
        },
        Fillers = {
            [48314] = {
                1,
            },
            [48313] = {
                1,
            },
        },
        Coord = {
            x = 3731.3,
            y = 915.6,
        },
    },
    {
        Qpart = {
            [51573] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 3731.3,
            y = 915.6,
        },
    },
    {
        ETA = 81,
        SpecialETAHide = 1,
        GetFP = 2143,
        Range = 5.91,
        Coord = {
            x = 3699.4,
            y = 890.1,
        },
    },
    {
        SpecialETAHide = 1,
        SetHS = 51573,
        Coord = {
            x = 3757.6,
            y = 865.7,
        },
    },
    {
        Qpart = {
            [51573] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3733.9,
            y = 977.1,
        },
    },
    {
        Done = {
            51573,
        },
        Coord = {
            x = 3733.6,
            y = 969.2,
        },
    },
    {
        PickUp = {
            48529,
            48530,
        },
        Coord = {
            x = 3731.6,
            y = 970.4,
        },
    },
    {
        Done = {
            48529,
        },
        Coord = {
            x = 3713.3,
            y = 850.5,
        },
    },
    {
        PickUp = {
            48531,
            48533,
        },
        Coord = {
            x = 3713.3,
            y = 850.5,
        },
    },
    {
        Waypoint = 48530,
        Range = 10.91,
        Coord = {
            x = 3747.1,
            y = 836.9,
        },
    },
    {
        Waypoint = 48530,
        Range = 9.72,
        Coord = {
            x = 3788.8,
            y = 837.9,
        },
    },
    {
        Done = {
            48530,
        },
        Coord = {
            x = 3820.3,
            y = 877.1,
        },
    },
    {
        PickUp = {
            48532,
        },
        Coord = {
            x = 3820.3,
            y = 877.1,
        },
    },
    {
        PickUp = {
            48585,
        },
        Coord = {
            x = 3935.6,
            y = 992.1,
        },
        Fillers = {
            [48532] = {
                1,
            },
            [48585] = {
                1,
            },
            [48531] = {
                1,
            },
        },
        Button = {
            ["48532-1"] = 152570,
        },
        ButtonSpellId = {
            [251267] = "48532-1",
        },
        ButtonCooldown = {
            [251267] = 5,
        },
    },
    {
        Qpart = {
            [48532] = {
                1,
            },
            [48585] = {
                1,
            },
            [48531] = {
                1,
            },
        },
        Button = {
            ["48532-1"] = 152570,
        },
        ButtonSpellId = {
            [251267] = "48532-1",
        },
        ButtonCooldown = {
            [251267] = 5,
        },
        Range = 26.52,
        Coord = {
            x = 3935.6,
            y = 992.1,
        },
    },
    {
        Qpart = {
            [48533] = {
                1,
            },
        },
        Button = {
            ["48533-1"] = 152572,
        },
        ButtonSpellId = {
            [251288] = "48533-1",
        },
        ButtonCooldown = {
            [251288] = 2,
        },
        Range = 18.77,
        Coord = {
            x = 3806.1,
            y = 939.5,
        },
    },
    {
        Coord = {
            x = 3734,
            y = 915,
        },
        Done = {
            48585,
        },
    },
    {
        Coord = {
            x = 3713,
            y = 850.1,
        },
        Done = {
            48531,
            48533,
        },
    },
    {
        PickUp = {
            48655,
        },
        Coord = {
            x = 3713,
            y = 850.1,
        },
    },
    {
        Range = 10.15,
        Waypoint = 48655,
        Coord = {
            x = 3755.5,
            y = 833.7,
        },
    },
    {
        Coord = {
            x = 3820.4,
            y = 875.9,
        },
        Done = {
            48532,
        },
    },
    {
        PickUp = {
            48534,
        },
        Coord = {
            x = 3819.3,
            y = 876,
        },
    },
    {
        Range = 6.15,
        Waypoint = 48655,
        Coord = {
            x = 3732.1,
            y = 738.6,
        },
    },
    {
        Coord = {
            x = 3734,
            y = 765.7,
        },
        Done = {
            48655,
        },
    },
    {
        PickUp = {
            48656,
            48657,
        },
        Coord = {
            x = 3734,
            y = 765.7,
        },
    },
    {
        Waypoint = 48534,
        Range = 11.36,
        Coord = {
            x = 3730.6,
            y = 592.5,
        },
        Fillers = {
            [48657] = {
                1,
            },
            [48656] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48534] = {
                1,
            },
        },
        Range = 7.87,
        Coord = {
            x = 3768.6,
            y = 510.1,
        },
        Fillers = {
            [48657] = {
                1,
            },
            [48656] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48657] = {
                1,
            },
            [48656] = {
                1,
            },
        },
        Range = 13.63,
        Coord = {
            x = 3727.1,
            y = 594.9,
        },
    },
    {
        Coord = {
            x = 3736.4,
            y = 765.5,
        },
        Done = {
            48656,
            48657,
        },
    },
    {
        Waypoint = 48534,
        Range = 11.23,
        Coord = {
            x = 3729.1,
            y = 737,
        },
    },
    {
        Waypoint = 48534,
        Range = 8.69,
        Coord = {
            x = 3664.6,
            y = 740.7,
        },
    },
    {
        Waypoint = 48534,
        Range = 10.13,
        Coord = {
            x = 3664.6,
            y = 755.9,
        },
    },
    {
        Waypoint = 48534,
        Range = 7.98,
        Coord = {
            x = 3707.9,
            y = 765.6,
        },
    },
    {
        Waypoint = 48534,
        Range = 11.59,
        Coord = {
            x = 3735.3,
            y = 810.2,
        },
    },
    {
        Waypoint = 48534,
        Range = 13.34,
        Coord = {
            x = 3789.1,
            y = 837.2,
        },
    },
    {
        Done = {
            48534,
        },
        Coord = {
            x = 3819.6,
            y = 876.4,
        },
    },
    {
        Waypoint = 51668,
        Range = 12.48,
        Coord = {
            x = 3786.1,
            y = 836.1,
        },
    },
    {
        PickUp = {
            48846,
        },
        Coord = {
            x = 3744.1,
            y = 842.7,
        },
    },
    {
        BuyMerchant = 160499,
        Qpart = {
            [48846] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3767.9,
            y = 870.7,
        },
    },
    {
        Qpart = {
            [48846] = {
                2,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 3744.1,
            y = 843.7,
        },
    },
    {
        Done = {
            48846,
        },
        Coord = {
            x = 3733.6,
            y = 914.7,
        },
    },
    {
        PickUp = {
            51602,
            48790,
            48850,
        },
        Coord = {
            x = 3733.6,
            y = 914.7,
        },
    },
    {
        Range = 8.84,
        Waypoint = 48850,
        Coord = {
            x = 3946.6,
            y = 885.2,
        },
        Fillers = {
            [48790] = {
                1,
            },
            [51602] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48850] = {
                1,
            },
        },
        Fillers = {
            [48790] = {
                1,
            },
            [51602] = {
                1,
            },
        },
        Range = 6.4,
        Coord = {
            x = 3909.9,
            y = 886.1,
        },
    },
    {
        Qpart = {
            [51602] = {
                1,
            },
            [48790] = {
                1,
            },
        },
        Range = 16.25,
        Coord = {
            x = 3921.4,
            y = 886,
        },
    },
    {
        Coord = {
            x = 3733.4,
            y = 915.5,
        },
        Done = {
            51602,
            48790,
            48850,
        },
    },
    {
        PickUp = {
            48847,
        },
        Coord = {
            x = 3733.4,
            y = 915.5,
        },
    },
    {
        Qpart = {
            [48847] = {
                1,
            },
        },
        Gossip = 1,
        Range = 19.64,
        Coord = {
            x = 3734.1,
            y = 878.4,
        },
    },
    {
        Done = {
            48847,
        },
        Coord = {
            x = 3733.9,
            y = 915.7,
        },
    },
    {
        PickUp = {
            51668,
        },
        Coord = {
            x = 3733.9,
            y = 915.7,
        },
    },
    {
        Qpart = {
            [51668] = {
                1,
            },
        },
        Button = {
            ["51668-1"] = 160525,
        },
        Range = 8.87,
        Coord = {
            x = 3733,
            y = 979.7,
        },
    },
    {
        Coord = {
            x = 3733.6,
            y = 915.1,
        },
        Done = {
            51668,
        },
    },
    {
        PickUp = {
            51161,
        },
        Coord = {
            x = 3750.9,
            y = 861.2,
        },
    },
    {
        PickUp = {
            51772,
        },
        Coord = {
            x = 3713.4,
            y = 850.7,
        },
    },
    {
        Fillers = {
            [48314] = {
                1,
            },
            [48313] = {
                1,
            },
        },
        Range = 17.19,
        Waypoint = 51161,
        Coord = {
            x = 3526.5,
            y = 920.7,
        },
    },
    {
        Range = 11.59,
        Waypoint = 51161,
        Coord = {
            x = 3509.1,
            y = 971.7,
        },
    },
    {
        Qpart = {
            [51161] = {
                1,
            },
        },
        Range = 17.73,
        Coord = {
            x = 3475.6,
            y = 1004.2,
        },
    },
    {
        PickUp = {
            51775,
        },
        Fillers = {
            [48313] = {
                1,
            },
            [48314] = {
                1,
            },
        },
        Coord = {
            x = 3819.4,
            y = 876.7,
        },
    },
    {
        Done = {
            51775,
        },
        Coord = {
            x = 4041.6,
            y = 826.7,
        },
    },
    {
        PickUp = {
            48324,
        },
        Coord = {
            x = 4041.6,
            y = 826.7,
        },
    },
    {
        PickUp = {
            51162,
        },
        Coord = {
            x = 4042.9,
            y = 842,
        },
    },
    {
        Waypoint = 51162,
        Range = 9.22,
        Coord = {
            x = 4246.3,
            y = 1124.4,
        },
    },
    {
        Qpart = {
            [51162] = {
                1,
            },
        },
        Range = 9.21,
        Coord = {
            x = 4270.3,
            y = 1121.9,
        },
    },
    {
        Done = {
            51162,
        },
        Coord = {
            x = 4041.5,
            y = 827,
        },
    },
    {
        Waypoint = 48324,
        Range = 16.87,
        Coord = {
            x = 4044.8,
            y = 777.9,
        },
    },
    {
        Done = {
            48324,
        },
        Coord = {
            x = 4274.3,
            y = 546.7,
        },
    },
    {

        PickUp = {
            51053,
        },
        Coord = {
            x = 4275.3,
            y = 532.7,
        },
    },
    {

        Qpart = {
            [51053] = {
                1,
            },
        },
        Button = {
            ["51053-1"] = 159747,
        },
        Range = 0.75,
        Coord = {
            x = 4362.3,
            y = 461.3,
        },
    },
    {

        Done = {
            51053,
        },
        Coord = {
            x = 4275.5,
            y = 532.4,
        },
    },
    {

        PickUp = {
            51054,
        },
        Coord = {
            x = 4275.3,
            y = 531.6,
        },
    },
    {

        Qpart = {
            [51054] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 4275.3,
            y = 531.6,
        },
    },
    {

        Done = {
            51054,
        },
        Coord = {
            x = 4284.1,
            y = 559.2,
        },
    },
    {

        PickUp = {
            51055,
            51056,
        },
        Coord = {
            x = 4284.1,
            y = 559.2,
        },
    },
    {

        Qpart = {
            [51055] = {
                1,
            },
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 4175.2,
            y = 792.1,
        },
    },
    {

        Waypoint = 51056,
        Range = 13.23,
        Coord = {
            x = 4192.3,
            y = 758.5,
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
    },
    {

        Qpart = {
            [51056] = {
                1,
            },
        },
        Button = {
            ["51056-1"] = 159757,
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 4234.3,
            y = 793.7,
        },
    },
    {

        Qpart = {
            [51055] = {
                2,
            },
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 4295.5,
            y = 799.4,
        },
    },
    {

        Waypoint = 51055,
        Range = 9.65,
        Coord = {
            x = 4285.3,
            y = 864.7,
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
    },
    {

        Qpart = {
            [51055] = {
                3,
            },
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 4330.6,
            y = 836.5,
        },
    },
    {

        Qpart = {
            [51056] = {
                2,
            },
        },
        Button = {
            ["51056-2"] = 159757,
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 4249.8,
            y = 915.2,
        },
    },
    {
        UseGlider = 1,

        Range = 11.64,
        Waypoint = 51056,
        Coord = {
            x = 4194.5,
            y = 632.2,
        },
        Fillers = {
            [47647] = {
                1,
            },
        },
    },
    {

        Coord = {
            x = 4283.1,
            y = 559.4,
        },
        Done = {
            51056,
            51055,
        },
    },
    {

        PickUp = {
            49138,
        },
        Coord = {
            x = 4300.3,
            y = 685.1,
        },
        Fillers = {
            [51057] = {
                1,
            },
            [47647] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 3,
        },
    },
    {

        Qpart = {
            [47499] = {
                1,
            },
        },
        Fillers = {
            [51057] = {
                1,
            },
            [49138] = {
                1,
            },
            [47647] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 3,
        },
        Range = 7.81,
        Coord = {
            x = 4378,
            y = 647.1,
        },
    },
    {

        Qpart = {
            [47499] = {
                2,
            },
        },
        Fillers = {
            [49138] = {
                1,
            },
            [51057] = {
                1,
            },
            [47647] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 3,
        },
        Range = 9.07,
        Coord = {
            x = 4349.2,
            y = 813.7,
        },
    },
    {

        Qpart = {
            [47499] = {
                3,
            },
        },
        Fillers = {
            [49138] = {
                1,
            },
            [51057] = {
                1,
            },
            [47647] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 3,
        },
        Range = 9.5,
        Coord = {
            x = 4440.1,
            y = 799,
        },
    },
    {

        Qpart = {
            [49138] = {
                1,
            },
        },
        Fillers = {
            [47647] = {
                1,
            },
            [51057] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 3,
        },
        Range = 1.1,
        Coord = {
            x = 4525.7,
            y = 742.4,
        },
    },
    {

        Qpart = {
            [49138] = {
                2,
            },
        },
        Fillers = {
            [47647] = {
                1,
            },
            [51057] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 3,
        },
        Range = 5.1,
        Coord = {
            x = 4525.7,
            y = 742.4,
        },
    },
    {

        Done = {
            49138,
        },
        Coord = {
            x = 4527.3,
            y = 735.5,
        },
        Fillers = {
            [47647] = {
                1,
            },
            [51057] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 3,
        },
    },
    {

        Qpart = {
            [47647] = {
                1,
            },
            [51057] = {
                1,
            },
        },
        Button = {
            ["51057-1"] = 159774,
        },
        ButtonSpellId = {
            [268665] = "51057-1",
        },
        ButtonCooldown = {
            [268665] = 5,
        },
        Range = 298.17,
        Coord = {
            x = 4527.3,
            y = 735.5,
        },
    },
    {

        Done = {
            47499,
            51057,
        },
        Coord = {
            x = 4424.6,
            y = 625.7,
        },
        LeaveQuest = 51059,
    },
    {

        UseHS = 48313,
        Coord = {
            x = 4424.6,
            y = 625.7,
        },
        LeaveQuest = 51059,
        Button = {
            ["22345678-1"] = 6948,
        },
    },
    {
        Coord = {
            x = 3734.1,
            y = 915.2,
        },
        LeaveQuest = 51059,
        Done = {
            51161,
        },
    },
    {
        Qpart = {
            [48314] = {
                1,
            },
            [48313] = {
                1,
            },
        },
        Range = 61.7,
        Coord = {
            x = 3558.1,
            y = 956.2,
        },
    },
    {
        Waypoint = 48314,
        Range = 33.53,
        Coord = {
            x = 3511.1,
            y = 908.7,
        },
    },
    {
        Done = {
            48314,
            48313,
        },
        Coord = {
            x = 3485.5,
            y = 904.2,
        },
    },
    {
        PickUp = {
            50770,
        },
        Coord = {
            x = 3485.5,
            y = 904.2,
        },
    },
    {
        SpecialMacro = 1,
        Qpart = {
            [50770] = {
                1,
            },
        },
        Button = {
            ["50770-1"] = 158678,
        },
        Range = 0.61,
        Coord = {
            x = 3484.6,
            y = 899.2,
        },
    },
    {
        Coord = {
            x = 3484.4,
            y = 899.2,
        },
        Done = {
            50770,
        },
    },
    {
        PickUp = {
            50539,
        },
        Coord = {
            x = 3484.4,
            y = 899.2,
        },
    },
    {
        Range = 10.76,
        Waypoint = 50539,
        Coord = {
            x = 3514.1,
            y = 926.5,
        },
    },
    {
        Range = 5.71,
        Waypoint = 50539,
        Coord = {
            x = 3497.6,
            y = 972.7,
        },
    },
    {
        Range = 8.15,
        Waypoint = 50539,
        Coord = {
            x = 3491.1,
            y = 927.7,
        },
    },
    {
        Range = 15.35,
        Waypoint = 50539,
        Coord = {
            x = 3469.3,
            y = 968.9,
        },
    },
    {
        PickUp = {
            50536,
        },
        Coord = {
            x = 3466.6,
            y = 1034,
        },
    },
    {
        Qpart = {
            [50536] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3463.3,
            y = 1036.5,
        },
    },
    {
        Coord = {
            x = 3358.6,
            y = 954.9,
        },
        Done = {
            50539,
        },
    },
    {
        PickUp = {
            48315,
        },
        Coord = {
            x = 3359.1,
            y = 955,
        },
    },
    {
        Qpart = {
            [50536] = {
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3415.5,
            y = 934.2,
        },
    },
    {
        Qpart = {
            [50536] = {
                3,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3360.8,
            y = 873,
        },
    },
    {
        Qpart = {
            [50536] = {
                4,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3302.1,
            y = 931.7,
        },
    },
    {
        Range = 11.47,
        Waypoint = 48315,
        Coord = {
            x = 3317.8,
            y = 966.4,
        },
    },
    {
        Range = 13.25,
        Waypoint = 48315,
        Coord = {
            x = 3289.1,
            y = 1000.1,
        },
    },
    {
        QpartPart = {
            [48315] = {
                1,
            },
        },
        TrigText = "1/2",
        Range = 0.75,
        Coord = {
            x = 3294.1,
            y = 1014.1,
        },
    },
    {
        Range = 11.22,
        Waypoint = 48315,
        Coord = {
            x = 3263.6,
            y = 1071.8,
        },
    },
    {
        QpartPart = {
            [48315] = {
                1,
            },
        },
        Range = 0.69,
        TrigText = "2/2",
        Coord = {
            x = 3213.4,
            y = 1053,
        },
    },
    {
        Coord = {
            x = 3358.5,
            y = 955.4,
        },
        Done = {
            48315,
        },
    },
    {
        PickUp = {
            50561,
        },
        Coord = {
            x = 3359.4,
            y = 965.2,
        },
    },
    {
        Range = 21.47,
        Waypoint = 50536,
        Coord = {
            x = 3400.5,
            y = 967.9,
        },
    },
    {
        Range = 5.48,
        Waypoint = 50536,
        Coord = {
            x = 3465,
            y = 1015.7,
        },
    },
    {
        Done = {
            50536,
        },
        Coord = {
            x = 3466.4,
            y = 1034.5,
        },
    },
    {
        PickUp = {
            48871,
        },
        Coord = {
            x = 3466.4,
            y = 1034.5,
        },
    },
    {
        PickUp = {
            48872,
        },
        Coord = {
            x = 3458.9,
            y = 1039.9,
        },
    },
    {
        Waypoint = 48871,
        Range = 11.34,
        Coord = {
            x = 3461.8,
            y = 1005.2,
        },
    },
    {
        Qpart = {
            [48872] = {
                1,
            },
            [48871] = {
                1,
            },
        },
        Range = 18.76,
        Coord = {
            x = 3399.6,
            y = 972.9,
        },
    },
    {
        Waypoint = 48871,
        Range = 8.75,
        Coord = {
            x = 3462.1,
            y = 1005.7,
        },
    },
    {
        Done = {
            48872,
            48871,
        },
        Coord = {
            x = 3464.6,
            y = 1034.3,
        },
    },
    {
        PickUp = {
            50535,
        },
        Coord = {
            x = 3465.9,
            y = 1034.3,
        },
    },
    {
        Waypoint = 50535,
        Range = 8.13,
        Coord = {
            x = 3398.5,
            y = 967.9,
        },
    },
    {
        Waypoint = 50535,
        Range = 9.54,
        Coord = {
            x = 3392.5,
            y = 841.6,
        },
    },
    {
        Qpart = {
            [50535] = {
                1,
            },
        },
        Range = 5.01,
        Coord = {
            x = 3359.6,
            y = 853.9,
        },
    },
    {
        Waypoint = 50535,
        Range = 7.43,
        Coord = {
            x = 3464.8,
            y = 1008.6,
        },
    },
    {
        Done = {
            50535,
        },
        Coord = {
            x = 3466.3,
            y = 1034,
        },
    },
    {
        Waypoint = 50561,
        Range = 17.43,
        Coord = {
            x = 3512.6,
            y = 918.5,
        },
    },
    {
        Done = {
            50561,
        },
        Coord = {
            x = 3485.3,
            y = 900.1,
        },
    },
    {
        Qpart = {
            [47324] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3501.1,
            y = 910.7,
        },
    },
    {
        Done = {
            47324,
        },
        ETA = 49,
        Coord = {
            x = 4835.3,
            y = 1888.3,
        },
    },
    {
        PickUp = {
            49334,
            50641,
            49327,
        },
        Coord = {
            x = 4835.6,
            y = 1890.4,
        },
    },
    {
        PickUp = {
            50818,
        },
        Coord = {
            x = 4717.3,
            y = 1856.5,
        },
    },
    {
        Qpart = {
            [49334] = {
                1,
            },
        },
        Fillers = {
            [50641] = {
                1,
            },
            [49327] = {
                1,
                3,
                2,
            },
        },
        Range = 0.75,
        Coord = {
            x = 4646,
            y = 1976.9,
        },
    },
    {
        Qpart = {
            [50641] = {
                1,
            },
            [49327] = {
                1,
                3,
                2,
            },
        },
        Range = 12.1,
        Coord = {
            x = 4648.6,
            y = 1978.4,
        },
    },
    {
        Waypoint = 49327,
        Range = 20.71,
        Coord = {
            x = 4762,
            y = 1883.3,
        },
    },
    {
        Done = {
            50641,
            49327,
        },
        Coord = {
            x = 4835.6,
            y = 1891.3,
        },
    },
    {
        SetHS = 49340,
        Coord = {
            x = 4859.5,
            y = 1963.7,
        },
    },
    {
        Done = {
            49334,
        },
        Coord = {
            x = 4808.8,
            y = 1949.9,
        },
    },
    {
        PickUp = {
            49340,
        },
        Coord = {
            x = 4812.8,
            y = 1950.7,
        },
    },
    {
        Qpart = {
            [49340] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.75,
        Coord = {
            x = 4812.8,
            y = 1950.7,
        },
    },
    {
        Done = {
            49340,
        },
        Coord = {
            x = 4843.8,
            y = 1951.2,
        },
    },
    {
        PickUp = {
            49662,
        },
        Coord = {
            x = 4843.8,
            y = 1951.2,
        },
    },
    {
        Waypoint = 50656,
        Range = 5.42,
        Coord = {
            x = 4873.3,
            y = 1953.4,
        },
    },
    {
        GetFP = 2162,
        Range = 2.8,
        Coord = {
            x = 4806.6,
            y = 2052,
        },
    },
    {
        ExtraLineText = "MISSING_Q",
        PickUp = {
            48332,
            48334,
            49001,
        },
        Coord = {
            x = 3598.9,
            y = 2240.6,
        },
    },
    {

        Qpart = {
            [48334] = {
                1,
            },
        },
        Fillers = {
            [49001] = {
                1,
            },
            [48332] = {
                1,
            },
        },
        Range = 17.41,
        Coord = {
            x = 3486.8,
            y = 2052.5,
        },
    },
    {

        Qpart = {
            [49001] = {
                1,
            },
            [48332] = {
                1,
            },
        },
        Range = 28.12,
        Coord = {
            x = 3499.3,
            y = 2056.1,
        },
    },
    {

        Done = {
            48332,
            48334,
            49001,
        },
        Coord = {
            x = 3598.8,
            y = 2241.1,
        },
    },
    {

        PickUp = {
            48335,
            48331,
            49139,
        },
        Coord = {
            x = 3598.6,
            y = 2241.3,
        },
    },
    {

        Qpart = {
            [49139] = {
                1,
            },
        },
        Fillers = {
            [48331] = {
                1,
            },
            [48335] = {
                1,
            },
        },
        Button = {
            ["48331-1"] = 154051,
        },
        Range = 7.66,
        Coord = {
            x = 3402.5,
            y = 2321.6,
        },
    },
    {

        Waypoint = 49139,
        Range = 11.63,
        Coord = {
            x = 3528.1,
            y = 2321.3,
        },
        Fillers = {
            [48331] = {
                1,
            },
            [48335] = {
                1,
            },
        },
        Button = {
            ["48331-1"] = 154051,
        },
    },
    {

        Qpart = {
            [49139] = {
                2,
            },
        },
        Fillers = {
            [48331] = {
                1,
            },
            [48335] = {
                1,
            },
        },
        Button = {
            ["48331-1"] = 154051,
        },
        Range = 6.36,
        Coord = {
            x = 3552.5,
            y = 2381.1,
        },
    },
    {

        Qpart = {
            [48331] = {
                1,
            },
            [48335] = {
                1,
            },
        },
        Button = {
            ["48331-1"] = 154051,
        },
        Range = 27.98,
        Coord = {
            x = 3540.8,
            y = 2359,
        },
    },
    {

        Done = {
            48335,
            48331,
            49139,
        },
        Coord = {
            x = 3599.6,
            y = 2240,
        },
    },
    {

        PickUp = {
            48330,
        },
        Coord = {
            x = 3600.1,
            y = 2240.8,
        },
    },
    {

        Waypoint = 48330,
        Range = 12.49,
        Coord = {
            x = 3532.6,
            y = 2309,
        },
    },
    {

        Qpart = {
            [48330] = {
                1,
            },
        },
        Range = 11.29,
        Coord = {
            x = 3470.1,
            y = 2442.8,
        },
    },
    {

        Done = {
            48330,
        },
        Coord = {
            x = 3600.1,
            y = 2240.8,
        },
    },
    {
        Done = {
            49662,
        },
        Coord = {
            x = 3766.1,
            y = 2713.4,
        },
    },
    {
        PickUp = {
            50745,
        },
        Coord = {
            x = 3766.1,
            y = 2713.4,
        },
    },
    {
        SpecialETAHide = 1,
        ETA = 79,
        RaidIcon = 135172,
        Range = 16.48,
        Waypoint = 50745,
        Coord = {
            x = 3769.6,
            y = 2792.9,
        },
    },
    {
        SpecialETAHide = 1,
        Range = 9.57,
        Waypoint = 50745,
        Coord = {
            x = 3730.4,
            y = 2793.6,
        },
    },
    {
        SpecialETAHide = 1,
        Range = 13.93,
        Waypoint = 50745,
        Coord = {
            x = 3683.1,
            y = 2769,
        },
    },
    {
        SpecialETAHide = 1,
        Range = 18.17,
        Waypoint = 50745,
        Coord = {
            x = 3626,
            y = 2758.6,
        },
    },
    {
        SpecialETAHide = 1,
        Range = 14.89,
        Waypoint = 50745,
        Coord = {
            x = 3498.3,
            y = 2753.1,
        },
    },
    {
        SpecialETAHide = 1,
        Range = 4.91,
        GetFP = 2111,
        Coord = {
            x = 3467.9,
            y = 2738,
        },
    },
    {
        SpecialETAHide = 1,
        Range = 5.58,
        Waypoint = 50745,
        Coord = {
            x = 3426.9,
            y = 2730,
        },
    },
    {
        Coord = {
            x = 3422.4,
            y = 2686.6,
        },
        Done = {
            50745,
        },
    },
    {
        PickUp = {
            49664,
            49667,
        },
        Coord = {
            x = 3421.4,
            y = 2682.1,
        },
    },
    {
        Waypoint = 49664,
        Range = 7.77,
        Coord = {
            x = 3429.3,
            y = 2732.6,
        },
    },
    {
        Waypoint = 49664,
        Range = 13.86,
        Coord = {
            x = 3507.5,
            y = 2778.1,
        },
    },
    {
        Done = {
            49664,
        },
        Coord = {
            x = 3547.1,
            y = 2829.6,
        },
    },
    {
        PickUp = {
            49665,
            49666,
        },
        Coord = {
            x = 3547.1,
            y = 2829.6,
        },
    },
    {
        ExtraLineText = "USE_BANNER_ON_CORPSES",
        Qpart = {
            [49667] = {
                1,
            },
        },
        Gossip = 1,
        Fillers = {
            [49666] = {
                1,
            },
            [49665] = {
                1,
            },
        },
        Button = {
            ["49666-1"] = 158884,
        },
        ButtonSpellId = {
            [272019] = "49666-1",
        },
        ButtonCooldown = {
            [272019] = 5,
        },
        Range = 11.56,
        Coord = {
            x = 3388.1,
            y = 2875.9,
        },
    },
    {
        ExtraLineText = "USE_BANNER_ON_CORPSES",
        Qpart = {
            [49666] = {
                1,
            },
            [49665] = {
                1,
            },
        },
        Gossip = 1,
        Button = {
            ["49666-1"] = 158884,
        },
        ButtonSpellId = {
            [272019] = "49666-1",
        },
        ButtonCooldown = {
            [272019] = 5,
        },
        Range = 34.99,
        Coord = {
            x = 3386.6,
            y = 2875.6,
        },
    },
    {
        Waypoint = 49665,
        Range = 8.78,
        Coord = {
            x = 3478,
            y = 2802.1,
        },
    },
    {
        Coord = {
            x = 3547.1,
            y = 2829.6,
        },
        Done = {
            49665,
            49666,
        },
    },
    {
        PickUp = {
            49668,
        },
        Coord = {
            x = 3547.1,
            y = 2829.6,
        },
    },
    {
        PickUp = {
            50746,
        },
        Coord = {
            x = 3538.9,
            y = 2831.6,
        },
    },
    {
        Range = 12.14,
        Waypoint = 50746,
        Coord = {
            x = 3505,
            y = 2775.6,
        },
    },
    {
        Range = 6.54,
        Waypoint = 50746,
        Coord = {
            x = 3425.8,
            y = 2730.3,
        },
    },
    {
        Coord = {
            x = 3421.6,
            y = 2681.6,
        },
        Done = {
            50746,
            49667,
        },
    },
    {
        PickUp = {
            49141,
            50748,
        },
        Coord = {
            x = 3421.6,
            y = 2682.5,
        },
    },
    {
        Range = 11.7,
        Waypoint = 49668,
        Coord = {
            x = 3370.1,
            y = 2770.1,
        },
    },
    {
        Qpart = {
            [49668] = {
                1,
            },
        },
        Button = {
            ["49668-1"] = 158896,
        },
        ButtonSpellId = {
            [265957] = "49668-1",
        },
        ButtonCooldown = {
            [265957] = 15,
        },
        Range = 10.43,
        Coord = {
            x = 3238.1,
            y = 2834.3,
        },
    },
    {
        Qpart = {
            [49668] = {
                2,
            },
        },
        Button = {
            ["49668-2"] = 158896,
        },
        ButtonSpellId = {
            [265957] = "49668-2",
        },
        ButtonCooldown = {
            [265957] = 15,
        },
        Range = 13.92,
        Coord = {
            x = 3130.1,
            y = 2827.6,
        },
    },
    {
        Qpart = {
            [49668] = {
                3,
            },
        },
        Button = {
            ["49668-3"] = 158896,
        },
        ButtonSpellId = {
            [265957] = "49668-3",
        },
        ButtonCooldown = {
            [265957] = 15,
        },
        Range = 16.88,
        Coord = {
            x = 3041.5,
            y = 2823.4,
        },
    },
    {
        PickUp = {
            49437,
        },
        Coord = {
            x = 2988,
            y = 2783.3,
        },
    },
    {
        Coord = {
            x = 2914.1,
            y = 2747.3,
        },
        Done = {
            49668,
        },
    },
    {
        PickUp = {
            49669,
            50757,
        },
        Coord = {
            x = 2914.1,
            y = 2748.3,
        },
    },
    {
        Waypoint = 50757,
        Range = 10.46,
        Coord = {
            x = 2883.1,
            y = 2769.1,
        },
        Fillers = {
            [50757] = {
                1,
            },
        },
    },
    {
        Waypoint = 50757,
        Range = 8.29,
        Coord = {
            x = 2896.6,
            y = 2788.9,
        },
        Fillers = {
            [50757] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49437] = {
                1,
            },
        },
        Fillers = {
            [50757] = {
                1,
            },
        },
        Range = 11.91,
        Coord = {
            x = 2977.3,
            y = 2830.6,
        },
    },
    {
        Waypoint = 50757,
        Range = 17.44,
        Coord = {
            x = 2880.1,
            y = 2851.1,
        },
        Fillers = {
            [50757] = {
                1,
            },
        },
    },
    {
        Waypoint = 50757,
        Range = 11.25,
        Coord = {
            x = 2893.8,
            y = 2880.4,
        },
        Fillers = {
            [50757] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49669] = {
                1,
            },
        },
        Fillers = {
            [50757] = {
                1,
            },
        },
        Range = 12.66,
        Coord = {
            x = 2922.9,
            y = 2939.3,
        },
    },
    {
        Qpart = {
            [50757] = {
                1,
            },
        },
        Range = 31.2,
        Coord = {
            x = 2923.1,
            y = 2936.1,
        },
    },
    {
        Done = {
            50757,
            49669,
        },
        Coord = {
            x = 2913.1,
            y = 2747.1,
        },
    },
    {
        PickUp = {
            50749,
        },
        Coord = {
            x = 2913.1,
            y = 2747.1,
        },
    },
    {
        Qpart = {
            [50749] = {
                1,
            },
        },
        Range = 0.99,
        Coord = {
            x = 2928.6,
            y = 2739.1,
        },
    },
    {
        Waypoint = 50749,
        Range = 33.72,
        Coord = {
            x = 3016.1,
            y = 2807.9,
        },
    },
    {
        Waypoint = 50749,
        Range = 27.42,
        Coord = {
            x = 3281.9,
            y = 2819.6,
        },
    },
    {
        Waypoint = 50749,
        Range = 27.01,
        Coord = {
            x = 3335.1,
            y = 2774,
        },
    },
    {
        Range = 7.83,
        Waypoint = 50749,
        Coord = {
            x = 3427.3,
            y = 2728.6,
        },
    },
    {
        Coord = {
            x = 3420.3,
            y = 2679.5,
        },
        Done = {
            50749,
            49437,
        },
    },
    {
        Waypoint = 50748,
        Range = 9.39,
        Coord = {
            x = 3423.6,
            y = 2731.9,
        },
    },
    {
        Waypoint = 50748,
        Range = 12.57,
        Coord = {
            x = 3357,
            y = 2771.1,
        },
    },
    {
        Waypoint = 50748,
        Range = 12.46,
        Coord = {
            x = 3313.1,
            y = 2741.8,
        },
    },
    {
        Waypoint = 50748,
        Range = 19.45,
        Coord = {
            x = 3399.1,
            y = 2667.1,
        },
        Fillers = {
            [49141] = {
                1,
            },
            [50748] = {
                1,
            },
        },
    },
    {
        Waypoint = 48329,
        Range = 18.52,
        Coord = {
            x = 3353.1,
            y = 2637.6,
        },
        Fillers = {
            [49141] = {
                1,
            },
            [50748] = {
                1,
            },
        },
    },
    {
        Waypoint = 48329,
        Range = 8.95,
        Coord = {
            x = 3348.3,
            y = 2583.4,
        },
        Fillers = {
            [49141] = {
                1,
            },
            [50748] = {
                1,
            },
        },
    },
    {
        Waypoint = 48329,
        Range = 8.95,
        Coord = {
            x = 3413.6,
            y = 2546.3,
        },
        DroppableQuest = {
            Text = "Beastbreaker Hakid",
            Qid = 48329,
            MobId = 130603,
        },
        Fillers = {
            [49141] = {
                1,
            },
            [50748] = {
                1,
            },
        },
    },
    {
        DroppableQuest = {
            Text = "Beastbreaker Hakid",
            Qid = 48329,
            MobId = 130603,
        },
        DropQuest = 48329,
        Coord = {
            x = 3413.6,
            y = 2546.3,
        },
        Fillers = {
            [49141] = {
                1,
            },
            [50748] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [48329] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 3424.5,
            y = 2531.1,
        },
        Fillers = {
            [49141] = {
                1,
            },
            [50748] = {
                1,
            },
        },
    },
    {
        Qpart = {
            [49141] = {
                1,
            },
            [50748] = {
                1,
            },
        },
        Range = 30.42,
        Coord = {
            x = 3338.4,
            y = 2610.6,
        },
    },
    {
        Range = 14.48,
        Waypoint = 49141,
        Coord = {
            x = 3433.6,
            y = 2620.1,
        },
    },
    {
        Range = 7.15,
        Waypoint = 49141,
        Coord = {
            x = 3419.5,
            y = 2559.6,
        },
    },
    {
        PickUp = {
            49002,
        },
        Coord = {
            x = 3480.6,
            y = 2579.9,
        },
    },
    {
        ExtraLineText = "SPEAR_DOWN_THE_UFO",
        SpecialMacro2 = 1,
        DenyNPC = 129763,
        Qpart = {
            [49002] = {
                1,
            },
        },
        Button = {
            ["49002-1"] = 154893,
        },
        ButtonSpellId = {
            [257490] = "49002-1",
        },
        ButtonCooldown = {
            [257490] = 5,
        },
        Range = 15.79,
        Coord = {
            x = 3478.3,
            y = 2568.1,
        },
    },
    {
        Coord = {
            x = 3477.6,
            y = 2553.1,
        },
        Done = {
            49002,
        },
    },
    {
        Coord = {
            x = 3473.6,
            y = 2562,
        },
        Done = {
            49141,
            50748,
        },
    },
    {
        Qpart = {
            [49003] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 3478.6,
            y = 2551.4,
        },
    },
    {
        Qpart = {
            [49003] = {
                3,
                2,
            },
        },
        Range = 219.05,
        Coord = {
            x = 3511.6,
            y = 2861.6,
        },
    },
    {
        Done = {
            49003,
        },
        Coord = {
            x = 3151.6,
            y = 3032.8,
        },
    },
    {
        PickUp = {
            50750,
            50752,
        },
        Coord = {
            x = 3151.6,
            y = 3032.8,
        },
    },
    {
        Qpart = {
            [50752] = {
                1,
            },
        },
        Fillers = {
            [50750] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3290.1,
            y = 3043.4,
        },
    },
    {
        Qpart = {
            [50752] = {
                2,
            },
        },
        Fillers = {
            [50750] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 3266.8,
            y = 3124.6,
        },
    },
    {
        Qpart = {
            [50752] = {
                3,
            },
        },
        Fillers = {
            [50750] = {
                1,
            },
        },
        Range = 0.75,
        Coord = {
            x = 3403,
            y = 3149.6,
        },
    },
    {
        Qpart = {
            [50752] = {
                4,
            },
        },
        Fillers = {
            [50750] = {
                1,
            },
        },
        Range = 0.69,
        Coord = {
            x = 3314.6,
            y = 3229.9,
        },
    },
    {
        Done = {
            50750,
            50752,
        },
        Coord = {
            x = 3151.3,
            y = 3034.4,
        },
    },
    {
        PickUp = {
            50550,
        },
        Coord = {
            x = 3151.1,
            y = 3034,
        },
    },
    {
        Qpart = {
            [50550] = {
                1,
            },
        },
        Gossip = 1,
        Range = 0.69,
        Coord = {
            x = 3151.1,
            y = 3034,
        },
    },
    {
        Bloodlust = 1,
        Qpart = {
            [50550] = {
                2,
            },
        },
        Range = 16.87,
        Coord = {
            x = 3151.1,
            y = 3128,
        },
    },
    {
        Coord = {
            x = 3149.3,
            y = 3080.3,
        },
        Done = {
            50550,
        },
    },
    {
        PickUp = {
            50751,
        },
        Coord = {
            x = 3149.3,
            y = 3080.3,
        },
    },
    {
        Qpart = {
            [50805] = {
                1,
            },
        },
        Range = 22.99,
        Coord = {
            x = 3087.1,
            y = 3139.3,
        },
    },
    {
        Button = {
            ["22345678-1"] = 6948,
        },
        UseHS = 50751,
        Coord = {
            x = 3149.3,
            y = 3080.3,
        },
    },
    {
        Range = 6.69,
        Waypoint = 50751,
        Coord = {
            x = 4851.7,
            y = 1926,
        },
    },
    {
        Range = 7.74,
        Waypoint = 50751,
        Coord = {
            x = 4881.8,
            y = 1927.5,
        },
    },
    {
        Range = 8.15,
        Waypoint = 50751,
        Coord = {
            x = 4868.1,
            y = 1950.7,
        },
    },
    {
        Coord = {
            x = 4845.3,
            y = 1950.9,
        },
        Done = {
            50751,
        },
    },
    {
        PickUp = {
            50617,
        },
        Coord = {
            x = 4845.3,
            y = 1950.9,
        },
    },
    {
        ExtraLineText = "ZONE_COMPLETE",
        UseDalaHS = 50703,
        Coord = {
            x = 4845.3,
            y = 1950.9,
        },
        Button = {
            ["12112552-1"] = 140192,
        },
    },
    {
        ZoneDoneSave = 1,
    },
}
