-- Space topology is independent of UI nesting and IsIndoors observations.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local nativeInfo=C_Map.GetMapInfo
local maps={
    [91000]={mapType=2,parentMapID=0}, [91001]={mapType=3,parentMapID=91000},
    [91002]={mapType=5,parentMapID=91001}, [91003]={mapType=6,parentMapID=91001},
    [91004]={mapType=4,parentMapID=91001}, [91005]={mapType=3,parentMapID=0},
    [91006]={mapType=5,parentMapID=91003}, [91008]={mapType=6,parentMapID=91001},
    [91010]={mapType=6,parentMapID=91001},
    [91011]={mapType=5,parentMapID=91001},
    [91012]={mapType=3,parentMapID=91001}, [91013]={mapType=3,parentMapID=91001},
}
C_Map.GetMapInfo=function(id)
    if id>=91000 and id<=91020 then return maps[id] end
    return nativeInfo(id)
end
local spaces={
    {id="city",kind="outdoor",worldID=77,mapIDs={91001},transitFaction="Alliance",transitRegion="city-control"},
    {id="cave",kind="cave",worldID=77,mapIDs={91003},parentSpace="city",groundOnly=true,requiresExit=true,region="cave-room"},
    {id="building",kind="building",worldID=77,mapIDs={91002},parentSpace="city",groundOnly=true,requiresExit=true},
    {id="instance",kind="instance",worldID=77,mapIDs={91004},parentSpace="city",requiresExit=true},
    {id="subzone",kind="subzone",worldID=77,mapIDs={91005}},
    {id="lower",kind="floor",worldID=77,mapIDs={91006},parentSpace="cave",floor="lower",
        bounds={minX=-10,maxX=10,minY=-10,maxY=10,minZ=0,maxZ=5},region="lower-room"},
    {id="upper",kind="floor",worldID=77,mapIDs={91006},parentSpace="cave",floor="upper",
        bounds={minX=-10,maxX=10,minY=-10,maxY=10,minZ=20,maxZ=25},region="upper-room"},
    {id="transport",kind="transport",worldID=77,mapIDs={91008},parentSpace="city",groundOnly=true,requiresExit=true},
    {id="underground",kind="underground",worldID=77,mapIDs={91010},groundOnly=true,requiresExit=true},
    {id="single-floor",kind="floor",worldID=77,mapIDs={91012},floor="upper",requiresExit=true},
    {id="single-phase",kind="building",worldID=77,mapIDs={91013},accessKey="sealed",requiresExit=true},
    {id="shop",kind="building",worldID=77,mapIDs={91001},areaIDs={991},parentSpace="city",groundOnly=true,
        bounds={minX=50,maxX=60,minY=50,maxY=60,minZ=0,maxZ=5}},
}
local data=fixture:Load({config={NavigationSpaces=spaces,IsolatedAreas={[91011]="synthetic-floor"}},connections={}})
local lib=LibStub("LibAPRNavigation-1.0")
for index,invalid in ipairs({
    {{id="broken",kind="not-a-space",worldID=77,mapIDs={91003}}},
    {[2]={id="hole",kind="cave",worldID=77,mapIDs={91003}}},
    {{id="duplicate",kind="cave",worldID=77,mapIDs={91003}}, {id="duplicate",kind="building",worldID=77,mapIDs={91002}}},
    {{id="bad-faction",kind="outdoor",worldID=77,mapIDs={91001},transitFaction="enemy-name"}},
}) do
    assert(not pcall(lib.RegisterData,lib,"invalid-space-profile","invalid-"..index,{config={NavigationSpaces=invalid}},1),
        "Invalid space declarations must fail at registration, without leaving partial data")
end
lib:RegisterData("space-merge","one",{config={NavigationSpaces={
    {id="merged-child",kind="cave",worldID=77,mapIDs={91003},parentSpace="merged-parent"}}}},1)
lib:RegisterData("space-merge","two",{config={NavigationSpaces={
    {id="merged-parent",kind="outdoor",worldID=77,mapIDs={91001},groundOnly=true}}}},1)
