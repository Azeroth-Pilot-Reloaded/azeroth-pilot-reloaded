local F=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
-- Invalid replacement is not an instruction to keep guiding to the old target.
for _,awp in ipairs({false,true})do
    local e,h=F.New(awp)
    assert(e:Enable());e:Plan();assert(e:Finish().status=='complete')
    assert(e:Target()=='active' and e:HasMarker())
    local output,why=h:SetWorldTarget({key='missing world',title='Destination'},e.context)
    assert(output==nil and why=='invalid_world_target')
    assert(not e:HasMarker(),'An invalid replacement must clear the previous owned marker')
    e:Cleanup()
end
