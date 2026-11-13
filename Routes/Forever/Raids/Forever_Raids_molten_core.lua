local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-molten-core"] = {
    label = L["FOREVER_RAID_MOLTEN_CORE"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1427,
    conditions = {
        MinLevel = 60,
    },
    levelRange = {
        min = 60,
    },
    autoStartOnMap = false,
    steps = { {
            EnterInstance = {
                dungeonKey = "INSTANCE_409",
            },
            Note = { "FOREVER_RAID_CORE_RUNES", "FOREVER_RAID_BLACKROCK_ENTRY" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1427,34.8,85.3),
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            Zone = 1427,
            _index = 1,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 12118,
                name = "Lucifron",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 2,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 11982,
                name = "Magmadar",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 3,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 12259,
                name = "Gehennas",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 4,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 12057,
                name = "Garr",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 5,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 12264,
                name = "Shazzrah",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 6,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 12056,
                name = "Baron Geddon",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 7,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 12098,
                name = "Sulfuron Harbinger",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 8,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 11988,
                name = "Golemagg the Incinerator",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 9,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 12018,
                name = "Majordomo Executus",
            },
            Note = { "FOREVER_RAID_CORE_RUNES", "MANUAL_SKIP" },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 10,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_409",
                npcID = 11502,
                name = "Ragnaros",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 11,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_409",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            _index = 12,
        }, {
            Done = { 6642 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6642,
            IsQuestReadyForTurnIn = 6642,
            _index = 13,
        }, {
            Done = { 6643 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6643,
            IsQuestReadyForTurnIn = 6643,
            _index = 14,
        }, {
            Done = { 6644 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6644,
            IsQuestReadyForTurnIn = 6644,
            _index = 15,
        }, {
            Done = { 6645 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6645,
            IsQuestReadyForTurnIn = 6645,
            _index = 16,
        }, {
            Done = { 6646 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6646,
            IsQuestReadyForTurnIn = 6646,
            _index = 17,
        }, {
            Done = { 6822 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6822,
            IsQuestReadyForTurnIn = 6822,
            Zone = 1447,
            _index = 18,
        }, {
            Done = { 6824 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6824,
            IsQuestReadyForTurnIn = 6824,
            Zone = 1447,
            _index = 19,
        }, {
            Done = { 7521 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 7521,
            IsQuestReadyForTurnIn = 7521,
            _index = 20,
        }, {
            Done = { 7632 },
            Coord = {
                x = -1106.8,
                y = 6209.5,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7632,
            IsQuestReadyForTurnIn = 7632,
            Zone = 1448,
            _index = 21,
        }, {
            Done = { 7786 },
            Coord = {
                x = 1779.0,
                y = -6156.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7786,
            IsQuestReadyForTurnIn = 7786,
            Zone = 1444,
            _index = 22,
        }, {
            Done = { 7848 },
            Coord = {
                x = -1039.1,
                y = -7508.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7848,
            IsQuestReadyForTurnIn = 7848,
            Zone = 1427,
            _index = 23,
        }, {
            Done = { 8578 },
            Coord = {
                x = -4717.6,
                y = -6730.6,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8578,
            IsQuestReadyForTurnIn = 8578,
            Zone = 1446,
            _index = 24,
        }, {
            RouteCompleted = true,
            _index = 25,
        } },
}
