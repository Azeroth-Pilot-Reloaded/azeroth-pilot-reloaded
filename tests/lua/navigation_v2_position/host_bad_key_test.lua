local F=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
local e,h=F.New()
assert(e:Enable());e:Plan();assert(e:Finish().status=='complete')
assert(e:Target()=='active' and e:HasMarker())
e.target.key=nil
assert(e:Target()=='invalid_target')
assert(not e:HasMarker(),'Invalid output metadata cannot keep a prior reliable marker')
e:Cleanup()
