local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Dire-Maul"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 54,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Dire Maul"],
    levelRange = {
        max = 60,
        min = 54,
    },
    mapID = 1444,
    steps = { {
        PickUp = { 7441 },
        _comment = "Quest contract: 7441 Pusillin and the Elder Azj'Tordin",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 76.91, 37.35),
        RaidIcon = { {
            npcID = 14355,
            questID = 7441,
        } },
        MinLevel = 54,
        Zone = 1444,
        _index = 1,
    }, {
        PickUp = { 7481 },
        _comment = "Quest contract: 7481 Elven Legends",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 74.4, 44),
        RaidIcon = { {
            npcID = 14373,
            questID = 7481,
        } },
        Faction = "Horde",
        MinLevel = 54,
        Zone = 1444,
        _index = 2,
    }, {
        PickUp = { 7482 },
        _comment = "Quest contract: 7482 Elven Legends",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 31.65, 43.45),
        RaidIcon = { {
            npcID = 14374,
            questID = 7482,
        } },
        Faction = "Alliance",
        MinLevel = 54,
        Zone = 1444,
        _index = 3,
    }, {
        PickUp = { 7488 },
        _comment = "Quest contract: 7488 Lethtendris's Web",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 30.38, 46.17),
        RaidIcon = { {
            npcID = 7877,
            questID = 7488,
        } },
        Faction = "Alliance",
        MinLevel = 54,
        Zone = 1444,
        _index = 4,
    }, {
        PickUp = { 7489 },
        _comment = "Quest contract: 7489 Lethtendris's Web",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 76.18, 43.83),
        RaidIcon = { {
            npcID = 7776,
            questID = 7489,
        } },
        Faction = "Horde",
        MinLevel = 54,
        Zone = 1444,
        _index = 5,
    }, {
        PickUp = { 7492 },
        _comment = "Quest contract: 7492 Camp Mojache",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 63.9, 44.08),
        RaidIcon = { {
            npcID = 10879,
            questID = 7492,
        } },
        Faction = "Horde",
        MinLevel = 54,
        Zone = 1458,
        _index = 6,
    }, {
        PickUp = { 7494 },
        _comment = "Quest contract: 7494 Feathermoon Stronghold",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 56.39, 74.09),
        RaidIcon = { {
            npcID = 2198,
            questID = 7494,
        } },
        Faction = "Alliance",
        MinLevel = 54,
        Zone = 1453,
        _index = 7,
    }, {
        PickUp = { 7581 },
        _comment = "Quest contract: 7581 The Prison's Bindings",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 34.13, 50.14),
        RaidIcon = { {
            npcID = 14463,
            questID = 7581,
        } },
        Class = { "WARLOCK" },
        MinLevel = 60,
        Zone = 1419,
        _index = 8,
    }, {
        PickUp = { 7582 },
        _comment = "Quest contract: 7582 The Prison's Casing",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 34.13, 50.14),
        RaidIcon = { {
            npcID = 14463,
            questID = 7582,
        } },
        Class = { "WARLOCK" },
        MinLevel = 60,
        Zone = 1419,
        _index = 9,
    }, {
        PickUp = { 8905 },
        _comment = "Quest contract: 8905 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8905,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 10,
    }, {
        PickUp = { 8906 },
        _comment = "Quest contract: 8906 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8906,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 11,
    }, {
        PickUp = { 8907 },
        _comment = "Quest contract: 8907 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8907,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 12,
    }, {
        PickUp = { 8908 },
        _comment = "Quest contract: 8908 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8908,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 13,
    }, {
        PickUp = { 8909 },
        _comment = "Quest contract: 8909 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8909,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 14,
    }, {
        PickUp = { 8910 },
        _comment = "Quest contract: 8910 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8910,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 15,
    }, {
        PickUp = { 8911 },
        _comment = "Quest contract: 8911 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8911,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 16,
    }, {
        PickUp = { 8912 },
        _comment = "Quest contract: 8912 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8912,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        MinLevel = 58,
        Zone = 1455,
        _index = 17,
    }, {
        PickUp = { 8913 },
        _comment = "Quest contract: 8913 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8913,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 18,
    }, {
        PickUp = { 8914 },
        _comment = "Quest contract: 8914 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8914,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 19,
    }, {
        PickUp = { 8915 },
        _comment = "Quest contract: 8915 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8915,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 20,
    }, {
        PickUp = { 8916 },
        _comment = "Quest contract: 8916 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8916,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 21,
    }, {
        PickUp = { 8917 },
        _comment = "Quest contract: 8917 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8917,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 22,
    }, {
        PickUp = { 8918 },
        _comment = "Quest contract: 8918 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8918,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 23,
    }, {
        PickUp = { 8919 },
        _comment = "Quest contract: 8919 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8919,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 24,
    }, {
        PickUp = { 8920 },
        _comment = "Quest contract: 8920 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8920,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        MinLevel = 58,
        Zone = 1454,
        _index = 25,
    }, {
        Done = { 7492 },
        _comment = "Quest contract: 7492 Camp Mojache",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 76.18, 43.83),
        RaidIcon = { {
            npcID = 7776,
            questID = 7492,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 7492,
        Zone = 1444,
        _index = 26,
    }, {
        Done = { 7494 },
        _comment = "Quest contract: 7494 Feathermoon Stronghold",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 30.38, 46.17),
        RaidIcon = { {
            npcID = 7877,
            questID = 7494,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 7494,
        Zone = 1444,
        _index = 27,
    }, {
        Qpart = {
            [7582] = { 1 },
        },
        _comment = "Quest contract: 7582 The Prison's Casing",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 55.46, 84.22),
        IsQuestOnQuest = 7582,
        Zone = 1452,
        _index = 28,
    }, {
        Qpart = {
            [8905] = { 1, 2 },
        },
        _comment = "Quest contract: 8905 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8905,
        Zone = 1452,
        _index = 29,
    }, {
        Qpart = {
            [8906] = { 1, 2 },
        },
        _comment = "Quest contract: 8906 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8906,
        Zone = 1452,
        _index = 30,
    }, {
        Qpart = {
            [8907] = { 1, 2 },
        },
        _comment = "Quest contract: 8907 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8907,
        Zone = 1452,
        _index = 31,
    }, {
        Qpart = {
            [8908] = { 1, 2 },
        },
        _comment = "Quest contract: 8908 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8908,
        Zone = 1452,
        _index = 32,
    }, {
        Qpart = {
            [8909] = { 1, 2 },
        },
        _comment = "Quest contract: 8909 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8909,
        Zone = 1452,
        _index = 33,
    }, {
        Qpart = {
            [8910] = { 1, 2 },
        },
        _comment = "Quest contract: 8910 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8910,
        Zone = 1452,
        _index = 34,
    }, {
        Qpart = {
            [8911] = { 1, 2 },
        },
        _comment = "Quest contract: 8911 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8911,
        Zone = 1452,
        _index = 35,
    }, {
        Qpart = {
            [8912] = { 1, 2 },
        },
        _comment = "Quest contract: 8912 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 48.89, 18.84),
        IsQuestOnQuest = 8912,
        Zone = 1452,
        _index = 36,
    }, {
        Qpart = {
            [8913] = { 1, 2 },
        },
        _comment = "Quest contract: 8913 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8913,
        Zone = 1451,
        _index = 37,
    }, {
        Qpart = {
            [8914] = { 1, 2 },
        },
        _comment = "Quest contract: 8914 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8914,
        Zone = 1451,
        _index = 38,
    }, {
        Qpart = {
            [8915] = { 1, 2 },
        },
        _comment = "Quest contract: 8915 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8915,
        Zone = 1451,
        _index = 39,
    }, {
        Qpart = {
            [8916] = { 1, 2 },
        },
        _comment = "Quest contract: 8916 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8916,
        Zone = 1451,
        _index = 40,
    }, {
        Qpart = {
            [8917] = { 1, 2 },
        },
        _comment = "Quest contract: 8917 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8917,
        Zone = 1451,
        _index = 41,
    }, {
        Qpart = {
            [8918] = { 1, 2 },
        },
        _comment = "Quest contract: 8918 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8918,
        Zone = 1451,
        _index = 42,
    }, {
        Qpart = {
            [8919] = { 1, 2 },
        },
        _comment = "Quest contract: 8919 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8919,
        Zone = 1451,
        _index = 43,
    }, {
        Qpart = {
            [8920] = { 1, 2 },
        },
        _comment = "Quest contract: 8920 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 72.57, 36.82),
        IsQuestOnQuest = 8920,
        Zone = 1451,
        _index = 44,
    }, {
        Done = { 7582 },
        _comment = "Quest contract: 7582 The Prison's Casing",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 34.13, 50.14),
        RaidIcon = { {
            npcID = 14463,
            questID = 7582,
        } },
        Class = { "WARLOCK" },
        IsQuestOnQuest = 7582,
        Zone = 1419,
        _index = 45,
    }, {
        Done = { 8905 },
        _comment = "Quest contract: 8905 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8905,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        IsQuestOnQuest = 8905,
        Zone = 1455,
        _index = 46,
    }, {
        Done = { 8906 },
        _comment = "Quest contract: 8906 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8906,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        IsQuestOnQuest = 8906,
        Zone = 1455,
        _index = 47,
    }, {
        Done = { 8907 },
        _comment = "Quest contract: 8907 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8907,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8907,
        Zone = 1455,
        _index = 48,
    }, {
        Done = { 8908 },
        _comment = "Quest contract: 8908 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8908,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        IsQuestOnQuest = 8908,
        Zone = 1455,
        _index = 49,
    }, {
        Done = { 8909 },
        _comment = "Quest contract: 8909 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8909,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        IsQuestOnQuest = 8909,
        Zone = 1455,
        _index = 50,
    }, {
        Done = { 8910 },
        _comment = "Quest contract: 8910 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8910,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8910,
        Zone = 1455,
        _index = 51,
    }, {
        Done = { 8911 },
        _comment = "Quest contract: 8911 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8911,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        IsQuestOnQuest = 8911,
        Zone = 1455,
        _index = 52,
    }, {
        Done = { 8912 },
        _comment = "Quest contract: 8912 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8912,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        IsQuestOnQuest = 8912,
        Zone = 1455,
        _index = 53,
    }, {
        Done = { 8913 },
        _comment = "Quest contract: 8913 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8913,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        IsQuestOnQuest = 8913,
        Zone = 1454,
        _index = 54,
    }, {
        Done = { 8914 },
        _comment = "Quest contract: 8914 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8914,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        IsQuestOnQuest = 8914,
        Zone = 1454,
        _index = 55,
    }, {
        Done = { 8915 },
        _comment = "Quest contract: 8915 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8915,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        IsQuestOnQuest = 8915,
        Zone = 1454,
        _index = 56,
    }, {
        Done = { 8916 },
        _comment = "Quest contract: 8916 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8916,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        IsQuestOnQuest = 8916,
        Zone = 1454,
        _index = 57,
    }, {
        Done = { 8917 },
        _comment = "Quest contract: 8917 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8917,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        IsQuestOnQuest = 8917,
        Zone = 1454,
        _index = 58,
    }, {
        Done = { 8918 },
        _comment = "Quest contract: 8918 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8918,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        IsQuestOnQuest = 8918,
        Zone = 1454,
        _index = 59,
    }, {
        Done = { 8919 },
        _comment = "Quest contract: 8919 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8919,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        IsQuestOnQuest = 8919,
        Zone = 1454,
        _index = 60,
    }, {
        Done = { 8920 },
        _comment = "Quest contract: 8920 An Earnest Proposition",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8920,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        IsQuestOnQuest = 8920,
        Zone = 1454,
        _index = 61,
    }, {
        PickUp = { 8922 },
        _comment = "Quest contract: 8922 A Supernatural Device",
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
        _index = 62,
    }, {
        PickUp = { 8923 },
        _comment = "Quest contract: 8923 A Supernatural Device",
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
        _index = 63,
    }, {
        Qpart = {
            [8922] = { 1 },
        },
        _comment = "Quest contract: 8922 A Supernatural Device",
        NoArrow = true,
        IsQuestOnQuest = 8922,
        _index = 64,
    }, {
        Qpart = {
            [8923] = { 1 },
        },
        _comment = "Quest contract: 8923 A Supernatural Device",
        NoArrow = true,
        IsQuestOnQuest = 8923,
        _index = 65,
    }, {
        Done = { 8922 },
        _comment = "Quest contract: 8922 A Supernatural Device",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8922,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8922,
        Zone = 1446,
        _index = 66,
    }, {
        Done = { 8923 },
        _comment = "Quest contract: 8923 A Supernatural Device",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8923,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 8923,
        Zone = 1446,
        _index = 67,
    }, {
        PickUp = { 8921 },
        _comment = "Quest contract: 8921 The Ectoplasmic Distiller",
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
        _index = 68,
    }, {
        Qpart = {
            [8921] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 8921 The Ectoplasmic Distiller",
        NoArrow = true,
        IsQuestOnQuest = 8921,
        _index = 69,
    }, {
        Done = { 8921 },
        _comment = "Quest contract: 8921 The Ectoplasmic Distiller",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8921,
        } },
        IsQuestOnQuest = 8921,
        Zone = 1446,
        _index = 70,
    }, {
        PickUp = { 8924 },
        _comment = "Quest contract: 8924 Hunting for Ectoplasm",
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
        _index = 71,
    }, {
        Qpart = {
            [8924] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 8924 Hunting for Ectoplasm",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 60.94, 58.39),
        IsQuestOnQuest = 8924,
        Zone = 1451,
        _index = 72,
    }, {
        Done = { 8924 },
        _comment = "Quest contract: 8924 Hunting for Ectoplasm",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8924,
        } },
        IsQuestOnQuest = 8924,
        Zone = 1446,
        _index = 73,
    }, {
        PickUp = { 8925 },
        _comment = "Quest contract: 8925 A Portable Power Source",
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
        _index = 74,
    }, {
        Qpart = {
            [8925] = { 1 },
        },
        _comment = "Quest contract: 8925 A Portable Power Source",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 35.39, 57.76),
        IsQuestOnQuest = 8925,
        Zone = 1428,
        _index = 75,
    }, {
        Done = { 8925 },
        _comment = "Quest contract: 8925 A Portable Power Source",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8925,
        } },
        IsQuestOnQuest = 8925,
        Zone = 1446,
        _index = 76,
    }, {
        PickUp = { 8928 },
        _comment = "Quest contract: 8928 A Shifty Merchant",
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
        _index = 77,
    }, {
        Qpart = {
            [8928] = { 1 },
        },
        _comment = "Quest contract: 8928 A Shifty Merchant",
        NoArrow = true,
        IsQuestOnQuest = 8928,
        _index = 78,
    }, {
        Done = { 8928 },
        _comment = "Quest contract: 8928 A Shifty Merchant",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 52.47, 27.23),
        RaidIcon = { {
            npcID = 16014,
            questID = 8928,
        } },
        IsQuestOnQuest = 8928,
        Zone = 1446,
        _index = 79,
    }, {
        PickUp = { 8977 },
        _comment = "Quest contract: 8977 Return to Deliana",
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
        _index = 80,
    }, {
        PickUp = { 8978 },
        _comment = "Quest contract: 8978 Return to Mokvar",
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
        _index = 81,
    }, {
        Qpart = {
            [8977] = { 1 },
        },
        _comment = "Quest contract: 8977 Return to Deliana",
        NoArrow = true,
        IsQuestOnQuest = 8977,
        _index = 82,
    }, {
        Qpart = {
            [8978] = { 1 },
        },
        _comment = "Quest contract: 8978 Return to Mokvar",
        NoArrow = true,
        IsQuestOnQuest = 8978,
        _index = 83,
    }, {
        Done = { 8977 },
        _comment = "Quest contract: 8977 Return to Deliana",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8977,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8977,
        Zone = 1455,
        _index = 84,
    }, {
        Done = { 8978 },
        _comment = "Quest contract: 8978 Return to Mokvar",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8978,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 8978,
        Zone = 1454,
        _index = 85,
    }, {
        PickUp = { 8926 },
        _comment = "Quest contract: 8926 Just Compensation",
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
        _index = 86,
    }, {
        PickUp = { 8927 },
        _comment = "Quest contract: 8927 Just Compensation",
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
        _index = 87,
    }, {
        PickUp = { 8931 },
        _comment = "Quest contract: 8931 Just Compensation",
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
        _index = 88,
    }, {
        PickUp = { 8932 },
        _comment = "Quest contract: 8932 Just Compensation",
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
        _index = 89,
    }, {
        PickUp = { 8933 },
        _comment = "Quest contract: 8933 Just Compensation",
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
        _index = 90,
    }, {
        PickUp = { 8934 },
        _comment = "Quest contract: 8934 Just Compensation",
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
        _index = 91,
    }, {
        PickUp = { 8935 },
        _comment = "Quest contract: 8935 Just Compensation",
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
        _index = 92,
    }, {
        PickUp = { 8936 },
        _comment = "Quest contract: 8936 Just Compensation",
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
        _index = 93,
    }, {
        PickUp = { 8937 },
        _comment = "Quest contract: 8937 Just Compensation",
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
        _index = 94,
    }, {
        PickUp = { 8938 },
        _comment = "Quest contract: 8938 Just Compensation",
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
        _index = 95,
    }, {
        PickUp = { 8939 },
        _comment = "Quest contract: 8939 Just Compensation",
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
        _index = 96,
    }, {
        PickUp = { 8940 },
        _comment = "Quest contract: 8940 Just Compensation",
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
        _index = 97,
    }, {
        PickUp = { 8941 },
        _comment = "Quest contract: 8941 Just Compensation",
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
        _index = 98,
    }, {
        PickUp = { 8942 },
        _comment = "Quest contract: 8942 Just Compensation",
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
        _index = 99,
    }, {
        PickUp = { 8943 },
        _comment = "Quest contract: 8943 Just Compensation",
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
        _index = 100,
    }, {
        PickUp = { 8944 },
        _comment = "Quest contract: 8944 Just Compensation",
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
        _index = 101,
    }, {
        Qpart = {
            [8926] = { 1, 2 },
        },
        _comment = "Quest contract: 8926 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8926,
        _index = 102,
    }, {
        Qpart = {
            [8927] = { 1, 2 },
        },
        _comment = "Quest contract: 8927 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8927,
        _index = 103,
    }, {
        Qpart = {
            [8931] = { 1, 2 },
        },
        _comment = "Quest contract: 8931 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8931,
        _index = 104,
    }, {
        Qpart = {
            [8932] = { 1, 2 },
        },
        _comment = "Quest contract: 8932 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8932,
        _index = 105,
    }, {
        Qpart = {
            [8933] = { 1, 2 },
        },
        _comment = "Quest contract: 8933 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 51.93, 23.82),
        IsQuestOnQuest = 8933,
        Zone = 1422,
        _index = 106,
    }, {
        Qpart = {
            [8934] = { 1, 2 },
        },
        _comment = "Quest contract: 8934 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8934,
        _index = 107,
    }, {
        Qpart = {
            [8935] = { 1, 2 },
        },
        _comment = "Quest contract: 8935 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8935,
        _index = 108,
    }, {
        Qpart = {
            [8936] = { 1, 2 },
        },
        _comment = "Quest contract: 8936 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8936,
        _index = 109,
    }, {
        Qpart = {
            [8937] = { 1, 2 },
        },
        _comment = "Quest contract: 8937 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8937,
        _index = 110,
    }, {
        Qpart = {
            [8938] = { 1, 2 },
        },
        _comment = "Quest contract: 8938 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8938,
        _index = 111,
    }, {
        Qpart = {
            [8939] = { 1, 2 },
        },
        _comment = "Quest contract: 8939 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8939,
        _index = 112,
    }, {
        Qpart = {
            [8940] = { 1, 2 },
        },
        _comment = "Quest contract: 8940 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8940,
        _index = 113,
    }, {
        Qpart = {
            [8941] = { 1, 2 },
        },
        _comment = "Quest contract: 8941 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8941,
        _index = 114,
    }, {
        Qpart = {
            [8942] = { 1, 2 },
        },
        _comment = "Quest contract: 8942 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8942,
        _index = 115,
    }, {
        Qpart = {
            [8943] = { 1, 2 },
        },
        _comment = "Quest contract: 8943 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8943,
        _index = 116,
    }, {
        Qpart = {
            [8944] = { 1, 2 },
        },
        _comment = "Quest contract: 8944 Just Compensation",
        NoArrow = true,
        IsQuestOnQuest = 8944,
        _index = 117,
    }, {
        Done = { 8926 },
        _comment = "Quest contract: 8926 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8926,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        IsQuestOnQuest = 8926,
        Zone = 1455,
        _index = 118,
    }, {
        Done = { 8927 },
        _comment = "Quest contract: 8927 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8927,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        IsQuestOnQuest = 8927,
        Zone = 1454,
        _index = 119,
    }, {
        Done = { 8931 },
        _comment = "Quest contract: 8931 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8931,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        IsQuestOnQuest = 8931,
        Zone = 1455,
        _index = 120,
    }, {
        Done = { 8932 },
        _comment = "Quest contract: 8932 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8932,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8932,
        Zone = 1455,
        _index = 121,
    }, {
        Done = { 8933 },
        _comment = "Quest contract: 8933 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8933,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        IsQuestOnQuest = 8933,
        Zone = 1455,
        _index = 122,
    }, {
        Done = { 8934 },
        _comment = "Quest contract: 8934 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8934,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        IsQuestOnQuest = 8934,
        Zone = 1455,
        _index = 123,
    }, {
        Done = { 8935 },
        _comment = "Quest contract: 8935 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8935,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8935,
        Zone = 1455,
        _index = 124,
    }, {
        Done = { 8936 },
        _comment = "Quest contract: 8936 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8936,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        IsQuestOnQuest = 8936,
        Zone = 1455,
        _index = 125,
    }, {
        Done = { 8937 },
        _comment = "Quest contract: 8937 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8937,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        IsQuestOnQuest = 8937,
        Zone = 1455,
        _index = 126,
    }, {
        Done = { 8938 },
        _comment = "Quest contract: 8938 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8938,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        IsQuestOnQuest = 8938,
        Zone = 1454,
        _index = 127,
    }, {
        Done = { 8939 },
        _comment = "Quest contract: 8939 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8939,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        IsQuestOnQuest = 8939,
        Zone = 1454,
        _index = 128,
    }, {
        Done = { 8940 },
        _comment = "Quest contract: 8940 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8940,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        IsQuestOnQuest = 8940,
        Zone = 1454,
        _index = 129,
    }, {
        Done = { 8941 },
        _comment = "Quest contract: 8941 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8941,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        IsQuestOnQuest = 8941,
        Zone = 1454,
        _index = 130,
    }, {
        Done = { 8942 },
        _comment = "Quest contract: 8942 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8942,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        IsQuestOnQuest = 8942,
        Zone = 1454,
        _index = 131,
    }, {
        Done = { 8943 },
        _comment = "Quest contract: 8943 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8943,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        IsQuestOnQuest = 8943,
        Zone = 1454,
        _index = 132,
    }, {
        Done = { 8944 },
        _comment = "Quest contract: 8944 Just Compensation",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8944,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        IsQuestOnQuest = 8944,
        Zone = 1454,
        _index = 133,
    }, {
        PickUp = { 8929 },
        _comment = "Quest contract: 8929 In Search of Anthion",
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
        _index = 134,
    }, {
        PickUp = { 8930 },
        _comment = "Quest contract: 8930 In Search of Anthion",
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
        _index = 135,
    }, {
        Done = { 8929 },
        _comment = "Quest contract: 8929 In Search of Anthion",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8929,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8929,
        Zone = 1423,
        _index = 136,
    }, {
        Done = { 8930 },
        _comment = "Quest contract: 8930 In Search of Anthion",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8930,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 8930,
        Zone = 1423,
        _index = 137,
    }, {
        PickUp = { 8945 },
        _comment = "Quest contract: 8945 Dead Man's Plea",
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
        _index = 138,
    }, {
        Qpart = {
            [8945] = { 1 },
        },
        _comment = "Quest contract: 8945 Dead Man's Plea",
        NoArrow = true,
        IsQuestOnQuest = 8945,
        _index = 139,
    }, {
        Done = { 8945 },
        _comment = "Quest contract: 8945 Dead Man's Plea",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16031,
            questID = 8945,
        } },
        IsQuestOnQuest = 8945,
        _index = 140,
    }, {
        PickUp = { 8946 },
        _comment = "Quest contract: 8946 Proof of Life",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16031,
            questID = 8946,
        } },
        AnyOf = { {
            IsQuestCompleted = 8945,
        } },
        MinLevel = 58,
        _index = 141,
    }, {
        Qpart = {
            [8946] = { 1 },
        },
        _comment = "Quest contract: 8946 Proof of Life",
        NoArrow = true,
        IsQuestOnQuest = 8946,
        _index = 142,
    }, {
        Done = { 8946 },
        _comment = "Quest contract: 8946 Proof of Life",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8946,
        } },
        IsQuestOnQuest = 8946,
        Zone = 1423,
        _index = 143,
    }, {
        PickUp = { 8947 },
        _comment = "Quest contract: 8947 Anthion's Strange Request",
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
        _index = 144,
    }, {
        Qpart = {
            [8947] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 8947 Anthion's Strange Request",
        NoArrow = true,
        IsQuestOnQuest = 8947,
        _index = 145,
    }, {
        Done = { 8947 },
        _comment = "Quest contract: 8947 Anthion's Strange Request",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 8947,
        } },
        IsQuestOnQuest = 8947,
        Zone = 1423,
        _index = 146,
    }, {
        PickUp = { 8948 },
        _comment = "Quest contract: 8948 Anthion's Old Friend",
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
        _index = 147,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_429",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 64.9, 29.4),
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Zone = 1444,
        _index = 148,
    }, {
        PickUp = { 1193 },
        _comment = "Quest contract: 1193 A Broken Trap",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        MinLevel = 56,
        _index = 149,
    }, {
        PickUp = { 5518 },
        _comment = "Quest contract: 5518 The Gordok Ogre Suit",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 5518,
        } },
        MinLevel = 56,
        _index = 150,
    }, {
        PickUp = { 5525 },
        _comment = "Quest contract: 5525 Free Knot!",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 5525,
        } },
        MinLevel = 57,
        _index = 151,
    }, {
        PickUp = { 5528 },
        _comment = "Quest contract: 5528 The Gordok Taste Test",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14322,
            questID = 5528,
        } },
        MinLevel = 57,
        _index = 152,
    }, {
        PickUp = { 7461 },
        _comment = "Quest contract: 7461 The Madness Within",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14358,
            questID = 7461,
        } },
        MinLevel = 56,
        _index = 153,
    }, {
        PickUp = { 7463 },
        _comment = "Quest contract: 7463 Arcane Refreshment",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7463,
        } },
        Class = { "MAGE" },
        MinLevel = 60,
        _index = 154,
    }, {
        PickUp = { 7703 },
        _comment = "Quest contract: 7703 Unfinished Gordok Business",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14325,
            questID = 7703,
        } },
        MinLevel = 56,
        _index = 155,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Zevrim Thornhoof",
            npcID = 11490,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 156,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Hydrospawn",
            npcID = 13280,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 157,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Lethtendris",
            npcID = 14327,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 158,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Pusillin",
            npcID = 14354,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 159,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Alzzin the Wildshaper",
            npcID = 11492,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 160,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Tendris Warpwood",
            npcID = 11489,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 161,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Illyanna Ravenoak",
            npcID = 11488,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 162,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Magister Kalendris",
            npcID = 11487,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 163,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Immol'thar",
            npcID = 11496,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 164,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Prince Tortheldrin",
            npcID = 11486,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 165,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Guard Mol'dar",
            npcID = 14326,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 166,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Stomper Kreeg",
            npcID = 14322,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 167,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Guard Fengus",
            npcID = 14321,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 168,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Guard Slip'kik",
            npcID = 14323,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 169,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Captain Kromcrush",
            npcID = 14325,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 170,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Cho'Rush the Observer",
            npcID = 14324,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 171,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "King Gordok",
            npcID = 11501,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 172,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_429",
            name = "Lord Hel'nurath",
            npcID = 14506,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        _index = 173,
    }, {
        Qpart = {
            [1193] = { 1, 2 },
        },
        _comment = "Quest contract: 1193 A Broken Trap",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 1193,
        _index = 174,
    }, {
        Qpart = {
            [5518] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 5518 The Gordok Ogre Suit",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 5518,
        _index = 175,
    }, {
        Qpart = {
            [5525] = { 1 },
        },
        _comment = "Quest contract: 5525 Free Knot!",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 5525,
        _index = 176,
    }, {
        Done = { 5528 },
        _comment = "Quest contract: 5528 The Gordok Taste Test",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14322,
            questID = 5528,
        } },
        IsQuestOnQuest = 5528,
        _index = 177,
    }, {
        Qpart = {
            [7441] = { 1 },
        },
        _comment = "Quest contract: 7441 Pusillin and the Elder Azj'Tordin",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7441,
        _index = 178,
    }, {
        Qpart = {
            [7461] = { 1, 2 },
        },
        _comment = "Quest contract: 7461 The Madness Within",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7461,
        _index = 179,
    }, {
        Qpart = {
            [7463] = { 1 },
        },
        _comment = "Quest contract: 7463 Arcane Refreshment",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7463,
        _index = 180,
    }, {
        Qpart = {
            [7481] = { 1 },
        },
        _comment = "Quest contract: 7481 Elven Legends",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7481,
        _index = 181,
    }, {
        Qpart = {
            [7482] = { 1 },
        },
        _comment = "Quest contract: 7482 Elven Legends",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7482,
        _index = 182,
    }, {
        Qpart = {
            [7488] = { 1 },
        },
        _comment = "Quest contract: 7488 Lethtendris's Web",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7488,
        _index = 183,
    }, {
        Qpart = {
            [7489] = { 1 },
        },
        _comment = "Quest contract: 7489 Lethtendris's Web",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7489,
        _index = 184,
    }, {
        PickUp = { 7498 },
        _comment = "Quest contract: 7498 Garona: A Study on Stealth and Treachery",
        Button = {
            ["7498"] = 18356,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "ROGUE" },
        ItemCount = {
            count = 1,
            itemID = 18356,
        },
        MinLevel = 54,
        _index = 185,
    }, {
        PickUp = { 7499 },
        _comment = "Quest contract: 7499 Codex of Defense",
        Button = {
            ["7499"] = 18357,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "WARRIOR" },
        ItemCount = {
            count = 1,
            itemID = 18357,
        },
        MinLevel = 54,
        _index = 186,
    }, {
        PickUp = { 7500 },
        _comment = "Quest contract: 7500 The Arcanist's Cookbook",
        Button = {
            ["7500"] = 18358,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "MAGE" },
        ItemCount = {
            count = 1,
            itemID = 18358,
        },
        MinLevel = 54,
        _index = 187,
    }, {
        PickUp = { 7501 },
        _comment = "Quest contract: 7501 The Light and How To Swing It",
        Button = {
            ["7501"] = 18359,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "PALADIN" },
        ItemCount = {
            count = 1,
            itemID = 18359,
        },
        MinLevel = 54,
        _index = 188,
    }, {
        PickUp = { 7502 },
        _comment = "Quest contract: 7502 Harnessing Shadows",
        Button = {
            ["7502"] = 18360,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "WARLOCK" },
        ItemCount = {
            count = 1,
            itemID = 18360,
        },
        MinLevel = 54,
        _index = 189,
    }, {
        PickUp = { 7503 },
        _comment = "Quest contract: 7503 The Greatest Race of Hunters",
        Button = {
            ["7503"] = 18361,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "HUNTER" },
        ItemCount = {
            count = 1,
            itemID = 18361,
        },
        MinLevel = 54,
        _index = 190,
    }, {
        PickUp = { 7504 },
        _comment = "Quest contract: 7504 Holy Bologna: What the Light Won't Tell You",
        Button = {
            ["7504"] = 18362,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "PRIEST" },
        ItemCount = {
            count = 1,
            itemID = 18362,
        },
        MinLevel = 54,
        _index = 191,
    }, {
        PickUp = { 7505 },
        _comment = "Quest contract: 7505 Frost Shock and You",
        Button = {
            ["7505"] = 18363,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "SHAMAN" },
        ItemCount = {
            count = 1,
            itemID = 18363,
        },
        MinLevel = 54,
        _index = 192,
    }, {
        PickUp = { 7506 },
        _comment = "Quest contract: 7506 The Emerald Dream...",
        Button = {
            ["7506"] = 18364,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "DRUID" },
        ItemCount = {
            count = 1,
            itemID = 18364,
        },
        MinLevel = 54,
        _index = 193,
    }, {
        PickUp = { 7507 },
        _comment = "Quest contract: 7507 Nostro's Compendium",
        Button = {
            ["7507"] = 18401,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Class = { "WARRIOR", "PALADIN" },
        ItemCount = {
            count = 1,
            itemID = 18401,
        },
        MinLevel = 60,
        _index = 194,
    }, {
        Qpart = {
            [7581] = { 1 },
        },
        _comment = "Quest contract: 7581 The Prison's Bindings",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7581,
        _index = 195,
    }, {
        Qpart = {
            [7703] = { 1 },
        },
        _comment = "Quest contract: 7703 Unfinished Gordok Business",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7703,
        _index = 196,
    }, {
        Qpart = {
            [8948] = { 1 },
        },
        _comment = "Quest contract: 8948 Anthion's Old Friend",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 8948,
        _index = 197,
    }, {
        Done = { 1193 },
        _comment = "Quest contract: 1193 A Broken Trap",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 1193,
        _index = 198,
    }, {
        Done = { 5518 },
        _comment = "Quest contract: 5518 The Gordok Ogre Suit",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 5518,
        } },
        IsQuestOnQuest = 5518,
        _index = 199,
    }, {
        Done = { 5525 },
        _comment = "Quest contract: 5525 Free Knot!",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 5525,
        } },
        IsQuestOnQuest = 5525,
        _index = 200,
    }, {
        Done = { 7461 },
        _comment = "Quest contract: 7461 The Madness Within",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14358,
            questID = 7461,
        } },
        IsQuestOnQuest = 7461,
        _index = 201,
    }, {
        Done = { 7463 },
        _comment = "Quest contract: 7463 Arcane Refreshment",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7463,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 7463,
        _index = 202,
    }, {
        Qpart = {
            [7498] = { 1 },
        },
        _comment = "Quest contract: 7498 Garona: A Study on Stealth and Treachery",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7498,
        _index = 203,
    }, {
        Qpart = {
            [7499] = { 1 },
        },
        _comment = "Quest contract: 7499 Codex of Defense",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7499,
        _index = 204,
    }, {
        Qpart = {
            [7500] = { 1 },
        },
        _comment = "Quest contract: 7500 The Arcanist's Cookbook",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7500,
        _index = 205,
    }, {
        Qpart = {
            [7501] = { 1 },
        },
        _comment = "Quest contract: 7501 The Light and How To Swing It",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7501,
        _index = 206,
    }, {
        Qpart = {
            [7502] = { 1 },
        },
        _comment = "Quest contract: 7502 Harnessing Shadows",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7502,
        _index = 207,
    }, {
        Qpart = {
            [7503] = { 1 },
        },
        _comment = "Quest contract: 7503 The Greatest Race of Hunters",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7503,
        _index = 208,
    }, {
        Qpart = {
            [7504] = { 1 },
        },
        _comment = "Quest contract: 7504 Holy Bologna: What the Light Won't Tell You",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7504,
        _index = 209,
    }, {
        Qpart = {
            [7505] = { 1 },
        },
        _comment = "Quest contract: 7505 Frost Shock and You",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7505,
        _index = 210,
    }, {
        Qpart = {
            [7506] = { 1 },
        },
        _comment = "Quest contract: 7506 The Emerald Dream...",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7506,
        _index = 211,
    }, {
        Qpart = {
            [7507] = { 1 },
        },
        _comment = "Quest contract: 7507 Nostro's Compendium",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7507,
        _index = 212,
    }, {
        Done = { 7703 },
        _comment = "Quest contract: 7703 Unfinished Gordok Business",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14325,
            questID = 7703,
        } },
        IsQuestOnQuest = 7703,
        _index = 213,
    }, {
        Done = { 8948 },
        _comment = "Quest contract: 8948 Anthion's Old Friend",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8948,
        } },
        IsQuestOnQuest = 8948,
        _index = 214,
    }, {
        PickUp = { 5519 },
        _comment = "Quest contract: 5519 The Gordok Ogre Suit",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 5519,
        } },
        AnyOf = { {
            IsQuestCompleted = 5518,
        } },
        MinLevel = 56,
        _index = 215,
    }, {
        PickUp = { 7429 },
        _comment = "Quest contract: 7429 Free Knot!",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 7429,
        } },
        AnyOf = { {
            IsQuestCompleted = 5525,
        } },
        MinLevel = 57,
        _index = 216,
    }, {
        PickUp = { 7462 },
        _comment = "Quest contract: 7462 The Treasure of the Shen'dralar",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14358,
            questID = 7462,
        } },
        AnyOf = { {
            IsQuestCompleted = 7461,
        } },
        Faction = "Alliance",
        MinLevel = 56,
        _index = 217,
    }, {
        Done = { 7498 },
        _comment = "Quest contract: 7498 Garona: A Study on Stealth and Treachery",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14383,
            questID = 7498,
        } },
        Class = { "ROGUE" },
        IsQuestOnQuest = 7498,
        _index = 218,
    }, {
        Done = { 7499 },
        _comment = "Quest contract: 7499 Codex of Defense",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14383,
            questID = 7499,
        } },
        Class = { "WARRIOR" },
        IsQuestOnQuest = 7499,
        _index = 219,
    }, {
        Done = { 7500 },
        _comment = "Quest contract: 7500 The Arcanist's Cookbook",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14383,
            questID = 7500,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 7500,
        _index = 220,
    }, {
        Done = { 7501 },
        _comment = "Quest contract: 7501 The Light and How To Swing It",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14382,
            questID = 7501,
        } },
        Class = { "PALADIN" },
        IsQuestOnQuest = 7501,
        _index = 221,
    }, {
        Done = { 7502 },
        _comment = "Quest contract: 7502 Harnessing Shadows",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14382,
            questID = 7502,
        } },
        Class = { "WARLOCK" },
        IsQuestOnQuest = 7502,
        _index = 222,
    }, {
        Done = { 7503 },
        _comment = "Quest contract: 7503 The Greatest Race of Hunters",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14382,
            questID = 7503,
        } },
        Class = { "HUNTER" },
        IsQuestOnQuest = 7503,
        _index = 223,
    }, {
        Done = { 7504 },
        _comment = "Quest contract: 7504 Holy Bologna: What the Light Won't Tell You",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14381,
            questID = 7504,
        } },
        Class = { "PRIEST" },
        IsQuestOnQuest = 7504,
        _index = 224,
    }, {
        Done = { 7505 },
        _comment = "Quest contract: 7505 Frost Shock and You",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14381,
            questID = 7505,
        } },
        Class = { "SHAMAN" },
        IsQuestOnQuest = 7505,
        _index = 225,
    }, {
        Done = { 7506 },
        _comment = "Quest contract: 7506 The Emerald Dream...",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14381,
            questID = 7506,
        } },
        Class = { "DRUID" },
        IsQuestOnQuest = 7506,
        _index = 226,
    }, {
        Done = { 7507 },
        _comment = "Quest contract: 7507 Nostro's Compendium",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7507,
        } },
        Class = { "WARRIOR", "PALADIN" },
        IsQuestOnQuest = 7507,
        _index = 227,
    }, {
        PickUp = { 7877 },
        _comment = "Quest contract: 7877 The Treasure of the Shen'dralar",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14358,
            questID = 7877,
        } },
        AnyOf = { {
            IsQuestCompleted = 7461,
        } },
        Faction = "Horde",
        MinLevel = 56,
        _index = 228,
    }, {
        PickUp = { 8949 },
        _comment = "Quest contract: 8949 Falrin's Vendetta",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8949,
        } },
        AnyOf = { {
            IsQuestCompleted = 8948,
        } },
        MinLevel = 58,
        _index = 229,
    }, {
        Qpart = {
            [5519] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 5519 The Gordok Ogre Suit",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 5519,
        _index = 230,
    }, {
        Qpart = {
            [7429] = { 1 },
        },
        _comment = "Quest contract: 7429 Free Knot!",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7429,
        _index = 231,
    }, {
        Done = { 7462 },
        _comment = "Quest contract: 7462 The Treasure of the Shen'dralar",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Faction = "Alliance",
        IsQuestOnQuest = 7462,
        _index = 232,
    }, {
        PickUp = { 7508 },
        _comment = "Quest contract: 7508 The Forging of Quel'Serrar",
        Button = {
            ["7508"] = 18513,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 7507,
        } },
        Class = { "WARRIOR", "PALADIN" },
        ItemCount = {
            count = 1,
            itemID = 18513,
        },
        MinLevel = 60,
        _index = 233,
    }, {
        Done = { 7877 },
        _comment = "Quest contract: 7877 The Treasure of the Shen'dralar",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Faction = "Horde",
        IsQuestOnQuest = 7877,
        _index = 234,
    }, {
        Qpart = {
            [8949] = { 1 },
        },
        _comment = "Quest contract: 8949 Falrin's Vendetta",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 8949,
        _index = 235,
    }, {
        Done = { 5519 },
        _comment = "Quest contract: 5519 The Gordok Ogre Suit",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 5519,
        } },
        IsQuestOnQuest = 5519,
        _index = 236,
    }, {
        Done = { 7429 },
        _comment = "Quest contract: 7429 Free Knot!",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14338,
            questID = 7429,
        } },
        IsQuestOnQuest = 7429,
        _index = 237,
    }, {
        Qpart = {
            [7508] = { 1 },
        },
        _comment = "Quest contract: 7508 The Forging of Quel'Serrar",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7508,
        _index = 238,
    }, {
        Done = { 8949 },
        _comment = "Quest contract: 8949 Falrin's Vendetta",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8949,
        } },
        IsQuestOnQuest = 8949,
        _index = 239,
    }, {
        Done = { 7508 },
        _comment = "Quest contract: 7508 The Forging of Quel'Serrar",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7508,
        } },
        Class = { "WARRIOR", "PALADIN" },
        IsQuestOnQuest = 7508,
        _index = 240,
    }, {
        PickUp = { 8950 },
        _comment = "Quest contract: 8950 The Instigator's Enchantment",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8950,
        } },
        AnyOf = { {
            IsQuestCompleted = 8949,
        } },
        MinLevel = 58,
        _index = 241,
    }, {
        Qpart = {
            [8950] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8950 The Instigator's Enchantment",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 8950,
        _index = 242,
    }, {
        Done = { 8950 },
        _comment = "Quest contract: 8950 The Instigator's Enchantment",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 8950,
        } },
        IsQuestOnQuest = 8950,
        _index = 243,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_429",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        _index = 244,
    }, {
        Done = { 7441 },
        _comment = "Quest contract: 7441 Pusillin and the Elder Azj'Tordin",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 76.91, 37.35),
        RaidIcon = { {
            npcID = 14355,
            questID = 7441,
        } },
        IsQuestOnQuest = 7441,
        Zone = 1444,
        _index = 245,
    }, {
        Done = { 7481 },
        _comment = "Quest contract: 7481 Elven Legends",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 74.4, 44),
        RaidIcon = { {
            npcID = 14373,
            questID = 7481,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 7481,
        Zone = 1444,
        _index = 246,
    }, {
        Done = { 7482 },
        _comment = "Quest contract: 7482 Elven Legends",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 31.65, 43.45),
        RaidIcon = { {
            npcID = 14374,
            questID = 7482,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 7482,
        Zone = 1444,
        _index = 247,
    }, {
        Done = { 7488 },
        _comment = "Quest contract: 7488 Lethtendris's Web",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 30.38, 46.17),
        RaidIcon = { {
            npcID = 7877,
            questID = 7488,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 7488,
        Zone = 1444,
        _index = 248,
    }, {
        Done = { 7489 },
        _comment = "Quest contract: 7489 Lethtendris's Web",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 76.18, 43.83),
        RaidIcon = { {
            npcID = 7776,
            questID = 7489,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 7489,
        Zone = 1444,
        _index = 249,
    }, {
        Done = { 7581 },
        _comment = "Quest contract: 7581 The Prison's Bindings",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 34.13, 50.14),
        RaidIcon = { {
            npcID = 14463,
            questID = 7581,
        } },
        Class = { "WARLOCK" },
        IsQuestOnQuest = 7581,
        Zone = 1419,
        _index = 250,
    }, {
        PickUp = { 9015 },
        _comment = "Quest contract: 9015 The Challenge",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16032,
            questID = 9015,
        } },
        AnyOf = { {
            IsQuestCompleted = 8950,
        } },
        MinLevel = 58,
        _index = 251,
    }, {
        PickUp = { 7583 },
        _comment = "Quest contract: 7583 Suppression",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 34.13, 50.14),
        RaidIcon = { {
            npcID = 14463,
            questID = 7583,
        } },
        AllOf = { {
            IsQuestCompleted = 7581,
        }, {
            IsQuestCompleted = 7582,
        } },
        Class = { "WARLOCK" },
        MinLevel = 60,
        Zone = 1419,
        _index = 252,
    }, {
        Qpart = {
            [9015] = { 1, 2 },
        },
        _comment = "Quest contract: 9015 The Challenge",
        NoArrow = true,
        IsQuestOnQuest = 9015,
        _index = 253,
    }, {
        Qpart = {
            [7583] = { 1, 2 },
        },
        _comment = "Quest contract: 7583 Suppression",
        NoArrow = true,
        IsQuestOnQuest = 7583,
        _index = 254,
    }, {
        Done = { 9015 },
        _comment = "Quest contract: 9015 The Challenge",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 26.11, 11.3),
        RaidIcon = { {
            npcID = 16016,
            questID = 9015,
        } },
        IsQuestOnQuest = 9015,
        Zone = 1423,
        _index = 255,
    }, {
        Done = { 7583 },
        _comment = "Quest contract: 7583 Suppression",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 34.13, 50.14),
        RaidIcon = { {
            npcID = 14463,
            questID = 7583,
        } },
        Class = { "WARLOCK" },
        IsQuestOnQuest = 7583,
        Zone = 1419,
        _index = 256,
    }, {
        PickUp = { 8951 },
        _comment = "Quest contract: 8951 Anthion's Parting Words",
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
        _index = 257,
    }, {
        PickUp = { 8952 },
        _comment = "Quest contract: 8952 Anthion's Parting Words",
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
        _index = 258,
    }, {
        PickUp = { 8953 },
        _comment = "Quest contract: 8953 Anthion's Parting Words",
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
        _index = 259,
    }, {
        PickUp = { 8954 },
        _comment = "Quest contract: 8954 Anthion's Parting Words",
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
        _index = 260,
    }, {
        PickUp = { 8955 },
        _comment = "Quest contract: 8955 Anthion's Parting Words",
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
        _index = 261,
    }, {
        PickUp = { 8956 },
        _comment = "Quest contract: 8956 Anthion's Parting Words",
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
        _index = 262,
    }, {
        PickUp = { 8957 },
        _comment = "Quest contract: 8957 Anthion's Parting Words",
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
        _index = 263,
    }, {
        PickUp = { 8958 },
        _comment = "Quest contract: 8958 Anthion's Parting Words",
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
        _index = 264,
    }, {
        PickUp = { 8959 },
        _comment = "Quest contract: 8959 Anthion's Parting Words",
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
        _index = 265,
    }, {
        PickUp = { 9016 },
        _comment = "Quest contract: 9016 Anthion's Parting Words",
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
        _index = 266,
    }, {
        PickUp = { 9017 },
        _comment = "Quest contract: 9017 Anthion's Parting Words",
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
        _index = 267,
    }, {
        PickUp = { 9018 },
        _comment = "Quest contract: 9018 Anthion's Parting Words",
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
        _index = 268,
    }, {
        PickUp = { 9019 },
        _comment = "Quest contract: 9019 Anthion's Parting Words",
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
        _index = 269,
    }, {
        PickUp = { 9020 },
        _comment = "Quest contract: 9020 Anthion's Parting Words",
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
        _index = 270,
    }, {
        PickUp = { 9021 },
        _comment = "Quest contract: 9021 Anthion's Parting Words",
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
        _index = 271,
    }, {
        PickUp = { 9022 },
        _comment = "Quest contract: 9022 Anthion's Parting Words",
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
        _index = 272,
    }, {
        Qpart = {
            [8951] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8951 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8951,
        _index = 273,
    }, {
        Qpart = {
            [8952] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8952 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8952,
        _index = 274,
    }, {
        Qpart = {
            [8953] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8953 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8953,
        _index = 275,
    }, {
        Qpart = {
            [8954] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8954 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8954,
        _index = 276,
    }, {
        Qpart = {
            [8955] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8955 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8955,
        _index = 277,
    }, {
        Qpart = {
            [8956] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8956 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8956,
        _index = 278,
    }, {
        Qpart = {
            [8957] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8957 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8957,
        _index = 279,
    }, {
        Qpart = {
            [8958] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8958 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8958,
        _index = 280,
    }, {
        Qpart = {
            [8959] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8959 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 8959,
        _index = 281,
    }, {
        Qpart = {
            [9016] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 9016 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 9016,
        _index = 282,
    }, {
        Qpart = {
            [9017] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 9017 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 9017,
        _index = 283,
    }, {
        Qpart = {
            [9018] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 9018 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 9018,
        _index = 284,
    }, {
        Qpart = {
            [9019] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 9019 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 9019,
        _index = 285,
    }, {
        Qpart = {
            [9020] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 9020 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 9020,
        _index = 286,
    }, {
        Qpart = {
            [9021] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 9021 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 9021,
        _index = 287,
    }, {
        Qpart = {
            [9022] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 9022 Anthion's Parting Words",
        NoArrow = true,
        IsQuestOnQuest = 9022,
        _index = 288,
    }, {
        Done = { 8951 },
        _comment = "Quest contract: 8951 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8951,
        } },
        Class = { "DRUID" },
        Faction = "Alliance",
        IsQuestOnQuest = 8951,
        Zone = 1455,
        _index = 289,
    }, {
        Done = { 8952 },
        _comment = "Quest contract: 8952 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8952,
        } },
        Class = { "HUNTER" },
        Faction = "Alliance",
        IsQuestOnQuest = 8952,
        Zone = 1455,
        _index = 290,
    }, {
        Done = { 8953 },
        _comment = "Quest contract: 8953 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8953,
        } },
        Class = { "MAGE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8953,
        Zone = 1455,
        _index = 291,
    }, {
        Done = { 8954 },
        _comment = "Quest contract: 8954 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8954,
        } },
        Class = { "PALADIN" },
        Faction = "Alliance",
        IsQuestOnQuest = 8954,
        Zone = 1455,
        _index = 292,
    }, {
        Done = { 8955 },
        _comment = "Quest contract: 8955 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8955,
        } },
        Class = { "PRIEST" },
        Faction = "Alliance",
        IsQuestOnQuest = 8955,
        Zone = 1455,
        _index = 293,
    }, {
        Done = { 8956 },
        _comment = "Quest contract: 8956 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8956,
        } },
        Class = { "ROGUE" },
        Faction = "Alliance",
        IsQuestOnQuest = 8956,
        Zone = 1455,
        _index = 294,
    }, {
        Done = { 8957 },
        _comment = "Quest contract: 8957 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 8957,
        } },
        Class = { "SHAMAN" },
        Faction = "Horde",
        IsQuestOnQuest = 8957,
        Zone = 1454,
        _index = 295,
    }, {
        Done = { 8958 },
        _comment = "Quest contract: 8958 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8958,
        } },
        Class = { "WARLOCK" },
        Faction = "Alliance",
        IsQuestOnQuest = 8958,
        Zone = 1455,
        _index = 296,
    }, {
        Done = { 8959 },
        _comment = "Quest contract: 8959 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 43.53, 52.64),
        RaidIcon = { {
            npcID = 16013,
            questID = 8959,
        } },
        Class = { "WARRIOR" },
        Faction = "Alliance",
        IsQuestOnQuest = 8959,
        Zone = 1455,
        _index = 297,
    }, {
        Done = { 9016 },
        _comment = "Quest contract: 9016 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9016,
        } },
        Class = { "DRUID" },
        Faction = "Horde",
        IsQuestOnQuest = 9016,
        Zone = 1454,
        _index = 298,
    }, {
        Done = { 9017 },
        _comment = "Quest contract: 9017 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9017,
        } },
        Class = { "HUNTER" },
        Faction = "Horde",
        IsQuestOnQuest = 9017,
        Zone = 1454,
        _index = 299,
    }, {
        Done = { 9018 },
        _comment = "Quest contract: 9018 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9018,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        IsQuestOnQuest = 9018,
        Zone = 1454,
        _index = 300,
    }, {
        Done = { 9019 },
        _comment = "Quest contract: 9019 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9019,
        } },
        Class = { "PRIEST" },
        Faction = "Horde",
        IsQuestOnQuest = 9019,
        Zone = 1454,
        _index = 301,
    }, {
        Done = { 9020 },
        _comment = "Quest contract: 9020 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9020,
        } },
        Class = { "ROGUE" },
        Faction = "Horde",
        IsQuestOnQuest = 9020,
        Zone = 1454,
        _index = 302,
    }, {
        Done = { 9021 },
        _comment = "Quest contract: 9021 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9021,
        } },
        Class = { "WARLOCK" },
        Faction = "Horde",
        IsQuestOnQuest = 9021,
        Zone = 1454,
        _index = 303,
    }, {
        Done = { 9022 },
        _comment = "Quest contract: 9022 Anthion's Parting Words",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
        RaidIcon = { {
            npcID = 16012,
            questID = 9022,
        } },
        Class = { "WARRIOR" },
        Faction = "Horde",
        IsQuestOnQuest = 9022,
        Zone = 1454,
        _index = 304,
    }, {
        PickUp = { 8960 },
        _comment = "Quest contract: 8960 Bodley's Unfortunate Fate",
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
        _index = 305,
    }, {
        PickUp = { 9032 },
        _comment = "Quest contract: 9032 Bodley's Unfortunate Fate",
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
        _index = 306,
    }, {
        Done = { 8960 },
        _comment = "Quest contract: 8960 Bodley's Unfortunate Fate",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8960,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 8960,
        _index = 307,
    }, {
        Done = { 9032 },
        _comment = "Quest contract: 9032 Bodley's Unfortunate Fate",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 9032,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 9032,
        _index = 308,
    }, {
        PickUp = { 8961 },
        _comment = "Quest contract: 8961 Three Kings of Flame",
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
        _index = 309,
    }, {
        Qpart = {
            [8961] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 8961 Three Kings of Flame",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 37.63, 44.8),
        IsQuestOnQuest = 8961,
        Zone = 1451,
        _index = 310,
    }, {
        Done = { 8961 },
        _comment = "Quest contract: 8961 Three Kings of Flame",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8961,
        } },
        IsQuestOnQuest = 8961,
        _index = 311,
    }, {
        PickUp = { 8962 },
        _comment = "Quest contract: 8962 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8962,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 312,
    }, {
        PickUp = { 8963 },
        _comment = "Quest contract: 8963 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8963,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 313,
    }, {
        PickUp = { 8964 },
        _comment = "Quest contract: 8964 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8964,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 314,
    }, {
        PickUp = { 8965 },
        _comment = "Quest contract: 8965 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8965,
        } },
        AnyOf = { {
            IsQuestCompleted = 8961,
        } },
        MinLevel = 58,
        _index = 315,
    }, {
        Qpart = {
            [8962] = { 1 },
        },
        _comment = "Quest contract: 8962 Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 49.31, 80.12),
        IsQuestOnQuest = 8962,
        Zone = 1451,
        _index = 316,
    }, {
        Qpart = {
            [8963] = { 1 },
        },
        _comment = "Quest contract: 8963 Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 65.66, 69.28),
        IsQuestOnQuest = 8963,
        Zone = 1452,
        _index = 317,
    }, {
        Qpart = {
            [8964] = { 1 },
        },
        _comment = "Quest contract: 8964 Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 78.03, 72.34),
        IsQuestOnQuest = 8964,
        Zone = 1423,
        _index = 318,
    }, {
        Qpart = {
            [8965] = { 1 },
        },
        _comment = "Quest contract: 8965 Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 18.33, 77.93),
        IsQuestOnQuest = 8965,
        Zone = 1424,
        _index = 319,
    }, {
        Done = { 8962 },
        _comment = "Quest contract: 8962 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8962,
        } },
        IsQuestOnQuest = 8962,
        _index = 320,
    }, {
        Done = { 8963 },
        _comment = "Quest contract: 8963 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8963,
        } },
        IsQuestOnQuest = 8963,
        _index = 321,
    }, {
        Done = { 8964 },
        _comment = "Quest contract: 8964 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8964,
        } },
        IsQuestOnQuest = 8964,
        _index = 322,
    }, {
        Done = { 8965 },
        _comment = "Quest contract: 8965 Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8965,
        } },
        IsQuestOnQuest = 8965,
        _index = 323,
    }, {
        PickUp = { 8966 },
        _comment = "Quest contract: 8966 The Left Piece of Lord Valthalak's Amulet",
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
        _index = 324,
    }, {
        PickUp = { 8968 },
        _comment = "Quest contract: 8968 The Left Piece of Lord Valthalak's Amulet",
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
        _index = 325,
    }, {
        PickUp = { 8969 },
        _comment = "Quest contract: 8969 The Left Piece of Lord Valthalak's Amulet",
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
        _index = 326,
    }, {
        Qpart = {
            [8966] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8966 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        IsQuestOnQuest = 8966,
        _index = 327,
    }, {
        Qpart = {
            [8968] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 8968 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        IsQuestOnQuest = 8968,
        _index = 328,
    }, {
        Qpart = {
            [8969] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8969 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        IsQuestOnQuest = 8969,
        _index = 329,
    }, {
        Done = { 8966 },
        _comment = "Quest contract: 8966 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8966,
        } },
        IsQuestOnQuest = 8966,
        _index = 330,
    }, {
        Done = { 8968 },
        _comment = "Quest contract: 8968 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8968,
        } },
        IsQuestOnQuest = 8968,
        _index = 331,
    }, {
        Done = { 8969 },
        _comment = "Quest contract: 8969 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8969,
        } },
        IsQuestOnQuest = 8969,
        _index = 332,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_429",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 64.9, 29.4),
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Zone = 1444,
        _index = 333,
    }, {
        PickUp = { 7483 },
        _comment = "Quest contract: 7483 Libram of Rapidity",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7483,
        } },
        AnyOf = { {
            IsQuestCompleted = 7481,
        }, {
            IsQuestCompleted = 7482,
        } },
        MinLevel = 58,
        _index = 334,
    }, {
        PickUp = { 7484 },
        _comment = "Quest contract: 7484 Libram of Focus",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7484,
        } },
        AnyOf = { {
            IsQuestCompleted = 7481,
        }, {
            IsQuestCompleted = 7482,
        } },
        MinLevel = 58,
        _index = 335,
    }, {
        PickUp = { 7485 },
        _comment = "Quest contract: 7485 Libram of Protection",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7485,
        } },
        AnyOf = { {
            IsQuestCompleted = 7481,
        }, {
            IsQuestCompleted = 7482,
        } },
        MinLevel = 58,
        _index = 336,
    }, {
        PickUp = { 8967 },
        _comment = "Quest contract: 8967 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
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
        _index = 337,
    }, {
        Qpart = {
            [7483] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 7483 Libram of Rapidity",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7483,
        _index = 338,
    }, {
        Qpart = {
            [7484] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 7484 Libram of Focus",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7484,
        _index = 339,
    }, {
        Qpart = {
            [7485] = { 1, 2, 3, 4 },
        },
        _comment = "Quest contract: 7485 Libram of Protection",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 7485,
        _index = 340,
    }, {
        Qpart = {
            [8967] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8967 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 8967,
        _index = 341,
    }, {
        Done = { 7483 },
        _comment = "Quest contract: 7483 Libram of Rapidity",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7483,
        } },
        IsQuestOnQuest = 7483,
        _index = 342,
    }, {
        Done = { 7484 },
        _comment = "Quest contract: 7484 Libram of Focus",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7484,
        } },
        IsQuestOnQuest = 7484,
        _index = 343,
    }, {
        Done = { 7485 },
        _comment = "Quest contract: 7485 Libram of Protection",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 14368,
            questID = 7485,
        } },
        IsQuestOnQuest = 7485,
        _index = 344,
    }, {
        Done = { 8967 },
        _comment = "Quest contract: 8967 The Left Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8967,
        } },
        IsQuestOnQuest = 8967,
        _index = 345,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_429",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        _index = 346,
    }, {
        PickUp = { 8970 },
        _comment = "Quest contract: 8970 I See Alcaz Island In Your Future...",
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
        _index = 347,
    }, {
        Qpart = {
            [8970] = { 1 },
        },
        _comment = "Quest contract: 8970 I See Alcaz Island In Your Future...",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 74.79, 15.12),
        IsQuestOnQuest = 8970,
        Zone = 1445,
        _index = 348,
    }, {
        Done = { 8970 },
        _comment = "Quest contract: 8970 I See Alcaz Island In Your Future...",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8970,
        } },
        IsQuestOnQuest = 8970,
        _index = 349,
    }, {
        PickUp = { 8985 },
        _comment = "Quest contract: 8985 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8985,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 350,
    }, {
        PickUp = { 8986 },
        _comment = "Quest contract: 8986 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8986,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 351,
    }, {
        PickUp = { 8987 },
        _comment = "Quest contract: 8987 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8987,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 352,
    }, {
        PickUp = { 8988 },
        _comment = "Quest contract: 8988 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8988,
        } },
        AnyOf = { {
            IsQuestCompleted = 8970,
        } },
        MinLevel = 58,
        _index = 353,
    }, {
        Qpart = {
            [8985] = { 1 },
        },
        _comment = "Quest contract: 8985 More Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 65.66, 69.28),
        IsQuestOnQuest = 8985,
        Zone = 1452,
        _index = 354,
    }, {
        Qpart = {
            [8986] = { 1 },
        },
        _comment = "Quest contract: 8986 More Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 49.31, 80.12),
        IsQuestOnQuest = 8986,
        Zone = 1451,
        _index = 355,
    }, {
        Qpart = {
            [8987] = { 1 },
        },
        _comment = "Quest contract: 8987 More Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423, 78.03, 72.34),
        IsQuestOnQuest = 8987,
        Zone = 1423,
        _index = 356,
    }, {
        Qpart = {
            [8988] = { 1 },
        },
        _comment = "Quest contract: 8988 More Components of Importance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 18.33, 77.93),
        IsQuestOnQuest = 8988,
        Zone = 1424,
        _index = 357,
    }, {
        Done = { 8985 },
        _comment = "Quest contract: 8985 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8985,
        } },
        IsQuestOnQuest = 8985,
        _index = 358,
    }, {
        Done = { 8986 },
        _comment = "Quest contract: 8986 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8986,
        } },
        IsQuestOnQuest = 8986,
        _index = 359,
    }, {
        Done = { 8987 },
        _comment = "Quest contract: 8987 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8987,
        } },
        IsQuestOnQuest = 8987,
        _index = 360,
    }, {
        Done = { 8988 },
        _comment = "Quest contract: 8988 More Components of Importance",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8988,
        } },
        IsQuestOnQuest = 8988,
        _index = 361,
    }, {
        PickUp = { 8989 },
        _comment = "Quest contract: 8989 The Right Piece of Lord Valthalak's Amulet",
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
        _index = 362,
    }, {
        PickUp = { 8991 },
        _comment = "Quest contract: 8991 The Right Piece of Lord Valthalak's Amulet",
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
        _index = 363,
    }, {
        PickUp = { 8992 },
        _comment = "Quest contract: 8992 The Right Piece of Lord Valthalak's Amulet",
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
        _index = 364,
    }, {
        Qpart = {
            [8989] = { 1, 2 },
        },
        _comment = "Quest contract: 8989 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        IsQuestOnQuest = 8989,
        _index = 365,
    }, {
        Qpart = {
            [8991] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 8991 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        IsQuestOnQuest = 8991,
        _index = 366,
    }, {
        Qpart = {
            [8992] = { 1, 2 },
        },
        _comment = "Quest contract: 8992 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        IsQuestOnQuest = 8992,
        _index = 367,
    }, {
        Done = { 8989 },
        _comment = "Quest contract: 8989 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8989,
        } },
        IsQuestOnQuest = 8989,
        _index = 368,
    }, {
        Done = { 8991 },
        _comment = "Quest contract: 8991 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8991,
        } },
        IsQuestOnQuest = 8991,
        _index = 369,
    }, {
        Done = { 8992 },
        _comment = "Quest contract: 8992 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8992,
        } },
        IsQuestOnQuest = 8992,
        _index = 370,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_429",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 64.9, 29.4),
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        Zone = 1444,
        _index = 371,
    }, {
        PickUp = { 8990 },
        _comment = "Quest contract: 8990 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
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
        _index = 372,
    }, {
        Qpart = {
            [8990] = { 1, 2 },
        },
        _comment = "Quest contract: 8990 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        IsQuestOnQuest = 8990,
        _index = 373,
    }, {
        Done = { 8990 },
        _comment = "Quest contract: 8990 The Right Piece of Lord Valthalak's Amulet",
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8990,
        } },
        IsQuestOnQuest = 8990,
        _index = 374,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_429",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_429",
        _index = 375,
    }, {
        PickUp = { 8994 },
        _comment = "Quest contract: 8994 Final Preparations",
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
        _index = 376,
    }, {
        Qpart = {
            [8994] = { 1, 2 },
        },
        _comment = "Quest contract: 8994 Final Preparations",
        NoArrow = true,
        IsQuestOnQuest = 8994,
        _index = 377,
    }, {
        Done = { 8994 },
        _comment = "Quest contract: 8994 Final Preparations",
        NoArrow = true,
        RaidIcon = { {
            npcID = 16033,
            questID = 8994,
        } },
        IsQuestOnQuest = 8994,
        _index = 378,
    }, {
        RouteCompleted = true,
        _index = 379,
    } },
}
