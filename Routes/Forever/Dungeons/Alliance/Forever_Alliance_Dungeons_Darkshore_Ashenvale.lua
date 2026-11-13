local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Generated locally by the APR route converter.
APR.RouteQuestStepList["Forever-Alliance-Dungeons-Darkshore-Ashenvale"] = {
    label = L["Forever - Leveling Dungeon - Darkshore / Ashenvale"],
    legacyLabels = { L["Forever - Leveling Dungeon - Darkshore / Ashenvale"] .. " (20-21)" },
    levelRange = { min = 20, max = 21 },
    expansion = APR.EXPANSIONS.Forever,
    gameVersion = APR.GAME_VERSIONS.Forever,
    category = APR.CATEGORIES.Dungeons,
    mapID = 1439,
    conditions = { MinLevel = 20, Faction = "Alliance" },
    nextRoute = {
        { route = "Forever-Shared-Dungeons-Wailing-Caverns", conditions = { MinLevel = 17, Faction = "Alliance", SkipForLvl = 26 } },
        { route = "Forever-Shared-Dungeons-Deadmines", conditions = { MinLevel = 18, Faction = "Alliance", SkipForLvl = 24 } },
    },
    prefab = { [APR.PREFAB_TYPES.Dungeons] = { index = 9 } },
    hiddenFromSelection = true,
    steps = {
        {
            RouteCompleted = true,
            _index = 1,
        },
    },
}
