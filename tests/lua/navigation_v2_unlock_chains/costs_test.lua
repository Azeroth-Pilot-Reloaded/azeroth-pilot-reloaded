local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local graph=F.Graph()
graph.edges[1].resources={supplies=1};graph.edges[3].seconds=1;graph.edges[3].resources={supplies=1}
local entries=F.Entries();entries[1].completionSeconds=1;entries[1].resources={supplies=1}
for _,balance in ipairs({2,3})do
    local p=F.Planner(graph,entries,{resources={supplies=balance}})
    local r=F.Result(p)
    assert(r.unlock.id==(balance==3 and 'near-keeper' or 'far-keeper'))
    if balance==3 then
        assert(r.unlockPlan.estimatedSeconds==3 and r.unlockPlan.resourcesSpent.supplies==3)
        assert(r.resourcesSpent.supplies==1,'Executable result contains only resources spent by its real approach')
    else assert(r.unlockPlan.estimatedSeconds==9 and not r.resourcesSpent.supplies)end
end
local bad=F.Entries();bad[1].resources={supplies=-1}
assert(F.Library.New(F.Graph(),{clock=function()return 1 end,profileClock=function()return 0 end,unlocks=bad})==nil)

-- Declared realization time moves the actual timetable-use instant.
local route={id='boat',kind='boat',from='pier',to='arrival',access='available',requirements=F.Gate('boat-open'),
    origin={id='dock',worldID=7,floorID=0,phaseID='present'},
    destination={id='berth',worldID=7,floorID=0,phaseID='present'},
    costs={approach=0,boarding=0,ride=3,loading=0,disembark=0,final=0},
    wait={mode='periodic',firstDeparture=110,periodSeconds=30}}
graph={complete=true,nodes={'start','near','pier','arrival','goal'},edges={
    {id='pier',from='start',to='pier',seconds=5},{id='final',from='arrival',to='goal',seconds=2},
    {id='near',from='start',to='near',seconds=1},
    {id='walk',from='near',to='goal',seconds=40,requirements=F.Gate('walk-open')}}}
entries={F.Unlock('boat','start','boat-open',20),F.Unlock('walk','near','walk-open',1)}
local function Timed()
    return F.Result(F.Planner(graph,entries,{scheduled={route},
        conditionObservation={sequence=1,worldState='ready',access={['boat-open']=false,['walk-open']=false}}}))
end
local r=Timed();assert(r.unlock.id=='walk' and r.unlockPlan.estimatedSeconds==42,'Missed departure: boat costs 45')
entries[1].completionSeconds=0
r=Timed();assert(r.unlock.id=='boat' and r.unlockPlan.estimatedSeconds==15 and #r.segments==0)

-- Future personal uses share the original cumulative resources/cooldown labels.
local P=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local d,o=P.Declarations(),P.Observation()
d[1].cooldownSeconds=10;d[1].requirements=F.Gate('recall-open');o.actions.recall.readyAt=108
graph={complete=true,nodes={'cave','town'},edges={{id='return',from='town',to='cave',seconds=2}}}
local action=F.Unlock('learn','cave','recall-open',7);action.destination='town'
local options=P.Options(d,o)
options.unlocks={action};options.conditionObservation={sequence=1,worldState='ready',access={['recall-open']=false}}
local p=assert(P.Library.New(graph,options))
r=P.Base.Finish(p:Plan({from='cave',to='town',via={'town','cave'}}),1)
assert(r.unlock.id=='learn' and r.unlockPlan.estimatedSeconds==23,
    '7 realization + 1 initial cooldown wait + 3 cast + 2 loading + 2 return + 3 shared cooldown wait + 3 cast + 2 loading')
assert(r.unlockPlan.resourcesSpent.money==8 and r.unlockPlan.resourcesSpent['item:travel_powder']==4)
assert(r.unlockPlan.resourcesSpent['personal:recall']==2 and not next(r.resourcesSpent))
o.moneyCopper=8;action.resources={money=1}
options=P.Options(d,o);options.unlocks={action}
options.conditionObservation={sequence=1,worldState='ready',access={['recall-open']=false}}
p=assert(P.Library.New(graph,options))
r=P.Base.Finish(p:Plan({from='cave',to='town',via={'town','cave'}}),1)
assert(r.status=='no_path' and not r.unlock,'Realization cannot regenerate money for the second cast')
