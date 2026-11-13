local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-blackwing-lair"] = {
    label = L["FOREVER_RAID_BLACKWING_LAIR"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1428,
    conditions = {
        MinLevel = 60,
    },
    levelRange = {
        min = 60,
    },
    autoStartOnMap = false,
    steps = { {
            EnterInstance = {
                dungeonKey = "INSTANCE_469",
            },
            Note = { "FOREVER_RAID_BLACKROCK_ENTRY" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428,29.4,38.3),
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            Zone = 1428,
            _index = 1,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 12435,
                name = "Razorgore the Untamed",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 2,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 13020,
                name = "Vaelastrasz the Corrupt",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 3,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 12017,
                name = "Broodlord Lashlayer",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 4,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 11983,
                name = "Firemaw",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 5,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 14601,
                name = "Ebonroc",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 6,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 11981,
                name = "Flamegor",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 7,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 14020,
                name = "Chromaggus",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 8,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_469",
                npcID = 11583,
                name = "Nefarian",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 9,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_469",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_469",
            InstanceQuest = true,
            _index = 10,
        }, {
            PickUp = { 7781 },
            Button = {
                ["7781"] = 19003,
            },
            NoArrow = true,
            InstanceQuest = true,
            Faction = "Alliance",
            IsQuestUncompleted = 7781,
            ItemCount = {
                itemID = 19003,
                count = 1,
            },
            _index = 11,
        }, {
            Done = { 7781 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453,80.2,38.4),
            InstanceQuest = true,
            IsQuestOnQuest = 7781,
            Zone = 1453,
            _index = 12,
        }, {
            PickUp = { 7783 },
            Button = {
                ["7783"] = 19002,
            },
            NoArrow = true,
            InstanceQuest = true,
            Faction = "Horde",
            IsQuestUncompleted = 7783,
            ItemCount = {
                itemID = 19002,
                count = 1,
            },
            _index = 13,
        }, {
            Done = { 7783 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7783,
            Zone = 1454,
            _index = 14,
        }, {
            Done = { 7782 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453,71.5,80.5),
            InstanceQuest = true,
            IsQuestOnQuest = 7782,
            IsQuestReadyForTurnIn = 7782,
            Zone = 1453,
            _index = 15,
        }, {
            Done = { 7784 },
            Coord = {
                x = -4395.9,
                y = 1565.8,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7784,
            IsQuestReadyForTurnIn = 7784,
            Zone = 1454,
            _index = 16,
        }, {
            Done = { 8288 },
            Coord = {
                x = 815.0,
                y = -6805.0,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8288,
            IsQuestReadyForTurnIn = 8288,
            Zone = 1451,
            _index = 17,
        }, {
            Done = { 8728 },
            Coord = {
                x = -4717.6,
                y = -6730.6,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8728,
            IsQuestReadyForTurnIn = 8728,
            Zone = 1446,
            _index = 18,
        }, {
            Done = { 8730 },
            Coord = {
                x = -4724.4,
                y = -8175.0,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 8730,
            IsQuestReadyForTurnIn = 8730,
            Zone = 1446,
            _index = 19,
        }, {
            RouteCompleted = true,
            _index = 20,
        } },
}
