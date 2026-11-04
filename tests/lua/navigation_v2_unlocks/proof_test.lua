local F=dofile('tests/lua/navigation_v2_unlocks/fixture.lua')
local graph=F.Graph()
graph.zones={{id='garden',requirements={phase='live'}}}
graph.nodes[4]={id='goal',zone='garden',requirements=F.Gate()}
local r=F.Result(F.Planner(graph))
assert(r.status=='no_path' and not r.unlock,'A known denial must not hide unknown phase proof and trigger fallback')
assert(r.diagnostics.unlockReason=='absence_unproven')
graph=F.Graph()
graph.edges[#graph.edges+1]={id='unknown',from='cave',to='keeper',seconds=1,access='unknown'}
r=F.Result(F.Planner(graph))
assert(r.status=='no_path' and not r.unlock,'Even a dead-end unknown alternative is not certified absence')
assert(r.diagnostics.unlockReason=='absence_unproven')
graph=F.Graph();graph.edges[1].access='unavailable'
r=F.Result(F.Planner(graph));assert(r.status=='no_path' and not r.unlock)
graph=F.Graph();graph.edges[1].access='unknown'
r=F.Result(F.Planner(graph));assert(r.status=='no_path' and not r.unlock and r.diagnostics.unlockReason=='absence_unproven')
local entry=F.Entry();entry.opens={access={{key='unrelated-gate',allowed=true}}}
r=F.Result(F.Planner(nil,{unlocks={entry}}));assert(r.status=='no_path' and not r.unlock)
entry=F.Entry();entry.requirements={access={{key='eligible',allowed=true}}}
r=F.Result(F.Planner(nil,{unlocks={entry},conditionObservation={sequence=1,worldState='ready',
    access={['garden-open']=false,eligible=false}}}))
assert(r.status=='no_path' and not r.unlock and r.diagnostics.unlockReason=='unlock_eligibility_denied')
local p=F.Planner();r=F.Result(p)
assert(r.status=='complete' and r.unlock and r.optimal==false and r.estimateScope=='unlock_approach',
    'An approach estimate is not an optimal completed journey to the original destination')
local journey=assert(F.Library.NewJourney(r.objective))
local travel=assert(p:StartTravel(r,nil,journey))
travel:Observe({sequence=1,reliable=true,node='keeper'})
journey:Unlocate()
assert(p:ObserveConditions({sequence=2,worldState='ready',access={['garden-open']=true}}))
local job,reason=p:ResumeUnlock(journey)
assert(not job and reason=='location_unknown' and journey.unlock,'Fresh access cannot invent an origin')
journey:Locate('keeper');job=assert(p:ResumeUnlock(journey))
assert(F.Base.Finish(job).status=='complete')
