local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local g=F.Graph()
g.nodes[4]={id='goal',requirements={phase='present',access={{key='far-open',allowed=true}}}}
local observation={sequence=1,worldState='ready',phase='present',access={['near-open']=false,['far-open']=false}}
local p=F.Planner(g,nil,{conditionObservation=observation})
local r=F.Result(p)
assert(r.unlock.id=='far-keeper' and r.unlockPlan.estimatedSeconds==9,'Destination node conditions use explicit conditional state')
observation.phase=nil
r=F.Result(F.Planner(g,nil,{conditionObservation=observation}))
assert(not r.unlock,'A positive effect cannot invent the unknown destination phase')
-- Completed quest effects are hypothetical inside planning, never real completion.
g=F.Graph();g.edges[4].requirements={quests={{questID=831,completed=true}}}
local entries=F.Entries();entries[2].opens={quests={{questID=831,completed=true}}}
p=F.Planner(g,entries,{conditionObservation={sequence=1,worldState='ready',quests={[831]=false},access={['near-open']=false}}})
r=F.Result(p)
assert(r.unlock.id=='far-keeper' and r.unlockPlan.estimatedSeconds==9 and p.conditions.snapshot.quests[831]==false)
local journey=assert(F.Library.NewJourney(r.objective))
local travel=assert(p:StartTravel(r,nil,journey))
travel:Observe({sequence=1,reliable=true,node='far'})
assert(not p:ResumeUnlock(journey) and p.conditions.snapshot.quests[831]==false)
assert(p:ObserveConditions({sequence=2,worldState='ready',quests={[831]=true},access={['near-open']=false}}))
r=F.Base.Finish(assert(p:ResumeUnlock(journey)),1)
assert(not r.unlock and r.estimatedSeconds==2 and r.objective.to=='goal')
