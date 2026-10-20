local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Hall-of-Thanes"] = {
    label = L["Forever - Dungeon - Hall of Thanes"] .. " (16-18)",
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1455,
    conditions = {  },
    steps = {
        {
            EnterInstance = { dungeonKey = "HOT" },
            Coord = { x = -933.2, y = -4821.9 },
            Dungeon = "HOT",
            InstanceQuest = true,
            Zone = 1455,
            _index = 1,
        },
        {
            KillNPC = { dungeonKey = "HOT", npcID = 261306, name = "Faldrim Anvilmar" },
            NoArrow = true,
            Dungeon = "HOT",
            InstanceQuest = true,
            RaidIcon = 261306,
            _index = 2,
        },
        {
            KillNPC = { dungeonKey = "HOT", npcID = 261319, name = "Durgen Dirgehammer" },
            NoArrow = true,
            Dungeon = "HOT",
            InstanceQuest = true,
            RaidIcon = 261319,
            _index = 3,
        },
        {
            LeaveInstance = { dungeonKey = "HOT" },
            Note = { "Exit the Hall of Thanes. Fastest way is running straight down the corridor from the final boss room" },
            NoArrow = true,
            Dungeon = "HOT",
            InstanceQuest = true,
            _index = 4,
        },
        {
            RouteCompleted = true,
            _index = 5,
        },
    },
}
