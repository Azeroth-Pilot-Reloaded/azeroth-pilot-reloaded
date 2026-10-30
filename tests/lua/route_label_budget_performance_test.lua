-- A startup signature job must budget display-name resolution as well as bytes.
local noop = function() end
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
function tinsert(values, value) values[#values + 1] = value end
APR = { EXPANSIONS = { Test = "Test" }, PlayerID = "player", version = "1",
    settings = { profile = { lastRecordedVersion = "1" } }, Debug = noop,
    RouteQuestStepList = {}, questionDialog = { CreateMessagePopup = function() error("No reset expected") end } }
local state = { clock = 0, scans = 0, visibilityReads = 0, visibility = {} }
local catalogue, keys = APR.RouteQuestStepList, {}
for index = 1, 2000 do
    local key = "candidate-" .. index
    keys[index] = key
    catalogue[key] = { label = "Other label " .. index, expansion = "Test", steps = { {} } }
end
local function declare(key, data)
    if not catalogue[key] then keys[#keys + 1] = key end
    catalogue[key] = data
end
declare("z-shared", { label = "Shared", expansion = "Test", mapID = 30, steps = { {} } })
declare("b-shared", { label = "Shared", legacyLabels = { "Legacy label" }, expansion = "Test", mapID = 20,
    conditions = { Zones = { 20, 50, 20, 0 } }, steps = { {} } })
declare("a-shared", { label = "Shared", expansion = "Test", mapID = 10, steps = { {} } })
local nativePairs, nativeSort = pairs, table.sort
function pairs(values)
    if values ~= catalogue then return nativePairs(values) end
    local index = 0
    return function()
        index = index + 1
        local key = keys[index]
        if key then
            state.scans, state.clock = state.scans + 1, state.clock + 0.02
            return key, catalogue[key]
        end
    end
end
function APR:GetRouteVisibility(key)
    state.visibilityReads = state.visibilityReads + 1
    state.lastVisibility = key
    return state.visibility[key] or "visible"
end
function APR:GetEnumKeyByValue() return "Test" end
function APR:GetRouteData(key) return catalogue[key] end
function APR:GetRouteSignature() return "unchanged" end
dofile("APR-Core/utils/RouteUtils.lua")
table.sort = function() error("Display-name lookup must not sort its catalogue matches") end

local function expect(label, wanted)
    local maps, map, key, expansion = APR:GetRouteMapIDsAndName(label)
    assert(key == wanted and expansion == "Test")
    assert(map == catalogue[wanted].mapID and maps[1] == map)
    assert(APR:GetRouteKeyFromDisplayName(label) == wanted)
    return maps
end
state.visibility["a-shared"] = "hidden"
state.visibility["b-shared"] = "disabled"
local maps = expect("Shared", "b-shared")
assert(#maps == 2 and maps[2] == 50, "Map metadata still deduplicates condition zones")
expect("Legacy label", "b-shared")
state.visibility["b-shared"] = "hidden"
expect("Shared", "z-shared")
state.visibility["z-shared"] = "hidden"
expect("Shared", "a-shared")
state.visibility = {}
state.visibilityReads = 0
expect("Shared", "a-shared")
assert(state.visibilityReads == 2, "Each resolver checks only the first variant when it is available")
local before = state.scans
expect("b-shared", "b-shared")
assert(state.scans == before, "An exact key does not inspect the catalogue or its visibility")
assert(APR:GetRouteKeyFromDisplayName(nil) == nil and APR:GetRouteKeyFromDisplayName("missing") == nil)
assert(select(3, APR:GetRouteMapIDsAndName("missing")) == "")

declare("00-no-metadata", { label = "Shared", mapID = 2 })
assert(APR:GetRouteKeyFromDisplayName("Shared") == "00-no-metadata")
assert(select(3, APR:GetRouteMapIDsAndName("Shared")) == "a-shared",
    "Map resolution retains its requirement for expansion metadata")
catalogue["00-no-metadata"].label = "Renamed"
catalogue["a-shared"].label = "Renamed"
assert(APR:GetRouteKeyFromDisplayName("Shared") == "b-shared", "In-place label changes are observed immediately")
catalogue["a-shared"].label = "Shared"
catalogue["b-shared"].legacyLabels[1] = "Changed alias"
assert(APR:GetRouteKeyFromDisplayName("Legacy label") == nil and APR:GetRouteKeyFromDisplayName("Changed alias") == "b-shared")
catalogue["b-shared"].legacyLabels[1] = "Legacy label"

local instrumentation = APRInstrumentation
local resume = instrumentation and instrumentation.Resume or coroutine.resume
local checkpoint = instrumentation and instrumentation.Yield or coroutine.yield
local largest, batches = 0, 0
local function budgeted(callback)
    local thread = coroutine.create(callback)
    local result
    repeat
        local started = state.clock
        repeat
            local ok
            ok, result = resume(thread)
            assert(ok, result)
            if coroutine.status(thread) == "dead" then break end
        until state.clock - started >= 2
        local elapsed = state.clock - started
        largest, batches = math.max(largest, elapsed), batches + 1
        assert(elapsed < 2.03, "Catalogue scanning may overrun 2 ms only by one small controlled lookup")
        assert(batches < 1000)
    until coroutine.status(thread) == "dead"
    return result
end
state.clock, state.scans = 0, 0
assert(budgeted(function() return select(3, APR:GetRouteMapIDsAndName("Shared", checkpoint)) end) == "a-shared")
assert(state.scans == #keys and state.clock > 40 and batches > 10)

-- Exercise the real startup caller, not just an optional argument in isolation.
APRData = { player = { ["b-shared"] = 1, ["b-shared-RawTotalSteps"] = 1,
    RouteSignatures = { ["b-shared"] = "unchanged" } } }
APRCustomPath, APRZoneCompleted = { player = { "Shared" } }, { player = { Shared = true } }
state.visibility["a-shared"], state.visibility["b-shared"] = "hidden", "disabled"
state.clock, state.scans, batches = 0, 0, 0
assert(budgeted(function() return APR:CheckCurrentRouteUpToDate(nil, checkpoint) end))
assert(state.scans == #keys and batches > 10 and APRData.player["b-shared"] == 1 and APRZoneCompleted.player.Shared)
assert(APRData.player.RouteSignatures["b-shared"] == "unchanged", "Budgeting cannot reset unchanged persisted progress")

local function finish(thread)
    local result, count
    count = 0
    while coroutine.status(thread) ~= "dead" do
        local ok
        ok, result = resume(thread)
        assert(ok, result)
        count = count + 1
        assert(count < 10000)
    end
    return result
end
local function pendingSelection()
    state.lastVisibility = nil
    local thread = coroutine.create(function() return APR:CheckCurrentRouteUpToDate(nil, checkpoint) end)
    local count = 0
    repeat
        local ok, result = resume(thread)
        assert(ok and coroutine.status(thread) ~= "dead", result)
        count = count + 1
        assert(count < 10000)
    until state.lastVisibility == "b-shared"
    return thread
end
local function unchanged()
    assert(APRData.player["b-shared"] == 1 and APRData.player.RouteSignatures["b-shared"] == "unchanged"
        and APRZoneCompleted.player.Shared, "A retired lookup publishes no partial saved-state change")
end
local thread = pendingSelection()
catalogue["b-shared"].label = "Renamed while suspended"
assert(finish(thread) == false)
unchanged()
catalogue["b-shared"].label = "Shared"
assert(finish(coroutine.create(function() return APR:CheckCurrentRouteUpToDate(nil, checkpoint) end)))

thread = pendingSelection()
local previous = catalogue["b-shared"]
catalogue["b-shared"] = { label = "Shared", expansion = "Test", mapID = 80, steps = { {} } }
assert(finish(thread) == false, "Replacing even a same-label candidate retires its old observation")
unchanged()
catalogue["b-shared"] = previous
thread = pendingSelection()
local replacement = {}
for key, value in nativePairs(catalogue) do replacement[key] = value end
APR.RouteQuestStepList = replacement
assert(finish(thread) == false, "A replaced catalogue cannot publish the prior selection")
unchanged()
APR.RouteQuestStepList = catalogue

-- Exercise the production import writer while a lookup is suspended, including
-- a newly inserted better alias which was not among the old candidate refs.
function APR:DeepCopyTable(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, field in nativePairs(value) do copy[key] = self:DeepCopyTable(field) end
    return copy
end
APR.CATEGORIES, APR._customRouteUpdatePending = { Miscellaneous = "Test" }, true
thread = pendingSelection()
assert(APR:RegisterCustomRoute("0-imported", { label = "Shared", expansion = "Test", category = "Test", mapID = 90, steps = { {} } }))
keys[#keys + 1] = "0-imported"
assert(finish(thread) == false, "An imported better alias retires the scan before resuming its catalogue iterator")
unchanged()
local _, _, selected = APR:GetRouteMapIDsAndName("Shared")
assert(selected == "0-imported")
assert(finish(coroutine.create(function() return APR:CheckCurrentRouteUpToDate(nil, checkpoint) end)))
unchanged()
table.sort, pairs = nativeSort, nativePairs
print("Route labels: deterministic live aliases/visibility, no sorting, direct keys and budgeted completed-route scans passed")
