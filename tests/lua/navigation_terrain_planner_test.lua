-- Real terrain costs must participate in transport selection, not just drawing.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load({ connections = {} })
local lib = LibStub("LibAPRNavigation-1.0")
local raw = {
    format = 1, build = "fixture", nodes = {}, edges = {}, anchors = {},
}
local coords = {{0,0}, {10,0}, {10,100}, {90,100}, {90,0}, {100,0}}
for index, coord in ipairs(coords) do
    raw.nodes[index] = { id = tostring(index), x = coord[1], y = coord[2], z = 0, uiMapID = 501 }
    raw.anchors[index] = { node = tostring(index), minX = coord[1] - 0.1, maxX = coord[1] + 0.1,
        minY = coord[2] - 0.1, maxY = coord[2] + 0.1, minZ = -0.1, maxZ = 0.1, mode = "ground", bidirectional = true }
    if index > 1 then
        raw.edges[#raw.edges + 1] = { from = tostring(index-1), to = tostring(index), mode = "ground" }
        raw.edges[#raw.edges + 1] = { from = tostring(index), to = tostring(index-1), mode = "ground" }
    end
end
assert(type(lib.RegisterTerrainData) == "function", "Terrain registration must be available to an embedded consumer")
local beforeRevision = lib.terrainRevision
assert(not pcall(lib.RegisterTerrainData, lib, "invalid-profile", 999, {format=99}, 1), "Reject malformed packs at registration")
assert(lib.terrainDatasets["invalid-profile"] == nil and lib.terrainRevision == beforeRevision,
    "A rejected registration cannot leave a managed world or change the source revision")
lib:RegisterTerrainData("retail", 0, raw, 1, "fixture")
-- This standalone fixture authorizes its synthetic registration without a WoW
-- load-on-demand addon or client-build index.
data.env.requestTerrainData = function() return "ready" end
local shared = {x=1,y=2,z=0}
local aliased = {format=1,nodes={},edges={},anchors={},points={shared,shared}}
lib:RegisterTerrainData("alias-profile", 0, aliased, 1)
local copied = lib.terrainDatasets["alias-profile"][0].packs.default.data
assert(copied.points[1] == copied.points[2] and copied.points[1] ~= shared,
    "A terrain registration owns its data while preserving interned point identities")
local function point(index)
    return data:NormalizeLocation({ instanceID = 0, uiMapID = 501,
        x = coords[index][1], y = coords[index][2], z = 0 })
end
local portal = { kind = "portal", id = "synthetic-crossing", from = point(2), to = point(5), seconds = 120 }
data.CreateEdgeBuild = function()
    return { Step = function() return "ready", { portal }, { resources = {} } end }
end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local request = {
    data = data, engine = lib.Engine, start = point(1), goal = point(6), walkSpeed = 1,
    movementProfile = { groundSpeed = 1, canSteady = false, canSkyriding = false },
    taxiData = { BuildEdges = function() return {} end },
    canWalk = function(a,b) return data:CanWalk(a,b) end,
    walkingIsTransitive = true, prepareSegment = function(segment) return segment end,
}
local function plan()
    local job = APR.NavigationPlanner:Create(request)
    local iterations = 0
    while job:Step(4, 1) == "planning" do
        iterations = iterations + 1
        assert(iterations < 10000, "Terrain planning must finish in bounded slices")
    end
    assert(job.status == "ready", "The synthetic terrain itinerary is reachable")
    return job:GetResult(), job
end
local result = plan()
assert(result.totalSeconds == 140, "The crossing beats the 300-second terrain detour, although a false direct walk would take 100")
local usedPortal = false
for _, segment in ipairs(result.segments) do if segment.id == portal.id then usedPortal = true end end
assert(usedPortal, "Terrain approach costs must influence the chosen transport")
portal.seconds = 400
result = plan()
assert(result.totalSeconds == 300, "The ground detour wins when the crossing becomes slower")
for _, segment in ipairs(result.segments) do assert(segment.kind ~= "portal", "Do not retain an obsolete transport preference") end
-- Unloaded terrain uses a lower bound until it lies on a winning candidate.
-- Refining that candidate must happen before publication, without loading
-- the catalogue's unrelated or blocked worlds.
local loads = {}
data.env.hasTerrainData = function(_,world) return world == 9 or world == 10 end
data.env.requestTerrainData = function(_,world)
    loads[world] = (loads[world] or 0) + 1
    if world == 9 and not (lib.terrainDatasets.retail[9]) then
        local points = {{0,0},{0,100},{100,100},{100,0}}
        local pack = {format=1,nodes={},edges={},anchors={}}
        for i,p in ipairs(points) do
            pack.nodes[i] = {id=tostring(i),x=p[1],y=p[2],z=0,uiMapID=601}
            pack.anchors[i] = {node=tostring(i),mode="ground",bidirectional=true,
                minX=p[1]-.1,maxX=p[1]+.1,minY=p[2]-.1,maxY=p[2]+.1,minZ=-.1,maxZ=.1}
            if i > 1 then
                pack.edges[#pack.edges+1] = {from=tostring(i-1),to=tostring(i),mode="ground"}
                pack.edges[#pack.edges+1] = {from=tostring(i),to=tostring(i-1),mode="ground"}
            end
        end
        lib:RegisterTerrainData("retail",9,pack,1,"detour")
    end
    return "ready"
end
local a = data:NormalizeLocation({instanceID=9,uiMapID=601,x=0,y=0,z=0})
local b = data:NormalizeLocation({instanceID=9,uiMapID=601,x=100,y=0,z=0})
local unused = data:NormalizeLocation({instanceID=10,uiMapID=602,x=0,y=0,z=0})
portal.seconds = 120
data.CreateEdgeBuild = function()
    return {Step=function() return "ready", {portal,
        {kind="portal",from=point(1),to=a,seconds=1},
        {kind="portal",from=b,to=point(6),seconds=1},
        {kind="portal",from=point(1),to=unused,seconds=1000}}, {resources={}} end}
end
result = plan()
assert(result.totalSeconds == 140, "An optimistic 102-second crossing must be refined to its 302-second terrain cost before selecting the winner")
assert(loads[9] and not loads[10], "Only a competitive intermediate world may load; irrelevant transport branches stay dormant")
print("Terrain planning: explicit local costs compete with transports under the shared scheduler")
