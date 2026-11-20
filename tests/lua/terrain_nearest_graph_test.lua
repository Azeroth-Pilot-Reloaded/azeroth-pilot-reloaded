-- The real collision router and real service selector on a controlled wall.
local F=dofile("tests/lua/terrain_runtime_fixture.lua")
local lib=F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Search.lua")
dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")
local provider,nav=F.provider(lib,F.map({wall=true}))
local start=F.point(1,1) -- No observed player altitude, just as on the client.
start.uiMapID,start.region=9001,"fixture"
nav.serviceLocations={
    {service="bank",npcID=31,mapID=9001,x=5,y=1,z=0},
    {service="bank",npcID=32,mapID=9001,x=1,y=6,z=0},
}
function nav:NormalizeLocation(location)
    local p=F.point(location.x*100,location.y*100,location.z)
    p.uiMapID,p.region=location.uiMapID,"fixture"
    return p
end
function nav:CanWalk(a,b) return a.instanceID==b.instanceID and a.region==b.region end
function nav:CreateEdgeBuild() return {Step=function() return "ready",{},{} end} end
local function find()
    local job=nav:CreateServiceSearch({start=start,query={service="bank"},walkSpeed=7,walkingSpeedCeiling=7})
    for _=1,20000 do
        local status,result=job:Step(64,1)
        if status~="planning" then return status,result end
    end
    error("Physical nearest-service selection did not finish")
end
assert(nav:GetWalkingProvider()==provider)
local status,result=find()
assert(status=="ready" and result.record.npcID==32,
    "Forever chooses the physically faster bank, although the bank behind the wall is geometrically closer")
F.near(result.totalSeconds,5*F.cellSize/7)
assert(result.itinerary.segments[1].path and #result.itinerary.segments[1].path>=2,
    "The winner retains the real collision polyline for navigation")
assert(result.itinerary.segments[1].path[1].z==0,
    "The provider resolves the unique controlled surface instead of inventing a native player altitude")

nav.profile="retail"
assert(nav:GetWalkingProvider()==nil)
status,result=find()
assert(status=="ready" and result.record.npcID==31 and not result.itinerary.segments[1].path,
    "Without the Forever provider, Retail preserves its existing travel model")
F.near(result.totalSeconds,4*F.cellSize/7)
print("Actual terrain nearest: wall-aware service winner, physical ETA/polyline, unknown player altitude and Retail isolation passed")
