-- A route loads and compiles its selected physical scopes, not a whole world.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({connections={}})
local lib=LibStub("LibAPRNavigation-1.0")
local function point(x,world) return {x=x,y=5,z=0,instanceID=world or 8,uiMapID=18,region="outside"} end
local function pack(id,lower)
    local scope={id=id,bounds={minX=lower,maxX=lower+30,minY=0,maxY=10,minZ=-1,maxZ=1},groundOnly=true}
    return {format=1,scope=scope,nodes={{id="node",x=lower+15,y=5,z=0,uiMapID=18,region="outside"}},edges={}}
end
local first,second=pack("first",10),pack("second",100)
lib:RegisterTerrainData("retail",8,first,1,"a")
lib:RegisterTerrainData("retail",8,second,1,"b")
local selected,unbounded=data:GetRequiredTerrainScopes(point(0),point(50))
assert(selected[8].first and not selected[8].second and not unbounded[8],
    "Only the volume intersected by the candidate chord is initially required")
local calls,rejectSecond={},true
data.env.requestTerrainData=function(_,world,position,options)
    calls[#calls+1]={world=world,point=position,options=options}
    assert(position==nil and options and options.scopeIDs,"Bounded selection is forwarded explicitly to the loader")
    local count=0
    for _ in pairs(options.scopeIDs) do count=count+1 end
    assert(count==1,"Each native loader operation selects exactly one bounded scope")
    if options.scopeIDs.second and rejectSecond then return "missing","unrelated_pack_unavailable" end
    return "ready"
end
local function finish(selection)
    local job=data:CreateTerrainEdgeBuild({start=point(0),goal=point(50),terrainScopes=selection,
        edges={{from=point(110),to=point(120),kind="portal"}},canWalk=function()return true end})
    for _=1,10000 do
        local before=#calls
        local status,_,coverage=job:Step(1,100)
        assert(job.workLastStep<=1 and #calls-before<=1,"One operation cannot perform an unbounded batch of native loads")
        if status~="planning" then return job,status,coverage end
    end
    error("The small selected-scope build did not finish")
end
local job,status,coverage=finish(selected)
assert(status=="ready" and #calls==1 and calls[1].options.scopeIDs.first and not calls[1].options.scopeIDs.second)
assert(#job.packs==1 and job.packs[1].data.scope.id=="first" and not coverage.missingData,
    "An unrelated unavailable pack cannot contaminate selected geometry or coverage")
assert(not coverage.canWalk(point(0),point(50)) and coverage.canWalk(point(90),point(140)),
    "Only managed scopes block optimistic walking before the winning route is refined")
local previousKey=data._terrainGeometryCache.selectionKey
rejectSecond=false
selected[8].second=true
job,status,coverage=finish(selected)
assert(status=="ready" and #job.packs==2 and data._terrainGeometryCache.selectionKey~=previousKey,
    "Adding a scope cannot reuse a warm cache compiled for its smaller predecessor")
assert(not coverage.canWalk(point(90),point(140)),"The refined second scope now requires its proved terrain graph")
rejectSecond=true
job,status,coverage=finish(selected)
assert(status=="ready" and #job.packs==1 and job.packs[1].data.scope.id=="first"
    and job.unavailableScopes[8].second.reason=="unrelated_pack_unavailable" and not job.unavailableWorlds[8],
    "A rejected bounded source cannot invalidate another accepted scope in the same world")
assert(coverage.missingData and not coverage.canWalk(point(90),point(140))
    and coverage.canWalk({x=0,y=50,z=0,instanceID=8},{x=140,y=50,z=0,instanceID=8}),
    "Missing source metadata blocks its own volume while unrelated exterior walking remains available")
assert(data:CanTraverseTerrain(point(115),point(115),"ground")==nil,
    "A rejected source cannot remain visible through an earlier geometry cache")
rejectSecond=false
selected[8].second=nil
job,status=finish(selected)
assert(status=="ready" and #job.packs==1,
    "A later smaller selection cannot inherit unrelated packs from a warm superset cache")
local invalid,_,invalidCoverage=finish({[8]={missing=true}})
assert(invalidCoverage.waitingData and invalidCoverage.missing[1].reason=="terrain_scope_unavailable" and #invalid.packs==0,
    "A requested scope missing from the inventory remains explicit waiting data, never vacuous successful coverage")
lib:RegisterTerrainData("retail",9,{format=1,nodes={},edges={}},1,"legacy")
local cross,legacy=data:GetRequiredTerrainScopes(point(20),point(0,9))
assert(cross[8].first and legacy[9],"Scoped endpoints and legacy world inventory remain separate requirements")
data.env.requestTerrainData=function(_,world,position,options)
    if world==9 then assert(position and not options,"Legacy world requests preserve point-based lazy selection") end
    return "ready"
end
local mixed=data:CreateTerrainEdgeBuild({start=point(20),goal=point(0,9),terrainScopes=cross,terrainUnboundedWorlds=legacy})
for _=1,10000 do if mixed:Step(64,100)~="planning" then break end end
assert(mixed.status=="ready" and mixed.unbounded[9] and #mixed.packs==2)
print("Terrain scope selection: bounded loads, ambient catalogue endpoints, cache unions/subsets and legacy world compatibility")
