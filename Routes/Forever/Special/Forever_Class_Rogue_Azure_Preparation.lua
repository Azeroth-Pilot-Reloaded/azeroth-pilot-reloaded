local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "ROGUE", MinLevel = 50, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Skyborne", "Troll" } } } }

APR.RouteQuestStepList["Forever-Class-Rogue-Azure-Preparation"] = {
    label = L["FOREVER_ROGUE_AZURE_PREPARATION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1416,
    levelRange = { min = 50 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { IsQuestUncompleted = 8235 } } } } },
    steps = {
        { Waypoint = 8234, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 75.51, 23.52), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestNotOnQuest = 8234, IsQuestUncompleted = 8234 } }, MinLevel = 50, Zone = 1424, _index = 1 },
        { Waypoint = 8234, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 77.82, 19.27), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestNotOnQuest = 8234, IsQuestUncompleted = 8234 } }, MinLevel = 50, Zone = 1424, _index = 2 },
        { Waypoint = 8234, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 81.71, 77.48), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestNotOnQuest = 8234, IsQuestUncompleted = 8234 } }, MinLevel = 50, Zone = 1416, _index = 3 },
        { Waypoint = 8234, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 85.46, 79.39), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestNotOnQuest = 8234, IsQuestUncompleted = 8234 } }, MinLevel = 50, Zone = 1416, _index = 4 },
        { PickUp = { 8234 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 86.03, 78.88), Range = 5, RaidIcon = { { npcID = 6768, questID = 8234 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestNotOnQuest = 8234, IsQuestUncompleted = 8234 } }, MinLevel = 50, Zone = 1416, _index = 5 },
        { Qpart = { [8234] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 43.77, 25.56), RaidIcon = { { npcID = 6188, questID = 8234, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestOnQuest = 8234, IsQuestUncompleted = 8234, Not = { IsQuestReadyForTurnIn = 8234 } } }, MinLevel = 50, Zone = 1447, _index = 6 },
        { TakePortal = { mapID = 1447 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 28.11, 50.09), Range = 5, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1447, 26.466, 46.271, 20), RaidIcon = { { npcID = 8395 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestOnQuest = 8234, IsQuestUncompleted = 8234, IsQuestReadyForTurnIn = 8234 } }, MinLevel = 50, Zone = 1447, _index = 7 },
        { Done = { 8234 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 29.71, 40.52), Range = 5, RaidIcon = { { npcID = 8379, questID = 8234 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestOnQuest = 8234, IsQuestUncompleted = 8234 } }, MinLevel = 50, Zone = 1447, _index = 8 },
        { PickUp = { 8235 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 29.71, 40.52), Range = 5, RaidIcon = { { npcID = 8379, questID = 8235 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestNotOnQuest = 8235, IsQuestUncompleted = 8235, IsQuestCompleted = 8234 } }, MinLevel = 50, Zone = 1447, _index = 9 },
        { TakePortal = { mapID = 1447 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 26.466, 46.271), Range = 5, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1447, 28.11, 50.09, 20), RaidIcon = { { npcID = 8399 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestOnQuest = 8235, IsQuestUncompleted = 8235, Not = { IsQuestReadyForTurnIn = 8235 }, OnlyInZones = { 1447 } } }, MinLevel = 50, Zone = 1447, _index = 10 },
        { Qpart = { [8235] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 73.4, 25.2), RaidIcon = { { npcID = 8766, questID = 8235, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestOnQuest = 8235, IsQuestUncompleted = 8235, Not = { IsQuestReadyForTurnIn = 8235 } } }, MinLevel = 50, Zone = 1447, _index = 11 },
        { TakePortal = { mapID = 1447 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 28.11, 50.09), Range = 5, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1447, 26.466, 46.271, 20), RaidIcon = { { npcID = 8395 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestOnQuest = 8235, IsQuestUncompleted = 8235, IsQuestReadyForTurnIn = 8235 } }, MinLevel = 50, Zone = 1447, _index = 12 },
        { Done = { 8235 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 29.71, 40.52), Range = 5, RaidIcon = { { npcID = 8379, questID = 8235 } }, AllOf = { audience, { IsQuestUncompleted = 8235 }, { IsQuestOnQuest = 8235, IsQuestUncompleted = 8235 } }, MinLevel = 50, Zone = 1447, _index = 13 },
        { RouteCompleted = true, AllOf = { audience, { IsQuestCompleted = 8235 } }, MinLevel = 50, _index = 14 },
    },
}
