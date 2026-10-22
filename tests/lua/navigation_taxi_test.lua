-- Standalone provider tests: quotes, snapshot isolation, probes and real arrivals.
local function noop() end
function LibStub() return { GetText = function(_, key) assert(key == "USE_FLIGHTPATH"); return "Fly to %s" end, GetLocale = function() return {
    USE_FLIGHTPATH = "Use Flightpath to %s", NAVIGATION_CONSULT_TAXI = "Consult the flight master",
} end } end
function CreateFrame() return { SetScript = noop } end
local clock, money, onTaxi, dead = 0, 100, false, false
local playerX, playerY, world = 0, 0, 0
function GetTime() return clock end
function GetMoney() return money end
function UnitOnTaxi() return onTaxi end
function UnitIsDeadOrGhost() return dead end
function UnitPosition() return playerX, playerY, 0, world end
local secret = {}
function issecretvalue(value) return value == secret end
APR = { PlayerID = "first", navigation = { InvalidatePathCache = noop, RequestUpdate = noop } }
function APR:NewModule() return {} end
function APR:GetGameVersion() return "forever" end
function APR:HasTaxiNode(node) return node == 1 or node == 2 or node == 3 end
APRData = { first = {}, second = {} }
Enum = { FlightPathState = { Current = 0, Reachable = 1, Unreachable = 2 } }
local source = { profile = "forever", build = "1.60.1.70205", paths = { fingerprint = "first" } }
local positions = { [1] = 0, [2] = 1000, [3] = 2000 }
local paths = {
    [11] = { fromNodeID = 1, toNodeID = 2, durationSeconds = 10, basePriceCopper = 200 },
    [12] = { fromNodeID = 2, toNodeID = 3, durationSeconds = 20, basePriceCopper = 50 },
}
local api = {
    GetSource = function() return source end,
    GetAllPaths = function() return paths end,
    GetNodeWorldPosition = function(id)
        return positions[id] and { x = positions[id], y = 0, z = 0, instanceID = 0, uiMapID = 100 }
    end,
    GetNodeName = function(id) return "Node " .. id end,
    IsNodeAvailable = function() return true end,
}
LibTaxiData_API = api
local prices = { [2] = 40, [3] = 80 }
local routes = { [2] = { 2 }, [3] = { 2, 3 } }
function TaxiNodeCost(slot) return prices[slot] end
function GetNumRoutes(slot) return #routes[slot] end
function TaxiGetNodeSlot(slot, index) return routes[slot][index] end
local nodes = {
    { nodeID = 1, state = 0, slotIndex = 1 },
    { nodeID = 2, state = 1, slotIndex = 2 },
    { nodeID = 3, state = 1, slotIndex = 3 },
}
dofile("APR-Core/features/navigation/NavigationTaxi.lua")
local taxi = APR.taxiData
local function find(edges, from, to)
    for _, edge in ipairs(edges) do if edge.fromNodeID == from and edge.toNodeID == to then return edge end end
