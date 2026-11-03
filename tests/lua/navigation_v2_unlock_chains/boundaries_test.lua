local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
for _,seconds in ipairs({false,'3',-1,math.huge,0/0})do
    local entries=F.Entries();entries[1].completionSeconds=seconds
    local p,reason=F.Library.New(F.Graph(),{clock=function()return 1 end,profileClock=function()return 0 end,unlocks=entries})
    assert(not p and reason=='invalid_unlock')
end
local entries=F.Entries();entries[1].completionSeconds=nil
local p=F.Planner(nil,entries)
local r=F.Result(p)
assert(r.unlock.id=='far-keeper' and r.unlockPlan.estimatedSeconds==9 and not r.unlockPlan.optimal,
    'An absent realization duration is unknown; it is never a free alternative')
entries=F.Entries();entries[2].destination='near'
r=F.Result(F.Planner(nil,entries))
assert(r.unlock.id=='near-keeper' and r.unlockPlan.estimatedSeconds==41,'Applicability stays explicit')
entries=F.Entries();entries[2].requirements={quests={{questID=731,completed=true}}}
for _,quest in ipairs({false,true})do
    p=F.Planner(nil,entries,{conditionObservation={sequence=1,worldState='ready',quests={[731]=quest},
        access={['near-open']=false,['far-open']=false}}})
    r=F.Result(p)
    assert(r.unlock.id==(quest and 'far-keeper' or 'near-keeper'))
end
p=F.Planner(nil,entries)
r=F.Result(p)
assert(r.unlock.id=='near-keeper' and not r.unlockPlan.optimal,'An unknown prerequisite is excluded, never completed')
assert(p.conditions.snapshot.quests[731]==nil)
for _,snapshot in ipairs({{sequence=1,worldState='ready',access={['near-open']=false}},
    {sequence=1,worldState='loading',access={['near-open']=false,['far-open']=false}}})do
    r=F.Result(F.Planner(nil,nil,{conditionObservation=snapshot}))
    assert(not r.unlock,'Unknown access/loading is not proof of normal-route absence')
end
local g=F.Graph();g.complete=false
r=F.Result(F.Planner(g));assert(r.status=='unknown' and not r.unlock)
-- Explicit zero is meaningful, unlike missing duration, and equal costs terminate.
entries=F.Entries();entries[1].completionSeconds=0;entries[2].completionSeconds=25
r=F.Result(F.Planner(nil,entries));assert(r.unlockPlan.estimatedSeconds==31 and r.unlockPlan.optimal)
entries[2].completionSeconds=24
r=F.Result(F.Planner(nil,entries));assert(r.unlock.id=='far-keeper' and r.unlockPlan.estimatedSeconds==30)
entries={F.Unlock('untimed','near','near-open',nil)}
r=F.Result(F.Planner(nil,entries))
assert(r.unlock and r.estimatedSeconds==1 and not r.unlockPlan,'Legacy untimed approach never claims a realization cost')
for _,access in ipairs({'unavailable','unknown'})do
    g=F.Graph();g.edges[3].access=access;g.edges[4].access=access
    r=F.Result(F.Planner(g));assert(not r.unlock,'Declared effects cannot rewrite raw traversal access')
end
-- Caller edits cannot mutate captured realization data or the chosen proof.
entries=F.Entries();p=F.Planner(nil,entries);entries[2].completionSeconds=100;entries[2].opens.access[1].key='fake'
r=F.Result(p);assert(r.unlock.id=='far-keeper' and r.unlockPlan.estimatedSeconds==9)
