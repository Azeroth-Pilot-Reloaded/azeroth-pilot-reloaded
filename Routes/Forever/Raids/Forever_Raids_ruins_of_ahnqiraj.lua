local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-ruins-of-ahnqiraj"] = {
    label = L["FOREVER_RAID_RUINS_OF_AHNQIRAJ"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1451,
    conditions = {
        MinLevel = 60,
    },
    levelRange = {
        min = 60,
    },
    autoStartOnMap = false,
    steps = { {
            EnterInstance = {
                dungeonKey = "INSTANCE_509",
            },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451,28.6,92.3),
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            Zone = 1451,
            _index = 1,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_509",
                npcID = 15348,
                name = "Kurinnaxx",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            _index = 2,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_509",
                npcID = 15341,
                name = "General Rajaxx",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            _index = 3,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_509",
                npcID = 15340,
                name = "Moam",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            _index = 4,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_509",
                npcID = 15370,
                name = "Buru the Gorger",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            _index = 5,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_509",
                npcID = 15369,
                name = "Ayamiss the Hunter",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            _index = 6,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_509",
                npcID = 15339,
                name = "Ossirian the Unscarred",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            _index = 7,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_509",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_509",
            InstanceQuest = true,
            _index = 8,
        }, {
            Done = { 8764 },
            Coord = {
                x = -4724.4,
                y = -8175.0,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8764,
            IsQuestReadyForTurnIn = 8764,
            Zone = 1446,
            _index = 9,
        }, {
            Done = { 8765 },
            Coord = {
                x = -4724.4,
                y = -8175.0,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8765,
            IsQuestReadyForTurnIn = 8765,
            Zone = 1446,
            _index = 10,
        }, {
            Done = { 8766 },
            Coord = {
                x = -4724.4,
                y = -8175.0,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8766,
            IsQuestReadyForTurnIn = 8766,
            Zone = 1446,
            _index = 11,
        }, {
            Done = { 8791 },
            Coord = {
                x = 823.7,
                y = -6752.8,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8791,
            IsQuestReadyForTurnIn = 8791,
            Zone = 1451,
            _index = 12,
        }, {
            Done = { 9023 },
            Coord = {
                x = 722.7,
                y = -6866.6,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 9023,
            IsQuestReadyForTurnIn = 9023,
            Zone = 1451,
            _index = 13,
        }, {
            RouteCompleted = true,
            _index = 14,
        } },
}
