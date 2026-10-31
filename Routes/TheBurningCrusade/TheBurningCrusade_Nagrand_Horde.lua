local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["107-BC-4-Horde"] = {
    label = L["BC04 - Nagrand"],
    author = "Jumbonero",
    expansion = APR.EXPANSIONS.TheBurningCrusade,
    category = APR.CATEGORIES.Leveling,
    prefab = {
        [APR.PREFAB_TYPES.Leveling] = 40,
    },
    mapID = 107,
    conditions = { Faction = "Horde", Level = 15 },
    nextRoute = {},
    steps = {
        {
            RouteCompleted = true,
            _index = 1,
        },
    },
}
