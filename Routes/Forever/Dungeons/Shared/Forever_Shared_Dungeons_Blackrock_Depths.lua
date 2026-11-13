local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Blackrock-Depths"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 52,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Blackrock Depths"],
    levelRange = {
        max = 60,
        min = 52,
    },
    mapID = 1427,
    steps = { {
        PickUp = { 3441 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3441,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 1,
    }, {
        PickUp = { 3702 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 38.37, 55.31),
        RaidIcon = { {
            npcID = 8879,
            questID = 3702,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1455,
        _index = 2,
    }, {
        PickUp = { 3801 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 28.96, 28.93),
        RaidIcon = { {
            npcID = 8888,
            questID = 3801,
        } },
        MinLevel = 48,
        Zone = 1428,
        _index = 3,
    }, {
        PickUp = { 3906 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.33, 48.26),
        RaidIcon = { {
            npcID = 9084,
            questID = 3906,
        } },
        Faction = "Horde",
        MinLevel = 48,
        Zone = 1418,
        _index = 4,
    }, {
        PickUp = { 4023 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 95.09, 31.56),
        RaidIcon = { {
            npcID = 9459,
            questID = 4023,
        } },
        MinLevel = 52,
        Zone = 1428,
        _index = 5,
    }, {
        PickUp = { 4061 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.02, 47.81),
        RaidIcon = { {
            npcID = 9079,
            questID = 4061,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1418,
        _index = 6,
    }, {
        PickUp = { 4081 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.74, 47.43),
        Faction = "Horde",
        MinLevel = 48,
        Zone = 1418,
        _index = 7,
    }, {
        PickUp = { 4123 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.15, 23.91),
        RaidIcon = { {
            npcID = 9536,
            questID = 4123,
        } },
        MinLevel = 50,
        Zone = 1428,
        _index = 8,
    }, {
        PickUp = { 4126 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 46.83, 52.36),
        RaidIcon = { {
            npcID = 1267,
            questID = 4126,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1426,
        _index = 9,
    }, {
        PickUp = { 4128 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 63.63, 20.63),
        RaidIcon = { {
            npcID = 9540,
            questID = 4128,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1419,
        _index = 10,
    }, {
        PickUp = { 4133 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 50.14, 67.97),
        RaidIcon = { {
            npcID = 5204,
            questID = 4133,
        } },
        Faction = "Horde",
        MinLevel = 50,
        Zone = 1458,
        _index = 11,
    }, {
        PickUp = { 4134 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 4134,
        } },
        Faction = "Horde",
        MinLevel = 50,
        Zone = 1418,
        _index = 12,
    }, {
        PickUp = { 4136 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 66.06, 21.95),
        RaidIcon = { {
            npcID = 9544,
            questID = 4136,
        } },
        MinLevel = 48,
        Zone = 1428,
        _index = 13,
    }, {
        PickUp = { 4182 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.82, 68.95),
        RaidIcon = { {
            npcID = 9562,
            questID = 4182,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1428,
        _index = 14,
    }, {
        PickUp = { 4262 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.41, 70.06),
        RaidIcon = { {
            npcID = 9561,
            questID = 4262,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1428,
        _index = 15,
    }, {
        PickUp = { 4286 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.56, 68.68),
        RaidIcon = { {
            npcID = 9177,
            questID = 4286,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1428,
        _index = 16,
    }, {
        PickUp = { 4324 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 67.04, 24.01),
        RaidIcon = { {
            npcID = 9706,
            questID = 4324,
        } },
        MinLevel = 48,
        Zone = 1446,
        _index = 17,
    }, {
        PickUp = { 8905 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8905,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 18,
    }, {
        PickUp = { 8906 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8906,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 19,
    }, {
        PickUp = { 8907 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8907,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 20,
    }, {
        PickUp = { 8908 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8908,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 21,
    }, {
        PickUp = { 8909 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8909,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 22,
    }, {
        PickUp = { 8910 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8910,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 23,
    }, {
        PickUp = { 8911 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8911,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 24,
    }, {
        PickUp = { 8912 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8912,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 25,
    }, {
        PickUp = { 8913 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8913,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 26,
    }, {
        PickUp = { 8914 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8914,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 27,
    }, {
        PickUp = { 8915 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8915,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 28,
    }, {
        PickUp = { 8916 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8916,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 29,
    }, {
        PickUp = { 8917 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8917,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 30,
    }, {
        PickUp = { 8918 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8918,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 31,
    }, {
        PickUp = { 8919 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8919,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 32,
    }, {
        PickUp = { 8920 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8920,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 33,
    }, {
        Qpart = {
            [3441] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        IsQuestOnQuest = 3441,
        Zone = 1427,
        _index = 34,
    }, {
        Qpart = {
            [3702] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 38.37, 55.31),
        IsQuestOnQuest = 3702,
        Zone = 1455,
        _index = 35,
    }, {
        Done = { 3801 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 28.96, 28.93),
        RaidIcon = { {
            npcID = 8888,
            questID = 3801,
        } },
        IsQuestOnQuest = 3801,
        Zone = 1428,
        _index = 36,
    }, {
        Qpart = {
            [3906] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 3906,
        _index = 37,
    }, {
        Qpart = {
            [4023] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 94.4, 31.8),
        IsQuestOnQuest = 4023,
        Zone = 1428,
        _index = 38,
    }, {
        Qpart = {
            [4061] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 29.06, 62.33),
        IsQuestOnQuest = 4061,
        Zone = 1428,
        _index = 39,
    }, {
        Done = { 4128 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 46.83, 52.36),
        RaidIcon = { {
            npcID = 1267,
            questID = 4128,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4128,
        Zone = 1426,
        _index = 40,
    }, {
        Done = { 4133 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 4133,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4133,
        Zone = 1418,
        _index = 41,
    }, {
        Qpart = {
            [4182] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 86.92, 30.55),
        IsQuestOnQuest = 4182,
        Zone = 1428,
        _index = 42,
    }, {
        Qpart = {
            [4262] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4262,
        _index = 43,
    }, {
        Done = { 4324 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 66.06, 21.95),
        RaidIcon = { {
            npcID = 9544,
            questID = 4324,
        } },
        IsQuestOnQuest = 4324,
        Zone = 1428,
        _index = 44,
    }, {
        Qpart = {
            [8905] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8905,
        Zone = 1452,
        _index = 45,
    }, {
        Qpart = {
            [8906] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8906,
        Zone = 1452,
        _index = 46,
    }, {
        Qpart = {
            [8907] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8907,
        Zone = 1452,
        _index = 47,
    }, {
        Qpart = {
            [8908] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8908,
        Zone = 1452,
        _index = 48,
    }, {
        Qpart = {
            [8909] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8909,
        Zone = 1452,
        _index = 49,
    }, {
        Qpart = {
            [8910] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8910,
        Zone = 1452,
        _index = 50,
    }, {
        Qpart = {
            [8911] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8911,
        Zone = 1452,
        _index = 51,
    }, {
        Qpart = {
            [8912] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8912,
        Zone = 1452,
        _index = 52,
    }, {
        Qpart = {
            [8913] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8913,
        Zone = 1451,
        _index = 53,
    }, {
        Qpart = {
            [8914] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8914,
        Zone = 1451,
        _index = 54,
    }, {
        Qpart = {
            [8915] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8915,
        Zone = 1451,
        _index = 55,
    }, {
        Qpart = {
            [8916] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8916,
        Zone = 1451,
        _index = 56,
    }, {
        Qpart = {
            [8917] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8917,
        Zone = 1451,
        _index = 57,
    }, {
        Qpart = {
            [8918] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8918,
        Zone = 1451,
        _index = 58,
    }, {
        Qpart = {
            [8919] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8919,
        Zone = 1451,
        _index = 59,
    }, {
        Qpart = {
            [8920] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8920,
        Zone = 1451,
        _index = 60,
    }, {
        Done = { 3441 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3441,
        } },
        IsQuestOnQuest = 3441,
        Zone = 1427,
        _index = 61,
    }, {
        Done = { 3702 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 38.37, 55.31),
        RaidIcon = { {
            npcID = 8879,
            questID = 3702,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 3702,
        Zone = 1455,
        _index = 62,
    }, {
        PickUp = { 3802 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 28.96, 28.93),
        RaidIcon = { {
            npcID = 8888,
            questID = 3802,
        } },
        AnyOf = { {
            IsQuestCompleted = 3801,
        } },
        MinLevel = 48,
        Zone = 1428,
        _index = 63,
    }, {
        Done = { 3906 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.33, 48.26),
        RaidIcon = { {
            npcID = 9084,
            questID = 3906,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 3906,
        Zone = 1418,
        _index = 64,
    }, {
        Done = { 4023 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 95.09, 31.56),
        RaidIcon = { {
            npcID = 9459,
            questID = 4023,
        } },
        IsQuestOnQuest = 4023,
        Zone = 1428,
        _index = 65,
    }, {
        Done = { 4061 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.02, 47.81),
        RaidIcon = { {
            npcID = 9079,
            questID = 4061,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4061,
        Zone = 1418,
        _index = 66,
    }, {
        Done = { 4182 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.82, 68.95),
        RaidIcon = { {
            npcID = 9562,
            questID = 4182,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4182,
        Zone = 1428,
        _index = 67,
    }, {
        Done = { 4262 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.41, 70.06),
        RaidIcon = { {
            npcID = 9561,
            questID = 4262,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4262,
        Zone = 1428,
        _index = 68,
    }, {
        Done = { 8905 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8905,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        IsQuestOnQuest = 8905,
        Zone = 1455,
        _index = 69,
    }, {
        Done = { 8906 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8906,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        IsQuestOnQuest = 8906,
        Zone = 1455,
        _index = 70,
    }, {
        Done = { 8907 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8907,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8907,
        Zone = 1455,
        _index = 71,
    }, {
        Done = { 8908 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8908,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        IsQuestOnQuest = 8908,
        Zone = 1455,
        _index = 72,
    }, {
        Done = { 8909 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8909,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        IsQuestOnQuest = 8909,
        Zone = 1455,
        _index = 73,
    }, {
        Done = { 8910 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8910,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8910,
        Zone = 1455,
        _index = 74,
    }, {
        Done = { 8911 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8911,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        IsQuestOnQuest = 8911,
        Zone = 1455,
        _index = 75,
    }, {
        Done = { 8912 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8912,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        IsQuestOnQuest = 8912,
        Zone = 1455,
        _index = 76,
    }, {
        Done = { 8913 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8913,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        IsQuestOnQuest = 8913,
        Zone = 1454,
        _index = 77,
    }, {
        Done = { 8914 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8914,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        IsQuestOnQuest = 8914,
        Zone = 1454,
        _index = 78,
    }, {
        Done = { 8915 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8915,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        IsQuestOnQuest = 8915,
        Zone = 1454,
        _index = 79,
    }, {
        Done = { 8916 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8916,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        IsQuestOnQuest = 8916,
        Zone = 1454,
        _index = 80,
    }, {
        Done = { 8917 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8917,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        IsQuestOnQuest = 8917,
        Zone = 1454,
        _index = 81,
    }, {
        Done = { 8918 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8918,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        IsQuestOnQuest = 8918,
        Zone = 1454,
        _index = 82,
    }, {
        Done = { 8919 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8919,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        IsQuestOnQuest = 8919,
        Zone = 1454,
        _index = 83,
    }, {
        Done = { 8920 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8920,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        IsQuestOnQuest = 8920,
        Zone = 1454,
        _index = 84,
    }, {
        PickUp = { 3442 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3442,
        } },
        AnyOf = { {
            IsQuestCompleted = 3441,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 85,
    }, {
        PickUp = { 3701 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 38.37, 55.31),
        RaidIcon = { {
            npcID = 8879,
            questID = 3701,
        } },
        AnyOf = { {
            IsQuestCompleted = 3702,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1455,
        _index = 86,
    }, {
        PickUp = { 3907 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.33, 48.26),
        RaidIcon = { {
            npcID = 9084,
            questID = 3907,
        } },
        AnyOf = { {
            IsQuestCompleted = 3906,
        } },
        Faction = "Horde",
        MinLevel = 48,
        Zone = 1418,
        _index = 87,
    }, {
        PickUp = { 3981 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.96, 47.73),
        RaidIcon = { {
            npcID = 9081,
            questID = 3981,
        } },
        AnyOf = { {
            IsQuestCompleted = 3906,
        } },
        Faction = "Horde",
        MinLevel = 48,
        Zone = 1418,
        _index = 88,
    }, {
        PickUp = { 4062 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.02, 47.81),
        RaidIcon = { {
            npcID = 9079,
            questID = 4062,
        } },
        AnyOf = { {
            IsQuestCompleted = 4061,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1418,
        _index = 89,
    }, {
        PickUp = { 4183 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.82, 68.95),
        RaidIcon = { {
            npcID = 9562,
            questID = 4183,
        } },
        AnyOf = { {
            IsQuestCompleted = 4182,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1428,
        _index = 90,
    }, {
        PickUp = { 4263 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.41, 70.06),
        RaidIcon = { {
            npcID = 9561,
            questID = 4263,
        } },
        AnyOf = { {
            IsQuestCompleted = 4262,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1428,
        _index = 91,
    }, {
        PickUp = { 7201 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 7201,
        } },
        AnyOf = { {
            IsQuestCompleted = 3906,
        } },
        Faction = "Horde",
        MinLevel = 48,
        Zone = 1418,
        _index = 92,
    }, {
        PickUp = { 8922 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8922,
        } },
        AnyOf = { {
            IsQuestCompleted = 8905,
        }, {
            IsQuestCompleted = 8906,
        }, {
            IsQuestCompleted = 8907,
        }, {
            IsQuestCompleted = 8908,
        }, {
            IsQuestCompleted = 8909,
        }, {
            IsQuestCompleted = 8910,
        }, {
            IsQuestCompleted = 8911,
        }, {
            IsQuestCompleted = 8912,
        } },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 93,
    }, {
        PickUp = { 8923 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8923,
        } },
        AnyOf = { {
            IsQuestCompleted = 8913,
        }, {
            IsQuestCompleted = 8914,
        }, {
            IsQuestCompleted = 8915,
        }, {
            IsQuestCompleted = 8916,
        }, {
            IsQuestCompleted = 8917,
        }, {
            IsQuestCompleted = 8918,
        }, {
            IsQuestCompleted = 8919,
        }, {
            IsQuestCompleted = 8920,
        } },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 94,
    }, {
        Qpart = {
            [3442] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 58.3, 76.98),
        IsQuestOnQuest = 3442,
        Zone = 1427,
        _index = 95,
    }, {
        Qpart = {
            [3701] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 60.31, 35.13),
        IsQuestOnQuest = 3701,
        Zone = 1428,
        _index = 96,
    }, {
        Qpart = {
            [4062] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4062,
        _index = 97,
    }, {
        Qpart = {
            [4183] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4183,
        _index = 98,
    }, {
        Qpart = {
            [8922] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8922,
        _index = 99,
    }, {
        Qpart = {
            [8923] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8923,
        _index = 100,
    }, {
        Done = { 3442 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3442,
        } },
        IsQuestOnQuest = 3442,
        Zone = 1427,
        _index = 101,
    }, {
        Done = { 3701 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 38.37, 55.31),
        RaidIcon = { {
            npcID = 8879,
            questID = 3701,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 3701,
        Zone = 1455,
        _index = 102,
    }, {
        Done = { 4062 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 25.95, 44.87),
        RaidIcon = { {
            npcID = 2921,
            questID = 4062,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4062,
        Zone = 1418,
        _index = 103,
    }, {
        Done = { 4183 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1433, 24.9, 44.45),
        RaidIcon = { {
            npcID = 344,
            questID = 4183,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4183,
        Zone = 1433,
        _index = 104,
    }, {
        Done = { 8922 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8922,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8922,
        Zone = 1446,
        _index = 105,
    }, {
        Done = { 8923 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8923,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 8923,
        Zone = 1446,
        _index = 106,
    }, {
        PickUp = { 3443 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3443,
        } },
        AnyOf = { {
            IsQuestCompleted = 3442,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 107,
    }, {
        PickUp = { 4063 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 25.95, 44.87),
        RaidIcon = { {
            npcID = 2921,
            questID = 4063,
        } },
        AnyOf = { {
            IsQuestCompleted = 4062,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1418,
        _index = 108,
    }, {
        PickUp = { 4184 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1433, 24.9, 44.45),
        RaidIcon = { {
            npcID = 344,
            questID = 4184,
        } },
        AnyOf = { {
            IsQuestCompleted = 4183,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1433,
        _index = 109,
    }, {
        PickUp = { 4341 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 39.09, 56.2),
        RaidIcon = { {
            npcID = 2784,
            questID = 4341,
        } },
        AnyOf = { {
            IsQuestCompleted = 3701,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1455,
        _index = 110,
    }, {
        PickUp = { 8921 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8921,
        } },
        AnyOf = { {
            IsQuestCompleted = 8922,
        }, {
            IsQuestCompleted = 8923,
        } },
        MinLevel = 58,
        Zone = 1446,
        _index = 111,
    }, {
        Qpart = {
            [3443] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 69.35, 32.7),
        IsQuestOnQuest = 3443,
        Zone = 1427,
        _index = 112,
    }, {
        Qpart = {
            [4184] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4184,
        _index = 113,
    }, {
        Qpart = {
            [8921] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8921,
        _index = 114,
    }, {
        Done = { 3443 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3443,
        } },
        IsQuestOnQuest = 3443,
        Zone = 1427,
        _index = 115,
    }, {
        Done = { 4184 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.21, 38.35),
        RaidIcon = { {
            npcID = 1748,
            questID = 4184,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4184,
        Zone = 1453,
        _index = 116,
    }, {
        Done = { 8921 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8921,
        } },
        IsQuestOnQuest = 8921,
        Zone = 1446,
        _index = 117,
    }, {
        PickUp = { 3452 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3452,
        } },
        AnyOf = { {
            IsQuestCompleted = 3443,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 118,
    }, {
        PickUp = { 4185 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.21, 38.35),
        RaidIcon = { {
            npcID = 1748,
            questID = 4185,
        } },
        AnyOf = { {
            IsQuestCompleted = 4184,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1453,
        _index = 119,
    }, {
        PickUp = { 8924 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8924,
        } },
        AnyOf = { {
            IsQuestCompleted = 8921,
        } },
        MinLevel = 58,
        Zone = 1446,
        _index = 120,
    }, {
        Qpart = {
            [3452] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 24.06, 34.16),
        IsQuestOnQuest = 3452,
        Zone = 1427,
        _index = 121,
    }, {
        Qpart = {
            [4185] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.1, 38.17),
        IsQuestOnQuest = 4185,
        Zone = 1453,
        _index = 122,
    }, {
        Qpart = {
            [8924] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 60.94, 58.39),
        IsQuestOnQuest = 8924,
        Zone = 1451,
        _index = 123,
    }, {
        Done = { 3452 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3452,
        } },
        IsQuestOnQuest = 3452,
        Zone = 1427,
        _index = 124,
    }, {
        Done = { 4185 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.21, 38.35),
        RaidIcon = { {
            npcID = 1748,
            questID = 4185,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4185,
        Zone = 1453,
        _index = 125,
    }, {
        Done = { 8924 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8924,
        } },
        IsQuestOnQuest = 8924,
        Zone = 1446,
        _index = 126,
    }, {
        PickUp = { 3453 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3453,
        } },
        AnyOf = { {
            IsQuestCompleted = 3452,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 127,
    }, {
        PickUp = { 4186 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.21, 38.35),
        RaidIcon = { {
            npcID = 1748,
            questID = 4186,
        } },
        AnyOf = { {
            IsQuestCompleted = 4185,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1453,
        _index = 128,
    }, {
        PickUp = { 8925 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8925,
        } },
        AnyOf = { {
            IsQuestCompleted = 8924,
        } },
        MinLevel = 58,
        Zone = 1446,
        _index = 129,
    }, {
        Qpart = {
            [3453] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        IsQuestOnQuest = 3453,
        Zone = 1427,
        _index = 130,
    }, {
        Qpart = {
            [4186] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4186,
        _index = 131,
    }, {
        Qpart = {
            [8925] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 35.39, 57.76),
        IsQuestOnQuest = 8925,
        Zone = 1428,
        _index = 132,
    }, {
        Done = { 3453 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3453,
        } },
        IsQuestOnQuest = 3453,
        Zone = 1427,
        _index = 133,
    }, {
        Done = { 4186 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1433, 24.9, 44.45),
        RaidIcon = { {
            npcID = 344,
            questID = 4186,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4186,
        Zone = 1433,
        _index = 134,
    }, {
        Done = { 8925 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8925,
        } },
        IsQuestOnQuest = 8925,
        Zone = 1446,
        _index = 135,
    }, {
        PickUp = { 3454 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3454,
        } },
        AnyOf = { {
            IsQuestCompleted = 3453,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 136,
    }, {
        PickUp = { 4223 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1433, 24.9, 44.45),
        RaidIcon = { {
            npcID = 344,
            questID = 4223,
        } },
        AnyOf = { {
            IsQuestCompleted = 4186,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1433,
        _index = 137,
    }, {
        PickUp = { 8928 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8928,
        } },
        AnyOf = { {
            IsQuestCompleted = 8925,
        } },
        MinLevel = 58,
        Zone = 1446,
        _index = 138,
    }, {
        Done = { 3454 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 39.07),
        IsQuestOnQuest = 3454,
        Zone = 1427,
        _index = 139,
    }, {
        Done = { 4223 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 4223,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4223,
        Zone = 1428,
        _index = 140,
    }, {
        Qpart = {
            [8928] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8928,
        _index = 141,
    }, {
        PickUp = { 3462 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.06, 38.99),
        RaidIcon = { {
            npcID = 8479,
            questID = 3462,
        } },
        AnyOf = { {
            IsQuestCompleted = 3454,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 142,
    }, {
        PickUp = { 4224 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 4224,
        } },
        AnyOf = { {
            IsQuestCompleted = 4223,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1428,
        _index = 143,
    }, {
        Done = { 8928 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8928,
        } },
        IsQuestOnQuest = 8928,
        Zone = 1446,
        _index = 144,
    }, {
        Done = { 3462 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.17, 39),
        RaidIcon = { {
            npcID = 8509,
            questID = 3462,
        } },
        IsQuestOnQuest = 3462,
        Zone = 1427,
        _index = 145,
    }, {
        Qpart = {
            [4224] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.01, 23.76),
        IsQuestOnQuest = 4224,
        Zone = 1428,
        _index = 146,
    }, {
        PickUp = { 8977 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8977,
        } },
        AnyOf = { {
            IsQuestCompleted = 8928,
        } },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1446,
        _index = 147,
    }, {
        PickUp = { 8978 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8978,
        } },
        AnyOf = { {
            IsQuestCompleted = 8928,
        } },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1446,
        _index = 148,
    }, {
        PickUp = { 3463 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.17, 39),
        RaidIcon = { {
            npcID = 8509,
            questID = 3463,
        } },
        AnyOf = { {
            IsQuestCompleted = 3462,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 149,
    }, {
        Done = { 4224 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 4224,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4224,
        Zone = 1428,
        _index = 150,
    }, {
        Qpart = {
            [8977] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8977,
        _index = 151,
    }, {
        Qpart = {
            [8978] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8978,
        _index = 152,
    }, {
        Qpart = {
            [3463] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 35.67, 60.68),
        IsQuestOnQuest = 3463,
        Zone = 1427,
        _index = 153,
    }, {
        PickUp = { 4241 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 4241,
        } },
        AnyOf = { {
            IsQuestCompleted = 4224,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        Zone = 1428,
        _index = 154,
    }, {
        Done = { 8977 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8977,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8977,
        Zone = 1455,
        _index = 155,
    }, {
        Done = { 8978 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8978,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 8978,
        Zone = 1454,
        _index = 156,
    }, {
        Done = { 3463 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 39.17, 39),
        RaidIcon = { {
            npcID = 8509,
            questID = 3463,
        } },
        IsQuestOnQuest = 3463,
        Zone = 1427,
        _index = 157,
    }, {
        PickUp = { 8926 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8926,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 158,
    }, {
        PickUp = { 8927 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8927,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 159,
    }, {
        PickUp = { 8931 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8931,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 160,
    }, {
        PickUp = { 8932 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8932,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 161,
    }, {
        PickUp = { 8933 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8933,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 162,
    }, {
        PickUp = { 8934 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8934,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 163,
    }, {
        PickUp = { 8935 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8935,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 164,
    }, {
        PickUp = { 8936 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8936,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 165,
    }, {
        PickUp = { 8937 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8937,
        } },
        AnyOf = { {
            IsQuestCompleted = 8977,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 166,
    }, {
        PickUp = { 8938 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8938,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 167,
    }, {
        PickUp = { 8939 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8939,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 168,
    }, {
        PickUp = { 8940 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8940,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 169,
    }, {
        PickUp = { 8941 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8941,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 170,
    }, {
        PickUp = { 8942 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8942,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 171,
    }, {
        PickUp = { 8943 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8943,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 172,
    }, {
        PickUp = { 8944 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8944,
        } },
        AnyOf = { {
            IsQuestCompleted = 8978,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 173,
    }, {
        PickUp = { 3481 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 38.85, 38.99),
        AnyOf = { {
            IsQuestCompleted = 3463,
        } },
        MinLevel = 40,
        Zone = 1427,
        _index = 174,
    }, {
        Qpart = {
            [8926] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8926,
        _index = 175,
    }, {
        Qpart = {
            [8927] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8927,
        _index = 176,
    }, {
        Qpart = {
            [8931] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8931,
        _index = 177,
    }, {
        Qpart = {
            [8932] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8932,
        _index = 178,
    }, {
        Qpart = {
            [8933] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 51.93, 23.82),
        IsQuestOnQuest = 8933,
        Zone = 1422,
        _index = 179,
    }, {
        Qpart = {
            [8934] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8934,
        _index = 180,
    }, {
        Qpart = {
            [8935] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8935,
        _index = 181,
    }, {
        Qpart = {
            [8936] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8936,
        _index = 182,
    }, {
        Qpart = {
            [8937] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8937,
        _index = 183,
    }, {
        Qpart = {
            [8938] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8938,
        _index = 184,
    }, {
        Qpart = {
            [8939] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8939,
        _index = 185,
    }, {
        Qpart = {
            [8940] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8940,
        _index = 186,
    }, {
        Qpart = {
            [8941] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8941,
        _index = 187,
    }, {
        Qpart = {
            [8942] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8942,
        _index = 188,
    }, {
        Qpart = {
            [8943] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8943,
        _index = 189,
    }, {
        Qpart = {
            [8944] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8944,
        _index = 190,
    }, {
        Done = { 3481 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 38.85, 38.99),
        IsQuestOnQuest = 3481,
        Zone = 1427,
        _index = 191,
    }, {
        Done = { 8926 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8926,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        IsQuestOnQuest = 8926,
        Zone = 1455,
        _index = 192,
    }, {
        Done = { 8927 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8927,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        IsQuestOnQuest = 8927,
        Zone = 1454,
        _index = 193,
    }, {
        Done = { 8931 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8931,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        IsQuestOnQuest = 8931,
        Zone = 1455,
        _index = 194,
    }, {
        Done = { 8932 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8932,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8932,
        Zone = 1455,
        _index = 195,
    }, {
        Done = { 8933 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8933,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        IsQuestOnQuest = 8933,
        Zone = 1455,
        _index = 196,
    }, {
        Done = { 8934 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8934,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        IsQuestOnQuest = 8934,
        Zone = 1455,
        _index = 197,
    }, {
        Done = { 8935 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8935,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8935,
        Zone = 1455,
        _index = 198,
    }, {
        Done = { 8936 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8936,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        IsQuestOnQuest = 8936,
        Zone = 1455,
        _index = 199,
    }, {
        Done = { 8937 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8937,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        IsQuestOnQuest = 8937,
        Zone = 1455,
        _index = 200,
    }, {
        Done = { 8938 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8938,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        IsQuestOnQuest = 8938,
        Zone = 1454,
        _index = 201,
    }, {
        Done = { 8939 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8939,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        IsQuestOnQuest = 8939,
        Zone = 1454,
        _index = 202,
    }, {
        Done = { 8940 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8940,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        IsQuestOnQuest = 8940,
        Zone = 1454,
        _index = 203,
    }, {
        Done = { 8941 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8941,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        IsQuestOnQuest = 8941,
        Zone = 1454,
        _index = 204,
    }, {
        Done = { 8942 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8942,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        IsQuestOnQuest = 8942,
        Zone = 1454,
        _index = 205,
    }, {
        Done = { 8943 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8943,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        IsQuestOnQuest = 8943,
        Zone = 1454,
        _index = 206,
    }, {
        Done = { 8944 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8944,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        IsQuestOnQuest = 8944,
        Zone = 1454,
        _index = 207,
    }, {
        PickUp = { 4022 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 95.09, 31.56),
        RaidIcon = { {
            npcID = 9459,
            questID = 4022,
        } },
        AnyOf = { {
            IsQuestCompleted = 3481,
        } },
        MinLevel = 52,
        Zone = 1428,
        _index = 208,
    }, {
        PickUp = { 8929 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8929,
        } },
        AnyOf = { {
            IsQuestCompleted = 8926,
        }, {
            IsQuestCompleted = 8931,
        }, {
            IsQuestCompleted = 8932,
        }, {
            IsQuestCompleted = 8933,
        }, {
            IsQuestCompleted = 8934,
        }, {
            IsQuestCompleted = 8935,
        }, {
            IsQuestCompleted = 8936,
        }, {
            IsQuestCompleted = 8937,
        } },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 209,
    }, {
        PickUp = { 8930 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8930,
        } },
        AnyOf = { {
            IsQuestCompleted = 8927,
        }, {
            IsQuestCompleted = 8938,
        }, {
            IsQuestCompleted = 8939,
        }, {
            IsQuestCompleted = 8940,
        }, {
            IsQuestCompleted = 8941,
        }, {
            IsQuestCompleted = 8942,
        }, {
            IsQuestCompleted = 8943,
        }, {
            IsQuestCompleted = 8944,
        } },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 210,
    }, {
        Qpart = {
            [4022] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 94.4, 31.8),
        IsQuestOnQuest = 4022,
        Zone = 1428,
        _index = 211,
    }, {
        Done = { 8929 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8929,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8929,
        Zone = 1423,
        _index = 212,
    }, {
        Done = { 8930 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8930,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 8930,
        Zone = 1423,
        _index = 213,
    }, {
        Done = { 4022 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 95.09, 31.56),
        RaidIcon = { {
            npcID = 9459,
            questID = 4022,
        } },
        IsQuestOnQuest = 4022,
        Zone = 1428,
        _index = 214,
    }, {
        PickUp = { 8945 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8945,
        } },
        AnyOf = { {
            IsQuestCompleted = 8929,
        }, {
            IsQuestCompleted = 8930,
        } },
        MinLevel = 58,
        Zone = 1423,
        _index = 215,
    }, {
        PickUp = { 4024 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 95.09, 31.56),
        RaidIcon = { {
            npcID = 9459,
            questID = 4024,
        } },
        AnyOf = { {
            IsQuestCompleted = 4022,
        }, {
            IsQuestCompleted = 4023,
        } },
        MinLevel = 52,
        Zone = 1428,
        _index = 216,
    }, {
        Qpart = {
            [8945] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8945,
        _index = 217,
    }, {
        Done = { 8945 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16031,
            questID = 8945,
        } },
        IsQuestOnQuest = 8945,
        _index = 218,
    }, {
        PickUp = { 8946 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16031,
            questID = 8946,
        } },
        AnyOf = { {
            IsQuestCompleted = 8945,
        } },
        MinLevel = 58,
        _index = 219,
    }, {
        Qpart = {
            [8946] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8946,
        _index = 220,
    }, {
        Done = { 8946 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8946,
        } },
        IsQuestOnQuest = 8946,
        Zone = 1423,
        _index = 221,
    }, {
        PickUp = { 8947 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8947,
        } },
        AnyOf = { {
            IsQuestCompleted = 8946,
        } },
        MinLevel = 58,
        Zone = 1423,
        _index = 222,
    }, {
        Qpart = {
            [8947] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8947,
        _index = 223,
    }, {
        Done = { 8947 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8947,
        } },
        IsQuestOnQuest = 8947,
        Zone = 1423,
        _index = 224,
    }, {
        PickUp = { 8948 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8948,
        } },
        AnyOf = { {
            IsQuestCompleted = 8947,
        } },
        MinLevel = 58,
        Zone = 1423,
        _index = 225,
    }, {
        Qpart = {
            [8948] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8948,
        _index = 226,
    }, {
        Done = { 8948 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8948,
        } },
        IsQuestOnQuest = 8948,
        _index = 227,
    }, {
        PickUp = { 8949 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8949,
        } },
        AnyOf = { {
            IsQuestCompleted = 8948,
        } },
        MinLevel = 58,
        _index = 228,
    }, {
        Qpart = {
            [8949] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.95, 46.58),
        IsQuestOnQuest = 8949,
        Zone = 1444,
        _index = 229,
    }, {
        Done = { 8949 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8949,
        } },
        IsQuestOnQuest = 8949,
        _index = 230,
    }, {
        PickUp = { 8950 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8950,
        } },
        AnyOf = { {
            IsQuestCompleted = 8949,
        } },
        MinLevel = 58,
        _index = 231,
    }, {
        Qpart = {
            [8950] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8950,
        _index = 232,
    }, {
        Done = { 8950 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8950,
        } },
        IsQuestOnQuest = 8950,
        _index = 233,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_230",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 27.6, 72.4),
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        Zone = 1427,
        _index = 234,
    }, {
        PickUp = { 4083 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        MinLevel = 40,
        _index = 235,
    }, {
        PickUp = { 4201 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9500,
            questID = 4201,
        } },
        MinLevel = 50,
        _index = 236,
    }, {
        PickUp = { 4295 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9503,
            questID = 4295,
        } },
        MinLevel = 42,
        _index = 237,
    }, {
        PickUp = { 9015 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 9015,
        } },
        AnyOf = { {
            IsQuestCompleted = 8950,
        } },
        MinLevel = 58,
        _index = 238,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "High Interrogator Gerstahn",
            npcID = 9018,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 239,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Lord Roccor",
            npcID = 9025,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 240,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Houndmaster Grebmar",
            npcID = 9319,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 241,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Lord Incendius",
            npcID = 9017,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 242,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Warder Stilgiss",
            npcID = 9041,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 243,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Fineous Darkvire",
            npcID = 9056,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 244,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Bael'Gar",
            npcID = 9016,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 245,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "General Angerforge",
            npcID = 9033,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 246,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Golem Lord Argelmach",
            npcID = 8983,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 247,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Hurley Blackbreath",
            npcID = 9537,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 248,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Phalanx",
            npcID = 9502,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 249,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Ribbly Screwspigot",
            npcID = 9543,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 250,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Plugger Spazzring",
            npcID = 9499,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 251,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Ambassador Flamelash",
            npcID = 9156,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 252,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Magmus",
            npcID = 9938,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 253,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Princess Moira Bronzebeard",
            npcID = 8929,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 254,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_230",
            name = "Emperor Dagran Thaurissan",
            npcID = 9019,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        _index = 255,
    }, {
        Qpart = {
            [3802] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 3802,
        _index = 256,
    }, {
        Qpart = {
            [3907] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 3907,
        _index = 257,
    }, {
        Done = { 3981 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9020,
            questID = 3981,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 3981,
        _index = 258,
    }, {
        Qpart = {
            [4024] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4024,
        _index = 259,
    }, {
        Qpart = {
            [4063] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4063,
        _index = 260,
    }, {
        Qpart = {
            [4081] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4081,
        _index = 261,
    }, {
        Qpart = {
            [4083] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4083,
        _index = 262,
    }, {
        Qpart = {
            [4123] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4123,
        _index = 263,
    }, {
        Qpart = {
            [4126] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4126,
        _index = 264,
    }, {
        Qpart = {
            [4134] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4134,
        _index = 265,
    }, {
        Qpart = {
            [4136] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4136,
        _index = 266,
    }, {
        Qpart = {
            [4201] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4201,
        _index = 267,
    }, {
        Done = { 4241 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9023,
            questID = 4241,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4241,
        _index = 268,
    }, {
        Qpart = {
            [4263] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4263,
        _index = 269,
    }, {
        Qpart = {
            [4286] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4286,
        _index = 270,
    }, {
        Qpart = {
            [4295] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4295,
        _index = 271,
    }, {
        Done = { 4341 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9021,
            questID = 4341,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4341,
        _index = 272,
    }, {
        Qpart = {
            [7201] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 7201,
        _index = 273,
    }, {
        PickUp = { 7604 },
        Button = {
            ["7604"] = 18628,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        ItemCount = {
            count = 1,
            itemID = 18628,
        },
        MinLevel = 60,
        _index = 274,
    }, {
        Qpart = {
            [9015] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 9015,
        _index = 275,
    }, {
        Done = { 3802 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 3802,
        _index = 276,
    }, {
        PickUp = { 3982 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9020,
            questID = 3982,
        } },
        AnyOf = { {
            IsQuestCompleted = 3981,
        } },
        Faction = "Horde",
        MinLevel = 48,
        _index = 277,
    }, {
        Done = { 4083 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4083,
        _index = 278,
    }, {
        Done = { 4201 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9500,
            questID = 4201,
        } },
        IsQuestOnQuest = 4201,
        _index = 279,
    }, {
        PickUp = { 4242 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9023,
            questID = 4242,
        } },
        AnyOf = { {
            IsQuestCompleted = 4241,
        } },
        Faction = "Alliance",
        MinLevel = 48,
        _index = 280,
    }, {
        Done = { 4295 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9503,
            questID = 4295,
        } },
        IsQuestOnQuest = 4295,
        _index = 281,
    }, {
        PickUp = { 4342 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9021,
            questID = 4342,
        } },
        AnyOf = { {
            IsQuestCompleted = 4341,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        _index = 282,
    }, {
        Qpart = {
            [7604] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 7604,
        _index = 283,
    }, {
        Qpart = {
            [3982] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 3982,
        _index = 284,
    }, {
        Qpart = {
            [4342] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4342,
        _index = 285,
    }, {
        Done = { 7604 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 12944,
            questID = 7604,
        } },
        IsQuestOnQuest = 7604,
        _index = 286,
    }, {
        Done = { 3982 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9020,
            questID = 3982,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 3982,
        _index = 287,
    }, {
        Done = { 4342 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9021,
            questID = 4342,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4342,
        _index = 288,
    }, {
        PickUp = { 4001 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9020,
            questID = 4001,
        } },
        AnyOf = { {
            IsQuestCompleted = 3982,
        } },
        Faction = "Horde",
        MinLevel = 48,
        _index = 289,
    }, {
        PickUp = { 4361 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9021,
            questID = 4361,
        } },
        AnyOf = { {
            IsQuestCompleted = 4342,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        _index = 290,
    }, {
        Qpart = {
            [4001] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4001,
        _index = 291,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_230",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        _index = 292,
    }, {
        Done = { 3907 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.33, 48.26),
        RaidIcon = { {
            npcID = 9084,
            questID = 3907,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 3907,
        Zone = 1418,
        _index = 293,
    }, {
        Done = { 4001 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4001,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4001,
        Zone = 1454,
        _index = 294,
    }, {
        Done = { 4024 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 95.09, 31.56),
        RaidIcon = { {
            npcID = 9459,
            questID = 4024,
        } },
        IsQuestOnQuest = 4024,
        Zone = 1428,
        _index = 295,
    }, {
        Done = { 4063 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 25.95, 44.87),
        RaidIcon = { {
            npcID = 2921,
            questID = 4063,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4063,
        Zone = 1418,
        _index = 296,
    }, {
        Done = { 4081 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.81, 47.52),
        RaidIcon = { {
            npcID = 9077,
            questID = 4081,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4081,
        Zone = 1418,
        _index = 297,
    }, {
        Done = { 4123 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.15, 23.91),
        RaidIcon = { {
            npcID = 9536,
            questID = 4123,
        } },
        IsQuestOnQuest = 4123,
        Zone = 1428,
        _index = 298,
    }, {
        Done = { 4126 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 46.83, 52.36),
        RaidIcon = { {
            npcID = 1267,
            questID = 4126,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4126,
        Zone = 1426,
        _index = 299,
    }, {
        Done = { 4134 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 4134,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4134,
        Zone = 1418,
        _index = 300,
    }, {
        Done = { 4136 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 66.06, 21.95),
        RaidIcon = { {
            npcID = 9544,
            questID = 4136,
        } },
        IsQuestOnQuest = 4136,
        Zone = 1428,
        _index = 301,
    }, {
        Done = { 4242 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 4242,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4242,
        Zone = 1428,
        _index = 302,
    }, {
        Done = { 4263 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.41, 70.06),
        RaidIcon = { {
            npcID = 9561,
            questID = 4263,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4263,
        Zone = 1428,
        _index = 303,
    }, {
        Done = { 4286 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.56, 68.68),
        RaidIcon = { {
            npcID = 9177,
            questID = 4286,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4286,
        Zone = 1428,
        _index = 304,
    }, {
        Done = { 4361 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 39.09, 56.2),
        RaidIcon = { {
            npcID = 2784,
            questID = 4361,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4361,
        Zone = 1455,
        _index = 305,
    }, {
        Done = { 7201 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 7201,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 7201,
        Zone = 1418,
        _index = 306,
    }, {
        Done = { 9015 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9015,
        } },
        IsQuestOnQuest = 9015,
        Zone = 1423,
        _index = 307,
    }, {
        PickUp = { 4002 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4002,
        } },
        AnyOf = { {
            IsQuestCompleted = 4001,
        } },
        Faction = "Horde",
        MinLevel = 48,
        Zone = 1454,
        _index = 308,
    }, {
        PickUp = { 4082 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 3.94, 46.73),
        AnyOf = { {
            IsQuestCompleted = 4081,
        } },
        Faction = "Horde",
        MinLevel = 50,
        Zone = 1418,
        _index = 309,
    }, {
        PickUp = { 4362 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 39.09, 56.2),
        RaidIcon = { {
            npcID = 2784,
            questID = 4362,
        } },
        AnyOf = { {
            IsQuestCompleted = 4361,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1455,
        _index = 310,
    }, {
        Done = { 4002 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4002,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4002,
        Zone = 1454,
        _index = 311,
    }, {
        PickUp = { 4003 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4003,
        } },
        AnyOf = { {
            IsQuestCompleted = 4002,
        } },
        Faction = "Horde",
        MinLevel = 48,
        Zone = 1454,
        _index = 312,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_230",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 27.6, 72.4),
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        Zone = 1427,
        _index = 313,
    }, {
        Qpart = {
            [4003] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4003,
        _index = 314,
    }, {
        Qpart = {
            [4082] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4082,
        _index = 315,
    }, {
        PickUp = { 4264 },
        Button = {
            ["4264"] = 11446,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 4242,
        } },
        Faction = "Alliance",
        ItemCount = {
            count = 1,
            itemID = 11446,
        },
        MinLevel = 50,
        _index = 316,
    }, {
        Qpart = {
            [4362] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4362,
        _index = 317,
    }, {
        Done = { 4003 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 8929,
            questID = 4003,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4003,
        _index = 318,
    }, {
        Qpart = {
            [4264] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4264,
        _index = 319,
    }, {
        Done = { 4362 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 8929,
            questID = 4362,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4362,
        _index = 320,
    }, {
        PickUp = { 4004 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 8929,
            questID = 4004,
        } },
        AnyOf = { {
            IsQuestCompleted = 4003,
        } },
        Faction = "Horde",
        MinLevel = 48,
        _index = 321,
    }, {
        Done = { 4264 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9023,
            questID = 4264,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4264,
        _index = 322,
    }, {
        PickUp = { 4363 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 8929,
            questID = 4363,
        } },
        AnyOf = { {
            IsQuestCompleted = 4362,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        _index = 323,
    }, {
        PickUp = { 4282 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9023,
            questID = 4282,
        } },
        AnyOf = { {
            IsQuestCompleted = 4264,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        _index = 324,
    }, {
        Qpart = {
            [4282] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4282,
        _index = 325,
    }, {
        Done = { 4282 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9023,
            questID = 4282,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4282,
        _index = 326,
    }, {
        PickUp = { 4322 },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9023,
            questID = 4322,
        } },
        AnyOf = { {
            IsQuestCompleted = 4282,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        _index = 327,
    }, {
        Qpart = {
            [4322] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4322,
        _index = 328,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_230",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        _index = 329,
    }, {
        Done = { 4004 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4004,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4004,
        Zone = 1454,
        _index = 330,
    }, {
        Done = { 4082 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.81, 47.52),
        RaidIcon = { {
            npcID = 9077,
            questID = 4082,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4082,
        Zone = 1418,
        _index = 331,
    }, {
        Done = { 4322 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 4322,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4322,
        Zone = 1428,
        _index = 332,
    }, {
        Done = { 4363 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 39.09, 56.2),
        RaidIcon = { {
            npcID = 2784,
            questID = 4363,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4363,
        Zone = 1455,
        _index = 333,
    }, {
        PickUp = { 4122 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.88, 47.63),
        RaidIcon = { {
            npcID = 9080,
            questID = 4122,
        } },
        AnyOf = { {
            IsQuestCompleted = 4082,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1418,
        _index = 334,
    }, {
        PickUp = { 6402 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 6402,
        } },
        AnyOf = { {
            IsQuestCompleted = 4322,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1428,
        _index = 335,
    }, {
        Done = { 4122 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 40.2, 34.24),
        RaidIcon = { {
            npcID = 9520,
            questID = 4122,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4122,
        Zone = 1428,
        _index = 336,
    }, {
        Done = { 6402 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 73.61, 91.05),
        RaidIcon = { {
            npcID = 12580,
            questID = 6402,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 6402,
        Zone = 1453,
        _index = 337,
    }, {
        PickUp = { 4121 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 40.2, 34.24),
        RaidIcon = { {
            npcID = 9520,
            questID = 4121,
        } },
        AnyOf = { {
            IsQuestCompleted = 4122,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1428,
        _index = 338,
    }, {
        PickUp = { 6403 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 73.61, 91.05),
        RaidIcon = { {
            npcID = 12580,
            questID = 6403,
        } },
        AnyOf = { {
            IsQuestCompleted = 6402,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1453,
        _index = 339,
    }, {
        Qpart = {
            [6403] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 6403,
        _index = 340,
    }, {
        Done = { 6403 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.21, 38.35),
        RaidIcon = { {
            npcID = 1748,
            questID = 6403,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 6403,
        Zone = 1453,
        _index = 341,
    }, {
        PickUp = { 6501 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.21, 38.35),
        RaidIcon = { {
            npcID = 1748,
            questID = 6501,
        } },
        AnyOf = { {
            IsQuestCompleted = 6403,
        } },
        Faction = "Alliance",
        MinLevel = 50,
        Zone = 1453,
        _index = 342,
    }, {
        Qpart = {
            [6501] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 6501,
        _index = 343,
    }, {
        Done = { 6501 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 54.55, 51.2),
        RaidIcon = { {
            npcID = 10929,
            questID = 6501,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 6501,
        Zone = 1452,
        _index = 344,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_230",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 27.6, 72.4),
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        Zone = 1427,
        _index = 345,
    }, {
        Qpart = {
            [4121] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4121,
        _index = 346,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_230",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        _index = 347,
    }, {
        Done = { 4121 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.88, 47.63),
        RaidIcon = { {
            npcID = 9080,
            questID = 4121,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4121,
        Zone = 1418,
        _index = 348,
    }, {
        PickUp = { 4132 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.81, 47.52),
        RaidIcon = { {
            npcID = 9077,
            questID = 4132,
        } },
        AnyOf = { {
            IsQuestCompleted = 4121,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1418,
        _index = 349,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_230",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427, 27.6, 72.4),
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        Zone = 1427,
        _index = 350,
    }, {
        Qpart = {
            [4132] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        InstanceQuest = true,
        IsQuestOnQuest = 4132,
        _index = 351,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_230",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_230",
        _index = 352,
    }, {
        Done = { 4132 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.81, 47.52),
        RaidIcon = { {
            npcID = 9077,
            questID = 4132,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4132,
        Zone = 1418,
        _index = 353,
    }, {
        RouteCompleted = true,
        _index = 354,
    } },
}
