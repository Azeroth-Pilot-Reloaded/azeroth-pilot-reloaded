-- Run the real Dijkstra engine against a small, measurable ground-travel map.
local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
local widget
widget = setmetatable({}, { __index = function() return function() return widget end end })
widget.GetStringWidth = function() return 20 end
widget.GetStringHeight = function() return 20 end
function CreateFrame() return widget end
function CreateVector2D(x, y) return { x = x, y = y } end
function GetTime() return 100 end
function GetSubZoneText() return "Field" end
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, WOW_PROJECT_MISTS_CLASSIC = 99, 1, 19
Enum = { UIMapType = { Dungeon = 4, Continent = 2 },
    FlightPathState = { Current = 0, Reachable = 1, Unreachable = 2 } }
bit = { band = function(a) assert(a == 0); return 0 end }
C_Map = {
    GetMapInfo = function(id) return { mapID = id, mapType = id == 102 and 3 or 2, parentMapID = 101 } end,
    GetMapInfoAtPosition = function() return { mapID = 102, mapType = 3, parentMapID = 101 } end,
    GetAreaInfo = function() return "Sanctum" end,
    GetWorldPosFromMapPos = function(_, pos) return 0, CreateVector2D(pos.x * 10000, pos.y * 10000) end,
    GetMapPosFromWorldPos = function(_, pos) return 102, CreateVector2D(pos.x / 10000, pos.y / 10000) end,
}
local client = "forever"
APR = { PlayerID = "player", taxiData = {}, farstrider = { InvalidatePathCache = noop, ScheduleRouteCheck = noop } }
function APR:NewModule() return {} end
function APR:GetGameVersion() return client end
function APR:RegisterFontString() end
APRData = { player = {}, other = {} }
APRTaxiNodes = { player = {}, other = {} }
APRTaxiNodesTimer = {}
dofile("APR-Core/utils/NavigationUtils.lua")
dofile("APR-Core/features/navigation/Arrow.lua")
assert(APR.Arrow.MaxDistanceWrongZone == 1000)
client = "retail"
dofile("APR-Core/features/navigation/Arrow.lua")
assert(APR.Arrow.MaxDistanceWrongZone == 10000)
client = "forever"

local positions = { [1] = 100, [2] = 8000, [3] = 4500, [4] = 6000 }
local taxiAPI = {}
function APR.taxiData:GetAPI() return taxiAPI end
function APR.taxiData:GetNodeWorldPosition(id)
    if positions[id] then return { x = positions[id], y = 100, z = 0, instanceID = 0 } end
end
function APR.taxiData:GetNodeName(id) return "Node " .. id end
local usable = false
local transport = {
    id = "teleport", cost = 10,
    from = { flags = 0, type = 1, important = true, locaId = 1006,
        loc = { mapId = 102, isUI = true, pos = { x = 0.012, y = 0.01, z = 0 } },
        condition = function() return usable end },
    to = { flags = 0, type = 1, locaId = 1006,
        loc = { mapId = 102, isUI = true, pos = { x = 0.899, y = 0.01, z = 0 } } },
}
FarstriderLib = {
    Internal = true, Logger = { Info = noop, InfoGreen = noop, Error = noop, Warning = noop },
    Data = { WAYPOINTS = { transport },
        CONFIG = { ElevationOverrides = {}, MapTypeOverrides = {}, ContinentMapOverrides = {},
            IsolatedContinents = {}, IsolatedAreas = {} },
        GetLocalizedString = function(id) return id == 1001 and "Flight to %s" or "Transport" end },
}
assert(loadfile("APR-Core/libs/FarstriderLib/FarstriderLib~NavNode.lua"))("APR", FarstriderLib)
assert(loadfile("APR-Core/libs/FarstriderLib/FarstriderLib~Pathfinding.lua"))("APR", FarstriderLib)
dofile("APR-Core/integrations/ForeverTravel.lua")
local engine = FarstriderLib.Pathfinding
local function path(goal)
    return engine:FindPathBetweenLocations2(
        { mapId = 102, isUI = true, pos = { x = 0.01, y = 0.01, z = 0 } },
        { mapId = 102, isUI = true, pos = { x = goal or 0.9, y = 0.01, z = 0 } })
end
local function hasEdge(edges, id)
    for _, edge in ipairs(edges) do if edge.locaId == id then return true end end
    return false
end
local function observe(nodes)
    for _, node in ipairs(nodes) do
        if node.state == 0 or node.state == 1 then APRTaxiNodes[APR.PlayerID][node.nodeID] = true end
    end
    APR.foreverTravel:ObserveTaxiMap(nodes)
    APR.foreverTravel:RefreshGraph()
