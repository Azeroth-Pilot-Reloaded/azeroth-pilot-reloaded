local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-blackwing-lair-blackhand"] = {
    label = L["FOREVER_RAID_BLACKWING_LAIR_BLACKHAND"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1428,
    conditions = {
        MinLevel = 55,
    },
    levelRange = {
        min = 55,
    },
    autoStartOnMap = false,
    steps = { {
            LootItems = { {
                    itemID = 18987,
                    quantity = 1,
                } },
            Coord = {
                x = -1289.0,
                y = -7575.6,
            },
            InstanceQuest = true,
            RaidIcon = { {
                    npcID = 9046,
                } },
            IsQuestNotOnQuest = 7761,
            IsQuestUncompleted = 7761,
            Zone = 1427,
            _index = 1,
        }, {
            PickUp = { 7761 },
            Button = {
                ["7761"] = 18987,
            },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestUncompleted = 7761,
            ItemCount = {
                itemID = 18987,
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
            IsQuestOnQuest = 7761,
            _index = 3,
        }, {
            KillNPC = {
                dungeonKey = "INSTANCE_229",
                npcID = 10363,
                name = "General Drakkisath",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            IsQuestOnQuest = 7761,
            _index = 4,
        }, {
            Done = { 7761 },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 7761,
            _index = 5,
        }, {
            LeaveInstance = {
                dungeonKey = "INSTANCE_229",
            },
            NoArrow = true,
            Dungeon = "INSTANCE_229",
            InstanceQuest = true,
            _index = 6,
        }, {
            RouteCompleted = true,
            _index = 7,
        } },
}
