local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional class chain; select explicitly in the Forever route browser.
APR.RouteQuestStepList["Forever-Alliance-Class-Rogue-Onin-Report"] = {
    label = L["FOREVER_ROGUE_ONIN_REPORT"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1426,
    conditions = { Faction = "Alliance", Class = "ROGUE", Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" }, MinLevel = 10 },
    levelRange = { min = 10 },
    autoStartOnMap = false,
    steps = {
        {
            PickUp = { 2218 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 47.56, 52.61), RaidIcon = { { npcID = 1234, questID = 2218 } },
            AllOf = { { IsQuestUncompleted = 2218 }, { IsQuestNotOnQuest = 2218 }, { IsQuestUncompleted = 2238 }, { IsQuestNotOnQuest = 2238 }, { IsQuestUncompleted = 2239 }, { IsQuestNotOnQuest = 2239 } }, Class = "ROGUE",
            Faction = "Alliance", MinLevel = 10, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1426, _index = 1,
        },
        {
            Done = { 2218 },
            Note = { "INSIDE_BUILDING", "DOWNSTAIRS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 51.94, 14.82), RaidIcon = { { npcID = 5165, questID = 2218 } }, Class = "ROGUE",
            Faction = "Alliance",
            IsQuestOnQuest = 2218, MinLevel = 10, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1455, _index = 2,
        },
        {
            PickUp = { 2238 },
            Note = { "INSIDE_BUILDING", "DOWNSTAIRS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 51.94, 14.82), RaidIcon = { { npcID = 5165, questID = 2238 } },
            AllOf = { { IsQuestCompleted = 2218 }, { IsQuestUncompleted = 2238 }, { IsQuestNotOnQuest = 2238 }, { IsQuestUncompleted = 2239 }, { IsQuestNotOnQuest = 2239 } }, Class = "ROGUE",
            Faction = "Alliance", MinLevel = 10, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1455, _index = 3,
        },
        {
            Done = { 2238 },
            Note = { "ON_PLATFORM_ABOVE_YOU" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 25.16, 44.45), RaidIcon = { { npcID = 6886, questID = 2238 } }, Class = "ROGUE",
            Faction = "Alliance",
            IsQuestOnQuest = 2238, MinLevel = 10, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1426, _index = 4,
        },
        {
            PickUp = { 2239 },
            Note = { "ON_PLATFORM_ABOVE_YOU" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1426, 25.16, 44.45), RaidIcon = { { npcID = 6886, questID = 2239 } },
            AllOf = { { IsQuestCompleted = 2238 }, { IsQuestUncompleted = 2239 }, { IsQuestNotOnQuest = 2239 } }, Class = "ROGUE",
            Faction = "Alliance", MinLevel = 10, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1426, _index = 5,
        },
        {
            Done = { 2239 },
            Note = { "INSIDE_BUILDING", "DOWNSTAIRS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1455, 51.94, 14.82), RaidIcon = { { npcID = 5165, questID = 2239 } }, Class = "ROGUE",
            Faction = "Alliance",
            IsQuestOnQuest = 2239, MinLevel = 10, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" },
            Zone = 1455, _index = 6,
        },
        {
            RouteCompleted = true, Class = "ROGUE",
            Faction = "Alliance",
            IsQuestCompleted = 2239, MinLevel = 10, Race = { "Dwarf", "Gnome", "Human", "NightElf", "Skyborne" }, _index = 7,
        },
    },
}
