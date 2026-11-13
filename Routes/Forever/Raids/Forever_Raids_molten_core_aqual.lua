local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-molten-core-aqual"] = {
    label = L["FOREVER_RAID_MOLTEN_CORE_AQUAL"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1447,
    conditions = {
        MinLevel = 55,
    },
    levelRange = {
        min = 55,
    },
    autoStartOnMap = false,
    steps = { {
            PickUp = { 6804 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestUncompleted = 6804,
            Zone = 1447,
            _index = 1,
        }, {
            Qpart = {
                [6804] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6804,
            _index = 2,
        }, {
            Done = { 6804 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6804,
            Zone = 1447,
            _index = 3,
        }, {
            PickUp = { 6805 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestUncompleted = 6805,
            Zone = 1447,
            _index = 4,
        }, {
            Qpart = {
                [6805] = { 1, 2 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6805,
            _index = 5,
        }, {
            Done = { 6805 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6805,
            Zone = 1447,
            _index = 6,
        }, {
            PickUp = { 6821 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestUncompleted = 6821,
            IsQuestsCompleted = { 6804, 6805 },
            Zone = 1447,
            _index = 7,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 6821,
            _index = 8,
        }, {
            Qpart = {
                [6821] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6821,
            _index = 9,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 6821,
            _index = 10,
        }, {
            Done = { 6821 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6821,
            Zone = 1447,
            _index = 11,
        }, {
            PickUp = { 6822 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsOneOfQuestsCompleted = { 6821 },
            IsQuestUncompleted = 6822,
            Zone = 1447,
            _index = 12,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_409",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            IsQuestOnQuest = 6822,
            _index = 13,
        }, {
            Qpart = {
                [6822] = { 1, 2, 3, 4 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6822,
            _index = 14,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_409",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            IsQuestOnQuest = 6822,
            _index = 15,
        }, {
            Done = { 6822 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6822,
            Zone = 1447,
            _index = 16,
        }, {
            PickUp = { 6823 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            ReputationLevel = {
                factionID = 749,
                level = 6,
            },
            IsOneOfQuestsCompleted = { 6822 },
            IsQuestUncompleted = 6823,
            Zone = 1447,
            _index = 17,
        }, {
            Done = { 6823 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6823,
            Zone = 1447,
            _index = 18,
        }, {
            PickUp = { 6824 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsOneOfQuestsCompleted = { 6823 },
            IsQuestUncompleted = 6824,
            Zone = 1447,
            _index = 19,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_409",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            IsQuestOnQuest = 6824,
            _index = 20,
        }, {
            Qpart = {
                [6824] = { 1, 2, 3, 4 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 6824,
            _index = 21,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_409",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_409",
            InstanceQuest = true,
            IsQuestOnQuest = 6824,
            _index = 22,
        }, {
            Done = { 6824 },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 6824,
            Zone = 1447,
            _index = 23,
        }, {
            LootItems = { {
                    itemID = 17333,
                    quantity = 1,
                } },
            Coord = {
                x = -7298.3,
                y = 2849.7,
            },
            InstanceQuest = true,
            IsQuestCompleted = 6824,
            Zone = 1447,
            _index = 24,
        }, {
            RouteCompleted = true,
            _index = 25,
        } },
}
