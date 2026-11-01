-- Discovery must scale with matching guides, not the full catalog on every read.
APR = { RouteQuestStepList = {}, DelveRouteRegistry = {}, PlayerID = "fixture" }
APRData = {}
function LibStub() return { GetLocale = function() return { DELVE = "Delve" } end } end
local client, scenario, map, step = "retail", 41, 20, 1
function APR:GetGameVersion() return client end
function APR:GetRouteData(key)
    local data = self.RouteQuestStepList[key]
    return data and (not data.client or data.client == client) and data or nil
end
function APR:GetMapInfoCached(id) return { name = "Map " .. id } end
C_Map = { GetBestMapForUnit = function() return map end }
C_ScenarioInfo = {
    GetScenarioInfo = function() return { scenarioID = scenario } end,
    GetScenarioStepInfo = function() return { stepID = step } end,
}
dofile("APR-Core/features/questing/DelveRoutes.lua")
local function guide(label, ids, requiredClient)
    local blocks = {}
    for _, id in ipairs(ids) do blocks[#blocks + 1] = { scenarioID = id, steps = {} } end
    return { label = label, delve = {}, scenarios = blocks, client = requiredClient }
end
for i = 1, 1000 do APR.RouteQuestStepList["ordinary" .. i] = { steps = {} } end
APR.RouteQuestStepList.alpha = guide("Alpha", { 41, 41, 42 })
APR.RouteQuestStepList.beta = guide("beta", { 41 })
APR.RouteQuestStepList.classic = guide("Classic", { 41 }, "classic")
local scans, isDelve = 0, APR.IsDelveRoute
function APR:IsDelveRoute(key) scans = scans + 1; return isDelve(self, key) end
assert(#APR:FindDelveRoutesForContext(nil) == 0 and scans == 0)
local matches, found = APR:FindDelveRoutesForContext({ scenarioID = 41 })
assert(found and #matches == 2 and matches[1].key == "alpha" and matches[2].key == "beta",
    "Duplicate blocks produce one result; unavailable client routes remain excluded")
local firstScan = scans
for _ = 1, 1000 do
    local result = APR:FindDelveRoutesForContext({ scenarioID = "41" })
    assert(#result == 2)
end
assert(scans == firstScan, "Repeated discovery cannot scan unrelated declarations")
matches[1].key = "corrupted"
APR.RouteQuestStepList.alpha.label = "Zulu"
matches = APR:FindDelveRoutesForContext({ scenarioID = 41 })
assert(matches[1].key == "beta" and matches[2].label == "Zulu", "Results are independent and labels stay live")
APR.RouteQuestStepList.beta = nil
assert(#APR:FindDelveRoutesForContext({ scenarioID = 41 }) == 1, "Deleted guides disappear immediately")
APR.RouteQuestStepList.added = guide("Added", { 41 })
APR._routeLookupRevision = 1
assert(#APR:FindDelveRoutesForContext({ scenarioID = 41 }) == 2, "Imports invalidate discovery through the route revision")
APR.RouteQuestStepList.added.scenarios[1].scenarioID = 43
APR:InvalidateDelveRouteIndex()
assert(#APR:FindDelveRoutesForContext({ scenarioID = 43 }) == 1, "In-place edits rebuild scenario membership")
client = "classic"
assert(#APR:FindDelveRoutesForContext({ scenarioID = 41 }) == 2, "Changing client replaces the filtered index")
APR.DelveRouteRegistry = {}
firstScan = scans
APR:FindDelveRoutesForContext({ scenarioID = 41 })
assert(scans > firstScan, "Replacing the registration catalog invalidates discovery")

APR.ActiveRoute = "alpha"
local lookups, find = 0, APR.FindDelveRoutesForContext
function APR:FindDelveRoutesForContext(context) lookups = lookups + 1; return find(self, context) end
firstScan = scans
for _ = 1, 1000 do assert(APR:GetCurrentDelveContext().scenarioID == 41) end
assert(lookups == 0 and scans - firstScan == 1000,
    "Reading an active delve checks only its live membership, without discovery")
scenario, step, map = 42, 7, 21
local context = APR:GetCurrentDelveContext()
assert(context.scenarioID == 42 and context.stepID == 7 and context.mapID == 21,
    "Native context data remains live across scenario, step and map changes")
scenario = 43
assert(APR:GetCurrentDelveContext().scenarioID == 43 and lookups == 1,
    "An unrelated active guide still discovers another compatible scenario")
scenario = 999
assert(APR:GetCurrentDelveContext() == nil, "Leaving known scenarios cannot retain stale context")
map = nil
assert(APR:GetCurrentDelveContext() == nil, "Missing map data remains safe")
APR.RouteQuestStepList = { fresh = guide("Fresh", { 55 }) }
assert(#APR:FindDelveRoutesForContext({ scenarioID = 55 }) == 1,
    "Replacing the route catalog drops the old index")
print("Delve discovery: bounded hot reads, live context, independent results, edits/imports/client invalidation passed")
