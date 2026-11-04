-- A coarse indoor walking hint cannot beat a proved floor/stair route.
local function run(withGeometry, includeEntrance)
    local fixture = dofile("tests/lua/navigation_fixture.lua")
    local function p(x, y, z, access)
        return { space = "world", instanceID = 0, uiMapID = 501, x = x, y = y, z = z, accessKey = access }
    end
    local outside = p(-10, 0, 100)
    outside.noAutoconnect = true
    local entrance, goal = p(0, 0, 0, "room"), p(30, 0, 10, "room")
    local connections = { { id = "indoor-hint", kind = "passage", terrainWalk = true,
        from = entrance, to = goal, seconds = 5 } }
    if includeEntrance then connections[#connections + 1] = { id = "entry-crossing", kind = "passage",
        from = outside, to = entrance, seconds = 2 } end
    local data = fixture:Load({ connections = connections })
    local lib = LibStub("LibAPRNavigation-1.0")
    if withGeometry then
        lib:RegisterTerrainData("retail", 0, { format = 1, nodes = {
            { id = "entry", x = 0, y = 0, z = 0, uiMapID = 501, accessKey = "room" },
            { id = "corner", x = 0, y = 40, z = 0, uiMapID = 501, accessKey = "room" },
            { id = "stairs", x = 30, y = 40, z = 10, uiMapID = 501, accessKey = "room" },
            { id = "goal", x = 30, y = 0, z = 10, uiMapID = 501, accessKey = "room" },
        }, edges = {
            { from = "entry", to = "corner", mode = "ground", seconds = 10 },
            { from = "corner", to = "stairs", mode = "ground", seconds = 15 },
            { from = "stairs", to = "goal", mode = "ground", seconds = 20 },
        }, anchors = {} }, 1, "fixture-room")
        data.env.requestTerrainData = function() return "ready" end
    end
    -- The fixture controls a point-scoped source independently of catalog content.
    data.HasTerrainData = function(_, point)
        return withGeometry and (point == nil or point.accessKey == "room")
    end
    local start = data:NormalizeLocation(outside)
    local target = data:NormalizeLocation(goal)
    local edges = data:BuildEdges({ start = start, goal = target, walkSpeed = 1 })
    local hint, crossing
    for _, edge in ipairs(edges) do
        if edge.id == "retail:indoor-hint:forward" then hint = edge end
        if edge.id == "retail:entry-crossing:forward" then crossing = edge end
    end
    if withGeometry then assert(not hint, "Covered walking hints must not survive as fixed-cost shortcuts")
    else assert(hint and hint.kind == "passage" and hint.seconds == 5, "Without terrain the original hint remains compatible") end
    if includeEntrance then assert(crossing and crossing.kind == "passage" and crossing.seconds == 2,
        "The real access crossing remains mandatory, independent of interior walking") end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local job = APR.NavigationPlanner:Create({ data = data, engine = lib.Engine, start = start, goal = target,
        walkSpeed = 1, movementProfile = { groundSpeed = 1 },
        taxiData = { BuildEdges = function() return {} end },
        canWalk = function(a, b) return data:CanWalk(a, b) end,
        prepareSegment = function(segment) return segment end })
    for _ = 1, 20000 do
        local state = job:Step(4, 1)
        if state ~= "planning" then
            if not includeEntrance then assert(state == "no_path", "Terrain cannot invent entry across an access boundary"); return end
            assert(state == "ready", state)
            local result = job:GetResult()
            assert(result.totalSeconds == (withGeometry and 47 or 7), "The independent staircase costs must participate in route choice")
            assert(result.segments[1].kind == "passage", "Entering the room is still an explicit crossing")
            if withGeometry then
                local shaped = result.segments[2]
                assert(shaped.terrain and #shaped.polyline >= 4, "The published floor route keeps both wall corners and the stair height")
                assert(shaped.polyline[2].y == 40 and shaped.polyline[#shaped.polyline].z == 10)
            end
            return
        end
    end
    error("Indoor passage plan did not finish")
end
run(true, true)
run(false, true)
run(true, false)

-- Only declared walking hints are replaced; fixed transports and boundary legs stay.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local function p(x, access) return { space = "world", instanceID = 0, uiMapID = 501, x = x, y = 0, accessKey = access } end
local data = fixture:Load({ connections = {
    { id = "partial", kind = "passage", terrainWalk = true, bidirectional = true, from = p(0, "room"), to = p(20, "room"), seconds = 5 },
    { id = "boundary", kind = "passage", terrainWalk = true, from = p(0), to = p(20, "room"), seconds = 2 },
    { id = "transport", kind = "portal", from = p(0, "room"), to = p(20, "room"), seconds = 3 },
    { id = "unmarked", kind = "passage", from = p(0, "room"), to = p(20, "room"), seconds = 4 },
    { id = "disabled-flag", kind = "passage", terrainWalk = false, from = p(0, "room"), to = p(20, "room"), seconds = 6 },
} })
data.HasTerrainData = function(_, point) return point and point.x == 20 end
local found = {}
for _, edge in ipairs(data:BuildEdges({ walkSpeed = 1 })) do found[edge.id] = true end
assert(not found["retail:partial:forward"], "One covered endpoint is enough to reject an unsafe inward chord")
assert(not found["retail:partial:reverse"], "The reverse walking hint is replaced by the same scoped geometry")
for _, id in ipairs({ "boundary", "transport", "unmarked", "disabled-flag" }) do
    assert(found["retail:" .. id .. ":forward"], "An unrelated transport/access declaration must remain intact")
end
local lib = LibStub("LibAPRNavigation-1.0")
for _, invalid in ipairs({ { kind = "passage", terrainWalk = "yes" }, { kind = "portal", terrainWalk = true },
    { kind = "passage", terrainWalk = true, from = { dynamic = "player" } } }) do
    invalid.id, invalid.from, invalid.to = "invalid", invalid.from or p(0), p(20)
    assert(not pcall(lib.RegisterData, lib, "invalid", "fixture", { connections = { invalid } }), "Reject invalid walking-hint semantics at registration")
end
print("Terrain catalog walking: scoped replacement, explicit entrance, stairs, legacy fallback and flag validation passed")
