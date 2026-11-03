local F=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
for _,awp in ipairs({false,true})do
    local e,h=F.New(awp)
    assert(e:Enable());e:Plan();local result=e:Finish()
    assert(result.status=='complete' and not e:HasMarker(),'Planning publishes nothing')
    e.noProjection=true
    assert(select(2,e:Target())=='projection_unavailable' and not e:HasMarker())
    assert(result.objective.to=='g' and result.objective.via[1]=='a' and result.objective.via[2]=='b')
    e.noProjection=false
    assert(e:Target()=='active' and e:HasMarker())
    e.noProjection=true
    assert(select(2,e:Target())=='projection_unavailable' and not e:HasMarker(),
        'Loss of a previous reliable projection clears owned output')
    e.noProjection=false
    assert(e:Target()=='active' and e:HasMarker())
    e.target.worldPosition.floor='lower'
    assert(select(2,e:Target())=='floor_mismatch' and not e:HasMarker())
    e.target.worldPosition.floor='upper'
    assert(e:Target()=='active' and e:HasMarker())
    e.target.worldPosition.phase='red'
    assert(select(2,e:Target())=='phase_mismatch' and not e:HasMarker())
    e.target.worldPosition.phase='blue'
    assert(e:Target()=='active' and e:HasMarker())
    e.target.worldPosition.x=0/0
    assert(select(2,e:Target())=='position_missing' and not e:HasMarker())
    e.target.worldPosition.x=123
    assert(e:Target()=='active' and e:HasMarker())
    e:Fire('PLAYER_LEAVING_WORLD')
    assert(not e:HasMarker() and select(2,e:Target())=='loading')
    e:Cleanup()
end
