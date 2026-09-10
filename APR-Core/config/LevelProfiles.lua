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
            [0]   = 89,
            [5]   = 88.80,
            [10]  = 88.6,
            [15]  = 88.30,
            [20]  = 88.1,
            [25]  = 87.8,
            [30]  = 87.6,
            [35]  = 87.3,
            [40]  = 87.1,
            [45]  = 86.8,
            [50]  = 86.6,
            [55]  = 86.3,
            [60]  = 86.1,
            [65]  = 85.8,
            [70]  = 85.6,
            [75]  = 85.3,
            [80]  = 85.1,
            [85]  = 84.8,
            [90]  = 84.6,
            [95]  = 84.3,
            [100] = 84,
            [105] = 83.8,
            [110] = 83.6,
        },
    },
}
