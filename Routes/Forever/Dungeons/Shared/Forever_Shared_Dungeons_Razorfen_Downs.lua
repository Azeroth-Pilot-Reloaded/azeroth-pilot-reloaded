local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Razorfen-Downs"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 37,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Razorfen Downs"],
    levelRange = {
        max = 46,
        min = 37,
    },
    mapID = 1413,
    steps = { {
        PickUp = { 3341 },
        _comment = "Quest contract: 3341 Bring the End",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 74.05, 33.31),
        RaidIcon = { {
            npcID = 2308,
            questID = 3341,
        } },
        Faction = "Horde",
        MinLevel = 37,
        Zone = 1458,
        _index = 1,
    }, {
        PickUp = { 3636 },
        _comment = "Quest contract: 3636 Bring the Light",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 50.31, 45.47),
        RaidIcon = { {
            npcID = 1284,
            questID = 3636,
        } },
        Faction = "Alliance",
        MinLevel = 39,
        Zone = 1453,
        _index = 2,
    }, {
        PickUp = { 6626 },
        _comment = "Quest contract: 6626 A Host of Evil",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 49.01, 94.94),
        RaidIcon = { {
            npcID = 12866,
            questID = 6626,
        } },
        MinLevel = 28,
        Zone = 1413,
        _index = 3,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_129",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 50.917, 92.954),
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        Zone = 1413,
        _index = 4,
    }, {
        PickUp = { 3523 },
        _comment = "Quest contract: 3523 Scourge of the Downs",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 8516,
            questID = 3523,
        } },
        MinLevel = 32,
        _index = 5,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_129",
            name = "Tuten'kash",
            npcID = 7355,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        _index = 6,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_129",
            name = "Plaguemaw the Rotting",
            npcID = 7356,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        _index = 7,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_129",
            name = "Mordresh Fire Eye",
            npcID = 7357,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        _index = 8,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_129",
            name = "Glutton",
            npcID = 8567,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        _index = 9,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_129",
            name = "Amnennar the Coldbringer",
            npcID = 7358,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        _index = 10,
    }, {
        Qpart = {
            [3341] = { 1 },
        },
        _comment = "Quest contract: 3341 Bring the End",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 3341,
        _index = 11,
    }, {
        Qpart = {
            [3523] = { 1 },
        },
        _comment = "Quest contract: 3523 Scourge of the Downs",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 3523,
        _index = 12,
    }, {
        Qpart = {
            [3636] = { 1 },
        },
        _comment = "Quest contract: 3636 Bring the Light",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 3636,
        _index = 13,
    }, {
        PickUp = { 6522 },
        _comment = "Quest contract: 6522 An Unholy Alliance",
        Button = {
            ["6522"] = 17008,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        Faction = "Horde",
        ItemCount = {
            count = 1,
            itemID = 17008,
        },
        MinLevel = 28,
        _index = 14,
    }, {
        Qpart = {
            [6626] = { 1, 2, 3 },
        },
        _comment = "Quest contract: 6626 A Host of Evil",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 6626,
        _index = 15,
    }, {
        Done = { 3523 },
        _comment = "Quest contract: 3523 Scourge of the Downs",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 8516,
            questID = 3523,
        } },
        IsQuestOnQuest = 3523,
        _index = 16,
    }, {
        Qpart = {
            [6522] = { 1 },
        },
        _comment = "Quest contract: 6522 An Unholy Alliance",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 6522,
        _index = 17,
    }, {
        PickUp = { 3525 },
        _comment = "Quest contract: 3525 Extinguishing the Idol",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 8516,
            questID = 3525,
        } },
        AnyOf = { {
            IsQuestCompleted = 3523,
        } },
        MinLevel = 32,
        _index = 18,
    }, {
        Qpart = {
            [3525] = { 1 },
        },
        _comment = "Quest contract: 3525 Extinguishing the Idol",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 3525,
        _index = 19,
    }, {
        Done = { 3525 },
        _comment = "Quest contract: 3525 Extinguishing the Idol",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 3525,
        _index = 20,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_129",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        _index = 21,
    }, {
        Done = { 3341 },
        _comment = "Quest contract: 3341 Bring the End",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 74.05, 33.31),
        RaidIcon = { {
            npcID = 2308,
            questID = 3341,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 3341,
        Zone = 1458,
        _index = 22,
    }, {
        Done = { 3636 },
        _comment = "Quest contract: 3636 Bring the Light",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1453, 50.31, 45.47),
        RaidIcon = { {
            npcID = 1284,
            questID = 3636,
        } },
        Faction = "Alliance",
        IsQuestOnQuest = 3636,
        Zone = 1453,
        _index = 23,
    }, {
        Done = { 6522 },
        _comment = "Quest contract: 6522 An Unholy Alliance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 56.25, 92.2),
        RaidIcon = { {
            npcID = 2425,
            questID = 6522,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 6522,
        Zone = 1458,
        _index = 24,
    }, {
        Done = { 6626 },
        _comment = "Quest contract: 6626 A Host of Evil",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 49.01, 94.94),
        RaidIcon = { {
            npcID = 12866,
            questID = 6626,
        } },
        IsQuestOnQuest = 6626,
        Zone = 1413,
        _index = 25,
    }, {
        PickUp = { 6521 },
        _comment = "Quest contract: 6521 An Unholy Alliance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 56.25, 92.2),
        RaidIcon = { {
            npcID = 2425,
            questID = 6521,
        } },
        AnyOf = { {
            IsQuestCompleted = 6522,
        } },
        Faction = "Horde",
        MinLevel = 28,
        Zone = 1458,
        _index = 26,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_129",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 50.917, 92.954),
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        Zone = 1413,
        _index = 27,
    }, {
        Qpart = {
            [6521] = { 1 },
        },
        _comment = "Quest contract: 6521 An Unholy Alliance",
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        InstanceQuest = true,
        IsQuestOnQuest = 6521,
        _index = 28,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_129",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_129",
        _index = 29,
    }, {
        Done = { 6521 },
        _comment = "Quest contract: 6521 An Unholy Alliance",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 56.25, 92.2),
        RaidIcon = { {
            npcID = 2425,
            questID = 6521,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 6521,
        Zone = 1458,
        _index = 30,
    }, {
        RouteCompleted = true,
        _index = 31,
    } },
}
