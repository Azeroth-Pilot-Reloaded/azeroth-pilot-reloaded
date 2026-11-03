local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local graph={complete=true,nodes={'start','a','b','visit','goal'},edges={
    {id='approach',from='start',to='a',seconds=2},
    {id='second',from='a',to='b',seconds=3,requirements=F.Gate('first')},
    {id='visit',from='b',to='visit',seconds=4,requirements=F.Gate('second')},
    {id='finish',from='visit',to='goal',seconds=5}}}
local entries={F.Unlock('first','a','first',7),F.Unlock('second','b','second',11,F.Gate('first'))}
local function O(sequence,a,b)return {sequence=sequence,worldState='ready',access={first=a,second=b}}end
local p=F.Planner(graph,entries,{conditionObservation=O(1,false,false)})
local r=F.Result(p,{from='start',to='goal',via={'visit'}})
assert(r.unlock and r.unlock.id=='first' and r.estimatedSeconds==2)
assert(r.unlockPlan.estimatedSeconds==32 and #r.unlockPlan.steps==2 and r.unlockPlan.optimal)
assert(r.unlockPlan.steps[1].id=='first' and r.unlockPlan.steps[2].id=='second')
assert(#r.segments==1 and r.segments[1].edgeId=='approach','Future conditional segments cannot be executed')
local journey=assert(F.Library.NewJourney(r.objective))
local travel=assert(p:StartTravel(r,nil,journey))
assert(travel:GetAction().node=='a')
assert(travel:Observe({sequence=1,reliable=true,node='a'}).kind=='unlock')
assert(journey.objective.to=='goal' and journey.viaIndex==0)
assert(p:ResumeUnlock(journey)==nil,'Arrival is not evidence of completion')
local revision=p.revision
assert(p:ObserveConditions(O(2,false,false))==false and p.revision==revision)
assert(p:ResumeUnlock(journey)==nil,'Identical fresh facts cannot restart the same search')
assert(p:ObserveConditions(O(3,true,false)))
r=F.Base.Finish(assert(p:ResumeUnlock(journey)),1)
assert(r.unlock.id=='second' and r.estimatedSeconds==3 and r.unlockPlan.estimatedSeconds==23)
assert(r.objective.from=='a' and r.objective.to=='goal' and r.objective.via[1]=='visit')
travel=assert(p:StartTravel(r,nil,journey))
assert(travel:Observe({sequence=1,reliable=true,node='b'}).kind=='unlock')
assert(p.conditions.snapshot.access.second==false)
assert(p:ObserveConditions(O(4,true,true)))
r=F.Base.Finish(assert(p:ResumeUnlock(journey)),1)
assert(not r.unlock and r.optimal and r.estimatedSeconds==9 and r.objective.via[1]=='visit')
travel=assert(p:StartTravel(r,nil,journey))
assert(travel:Observe({sequence=1,reliable=true,node='visit'}).kind=='walk')
assert(journey.viaIndex==1 and travel:Observe({sequence=2,reliable=true,node='goal'}).kind=='complete')
assert(journey.objective.to=='goal')

-- A shared first prerequisite is realized once; both required effects are needed.
local g={complete=true,nodes={'start','goal'},edges={{id='gate',from='start',to='goal',seconds=2,
    requirements={access={{key='left',allowed=true},{key='right',allowed=true}}}}}}
entries={F.Unlock('base','start','base',3),F.Unlock('left','start','left',5,F.Gate('base')),
    F.Unlock('right','start','right',7,F.Gate('base')),
    F.Unlock('cycle-one','start','cycle-one',0,F.Gate('cycle-two')),
    F.Unlock('cycle-two','start','cycle-two',0,F.Gate('cycle-one'))}
p=F.Planner(g,entries,{conditionObservation={sequence=1,worldState='ready',
    access={base=false,left=false,right=false,['cycle-one']=false,['cycle-two']=false}}})
r=F.Result(p)
assert(r.unlock.id=='base' and r.unlockPlan.estimatedSeconds==17 and #r.unlockPlan.steps==3)
assert(r.estimatedSeconds==0 and #r.segments==0 and #r.nodes==1)
assert(p:StartTravel(r):GetAction().kind=='unlock','No invented waypoint for an action already at its node')
entries[1].requirements=F.Gate('left')
r=F.Result(F.Planner(g,entries,{conditionObservation={sequence=1,worldState='ready',
    access={base=false,left=false,right=false,['cycle-one']=false,['cycle-two']=false}}}))
assert(r.status=='no_path' and not r.unlock,'Cycles without a feasible first action cannot grant access')
entries[#entries+1]=F.Unlock('seed','start','base',2)
r=F.Result(F.Planner(g,entries,{conditionObservation={sequence=1,worldState='ready',
    access={base=false,left=false,right=false,['cycle-one']=false,['cycle-two']=false}}}))
assert(r.unlock.id=='seed' and r.unlockPlan.estimatedSeconds==16,'An independent realizable alternative can seed a cycle')
