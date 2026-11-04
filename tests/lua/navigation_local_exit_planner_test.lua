-- A missing local exit cannot turn a nearby objective into a world tour.
local fixture=dofile("tests/lua/navigation_fixture.lua")
fixture.maps[501]={mapID=501,mapType=3,parentMapID=12}
fixture.maps[502]={mapID=502,mapType=6,parentMapID=501}
local data=fixture:Load({config={NavigationSpaces={
    {id="cave",kind="cave",worldID=8,mapIDs={502},groundOnly=true,requiresExit=true},
    {id="plain",kind="outdoor",worldID=8,mapIDs={501}},
}},connections={}})
local lib=LibStub("LibAPRNavigation-1.0")
local function p(map,x,y) return data:NormalizeLocation({instanceID=8,uiMapID=map,x=x,y=y,z=1}) end
local start,goal=p(502,0,0),p(501,20,10)
local remote={instanceID=9,uiMapID=503,x=0,y=0,z=1,region="remote"}
local edges={
    {kind="item",id="remote-shortcut",from=start,to=remote,seconds=100,sourceFree=true,action={type="item",data=999}},
    {kind="portal",id="return",from=remote,to=goal,seconds=1},
}
data.CreateEdgeBuild=function()return {Step=function()return "ready",edges,{resources={}}end}end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local function plan(localExit)
    local job=APR.NavigationPlanner:Create({data=data,engine=lib.Engine,start=start,goal=goal,
        preferLocalSpaceExit=localExit,taxiData={BuildEdges=function()return {}end},walkSpeed=7,canWalk=function(a,b)return data:CanWalk(a,b)end,
        prepareSegment=function(s)return s end})
    for _=1,10000 do if job:Step(4,10)~="planning" then return job end end
    error("Local topology check must finish under the planner's shared budget")
end
local job=plan()
assert(job.status=="no_path" and job.terrainReason=="navigation_exit_unavailable",
    "The planner reports the missing local connection instead of publishing a remote item round trip")
assert(not job:GetResult() or #job:GetResult().segments==0,"A failed local proof publishes no travel itinerary")
edges[#edges+1]={kind="passage",id="turn",from=p(502,5,0),to=p(502,5,10),seconds=10/7,mandatory=true}
edges[#edges].to.noAutoconnect=true
edges[#edges+1]={kind="passage",id="exit",from=edges[#edges].to,to=p(501,10,10),seconds=5/7,mandatory=true}
job=plan()
assert(job.status=="ready","A verified physical exit restores ordinary route planning")
local result=job:GetResult()
local turns={}
for _,leg in ipairs(result.segments) do
    assert(leg.kind~="item","A short local itinerary wins once its real exit exists")
    if leg.kind=="passage" then turns[#turns+1]=leg.id end
end
assert(turns[1]=="turn" and turns[2]=="exit","Both mandatory corners survive the shared planner")
job=plan(true)
result=job:GetResult()
assert(job.status=="ready" and result.localExitOnly and result.segments[#result.segments].to.uiMapID==501,
    "Host guidance may finish the proved local exit before repricing the future outdoor journey")
assert(result.segments[#result.segments].to~=goal,"The exit prefix does not claim to finish the objective")
print("Local exit planner: missing subzone exits stay local, and proved corner chains restore guidance")
