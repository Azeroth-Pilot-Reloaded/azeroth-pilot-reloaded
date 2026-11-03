local F=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
for _,kind in ipairs({'x','world','secret','floor','floor_with_z','phase','space'})do
    local e,h=F.New()
    local reason='position_missing'
    if kind=='x'then e.x=nil
    elseif kind=='world'then e.world=nil
    elseif kind=='secret'then
        local secret={};e.x=secret;e.api.issecretvalue=function(v)return v==secret end
    elseif kind=='floor'or kind=='floor_with_z'then
        e.options.positionIdentity.floor=nil;e.uiMapID=42
        e.z=kind=='floor'and nil or 117;reason='floor_ambiguous'
    elseif kind=='phase'then e.options.positionIdentity.phase=nil;reason='phase_unknown'
    elseif kind=='space'then e.options.positionIdentity.space=nil;reason='space_unknown'end
    assert(e:Enable());e:Plan();local result=e:Finish()
    assert(result.status=='unknown' and result.reason==reason,kind..': wrong missing-data outcome')
    assert(result.objective.to=='g' and result.objective.via[1]=='a' and result.objective.via[2]=='b')
    assert(result.diagnostics.operations==0 and h.planner.preparation.phase=='prepare_nodes')
    assert(not e:HasMarker())
    local job,revision=h.job,h.planner.revision
    for _=1,15 do assert(h:ObservePosition()==false)end
    assert(h.job==job and h.planner.revision==revision and #e.timers==0)
    e.x,e.world,e.z=123,0,17;e.api.issecretvalue=nil
    h:SetPositionIdentity({space='room',floor='upper',phase='blue'})
    e:Plan();assert(e:Finish().status=='complete','Fresh sufficient evidence resumes a new request')
    e:Cleanup()
end
