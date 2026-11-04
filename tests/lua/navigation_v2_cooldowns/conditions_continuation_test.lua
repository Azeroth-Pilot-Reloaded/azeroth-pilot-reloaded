local F=dofile('tests/lua/navigation_v2_personal/host_fixture.lua')
local function Graph()
    return {complete=true,nodes={'cave','town','goal'},edges={
        {id='shortcut',from='cave',to='goal',seconds=1,requirements={quests={{questID=905,completed=true}}}},
        {id='detour',from='cave',to='town',seconds=8},{id='finish',from='town',to='goal',seconds=4}}}
end
local e=F.Host();local reads=0;e.completed=true
e.api.C_QuestLog={IsQuestFlaggedCompleted=function(id)assert(id==905);reads=reads+1;return e.completed end}
e:Enable({}, {observeConditions=true,conditionAPI=e.api},Graph())
local job=assert(e.host:Plan({from='cave',to='goal'},e.context))
local result=e:Finish()
assert(result.status=='observation_required' and result.reason=='conditions' and reads==0)
assert(e.host:GetResult().status=='observation_required' and reads==0)
assert(e.host:ResumeConditions().status=='running' and e.host.job==job and reads==1)
result=e:Finish();assert(result.estimatedSeconds==1 and e.host.job==job and reads==1,
    'The first Plan continues after one capture of its newly prepared dependencies')
local old=result
e.host:StartTravel(result);assert(reads==2,'Consumption captures once more')
e:Fire('QUEST_LOG_UPDATE')
assert(not e.host.planner:IsCurrent(old) and e.host.travel==nil and reads==2)
local revision=e.host.planner.revision;e:Fire('QUEST_LOG_UPDATE');assert(e.host.planner.revision==revision)
assert(e.host:ResumeConditions().status=='running')
local resumed=e.host.job;result=e:Finish();assert(result.estimatedSeconds==1 and resumed~=job and reads==3)
assert(e.host:ResumeConditions().status=='complete' and e.host.job==resumed and reads==3,
    'Identical fresh proof after dirty resumes once without a second loop')
e.completed=false;e:Fire('QUEST_LOG_UPDATE');e.host:ResumeConditions()
assert(e:Finish().estimatedSeconds==12 and reads==4)
e.host:Disable()
