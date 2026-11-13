local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Drowned-City"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 35,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Drowned City"],
    levelRange = {
        max = 42,
        min = 35,
    },
    mapID = 1434,
    steps = { {
        PickUp = { 96774 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1412, 32.5, 20.66),
        RaidIcon = { {
            npcID = 264074,
            questID = 96774,
        } },
        Faction = "Horde",
        MinLevel = 30,
        Zone = 1412,
        _index = 1,
    }, {
        EnterInstance = {
            dungeonKey = "DROWNED_CITY",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1434, 21.3, 27.9),
        Dungeon = "DROWNED_CITY",
        InstanceQuest = true,
        Zone = 1434,
        _index = 2,
    }, {
        KillNPC = {
            dungeonKey = "DROWNED_CITY",
            name = "Zul'Alai",
            npcID = 258905,
        },
        NoArrow = true,
        Dungeon = "DROWNED_CITY",
        InstanceQuest = true,
        _index = 3,
    }, {
        KillNPC = {
            dungeonKey = "DROWNED_CITY",
            name = "Var'Taka",
            npcID = 258924,
        },
        NoArrow = true,
        Dungeon = "DROWNED_CITY",
        InstanceQuest = true,
        _index = 4,
    }, {
        KillNPC = {
            dungeonKey = "DROWNED_CITY",
            name = "Captain Dreadrise",
            npcID = 260042,
        },
        NoArrow = true,
        Dungeon = "DROWNED_CITY",
        InstanceQuest = true,
        _index = 5,
    }, {
        KillNPC = {
            dungeonKey = "DROWNED_CITY",
            name = "Primeval Elemental",
            npcID = 273738,
        },
        NoArrow = true,
        Dungeon = "DROWNED_CITY",
        InstanceQuest = true,
        _index = 6,
    }, {
        KillNPC = {
            dungeonKey = "DROWNED_CITY",
            name = "Min'loth the Serpent",
            npcID = 260243,
        },
        NoArrow = true,
        Dungeon = "DROWNED_CITY",
        InstanceQuest = true,
        _index = 7,
    }, {
        Qpart = {
            [96774] = { 1 },
        },
        NoArrow = true,
        Dungeon = "DROWNED_CITY",
        InstanceQuest = true,
        IsQuestOnQuest = 96774,
        _index = 8,
    }, {
        LeaveInstance = {
            dungeonKey = "DROWNED_CITY",
        },
        NoArrow = true,
        Dungeon = "DROWNED_CITY",
        _index = 9,
    }, {
        Done = { 96774 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1412, 32.5, 20.66),
        RaidIcon = { {
            npcID = 264074,
            questID = 96774,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 96774,
        Zone = 1412,
        _index = 10,
    }, {
        RouteCompleted = true,
        _index = 11,
    } },
}
