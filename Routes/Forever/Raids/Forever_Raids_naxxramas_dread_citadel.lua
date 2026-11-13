local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Forever-Raids-naxxramas-dread-citadel"] = {
    label = L["FOREVER_RAID_NAXXRAMAS_DREAD_CITADEL"],
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Raids,
    mapID = 1423,
    conditions = {
        MinLevel = 60,
    },
    levelRange = {
        min = 60,
    },
    autoStartOnMap = false,
    steps = { {
            PickUp = { 9121 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423,71.7,48.7),
            InstanceQuest = true,
            ReputationLevel = {
                factionID = 529,
                level = 6,
            },
            AllOf = { {
                    Not = {
                        ReputationLevel = {
                            factionID = 529,
                            level = 7,
                        },
                    },
                } },
            IsQuestUncompleted = 9121,
            Not = {
                IsOneOfQuestsCompleted = { 9121, 9122, 9123 },
            },
            Zone = 1423,
            _index = 1,
        }, {
            Qpart = {
                [9121] = { 1, 2, 3 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 9121,
            _index = 2,
        }, {
            Done = { 9121 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423,71.7,48.7),
            InstanceQuest = true,
            IsQuestOnQuest = 9121,
            Zone = 1423,
            _index = 3,
        }, {
            PickUp = { 9122 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423,71.7,48.7),
            InstanceQuest = true,
            ReputationLevel = {
                factionID = 529,
                level = 7,
            },
            AllOf = { {
                    Not = {
                        ReputationLevel = {
                            factionID = 529,
                            level = 8,
                        },
                    },
                } },
            IsQuestUncompleted = 9122,
            Not = {
                IsOneOfQuestsCompleted = { 9121, 9122, 9123 },
            },
            Zone = 1423,
            _index = 4,
        }, {
            Qpart = {
                [9122] = { 1, 2 },
            },
            Note = { "FOREVER_RAID_NATIVE_QUEST" },
            NoArrow = true,
            InstanceQuest = true,
            IsQuestOnQuest = 9122,
            _index = 5,
        }, {
            Done = { 9122 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423,71.7,48.7),
            InstanceQuest = true,
            IsQuestOnQuest = 9122,
            Zone = 1423,
            _index = 6,
        }, {
            PickUp = { 9123 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423,71.7,48.7),
            InstanceQuest = true,
            ReputationLevel = {
                factionID = 529,
                level = 8,
            },
            IsQuestUncompleted = 9123,
            Not = {
                IsOneOfQuestsCompleted = { 9121, 9122, 9123 },
            },
            Zone = 1423,
            _index = 7,
        }, {
            Done = { 9123 },
            Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1423,71.7,48.7),
            InstanceQuest = true,
            IsQuestOnQuest = 9123,
            Zone = 1423,
            _index = 8,
        }, {
            RouteCompleted = true,
            _index = 9,
        } },
}
