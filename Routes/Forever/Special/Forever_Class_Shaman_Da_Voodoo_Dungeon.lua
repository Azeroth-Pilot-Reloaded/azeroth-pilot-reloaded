local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "SHAMAN", MinLevel = 50, Faction = "Horde", Race = { "Orc", "Skyborne", "Tauren", "Troll" } }

APR.RouteQuestStepList["Forever-Horde-Class-Shaman-Da-Voodoo-Dungeon"] = {
    label = L["FOREVER_SHAMAN_VOODOO"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1435,
    levelRange = { min = 50 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { IsQuestCompleted = 8412, IsQuestUncompleted = 8413 } } } } },
    steps = {
        { PickUp = { 8413 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 80.5, 66.92), Range = 5, RaidIcon = { { npcID = 6176, questID = 8413 } }, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestNotOnQuest = 8413, IsQuestUncompleted = 8413, IsQuestCompleted = 8412 } }, MinLevel = 50, Zone = 1416, _index = 1 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 69.36, 56.89), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 2 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 70.54, 49.78), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 3 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 72.69, 42.22), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 4 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 75.69, 45.78), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 5 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 78.62, 47.47), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 6 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 80.22, 49.62), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 7 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 81.33, 42.38), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 8 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 78.86, 40.74), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 9 },
        { Waypoint = 8413, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 76.85, 38.82), Range = 7, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 10 },
        { EnterInstance = { dungeonKey = "INSTANCE_109" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1435, 77.34, 35.85), Dungeon = "INSTANCE_109", InstanceQuest = true, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, Zone = 1435, _index = 11 },
        { Qpart = { [8413] = { 1 } }, NoArrow = true, Dungeon = "INSTANCE_109", InstanceQuest = true, RaidIcon = { { npcID = 5713, questID = 8413, objectiveIndex = 1 }, { npcID = 5716, questID = 8413, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, _index = 12 },
        { Qpart = { [8413] = { 2 } }, NoArrow = true, Dungeon = "INSTANCE_109", InstanceQuest = true, RaidIcon = { { npcID = 5715, questID = 8413, objectiveIndex = 2 }, { npcID = 5717, questID = 8413, objectiveIndex = 2 } }, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, _index = 13 },
        { Qpart = { [8413] = { 3 } }, NoArrow = true, Dungeon = "INSTANCE_109", InstanceQuest = true, RaidIcon = { { npcID = 5712, questID = 8413, objectiveIndex = 3 }, { npcID = 5714, questID = 8413, objectiveIndex = 3 } }, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, Not = { IsQuestReadyForTurnIn = 8413 } } }, MinLevel = 50, _index = 14 },
        { LeaveInstance = { dungeonKey = "INSTANCE_109" }, NoArrow = true, Dungeon = "INSTANCE_109", InstanceQuest = true, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413, IsQuestReadyForTurnIn = 8413 } }, MinLevel = 50, _index = 15 },
        { Done = { 8413 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1416, 80.5, 66.92), Range = 5, RaidIcon = { { npcID = 6176, questID = 8413 } }, AllOf = { audience, { IsQuestUncompleted = 8413 }, { IsQuestOnQuest = 8413, IsQuestUncompleted = 8413 } }, MinLevel = 50, Zone = 1416, _index = 16 },
        { RouteCompleted = true, _index = 17 },
    },
}
