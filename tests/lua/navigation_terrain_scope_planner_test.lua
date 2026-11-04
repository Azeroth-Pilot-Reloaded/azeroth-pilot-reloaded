-- Refine only the scopes touched by a candidate, including a second scope in
-- an already loaded world. An unrelated local inventory must stay dormant.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({connections={}})
local lib=LibStub("LibAPRNavigation-1.0")
local function point(x,y) return data:NormalizeLocation({x=x,y=y,z=0,instanceID=8,uiMapID=501}) end
local function scope(id,x)
    return {id=id,bounds={minX=x,maxX=x+20,minY=-1,maxY=201,minZ=-1,maxZ=1},groundOnly=true}
end
local first,second,ambient=scope("first",10),scope("second",1000),scope("ambient",2000)
data.env.getTerrainScopes=function(_,world) if world==8 then return {first,second,ambient},false end return {},false end
data.env.hasTerrainData=function(_,world,p)
    if world==nil then return true end
    if world~=8 then return false end
    if not p then return true end
    for _,s in ipairs({first,second,ambient}) do if lib.Terrain.ScopeContains(s,p) then return true end end
    return false
end
local loaded,selections,rejectSecond={},{},false
data.env.requestTerrainData=function(_,world,p,selection)
    assert(world==8 and p==nil and selection and selection.scopeIDs,
        "A scoped planning job must select local chunks rather than the whole world")
    assert(not selection.scopeIDs.ambient,"Unrelated catalogue endpoints do not load their local terrain")
    selections[#selections+1]=lib.Copy(selection.scopeIDs)
    if selection.scopeIDs.second and rejectSecond then return "missing","second_scope_unavailable" end
    for _,s in ipairs({first,second}) do
        if selection.scopeIDs[s.id] and not loaded[s.id] then
            local turn=s==first and 20 or 200
            local x=s.bounds.minX
            local nodes={
                {id=1,x=x,y=0,z=0,uiMapID=501,terrainBoundary=s.id},
                {id=2,x=x+1,y=turn,z=0,uiMapID=501},
                {id=3,x=x+19,y=turn,z=0,uiMapID=501},
                {id=4,x=x+20,y=0,z=0,uiMapID=501,terrainBoundary=s.id}}
            local edges={}
            for i=1,3 do
                edges[#edges+1]={from=i,to=i+1,mode="ground"}
                edges[#edges+1]={from=i+1,to=i,mode="ground"}
            end
            lib:RegisterTerrainData("retail",8,{format=1,scope=s,nodes=nodes,edges=edges},1,s.id)
            loaded[s.id]=true
        end
    end
    return "ready"
end
local start,goal=point(0,0),point(40,0)
local catalogue={
    {kind="portal",id="to-second",from=start,to=point(1000,0),seconds=1},
    {kind="portal",id="from-second",from=point(1020,0),to=goal,seconds=1},
    {kind="portal",id="ambient",from=point(2000,0),to=point(2020,0),seconds=9999}}
data.CreateEdgeBuild=function()return {Step=function()return "ready",catalogue,{resources={}}end}end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local function plan()
    local job=APR.NavigationPlanner:Create({data=data,engine=lib.Engine,start=start,goal=goal,
        walkSpeed=7,movementProfile={groundSpeed=7},taxiData={BuildEdges=function()return {}end},
        canWalk=function(a,b)return data:CanWalk(a,b)end,prepareSegment=function(s)return s end})
    for _=1,30000 do if job:Step(16,10)~="planning" then break end end
    return job
end
local job=plan()
assert(job.status=="ready","The verified local ground route remains reachable")
assert(loaded.first and loaded.second and not loaded.ambient,
    "The optimistic second-scope candidate must be refined before it can be rejected")
assert(selections[1].first and not selections[1].second,
    "Initial refinement selects only the direct request's intersected scope")
local route=job:GetResult()
assert(route.totalSeconds>11 and route.totalSeconds<12,
    "The short local detour beats the fully measured second-scope transport detour")
for _,segment in ipairs(route.segments) do assert(segment.kind~="portal","Do not publish an optimistic unproved crossing") end
rejectSecond=true
job=plan()
assert(job.status=="ready","Failure of a competing scope cannot discard the already proved local alternative")
route=job:GetResult()
assert(route.totalSeconds>11 and route.totalSeconds<12 and job.terrainCoverage.missingData)
assert(not job.terrainCoverage.canWalk(point(1000,0),point(1020,0)),
    "An unavailable candidate scope must still block a straight-line shortcut")
for _,segment in ipairs(route.segments) do assert(segment.kind~="portal") end
assert(#data._terrainGeometryCache.packs==1 and data._terrainGeometryCache.packs[1].data.scope.id=="first",
    "A rejected scope cannot borrow its previously registered geometry from a warm cache")
local acceptedKey=data._terrainGeometryCache.selectionKey
rejectSecond=false
job=plan()
assert(job.status=="ready" and #data._terrainGeometryCache.packs==2
    and data._terrainGeometryCache.selectionKey~=acceptedKey,
    "A recovered scope must compile into a new accepted subset even without a source revision change")
print("Scope planner: local loading, same-world candidate refinement and dormant unrelated inventory passed")
