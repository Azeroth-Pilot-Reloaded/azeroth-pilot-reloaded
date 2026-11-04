local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
local C=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do for _,awp in ipairs({false,true})do
    local graph=F.Graph()
    graph.edges[3].requirements={access={{key='garden-open',allowed=true},{key='second',allowed=true}}}
    local first=F.Entry();first.completionSeconds=3
    local second={id='second',destination='goal',node='keeper',title='Talk to the second keeper',
        opens=C.Gate('second'),requirements=F.Gate(),completionSeconds=5}
    local e=F.Host(client,awp,{unlocks={first,second}},graph)
    e.host:SetConditionAccess({['garden-open']=false,second=false})
    APR.CurrentStep=17
    local r=e:Result()
    assert(r.unlock.id==first.id and r.unlockPlan.estimatedSeconds==14 and #r.unlockPlan.steps==2)
    assert(not e:HasMarker(),'Conditional planning cannot publish future markers')
    local journey=e.host.journey
    assert(e:Start(r).node=='keeper' and e:HasMarker())
    assert(e.host:ObserveTravel({sequence=1,reliable=true,node='keeper'}).kind=='unlock')
    assert(not e:HasMarker() and e.quests==0 and APR.CurrentStep==17)
    local job=e.host.job
    assert(e.host:ResumeUnlock().kind=='unlock' and e.host.job==job)
    assert(e.host:SetConditionAccess({['garden-open']=true,second=false}))
    assert(e.host:ResumeConditions().status=='running')
    r=e:Finish()
    assert(r.unlock.id=='second' and r.estimatedSeconds==0 and r.unlockPlan.estimatedSeconds==9)
    assert(r.objective.to=='goal' and r.objective.via[1]=='town' and e.host.journey==journey)
    assert(e:Start(r).kind=='unlock' and not e:HasMarker())
    e.host:ObserveWorld(true)
    assert(not journey.node)
    e.host:ObserveWorld(false)
    e.host:SetConditionAccess({['garden-open']=true,second=true})
    local held=e.host:ResumeConditions()
    assert(held.kind=='unlock' and held.reason=='location_unknown','Loading alone cannot invent the completion location')
    journey:Locate('keeper')
    assert(e.host:ResumeUnlock().status=='running')
    r=e:Finish();assert(not r.unlock and r.estimatedSeconds==4 and r.objective.to=='goal')
    assert(e:Start(r).node=='town')
    assert(e.host:ObserveTravel({sequence=1,reliable=true,node='town'}).node=='goal')
    assert(e.host:ObserveTravel({sequence=2,reliable=true,node='goal'}).kind=='complete')
    assert(e.quests==0 and APR.CurrentStep==17 and journey.viaIndex==1)
    e.host:Disable()
end end
