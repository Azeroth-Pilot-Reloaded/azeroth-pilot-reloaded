local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "WARLOCK", MinLevel = 50, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } } }

APR.RouteQuestStepList["Forever-Class-Warlock-Infernal-Essences"] = {
    label = L["FOREVER_WARLOCK_INFERNAL_ESSENCES"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1448,
    levelRange = { min = 50 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { IsQuestUncompleted = 7602 } } } } },
    steps = {
        { PickUp = { 7601 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 41.38, 44.86), Range = 5, RaidIcon = { { npcID = 14469, questID = 7601 } }, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestNotOnQuest = 7601, IsQuestUncompleted = 7601 } }, MinLevel = 50, Zone = 1448, _index = 1 },
        { Done = { 7601 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 41.36, 45.02), Range = 5, RaidIcon = { { npcID = 14470, questID = 7601 } }, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestOnQuest = 7601, IsQuestUncompleted = 7601 } }, MinLevel = 50, Zone = 1448, _index = 2 },
        { PickUp = { 7602 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 41.36, 45.02), Range = 5, RaidIcon = { { npcID = 14470, questID = 7602 } }, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestNotOnQuest = 7602, IsQuestUncompleted = 7602, IsQuestCompleted = 7601 } }, MinLevel = 50, Zone = 1448, _index = 3 },
        { Waypoint = 7602, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.39, 58.54), Range = 7, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestOnQuest = 7602, IsQuestUncompleted = 7602, Not = { IsQuestReadyForTurnIn = 7602 }, ItemCount = { itemID = 18622, count = 1, operator = "<" } } }, MinLevel = 50, Zone = 1448, _index = 4 },
        { Qpart = { [7602] = { 2 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 36.25, 55.94), RaidIcon = { { npcID = 9862, questID = 7602, objectiveIndex = 2 } }, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestOnQuest = 7602, IsQuestUncompleted = 7602 } }, MinLevel = 50, Zone = 1448, _index = 5 },
        { Qpart = { [7602] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 52.03, 18.65), RaidIcon = { { npcID = 6200, questID = 7602, objectiveIndex = 1 }, { npcID = 6201, questID = 7602, objectiveIndex = 1 }, { npcID = 6202, questID = 7602, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestOnQuest = 7602, IsQuestUncompleted = 7602 } }, MinLevel = 50, Zone = 1447, _index = 6 },
        { Qpart = { [7602] = { 3 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1419, 61.32, 54.18), RaidIcon = { { npcID = 6011, questID = 7602, objectiveIndex = 3 } }, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestOnQuest = 7602, IsQuestUncompleted = 7602 } }, MinLevel = 50, Zone = 1419, _index = 7 },
        { Done = { 7602 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 41.36, 45.02), Range = 5, RaidIcon = { { npcID = 14470, questID = 7602 } }, AllOf = { audience, { IsQuestUncompleted = 7602 }, { IsQuestOnQuest = 7602, IsQuestUncompleted = 7602 } }, MinLevel = 50, Zone = 1448, _index = 8 },
        { RouteCompleted = true, AllOf = { audience, { IsQuestCompleted = 7602 } }, MinLevel = 50, _index = 9 },
    },
}
