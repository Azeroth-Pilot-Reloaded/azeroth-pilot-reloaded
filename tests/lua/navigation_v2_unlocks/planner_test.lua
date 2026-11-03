local F=dofile('tests/lua/navigation_v2_unlocks/fixture.lua')
local p=F.Planner()
local r=F.Result(p,{from='cave',to='goal',via={'town'}})
assert(r.status=='complete',r.reason)
assert(r.unlock and r.unlock.id=='speak-keeper','Proven disconnection should guide the explicit simple prerequisite')
assert(r.objective.to=='goal' and r.objective.via[1]=='town')
assert(r.travelObjective.to=='keeper' and #r.travelObjective.via==0)
assert(r.estimatedSeconds==2 and #r.segments==1 and r.segments[1].edgeId=='approach')
assert(p.conditions.snapshot.access['garden-open']==false,'Planning must not open the gate')
for _,cost in ipairs({10,10000})do
    r=F.Result(F.Planner(F.Graph(cost)))
    assert(r.status=='complete' and r.estimatedSeconds==cost and not r.unlock,'Any usable detour takes priority')
end
for _,snapshot in ipairs({{sequence=1,worldState='ready'},{sequence=1,worldState='loading'}})do
    r=F.Result(F.Planner(nil,{conditionObservation=snapshot}))
    assert(r.status=='unknown' and not r.unlock,'Unknown access cannot authorize a prerequisite')
end
local graph=F.Graph();graph.complete=false
r=F.Result(F.Planner(graph));assert(r.status=='unknown' and not r.unlock)
r=F.Result(F.Planner(nil,{unlocks={}}));assert(r.status=='no_path' and not r.unlock)
local entry=F.Entry();entry.destination='town'
r=F.Result(F.Planner(nil,{unlocks={entry}}));assert(r.status=='no_path' and not r.unlock)
entry=F.Entry();entry.requirements={quests={{questID=811,completed=true}}}
r=F.Result(F.Planner(nil,{unlocks={entry}}));assert(r.status=='no_path' and not r.unlock)
local second=F.Entry();second.id='other-keeper'
r=F.Result(F.Planner(nil,{unlocks={F.Entry(),second}}))
assert(r.status=='no_path' and not r.unlock and r.diagnostics.unlockReason=='ambiguous_unlock')
