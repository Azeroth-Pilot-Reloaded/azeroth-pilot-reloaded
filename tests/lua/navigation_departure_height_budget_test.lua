-- Missing native departure height cannot be repaired by relaxing distant gates.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({connections={}})
local lib=LibStub("LibAPRNavigation-1.0")
data.env.requestTerrainData=function() return "ready" end
local scope={id="stacked-room",bounds={minX=-5,maxX=5,minY=-5,maxY=5,minZ=1,maxZ=40}}
local raw={format=1,scope=scope,nodes={},edges={},anchors={}}
local function point(world,x,z,native)
    return data:NormalizeLocation({instanceID=world,uiMapID=world==8 and 501 or 502,x=x,y=0,z=z,
        positionSource=native and "unit" or nil,observedZ=native and z or nil,indoors=false})
end
for i,z in ipairs({10,30}) do
    raw.nodes[i]={id=i,x=0,y=0,z=z,uiMapID=501}
    raw.anchors[i]={node=i,minX=-1,maxX=1,minY=-1,maxY=1,minZ=z-1,maxZ=z+1,bidirectional=true}
end
lib:RegisterTerrainData("retail",8,raw,1,"room")
local start,goal=point(8,0,0,true),point(9,100,0)
local doorway=point(8,0,10)
local blocked={}
for i=1,500 do
    blocked[i]={id="locked-"..i,kind="portal",from=doorway,to=goal,seconds=10,
        blockedRequirements={quest=i}}
end
local available,escape,relaxed,searches,probeCalls=false,false,0,0,0
data.CreateEdgeBuild=function()
    local edges={}
    if available then edges[#edges+1]={id="open",kind="portal",from=doorway,to=goal,seconds=10} end
    if escape then edges[#edges+1]={id="escape",kind="spell",sourceFree=true,from=doorway,to=goal,seconds=3} end
    return {Step=function()return "ready",edges,{resources={},blockedEdges=blocked}end}
end
local actualBuild=data.CreateTerrainEdgeBuild
local rewrite
data.CreateTerrainEdgeBuild=function(self,request)
    local build=actualBuild(self,request)
    if not rewrite then return build end
    return {Step=function(_,operations,milliseconds)
        local status,edges,coverage=build:Step(operations,milliseconds)
        if status~="planning" then rewrite(coverage) end
        return status,edges,coverage
    end,Cancel=function()build:Cancel()end}
end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local probe
local function plan()
    relaxed,searches,probeCalls=0,0,0
    local job=APR.NavigationPlanner:Create({data=data,start=start,goal=goal,walkSpeed=7,
        engine={CreateSearch=function(_,request)
            searches=searches+1
            if request.edgeGroups[3]==blocked then relaxed=relaxed+1 end
            return lib.Engine:CreateSearch(request)
        end},taxiData={BuildEdges=function()return {}end,CreateProbeSearch=function()
            probeCalls=probeCalls+1
            return {Step=function()return "ready",probe end}
        end},probeSegments=function(value)return {value}end,
        canWalk=function(a,b)return data:CanWalk(a,b)end,prepareSegment=function(segment)return segment end})
    for slice=1,20000 do
        if job:Step(32,1)~="planning" then return job,slice end
    end
    error("Departure height fixture exceeded its finite planning bound")
end
local job=plan()
assert(job.status=="no_path" and job.waitingData and job.terrainReason=="ambiguous_terrain_surface")
assert(relaxed==0 and searches==1 and probeCalls==1,
    "After real alternatives and taxi consultation, unresolved departure height skips the relaxed catalogue")

escape=true
job=plan()
assert(job.status=="ready" and job.result.totalSeconds==3 and job.result.queue[1].id=="escape",
    "A usable personal escape remains available without inventing a ground floor")
escape=false
probe={id="ask-master",kind="verify_taxi",from=start,to=start,seconds=0}
job=plan()
assert(job.status=="ready" and job.result.queue[1].id=="ask-master" and probeCalls==1,
    "A real taxi consultation retains its chance before the departure-height stop")
probe=nil

-- Equivalent snapshots work, but an unrelated floor/world/endpoint does not.
rewrite=function(coverage)
    local copy={};for key,value in pairs(start)do copy[key]=value end
    coverage.missing[1].position=copy
end
job=plan()
assert(job.status=="no_path" and job.terrainReason=="ambiguous_terrain_surface" and relaxed==0)
rewrite=function(coverage)
    table.insert(coverage.missing,1,{position=goal,reason="terrain_source_unavailable"})
end
job=plan()
assert(job.terrainReason=="ambiguous_terrain_surface" and relaxed==0,
    "An unrelated first missing source does not hide the exact native departure blocker")
for _,change in ipairs({{floor=2},{instanceID=9},{x=1},{accessKey="foreign"},{positionSource="authored"}})do
    rewrite=function(coverage)
        local copy={};for key,value in pairs(start)do copy[key]=value end
        for key,value in pairs(change)do copy[key]=value end
        coverage.missing[1].position=copy
    end
    job=plan()
    assert(relaxed>0 and job.terrainReason==nil,
        "Missing height at a different observation cannot suppress gate diagnostics")
end
rewrite=function(coverage)coverage.missing[1].reason="terrain_anchor_missing"end
job=plan()
assert(relaxed>0 and job.terrainReason==nil,"An ordinary source/attachment gap keeps gate diagnostics")
for _,reason in ipairs({"terrain_height_unavailable","aerial_altitude_unavailable","terrain_altitude_missing"})do
    rewrite=function(coverage)coverage.missing[1].reason=reason end
    job=plan()
    assert(job.status=="no_path" and job.waitingData and job.terrainReason==reason and relaxed==0)
end

rewrite=nil
available=true
start=point(8,0,10,true)
lib:RegisterTerrainData("retail",8,raw,2,"room")
job=plan()
assert(job.status=="ready" and job.result.totalSeconds==10 and job.terrainReason==nil,
    "Fresh native height and geometry allow the actual physical doorway on a new request")
print("Departure height: bounded diagnostics, personal/taxi alternatives, exact observations and recovered native proof passed")
