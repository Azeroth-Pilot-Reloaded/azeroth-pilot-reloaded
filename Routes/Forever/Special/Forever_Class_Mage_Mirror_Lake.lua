local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Alliance-Mage-Mirror-Lake"] = {
    label = L["FOREVER_MAGE_MIRROR_LAKE"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1453,
    levelRange = { min = 10 },
    conditions = { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 10, IsQuestUncompleted = 1861, AnyOf = { { Not = { AnyOf = { { IsQuestOnQuest = 1880 }, { IsQuestCompleted = 1880 } } } } } },
    autoStartOnMap = false,
    steps = {
        { Done = { 1860 }, ExtraLineText = { "UPSTAIRS", "INSIDE_BUILDING" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.5, 85.84), Range = 5, RaidIcon = { { npcID = 5497, questID = 1860 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 10, IsQuestUncompleted = 1861, AnyOf = { { Not = { AnyOf = { { IsQuestOnQuest = 1880 }, { IsQuestCompleted = 1880 } } } } } } }, IsQuestOnQuest = 1860, Zone = 1453 },
        { PickUp = { 1861 }, ExtraLineText = { "UPSTAIRS", "INSIDE_BUILDING" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.5, 85.84), Range = 5, RaidIcon = { { npcID = 5497, questID = 1861 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 10, IsQuestUncompleted = 1861, AnyOf = { { Not = { AnyOf = { { IsQuestOnQuest = 1880 }, { IsQuestCompleted = 1880 } } } } } } }, IsQuestNotOnQuest = 1861, Zone = 1453 },
        { Qpart = { [1861] = { 1 } }, ExtraLineText = { "IN_WATER" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1429, 28.78, 61.47), Button = { ["1861-1"] = 7207 }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 10, IsQuestUncompleted = 1861, AnyOf = { { Not = { AnyOf = { { IsQuestOnQuest = 1880 }, { IsQuestCompleted = 1880 } } } } } } }, IsQuestOnQuest = 1861, Zone = 1429 },
        { Done = { 1861 }, ExtraLineText = { "UPSTAIRS", "INSIDE_BUILDING" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.5, 85.84), Range = 5, RaidIcon = { { npcID = 5497, questID = 1861 } }, AllOf = { { Faction = "Alliance", Class = "MAGE", Race = { "Human", "Gnome" }, MinLevel = 10, IsQuestUncompleted = 1861, AnyOf = { { Not = { AnyOf = { { IsQuestOnQuest = 1880 }, { IsQuestCompleted = 1880 } } } } } } }, IsQuestOnQuest = 1861, Zone = 1453 },
        { RouteCompleted = true,  },
    },
}
