local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = { Class = "WARLOCK", MinLevel = 60, AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } } }

APR.RouteQuestStepList["Forever-Class-Warlock-Dreadsteed-Scholomance"] = {
    label = L["FOREVER_WARLOCK_DREADSTEED_SCHOLOMANCE"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1428,
    levelRange = { min = 60 },
    autoStartOnMap = false,
    conditions = { AnyOf = { { AllOf = { audience, { AnyOf = { { IsQuestCompleted = 7625 }, { IsQuestOnQuest = 7629 } } } } } } },
    steps = {
        { PickUp = { 7629 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63), Range = 3, RaidIcon = { { npcID = 14437, questID = 7629 } }, AllOf = { audience, { IsQuestNotOnQuest = 7629, IsQuestUncompleted = 7629, IsQuestCompleted = 7625 } }, Zone = 1428, _index = 1 },
        { EnterInstance = { dungeonKey = "INSTANCE_289", questID = 7629 }, Note = { "SCHOLOMANCE_GROUP_SHARED_KEY" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1422, 68.5, 72.58), AllOf = { audience, { IsQuestOnQuest = 7629, IsQuestUncompleted = 7629, Not = { IsQuestReadyForTurnIn = 7629 } } }, Zone = 1422, _index = 2 },
        { Qpart = { [7629] = { 1 } }, Note = { "SCHOLOMANCE_IMP_PARCHMENT" }, Button = { ["7629-1"] = 18688 }, NoArrow = true, Dungeon = "INSTANCE_289", AllOf = { audience, { IsQuestOnQuest = 7629, IsQuestUncompleted = 7629, Not = { IsQuestReadyForTurnIn = 7629 } } }, _index = 3 },
        { LeaveInstance = { dungeonKey = "INSTANCE_289", questID = 7629 }, NoArrow = true, Dungeon = "INSTANCE_289", AllOf = { audience, { IsQuestOnQuest = 7629, IsQuestUncompleted = 7629, IsQuestReadyForTurnIn = 7629 } }, _index = 4 },
        { Done = { 7629 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63), Range = 3, RaidIcon = { { npcID = 14437, questID = 7629 } }, AllOf = { audience, { IsQuestOnQuest = 7629, IsQuestUncompleted = 7629 } }, Zone = 1428, _index = 5 },
        { RouteCompleted = true, _index = 6 },
    },
}
