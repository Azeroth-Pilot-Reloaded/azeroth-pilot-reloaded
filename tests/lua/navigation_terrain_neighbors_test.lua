-- Internal chunk seams are explicit references, never exterior gateways.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local function point(x,y)return {x=x,y=y,z=0,instanceID=8,uiMapID=18,region="room"} end
local function scope(id,low,high)return {id=id,bounds={minX=low,maxX=high,minY=0,maxY=10,minZ=-1,maxZ=1}} end
local first,second=scope("first",0,10),scope("second",10,20)
local function sources()
    local a={format=1,scope=first,neighborScopeIDs={"second"},nodes={
        {id="start",x=1,y=1,z=0,uiMapID=18,region="room"},
        {id="seam",x=10,y=1,z=0,uiMapID=18,region="room"}},
        edges={{from="start",to="seam",mode="ground",seconds=9},
            {from="seam",to={pack="b",node="seam"},mode="ground",seconds=0,neighborScopeID="second"}},
        anchors={{node="start",minX=1,maxX=9,minY=.5,maxY=1.5,minZ=-.5,maxZ=.5}}}
    local b={format=1,scope=second,neighborScopeIDs={"first"},nodes={
        {id="seam",x=10,y=1,z=0,uiMapID=18,region="room"},
        {id="turn",x=10,y=8,z=0,uiMapID=18,region="room"},
        {id="goal",x=18,y=8,z=0,uiMapID=18,region="room"}},
        edges={{from="seam",to="turn",mode="ground",seconds=7},
            {from="turn",to="goal",mode="ground",seconds=8}}}
    return a,b
end
local function setup(a,b,legacy)
    local data=fixture:Load({connections={}})
    local lib=LibStub("LibAPRNavigation-1.0")
    assert(type(data.GetTerrainScopeNeighbors)=="function","Neighbor lookup must be available without loading neighboring geometry")
    lib:RegisterTerrainData("retail",8,a,1,"a")
    local state={loads={},reject=false}
    data.env.getTerrainScopes=function()return legacy and {} or {first,second},legacy==true end
    data.env.requestTerrainData=function(_,world,p,selection)
        if legacy then assert(p and not selection);return "ready" end
        assert(p==nil and selection and selection.scopeIDs)
        for id in pairs(selection.scopeIDs) do
            state.loads[id]=(state.loads[id] or 0)+1
            if id=="second" then
                if state.reject then return "missing","neighbor_unavailable" end
                lib:RegisterTerrainData("retail",8,b,1,"b")
            end
        end
        return "ready"
    end
    return data,lib,state
end
local function finish(job)
    for _=1,10000 do
        local state,result,coverage=job:Step(1,100)
        assert(job.workLastStep<=1)
        if state~="planning" then return state,result,coverage end
    end
    error("Neighbor fixture did not finish")
end
local function build(data,selection)
    local job=data:CreateTerrainEdgeBuild({start=point(1,1),goal=point(18,8),terrainScopes=selection,
        canWalk=function(a,b)return data:CanWalk(a,b)end})
    local status,edges,coverage=finish(job)
    return job,status,edges,coverage
end
local a,b=sources()
local data,lib,state=setup(a,b)
assert(data:GetTerrainScopeNeighbors(8,"first")[1]=="second" and not state.loads.second)
local job,status,edges,coverage=build(data,{[8]={first=true}})
assert(status=="ready" and #job.packs==1 and not state.loads.second,
    "An explicitly declared unloaded neighbor is deferred without invalidating the accepted chunk")
for _,edge in ipairs(edges) do
    assert(not edge.from.terrainBoundary and not edge.to.terrainBoundary,
        "Internal seams cannot create free exterior attachment points")
end
local search=data:CreateSearch({start=point(1,1),goal=point(18,8),edges=edges,canWalk=coverage.canWalk,walkingIsTransitive=false})
assert(finish(search)=="no_path","An unselected seam cannot create a coarse shortcut to the objective")
job,status,edges,coverage=build(data,{[8]={first=true,second=true}})
assert(status=="ready" and state.loads.second==1)
local route
status,route=finish(data:CreateSearch({start=point(1,1),goal=point(18,8),edges=edges,
    canWalk=coverage.canWalk,walkingIsTransitive=false,walkSpeed=1}))
assert(status=="ready" and route.totalSeconds==24)
local turn=false
for _,edge in ipairs(route.segments) do if edge.to.x==10 and edge.to.y==8 then turn=true end end
assert(turn,"The accepted neighboring chunk must retain its explicit corner")
local cached=lib.terrainDatasets.retail[8].packs.b.data
state.reject=true
job,status=build(data,{[8]={first=true,second=true}})
assert(status=="ready" and #job.packs==1 and job.unavailableScopes[8].second,
    "A rejected neighbor is deferred even if an earlier registration is still cached")
state.reject=false
job,status=build(data,{[8]={first=true,second=true}})
assert(status=="ready" and lib.terrainDatasets.retail[8].packs.b.data==cached,
    "A newly selected neighbor may reuse registered data after its availability is proved again")
