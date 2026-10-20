local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Ruins-of-Lordaeron"] = {
    label = L["Forever - Dungeon - Ruins of Lordaeron"] .. " (17-19)",
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1411,
    conditions = {  },
    steps = {
        {
            EnterInstance = { dungeonKey = "ROL" },
            Coord = { x = 188.4, y = 1804.5 },
            Dungeon = "ROL",
            InstanceQuest = true,
            Zone = 1458,
            _index = 1,
        },
        {
            KillNPC = { dungeonKey = "ROL", npcID = 250483, name = "Witherfang" },
            NoArrow = true,
            Dungeon = "ROL",
            InstanceQuest = true,
            _index = 2,
        },
        {
            KillNPC = { dungeonKey = "ROL", npcID = 250660, name = "The Baron" },
            NoArrow = true,
            Dungeon = "ROL",
            InstanceQuest = true,
            _index = 3,
        },
        {
            KillNPC = { dungeonKey = "ROL", npcID = 250657, name = "Rath'mael" },
            NoArrow = true,
            Dungeon = "ROL",
            InstanceQuest = true,
            _index = 4,
        },
        {
            LeaveInstance = { dungeonKey = "ROL" },
            NoArrow = true,
            Dungeon = "ROL",
            InstanceQuest = true,
            _index = 5,
        },
        {
            RouteCompleted = true,
            _index = 6,
        },
    },
}
