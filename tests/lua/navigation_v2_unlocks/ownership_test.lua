local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
for _,awp in ipairs({false,true})do
    local e=F.Host('Standard',awp)
    local old=e:Result();e:Start(old)
    local oldTravel,oldJourney,oldJob=e.host.travel,e.host.journey,e.host.job
    local oldTimer=e.timers[#e.timers]
    e.context='replacement'
    e.host:Plan({from='town',to='goal'},e.context)
    local fresh=e:Finish();assert(fresh.status=='complete' and not fresh.unlock)
    e:Start(fresh);assert(e:HasMarker())
    local marker=awp and e.as.record or e.ws.current
    local action,reason=e.host:StartTravel(old,nil,'first')
    assert(not action and reason=='stale_context')
    if oldTimer then oldTimer.callback()end
    oldJob:Step(100);oldTravel:Observe({sequence=1,reliable=true,node='keeper'})
    assert(e.host.journey~=oldJourney and e.host.journey.objective.to=='goal' and not e.host.journey.unlock)
    assert((awp and e.as.record or e.ws.current)==marker and e:HasMarker())
    action,reason=e.host:ResumeUnlock();assert(not action and reason=='no_unlock')
    e.host:Cancel();assert(not e.host.journey and not e:HasMarker())
    assert(e.quests==0 and e.protectedUses==0)
    e.host:Disable()
end
-- A resolver replacing the request cannot publish the former prerequisite.
local e=F.Host('Camelot',false)
local result=e:Result();local once=false
local action,reason=e:Start(result,function()
    if not once then once=true;e.context='replacement';e.host:Plan({from='town',to='goal'},e.context)end
    return {key='obsolete',title='1, 2',position={mapID=42,x=.2,y=.3}}
end)
assert(not action and reason=='superseded' and not e:HasMarker())
assert(e:Finish().objective.from=='town' and not e.host.journey.unlock)
e.host:Disable()
