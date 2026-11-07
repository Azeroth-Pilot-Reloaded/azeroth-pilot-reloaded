local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "WARLOCK", MinLevel = 60, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } } }

APR.RouteQuestStepList["Forever-Class-Warlock-Dreadsteed-Ritual"] = {
    label = L["FOREVER_WARLOCK_DREADSTEED_RITUAL"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1428,
    levelRange = { min = 60 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { AnyOf = { { AllOf = { { IsQuestCompleted = 7629 }, { IsQuestCompleted = 7630 } } }, { IsQuestOnQuest = 7631 } } } } } } },
    steps = {
        { PickUp = { 7631 }, Note = { "DREADSTEED_RITUAL_PREPARATION" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.69, 31.64), Range = 3, RaidIcon = { { npcID = 14436, questID = 7631 } }, AllOf = { audience, { IsQuestNotOnQuest = 7631, IsQuestUncompleted = 7631, AllOf = { { IsQuestCompleted = 7629 }, { IsQuestCompleted = 7630 } } } }, Zone = 1428, _index = 1 },
        { Waypoint = 7631, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.13, 44.67), Range = 7, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.13, 44.67, 7), AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 } } }, Zone = 1444, _index = 2 },
        { Waypoint = 7631, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.52, 39.51), Range = 7, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.52, 39.51, 7), AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 } } }, Zone = 1444, _index = 3 },
        { Waypoint = 7631, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.72, 38.78), Range = 7, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.72, 38.78, 7), AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 } } }, Zone = 1444, _index = 4 },
        { Waypoint = 7631, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.15, 34.87), Range = 7, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.15, 34.87, 7), AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 } } }, Zone = 1444, _index = 5 },
        { Waypoint = 7631, NonSkippableWaypoint = true, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 60.32, 30.16), Range = 7, ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 60.32, 30.16, 7), AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 } } }, Zone = 1444, _index = 6 },
        { EnterInstance = { dungeonKey = "INSTANCE_429", questID = 7631 }, Note = { "DREADSTEED_DIRE_MAUL_ACCESS" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 60.32, 30.16), AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 } } }, Zone = 1444, _index = 7 },
        { UseItem = { itemID = 18663 }, Note = { "DREADSTEED_PRISON_PREPARATION" }, NoArrow = true, Dungeon = "INSTANCE_429", AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 }, ItemCount = { itemID = 18663, count = 1, operator = ">=" } } }, _index = 8 },
        { UseItem = { itemID = 18670 }, Note = { "DREADSTEED_RITUAL_DEFENSE" }, NoArrow = true, Dungeon = "INSTANCE_429", AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 }, ItemCount = { itemID = 18670, count = 1, operator = ">=" } } }, _index = 9 },
        { Qpart = { [7631] = { 1 } }, Note = { "DREADSTEED_RITUAL_COMPLETION" }, NoArrow = true, Dungeon = "INSTANCE_429", RaidIcon = { { npcID = 14502, questID = 7631, objectiveIndex = 1 }, { npcID = 14506, questID = 7631, objectiveIndex = 1 } }, AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631, Not = { IsQuestReadyForTurnIn = 7631 } } }, _index = 10 },
        { Done = { 7631 }, Range = 3, NoArrow = true, Dungeon = "INSTANCE_429", RaidIcon = { { npcID = 14504, questID = 7631 } }, AllOf = { audience, { IsQuestOnQuest = 7631, IsQuestUncompleted = 7631 } }, _index = 11 },
        { RouteCompleted = true, AllOf = { audience, { IsQuestCompleted = 7631 } }, _index = 12 },
    },
}
