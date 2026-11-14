local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Horde-Dungeons-Barrens-12-16"] = {
    label = L["Forever - Leveling Dungeon - The Barrens"] .. " - I",
    legacyLabels = { L["Forever - Leveling Dungeon - The Barrens"] .. " (12-16)" },
    levelRange = { min = 12, max = 16 },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1413,
    conditions = { MinLevel = 12, Faction = "Horde" },
    nextRoute = {
        "Forever-Horde-Dungeons-Ragefire-Chasm",
        { route = "Forever-Shared-Dungeons-Hall-of-Thanes", conditions = { MinLevel = 13, Faction = "Horde", SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ragefire-Chasm", conditions = { MinLevel = 13, Faction = "Horde", SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ruins-of-Lordaeron", conditions = { MinLevel = 15, Faction = "Horde", SkipForLvl = 21 } },
        { route = "Forever-Shared-Dungeons-Wailing-Caverns", conditions = { MinLevel = 17, Faction = "Horde", SkipForLvl = 26 } },
    },
    prefab = { [APR.PREFAB_TYPES.Dungeons] = { index = 4 } },
    steps = {
        {
            PickUp = { 870 },
            Coord = { x = -2672.76, y = -544.77 },
            Hardcore = false,
            Zone = 1413,
            _index = 1,
        },
        {
            PickUp = { 870 },
            Coord = { x = -2672.76, y = -544.77 },
            Hardcore = true,
            Zone = 1413,
            _index = 2,
        },
        {
            Qpart = {
                [870] = { 1 },
            },
            
            Note = { "DIVE_UNDERWATER_BUBBLING_FISSURE" },
            Coord = { x = -1943.16, y = 89.64 },
            Zone = 1413,
            _index = 3,
        },
        {
            Done = { 870 },
            Coord = { x = -2672.76, y = -544.77 },
            Zone = 1413,
            _index = 4,
        },
        {
            PickUp = { 877 },
            Coord = { x = -2672.76, y = -544.77 },
            Zone = 1413,
            _index = 5,
        },
        {
            RouteCompleted = true,
            _index = 6,
        },
    },
}
