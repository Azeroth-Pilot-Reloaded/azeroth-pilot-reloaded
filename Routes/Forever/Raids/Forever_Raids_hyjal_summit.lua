local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-hyjal-summit"] = {
    label = L["FOREVER_RAID_HYJAL_SUMMIT"],
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
                dungeonKey = "INSTANCE_2981",
            },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(2482,89,32),
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            Zone = 2482,
            _index = 1,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 249790,
                name = "Bandalar",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 2,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250076,
                name = "Ancient of Decay",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 3,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 257638,
                name = "Sylvestris Dusksong",
            },
            Note = { "FOREVER_RAID_TIME_LOST_BATTALION" },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 4,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250070,
                name = "Old Gloomlurker",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 5,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250075,
                name = "Gharalis the Abyssal",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 6,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250077,
                name = "Kathris the Haunted",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 7,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 249787,
                name = "Anara Chillwind",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 8,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 253861,
                name = "Elder Minderel",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 9,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250074,
                name = "Tracker Stillwind",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 10,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250082,
                name = "Council of Thorns",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 11,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250078,
                name = "Nythus the Dreambound",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 12,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_2981",
                npcID = 250079,
                name = "The Wild King",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 13,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_2981",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_2981",
            InstanceQuest = true,
            _index = 14,
        }, {
            RouteCompleted = true,
            _index = 15,
        } },
}
