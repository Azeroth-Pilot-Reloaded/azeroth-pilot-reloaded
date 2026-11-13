local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Alliance-Dungeons-Darkshore"] = {
    label = L["Forever - Leveling Dungeon - Darkshore"],
    legacyLabels = { L["Forever - Leveling Dungeon - Darkshore"] .. " (15-17)" },
    levelRange = { min = 15, max = 17 },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1439,
    conditions = { MinLevel = 15, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
    nextRoute = {
        { route = "Forever-Alliance-Dungeons-Hall-of-Thanes" },
        { route = "Forever-Shared-Dungeons-Hall-of-Thanes", conditions = { MinLevel = 13, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne }, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ragefire-Chasm", conditions = { MinLevel = 13, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne }, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ruins-of-Lordaeron", conditions = { MinLevel = 15, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne }, SkipForLvl = 21 } },
        { route = "Forever-Shared-Dungeons-Wailing-Caverns", conditions = { MinLevel = 17, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne }, SkipForLvl = 26 } },
        { route = "Forever-Shared-Dungeons-Deadmines", conditions = { MinLevel = 18, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne }, SkipForLvl = 24 } },
    },
    prefab = { [APR.PREFAB_TYPES.Dungeons] = { index = 5 } },
    hiddenFromSelection = true,
    steps = {
        {
            RouteCompleted = true,
            _index = 1,
        },
    },
}
