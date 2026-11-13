local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-barrow-deeps"] = {
    label = L["FOREVER_RAID_BARROW_DEEPS"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 2482,
    conditions = {
        MinLevel = 60,
    },
    levelRange = {
        min = 60,
    },
    autoStartOnMap = false,
    steps = { {
            EnterInstance = {
                dungeonKey = "INSTANCE_3052",
            },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(2482,70,62),
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            Zone = 2482,
            _index = 1,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259867,
                name = "Chillhowl",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 2,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259902,
                name = "Khalith the Dreadspinner",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 3,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259907,
                name = "Amethrax",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 4,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259905,
                name = "Ravus and Darlissa",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 5,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259904,
                name = "Elder Tangleclaw",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 6,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259866,
                name = "Well of Sorrow",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 7,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259911,
                name = "Del'lynar Songwood",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 8,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_3052",
                npcID = 259912,
                name = "Sonya Darkhallow",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 9,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_3052",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_3052",
            InstanceQuest = true,
            _index = 10,
        }, {
            RouteCompleted = true,
            _index = 11,
        } },
}
