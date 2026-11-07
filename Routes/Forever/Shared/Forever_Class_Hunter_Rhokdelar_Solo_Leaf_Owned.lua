local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional state-based Hunter segment; explicit selection only.
APR.RouteQuestStepList["Forever-Class-Hunter-Rhokdelar-Solo-Leaf-Owned"] = {
    label = L["FOREVER_HUNTER_ANCIENT_STAVE"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1448,
    levelRange = { min = 60 },
    autoStartOnMap = false,
    conditions = {
        Class = "HUNTER",
        MinLevel = 60,
        AnyOf = {
            {
                Faction = "Alliance",
                Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" },
                AllOf = {
                    {
                        AnyOf = {
                            { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                            { IsQuestOnQuest = 7632 },
                            { IsQuestCompleted = 7632 }
                        }
                    }
                }
            },
            {
                Faction = "Horde",
                Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" },
                AllOf = {
                    {
                        AnyOf = {
                            { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                            { IsQuestOnQuest = 7632 },
                            { IsQuestCompleted = 7632 }
                        }
                    }
                }
            }
        }
    },
    steps = {
        {
            PickUp = { [1] = 7632 },
            Button = { ["7632"] = 18703 },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestNotOnQuest = 7632,
            IsQuestUncompleted = 7632,
            ItemCount = { includeBank = false, itemID = 18703, count = 1 },
            MinLevel = 60,
            _index = 1
        },
        {
            LeaveInstance = { dungeonKey = "INSTANCE_409", questID = 7632 },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 7632,
            MinLevel = 60,
            _index = 2
        },
        {
            Done = { [1] = 7632 },
            ExtraLineText = { [1] = "CLEAR_ENEMIES_REVEAL_ANCIENT" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 48.99, 24.44),
            RaidIcon = { { npcID = 14524, questID = 7632 } },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 7632,
            MinLevel = 60,
            Zone = 1448,
            _index = 3
        },
        {
            PickUp = { [1] = 7636 },
            ExtraLineText = { [1] = "CLEAR_ENEMIES_REVEAL_ANCIENT" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 48.99, 24.44),
            Range = 5,
            RaidIcon = { { npcID = 14524, questID = 7636 } },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestCompleted = 7632,
            IsQuestNotOnQuest = 7636,
            IsQuestUncompleted = 7636,
            MinLevel = 60,
            Zone = 1448,
            _index = 4
        },
        {
            Qpart = { [7636] = { [1] = 1 } },
            ExtraLineText = { [1] = "HUNTER_DEMON_SOLO_PATROL", [2] = "HUNTER_DEMON_UNGORO_PATROL" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 40.6, 79.81),
            Range = 20,
            MapMarkers = {
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 40.6, 79.81),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 39.66, 80.76),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 40.56, 83.56),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 44.2, 84.6),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 44.7, 84.97),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 47.33, 83.43),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 48.29, 83.07),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 49.48, 82.62),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 52.88, 82.85),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 54.39, 80.58),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 53.25, 76.57),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 52.94, 71.85),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 52.49, 70.68),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 50.94, 68.32),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 48.26, 68.82),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 46.33, 66.62),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 45.54, 65.95),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 44.59, 63.45),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 41.43, 62.58),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 41.03, 62.86),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 39.76, 60.14),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 40.27, 55.85),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 39.31, 48.7),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 38.48, 45.86),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 38.04, 41.96),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 36.18, 39.79),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 35.09, 38.14),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 33.26, 37.56),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 31.74, 42.57),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 31.26, 43.64),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 31.58, 44.98),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 34.12, 41.24),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 35.41, 41.78),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 36.58, 44.59),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 37.39, 46.16),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 37.11, 50.89),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 38.49, 51.8),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 39.14, 53.13),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 38.36, 56.24),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 38.06, 60.14),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 38.74, 65.34),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 39.38, 67.27),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 39.65, 69.63),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 40.89, 73.47),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 41.67, 73.78),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 42.23, 75.22),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 42.32, 77.27),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 41.33, 78.48),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1449, 40.66, 79.79)
            },
            RaidIcon = { { npcID = 14527, questID = 7636, objectiveIndex = 1 } },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 7636,
            MinLevel = 60,
            Zone = 1449,
            _index = 5
        },
        {
            Qpart = { [7636] = { [1] = 2 } },
            ExtraLineText = { [1] = "HUNTER_DEMON_SOLO_PATROL", [2] = "HUNTER_DEMON_BURNING_STEPPES_PATROL" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 30.95, 53.11),
            Range = 20,
            MapMarkers = {
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 30.95, 53.11),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 28.61, 51.69),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 26.37, 50.79),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 24.46, 49.56),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 22.35, 49.13),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 19.24, 49.41),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 17.32, 53.62),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 17.55, 57.76),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 19.13, 59.29),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 21.32, 59.59),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 24.15, 62.26),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 25.6, 62.31),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 25.54, 64.65),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 27.14, 62.05),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 28.46, 59.49),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 28.81, 56.98),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 30.04, 55.63),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 29.2, 51.92)
            },
            RaidIcon = {
                { npcID = 14529, questID = 7636, objectiveIndex = 2 },
                { npcID = 14534, questID = 7636, objectiveIndex = 2 }
            },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 7636,
            MinLevel = 60,
            Zone = 1428,
            _index = 6
        },
        {
            Qpart = { [7636] = { [1] = 3 } },
            ExtraLineText = { [1] = "HUNTER_DEMON_SOLO_PATROL", [2] = "HUNTER_DEMON_SILITHUS_PATROL" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 27.18, 84.28),
            Range = 20,
            MapMarkers = {
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 27.18, 84.28),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 25.7, 86.85),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 25.51, 88.41),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 22, 86.39),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 21.41, 83.81),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 21.45, 81.74),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 23, 79.45),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 24.79, 76.13),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 26.93, 75.99),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 28.43, 76.18),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 28.98, 80.3),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 29.15, 81.69),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1451, 26.81, 84.8)
            },
            RaidIcon = {
                { npcID = 14536, questID = 7636, objectiveIndex = 3 },
                { npcID = 14530, questID = 7636, objectiveIndex = 3 }
            },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 7636,
            MinLevel = 60,
            Zone = 1451,
            _index = 7
        },
        {
            Qpart = { [7636] = { [1] = 4 } },
            ExtraLineText = { [1] = "HUNTER_DEMON_SOLO_PATROL", [2] = "HUNTER_DEMON_WINTERSPRING_PATROL" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 57.82, 21.11),
            Range = 20,
            MapMarkers = {
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 57.82, 21.11),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 58.43, 21.89),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 58.74, 22.81),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 59.05, 23.6),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 59.71, 24.17),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.19, 23.6),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.38, 22.81),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.15, 21.85),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.63, 21.54),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.84, 21.21),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.33, 20.38),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 59.94, 19.05),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 59.71, 17.37),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.14, 16.22),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.62, 15.32),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.87, 14.53),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 60.51, 13.36),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 59.83, 12.09),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 59.33, 12.32),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 58.73, 12.74),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 58.15, 13.34),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 57.93, 14.47),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 58.11, 15.96),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 58.5, 17.78),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 58.22, 19.31),
                APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 57.98, 20.53)
            },
            RaidIcon = {
                { npcID = 14531, questID = 7636, objectiveIndex = 4 },
                { npcID = 14535, questID = 7636, objectiveIndex = 4 }
            },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 7636,
            MinLevel = 60,
            Zone = 1452,
            _index = 8
        },
        {
            Done = { [1] = 7636 },
            ExtraLineText = { [1] = "CLEAR_ENEMIES_REVEAL_ANCIENT" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 48.99, 24.44),
            RaidIcon = { { npcID = 14524, questID = 7636 } },
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestOnQuest = 7636,
            MinLevel = 60,
            Zone = 1448,
            _index = 9
        },
        {
            RouteCompleted = true,
            AllOf = {
                [1] = {
                    AnyOf = {
                        { ItemCount = { itemID = 18703, count = 1, includeBank = false } },
                        { IsQuestOnQuest = 7632 },
                        { IsQuestCompleted = 7632 }
                    }
                }
            },
            AnyOf = {
                [1] = { Faction = "Alliance", Race = { [1] = "Dwarf", [2] = "Human", [4] = "Skyborne", [3] = "NightElf" } },
                [2] = { Faction = "Horde", Race = { [1] = "Orc", [2] = "Skyborne", [4] = "Troll", [3] = "Tauren" } }
            },
            Class = "HUNTER",
            IsQuestCompleted = 7636,
            MinLevel = 60,
            _index = 10
        }
    }
}
