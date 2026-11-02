-- A bounded interior proves its paths without claiming the surrounding world.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
for _, name in ipairs({ "Core", "Geography", "Search", "Terrain", "LocalRouting", "Guidance" }) do dofile(root .. name .. ".lua") end
local lib = LibStub("LibAPRNavigation-1.0")
local function p(x, y, z) return { x = x, y = y, z = z, instanceID = 8, uiMapID = 18, region = "outside" } end
local function n(id, x, y, z, boundary)
    local point = p(x,y,z); point.id, point.terrainBoundary = id, boundary; return point
end
local scope = { id = "interior", groundOnly = true,
    bounds = { minX = 10, maxX = 40, minY = 0, maxY = 30, minZ = -1, maxZ = 10 } }
local raw = { format = 1, scope = scope,
    nodes = { n("door",10,5,0,"interior"), n("a",12,5,0), n("corner",12,25,0), n("goal",35,25,0) },
    edges = { {from="door",to="a",mode="ground"}, {from="a",to="corner",mode="ground"}, {from="corner",to="goal",mode="ground"} } }
lib:RegisterTerrainData("fixture",8,raw,1,"room")
local instance = lib:New({ profile="fixture", environment={} })
assert(instance:HasTerrainData(p(20,20,0)) and not instance:HasTerrainData(p(-100,20,0)),
    "An interior pack must not claim an entire continent")
assert(not instance:HasTerrainData(p(20,20,50)), "The outdoor floor above an interior remains outside its scope")
assert(instance:RequiresTerrainRoute(p(0,15,0),p(50,15,0)), "A chord across an interior needs its collision graph")
assert(not instance:RequiresTerrainRoute(p(0,40,0),p(50,40,0)))
assert(not instance:RequiresTerrainRoute(p(0,15,50),p(50,15,50)), "An observed path above the volume is distinct")
local function finish(job)
    for _=1,20000 do
        local status,result,coverage=job:Step(5,1)
        assert((job.workLastStep or 0)<=5)
        if status~="planning" then return status,result,coverage end
    end
    error("scoped routing did not finish")
end
local start,goal=p(0,5,0),p(35,25,0)
local state,edges,coverage=finish(instance:CreateTerrainEdgeBuild({ start=start,goal=goal,
    canWalk=function(a,b) return instance:CanWalk(a,b) end }))
assert(state=="ready" and coverage.covered)
assert(coverage.canWalk(p(-100,50,0),p(100,50,0)), "Ordinary travel outside remains available")
assert(not coverage.canWalk(p(0,15,0),p(50,15,0)), "Outside endpoints cannot tunnel through the room")
assert(not coverage.canWalk(start,goal))
local route
state,route=finish(instance:CreateSearch({ start=start,goal=goal,edges=edges,
    canWalk=coverage.canWalk,walkingIsTransitive=false,walkSpeed=1 }))
assert(state=="ready" and math.abs(route.totalSeconds-(10+45/7))<0.00001,
    "The exterior approach joins the proved doorway and follows both interior legs")
local corner=false
for _,segment in ipairs(route.segments) do
    if segment.to.x==12 and segment.to.y==25 then corner=true end
end
assert(corner,"The room corner must survive publication")

-- Scope metadata must still constrain routing when loading fails.
local denied=lib:New({ profile="fixture",environment={requestTerrainData=function() return "missing","wrong_build" end} })
state,edges,coverage=finish(denied:CreateTerrainEdgeBuild({start=start,goal=goal,canWalk=function()return true end}))
assert(state=="ready" and #edges==0 and not coverage.canWalk(start,goal))
assert(coverage.canWalk(p(0,50,0),p(50,50,0)),"A missing room pack cannot disable the rest of the world")
for _,stateName in ipairs({"planning","missing"}) do
    local unavailable=lib:New({profile="fixture",environment={requestTerrainData=function()return stateName,"fixture_unavailable"end}})
    local _,_,unknown=finish(unavailable:CreateTerrainEdgeBuild({start=p(0,15,0),goal=p(50,15,0),canWalk=function()return true end}))
    assert(not unknown.covered and #unknown.missing>0,"A failed crossed region is diagnosed even with both endpoints exterior")
    assert((stateName=="planning" and unknown.waitingData) or (stateName=="missing" and unknown.missingData))
end
local legacyPresence=lib:New({profile="fixture",environment={hasTerrainData=function()return true end}})
assert(not legacyPresence:HasTerrainData(p(-100,20,0)),"Registered bounded coverage cannot be widened by a legacy world-presence callback")
local copiedScope={id="ground-room",groundOnly=true,bounds=scope.bounds}
lib:RegisterTerrainData("air-fixture",8,{format=1,scope=copiedScope,nodes={
    {id="a",x=15,y=10,z=5,movementMode="steady"}, {id="b",x=25,y=10,z=5,movementMode="steady"}},
    edges={{from="a",to="b",mode="steady"}}},1,"air")
local airStart,airGoal=p(15,10,5),p(25,10,5)
airStart.movementMode,airGoal.movementMode="steady","steady"
local grounded=lib:New({profile="air-fixture",environment={}})
assert(finish(grounded:CreateLocalRoute({start=airStart,goal=airGoal,movementProfile={canSteady=true,currentMode="steady"}}))=="no_path",
    "A ground-only scope rejects flight even when raw nodes omit repeated noFly flags")

-- Host metadata provides the scope before the first load and excludes unrelated regions.
lib.terrainDatasets.fixture=nil
local loads=0
instance=lib:New({profile="fixture",environment={
    getTerrainScopes=function(_,world) if world==8 then return {scope},false end end,
    hasTerrainData=function(_,world,point)
        if world==nil then return true end
        return world==8 and (point==nil or lib.Terrain.ScopeContains(scope,point))
    end,
    requestTerrainData=function(_,world,point)
        loads=loads+1
        assert(point==nil,"A bounded-world job loads its regional inventory before checking crossings")
        lib:RegisterTerrainData("fixture",world,raw,2,"room")
        return "ready"
    end,
}})
state,edges,coverage=finish(instance:CreateTerrainEdgeBuild({start=p(-20,15,0),goal=p(70,15,0),canWalk=function()return true end}))
assert(state=="ready" and loads==1 and #edges>0 and not coverage.canWalk(p(-20,15,0),p(70,15,0)))
assert(not coverage.canWalk(p(-20,15),p(70,15)),"Unknown altitude cannot prove a chord clears an interior")
print("Scoped terrain: bounded 3D coverage, exterior gateways, collision detours and refused-load isolation passed")
