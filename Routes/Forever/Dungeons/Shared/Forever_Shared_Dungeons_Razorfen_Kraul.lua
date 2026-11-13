local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Razorfen-Kraul"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 29,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Razorfen Kraul"],
    levelRange = {
        max = 38,
        min = 29,
    },
    mapID = 1413,
    steps = { {
        PickUp = { 1100 },
        Button = {
            ["1100"] = 5791,
        },
        NoArrow = true,
        Faction = "Alliance",
        ItemCount = {
            count = 1,
            itemID = 5791,
        },
        MinLevel = 29,
        _index = 1,
    }, {
        PickUp = { 1102 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 35.97, 59.92),
        RaidIcon = { {
            npcID = 4451,
            questID = 1102,
        } },
        Faction = "Horde",
        MinLevel = 29,
        Zone = 1456,
        _index = 2,
    }, {
        PickUp = { 1109 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 48.82, 69.28),
        RaidIcon = { {
            npcID = 2055,
            questID = 1109,
        } },
        Faction = "Horde",
        MinLevel = 30,
        Zone = 1458,
        _index = 3,
    }, {
        PickUp = { 1221 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 62.37, 37.62),
        RaidIcon = { {
            npcID = 3446,
            questID = 1221,
        } },
        MinLevel = 20,
        Zone = 1413,
        _index = 4,
    }, {
        PickUp = { 96264 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1417, 59.84, 27.57),
        RaidIcon = { {
            npcID = 259023,
            questID = 96264,
        } },
        Class = { "SHAMAN" },
        Faction = "Alliance",
        MinLevel = 30,
        Zone = 1417,
        _index = 5,
    }, {
        Qpart = {
            [1100] = { 1 },
        },
        NoArrow = true,
        IsQuestOnQuest = 1100,
        _index = 6,
    }, {
        Done = { 1100 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 89.64, 46.57),
        RaidIcon = { {
            npcID = 4048,
            questID = 1100,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 1100,
        Zone = 1444,
        _index = 7,
    }, {
        PickUp = { 1101 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 89.64, 46.57),
        RaidIcon = { {
            npcID = 4048,
            questID = 1101,
        } },
        AnyOf = { {
            IsQuestCompleted = 1100,
        } },
        Faction = "Alliance",
        MinLevel = 29,
        Zone = 1444,
        _index = 8,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_47",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 42.237, 89.832),
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        Zone = 1413,
        _index = 9,
    }, {
        PickUp = { 1142 },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 4510,
            questID = 1142,
        } },
        Faction = "Alliance",
        MinLevel = 25,
        _index = 10,
    }, {
        PickUp = { 1144 },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 4508,
            questID = 1144,
        } },
        MinLevel = 23,
        _index = 11,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_47",
            name = "Roogug",
            npcID = 6168,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        _index = 12,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_47",
            name = "Aggem Thorncurse",
            npcID = 4424,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        _index = 13,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_47",
            name = "Razorfen Spearhide",
            npcID = 4438,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        _index = 14,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_47",
            name = "Death Speaker Jargba",
            npcID = 4428,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        _index = 15,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_47",
            name = "Overlord Ramtusk",
            npcID = 4420,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        _index = 16,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_47",
            name = "Agathelos the Raging",
            npcID = 4422,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        _index = 17,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_47",
            name = "Charlga Razorflank",
            npcID = 4421,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        _index = 18,
    }, {
        Qpart = {
            [1101] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        IsQuestOnQuest = 1101,
        _index = 19,
    }, {
        Qpart = {
            [1102] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        IsQuestOnQuest = 1102,
        _index = 20,
    }, {
        Qpart = {
            [1109] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        IsQuestOnQuest = 1109,
        _index = 21,
    }, {
        Qpart = {
            [1142] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        IsQuestOnQuest = 1142,
        _index = 22,
    }, {
        Qpart = {
            [1144] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        IsQuestOnQuest = 1144,
        _index = 23,
    }, {
        Qpart = {
            [1221] = { 1, 2, 3, 4 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        IsQuestOnQuest = 1221,
        _index = 24,
    }, {
        Qpart = {
            [96264] = { 1 },
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        IsQuestOnQuest = 96264,
        _index = 25,
    }, {
        Done = { 1144 },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 4508,
            questID = 1144,
        } },
        IsQuestOnQuest = 1144,
        _index = 26,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_47",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_47",
        _index = 27,
    }, {
        Done = { 1101 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1444, 89.64, 46.57),
        RaidIcon = { {
            npcID = 4048,
            questID = 1101,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 1101,
        Zone = 1444,
        _index = 28,
    }, {
        Done = { 1102 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1456, 35.97, 59.92),
        RaidIcon = { {
            npcID = 4451,
            questID = 1102,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 1102,
        Zone = 1456,
        _index = 29,
    }, {
        Done = { 1109 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 48.82, 69.28),
        RaidIcon = { {
            npcID = 2055,
            questID = 1109,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 1109,
        Zone = 1458,
        _index = 30,
    }, {
        Done = { 1142 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1457, 69.54, 67.75),
        RaidIcon = { {
            npcID = 4521,
            questID = 1142,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 1142,
        Zone = 1457,
        _index = 31,
    }, {
        Done = { 1221 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 62.37, 37.62),
        RaidIcon = { {
            npcID = 3446,
            questID = 1221,
        } },
        IsQuestOnQuest = 1221,
        Zone = 1413,
        _index = 32,
    }, {
        Done = { 96264 },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1417, 59.84, 27.57),
        RaidIcon = { {
            npcID = 259023,
            questID = 96264,
        } },
        Class = { "SHAMAN" },
        Faction = "Alliance",
        IsQuestOnQuest = 96264,
        Zone = 1417,
        _index = 33,
    }, {
        RouteCompleted = true,
        _index = 34,
    } },
}
