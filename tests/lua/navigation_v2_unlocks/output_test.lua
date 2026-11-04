local F=dofile('tests/lua/navigation_v2_unlocks/host_fixture.lua')
for _,awp in ipairs({false,true})do
    local e=F.Host('Camelot',awp)
    local hooks=0
    hooksecurefunc=function(api,name,observer)
        local original=assert(api[name]);hooks=hooks+1
        api[name]=function(...)
            local returned={original(...)};observer(...);return unpack(returned)
        end
    end
    local result=e:Result();e:Start(result)
    assert(e:HasMarker())
    if awp then
        assert(hooks==3)
        AzerothWaypointNS.ClearGuideRouteState('apr')
        assert(e.as.provider.extractTarget()==nil,'Public provider clear suppresses old extraction immediately')
        e.as:Flush()
        -- Drain only queued existing host refresh callbacks, never a new ticker.
        for _,timer in ipairs(e.timers)do if not timer.cancelled then timer.callback()end end
        assert(e.host:GetWaypointStatus()=='dismissed')
    else
        assert(e.ws.current.stripCoordinates==true and e.ws.current.name=='Follow the passage')
        e.host:DismissTarget();assert(e.host:GetWaypointStatus()=='dismissed')
    end
    e.host:ObserveTravel({sequence=1,reliable=true,node='keeper'})
    assert(e.host:GetTravelAction().title=='Speak to the keeper' and not e:HasMarker())
    assert(e.quests==0 and e.protectedUses==0)
    e.host:Disable()
    for _,frame in ipairs(e.frames)do assert(next(frame.events)==nil)end
end
-- An unlocalized prerequisite approach has no fabricated output point.
local e=F.Host('Standard',false)
local result=e:Result();assert(e:Start(result,function()end).kind=='walk')
assert(not e:HasMarker())
e.host:Disable()
for _,awp in ipairs({false,true})do
    e=F.Host('Standard',awp)
    result=e:Result();e:Start(result)
    local foreign={name='Foreign destination',flags='foreign',mapID=42,x=.5,y=.5}
    if awp then
        AzerothWaypointNS.RegisterGuideTargetProvider('apr',{extractTarget=function()return nil,true end})
        e.as.record=foreign
    else e.ws.current=foreign end
    e.host:MarkConditionsDirty({access={['garden-open']=true}})
    assert((awp and e.as.record or e.ws.current)==foreign)
    e.host:Disable()
    assert((awp and e.as.record or e.ws.current)==foreign,'Unlock invalidation preserves foreign output')
end
