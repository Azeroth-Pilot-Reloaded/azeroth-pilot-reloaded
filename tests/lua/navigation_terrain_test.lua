-- Invented terrain proves routing contracts independently of maintained guides.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
dofile(root .. "Core.lua")
dofile(root .. "Geography.lua")
dofile(root .. "Search.lua")
for _, name in ipairs({ "Terrain.lua", "LocalRouting.lua", "Guidance.lua" }) do
    local file = io.open(root .. name)
    if file then file:close(); dofile(root .. name) end
end
local lib = LibStub("LibAPRNavigation-1.0")
assert(type(lib.Instance.CreateLocalRoute) == "function", "terrain routing API must be available")

local function point(x, y, z, floor)
    return { x = x, y = y, z = z, floor = floor, instanceID = 8, uiMapID = 18, region = "outside" }
end
local function node(id, x, y, z, floor, mode)
    local p = point(x, y, z, floor)
    p.id, p.movementMode = id, mode
    return p
end
local function setup(data, env)
    lib.terrainDatasets, lib.terrainRevision = {}, 0
    lib:RegisterTerrainData("fixture", 8, data, 1)
    local instance = lib:New({ profile = "fixture", environment = env or {} })
    return instance
end
local function finish(job)
    local status, result, coverage
    for _ = 1, 20000 do
        status, result, coverage = job:Step(7, 1)
        assert((job.workLastStep or 0) <= 7, "work must obey the operation budget")
        if status ~= "planning" then return status, result, coverage end
    end
    error("terrain job did not finish")
end
local function near(a, b) assert(math.abs(a - b) < 0.00001, tostring(a) .. " ~= " .. tostring(b)) end

local data = {
    format = 1,
    nodes = { node(1, 0, 0, 0), node(2, 0, 10, 0), node(3, 20, 10, 0), node(4, 20, 0, 0) },
    edges = {
        { from = 1, to = 2, mode = "ground", length = 10 },
        { from = 2, to = 3, mode = "ground", length = 20 },
        { from = 3, to = 4, mode = "ground", length = 10 },
    },
}
local instance = setup(data)
local status, route = finish(instance:CreateLocalRoute({ start = point(0, 0, 0), goal = point(20, 0, 0),
    movementProfile = { groundSpeed = 10 } }))
assert(status == "ready", "a verified detour must be found")
near(route.totalSeconds, 4)
assert(#route.polyline == 4 and route.polyline[2].y == 10 and route.polyline[3].x == 20,
    "the published polyline must retain both wall corners")
status = finish(instance:CreateLocalRoute({ start = point(20, 0, 0), goal = point(0, 0, 0) }))
assert(status == "no_path", "one-way terrain links must not become bidirectional")

-- A cell is a convex, proved traversable volume, not a nearest-node radius.
data.anchors = { { node = 1, minX = -2, maxX = 2, minY = -2, maxY = 2, minZ = -1, maxZ = 1 } }
instance = setup(data)
status, route = finish(instance:CreateLocalRoute({ start = point(-1, 0, 0), goal = point(20, 0, 0),
    movementProfile = { groundSpeed = 10 } }))
assert(status == "ready"); near(route.totalSeconds, 4.1)
status = finish(instance:CreateLocalRoute({ start = point(-3, 0, 0), goal = point(20, 0, 0) }))
assert(status == "missing_data", "outside a proved cell no nearest-node shortcut is invented")

-- A high summit is slower than going around it; a low summit reverses the winner.
local function mountain(height)
    return { format = 1, nodes = { node(1, 0, 0, 0, nil, "skyriding"),
        node(2, 50, 0, height, nil, "skyriding"), node(3, 50, 80, 0, nil, "skyriding"),
        node(4, 100, 0, 0, nil, "skyriding") }, edges = {
        { from = 1, to = 2, mode = "skyriding", horizontal = 50, rise = height },
        { from = 2, to = 4, mode = "skyriding", horizontal = 50, fall = height },
        { from = 1, to = 3, mode = "skyriding", horizontal = 100 },
        { from = 3, to = 4, mode = "skyriding", horizontal = 100 },
    } }
