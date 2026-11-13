local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Alliance-Dungeons-Loch-Modan-Dwarf-Gnome"] = {
    label = L["Forever - Leveling Dungeon - Loch Modan"] .. " - III",
    legacyLabels = { L["Forever - Leveling Dungeon - Loch Modan"] .. " (12-14)" },
    levelRange = { min = 12, max = 14 },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1432,
    conditions = { MinLevel = 12, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome }, Class = { APR.Classes.Mage, APR.Classes.Paladin, APR.Classes.Priest, APR.Classes.Rogue, APR.Classes.Shaman, APR.Classes.Warlock, APR.Classes.Warrior } },
    nextRoute = {
        { route = "Forever-Alliance-Dungeons-Westfall" },
        { route = "Forever-Shared-Dungeons-Hall-of-Thanes", conditions = { MinLevel = 13, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome }, Class = { APR.Classes.Warrior, APR.Classes.Paladin, APR.Classes.Rogue, APR.Classes.Priest, APR.Classes.Shaman, APR.Classes.Mage, APR.Classes.Warlock }, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ragefire-Chasm", conditions = { MinLevel = 13, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome }, Class = { APR.Classes.Warrior, APR.Classes.Paladin, APR.Classes.Rogue, APR.Classes.Priest, APR.Classes.Shaman, APR.Classes.Mage, APR.Classes.Warlock }, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ruins-of-Lordaeron", conditions = { MinLevel = 15, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome }, Class = { APR.Classes.Warrior, APR.Classes.Paladin, APR.Classes.Rogue, APR.Classes.Priest, APR.Classes.Shaman, APR.Classes.Mage, APR.Classes.Warlock }, SkipForLvl = 21 } },
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
