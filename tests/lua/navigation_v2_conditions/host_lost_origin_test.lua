local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
local e=F.Host('Standard');e:EnableConditions()
local r=e:FirstResult({from='cave',to='goal',via={'town'}})
e:StartWalk(r)
e.host:ObserveTravel({sequence=1,reliable=true,loading=true,node='cave'})
assert(e.host.journey.node==nil)
e:Fire('QUEST_LOG_UPDATE')
local held=e.host:ResumeConditions()
assert(held.status=='unknown' and held.reason=='location_unknown')
assert(held.objective.to=='goal' and held.objective.via[1]=='town')
local job,reads=e.host.job,e.questReads
for _=1,5 do
    held=e.host:ResumeConditions()
    assert(held.status=='unknown' and held.reason=='location_unknown')
end
assert(e.host.job==job and e.questReads==reads,'Unchanged missing origin cannot loop native capture or Plan')
-- Recovery needs a new trusted origin, not the previous request's departure.
assert(e.host:Plan({from='town',to='goal'},e.context))
r=e:Finish();assert(r.status=='complete' and r.objective.from=='town')
e:Cleanup()
