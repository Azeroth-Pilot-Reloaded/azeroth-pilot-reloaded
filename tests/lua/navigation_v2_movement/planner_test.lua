local F=dofile('tests/lua/navigation_v2_movement/fixture.lua')
local E,G=F.Edge,F.Graph
local graph=G({'s','g'},{E('foot','s','g','walk',70),E('ride','s','g','mount',112)})
F.Path(F.Plan(graph),{'foot'},10) -- 10 < 3 + 112/11.2 = 13.
graph.edges[1].movement.distance=140
F.Path(F.Plan(graph),{'ride'},13) -- 13 < 140/7 = 20.
for _,observation in ipairs({
    {level=39,mountOwned=true,mountUsable=true},
    {level=40,mountOwned=false,mountUsable=true},
    {level=40,mountOwned=true,mountUsable=false},
    {level=40,mountOwned=nil,mountUsable=true},
    {level=40,mountOwned=true,mountUsable=nil},
}) do
    observation.initialMode,observation.canMountHere='walk',true
    F.Path(F.Plan(graph,observation),{'foot'},20)
end
local onlyMount=G({'s','g'},{E('ride','s','g','mount',112)})
assert(F.Plan(onlyMount,{level=39,mountOwned=true,mountUsable=true,initialMode='walk'}).status=='no_path')
assert(F.Plan(onlyMount,{level=40,mountUsable=true,initialMode='walk',canMountHere=true}).status=='unknown')
assert(F.Plan(onlyMount,nil,{mountSpeed=false}).status=='unknown')
assert(F.Plan(onlyMount,nil,{mountSeconds=false}).status=='unknown')
assert(F.Plan(graph,{level=40,mountOwned=true,mountUsable=true}).status=='unknown')

-- A cave requires walking. Riding resumes only at the exterior exit.
graph=G({'s','mouth','exit','g'},{
    E('approach','s','mouth','mount',112),E('cave','mouth','exit','walk',14),
    E('resume','exit','g','mount',112),E('outside','s','g','mount',336),
})
F.Path(F.Plan(graph),{'approach','cave','resume'},28) -- 13 + 2 + 13 < 3 + 30.
graph.edges[4].movement.distance=324.8
F.Path(F.Plan(graph,nil,{mountSeconds=8}),{'outside'},37)
graph.edges[3].movement.canMount='unavailable'
F.Path(F.Plan(graph),{'outside'},32)
graph.edges[4].access='unavailable'
assert(F.Plan(graph).status=='no_path')
graph.edges[3].movement.canMount='unknown'
assert(F.Plan(graph).status=='unknown')

-- Arrival state cannot be dominated by a cheaper arrival in another mode.
graph=G({'s','join','g'},{E('walk-in','s','join','walk',7),
    E('ride-in','s','join','mount',11.2),E('ride-on','join','g','mount',112,'available','unavailable')})
F.Path(F.Plan(graph),{'ride-in','ride-on'},14)

-- Swimming beats the land detour only under the appropriate profile.
graph=G({'s','shore','g'},{E('lake','s','shore','swim',47),E('exit','shore','g','walk',7),
    E('land','s','g','walk',105),E('bridle','s','g','mount',156.8)})
F.Path(F.Plan(graph),{'lake','exit'},12.5) -- 0.75 + 10 + 0.75 + 1 < 15 and 17.
F.Path(F.Plan(graph,nil,{swimSpeed=2}),{'land'},15)
F.Path(F.Plan(graph,nil,{swimSpeed=2,mountSpeed=15.68}),{'bridle'},13)

-- Captured inputs and invalidated/cancelled jobs use the planner lifecycle.
local planner,profile=F.New(graph)
local job=planner:Plan({from='s',to='g'})
assert(job:Step(1).status=='running')
planner:Invalidate()
assert(F.Finish(job).status=='stale')
job=planner:Plan({from='s',to='g'})
assert(job:Cancel().status=='cancelled')
assert(job:Step(1).status=='cancelled')
local fresh=F.Finish(planner:Plan({from='s',to='g'}))
assert(planner:IsCurrent(fresh))
planner:Invalidate()
assert(not planner:IsCurrent(fresh))
