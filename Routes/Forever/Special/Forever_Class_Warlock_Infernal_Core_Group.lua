local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "WARLOCK", MinLevel = 50, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } } }

APR.RouteQuestStepList["Forever-Class-Warlock-Infernal-Core-Group"] = {
    label = L["FOREVER_WARLOCK_INFERNAL_CORE"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1448,
    levelRange = { min = 50 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { AnyOf = { { IsQuestCompleted = 7602 }, { IsQuestOnQuest = 7603 }, { IsQuestCompleted = 7603 } } } } } } },
    steps = {
        { PickUp = { 7603 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 41.36, 45.02), Range = 5, RaidIcon = { { npcID = 14470, questID = 7603 } }, AllOf = { audience, { IsQuestUncompleted = 7603 }, { IsQuestNotOnQuest = 7603, IsQuestUncompleted = 7603, IsQuestCompleted = 7602 } }, MinLevel = 50, Zone = 1448, _index = 1 },
        { Waypoint = 7603, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.76, 41.7), Range = 7, AllOf = { audience, { IsQuestUncompleted = 7603 }, { IsQuestOnQuest = 7603, IsQuestUncompleted = 7603, Not = { IsQuestReadyForTurnIn = 7603 } } }, MinLevel = 50, Zone = 1448, _index = 2 },
        { Waypoint = 7603, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 39.01, 37.86), Range = 7, AllOf = { audience, { IsQuestUncompleted = 7603 }, { IsQuestOnQuest = 7603, IsQuestUncompleted = 7603, Not = { IsQuestReadyForTurnIn = 7603 } } }, MinLevel = 50, Zone = 1448, _index = 3 },
        { Waypoint = 7603, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 41.25, 36.95), Range = 7, AllOf = { audience, { IsQuestUncompleted = 7603 }, { IsQuestOnQuest = 7603, IsQuestUncompleted = 7603, Not = { IsQuestReadyForTurnIn = 7603 } } }, MinLevel = 50, Zone = 1448, _index = 4 },
        { Qpart = { [7603] = { 1 } }, GroupTask = 7603, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 45.73, 34.81), Button = { ["7603-1"] = 18626 }, RaidIcon = { { npcID = 14467, questID = 7603, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestUncompleted = 7603 }, { IsQuestOnQuest = 7603, IsQuestUncompleted = 7603 } }, MinLevel = 50, Zone = 1448, _index = 5 },
        { Done = { 7603 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 41.38, 44.86), Range = 5, RaidIcon = { { npcID = 14469, questID = 7603 } }, AllOf = { audience, { IsQuestUncompleted = 7603 }, { IsQuestOnQuest = 7603, IsQuestUncompleted = 7603 } }, MinLevel = 50, Zone = 1448, _index = 6 },
        { RouteCompleted = true, AllOf = { audience, { IsQuestCompleted = 7603 } }, MinLevel = 50, _index = 7 },
    },
}