end
local profile = { canSkyriding = true, currentMode = "skyriding", skyridingSpeed = 50, climbSpeed = 10, descentSpeed = 50 }
local start, goal = point(0, 0, 0), point(100, 0, 0)
start.movementMode, goal.movementMode = "skyriding", "skyriding"
instance = setup(mountain(100))
status, route = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = profile }))
assert(status == "ready" and route.polyline[2].y == 80); near(route.totalSeconds, 4)
instance = setup(mountain(1))
status, route = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = profile }))
assert(status == "ready" and route.polyline[2].z == 1); near(route.totalSeconds, 2.12)
status = finish(instance:CreateLocalRoute({ start = start, goal = goal, movementProfile = { currentMode = "skyriding" } }))
assert(status == "no_path", "a character without flight cannot use aerial edges")

-- XY cannot select between floors while altitude and floor are unknown.
instance = setup({ format = 1, nodes = { node(1, 0, 0, 0, 1), node(2, 0, 0, 20, 2) }, edges = {},
    anchors = {
        { node = 1, minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = -1, maxZ = 1 },
        { node = 2, minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = 19, maxZ = 21 },
    } })
status = finish(instance:CreateLocalRoute({ start = point(0, 0), goal = point(0, 0, 20, 2) }))
assert(status == "waiting_data", "an ambiguous surface needs an observation")
status = finish(instance:CreateLocalRoute({ start = point(0, 0, 0, 2), goal = point(0, 0, 20, 2) }))
assert(status == "missing_data", "a matching XY and Z cannot ignore a conflicting observed floor")

-- Incomplete terrain cannot leak the old same-region euclidean connection.
instance = setup(data)
local build = instance:CreateTerrainEdgeBuild({ start = point(-3, 0, 0), goal = point(20, 0, 0),
    canWalk = function() return true end })
local edges, coverage
status, edges, coverage = finish(build)
assert(status == "ready" and coverage.missingData and not coverage.covered)
assert(not coverage.canWalk(point(-3, 0, 0), point(20, 0, 0)))
assert(coverage.canWalk({ instanceID = 9 }, { instanceID = 9 }), "unmanaged worlds retain the host policy")

local cancelled = instance:CreateLocalRoute({ start = point(0, 0, 0), goal = point(20, 0, 0) })
cancelled:Cancel()
assert(cancelled:Step(100) == "cancelled")

-- A tiny free entry volume can lead to a distant HPA portal by a proved path.
instance = setup({ format = 1, nodes = { node(1, 20, 20, 0), node(2, 40, 20, 0) },
    edges = { { from = 1, to = 2, mode = "ground", length = 20 } }, anchors = {
        { node = 1, minX = -1, maxX = 1, minY = -1, maxY = 1, minZ = -1, maxZ = 1,
            path = { point(0, 0, 0), point(0, 20, 0), point(20, 20, 0) }, bidirectional = true },
    } })
status, route = finish(instance:CreateLocalRoute({ start = point(0, 0, 0), goal = point(40, 20, 0),
    movementProfile = { groundSpeed = 10 } }))
assert(status == "ready"); near(route.totalSeconds, 6)
assert(route.polyline[2].x == 0 and route.polyline[2].y == 20)
status, route = finish(instance:CreateLocalRoute({ start = point(20, 20, 0), goal = point(0, 0, 0),
    movementProfile = { groundSpeed = 10 } }))
assert(status == "ready"); near(route.totalSeconds, 4)

local private = point(0, 0, 0)
private.noAutoconnect = true
status, edges, coverage = finish(instance:CreateTerrainEdgeBuild({ start = point(20, 20, 0), goal = private }))
assert(status == "ready" and not coverage.attached[private])
for _, edge in ipairs(edges) do assert(edge.from ~= private and edge.to ~= private, "private passages cannot gain terrain shortcuts") end

-- Results prepared against an older pack revision must never be published.
instance = setup(data)
local changing = instance:CreateLocalRoute({ start = point(0, 0, 0), goal = point(20, 0, 0) })
while changing.phase ~= "search" do assert(changing:Step(1, 1) == "planning") end
lib:RegisterTerrainData("fixture", 8, { format = 1, nodes = data.nodes, edges = {} }, 2)
assert(finish(changing) == "no_path")

assert(type(instance.CreateTerrainRouteBuild) == "function", "terrain route coalescing must be available")
local a, b, c, d = point(0, 0, 0), point(0, 10, 0), point(10, 10, 0), point(20, 10, 0)
local assembled
status, assembled = finish(instance:CreateTerrainRouteBuild({ totalSeconds = 4, totalCopper = 20, resourcesUsed = { token = 1 },
    segments = {
        { kind = "walk", terrain = true, from = a, to = a, movementMode = "ground", seconds = 0, polyline = { a, a } },
        { kind = "walk", terrain = true, from = a, to = b, movementMode = "ground", seconds = 1, polyline = { a, b } },
        { kind = "walk", terrain = true, from = b, to = c, movementMode = "ground", seconds = 1, polyline = { b, c } },
        { kind = "walk", terrain = true, from = c, to = d, movementMode = "ground", seconds = 2, mandatory = true, polyline = { c, d } },
    } }))
