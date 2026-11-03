local Position=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
for _,awp in ipairs({false,true})do
    local e,h=Position.New(awp);e.uiMapID=42
    local graph=Position.Graph();graph.edges[1].requirements={phase='blue'}
    e.options.observeConditions=true;e.options.conditionAPI=e.api;e.options.conditionIdentity={phase='blue'}
    assert(h:Enable(graph,e.options))
    e:Plan({from='s',to='g'});local r=e:Finish()
    assert(r.status=='observation_required');h:ResumeConditions();r=e:Finish()
    assert(r.estimatedSeconds==1 and h:GetPositionSnapshot().uiMapID==42)
    assert(h:SetConditionIdentity({phase='red'}));h:ResumeConditions();r=e:Finish()
    assert(r.estimatedSeconds==6 and h:GetPositionSnapshot().uiMapID==42,
        'Identical public UiMap and world position cannot prove the required phase')
    assert(h:SetConditionIdentity({}));h:ResumeConditions();r=e:Finish()
    assert(r.estimatedSeconds==6,'Missing phase proof does not inherit compatibility from the map')
    assert(h:SetConditionIdentity({phase='blue'}));h:ResumeConditions();r=e:Finish()
    assert(r.estimatedSeconds==1)
    e:Cleanup()
end