a,b=sources();data,lib,state=setup(a,b)
local stale=lib.Copy(b);stale.scope=scope("retired-neighbor",30,40)
lib:RegisterTerrainData("retail",8,stale,1,"b")
state.reject=true
job,status=build(data,{[8]={first=true,second=true}})
assert(status=="ready" and #job.packs==1,
    "Rejected stale registration metadata cannot invalidate an accepted chunk's declared seam")

a,b=sources();a.edges[2].to.node="missing"
data=setup(a,b)
job,status=build(data,{[8]={first=true,second=true}})
assert(status=="invalid_data" and job.reason=="unknown_terrain_node",
    "Once both scopes are accepted a missing node is corrupt data, not a deferred edge")
a,b=sources();a.edges[2].from={pack="b",node="seam"};a.edges[2].to="missing-local"
data=setup(a,b)
job,status=build(data,{[8]={first=true}})
assert(status=="invalid_data" and job.reason=="unknown_terrain_node",
    "Deferring an unloaded foreign endpoint cannot hide a corrupt local endpoint")
a,b=sources();a.edges[2].polyline="invalid"
data=setup(a,b)
job,status=build(data,{[8]={first=true}})
assert(status=="invalid_data" and job.reason=="invalid_terrain_polyline",
    "Deferring a neighbor cannot bypass the edge declaration's field validation")
for _,variant in ipairs({"undeclared","unknown"}) do
    a,b=sources()
    if variant=="undeclared" then a.neighborScopeIDs={} else
        a.neighborScopeIDs={"ghost"};a.edges[2].neighborScopeID="ghost"
    end
    data=setup(a,b)
    job,status=build(data,{[8]={first=true}})
    assert(status=="invalid_data" and job.reason=="invalid_terrain_neighbor",
        "An unknown or undeclared neighbor cannot hide an invalid reference")
end
a,b=sources();a.scope,b.scope=nil,nil;a.neighborScopeIDs,b.neighborScopeIDs=nil,nil
a.edges[2].neighborScopeID=nil;a.edges[2].to.node="missing"
data,lib=setup(a,b,true);lib:RegisterTerrainData("retail",8,b,1,"b")
job,status=build(data,nil)
assert(status=="invalid_data" and job.reason=="unknown_terrain_node",
    "Legacy whole-world builds retain complete reference validation")

-- Host inventory advertises adjacency without reading or loading the addons.
data=fixture:Load({connections={}})
APR.NavigationTerrainIndex={schema=1,profiles={retail={worlds={[8]={packs={
    {id="a",scope=first,neighborScopeIDs={"second"}},
    {id="a-extra",scope=first,neighborScopeIDs={"second"}},
    {id="b",scope=second,neighborScopeIDs={"first"}},
}}}}}}
C_AddOns={LoadAddOn=function()error("A metadata neighbor lookup cannot load an addon")end}
dofile("APR-Core/features/navigation/NavigationTerrain.lua")
local neighbors=APR.NavigationTerrain:GetScopeNeighbors("retail",8,"first")
assert(#neighbors==1 and neighbors[1]=="second")
assert(data:GetTerrainScopeNeighbors(8,"first")[1]=="second","The adapter forwards the same metadata-only lookup")
local replacement={id="third",bounds={minX=20,maxX=30,minY=0,maxY=10,minZ=-1,maxZ=1}}
APR.NavigationTerrainIndex.profiles.retail.worlds[8]={packs={
    {id="a-new",scope=first,neighborScopeIDs={"third"}},{id="c",scope=replacement}}}
assert(APR.NavigationTerrain:GetScopeNeighbors("retail",8,"first")[1]=="third",
    "Replacing a world record cannot retain the previous adjacency index")
function GetBuildInfo()return "12.3.4","99" end
function APR:GetGameVersion()return "retail" end
local indexed={id="a",addon="FixtureNeighborA",revision=1,scope=first,neighborScopeIDs={"second"}}
APR.NavigationTerrainIndex.profiles.retail.builds={["12.3.4.99"]=true}
APR.NavigationTerrainIndex.profiles.retail.worlds[8]={packs={indexed,{id="b",scope=second}}}
local hostLib=LibStub("LibAPRNavigation-1.0")
hostLib:RegisterTerrainData("retail",8,{format=1,profile="retail",build="12.3.4.99",scope=first,
    neighborScopeIDs={},nodes={},edges={}},1,"a")
C_AddOns.IsAddOnLoaded=function()return true,true end
local hostState,hostReason=APR.NavigationTerrain:RequestData("retail",8,nil,{scopeIDs={first=true}})
assert(hostState=="missing" and hostReason=="terrain_registration_missing",
    "Registered geometry cannot satisfy different advertised neighbor metadata")
indexed.revision=2
hostLib:RegisterTerrainData("retail",8,{format=1,profile="retail",build="12.3.4.99",scope=first,
    neighborScopeIDs={"second"},nodes={},edges={}},2,"a")
assert(APR.NavigationTerrain:RequestData("retail",8,nil,{scopeIDs={first=true}})=="ready")
print("Terrain neighbors: lazy seams, explicit corners, strict references, cache recovery and metadata-only inventory passed")
