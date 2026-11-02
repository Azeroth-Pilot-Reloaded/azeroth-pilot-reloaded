-- Entering a floor inside a building is not leaving its containing structure.
local fixture=dofile("tests/lua/navigation_fixture.lua")
fixture.maps[71001]={mapType=3,parentMapID=13}
fixture.maps[71002]={mapType=3,parentMapID=13}
local data=fixture:Load({config={NavigationSpaces={
    {id="city",kind="outdoor",worldID=8,mapIDs={71002}},
    {id="building",kind="building",worldID=8,mapIDs={71001},parentSpace="city",requiresExit=true,groundOnly=true},
    {id="floor",kind="floor",worldID=8,mapIDs={71001},parentSpace="building",floor="lower",
        bounds={minX=10,maxX=20,minY=-1,maxY=1,minZ=-1,maxZ=1}},
    {id="room",kind="building",worldID=8,mapIDs={71001},parentSpace="floor",floor="lower",
        bounds={minX=12,maxX=14,minY=-1,maxY=1,minZ=-1,maxZ=1}},
}},connections={}})
assert(type(data.IsNavigationSpaceDescendant)=="function","Shared physical containment must be available to local exit checks")
local function point(x,space,floor,access)
    return {instanceID=8,uiMapID=space=="city" and 71002 or 71001,x=x,y=0,z=0,
        spaceID=space,floor=floor,accessKey=access}
end
local start,child,deep,outside,goal=point(0,"building"),point(10,"floor","lower"),point(12,"room","lower"),point(25,"city"),point(100,"city")
assert(data:IsNavigationSpaceDescendant("floor","building") and data:IsNavigationSpaceDescendant(data:ResolveNavigationSpace(deep),"building"))
assert(not data:IsNavigationSpaceDescendant("building","building") and not data:IsNavigationSpaceDescendant("building","floor")
    and not data:IsNavigationSpaceDescendant("city","building") and not data:IsNavigationSpaceDescendant("missing","building"))
local function request(target,edges)
    return {start=start,goal=target,edgeGroups={edges or {}},route=true,walkSpeed=1,
        canWalk=function(a,b)return data:CanWalk(a,b)end}
end
local function finish(job)
    for _=1,10000 do
        local status,metadata=job:Step(1,100)
        if status~="planning" then return status,metadata end
    end
    error("Synthetic hierarchical exit check did not finish")
end
for _,target in ipairs({child,deep})do
    local status,metadata=finish(data:CreateLocalExitCheck(request(target)))
    assert(status=="ready" and not metadata.applicable and not metadata.exitRoute,
        "Going deeper inside the origin bypasses the outer-container exit layer")
end
local down={kind="passage",from=start,to=child,seconds=10}
local status,metadata=finish(data:CreateLocalExitCheck(request(goal,{down})))
assert(status=="missing_data" and not metadata.exitRoute,
    "A reachable child floor cannot masquerade as the building's outdoor exit")
local up={kind="passage",from=child,to=outside,seconds=15}
status,metadata=finish(data:CreateLocalExitCheck(request(goal,{down,up})))
assert(status=="ready" and metadata.exitRoute.exitSpace=="city" and #metadata.exitRoute.segments==2
    and metadata.exitRoute.segments[2].to.x==25,
    "The prefix must continue through the real parent/outdoor connector after reaching a descendant")
start=child
status,metadata=finish(data:CreateLocalExitCheck(request(deep)))
assert(status=="ready" and not metadata.applicable,"A room on the same floor is contained by its origin floor")
status,metadata=finish(data:CreateLocalExitCheck(request(point(0,"building"))))
assert(status=="missing_data","Leaving the origin floor for its parent still requires a connector")
print("Exit containment: descendants, nested rooms, floor boundaries and real outdoor prefixes")
