local ns={}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Localization/World.lua'))('APR',ns)
local W=assert(ns.NavigationV2World)
local tracker=W.New()
local first=tracker:GetSnapshot()
assert(first.quality=='world_unknown' and tracker:IsCurrent(first))
local observation={sequence=1,worldState='ready',world=0,x=12,y=-4,z=8,
    space='room',floor='upper',phase='blue'}
local changed,snapshot=tracker:Observe(observation)
assert(changed and snapshot.quality=='world_position' and snapshot.mapReason=='map_missing')
assert(snapshot.world==0 and snapshot.x==12 and snapshot.y==-4 and snapshot.z==8)
assert(snapshot.space=='room' and snapshot.floor=='upper' and snapshot.phase=='blue')
assert(not tracker:IsCurrent(first) and tracker:IsCurrent(snapshot))
observation.x=999
snapshot.x=555
assert(tracker:GetSnapshot().x==12,'snapshots and inputs must be isolated')
local good=tracker:GetSnapshot()
assert(W.Match(good,{world=0,space='room',floor='upper',phase='blue'}))
for key,value in pairs({world=1,space='outside',floor='lower',phase='red'}) do
    local match,reason=W.Match(good,{[key]=value})
    assert(match==false and reason==key..'_mismatch')
end
assert(tracker:Observe({sequence=2,worldState='ready',uiMapID=42})==true)
local missing=tracker:GetSnapshot()
assert(missing.quality=='position_missing' and missing.uiMapID==42)
assert(not tracker:IsCurrent(good))
assert(select(2,W.Match(missing,{}))=='position_missing')
local accepted,reason=tracker:Observe({sequence=1,worldState='ready',world=0,x=0,y=0})
assert(accepted==false and reason=='stale_observation' and tracker:IsCurrent(missing))
assert(tracker:Observe({sequence=3,worldState='loading',world=0,x=12,y=-4,z=8}))
assert(tracker:GetSnapshot().quality=='loading')
assert(tracker:Observe({sequence=4,worldState='unknown',world=0,x=12,y=-4,z=8}))
assert(select(2,W.Match(tracker:GetSnapshot(),{}))=='world_unknown')
assert(tracker:Observe({sequence=5,worldState='ready',world=0,x=12,y=-4,z=8}))
local unresolved=tracker:GetSnapshot()
assert(unresolved.quality=='world_position','missing map and Z-independent identity do not erase world position')
assert(select(2,W.Match(unresolved,{floor='upper'}))=='floor_ambiguous')
assert(select(2,W.Match(unresolved,{phase='blue'}))=='phase_unknown')
assert(select(2,W.Match(unresolved,{space='room'}))=='space_unknown')
assert(tracker:Observe({sequence=6,worldState='ready',world=0,x=12,y=-4,z=108})==false)
assert(select(2,W.Match(tracker:GetSnapshot(),{floor='upper'}))=='floor_ambiguous',
    'Z proximity, including a stacked surface, does not certify floor identity')
assert(tracker:Observe({sequence=7,worldState='ready',world=0,x=12,y=-4,floor='lower',phase='blue'}))
assert(W.Match(tracker:GetSnapshot(),{floor='lower',phase='blue'}))
assert(select(2,W.Match(tracker:GetSnapshot(),{floor='upper'}))=='floor_mismatch')
for _,bad in ipairs({{}, {sequence=8,worldState='bad'}, {sequence=0,worldState='ready'},
    {sequence=8,worldState='ready',x=0/0}, {sequence=8,worldState='ready',world=-1},
    {sequence=8,worldState='ready',floor={}}}) do
    assert(select(2,tracker:Observe(bad))=='invalid_position_observation')
end
assert(tracker:GetSnapshot().sequence==7)
assert(select(2,W.Match(tracker:GetSnapshot(),{world=-1}))=='invalid_location_identity')
