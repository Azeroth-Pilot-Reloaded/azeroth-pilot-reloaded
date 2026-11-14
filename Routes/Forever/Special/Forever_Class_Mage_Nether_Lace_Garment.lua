local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Horde-Mage-Nether-Lace-Garment"] = {
    label = L["FOREVER_MAGE_NETHERLACE_GARMENT"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1454,
    levelRange = { min = 26 },
    conditions = { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 },
    autoStartOnMap = false,
    steps = {
        { Done = { 1943 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 38.45, 86.14), Range = 5, RaidIcon = { { npcID = 5885, questID = 1943 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestOnQuest = 1943, Zone = 1454 },
        { PickUp = { 1944 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 38.45, 86.14), Range = 5, RaidIcon = { { npcID = 5885, questID = 1944 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestNotOnQuest = 1944, IsQuestUncompleted = 1944, Zone = 1454 },
        { Waypoint = 1944, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1440, 73.67, 50.38), Range = 15, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestOnQuest = 1944, Not = { IsQuestReadyForTurnIn = 1944 }, Zone = 1440 },
        { Qpart = { [1944] = { 1 } }, ExtraLineText = { "IN_WATER" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1440, 76.33, 41.43), Button = { ["1944-1"] = 7269 }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestOnQuest = 1944, Zone = 1440 },
        { Done = { 1944 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 38.45, 86.14), Range = 5, RaidIcon = { { npcID = 5885, questID = 1944 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestOnQuest = 1944, Zone = 1454 },
        { PickUp = { 1945 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 38.45, 86.14), Range = 5, RaidIcon = { { npcID = 5885, questID = 1945 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestCompleted = 1944, IsQuestNotOnQuest = 1945, IsQuestUncompleted = 1945, Zone = 1454 },
        { Qpart = { [1945] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1440, 58.61, 59.49), RaidIcon = { { npcID = 4054, questID = 1945, objectiveIndex = 1 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestOnQuest = 1945, Zone = 1440 },
        { Done = { 1945 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 52.2, 31.7), Range = 5, RaidIcon = { { npcID = 3484, questID = 1945 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestOnQuest = 1945, Zone = 1413 },
        { PickUp = { 1946 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 52.2, 31.7), Range = 5, RaidIcon = { { npcID = 3484, questID = 1946 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestCompleted = 1945, IsQuestNotOnQuest = 1946, Zone = 1413 },
        { Done = { 1946 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 52.2, 31.7), Range = 5, RaidIcon = { { npcID = 3484, questID = 1946 } }, AllOf = { { Faction = "Horde", Class = "MAGE", Race = { "Scourge", "Troll" }, MinLevel = 26, IsQuestUncompleted = 1946 } }, IsQuestOnQuest = 1946, Zone = 1413 },
        { RouteCompleted = true,  },
    },
}
