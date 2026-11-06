-- Real Speedrun button and builder, driven entirely by invented declarations.
local ui = dofile("tests/lua/route_browser_test_env.lua")
dofile("APR-Core/data/models/Classes.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
local version = APR.GAME_VERSIONS.Forever
function APR:GetGameVersion() return version end
function APR:GetPlayerEffectiveLevel() return self.Level end
local map, spec = 7, 81
function APR:GetPlayerParentMapID() return map end
C_Map = { GetBestMapForUnit = function() return map end }
C_SpecializationInfo =
    { GetSpecialization = function() return 1 end, GetSpecializationInfo = function() return spec end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
function tContains(values, wanted)
    for _, value in ipairs(values) do
        if value == wanted then return true end
    end
    return false
end
function APR:IsDelveRoute() return false end
APR.Faction, APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = "Horde", "Orc", 2, "WARRIOR", 1
APR.Level, APR.MinBoostLvl, APR.MaxLevelChromie, APR.PreviousMaxLvl = 1, 10, 70, 80
local kind = APR.PREFAB_TYPES
local updates, checked = 0, {}
function APR.routeconfig:SendCustomPathUpdate(suppress)
    if not suppress then updates = updates + 1 end
end
function APR.routeconfig:SendMessage() updates = updates + 1 end
function APR:CheckRouteChanges(key) checked[key] = (checked[key] or 0) + 1 end
local function reset()
    APR.RouteQuestStepList, APRCustomPath.test, APRData.test, APRZoneCompleted.test = {}, {}, {}, {}
    APR.ActiveRoute, APR.Level, map, spec = nil, 1, 7, 81
    APR.Faction, APR.Race, APR.ClassName, APR.ClassId = "Horde", "Orc", "WARRIOR", 1
end
local function route(key, index, level, conditions)
    local data = {
        label = "Invented " .. key,
        expansion = APR.EXPANSIONS.Forever,
        category = APR.CATEGORIES.Leveling,
        mapID = 9,
        conditions = conditions or { Faction = "Horde", MinLevel = level },
        prefab = { [kind.Speedrun] = index },
        steps = { { Note = { "Invented instruction" } }, { RouteCompleted = true } },
    }
    APR.RouteQuestStepList[key] = data
    return data
end
local function expect(...)
    local keys = { ... }
    assert(#APRCustomPath.test == #keys, "Unexpected Speedrun path length: " .. #APRCustomPath.test)
    for i, key in ipairs(keys) do
        assert(APRCustomPath.test[i] == APR.RouteQuestStepList[key].label, "Wrong chapter at " .. i)
        assert(APRData.test.RouteChoices[APRCustomPath.test[i]] == key, "Persist the selected variant")
    end
end
reset()
local start = route("start", 1, 1)
start.prefab[kind.StartingZone], start.mapID = 1, 7
start.prefab[kind.Speedrun] = { index = 1, conditions = { SkipForLvl = 10 } }
local wrongStart = route("wrong-start", 0, 1, { Race = "Tauren" })
wrongStart.prefab[kind.StartingZone], wrongStart.mapID = 1, 7
local fast = route("z-fast", 2, 10)
local alternative = route("a-alternative", 20, 10)
local future = route("future", 3, 25)
local finish = route("finish", 4, 58)
finish.prefab[kind.Speedrun] = { index = 4, endLevel = 60 }
future.requiredRoute, finish.requiredRoute = "z-fast", { "future", "a-alternative" }
local dungeon = route("dungeon", 0, 10)
dungeon.category = APR.CATEGORIES.Dungeons
local aoe = route("Forever-MageAoE-invented", 0, 10)
local hidden = route("hidden", 0, 10)
hidden.hiddenFromSelection = true
route("unlinked", 0, 20)
local otherClass = route("class", 0, 10, { Class = "MAGE", MinLevel = 10 })
local otherRace = route("race", 0, 10, { Race = "Tauren", MinLevel = 10 })
local otherFaction = route("faction", 0, 10, { Faction = "Alliance", MinLevel = 10 })
local otherSpec = route("spec", 0, 10, { ClassSpec = 82, MinLevel = 10 })
start.nextRoute =
    { "a-alternative", "dungeon", "Forever-MageAoE-invented", "hidden", "class", "race", "faction", "spec", "z-fast" }
alternative.nextRoute, fast.nextRoute, future.nextRoute = { "finish" }, { "future" }, { "finish" }
assert(APR.routeconfig:HasPrefab("speedrun"))
APR.RouteBrowser:Show()
-- Invoke the actual UI callback; it must retain progress before planning.
local click = APR.RouteBrowser.prefabs[1].scripts.OnClick
APRCustomPath.test = { "Old dungeon selection" }
local before = updates
click()
expect("start", "z-fast", "future", "finish")
assert(updates == before + 1 and not APRZoneCompleted.test[fast.label], "Publish once without inventing completion")
assert(not APR:CanStartRoute("future"), "Queued prerequisites remain actual activation gates")
assert(APR.Level == 1 and not checked.start, "Future-level planning cannot mutate native level/progress")

-- Stable tie break selects one branch; equal indices do not append alternatives.
alternative.prefab[kind.Speedrun] = 2
click()
expect("start", "a-alternative", "finish")
alternative.prefab[kind.Speedrun] = 20
APRData.test["a-alternative"], APR.ActiveRoute = 2, "a-alternative"
click()
expect("a-alternative", "finish")
assert(checked["a-alternative"] == 1, "A started compatible alternative takes precedence over a fresh faster branch")
APRData.test["a-alternative"], APR.ActiveRoute = nil, nil
APR.Level, map = 26, 99
click()
expect("z-fast", "future", "finish")
assert(APRCustomPath.test[1] == fast.label, "An unmet predecessor is retained before a higher-level chapter")
APRZoneCompleted.test[fast.label] = true
click()
expect("future", "finish")
APRData.test.future, APR.ActiveRoute, APR.Level = 2, "future", 59
click()
expect("future", "finish")
assert(APRData.test.future == 2 and checked.future == 1, "Retain and validate partially completed chapters")
APRZoneCompleted.test[future.label] = true
click()
expect("finish")
APR.Level = 60
local preserved, choices, unchanged = APRCustomPath.test, APRData.test.RouteChoices, updates
assert(not APR.routeconfig:HasPrefab("speedrun"))
click()
assert(
    APRCustomPath.test == preserved and APRData.test.RouteChoices == choices and updates == unchanged,
    "A stale unavailable click must preserve the current path and choices"
)

-- Character filters stay strict in presets despite Forever's manual advice.
reset()
local root = route("root", 1, 1)
root.nextRoute = { "warrior", "mage", "tauren", "alliance" }
local warrior = route("warrior", 2, 10, { AllOf = { { Class = 1 }, { Race = "Orc" } }, MinLevel = 10 })
local mage = route("mage", 2, 10, { Class = 8, ClassSpec = 81, MinLevel = 10 })
route("tauren", 2, 10, { Race = "Tauren", ClassNot = "MAGE", MinLevel = 10 })
route("alliance", 2, 10, { Faction = "Alliance", MinLevel = 10 })
for _, key in ipairs({ "warrior", "mage", "tauren", "alliance" }) do
    APR.RouteQuestStepList[key].prefab[kind.Speedrun] = { index = 2, endLevel = 60 }
end
click()
expect("root", "warrior")
APR.ClassName, APR.ClassId = "MAGE", 8
click()
expect("root", "mage")
spec = 82
preserved = APRCustomPath.test
click()
assert(APRCustomPath.test == preserved and not APR.routeconfig:HasPrefab("speedrun"))
APR.Race, APR.ClassName, APR.ClassId = "Tauren", "DRUID", 11
click()
expect("root", "tauren")
APR.Faction, APR.Race = "Alliance", "Human"
APR.Level = 10
click()
expect("alliance") -- root's Horde condition is an admission rule.
APR.Faction = "Neutral"
assert(not APR.routeconfig:HasPrefab("speedrun"))

-- Entry/edge conditions use a future level but current quest/spec/race state.
reset()
root = route("entry", 1, 1)
root.nextRoute = { { route = "late", conditions = { MinLevel = 24, Not = { Class = "MAGE" } } } }
local late = route("late", 2, 24)
late.prefab[kind.Speedrun] = { index = 2, endLevel = 60, conditions = { ClassNot = 8, MinLevel = 24 } }
click()
expect("entry", "late")
APR.ClassName, APR.ClassId = "MAGE", 8
preserved = APRCustomPath.test
click()
assert(APRCustomPath.test == preserved and not APR.routeconfig:HasPrefab("speedrun"))
APR.ClassName, APR.ClassId = "WARRIOR", 1
root.nextRoute[1].conditions.IsQuestCompleted = 12
click()
assert(APRCustomPath.test == preserved and not APR.routeconfig:HasPrefab("speedrun"))
C_QuestLog.IsQuestFlaggedCompleted = function(id) return id == 12 end
click()
expect("entry", "late")
APRZoneCompleted.test[root.label] = true
click()
expect("late")
late.nextRoute = { "entry" }
late.prefab[kind.Speedrun].endLevel = nil
preserved = APRCustomPath.test
click()
assert(
    APRCustomPath.test == preserved and not APR.routeconfig:HasPrefab("speedrun"),
    "A cycle without a terminal cannot masquerade as a complete plan"
)
late.prefab[kind.Speedrun].endLevel = 25
late.nextRoute = nil
click()
assert(
    APRCustomPath.test == preserved and not APR.routeconfig:HasPrefab("speedrun"),
    "A nonempty prefix ending below the target is unavailable"
)
local fallback = route("fallback", 30, 24)
fallback.prefab[kind.Speedrun] = { index = 30, endLevel = 60 }
root.nextRoute = { "late", "fallback" }
click()
expect("fallback")
APRZoneCompleted.test[root.label] = nil
click()
expect("entry", "fallback")
fallback.requiredRoute = "missing"
preserved = APRCustomPath.test
click()
assert(
    APRCustomPath.test == preserved and not APR.routeconfig:HasPrefab("speedrun"),
    "An unsatisfiable prerequisite refuses the entire replacement"
)
APR.RouteQuestStepList = {}
preserved, unchanged = APRCustomPath.test, updates
assert(not APR.routeconfig:HasPrefab("speedrun"))
click()
assert(APRCustomPath.test == preserved and updates == unchanged)

-- A dense dead-end graph cannot make a click enumerate every possible prefix.
reset()
root = route("dense-root", 1, 1)
root.prefab[kind.StartingZone] = 1
root.nextRoute = { "dense-1", "complete" }
for i = 1, 24 do
    local dead = route("dense-" .. i, i + 1, 20)
    dead.nextRoute = {}
    for j = i + 1, 24 do
        dead.nextRoute[#dead.nextRoute + 1] = "dense-" .. j
    end
end
finish = route("complete", 99, 58)
finish.prefab[kind.Speedrun] = { index = 99, endLevel = 60 }
local filters, calls = APR.AreConditionalFiltersMet, 0
function APR:AreConditionalFiltersMet(...)
    calls = calls + 1
    return filters(self, ...)
end
click()
expect("dense-root", "complete")
assert(calls < 1000, "Evaluate dense graph conditions with bounded work")
APR.AreConditionalFiltersMet = filters

-- The same prefab type does not import Forever into the Retail builder.
reset()
version = APR.GAME_VERSIONS.Retail
APR.Level = 20
local retail = route("retail", 1, 1)
retail.expansion, retail.prefab = APR.EXPANSIONS.WarlordsOfDraenor, { [kind.Leveling] = 1 }
route("forever", 0, 1)
function APR:GetStartingZonePrefab() end
click()
assert(#APRCustomPath.test == 1 and APRCustomPath.test[1] == retail.label)
print(
    "Speedrun: actual click, ranked branches, character/spec/quest filters, future levels, prerequisites, progress, refusal and Retail passed"
)
