local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional Hunter segment; explicit selection only.
APR.RouteQuestStepList["Forever-Class-Hunter-Wavethrashing"] = {
    expansion = APR.EXPANSIONS.Forever,
    label = L["FOREVER_HUNTER_WAVETHRASHING"],
    autoStartOnMap = false,
    category = APR.CATEGORIES.Class,
    levelRange = { min = 50 },
    conditions = {
        IsQuestCompleted = 8153,
        Class = 3,
        MinLevel = 50,
        AnyOf = {
            [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
            [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
        }
    },
    mapID = 1447,
    gameVersion = APR.GAME_VERSIONS.Forever,
    steps = {
        {
            PickUp = { [1] = 8231 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 42.4, 42.62),
            Range = 5,
            RaidIcon = { { npcID = 8405, questID = 8231 } },
            AnyOf = {
                [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
                [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
            },
            Class = "HUNTER",
            IsQuestCompleted = 8153,
            IsQuestNotOnQuest = 8231,
            IsQuestUncompleted = 8231,
            MinLevel = 50,
            Zone = 1447,
            _index = 1
        },
        {
            Note = { [1] = "UNDERWATER_SCALES_ELITE_WARNING" },
            AnyOf = {
                [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
                [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
            },
            Class = "HUNTER",
            Faction = "Alliance",
            Hardcore = true,
            IsQuestOnQuest = 8231,
            MinLevel = 50,
            Not = { IsQuestReadyForTurnIn = 8231 },
            _index = 2
        },
        {
            Waypoint = 8231,
            NonSkippableWaypoint = true,
            ExtraLineText = { "DESCEND_CAREFULLY" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 33.68, 48.68),
            Range = 7,
            AnyOf = {
                [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
                [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 8231,
            MinLevel = 50,
            Not = { IsQuestReadyForTurnIn = 8231 },
            Zone = 1447,
            _index = 3
        },
        {
            Waypoint = 8231,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 40.54, 47.84),
            Range = 7,
            AnyOf = {
                [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
                [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 8231,
            MinLevel = 50,
            Not = { IsQuestReadyForTurnIn = 8231 },
            Zone = 1447,
            _index = 4
        },
        {
            Qpart = { [8231] = { [1] = 1 } },
            ExtraLineText = { "SEARCH_UNDERWATER_SCALES" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 52.61, 41.87),
            Range = 30,
            MapMarkers = {
                APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 52.61, 41.87),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 59.77, 37.36),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 67.20, 33.08),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 72.19, 35.39),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 84.34, 33.76),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 86.73, 25.65)
            },
            AnyOf = {
                [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
                [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 8231,
            MinLevel = 50,
            Zone = 1447,
            _index = 5
        },
        {
            Done = { [1] = 8231 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1447, 42.4, 42.62),
            RaidIcon = { { npcID = 8405, questID = 8231 } },
            AnyOf = {
                [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
                [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 8231,
            MinLevel = 50,
            Zone = 1447,
            _index = 6
        },
        {
            RouteCompleted = true,
            AnyOf = {
                [1] = { Race = { [1] = "Dwarf", [2] = "Human", [3] = "NightElf", [4] = "Skyborne" }, Faction = "Alliance" },
                [2] = { Race = { [1] = "Orc", [2] = "Skyborne", [3] = "Tauren", [4] = "Troll" }, Faction = "Horde" }
            },
            Class = "HUNTER",
            IsQuestCompleted = 8231,
            MinLevel = 50,
            _index = 7
        }
    }
}
