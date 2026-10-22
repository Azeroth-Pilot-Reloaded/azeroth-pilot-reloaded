-- Exercise the reusable library with the real LibStub and a standard-Lua-only
-- sandbox. Looking up APR, frames or a WoW global here is an immediate failure.
local sandbox = {
    assert = assert, error = error, ipairs = ipairs, pairs = pairs, next = next,
    type = type, tonumber = tonumber, tostring = tostring, select = select,
    pcall = pcall, xpcall = xpcall, unpack = unpack, rawget = rawget, rawset = rawset,
    setmetatable = setmetatable, getmetatable = getmetatable,
    math = math, string = string, table = table,
    -- The shipped LibStub uses Blizzard's historical alias for string.match.
    strmatch = string.match,
}
sandbox._G = sandbox
local function loadModule(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, sandbox)
    return chunk()
end
loadModule("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
setmetatable(sandbox, { __index = function(_, key) error("Unexpected global dependency: " .. tostring(key)) end })
for _, name in ipairs({ "Core", "Locales", "Conditions", "Diagnostics", "Geography", "Catalog", "Search" }) do
    loadModule("APR-Core/libs/LibAPRNavigation-1.0/" .. name .. ".lua")
end
local library = assert(sandbox.LibStub("LibAPRNavigation-1.0"))
assert(rawget(sandbox, "APR") == nil and rawget(sandbox, "CreateFrame") == nil and rawget(sandbox, "C_Map") == nil)

local function Point(x, map, region)
    return { x = x, y = 0, instanceID = 0, uiMapID = map or 10, region = region }
end
local function Connection(id, from, to, seconds, copper)
    return { id = id, from = from, to = to, seconds = seconds, copper = copper, kind = "portal" }
end
local function Environment(tag)
    local state = { character = { faction = "Alliance", class = "MAGE", raceID = 1, level = 40,
            mapID = 10, inGroup = false, indoors = false, inInstance = false },
        quests = {}, counts = {}, usable = {}, dynamic = {}, projections = 0, mapReads = 0, tag = tag }
    local env = {
        getCharacter = function() return state.character end,
        isQuestCompleted = function(id) return state.quests[id] end,
        getItemCount = function(id) return state.counts[id] end,
        getActionUsability = function(kind, id)
            local value = state.usable[kind .. ":" .. id]
            if value == nil then return false, "unknown" end
            if value == "pending" then return false, "pending_data" end
            return value
        end,
        getDynamicPosition = function(kind) return state.dynamic[kind] end,
        getText = function(key) return key == "UNKNOWN" and tag .. " unknown" or key .. " %s" end,
        getItemName = function(id) return tag .. " item " .. id end,
        getSpellName = function(id) return tag .. " spell " .. id end,
        getSpellInfo = function() return { castTime = 10000 } end,
        getAreaName = function(id) return id == 42 and tag .. " precise dock" end,
        getMapInfo = function(id)
            state.mapReads = state.mapReads + 1
            if state.mapsMissing then return nil end
            if id == 1 then return { mapID = 1, mapType = 2, parentMapID = 0, name = state.tag .. " continent" } end
            if id == 999 then return { mapID = 999, mapType = 3, parentMapID = 999 } end
            if id == 12 then return { mapID = 12, mapType = 5, parentMapID = 10, name = state.tag .. " cave" } end
            if id == 10 or id == 20 or id == 30 then
                return { mapID = id, mapType = 3, parentMapID = 1, name = state.tag .. " map " .. id }
            end
        end,
        mapToWorld = function(map, x, y)
            state.projections = state.projections + 1
            if state.projectionMissing then return nil end
            return 0, x * 1000 + map, y * 1000
        end,
        worldToMap = function() return 10 end,
    }
    return env, state
end
local envA, stateA = Environment("consumer A")
local envB, stateB = Environment("consumer B")
local origin, target = Point(0), Point(100, 20)
local data = { config = { threshold = 2000, IsolatedAreas = { [20] = "restricted" } },
    connections = { Connection("portal", origin, target, 7, 5) },
    bindings = { [42] = Point(55) } }
library:RegisterData("retail", "world", data)
library:RegisterData("forever", "world", { config = { threshold = 1234 },
    connections = { Connection("older-world", Point(200), Point(300), 40, 0) } })
-- Registration detaches data from the exporter before either instance is made.
data.connections[1].seconds = 900
data.bindings[42].x = 900
local a = library:New({ profile = "retail", environment = envA })
local b = library:New({ profile = "retail", environment = envB })
local forever = library:New({ profile = "forever", environment = envA })
local originalMap = stateA.character.mapID
a:GetBlockedRouteText({ { from = { uiMapID = 20 }, blockedRequirements = { quest = 123 } } })
assert(stateA.character.mapID == originalMap, "Formatting failures cannot mutate the consumer's character snapshot")
assert(a:GetProfile().threshold == 2000 and forever:GetProfile().threshold == 1234)
assert(a:GetConnections()[1].seconds == 7 and a:GetBindings()[42].x == 55)
assert(forever:GetConnections()[1].id == "older-world", "Permanent profiles retain separate coordinate datasets")
a:GetConnections()[1].from.x = 999
assert(b:GetConnections()[1].from.x == 0, "Consumer mutation must not change a second instance's connections")
a:GetBindings()[42].x = 999
assert(b:GetBindings()[42].x == 55, "Binding state must not be shared by consumers")
a:GetConfig().IsolatedAreas[20] = "changed by A"
assert(b:GetConfig().IsolatedAreas[20] == "restricted")

local unknown = library:New({ profile = "missing", environment = envA })
local missingEdges, missingMeta = unknown:BuildEdges({})
assert(not unknown:GetProfile() and #missingEdges == 0 and missingMeta.waitingData and missingMeta.reason == "unsupported_client")
library:RegisterData("empty", "world", { connections = {} })
local empty = library:New({ profile = "empty", environment = envA })
local noEdges, emptyMeta = empty:BuildEdges({})
assert(#noEdges == 0 and not emptyMeta.waitingData, "A valid empty dataset is different from an unsupported profile")
local _, wrongProfile = b:BuildEdges({ profile = "forever" })
assert(wrongProfile.waitingData and wrongProfile.reason == "profile_mismatch")

-- Declarative requirements use true/false/unknown without invoking code from data.
local phase = { mapArt = { mapID = 10, artID = 7 } }
assert(a:CheckRequirements(phase, stateA.character) == nil, "Unknown phases must not open their portals")
envA.getMapArtID = function(id) return id == 10 and 7 or nil end
assert(a:CheckRequirements(phase, stateA.character) == true)
envA.getMapArtID = function() return 8 end
assert(a:CheckRequirements(phase, stateA.character) == false, "Portals belong to a specific world phase")
assert(a:CheckRequirements({ mapArt = { mapID = 10 } }, stateA.character) == false)
envA.getMapArtID = nil
assert(b:CheckRequirements({ faction = "Alliance", class = "MAGE", minLevel = 40, maxLevel = 40 }, stateA.character))
assert(not b:CheckRequirements({ faction = "Horde" }, stateA.character))
assert(b:CheckRequirements({ quest = 1 }, stateA.character) == nil)
stateA.quests[1], stateA.quests[2] = true, false
assert(b:CheckRequirements({ quest = 1 }, stateA.character) == nil,
    "A second environment must not read consumer A's quest state")
assert(a:CheckRequirements({ quest = 1 }, stateA.character) == true)
assert(a:CheckRequirements({ all = { { quest = 1 }, { quest = 3 } } }, stateA.character) == nil)
assert(a:CheckRequirements({ all = { { quest = 2 }, { quest = 3 } } }, stateA.character) == false)
assert(a:CheckRequirements({ any = { { quest = 1 }, { quest = 3 } } }, stateA.character) == true)
assert(a:CheckRequirements({ any = { { quest = 2 }, { quest = 3 } } }, stateA.character) == nil)
assert(a:CheckRequirements({ notCondition = { quest = 3 } }, stateA.character) == nil)
assert(a:CheckRequirements({ questsAny = { 1, 2 }, questsAll = { 1 }, maps = { 10, 12 },
    notMaps = { 20 }, outdoors = true, notInstance = true, inGroup = false }, stateA.character))
local rejected, reason = a:CheckRequirements({ arbitraryLua = "return true" }, stateA.character)
assert(rejected == false and reason == "unknown_requirement:arbitraryLua")
for _, requirements in ipairs({ { minLevel = "bad" }, { all = true }, { maps = false }, "not a table",
    false, { all = { false } }, { any = { false } }, { notCondition = "not a table" },
    { notCondition = { arbitraryLua = "return true" } } }) do
    local ok, allowed = pcall(a.CheckRequirements, a, requirements, stateA.character)
    assert(ok and allowed == false, "Malformed requirements fail closed without a runtime exception")
end
local functionsRejected = not pcall(library.RegisterData, library, "bad", "functions", { conditions = function() return true end })
assert(functionsRejected, "Exported executable conditions are never accepted")
local cycle = {}; cycle.self = cycle
assert(not pcall(library.RegisterData, library, "bad", "cycle", cycle))
for index, connection in ipairs({
    Connection("bad-number", Point(0 / 0), target, 1, 0),
    Connection("bad-number", Point(math.huge), target, 1, 0),
    Connection("bad-duration", origin, target, -1, 0),
    Connection("bad-fare", origin, target, 1, -1),
}) do
    assert(not pcall(library.RegisterData, library, "bad", "typed-" .. index, { connections = { connection } }),
        "Invalid endpoint numbers, durations and fares are rejected when registering data")
end
local signedFrom = { x = -100, y = -50, instanceID = 0, uiMapID = 10 }
library:RegisterData("signed", "world", { connections = { Connection("signed-world", signedFrom, target, 1, 0) } })
assert(library:New({ profile = "signed", environment = envA }):GetConnections()[1].from.y == -50,
    "Finite negative world coordinates remain valid")
library:RegisterData("duplicates", "one", { connections = { Connection("same", origin, target, 1, 0) } })
library:RegisterData("duplicates", "two", { connections = { Connection("same", origin, target, 2, 0) } })
assert(not pcall(library.New, library, { profile = "duplicates", environment = envA }))

-- Exact environment-provided names and cached projections; failed client
-- lookups are retried, and invalidating one consumer leaves the other alone.
assert(a:GetDisplayMapName({ uiMapID = 10 }) == "consumer A map 10")
assert(b:GetDisplayMapName({ uiMapID = 10, areaID = 42 }) == "consumer B precise dock")
stateA.tag = "updated live name"
assert(a:GetDisplayMapName({ uiMapID = 10 }) == "updated live name map 10", "Display names remain authoritative live data")
local mapPosition = { space = "map", uiMapID = 10, x = 0.2, y = 0.3 }
local first = a:ResolvePosition(mapPosition, {})
local before = stateA.projections
assert(first.x == 210 and first.y == 300 and a:ResolvePosition(mapPosition, {}) == first and stateA.projections == before)
assert(b:ResolvePosition(mapPosition, {}) ~= first and stateB.projections == 1)
a:InvalidatePositionCache()
assert(a:ResolvePosition(mapPosition, {}) ~= first and stateA.projections == before + 1)
stateA.projectionMissing = true
local delayed = { space = "map", uiMapID = 10, x = 0.4, y = 0.5 }
assert(not a:ResolvePosition(delayed, {}))
stateA.projectionMissing = false
assert(a:ResolvePosition(delayed, {}), "Missing client geometry is retried after loading")
assert(not a:NormalizeLocation({ space = "map", uiMapID = 10, x = 1.1, y = 0.5 }))
assert(not a:NormalizeLocation({ instanceID = 0, x = 0 / 0, y = 0 }))
assert(a:GetPositionRegion(Point(1, 999)) == nil)
assert(b:CanWalk(Point(0, 10), Point(1, 12)), "A cave shares its accessible parent")
assert(not b:CanWalk(Point(0, 10), Point(1, 20)), "Declared isolation wins over common map ancestry")
local otherWorld = Point(1, 10); otherWorld.instanceID = 1
assert(not b:CanWalk(Point(0, 10), otherWorld))

-- End-to-end action selection and resource annotations are supplied by the
-- library, while character and item/spell observations remain environment-owned.
local personal = Connection("mage", { dynamic = "player" }, Point(900, 20), 1, 0)
personal.actions = { { type = "spell", id = 100, reagentID = 500, groupSpellID = 101, groupReagentID = 501 } }
local hearthA = Connection("stone-a", Point(0), Point(10), 1, 0)
hearthA.actions, hearthA.cooldownGroup = { { type = "item", id = 200, consumable = true } }, "hearthstone"
local hearthB = Connection("stone-b", Point(10), Point(20), 1, 0)
hearthB.actions, hearthB.cooldownGroup = { { type = "item", id = 201, consumable = true } }, "hearthstone"
library:RegisterData("actions", "world", { connections = { personal, hearthA, hearthB } })
local actions = library:New({ profile = "actions", environment = envA })
stateA.usable["spell:100"], stateA.usable["spell:101"] = true, true
stateA.usable["item:200"], stateA.usable["item:201"] = true, true
stateA.counts[500], stateA.counts[501], stateA.counts[200], stateA.counts[201] = 1, 2, 1, 1
local player = Point(77)
local actionEdges, meta = actions:BuildEdges({ playerPosition = player })
assert(#actionEdges == 3 and actionEdges[1].sourceFree and actionEdges[1].action.data == 100)
assert(actionEdges[1].seconds == 10 and actionEdges[1].resources["item:500"] == 1 and meta.resources["item:500"] == 1)
local timed = library.Copy(personal)
timed.seconds = nil
library:RegisterData("timing", "personal", { connections = { timed },
    config = { actionLoadingSeconds = 5, defaultSpellCastSeconds = 10 } })
envA.getActionCastSeconds = function() return 2 end
local timings = library:New({ profile = "timing", environment = envA })
local timedEdges = timings:BuildEdges({ playerPosition = player })
assert(timedEdges[1].seconds == 7 and timedEdges[1].durationSource == "client-cast-estimated-loading",
    "Client cast duration replaces a fallback weight while loading remains an explicit estimate")
envA.getActionCastSeconds = function() return nil end
timedEdges = timings:BuildEdges({ playerPosition = player })
assert(timedEdges[1].seconds == 15 and timedEdges[1].durationSource == "profile-estimate")
envA.getActionCastSeconds = nil
local portal = Connection("estimated-portal", Point(0), Point(30), nil, 0)
portal.waitSeconds = 2
local measuredPortal = Connection("measured-portal", Point(0), Point(30), 0, 0)
measuredPortal.durationSource = "measured"
library:RegisterData("portal-timing", "world", { connections = { portal, measuredPortal },
    config = { actionLoadingSeconds = 5 } })
local portalTimings = library:New({ profile = "portal-timing", environment = envA })
local portalEdges = portalTimings:BuildEdges({ playerPosition = player })
assert(portalEdges[1].seconds == 7 and portalEdges[1].durationSource == "profile-estimated-loading",
    "Unknown portal durations use the common loading estimate plus any explicit wait")
assert(portalEdges[2].seconds == 0 and portalEdges[2].durationSource == "measured",
    "An explicit zero duration and its measured provenance must survive estimation")
portalTimings.config.actionLoadingSeconds = 9
portalEdges = portalTimings:BuildEdges({ playerPosition = player })
assert(portalEdges[1].seconds == 11 and portalEdges[2].seconds == 0,
    "Changing the loading estimate affects only unmeasured portal durations")
assert(actionEdges[1].instruction:find("consumer A spell 100", 1, true))
local groupEdges = actions:BuildEdges({ playerPosition = player, inGroup = true })
assert(groupEdges[1].action.data == 101 and groupEdges[1].resources["item:501"] == 1)
assert(actions:GetActionUsability("spell", 101) == false, "A group-only portal cannot be used by a solo character")
stateA.counts[500] = 0
actionEdges = actions:BuildEdges({ playerPosition = player })
assert(#actionEdges == 2, "Missing teleport reagents remove the personal action")
stateA.counts[500] = nil
local _, pendingReagent = actions:BuildEdges({ playerPosition = player })
assert(pendingReagent.waitingData)
stateA.counts[500] = 1
stateA.usable["spell:100"] = "pending"
local _, pendingSpell = actions:BuildEdges({ playerPosition = player })
assert(pendingSpell.waitingData)
stateA.usable["spell:100"] = true
local unknownRequirements = Connection("quest-gated", origin, target, 1, 0)
unknownRequirements.requirements = { quest = 3 }
library:RegisterData("pending", "world", { connections = { unknownRequirements } })
local pending = library:New({ profile = "pending", environment = envA })
local gated, gateMeta = pending:BuildEdges({})
assert(#gated == 0 and gateMeta.waitingData, "Unknown requirements never publish an unlocked edge")

local function NeverWalk() return false end
local function Finish(instance, options)
    local search = instance:CreateSearch(options)
    local status, result, calls = nil, nil, 0
    repeat
        status, result = search:Step(16)
        calls = calls + 1
        assert(calls < 1000, "Tiny graph search did not terminate")
    until status ~= "planning"
    return status, result, search
end
local p, q, r, goal = Point(0, 10, "p"), Point(1, 10, "q"), Point(2, 10, "r"), Point(3, 10, "goal")
local function Edge(id, from, to, seconds, copper, resources)
    return { id = id, from = from, to = to, seconds = seconds, copper = copper, resources = resources, kind = "portal" }
end
local limited = Connection("map-limited-item", { dynamic = "player" }, Point(1200, 20), 1, 0)
limited.requirements, limited.actions = { mapID = 10, minLevel = 40 }, { { type = "item", id = 203, consumable = true } }
stateA.usable["item:203"], stateA.counts[203] = true, 1
library:RegisterData("limited", "world", { connections = { limited } })
local limitedInstance = library:New({ profile = "limited", environment = envA })
local limitedEdges, limitedMeta = limitedInstance:BuildEdges({ playerPosition = Point(0, 10) })
assert(#limitedEdges == 1 and limitedEdges[1].canStart(Point(0, 10)),
    "The map-limited item is offered while its current departure condition is satisfied")
stateA.character.level = 20
assert(limitedEdges[1].canStart(Point(0, 10)) and not limitedEdges[1].canStart(Point(0, 10), true),
    "Retained edges can revalidate live character requirements independently of their search snapshot")
stateA.character.level = nil
assert(limitedEdges[1].canStart(Point(0, 10), true) == nil, "Missing live requirements remain unknown")
stateA.character.level = 40
local changedMap = Point(600, 30)
local portal = Edge("changes-map", Point(0, 10), changedMap, 0, 0)
local firstLeg, firstResult = Finish(limitedInstance, { start = portal.from, goal = changedMap,
    edges = { portal, limitedEdges[1] }, resources = limitedMeta.resources, canWalk = NeverWalk })
assert(firstLeg == "ready" and firstResult.segments[1].id == "changes-map")
local afterPortal = firstResult.segments[1].to
assert(not limitedEdges[1].canStart(afterPortal))
local continuation = Finish(limitedInstance, { start = afterPortal, goal = limitedEdges[1].to,
    edges = limitedEdges, resources = limitedMeta.resources, canWalk = NeverWalk })
assert(continuation == "no_path",
    "An item offered before a portal cannot be reused from a simulated departure on a forbidden map")

-- The opposite journey must work too: an item restricted to map 10 can be
-- planned after a transfer there, even though the character starts on map 30.
stateA.character.mapID = 30
local futureEdges, futureMeta = limitedInstance:BuildEdges({ playerPosition = changedMap })
assert(#futureEdges == 1 and not futureEdges[1].canStart(changedMap))
local toAllowedMap = Edge("arrives-on-allowed-map", changedMap, Point(0, 10), 2, 0)
local futureStatus, futureResult = Finish(limitedInstance, { start = changedMap, goal = futureEdges[1].to,
    edges = { toAllowedMap, futureEdges[1] }, resources = futureMeta.resources, canWalk = NeverWalk })
assert(futureStatus == "ready" and #futureResult.segments == 2 and futureResult.totalSeconds == 3,
    "Do not reject a future usable departure because its map differs from the initial player map")

local nested = { notCondition = { any = { { mapID = 30 }, { quest = 1 } } } }
stateA.quests[1] = false
assert(limitedInstance:CheckPlanningRequirements(nested, stateA.character) == true)
stateA.quests[1] = true
assert(limitedInstance:CheckPlanningRequirements(nested, stateA.character) == false,
    "Changing departure map cannot negate a completed quest")
stateA.quests[1] = nil
assert(limitedInstance:CheckPlanningRequirements(nested, stateA.character) == nil,
    "Unknown quest flags remain unknown even when map predicates are deferred")
assert(limitedInstance:CheckPlanningRequirements({ all = { { mapID = 10 }, { notMaps = { 10 } } } }, stateA.character) == false,
    "Contradictory map predicates cannot become a possible future departure")

local fixed = Connection("fixed-map-gate", Point(0, 10), Point(10, 20), 2)
fixed.requirements, fixed.bidirectional = { mapID = 10, minLevel = 40 }, true
library:RegisterData("fixed-map", "world", { connections = { fixed } })
local fixedInstance = library:New({ profile = "fixed-map", environment = envA })
local fixedEdges = fixedInstance:BuildEdges({ playerPosition = changedMap })
assert(#fixedEdges == 1 and fixedEdges[1].id == "fixed-map:fixed-map-gate:forward",
    "Each fixed direction checks its own entrance map, including before the player reaches it")
stateA.character.mapID, stateA.quests[1] = 10, true

local status, result = Finish(a, { start = p, goal = goal, budget = 10, canWalk = NeverWalk, edges = {
    Edge("fast-expensive", p, q, 1, 9), Edge("slow-free", p, r, 2, 0),
    Edge("free-transfer", r, q, 1, 0), Edge("final-fare", q, goal, 1, 5) } })
assert(status == "ready" and result.totalSeconds == 4 and result.totalCopper == 5,
    "Cheaper labels survive a faster arrival so cumulative fares remain affordable")
status = Finish(a, { start = p, goal = goal, budget = 4, canWalk = NeverWalk, edges = { Edge("fare", p, goal, 1, 5) } })
assert(status == "no_path")
status, result = Finish(a, { start = p, goal = goal, resources = { reagent = 1 }, canWalk = NeverWalk, edges = {
    Edge("uses-reagent", p, q, 1, 0, { reagent = 1 }), Edge("preserves", p, r, 2, 0),
    Edge("transfer", r, q, 1, 0), Edge("requires-reagent", q, goal, 1, 0, { reagent = 1 }) } })
assert(status == "ready" and result.totalSeconds == 4 and result.resourcesUsed.reagent == 1)
actionEdges, meta = actions:BuildEdges({ playerPosition = player })
local stones = { actionEdges[2], actionEdges[3] }
status = Finish(actions, { start = Point(0), goal = Point(20), edges = stones, resources = meta.resources, canWalk = NeverWalk })
assert(status == "no_path", "Different hearthstone items still share one cooldown budget")
local completed
status, result, completed = Finish(a, { start = p, goal = p, edges = {}, canWalk = NeverWalk })
assert(status == "ready" and #result.segments == 0 and result.totalCopper == 0)
completed:Cancel()
assert(completed:Step(1) == "ready" and completed:GetResult() == result,
    "Cancelling after completion preserves the result already returned to the consumer")
status = Finish(a, { start = p, goal = goal, edges = {}, canWalk = NeverWalk })
assert(status == "no_path")
status = Finish(a, { start = p, goal = goal, edges = {
    Edge("negative", p, goal, -1, 0), Edge("nan", p, goal, 0 / 0, 0),
    Edge("infinite-fare", p, goal, 1, math.huge), { from = p, seconds = 1 },
}, canWalk = NeverWalk })
assert(status == "no_path", "Malformed, negative and non-finite edges cannot enter the graph")
for _, malformed in ipairs({ false, 3, "not an edge", { from = p, to = goal, seconds = 1, resources = 3 } }) do
    local ok, malformedStatus = pcall(Finish, a, { start = p, goal = goal,
        edges = { malformed }, canWalk = NeverWalk })
    assert(ok and malformedStatus == "no_path", "Malformed edges fail closed without crashing an incremental search")
end
local search = a:CreateSearch({ start = p, goal = goal, canWalk = NeverWalk, edges = { Edge("ab", p, q, 1, 0) } })
assert(search:Step(1) == "planning")
search:Cancel()
assert(search:Step(100) == "cancelled" and not search:GetResult())
assert(next(search.heap) == nil and next(search.labels) == nil and search.pending == nil,
    "Cancellation releases the label graph and pending cursor")
assert(rawget(sandbox, "APR") == nil and rawget(sandbox, "CreateFrame") == nil)
print("Navigation library: real LibStub without WoW/APR globals, independent consumers/profiles, declarative gates, API geometry/names/cache, cumulative budgets/resources and malformed graph handling passed")
