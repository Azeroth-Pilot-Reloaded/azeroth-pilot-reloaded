local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional raid quest collection; group supplies access and travel, no interior navigation.
APR.RouteQuestStepList["Forever-Class-Hunter-Rhokdelar-Sinew-Raid-Collection"] = {
    label = L["FOREVER_HUNTER_SINEW_RAID"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1448,
    levelRange = { min = 60 },
    autoStartOnMap = false,
    conditions = { Class = "HUNTER", MinLevel = 60, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" }, AllOf = { { IsQuestCompleted = 7632 } } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" }, AllOf = { { IsQuestCompleted = 7632 } } } } },
    steps = {
        { PickUp = { 7635 }, ExtraLineText = { "ACCEPT_RAID_QUEST_ANCIENT" }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 48.31, 24.43), Range = 5, RaidIcon = { { npcID = 14525, questID = 7635 } }, AllOf = { { IsQuestCompleted = 7632 } }, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" } } }, Class = "HUNTER", IsQuestCompleted = 7632, IsQuestNotOnQuest = 7635, IsQuestUncompleted = 7635, MinLevel = 60, Zone = 1448, _index = 1, },
        { LootItems = { { itemID = 18705, quantity = 1, includeBank = false } }, ExtraLineText = { "COLLECT_DRAGON_SINEW_RAID" }, NoArrow = true, Dungeon = "INSTANCE_249", InstanceQuest = true, AllOf = { { IsQuestCompleted = 7632 } }, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" } } }, Class = "HUNTER", IsQuestOnQuest = 7635, MinLevel = 60, Not = { IsQuestReadyForTurnIn = 7635 }, _index = 2, },
        { Qpart = { [7635] = { 1 } }, NoArrow = true, Dungeon = "INSTANCE_249", InstanceQuest = true, AllOf = { { IsQuestCompleted = 7632 } }, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" } } }, Class = "HUNTER", IsQuestOnQuest = 7635, MinLevel = 60, _index = 3, },
        { RouteCompleted = true, AllOf = { { AnyOf = { { IsQuestReadyForTurnIn = 7635 }, { IsQuestCompleted = 7635 } } }, { IsQuestCompleted = 7632 } }, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" } } }, Class = "HUNTER", MinLevel = 60, _index = 4 },
    },
}