end
local edges = taxi:BuildEdges()
assert(#edges == 2 and find(edges, 1, 2).copper == 200)
assert(find(edges, 1, 2).requiresVerification, "A base fare is never a live price guarantee")

taxi:ObserveTaxiMap(nodes)
nodes[2].name = "Comte-du-Lac"
assert(taxi:GetNodeName(2) == "Comte-du-Lac", "The live client label takes priority over a library translation")
assert(find(taxi:BuildEdges(), 1, 2).instruction == "Fly to Comte-du-Lac")
nodes[2].name = ""
assert(taxi:GetNodeName(2) == "Node 2", "An empty live name falls back to LibTaxiData")
local quote = assert(taxi:GetQuote(2, 1))
assert(quote.priceCopper == 40 and quote.signature == "1>2")
assert(taxi:GetQuote(2, 3) == nil, "A quote only applies at its departure master")
assert(taxi:CanTake(2))
assert(find(taxi:BuildEdges(), 1, 2).copper == 40, "Live discounted fares replace the base fare")
APR.NavigationEngine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
for _, budget in ipairs({80, 90}) do
    local search = APR.NavigationEngine:CreateSearch({ start = { x = 0, y = 0, instanceID = 0, uiMapID = 100 },
        goal = { x = 2000, y = 0, instanceID = 0, uiMapID = 100 }, budget = budget, edges = taxi:BuildEdges(),
        canWalk = function() return false end })
    local state, result
    repeat state, result = search:Step(64) until state ~= "planning"
    assert((budget == 80 and state == "no_path") or (budget == 90 and state == "ready" and result.totalCopper == 90),
        "The live first fare plus the second fare must respect the cumulative journey budget")
end
prices[2] = 120
assert(not taxi:CanTake(2), "A changed price is checked immediately before payment")
prices[2] = 0
assert(taxi:CanTake(2) and taxi:GetQuote(2).priceCopper == 0, "A true free fare is valid")
for _, invalid in ipairs({ -1, secret, 0 / 0, math.huge }) do
    prices[2] = invalid
    assert(taxi:GetQuote(2) == nil and not taxi:CanTake(2))
    assert(not find(taxi:BuildEdges(), 1, 2), "A live unknown fare must not reuse a base fare as a quote")
end
prices[2] = nil
assert(not taxi:CanTake(2), "Missing price never means free")
prices[2] = 40
taxi:CloseTaxiMap()
assert(taxi:GetQuote(2) == nil and not taxi:CanTake(2), "Closing the map invalidates every quote")
assert(find(taxi:BuildEdges(), 1, 2).copper == 200, "Persisted discounts are not reused as live prices")

local start = { x = 0, y = 0, instanceID = 0 }
local goal = { x = 1000, y = 0, instanceID = 0 }
local options = { contextKey = "route:1:revision", walkSpeed = 7, canWalk = function() return true end }
local probe = assert(taxi:FindProbe(start, goal, 200, options))
assert(probe.fromNodeID == 1 and probe.toNodeID == 2 and probe.to == probe.from)
assert(probe.kind == "verify_taxi", "A probe ends at the departure, never an imaginary flight arrival")
taxi:MarkProbeAttempt(1, 2, options.contextKey)
start.x = 40
assert(not taxi:FindProbe(start, goal, 200, options), "Moving must not reset an unsuccessful probe")
options.contextKey = "route:2:revision"
assert(taxi:FindProbe(start, goal, 200, options), "A new objective can verify its options again")
options.canWalk = function() return false end
assert(not taxi:FindProbe(start, goal, 200, options), "A probe cannot cross an inaccessible ground region")
options.canWalk = function() return true end
assert(not taxi:FindProbe(start, goal, 5, options), "A faster confirmed route suppresses taxi detours")

taxi:ObserveTaxiMap(nodes)
taxi:StartMeasurement(2)
clock = 11; taxi:PollMeasurement()
assert(not taxi.measurement, "A failed boarding request expires before an unrelated later flight")
clock = 20; taxi:StartMeasurement(2)
clock = 21; onTaxi = true; taxi:PollMeasurement(); taxi:CloseTaxiMap()
clock = 51; onTaxi = false; playerX = 1000; taxi:PollMeasurement()
assert(taxi:GetMeasuredDuration(1, 2) == 30, "Only time airborne through a valid arrival is recorded")
assert(taxi:GetMeasuredDuration(1, 2, "1>3>2") == nil, "A different route sequence cannot inherit a measurement")
taxi:ObserveTaxiMap(nodes); clock = 60; taxi:StartMeasurement(3)
onTaxi = true; clock = 61; taxi:PollMeasurement()
onTaxi = false; playerX = 500; clock = 75; taxi:PollMeasurement()
assert(taxi:GetMeasuredDuration(1, 3, "1>2>3") == nil, "An aborted flight does not become a complete duration")

local originalData = taxi:GetCharacterData()
APR.PlayerID = "second"
assert(taxi:GetMeasuredDuration(1, 2) == nil and taxi:GetQuote(2) == nil, "Characters share neither quotes nor durations")
APR.PlayerID = "first"
assert(taxi:GetCharacterData() == originalData)
source.paths.fingerprint = "changed-manual-correction"
assert(taxi:GetMeasuredDuration(1, 2) == nil and taxi:GetQuote(2) == nil,
    "Same-build data corrections create a new snapshot")
source.paths.fingerprint = "first"
assert(taxi:GetMeasuredDuration(1, 2) == 30, "Returning to a snapshot recovers its own measurements")

paths[13] = { fromNodeID = 1, toNodeID = 2, durationSeconds = 55, basePriceCopper = 40 }
taxi:InvalidateStaticCache() -- The fixture mutates a catalog that LibTaxiData publishes as immutable.
taxi:CloseTaxiMap()
local variants = {}
for _, edge in ipairs(taxi:BuildEdges()) do if edge.pathID then variants[edge.pathID] = edge.seconds end end
assert(variants[11] == 25 and variants[13] == 70,
    "An endpoint observation never overwrites two unidentified parallel DB2 path variants")
taxi:ObserveTaxiMap(nodes)
local observed
for _, edge in ipairs(taxi:BuildEdges()) do if edge.id == "offer:1:2" then observed = edge end end
assert(observed and observed.seconds == 45 and not observed.pathID,
    "A measured live itinerary remains usable as its own edge without inventing a DB2 path identity")
paths[13] = nil
paths[13] = { fromNodeID = 1, toNodeID = 3, durationSeconds = 9, basePriceCopper = 5 }
taxi:InvalidateStaticCache()
local direct, whole
for _, edge in ipairs(taxi:BuildEdges()) do
    if edge.pathID == 13 then direct = edge end
    if edge.id == "offer:1:3" then whole = edge end
end
assert(not direct and not whole, "A multi-stop live quote must not be combined with an unrelated direct-path duration")
taxi:GetCharacterData().durations["1>2>3"] = { seconds = 90 }
for _, edge in ipairs(taxi:BuildEdges()) do
    assert(edge.pathID ~= 13, "The static direct variant remains unavailable while the client offers a different journey")
    if edge.id == "offer:1:3" then whole = edge end
end
assert(whole and whole.seconds == 105 and whole.copper == 80 and not whole.pathID,
    "A measured multi-stop offer retains its matching whole-journey price and duration")
paths[13], taxi:GetCharacterData().durations["1>2>3"] = nil, nil
taxi:InvalidateStaticCache()

taxi:CloseTaxiMap()
local originalPaths, positionReads, availabilityReads = paths, 0, 0
local originalPosition, originalAvailable = api.GetNodeWorldPosition, api.IsNodeAvailable
api.GetNodeWorldPosition = function(id) positionReads = positionReads + 1; return originalPosition(id) end
api.IsNodeAvailable = function(id) availabilityReads = availabilityReads + 1; return originalAvailable(id) end
paths = {}
for id = 1, 4000 do paths[id] = { fromNodeID = 1, toNodeID = 2, durationSeconds = 20, basePriceCopper = 20 } end
local started = os.clock()
edges = taxi:BuildEdges()
assert(#edges == 4000 and positionReads == 2 and availabilityReads == 2,
    "Large catalogs resolve coordinates and character conditions once per node, not once per edge")
print(string.format("Navigation taxi 4000-path provider: %.4fs; 2 position/availability reads", os.clock() - started))
paths, api.GetNodeWorldPosition, api.IsNodeAvailable = originalPaths, originalPosition, originalAvailable

api.GetAllPaths = nil
taxi:CloseTaxiMap()
local metadata
edges, metadata = taxi:BuildEdges()
assert(#edges == 0 and metadata.taxiUnavailable and not metadata.waitingData,
    "An older LibTaxiData degrades only taxi optimisation, without blocking local navigation")
-- Boolean legacy discoveries keep their evidence without invented prices or timing.
APRData[APR.PlayerID].TaxiRoutes = { [1] = { [2] = true } }
local oldVersion = APR.GetGameVersion
function APR:GetGameVersion() return "forever" end
local legacy = taxi:GetCharacterData()
legacy.legacyMigrated = nil
legacy.offers = {}
legacy = taxi:GetCharacterData()
assert(legacy.offers[1][2].legacy and legacy.offers[1][2].priceCopper == nil)
APR.GetGameVersion = oldVersion
LibTaxiData_API = nil
edges, metadata = taxi:BuildEdges()
assert(#edges == 0 and metadata.taxiUnavailable and not metadata.waitingData)
print("Navigation taxi quotes, probes, snapshots and arrival timings: OK")
