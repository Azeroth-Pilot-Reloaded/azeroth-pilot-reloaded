local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Optional class segments; select the group finale separately.
APR.RouteQuestStepList["Forever-Class-Mage-Tabetha-Wand-Preparation"] = {
    label = L["FOREVER_MAGE_TABETHA_PREPARATION"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Class,
    mapID = 1445,
    conditions = {
        Class = "MAGE",
        MinLevel = 30,
        AnyOf = {
            { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
            { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
        }
    },
    levelRange = { min = 30 },
    autoStartOnMap = false,
    steps = {
        {
            PickUp = { 1947 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 49.5, 85.84),
            Range = 3,
            RaidIcon = { { npcID = 5497, questID = 1947 } },
            AllOf = { { IsQuestNotOnQuest = 1947 }, { IsQuestUncompleted = 1947 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            Faction = "Alliance",
            MinLevel = 30,
            Zone = 1453
        },
        {
            PickUp = { 1947 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1454, 38.45, 86.14),
            Range = 3,
            RaidIcon = { { npcID = 5885, questID = 1947 } },
            AllOf = { { IsQuestNotOnQuest = 1947 }, { IsQuestUncompleted = 1947 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            Faction = "Horde",
            MinLevel = 30,
            Zone = 1454
        },
        {
            Done = { 1947 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            Range = 3,
            RaidIcon = { { npcID = 6546, questID = 1947 } },
            AllOf = { { IsQuestOnQuest = 1947 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1445
        },
        {
            PickUp = { 1949 },
            ExtraLineText = { "WAIT_FOR_NPC_END_RP" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            Range = 3,
            RaidIcon = { { npcID = 6546, questID = 1949 } },
            AllOf = { { IsQuestNotOnQuest = 1949 }, { IsQuestUncompleted = 1949 }, { IsQuestCompleted = 1947 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1445
        },
        {
            Done = { 1949 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1441, 78.29, 75.7),
            Range = 3,
            RaidIcon = { { npcID = 6548, questID = 1949 } },
            AllOf = { { IsQuestOnQuest = 1949 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1441
        },
        {
            PickUp = { 1950 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1441, 78.29, 75.7),
            Range = 3,
            RaidIcon = { { npcID = 6548, questID = 1950 } },
            AllOf = { { IsQuestNotOnQuest = 1950 }, { IsQuestUncompleted = 1950 }, { IsQuestCompleted = 1949 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1441
        },
        {
            Qpart = { [1950] = { 1 } },
            Emote = { emote = "BECKON", npcID = 6626, manual = true },
            Note = { "BECKON_SECRET_PHRASE" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1441, 79.6, 75.6),
            RaidIcon = { { npcID = 6626, questID = 1950, objectiveIndex = 1 } },
            AllOf = { { IsQuestOnQuest = 1950 }, { Not = { IsQuestReadyForTurnIn = 1950 } } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1441
        },
        {
            Done = { 1950 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1441, 78.29, 75.7),
            Range = 3,
            RaidIcon = { { npcID = 6548, questID = 1950 } },
            AllOf = { { IsQuestOnQuest = 1950 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1441
        },
        {
            PickUp = { 1951 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1441, 78.29, 75.7),
            Range = 3,
            RaidIcon = { { npcID = 6548, questID = 1951 } },
            AllOf = { { IsQuestNotOnQuest = 1951 }, { IsQuestUncompleted = 1951 }, { IsQuestCompleted = 1950 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1441
        },
        {
            PickUp = { 1948 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            Range = 3,
            RaidIcon = { { npcID = 6546, questID = 1948 } },
            AllOf = { { IsQuestNotOnQuest = 1948 }, { IsQuestUncompleted = 1948 }, { IsQuestCompleted = 1947 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1445
        },
        {
            LootItems = { { itemID = 7273, quantity = 10, questID = 1948, includeBank = false } },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1417, 66.66, 64.37),
            AllOf = {
                { IsQuestOnQuest = 1948 },
                { ItemCount = { itemID = 7272, count = 1, operator = "<" } },
                { Not = { IsQuestReadyForTurnIn = 1948 } }
            },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1417
        },
        {
            Qpart = { [1948] = { 2 } },
            Note = { "CHARGE_TOTEM_STICKS" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1417, 52.06, 50.69),
            Button = { ["1948-2"] = 7273 },
            AllOf = { { IsQuestOnQuest = 1948 }, { Not = { IsQuestReadyForTurnIn = 1948 } } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1417
        },
        {
            LootItems = { { itemID = 1529, quantity = 1, questID = 1948, includeBank = false } },
            Note = { "OBTAIN_QUEST_JADE" },
            AllOf = { { IsQuestOnQuest = 1948 }, { Not = { IsQuestReadyForTurnIn = 1948 } } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30
        },
        {
            Done = { 1948 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            Range = 3,
            RaidIcon = { { npcID = 6546, questID = 1948 } },
            AllOf = { { IsQuestOnQuest = 1948 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1445
        },
        {
            RouteCompleted = true,
            AllOf = {
                { IsQuestCompleted = 1948 },
                { AnyOf = { { IsQuestOnQuest = 1951 }, { IsQuestCompleted = 1951 }, { IsQuestCompleted = 1952 } } }
            },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30
        }
    }
}

APR.RouteQuestStepList["Forever-Class-Mage-Tabetha-Wand-Library"] = {
    label = L["FOREVER_MAGE_TABETHA_LIBRARY"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1445,
    conditions = {
        Class = "MAGE",
        MinLevel = 30,
        AnyOf = {
            { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
            { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
        },
        IsQuestCompleted = 1948
    },
    levelRange = { min = 30 },
    autoStartOnMap = false,
    steps = {
        {
            EnterInstance = {
                dungeonKey = "INSTANCE_189",
                questID = 1951,
                entranceID = "entrance-9015-from-1420-at-8533-3227"
            },
            Note = { "SCARLET_LIBRARY_ENTRANCE" },
            AllOf = { { IsQuestOnQuest = 1951 }, { Not = { IsQuestReadyForTurnIn = 1951 } }, { IsQuestCompleted = 1948 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30
        },
        {
            Qpart = { [1951] = { 1 } },
            Note = { "LOOT_LIBRARY_ATHENAEUM_BOOK" },
            Dungeon = "INSTANCE_189",
            AllOf = { { IsQuestOnQuest = 1951 }, { Not = { IsQuestReadyForTurnIn = 1951 } }, { IsQuestCompleted = 1948 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30
        },
        {
            LeaveInstance = { dungeonKey = "INSTANCE_189", questID = 1951 },
            AllOf = { { IsQuestOnQuest = 1951 }, { IsQuestReadyForTurnIn = 1951 }, { IsQuestCompleted = 1948 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30
        },
        {
            Done = { 1951 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            Range = 3,
            RaidIcon = { { npcID = 6546, questID = 1951 } },
            AllOf = { { IsQuestOnQuest = 1951 }, { IsQuestCompleted = 1948 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1445
        },
        {
            PickUp = { 1952 },
            ExtraLineText = { "WAIT_FOR_NPC_END_RP" },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            Range = 3,
            RaidIcon = { { npcID = 6546, questID = 1952 } },
            AllOf = {
                { IsQuestNotOnQuest = 1952 },
                { IsQuestUncompleted = 1952 },
                { IsQuestCompleted = 1948 },
                { IsQuestCompleted = 1951 },
                { IsQuestCompleted = 1948 }
            },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1445
        },
        {
            Done = { 1952 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1445, 46.06, 57.09),
            Range = 3,
            RaidIcon = { { npcID = 6546, questID = 1952 } },
            AllOf = { { IsQuestOnQuest = 1952 }, { IsQuestCompleted = 1948 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30,
            Zone = 1445
        },
        {
            RouteCompleted = true,
            AllOf = { { IsQuestCompleted = 1952 }, { IsQuestCompleted = 1948 } },
            AnyOf = {
                { Faction = "Alliance", Race = { "Gnome", "Human", "Skyborne" } },
                { Faction = "Horde",    Race = { "Orc", "Scourge", "Troll" } }
            },
            Class = "MAGE",
            MinLevel = 30
        }
    }
}
