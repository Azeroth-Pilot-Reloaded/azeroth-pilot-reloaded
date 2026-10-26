local fixture = dofile("tests/lua/navigation_forever_fixture.lua")
local function point(map, x, y, z)
    return { instanceID = fixture:WorldForMap(map), uiMapID = map, x = x, y = y, z = z }
end
local connections = {
    { id = "fixture-boat", kind = "boat", from = point(1453, 5000, 5000), to = point(1439, 5000, 5000),
        seconds = 20, bidirectional = true, requirements = { faction = "Alliance" } },
    { id = "fixture-zeppelin", kind = "zeppelin", from = point(1420, 6070, 5880), to = point(1411, 5080, 1370),
        seconds = 20, bidirectional = true, requirements = { faction = "Horde" } },
    { id = "fixture-elevator", kind = "elevator", from = point(1420, 5000, 5000, 0), to = point(1458, 5000, 5000, 100),
        seconds = 15, arrivalZTolerance = 5, bidirectional = true },
}
local previous = point(1448, 6000, 500)
for index = 1, 4 do
    local target = point(index == 4 and 1452 or 1448, 6000 + index * 100, 500 + index % 2 * 100)
    target.noAutoconnect = index < 4
    connections[#connections + 1] = { id = "fixture-turn-" .. index, kind = "passage", costMode = "ground",
        from = previous, to = target }
    previous = target
end
local data = fixture:Load({ connections = connections, config = { IsolatedAreas = { [1452] = "exit", [1458] = "cellar" } } })
assert(data.profile == "forever")
assert(C_Map.GetMapArtID == nil and C_Map.GetMapRectOnMap == nil and C_PlayerInfo == nil and C_Housing == nil)
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local calls = 0
local originalBuild = data.CreateEdgeBuild
function data:CreateEdgeBuild(context)
    assert(context.connectionID, "Forever must not rebuild the entire catalogue for physical zone travel")
    calls = calls + 1
    return originalBuild(self, context)
end
data.env.getItemCount = function() error("Forever physical routes cannot scan optional items") end
local function point(map, x, y)
    return assert(data:NormalizeLocation({ space = "map", uiMapID = map, x = x or 0.5, y = y or 0.5 }))
end
local function create(start, goal)
    return APR.NavigationPlanner:Create({ preferZoneAccess = true, data = data,
        start = start, goal = goal, walkSpeed = 7, budget = 0,
        prepareSegment = function(edge) return edge end,
        adapter = { CreatePreparation = function() error("Unexpected Forever inn scan") end },
        taxiData = { BuildEdges = function() error("Unexpected Forever taxi scan") end },
        engine = { CreateSearch = function() error("Unexpected Forever coordinate-graph search") end } })
end
local function finish(job)
    for slice = 1, 200 do
        local status = job:Step(16, 1)
        if status ~= "planning" then return job, slice end
    end
    error("Forever zone routing exceeded its operation bound")
end
local alliance = finish(create(point(1453), point(1439)))
assert(alliance.status == "ready" and alliance.zoneRouted)
local boat = false
for _, edge in ipairs(alliance.result.segments) do
    if edge.kind == "boat" then
        boat = true
        assert(edge.id:find("forever:", 1, true) == 1 and edge.from.instanceID == 0 and edge.to.instanceID == 1)
    end
end
assert(boat, "Cross-world travel uses the eligible fixture boat")
local graph, oldCalls = data.zoneGraph, calls
local warm, slices = finish(create(point(1453), point(1439)))
assert(warm.status == "ready" and data.zoneGraph == graph and calls == oldCalls + 1 and slices <= 3,
    "A warm Forever objective reuses its index and prepares only the selected crossing")
fixture.faction, fixture.currentMap = "Horde", 1411
local horde = finish(create(point(1411, 0.508, 0.137), point(1420, 0.607, 0.588)))
assert(horde.status == "ready" and data.zoneGraph == graph)
local zeppelin = false
for _, edge in ipairs(horde.result.segments) do
    if edge.kind == "zeppelin" then
        zeppelin = true
        assert(edge.id == "forever:fixture-zeppelin:reverse", "Faction changes select the eligible fixture crossing")
    end
end
assert(zeppelin, "A fresh Horde snapshot must select a zeppelin without reusing Alliance access flags")

local tunnel = finish(create(point(1448, 0.6, 0.05), point(1452, 0.69, 0.23)))
assert(tunnel.status == "ready")
local turns = 0
for _, edge in ipairs(tunnel.result.segments) do
    if edge.id and edge.id:find("forever:fixture-turn-", 1, true) == 1 then turns = turns + 1 end
end
assert(turns == 4, "The optimized graph preserves every mandatory fixture turn")
local city = finish(create(point(1420), point(1458)))
assert(city.status == "ready")
local elevators = 0
for _, edge in ipairs(city.result.segments) do
    if edge.kind == "elevator" and edge.id:find("forever:fixture-elevator:", 1, true) == 1 then
        elevators = elevators + 1
        assert(edge.arrivalZTolerance == 5 and edge.from.z ~= edge.to.z)
    end
end
assert(elevators == 1, "The fixture cellar requires an explicit elevator")
oldCalls = calls
assert(finish(create(point(1411), point(1411, 0.6, 0.6))).status == "ready" and calls == oldCalls,
    "A local Forever objective bypasses all transport preparation")

-- No Retail access recipes may fill gaps in the independent Forever catalogue.
assert(#data.unlockRoutes == 0)
data.env.isQuestCompleted = function() return false end
data.env.isQuestActive = function() return false end
local unlock = data:CreateUnlockSession({ destination = point(1452), blockers = {
    { id = "unverified-forever-gate", blockedRequirements = { quest = 84957 } },
} })
local status
for _ = 1, 10 do status = unlock:Step(16, 1); if status ~= "planning" then break end end
assert(status == "missing_data", "Missing Forever acquisition evidence cannot select a Retail campaign")

local adapter = APR.NavigationAdapter
APR.navigation = { ForceRefresh = function() end }
for _ = 1, 100 do
    adapter.frame.OnEvent(adapter.frame, "QUEST_LOG_UPDATE")
    adapter.frame.OnEvent(adapter.frame, "BAG_UPDATE_DELAYED")
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_CLOSED")
end
assert(data.zoneGraph == graph, "Without map-art APIs, ordinary Forever events still retain static topology")
adapter.frame.OnEvent(adapter.frame, "QUEST_TURNED_IN", 1)
assert(data.zoneGraph == nil, "A possible phase transition remains conservative on clients without map art")
assert(finish(create(point(1411), point(1420))).status == "ready")
local pending = create(point(1411), point(1420))
pending:Step(1, 1); pending:Cancel()
assert(pending:Step(4096, 1) == "cancelled")
print("Forever performance: synthetic transports, warm index reuse, local bypass, mandatory barriers, profile isolation, legacy events and cancellation passed")
