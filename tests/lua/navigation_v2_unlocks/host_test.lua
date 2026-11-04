local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do for _,awp in ipairs({false,true})do
    local e=F.Host(client,awp)
    APR.ActiveRoute='authored-route';APR.CurrentStep=17
    local result=e:Result()
    assert(result.unlock and result.unlock.id=='speak-keeper')
    assert(not e:HasMarker(),'Planning alone publishes nothing')
    local original=e.host.journey
    assert(e:Start(result).node=='keeper' and e:HasMarker())
    local action=e.host:ObserveTravel({sequence=1,reliable=true,loading=false,node='keeper'})
    assert(action.kind=='unlock' and not e:HasMarker())
    assert(e.quests==0 and APR.ActiveRoute=='authored-route' and APR.CurrentStep==17)
    local job=e.host.job
    assert(e.host:ResumeUnlock().kind=='unlock' and e.host.job==job)
    assert(e.host:SetConditionAccess({['garden-open']=true}))
    assert(not e:HasMarker(),'Access changes retire the old output immediately')
    assert(e.host:ResumeConditions().status=='running')
    assert(e.host.journey==original and original.node=='keeper' and original.viaIndex==0)
    result=e:Finish()
    assert(result.status=='complete' and result.objective.to=='goal' and result.objective.via[1]=='town' and not result.unlock)
    assert(e:Start(result).node=='town')
    assert(e.host:ObserveTravel({sequence=1,reliable=true,node='town'}).node=='goal')
    assert(e.host:ObserveTravel({sequence=2,reliable=true,node='goal'}).kind=='complete')
    assert(e.quests==0 and APR.CurrentStep==17 and original.viaIndex==1)
    e.host:Disable()
end end
