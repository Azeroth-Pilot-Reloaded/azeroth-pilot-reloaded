local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional group class quest; select explicitly in the route browser.
APR.RouteQuestStepList["Forever-Class-Mage-Tiara-of-the-Deep"] = {
    label = L["FOREVER_MAGE_DEEP_TIARA"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1445,
    conditions = {
        Class = APR.Classes.Mage,
        MinLevel = 40,
        AnyOf = {
            { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
            { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
        }
    },
    levelRange = { min = 40 },
    autoStartOnMap = false,
    steps = {
        {
            PickUp = { 2846 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            RaidIcon = { { npcID = 6546, questID = 2846 } },
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 40,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestNotOnQuest = 2846,
            IsQuestUncompleted = 2846,
            Zone = 1445,
            _index = 1
        },
        {
            Waypoint = 2846,
            NonSkippableWaypoint = true,
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1446, 38.73, 19.74),
            Range = 15,
            ZoneStepTrigger = APR.worldCoordinateConverter:ConvertMapTrigger(1446, 38.73, 19.74, 15),
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 40,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 2846,
            IsQuestUncompleted = 2846,
            Not = { IsQuestReadyForTurnIn = 2846 },
            Zone = 1446,
            _index = 2
        },
        {
            EnterInstance = { dungeonKey = "INSTANCE_209" },
            Dungeon = "INSTANCE_209",
            InstanceQuest = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 40,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 2846,
            IsQuestUncompleted = 2846,
            Not = { IsQuestReadyForTurnIn = 2846 },
            _index = 3
        },
        {
            Qpart = { [2846] = { 1 } },
            GroupTask = 2846,
            NoArrow = true,
            Dungeon = "INSTANCE_209",
            InstanceQuest = true,
            RaidIcon = { { npcID = 7795, questID = 2846, objectiveIndex = 1 } },
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 40,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 2846,
            IsQuestUncompleted = 2846,
            Not = { IsQuestReadyForTurnIn = 2846 },
            _index = 4
        },
        {
            LeaveInstance = { dungeonKey = "INSTANCE_209" },
            NoArrow = true,
            InstanceQuest = true,
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 40,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 2846,
            IsQuestReadyForTurnIn = 2846,
            IsQuestUncompleted = 2846,
            _index = 5
        },
        {
            Done = { 2846 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            RaidIcon = { { npcID = 6546, questID = 2846 } },
            AllOf = {
                {
                    Class = APR.Classes.Mage,
                    MinLevel = 40,
                    AnyOf = {
                        { Faction = "Alliance", Race = { APR.RACES.Gnome, APR.RACES.Human, APR.RACES.Skyborne } },
                        { Faction = "Horde",    Race = { APR.RACES.Orc, APR.RACES.Scourge, APR.RACES.Troll } }
                    }
                }
            },
            IsQuestOnQuest = 2846,
            IsQuestUncompleted = 2846,
            Zone = 1445,
            _index = 6
        },
        {
            RouteCompleted = true,
            _index = 7
        }
    }
}
