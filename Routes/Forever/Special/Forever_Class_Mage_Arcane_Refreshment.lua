local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional group class quest; select explicitly in the route browser.
-- Entry contract: group access through the North and Conservatory doors
-- (Crescent Key held by any member, or a capable group opener).
-- Interior quest NPC/objective uses native quest guidance; no invented map point.
APR.RouteQuestStepList["Forever-Class-Mage-Arcane-Refreshment"] = {
    label = L["FOREVER_MAGE_ARCANE_REFRESHMENT"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1444,
    conditions = {
        Class = APR.Classes.Mage,
        MinLevel = 60,
        AnyOf = {
            { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
            { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
        }
    },
    levelRange = { min = 60 },
    autoStartOnMap = false,
    steps = {
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.13, 44.67),
            Range = 20,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.13, 44.67, 20),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 1
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.52, 39.51),
            Range = 15,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.52, 39.51, 15),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 2
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.72, 38.78),
            Range = 15,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.72, 38.78, 15),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 3
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.15, 34.87),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.15, 34.87, 7),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 4
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 62.49, 24.89),
            Range = 5,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 62.49, 24.89, 5),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 5
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 62.82, 24.46),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 62.82, 24.46, 7),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 6
        },
        {
            EnterInstance = { dungeonKey = "INSTANCE_429" },
            Dungeon = "INSTANCE_429",
            InstanceQuest = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            _index = 7
        },
        {
            PickUp = { 7463 },
            NoArrow = true,
            Dungeon = "INSTANCE_429",
            InstanceQuest = true,
            RaidIcon = { { npcID = 14368, questID = 7463 } },
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 7463,
            IsQuestUncompleted = 7463,
            _index = 8
        },
        {
            LeaveInstance = { dungeonKey = "INSTANCE_429" },
            NoArrow = true,
            InstanceQuest = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            _index = 9
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.13, 44.67),
            Range = 20,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.13, 44.67, 20),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            Zone = 1444,
            _index = 10
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.52, 39.51),
            Range = 15,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.52, 39.51, 15),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            Zone = 1444,
            _index = 11
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.72, 38.78),
            Range = 15,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.72, 38.78, 15),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            Zone = 1444,
            _index = 12
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.15, 34.87),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.15, 34.87, 7),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            Zone = 1444,
            _index = 13
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 64.85, 30.18),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 64.85, 30.18, 7),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            Zone = 1444,
            _index = 14
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 64.85, 29.54),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 64.85, 29.54, 7),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            Zone = 1444,
            _index = 15
        },
        {
            EnterInstance = { dungeonKey = "INSTANCE_429" },
            Dungeon = "INSTANCE_429",
            InstanceQuest = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            _index = 16
        },
        {
            Qpart = { [7463] = { 1 } },
            GroupTask = 7463,
            NoArrow = true,
            Dungeon = "INSTANCE_429",
            InstanceQuest = true,
            RaidIcon = { { npcID = 13280, questID = 7463, objectiveIndex = 1 } },
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            Not = { IsQuestReadyForTurnIn = 7463 },
            _index = 17
        },
        {
            LeaveInstance = { dungeonKey = "INSTANCE_429" },
            NoArrow = true,
            InstanceQuest = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            _index = 18
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.13, 44.67),
            Range = 20,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.13, 44.67, 20),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 19
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 59.52, 39.51),
            Range = 15,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 59.52, 39.51, 15),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 20
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.72, 38.78),
            Range = 15,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.72, 38.78, 15),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 21
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 61.15, 34.87),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 61.15, 34.87, 7),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 22
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 62.49, 24.89),
            Range = 5,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 62.49, 24.89, 5),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 23
        },
        {
            Waypoint = 7463,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 62.82, 24.46),
            Range = 7,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1444, 62.82, 24.46, 7),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            Zone = 1444,
            _index = 24
        },
        {
            EnterInstance = { dungeonKey = "INSTANCE_429" },
            Dungeon = "INSTANCE_429",
            InstanceQuest = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestReadyForTurnIn = 7463,
            IsQuestUncompleted = 7463,
            _index = 25
        },
        {
            Done = { 7463 },
            NoArrow = true,
            Dungeon = "INSTANCE_429",
            InstanceQuest = true,
            RaidIcon = { { npcID = 14368, questID = 7463 } },
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 7463,
            IsQuestUncompleted = 7463,
            _index = 26
        },
        {
            RouteCompleted = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 60,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestCompleted = 7463,
            _index = 27
        }
    }
}
