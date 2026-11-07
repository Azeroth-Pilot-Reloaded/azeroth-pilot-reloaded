local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional independent class chain; resume from current quest state.
APR.RouteQuestStepList["Forever-Alliance-Class-Mage-Astral-Knot-Garment"] = {
    label = L["FOREVER_MAGE_ASTRAL_KNOT"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1453,
    levelRange = { min = 26 },
    conditions = { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26, IsQuestUncompleted = 1942 },
    autoStartOnMap = false,
    steps = {
        { Done = { 1939 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 48.71, 87.61), Range = 5, RaidIcon = { { npcID = 5694, questID = 1939 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestOnQuest = 1939, IsQuestUncompleted = 1939, Zone = 1453, },
        { PickUp = { 1938 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 48.71, 87.61), Range = 5, RaidIcon = { { npcID = 5694, questID = 1938 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestNotOnQuest = 1938, IsQuestUncompleted = 1938, Zone = 1453, },
        { Qpart = { [1938] = { 1 } }, ExtraLineText = { "UPSTAIRS" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1433, 73.78, 47.64), AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestOnQuest = 1938, Zone = 1433, },
        { Done = { 1938 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 48.71, 87.61), Range = 5, RaidIcon = { { npcID = 5694, questID = 1938 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestOnQuest = 1938, IsQuestUncompleted = 1938, Zone = 1453, },
        { PickUp = { 1940 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 48.71, 87.61), Range = 5, RaidIcon = { { npcID = 5694, questID = 1940 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestCompleted = 1938, IsQuestNotOnQuest = 1940, IsQuestUncompleted = 1940, Zone = 1453, },
        { Qpart = { [1940] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1431, 31.93, 34.27), RaidIcon = { { npcID = 930, questID = 1940, objectiveIndex = 1 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestOnQuest = 1940, Zone = 1431, },
        { Done = { 1940 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.84, 83.51), Range = 5, RaidIcon = { { npcID = 1309, questID = 1940 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestOnQuest = 1940, IsQuestUncompleted = 1940, Zone = 1453, },
        { PickUp = { 1942 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.84, 83.51), Range = 5, RaidIcon = { { npcID = 1309, questID = 1942 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestCompleted = 1940, IsQuestNotOnQuest = 1942, IsQuestUncompleted = 1942, Zone = 1453, },
        { Done = { 1942 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 51.84, 83.51), Range = 5, RaidIcon = { { npcID = 1309, questID = 1942 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 }, { IsQuestUncompleted = 1942 } }, IsQuestOnQuest = 1942, IsQuestUncompleted = 1942, Zone = 1453, },
        { RouteCompleted = true, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 26 } }, IsQuestCompleted = 1942, },
    },
}
