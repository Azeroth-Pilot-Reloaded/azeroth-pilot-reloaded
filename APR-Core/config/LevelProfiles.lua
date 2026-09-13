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
        -- Calibration: a full delve turn-in ended at 89 + 570908 / 592980 XP,
        -- leaving 22072 XP (3.72% of the level) before 90. Add a rounded 4% margin.
        levels = {
            -- Total active bonus -> required level
            [0]   = 89.08,
            [5]   = 88.88,
            [10]  = 88.68,
            [15]  = 88.38,
            [20]  = 88.18,
            [25]  = 87.88,
            [30]  = 87.68,
            [35]  = 87.38,
            [40]  = 87.18,
            [45]  = 86.88,
            [50]  = 86.68,
            [55]  = 86.38,
            [60]  = 86.18,
            [65]  = 85.88,
            [70]  = 85.68,
            [75]  = 85.38,
            [80]  = 85.18,
            [85]  = 84.88,
            [90]  = 84.68,
            [95]  = 84.38,
            [100] = 84.08,
            [105] = 83.88,
            [110] = 83.68,
        },
    },
}
