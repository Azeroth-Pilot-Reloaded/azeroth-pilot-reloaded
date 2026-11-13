local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Alliance-Dungeons-Darkshore-Loch-Modan-NightElf"] = {
    label = L["Forever - Leveling Dungeon - Darkshore / Loch Modan"],
    legacyLabels = { L["Forever - Leveling Dungeon - Darkshore / Loch Modan"] .. " (11-16)" },
    levelRange = { min = 11, max = 16 },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1439,
    conditions = { Race = APR.RACES.NightElf, Faction = "Alliance", MinLevel = 11 },
    nextRoute = {
        { route = "Forever-Alliance-Dungeons-Hall-of-Thanes" },
        { route = "Forever-Shared-Dungeons-Hall-of-Thanes", conditions = { MinLevel = 13, Faction = "Alliance", Race = APR.RACES.NightElf, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ragefire-Chasm", conditions = { MinLevel = 13, Faction = "Alliance", Race = APR.RACES.NightElf, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ruins-of-Lordaeron", conditions = { MinLevel = 15, Faction = "Alliance", Race = APR.RACES.NightElf, SkipForLvl = 21 } },
        { route = "Forever-Shared-Dungeons-Wailing-Caverns", conditions = { MinLevel = 17, Faction = "Alliance", Race = APR.RACES.NightElf, SkipForLvl = 26 } },
    },
    prefab = { [APR.PREFAB_TYPES.Dungeons] = { index = 4 } },
    steps = {
        {
            Waypoint = 96391,
            Note = { "KILL_DARK_IRON_SPIES_LOOT_DARK_IRON_MAP" },
            Coord = { x = -2009.87, y = -5860.22 },
            Range = 40.0,
            Zone = 1426,
            _index = 1,
        },
        {
            Done = { 96391 },
            Coord = { x = -1394.24, y = -5797.83 },
            Zone = 1426,
            _index = 2,
        },
        {
            PickUp = { 96393 },
            Coord = { x = -1394.24, y = -5797.83 },
            Zone = 1426,
            _index = 3,
        },
        {
            RouteCompleted = true,
            _index = 4,
        },
    },
}
