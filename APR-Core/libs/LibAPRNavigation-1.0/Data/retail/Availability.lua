-- Conditional world access. Two static map artworks do not prove a live phase.
LibStub("LibAPRNavigation-1.0"):RegisterData("retail", "availability", {
    config = {
        PhaseGroups = {
            tirisfal = {
                sides = { { mapID = 18, artID = 19, phase = "past" }, { mapID = 2070, artID = 1136, phase = "present" } },
                localMaps = { [18] = "past", [90] = "past", [2070] = "present" },
            },
            darkshore = {
                sides = { { mapID = 62, artID = 67, phase = "past" }, { mapID = 62, artID = 1176, phase = "present" } },
            },
            blasted_lands = {
                sides = { { mapID = 17, artID = 18, phase = "past" }, { mapID = 17, artID = 628, phase = "present" } },
            },
            silithus = {
                sides = { { mapID = 81, artID = 86, phase = "past" }, { mapID = 81, artID = 962, phase = "present" } },
            },
            dustwallow = {
                sides = { { mapID = 70, artID = 75, phase = "past" }, { mapID = 70, artID = 498, phase = "present" } },
            },
            uldum = {
                sides = { { mapID = 249, artID = 289, phase = "past" }, { mapID = 1527, artID = 260, phase = "present" } },
                localMaps = { [249] = "past", [1527] = "present" },
            },
            vale = {
                sides = { { mapID = 390, artID = 402, phase = "past" }, { mapID = 1530, artID = 1342, phase = "present" } },
                localMaps = { [390] = "past", [1530] = "present" },
            },
        },
        MapRequirements = {
            [18] = { phase = { group = "tirisfal", phase = "past" } },
            [90] = { phase = { group = "tirisfal", phase = "past" } },
            [57] = { phase = { group = "darkshore", phase = "past" } },
            [89] = { phase = { group = "darkshore", phase = "past" } },
            [249] = { phase = { group = "uldum", phase = "past" } },
            [1527] = { phase = { group = "uldum", phase = "present" } },
            [390] = { phase = { group = "vale", phase = "past" } },
            [1530] = { phase = { group = "vale", phase = "present" } },
            [407] = { holiday = "darkmoon_faire" },
        },
        Holidays = {
            darkmoon_faire = { [235446] = true, [235447] = true, [235448] = true },
        },
    },
    unlockRoutes = {
        {
            id = "phase-tirisfal-past",
            goal = { key = "phase", value = { group = "tirisfal", phase = "past" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_past", npcID = 141488,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 2070, x = 0.6945, y = 0.628 },
                    completeWhen = { phase = { group = "tirisfal", phase = "past" } },
                },
            },
        },
        {
            id = "phase-tirisfal-present",
            goal = { key = "phase", value = { group = "tirisfal", phase = "present" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_present", npcID = 141488,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 18, x = 0.6945, y = 0.628 },
                    completeWhen = { phase = { group = "tirisfal", phase = "present" } },
                },
            },
        },
        {
            id = "phase-darkshore-past",
            goal = { key = "phase", value = { group = "darkshore", phase = "past" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_past", npcID = 141489,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 62, x = 0.4888, y = 0.2447 },
                    completeWhen = { phase = { group = "darkshore", phase = "past" } },
                },
            },
        },
        {
            id = "phase-darkshore-present",
            goal = { key = "phase", value = { group = "darkshore", phase = "present" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_present", npcID = 141489,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 62, x = 0.4888, y = 0.2447 },
                    completeWhen = { phase = { group = "darkshore", phase = "present" } },
                },
            },
        },
        {
            id = "phase-blasted_lands-past",
            goal = { key = "phase", value = { group = "blasted_lands", phase = "past" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_past", npcID = 88206,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 17, x = 0.4812, y = 0.0732 },
                    completeWhen = { phase = { group = "blasted_lands", phase = "past" } },
                },
            },
        },
        {
            id = "phase-blasted_lands-present",
            goal = { key = "phase", value = { group = "blasted_lands", phase = "present" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_present", npcID = 88206,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 17, x = 0.4812, y = 0.0732 },
                    completeWhen = { phase = { group = "blasted_lands", phase = "present" } },
                },
            },
        },
        {
            id = "phase-silithus-past",
            goal = { key = "phase", value = { group = "silithus", phase = "past" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_past", npcID = 128607,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 81, x = 0.7892, y = 0.2203 },
                    completeWhen = { phase = { group = "silithus", phase = "past" } },
                },
            },
        },
        {
            id = "phase-silithus-present",
            goal = { key = "phase", value = { group = "silithus", phase = "present" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_present", npcID = 128607,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 81, x = 0.7892, y = 0.2203 },
                    completeWhen = { phase = { group = "silithus", phase = "present" } },
                },
            },
        },
        {
            id = "phase-dustwallow-past",
            goal = { key = "phase", value = { group = "dustwallow", phase = "past" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_past", npcID = 63546,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 70, x = 0.559, y = 0.4956 },
                    completeWhen = { phase = { group = "dustwallow", phase = "past" } },
                },
            },
        },
        {
            id = "phase-dustwallow-present",
            goal = { key = "phase", value = { group = "dustwallow", phase = "present" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_present", npcID = 63546,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 70, x = 0.559, y = 0.4956 },
                    completeWhen = { phase = { group = "dustwallow", phase = "present" } },
                },
            },
        },
        {
            id = "phase-uldum-past",
            goal = { key = "phase", value = { group = "uldum", phase = "past" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_past", npcID = 162419,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 1527, x = 0.56, y = 0.3514 },
                    completeWhen = { phase = { group = "uldum", phase = "past" } },
                },
            },
        },
        {
            id = "phase-uldum-present",
            goal = { key = "phase", value = { group = "uldum", phase = "present" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_present", npcID = 162419,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 249, x = 0.56, y = 0.3514 },
                    completeWhen = { phase = { group = "uldum", phase = "present" } },
                },
            },
        },
        {
            id = "phase-vale-past",
            goal = { key = "phase", value = { group = "vale", phase = "past" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_past", npcID = 163463,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 1530, x = 0.8101, y = 0.2945 },
                    completeWhen = { phase = { group = "vale", phase = "past" } },
                },
            },
        },
        {
            id = "phase-vale-present",
            goal = { key = "phase", value = { group = "vale", phase = "present" } },
            prerequisitesKnown = false,
            steps = {
                {
                    kind = "action", actionType = "phase_present", npcID = 163463,
                    position = { space = "map", phaseAgnostic = true, uiMapID = 390, x = 0.8052, y = 0.3192 },
                    completeWhen = { phase = { group = "vale", phase = "present" } },
                },
            },
        },
    },
    connections = {
        {
            id = "darkmoon-elwynn", kind = "portal",
            from = { space = "map", uiMapID = 37, x = 0.4179, y = 0.6948 },
            to = { space = "map", uiMapID = 407, x = 0.5129, y = 0.2386 },
            requirements = { holiday = "darkmoon_faire" },
        },
        {
            id = "darkmoon-mulgore", kind = "portal",
            from = { space = "map", uiMapID = 7, x = 0.3685, y = 0.3586 },
            to = { space = "map", uiMapID = 407, x = 0.5129, y = 0.2386 },
            requirements = { holiday = "darkmoon_faire" },
        },
        {
            id = "darkmoon-exit-alliance", kind = "portal",
            from = { space = "map", uiMapID = 407, x = 0.5122, y = 0.2312 },
            to = { space = "map", uiMapID = 37, x = 0.4187, y = 0.6817 },
            requirements = { holiday = "darkmoon_faire", faction = "Alliance" },
        },
        {
            id = "darkmoon-exit-horde", kind = "portal",
            from = { space = "map", uiMapID = 407, x = 0.5122, y = 0.2312 },
            to = { space = "map", uiMapID = 7, x = 0.3649, y = 0.3511 },
            requirements = { holiday = "darkmoon_faire", faction = "Horde" },
        },
        {
            id = "darkmoon-dock-alliance", kind = "portal",
            from = { space = "map", uiMapID = 407, x = 0.5056, y = 0.9075 },
            to = { space = "map", uiMapID = 37, x = 0.4187, y = 0.6817 },
            requirements = { holiday = "darkmoon_faire", faction = "Alliance" },
        },
        {
            id = "darkmoon-dock-horde", kind = "portal",
            from = { space = "map", uiMapID = 407, x = 0.5056, y = 0.9075 },
            to = { space = "map", uiMapID = 7, x = 0.3649, y = 0.3511 },
            requirements = { holiday = "darkmoon_faire", faction = "Horde" },
        },
        {
            id = "undercity-hellfire", kind = "portal",
            from = { space = "map", uiMapID = 90, x = 0.8525, y = 0.1704 },
            to = { space = "map", uiMapID = 100, x = 0.8916, y = 0.4956 },
            requirements = { faction = "Horde", minLevel = 10 },
        },
        {
            id = "undercity-silvermoon-orb", kind = "portal",
            from = { space = "map", uiMapID = 18, x = 0.5945, y = 0.6744, accessKey = "undercity-courtyard" },
            to = { space = "map", uiMapID = 110, x = 0.4949, y = 0.148 },
            requirements = { faction = "Horde" },
        },
        {
            id = "silvermoon-tirisfal-orb", kind = "portal",
            from = { space = "map", uiMapID = 110, x = 0.4949, y = 0.148 },
            to = { space = "map", uiMapID = 2070, x = 0.6941, y = 0.6274 },
            requirements = { faction = "Horde" },
        },
    },
}, 1)
