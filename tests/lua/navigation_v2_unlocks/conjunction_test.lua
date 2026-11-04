local F=dofile('tests/lua/navigation_v2_unlocks/fixture.lua')
local function Graph(second,detour)
    local graph=F.Graph(detour)
    for _,edge in ipairs(graph.edges)do
        if edge.requirements then
            edge.requirements.access[2]={key='second-proof',allowed=true}
            edge.requirements.quests={{questID=811,completed=false}}
            edge.requirements.world=7
            edge.requirements.phase='present'
        end
    end
    graph.edges[3].requirements.access={{key='second-proof',allowed=true},{key='garden-open',allowed=true}}
    return graph
end
local function Observation(sequence,second)
    return {sequence=sequence,worldState='ready',world=7,phase='present',quests={[811]=false},
        access={['garden-open']=false,['second-proof']=second}}
end
local graphSource=Graph()
local p=F.Planner(graphSource,{conditionObservation=Observation(1,true)})
local r=F.Result(p)
assert(r.status=='complete' and r.unlock and r.estimatedSeconds==2,
    'A simple denied fact inside otherwise satisfied conjunctions must authorize the same approach')
assert(p.conditions.snapshot.access['garden-open']==false,'A refusal proof cannot open the observed gate')
local bindingCount,conditionRevision=p.conditions.bindingCount,p.conditions.revision
assert(bindingCount==2,'Editor fact order does not multiply semantic bindings')
graphSource.edges[2].requirements.access[2].allowed=false
assert(F.Result(p).unlock,'Prepared fact metadata must not retain mutable authored tables')
for sequence,second in ipairs({false,true})do
    local revision=p.revision
    assert(p:ObserveConditions(Observation(sequence+1,second))==true,
        'Supporting evidence changes retire unlock proof even while aggregate access stays denied')
    r=F.Result(p)
    if second then assert(r.unlock and r.estimatedSeconds==2)
    else assert(r.status=='no_path' and not r.unlock,'An independent false sibling prevents a simple unlock')end
    assert(p.conditions.bindingCount==bindingCount and p.conditions.revision==conditionRevision,
        'Semantic bindings and aggregate Conditions tokens remain unchanged')
    assert(p.revision==revision+1,'The planner separately owns unlock proof invalidation')
end
assert(p:ObserveConditions(Observation(4,nil))==true)
r=F.Result(p)
assert(r.status=='no_path' and not r.unlock and r.diagnostics.unlockReason=='absence_unproven',
    'A known false fact cannot hide an unknown sibling in the refusal certificate')
assert(p:ObserveConditions(Observation(5,true))==true)
assert(F.Result(p).unlock)
local changed=p:MarkConditionsDirty({access={['second-proof']=true}});assert(changed)
local held=p:Plan({from='cave',to='goal'})
r=F.Base.Finish(held,1);assert(not r.unlock)
p:ObserveConditions(Observation(6,true));assert(F.Result(p).unlock)
local snapshot=Observation(7,true)
p:ObserveConditions(snapshot);snapshot.access['second-proof']=false
assert(F.Result(p).unlock,'Caller snapshot edits cannot mutate accepted proof or its cache')
local accepted,reason=p:ObserveConditions(Observation(6,false))
assert(accepted==false and reason=='stale_observation' and F.Result(p).unlock)
for _,second in ipairs({true,false})do
    r=F.Result(F.Planner(Graph(nil,13),{conditionObservation=Observation(1,second)}))
    assert(r.status=='complete' and r.estimatedSeconds==13 and not r.unlock,'A usable normal detour always wins')
end
-- The same independent denial in another requirement scope cannot be hidden.
local graph=Graph()
graph.nodes[3]={id='town',requirements={access={{key='third-proof',allowed=true}}}}
local observation=Observation(1,true);observation.access['third-proof']=false
r=F.Result(F.Planner(graph,{conditionObservation=observation}))
assert(r.status=='no_path' and not r.unlock,'A separate node requirement still blocks this passage independently')
for _,raw in ipairs({'unavailable','unknown'})do
    graph=Graph()
    graph.edges[2].access,graph.edges[3].access=raw,raw
    r=F.Result(F.Planner(graph,{conditionObservation=Observation(1,true)}))
    assert(not r.unlock,'A separate authored access denial/unknown is not repaired by the prerequisite')
end
-- Positive completed-quest facts share the same semantics as access facts.
graph=F.Graph()
for _,edge in ipairs(graph.edges)do
    if edge.requirements then edge.requirements={quests={{questID=912,completed=true}},
        access={{key='second-proof',allowed=true}}}end
end
local entry=F.Entry();entry.opens={quests={{questID=912,completed=true}}}
r=F.Result(F.Planner(graph,{unlocks={entry},conditionObservation={sequence=1,worldState='ready',
    quests={[912]=false},access={['second-proof']=true}}}))
assert(r.unlock and r.estimatedSeconds==2)
