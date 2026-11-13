local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Blackmaw-Hold"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 55,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Blackmaw Hold"],
    levelRange = {
        max = 60,
        min = 55,
    },
    mapID = 0,
    steps = { {
        EnterInstance = {
            dungeonKey = "BLACKMAW_HOLD",
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 1,
    }, {
        KillNPC = {
            dungeonKey = "BLACKMAW_HOLD",
            name = "Withermaw",
            npcID = 247195,
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 2,
    }, {
        KillNPC = {
            dungeonKey = "BLACKMAW_HOLD",
            name = "Impaan the Imprisoner",
            npcID = 247206,
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 3,
    }, {
        KillNPC = {
            dungeonKey = "BLACKMAW_HOLD",
            name = "Elder Shaman Bloodmane",
            npcID = 247209,
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 4,
    }, {
        KillNPC = {
            dungeonKey = "BLACKMAW_HOLD",
            name = "Bonesnout the Unbroken",
            npcID = 247198,
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 5,
    }, {
        KillNPC = {
            dungeonKey = "BLACKMAW_HOLD",
            name = "Varrox Bleakhoof",
            npcID = 247234,
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 6,
    }, {
        KillNPC = {
            dungeonKey = "BLACKMAW_HOLD",
            name = "Blackmaw Behemoth",
            npcID = 247207,
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 7,
    }, {
        KillNPC = {
            dungeonKey = "BLACKMAW_HOLD",
            name = "Unbound Spirit",
            npcID = 247231,
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        InstanceQuest = true,
        _index = 8,
    }, {
        LeaveInstance = {
            dungeonKey = "BLACKMAW_HOLD",
        },
        NoArrow = true,
        Dungeon = "BLACKMAW_HOLD",
        _index = 9,
    }, {
        RouteCompleted = true,
        _index = 10,
    } },
}
