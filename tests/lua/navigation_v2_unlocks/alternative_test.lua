local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
for _,arrived in ipairs({false,true})do
    local graph=F.Graph()
    graph.edges[#graph.edges+1]={id='new-route',from='cave',to='town',seconds=20,
        requirements={access={{key='bridge-open',allowed=true}}}}
    graph.edges[#graph.edges+1]={id='keeper-route',from='keeper',to='town',seconds=30,
        requirements={access={{key='bridge-open',allowed=true}}}}
    local e=F.Host('Standard',false,nil,graph)
    e.host:SetConditionAccess({['garden-open']=false,['bridge-open']=false})
    local result=e:Result();assert(result.unlock);e:Start(result)
    local journey=e.host.journey
    if arrived then e.host:ObserveTravel({sequence=1,reliable=true,node='keeper'})end
    local before=e.host.job
    e.host:SetConditionAccess({['garden-open']=false,['bridge-open']=true})
    assert(e.host:ResumeConditions().status=='running','A newly usable normal route must be reconsidered before continuing the prerequisite')
    assert(e.host.job~=before and e.host.journey==journey)
    result=e:Finish()
    assert(result.status=='complete' and not result.unlock and result.optimal)
    assert(result.objective.to=='goal' and result.objective.via[1]=='town')
    assert(result.estimatedSeconds==(arrived and 31 or 21),'The normal route wins while the original unlock gate remains closed')
    assert(e.host.planner.conditions.snapshot.access['garden-open']==false)
    local job=e.host.job
    assert(e.host:ResumeConditions()==result and e.host.job==job,'Unchanged snapshots do not repeat reconsideration')
    e:Start(result);assert(not journey.unlock)
    assert(e.host:GetTravelAction().node=='town' and e.quests==0)
    e.host:Disable()
end
