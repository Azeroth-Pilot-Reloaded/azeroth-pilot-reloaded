local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
local function Graph()
    return {complete=true,requirements=F.Require('global'),zones={{id='hall',requirements=F.Require('zone')}},
        nodes={{id='cave',requirements=F.Require('from')},{id='town',zone='hall',requirements=F.Require('node')},
            {id='goal',requirements=F.Require('to')}},edges={
        {id='short',from='cave',to='town',seconds=1,requirements=F.Require('passage')},
        {id='finish',from='town',to='goal',seconds=2},{id='detour',from='cave',to='goal',seconds=13}}}
end
local function Observation()
    return {sequence=1,worldState='ready',access={global=true,zone=true,from=true,node=true,to=true,passage=true}}
end
local r=F.Result(F.Planner(Graph(),Observation()))
assert(r.status=='complete' and r.estimatedSeconds==3 and r.segments[1].edgeId=='short')
for _,key in ipairs({'zone','node','passage'})do
    for _,known in ipairs({false,true})do
        local observation=Observation();observation.access[key]=known and nil or false
        -- Assign nil explicitly: Lua's and/or cannot represent a nil branch.
        if known then observation.access[key]=nil end
        r=F.Result(F.Planner(Graph(),observation))
        assert(r.status=='complete' and r.estimatedSeconds==13,'Known usable detour precedes denied/unknown shortcut')
    end
end
for _,key in ipairs({'global','from','to'})do
    local o=Observation();o.access[key]=false
    assert(F.Result(F.Planner(Graph(),o)).status=='no_path','Required endpoint/global false blocks request')
    o.access[key]=nil
    assert(F.Result(F.Planner(Graph(),o)).status=='unknown','Required endpoint/global missing proof holds request')
end
local o=Observation();o.access.zone=nil;o.access.node=false
r=F.Result(F.Planner(Graph(),o),{from='cave',to='goal',via={'town'}})
assert(r.status=='no_path','A false node conjunct outranks its unknown zone')
o=Observation();o.access.node=nil
r=F.Result(F.Planner(Graph(),o),{from='cave',to='goal',via={'town'}})
assert(r.status=='unknown' and r.objective.via[1]=='town')
local graph={complete=true,nodes={'cave','goal'},edges={{id='walk',from='cave',to='goal',seconds=4}}}
for i=1,5000 do graph.nodes[#graph.nodes+1]={id='room'..i,requirements={phase='present'}}end
local p=F.Planner(graph,{sequence=1,worldState='ready',phase='present'})
assert(F.Result(p).estimatedSeconds==4 and p.conditions.bindingCount==1,'Identical requirements share a binding')
-- A stale observation cannot restore an old useful result or finish an old job.
p=F.Planner(F.Graph(),{sequence=1,worldState='ready',quests={[711]=true}})
r=F.Result(p);local job=p:Plan({from='cave',to='goal'});local oldToken=r.conditionToken
assert(p:MarkConditionsDirty({quests={[711]=true}}))
assert(not p:IsCurrent(r) and job:Step(1).status=='stale')
local changed,why=p:ObserveConditions({sequence=1,worldState='ready',quests={[711]=true}})
assert(changed==false and why=='stale_observation' and not p.conditions:IsCurrent(oldToken))
local _,_,recovered=p:ObserveConditions({sequence=2,worldState='ready',quests={[711]=true}})
assert(recovered and F.Result(p).estimatedSeconds==3 and not p:IsCurrent(r))
