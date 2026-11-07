local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional class segment; select explicitly in the Forever route browser.
APR.RouteQuestStepList["Forever-Horde-Class-Mage-Ju-Ju-Heaps"] = {
    label = L["FOREVER_MAGE_JUJU_HEAPS"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1411,
    conditions = { Faction = "Horde", Class = "MAGE", Race = { "Orc", "Scourge", "Troll" }, MinLevel = 10 },
    levelRange = { min = 10 },
    autoStartOnMap = false,
    steps = {
        {
            Done = { 1883 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1411, 56.31, 75.11), RaidIcon = { { npcID = 5880, questID = 1883 } }, Class = "MAGE",
            Faction = "Horde",
            IsQuestOnQuest = 1883, MinLevel = 10, Race = { "Orc", "Scourge", "Troll" },
            Zone = 1411, _index = 1,
        },
        {
            PickUp = { 1884 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1411, 56.31, 75.11), RaidIcon = { { npcID = 5880, questID = 1884 } },
            AllOf = { { IsQuestUncompleted = 1884 }, { IsQuestNotOnQuest = 1884 }, { IsQuestUncompleted = 1882 }, { IsQuestNotOnQuest = 1882 } }, Class = "MAGE",
            Faction = "Horde", MinLevel = 10, Race = { "Orc", "Scourge", "Troll" },
            Zone = 1411, _index = 2,
        },
        {
            Qpart = { [1884] = { 1 } },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1411, 67.76, 83.50),
            AllOf = { { IsQuestOnQuest = 1884 }, { Not = { IsQuestReadyForTurnIn = 1884 } } }, Class = "MAGE",
            Faction = "Horde", MinLevel = 10, Race = { "Orc", "Scourge", "Troll" },
            Zone = 1411, _index = 3,
        },
        {
            Done = { 1884 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1411, 56.31, 75.11), RaidIcon = { { npcID = 5880, questID = 1884 } }, Class = "MAGE",
            Faction = "Horde",
            IsQuestOnQuest = 1884, MinLevel = 10, Race = { "Orc", "Scourge", "Troll" },
            Zone = 1411, _index = 4,
        },
        {
            RouteCompleted = true, Class = "MAGE",
            Faction = "Horde",
            IsQuestCompleted = 1884, MinLevel = 10, Race = { "Orc", "Scourge", "Troll" }, _index = 5,
        },
    },
}
