local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-onyxias-lair-drakefire-h"] = {
    label = L["FOREVER_RAID_ONYXIAS_LAIR_DRAKEFIRE_H"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1418,
    conditions = {
        MinLevel = 55,
        Faction = "Horde",
    },
    levelRange = {
        min = 55,
    },
    autoStartOnMap = false,
    steps = { {
            LootItems = { {
                    itemID = 12563,
                    quantity = 1,
                } },
            Note = { "FOREVER_RAID_GORETOOTH_COMMAND" },
            Coord = {
                x = -2223.4,
                y = -6677.3,
            },
            InstanceQuest = true,
            RaidIcon = { {
                    npcID = 9077,
                } },
            IsQuestNotOnQuest = 4903,
            IsQuestUncompleted = 4903,
            Zone = 1418,
            _index = 1,
        }, {
            PickUp = { 4903 },
            Button = {
                ["4903"] = 12563,
            },
            NoArrow = true,
            InstanceQuest = true,
            Faction = "Horde",
            IsQuestUncompleted = 4903,
            ItemCount = {
                itemID = 12563,
                count = 1,
            },
            _index = 2,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 4903,
            _index = 3,
        }, {
            Qpart = {
                [4903] = { 1, 2, 3, 4 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 4903,
            _index = 4,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 4903,
            _index = 5,
        }, {
            Done = { 4903 },
            Coord = {
                x = -2223.4,
                y = -6677.3,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 4903,
            Zone = 1418,
            _index = 6,
        }, {
            PickUp = { 4941 },
            Coord = {
                x = -2223.4,
                y = -6677.3,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 4903 },
            IsQuestUncompleted = 4941,
            Zone = 1418,
            _index = 7,
        }, {
            Qpart = {
                [4941] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 4941,
            _index = 8,
        }, {
            Done = { 4941 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 4941,
            Zone = 1454,
            _index = 9,
        }, {
            PickUp = { 4974 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 4941 },
            IsQuestUncompleted = 4974,
            Zone = 1454,
            _index = 10,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 4974,
            _index = 11,
        }, {
            Qpart = {
                [4974] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 4974,
            _index = 12,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 4974,
            _index = 13,
        }, {
            Done = { 4974 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 4974,
            Zone = 1454,
            _index = 14,
        }, {
            PickUp = { 6566 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 4974 },
            IsQuestUncompleted = 6566,
            Zone = 1454,
            _index = 15,
        }, {
            Qpart = {
                [6566] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6566,
            _index = 16,
        }, {
            Done = { 6566 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6566,
            Zone = 1454,
            _index = 17,
        }, {
            PickUp = { 6567 },
            Coord = {
                x = -4125.2,
                y = 1920.3,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6566 },
            IsQuestUncompleted = 6567,
            Zone = 1454,
            _index = 18,
        }, {
            Done = { 6567 },
            Coord = {
                x = 1805.6,
                y = 392.1,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6567,
            Zone = 1443,
            _index = 19,
        }, {
            PickUp = { 6568 },
            Coord = {
                x = 1805.6,
                y = 392.1,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6567 },
            IsQuestUncompleted = 6568,
            Zone = 1443,
            _index = 20,
        }, {
            Done = { 6568 },
            Coord = {
                x = -1767.7,
                y = 1133.5,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6568,
            Zone = 1422,
            _index = 21,
        }, {
            PickUp = { 6569 },
            Coord = {
                x = -1767.7,
                y = 1133.5,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6568 },
            IsQuestUncompleted = 6569,
            Zone = 1422,
            _index = 22,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 6569,
            _index = 23,
        }, {
            Qpart = {
                [6569] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6569,
            _index = 24,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 6569,
            _index = 25,
        }, {
            Done = { 6569 },
            Coord = {
                x = -1767.7,
                y = 1133.5,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6569,
            Zone = 1422,
            _index = 26,
        }, {
            PickUp = { 6570 },
            Coord = {
                x = -1767.7,
                y = 1133.5,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6569 },
            IsQuestUncompleted = 6570,
            Zone = 1422,
            _index = 27,
        }, {
            Done = { 6570 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6570,
            Zone = 1445,
            _index = 28,
        }, {
            PickUp = { 6582 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6570 },
            IsQuestUncompleted = 6582,
            Zone = 1445,
            _index = 29,
        }, {
            Qpart = {
                [6582] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6582,
            _index = 30,
        }, {
            Done = { 6582 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6582,
            Zone = 1445,
            _index = 31,
        }, {
            PickUp = { 6583 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6570 },
            IsQuestUncompleted = 6583,
            Zone = 1445,
            _index = 32,
        }, {
            Qpart = {
                [6583] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6583,
            _index = 33,
        }, {
            Done = { 6583 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6583,
            Zone = 1445,
            _index = 34,
        }, {
            PickUp = { 6584 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6570 },
            IsQuestUncompleted = 6584,
            Zone = 1445,
            _index = 35,
        }, {
            Qpart = {
                [6584] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6584,
            _index = 36,
        }, {
            Done = { 6584 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6584,
            Zone = 1445,
            _index = 37,
        }, {
            PickUp = { 6585 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsQuestUncompleted = 6585,
            IsQuestsCompleted = { 6582, 6583, 6584 },
            Zone = 1445,
            _index = 38,
        }, {
            Qpart = {
                [6585] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6585,
            _index = 39,
        }, {
            Done = { 6585 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6585,
            Zone = 1445,
            _index = 40,
        }, {
            PickUp = { 6601 },
            Coord = {
                x = -3951.8,
                y = -5102.8,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6585 },
            IsQuestUncompleted = 6601,
            Zone = 1445,
            _index = 41,
        }, {
            Done = { 6601 },
            Coord = {
                x = 1805.6,
                y = 392.1,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6601,
            Zone = 1443,
            _index = 42,
        }, {
            PickUp = { 6602 },
            Coord = {
                x = 1805.6,
                y = 392.1,
            },
            InstanceQuest = true,
            Faction = "Horde",
            IsOneOfQuestsCompleted = { 6601 },
            IsQuestUncompleted = 6602,
            Zone = 1443,
            _index = 43,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 6602,
            _index = 44,
        }, {
            Qpart = {
                [6602] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6602,
            _index = 45,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 6602,
            _index = 46,
        }, {
            Done = { 6602 },
            Coord = {
                x = 1805.6,
                y = 392.1,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6602,
            Zone = 1443,
            _index = 47,
        }, {
            RouteCompleted = true,
            _index = 48,
        } },
}
