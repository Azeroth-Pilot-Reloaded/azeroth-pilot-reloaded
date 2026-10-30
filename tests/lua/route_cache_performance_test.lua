-- Cache hits must not rebuild/sort activation keys on frequent gameplay events.
local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
function wipe(values) for key in pairs(values) do values[key] = nil end end
APR = {
    PlayerID = "player", EXPANSIONS = { Custom = "custom" }, GAME_VERSIONS = {},
    RouteQuestStepList = {}, IsDelveRoute = function() return false end,
    GetGameVersion = noop,
}
dofile("APR-Core/features/questing/RouteManager.lua")

local first, last = { Note = "first" }, { Note = "last" }
local route = { steps = { first, last }, parallelSteps = {} }
local state = { groups = {} }
APR.RouteQuestStepList.synthetic = route
APRData = { player = { ["synthetic-ParallelStepsState"] = state } }
for index = 1, 60 do
    route.parallelSteps[index] = { steps = { { Note = "insert " .. index } } }
    state.groups[index] = { activationOrder = index, effectiveBeforeIndex = index + 1 }
end
local steps = APR:BuildEffectiveRouteSteps("synthetic")
assert(#steps == 62 and steps[1] == first and steps[62] == last)
for index = 1, 60 do assert(steps[index + 1] == route.parallelSteps[index].steps[1]) end

local sort, format, concat = table.sort, string.format, table.concat
local sorts, formats, concats = 0, 0, 0
table.sort = function(...) sorts = sorts + 1; return sort(...) end
string.format = function(...) formats = formats + 1; return format(...) end
table.concat = function(...) concats = concats + 1; return concat(...) end
for _ = 1, 1000 do
    assert(APR:BuildEffectiveRouteSteps("synthetic") == steps)
end
table.sort, string.format, table.concat = sort, format, concat
assert(sorts == 0 and formats == 0 and concats == 0,
    "1,000 warm reads of 60 active groups must not sort or format activation keys")

-- Direct saved-state edits must invalidate even when their table identity survives.
state.groups[1].effectiveBeforeIndex = 1
local moved = APR:BuildEffectiveRouteSteps("synthetic")
assert(moved ~= steps and moved[1] == route.parallelSteps[1].steps[1] and moved[2] == first)
state.groups[1].effectiveBeforeIndex = 2
steps = APR:BuildEffectiveRouteSteps("synthetic")
assert(steps[1] == first and steps[2] == route.parallelSteps[1].steps[1])

state.groups[1].activations = {
    { activationOrder = 1, effectiveBeforeIndex = 2 },
    { activationOrder = 61, effectiveBeforeIndex = 63 },
}
local repeated = APR:BuildEffectiveRouteSteps("synthetic")
assert(#repeated == 63 and repeated[63] == route.parallelSteps[1].steps[1])
state.groups[1].activations[2] = nil
assert(#APR:BuildEffectiveRouteSteps("synthetic") == 62)
state.groups[60] = nil
assert(#APR:BuildEffectiveRouteSteps("synthetic") == 61)
state.groups[60] = { activationOrder = 60, effectiveBeforeIndex = 61 }
assert(#APR:BuildEffectiveRouteSteps("synthetic") == 62)

-- Replacement definitions of the same size cannot reuse the old effective array.
local replacement = { Note = "replacement" }
route.parallelSteps[1].steps = { replacement }
steps = APR:BuildEffectiveRouteSteps("synthetic")
assert(steps[2] == replacement)
local newFirst = { Note = "new first" }
route.steps = { newFirst, last }
assert(APR:BuildEffectiveRouteSteps("synthetic")[1] == newFirst)
route.parallelSteps[1] = { steps = {} }
assert(#APR:BuildEffectiveRouteSteps("synthetic") == 61)
route.parallelSteps[1].steps[1] = replacement
assert(APR:BuildEffectiveRouteSteps("synthetic")[2] == replacement)
steps = APR:BuildEffectiveRouteSteps("synthetic")
APR:InvalidateEffectiveRouteStepsCache("synthetic")
local rebuilt = APR:BuildEffectiveRouteSteps("synthetic")
assert(rebuilt ~= steps and rebuilt[2] == replacement)
print("Route cache: 1,000 warm reads/60 activations with zero key sorts or formatting; saved-state and definition edits remain live")

-- Delve event reads must reuse their flattened scenario instead of reconstructing
-- its array; same-length scenario changes and direct edits must remain visible.
local scenarios = {
    { scenarioID = 7, steps = {} },
    { scenarioID = 9, steps = {} },
}
for index = 1, 50 do
    scenarios[1].steps[index] = { Note = "first scenario " .. index }
    scenarios[2].steps[index] = { Note = "second scenario " .. index }
end
local activeScenario = 7
dofile("APR-Core/features/questing/DelveRoutes.lua")
APR.GetCurrentDelveContext = function() return { scenarioID = activeScenario } end
APR.ActiveRoute = "delve"
local inserted = { Note = "parallel" }
APR.RouteQuestStepList.delve = { delve = {}, scenarios = scenarios, parallelSteps = { { steps = { inserted } } } }
APRData.player["delve-ParallelStepsState"] = { groups = {
    { activationOrder = 1, effectiveBeforeIndex = 2 },
} }
local delveSteps = APR:BuildEffectiveRouteSteps("delve")
assert(#delveSteps == 51 and delveSteps[1] == scenarios[1].steps[1] and delveSteps[2] == inserted)
local insert, inserts = table.insert, 0
table.insert = function(...) inserts = inserts + 1; return insert(...) end
table.sort = function(...) sorts = sorts + 1; return sort(...) end
sorts = 0
for _ = 1, 1000 do assert(APR:BuildEffectiveRouteSteps("delve") == delveSteps) end
table.insert, table.sort = insert, sort
assert(inserts == 0 and sorts == 0,
    "1,000 stable delve reads must not rebuild the 50-step scenario arrays or sort scenario IDs")
activeScenario = 9
local switched = APR:BuildEffectiveRouteSteps("delve")
assert(switched ~= delveSteps and switched[1] == scenarios[2].steps[1] and switched[2] == inserted,
    "Different scenarios of equal length must not reuse the previous effective route")
local edited = { Note = "edited in place" }
scenarios[2].steps[1] = edited
assert(APR:BuildEffectiveRouteSteps("delve")[1] == edited)
scenarios[2].steps[51] = { Note = "appended" }
assert(#APR:BuildEffectiveRouteSteps("delve") == 52)
scenarios[2].steps[51] = nil
assert(#APR:BuildEffectiveRouteSteps("delve") == 51)
scenarios[2].scenarioID = 10
assert(#APR:BuildEffectiveRouteSteps("delve") == 101,
    "An unavailable selected scenario falls back to every block")
APRData.player.TemporaryRouteState = { routeKey = "delve", scenarioID = 999 }
local fallback = APR:BuildEffectiveRouteSteps("delve")
local fallbackInserts = 0
table.insert = function(...) fallbackInserts = fallbackInserts + 1; return insert(...) end
for _ = 1, 1000 do assert(APR:BuildEffectiveRouteSteps("delve") == fallback) end
table.insert = insert
assert(fallbackInserts == 0,
    "A saved but unavailable scenario must reuse both the empty selection and all-block fallback")
print("Delve cache: 1,000 stable 50-step reads with zero flatten inserts; equal-length scenario switches and in-place edits remain live")
