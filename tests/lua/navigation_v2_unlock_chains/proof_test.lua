local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local graph=F.Graph()
graph.edges[4].requirements.access[2]={key='support',allowed=true}
local function O(sequence,support)return {sequence=sequence,worldState='ready',
    access={['near-open']=false,['far-open']=false,support=support}}end
local p=F.Planner(graph,nil,{conditionObservation=O(1,true)})
local r=F.Result(p);assert(r.unlock.id=='far-keeper')
local revision,token=p.revision,p.conditions.revision
assert(p:ObserveConditions(O(2,true))==false and p:IsCurrent(r) and p.revision==revision)
assert(p:ObserveConditions(O(3,false)))
assert(p.conditions.revision==token and p.revision==revision+1 and not p:IsCurrent(r),
    'Supporting proof changes retire conditional plans even at constant aggregate denial')
assert(F.Result(p).unlock.id=='near-keeper')
assert(p:ObserveConditions(O(4,true)))
r=F.Result(p)
local journey=assert(F.Library.NewJourney(r.objective))
local travel=assert(p:StartTravel(r,nil,journey))
assert(p:ObserveConditions(O(5,nil)))
assert(not p:IsCurrent(r) and travel:GetAction().kind=='cancelled')
local job=assert(p:ResumeUnlock(journey));assert(not journey.unlock and journey.objective.to=='goal')
assert(not F.Base.Finish(job,1).unlock,'Unknown support prevents certified absence; no replacement unlock is invented')
-- Support changes before proof registration cannot escape the revision guard.
p=F.Planner(graph,nil,{conditionObservation=O(1,true)})
job=p:Plan({from='start',to='goal'})
for _=1,2000 do
    assert(job:Step(1).status=='running')
    if job.chain then break end
end
assert(job.chain)
assert(p:ObserveConditions(O(2,false))==false,'No selected-proof watcher exists yet; aggregate access is unchanged')
assert(F.Base.Finish(job,1).status=='stale','Final proof compares the frozen snapshot as well as aggregate status')
-- Identical accepted snapshots during search remain eligible, no unnecessary retry.
p=F.Planner(graph,nil,{conditionObservation=O(1,true)})
job=p:Plan({from='start',to='goal'})
for _=1,2000 do assert(job:Step(1).status=='running');if job.chain then break end end
assert(p:ObserveConditions(O(2,true))==false)
assert(F.Base.Finish(job,1).unlock.id=='far-keeper')
-- The same check applies to an in-flight conditional label, before a route exists.
p=F.Planner(graph,nil,{conditionObservation=O(1,true)})
job=p:Plan({from='start',to='goal'})
for _=1,2000 do
    assert(job:Step(1).status=='running')
    if job.search and job.search.planSnapshot and job.search.current and next(job.search.current.assumed)then break end
end
assert(job.search and job.search.current and next(job.search.current.assumed))
assert(p:ObserveConditions(O(2,false))==false)
assert(F.Base.Finish(job,1).status=='stale')
