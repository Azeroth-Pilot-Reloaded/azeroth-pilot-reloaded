local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Class-Warlock-Horde-Felsteed"] = {
    label = L["FOREVER_WARLOCK_FELSTEED"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1413,
    conditions = {
        Faction = "Horde",
        Class = APR.Classes.Warlock,
        Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll },
        MinLevel = 40,
    },
    levelRange = { min = 40 },
    autoStartOnMap = false,
    steps = {
        {
            Waypoint = 4490,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 61.93, 36.72),
            Range = 5,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1413, 61.93, 36.72, 5),
            AllOf = {
                {
                    Faction = "Horde",
                    Class = APR.Classes.Warlock,
                    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll },
                    MinLevel = 40,
                },
            },
            IsQuestUncompleted = 4490,
            Zone = 1413,
        },
        {
            PickUp = { 4490 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 62.63, 35.5),

            RaidIcon = { { npcID = 6251, questID = 4490 } },
            AllOf = {
                {
                    Faction = "Horde",
                    Class = APR.Classes.Warlock,
                    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll },
                    MinLevel = 40,
                },
            },
            IsQuestNotOnQuest = 4490,
            IsQuestUncompleted = 4490,
            Zone = 1413,
        },
        {
            Done = { 4490 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 62.63, 35.5),

            RaidIcon = { { npcID = 6251, questID = 4490 } },
            AllOf = {
                {
                    Faction = "Horde",
                    Class = APR.Classes.Warlock,
                    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll },
                    MinLevel = 40,
                },
            },
            IsQuestOnQuest = 4490,
            Zone = 1413,
        },
        {
            RouteCompleted = true,
        },
    },
}
