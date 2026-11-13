local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Verified offline instance and quest contracts.
APR.RouteQuestStepList["Forever-Shared-Dungeons-Shadowfang-Keep"] = {
    category = APR.CATEGORIES.Dungeons,
    conditions = {
        MinLevel = 20,
    },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    label = L["Forever - Dungeon - Shadowfang Keep"],
    levelRange = {
        max = 30,
        min = 20,
    },
    mapID = 1421,
    steps = { {
        PickUp = { 1013 },
        _comment = "Quest contract: 1013 The Book of Ur",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 53.74, 54.46),
        RaidIcon = { {
            npcID = 2934,
            questID = 1013,
        } },
        Faction = "Horde",
        MinLevel = 16,
        Zone = 1458,
        _index = 1,
    }, {
        PickUp = { 1014 },
        _comment = "Quest contract: 1014 Arugal Must Die",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1421, 44.2, 39.81),
        RaidIcon = { {
            npcID = 1938,
            questID = 1014,
        } },
        Faction = "Horde",
        MinLevel = 18,
        Zone = 1421,
        _index = 2,
    }, {
        PickUp = { 1098 },
        _comment = "Quest contract: 1098 Deathstalkers in Shadowfang",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1421, 43.42, 40.86),
        RaidIcon = { {
            npcID = 1952,
            questID = 1098,
        } },
        Faction = "Horde",
        MinLevel = 18,
        Zone = 1421,
        _index = 3,
    }, {
        PickUp = { 1740 },
        _comment = "Quest contract: 1740 The Orb of Soran'ruk",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 49.31, 57.21),
        RaidIcon = { {
            npcID = 6247,
            questID = 1740,
        } },
        Class = { "WARLOCK" },
        MinLevel = 20,
        Zone = 1413,
        _index = 4,
    }, {
        EnterInstance = {
            dungeonKey = "INSTANCE_33",
        },
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1421, 44.6, 67.7),
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        Zone = 1421,
        _index = 5,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Rethilgore",
            npcID = 3914,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 6,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Razorclaw the Butcher",
            npcID = 3886,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 7,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Baron Silverlaine",
            npcID = 3887,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 8,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Commander Springvale",
            npcID = 4278,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 9,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Odo the Blindwatcher",
            npcID = 4279,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 10,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Fenrus the Devourer",
            npcID = 4274,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 11,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Wolf Master Nandos",
            npcID = 3927,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 12,
    }, {
        KillNPC = {
            dungeonKey = "INSTANCE_33",
            name = "Archmage Arugal",
            npcID = 4275,
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        _index = 13,
    }, {
        Qpart = {
            [1013] = { 1 },
        },
        _comment = "Quest contract: 1013 The Book of Ur",
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        IsQuestOnQuest = 1013,
        _index = 14,
    }, {
        Qpart = {
            [1014] = { 1 },
        },
        _comment = "Quest contract: 1014 Arugal Must Die",
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        IsQuestOnQuest = 1014,
        _index = 15,
    }, {
        Done = { 1098 },
        _comment = "Quest contract: 1098 Deathstalkers in Shadowfang",
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        RaidIcon = { {
            npcID = 4444,
            questID = 1098,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 1098,
        _index = 16,
    }, {
        Qpart = {
            [1740] = { 1, 2 },
        },
        _comment = "Quest contract: 1740 The Orb of Soran'ruk",
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        InstanceQuest = true,
        IsQuestOnQuest = 1740,
        _index = 17,
    }, {
        LeaveInstance = {
            dungeonKey = "INSTANCE_33",
        },
        NoArrow = true,
        Dungeon = "INSTANCE_33",
        _index = 18,
    }, {
        Done = { 1013 },
        _comment = "Quest contract: 1013 The Book of Ur",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1458, 53.74, 54.46),
        RaidIcon = { {
            npcID = 2934,
            questID = 1013,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 1013,
        Zone = 1458,
        _index = 19,
    }, {
        Done = { 1014 },
        _comment = "Quest contract: 1014 Arugal Must Die",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1421, 44.2, 39.81),
        RaidIcon = { {
            npcID = 1938,
            questID = 1014,
        } },
        Faction = "Horde",
        IsQuestOnQuest = 1014,
        Zone = 1421,
        _index = 20,
    }, {
        Done = { 1740 },
        _comment = "Quest contract: 1740 The Orb of Soran'ruk",
        Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1413, 49.31, 57.21),
        RaidIcon = { {
            npcID = 6247,
            questID = 1740,
        } },
        Class = { "WARLOCK" },
        IsQuestOnQuest = 1740,
        Zone = 1413,
        _index = 21,
    }, {
        RouteCompleted = true,
        _index = 22,
    } },
}
