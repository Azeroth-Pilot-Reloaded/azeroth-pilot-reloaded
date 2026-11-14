local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "PALADIN", MinLevel = 12, Faction = "Alliance", Race = "Human" }

APR.RouteQuestStepList["Forever-Alliance-Class-Paladin-Human-Redemption"] = {
    label = L["FOREVER_PALADIN_HUMAN_REDEMPTION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1453,
    levelRange = { min = 12 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { AnyOf = { { IsQuestCompleted = 1781 }, { IsQuestOnQuest = 1786 }, { IsQuestOnQuest = 1787 }, { IsQuestOnQuest = 1788 } } } } } } },
    steps = {
        { Waypoint = 1786, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 53.29, 51.63), Range = 7, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1453, 53.29, 51.63, 7), AllOf = { audience, { IsQuestNotOnQuest = 1786, IsQuestUncompleted = 1786, IsQuestCompleted = 1781 } }, Zone = 1453, _index = 1 },
        { PickUp = { 1786 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.51, 44.9), Range = 3, RaidIcon = { { npcID = 6173, questID = 1786 } }, AllOf = { audience, { IsQuestNotOnQuest = 1786, IsQuestUncompleted = 1786, IsQuestCompleted = 1781 } }, Zone = 1453, _index = 2 },
        { Qpart = { [1786] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1429, 72.6, 51.41), Button = { ["1786-1"] = 6866 }, RaidIcon = { { npcID = 6172, questID = 1786, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestOnQuest = 1786, IsQuestUncompleted = 1786, Not = { IsQuestReadyForTurnIn = 1786 } } }, Zone = 1429, _index = 3 },
        { Done = { 1786 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1429, 72.6, 51.41), Range = 3, RaidIcon = { { npcID = 6172, questID = 1786 } }, AllOf = { audience, { IsQuestOnQuest = 1786, IsQuestUncompleted = 1786 } }, Zone = 1429, _index = 4 },
        { PickUp = { 1787 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1429, 72.6, 51.41), Range = 3, RaidIcon = { { npcID = 6172, questID = 1787 } }, AllOf = { audience, { IsQuestNotOnQuest = 1787, IsQuestUncompleted = 1787, IsQuestCompleted = 1786 } }, Zone = 1429, _index = 5 },
        { Qpart = { [1787] = { 1 } }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1429, 74.07, 51.57), RaidIcon = { { npcID = 474, questID = 1787, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestOnQuest = 1787, IsQuestUncompleted = 1787, Not = { IsQuestReadyForTurnIn = 1787 } } }, Zone = 1429, _index = 6 },
        { Waypoint = 1787, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 53.29, 51.63), Range = 7, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1453, 53.29, 51.63, 7), AllOf = { audience, { IsQuestOnQuest = 1787, IsQuestUncompleted = 1787 } }, Zone = 1453, _index = 7 },
        { Done = { 1787 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.51, 44.9), Range = 3, RaidIcon = { { npcID = 6173, questID = 1787 } }, AllOf = { audience, { IsQuestOnQuest = 1787, IsQuestUncompleted = 1787 } }, Zone = 1453, _index = 8 },
        { PickUp = { 1788 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.51, 44.9), Range = 3, RaidIcon = { { npcID = 6173, questID = 1788 } }, AllOf = { audience, { IsQuestNotOnQuest = 1788, IsQuestUncompleted = 1788, IsQuestCompleted = 1787 } }, Zone = 1453, _index = 9 },
        { Done = { 1788 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 50.48, 47.49), Range = 3, RaidIcon = { { npcID = 6171, questID = 1788 } }, AllOf = { audience, { IsQuestOnQuest = 1788, IsQuestUncompleted = 1788 } }, Zone = 1453, _index = 10 },
        { RouteCompleted = true, _index = 11 },
    },
}
