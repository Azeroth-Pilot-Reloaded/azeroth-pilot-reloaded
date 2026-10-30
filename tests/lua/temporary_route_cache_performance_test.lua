-- A temporary scenario's preserved parent prefix must not rebuild its effective
-- route on every event read. Definitions remain editable without stale snapshots.
local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
function wipe(values) for key in pairs(values) do values[key] = nil end end
APR = {
    PlayerID = "player", EXPANSIONS = { Custom = "custom" }, GAME_VERSIONS = {},
    RouteQuestStepList = {}, GetGameVersion = noop, performanceLogging = true,
    UpdateMapId = noop, UpdateStep = noop,
}
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/features/questing/DelveRoutes.lua")
local metrics = {}
function APR:CountPerformanceEvent(name) metrics[name] = (metrics[name] or 0) + 1 end
function APR:SetRouteProgress(route, progress) APRData[self.PlayerID][route] = progress end
function APR:ActivateRoute(route) self.ActiveRoute = route end

local parent = { steps = {} }
for index = 1, 220 do parent.steps[index] = { Note = "parent " .. index } end
local scenarios = { { scenarioID = 7, steps = {} }, { scenarioID = 9, steps = {} } }
for index = 1, 50 do
    scenarios[1].steps[index] = { Note = "first scenario " .. index }
    scenarios[2].steps[index] = { Note = "second scenario " .. index }
end
local parallel = { Note = "parallel" }
APR.RouteQuestStepList.parent = parent
APR.RouteQuestStepList.temporary = {
    delve = {}, scenarios = scenarios, parallelSteps = { { steps = { parallel } } },
}
local function savedState()
    return { routeKey = "temporary", previousRouteKey = "parent", parentStartIndex = 181,
        replaceStepIndex = 201, scenarioID = 7, kind = "delve", sessionKey = "synthetic-session" }
end
local state = savedState()
APRData = { player = { parent = 181, temporary = 1, TemporaryRouteState = state,
    ["temporary-ParallelStepsState"] = { groups = { { activationOrder = 1, effectiveBeforeIndex = 22 } } } } }
APR.ActiveRoute = "temporary"
local selectedScenario = 7
function APR:GetCurrentDelveContext() return { scenarioID = selectedScenario } end

local initial = APR:BuildEffectiveRouteSteps("temporary")
assert(#initial == 71 and initial[1] == parent.steps[181] and initial[20] == parent.steps[200]
    and initial[21] == scenarios[1].steps[1] and initial[22] == parallel
    and initial[71] == scenarios[1].steps[50])
metrics = {}
local sort, sorts = table.sort, 0
table.sort = function(...) sorts = sorts + 1; return sort(...) end
for _ = 1, 1000 do assert(APR:BuildEffectiveRouteSteps("temporary") == initial) end
table.sort = sort
assert(metrics.EffectiveRouteCacheMiss == nil and metrics.EffectiveRouteCacheHit == 1000 and sorts == 0,
    "1,000 warm prefix reads must reuse the effective route with zero rebuilds or activation sorts")

-- Edits outside the selected parent slice must not invalidate a useful prefix.
parent.steps[1] = { Note = "unrelated edit" }
assert(APR:BuildEffectiveRouteSteps("temporary") == initial)
local editedParent = { Note = "edited preserved step" }
parent.steps[181] = editedParent
local changed = APR:BuildEffectiveRouteSteps("temporary")
assert(changed ~= initial and changed[1] == editedParent and changed[21] == scenarios[1].steps[1])

