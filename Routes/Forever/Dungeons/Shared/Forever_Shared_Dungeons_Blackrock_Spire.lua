local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Blackrock-Spire"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 55,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Blackrock Spire"],
    levelRange = {
        max = 60,
        min = 55,
    },
    mapID = 1428,
    steps = { {
        PickUp = { 3520 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 3520,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 1,
    }, {
        PickUp = { 4701 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.82, 68.95),
        RaidIcon = { {
            npcID = 9562,
            questID = 4701,
        } },
        Faction = "Alliance",
        MinLevel = 55,
        Zone = 1428,
        _index = 2,
    }, {
        PickUp = { 4724 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.96, 47.73),
        RaidIcon = { {
            npcID = 9081,
            questID = 4724,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1418,
        _index = 3,
    }, {
        PickUp = { 4726 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4726,
        } },
        MinLevel = 50,
        Zone = 1428,
        _index = 4,
    }, {
        PickUp = { 4729 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.89, 21.92),
        RaidIcon = { {
            npcID = 10260,
            questID = 4729,
        } },
        MinLevel = 55,
        Zone = 1428,
        _index = 5,
    }, {
        PickUp = { 4764 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.84, 69.12),
        RaidIcon = { {
            npcID = 9565,
            questID = 4764,
        } },
        Faction = "Alliance",
        MinLevel = 57,
        Zone = 1428,
        _index = 6,
    }, {
        PickUp = { 4766 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 76.94, 47.83),
        RaidIcon = { {
            npcID = 2285,
            questID = 4766,
        } },
        Faction = "Alliance",
        MinLevel = 57,
        Zone = 1453,
        _index = 7,
    }, {
        PickUp = { 4768 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 4768,
        } },
        Faction = "Horde",
        MinLevel = 57,
        Zone = 1418,
        _index = 8,
    }, {
        PickUp = { 4769 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 50.14, 67.97),
        RaidIcon = { {
            npcID = 5204,
            questID = 4769,
        } },
        Faction = "Horde",
        MinLevel = 57,
        Zone = 1458,
        _index = 9,
    }, {
        PickUp = { 4862 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.89, 21.92),
        RaidIcon = { {
            npcID = 10260,
            questID = 4862,
        } },
        MinLevel = 55,
        Zone = 1428,
        _index = 10,
    }, {
        PickUp = { 4866 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.01, 23.76),
        RaidIcon = { {
            npcID = 9563,
            questID = 4866,
        } },
        MinLevel = 55,
        Zone = 1428,
        _index = 11,
    }, {
        PickUp = { 4981 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.88, 47.63),
        RaidIcon = { {
            npcID = 9080,
            questID = 4981,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1418,
        _index = 12,
    }, {
        PickUp = { 5126 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 63.79, 73.76),
        RaidIcon = { {
            npcID = 10918,
            questID = 5126,
        } },
        Class = { "WARRIOR", "PALADIN", "SHAMAN" },
        MinLevel = 55,
        Zone = 1452,
        _index = 13,
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
        _index = 14,
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
        _index = 15,
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
        _index = 16,
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
        _index = 17,
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
        _index = 18,
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
        _index = 19,
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
        _index = 20,
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
        _index = 21,
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
        _index = 22,
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
        _index = 23,
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
        _index = 24,
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
        _index = 25,
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
        _index = 26,
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
        _index = 27,
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
        _index = 28,
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
        _index = 29,
    }, {
        Qpart = {
            [3520] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 43.07, 36.94),
        IsQuestOnQuest = 3520,
        Zone = 1444,
        _index = 30,
    }, {
        Qpart = {
            [4726] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4726,
        _index = 31,
    }, {
        Done = { 4766 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.84, 69.12),
        RaidIcon = { {
            npcID = 9565,
            questID = 4766,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4766,
        Zone = 1428,
        _index = 32,
    }, {
        Done = { 4769 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 4769,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4769,
        Zone = 1418,
        _index = 33,
    }, {
        Qpart = {
            [5126] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 63.79, 73.76),
        IsQuestOnQuest = 5126,
        Zone = 1452,
        _index = 34,
    }, {
        Qpart = {
            [8905] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8905,
        Zone = 1452,
        _index = 35,
    }, {
        Qpart = {
            [8906] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8906,
        Zone = 1452,
        _index = 36,
    }, {
        Qpart = {
            [8907] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8907,
        Zone = 1452,
        _index = 37,
    }, {
        Qpart = {
            [8908] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8908,
        Zone = 1452,
        _index = 38,
    }, {
        Qpart = {
            [8909] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8909,
        Zone = 1452,
        _index = 39,
    }, {
        Qpart = {
            [8910] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8910,
        Zone = 1452,
        _index = 40,
    }, {
        Qpart = {
            [8911] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8911,
        Zone = 1452,
        _index = 41,
    }, {
        Qpart = {
            [8912] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8912,
        Zone = 1452,
        _index = 42,
    }, {
        Qpart = {
            [8913] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8913,
        Zone = 1451,
        _index = 43,
    }, {
        Qpart = {
            [8914] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8914,
        Zone = 1451,
        _index = 44,
    }, {
        Qpart = {
            [8915] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8915,
        Zone = 1451,
        _index = 45,
    }, {
        Qpart = {
            [8916] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8916,
        Zone = 1451,
        _index = 46,
    }, {
        Qpart = {
            [8917] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8917,
        Zone = 1451,
        _index = 47,
    }, {
        Qpart = {
            [8918] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8918,
        Zone = 1451,
        _index = 48,
    }, {
        Qpart = {
            [8919] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8919,
        Zone = 1451,
        _index = 49,
    }, {
        Qpart = {
            [8920] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8920,
        Zone = 1451,
        _index = 50,
    }, {
        Done = { 3520 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 3520,
        } },
        IsQuestOnQuest = 3520,
        Zone = 1446,
        _index = 51,
    }, {
        Done = { 4726 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4726,
        } },
        IsQuestOnQuest = 4726,
        Zone = 1428,
        _index = 52,
    }, {
        Done = { 5126 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 63.79, 73.76),
        RaidIcon = { {
            npcID = 10918,
            questID = 5126,
        } },
        Class = { "WARRIOR", "PALADIN", "SHAMAN" },
        IsQuestOnQuest = 5126,
        Zone = 1452,
        _index = 53,
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
        _index = 54,
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
        _index = 55,
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
        _index = 56,
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
        _index = 57,
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
        _index = 58,
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
        _index = 59,
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
        _index = 60,
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
        _index = 61,
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
        _index = 62,
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
        _index = 63,
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
        _index = 64,
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
        _index = 65,
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
        _index = 66,
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
        _index = 67,
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
        _index = 68,
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
        _index = 69,
    }, {
        PickUp = { 3527 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 3527,
        } },
        AnyOf = { {
            IsQuestCompleted = 3520,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 70,
    }, {
        PickUp = { 4808 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4808,
        } },
        AnyOf = { {
            IsQuestCompleted = 4726,
        } },
        MinLevel = 50,
        Zone = 1428,
        _index = 71,
    }, {
        PickUp = { 5127 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 63.79, 73.76),
        RaidIcon = { {
            npcID = 10918,
            questID = 5127,
        } },
        AnyOf = { {
            IsQuestCompleted = 5126,
        } },
        MinLevel = 55,
        Zone = 1452,
        _index = 72,
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
        _index = 73,
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
        _index = 74,
    }, {
        Qpart = {
            [3527] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 3527,
        _index = 75,
    }, {
        Qpart = {
            [4808] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4808,
        _index = 76,
    }, {
        Qpart = {
            [8922] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8922,
        _index = 77,
    }, {
        Qpart = {
            [8923] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8923,
        _index = 78,
    }, {
        Done = { 3527 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 3527,
        } },
        IsQuestOnQuest = 3527,
        Zone = 1446,
        _index = 79,
    }, {
        Done = { 4808 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 61.63, 38.61),
        RaidIcon = { {
            npcID = 10468,
            questID = 4808,
        } },
        IsQuestOnQuest = 4808,
        Zone = 1452,
        _index = 80,
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
        _index = 81,
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
        _index = 82,
    }, {
        PickUp = { 4787 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 4787,
        } },
        AnyOf = { {
            IsQuestCompleted = 3527,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 83,
    }, {
        PickUp = { 4809 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 61.63, 38.61),
        RaidIcon = { {
            npcID = 10468,
            questID = 4809,
        } },
        AnyOf = { {
            IsQuestCompleted = 4808,
        } },
        MinLevel = 50,
        Zone = 1452,
        _index = 84,
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
        _index = 85,
    }, {
        Qpart = {
            [4787] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4787,
        _index = 86,
    }, {
        Qpart = {
            [4809] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 29.56, 48.5),
        IsQuestOnQuest = 4809,
        Zone = 1452,
        _index = 87,
    }, {
        Qpart = {
            [8921] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8921,
        _index = 88,
    }, {
        Done = { 4787 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 4787,
        } },
        IsQuestOnQuest = 4787,
        Zone = 1446,
        _index = 89,
    }, {
        Done = { 4809 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 61.63, 38.61),
        RaidIcon = { {
            npcID = 10468,
            questID = 4809,
        } },
        IsQuestOnQuest = 4809,
        Zone = 1452,
        _index = 90,
    }, {
        Done = { 8921 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8921,
        } },
        IsQuestOnQuest = 8921,
        Zone = 1446,
        _index = 91,
    }, {
        PickUp = { 3528 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 3528,
        } },
        AnyOf = { {
            IsQuestCompleted = 4787,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 92,
    }, {
        PickUp = { 4810 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 61.63, 38.61),
        RaidIcon = { {
            npcID = 10468,
            questID = 4810,
        } },
        AnyOf = { {
            IsQuestCompleted = 4809,
        } },
        MinLevel = 50,
        Zone = 1452,
        _index = 93,
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
        _index = 94,
    }, {
        Qpart = {
            [3528] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 3528,
        _index = 95,
    }, {
        Qpart = {
            [4810] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4810,
        _index = 96,
    }, {
        Qpart = {
            [8924] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 60.94, 58.39),
        IsQuestOnQuest = 8924,
        Zone = 1451,
        _index = 97,
    }, {
        Done = { 3528 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 3528,
        } },
        IsQuestOnQuest = 3528,
        Zone = 1446,
        _index = 98,
    }, {
        Done = { 4810 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4810,
        } },
        IsQuestOnQuest = 4810,
        Zone = 1428,
        _index = 99,
    }, {
        Done = { 8924 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8924,
        } },
        IsQuestOnQuest = 8924,
        Zone = 1446,
        _index = 100,
    }, {
        PickUp = { 4734 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4734,
        } },
        AnyOf = { {
            IsQuestCompleted = 4810,
        } },
        MinLevel = 57,
        Zone = 1428,
        _index = 101,
    }, {
        PickUp = { 5065 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.89, 24.03),
        RaidIcon = { {
            npcID = 10460,
            questID = 5065,
        } },
        AnyOf = { {
            IsQuestCompleted = 3528,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 102,
    }, {
        PickUp = { 4907 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 61.63, 38.61),
        RaidIcon = { {
            npcID = 10468,
            questID = 4907,
        } },
        AnyOf = { {
            IsQuestCompleted = 4810,
        } },
        MinLevel = 57,
        Zone = 1452,
        _index = 103,
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
        _index = 104,
    }, {
        Qpart = {
            [5065] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5065,
        _index = 105,
    }, {
        Done = { 4907 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4907,
        } },
        IsQuestOnQuest = 4907,
        Zone = 1428,
        _index = 106,
    }, {
        Qpart = {
            [8925] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 35.39, 57.76),
        IsQuestOnQuest = 8925,
        Zone = 1428,
        _index = 107,
    }, {
        Done = { 5065 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.89, 24.03),
        RaidIcon = { {
            npcID = 10460,
            questID = 5065,
        } },
        IsQuestOnQuest = 5065,
        Zone = 1446,
        _index = 108,
    }, {
        Done = { 8925 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8925,
        } },
        IsQuestOnQuest = 8925,
        Zone = 1446,
        _index = 109,
    }, {
        PickUp = { 4788 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.89, 24.03),
        RaidIcon = { {
            npcID = 10460,
            questID = 4788,
        } },
        AnyOf = { {
            IsQuestCompleted = 5065,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 110,
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
        _index = 111,
    }, {
        Qpart = {
            [8928] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8928,
        _index = 112,
    }, {
        Done = { 8928 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8928,
        } },
        IsQuestOnQuest = 8928,
        Zone = 1446,
        _index = 113,
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
        _index = 114,
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
        _index = 115,
    }, {
        Qpart = {
            [8977] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8977,
        _index = 116,
    }, {
        Qpart = {
            [8978] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8978,
        _index = 117,
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
        _index = 118,
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
        _index = 119,
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
        _index = 120,
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
        _index = 121,
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
        _index = 122,
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
        _index = 123,
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
        _index = 124,
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
        _index = 125,
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
        _index = 126,
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
        _index = 127,
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
        _index = 128,
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
        _index = 129,
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
        _index = 130,
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
        _index = 131,
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
        _index = 132,
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
        _index = 133,
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
        _index = 134,
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
        _index = 135,
    }, {
        Qpart = {
            [8926] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8926,
        _index = 136,
    }, {
        Qpart = {
            [8927] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8927,
        _index = 137,
    }, {
        Qpart = {
            [8931] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8931,
        _index = 138,
    }, {
        Qpart = {
            [8932] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8932,
        _index = 139,
    }, {
        Qpart = {
            [8933] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 51.93, 23.82),
        IsQuestOnQuest = 8933,
        Zone = 1422,
        _index = 140,
    }, {
        Qpart = {
            [8934] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8934,
        _index = 141,
    }, {
        Qpart = {
            [8935] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8935,
        _index = 142,
    }, {
        Qpart = {
            [8936] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8936,
        _index = 143,
    }, {
        Qpart = {
            [8937] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8937,
        _index = 144,
    }, {
        Qpart = {
            [8938] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8938,
        _index = 145,
    }, {
        Qpart = {
            [8939] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8939,
        _index = 146,
    }, {
        Qpart = {
            [8940] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8940,
        _index = 147,
    }, {
        Qpart = {
            [8941] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8941,
        _index = 148,
    }, {
        Qpart = {
            [8942] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8942,
        _index = 149,
    }, {
        Qpart = {
            [8943] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8943,
        _index = 150,
    }, {
        Qpart = {
            [8944] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8944,
        _index = 151,
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
        _index = 152,
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
        _index = 153,
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
        _index = 154,
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
        _index = 155,
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
        _index = 156,
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
        _index = 157,
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
        _index = 158,
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
        _index = 159,
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
        _index = 160,
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
        _index = 161,
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
        _index = 162,
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
        _index = 163,
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
        _index = 164,
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
        _index = 165,
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
        _index = 166,
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
        _index = 167,
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
        _index = 168,
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
        _index = 169,
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
        _index = 170,
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
        _index = 171,
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
        _index = 172,
    }, {
        Qpart = {
            [8945] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8945,
        _index = 173,
    }, {
        Done = { 8945 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16031,
            questID = 8945,
        } },
        IsQuestOnQuest = 8945,
        _index = 174,
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
        _index = 175,
    }, {
        Qpart = {
            [8946] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8946,
        _index = 176,
    }, {
        Done = { 8946 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8946,
        } },
        IsQuestOnQuest = 8946,
        Zone = 1423,
        _index = 177,
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
        _index = 178,
    }, {
        Qpart = {
            [8947] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8947,
        _index = 179,
    }, {
        Done = { 8947 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8947,
        } },
        IsQuestOnQuest = 8947,
        Zone = 1423,
        _index = 180,
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
        _index = 181,
    }, {
        Qpart = {
            [8948] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8948,
        _index = 182,
    }, {
        Done = { 8948 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8948,
        } },
        IsQuestOnQuest = 8948,
        _index = 183,
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
        _index = 184,
    }, {
        Qpart = {
            [8949] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.95, 46.58),
        IsQuestOnQuest = 8949,
        Zone = 1444,
        _index = 185,
    }, {
        Done = { 8949 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8949,
        } },
        IsQuestOnQuest = 8949,
        _index = 186,
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
        _index = 187,
    }, {
        Qpart = {
            [8950] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8950,
        _index = 188,
    }, {
        Done = { 8950 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8950,
        } },
        IsQuestOnQuest = 8950,
        _index = 189,
    }, {
        PickUp = { 9015 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 9015,
        } },
        AnyOf = { {
            IsQuestCompleted = 8950,
        } },
        MinLevel = 58,
        _index = 190,
    }, {
        Qpart = {
            [9015] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9015,
        _index = 191,
    }, {
        Done = { 9015 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9015,
        } },
        IsQuestOnQuest = 9015,
        Zone = 1423,
        _index = 192,
    }, {
        PickUp = { 8951 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8951,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 193,
    }, {
        PickUp = { 8952 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8952,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 194,
    }, {
        PickUp = { 8953 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8953,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 195,
    }, {
        PickUp = { 8954 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8954,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 196,
    }, {
        PickUp = { 8955 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8955,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 197,
    }, {
        PickUp = { 8956 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8956,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 198,
    }, {
        PickUp = { 8957 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8957,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 199,
    }, {
        PickUp = { 8958 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8958,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 200,
    }, {
        PickUp = { 8959 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8959,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1423,
        _index = 201,
    }, {
        PickUp = { 9016 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9016,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 202,
    }, {
        PickUp = { 9017 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9017,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 203,
    }, {
        PickUp = { 9018 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9018,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 204,
    }, {
        PickUp = { 9019 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9019,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 205,
    }, {
        PickUp = { 9020 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9020,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 206,
    }, {
        PickUp = { 9021 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9021,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 207,
    }, {
        PickUp = { 9022 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9022,
        } },
        AnyOf = { {
            IsQuestCompleted = 9015,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1423,
        _index = 208,
    }, {
        Qpart = {
            [8951] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8951,
        _index = 209,
    }, {
        Qpart = {
            [8952] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8952,
        _index = 210,
    }, {
        Qpart = {
            [8953] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8953,
        _index = 211,
    }, {
        Qpart = {
            [8954] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8954,
        _index = 212,
    }, {
        Qpart = {
            [8955] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8955,
        _index = 213,
    }, {
        Qpart = {
            [8956] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8956,
        _index = 214,
    }, {
        Qpart = {
            [8957] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8957,
        _index = 215,
    }, {
        Qpart = {
            [8958] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8958,
        _index = 216,
    }, {
        Qpart = {
            [8959] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8959,
        _index = 217,
    }, {
        Qpart = {
            [9016] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9016,
        _index = 218,
    }, {
        Qpart = {
            [9017] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9017,
        _index = 219,
    }, {
        Qpart = {
            [9018] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9018,
        _index = 220,
    }, {
        Qpart = {
            [9019] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9019,
        _index = 221,
    }, {
        Qpart = {
            [9020] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9020,
        _index = 222,
    }, {
        Qpart = {
            [9021] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9021,
        _index = 223,
    }, {
        Qpart = {
            [9022] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9022,
        _index = 224,
    }, {
        Done = { 8951 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8951,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        IsQuestOnQuest = 8951,
        Zone = 1455,
        _index = 225,
    }, {
        Done = { 8952 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8952,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        IsQuestOnQuest = 8952,
        Zone = 1455,
        _index = 226,
    }, {
        Done = { 8953 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8953,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8953,
        Zone = 1455,
        _index = 227,
    }, {
        Done = { 8954 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8954,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        IsQuestOnQuest = 8954,
        Zone = 1455,
        _index = 228,
    }, {
        Done = { 8955 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8955,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        IsQuestOnQuest = 8955,
        Zone = 1455,
        _index = 229,
    }, {
        Done = { 8956 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8956,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8956,
        Zone = 1455,
        _index = 230,
    }, {
        Done = { 8957 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8957,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        IsQuestOnQuest = 8957,
        Zone = 1454,
        _index = 231,
    }, {
        Done = { 8958 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8958,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        IsQuestOnQuest = 8958,
        Zone = 1455,
        _index = 232,
    }, {
        Done = { 8959 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8959,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        IsQuestOnQuest = 8959,
        Zone = 1455,
        _index = 233,
    }, {
        Done = { 9016 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9016,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        IsQuestOnQuest = 9016,
        Zone = 1454,
        _index = 234,
    }, {
        Done = { 9017 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9017,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        IsQuestOnQuest = 9017,
        Zone = 1454,
        _index = 235,
    }, {
        Done = { 9018 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9018,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        IsQuestOnQuest = 9018,
        Zone = 1454,
        _index = 236,
    }, {
        Done = { 9019 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9019,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        IsQuestOnQuest = 9019,
        Zone = 1454,
        _index = 237,
    }, {
        Done = { 9020 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9020,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        IsQuestOnQuest = 9020,
        Zone = 1454,
        _index = 238,
    }, {
        Done = { 9021 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9021,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        IsQuestOnQuest = 9021,
        Zone = 1454,
        _index = 239,
    }, {
        Done = { 9022 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9022,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        IsQuestOnQuest = 9022,
        Zone = 1454,
        _index = 240,
    }, {
        PickUp = { 8960 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8960,
        } },
        AnyOf = { {
            IsQuestCompleted = 8951,
        }, {
            IsQuestCompleted = 8952,
        }, {
            IsQuestCompleted = 8953,
        }, {
            IsQuestCompleted = 8954,
        }, {
            IsQuestCompleted = 8955,
        }, {
            IsQuestCompleted = 8956,
        }, {
            IsQuestCompleted = 8958,
        }, {
            IsQuestCompleted = 8959,
        } },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 241,
    }, {
        PickUp = { 9032 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9032,
        } },
        AnyOf = { {
            IsQuestCompleted = 8957,
        }, {
            IsQuestCompleted = 9016,
        }, {
            IsQuestCompleted = 9017,
        }, {
            IsQuestCompleted = 9018,
        }, {
            IsQuestCompleted = 9019,
        }, {
            IsQuestCompleted = 9020,
        }, {
            IsQuestCompleted = 9021,
        }, {
            IsQuestCompleted = 9022,
        } },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 242,
    }, {
        Done = { 8960 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8960,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8960,
        _index = 243,
    }, {
        Done = { 9032 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 9032,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 9032,
        _index = 244,
    }, {
        PickUp = { 8961 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8961,
        } },
        AnyOf = { {
            IsQuestCompleted = 8960,
        }, {
            IsQuestCompleted = 9032,
        } },
        MinLevel = 58,
        _index = 245,
    }, {
        Qpart = {
            [8961] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 37.63, 44.8),
        IsQuestOnQuest = 8961,
        Zone = 1451,
        _index = 246,
    }, {
        Done = { 8961 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8961,
        } },
        IsQuestOnQuest = 8961,
        _index = 247,
    }, {
        PickUp = { 8962 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8962,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 248,
    }, {
        PickUp = { 8963 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8963,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 249,
    }, {
        PickUp = { 8964 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8964,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 250,
    }, {
        PickUp = { 8965 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8965,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 251,
    }, {
        Qpart = {
            [8962] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 49.31, 80.12),
        IsQuestOnQuest = 8962,
        Zone = 1451,
        _index = 252,
    }, {
        Qpart = {
            [8963] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 65.66, 69.28),
        IsQuestOnQuest = 8963,
        Zone = 1452,
        _index = 253,
    }, {
        Qpart = {
            [8964] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 78.03, 72.34),
        IsQuestOnQuest = 8964,
        Zone = 1423,
        _index = 254,
    }, {
        Qpart = {
            [8965] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 18.33, 77.93),
        IsQuestOnQuest = 8965,
        Zone = 1424,
        _index = 255,
    }, {
        Done = { 8962 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8962,
        } },
        IsQuestOnQuest = 8962,
        _index = 256,
    }, {
        Done = { 8963 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8963,
        } },
        IsQuestOnQuest = 8963,
        _index = 257,
    }, {
        Done = { 8964 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8964,
        } },
        IsQuestOnQuest = 8964,
        _index = 258,
    }, {
        Done = { 8965 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8965,
        } },
        IsQuestOnQuest = 8965,
        _index = 259,
    }, {
        PickUp = { 8967 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8967,
        } },
        AnyOf = { {
            IsQuestCompleted = 8962,
        }, {
            IsQuestCompleted = 8963,
        }, {
            IsQuestCompleted = 8964,
        }, {
            IsQuestCompleted = 8965,
        } },
        MinLevel = 58,
        _index = 260,
    }, {
        PickUp = { 8968 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8968,
        } },
        AnyOf = { {
            IsQuestCompleted = 8962,
        }, {
            IsQuestCompleted = 8963,
        }, {
            IsQuestCompleted = 8964,
        }, {
            IsQuestCompleted = 8965,
        } },
        MinLevel = 58,
        _index = 261,
    }, {
        PickUp = { 8969 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8969,
        } },
        AnyOf = { {
            IsQuestCompleted = 8962,
        }, {
            IsQuestCompleted = 8963,
        }, {
            IsQuestCompleted = 8964,
        }, {
            IsQuestCompleted = 8965,
        } },
        MinLevel = 58,
        _index = 262,
    }, {
        Qpart = {
            [8967] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8967,
        _index = 263,
    }, {
        Qpart = {
            [8968] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8968,
        _index = 264,
    }, {
        Qpart = {
            [8969] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8969,
        _index = 265,
    }, {
        Done = { 8967 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8967,
        } },
        IsQuestOnQuest = 8967,
        _index = 266,
    }, {
        Done = { 8968 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8968,
        } },
        IsQuestOnQuest = 8968,
        _index = 267,
    }, {
        Done = { 8969 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8969,
        } },
        IsQuestOnQuest = 8969,
        _index = 268,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_229",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 33.2, 24.9),
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        Zone = 1428,
        _index = 269,
    }, {
        PickUp = { 4742 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10299,
            questID = 4742,
        } },
        MinLevel = 57,
        _index = 270,
    }, {
        PickUp = { 4867 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10799,
            questID = 4867,
        } },
        MinLevel = 55,
        _index = 271,
    }, {
        PickUp = { 4903 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 9077,
            questID = 4903,
        } },
        Faction = "Horde",
        MinLevel = 55,
        _index = 272,
    }, {
        PickUp = { 5001 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10257,
            questID = 5001,
        } },
        Faction = "Alliance",
        MinLevel = 55,
        _index = 273,
    }, {
        PickUp = { 5047 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10776,
            questID = 5047,
        } },
        MinLevel = 55,
        _index = 274,
    }, {
        PickUp = { 5160 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10740,
            questID = 5160,
        } },
        MinLevel = 57,
        _index = 275,
    }, {
        PickUp = { 8966 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8966,
        } },
        AnyOf = { {
            IsQuestCompleted = 8962,
        }, {
            IsQuestCompleted = 8963,
        }, {
            IsQuestCompleted = 8964,
        }, {
            IsQuestCompleted = 8965,
        } },
        MinLevel = 58,
        _index = 276,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Highlord Omokk",
            npcID = 9196,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 277,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Shadow Hunter Vosh'gajin",
            npcID = 9236,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 278,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "War Master Voone",
            npcID = 9237,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 279,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Mother Smolderweb",
            npcID = 10596,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 280,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Urok Doomhowl",
            npcID = 10584,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 281,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Quartermaster Zigris",
            npcID = 9736,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 282,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Halycon",
            npcID = 10220,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 283,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Gizrul the Slavener",
            npcID = 10268,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 284,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Overlord Wyrmthalak",
            npcID = 9568,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 285,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Pyroguard Emberseer",
            npcID = 9816,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 286,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "Warchief Rend Blackhand",
            npcID = 10429,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 287,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "The Beast",
            npcID = 10430,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 288,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_229",
            name = "General Drakkisath",
            npcID = 10363,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        _index = 289,
    }, {
        Qpart = {
            [4701] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4701,
        _index = 290,
    }, {
        Qpart = {
            [4724] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4724,
        _index = 291,
    }, {
        Qpart = {
            [4729] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4729,
        _index = 292,
    }, {
        Qpart = {
            [4734] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4734,
        _index = 293,
    }, {
        Qpart = {
            [4742] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4742,
        _index = 294,
    }, {
        Qpart = {
            [4764] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4764,
        _index = 295,
    }, {
        Qpart = {
            [4768] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4768,
        _index = 296,
    }, {
        Qpart = {
            [4788] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4788,
        _index = 297,
    }, {
        Qpart = {
            [4862] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4862,
        _index = 298,
    }, {
        Qpart = {
            [4866] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4866,
        _index = 299,
    }, {
        Qpart = {
            [4867] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4867,
        _index = 300,
    }, {
        Qpart = {
            [4903] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4903,
        _index = 301,
    }, {
        Done = { 4981 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10257,
            questID = 4981,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4981,
        _index = 302,
    }, {
        Qpart = {
            [5001] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5001,
        _index = 303,
    }, {
        Qpart = {
            [5047] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5047,
        _index = 304,
    }, {
        PickUp = { 5089 },
        Button = {
            ["5089"] = 12780,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        Faction = "Alliance",
        ItemCount = {
            count = 1,
            itemID = 12780,
        },
        MinLevel = 55,
        _index = 305,
    }, {
        Qpart = {
            [5127] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5127,
        _index = 306,
    }, {
        Qpart = {
            [5160] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5160,
        _index = 307,
    }, {
        PickUp = { 7761 },
        Button = {
            ["7761"] = 18987,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        ItemCount = {
            count = 1,
            itemID = 18987,
        },
        MinLevel = 55,
        _index = 308,
    }, {
        Qpart = {
            [8966] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 8966,
        _index = 309,
    }, {
        Done = { 4742 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10299,
            questID = 4742,
        } },
        IsQuestOnQuest = 4742,
        _index = 310,
    }, {
        Done = { 4867 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10799,
            questID = 4867,
        } },
        IsQuestOnQuest = 4867,
        _index = 311,
    }, {
        PickUp = { 4982 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10257,
            questID = 4982,
        } },
        AnyOf = { {
            IsQuestCompleted = 4981,
        } },
        Faction = "Horde",
        MinLevel = 55,
        _index = 312,
    }, {
        Done = { 5001 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10257,
            questID = 5001,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 5001,
        _index = 313,
    }, {
        Qpart = {
            [5089] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5089,
        _index = 314,
    }, {
        Done = { 7761 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 7761,
        _index = 315,
    }, {
        Done = { 8966 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8966,
        } },
        IsQuestOnQuest = 8966,
        _index = 316,
    }, {
        PickUp = { 4743 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10299,
            questID = 4743,
        } },
        AnyOf = { {
            IsQuestCompleted = 4742,
        } },
        MinLevel = 57,
        _index = 317,
    }, {
        Qpart = {
            [4982] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4982,
        _index = 318,
    }, {
        PickUp = { 5002 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10257,
            questID = 5002,
        } },
        AnyOf = { {
            IsQuestCompleted = 5001,
        } },
        Faction = "Alliance",
        MinLevel = 55,
        _index = 319,
    }, {
        Qpart = {
            [4743] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4743,
        _index = 320,
    }, {
        Done = { 4982 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10257,
            questID = 4982,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4982,
        _index = 321,
    }, {
        Qpart = {
            [5002] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5002,
        _index = 322,
    }, {
        Done = { 4743 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10299,
            questID = 4743,
        } },
        IsQuestOnQuest = 4743,
        _index = 323,
    }, {
        PickUp = { 4983 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 10257,
            questID = 4983,
        } },
        AnyOf = { {
            IsQuestCompleted = 4982,
        } },
        Faction = "Horde",
        MinLevel = 55,
        _index = 324,
    }, {
        Qpart = {
            [4983] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4983,
        _index = 325,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_229",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        _index = 326,
    }, {
        Done = { 4701 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 85.82, 68.95),
        RaidIcon = { {
            npcID = 9562,
            questID = 4701,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4701,
        Zone = 1428,
        _index = 327,
    }, {
        Done = { 4724 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.96, 47.73),
        RaidIcon = { {
            npcID = 9081,
            questID = 4724,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4724,
        Zone = 1418,
        _index = 328,
    }, {
        Done = { 4729 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.89, 21.92),
        RaidIcon = { {
            npcID = 10260,
            questID = 4729,
        } },
        IsQuestOnQuest = 4729,
        Zone = 1428,
        _index = 329,
    }, {
        Done = { 4734 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4734,
        } },
        IsQuestOnQuest = 4734,
        Zone = 1428,
        _index = 330,
    }, {
        Done = { 4764 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.84, 69.12),
        RaidIcon = { {
            npcID = 9565,
            questID = 4764,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4764,
        Zone = 1428,
        _index = 331,
    }, {
        Done = { 4768 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.9, 47.76),
        RaidIcon = { {
            npcID = 9078,
            questID = 4768,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4768,
        Zone = 1418,
        _index = 332,
    }, {
        Done = { 4788 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.89, 24.03),
        RaidIcon = { {
            npcID = 10460,
            questID = 4788,
        } },
        IsQuestOnQuest = 4788,
        Zone = 1446,
        _index = 333,
    }, {
        Done = { 4862 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.89, 21.92),
        RaidIcon = { {
            npcID = 10260,
            questID = 4862,
        } },
        IsQuestOnQuest = 4862,
        Zone = 1428,
        _index = 334,
    }, {
        Done = { 4866 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.01, 23.76),
        RaidIcon = { {
            npcID = 9563,
            questID = 4866,
        } },
        IsQuestOnQuest = 4866,
        Zone = 1428,
        _index = 335,
    }, {
        Done = { 4903 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.81, 47.52),
        RaidIcon = { {
            npcID = 9077,
            questID = 4903,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4903,
        Zone = 1418,
        _index = 336,
    }, {
        Done = { 4983 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.88, 47.63),
        RaidIcon = { {
            npcID = 9080,
            questID = 4983,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4983,
        Zone = 1418,
        _index = 337,
    }, {
        Done = { 5002 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 5002,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 5002,
        Zone = 1428,
        _index = 338,
    }, {
        Done = { 5047 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.99, 38.78),
        RaidIcon = { {
            npcID = 10637,
            questID = 5047,
        } },
        IsQuestOnQuest = 5047,
        Zone = 1452,
        _index = 339,
    }, {
        Done = { 5089 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 5089,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 5089,
        Zone = 1428,
        _index = 340,
    }, {
        Done = { 5127 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 63.79, 73.76),
        RaidIcon = { {
            npcID = 10918,
            questID = 5127,
        } },
        IsQuestOnQuest = 5127,
        Zone = 1452,
        _index = 341,
    }, {
        Done = { 5160 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 54.55, 51.2),
        RaidIcon = { {
            npcID = 10929,
            questID = 5160,
        } },
        IsQuestOnQuest = 5160,
        Zone = 1452,
        _index = 342,
    }, {
        PickUp = { 8970 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8970,
        } },
        AnyOf = { {
            IsQuestCompleted = 8966,
        }, {
            IsQuestCompleted = 8967,
        }, {
            IsQuestCompleted = 8968,
        }, {
            IsQuestCompleted = 8969,
        } },
        MinLevel = 58,
        _index = 343,
    }, {
        PickUp = { 4735 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4735,
        } },
        AnyOf = { {
            IsQuestCompleted = 4734,
        } },
        MinLevel = 57,
        Zone = 1428,
        _index = 344,
    }, {
        PickUp = { 4765 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.84, 69.12),
        RaidIcon = { {
            npcID = 9565,
            questID = 4765,
        } },
        AnyOf = { {
            IsQuestCompleted = 4764,
        } },
        Faction = "Alliance",
        MinLevel = 57,
        Zone = 1428,
        _index = 345,
    }, {
        PickUp = { 4941 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 5.81, 47.52),
        RaidIcon = { {
            npcID = 9077,
            questID = 4941,
        } },
        AnyOf = { {
            IsQuestCompleted = 4903,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1418,
        _index = 346,
    }, {
        PickUp = { 5081 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 5081,
        } },
        AnyOf = { {
            IsQuestCompleted = 5002,
        } },
        Faction = "Alliance",
        MinLevel = 55,
        Zone = 1428,
        _index = 347,
    }, {
        PickUp = { 5102 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 5102,
        } },
        AnyOf = { {
            IsQuestCompleted = 5089,
        } },
        Faction = "Alliance",
        MinLevel = 55,
        Zone = 1428,
        _index = 348,
    }, {
        PickUp = { 5161 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 54.55, 51.2),
        RaidIcon = { {
            npcID = 10929,
            questID = 5161,
        } },
        AnyOf = { {
            IsQuestCompleted = 5160,
        } },
        MinLevel = 57,
        Zone = 1452,
        _index = 349,
    }, {
        PickUp = { 8181 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.89, 24.03),
        RaidIcon = { {
            npcID = 10460,
            questID = 8181,
        } },
        AnyOf = { {
            IsQuestCompleted = 4788,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 350,
    }, {
        Qpart = {
            [8970] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 74.79, 15.12),
        IsQuestOnQuest = 8970,
        Zone = 1445,
        _index = 351,
    }, {
        Qpart = {
            [4941] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4941,
        _index = 352,
    }, {
        Done = { 5161 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 54.55, 51.2),
        RaidIcon = { {
            npcID = 10929,
            questID = 5161,
        } },
        IsQuestOnQuest = 5161,
        Zone = 1452,
        _index = 353,
    }, {
        Done = { 8181 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.99, 22.36),
        RaidIcon = { {
            npcID = 8579,
            questID = 8181,
        } },
        IsQuestOnQuest = 8181,
        Zone = 1446,
        _index = 354,
    }, {
        Done = { 8970 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8970,
        } },
        IsQuestOnQuest = 8970,
        _index = 355,
    }, {
        Done = { 4941 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4941,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4941,
        Zone = 1454,
        _index = 356,
    }, {
        PickUp = { 5162 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 54.55, 51.2),
        RaidIcon = { {
            npcID = 10929,
            questID = 5162,
        } },
        AnyOf = { {
            IsQuestCompleted = 5161,
        } },
        MinLevel = 57,
        Zone = 1452,
        _index = 357,
    }, {
        PickUp = { 8182 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 66.89, 24.03),
        RaidIcon = { {
            npcID = 10460,
            questID = 8182,
        } },
        AnyOf = { {
            IsQuestCompleted = 8181,
        } },
        MinLevel = 40,
        Zone = 1446,
        _index = 358,
    }, {
        PickUp = { 8985 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8985,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 359,
    }, {
        PickUp = { 8986 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8986,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 360,
    }, {
        PickUp = { 8987 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8987,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 361,
    }, {
        PickUp = { 8988 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8988,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 362,
    }, {
        PickUp = { 4974 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4974,
        } },
        AnyOf = { {
            IsQuestCompleted = 4941,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1454,
        _index = 363,
    }, {
        Done = { 5162 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 39.37, 66.78),
        RaidIcon = { {
            npcID = 10976,
            questID = 5162,
        } },
        IsQuestOnQuest = 5162,
        Zone = 1422,
        _index = 364,
    }, {
        Done = { 8182 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1434, 15.04, 15.13),
        RaidIcon = { {
            npcID = 14875,
            questID = 8182,
        } },
        IsQuestOnQuest = 8182,
        Zone = 1434,
        _index = 365,
    }, {
        Qpart = {
            [8985] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 65.66, 69.28),
        IsQuestOnQuest = 8985,
        Zone = 1452,
        _index = 366,
    }, {
        Qpart = {
            [8986] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 49.31, 80.12),
        IsQuestOnQuest = 8986,
        Zone = 1451,
        _index = 367,
    }, {
        Qpart = {
            [8987] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 78.03, 72.34),
        IsQuestOnQuest = 8987,
        Zone = 1423,
        _index = 368,
    }, {
        Qpart = {
            [8988] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 18.33, 77.93),
        IsQuestOnQuest = 8988,
        Zone = 1424,
        _index = 369,
    }, {
        PickUp = { 5164 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 39.37, 66.78),
        RaidIcon = { {
            npcID = 10976,
            questID = 5164,
        } },
        AnyOf = { {
            IsQuestCompleted = 5162,
        } },
        MinLevel = 57,
        Zone = 1422,
        _index = 370,
    }, {
        Done = { 8985 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8985,
        } },
        IsQuestOnQuest = 8985,
        _index = 371,
    }, {
        Done = { 8986 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8986,
        } },
        IsQuestOnQuest = 8986,
        _index = 372,
    }, {
        Done = { 8987 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8987,
        } },
        IsQuestOnQuest = 8987,
        _index = 373,
    }, {
        Done = { 8988 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8988,
        } },
        IsQuestOnQuest = 8988,
        _index = 374,
    }, {
        Done = { 5164 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 39.35, 66.6),
        IsQuestOnQuest = 5164,
        Zone = 1422,
        _index = 375,
    }, {
        PickUp = { 8990 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8990,
        } },
        AnyOf = { {
            IsQuestCompleted = 8985,
        }, {
            IsQuestCompleted = 8986,
        }, {
            IsQuestCompleted = 8987,
        }, {
            IsQuestCompleted = 8988,
        } },
        MinLevel = 58,
        _index = 376,
    }, {
        PickUp = { 8991 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8991,
        } },
        AnyOf = { {
            IsQuestCompleted = 8985,
        }, {
            IsQuestCompleted = 8986,
        }, {
            IsQuestCompleted = 8987,
        }, {
            IsQuestCompleted = 8988,
        } },
        MinLevel = 58,
        _index = 377,
    }, {
        PickUp = { 8992 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8992,
        } },
        AnyOf = { {
            IsQuestCompleted = 8985,
        }, {
            IsQuestCompleted = 8986,
        }, {
            IsQuestCompleted = 8987,
        }, {
            IsQuestCompleted = 8988,
        } },
        MinLevel = 58,
        _index = 378,
    }, {
        Qpart = {
            [8990] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8990,
        _index = 379,
    }, {
        Qpart = {
            [8991] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8991,
        _index = 380,
    }, {
        Qpart = {
            [8992] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8992,
        _index = 381,
    }, {
        Done = { 8990 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8990,
        } },
        IsQuestOnQuest = 8990,
        _index = 382,
    }, {
        Done = { 8991 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8991,
        } },
        IsQuestOnQuest = 8991,
        _index = 383,
    }, {
        Done = { 8992 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8992,
        } },
        IsQuestOnQuest = 8992,
        _index = 384,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_229",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 33.2, 24.9),
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        Zone = 1428,
        _index = 385,
    }, {
        Qpart = {
            [4735] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4735,
        _index = 386,
    }, {
        Qpart = {
            [4765] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4765,
        _index = 387,
    }, {
        Qpart = {
            [4974] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 4974,
        _index = 388,
    }, {
        Qpart = {
            [5081] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5081,
        _index = 389,
    }, {
        Qpart = {
            [5102] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 5102,
        _index = 390,
    }, {
        PickUp = { 8989 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8989,
        } },
        AnyOf = { {
            IsQuestCompleted = 8985,
        }, {
            IsQuestCompleted = 8986,
        }, {
            IsQuestCompleted = 8987,
        }, {
            IsQuestCompleted = 8988,
        } },
        MinLevel = 58,
        _index = 391,
    }, {
        Qpart = {
            [8989] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 8989,
        _index = 392,
    }, {
        Done = { 8989 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8989,
        } },
        IsQuestOnQuest = 8989,
        _index = 393,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_229",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        _index = 394,
    }, {
        Done = { 4735 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4735,
        } },
        IsQuestOnQuest = 4735,
        Zone = 1428,
        _index = 395,
    }, {
        Done = { 4765 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 76.94, 47.83),
        RaidIcon = { {
            npcID = 2285,
            questID = 4765,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 4765,
        Zone = 1453,
        _index = 396,
    }, {
        Done = { 4974 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 4974,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 4974,
        Zone = 1454,
        _index = 397,
    }, {
        Done = { 5081 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 5081,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 5081,
        Zone = 1428,
        _index = 398,
    }, {
        Done = { 5102 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 84.74, 69.02),
        RaidIcon = { {
            npcID = 9560,
            questID = 5102,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 5102,
        Zone = 1428,
        _index = 399,
    }, {
        PickUp = { 8994 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8994,
        } },
        AnyOf = { {
            IsQuestCompleted = 8989,
        }, {
            IsQuestCompleted = 8990,
        }, {
            IsQuestCompleted = 8991,
        }, {
            IsQuestCompleted = 8992,
        } },
        MinLevel = 58,
        _index = 400,
    }, {
        PickUp = { 5522 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 5522,
        } },
        AnyOf = { {
            IsQuestCompleted = 4735,
        } },
        MinLevel = 57,
        Zone = 1428,
        _index = 401,
    }, {
        PickUp = { 6566 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 6566,
        } },
        AnyOf = { {
            IsQuestCompleted = 4974,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1454,
        _index = 402,
    }, {
        Qpart = {
            [8994] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8994,
        _index = 403,
    }, {
        Qpart = {
            [5522] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5522,
        _index = 404,
    }, {
        Qpart = {
            [6566] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 6566,
        _index = 405,
    }, {
        Done = { 8994 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8994,
        } },
        IsQuestOnQuest = 8994,
        _index = 406,
    }, {
        Done = { 5522 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.89, 48.29),
        RaidIcon = { {
            npcID = 11036,
            questID = 5522,
        } },
        IsQuestOnQuest = 5522,
        Zone = 1423,
        _index = 407,
    }, {
        Done = { 6566 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 6566,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 6566,
        Zone = 1454,
        _index = 408,
    }, {
        PickUp = { 6567 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 31.73, 37.82),
        RaidIcon = { {
            npcID = 4949,
            questID = 6567,
        } },
        AnyOf = { {
            IsQuestCompleted = 6566,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1454,
        _index = 409,
    }, {
        Done = { 6567 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1443, 54, 2),
        RaidIcon = { {
            npcID = 10182,
            questID = 6567,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 6567,
        Zone = 1443,
        _index = 410,
    }, {
        PickUp = { 6568 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1443, 54, 2),
        RaidIcon = { {
            npcID = 10182,
            questID = 6568,
        } },
        AnyOf = { {
            IsQuestCompleted = 6567,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1443,
        _index = 411,
    }, {
        Qpart = {
            [6568] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 6568,
        _index = 412,
    }, {
        Done = { 6568 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 50.79, 77.85),
        RaidIcon = { {
            npcID = 11872,
            questID = 6568,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 6568,
        Zone = 1422,
        _index = 413,
    }, {
        PickUp = { 6569 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 50.79, 77.85),
        RaidIcon = { {
            npcID = 11872,
            questID = 6569,
        } },
        AnyOf = { {
            IsQuestCompleted = 6568,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1422,
        _index = 414,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_229",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 33.2, 24.9),
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        Zone = 1428,
        _index = 415,
    }, {
        Qpart = {
            [6569] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 6569,
        _index = 416,
    }, {
        PickUp = { 8995 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8995,
        } },
        AnyOf = { {
            IsQuestCompleted = 8994,
        } },
        MinLevel = 58,
        _index = 417,
    }, {
        Qpart = {
            [8995] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        IsQuestOnQuest = 8995,
        _index = 418,
    }, {
        Done = { 8995 },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16073,
            questID = 8995,
        } },
        IsQuestOnQuest = 8995,
        _index = 419,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_229",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_229",
        _index = 420,
    }, {
        Done = { 6569 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 50.79, 77.85),
        RaidIcon = { {
            npcID = 11872,
            questID = 6569,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 6569,
        Zone = 1422,
        _index = 421,
    }, {
        PickUp = { 8996 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16073,
            questID = 8996,
        } },
        AnyOf = { {
            IsQuestCompleted = 8995,
        } },
        MinLevel = 58,
        _index = 422,
    }, {
        PickUp = { 6570 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 50.79, 77.85),
        RaidIcon = { {
            npcID = 11872,
            questID = 6570,
        } },
        AnyOf = { {
            IsQuestCompleted = 6569,
        } },
        Faction = "Horde",
        MinLevel = 55,
        Zone = 1422,
        _index = 423,
    }, {
        Qpart = {
            [8996] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8996,
        _index = 424,
    }, {
        Done = { 6570 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 56.66, 87.72),
        RaidIcon = { {
            npcID = 10321,
            questID = 6570,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 6570,
        Zone = 1445,
        _index = 425,
    }, {
        Done = { 8996 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8996,
        } },
        IsQuestOnQuest = 8996,
        _index = 426,
    }, {
        RouteCompleted = true,
        _index = 427,
    } },
}
