local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Wailing-Caverns"] = {
    label = L["Forever - Dungeon - Wailing Caverns"] .. " (21-22)",
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1414,
    conditions = {  },
    parallelSteps = {
        {
            conditions = { ItemCount = { itemID = 10441, count = 1 }, IsQuestNotOnQuest = 6981, IsQuestUncompleted = 6981 },
            steps = {
                {
                    DropQuest = 6981,
                    DroppableQuest = { Qid = 6981, MobId = 3654, Text = "Mutanus the Devourer" },
                    NoArrow = true,
                    Dungeon = "WC",
                    InstanceQuest = true,
                    _index = 1,
                },
            },
        },
    },
    steps = {
        {
            EnterInstance = { dungeonKey = "WC" },
            Note = { "ENTER_WC_INSTANCE_PORTAL_ZONE" },
            Coord = { x = -2216.5, y = -742.43 },
            Range = 30.0,
            Dungeon = "WC",
            InstanceQuest = true,
            Zone = 1414,
            _index = 1,
        },
        {
            KillNPC = { dungeonKey = "WC", npcID = 3671, name = "Lady Anacondra" },
            Fillers = { [1491] = { 1 }, [1487] = { 1, 2, 3, 4 }, [1486] = { 1 } },
            NoArrow = true,
            Dungeon = "WC",
            InstanceQuest = true,
            _index = 2,
        },
        {
            KillNPC = { dungeonKey = "WC", npcID = 3669, name = "Lord Cobrahn" },
            Fillers = { [1491] = { 1 }, [1487] = { 1, 2, 3, 4 }, [1486] = { 1 } },
            NoArrow = true,
            Dungeon = "WC",
            InstanceQuest = true,
            _index = 3,
        },
        {
            KillNPC = { dungeonKey = "WC", npcID = 3670, name = "Lord Pythas" },
            Fillers = { [1491] = { 1 }, [1487] = { 1, 2, 3, 4 }, [1486] = { 1 } },
            NoArrow = true,
            Dungeon = "WC",
            InstanceQuest = true,
            _index = 4,
        },
        {
            KillNPC = { dungeonKey = "WC", npcID = 3673, name = "Lord Serpentis" },
            Fillers = { [1491] = { 1 }, [1487] = { 1, 2, 3, 4 }, [1486] = { 1 } },
            NoArrow = true,
            Dungeon = "WC",
            InstanceQuest = true,
            _index = 5,
        },
        {
            KillNPC = { dungeonKey = "WC", npcID = 5775, name = "Verdan the Everliving" },
            Fillers = { [1491] = { 1 }, [1487] = { 1, 2, 3, 4 }, [1486] = { 1 } },
            NoArrow = true,
            Dungeon = "WC",
            InstanceQuest = true,
            _index = 6,
        },
        {
            KillNPC = { dungeonKey = "WC", npcID = 3654, name = "Mutanus the Devourer" },
            Fillers = { [1491] = { 1 }, [1487] = { 1, 2, 3, 4 }, [1486] = { 1 } },
            Note = { "ESCORT_TALK_DISCIPLE_NARALEX_ENTRANCE_WAILING", "REACHED_NARALEX_GET_ATTACK_TWO_WAVES_ENEMIES" },
            NoArrow = true,
            Dungeon = "WC",
            InstanceQuest = true,
            _index = 7,
        },
        {
            LeaveInstance = { dungeonKey = "WC" },
            NoArrow = true,
            Dungeon = "WC",
            InstanceQuest = true,
            _index = 8,
        },
        {
            RouteCompleted = true,
            _index = 9,
        },
    },
}
