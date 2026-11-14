local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "SHAMAN", MinLevel = 50, Faction = "Horde", Race = { "Orc", "Skyborne", "Tauren", "Troll" } }

APR.RouteQuestStepList["Forever-Horde-Class-Shaman-Elemental-Preparation"] = {
    label = L["FOREVER_SHAMAN_ELEMENTAL_PREPARATION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1416,
    levelRange = { min = 50 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { IsQuestUncompleted = 8412 } } } } },
    steps = {
        { PickUp = { 8411 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 80.5, 66.92), Range = 5, RaidIcon = { { npcID = 6176, questID = 8411 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { IsQuestNotOnQuest = 8411, IsQuestUncompleted = 8411, Not = { AnyOf = { { IsQuestOnQuest = 8410 }, { IsQuestCompleted = 8410 }, { IsQuestCompleted = 8411 }, { IsQuestCompleted = 8412 } } } } }, MinLevel = 50, Zone = 1416, _index = 1 },
        { LootItems = { { itemID = 7069, quantity = 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1417, 52.03, 50.77), RaidIcon = { { npcID = 2762 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { AnyOf = { { IsQuestOnQuest = 8410 }, { IsQuestOnQuest = 8411 } }, IsQuestUncompleted = 8412 } }, MinLevel = 50, Zone = 1417, _index = 2 },
        { LootItems = { { itemID = 7068, quantity = 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1417, 24.8, 29.95), RaidIcon = { { npcID = 2760 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { AnyOf = { { IsQuestOnQuest = 8410 }, { IsQuestOnQuest = 8411 } }, IsQuestUncompleted = 8412 } }, MinLevel = 50, Zone = 1417, _index = 3 },
        { LootItems = { { itemID = 7070, quantity = 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1417, 66.7, 29.91), RaidIcon = { { npcID = 2761 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { AnyOf = { { IsQuestOnQuest = 8410 }, { IsQuestOnQuest = 8411 } }, IsQuestUncompleted = 8412 } }, MinLevel = 50, Zone = 1417, _index = 4 },
        { Waypoint = 8411, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 46.37, 77.2), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8412 }, { AnyOf = { { IsQuestOnQuest = 8410 }, { IsQuestOnQuest = 8411 } }, IsQuestUncompleted = 8412, Not = { ItemCount = { itemID = 7067, count = 1 } } } }, MinLevel = 50, Zone = 1418, _index = 5 },
        { LootItems = { { itemID = 7067, quantity = 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1418, 43.3, 84.24), RaidIcon = { { npcID = 92 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { AnyOf = { { IsQuestOnQuest = 8410 }, { IsQuestOnQuest = 8411 } }, IsQuestUncompleted = 8412 } }, MinLevel = 50, Zone = 1418, _index = 6 },
        { Done = { 8410 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 80.5, 66.92), Range = 5, RaidIcon = { { npcID = 6176, questID = 8410 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { IsQuestOnQuest = 8410, IsQuestUncompleted = 8410 } }, MinLevel = 50, Zone = 1416, _index = 7 },
        { Done = { 8411 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 80.5, 66.92), Range = 5, RaidIcon = { { npcID = 6176, questID = 8411 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { IsQuestOnQuest = 8411, IsQuestUncompleted = 8411 } }, MinLevel = 50, Zone = 1416, _index = 8 },
        { PickUp = { 8412 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 80.5, 66.92), Range = 5, RaidIcon = { { npcID = 6176, questID = 8412 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { IsQuestNotOnQuest = 8412, IsQuestUncompleted = 8412, AnyOf = { { IsQuestCompleted = 8410 }, { IsQuestCompleted = 8411 } } } }, MinLevel = 50, Zone = 1416, _index = 9 },
        { Qpart = { [8412] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 46.41, 59.88), RaidIcon = { { npcID = 1821, questID = 8412, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { IsQuestOnQuest = 8412, IsQuestUncompleted = 8412, Not = { IsQuestReadyForTurnIn = 8412 } } }, MinLevel = 50, Zone = 1422, _index = 10 },
        { Qpart = { [8412] = { 2 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 34.22, 62.1), RaidIcon = { { npcID = 1815, questID = 8412, objectiveIndex = 2 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { IsQuestOnQuest = 8412, IsQuestUncompleted = 8412, Not = { IsQuestReadyForTurnIn = 8412 } } }, MinLevel = 50, Zone = 1422, _index = 11 },
        { Done = { 8412 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 80.5, 66.92), Range = 5, RaidIcon = { { npcID = 6176, questID = 8412 } }, AllOf = { audience, { IsQuestUncompleted = 8412 }, { IsQuestOnQuest = 8412, IsQuestUncompleted = 8412 } }, MinLevel = 50, Zone = 1416, _index = 12 },
        { RouteCompleted = true, _index = 13 },
    },
}
