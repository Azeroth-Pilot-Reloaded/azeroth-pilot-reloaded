-- Class metadata remains an access gate; race advice stays available.
CLASS, RACE, CHARACTER, YES, NO = "Class", "Race", "Character", "Yes", "No"
local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
APR.Level = 30
local route = env.route("fixture-class", "Invented class chapter", {
    Class = "MAGE", Faction = "Horde",
}, nil, APR.CATEGORIES.Class)
assert(APR:GetRouteVisibility("fixture-class") == "hidden", "Class chapters must hide other classes")
assert(not APR:CanStartRoute("fixture-class"))
assert(not APR:AddRouteToCustomPathByKey("fixture-class"))
assert(not APR:ActivateRoute("fixture-class"))
APR.ClassName, APR.ClassId = "MAGE", 8
assert(APR:GetRouteVisibility("fixture-class") == "visible")
route.conditions = { Class = { "WARRIOR", 8 }, Race = "Tauren", Faction = "Horde" }
assert(APR:CanStartRoute("fixture-class"), "Matching list members retain racial advice")
assert(#APR:GetRouteSelectionWarnings("fixture-class") == 1)
route.conditions.Class = { 1, "SHAMAN" }
assert(APR:GetRouteVisibility("fixture-class") == "hidden")
route.conditions = { ClassNot = { 8, "WARRIOR" } }
assert(not APR:CanStartRoute("fixture-class"))
route.conditions = { AllOf = { { Class = "MAGE" }, { Faction = "Horde" } } }
assert(APR:CanStartRoute("fixture-class"))
route.conditions = { AnyOf = { { Class = "WARRIOR", Race = "Tauren" }, { Class = 8, Faction = "Alliance" } } }
assert(not APR:CanStartRoute("fixture-class"), "An incompatible class arm cannot bypass faction")
route.conditions = { AnyOf = { { Class = "MAGE", Race = "Tauren" }, { Class = 1 } } }
assert(APR:CanStartRoute("fixture-class"))
route.conditions = { Not = { AnyOf = { { Class = "MAGE" }, { Race = "Tauren" } } } }
assert(not APR:CanStartRoute("fixture-class"), "Nested negation retains class restrictions")
route.conditions = { Not = { AllOf = { { Class = "MAGE" }, { Race = "Tauren" } } } }
assert(APR:CanStartRoute("fixture-class"), "A passing authored branch stays valid")
route.conditions = nil
assert(APR:CanStartRoute("fixture-class"), "Absent class metadata cannot infer a restriction from a label")
route.conditions = { Class = "WARRIOR" }
route.category = APR.CATEGORIES.Leveling
assert(APR:CanStartRoute("fixture-class"), "Other categories retain class advice")
route.category = APR.CATEGORIES.Class
route.expansion = APR.EXPANSIONS.Classic
route.gameVersion = APR.GAME_VERSIONS.Retail
env.gameVersion = APR.GAME_VERSIONS.Retail
assert(not APR:CanStartRoute("fixture-class"), "Retail retains strict class conditions")
env.gameVersion = APR.GAME_VERSIONS.Forever
assert(APR:GetRouteVisibility("fixture-class") == "hidden", "Client compatibility still precedes selection")
route.gameVersion, route.expansion = nil, APR.EXPANSIONS.Forever
route.conditions = { Class = "MAGE", IsQuestCompleted = 731 }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
assert(not APR:CanStartRoute("fixture-class"), "Class matches cannot bypass quest requirements")
route.conditions = { Class = "MAGE" }
function APR:GetSettingsProfile() return {} end
dofile("APR-Core/features/questing/RouteCatalog.lua")
local catalog = APR.RouteCatalog
local records = catalog:Build()
assert(#catalog:Filter(records, { category = APR.CATEGORIES.Class }) == 1)
APRCustomPath.player = { route.label }
APR.ClassName, APR.ClassId = "WARRIOR", 1
records = catalog:Build()
assert(#records == 1 and records[1].visibility == "hidden", "Saved paths retain removable mismatching chapters")
assert(#catalog:Filter(records, { category = APR.CATEGORIES.Class }) == 0,
    "Queuing never exposes an incompatible class in the browser")
assert(not APR:CanStartRoute("fixture-class"))
assert(#catalog:GetCategories(records, {}) == 1, "Hidden class routes do not populate the category list")
APR.ClassName, APR.ClassId = "MAGE", 8
assert(#catalog:Filter(catalog:Build(), { category = APR.CATEGORIES.Class }) == 1,
    "A rebuild uses current character metadata")
print("Class selection: identifiers, lists, exclusion, nesting, factions, warnings and category/client isolation passed")
