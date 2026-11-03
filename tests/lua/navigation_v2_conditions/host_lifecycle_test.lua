local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do for _,awp in ipairs({false,true})do
    local e=F.Host(client,awp);e:EnableConditions()
    local result,first=e:FirstResult()
    assert(e:StartWalk(result).kind=='walk' and e:HasMarker())
    assert(e.questReads==2)
    if not awp then
        local options=e.ws.creates[#e.ws.creates]
        assert(options.stripCoordinates==true and options.name=='Follow the passage')
    else
        assert(#e.ws.creates==0,'AWP keeps provider priority')
        assert(e.as.record.target.title=='Follow the passage')
    end
    local oldTravel=e.host.travel
    local revision=e.host.planner.revision
    e:Fire('QUEST_TURNED_IN',999)
    assert(e.host.planner.revision==revision and e.host.travel==oldTravel and e:HasMarker())
    local reads=e.questReads
    e:Fire('QUEST_LOG_UPDATE')
    local dirtyRevision=e.host.planner.revision
    assert(dirtyRevision>revision and e.host.travel==nil and not e:HasMarker())
    assert(e.questReads==reads and not e.host.planner:IsCurrent(result))
    for _=1,8 do e:Fire('QUEST_LOG_UPDATE')end
    assert(e.host.planner.revision==dirtyRevision and e.questReads==reads,'Burst coalesces without native reads')
    assert(oldTravel:GetAction().kind=='cancelled')
    assert(e.host:ResumeConditions().status=='running')
    local resumed=e.host.job
    assert(resumed~=first and e.questReads==reads+1)
    result=e:Finish();assert(result.estimatedSeconds==3)
    assert(e.host:ResumeConditions().status=='complete' and e.host.job==resumed and e.questReads==reads+1)
    assert(e:StartWalk(result).kind=='walk' and e:HasMarker())
    -- Trusted node confirmation consumes the first mandatory visit only.
    e.host:Plan({from='cave',to='goal',via={'town','goal'}},e.context)
    result=e:Finish();assert(result.status=='complete')
    e:StartWalk(result)
    e.host:ObserveTravel({sequence=1,reliable=true,loading=false,node='town'})
    assert(e.host.journey.node=='town' and e.host.journey.viaIndex==1)
    e:Fire('QUEST_LOG_UPDATE');e.host:ResumeConditions();result=e:Finish()
    assert(result.objective.from=='town' and result.objective.to=='goal' and result.objective.via[1]=='goal')
    -- Loading loses the origin and cannot snap back on entering-world.
    e:Fire('PLAYER_LEAVING_WORLD');e:Fire('PLAYER_ENTERING_WORLD')
    assert(e.host.journey.node==nil and not e:HasMarker())
    local held=e.host:ResumeConditions()
    assert(held.status=='unknown' and held.reason=='location_unknown' and held.objective.to=='goal')
    assert(e.host.journey.objective.via[1]=='town' and e.host.journey.viaIndex==1)
    e:Cleanup()
end end
