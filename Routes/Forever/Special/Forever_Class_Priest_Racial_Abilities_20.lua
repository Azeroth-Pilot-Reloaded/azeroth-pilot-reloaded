local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Independent optional racial abilities; no leveling preset or incoming route edge.
APR.RouteQuestStepList["Forever-Alliance-Priest-A-Lack-of-Fear"] = {
    label = L["FOREVER_PRIEST_LACK_FEAR"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1455,
    levelRange = { min = 20 },
    conditions = { Faction = "Alliance", Class = "PRIEST", Race = "Dwarf", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5641 }, { IsQuestCompleted = 5645 }, { IsQuestCompleted = 5647 }, { IsQuestOnQuest = 5645 }, { IsQuestOnQuest = 5647 } } } } } },
    autoStartOnMap = false,
    steps = {
        { PickUp = { 5641 }, ExtraLineText = { "INSIDE_BUILDING" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 24.72, 8.14), Range = 5,
            RaidIcon = { { npcID = 11406, questID = 5641 } }, AllOf = { { Faction = "Alliance", Class = "PRIEST", Race = "Dwarf", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5641 }, { IsQuestCompleted = 5645 }, { IsQuestCompleted = 5647 }, { IsQuestOnQuest = 5645 }, { IsQuestOnQuest = 5647 } } } } } } }, MinLevel = 20, Zone = 1455, _index = 1 },
        { Done = { 5641 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 24.72, 8.14),
            RaidIcon = { { npcID = 11406, questID = 5641 } }, AllOf = { { Faction = "Alliance", Class = "PRIEST", Race = "Dwarf", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5641 }, { IsQuestCompleted = 5645 }, { IsQuestCompleted = 5647 }, { IsQuestOnQuest = 5645 }, { IsQuestOnQuest = 5647 } } } } } } }, IsQuestOnQuest = 5641, MinLevel = 20, Zone = 1455, _index = 2 },
        { RouteCompleted = true, _index = 3 },
    },
}

APR.RouteQuestStepList["Forever-Alliance-Priest-Arcane-Feedback"] = {
    label = L["FOREVER_PRIEST_ARCANE_FEEDBACK"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Miscellaneous,
    mapID = 1453,
    levelRange = { min = 20 },
    conditions = { Faction = "Alliance", Class = "PRIEST", Race = "Human", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5676 }, { IsQuestCompleted = 5677 }, { IsQuestCompleted = 5678 }, { IsQuestOnQuest = 5677 }, { IsQuestOnQuest = 5678 } } } } } },
    autoStartOnMap = false,
    steps = {
        { Waypoint = 5676, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 52.98, 51.14),
            Range = 7, AllOf = { { Faction = "Alliance", Class = "PRIEST", Race = "Human", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5676 }, { IsQuestCompleted = 5677 }, { IsQuestCompleted = 5678 }, { IsQuestOnQuest = 5677 }, { IsQuestOnQuest = 5678 } } } } } } }, IsQuestNotOnQuest = 5676, MinLevel = 20, Zone = 1453, _index = 1 },
        { PickUp = { 5676 }, ExtraLineText = { "INSIDE_BUILDING" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.53, 44.57), Range = 5,
            RaidIcon = { { npcID = 376, questID = 5676 } }, AllOf = { { Faction = "Alliance", Class = "PRIEST", Race = "Human", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5676 }, { IsQuestCompleted = 5677 }, { IsQuestCompleted = 5678 }, { IsQuestOnQuest = 5677 }, { IsQuestOnQuest = 5678 } } } } } } }, MinLevel = 20, Zone = 1453, _index = 2 },
        { Done = { 5676 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.53, 44.57),
            RaidIcon = { { npcID = 376, questID = 5676 } }, AllOf = { { Faction = "Alliance", Class = "PRIEST", Race = "Human", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5676 }, { IsQuestCompleted = 5677 }, { IsQuestCompleted = 5678 }, { IsQuestOnQuest = 5677 }, { IsQuestOnQuest = 5678 } } } } } } }, IsQuestOnQuest = 5676, MinLevel = 20, Zone = 1453, _index = 3 },
        { RouteCompleted = true, _index = 4 },
    },
}

APR.RouteQuestStepList["Forever-Alliance-Priest-Elunes-Grace"] = {
    label = L["FOREVER_PRIEST_ELUNE_GRACE"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Miscellaneous,
    mapID = 1457,
    levelRange = { min = 20 },
    conditions = { Faction = "Alliance", Class = "PRIEST", Race = "NightElf", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5672 }, { IsQuestCompleted = 5673 }, { IsQuestCompleted = 5674 }, { IsQuestCompleted = 5675 }, { IsQuestOnQuest = 5673 }, { IsQuestOnQuest = 5674 }, { IsQuestOnQuest = 5675 } } } } } },
    autoStartOnMap = false,
    steps = {
        { PickUp = { 5672 }, ExtraLineText = { "UPSTAIRS", "INSIDE_BUILDING" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1457, 39.53, 81.18), Range = 5,
            RaidIcon = { { npcID = 11401, questID = 5672 } }, AllOf = { { Faction = "Alliance", Class = "PRIEST", Race = "NightElf", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5672 }, { IsQuestCompleted = 5673 }, { IsQuestCompleted = 5674 }, { IsQuestCompleted = 5675 }, { IsQuestOnQuest = 5673 }, { IsQuestOnQuest = 5674 }, { IsQuestOnQuest = 5675 } } } } } } }, MinLevel = 20, Zone = 1457, _index = 1 },
        { Done = { 5672 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1457, 39.53, 81.18),
            RaidIcon = { { npcID = 11401, questID = 5672 } }, AllOf = { { Faction = "Alliance", Class = "PRIEST", Race = "NightElf", MinLevel = 20,
        AnyOf = { { Not = { AnyOf = { { IsQuestCompleted = 5672 }, { IsQuestCompleted = 5673 }, { IsQuestCompleted = 5674 }, { IsQuestCompleted = 5675 }, { IsQuestOnQuest = 5673 }, { IsQuestOnQuest = 5674 }, { IsQuestOnQuest = 5675 } } } } } } }, IsQuestOnQuest = 5672, MinLevel = 20, Zone = 1457, _index = 2 },
        { RouteCompleted = true, _index = 3 },
    },
}
