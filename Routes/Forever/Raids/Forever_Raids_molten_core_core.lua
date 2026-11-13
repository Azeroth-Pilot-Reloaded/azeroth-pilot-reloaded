local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-molten-core-core"] = {
    label = L["FOREVER_RAID_MOLTEN_CORE_CORE"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1427,
    conditions = {
        MinLevel = 55,
    },
    levelRange = {
        min = 55,
    },
    autoStartOnMap = false,
    steps = { {
            PickUp = { 7848 },
            Coord = {
                x = -1039.1,
                y = -7508.7,
            },
            InstanceQuest = true,
            IsQuestUncompleted = 7848,
            Zone = 1427,
            _index = 1,
        }, {
            EnterInstance = {
                dungeonKey = "INSTANCE_230",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_230",
            InstanceQuest = true,
            IsQuestOnQuest = 7848,
            _index = 2,
        }, {
            Qpart = {
                [7848] = { 1 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 7848,
            _index = 3,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_230",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_230",
            InstanceQuest = true,
            IsQuestOnQuest = 7848,
            _index = 4,
        }, {
            Done = { 7848 },
            Coord = {
                x = -1039.1,
                y = -7508.7,
            },
            InstanceQuest = true,
            IsQuestOnQuest = 7848,
            Zone = 1427,
            _index = 5,
        }, {
            RouteCompleted = true,
            _index = 6,
        } },
}
