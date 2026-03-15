local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["2393-Midnight-Glyph-Eversong-Woods"] = {
    label = L["Glyph - Eversong Woods"],
    expansion = APR.EXPANSIONS.Midnight,
    category = APR.CATEGORIES.Achievement,
    prefab = {
        [APR.PREFAB_TYPES.AllQuests] = 100,
        [APR.PREFAB_TYPES.Speedrun] = 40,
    },
    mapID = 2393,
    conditions = { Level = 80 },
    nextRoute = { "2395-Midnight-Glyph-Zulaman" },
    steps = {
        {
            Achievement = { achievementID = 61576, criteriaIndex = 1 },
            Coord = { x = -4692.8, y = 9647.9 },
            Zone = 2395,
            _index = 1,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 3 },
            Coord = { x = -5406.1, y = 8934.9 },
            Zone = 2395,
            _index = 2,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 2 },
            Coord = { x = -5997.4, y = 8117.0 },
            Zone = 2395,
            _index = 3,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 5 },
            Coord = { x = -4512.7, y = 7149.1 },
            Zone = 2395,
            _index = 4,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 11 },
            Coord = { x = -3920.5, y = 7252.7 },
            Zone = 2395,
            _index = 5,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 6 },
            Coord = { x = -3570.3, y = 7298.5 },
            Zone = 2395,
            _index = 6,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 9 },
            Coord = { x = -3002.6, y = 6059.4 },
            Zone = 2395,
            _index = 7,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 4 },
            Coord = { x = -3619.3, y = 6422.2 },
            Zone = 2395,
            _index = 8,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 8 },
            Coord = { x = -4794.2, y = 5921.9 },
            Zone = 2395,
            _index = 9,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 10 },
            Coord = { x = -5361.9, y = 6510.1 },
            Zone = 2395,
            _index = 10,
        },
        {
            Achievement = { achievementID = 61576, criteriaIndex = 7 },
            Coord = { x = -5751.7, y = 6221.3 },
            Zone = 2395,
            _index = 11,
        },
        {
            RouteCompleted = true,
            _index = 12,
        },
    }
}

APR.RouteQuestStepList["2395-Midnight-Glyph-Zulaman"] = {
    label = L["Glyph - Zul'Aman"],
    expansion = APR.EXPANSIONS.Midnight,
    category = APR.CATEGORIES.Achievement,
    prefab = {
        [APR.PREFAB_TYPES.AllQuests] = 110,
        [APR.PREFAB_TYPES.Speedrun] = 50,
    },
    mapID = 2395,
    conditions = { Level = 80 },
    nextRoute = { "2413-Midnight-Glyph-Harandar" },
    steps = {
        {
            Achievement = { achievementID = 61581, criteriaIndex = 9 },
            Coord = { x = -5863.7, y = 5023.7 },
            Zone = 2395,
            _index = 1,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 1 },
            Coord = { x = -5356.5, y = 4084.0 },
            Zone = 2437,
            _index = 2,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 7 },
            Coord = { x = -6366.0, y = 3240.9 },
            Zone = 2437,
            _index = 3,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 11 },
            Coord = { x = -7465.1, y = 3517.7 },
            Zone = 2437,
            _index = 4,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 10 },
            Coord = { x = -7823.1, y = 3394.2 },
            Zone = 2437,
            _index = 5,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 3 },
            Coord = { x = -8438.9, y = 3498.0 },
            Zone = 2437,
            _index = 6,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 5 },
            Coord = { x = -8404.0, y = 5051.1 },
            Zone = 2437,
            _index = 7,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 2 },
            Coord = { x = -7484.8, y = 6251.0 },
            Zone = 2437,
            _index = 8,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 4 },
            Coord = { x = -8250.9, y = 6891.9 },
            Zone = 2437,
            _index = 9,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 6 },
            Coord = { x = -7183.2, y = 7124.6 },
            Zone = 2437,
            _index = 10,
        },
        {
            Achievement = { achievementID = 61581, criteriaIndex = 8 },
            Coord = { x = -6143.2, y = 6592.3 },
            Zone = 2437,
            _index = 11,
        },
        {
            RouteCompleted = true,
            _index = 12,
        },
    }
}

