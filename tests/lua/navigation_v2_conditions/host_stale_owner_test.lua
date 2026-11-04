local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
for _,awp in ipairs({false,true})do
    local e=F.Host('Standard',awp);e:EnableConditions()
    local oldResult,oldJob=e:FirstResult()
    e:StartWalk(oldResult);local oldTravel=e.host.travel
    e.context='replacement'
    local nextJob=assert(e.host:Plan({from='town',to='goal'},e.context))
    local nextResult=e:Finish();assert(nextResult.status=='complete')
    e:StartWalk(nextResult);assert(e:HasMarker())
    local marker=awp and e.as.record or e.ws.current
    local action,reason=e.host:StartTravel(oldResult,nil,'first')
    assert(action==nil and reason=='stale_context')
    assert(oldTravel:GetAction().kind=='cancelled')
    oldJob:Step(1)
    assert(e.host.job==nextJob and e.host.travel~=oldTravel and e:HasMarker())
    assert((awp and e.as.record or e.ws.current)==marker,'Old ownership cannot clear the replacement marker')
    e:Cleanup()
end
-- A client callback replacing the request while a first capture is running
-- cannot continue the former suspended job into that new objective.
local e=F.Host('Camelot');e:EnableConditions()
local old=assert(e.host:Plan({from='cave',to='goal'},e.context))
assert(e:Finish().status=='observation_required')
local once=false
e.api.C_QuestLog.IsQuestFlaggedCompleted=function()
    e.questReads=e.questReads+1
    if not once then
        once=true;e.context='replacement'
        assert(e.host:Plan({from='town',to='goal'},e.context))
    end
    return true
end
local resumed,reason=e.host:ResumeConditions()
assert(resumed==nil and reason=='superseded' and e.host.job~=old)
local r=e:Finish()
if r.status=='observation_required'then e.host:ResumeConditions();r=e:Finish()end
assert(r.status=='complete' and r.objective.from=='town' and r.objective.to=='goal')
e:Cleanup()
