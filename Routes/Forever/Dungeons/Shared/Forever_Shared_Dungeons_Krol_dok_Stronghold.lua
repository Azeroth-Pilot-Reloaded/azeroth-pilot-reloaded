local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Krol-dok-Stronghold"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 40,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Krol'dok Stronghold"],
    levelRange = {
        max = 47,
        min = 40,
    },
    mapID = 2548,
    steps = { {
        EnterInstance = {
            dungeonKey = "KROLDOK",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(2548, 37.5, 37.2),
        Dungeon = "KROLDOK",
        InstanceQuest = true,
        Zone = 2548,
        _index = 1,
    }, {
        KillNPC = {
            dungeonKey = "KROLDOK",
            name = "Slavecrusher Grox",
            npcID = 258966,
        },
        NoArrow = true,
        Dungeon = "KROLDOK",
        InstanceQuest = true,
        _index = 2,
    }, {
        KillNPC = {
            dungeonKey = "KROLDOK",
            name = "Twilight Commander Zarmok",
            npcID = 258972,
        },
        NoArrow = true,
        Dungeon = "KROLDOK",
        InstanceQuest = true,
        _index = 3,
    }, {
        KillNPC = {
            dungeonKey = "KROLDOK",
            name = "Handler Ashka",
            npcID = 259281,
        },
        NoArrow = true,
        Dungeon = "KROLDOK",
        InstanceQuest = true,
        _index = 4,
    }, {
        KillNPC = {
            dungeonKey = "KROLDOK",
            name = "Nar'gurk",
            npcID = 258964,
        },
        NoArrow = true,
        Dungeon = "KROLDOK",
        InstanceQuest = true,
        _index = 5,
    }, {
        KillNPC = {
            dungeonKey = "KROLDOK",
            name = "Bossman Toof",
            npcID = 264773,
        },
        NoArrow = true,
        Dungeon = "KROLDOK",
        InstanceQuest = true,
        _index = 6,
    }, {
        KillNPC = {
            dungeonKey = "KROLDOK",
            name = "Overseer Mugg",
            npcID = 258968,
        },
        NoArrow = true,
        Dungeon = "KROLDOK",
        InstanceQuest = true,
        _index = 7,
    }, {
        LeaveInstance = {
            dungeonKey = "KROLDOK",
        },
        NoArrow = true,
        Dungeon = "KROLDOK",
        _index = 8,
    }, {
        RouteCompleted = true,
        _index = 9,
    } },
}
