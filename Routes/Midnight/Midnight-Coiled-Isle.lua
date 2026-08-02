local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["2393-Coiled-Isle"] = {
    label = L["Midnight - Coiled Isle - sojourner"],
    expansion = APR.EXPANSIONS.Midnight,
    category = APR.CATEGORIES.Sojourner,
    prefab = {
        [APR.PREFAB_TYPES.AllQuests] = 92,
    },
    sojournerAchievementID = 63641,
    mapID = 2512,
    conditions = { Level = 90 },
    requiredRoute = { "2432-Midnight-Intro" },
    nextRoute = {},
    steps = {},
}
