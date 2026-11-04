-- A proved walking gate remains continuous when the native map/floor flips.
local fixture=dofile("tests/lua/navigation_fixture.lua")
for map=501,506 do fixture.maps[map]={mapID=map,mapType=3,parentMapID=13} end
local data=fixture:Load({connections={},config={NavigationSpaces={
    {id="outside",kind="outdoor",worldID=8,mapIDs={501},region="outside"},
    {id="cave",kind="cave",worldID=8,mapIDs={502},region="cave",parentSpace="outside",requiresExit=true,groundOnly=true},
    {id="building",kind="building",worldID=8,mapIDs={503},region="building",requiresExit=true},
    {id="lower",kind="floor",worldID=8,mapIDs={504},region="lower",floor="lower",parentSpace="building"},
    {id="upper",kind="floor",worldID=8,mapIDs={505},region="upper",floor="upper",parentSpace="building"},
    {id="foreign",kind="cave",worldID=8,mapIDs={506},region="foreign",requiresExit=true},
}}})
local lib=LibStub("LibAPRNavigation-1.0")
data.env.requestTerrainData=function()return "ready" end
local function p(map,space,x,z,floor,access)
    return {instanceID=8,uiMapID=map,spaceID=space,region=space,x=x,y=0,z=z,floor=floor,accessKey=access}
end
local cave={p(502,"cave",0,10),p(502,"cave",5,12),p(501,"outside",10,14),p(501,"outside",15,16)}
local stairs={p(504,"lower",30,20,"lower"),p(504,"lower",35,23,"lower"),
    p(505,"upper",40,26,"upper"),p(505,"upper",45,29,"upper")}
local phase={p(502,"cave",60,10,nil,"alpha"),p(502,"cave",65,12,nil,"alpha"),p(502,"cave",70,14,nil,"beta")}
local nodes,anchors,edges={},{},{}
local function add(point)
    local node=lib.Copy(point);node.id="point:"..(#nodes+1);nodes[#nodes+1]=node
    anchors[#anchors+1]={node=node.id,minX=node.x-3,maxX=node.x+3,minY=-2,maxY=2,
        minZ=node.z-2,maxZ=node.z+2,mode="ground",bidirectional=true}
    return node
end
for _,path in ipairs({cave,stairs,phase}) do
    local previous
    for _,point in ipairs(path) do
        local node=add(point)
        if previous then edges[#edges+1]={from=previous.id,to=node.id,mode="ground"} end
        previous=node
    end
end
add(p(506,"foreign",8,13.2))
add(p(501,"outside",1000,16))
lib:RegisterTerrainData("retail",8,{format=1,nodes=nodes,anchors=anchors,edges=edges},1,"crossings")
local build=data:CreateTerrainEdgeBuild({start=cave[1],goal=cave[#cave]})
for _=1,10000 do if build:Step(64,100)~="planning" then break end end
assert(build.status=="ready",build.reason)
local function guidance(path,kind)
    local route={totalSeconds=20,segments={{kind=kind or "walk",terrain=true,movementMode="ground",
        from=path[1],to=path[#path],polyline=path,seconds=20}}}
    local hint=data:CreateGuidance(route,{arrivalRange=.1})
    for _=1,1000 do if hint:Step(64,100)~="planning" then break end end
    return hint
end
local function native(point)
    local observed=lib.Copy(point)
    observed.z,observed.observedZ,observed.positionSource,observed.indoors=0,0,"unit",false
    return observed
end
local function follow(hint,samples)
    for _,sample in ipairs(samples) do
        local resolved,reason=data:ResolveTerrainGroundPosition(native(sample),hint)
        assert(resolved and math.abs(resolved.z-sample.z)<.00001 and resolved.observedZ==0,
            "An explicit physical gate must infer its connected ground height: "..tostring(reason))
        local _,state=hint:Update(resolved)
        assert(state=="guiding" or state=="arrived","A current proved cross-space leg cannot deviate: "..state)
    end
end
local hint=guidance(cave)
follow(hint,{cave[1],cave[2],p(502,"cave",7.5,13),p(501,"outside",8,13.2),cave[3],cave[4]})
assert(hint.status=="arrived","Continuous native-zero observations complete a cave-to-parent outdoor route")
hint=guidance(stairs)
follow(hint,{stairs[1],stairs[2],p(505,"upper",38,24.8,"upper"),stairs[3],stairs[4]})
assert(hint.status=="arrived","An explicit stair connector completes when both floor and region change")
hint=guidance(cave)
follow(hint,{cave[1],cave[2]})
local foreign,reason=data:ResolveTerrainGroundPosition(native(p(506,"foreign",8,13.2)),hint)
assert(not foreign and reason=="terrain_height_disconnected","A nearby foreign region cannot borrow the current physical gate")
local wrongPhase=native(p(501,"outside",8,13.2,nil,"other"))
assert(not data:ResolveTerrainGroundPosition(wrongPhase,hint),"A ground gate cannot absorb an unrelated access phase")
local jumped=native(p(501,"outside",1000,16))
assert(not data:ResolveTerrainGroundPosition(jumped,hint),"An outdoor teleport cannot reset bounded walking continuity")
local airborne=native(cave[2]);airborne.airborne=true
assert(select(2,data:ResolveTerrainGroundPosition(airborne,hint))=="aerial_altitude_unavailable",
    "Cross-space continuity preserves the unknown aerial-altitude guard")
hint=guidance(phase)
follow(hint,{phase[1]})
local alpha=data:ResolveTerrainGroundPosition(native(phase[2]),hint)
assert(alpha and alpha.z==12,"The valid approach to a phase boundary retains its own ground height")
assert(select(2,hint:Update(alpha))=="deviated","A terrain polyline cannot start a cross-phase ground leg")
assert(not data:ResolveTerrainGroundPosition(native(phase[3]),hint),
    "A terrain polyline does not make a cross-phase ground leg physically continuous")
local _,state=hint:Update(phase[3])
assert(state=="deviated","Even known native height cannot finish an invalid cross-phase ground leg")
hint=guidance(cave)
follow(hint,{cave[1],cave[2]})
local source=hint.segments[1].source
source.kind="portal"
assert(not data:ResolveTerrainGroundPosition(native(p(501,"outside",8,13.2)),hint),
    "A localized teleport action cannot inherit a walking-height proof")
print("Terrain height crossings: cave outdoors, stair floors, current contexts, bounded progress and rejected phase/teleport jumps")
