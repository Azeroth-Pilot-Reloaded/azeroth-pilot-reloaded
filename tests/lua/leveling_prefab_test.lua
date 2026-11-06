-- Exercise the real browser click and popup callbacks with invented guides.
local ui = dofile("tests/lua/route_browser_test_env.lua")
dofile("APR-Core/data/models/Classes.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
local version, map, xp, maxXP = APR.GAME_VERSIONS.Forever, 7, 0, 100
function APR:GetGameVersion() return version end
function APR:GetPlayerParentMapID() return map end
function UnitXP() return xp end
function UnitXPMax() return maxXP end
function UnitFactionGroup() return APR.Faction end
C_Map = { GetBestMapForUnit = function() return map end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
function tContains(values, wanted)
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end
function APR:IsDelveRoute(key) return self.RouteQuestStepList[key] and self.RouteQuestStepList[key].isDelve == true end
local kind, config = APR.PREFAB_TYPES, APR.routeconfig
local updates, checked, popup, selectOption, messages = 0, {}, nil, nil, 0
function config:SendCustomPathUpdate(suppress) if not suppress then updates = updates + 1 end end
function APR:CheckRouteChanges(key) checked[key] = (checked[key] or 0) + 1 end
APR.questionDialog = {
    CreateSelectionPopup = function(_, _, _, options, callback) popup, selectOption = options, callback end,
    CreateMessagePopup = function() messages = messages + 1 end,
}
local function reset()
    APR.RouteQuestStepList, APRData.test, APRCustomPath.test, APRZoneCompleted.test = {}, {}, {}, {}
    APR.Faction, APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = "Horde", "Orc", 2, "WARRIOR", 1
    APR.ActiveRoute, APR.Level, APR.MaxLevel = nil, 1, 60
    APR.MinBoostLvl, APR.MaxLevelChromie, APR.PreviousMaxLvl = 10, 70, 80
    version, map, xp, maxXP, popup, selectOption = APR.GAME_VERSIONS.Forever, 7, 0, 100, nil, nil
    checked = {}
end
local function route(key, index, level, conditions, expansion)
    local data = { label = "Invented " .. key, expansion = expansion or APR.EXPANSIONS.Forever,
        category = APR.CATEGORIES.Leveling, mapID = 9,
        conditions = conditions or { MinLevel = level, Faction = "Horde" },
        prefab = { [kind.Leveling] = index },
        steps = { { Note = { "Synthetic instruction" } }, { RouteCompleted = true } } }
    APR.RouteQuestStepList[key] = data
    return data
end
local function expect(...)
    local keys = { ... }
    assert(#APRCustomPath.test == #keys, "Unexpected Leveling path length: " .. #APRCustomPath.test)
    for i, key in ipairs(keys) do
        assert(APRCustomPath.test[i] == APR.RouteQuestStepList[key].label, "Wrong chapter at " .. i)
        assert(APRData.test.RouteChoices[APRCustomPath.test[i]] == key, "Persist the selected variant")
    end
end
local function refused(action)
    local path, progress, choices, completed, before = APRCustomPath.test, APRData.test,
        APRData.test.RouteChoices, APRZoneCompleted.test, updates
    action()
    assert(APRCustomPath.test == path and APRData.test == progress and APRData.test.RouteChoices == choices
        and APRZoneCompleted.test == completed and updates == before, "Refusal must preserve all live state")
end
reset()
local first = route("first", 1, 1)
first.prefab[kind.StartingZone] = 1
local middle = route("middle", 2, 12)
local future = route("future", 3, 27.5)
local finish = route("finish", 4, 53)
first.nextRoute, middle.nextRoute, future.nextRoute = { "middle" }, { "future" }, { "finish" }
-- Display ranges cannot supply arbitrary gameplay entry requirements.
middle.levelRange = { min = 45, max = 46 }
APR.RouteBrowser:Show()
local click = APR.RouteBrowser.prefabButtons[3].scripts.OnClick
local before = updates
click(); expect("first", "middle", "future", "finish")
assert(updates == before + 1 and not APRZoneCompleted.test[first.label])
APR.Level = 12
click(); expect("middle", "future", "finish")
APR.Level, xp = 27, 49
click(); expect("middle", "future", "finish")
xp = 50
click(); expect("future", "finish")
xp = 51
click(); expect("future", "finish")
APRData.test.middle, APR.ActiveRoute, APR.Level = 2, "middle", 54
click(); expect("middle", "future", "finish")
assert(APRData.test.middle == 2 and checked.middle == 1, "A begun compatible chapter is resumed without reset")
APRZoneCompleted.test[middle.label] = true
click(); expect("finish")
APR.Level = 60
assert(not config:HasPrefab("leveling"))
refused(click)
APR.Level, maxXP = 27, 0
APRZoneCompleted.test[middle.label], APRData.test.middle, APR.ActiveRoute = nil, nil, nil
click(); expect("middle", "future", "finish")

-- Exact upper bounds and exclusive skip levels, with native XP unavailable.
reset()
first = route("bounded", 1, 1, { MinLevel = 1, MaxLevel = 8 })
middle = route("after-bound", 2, 8.5)
first.nextRoute = { "after-bound" }
APR.Level = 8
click(); expect("bounded", "after-bound")
xp = 1
assert(not config:HasPrefab("leveling"), "No usable start in the authored gap")
refused(click)
xp = 50
click(); expect("after-bound")
middle.prefab[kind.Leveling] = { index = 2, conditions = { SkipForLvl = 9 } }
APR.Level, xp = 9, 0
assert(not config:HasPrefab("leveling"))
refused(click)

-- Character filters, condition trees and edge-only admission remain strict.
reset()
first = route("entry", 1, 1)
first.nextRoute = { { route = "warrior", conditions = { MinLevel = 20.5, Not = { Class = "MAGE" } } }, "mage", "race", "faction" }
middle = route("warrior", 3, 10, { AllOf = { { Class = 1 }, { Race = "Orc" } }, MinLevel = 10 })
local mage = route("mage", 2, 10, { Class = 8, MinLevel = 10 })
route("race", 2, 10, { Race = "Tauren", MinLevel = 10 })
route("faction", 2, 10, { Faction = "Alliance", MinLevel = 10 })
APR.Level = 15
click(); expect("entry", "warrior")
APR.Level, xp = 20, 50
click(); expect("warrior")
APR.ClassName, APR.ClassId = "MAGE", 8
click(); expect("mage")
APR.Race, APR.ClassName, APR.ClassId = "Tauren", "DRUID", 11
click(); expect("race")
APR.Faction = "Alliance"
refused(click) -- Horde root cannot make its Alliance-only branch independently reachable.
APR.Faction, APR.Race = "Horde", "Orc"
APR.Level, xp = 1, 0
route("Forever-MageAoE-invented", 1, 20, { Class = 8, MinLevel = 20 })
assert(#config:GetPrefabOptions("leveling") == 1)
APR.ClassName, APR.ClassId, APR.Level = "MAGE", 8, 20
click()
assert(#popup == 2)
local staleOption, callback = popup[2], selectOption
APR.ClassName, APR.ClassId = "WARRIOR", 1
refused(function() callback(staleOption) end)
APR.ClassName, APR.ClassId = "MAGE", 8
callback(staleOption); expect("Forever-MageAoE-invented")
APR.Level = 60
refused(function() callback(staleOption) end)

-- Keep real dependencies, choose one alternative and never fabricate receipts.
reset()
first = route("required", 1, 1)
middle = route("target", 2, 20)
future = route("later", 3, 40)
first.nextRoute, middle.nextRoute, middle.requiredRoute = { "target" }, { "later" }, { "other-class", "required" }
route("other-class", 1, 1, { Class = "MAGE" })
APR.Level = 25
click(); expect("required", "target", "later")
assert(not APR:CanStartRoute("target") and not APRZoneCompleted.test[first.label])
APRZoneCompleted.test[first.label] = true
click(); expect("target", "later")
assert(APR:CanStartRoute("target"))
-- A prerequisite may be explicitly declared outside the prefab itself.
first.prefab = nil
click(); expect("target", "later")
APRZoneCompleted.test[first.label] = nil
click(); expect("required", "target", "later")
first.requiredRoute = "target"
refused(click)
first.requiredRoute, middle.requiredRoute = nil, "missing"
refused(click)

-- A failed future alternative does not hide a usable authored branch or leak
-- the rejected branch's prerequisite prefix into the final replacement.
reset()
first = route("branch-root", 1, 1)
middle = route("broken-branch", 2, 20)
future = route("good-branch", 3, 20)
first.nextRoute, middle.requiredRoute = { "broken-branch", "good-branch" }, "missing"
click(); expect("branch-root", "good-branch")
middle.requiredRoute, middle.nextRoute = nil, { "branch-root" }
click(); expect("branch-root", "good-branch")

reset()
first = route("dense-root", 1, 1)
first.nextRoute = { "dense-1" }
for i = 1, 18 do
    local dead = route("dense-" .. i, i + 1, 20)
    dead.nextRoute = {}
    for j = i + 1, 18 do dead.nextRoute[#dead.nextRoute + 1] = "dense-" .. j end
end
APR.RouteQuestStepList["dense-18"].requiredRoute = "missing"
local filters, calls = APR.AreConditionalFiltersMet, 0
function APR:AreConditionalFiltersMet(...)
    calls = calls + 1
    return filters(self, ...)
end
assert(not config:HasPrefab("leveling"))
assert(calls < 15000, "Dense dead ends must have bounded planning work")
APR.AreConditionalFiltersMet = filters

-- Shared-label variants and index-only data retain deterministic choices.
reset()
first = route("a-variant", 1, 1)
middle = route("z-variant", 1, 1)
middle.label = first.label
future = route("tail", 2, 30)
click(); expect("a-variant", "tail")
APRData.test.RouteChoices[first.label] = "z-variant"
click(); expect("z-variant", "tail")
APRData.test["a-variant"], APR.ActiveRoute = 2, "a-variant"
click(); expect("a-variant", "tail")
-- Hidden, temporary, incompatible client and non-Leveling data are excluded.
for _, key in ipairs({ "hidden", "temporary", "client", "delve" }) do route(key, 0, 1) end
APR.RouteQuestStepList.hidden.hiddenFromSelection = true
APR.RouteQuestStepList.temporary.temporary = true
APR.RouteQuestStepList.client.gameVersion = APR.GAME_VERSIONS.Retail
APR.RouteQuestStepList.delve.isDelve = true
route("dungeon", 0, 1).prefab = { [kind.Dungeons] = 1 }
click()
assert(popup and #popup == 2)
selectOption(popup[1]); expect("a-variant", "tail")
future.requiredRoute = "delve"
refused(function() selectOption(popup[1]) end)
future.requiredRoute = nil

-- Retail uses scaled expansion bands and actual chapter conditions, not a
-- guessed linear level distribution. Future chapters survive until the cap.
reset()
version, APR.MaxLevel, APR.Level = APR.GAME_VERSIONS.Retail, 90, 40
local old = APR.EXPANSIONS.WarlordsOfDraenor
first = route("scaled-intro", 1, 10, nil, old)
middle = route("scaled-later", 2, 15, nil, old)
future = route("scaled-future", 3, 55, nil, old)
first.nextRoute, middle.nextRoute = { "scaled-later" }, { "scaled-future" }
local tww = route("newer", 1, 70, nil, APR.EXPANSIONS.TheWarWithin)
local midnight = route("latest", 1, 80, nil, APR.EXPANSIONS.Midnight)
route("postcap", 2, 90, nil, APR.EXPANSIONS.Midnight)
route("foreign", 0, 1)
click(); expect("scaled-later", "scaled-future")
APR.Level = 69
click(); expect("scaled-future")
APR.Level = 70
click(); expect("newer")
APR.Level = 79
click(); expect("newer")
APR.Level = 80
click(); expect("latest")
APR.Level = 90
assert(not config:HasPrefab("leveling"))
refused(click)
APR.Level = 5
local starter = route("starter", 1, 1, { Race = "Orc", MaxLevel = 9 }, APR.EXPANSIONS.Vanilla)
starter.mapID, starter.prefab = 7, { [kind.StartingZone] = 1 }
click(); expect("starter", "scaled-intro", "scaled-later", "scaled-future")
APR.Level = 10
click(); expect("scaled-intro", "scaled-later", "scaled-future")
starter.conditions = { Race = "Orc", MinLevel = 10 }
click(); expect("starter", "scaled-intro", "scaled-later", "scaled-future")
starter.conditions.Zones, starter.mapID = { 7 }, 8
click(); expect("starter", "scaled-intro", "scaled-later", "scaled-future")
starter.conditions.Zones, starter.mapID = nil, 7
APR.Level = 40
click(); expect("scaled-later", "scaled-future")
APRData.test.starter, APR.ActiveRoute = 2, "starter"
click(); expect("starter", "scaled-later", "scaled-future")
assert(APRData.test.starter == 2, "A started class/race introduction is retained at its current step")
APRZoneCompleted.test[starter.label] = true
click(); expect("scaled-later", "scaled-future")
APR.Level, APRData.test.starter, APR.ActiveRoute = 20, nil, nil
APRZoneCompleted.test[starter.label] = nil
starter.conditions = { Class = "WARRIOR", MinLevel = 20 }
click(); expect("starter", "scaled-later", "scaled-future")
APR.Level = 25
click(); expect("scaled-later", "scaled-future")
map, APR.Level = nil, 5
refused(click)
-- A stale popup re-plans the live level/client/catalogue before publishing.
APR.Level, map = 75, 7
C_Map.GetMapLevels = function() return 10, 80 end
-- Both currently usable supported expansions create a chooser.
click()
assert(popup and #popup == 2)
staleOption, callback = popup[1], selectOption
APR.Level = 85
refused(function() callback(staleOption) end)
version = APR.GAME_VERSIONS.Forever
refused(function() callback(staleOption) end)
APR.RouteQuestStepList = {}
refused(click)

-- Expansion introductions in old capitals retain the expansion fallback if
-- their authored entry cannot fit the unrelated native map observation.
reset()
version, APR.MaxLevel, APR.Level = APR.GAME_VERSIONS.Retail, 90, 80
first = route("capital-intro", 1, 80, nil, APR.EXPANSIONS.Midnight)
middle = route("campaign", 2, 80, nil, APR.EXPANSIONS.Midnight)
middle.mapID, middle.requiredRoute, first.nextRoute = 8, "capital-intro", { "campaign" }
C_Map.GetMapLevels = function(id) if id == 9 then return 1, 80 end return 80, 90 end
click(); expect("capital-intro", "campaign")
first.conditions.MaxLevel = 79
refused(click)
C_Map.GetMapLevels = nil

-- Native scaling takes precedence over the Chromie fallback; author ceilings
-- remain strict, and observations refresh for every popup and stale action.
reset()
version, APR.MaxLevel, APR.Level = APR.GAME_VERSIONS.Retail, 90, 75
first = route("native", 1, 10, nil, old)
local nativeCalls, nativeLow, nativeHigh = 0, 10, 80
C_Map.GetMapLevels = function() nativeCalls = nativeCalls + 1; return nativeLow, nativeHigh end
assert(APR.MaxLevelChromie == 70 and config:HasPrefab("leveling"))
click(); expect("native")
first.conditions.MaxLevel = 70
assert(not config:HasPrefab("leveling"))
refused(click)
first.conditions.MaxLevel = nil
nativeHigh = 70
refused(click)
nativeHigh = 80
click(); expect("native")
C_Map.GetMapLevels = function() error("Uncached map") end
refused(click)
C_Map.GetMapLevels = nil
refused(click)
APR.Level = 40
click(); expect("native")
nativeLow, nativeHigh, nativeCalls = 10, 80, 0
C_Map.GetMapLevels = function() nativeCalls = nativeCalls + 1; return nativeLow, nativeHigh end
route("same-map-future", 2, 55, nil, old)
config:GetPrefabOptions("leveling")
assert(nativeCalls == 1, "One native query per map in a popup build")
version, APR.MaxLevel = APR.GAME_VERSIONS.Forever, 60
first.expansion = APR.EXPANSIONS.Forever
nativeCalls = 0
click(); expect("native")
assert(nativeCalls == 0, "Forever must not query Retail map scaling")

-- Open bounds are predicates, not midpoint approximations of player levels.
reset()
first = route("open", 1, 1, { Not = { MaxLevel = 20 } })
APR.Level, xp = 20, 25
click(); expect("open")
xp = 0
assert(not config:HasPrefab("leveling"))
refused(click)
first.conditions = { Not = { MinLevel = 20.5 } }
xp = 49
click(); expect("open")
xp = 50
assert(not config:HasPrefab("leveling"))
refused(click)
reset()
APR.ClassName, APR.ClassId, APR.Level = "MAGE", 8, 20
first = route("quest-offer", 1, 1, { IsQuestUncompleted = 42 })
route("Forever-MageAoE-popup", 1, 1, { Class = "MAGE" })
click()
assert(#popup == 2)
staleOption, callback = popup[1], selectOption
APRData.test.checkpoint, APRCustomPath.test = 17, { "Existing itinerary" }
C_QuestLog.IsQuestFlaggedCompleted = function(id) return id == 42 end
refused(function() callback(staleOption) end)
assert(APRData.test.checkpoint == 17)
C_QuestLog.IsQuestFlaggedCompleted = function() return false end

-- Retail preserves its conjunction of applicable required routes, whereas
-- Forever's predecessor list above is an alternative completion contract.
reset()
version, APR.MaxLevel, APR.Level = APR.GAME_VERSIONS.Retail, 90, 40
first = route("preparation", 1, 10, nil, old)
middle = route("unlock", 2, 20, nil, old)
future = route("destination", 3, 40, nil, old)
local waived = route("other-character", 0, 10, { Class = "MAGE" }, old)
future.requiredRoute = { "preparation", "other-character", "unlock" }
click(); expect("preparation", "unlock", "destination")
APRZoneCompleted.test[first.label] = true
click(); expect("unlock", "destination")
middle.prefab = nil
click(); expect("unlock", "destination")
print("Leveling: actual click, XP boundaries, future chapters, branches, prerequisites, resume, variants, stale refusal and client bands passed")
