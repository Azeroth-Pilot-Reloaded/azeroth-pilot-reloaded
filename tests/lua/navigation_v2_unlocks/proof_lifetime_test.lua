local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
local function Graph()
    local graph=F.Graph()
    for _,edge in ipairs(graph.edges)do
        if edge.requirements then edge.requirements.access[2]={key='second-proof',allowed=true}end
    end
    return graph
end
local function O(sequence,second,open)
    return {sequence=sequence,worldState='ready',access={['garden-open']=open==true,['second-proof']=second}}
end
local p=F.Planner(Graph(),{conditionObservation=O(1,true)})
local result=F.Result(p)
assert(result.unlock and p:IsCurrent(result))
local revision,conditionRevision=p.revision,p.conditions.revision
assert(p:ObserveConditions(O(2,true))==false)
assert(p.revision==revision and p:IsCurrent(result),'Fresh identical evidence preserves a current unlock result')
assert(p:ObserveConditions(O(3,false))==true,'Losing a supporting fact must retire the previous prerequisite proof')
assert(p.revision==revision+1 and p.conditions.revision==conditionRevision,
    'Unlock proof invalidation is distinct from the unchanged aggregate Conditions token')
assert(not p:IsCurrent(result))
assert(F.Result(p).status=='no_path')
assert(p:StartTravel(result)==nil,'A retired result cannot start a prerequisite approach')
assert(p:ObserveConditions(O(4,true)))
result=F.Result(p);assert(result.unlock and p:IsCurrent(result))
assert(p:ObserveConditions(O(5,nil)))
assert(not p:IsCurrent(result) and not F.Result(p).unlock,'Unknown support also retires prior justification')
assert(p:ObserveConditions(O(6,true)))
result=F.Result(p)
local journey=assert(F.Library.NewJourney(result.objective))
local travel=assert(p:StartTravel(result,nil,journey))
travel:Observe({sequence=1,reliable=true,node='keeper'})
assert(p:ObserveConditions(O(7,false)))
assert(travel:GetAction().kind=='cancelled')
local resumed=assert(p:ResumeUnlock(journey))
assert(not journey.unlock,'Reconsideration discards the old invalid prerequisite while keeping its original goal')
local newer=F.Base.Finish(resumed,1)
assert(newer.status=='no_path' and not newer.unlock and journey.objective.to=='goal' and journey.node=='keeper')
-- A not-yet-published approach must not accept proof that changed during its slices.
p=F.Planner(Graph(),{conditionObservation=O(1,true)})
local job=p:Plan({from='cave',to='goal'})
for _=1,1000 do
    local state=job:Step(1);assert(state.status=='running')
    if state.diagnostics.phase=='unlock_approach' then break end
end
p:ObserveConditions(O(2,false))
assert(F.Base.Finish(job,1).status=='stale')
-- Real host consumption sees the same retirement and preserves replacement output.
for _,client in ipairs({'Standard','Camelot'})do for _,awp in ipairs({false,true})do
    local e=F.Host(client,awp,nil,Graph())
    e.host:SetConditionAccess({['garden-open']=false,['second-proof']=true})
    result=e:Result();assert(result.unlock);e:Start(result)
    local oldJob,oldTravel=e.host.job,e.host.travel
    local marker=awp and e.as.record or e.ws.current
    local sequence=e.host.planner.conditions.snapshot.sequence
    assert(e.host:ObserveConditions(O(sequence+1,true))==false)
    assert(e.host.job==oldJob and e.host.travel==oldTravel and (awp and e.as.record or e.ws.current)==marker)
    assert(e.host:ObserveConditions(O(sequence+2,false)))
    assert(not e.host.travel and not e:HasMarker() and not e.host.planner:IsCurrent(result))
    e.context='replacement'
    assert(e.host:Plan({from='town',to='goal'},e.context))
    newer=e:Finish();assert(newer.status=='complete' and not newer.unlock)
    e:Start(newer);assert(e:HasMarker())
    marker=awp and e.as.record or e.ws.current
    oldJob:Step(1);oldTravel:GetAction()
    local action,reason=e.host:StartTravel(result,nil,'first')
    assert(not action and reason=='stale_context' and (awp and e.as.record or e.ws.current)==marker)
    assert(e.host.journey.objective.from=='town' and e.quests==0)
    e.host:Disable()
end end
