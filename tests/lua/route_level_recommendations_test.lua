-- Level recommendations never depend on a maintained guide or its itinerary.
local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
C_Map = { GetBestMapForUnit = function() return 1 end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
local function contains(lines, text)
    for _, line in ipairs(lines) do if line:find(text, 1, true) then return true end end
    return false
end
for _, version in ipairs({ APR.GAME_VERSIONS.Retail, APR.GAME_VERSIONS.Forever }) do
    env.gameVersion = version
    APRData.player, APRCustomPath.player, APRZoneCompleted.player = {}, {}, {}
    APR.ActiveRoute = nil
    local step = { PickUp = { 4001 }, Race = "Orc", SkipForLvl = 18 }
    APR.RouteQuestStepList = {
        chapter = { label = "Invented chapter", gameVersion = version,
            conditions = { MinLevel = 14, MaxLevel = 18 }, steps = { step, { RouteCompleted = true } } },
        boundary = { label = "Starting boundary", gameVersion = version, conditions = { MinLevel = 10 } },
        nested = { label = "Character branch", gameVersion = version,
            conditions = { AnyOf = { { Class = "MAGE", MinLevel = 20 }, { Class = "WARRIOR", MinLevel = 16 } } } },
    }
    APR.Level = 12
    assert(APR:GetRouteVisibility("chapter") == "visible" and APR:CanStartRoute("chapter"))
    assert(contains(APR:GetRouteLevelWarnings("chapter"), ">= 14"))
    assert(not APR:EvaluateRouteConditions(APR.RouteQuestStepList.chapter.conditions),
        "Automatic recommendations still respect the suggested range")
    assert(APR:AddRouteToCustomPathByKey("chapter") and APR:ActivateRoute("chapter"))
    APRData.player.chapter = 1
    APR.Level = 17.99
    assert(APR:StepFilterQoL(step) and not APR:StepFilterQuestHandler(step))
    APR.Level = 18
    assert(not APR:StepFilterQoL(step) and APR:StepFilterQuestHandler(step),
        "Route selection cannot waive a step's authored upper cutoff")
    assert(not APR:AreConditionalFiltersMet(step), "Step conditions stay strict")
    assert(#APR:GetRouteLevelWarnings("chapter") == 0, "Step cutoffs never become route-level recommendations")
    assert(APRData.player.chapter == 1, "Checking recommendations never writes progress")
    APR.Level = 18.25
    local warnings = APR:GetRouteLevelWarnings("chapter")
    assert(#warnings == 1 and contains(warnings, "<= 18"))
    assert(APR:CanStartRoute("chapter"), "Overlevel routes remain selectable")
    assert(step.SkipForLvl == 18, "Warnings and execution never rewrite the declaration")
    APR.Level = 14
    assert(#APR:GetRouteLevelWarnings("chapter") == 0, "Warnings disappear when the range matches")
    assert(APR:GetRouteVisibility("nested") == "visible")
    warnings = APR:GetRouteLevelWarnings("nested")
    assert(#warnings == 1 and contains(warnings, ">= 16"), "Only a matching character branch warns")
    if version == APR.GAME_VERSIONS.Forever then
        APR.RouteQuestStepList.chapter.requiredRoute = { "nested" }
        assert(not APR:CanStartRoute("chapter"), "A recommended level never waives an unfinished prerequisite")
        assert(APR:IsRequiredRouteApplicable("nested"), "A higher suggested level does not hide a prerequisite")
        APRZoneCompleted.player["Character branch"] = true
        assert(APR:CanStartRoute("chapter"), "A completed matching branch counts below its recommended level")
        APR.RouteQuestStepList.chapter.requiredRoute = nil
    end
    APR.Level = 9.99
    assert(APR:GetRouteVisibility("boundary") == "disabled" and not APR:CanStartRoute("boundary"))
    assert(APR:GetRouteVisibility("chapter") == "visible", "The route's threshold determines whether it is advisory")
    APR.Level = 10
    assert(APR:GetRouteVisibility("boundary") == "visible")
    APR.RouteQuestStepList.boundary.conditions = { MaxLevel = 10 }
    APR.Level = 10.01
    assert(not APR:CanStartRoute("boundary"), "The level-10 upper boundary remains enforced")
    APR.RouteQuestStepList.boundary.conditions = { BeLvl = 10 }
    APR.Level = 11
    assert(not APR:CanStartRoute("boundary"), "Exact starting levels remain enforced")
    APR.RouteQuestStepList.boundary.conditions = { BeLvl = 12 }
    APR:InvalidateEffectiveRouteStepsCache("boundary")
    assert(APR:CanStartRoute("boundary") and #APR:GetRouteLevelWarnings("boundary") == 1)

    APR.Level = 18
    local conditional = { AnyOf = { { Class = "MAGE", SkipForLvl = 17 },
        { Class = "WARRIOR", AllOf = { { Race = "Orc", SkipForLvl = 18 } } } } }
    assert(not APR:StepFilterQoL(conditional), "Nested step upper cutoffs stay strict")
    APR.Level = 17.99
    assert(APR:StepFilterQoL(conditional), "A matching step branch remains available below its cutoff")
    APR.Race = "Tauren"
    assert(not APR:StepFilterQoL(conditional), "Nested race conditions remain enforced")
    APR.Race = "Orc"
    APR.Level = 18
    assert(not APR:StepFilterQoL({ SkipForLvl = 10 }), "Starting-step cutoffs stay strict")
    assert(not APR:StepFilterQoL({ MinLevel = 19, SkipForLvl = 20 }), "Action minimum levels remain strict")
    assert(not APR:StepFilterQoL({ MaxLevel = 17, SkipForLvl = 20 }), "Action maximum levels remain strict")
    assert(not APR:StepFilterQoL({ BeLvl = 17, SkipForLvl = 20 }), "Exact action levels remain strict")
    assert(not APR:StepFilterQoL({ IsQuestCompleted = 3999, SkipForLvl = 20 }), "Quest prerequisites stay strict")
    assert(not APR:StepFilterQoL({ Not = { Race = "Orc", SkipForLvl = 20 } }), "Negated character conditions stay strict")

    -- Only metadata contributes warnings, including after definition edits.
    APR.RouteQuestStepList.chapter.steps[1] = { PickUp = { 4002 }, SkipForLvl = 16 }
    assert(#APR:GetRouteLevelWarnings("chapter") == 0, "Step conditions cannot add route-level warnings")
    APR.RouteQuestStepList.chapter.conditions.MinLevel = 21
    assert(contains(APR:GetRouteLevelWarnings("chapter"), ">= 21"), "Metadata warnings stay live after an edit")
    APR.RouteQuestStepList.chapter = { label = "Replacement", gameVersion = version, conditions = { MinLevel = 23 } }
    assert(contains(APR:GetRouteLevelWarnings("chapter"), ">= 23"), "Replaced definitions cannot reuse stale warnings")
end

-- Actual recycled rows expose warnings without disabling the route or hiding progress.
env = dofile("tests/lua/route_browser_test_env.lua")
APR.RouteQuestStepList = {
    advice = { label = "Advisory route", conditions = { MinLevel = 22, MaxLevel = 24 },
        steps = { { PickUp = { 5001 }, SkipForLvl = 24 } } },
}
APR.Level = 20
function APR:GetPlayerEffectiveLevel() return self.Level end
local catalog, rows = APR.RouteCatalog, APR.RouteBrowserRows
local browser = { selectedKey = nil }
local record = catalog:Build()[1]
local row = rows:Create(UIParent, browser, false)
row.item = record
rows:Bind(row, record, 1, browser, false)
assert(row.name:GetText() == "Advisory route" and row.name.role == "warning")
assert(row.add:IsEnabled() and row.progressMarker:IsShown(), "Advice must not disable the add action or remove progress")
rows:Tooltip(row, false)
assert(env.tooltip():find(">= 22", 1, true))
APR.Level = 22
rows:Tooltip(row, false)
assert(not env.tooltip():find(">= 22", 1, true), "Tooltips re-evaluate the level instead of reusing an old warning")
record = catalog:Build()[1]
row.item = record
rows:Bind(row, record, 1, browser, false)
assert(row.name:GetText() == "Advisory route" and row.name.role == "routeNotStarted",
    "A recycled row clears the warning color while preserving the original label")
APR.Level = 24
assert(#catalog:Build()[1].levelWarnings == 0, "An authored step cutoff cannot color the route as advisory")
APR.Level = 24.5
record = catalog:Build()[1]
assert(#record.levelWarnings == 1 and contains(record.levelWarnings, "<= 24"))
APRCustomPath.test = { record.label }
local pathRow = rows:Create(UIParent, browser, true)
pathRow.item = record
rows:Bind(pathRow, record, 1, browser, true)
assert(pathRow.name.role == "warning" and pathRow.name:GetText() == "Advisory route")
print("Route levels: advisory selection only, strict step prerequisites/cutoffs, live warnings and recycled rows passed")