local merged=lib:New({profile="space-merge",environment=data.env})
assert(merged:ResolveNavigationSpace({instanceID=77,uiMapID=91003,x=0,y=0,z=1}).id=="merged-child",
    "Independent categories append spaces by identity instead of overwriting numeric array entries")
local function point(map,x,y,z,fields)
    local p={instanceID=77,uiMapID=map,x=x or 0,y=y or 0,z=z,indoors=false}
    for key,value in pairs(fields or {}) do p[key]=value end
    return p
end
for _,space in ipairs(spaces) do
    local query=point(space.mapIDs[1],0,0,1,{floor=space.floor,accessKey=space.accessKey})
    if space.id=="upper" then query.z=22 end
    if space.id=="shop" then query.x,query.y,query.areaID=55,55,991 end
    local resolved,reason=data:ResolveNavigationSpace(query)
    assert(resolved and resolved.id==space.id and resolved.kind==space.kind and resolved.known,
        "Every declared space kind must resolve by its attested selectors: "..space.id..":"..tostring(reason))
end
local cave=point(91003,0,0,1)
for _,map in ipairs({91012,91013}) do
    local unresolved,why=data:ResolveNavigationSpace(point(map,0,0,1))
    assert(unresolved==nil and why=="navigation_space_identity_unavailable",
        "One possible floor or phase still needs an observation proving its conditional selector")
end
local resolved=data:ResolveNavigationSpace(cave)
assert(resolved.groundOnly and resolved.requiresExit and resolved.transitFaction=="Alliance" and resolved.transitRegion=="city-control",
    "Subspaces inherit movement restrictions and the same controlled transit region")
assert(data:GetNavigationSpace("city").kind=="outdoor")
assert(data:GetPositionRegion(cave)=="cave-room" and not data:CanWalk(cave,point(91001)),
    "A proved cave region never acquires an automatic exit through its UI parent")
assert(data:GetWalkingSpeed(cave,60,7)==7 and data:GetWalkingSpeed(point(91001),60,7)==60,
    "A ground-only physical space overrides false native enclosure without grounding the outdoor parent")
assert(not data:CanWalk(cave,point(91003,1,1,1,{accessKey="other-phase"})), "Known access channels still bound physical navigation")
local unknown=point(91006,0,0,0,{positionSource="unit"})
local space,reason=data:ResolveNavigationSpace(unknown)
assert(not space and reason=="ambiguous_navigation_space" and not data:CanWalk(unknown,point(91001)),
    "Placeholder zero cannot flatten overlapping floors into their common parent")
unknown.floor="upper"
assert(data:ResolveNavigationSpace(unknown).id=="upper", "An explicit known floor can resolve an unavailable native height")
local normalizedFloor=data:NormalizeLocation(point(91006,0,0,22))
assert(normalizedFloor.floor=="upper" and normalizedFloor.region=="upper-room",
    "A uniquely proved bounded floor is carried into normalized arrival and attachment identity")
assert(data:ResolveNavigationSpace(point(91001,55,55,1,{areaID=992})).id=="city",
    "Known conflicting area identity excludes a more specific bound even inside its XY box")
assert(not data:ResolveNavigationSpace(point(91003,0,0,1,{instanceID=78})).known,
    "A matching UI map cannot claim another physical world")
assert(data:ResolveNavigationSpace(point(91009))==nil, "Missing native map metadata stays retryable")
maps[91009]={mapType=6,parentMapID=91001}
space=data:ResolveNavigationSpace(point(91009))
assert(space and not space.known and space.kind=="unknown" and space.requiresExit,
    "An uncovered Orphan reports unknown local topology instead of inheriting the outdoor world")
assert(not data:CanWalk(point(91009),point(91001)), "Uncovered subzones keep their native boundary")
local isolatedMicro=data:ResolveNavigationSpace(point(91011))
assert(not isolatedMicro.known and isolatedMicro.requiresExit and isolatedMicro.kind=="unknown",
    "An explicitly isolated Micro map requires a proved exit even without a native Orphan flag")
