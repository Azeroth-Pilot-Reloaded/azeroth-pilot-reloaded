-- A bent local exit needs a neighboring chunk outside the objective's ray.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local function setup(options)
    options=options or {}
    local maps={[500]={mapType=2,parentMapID=0},[501]={mapType=3,parentMapID=500},[502]={mapType=6,parentMapID=501}}
    C_Map.GetMapInfo=function(id)return maps[id] end
    local data=fixture:Load({config={NavigationSpaces={
        {id="outside",kind="outdoor",worldID=8,mapIDs={501},region="outside"},
        {id="cave",kind="cave",worldID=8,mapIDs={502},parentSpace="outside",requiresExit=true,groundOnly=true,region="cave"}
    }},connections={}})
    local lib=LibStub("LibAPRNavigation-1.0")
    local function point(x,y,map)return data:NormalizeLocation({instanceID=8,uiMapID=map or 502,x=x,y=y,z=0}) end
    local function node(id,x,y,outside)
        return {id=id,x=x,y=y,z=0,uiMapID=outside and 501 or 502,spaceID=outside and "outside" or "cave"}
    end
    local first={id="first",bounds={minX=0,maxX=10,minY=0,maxY=10,minZ=-1,maxZ=1}}
    local second={id="second",bounds={minX=8,maxX=20,minY=8,maxY=18,minZ=-1,maxZ=1}}
    local a={format=1,scope=first,neighborScopeIDs={"second"},nodes={node("start",1,1),node("corner",1,9),node("seam",9,9)},edges={
        {from="start",to="corner",mode="ground",seconds=8,mandatory=true},
        {from="corner",to="seam",mode="ground",seconds=8,mandatory=true},
        {from="seam",to={pack="b",node="seam"},mode="ground",seconds=0,neighborScopeID="second"}}}
    local exit=node("exit",20,18,not options.noExit)
    if not options.noExit then exit.terrainBoundary="second" end
    local b={format=1,scope=second,neighborScopeIDs={"first"},nodes={node("seam",9,9),node("corner",20,9),exit},edges={
        {from="seam",to="corner",mode="ground",seconds=11,mandatory=true},
        {from="corner",to="exit",mode="ground",seconds=9,mandatory=true}}}
    lib:RegisterTerrainData("retail",8,a,1,"a")
    local state={loads=0,requests={},queries=0,pending=options.pending}
    data.env.getTerrainScopes=function()return {first,second},false end
    data.env.hasTerrainData=function(_,world,p)
        if world==nil then return true end
        if world~=8 then return false end
        return p==nil or lib.Terrain.ScopeContains(first,p) or lib.Terrain.ScopeContains(second,p)
    end
    data.env.requestTerrainData=function(_,world,p,selection)
        assert(world==8 and p==nil)
        state.requests[#state.requests+1]=lib.Copy(selection.scopeIDs)
        if selection.scopeIDs.second then
            if state.pending then return "planning","neighbor_loading" end
            if not lib.terrainDatasets.retail[8].packs.b then
                state.loads=state.loads+1;lib:RegisterTerrainData("retail",8,b,1,"b")
            end
        end
        return "ready"
    end
    local neighborQuery=data.GetTerrainScopeNeighbors
    data.GetTerrainScopeNeighbors=function(self,world,id)
        state.queries=state.queries+1
        return neighborQuery(self,world,id)
    end
    if options.noExitCheck then data.CreateLocalExitCheck=false end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local request={data=data,engine=lib.Engine,start=point(1,1),goal=point(30,1,501),
        walkSpeed=1,movementProfile={groundSpeed=1},preferLocalSpaceExit=not options.noExitCheck,
        taxiData={BuildEdges=function()return {}end},canWalk=function(x,y)return data:CanWalk(x,y)end,
        prepareSegment=function(segment)
            assert(not segment.localExitProbe,"A private exit probe cannot be published")
            return segment
        end}
    return data,state,request
end
local function finish(job,state)
    for _=1,20000 do
        local before=state.queries
        local status=job:Step(1,100)
        assert(state.queries-before<=1,"One planner operation cannot batch neighbor lookups")
        assert((job.neighborWorkLastStep or 0)<=1,"Neighbor collection and frontier merging must respect the operation budget")
        if status~="planning" then return status,job:GetResult() end
    end
    error("Finite neighboring scopes did not finish")
end
local data,state,request=setup()
local job=APR.NavigationPlanner:Create(request)
assert(job.terrainScopes[8].first and not job.terrainScopes[8].second,
    "The bent second chunk is outside the direct request's initial scope selection")
local status,route=finish(job,state)
assert(status=="ready" and state.loads==1 and state.queries>0,
    "A missing local exit must expand its declared neighbor before concluding failure")
assert(route.localExitOnly and route.totalSeconds==36 and route.exitSpace=="outside")
local destination=route.segments[#route.segments].to
assert(destination.x==20 and destination.y==18,"The exit prefix stops at physical outside, before the remote objective")
local aCorner,bCorner=false,false
for _,segment in ipairs(route.segments) do
    for _,p in ipairs(segment.polyline or {segment.to}) do
        if p.x==1 and p.y==9 then aCorner=true end
        if p.x==20 and p.y==9 then bCorner=true end
    end
end
assert(aCorner and bCorner,"Both proved chunk corners must survive frontier expansion and prefix assembly")
assert(state.requests[1].first and not state.requests[1].second)

data,state,request=setup({noExitCheck=true})
job=APR.NavigationPlanner:Create(request)
status,route=finish(job,state)
assert(status=="ready" and not route.localExitOnly and math.abs(route.totalSeconds-(36+math.sqrt(389)))<.00001,
    "A failed ordinary search must also expand neighboring chunks and then reach its actual objective")

data,state,request=setup({noExit=true})
job=APR.NavigationPlanner:Create(request)
status=finish(job,state)
assert(status=="no_path" and state.loads==1 and state.queries<10
    and job.terrainReason=="navigation_exit_unavailable" and job.missingTerrain,
    "An A-to-B-to-A neighbor cycle terminates with the original physical-exit failure metadata")
for _,options in ipairs({{noExit=true},{noExit=true,noExitCheck=true}}) do
    data,state,request=setup(options)
    job=APR.NavigationPlanner:Create(request)
    for _=1,10000 do if job:Step(256,100)~="planning" then break end end
    assert(job.status=="no_path" and state.queries<10,
        "A terminal exhausted frontier ends the slice even when operation allowance remains")
end

data,state,request=setup({pending=true})
job=APR.NavigationPlanner:Create(request)
assert(finish(job,state)=="no_path" and job.waitingData and not job.missingTerrain)
state.pending=false
job=APR.NavigationPlanner:Create(request)
assert(finish(job,state)=="ready" and state.loads==1,
    "A fresh warm request must recover after its neighboring source becomes available")
data,state,request=setup({pending=true,noExit=true})
job=APR.NavigationPlanner:Create(request)
for _=1,20000 do
    if job.phase=="local_exit" and job.terrainCoverage and job.terrainCoverage.waitingData then break end
    assert(job:Step(1,100)=="planning")
end
assert(job.phase=="local_exit" and job.terrainCoverage.waitingData)
state.pending=false
data.env.requestTerrainData("retail",8,nil,{scopeIDs={second=true}})
assert(finish(job,state)=="no_path" and job.missingTerrain and not job.waitingData,
    "A source revision that resolves pending geometry cannot retain an obsolete waiting flag")

data,state,request=setup()
job=APR.NavigationPlanner:Create(request)
for _=1,10000 do
    if job.phase=="terrain_neighbors" or job.status~="planning" then break end
    job:Step(1,100)
end
assert(job.phase=="terrain_neighbors","The missing exit exposes a resumable neighbor stage")
local ticks=0
request.clock=function()ticks=ticks+.05;return ticks end
job:Step(10000,.15)
assert(job.status=="planning" and job.phase=="terrain_neighbors"
    and job.neighborWorkLastStep>0 and job.neighborWorkLastStep<10000,
    "Elapsed-time budgets must yield during metadata expansion")
local queries=state.queries
job:Cancel()
assert(job:Step(100,100)=="cancelled" and state.queries==queries,"Cancellation cannot perform another neighbor lookup")
print("Neighbor planner: bent exits, physical prefix, ordinary failure, finite cycles, warm recovery and bounded cancellation passed")
