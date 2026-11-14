local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional continuation after Klaven's Tower; no leveling-route prerequisite.
APR.RouteQuestStepList["Forever-Alliance-Class-Rogue-Zanzil-Diagnosis"] = {
    label = L["FOREVER_ROGUE_ZANZIL_TOUCH"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1453,
    conditions = { Faction = "Alliance", Class = "ROGUE", Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" }, MinLevel = 20, AnyOf = { { IsQuestCompleted = 2359 }, { IsQuestOnQuest = 2607 }, { IsQuestCompleted = 2607 }, { IsQuestOnQuest = 2608 }, { IsQuestCompleted = 2608 } } },
    levelRange = { min = 20 },
    autoStartOnMap = false,
    steps = {
        {
            PickUp = { 2607 },
            Note = { "INSIDE_BUILDING", "UPSTAIRS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 78.31, 70.75), RaidIcon = { { npcID = 332, questID = 2607 } },
            AllOf = { { IsQuestCompleted = 2359 }, { IsQuestUncompleted = 2607 }, { IsQuestNotOnQuest = 2607 }, { IsQuestUncompleted = 2608 }, { IsQuestNotOnQuest = 2608 } }, Class = "ROGUE",
            Faction = "Alliance", MinLevel = 20, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1453, _index = 1,
        },
        {
            Done = { 2607 },
            Note = { "INSIDE_BUILDING", "DOWNSTAIRS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.06, 69.91), RaidIcon = { { npcID = 7207, questID = 2607 } }, Class = "ROGUE",
            Faction = "Alliance",
            IsQuestOnQuest = 2607, MinLevel = 20, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1453, _index = 2,
        },
        {
            PickUp = { 2608 },
            Note = { "INSIDE_BUILDING", "DOWNSTAIRS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.06, 69.91), RaidIcon = { { npcID = 7207, questID = 2608 } },
            AllOf = { { IsQuestCompleted = 2607 }, { IsQuestUncompleted = 2608 }, { IsQuestNotOnQuest = 2608 } }, Class = "ROGUE",
            Faction = "Alliance", MinLevel = 20, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1453, _index = 3,
        },
        {
            Qpart = { [2608] = { 1 } },
            Emote = { emote = "lay", npcID = 7207, manual = true },
            Note = { "INSIDE_BUILDING", "DOWNSTAIRS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.06, 69.91), RaidIcon = { { npcID = 7207, questID = 2608, objectiveIndex = 1 } },
            AllOf = { { IsQuestOnQuest = 2608 }, { Not = { IsQuestReadyForTurnIn = 2608 } } }, Class = "ROGUE",
            Faction = "Alliance", MinLevel = 20, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1453, _index = 4,
        },
        {
            Done = { 2608 },
            Note = { "INSIDE_BUILDING", "DOWNSTAIRS", "ANTI_VENOM_USE_ONE_CURE_TOUCH_ZANZIL", "ASK_PALADIN_DRUID_REMOVE_POISON_POSSIBLE" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 80.06, 69.91), RaidIcon = { { npcID = 7207, questID = 2608 } }, Class = "ROGUE",
            Faction = "Alliance",
            IsQuestOnQuest = 2608, MinLevel = 20, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1453, _index = 5,
        },
        {
            RouteCompleted = true, 
   _index = 6,
        },
    },
}
