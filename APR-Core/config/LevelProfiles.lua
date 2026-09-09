-- Bonus percentages require an active aura or the source's isActive predicate.
-- Aura variants within one source never stack. Achievement tiers use the maximum.
APR.LevelBonusSources = {
    MysteriousWisdom = {
        auras = { 1221184 },
        bonus = 10,
        items = { 239142 },
    },
    Darkmoon = {
        -- WHEE! and the hat provide the same non-stacking bonus.
        auras = { 136583, 46668 },
        bonus = 10,
        items = { 93730, 171364 },
    },
    TenLands = {
        auras = { 289982 },
        bonus = 10,
        items = { 166750, 166751 },
        maxLevelExclusive = 50,
    },
    Timeways = {
        -- Take the highest active variant; Knowledge and Mastery never add together.
        auraBonuses = {
            [1269517] = { [1] = 5, [2] = 10, [3] = 15, [4] = 30 },
            [423860] = { [1] = 5, [2] = 10, [3] = 15, [4] = 30 },
            [1269518] = 30,
            [1229050] = 30,
            [1258528] = 30,
            [471544] = 30,
            [423861] = 30,
        },
    },
    WarMode = {
        isActive = function() return C_PvP.IsWarModeActive() end,
        bonus = 15,
    },
    Below80Mentorship = {
        auras = { 430191 },
        maxLevelExclusive = 80,
        achievementBonuses = {
            [19470] = 5,
            [19460] = 10,
            [19475] = 15,
            [19476] = 20,
            [19477] = 25,
        },
    },
    WindsOfMysteriousFortune = {
        auras = { 1287282, 1214848 },
        bonus = 20,
    },
    MidnightMentorship = {
        auras = { 430191 },
        minLevel = 80,
        maxLevelExclusive = 90,
        achievementBonuses = {
            [42328] = 5,
            [42329] = 10,
            [42330] = 15,
            [42331] = 20,
            [42332] = 25,
        },
    },
}

-- Routes reference a profile name in MinLevel, SkipForLvl, Grind, etc.
-- Select the greatest bonus breakpoint not exceeding the active bonus total.
-- Fractional levels represent XP progress: 87.5 means level 87 with 50% XP.
APR.LevelRequirementProfiles = {
    MidnightDelves = {
        bonuses = { "MidnightMentorship", "WindsOfMysteriousFortune", "WarMode", "Timeways",
            "MysteriousWisdom", "Darkmoon" },
        -- Empirical anchors: 20% total -> 88; 40% total -> 87.
        -- Linear estimate: 89 - totalBonus / 20. Values outside 20-40% are extrapolated.
        levels = {
            -- Total active bonus -> required level
            [0]  = 89,
            [5]  = 88.75,
            [10] = 88.5,
            [15] = 88.25,
            [20] = 88,
            [25] = 87.75,
            [30] = 87.5,
            [35] = 87.25,
            [40] = 87,
            [45] = 86.75,
            [50] = 86.5,
            [55] = 86.25,
            [60] = 86,
            [65] = 85.75,
            [70] = 85.5,
            [75] = 85.25,
            [80] = 85,
            [85] = 84.75,
            [90] = 84.5,
            [95] = 84.25,
            [100] = 84,
            [105] = 83.75,
            [110] = 83.5,
        },
    },
}
