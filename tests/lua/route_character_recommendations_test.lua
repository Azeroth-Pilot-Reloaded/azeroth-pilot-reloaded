-- Character advice applies to manual Forever entry, never to starter access or steps.
local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
CLASS, RACE, CHARACTER, YES, NO = "Class", "Race", "Character", "Yes", "No"
local visibility = APR.GetRouteVisibility
APR.Level, APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = 20, "Tauren", 6, "SHAMAN", 7
local route = env.route("fixture-chapter", "Invented chapter", {
    Faction = "Horde", Race = { "Orc", "Troll" }, Class = { 1, "MAGE" }, MinLevel = 20,
})
local conditions = route.conditions
local step = { Race = "Orc", Class = "MAGE" }
route.steps[1], route.parallelSteps = step, { { conditions = step, steps = { { Note = "Optional" } } } }
local function contains(lines, text)
    for _, line in ipairs(lines) do if line:find(text, 1, true) then return true end end
    return false
end
assert(APR:GetRouteVisibility("fixture-chapter") == "visible" and APR:CanStartRoute("fixture-chapter"))
assert(APR:GetRouteVisibility("fixture-chapter", true) == "hidden", "Presets keep character recommendations")
local warnings = APR:GetRouteSelectionWarnings("fixture-chapter")
assert(#warnings == 2 and contains(warnings, "Orc") and contains(warnings, "MAGE"))
APR.ClassName, APR.ClassId = "MAGE", 8
warnings = APR:GetRouteSelectionWarnings("fixture-chapter")
assert(#warnings == 1 and contains(warnings, "Orc"), "Matching classes must not produce a class warning")
APR.ClassName, APR.ClassId = "SHAMAN", 7
assert(APR:AddRouteToCustomPathByKey("fixture-chapter") and APR:ActivateRoute("fixture-chapter"))
assert(not APR:AreConditionalFiltersMet(step), "Selecting a route never relaxes its action filters")
assert(not APR:AreConditionalFiltersMet(route.parallelSteps[1].conditions), "Parallel groups stay strict")
assert(route.conditions == conditions and conditions.Class[1] == 1 and conditions.Race[1] == "Orc")
assert(not APR:EvaluateRouteConditions(conditions), "Automatic suggestions remain suitable for the character")
APR.Level = 19
warnings = APR:GetRouteSelectionWarnings("fixture-chapter")
assert(#warnings == 3 and contains(warnings, ">= 20"), "Level and character advice share one warning list")
APR.Level = 20

route.conditions = { Faction = "Alliance", Race = "Orc", Class = "MAGE" }
assert(APR:GetRouteVisibility("fixture-chapter") == "hidden" and not APR:CanStartRoute("fixture-chapter"))
assert(not APR:AddRouteToCustomPathByKey("fixture-chapter"))
route.conditions = { Faction = "Horde", Race = "Tauren", Class = 7 }
assert(#APR:GetRouteSelectionWarnings("fixture-chapter") == 0, "Matching metadata clears advice immediately")
route.conditions = { ClassNot = { "SHAMAN", 8 }, AlliedRace = true }
warnings = APR:GetRouteSelectionWarnings("fixture-chapter")
assert(APR:CanStartRoute("fixture-chapter") and #warnings == 2 and contains(warnings, "≠ "))

-- Nested branch recommendations retain their faction/quest predicates.
route.conditions = { Faction = "Horde", AnyOf = {
    { Class = "MAGE", AllOf = { { Race = "Orc" } } },
    { Class = "WARRIOR", Faction = "Alliance" },
} }
assert(APR:GetRouteVisibility("fixture-chapter") == "visible")
assert(#APR:GetRouteSelectionWarnings("fixture-chapter") > 0)
APR.Faction = "Alliance"
assert(not APR:CanStartRoute("fixture-chapter"), "An outer faction requirement is never advisory")
APR.Faction = "Horde"
route.conditions = { AnyOf = { { Class = "MAGE", IsQuestCompleted = 101 } } }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
assert(APR:GetRouteVisibility("fixture-chapter") == "hidden", "Character advice cannot waive quest gates")
route.conditions = { AnyOf = { { Not = { Race = "Tauren" } } } }
assert(APR:CanStartRoute("fixture-chapter"), "A negated race recommendation cannot prevent manual entry")
route.conditions = { AnyOf = { { Not = { AllOf = { { Class = "SHAMAN" }, { Race = "Tauren" } } } } } }
assert(APR:CanStartRoute("fixture-chapter"), "Nested negated character-only groups are advisory too")
local completed = false
C_QuestLog.IsQuestFlaggedCompleted = function() return completed end
route.conditions = { AnyOf = { { Not = { AnyOf = { { Race = "Tauren" }, { IsQuestCompleted = 101 } } } } } }
assert(APR:CanStartRoute("fixture-chapter"), "Negated branch projection keeps an independently unmet quest")
completed = true
assert(not APR:CanStartRoute("fixture-chapter"), "Removing a race alternative cannot waive a negated quest")
route.conditions = { Class = 8 }
C_CreatureInfo = { GetRaceInfo = function() error("Class localization must not call the race API") end }
assert(#APR:GetRouteSelectionWarnings("fixture-chapter") == 1, "Missing optional class APIs use a safe label fallback")
C_CreatureInfo = { GetClassInfo = function() return nil end }
assert(#APR:GetRouteSelectionWarnings("fixture-chapter") == 1, "Missing optional class data is safe")
C_CreatureInfo.GetClassInfo = function(id) assert(id == 8); return { className = "Localized mage" } end
assert(contains(APR:GetRouteSelectionWarnings("fixture-chapter"), "Localized mage"))
C_CreatureInfo = nil

local starter = env.route("fixture-starter", "Invented starter", { Race = "Orc", Class = "MAGE", Faction = "Horde" },
    { [APR.PREFAB_TYPES.StartingZone] = { index = 1 } })
assert(APR:GetRouteVisibility("fixture-starter") == "hidden" and not APR:CanStartRoute("fixture-starter"))
starter.prefab[APR.PREFAB_TYPES.StartingZone] = 1
assert(APR:GetRouteVisibility("fixture-starter") == "hidden", "Numeric starter entries retain the same restrictions")
APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = "Orc", 2, "MAGE", 8
assert(APR:GetRouteVisibility("fixture-starter") == "visible" and APR:CanStartRoute("fixture-starter"))

-- The prefix is the public AoE scope contract, not the name of a shipped guide.
local mageKey = "Forever-MageAoE-fixture-chapter"
local mage = env.route(mageKey, "Invented AoE chapter", { Race = "Troll", Faction = "Horde" })
assert(APR:GetRouteVisibility(mageKey) == "visible" and APR:CanStartRoute(mageKey))
assert(contains(APR:GetRouteSelectionWarnings(mageKey), "Troll"), "An unmatched mage race only warns")
assert(mage.conditions.Class == nil, "The AoE class gate does not rewrite authored conditions")
APR.ClassName = nil
assert(APR:CanStartRoute(mageKey), "The Mage gate accepts the numeric client class ID too")
APR.ClassName = "MAGE"
mage.prefab = { [APR.PREFAB_TYPES.StartingZone] = 1 }
assert(APR:GetRouteVisibility(mageKey) == "visible", "Same-faction AoE starters waive race while retaining the Mage gate")
mage.prefab = nil
APR.ClassName, APR.ClassId = "WARRIOR", 1
assert(APR:GetRouteVisibility(mageKey) == "hidden" and not APR:CanStartRoute(mageKey))
assert(not APR:AddRouteToCustomPathByKey(mageKey) and not APR:ActivateRoute(mageKey))

route.conditions, route.requiredRoute = { Faction = "Horde" }, { "fixture-predecessor" }
env.route("fixture-predecessor", "Completed incompatible character variant", { Faction = "Horde", Race = "Tauren" })
assert(not APR:CanStartRoute("fixture-chapter"))
APRZoneCompleted.player["Completed incompatible character variant"] = true
assert(APR:CanStartRoute("fixture-chapter"), "A deliberately completed character variant satisfies its dependency")
APR.RouteQuestStepList["fixture-predecessor"].conditions.Faction = "Alliance"
assert(not APR:CanStartRoute("fixture-chapter"), "Opposite-faction completions cannot waive a dependency")

env.gameVersion = APR.GAME_VERSIONS.Retail
local retail = env.route("fixture-retail", "Invented retail chapter", { Race = "Tauren", Class = "MAGE" })
retail.expansion, retail.gameVersion = APR.EXPANSIONS.TheWarWithin, APR.GAME_VERSIONS.Retail
assert(APR:GetRouteVisibility("fixture-retail") == "hidden" and not APR:CanStartRoute("fixture-retail"))

-- Label-only paths remain compatible; explicit choices preserve colliding variants.
env.gameVersion = APR.GAME_VERSIONS.Forever
APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = "Orc", 2, "WARRIOR", 1
local first = env.route("a-collision", "Shared invented label", { Race = "Tauren" })
local second = env.route("z-collision", "Shared invented label", { Race = "Orc" })
first.mapID, second.mapID = 11, 22
APRCustomPath.player, APRData.player.RouteChoices = { first.label }, nil
assert(APR:GetRouteKeyFromDisplayName(first.label) == "z-collision", "Old paths retain their suitable variant")
APRCustomPath.player = {}
assert(APR:AddRouteToCustomPathByKey("a-collision"))
assert(APRData.player.RouteChoices[first.label] == "a-collision")
APR.ActiveRoute = nil
assert(APR:GetRouteKeyFromDisplayName(first.label) == "a-collision", "Reload uses the explicit unadapted variant")
assert(select(3, APR:GetRouteMapIDsAndName(first.label)) == "a-collision")
first.label, first.legacyLabels = "Renamed invented label", { "Shared invented label" }
APR:NormalizeSavedRouteLabels()
assert(APRCustomPath.player[1] == first.label and APRData.player.RouteChoices[first.label] == "a-collision")
assert(APR:GetRouteKeyFromDisplayName(first.label) == "a-collision", "A declared label migration preserves the chosen key")
APR.RouteQuestStepList["a-collision"] = nil
assert(APR:GetSavedRouteChoice(first.label) == nil, "Removed definitions cannot survive through saved choices")
APRData.player.RouteChoices = "obsolete malformed value"
assert(APR:GetRouteKeyFromDisplayName(second.label) == "z-collision")

-- Actual browser records, recycled rows, tooltips and confirmation callbacks.
env = dofile("tests/lua/route_browser_test_env.lua")
APR.GetRouteVisibility = visibility
function APR:GetGameVersion() return self.GAME_VERSIONS.Forever end
function APR:IsDelveRoute() return false end
function APR:GetPlayerEffectiveLevel() return self.Level end
APR.Level, APR.Faction, APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = 20, "Horde", "Tauren", 6, "SHAMAN", 7
APR.RouteQuestStepList = {
    choice = { label = "Unadapted chapter", expansion = APR.EXPANSIONS.Forever,
        conditions = { Faction = "Horde", Race = "Orc", Class = "MAGE" } },
}
CONFIRM_CONTINUE = "Continue?"
local popup, notifications = nil, 0
function APR.UI:ShowConfirmationDialog(prompt, accept, cancel) popup = { prompt = prompt, accept = accept, cancel = cancel } end
function APR.routeconfig:SendCustomPathUpdate() notifications = notifications + 1 end
local catalog, rows = APR.RouteCatalog, APR.RouteBrowserRows
local record = catalog:Build()[1]
local row = rows:Create(UIParent, {}, false)
row.item = record
rows:Bind(row, record, 1, {}, false)
assert(row.name.role == "warning" and row.add:IsEnabled() and row.name:GetText() == record.label)
rows:Tooltip(row, false)
assert(env.tooltip():find("Orc", 1, true) and env.tooltip():find("MAGE", 1, true))
assert(not catalog:ChangePath(record, "add") and #APRCustomPath.test == 0)
assert(table.concat(popup.prompt.details, "\n"):find("MAGE", 1, true) and popup.prompt.description == "Continue?")
popup.cancel()
popup.accept()
assert(#APRCustomPath.test == 0 and notifications == 0, "Cancelling never changes the saved path")
catalog:ChangePath(record, "add")
APR.Faction = "Alliance"
popup.accept()
assert(#APRCustomPath.test == 0, "A stale warning cannot bypass a faction change")
APR.Faction = "Horde"
catalog:ChangePath(record, "add")
popup.accept()
popup.accept()
assert(#APRCustomPath.test == 1 and notifications == 1, "Accepting queues an unadapted route exactly once")
APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = "Orc", 2, "MAGE", 8
record = catalog:Build()[1]
row.item = record
rows:Bind(row, record, 1, {}, false)
assert(#record.warnings == 0 and row.name.role == "routeNotStarted", "Recycled rows clear old character warnings")
APR.RouteQuestStepList.other = { label = record.label, expansion = APR.EXPANSIONS.Forever,
    conditions = { Faction = "Horde", Race = "Tauren", Class = "SHAMAN" } }
local pathRecords = catalog:GetPathRecords(catalog:Build())
assert(#pathRecords == 1 and pathRecords[1].key == "choice", "The path displays the explicitly selected colliding variant")
print("Forever character advice: manual entry, confirmation, starters, factions, AoE, nested predicates, steps and Retail isolation passed")
