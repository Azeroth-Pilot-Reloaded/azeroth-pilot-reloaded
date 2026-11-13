local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Shaper-s-Terrace"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 58,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Shaper's Terrace"],
    levelRange = {
        max = 60,
        min = 58,
    },
    mapID = 0,
    steps = { {
        EnterInstance = {
            dungeonKey = "SHAPERS_TERRACE",
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 1,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Titanosaur",
            npcID = 253201,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 2,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Thunderhoof",
            npcID = 261812,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 3,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Venomridge",
            npcID = 261813,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 4,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Direhorn Matriarch",
            npcID = 262127,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 5,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Cinder",
            npcID = 261974,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 6,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Snowtalon",
            npcID = 262297,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 7,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Bolt",
            npcID = 262081,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 8,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Vitrix",
            npcID = 272561,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 9,
    }, {
        KillNPC = {
            dungeonKey = "SHAPERS_TERRACE",
            name = "Nanaya",
            npcID = 261809,
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        InstanceQuest = true,
        _index = 10,
    }, {
        LeaveInstance = {
            dungeonKey = "SHAPERS_TERRACE",
        },
        NoArrow = true,
        Dungeon = "SHAPERS_TERRACE",
        _index = 11,
    }, {
        RouteCompleted = true,
        _index = 12,
    } },
}
