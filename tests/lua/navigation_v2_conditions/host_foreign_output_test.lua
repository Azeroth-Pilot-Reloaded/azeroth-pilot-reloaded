local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
for _,awp in ipairs({false,true})do
    local e=F.Host('Standard',awp);e:EnableConditions()
    local r=e:FirstResult();e:StartWalk(r);assert(e:HasMarker())
    local foreign={name='Foreign destination',flags='foreign',mapID=42,x=.5,y=.5}
    local replacement
    if awp then
        replacement={extractTarget=function()return nil,true end}
        AzerothWaypointNS.RegisterGuideTargetProvider('apr',replacement)
        e.as.record=foreign
    else e.ws.current=foreign end
    e:Fire('QUEST_LOG_UPDATE')
    assert((awp and e.as.record or e.ws.current)==foreign,'Condition invalidation clears only owned output')
    e.host:Disable()
    assert((awp and e.as.record or e.ws.current)==foreign,'Disable preserves foreign output')
    if awp then assert(e.as.provider==replacement)end
    assert(e.quests==0 and e.protectedUses==0)
end