assert(data:ResolveNavigationSpace(point(91003,0,0,1,{spaceID="missing"}))==nil,
    "An explicit unavailable logical identity cannot silently become another space")
assert(not lib.ValidateNavigationSpace({id="invalid",kind="cave",worldID=77,mapIDs={}}))
assert(not lib.ValidateNavigationSpace({id="invalid",kind="cave",worldID=77,mapIDs={91003},
    bounds={minX=0,maxX=1,minY=0,maxY=1,minZ=0,maxZ=math.huge}}))
local oldSpaces=data.config.NavigationSpaces
data.config.NavigationSpaces={
    {id="loop-a",kind="cave",worldID=77,mapIDs={91003},parentSpace="loop-b"},
    {id="loop-b",kind="outdoor",worldID=77,mapIDs={91001},parentSpace="loop-a"},
}
local _,cycle=data:ResolveNavigationSpace(cave)
assert(cycle=="cyclic_navigation_space", "Cyclic logical parents never prove an outdoor escape")
data.config.NavigationSpaces=oldSpaces
lib:RegisterData("forever","synthetic-spaces",{config={NavigationSpaces=spaces}},1)
local forever=lib:New({profile="forever",environment=data.env})
assert(forever:ResolveNavigationSpace(cave).kind=="cave" and forever:GetWalkingSpeed(cave,60,7)==7
    and not forever:CanWalk(cave,point(91001)),
    "The same declarative space and mandatory-exit contracts apply to the Forever client namespace")

-- Exact physical passages retain all turns; local missing exits do not become chords.
local start,goal=cave,point(91001,20,5,1)
local function finish(edges)
    local job=data:CreateSearch({start=start,goal=goal,edges=edges,walkSpeed=1,
        canWalk=function(a,b)return data:CanWalk(a,b)end})
    for _=1,1000 do
        local status,result=job:Step(64)
        if status~="planning" then return status,result end
    end
end
assert(finish({})=="no_path", "A logical space requiring an exit cannot invent one when topology is absent")
local entry=point(91003,5,0,1)
local turn=point(91003,5,5,1,{noAutoconnect=true})
local exit=point(91001,10,5,1)
local status,route=finish({
    {kind="passage",id="first-turn",from=entry,to=turn,seconds=5,mandatory=true},
    {kind="passage",id="exit-turn",from=turn,to=exit,seconds=5,mandatory=true},
})
assert(status=="ready" and #route.segments==4 and route.segments[2].id=="first-turn" and route.segments[3].id=="exit-turn",
    "A declared exit connects the cave through both mandatory corners")

-- The native host carries logical space and enforces its speed even if all
-- enclosure/flyability observations claim an outdoor flying environment.
fixture.currentMap,fixture.player=91003,{instanceID=77,x=0,y=0,z=0}
function IsIndoors()return false end
dofile("APR-Core/utils/NavigationZones.lua")
local observed=APR:GetNavigationPlayerPosition()
assert(observed.spaceID=="cave" and observed.spaceKind=="cave" and observed.groundOnly and observed.observedZ==0)
local normalized=data:NormalizeLocation(observed)
assert(normalized.spaceID=="cave" and normalized.groundOnly and normalized.requiresExit)
APR.GAME_VERSIONS={Forever="forever"}
function APR:GetGameVersion()return "retail"end
function APR:NewModule()return {}end
function IsAdvancedFlyableArea()return true end
function IsFlyableArea()return true end
function IsFlying()return true end
function GetUnitSpeed()return 60,7,60 end
function IsMounted()return false end
dofile("APR-Core/features/navigation/Navigation.lua")
local nav=APR.navigation
assert(nav:GetThreshold()==2000 and nav:GetMovementSpeed(10000)==7,
    "A stale flying threshold cannot price an attested underground departure at 60 yards per second")
local movement=nav:GetMovementProfile()
assert(not movement.currentCanSkyriding and not movement.currentCanSteady and movement.currentMode=="ground" and not movement.canFlyAt(cave,"skyriding"))
print("Navigation spaces: all kinds, attested selectors, inherited restrictions, ambiguous floors, missing exits and native host policy")
