local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
local e=F.Host('Standard');e:EnableConditions()
local r,job=e:FirstResult();e:StartWalk(r);assert(e:HasMarker())
local reads,revision=e.questReads,e.host.planner.revision
assert(e.host:SetConditionIdentity({phase='unrelated'})==false,'Unrequired identity has no access effect')
assert(e.host:MarkConditionsDirty({quests={[999]=true}})==false,'Unobserved quest has no access effect')
assert(e.host.planner:IsCurrent(r) and e.host.planner.revision==revision and e:HasMarker())
local resumed=e.host:ResumeConditions()
assert(resumed.status=='complete' and e.host.job==job and e.questReads==reads,
    'An irrelevant fact change cannot schedule a new capture or search')
e:Cleanup()
