local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile = "forever"
local data = fixture:Load({connections = {}})
local lib = LibStub("LibAPRNavigation-1.0")
local function point(x, y, world)
    return {instanceID = world or 0, x = x, y = y, uiMapID = 501}
end
local function finish(job)
    for _ = 1, 20000 do
        local status, result = job:Step(4, 1)
        if status ~= "planning" then return status, result end
    end
    error("Road graph did not finish in bounded slices")
end
local graph = {n = {0,0, 0,100, 100,100, 100,0}, e = {
    {1,2,100,0, 0,0, 0,100}, {2,3,100,0, 0,100, 100,100},
    {3,4,100,0, 100,100, 100,0},
}}
local raw = {format = 1, roads = {[0] = graph}}
assert(lib:RegisterRoadData("forever", raw, 1))
assert(data:HasRoadData() and data:HasRoadData(point(0,0), point(100,0)))
assert(not data:HasRoadData(point(0,0), point(100,0,1)))
assert(not lib:New({profile="retail", environment={}}):HasRoadData(), "Never reuse Forever roads on Retail")
local status, route = finish(data:CreateRoadRoute({start = point(0,0), goal = point(100,0), walkSpeed = 1}))
assert(status == "ready" and math.abs(route.totalSeconds - 300) < 0.00001,
    "Measure the road's three sides, not its 100-yard chord")
local points = {}
for _, segment in ipairs(route.segments) do
    assert(segment.road and segment.movementMode == "ground")
    for _, p in ipairs(segment.polyline) do points[p.x .. ":" .. p.y] = true end
end
assert(points["0:100"] and points["100:100"], "Keep both real corners in the guidance corridor")
local cost, reason = data:RoadSegmentCost(point(0,0), point(100,0))
assert(cost == nil and reason == "road_terrain_missing", "A graph cannot prove arbitrary off-road attachments")

-- Immutable registration and replacement, without reusing compiled old edges.
raw.roads[0].e[1][3] = 1
status, route = finish(data:CreateRoadRoute({start = point(0,0), goal = point(100,0), walkSpeed = 1}))
assert(status == "ready" and math.abs(route.totalSeconds - 300) < 0.00001)
local before = data:GetRoadRevision()
assert(not lib:RegisterRoadData("forever", raw, 1) and data:GetRoadRevision() == before)
local direct = {format = 1, roads = {[0] = {n={0,0,100,0},e={{1,2,100,0,0,0,100,0}}}}}
lib:RegisterRoadData("forever", direct, 2)
status, route = finish(data:CreateRoadRoute({start = point(0,0), goal = point(100,0), walkSpeed = 2}))
assert(status == "ready" and math.abs(route.totalSeconds - 50) < 0.00001)
local cancelled = data:CreateRoadRoute({start=point(0,0),goal=point(100,0)})
cancelled:Cancel()
assert(cancelled:Step(100,1) == "cancelled")

-- Exhaustive cell traversal catches a short crossing at a blocked corner.
local rows = {}
for row = 1, 10 do rows[row] = "9" end -- ten open cells, source RLE
rows[5] = "3g4" -- four open, one blocked, five open
lib:RegisterRoadData("forever", {format=1,roads={[0]={n={-1,-1},e={}}},
    terrain={[0]={tx0=32,ty0=32,cell=1,w=10,h=10,rows=rows}}}, 3)
cost, reason = data:RoadSegmentCost(point(-3.5,-4.55), point(-4.55,-3.5))
assert(cost == nil and reason == "road_blocked", "Do not miss a corner between regular sample points")
cost = data:RoadSegmentCost(point(-1.5,-1.5), point(-1.5,-8.5))
assert(math.abs(cost - 7) < 0.00001)

-- Forever's native zero is unknown height, not a position below the road.
local from, to = point(0,0), point(0,100)
from.z, to.z = 100, 100
local guide = data:CreateGuidance({segments={{kind="walk",road=true,movementMode="ground",
    from=from,to=to,seconds=100,polyline={from,to}}}}, {canTraverse=function() return true end})
while guide:Step(4,1) == "planning" do end
local player = point(0,0)
player.z, player.positionSource = 0, "unit"
local target, state = guide:Update(player)
assert(target and state == "guiding", "Unknown native height cannot invalidate a resolved ground road")
player.positionSource = nil
target, state = guide:Update(player)
assert(not target and state == "deviated", "A real known height still distinguishes a lower floor")
print("Road network: polylines, profile isolation, unknown collision, immutable revisions, cancellation and blocked corners passed")
