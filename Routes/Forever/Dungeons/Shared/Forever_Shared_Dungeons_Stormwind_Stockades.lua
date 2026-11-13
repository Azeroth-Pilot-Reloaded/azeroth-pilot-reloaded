local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Stormwind-Stockades"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 24,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Stormwind Stockades"],
    levelRange = {
        max = 32,
        min = 24,
    },
    mapID = 1453,
    steps = { {
        PickUp = { 303 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1437, 49.67, 18.23),
        RaidIcon = { {
            npcID = 1074,
            questID = 303,
        } },
        Faction = "Alliance",
        MinLevel = 25,
        Zone = 1437,
        _index = 1,
    }, {
        PickUp = { 373 },
        Button = {
            ["373"] = 2874,
        },
        NoArrow = true,
        Faction = "Alliance",
        ItemCount = {
            count = 1,
            itemID = 2874,
        },
        MinLevel = 16,
        _index = 2,
    }, {
        PickUp = { 377 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1431, 71.92, 47.79),
        RaidIcon = { {
            npcID = 270,
            questID = 377,
        } },
        Faction = "Alliance",
        MinLevel = 22,
        Zone = 1431,
        _index = 3,
    }, {
        PickUp = { 386 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1433, 21.17, 46.58),
        RaidIcon = { {
            npcID = 859,
            questID = 386,
        } },
        Faction = "Alliance",
        MinLevel = 22,
        Zone = 1433,
        _index = 4,
    }, {
        PickUp = { 387 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.49, 69.38),
        RaidIcon = { {
            npcID = 1719,
            questID = 387,
        } },
        Faction = "Alliance",
        MinLevel = 22,
        Zone = 1453,
        _index = 5,
    }, {
        PickUp = { 388 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 76.42, 63.67),
        RaidIcon = { {
            npcID = 1721,
            questID = 388,
        } },
        Faction = "Alliance",
        MinLevel = 22,
        Zone = 1453,
        _index = 6,
    }, {
        Qpart = {
            [303] = { 1, 2, 3, 4 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1437, 59.93, 23.02),
        IsQuestOnQuest = 303,
        Zone = 1437,
        _index = 7,
    }, {
        Qpart = {
            [373] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 373,
        _index = 8,
    }, {
        Done = { 303 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1437, 49.67, 18.23),
        RaidIcon = { {
            npcID = 1074,
            questID = 303,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 303,
        Zone = 1437,
        _index = 9,
    }, {
        Done = { 373 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 57.74, 47.86),
        RaidIcon = { {
            npcID = 1646,
            questID = 373,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 373,
        Zone = 1453,
        _index = 10,
    }, {
        PickUp = { 389 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 57.74, 47.86),
        RaidIcon = { {
            npcID = 1646,
            questID = 389,
        } },
        AnyOf = { {
            IsQuestCompleted = 373,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 11,
    }, {
        PickUp = { 378 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1437, 49.67, 18.23),
        RaidIcon = { {
            npcID = 1074,
            questID = 378,
        } },
        AnyOf = { {
            IsQuestCompleted = 303,
        } },
        Faction = "Alliance",
        MinLevel = 22,
        Zone = 1437,
        _index = 12,
    }, {
        Done = { 389 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.49, 69.38),
        RaidIcon = { {
            npcID = 1719,
            questID = 389,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 389,
        Zone = 1453,
        _index = 13,
    }, {
        PickUp = { 391 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.49, 69.38),
        RaidIcon = { {
            npcID = 1719,
            questID = 391,
        } },
        AnyOf = { {
            IsQuestCompleted = 389,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 14,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_34",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 50.3, 66.1),
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        Zone = 1453,
        _index = 15,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_34",
            name = "Targorr the Dread",
            npcID = 1696,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        _index = 16,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_34",
            name = "Kam Deepfury",
            npcID = 1666,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        _index = 17,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_34",
            name = "Hamhock",
            npcID = 1717,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        _index = 18,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_34",
            name = "Dextren Ward",
            npcID = 1663,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        _index = 19,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_34",
            name = "Bazil Thredd",
            npcID = 1716,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        _index = 20,
    }, {
        Qpart = {
            [391] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        IsQuestOnQuest = 391,
        _index = 21,
    }, {
        Qpart = {
            [377] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        IsQuestOnQuest = 377,
        _index = 22,
    }, {
        Qpart = {
            [378] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        IsQuestOnQuest = 378,
        _index = 23,
    }, {
        Qpart = {
            [386] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        IsQuestOnQuest = 386,
        _index = 24,
    }, {
        Qpart = {
            [387] = { 1, 2, 3 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        IsQuestOnQuest = 387,
        _index = 25,
    }, {
        Qpart = {
            [388] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        InstanceQuest = true,
        IsQuestOnQuest = 388,
        _index = 26,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_34",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_34",
        _index = 27,
    }, {
        Done = { 391 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.49, 69.38),
        RaidIcon = { {
            npcID = 1719,
            questID = 391,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 391,
        Zone = 1453,
        _index = 28,
    }, {
        Done = { 377 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1431, 71.92, 47.79),
        RaidIcon = { {
            npcID = 270,
            questID = 377,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 377,
        Zone = 1431,
        _index = 29,
    }, {
        Done = { 378 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1437, 49.67, 18.23),
        RaidIcon = { {
            npcID = 1074,
            questID = 378,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 378,
        Zone = 1437,
        _index = 30,
    }, {
        Done = { 386 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1433, 21.17, 46.58),
        RaidIcon = { {
            npcID = 859,
            questID = 386,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 386,
        Zone = 1433,
        _index = 31,
    }, {
        Done = { 387 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.49, 69.38),
        RaidIcon = { {
            npcID = 1719,
            questID = 387,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 387,
        Zone = 1453,
        _index = 32,
    }, {
        Done = { 388 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 76.42, 63.67),
        RaidIcon = { {
            npcID = 1721,
            questID = 388,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 388,
        Zone = 1453,
        _index = 33,
    }, {
        PickUp = { 392 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.49, 69.38),
        RaidIcon = { {
            npcID = 1719,
            questID = 392,
        } },
        AnyOf = { {
            IsQuestCompleted = 391,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 34,
    }, {
        Qpart = {
            [392] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 392,
        _index = 35,
    }, {
        Done = { 392 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 57.74, 47.86),
        RaidIcon = { {
            npcID = 1646,
            questID = 392,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 392,
        Zone = 1453,
        _index = 36,
    }, {
        PickUp = { 393 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 57.74, 47.86),
        RaidIcon = { {
            npcID = 1646,
            questID = 393,
        } },
        AnyOf = { {
            IsQuestCompleted = 392,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 37,
    }, {
        Qpart = {
            [393] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 393,
        _index = 38,
    }, {
        Done = { 393 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 78.31, 70.74),
        RaidIcon = { {
            npcID = 332,
            questID = 393,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 393,
        Zone = 1453,
        _index = 39,
    }, {
        PickUp = { 350 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 78.31, 70.74),
        RaidIcon = { {
            npcID = 332,
            questID = 350,
        } },
        AnyOf = { {
            IsQuestCompleted = 393,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 40,
    }, {
        Done = { 350 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 66.03, 74.1),
        RaidIcon = { {
            npcID = 482,
            questID = 350,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 350,
        Zone = 1453,
        _index = 41,
    }, {
        PickUp = { 2745 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 66.03, 74.1),
        RaidIcon = { {
            npcID = 482,
            questID = 2745,
        } },
        AnyOf = { {
            IsQuestCompleted = 350,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 42,
    }, {
        Done = { 2745 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 73.23, 35.58),
        RaidIcon = { {
            npcID = 7766,
            questID = 2745,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2745,
        Zone = 1453,
        _index = 43,
    }, {
        PickUp = { 2746 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 73.23, 35.58),
        RaidIcon = { {
            npcID = 7766,
            questID = 2746,
        } },
        AnyOf = { {
            IsQuestCompleted = 2745,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 44,
    }, {
        Qpart = {
            [2746] = { 1, 2 },
        },
        NoArrow = true,
        IsQuestOnQuest = 2746,
        _index = 45,
    }, {
        Done = { 2746 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 73.23, 35.58),
        RaidIcon = { {
            npcID = 7766,
            questID = 2746,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 2746,
        Zone = 1453,
        _index = 46,
    }, {
        PickUp = { 434 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 73.23, 35.58),
        RaidIcon = { {
            npcID = 7766,
            questID = 434,
        } },
        AnyOf = { {
            IsQuestCompleted = 2746,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 47,
    }, {
        Qpart = {
            [434] = { 1, 2 },
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 72.36, 35.12),
        IsQuestOnQuest = 434,
        Zone = 1453,
        _index = 48,
    }, {
        Done = { 434 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 66.03, 74.1),
        RaidIcon = { {
            npcID = 482,
            questID = 434,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 434,
        Zone = 1453,
        _index = 49,
    }, {
        PickUp = { 394 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 66.03, 74.1),
        RaidIcon = { {
            npcID = 482,
            questID = 394,
        } },
        AnyOf = { {
            IsQuestCompleted = 434,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 50,
    }, {
        Done = { 394 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 78.31, 70.74),
        RaidIcon = { {
            npcID = 332,
            questID = 394,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 394,
        Zone = 1453,
        _index = 51,
    }, {
        PickUp = { 395 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 78.31, 70.74),
        RaidIcon = { {
            npcID = 332,
            questID = 395,
        } },
        AnyOf = { {
            IsQuestCompleted = 394,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 52,
    }, {
        Done = { 395 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 57.74, 47.86),
        RaidIcon = { {
            npcID = 1646,
            questID = 395,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 395,
        Zone = 1453,
        _index = 53,
    }, {
        PickUp = { 396 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 57.74, 47.86),
        RaidIcon = { {
            npcID = 1646,
            questID = 396,
        } },
        AnyOf = { {
            IsQuestCompleted = 395,
        } },
        Faction = "Alliance",
        MinLevel = 16,
        Zone = 1453,
        _index = 54,
    }, {
        Qpart = {
            [396] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 396,
        _index = 55,
    }, {
        Done = { 396 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.1, 38.17),
        RaidIcon = { {
            npcID = 1749,
            questID = 396,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 396,
        Zone = 1453,
        _index = 56,
    }, {
        RouteCompleted = true,
        _index = 57,
    } },
}