assert(status == "ready" and #assembled.segments == 2)
assert(#assembled.segments[1].polyline == 3 and assembled.segments[1].polyline[2] == b)
near(assembled.segments[1].seconds, 2)
assert(assembled.totalSeconds == 4 and assembled.totalCopper == 20 and assembled.resourcesUsed.token == 1)
assert(assembled.segments[2].mandatory, "coalescing must stop at a real passage")

-- Visibility is the union of proved free cells, never their encompassing box.
local function cells(secondMin)
    return { format = 1, nodes = { node(1, 1, 0, 0), node(2, 4, 0, 0) }, edges = {}, anchors = {
        { node = 1, minX = 0, maxX = 2, minY = -1, maxY = 1, minZ = -1, maxZ = 1 },
        { node = 2, minX = secondMin, maxX = 5, minY = -1, maxY = 1, minZ = -1, maxZ = 1 },
    } }
end
instance = setup(cells(2))
finish(instance:CreateTerrainEdgeBuild({ start = point(1, 0, 0), goal = point(4, 0, 0) }))
assert(instance:CanTraverseTerrain(point(0.5, 0, 0), point(4.5, 0, 0), "ground") == true)
assert(instance:CanTraverseTerrain(point(4.5, 0, 0), point(0.5, 0, 0), "ground") == true)
assert(instance:CanTraverseTerrain(point(0.5, 0, 10), point(4.5, 0, 10), "ground") == nil)
instance = setup(cells(3))
finish(instance:CreateTerrainEdgeBuild({ start = point(1, 0, 0), goal = point(4, 0, 0) }))
local clear, prefix = instance:CanTraverseTerrain(point(0.5, 0, 0), point(4.5, 0, 0), "ground")
assert(clear == nil and prefix.x < 2 and prefix.x > 1.99, "an obstacle limits the proved prefix")
lib:RegisterTerrainData("fixture", 8, cells(2), 2)
assert(instance:CanTraverseTerrain(point(0.5, 0, 0), point(4.5, 0, 0), "ground") == nil,
    "cached visibility cannot outlive the source revision")

local many = { format = 1, nodes = {}, edges = {} }
for i = 1, 200 do many.nodes[i] = node(i, i * 100, 0, 0) end
instance = setup(many)
local bounded = instance:CreateTerrainEdgeBuild({ start = point(100, 0, 0), goal = point(20000, 0, 0) })
assert(bounded:Step(0, 1) == "planning" and bounded.workLastStep == 0)
assert(bounded:Step(math.huge, 1) == "planning" and bounded.workLastStep <= 64, "invalid operation limits retain a finite bound")
finish(bounded)
local geometry = instance._terrainGeometryCache
finish(instance:CreateTerrainEdgeBuild({ start = point(100, 0, 0), goal = point(20000, 0, 0) }))
assert(instance._terrainGeometryCache == geometry, "warm plans reuse immutable geometry within one consumer")
local independent = lib:New({ profile = "fixture", environment = {} })
finish(independent:CreateTerrainEdgeBuild({ start = point(100, 0, 0), goal = point(20000, 0, 0) }))
assert(independent._terrainGeometryCache ~= geometry, "consumers do not share mutable planning caches")

local requested = {}
instance = setup(data, { requestTerrainData = function(_, world) requested[world] = true; return "ready" end })
local other = point(0, 0, 0)
other.instanceID = 9
lib:RegisterTerrainData("fixture", 9, { format = 1, nodes = {}, edges = {} }, 1)
status, edges, coverage = finish(instance:CreateTerrainEdgeBuild({ start = point(0, 0, 0), goal = point(20, 0, 0),
    terrainWorlds = { [8] = true }, edgeGroups = { { { from = other, to = other, kind = "taxi" } } },
    canWalk = function() return true end }))
assert(status == "ready" and requested[8] and not requested[9], "unselected transport worlds do not load their packs")
assert(coverage.canWalk(other, other), "unrefined worlds retain the caller's optimistic lower bound")
print("Terrain: proved attachments, directed detours, time-based flight, unknown floors, coverage and cancellation passed")
