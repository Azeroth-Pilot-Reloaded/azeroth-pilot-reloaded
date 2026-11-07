local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional class route; select explicitly in the route browser.
APR.RouteQuestStepList["Forever-Class-Druid-Torwa-Preparation"] = {
    label = L["FOREVER_DRUID_TORWA_PREPARATION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1449,
    conditions = { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } },
    levelRange = { min = 50 },
    autoStartOnMap = false,
    steps = {
        { PickUp = { 9052 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 71.63, 75.96), RaidIcon = { { npcID = 9619, questID = 9052 } }, AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, IsQuestUncompleted = 9052, MinLevel = 50, Zone = 1449, _index = 1, },
        { Qpart = { [9052] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 50.4, 78.6), AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, IsQuestOnQuest = 9052, Zone = 1449, _index = 2, },
        { Qpart = { [9052] = { 2 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 71.9, 57.4), AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, IsQuestOnQuest = 9052, Zone = 1449, _index = 3, },
        { Done = { 9052 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 71.63, 75.96), RaidIcon = { { npcID = 9619, questID = 9052 } }, AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, IsQuestOnQuest = 9052, Zone = 1449, _index = 4, },
        { PickUp = { 9051 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 71.63, 75.96), RaidIcon = { { npcID = 9619, questID = 9051 } }, AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, IsQuestCompleted = 9052, IsQuestUncompleted = 9051, MinLevel = 50, Zone = 1449, _index = 5, },
        { Qpart = { [9051] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 67.31, 33.89), Button = { ["9051-1"] = 22432 }, RaidIcon = { { npcID = 6498, questID = 9051, objectiveIndex = 1 }, { npcID = 6499, questID = 9051, objectiveIndex = 1 }, { npcID = 6500, questID = 9051, objectiveIndex = 1 } }, AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, IsQuestOnQuest = 9051, Zone = 1449, _index = 6, },
        { Done = { 9051 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 71.63, 75.96), RaidIcon = { { npcID = 9619, questID = 9051 } }, AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, IsQuestOnQuest = 9051, Zone = 1449, _index = 7, },
        { RouteCompleted = true, AllOf = { { Class = APR.Classes.Druid, MinLevel = 50, AnyOf = { { Faction = "Horde", Race = { APR.RACES.Tauren, APR.RACES.Skyborne } }, { Faction = "Alliance", Race = APR.RACES.NightElf } } } }, _index = 8, },
    },
}
