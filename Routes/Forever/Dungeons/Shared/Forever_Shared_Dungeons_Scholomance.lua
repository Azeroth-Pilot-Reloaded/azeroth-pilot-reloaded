local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Scholomance"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 58,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Scholomance"],
    levelRange = {
        max = 60,
        min = 58,
    },
    mapID = 1422,
    steps = { {
        PickUp = { 4726 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4726,
        } },
        MinLevel = 50,
        Zone = 1428,
        _index = 1,
    }, {
        PickUp = { 5341 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1420, 83.06, 71.6),
        RaidIcon = { {
            npcID = 11022,
            questID = 5341,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1420,
        _index = 2,
    }, {
        PickUp = { 5343 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 43.45, 83.73),
        RaidIcon = { {
            npcID = 11023,
            questID = 5343,
        } },
        Faction = "Alliance",
        MinLevel = 52,
        Zone = 1422,
        _index = 3,
    }, {
        PickUp = { 5382 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.22, 73.71),
        RaidIcon = { {
            npcID = 11216,
            questID = 5382,
        } },
        MinLevel = 55,
        Zone = 1422,
        _index = 4,
    }, {
        PickUp = { 5529 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.66, 49.94),
        RaidIcon = { {
            npcID = 11035,
            questID = 5529,
        } },
        MinLevel = 55,
        Zone = 1423,
        _index = 5,
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
        _index = 6,
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
        _index = 7,
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
        _index = 8,
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
        _index = 9,
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
        _index = 10,
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
        _index = 11,
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
        _index = 12,
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
        _index = 13,
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
        _index = 14,
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
        _index = 15,
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
        _index = 16,
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
        _index = 17,
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
        _index = 18,
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
        _index = 19,
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
        _index = 20,
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
        _index = 21,
    }, {
        Qpart = {
            [4726] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4726,
        _index = 22,
    }, {
        Qpart = {
            [8905] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8905,
        Zone = 1452,
        _index = 23,
    }, {
        Qpart = {
            [8906] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8906,
        Zone = 1452,
        _index = 24,
    }, {
        Qpart = {
            [8907] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8907,
        Zone = 1452,
        _index = 25,
    }, {
        Qpart = {
            [8908] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8908,
        Zone = 1452,
        _index = 26,
    }, {
        Qpart = {
            [8909] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8909,
        Zone = 1452,
        _index = 27,
    }, {
        Qpart = {
            [8910] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8910,
        Zone = 1452,
        _index = 28,
    }, {
        Qpart = {
            [8911] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8911,
        Zone = 1452,
        _index = 29,
    }, {
        Qpart = {
            [8912] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8912,
        Zone = 1452,
        _index = 30,
    }, {
        Qpart = {
            [8913] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8913,
        Zone = 1451,
        _index = 31,
    }, {
        Qpart = {
            [8914] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8914,
        Zone = 1451,
        _index = 32,
    }, {
        Qpart = {
            [8915] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8915,
        Zone = 1451,
        _index = 33,
    }, {
        Qpart = {
            [8916] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8916,
        Zone = 1451,
        _index = 34,
    }, {
        Qpart = {
            [8917] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8917,
        Zone = 1451,
        _index = 35,
    }, {
        Qpart = {
            [8918] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8918,
        Zone = 1451,
        _index = 36,
    }, {
        Qpart = {
            [8919] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8919,
        Zone = 1451,
        _index = 37,
    }, {
        Qpart = {
            [8920] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8920,
        Zone = 1451,
        _index = 38,
    }, {
        Done = { 4726 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4726,
        } },
        IsQuestOnQuest = 4726,
        Zone = 1428,
        _index = 39,
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
        _index = 40,
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
        _index = 41,
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
        _index = 42,
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
        _index = 43,
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
        _index = 44,
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
        _index = 45,
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
        _index = 46,
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
        _index = 47,
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
        _index = 48,
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
        _index = 49,
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
        _index = 50,
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
        _index = 51,
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
        _index = 52,
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
        _index = 53,
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
        _index = 54,
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
        _index = 55,
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
        _index = 56,
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
        _index = 57,
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
        _index = 58,
    }, {
        Qpart = {
            [4808] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4808,
        _index = 59,
    }, {
        Qpart = {
            [8922] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8922,
        _index = 60,
    }, {
        Qpart = {
            [8923] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8923,
        _index = 61,
    }, {
        Done = { 4808 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 61.63, 38.61),
        RaidIcon = { {
            npcID = 10468,
            questID = 4808,
        } },
        IsQuestOnQuest = 4808,
        Zone = 1452,
        _index = 62,
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
        _index = 63,
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
        _index = 64,
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
        _index = 65,
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
        _index = 66,
    }, {
        Qpart = {
            [4809] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 29.56, 48.5),
        IsQuestOnQuest = 4809,
        Zone = 1452,
        _index = 67,
    }, {
        Qpart = {
            [8921] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8921,
        _index = 68,
    }, {
        Done = { 4809 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 61.63, 38.61),
        RaidIcon = { {
            npcID = 10468,
            questID = 4809,
        } },
        IsQuestOnQuest = 4809,
        Zone = 1452,
        _index = 69,
    }, {
        Done = { 8921 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8921,
        } },
        IsQuestOnQuest = 8921,
        Zone = 1446,
        _index = 70,
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
        _index = 71,
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
        _index = 72,
    }, {
        Qpart = {
            [4810] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4810,
        _index = 73,
    }, {
        Qpart = {
            [8924] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 60.94, 58.39),
        IsQuestOnQuest = 8924,
        Zone = 1451,
        _index = 74,
    }, {
        Done = { 4810 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4810,
        } },
        IsQuestOnQuest = 4810,
        Zone = 1428,
        _index = 75,
    }, {
        Done = { 8924 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8924,
        } },
        IsQuestOnQuest = 8924,
        Zone = 1446,
        _index = 76,
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
        _index = 77,
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
        _index = 78,
    }, {
        Qpart = {
            [4734] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4734,
        _index = 79,
    }, {
        Qpart = {
            [8925] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 35.39, 57.76),
        IsQuestOnQuest = 8925,
        Zone = 1428,
        _index = 80,
    }, {
        Done = { 4734 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4734,
        } },
        IsQuestOnQuest = 4734,
        Zone = 1428,
        _index = 81,
    }, {
        Done = { 8925 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8925,
        } },
        IsQuestOnQuest = 8925,
        Zone = 1446,
        _index = 82,
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
        _index = 83,
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
        _index = 84,
    }, {
        Qpart = {
            [4735] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 4735,
        _index = 85,
    }, {
        Qpart = {
            [8928] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8928,
        _index = 86,
    }, {
        Done = { 4735 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 65.24, 24),
        RaidIcon = { {
            npcID = 10267,
            questID = 4735,
        } },
        IsQuestOnQuest = 4735,
        Zone = 1428,
        _index = 87,
    }, {
        Done = { 8928 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8928,
        } },
        IsQuestOnQuest = 8928,
        Zone = 1446,
        _index = 88,
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
        _index = 89,
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
        _index = 90,
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
        _index = 91,
    }, {
        Qpart = {
            [5522] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5522,
        _index = 92,
    }, {
        Qpart = {
            [8977] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8977,
        _index = 93,
    }, {
        Qpart = {
            [8978] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8978,
        _index = 94,
    }, {
        Done = { 5522 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.89, 48.29),
        RaidIcon = { {
            npcID = 11036,
            questID = 5522,
        } },
        IsQuestOnQuest = 5522,
        Zone = 1423,
        _index = 95,
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
        _index = 96,
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
        _index = 97,
    }, {
        PickUp = { 5531 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.89, 48.29),
        RaidIcon = { {
            npcID = 11036,
            questID = 5531,
        } },
        AnyOf = { {
            IsQuestCompleted = 5522,
        } },
        MinLevel = 57,
        Zone = 1423,
        _index = 98,
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
        _index = 99,
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
        _index = 100,
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
        _index = 101,
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
        _index = 102,
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
        _index = 103,
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
        _index = 104,
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
        _index = 105,
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
        _index = 106,
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
        _index = 107,
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
        _index = 108,
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
        _index = 109,
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
        _index = 110,
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
        _index = 111,
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
        _index = 112,
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
        _index = 113,
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
        _index = 114,
    }, {
        Qpart = {
            [8926] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8926,
        _index = 115,
    }, {
        Qpart = {
            [8927] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8927,
        _index = 116,
    }, {
        Qpart = {
            [8931] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8931,
        _index = 117,
    }, {
        Qpart = {
            [8932] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8932,
        _index = 118,
    }, {
        Qpart = {
            [8933] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 51.93, 23.82),
        IsQuestOnQuest = 8933,
        Zone = 1422,
        _index = 119,
    }, {
        Qpart = {
            [8934] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8934,
        _index = 120,
    }, {
        Qpart = {
            [8935] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8935,
        _index = 121,
    }, {
        Qpart = {
            [8936] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8936,
        _index = 122,
    }, {
        Qpart = {
            [8937] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8937,
        _index = 123,
    }, {
        Qpart = {
            [8938] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8938,
        _index = 124,
    }, {
        Qpart = {
            [8939] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8939,
        _index = 125,
    }, {
        Qpart = {
            [8940] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8940,
        _index = 126,
    }, {
        Qpart = {
            [8941] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8941,
        _index = 127,
    }, {
        Qpart = {
            [8942] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8942,
        _index = 128,
    }, {
        Qpart = {
            [8943] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8943,
        _index = 129,
    }, {
        Qpart = {
            [8944] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8944,
        _index = 130,
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
        _index = 131,
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
        _index = 132,
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
        _index = 133,
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
        _index = 134,
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
        _index = 135,
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
        _index = 136,
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
        _index = 137,
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
        _index = 138,
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
        _index = 139,
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
        _index = 140,
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
        _index = 141,
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
        _index = 142,
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
        _index = 143,
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
        _index = 144,
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
        _index = 145,
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
        _index = 146,
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
        _index = 147,
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
        _index = 148,
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
        _index = 149,
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
        _index = 150,
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
        _index = 151,
    }, {
        Qpart = {
            [8945] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8945,
        _index = 152,
    }, {
        Done = { 8945 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16031,
            questID = 8945,
        } },
        IsQuestOnQuest = 8945,
        _index = 153,
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
        _index = 154,
    }, {
        Qpart = {
            [8946] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8946,
        _index = 155,
    }, {
        Done = { 8946 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8946,
        } },
        IsQuestOnQuest = 8946,
        Zone = 1423,
        _index = 156,
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
        _index = 157,
    }, {
        Qpart = {
            [8947] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8947,
        _index = 158,
    }, {
        Done = { 8947 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8947,
        } },
        IsQuestOnQuest = 8947,
        Zone = 1423,
        _index = 159,
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
        _index = 160,
    }, {
        Qpart = {
            [8948] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8948,
        _index = 161,
    }, {
        Done = { 8948 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8948,
        } },
        IsQuestOnQuest = 8948,
        _index = 162,
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
        _index = 163,
    }, {
        Qpart = {
            [8949] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.95, 46.58),
        IsQuestOnQuest = 8949,
        Zone = 1444,
        _index = 164,
    }, {
        Done = { 8949 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8949,
        } },
        IsQuestOnQuest = 8949,
        _index = 165,
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
        _index = 166,
    }, {
        Qpart = {
            [8950] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8950,
        _index = 167,
    }, {
        Done = { 8950 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8950,
        } },
        IsQuestOnQuest = 8950,
        _index = 168,
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
        _index = 169,
    }, {
        Qpart = {
            [9015] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9015,
        _index = 170,
    }, {
        Done = { 9015 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9015,
        } },
        IsQuestOnQuest = 9015,
        Zone = 1423,
        _index = 171,
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
        _index = 172,
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
        _index = 173,
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
        _index = 174,
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
        _index = 175,
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
        _index = 176,
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
        _index = 177,
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
        _index = 178,
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
        _index = 179,
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
        _index = 180,
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
        _index = 181,
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
        _index = 182,
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
        _index = 183,
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
        _index = 184,
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
        _index = 185,
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
        _index = 186,
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
        _index = 187,
    }, {
        Qpart = {
            [8951] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8951,
        _index = 188,
    }, {
        Qpart = {
            [8952] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8952,
        _index = 189,
    }, {
        Qpart = {
            [8953] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8953,
        _index = 190,
    }, {
        Qpart = {
            [8954] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8954,
        _index = 191,
    }, {
        Qpart = {
            [8955] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8955,
        _index = 192,
    }, {
        Qpart = {
            [8956] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8956,
        _index = 193,
    }, {
        Qpart = {
            [8957] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8957,
        _index = 194,
    }, {
        Qpart = {
            [8958] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8958,
        _index = 195,
    }, {
        Qpart = {
            [8959] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8959,
        _index = 196,
    }, {
        Qpart = {
            [9016] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9016,
        _index = 197,
    }, {
        Qpart = {
            [9017] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9017,
        _index = 198,
    }, {
        Qpart = {
            [9018] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9018,
        _index = 199,
    }, {
        Qpart = {
            [9019] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9019,
        _index = 200,
    }, {
        Qpart = {
            [9020] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9020,
        _index = 201,
    }, {
        Qpart = {
            [9021] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9021,
        _index = 202,
    }, {
        Qpart = {
            [9022] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 9022,
        _index = 203,
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
        _index = 204,
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
        _index = 205,
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
        _index = 206,
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
        _index = 207,
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
        _index = 208,
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
        _index = 209,
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
        _index = 210,
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
        _index = 211,
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
        _index = 212,
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
        _index = 213,
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
        _index = 214,
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
        _index = 215,
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
        _index = 216,
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
        _index = 217,
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
        _index = 218,
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
        _index = 219,
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
        _index = 220,
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
        _index = 221,
    }, {
        Done = { 8960 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8960,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8960,
        _index = 222,
    }, {
        Done = { 9032 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 9032,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 9032,
        _index = 223,
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
        _index = 224,
    }, {
        Qpart = {
            [8961] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 37.63, 44.8),
        IsQuestOnQuest = 8961,
        Zone = 1451,
        _index = 225,
    }, {
        Done = { 8961 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8961,
        } },
        IsQuestOnQuest = 8961,
        _index = 226,
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
        _index = 227,
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
        _index = 228,
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
        _index = 229,
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
        _index = 230,
    }, {
        Qpart = {
            [8962] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 49.31, 80.12),
        IsQuestOnQuest = 8962,
        Zone = 1451,
        _index = 231,
    }, {
        Qpart = {
            [8963] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 65.66, 69.28),
        IsQuestOnQuest = 8963,
        Zone = 1452,
        _index = 232,
    }, {
        Qpart = {
            [8964] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 78.03, 72.34),
        IsQuestOnQuest = 8964,
        Zone = 1423,
        _index = 233,
    }, {
        Qpart = {
            [8965] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 18.33, 77.93),
        IsQuestOnQuest = 8965,
        Zone = 1424,
        _index = 234,
    }, {
        Done = { 8962 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8962,
        } },
        IsQuestOnQuest = 8962,
        _index = 235,
    }, {
        Done = { 8963 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8963,
        } },
        IsQuestOnQuest = 8963,
        _index = 236,
    }, {
        Done = { 8964 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8964,
        } },
        IsQuestOnQuest = 8964,
        _index = 237,
    }, {
        Done = { 8965 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8965,
        } },
        IsQuestOnQuest = 8965,
        _index = 238,
    }, {
        PickUp = { 8966 },
        NoArrow = true,
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
        _index = 239,
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
        _index = 240,
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
        _index = 241,
    }, {
        Qpart = {
            [8966] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8966,
        _index = 242,
    }, {
        Qpart = {
            [8967] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8967,
        _index = 243,
    }, {
        Qpart = {
            [8968] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8968,
        _index = 244,
    }, {
        Done = { 8966 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8966,
        } },
        IsQuestOnQuest = 8966,
        _index = 245,
    }, {
        Done = { 8967 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8967,
        } },
        IsQuestOnQuest = 8967,
        _index = 246,
    }, {
        Done = { 8968 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8968,
        } },
        IsQuestOnQuest = 8968,
        _index = 247,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_289",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 69, 72.7),
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        Zone = 1422,
        _index = 248,
    }, {
        PickUp = { 8969 },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
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
        _index = 249,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Kirtonos the Herald",
            npcID = 10506,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 250,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Jandice Barov",
            npcID = 10503,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 251,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Rattlegore",
            npcID = 11622,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 252,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Marduk Blackpool",
            npcID = 10433,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 253,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Vectus",
            npcID = 10432,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 254,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Ras Frostwhisper",
            npcID = 10508,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 255,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Instructor Malicia",
            npcID = 10505,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 256,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Doctor Theolen Krastinov",
            npcID = 11261,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 257,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Lorekeeper Polkelt",
            npcID = 10901,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 258,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "The Ravenian",
            npcID = 10507,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 259,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Lord Alexei Barov",
            npcID = 10504,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 260,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Lady Illucia Barov",
            npcID = 10502,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 261,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_289",
            name = "Darkmaster Gandling",
            npcID = 1853,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        _index = 262,
    }, {
        Qpart = {
            [5531] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5531,
        _index = 263,
    }, {
        Qpart = {
            [5341] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5341,
        _index = 264,
    }, {
        Qpart = {
            [5343] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5343,
        _index = 265,
    }, {
        Qpart = {
            [5382] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5382,
        _index = 266,
    }, {
        Qpart = {
            [5529] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5529,
        _index = 267,
    }, {
        Qpart = {
            [8969] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 8969,
        _index = 268,
    }, {
        Done = { 8969 },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8969,
        } },
        IsQuestOnQuest = 8969,
        _index = 269,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_289",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        _index = 270,
    }, {
        Done = { 5531 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.66, 49.94),
        RaidIcon = { {
            npcID = 11035,
            questID = 5531,
        } },
        IsQuestOnQuest = 5531,
        Zone = 1423,
        _index = 271,
    }, {
        Done = { 5341 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1420, 83.06, 71.6),
        RaidIcon = { {
            npcID = 11022,
            questID = 5341,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 5341,
        Zone = 1420,
        _index = 272,
    }, {
        Done = { 5343 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 43.45, 83.73),
        RaidIcon = { {
            npcID = 11023,
            questID = 5343,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 5343,
        Zone = 1422,
        _index = 273,
    }, {
        Done = { 5382 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.22, 73.71),
        RaidIcon = { {
            npcID = 11216,
            questID = 5382,
        } },
        IsQuestOnQuest = 5382,
        Zone = 1422,
        _index = 274,
    }, {
        Done = { 5529 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.66, 49.94),
        RaidIcon = { {
            npcID = 11035,
            questID = 5529,
        } },
        IsQuestOnQuest = 5529,
        Zone = 1423,
        _index = 275,
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
        _index = 276,
    }, {
        PickUp = { 4771 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.66, 49.94),
        RaidIcon = { {
            npcID = 11035,
            questID = 4771,
        } },
        AnyOf = { {
            IsQuestCompleted = 5531,
        } },
        MinLevel = 57,
        Zone = 1423,
        _index = 277,
    }, {
        PickUp = { 5342 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1420, 83.06, 71.6),
        RaidIcon = { {
            npcID = 11022,
            questID = 5342,
        } },
        AnyOf = { {
            IsQuestCompleted = 5341,
        } },
        Faction = "Horde",
        MinLevel = 52,
        Zone = 1420,
        _index = 278,
    }, {
        PickUp = { 5344 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 43.45, 83.73),
        RaidIcon = { {
            npcID = 11023,
            questID = 5344,
        } },
        AnyOf = { {
            IsQuestCompleted = 5343,
        } },
        Faction = "Alliance",
        MinLevel = 52,
        Zone = 1422,
        _index = 279,
    }, {
        PickUp = { 5515 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.22, 73.71),
        RaidIcon = { {
            npcID = 11216,
            questID = 5515,
        } },
        AnyOf = { {
            IsQuestCompleted = 5382,
        } },
        MinLevel = 55,
        Zone = 1422,
        _index = 280,
    }, {
        Qpart = {
            [8970] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 74.79, 15.12),
        IsQuestOnQuest = 8970,
        Zone = 1445,
        _index = 281,
    }, {
        Qpart = {
            [5342] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 43.45, 83.73),
        IsQuestOnQuest = 5342,
        Zone = 1422,
        _index = 282,
    }, {
        Qpart = {
            [5344] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1420, 83.06, 71.6),
        IsQuestOnQuest = 5344,
        Zone = 1420,
        _index = 283,
    }, {
        Done = { 8970 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8970,
        } },
        IsQuestOnQuest = 8970,
        _index = 284,
    }, {
        Done = { 5342 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1420, 83.06, 71.6),
        RaidIcon = { {
            npcID = 11022,
            questID = 5342,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 5342,
        Zone = 1420,
        _index = 285,
    }, {
        Done = { 5344 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 43.45, 83.73),
        RaidIcon = { {
            npcID = 11023,
            questID = 5344,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 5344,
        Zone = 1422,
        _index = 286,
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
        _index = 287,
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
        _index = 288,
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
        _index = 289,
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
        _index = 290,
    }, {
        Qpart = {
            [8985] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 65.66, 69.28),
        IsQuestOnQuest = 8985,
        Zone = 1452,
        _index = 291,
    }, {
        Qpart = {
            [8986] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 49.31, 80.12),
        IsQuestOnQuest = 8986,
        Zone = 1451,
        _index = 292,
    }, {
        Qpart = {
            [8987] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 78.03, 72.34),
        IsQuestOnQuest = 8987,
        Zone = 1423,
        _index = 293,
    }, {
        Qpart = {
            [8988] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 18.33, 77.93),
        IsQuestOnQuest = 8988,
        Zone = 1424,
        _index = 294,
    }, {
        Done = { 8985 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8985,
        } },
        IsQuestOnQuest = 8985,
        _index = 295,
    }, {
        Done = { 8986 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8986,
        } },
        IsQuestOnQuest = 8986,
        _index = 296,
    }, {
        Done = { 8987 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8987,
        } },
        IsQuestOnQuest = 8987,
        _index = 297,
    }, {
        Done = { 8988 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8988,
        } },
        IsQuestOnQuest = 8988,
        _index = 298,
    }, {
        PickUp = { 8989 },
        NoArrow = true,
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
        _index = 299,
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
        _index = 300,
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
        _index = 301,
    }, {
        Qpart = {
            [8989] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8989,
        _index = 302,
    }, {
        Qpart = {
            [8990] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8990,
        _index = 303,
    }, {
        Qpart = {
            [8991] = { 1, 2, 3 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8991,
        _index = 304,
    }, {
        Done = { 8989 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8989,
        } },
        IsQuestOnQuest = 8989,
        _index = 305,
    }, {
        Done = { 8990 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8990,
        } },
        IsQuestOnQuest = 8990,
        _index = 306,
    }, {
        Done = { 8991 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8991,
        } },
        IsQuestOnQuest = 8991,
        _index = 307,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_289",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 69, 72.7),
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        Zone = 1422,
        _index = 308,
    }, {
        Qpart = {
            [4771] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 4771,
        _index = 309,
    }, {
        Qpart = {
            [5515] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5515,
        _index = 310,
    }, {
        PickUp = { 5582 },
        Button = {
            ["5582"] = 13920,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 5529,
        } },
        ItemCount = {
            count = 1,
            itemID = 13920,
        },
        MinLevel = 55,
        _index = 311,
    }, {
        PickUp = { 8992 },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
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
        _index = 312,
    }, {
        Qpart = {
            [5582] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5582,
        _index = 313,
    }, {
        Qpart = {
            [8992] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 8992,
        _index = 314,
    }, {
        Done = { 8992 },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8992,
        } },
        IsQuestOnQuest = 8992,
        _index = 315,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_289",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        _index = 316,
    }, {
        Done = { 4771 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.66, 49.94),
        RaidIcon = { {
            npcID = 11035,
            questID = 4771,
        } },
        IsQuestOnQuest = 4771,
        Zone = 1423,
        _index = 317,
    }, {
        Done = { 5515 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.22, 73.71),
        RaidIcon = { {
            npcID = 11216,
            questID = 5515,
        } },
        IsQuestOnQuest = 5515,
        Zone = 1422,
        _index = 318,
    }, {
        Done = { 5582 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.66, 49.94),
        RaidIcon = { {
            npcID = 11035,
            questID = 5582,
        } },
        IsQuestOnQuest = 5582,
        Zone = 1423,
        _index = 319,
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
        _index = 320,
    }, {
        PickUp = { 5384 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.22, 73.71),
        RaidIcon = { {
            npcID = 11216,
            questID = 5384,
        } },
        AnyOf = { {
            IsQuestCompleted = 5515,
        } },
        MinLevel = 55,
        Zone = 1422,
        _index = 321,
    }, {
        Qpart = {
            [8994] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 8994,
        _index = 322,
    }, {
        Done = { 8994 },
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8994,
        } },
        IsQuestOnQuest = 8994,
        _index = 323,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_289",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 69, 72.7),
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        Zone = 1422,
        _index = 324,
    }, {
        Qpart = {
            [5384] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5384,
        _index = 325,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_289",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        _index = 326,
    }, {
        Done = { 5384 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.22, 73.71),
        RaidIcon = { {
            npcID = 11216,
            questID = 5384,
        } },
        IsQuestOnQuest = 5384,
        Zone = 1422,
        _index = 327,
    }, {
        PickUp = { 5461 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.57, 74.11),
        RaidIcon = { {
            npcID = 11286,
            questID = 5461,
        } },
        AnyOf = { {
            IsQuestCompleted = 5384,
        } },
        MinLevel = 57,
        Zone = 1422,
        _index = 328,
    }, {
        Qpart = {
            [5461] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5461,
        _index = 329,
    }, {
        Done = { 5461 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.57, 74.11),
        RaidIcon = { {
            npcID = 11286,
            questID = 5461,
        } },
        IsQuestOnQuest = 5461,
        Zone = 1422,
        _index = 330,
    }, {
        PickUp = { 5462 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.57, 74.11),
        RaidIcon = { {
            npcID = 11286,
            questID = 5462,
        } },
        AnyOf = { {
            IsQuestCompleted = 5461,
        } },
        MinLevel = 57,
        Zone = 1422,
        _index = 331,
    }, {
        Qpart = {
            [5462] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5462,
        _index = 332,
    }, {
        Done = { 5462 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.89, 48.29),
        RaidIcon = { {
            npcID = 11036,
            questID = 5462,
        } },
        IsQuestOnQuest = 5462,
        Zone = 1423,
        _index = 333,
    }, {
        PickUp = { 5463 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.89, 48.29),
        RaidIcon = { {
            npcID = 11036,
            questID = 5463,
        } },
        AnyOf = { {
            IsQuestCompleted = 5462,
        } },
        MinLevel = 57,
        Zone = 1423,
        _index = 334,
    }, {
        Qpart = {
            [5463] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5463,
        _index = 335,
    }, {
        Done = { 5463 },
        NoArrow = true,
        IsQuestOnQuest = 5463,
        _index = 336,
    }, {
        PickUp = { 5464 },
        NoArrow = true,
        AnyOf = { {
            IsQuestCompleted = 5463,
        } },
        MinLevel = 57,
        _index = 337,
    }, {
        Qpart = {
            [5464] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5464,
        _index = 338,
    }, {
        Done = { 5464 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.89, 48.29),
        RaidIcon = { {
            npcID = 11036,
            questID = 5464,
        } },
        IsQuestOnQuest = 5464,
        Zone = 1423,
        _index = 339,
    }, {
        PickUp = { 5465 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 71.89, 48.29),
        RaidIcon = { {
            npcID = 11036,
            questID = 5465,
        } },
        AnyOf = { {
            IsQuestCompleted = 5464,
        } },
        MinLevel = 57,
        Zone = 1423,
        _index = 340,
    }, {
        Qpart = {
            [5465] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 5465,
        _index = 341,
    }, {
        Done = { 5465 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.57, 74.11),
        RaidIcon = { {
            npcID = 11286,
            questID = 5465,
        } },
        IsQuestOnQuest = 5465,
        Zone = 1422,
        _index = 342,
    }, {
        PickUp = { 5466 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.57, 74.11),
        RaidIcon = { {
            npcID = 11286,
            questID = 5466,
        } },
        AnyOf = { {
            IsQuestCompleted = 5465,
        } },
        MinLevel = 57,
        Zone = 1422,
        _index = 343,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_289",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 69, 72.7),
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        Zone = 1422,
        _index = 344,
    }, {
        Qpart = {
            [5466] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        InstanceQuest = true,
        IsQuestOnQuest = 5466,
        _index = 345,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_289",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_289",
        _index = 346,
    }, {
        Done = { 5466 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 70.57, 74.11),
        RaidIcon = { {
            npcID = 11286,
            questID = 5466,
        } },
        IsQuestOnQuest = 5466,
        Zone = 1422,
        _index = 347,
    }, {
        RouteCompleted = true,
        _index = 348,
    } },
}
