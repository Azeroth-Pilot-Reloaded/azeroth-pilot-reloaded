local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Uldaman"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 41,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Uldaman"],
    levelRange = {
        max = 51,
        min = 41,
    },
    mapID = 1418,
    steps = { {
        PickUp = { 2500 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 37.07, 49.38),
        RaidIcon = { {
            npcID = 1470,
            questID = 2500,
        } },
        Faction = "Alliance",
        MinLevel = 36,
        Zone = 1432,
        _index = 1,
    }, {
        PickUp = { 707 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 74.64, 11.74),
        RaidIcon = { {
            npcID = 1356,
            questID = 707,
        } },
        Faction = "Alliance",
        MinLevel = 30,
        Zone = 1455,
        _index = 2,
    }, {
        PickUp = { 709 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 51.39, 76.87),
        RaidIcon = { {
            npcID = 2785,
            questID = 709,
        } },
        MinLevel = 30,
        Zone = 1418,
        _index = 3,
    }, {
        PickUp = { 720 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 53.03, 33.94),
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1418,
        _index = 4,
    }, {
        PickUp = { 1360 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 74.19, 9.39),
        RaidIcon = { {
            npcID = 6294,
            questID = 1360,
        } },
        Faction = "Alliance",
        MinLevel = 33,
        Zone = 1455,
        _index = 5,
    }, {
        PickUp = { 1953 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 25.7, 14.19),
        RaidIcon = { {
            npcID = 3048,
            questID = 1953,
        } },
        Class = { "MAGE" },
        Faction = "Horde",
        MinLevel = 35,
        Zone = 1456,
        _index = 6,
    }, {
        PickUp = { 2258 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2258,
        } },
        Faction = "Horde",
        MinLevel = 36,
        Zone = 1418,
        _index = 7,
    }, {
        PickUp = { 2398 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 74.64, 11.74),
        RaidIcon = { {
            npcID = 1356,
            questID = 2398,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1455,
        _index = 8,
    }, {
        PickUp = { 2283 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 59.49, 36.57),
        RaidIcon = { {
            npcID = 6986,
            questID = 2283,
        } },
        Faction = "Horde",
        MinLevel = 37,
        Zone = 1454,
        _index = 9,
    }, {
        PickUp = { 2342 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 62.32, 48.61),
        RaidIcon = { {
            npcID = 5651,
            questID = 2342,
        } },
        Faction = "Horde",
        MinLevel = 33,
        Zone = 1458,
        _index = 10,
    }, {
        PickUp = { 2418 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 42.39, 52.93),
        RaidIcon = { {
            npcID = 2817,
            questID = 2418,
        } },
        MinLevel = 30,
        Zone = 1418,
        _index = 11,
    }, {
        Qpart = {
            [2500] = { 1, 2, 3 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 60.21, 30.1),
        IsQuestOnQuest = 2500,
        Zone = 1418,
        _index = 12,
    }, {
        Done = { 707 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 65.93, 65.62),
        RaidIcon = { {
            npcID = 1344,
            questID = 707,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 707,
        Zone = 1432,
        _index = 13,
    }, {
        Done = { 720 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 53.42, 43.39),
        RaidIcon = { {
            npcID = 2910,
            questID = 720,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 720,
        Zone = 1418,
        _index = 14,
    }, {
        Done = { 1953 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1953,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 1953,
        Zone = 1445,
        _index = 15,
    }, {
        Qpart = {
            [2258] = { 1, 2, 3 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 60.21, 30.1),
        IsQuestOnQuest = 2258,
        Zone = 1418,
        _index = 16,
    }, {
        Done = { 2500 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 37.07, 49.38),
        RaidIcon = { {
            npcID = 1470,
            questID = 2500,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2500,
        Zone = 1432,
        _index = 17,
    }, {
        PickUp = { 738 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 65.93, 65.62),
        RaidIcon = { {
            npcID = 1344,
            questID = 738,
        } },
        AnyOf = { {
            IsQuestCompleted = 707,
        } },
        Faction = "Alliance",
        MinLevel = 30,
        Zone = 1432,
        _index = 18,
    }, {
        PickUp = { 721 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 53.42, 43.39),
        RaidIcon = { {
            npcID = 2910,
            questID = 721,
        } },
        AnyOf = { {
            IsQuestCompleted = 720,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1418,
        _index = 19,
    }, {
        PickUp = { 1954 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1954,
        } },
        AnyOf = { {
            IsQuestCompleted = 1953,
        } },
        Class = { "MAGE" },
        MinLevel = 35,
        Zone = 1445,
        _index = 20,
    }, {
        Done = { 2258 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2258,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2258,
        Zone = 1418,
        _index = 21,
    }, {
        PickUp = { 17 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 37.07, 49.38),
        RaidIcon = { {
            npcID = 1470,
            questID = 17,
        } },
        AnyOf = { {
            IsQuestCompleted = 2500,
        } },
        Faction = "Alliance",
        MinLevel = 38,
        Zone = 1432,
        _index = 22,
    }, {
        Done = { 738 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 50.89, 62.4),
        Faction = "Alliance",
        IsQuestOnQuest = 738,
        Zone = 1418,
        _index = 23,
    }, {
        Done = { 721 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 37.9, 10.59),
        RaidIcon = { {
            npcID = 2909,
            questID = 721,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 721,
        Zone = 1418,
        _index = 24,
    }, {
        Qpart = {
            [1954] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1443, 80.3, 76.98),
        IsQuestOnQuest = 1954,
        Zone = 1443,
        _index = 25,
    }, {
        PickUp = { 2202 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2202,
        } },
        AnyOf = { {
            IsQuestCompleted = 2258,
        } },
        Faction = "Horde",
        MinLevel = 36,
        Zone = 1418,
        _index = 26,
    }, {
        PickUp = { 739 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 50.89, 62.4),
        AnyOf = { {
            IsQuestCompleted = 738,
        } },
        Faction = "Alliance",
        MinLevel = 30,
        Zone = 1418,
        _index = 27,
    }, {
        PickUp = { 722 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 37.9, 10.59),
        RaidIcon = { {
            npcID = 2909,
            questID = 722,
        } },
        AnyOf = { {
            IsQuestCompleted = 721,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1418,
        _index = 28,
    }, {
        Done = { 1954 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1954,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 1954,
        Zone = 1445,
        _index = 29,
    }, {
        Qpart = {
            [739] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 49.63, 66.31),
        IsQuestOnQuest = 739,
        Zone = 1418,
        _index = 30,
    }, {
        PickUp = { 1955 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1955,
        } },
        AnyOf = { {
            IsQuestCompleted = 1954,
        } },
        Class = { "MAGE" },
        MinLevel = 35,
        Zone = 1445,
        _index = 31,
    }, {
        Done = { 739 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 65.93, 65.62),
        RaidIcon = { {
            npcID = 1344,
            questID = 739,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 739,
        Zone = 1432,
        _index = 32,
    }, {
        Qpart = {
            [1955] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 45.79, 56.97),
        IsQuestOnQuest = 1955,
        Zone = 1445,
        _index = 33,
    }, {
        PickUp = { 704 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 65.93, 65.62),
        RaidIcon = { {
            npcID = 1344,
            questID = 704,
        } },
        AnyOf = { {
            IsQuestCompleted = 739,
        } },
        Faction = "Alliance",
        MinLevel = 30,
        Zone = 1432,
        _index = 34,
    }, {
        Done = { 1955 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1955,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 1955,
        Zone = 1445,
        _index = 35,
    }, {
        PickUp = { 1956 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1956,
        } },
        AnyOf = { {
            IsQuestCompleted = 1955,
        } },
        Class = { "MAGE" },
        MinLevel = 35,
        Zone = 1445,
        _index = 36,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_70",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 35.215, 9.966),
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        Zone = 1418,
        _index = 37,
    }, {
        PickUp = { 2278 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        MinLevel = 40,
        _index = 38,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Revelosh",
            npcID = 6910,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 39,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Baelog",
            npcID = 6906,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 40,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Ironaya",
            npcID = 7228,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 41,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Obsidian Sentinel",
            npcID = 7023,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 42,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Ancient Stone Keeper",
            npcID = 7206,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 43,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Galgann Firehammer",
            npcID = 7291,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 44,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Grimlok",
            npcID = 4854,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 45,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_70",
            name = "Archaedas",
            npcID = 2748,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        _index = 46,
    }, {
        Qpart = {
            [17] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 17,
        _index = 47,
    }, {
        Qpart = {
            [704] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 704,
        _index = 48,
    }, {
        Qpart = {
            [709] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 709,
        _index = 49,
    }, {
        Qpart = {
            [722] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 722,
        _index = 50,
    }, {
        Qpart = {
            [1360] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 1360,
        _index = 51,
    }, {
        Qpart = {
            [1956] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 1956,
        _index = 52,
    }, {
        PickUp = { 2198 },
        Button = {
            ["2198"] = 7666,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        Faction = "Alliance",
        ItemCount = {
            count = 1,
            itemID = 7666,
        },
        MinLevel = 37,
        _index = 53,
    }, {
        Qpart = {
            [2202] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2202,
        _index = 54,
    }, {
        Done = { 2398 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 6906,
            questID = 2398,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2398,
        _index = 55,
    }, {
        Qpart = {
            [2278] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2278,
        _index = 56,
    }, {
        Qpart = {
            [2283] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2283,
        _index = 57,
    }, {
        Qpart = {
            [2342] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2342,
        _index = 58,
    }, {
        Qpart = {
            [2418] = { 1, 2 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2418,
        _index = 59,
    }, {
        Qpart = {
            [2198] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2198,
        _index = 60,
    }, {
        PickUp = { 2240 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 6906,
            questID = 2240,
        } },
        AnyOf = { {
            IsQuestCompleted = 2398,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        _index = 61,
    }, {
        Done = { 2278 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2278,
        _index = 62,
    }, {
        Qpart = {
            [2240] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2240,
        _index = 63,
    }, {
        PickUp = { 2279 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2278,
        } },
        Faction = "Alliance",
        MinLevel = 40,
        _index = 64,
    }, {
        PickUp = { 2280 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2278,
        } },
        Faction = "Horde",
        MinLevel = 40,
        _index = 65,
    }, {
        Qpart = {
            [2279] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2279,
        _index = 66,
    }, {
        Qpart = {
            [2280] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2280,
        _index = 67,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_70",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        _index = 68,
    }, {
        Done = { 17 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 37.07, 49.38),
        RaidIcon = { {
            npcID = 1470,
            questID = 17,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 17,
        Zone = 1432,
        _index = 69,
    }, {
        Done = { 704 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1432, 65.93, 65.62),
        RaidIcon = { {
            npcID = 1344,
            questID = 704,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 704,
        Zone = 1432,
        _index = 70,
    }, {
        Done = { 709 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 51.39, 76.87),
        RaidIcon = { {
            npcID = 2785,
            questID = 709,
        } },
        IsQuestOnQuest = 709,
        Zone = 1418,
        _index = 71,
    }, {
        Done = { 722 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 37.9, 10.59),
        RaidIcon = { {
            npcID = 2909,
            questID = 722,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 722,
        Zone = 1418,
        _index = 72,
    }, {
        Done = { 1360 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 74.19, 9.39),
        RaidIcon = { {
            npcID = 6294,
            questID = 1360,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 1360,
        Zone = 1455,
        _index = 73,
    }, {
        Done = { 1956 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1956,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 1956,
        Zone = 1445,
        _index = 74,
    }, {
        Done = { 2198 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2198,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2198,
        Zone = 1455,
        _index = 75,
    }, {
        Done = { 2202 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2202,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2202,
        Zone = 1418,
        _index = 76,
    }, {
        Done = { 2240 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 74.64, 11.74),
        RaidIcon = { {
            npcID = 1356,
            questID = 2240,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2240,
        Zone = 1455,
        _index = 77,
    }, {
        Done = { 2279 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.93, 18.55),
        RaidIcon = { {
            npcID = 5387,
            questID = 2279,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2279,
        Zone = 1455,
        _index = 78,
    }, {
        Done = { 2280 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 34.4, 46.87),
        RaidIcon = { {
            npcID = 3978,
            questID = 2280,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2280,
        Zone = 1456,
        _index = 79,
    }, {
        Done = { 2283 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 59.49, 36.57),
        RaidIcon = { {
            npcID = 6986,
            questID = 2283,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2283,
        Zone = 1454,
        _index = 80,
    }, {
        Done = { 2342 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 62.32, 48.61),
        RaidIcon = { {
            npcID = 5651,
            questID = 2342,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2342,
        Zone = 1458,
        _index = 81,
    }, {
        Done = { 2418 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 42.39, 52.93),
        RaidIcon = { {
            npcID = 2817,
            questID = 2418,
        } },
        IsQuestOnQuest = 2418,
        Zone = 1418,
        _index = 82,
    }, {
        PickUp = { 723 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 37.9, 10.59),
        RaidIcon = { {
            npcID = 2909,
            questID = 723,
        } },
        AnyOf = { {
            IsQuestCompleted = 722,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1418,
        _index = 83,
    }, {
        PickUp = { 1957 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1957,
        } },
        AnyOf = { {
            IsQuestCompleted = 1956,
        } },
        Class = { "MAGE" },
        MinLevel = 35,
        Zone = 1445,
        _index = 84,
    }, {
        PickUp = { 2199 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2199,
        } },
        AnyOf = { {
            IsQuestCompleted = 2198,
        } },
        Faction = "Alliance",
        MinLevel = 37,
        Zone = 1455,
        _index = 85,
    }, {
        PickUp = { 2203 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2203,
        } },
        AnyOf = { {
            IsQuestCompleted = 2202,
        } },
        Faction = "Horde",
        MinLevel = 40,
        Zone = 1418,
        _index = 86,
    }, {
        PickUp = { 2284 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 59.49, 36.57),
        RaidIcon = { {
            npcID = 6986,
            questID = 2284,
        } },
        AnyOf = { {
            IsQuestCompleted = 2283,
        } },
        Faction = "Horde",
        MinLevel = 37,
        Zone = 1454,
        _index = 87,
    }, {
        PickUp = { 2439 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.93, 18.55),
        RaidIcon = { {
            npcID = 5387,
            questID = 2439,
        } },
        AnyOf = { {
            IsQuestCompleted = 2279,
        } },
        Faction = "Alliance",
        MinLevel = 40,
        Zone = 1455,
        _index = 88,
    }, {
        PickUp = { 2440 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 34.4, 46.87),
        RaidIcon = { {
            npcID = 3978,
            questID = 2440,
        } },
        AnyOf = { {
            IsQuestCompleted = 2280,
        } },
        Faction = "Horde",
        MinLevel = 40,
        Zone = 1456,
        _index = 89,
    }, {
        Qpart = {
            [723] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 723,
        _index = 90,
    }, {
        Qpart = {
            [1957] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 45.83, 56.94),
        IsQuestOnQuest = 1957,
        Zone = 1445,
        _index = 91,
    }, {
        Qpart = {
            [2203] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 84.68, 55.85),
        IsQuestOnQuest = 2203,
        Zone = 1418,
        _index = 92,
    }, {
        Qpart = {
            [2439] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 2439,
        _index = 93,
    }, {
        Qpart = {
            [2440] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 2440,
        _index = 94,
    }, {
        Done = { 723 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 53.42, 43.39),
        RaidIcon = { {
            npcID = 2910,
            questID = 723,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 723,
        Zone = 1418,
        _index = 95,
    }, {
        Done = { 1957 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1957,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 1957,
        Zone = 1445,
        _index = 96,
    }, {
        Done = { 2203 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2203,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2203,
        Zone = 1418,
        _index = 97,
    }, {
        Done = { 2439 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 33.88, 59.15),
        RaidIcon = { {
            npcID = 7292,
            questID = 2439,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2439,
        Zone = 1455,
        _index = 98,
    }, {
        Done = { 2440 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 46.62, 33.17),
        RaidIcon = { {
            npcID = 3009,
            questID = 2440,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2440,
        Zone = 1456,
        _index = 99,
    }, {
        PickUp = { 724 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 53.42, 43.39),
        RaidIcon = { {
            npcID = 2910,
            questID = 724,
        } },
        AnyOf = { {
            IsQuestCompleted = 723,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1418,
        _index = 100,
    }, {
        PickUp = { 1958 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1958,
        } },
        AnyOf = { {
            IsQuestCompleted = 1957,
        } },
        Class = { "MAGE" },
        MinLevel = 35,
        Zone = 1445,
        _index = 101,
    }, {
        PickUp = { 2963 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 69.93, 18.55),
        RaidIcon = { {
            npcID = 5387,
            questID = 2963,
        } },
        AnyOf = { {
            IsQuestCompleted = 2439,
        } },
        Faction = "Alliance",
        MinLevel = 45,
        Zone = 1455,
        _index = 102,
    }, {
        PickUp = { 2965 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 34.4, 46.87),
        RaidIcon = { {
            npcID = 3978,
            questID = 2965,
        } },
        AnyOf = { {
            IsQuestCompleted = 2440,
        } },
        Faction = "Horde",
        MinLevel = 45,
        Zone = 1456,
        _index = 103,
    }, {
        Qpart = {
            [724] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 724,
        _index = 104,
    }, {
        Done = { 1958 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
        RaidIcon = { {
            npcID = 6546,
            questID = 1958,
        } },
        Class = { "MAGE" },
        IsQuestOnQuest = 1958,
        Zone = 1445,
        _index = 105,
    }, {
        Done = { 2963 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.54, 11.82),
        RaidIcon = { {
            npcID = 2916,
            questID = 2963,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2963,
        Zone = 1455,
        _index = 106,
    }, {
        Done = { 2965 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 75.65, 31.61),
        RaidIcon = { {
            npcID = 5770,
            questID = 2965,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2965,
        Zone = 1456,
        _index = 107,
    }, {
        Done = { 724 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.54, 11.82),
        RaidIcon = { {
            npcID = 2916,
            questID = 724,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 724,
        Zone = 1455,
        _index = 108,
    }, {
        PickUp = { 2946 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.54, 11.82),
        RaidIcon = { {
            npcID = 2916,
            questID = 2946,
        } },
        AnyOf = { {
            IsQuestCompleted = 2963,
        } },
        Faction = "Alliance",
        MinLevel = 45,
        Zone = 1455,
        _index = 109,
    }, {
        PickUp = { 2966 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 75.65, 31.61),
        RaidIcon = { {
            npcID = 5770,
            questID = 2966,
        } },
        AnyOf = { {
            IsQuestCompleted = 2965,
        } },
        Faction = "Horde",
        MinLevel = 45,
        Zone = 1456,
        _index = 110,
    }, {
        PickUp = { 725 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.54, 11.82),
        RaidIcon = { {
            npcID = 2916,
            questID = 725,
        } },
        AnyOf = { {
            IsQuestCompleted = 724,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1455,
        _index = 111,
    }, {
        Qpart = {
            [2946] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 2946,
        _index = 112,
    }, {
        Qpart = {
            [2966] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 2966,
        _index = 113,
    }, {
        Qpart = {
            [725] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 725,
        _index = 114,
    }, {
        Done = { 2946 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 37.63, 81.4),
        Faction = "Alliance",
        IsQuestOnQuest = 2946,
        Zone = 1446,
        _index = 115,
    }, {
        Done = { 2966 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 37.63, 81.4),
        Faction = "Horde",
        IsQuestOnQuest = 2966,
        Zone = 1446,
        _index = 116,
    }, {
        Done = { 725 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.34, 9.71),
        RaidIcon = { {
            npcID = 2918,
            questID = 725,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 725,
        Zone = 1455,
        _index = 117,
    }, {
        PickUp = { 2954 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 37.6, 81.4),
        RaidIcon = { {
            npcID = 7918,
            questID = 2954,
        } },
        AnyOf = { {
            IsQuestCompleted = 2946,
        }, {
            IsQuestCompleted = 2966,
        } },
        MinLevel = 45,
        Zone = 1446,
        _index = 118,
    }, {
        PickUp = { 726 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.34, 9.71),
        RaidIcon = { {
            npcID = 2918,
            questID = 726,
        } },
        AnyOf = { {
            IsQuestCompleted = 725,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1455,
        _index = 119,
    }, {
        Qpart = {
            [2954] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 37.6, 81.4),
        IsQuestOnQuest = 2954,
        Zone = 1446,
        _index = 120,
    }, {
        Done = { 726 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.54, 11.82),
        RaidIcon = { {
            npcID = 2916,
            questID = 726,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 726,
        Zone = 1455,
        _index = 121,
    }, {
        Done = { 2954 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 37.63, 81.4),
        IsQuestOnQuest = 2954,
        Zone = 1446,
        _index = 122,
    }, {
        PickUp = { 762 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.54, 11.82),
        RaidIcon = { {
            npcID = 2916,
            questID = 762,
        } },
        AnyOf = { {
            IsQuestCompleted = 726,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1455,
        _index = 123,
    }, {
        Qpart = {
            [762] = { 1 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 42.1, 28.88),
        IsQuestOnQuest = 762,
        Zone = 1418,
        _index = 124,
    }, {
        Done = { 762 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.34, 9.71),
        RaidIcon = { {
            npcID = 2918,
            questID = 762,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 762,
        Zone = 1455,
        _index = 125,
    }, {
        PickUp = { 1139 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.34, 9.71),
        RaidIcon = { {
            npcID = 2918,
            questID = 1139,
        } },
        AnyOf = { {
            IsQuestCompleted = 762,
        } },
        Faction = "Alliance",
        MinLevel = 35,
        Zone = 1455,
        _index = 126,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_70",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 35.215, 9.966),
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        Zone = 1418,
        _index = 127,
    }, {
        Qpart = {
            [1139] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 1139,
        _index = 128,
    }, {
        Qpart = {
            [2199] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2199,
        _index = 129,
    }, {
        Done = { 2284 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 6912,
            questID = 2284,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2284,
        _index = 130,
    }, {
        PickUp = { 2318 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 6912,
            questID = 2318,
        } },
        AnyOf = { {
            IsQuestCompleted = 2284,
        } },
        Faction = "Horde",
        MinLevel = 37,
        _index = 131,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_70",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        _index = 132,
    }, {
        Done = { 1139 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 77.34, 9.71),
        RaidIcon = { {
            npcID = 2918,
            questID = 1139,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 1139,
        Zone = 1455,
        _index = 133,
    }, {
        Done = { 2199 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2199,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2199,
        Zone = 1455,
        _index = 134,
    }, {
        Done = { 2318 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2318,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2318,
        Zone = 1418,
        _index = 135,
    }, {
        PickUp = { 2200 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2200,
        } },
        AnyOf = { {
            IsQuestCompleted = 2199,
        } },
        Faction = "Alliance",
        MinLevel = 37,
        Zone = 1455,
        _index = 136,
    }, {
        PickUp = { 2338 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2338,
        } },
        AnyOf = { {
            IsQuestCompleted = 2318,
        } },
        Faction = "Horde",
        MinLevel = 37,
        Zone = 1418,
        _index = 137,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_70",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 35.215, 9.966),
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        Zone = 1418,
        _index = 138,
    }, {
        Done = { 2200 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 6912,
            questID = 2200,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2200,
        _index = 139,
    }, {
        Qpart = {
            [2338] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2338,
        _index = 140,
    }, {
        PickUp = { 2201 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 6912,
            questID = 2201,
        } },
        AnyOf = { {
            IsQuestCompleted = 2200,
        } },
        Faction = "Alliance",
        MinLevel = 37,
        _index = 141,
    }, {
        Qpart = {
            [2201] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2201,
        _index = 142,
    }, {
        Done = { 2201 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        Faction = "Alliance",
        IsQuestOnQuest = 2201,
        _index = 143,
    }, {
        PickUp = { 2204 },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        AnyOf = { {
            IsQuestCompleted = 2201,
        } },
        Faction = "Alliance",
        MinLevel = 37,
        _index = 144,
    }, {
        Qpart = {
            [2204] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2204,
        _index = 145,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_70",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        _index = 146,
    }, {
        Done = { 2204 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2204,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2204,
        Zone = 1455,
        _index = 147,
    }, {
        Done = { 2338 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2338,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2338,
        Zone = 1418,
        _index = 148,
    }, {
        PickUp = { 3375 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 3375,
        } },
        AnyOf = { {
            IsQuestCompleted = 2201,
        } },
        Faction = "Alliance",
        MinLevel = 37,
        Zone = 1455,
        _index = 149,
    }, {
        PickUp = { 2339 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2339,
        } },
        AnyOf = { {
            IsQuestCompleted = 2338,
        } },
        Faction = "Horde",
        MinLevel = 37,
        Zone = 1418,
        _index = 150,
    }, {
        PickUp = { 2361 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2361,
        } },
        AnyOf = { {
            IsQuestCompleted = 2204,
        } },
        Faction = "Alliance",
        MinLevel = 37,
        Zone = 1455,
        _index = 151,
    }, {
        Done = { 2361 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 2361,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2361,
        Zone = 1455,
        _index = 152,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_70",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 35.215, 9.966),
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        Zone = 1418,
        _index = 153,
    }, {
        Qpart = {
            [2339] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2339,
        _index = 154,
    }, {
        Qpart = {
            [3375] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 3375,
        _index = 155,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_70",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        _index = 156,
    }, {
        Done = { 2339 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2339,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2339,
        Zone = 1418,
        _index = 157,
    }, {
        Done = { 3375 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 36.38, 3.61),
        RaidIcon = { {
            npcID = 6826,
            questID = 3375,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 3375,
        Zone = 1455,
        _index = 158,
    }, {
        PickUp = { 2340 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2340,
        } },
        AnyOf = { {
            IsQuestCompleted = 2339,
        } },
        Faction = "Horde",
        MinLevel = 37,
        Zone = 1418,
        _index = 159,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_70",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 35.215, 9.966),
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        Zone = 1418,
        _index = 160,
    }, {
        Qpart = {
            [2340] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        InstanceQuest = true,
        IsQuestOnQuest = 2340,
        _index = 161,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_70",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_70",
        _index = 162,
    }, {
        Done = { 2340 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 59.49, 36.57),
        RaidIcon = { {
            npcID = 6986,
            questID = 2340,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2340,
        Zone = 1454,
        _index = 163,
    }, {
        PickUp = { 2341 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 59.49, 36.57),
        RaidIcon = { {
            npcID = 6986,
            questID = 2341,
        } },
        AnyOf = { {
            IsQuestCompleted = 2340,
        } },
        Faction = "Horde",
        MinLevel = 40,
        Zone = 1454,
        _index = 164,
    }, {
        Done = { 2341 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 2.42, 46.06),
        RaidIcon = { {
            npcID = 6868,
            questID = 2341,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 2341,
        Zone = 1418,
        _index = 165,
    }, {
        RouteCompleted = true,
        _index = 166,
    } },
}