end
APR.foreverTravel:RefreshGraph()
local _, _, edges = path()
assert(not hasEdge(edges, 1001), "No taxis may be invented before a flight master is observed")
local total = 0
for _, edge in ipairs(edges) do total = total + edge.cost end
assert(math.abs(total - 8900 / 7) < 0.001, "The direct shortcut must use walking speed too")
local knownMap = {
    { nodeID = 1, state = 0, slotIndex = 1 },
    { nodeID = 2, state = 1, slotIndex = 2 },
    { nodeID = 3, state = 2, slotIndex = 3 },
    { nodeID = 4, state = 1, slotIndex = 4, isMapLayerTransition = true },
}
observe(knownMap)
assert(APRData.player.TaxiRoutes[1][2] and not APRData.player.TaxiRoutes[2], "Do not infer a reverse route")
assert(not APRData.player.TaxiRoutes[1][3] and not APRData.player.TaxiRoutes[1][4])
local optimized
optimized, _, edges = path()
assert(hasEdge(edges, 1001), "Long trips should use a known flight instead of walking")
assert(optimized[1].loca == "Flight to Node 2" and optimized[1].loc.pos.x == 0.01,
    "Guide to the departure master with a localized destination")
_, _, edges = path(0.8)
assert(hasEdge(edges, 1001), "A destination exactly on the arrival master must retain the flight")
local count = #FarstriderLib.Data.WAYPOINTS
observe(knownMap)
assert(#FarstriderLib.Data.WAYPOINTS == count, "Repeated observations must not duplicate flights")
_, _, edges = path(0.02)
assert(not hasEdge(edges, 1001), "A short walk should not cause a flight detour")

for _, kind in ipairs({ 1002, 1005, 1006 }) do
    transport.from.locaId = kind
    usable, transport.cost = true, 10
    engine:Rebuild()
    _, _, edges = path()
    assert(hasEdge(edges, kind) and not hasEdge(edges, 1001), "A usable faster teleport/item/spell must beat the taxi")
    transport.cost = 1000
    engine:Rebuild()
    _, _, edges = path()
    assert(hasEdge(edges, 1001), "A slower teleport must not beat the taxi")
    usable = false
    engine:Rebuild()
    _, _, edges = path()
    assert(hasEdge(edges, 1001) and not hasEdge(edges, kind), "Unavailable actions must be excluded")
end

knownMap[2].state = 2
observe(knownMap)
_, _, edges = path()
assert(not hasEdge(edges, 1001), "An explicitly unavailable flight must be removed, even if previously discovered")
knownMap[2].state = 1
knownMap[3].state = 1
observe(knownMap)
observe({ { nodeID = 3, state = 0, slotIndex = 1 }, { nodeID = 2, state = 1, slotIndex = 2 } })
APRTaxiNodesTimer["Node 1-Node 2"] = 1000
APRTaxiNodesTimer["Node 1-Node 3"] = 20
APRTaxiNodesTimer["Node 3-Node 2"] = 20
APR.foreverTravel.dirty = true
APR.foreverTravel:RefreshGraph()
optimized = path()
assert(optimized[1].loca == "Flight to Node 3" and optimized[1].loc.pos.x == 0.01,
    "Separate observed flights must keep the original departure and intermediate arrival")
assert(optimized[2].loca == "Flight to Node 2")

APR.PlayerID = "other"
APR.foreverTravel:RefreshGraph()
_, _, edges = path()
assert(not hasEdge(edges, 1001), "A different character must not inherit the flight network")
APR.PlayerID = "player"
APR.foreverTravel:RefreshGraph()
_, _, edges = path()
assert(hasEdge(edges, 1001), "Saved flights must be restored")
taxiAPI = nil
APR.foreverTravel:RefreshGraph()
_, _, edges = path()
assert(not hasEdge(edges, 1001), "Missing taxi coordinates must preserve the walking fallback")
client = "retail"
local originalRoutes = APRData.player.TaxiRoutes
APR.foreverTravel:ObserveTaxiMap({ { nodeID = 99, state = 0 }, { nodeID = 98, state = 1, slotIndex = 1 } })
assert(not originalRoutes[99], "Retail must not learn Forever routes")
engine:ChangeTravelCostMultiplier(1 / 31)
_, _, edges = path()
total = 0
for _, edge in ipairs(edges) do total = total + edge.cost end
assert(math.abs(total - 8900 / 31 * 0.8) < 0.001, "The default setter must keep the other clients' direct discount")
print("Forever travel: threshold, walking costs, observed taxis, availability, faster actions, transfers and character isolation passed")
