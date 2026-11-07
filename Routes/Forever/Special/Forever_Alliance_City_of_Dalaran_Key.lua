local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional key acquisition; select explicitly in the route browser.
APR.RouteQuestStepList["Forever-Alliance-City-of-Dalaran-Key"] = {
    label = L["FOREVER_DALARAN_KEY"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1424,
    conditions = { Faction = "Alliance", MinLevel = 30 },
    levelRange = { min = 30 },
    autoStartOnMap = false,
    steps = {
        {
            Note = { "DUNGEON_SHARED_KEY" },
            Not = { ItemCount = { itemID = 277507, count = 1, includeBank = false } },
            _index = 1,
        },
        {
            PickUp = { 92432 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1424, 48.3, 60.1),
            Range = 5,
            RaidIcon = { { npcID = 247264, questID = 92432 } },
            MinLevel = 30,
            Not = { ItemCount = { itemID = 277507, count = 1, includeBank = false } },
            Zone = 1424,
            _index = 2,
        },
        {
            Done = { 92432 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1421, 68.6, 45.2),
            RaidIcon = { { npcID = 269127, questID = 92432 } },
            Not = { ItemCount = { itemID = 277507, count = 1, includeBank = false } },
            Zone = 1421,
            _index = 3,
        },
        {
            PickUp = { 92458 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1421, 68.6, 45.2),
            Range = 5,
            RaidIcon = { { npcID = 269127, questID = 92458 } },
            IsQuestCompleted = 92432,
            MinLevel = 24,
            Not = { ItemCount = { itemID = 277507, count = 1, includeBank = false } },
            Zone = 1421,
            _index = 4,
        },
        {
            LootItems = { { itemID = 277507, quantity = 1, includeBank = false } },
            ExtraLineText = {
                "QUEST_ACCEPTANCE_GRANTS_KEY",
            },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1421, 68.6, 45.2),
            Zone = 1421,
            _index = 5,
        },
        { RouteCompleted = true, ItemCount = { itemID = 277507, count = 1, includeBank = false }, _index = 6 },
    },
}
