local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional materials preparation and turn-in; bracer acquisition is not a dungeon walkthrough.
APR.RouteQuestStepList["Forever-Class-Priest-Earnest-Proposition-Turn-In"] = {
    label = L["FOREVER_PRIEST_EARNEST_PROPOSITION"],
    description = L["EARNEST_PROPOSITION_ROUTE_DESCRIPTION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1454,
    conditions = { Faction = "Horde", Class = "PRIEST", Race = { "Scourge", "Troll" }, MinLevel = 58 },
    levelRange = { min = 58 },
    autoStartOnMap = false,
    steps = {
        {
            PickUp = { 8916 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
            RaidIcon = { { npcID = 16012, questID = 8916 } },
            AllOf = { { Faction = "Horde", Class = "PRIEST", Race = { "Scourge", "Troll" }, MinLevel = 58 } },
            Zone = 1454,
        },
        {
            LootItems = { { itemID = 22381, quantity = 15, includeBank = false, questID = 8916 } },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 34.28, 77.46),
            RaidIcon = { { npcID = 11739 } },
            AllOf = { { Faction = "Horde", Class = "PRIEST", Race = { "Scourge", "Troll" }, MinLevel = 58 } },
            IsQuestOnQuest = 8916,
            Zone = 1451,
        },
        {
            LootItems = { { itemID = 16697, quantity = 1, includeBank = false, questID = 8916 } },
            ExtraLineText = { "ACQUIRE_QUEST_BRACERS" },
            NoArrow = true,
            AllOf = { { Faction = "Horde", Class = "PRIEST", Race = { "Scourge", "Troll" }, MinLevel = 58 } },
            IsQuestOnQuest = 8916,
        },
        {
            LootMoney = { copper = 200000, junkOnly = true, includeEquipped = false },
            ExtraLineText = { "KEEP_QUEST_GOLD_MATERIALS" },
            NoArrow = true,
            AllOf = { { Faction = "Horde", Class = "PRIEST", Race = { "Scourge", "Troll" }, MinLevel = 58 } },
            IsQuestOnQuest = 8916,
        },
        {
            Done = { 8916 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 34.95, 38.29),
            RaidIcon = { { npcID = 16012, questID = 8916 } },
            AllOf = { { Faction = "Horde", Class = "PRIEST", Race = { "Scourge", "Troll" }, MinLevel = 58 } },
            Zone = 1454,
        },
        {
            RouteCompleted = true,
        },
    },
}
