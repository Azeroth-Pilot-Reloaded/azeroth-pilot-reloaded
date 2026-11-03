local F=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
for _,awp in ipairs({false,true})do
    -- A late rejected request must not erase a different, current step's output.
    local current,ch=F.New(awp)
    assert(current:Enable());current:Plan();assert(current:Finish().status=='complete')
    assert(current:Target()=='active' and current:HasMarker())
    local old=current.context
    current.context='new objective';current.target.key='new goal'
    assert(current:Target()=='active' and current:HasMarker())
    assert(select(2,ch:SetWorldTarget(current.target,old))=='stale_context')
    assert(current:HasMarker(),'A stale callback cannot clear the newer current owner')
    current:Cleanup()
    local e,h=F.New(awp)
    assert(e:Enable());e:Plan();assert(e:Finish().status=='complete')
    assert(e:Target()=='active' and e:HasMarker())
    local expired=e.context
    e.context='replacement objective'
    local output,why=h:SetWorldTarget(e.target,expired)
    assert(output==nil and why=='stale_context')
    assert(not e:HasMarker(),'Output owned by an expired step must be withdrawn at the boundary')
    e:Cleanup()
end
