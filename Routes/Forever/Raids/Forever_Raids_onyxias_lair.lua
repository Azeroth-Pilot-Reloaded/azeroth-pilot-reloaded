local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-onyxias-lair"] = {
    label = L["FOREVER_RAID_ONYXIAS_LAIR"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1445,
    conditions = {
        MinLevel = 60,
        AnyOf = { {
                ItemCount = {
                    itemID = 16309,
                    count = 1,
                },
            } },
    },
    levelRange = {
        min = 60,
    },
    autoStartOnMap = false,
    steps = { {
            EnterInstance = {
                dungeonKey = "INSTANCE_249",
            },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445,52.6,76.8),
            Dungeon = "INSTANCE_249",
            InstanceQuest = true,
            Zone = 1445,
            _index = 1,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_249",
                npcID = 10184,
                name = "Onyxia",
            },
            Fillers = {
                [7509] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            Dungeon = "INSTANCE_249",
            InstanceQuest = true,
            _index = 2,
        }, {
            Qpart = {
                [7509] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            Dungeon = "INSTANCE_249",
            InstanceQuest = true,
            IsQuestOnQuest = 7509,
            _index = 3,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_249",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_249",
            InstanceQuest = true,
            _index = 4,
        }, {
            PickUp = { 7490 },
            Button = {
                ["7490"] = 18422,
            },
            NoArrow = true,
            InstanceQuest = true,
            Faction = "Horde",
            IsQuestUncompleted = 7490,
            ItemCount = {
                itemID = 18422,
                count = 1,
            },
            _index = 5,
        }, {
            Done = { 7490 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7490,
            Zone = 1454,
            _index = 6,
        }, {
            PickUp = { 7495 },
            Button = {
                ["7495"] = 18423,
            },
            NoArrow = true,
            InstanceQuest = true,
            Faction = "Alliance",
            IsQuestUncompleted = 7495,
            ItemCount = {
                itemID = 18423,
                count = 1,
            },
            _index = 7,
        }, {
            Done = { 7495 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453,80.2,38.4),
            InstanceQuest = true,
            IsQuestOnQuest = 7495,
            Zone = 1453,
            _index = 8,
        }, {
            Done = { 7509 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 7509,
            IsQuestReadyForTurnIn = 7509,
            _index = 9,
        }, {
            Done = { 7635 },
            Coord = {
                x = -1141.3,
                y = 6278.5,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7635,
            IsQuestReadyForTurnIn = 7635,
            Zone = 1448,
            _index = 10,
        }, {
            RouteCompleted = true,
            _index = 11,
        } },
}
