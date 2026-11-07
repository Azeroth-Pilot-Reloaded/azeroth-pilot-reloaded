local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional raid quest collection; group supplies access and travel, no interior navigation.
APR.RouteQuestStepList["Forever-Class-Hunter-Rhokdelar-Leaf-Raid-Collection"] = {
    label = L["FOREVER_HUNTER_LEAF_RAID"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1448,
    levelRange = { min = 60 },
    autoStartOnMap = false,
    conditions = { Class = "HUNTER", MinLevel = 60, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" } } } },
    steps = {
        { LootItems = { { itemID = 18703, quantity = 1, includeBank = false } }, ExtraLineText = { "COLLECT_ANCIENT_LEAF_RAID" }, NoArrow = true, Dungeon = "INSTANCE_409", InstanceQuest = true, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" } } }, Class = "HUNTER", IsQuestNotOnQuest = 7632, IsQuestUncompleted = 7632, MinLevel = 60, _index = 1 },
        { LeaveInstance = { dungeonKey = "INSTANCE_409" }, NoArrow = true, Dungeon = "INSTANCE_409", InstanceQuest = true, AllOf = { { AnyOf = { { ItemCount = { itemID = 18703, count = 1, includeBank = false } }, { IsQuestOnQuest = 7632 } } } }, AnyOf = { [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" }, [2] = { Race = { [1] = "Orc", [2] = "Tauren", [3] = "Troll", [4] = "Skyborne" }, Faction = "Horde" } }, Class = "HUNTER", IsQuestUncompleted = 7632, MinLevel = 60, _index = 2 },
        { RouteCompleted = true, AllOf = { { AnyOf = { { ItemCount = { itemID = 18703, count = 1, includeBank = false } }, { IsQuestOnQuest = 7632 }, { IsQuestCompleted = 7632 } } } }, AnyOf = { { Faction = "Alliance", Race = { "Dwarf", "Human", "NightElf", "Skyborne" } }, { Faction = "Horde", Race = { "Orc", "Tauren", "Troll", "Skyborne" } } }, Class = "HUNTER", MinLevel = 60, _index = 3 },
    },
}
