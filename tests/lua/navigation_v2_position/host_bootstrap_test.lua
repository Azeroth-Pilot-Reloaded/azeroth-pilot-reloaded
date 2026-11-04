local F=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
for _,kind in ipairs({'true','false','nil','absent','error','secret'})do
    local e,h=F.New()
    local secret={}
    if kind=='false'then e.ready=false
    elseif kind=='nil'then e.ready=nil
    elseif kind=='absent'then e.api.IsPlayerInWorld=nil
    elseif kind=='error'then e.readyError=true
    elseif kind=='secret'then e.ready=secret;e.api.issecretvalue=function(v)return v==secret end end
    assert(e:Enable())
    local calls=e.readyCalls
    assert(calls==(kind=='absent'and 0 or 1))
    e:Plan();local result=e:Finish()
    if kind=='true'then
        assert(h.worldLoading==false and result.status=='complete' and result.estimatedSeconds==6)
        assert(h:GetPositionSnapshot().z==17 and h:GetPositionSnapshot().uiMapID==nil)
    else
        assert(result.status=='unknown' and result.objective.to=='g' and #result.objective.via==2)
        assert(h.planner.preparation.phase=='prepare_nodes' and result.diagnostics.operations==0)
        assert(e.positionCalls==0,'Incidental coordinates do not prove readiness')
        assert(result.reason==(kind=='false'and 'loading'or 'location_unknown'))
        assert(not e:HasMarker())
        for _=1,10 do assert(h:ObservePosition()==false)end
        assert(e.readyCalls==calls and h.job:GetResult().status=='unknown')
        e:Fire('PLAYER_ENTERING_WORLD')
        if kind=='false'then
            e:Plan();assert(e:Finish().reason=='space_unknown','Loading revoked old identity')
            assert(h:SetPositionIdentity({space='room',floor='upper',phase='blue'}))
        end
        e:Plan();assert(e:Finish().status=='complete','Fresh event is an actual recovery source')
    end
    assert(e.readyCalls==calls,'Plan and observation never repoll native readiness')
    e:Cleanup()
end

local e,h=F.New()
assert(e:Enable());e:Plan();local result=e:Finish()
e:Fire('PLAYER_LEAVING_WORLD')
assert(h.worldLoading==true and not h.planner:IsCurrent(result))
local calls=e.readyCalls
for _=1,3 do e:Plan();assert(e:Finish().reason=='loading')end
assert(e.readyCalls==calls)
assert(e:Enable() and h.worldLoading==true and e.readyCalls==calls)
assert(h:GetPositionSnapshot().floor==nil,'Reconfiguration cannot restore revoked loading identity')
assert(select(2,h:ObservePosition({sequence=h:GetPositionSnapshot().sequence+1,worldState='ready',
    world=0,x=123,y=-987,z=17,floor='upper'}))=='loading')
e:Fire('PLAYER_ENTERING_WORLD');e:Plan()
assert(e:Finish().reason=='space_unknown')
assert(h:SetPositionIdentity({space='room',floor='upper',phase='blue'}))
e:Plan();assert(e:Finish().status=='complete')
e:Cleanup()
e.ready=nil
assert(e:Enable() and e.readyCalls==calls+1 and h.worldLoading==nil)
e:Plan();assert(e:Finish().reason=='location_unknown','A real gap revokes prior ready knowledge')
e:Fire('PLAYER_ENTERING_WORLD');e:Plan();assert(e:Finish().status=='complete')
e:Cleanup()