APR.RouteQuestStepList["2413-Midnight-Glyph-Harandar"] = {
    label = L["Glyph - Harandar"],
    expansion = APR.EXPANSIONS.Midnight,
    category = APR.CATEGORIES.Achievement,
    prefab = {
        [APR.PREFAB_TYPES.AllQuests] = 120,
        [APR.PREFAB_TYPES.Speedrun] = 60,
    },
    mapID = 2413,
    conditions = { Level = 80 },
    nextRoute = { "2405-Midnight-Glyph-Voidstorm" },
    steps = {
        {
            Achievement = { achievementID = 61582, criteriaIndex = 2 },
            Coord = { x = 16.9, y = -160.4 },
            Zone = 2413,
            _index = 1,
        },
        {
            Achievement = { achievementID = 61582, criteriaIndex = 7 },
            Coord = { x = 203.9, y = -642.0 },
            Zone = 2413,
            _index = 2,
        },
        {
            Achievement = { achievementID = 61582, criteriaIndex = 9 },
            Coord = { x = -1105.4, y = -881.8 },
            Zone = 2413,
            _index = 3,
        },
        {
            Achievement = { achievementID = 61582, criteriaIndex = 4 },
            Coord = { x = -1674.2, y = 213.6 },
            Zone = 2413,
            _index = 4,
        },
        {
            Achievement = { achievementID = 61582, criteriaIndex = 6 },
            Coord = { x = -1955.1, y = 1221.2 },
            Zone = 2413,
            _index = 5,
        },
        {
            Achievement = { achievementID = 61582, criteriaIndex = 5 },
            Coord = { x = -564.0, y = 742.1 },
            Zone = 2413,
            _index = 6,
        },
        {
            Achievement = { achievementID = 61582, criteriaIndex = 3 },
            Coord = { x = 960.5, y = 1358.5 },
            Zone = 2413,
            _index = 7,
        },
        {
            Achievement = { achievementID = 61582, criteriaIndex = 8 },
            Coord = { x = 1567.0, y = -572.3 },
            Zone = 2413,
            _index = 8,
        },
        {
            RouteCompleted = true,
            _index = 9,
        },
    }
}

APR.RouteQuestStepList["2405-Midnight-Glyph-Voidstorm"] = {
    label = L["Glyph - Voidstorm"],
    expansion = APR.EXPANSIONS.Midnight,
    category = APR.CATEGORIES.Achievement,
    prefab = {
        [APR.PREFAB_TYPES.AllQuests] = 130,
        [APR.PREFAB_TYPES.Speedrun] = 70,
    },
    mapID = 2405,
    conditions = { Level = 80 },
    nextRoute = {},
    steps = {
        {
            Achievement = { achievementID = 61583, criteriaIndex = 11 },
            Coord = { x = -206.0, y = -276.0 },
            Zone = 2405,
            _index = 1,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 7 },
            Coord = { x = 847.9, y = 488.9 },
            Zone = 2405,
            _index = 2,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 4 },
            Coord = { x = 743.1, y = 841.6 },
            Zone = 2405,
            _index = 3,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 3 },
            Coord = { x = 1175.5, y = 1510.9 },
            Zone = 2405,
            _index = 4,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 2 },
            Coord = { x = 1020.9, y = 2267.7 },
            Zone = 2405,
            _index = 5,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 10 },
            Coord = { x = 1132.8, y = 3130.2 },
            Zone = 2405,
            _index = 6,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 6 },
            Coord = { x = 343.4, y = 4034.4 },
            Zone = 2405,
            _index = 7,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 5 },
            Coord = { x = -787.9, y = 2567.4 },
            Zone = 2405,
            _index = 8,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 8 },
            Coord = { x = 195.8, y = 2112.4 },
            Zone = 2405,
            _index = 9,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 1 },
            Coord = { x = -417.6, y = 1405.8 },
            Zone = 2405,
            _index = 10,
        },
        {
            Achievement = { achievementID = 61583, criteriaIndex = 9 },
            Coord = { x = -1815.4, y = 781.9 },
            Zone = 2405,
            _index = 11,
        },
        {
            RouteCompleted = true,
            _index = 12,
        },
    }
}
