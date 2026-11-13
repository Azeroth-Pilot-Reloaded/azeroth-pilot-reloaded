local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Alcaz-Prison"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 48,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Alcaz Prison"],
    levelRange = {
        max = 55,
        min = 48,
    },
    mapID = 1445,
    steps = { {
        EnterInstance = {
            dungeonKey = "ALCAZ_PRISON",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 75.3, 14.1),
        Dungeon = "ALCAZ_PRISON",
        InstanceQuest = true,
        Zone = 1445,
        _index = 1,
    }, {
        KillNPC = {
            dungeonKey = "ALCAZ_PRISON",
            name = "Tidemistress Ca'zass",
            npcID = 255997,
        },
        NoArrow = true,
        Dungeon = "ALCAZ_PRISON",
        InstanceQuest = true,
        _index = 2,
    }, {
        KillNPC = {
            dungeonKey = "ALCAZ_PRISON",
            name = "Katerina the Cleaner",
            npcID = 257016,
        },
        NoArrow = true,
        Dungeon = "ALCAZ_PRISON",
        InstanceQuest = true,
        _index = 3,
    }, {
        KillNPC = {
            dungeonKey = "ALCAZ_PRISON",
            name = "The Questioner",
            npcID = 256236,
        },
        NoArrow = true,
        Dungeon = "ALCAZ_PRISON",
        InstanceQuest = true,
        _index = 4,
    }, {
        KillNPC = {
            dungeonKey = "ALCAZ_PRISON",
            name = "Blazeroar",
            npcID = 255702,
        },
        NoArrow = true,
        Dungeon = "ALCAZ_PRISON",
        InstanceQuest = true,
        _index = 5,
    }, {
        LeaveInstance = {
            dungeonKey = "ALCAZ_PRISON",
        },
        NoArrow = true,
        Dungeon = "ALCAZ_PRISON",
        _index = 6,
    }, {
        RouteCompleted = true,
        _index = 7,
    } },
}
