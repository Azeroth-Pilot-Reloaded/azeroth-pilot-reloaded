local F=dofile('tests/lua/navigation_v2_position/host_fixture.lua')
local e,h=F.New()
assert(e:Enable());local job=e:Plan();local result=e:Finish()
local generation,revision,journey=h.generation,h.planner.revision,h.journey
local calls=e.readyCalls
for i=1,40 do
    e.x,e.y,e.z=123+i/1000,-987+i/1000,17+i/1000
    e.uiMapID=i%2==0 and 42 or nil
    assert(h:ObservePosition()==false)
    assert(h.planner:IsCurrent(result) and h.job==job and h.generation==generation and h.planner.revision==revision)
    assert(h.journey==journey and h.journey.viaIndex==0,'XYZ cannot certify a mandatory visit')
end
assert(e.readyCalls==calls and #e.timers==0)
local latest=h:GetPositionSnapshot()
assert(latest.z>17 and latest.phase=='blue' and latest.world==0 and latest.floor=='upper')
latest.floor='lower'
assert(h:GetPositionSnapshot().floor=='upper')
local sequence=h:GetPositionSnapshot().sequence
local changed,why=h:ObservePosition({sequence=sequence,worldState='ready',world=99,x=0,y=0,floor='lower'})
assert(changed==false and why=='stale_observation' and h.planner:IsCurrent(result))
assert(h:GetPositionSnapshot().world==0 and h:GetPositionSnapshot().floor=='upper')

-- Revoke one independent identity; new XY/Z and a valid UiMap cannot fill it.
e.x,e.y,e.z,e.uiMapID=123,-987,17,42
assert(h:SetPositionIdentity({space='room',phase='blue'}))
e:Plan();assert(e:Finish().reason=='floor_ambiguous')
assert(not e:HasMarker() and h.job:GetResult().objective.to=='g')
local unknownJob,unknownRevision=h.job,h.planner.revision
for _=1,20 do assert(h:ObservePosition()==false)end
assert(h.job==unknownJob and h.planner.revision==unknownRevision)
assert(h:SetPositionIdentity({space='room',floor='lower',phase='blue'}))
e:Plan();assert(e:Finish().reason=='floor_mismatch')
assert(h:SetPositionIdentity({space='room',floor='upper',phase='red'}))
e:Plan();assert(e:Finish().reason=='phase_mismatch')
assert(h:SetPositionIdentity({space='elsewhere',floor='upper',phase='blue'}))
e:Plan();assert(e:Finish().reason=='space_mismatch')
assert(h:SetPositionIdentity({space='room',floor='upper',phase='blue'}))
e:Plan();assert(e:Finish().status=='complete')
assert(e:Target()=='active' and e:HasMarker())
e.x=nil
assert(h:ObservePosition()==true and not e:HasMarker())
local held=h.planner.revision
for _=1,10 do assert(h:ObservePosition()==false)end
assert(h.planner.revision==held)
e:Plan();assert(e:Finish().reason=='position_missing')
e.x=123
assert(h:ObservePosition()==true)
e:Plan();assert(e:Finish().status=='complete')
e:Cleanup()