local previous = changed
local replacement = {}
for index, step in ipairs(parent.steps) do replacement[index] = step end
parent.steps = replacement
changed = APR:BuildEffectiveRouteSteps("temporary")
assert(changed ~= previous and changed[1] == editedParent, "Replacing the parent source refreshes its snapshot")
parent.steps[181] = nil
local missing = APR:BuildEffectiveRouteSteps("temporary")
assert(#missing == 70 and missing[1] == parent.steps[182], "Missing parent entries retain compact prefix semantics")
parent.steps[181] = editedParent
assert(APR:BuildEffectiveRouteSteps("temporary")[1] == editedParent)
state.parentStartIndex = 182
changed = APR:BuildEffectiveRouteSteps("temporary")
assert(#changed == 70 and changed[1] == parent.steps[182] and changed[20] == scenarios[1].steps[1])
state.replaceStepIndex = 200
changed = APR:BuildEffectiveRouteSteps("temporary")
assert(#changed == 69 and changed[18] == parent.steps[199] and changed[19] == scenarios[1].steps[1])
state.parentStartIndex, state.replaceStepIndex = 181, 201
local editedScenario = { Note = "scenario edit" }
scenarios[1].steps[3] = editedScenario
changed = APR:BuildEffectiveRouteSteps("temporary")
assert(changed[24] == editedScenario, "In-place scenario replacements remain visible after a preserved prefix")
scenarios[1].steps[51] = { Note = "appended scenario step" }
assert(#APR:BuildEffectiveRouteSteps("temporary") == 72)
scenarios[1].steps[51] = nil
assert(#APR:BuildEffectiveRouteSteps("temporary") == 71)
selectedScenario = 9
changed = APR:BuildEffectiveRouteSteps("temporary")
assert(#changed == 71 and changed[1] == editedParent and changed[21] == scenarios[2].steps[1])

local anotherParent = { steps = { { Note = "other preserved step" }, { Note = "replacement point" } } }
APR.RouteQuestStepList.other = anotherParent
state.previousRouteKey, state.parentStartIndex, state.replaceStepIndex = "other", 1, 2
changed = APR:BuildEffectiveRouteSteps("temporary")
assert(#changed == 52 and changed[1] == anotherParent.steps[1] and changed[2] == scenarios[2].steps[1])
state.previousRouteKey, state.parentStartIndex, state.replaceStepIndex = "parent", 181, 201
changed = APR:BuildEffectiveRouteSteps("temporary")
local activePrefix = APR._temporaryRouteStepsCache
assert(APR:GetTemporaryRouteSteps("other", scenarios[1].steps) == scenarios[1].steps
    and APR._temporaryRouteStepsCache == activePrefix,
    "A read of another delve must not evict the active temporary session")
APR:InvalidateEffectiveRouteStepsCache("unrelated")
assert(APR:BuildEffectiveRouteSteps("temporary") == changed)
APR:InvalidateEffectiveRouteStepsCache("parent")
assert(APR._temporaryRouteStepsCache == nil)
assert(APR:BuildEffectiveRouteSteps("temporary") ~= changed,
    "Explicit parent invalidation also retires the dependent temporary prefix")

-- SavedVariables can be replaced during import/reload; no old state owns the new prefix.
changed = APR:BuildEffectiveRouteSteps("temporary")
APRData.player.TemporaryRouteState = savedState()
local restored = APR:BuildEffectiveRouteSteps("temporary")
assert(restored ~= changed and restored[21] == scenarios[2].steps[1])
assert(APR._temporaryRouteStepsCache.state == APRData.player.TemporaryRouteState)
assert(APR:ClearTemporaryRoute({ completed = true }))
assert(APRData.player.TemporaryRouteState == nil and APR._temporaryRouteStepsCache == nil
    and APR.ActiveRoute == "parent" and APRData.player.parent == 202)
local unprefixed = APR:BuildEffectiveRouteSteps("temporary")
assert(#unprefixed == 101 and unprefixed[1] == scenarios[1].steps[1])
assert(not APR:ClearTemporaryRoute())

APRData.player.TemporaryRouteState = savedState()
APR.ActiveRoute = "temporary"
changed = APR:BuildEffectiveRouteSteps("temporary")
APR:InvalidateEffectiveRouteStepsCache()
assert(APR._temporaryRouteStepsCache == nil and APR:BuildEffectiveRouteSteps("temporary") ~= changed)
APRData.player.TemporaryRouteState.replaceStepIndex = nil
assert(#APR:BuildEffectiveRouteSteps("temporary") == 51 and APR._temporaryRouteStepsCache == nil)
print("Temporary route prefixes: 1,000 reads/zero rebuilds; parent slices, scenario edits, source/state replacement, completion and reset passed")
