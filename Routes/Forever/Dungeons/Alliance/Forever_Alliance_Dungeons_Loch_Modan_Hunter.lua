local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Alliance-Dungeons-Loch-Modan-Hunter"] = {
    label = L["Forever - Leveling Dungeon - Loch Modan"] .. " - II",
    legacyLabels = { L["Forever - Leveling Dungeon - Loch Modan"] .. " (11-13)" },
    levelRange = { min = 11, max = 13 },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1432,
    conditions = { Race = APR.RACES.Dwarf, Class = APR.Classes.Hunter, Faction = "Alliance", MinLevel = 11 },
    nextRoute = {
        { route = "Forever-Alliance-Dungeons-Westfall" },
        { route = "Forever-Shared-Dungeons-Hall-of-Thanes", conditions = { MinLevel = 13, Faction = "Alliance", Race = APR.RACES.Dwarf, Class = APR.Classes.Hunter, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ragefire-Chasm", conditions = { MinLevel = 13, Faction = "Alliance", Race = APR.RACES.Dwarf, Class = APR.Classes.Hunter, SkipForLvl = 19 } },
    },
    prefab = { [APR.PREFAB_TYPES.Dungeons] = { index = 3 } },
    hiddenFromSelection = true,
    steps = {
        {
            RouteCompleted = true,
            _index = 1,
        },
    },
}
