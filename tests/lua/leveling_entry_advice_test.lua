local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/utils/RouteConditions.lua")
C_Map = { GetBestMapForUnit = function() return 1 end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
local route = env.route(
    "ordinary",
    "Invented ordinary chapter",
    { MinLevel = 10, Faction = "Horde" },
    nil,
    APR.CATEGORIES.Leveling
)
APR.Level = 9
assert(APR:GetRouteVisibility("ordinary") == "visible" and APR:CanStartRoute("ordinary"))
assert(#APR:GetRouteLevelWarnings("ordinary") == 1)
assert(not APR:EvaluateRouteConditions(route.conditions), "Automatic recommendations retain the entry level")
assert(not APR:AreConditionalFiltersMet(route.conditions), "Action filters retain the minimum")
assert(APR:AddRouteToCustomPathByKey("ordinary"), "Manual addition accepts the advisory entry level")
route.conditions = { AnyOf = { { MinLevel = 10, Faction = "Horde" } } }
assert(APR:CanStartRoute("ordinary") and #APR:GetRouteLevelWarnings("ordinary") == 1)
APR.Faction = "Alliance"
assert(APR:GetRouteVisibility("ordinary") == "hidden" and not APR:CanStartRoute("ordinary"))
APR.Faction = "Horde"
route.conditions = { MinLevel = 10, IsQuestCompleted = 4321 }
assert(not APR:CanStartRoute("ordinary"), "A quest prerequisite remains mandatory")
route.conditions = { MinLevel = 10 }
route.prefab = { [APR.PREFAB_TYPES.StartingZone] = {} }
assert(not APR:CanStartRoute("ordinary"), "Starter entry remains strict")
route.prefab, route.category = nil, APR.CATEGORIES.Class
assert(not APR:CanStartRoute("ordinary"), "Specialized route access retains its strict boundary")
route.category = APR.CATEGORIES.Leveling
env.gameVersion = APR.GAME_VERSIONS.Retail
assert(APR:GetRouteVisibility("ordinary") == "hidden", "Client compatibility remains mandatory")

env.gameVersion = APR.GAME_VERSIONS.Forever
route.conditions = { AllOf = { { Faction = "Alliance" }, { MinLevel = 10 } } }
assert(not APR:CanStartRoute("ordinary") and APR:GetRouteVisibility("ordinary") == "hidden")
route.conditions = { AllOf = { { Faction = "Horde" }, { MinLevel = 10 } } }
assert(APR:CanStartRoute("ordinary") and #APR:GetRouteLevelWarnings("ordinary") == 1)
route.conditions = { Not = { Faction = "Horde" } }
assert(not APR:CanStartRoute("ordinary"), "Negated faction access cannot be waived")
route.conditions = { Not = { MinLevel = 10 } }
assert(APR:CanStartRoute("ordinary"), "Negated level predicates retain their original meaning")
APR.Level = 10
assert(not APR:CanStartRoute("ordinary"), "Negated levels remain strict at the boundary")
APR.Level = 9
route.conditions = { Not = { Faction = "Alliance", MinLevel = 10 } }
assert(APR:CanStartRoute("ordinary"))
route.conditions = { MinLevel = 10 }
APR.RouteQuestStepList["Forever-MageAoE-invented"] = route
APR.ClassName, APR.ClassId = "MAGE", 8
assert(not APR:CanStartRoute("Forever-MageAoE-invented"), "Specialized AoE entry retains its strict boundary")

-- Reputation selection uses one policy on either side of the old level-10 cutoff.
APR.ClassName, APR.ClassId = "WARRIOR", 1
local standing = env.route("standing", "Invented standing guide", {}, nil, APR.CATEGORIES.Reputation)
for _, fixture in ipairs({
    { level = 1, conditions = { Level = 5 }, warning = ">= 5" },
    { level = 1, conditions = { MinLevel = 5 }, warning = ">= 5" },
    { level = 9.99, conditions = { MinLevel = 10 }, warning = ">= 10" },
    { level = 9.99, conditions = { MinLevel = 11 }, warning = ">= 11" },
    { level = 9.99, conditions = { MinLevel = 60 }, warning = ">= 60" },
    { level = 6, conditions = { MaxLevel = 5 }, warning = "<= 5" },
    { level = 6, conditions = { BeLvl = 5 }, warning = "= 5" },
    { level = 6, conditions = { SkipForLvl = 5 }, warning = "< 5" },
}) do
    APR.Level, standing.conditions = fixture.level, fixture.conditions
    assert(APR:GetRouteVisibility("standing") == "visible" and APR:CanStartRoute("standing"))
    local warnings = APR:GetRouteLevelWarnings("standing")
    assert(#warnings == 1 and warnings[1]:find(fixture.warning, 1, true))
    assert(not APR:AreConditionalFiltersMet(standing.conditions), "Advice cannot waive execution filters")
end
standing.conditions = { MinLevel = 10, Faction = "Horde" }
for _, level in ipairs({ 9.99, 10, 10.01 }) do
    APR.Level = level
    assert(APR:GetRouteVisibility("standing") == "visible" and APR:CanStartRoute("standing"))
    assert(#APR:GetRouteLevelWarnings("standing") == (level < 10 and 1 or 0))
    assert(APR:EvaluateRouteConditions(standing.conditions) == (level >= 10), "Recommendations stay strict")
end
APR.Level = 9
standing.conditions = { AnyOf = {
    { Faction = "Alliance", MinLevel = 2 },
    { Faction = "Horde", AllOf = { { MinLevel = 10 } } },
} }
assert(APR:CanStartRoute("standing") and APR:GetRouteVisibility("standing") == "visible")
local warnings = APR:GetRouteLevelWarnings("standing")
assert(#warnings == 1 and warnings[1]:find(">= 10", 1, true), "Only the matching faction branch warns")
assert(not APR:EvaluateRouteConditions(standing.conditions), "Nested recommendations retain their minimum")
standing.conditions = { MinLevel = 10, Faction = "Alliance" }
assert(not APR:CanStartRoute("standing") and APR:GetRouteVisibility("standing") == "hidden")
standing.conditions = { MinLevel = 10, IsQuestCompleted = 4321 }
assert(not APR:CanStartRoute("standing"), "Quest prerequisites remain mandatory")
standing.conditions = { MinLevel = 10, Faction = "Horde" }
env.route("antecedent", "Invented completed prerequisite", { Faction = "Horde" })
standing.requiredRoute = { "antecedent" }
assert(not APR:CanStartRoute("standing") and APR:GetRouteVisibility("standing") == "disabled")
APRZoneCompleted.player["Invented completed prerequisite"] = true
assert(APR:CanStartRoute("standing"), "Completion gates still apply independently of level advice")
standing.requiredRoute = nil
standing.prefab = { [APR.PREFAB_TYPES.StartingZone] = {} }
assert(not APR:CanStartRoute("standing"), "Starter access stays strict even with another category")
standing.prefab = nil
dofile("APR-Core/features/questing/StepTransitions.lua")
assert(APR:AddRouteToCustomPathByKey("standing") and APR:ActivateRoute("standing"))
assert(APR.ActiveRoute == "standing" and not APR:AreConditionalFiltersMet({ MinLevel = 10 }))
standing.gameVersion, standing.expansion = APR.GAME_VERSIONS.Retail, APR.EXPANSIONS.Custom
env.gameVersion = APR.GAME_VERSIONS.Retail
assert(not APR:CanStartRoute("standing") and APR:GetRouteVisibility("standing") == "disabled", "Retail keeps its entry policy")
