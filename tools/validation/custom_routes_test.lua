local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
APR = { RouteQuestStepList = {}, EXPANSIONS = { Custom = "Custom" }, CATEGORIES = { Miscellaneous = "Misc" } }
APRData = { CustomRoute = {} }
local timers, messages, invalidated = {}, {}, {}
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
APR.routeconfig = { SendMessage = function(_, message) messages[#messages + 1] = message end }
function APR:InvalidateEffectiveRouteStepsCache(key) invalidated[key] = true end
dofile("APR-Core/utils/RouteUtils.lua")
local definition = { steps = { { Note = "Saved" } }, label = "Example", mapID = 84, gameVersion = "retail",
    nextRoute = { "next" }, requiredRoute = { "intro" }, XPConsumables = false, prefab = { speedrun = 5 },
    parallelSteps = { { conditions = { Level = 10 }, steps = { { Note = "Parallel" } } } },
    futureMetadata = { enabled = false } }
assert(APR:RegisterCustomRoute("84-Example", definition))
assert(APR:RegisterCustomRoute("85-Other", { steps = {} }))
assert(#timers == 1 and invalidated["84-Example"])
timers[1](); timers = {}
assert(#messages == 1 and messages[1] == "APR_Route_Catalog_Update")
definition.steps[1].Note = "Caller mutation"
APR.RouteQuestStepList["84-Example"].steps[1].Note = "Runtime mutation"
APR.RouteQuestStepList["84-Example"].parallelSteps[1].steps[1].Note = "Runtime parallel"
assert(APRData.CustomRoute["84-Example"].steps[1].Note == "Saved")
assert(APRData.CustomRoute["84-Example"].parallelSteps[1].steps[1].Note == "Parallel")

-- A reload must retain all metadata, false values and legacy support.
APR.RouteQuestStepList = {}
APRData.CustomRoute.legacy = { { PickUp = { 42 } } }
APRData.CustomRoute.invalid = false
APRData.CustomRoute.badSteps = { steps = "invalid" }
APR:LoadCustomRoutes()
local loaded = APR.RouteQuestStepList["84-Example"]
assert(loaded.steps[1].Note == "Saved" and loaded.mapID == 84 and loaded.gameVersion == "retail")
assert(loaded.nextRoute[1] == "next" and loaded.requiredRoute[1] == "intro")
assert(loaded.XPConsumables == false and loaded.prefab.speedrun == 5 and loaded.futureMetadata.enabled == false)
loaded.steps[1].Note = "Detached after reload"
assert(APRData.CustomRoute["84-Example"].steps[1].Note == "Saved")
assert(APR.RouteQuestStepList.legacy.steps[1].PickUp[1] == 42)
assert(not APR.RouteQuestStepList.invalid and not APR.RouteQuestStepList.badSteps)

APR.ActiveRoute = "84-Example"
assert(APR:RegisterCustomRoute("84-Example", { steps = { { Note = "Changed active route" } } }))
timers[1]()
assert(messages[2] == "APR_Custom_Path_Update")
assert(not APR:RegisterCustomRoute("", definition))
assert(not APR:RegisterCustomRoute("invalid", false))
print("Custom routes: complete metadata, persistence isolation, legacy arrays and coalesced refresh passed")
