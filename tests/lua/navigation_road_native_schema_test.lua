-- Authorable APR data uses native world identities and named declarations.
local fixture=dofile("tests/lua/navigation_fixture.lua")
fixture.profile="forever"
fixture:Load({})
local lib=LibStub("LibAPRNavigation-1.0")
local function point(x,y,z) return {instanceID=8,x=x,y=y,z=z} end
local function finish(job)
    for _=1,20000 do
        local status,result,reason=job:Step(3,1)
        assert((job.workLastStep or 0)<=3)
        if status~="planning" then return status,result,reason end
    end
    error("native road compilation did not finish")
end
local function near(a,b) assert(math.abs(a-b)<0.00001,tostring(a).." ~= "..tostring(b)) end
local definition={id="invented-world",instanceID=8,kind="world",sections={
    {id="invented-world-roads",kind="road",nodes={
        {id="invented-west-junction",x=0,y=0},
        {id="invented-east-junction",x=10,y=0},
    },edges={
        {id="invented-river-road",from="invented-west-junction",to="invented-east-junction",kind="road",
            points={{x=0,y=0},{x=0,y=20},{x=10,y=20},{x=10,y=0}}},
    }},
}}
assert(lib:RegisterRoadNetwork("native-fixture",definition,1))
local instance=lib:New({profile="native-fixture",environment={}})
assert(instance:GetRoadData().format==2 and instance:HasRoadData(point(0,0),point(10,0)))
local status,result=finish(instance:CreateRoadRoute({start=point(0,0),goal=point(10,0),walkSpeed=2}))
assert(status=="ready");near(result.totalSeconds,25)
assert(#result.polyline==4 and result.polyline[2].y==20)
assert(result.polyline[2].roadLevel=="invented-world" and result.polyline[2].instanceID==8)
definition.sections[1].edges[1].points[2].y=200
status,result=finish(instance:CreateRoadRoute({start=point(0,0),goal=point(10,0),walkSpeed=2}))
assert(status=="ready");near(result.totalSeconds,25)
assert(not instance:HasRoadData(point(0,0),{instanceID=10008,x=10,y=0}),"No private pseudo-world identity can leak into routing")

-- Known shape heights affect cost; a directed authored edge cannot be reversed.
lib:RegisterRoadNetwork("native-fixture",{id="invented-world",instanceID=8,kind="world",sections={
    {id="invented-world-stairs",kind="building",nodes={
        {id="invented-ground",x=0,y=0,z=0},{id="invented-landing",x=10,y=10,z=0},
    },edges={{id="invented-up-down-stairs",from="invented-ground",to="invented-landing",kind="stairs",bidirectional=false,
        points={{x=0,y=0,z=0},{x=0,y=10,z=10},{x=10,y=10,z=0}}}}},
}},2)
status,result=finish(instance:CreateRoadRoute({start=point(0,0,0),goal=point(10,10,0),walkSpeed=1,roadAttachmentRadius=0}))
assert(status=="ready");near(result.totalSeconds,2*math.sqrt(200))
assert(result.polyline[2].z==10,"A known intermediate landing height remains explicit")
status=finish(instance:CreateRoadRoute({start=point(10,10,0),goal=point(0,0,0),walkSpeed=1,roadAttachmentRadius=0}))
assert(status~="ready","A directed road never gains an implicit return")

-- Collision masks are independent declarations with named origins and fields.
local rows={};for i=1,10 do rows[i]={{from=1,to=10,state="open"}} end
assert(lib:RegisterRoadCollision("mask-fixture",{id="invented-ground-mask",originX=0,originY=0,
    cellSize=1,width=10,height=10,rows=rows,
    blockedRuns={{row=2,column=4,count=1}}},1))
lib:RegisterRoadNetwork("mask-fixture",{id="invented-world",instanceID=8,kind="world",
    collision={base="invented-ground-mask"},sections={{id="invented-road",kind="road",nodes={{id="invented-node",x=-1,y=-1}},edges={}}}},1)
local mask=lib:New({profile="mask-fixture",environment={}})
assert(mask:RoadSegmentCost(point(-1.5,-1.5),point(-1.5,-8.5))==nil)
local cost=mask:RoadSegmentCost(point(-3.5,-1.5),point(-3.5,-8.5));near(cost,7)
rows[4]={{from=1,to=10,state="blocked"}}
cost=mask:RoadSegmentCost(point(-3.5,-1.5),point(-3.5,-8.5));near(cost,7)
local before=mask:GetRoadRevision()
local malformed={id="bad-network",instanceID=8,kind="world",sections={},unusedPicture="art"}
assert(not pcall(lib.RegisterRoadNetwork,lib,"mask-fixture",malformed,1))
assert(mask:GetRoadRevision()==before and mask:GetRoadData().networks[malformed.id]==nil,
    "Unsupported data cannot pollute the authoritative registry")
lib:RegisterRoadNetwork("mask-fixture",{id="invented-world",instanceID=8,kind="world",collision={base="invented-ground-mask"},
    sections={},walls={{id="invented-fence",points={{x=-5,y=0},{x=-5,y=-10}}}}},2)
assert(mask:RoadSegmentCost(point(-3.5,-1.5),point(-8.5,-1.5))==nil)
lib:RegisterRoadNetwork("mask-fixture",{id="invented-world",instanceID=8,kind="world",collision={base="invented-ground-mask"},
    sections={},walls={}},3)
cost=mask:RoadSegmentCost(point(-3.5,-1.5),point(-8.5,-1.5));near(cost,5)

-- Duplicate names are rejected incrementally, before any route can publish.
lib:RegisterRoadNetwork("invalid-native",{id="invented-world",instanceID=8,kind="world",sections={
    {id="invented-duplicate",kind="road",nodes={{id="same-node",x=0,y=0},{id="same-node",x=1,y=1}},edges={}},
}},1)
local bad=lib:New({profile="invalid-native",environment={}})
status=finish(bad:CreateRoadRoute({start=point(0,0),goal=point(1,1)}))
assert(status=="invalid_data")

-- Native world zero and an unknown client height retain their real context.
lib:RegisterRoadNetwork("zero-world",{id="invented-mainland",instanceID=0,uiMapID=701,kind="world",sections={
    {id="invented-mainland-road",kind="road",nodes={{id="invented-zero-origin",x=0,y=0},{id="invented-zero-goal",x=10,y=10}},
        edges={{id="invented-zero-road",from="invented-zero-origin",to="invented-zero-goal",kind="road",
            points={{x=0,y=0},{x=0,y=10},{x=10,y=10}}}}},
}},1)
local mainland=lib:New({profile="zero-world",environment={}})
local origin={instanceID=0,uiMapID=701,x=0,y=0,z=0,positionSource="unit",accessKey="invented-room"}
local goal={instanceID=0,uiMapID=701,x=10,y=10,accessKey="invented-room"}
assert(mainland:HasRoadData(origin,goal))
status,result=finish(mainland:CreateRoadRoute({start=origin,goal=goal,walkSpeed=1,roadAttachmentRadius=0}))
assert(status=="ready");near(result.totalSeconds,20)
assert(result.segments[1].from==origin and result.segments[1].to==goal)
assert(result.polyline[2].instanceID==0 and result.polyline[2].z==nil and result.polyline[2].accessKey=="invented-room")
lib:RegisterRoadNetwork("zero-world",{id="invented-underground",instanceID=0,uiMapID=702,kind="city",sections={}},1)
assert(not mainland:HasRoadData(origin,{instanceID=0,uiMapID=702,x=10,y=10}),"City floors remain a separate named network")

-- LibStub may retain an older embedded registry during an in-session upgrade.
local legacy={format=1,roads={[8]={n={0,0,10,0},e={{1,2,10,0,0,0,10,0}}}}}
assert(lib:RegisterRoadData("mixed-fixture",legacy,100))
local mixed=lib:New({profile="mixed-fixture",environment={}})
local stale=mixed:CreateRoadRoute({start=point(0,0),goal=point(10,0)})
assert(lib:RegisterRoadNetwork("mixed-fixture",{id="invented-upgraded-world",instanceID=8,kind="world",sections={
    {id="invented-upgraded-road",kind="road",nodes={{id="upgraded-origin",x=0,y=0},{id="upgraded-goal",x=10,y=0}},
        edges={{id="upgraded-road",from="upgraded-origin",to="upgraded-goal",points={{x=0,y=0},{x=10,y=0}}}}},
}},1))
assert(stale:Step(10,1)=="cancelled" and mixed:GetRoadData().format==2)
assert(not lib:RegisterRoadData("mixed-fixture",legacy,1000),"Legacy registrations cannot downgrade native catalogues")
status,result=finish(mixed:CreateRoadRoute({start=point(0,0),goal=point(10,0),walkSpeed=1}))
assert(status=="ready");near(result.totalSeconds,10)
print("Native road schema: readable identities, authored points/heights, directed edges, independent masks and invalid-data isolation passed")
