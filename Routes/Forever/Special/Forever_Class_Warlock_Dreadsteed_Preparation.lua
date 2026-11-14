local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local audience = {
    Class = "WARLOCK",
    MinLevel = 60,
    AnyOf = { { Faction = "Alliance", Race = { "Gnome", "Human" } }, { Faction = "Horde", Race = { "Orc", "Scourge", "Troll" } } }
}

APR.RouteQuestStepList["Forever-Class-Warlock-Dreadsteed-Preparation"] = {
    label = L["FOREVER_WARLOCK_DREADSTEED_PREPARATION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1428,
    levelRange = { min = 60 },
    autoStartOnMap = false,
    conditions = {
        AnyOf = { { AllOf = { audience, { Not = { AllOf = { { IsQuestCompleted = 7625 }, { IsQuestCompleted = 7630 } } } } } } }
    },
    steps = {
        {
            PickUp = { 7563 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.69, 31.64),
            Range = 3,
            RaidIcon = { { npcID = 14436, questID = 7563 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7563, IsQuestUncompleted = 7563 } },
            Zone = 1428,
            _index = 1
        },
        {
            Waypoint = 7563,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 65.04, 18.78),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1452, 65.04, 18.78, 7),
            AllOf = { audience, { IsQuestOnQuest = 7563, IsQuestUncompleted = 7563, Not = { IsQuestReadyForTurnIn = 7563 } } },
            Zone = 1452,
            _index = 2
        },
        {
            Qpart = { [7563] = { 1 } },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1452, 63.65, 16.33),
            AllOf = { audience, { IsQuestOnQuest = 7563, IsQuestUncompleted = 7563, Not = { IsQuestReadyForTurnIn = 7563 } } },
            Zone = 1452,
            _index = 3
        },
        {
            Done = { 7563 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.69, 31.64),
            Range = 3,
            RaidIcon = { { npcID = 14436, questID = 7563 } },
            AllOf = { audience, { IsQuestOnQuest = 7563, IsQuestUncompleted = 7563 } },
            Zone = 1428,
            _index = 4
        },
        {
            PickUp = { 7564 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.69, 31.64),
            Range = 3,
            RaidIcon = { { npcID = 14436, questID = 7564 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7564, IsQuestUncompleted = 7564, IsQuestCompleted = 7563 } },
            Zone = 1428,
            _index = 5
        },
        {
            Done = { 7564 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7564 } },
            AllOf = { audience, { IsQuestOnQuest = 7564, IsQuestUncompleted = 7564 } },
            Zone = 1428,
            _index = 6
        },
        {
            PickUp = { 7626 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.69, 31.64),
            Range = 3,
            RaidIcon = { { npcID = 14436, questID = 7626 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7626, IsQuestUncompleted = 7626, IsQuestCompleted = 7564 } },
            Zone = 1428,
            _index = 7
        },
        {
            PickUp = { 7627 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.69, 31.64),
            Range = 3,
            RaidIcon = { { npcID = 14436, questID = 7627 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7627, IsQuestUncompleted = 7627, IsQuestCompleted = 7564 } },
            Zone = 1428,
            _index = 8
        },
        {
            PickUp = { 7628 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.69, 31.64),
            Range = 3,
            RaidIcon = { { npcID = 14436, questID = 7628 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7628, IsQuestUncompleted = 7628, IsQuestCompleted = 7564 } },
            Zone = 1428,
            _index = 9
        },
        {
            LootItems = { { itemID = 9264, quantity = 10, questID = 7626, includeBank = false } },
            Note = { "BUY_AUCTION_HOUSE_TRADE_PLAYERS_CRAFT_ALCHEMY" },
            AllOf = { audience, { IsQuestOnQuest = 7626, IsQuestUncompleted = 7626, Not = { IsQuestReadyForTurnIn = 7626 } } },
            _index = 10
        },
        {
            LootItems = { { itemID = 14344, quantity = 6, questID = 7627, includeBank = false } },
            Note = { "OBTAIN_ENCHANTING_TRADE" },
            AllOf = { audience, { IsQuestOnQuest = 7627, IsQuestUncompleted = 7627, Not = { IsQuestReadyForTurnIn = 7627 } } },
            _index = 11
        },
        {
            LootItems = { { itemID = 11370, quantity = 25, questID = 7627, includeBank = false } },
            Note = { "OBTAIN_MINING_TRADE" },
            AllOf = { audience, { IsQuestOnQuest = 7627, IsQuestUncompleted = 7627, Not = { IsQuestReadyForTurnIn = 7627 } } },
            _index = 12
        },
        {
            LootItems = { { itemID = 15416, quantity = 35, questID = 7628, includeBank = false } },
            Note = { "OBTAIN_SKINNING_TRADE" },
            AllOf = { audience, { IsQuestOnQuest = 7628, IsQuestUncompleted = 7628, Not = { IsQuestReadyForTurnIn = 7628 } } },
            _index = 13
        },
        {
            Done = { 7626 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7626 } },
            AllOf = { audience, { IsQuestOnQuest = 7626, IsQuestUncompleted = 7626 } },
            Zone = 1428,
            _index = 14
        },
        {
            Done = { 7627 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7627 } },
            AllOf = { audience, { IsQuestOnQuest = 7627, IsQuestUncompleted = 7627 } },
            Zone = 1428,
            _index = 15
        },
        {
            Done = { 7628 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7628 } },
            AllOf = { audience, { IsQuestOnQuest = 7628, IsQuestUncompleted = 7628 } },
            Zone = 1428,
            _index = 16
        },
        {
            PickUp = { 7630 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7630 } },
            AllOf = {
                audience,
                {
                    IsQuestNotOnQuest = 7630,
                    IsQuestUncompleted = 7630,
                    AllOf = { { IsQuestCompleted = 7626 }, { IsQuestCompleted = 7627 }, { IsQuestCompleted = 7628 } }
                }
            },
            Zone = 1428,
            _index = 17
        },
        {
            LootItems = { { itemID = 12360, quantity = 3, questID = 7630, includeBank = false } },
            Note = { "BUY_AUCTION_HOUSE_TRADE_PLAYERS_CRAFT_ALCHEMY" },
            AllOf = { audience, { IsQuestOnQuest = 7630, IsQuestUncompleted = 7630, Not = { IsQuestReadyForTurnIn = 7630 } } },
            _index = 18
        },
        {
            Done = { 7630 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7630 } },
            AllOf = { audience, { IsQuestOnQuest = 7630, IsQuestUncompleted = 7630 } },
            Zone = 1428,
            _index = 19
        },
        {
            PickUp = { 7623 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7623 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7623, IsQuestUncompleted = 7623, IsQuestCompleted = 7564 } },
            Zone = 1428,
            _index = 20
        },
        {
            BuyMerchant = { { itemID = 18802, quantity = 2, targetStock = true } },
            Note = { "KEEP_DISGUISE_POTION" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437 } },
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } }
                    }
                }
            },
            Zone = 1428,
            _index = 21
        },
        {
            BuyMerchant = { { itemID = 18802, quantity = 1, targetStock = true } },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437 } },
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7624, IsQuestReadyForTurnIn = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625,   Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1428,
            _index = 22
        },
        {
            UseItem = { itemID = 18802 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.42, 58.61),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    },
                    DontHaveAura = 23179
                }
            },
            Zone = 1448,
            _index = 23
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.42, 58.61),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 35.42, 58.61, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 24
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.47, 58.18),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 35.47, 58.18, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 25
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 36.04, 56.42),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 36.04, 56.42, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 26
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 36.69, 55.99),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 36.69, 55.99, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 27
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 36.64, 54.91),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 36.64, 54.91, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 28
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.19, 54.1),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 38.19, 54.1, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 29
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.1, 54.04),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.1, 54.04, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 30
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.61, 52.21),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.61, 52.21, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 31
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 36.26, 52.52),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 36.26, 52.52, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 32
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.2, 50.82),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.2, 50.82, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 33
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.9, 49.72),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 38.9, 49.72, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 34
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 39.85, 49.23),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 39.85, 49.23, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 35
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 40.04, 47.8),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 40.04, 47.8, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 36
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.56, 46.06),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 38.56, 46.06, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 37
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.43, 46.24),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.43, 46.24, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 38
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.03, 46.52),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 38.03, 46.52, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 39
        },
        {
            Waypoint = 7623,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.33, 47.22),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.33, 47.22, 7),
            AllOf = {
                audience,
                {
                    AnyOf = {
                        { IsQuestOnQuest = 7623 },
                        { IsQuestOnQuest = 7624 },
                        { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } }
                    }
                }
            },
            Zone = 1448,
            _index = 40
        },
        {
            UseItem = { itemID = 18802 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.93, 44.41),
            AllOf = { audience, { IsQuestOnQuest = 7623, IsQuestUncompleted = 7623, DontHaveAura = 23179 } },
            Zone = 1448,
            _index = 41
        },
        {
            Done = { 7623 },
            Note = { "RENEW_DISGUISE_HOSTILE_NPC" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.93, 44.41),
            Range = 3,
            RaidIcon = { { npcID = 9516, questID = 7623 } },
            AllOf = { audience, { IsQuestOnQuest = 7623, IsQuestUncompleted = 7623 } },
            Zone = 1448,
            _index = 42
        },
        {
            PickUp = { 7624 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.93, 44.41),
            Range = 3,
            RaidIcon = { { npcID = 9516, questID = 7624 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestCompleted = 7623 } },
            Zone = 1448,
            _index = 43
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 36.2, 46.09),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 36.2, 46.09, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 44
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.95, 47.27),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.95, 47.27, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 45
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.94, 45.39),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.94, 45.39, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 46
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.65, 46.62),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.65, 46.62, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 47
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 39.57, 47.05),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 39.57, 47.05, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 48
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 40.06, 48.94),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 40.06, 48.94, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 49
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 39.89, 49.17),
            Range = 5,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 39.89, 49.17, 5),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 50
        },
        {
            Qpart = { [7624] = { 1 } },
            Note = { "DEFEAT_DISGUISED_TRAITOR" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 40.77, 48.42),
            RaidIcon = { { npcID = 14523, questID = 7624, objectiveIndex = 1 } },
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, Not = { IsQuestReadyForTurnIn = 7624 } } },
            Zone = 1448,
            _index = 51
        },
        {
            UseItem = { itemID = 18802 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 40.49, 48.48),
            AllOf = {
                audience,
                { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624, DontHaveAura = 23179 }
            },
            Zone = 1448,
            _index = 52
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 40.49, 48.48),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 40.49, 48.48, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624 } },
            Zone = 1448,
            _index = 53
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 40.04, 47.71),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 40.04, 47.71, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624 } },
            Zone = 1448,
            _index = 54
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.49, 46.17),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 38.49, 46.17, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624 } },
            Zone = 1448,
            _index = 55
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.22, 46.82),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 38.22, 46.82, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624 } },
            Zone = 1448,
            _index = 56
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.35, 45.87),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.35, 45.87, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624 } },
            Zone = 1448,
            _index = 57
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 38.03, 46.48),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 38.03, 46.48, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624 } },
            Zone = 1448,
            _index = 58
        },
        {
            Waypoint = 7624,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 37.46, 47.35),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1448, 37.46, 47.35, 7),
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624, IsQuestReadyForTurnIn = 7624 } },
            Zone = 1448,
            _index = 59
        },
        {
            Done = { 7624 },
            Note = { "RENEW_DIALOGUE_DISGUISE" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.93, 44.41),
            Range = 3,
            RaidIcon = { { npcID = 9516, questID = 7624 } },
            AllOf = { audience, { IsQuestOnQuest = 7624, IsQuestUncompleted = 7624 } },
            Zone = 1448,
            _index = 60
        },
        {
            PickUp = { 7625 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 35.93, 44.41),
            Range = 3,
            RaidIcon = { { npcID = 9516, questID = 7625 } },
            AllOf = { audience, { IsQuestNotOnQuest = 7625, IsQuestUncompleted = 7625, IsQuestCompleted = 7624 } },
            Zone = 1448,
            _index = 61
        },
        {
            BuyMerchant = { { itemID = 18687, quantity = 1, questID = 7625, targetStock = true } },
            Note = { "DREADSTEED_QUEST_COST" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1448, 36.17, 44.46),
            Range = 3,
            RaidIcon = { { npcID = 14522 } },
            AllOf = { audience, { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625, Not = { IsQuestReadyForTurnIn = 7625 } } },
            Zone = 1448,
            _index = 62
        },
        {
            Done = { 7625 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1428, 12.43, 31.63),
            Range = 3,
            RaidIcon = { { npcID = 14437, questID = 7625 } },
            AllOf = { audience, { IsQuestOnQuest = 7625, IsQuestUncompleted = 7625 } },
            Zone = 1428,
            _index = 63
        },
        {
            RouteCompleted = true,
            _index = 64
        }
    }
}
