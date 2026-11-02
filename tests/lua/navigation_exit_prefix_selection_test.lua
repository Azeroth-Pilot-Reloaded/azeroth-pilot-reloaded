-- An enclosed sibling is a corridor candidate, not the outside of its neighbor.
local fixture=dofile("tests/lua/navigation_fixture.lua")
for map=601,610 do fixture.maps[map]={mapID=map,mapType=3,parentMapID=13} end
local data=fixture:Load({connections={},config={NavigationSpaces={
    {id="outside",kind="outdoor",worldID=8,mapIDs={601}},
    {id="first",kind="cave",worldID=8,mapIDs={602},parentSpace="outside",requiresExit=true},
    {id="second",kind="cave",worldID=8,mapIDs={603},parentSpace="outside",requiresExit=true},
    {id="building",kind="building",worldID=8,mapIDs={604},parentSpace="outside",requiresExit=true},
    {id="floor",kind="floor",worldID=8,mapIDs={605},parentSpace="building",floor="lower"},
    {id="uncertain",kind="unknown",worldID=8,mapIDs={606}},
    {id="open-subzone",kind="subzone",worldID=8,mapIDs={607}},
    {id="second-room",kind="building",worldID=8,mapIDs={609},parentSpace="second"},
    {id="closed-subzone",kind="subzone",worldID=8,mapIDs={610},requiresExit=true},
}}})
local function point(map,space,x,y,fields)
    local value={instanceID=8,uiMapID=map,spaceID=space,x=x,y=y,z=1,noAutoconnect=true}
    for key,item in pairs(fields or {}) do value[key]=item end
    return value
end
local start=point(602,"first",0,0)
local sibling=point(603,"second",1,0)
local cornerOne,cornerTwo=point(602,"first",0,10),point(602,"first",10,10)
local outside,goal=point(601,"outside",20,10),point(601,"outside",100,100)
local function edge(from,to,seconds,kind)
    return {kind=kind or "passage",from=from,to=to,seconds=seconds,mandatory=true}
end
local deadend={edge(start,sibling,1),edge(sibling,start,1)}
local corridor={deadend[1],deadend[2],edge(start,cornerOne,10),edge(cornerOne,cornerTwo,10),edge(cornerTwo,outside,10)}
local function check(target,edges,route,origin)
    local job=data:CreateLocalExitCheck({start=origin or start,goal=target,edges=edges,
        route=route,walkSpeed=1,canWalk=function()return false end})
    for _=1,10000 do
        local status,metadata=job:Step(1,100)
        assert(job.workLastStep<=1,"Prefix selection remains incremental")
        if status~="planning" then return status,metadata end
    end
    error("Synthetic exit prefix selection did not finish")
end
local status,metadata=check(goal,corridor,true)
local prefix=metadata.exitRoute
assert(status=="ready" and prefix and prefix.exitSpace=="outside" and prefix.totalSeconds==30,
    "The nearest enclosed sibling cannot be published as the origin's outdoor exit")
assert(#prefix.segments==3 and prefix.segments[1].to==cornerOne and prefix.segments[2].to==cornerTwo,
    "The real outdoor prefix preserves both mandatory corners")
for _,route in ipairs({false,true}) do
    status,metadata=check(goal,deadend,route)
    assert(status=="missing_data" and metadata.applicable and not metadata.exitRoute,
        "A cave-to-cave return loop cannot prove feasibility or a publishable outside prefix")
    status,metadata=check(sibling,deadend,route)
    assert(status=="ready" and (not route or metadata.exitRoute.exitSpace=="second"),
        "A destination inside the connected sibling may use its actual physical entry")
end
local nested=point(609,"second-room",2,0)
status,metadata=check(sibling,{edge(start,nested,2)},true)
assert(status=="ready" and metadata.exitRoute.exitSpace=="second-room",
    "The explicit destination enclosure may be reached through one of its contained rooms")
local onward=point(601,"outside",30,0)
status,metadata=check(goal,{deadend[1],edge(sibling,onward,2)},true)
assert(status=="ready" and metadata.exitRoute.totalSeconds==3 and #metadata.exitRoute.segments==2,
    "The search may traverse an enclosed sibling to reach a genuine outdoor connector")
local floor=point(605,"floor",0,0,{floor="lower"})
local building=point(604,"building",5,0)
status,metadata=check(goal,{edge(floor,building,5)},true,floor)
assert(status=="ready" and metadata.exitRoute.exitSpace=="building",
    "Leaving a floor for its containing building is a valid local prefix")
local unknown=point(606,"uncertain",1,0)
assert(check(goal,{edge(start,unknown,1)},true)=="missing_data",
    "An unclassified sibling does not prove an unconstrained outside space")
local subzone=point(607,"open-subzone",1,0)
assert(check(goal,{edge(start,subzone,1)},true)=="ready",
    "An ordinary open subzone needs no explicit false requiresExit declaration")
local closed=point(610,"closed-subzone",1,0)
assert(check(goal,{edge(start,closed,1)},true)=="missing_data",
    "A subzone that itself requires a known exit cannot impersonate open outdoors")
local native=point(608,nil,1,0)
local nativeSpace=data:ResolveNavigationSpace(native)
assert(nativeSpace.kind=="outdoor" and nativeSpace.known==false)
assert(check(goal,{edge(start,native,1)},true)=="ready",
    "A native outdoors fallback remains a valid physical outside")
local alpha=point(602,"first",0,0,{accessKey="alpha"})
local beta=point(602,"first",1,0,{accessKey="beta"})
local gamma=point(602,"first",2,0,{accessKey="gamma"})
assert(check(beta,{edge(alpha,gamma,1,"portal")},true,alpha)=="missing_data",
    "A different phase from the objective cannot impersonate the requested phase crossing")
status,metadata=check(beta,{edge(alpha,beta,1,"portal")},true,alpha)
assert(status=="ready" and metadata.exitRoute.segments[1].to.accessKey=="beta",
    "An explicit localized portal may reach the objective's known different phase")
local same=check(start,deadend,true)
assert(same=="ready","An objective still contained by its origin needs no outside prefix")
print("Exit prefixes: real outside, enclosed siblings, goal containment, ancestors and phase-aware localized portals")
