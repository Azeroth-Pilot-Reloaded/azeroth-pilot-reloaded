local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Ragefire-Chasm"] = {
    label = L["Forever - Dungeon - Ragefire Chasm"] .. " (16-17)",
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1414,
    conditions = {  },
    steps = {
        {
            EnterInstance = { dungeonKey = "RFC" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 52.77, 48.97),
            Dungeon = "RFC",
            InstanceQuest = true,
            Zone = 1454,
            _index = 1,
        },
        {
            KillNPC = { dungeonKey = "RFC", npcID = 11517, name = "Oggleflint" },
            NoArrow = true,
            Dungeon = "RFC",
            InstanceQuest = true,
            RaidIcon = 11517,
            _index = 2,
        },
        {
            KillNPC = { dungeonKey = "RFC", npcID = 11520, name = "Taragaman the Hungerer" },
            NoArrow = true,
            Dungeon = "RFC",
            InstanceQuest = true,
            RaidIcon = 11520,
            _index = 3,
        },
        {
            KillNPC = { dungeonKey = "RFC", npcID = 11518, name = "Jergosh the Invoker" },
            NoArrow = true,
            Dungeon = "RFC",
            InstanceQuest = true,
            RaidIcon = 11518,
            _index = 4,
        },
        {
            KillNPC = { dungeonKey = "RFC", npcID = 11519, name = "Bazzalan" },
            NoArrow = true,
            Dungeon = "RFC",
            InstanceQuest = true,
            RaidIcon = 11519,
            _index = 5,
        },
        {
            LeaveInstance = { dungeonKey = "RFC" },
            NoArrow = true,
            Dungeon = "RFC",
            InstanceQuest = true,
            _index = 6,
        },
        {
            RouteCompleted = true,
            _index = 7,
        },
    },
}
