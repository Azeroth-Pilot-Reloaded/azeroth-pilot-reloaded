local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
local g={complete=true,nodes={'cave','town','goal'},edges={
    {id='fast',from='cave',to='goal',seconds=1,requirements={phase='present',access={{key='gate',allowed=true}}}},
    {id='normal',from='cave',to='goal',seconds=12}}}
local e=F.Host();e:Enable({}, {observeConditions=true,conditionAPI=e.api,
    conditionIdentity={phase='present'},conditionAccess={gate=true}},g)
e.host:Plan({from='cave',to='goal'},e.context)
assert(e:Finish().status=='observation_required');e.host:ResumeConditions()
local r=e:Finish();assert(r.estimatedSeconds==1)
e.host:StartTravel(r)
e:Fire('UNIT_PHASE','target');assert(e.host.planner:IsCurrent(r))
e:Fire('UNIT_PHASE','player');assert(not e.host.planner:IsCurrent(r) and not e.host.travel)
assert(e.host.conditionSource.identity.phase==nil and next(e.host.conditionSource.access)==nil)
e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==12,'Phase event cannot restore stale phase/access')
e.host:SetConditionIdentity({phase='present'});e.host:ResumeConditions()
assert(e:Finish().estimatedSeconds==12,'Restored phase alone does not restore expired access proof')
e.host:SetConditionAccess({gate=true});e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==1)
e.host:MarkConditionsDirty({access={gate=true}});e.host:ResumeConditions()
assert(e:Finish().estimatedSeconds==12,'Explicitly revoked access cannot be recaptured from the old host cache')
e.host:SetConditionAccess({gate=true});e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==1)
e:Fire('PLAYER_LEAVING_WORLD');e:Fire('PLAYER_ENTERING_WORLD')
assert(next(e.host.conditionSource.identity)==nil and next(e.host.conditionSource.access)==nil)
assert(e.host:ResumeConditions().reason=='location_unknown','Loading does not reseed the old Journey origin')
e.host:Plan({from='cave',to='goal'},e.context);assert(e:Finish().estimatedSeconds==12)
e:Fire('PLAYER_LEAVING_WORLD')
e:Enable({}, {observeConditions=true,conditionAPI=e.api,
    conditionIdentity={phase='present'},conditionAccess={gate=true}},g)
e:Fire('PLAYER_ENTERING_WORLD')
e.host:Plan({from='cave',to='goal'},e.context)
if e:Finish().status=='observation_required' then e.host:ResumeConditions() end
assert(e:Finish().estimatedSeconds==12,'Active replacement during known loading cannot seed phase/access for the next world')
e.host:Disable()
-- A native nil is a completed capture attempt, never a dependency request loop.
g.edges[1].requirements={quests={{questID=905,completed=true}}}
e=F.Host();local reads=0
e.api.C_QuestLog={IsQuestFlaggedCompleted=function()reads=reads+1;return nil end}
e:Enable({}, {observeConditions=true,conditionAPI=e.api},g)
e.host:Plan({from='cave',to='goal'},e.context);assert(e:Finish().status=='observation_required')
e.host:ResumeConditions();assert(e:Finish().estimatedSeconds==12 and reads==1)
assert(e.host:ResumeConditions().status=='complete' and reads==1)
-- Reentrant capture must never cancel or overwrite a newer request.
local newer
e.api.C_QuestLog.IsQuestFlaggedCompleted=function()
    e.api.C_QuestLog.IsQuestFlaggedCompleted=function()return true end
    newer=assert(e.host:Plan({from='town',to='town'},e.context))
    return true
end
local old,why=e.host:Plan({from='cave',to='goal'},e.context)
assert(old==nil and why=='superseded' and e.host.job==newer)
assert(e:Finish().estimatedSeconds==0)
e.host:Disable()
