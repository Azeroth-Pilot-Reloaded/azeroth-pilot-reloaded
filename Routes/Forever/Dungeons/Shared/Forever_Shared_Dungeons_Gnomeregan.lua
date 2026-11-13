local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Gnomeregan"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 29,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Gnomeregan"],
    levelRange = {
        max = 38,
        min = 29,
    },
    mapID = 1426,
    steps = { {
        PickUp = { 2841 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 75.99, 25.41),
        RaidIcon = { {
            npcID = 3412,
            questID = 2841,
        } },
        Faction = "Horde",
        MinLevel = 25,
        Zone = 1454,
        _index = 1,
    }, {
        PickUp = { 2842 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 75.49, 25.36),
        RaidIcon = { {
            npcID = 3413,
            questID = 2842,
        } },
        Faction = "Horde",
        MinLevel = 20,
        Zone = 1454,
        _index = 2,
    }, {
        PickUp = { 2922 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.55, 50.33),
        RaidIcon = { {
            npcID = 7944,
            questID = 2922,
        } },
        Faction = "Alliance",
        MinLevel = 20,
        Zone = 1455,
        _index = 3,
    }, {
        PickUp = { 2923 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.05, 48.39),
        RaidIcon = { {
            npcID = 7917,
            questID = 2923,
        } },
        Faction = "Alliance",
        MinLevel = 20,
        Zone = 1453,
        _index = 4,
    }, {
        PickUp = { 2924 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 67.92, 46.1),
        RaidIcon = { {
            npcID = 6169,
            questID = 2924,
        } },
        Faction = "Alliance",
        MinLevel = 24,
        Zone = 1455,
        _index = 5,
    }, {
        PickUp = { 2925 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1457, 59.51, 45.38),
        RaidIcon = { {
            npcID = 6142,
            questID = 2925,
        } },
        Faction = "Alliance",
        MinLevel = 24,
        Zone = 1457,
        _index = 6,
    }, {
        PickUp = { 2927 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.18, 50.55),
        RaidIcon = { {
            npcID = 6569,
            questID = 2927,
        } },
        Faction = "Alliance",
        MinLevel = 20,
        Zone = 1455,
        _index = 7,
    }, {
        PickUp = { 2928 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 62.63, 34.11),
        RaidIcon = { {
            npcID = 6579,
            questID = 2928,
        } },
        Faction = "Alliance",
        MinLevel = 20,
        Zone = 1453,
        _index = 8,
    }, {
        PickUp = { 2929 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 68.75, 48.97),
        RaidIcon = { {
            npcID = 7937,
            questID = 2929,
        } },
        Faction = "Alliance",
        MinLevel = 25,
        Zone = 1455,
        _index = 9,
    }, {
        PickUp = { 2930 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.83, 48.1),
        RaidIcon = { {
            npcID = 7950,
            questID = 2930,
        } },
        Faction = "Alliance",
        MinLevel = 25,
        Zone = 1455,
        _index = 10,
    }, {
        PickUp = { 2931 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1442, 59.52, 67.15),
        RaidIcon = { {
            npcID = 4077,
            questID = 2931,
        } },
        Faction = "Alliance",
        MinLevel = 25,
        Zone = 1442,
        _index = 11,
    }, {
        Done = { 2842 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1434, 27.6, 77.48),
        RaidIcon = { {
            npcID = 7853,
            questID = 2842,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2842,
        Zone = 1434,
        _index = 12,
    }, {
        Done = { 2923 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.55, 50.33),
        RaidIcon = { {
            npcID = 7944,
            questID = 2923,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2923,
        Zone = 1455,
        _index = 13,
    }, {
        Done = { 2925 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 67.92, 46.1),
        RaidIcon = { {
            npcID = 6169,
            questID = 2925,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2925,
        Zone = 1455,
        _index = 14,
    }, {
        Done = { 2927 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 45.89, 49.39),
        RaidIcon = { {
            npcID = 1268,
            questID = 2927,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2927,
        Zone = 1426,
        _index = 15,
    }, {
        Done = { 2931 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.83, 48.1),
        RaidIcon = { {
            npcID = 7950,
            questID = 2931,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2931,
        Zone = 1455,
        _index = 16,
    }, {
        PickUp = { 2843 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1434, 27.6, 77.48),
        RaidIcon = { {
            npcID = 7853,
            questID = 2843,
        } },
        AnyOf = { {
            IsQuestCompleted = 2842,
        } },
        Faction = "Horde",
        MinLevel = 20,
        Zone = 1434,
        _index = 17,
    }, {
        PickUp = { 2926 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 45.89, 49.39),
        RaidIcon = { {
            npcID = 1268,
            questID = 2926,
        } },
        AnyOf = { {
            IsQuestCompleted = 2927,
        } },
        Faction = "Alliance",
        MinLevel = 20,
        Zone = 1426,
        _index = 18,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_90",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 17.5, 39.1),
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        Zone = 1426,
        _index = 19,
    }, {
        PickUp = { 2904 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 7850,
            questID = 2904,
        } },
        MinLevel = 24,
        _index = 20,
    }, {
        PickUp = { 2951 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        MinLevel = 25,
        _index = 21,
    }, {
        PickUp = { 4601 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        MinLevel = 25,
        _index = 22,
    }, {
        PickUp = { 4602 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        MinLevel = 25,
        _index = 23,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_90",
            name = "Grubbis",
            npcID = 7361,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        _index = 24,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_90",
            name = "Viscous Fallout",
            npcID = 7079,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        _index = 25,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_90",
            name = "Electrocutioner 6000",
            npcID = 6235,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        _index = 26,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_90",
            name = "Crowd Pummeler 9-60",
            npcID = 6229,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        _index = 27,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_90",
            name = "Mekgineer Thermaplugg",
            npcID = 7800,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        _index = 28,
    }, {
        Qpart = {
            [2841] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2841,
        _index = 29,
    }, {
        Qpart = {
            [2843] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2843,
        _index = 30,
    }, {
        Qpart = {
            [2904] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2904,
        _index = 31,
    }, {
        Qpart = {
            [2922] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2922,
        _index = 32,
    }, {
        Qpart = {
            [2924] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2924,
        _index = 33,
    }, {
        Qpart = {
            [2926] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2926,
        _index = 34,
    }, {
        Qpart = {
            [2928] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2928,
        _index = 35,
    }, {
        Qpart = {
            [2929] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2929,
        _index = 36,
    }, {
        Qpart = {
            [2930] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2930,
        _index = 37,
    }, {
        PickUp = { 2945 },
        Button = {
            ["2945"] = 9326,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        ItemCount = {
            count = 1,
            itemID = 9326,
        },
        MinLevel = 28,
        _index = 38,
    }, {
        Qpart = {
            [2951] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2951,
        _index = 39,
    }, {
        Qpart = {
            [4601] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4601,
        _index = 40,
    }, {
        Qpart = {
            [4602] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4602,
        _index = 41,
    }, {
        Qpart = {
            [2945] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2945,
        _index = 42,
    }, {
        Done = { 2951 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2951,
        _index = 43,
    }, {
        Done = { 4601 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4601,
        _index = 44,
    }, {
        Done = { 4602 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4602,
        _index = 45,
    }, {
        Done = { 2945 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2945,
        _index = 46,
    }, {
        PickUp = { 2952 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2951,
        }, {
            IsQuestCompleted = 4601,
        }, {
            IsQuestCompleted = 4602,
        } },
        MinLevel = 25,
        _index = 47,
    }, {
        PickUp = { 4605 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2951,
        }, {
            IsQuestCompleted = 4601,
        }, {
            IsQuestCompleted = 4602,
        } },
        MinLevel = 25,
        _index = 48,
    }, {
        PickUp = { 4606 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2951,
        }, {
            IsQuestCompleted = 4601,
        }, {
            IsQuestCompleted = 4602,
        } },
        MinLevel = 25,
        _index = 49,
    }, {
        PickUp = { 2947 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2945,
        } },
        Faction = "Alliance",
        MinLevel = 28,
        _index = 50,
    }, {
        PickUp = { 2949 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2945,
        } },
        Faction = "Horde",
        MinLevel = 28,
        _index = 51,
    }, {
        Done = { 2952 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2952,
        _index = 52,
    }, {
        Done = { 4605 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4605,
        _index = 53,
    }, {
        Done = { 4606 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4606,
        _index = 54,
    }, {
        Qpart = {
            [2947] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2947,
        _index = 55,
    }, {
        Qpart = {
            [2949] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2949,
        _index = 56,
    }, {
        PickUp = { 2953 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2952,
        }, {
            IsQuestCompleted = 4605,
        }, {
            IsQuestCompleted = 4606,
        } },
        MinLevel = 25,
        _index = 57,
    }, {
        PickUp = { 4603 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2952,
        }, {
            IsQuestCompleted = 4605,
        }, {
            IsQuestCompleted = 4606,
        } },
        MinLevel = 25,
        _index = 58,
    }, {
        PickUp = { 4604 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2955,
        }, {
            IsQuestCompleted = 4605,
        }, {
            IsQuestCompleted = 4606,
        } },
        MinLevel = 25,
        _index = 59,
    }, {
        Qpart = {
            [2953] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2953,
        _index = 60,
    }, {
        Qpart = {
            [4603] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4603,
        _index = 61,
    }, {
        Qpart = {
            [4604] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4604,
        _index = 62,
    }, {
        Done = { 2953 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2953,
        _index = 63,
    }, {
        Done = { 4603 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4603,
        _index = 64,
    }, {
        Done = { 4604 },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 4604,
        _index = 65,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_90",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        _index = 66,
    }, {
        Done = { 2841 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 75.99, 25.41),
        RaidIcon = { {
            npcID = 3412,
            questID = 2841,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2841,
        Zone = 1454,
        _index = 67,
    }, {
        Done = { 2843 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1434, 27.6, 77.48),
        RaidIcon = { {
            npcID = 7853,
            questID = 2843,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2843,
        Zone = 1434,
        _index = 68,
    }, {
        Done = { 2904 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1434, 27.6, 77.48),
        RaidIcon = { {
            npcID = 7853,
            questID = 2904,
        } },
        IsQuestOnQuest = 2904,
        Zone = 1434,
        _index = 69,
    }, {
        Done = { 2922 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.55, 50.33),
        RaidIcon = { {
            npcID = 7944,
            questID = 2922,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2922,
        Zone = 1455,
        _index = 70,
    }, {
        Done = { 2924 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 67.92, 46.1),
        RaidIcon = { {
            npcID = 6169,
            questID = 2924,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2924,
        Zone = 1455,
        _index = 71,
    }, {
        Done = { 2926 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 45.89, 49.39),
        RaidIcon = { {
            npcID = 1268,
            questID = 2926,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2926,
        Zone = 1426,
        _index = 72,
    }, {
        Done = { 2928 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 62.63, 34.11),
        RaidIcon = { {
            npcID = 6579,
            questID = 2928,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2928,
        Zone = 1453,
        _index = 73,
    }, {
        Done = { 2929 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 68.75, 48.97),
        RaidIcon = { {
            npcID = 7937,
            questID = 2929,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2929,
        Zone = 1455,
        _index = 74,
    }, {
        Done = { 2930 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.83, 48.1),
        RaidIcon = { {
            npcID = 7950,
            questID = 2930,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2930,
        Zone = 1455,
        _index = 75,
    }, {
        Done = { 2947 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2947,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2947,
        Zone = 1455,
        _index = 76,
    }, {
        Done = { 2949 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 75.99, 25.41),
        RaidIcon = { {
            npcID = 3412,
            questID = 2949,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2949,
        Zone = 1454,
        _index = 77,
    }, {
        PickUp = { 2948 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2948,
        } },
        AnyOf = { {
            IsQuestCompleted = 2947,
        } },
        Faction = "Alliance",
        MinLevel = 28,
        Zone = 1455,
        _index = 78,
    }, {
        PickUp = { 2950 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 75.99, 25.41),
        RaidIcon = { {
            npcID = 3412,
            questID = 2950,
        } },
        AnyOf = { {
            IsQuestCompleted = 2949,
        } },
        Faction = "Horde",
        MinLevel = 28,
        Zone = 1454,
        _index = 79,
    }, {
        PickUp = { 2962 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 45.89, 49.39),
        RaidIcon = { {
            npcID = 1268,
            questID = 2962,
        } },
        AnyOf = { {
            IsQuestCompleted = 2926,
        } },
        Faction = "Alliance",
        MinLevel = 20,
        Zone = 1426,
        _index = 80,
    }, {
        Qpart = {
            [2948] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 2948,
        _index = 81,
    }, {
        Qpart = {
            [2950] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 2950,
        _index = 82,
    }, {
        Done = { 2948 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2948,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2948,
        Zone = 1455,
        _index = 83,
    }, {
        Done = { 2950 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 75.99, 25.41),
        RaidIcon = { {
            npcID = 3412,
            questID = 2950,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2950,
        Zone = 1454,
        _index = 84,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_90",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 17.5, 39.1),
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        Zone = 1426,
        _index = 85,
    }, {
        Qpart = {
            [2962] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        InstanceQuest = true,
        IsQuestOnQuest = 2962,
        _index = 86,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_90",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_90",
        _index = 87,
    }, {
        Done = { 2962 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 45.89, 49.39),
        RaidIcon = { {
            npcID = 1268,
            questID = 2962,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2962,
        Zone = 1426,
        _index = 88,
    }, {
        RouteCompleted = true,
        _index = 89,
    } },
}
