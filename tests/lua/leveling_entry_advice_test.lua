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
