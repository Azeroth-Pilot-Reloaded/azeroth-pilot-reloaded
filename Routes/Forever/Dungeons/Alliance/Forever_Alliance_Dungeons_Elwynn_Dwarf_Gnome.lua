local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Alliance-Dungeons-Elwynn-Dwarf-Gnome"] = {
    label = L["Forever - Leveling Dungeon - Elwynn Forest"],
    legacyLabels = { L["Forever - Leveling Dungeon - Elwynn Forest"] .. " (11-12)" },
    levelRange = { min = 11, max = 12 },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1429,
    conditions = { MinLevel = 11, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome }, Class = { APR.Classes.Mage, APR.Classes.Paladin, APR.Classes.Priest, APR.Classes.Rogue, APR.Classes.Shaman, APR.Classes.Warlock, APR.Classes.Warrior } },
    nextRoute = {
        { route = "Forever-Alliance-Dungeons-Loch-Modan-Dwarf-Gnome" },
        { route = "Forever-Shared-Dungeons-Hall-of-Thanes", conditions = { MinLevel = 13, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome }, Class = { APR.Classes.Warrior, APR.Classes.Paladin, APR.Classes.Rogue, APR.Classes.Priest, APR.Classes.Shaman, APR.Classes.Mage, APR.Classes.Warlock }, SkipForLvl = 19 } },
        { route = "Forever-Shared-Dungeons-Ragefire-Chasm", conditions = { MinLevel = 13, Faction = "Alliance", Race = { APR.RACES.Dwarf, APR.RACES.Gnome }, Class = { APR.Classes.Warrior, APR.Classes.Paladin, APR.Classes.Rogue, APR.Classes.Priest, APR.Classes.Shaman, APR.Classes.Mage, APR.Classes.Warlock }, SkipForLvl = 19 } },
    },
    prefab = { [APR.PREFAB_TYPES.Dungeons] = { index = 2 } },
    hiddenFromSelection = true,
    steps = {
        {
            RouteCompleted = true,
            _index = 1,
        },
    },
}
