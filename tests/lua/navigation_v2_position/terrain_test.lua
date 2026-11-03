-- Real loader boundary, invented compact declaration. The XYZ triple is in
-- Recast Y-up order [WoW-world-Y, height, WoW-world-X], not UnitPosition order.
local F=dofile('tests/lua/navigation_v2/fixture.lua')
local _,ns=F.Load()
local W=assert(ns.NavigationV2World,'Real XML must load localization')
local loader=assert(ns.NavigationV2Terrain.New({room={complete=false,blocks={
    {first=1,nodes=2,edges=1,rawBytes=1,payload='synthetic'}}}}, {
    profileClock=function()return 0 end,decodeBase64=function()return 'x'end,
    inflate=function()return 'x'end,deserialize=function()
        return {2,1,{{12000,8000,-4000},{12000,108000,-4000}},{{1,2,1000}}}
    end}))
local job=loader:Load('room')
local result
repeat result=job:Step(1)until result.status~='running'
assert(result.status=='complete')
local lower=assert(W.FromTerrain(result.positions['terrain:1'],0,{space='room',floor='lower',phase='blue'}))
local upper=assert(W.FromTerrain(result.positions['terrain:2'],0,{space='room',floor='upper',phase='blue'}))
assert(lower.x==-4 and lower.y==12 and lower.z==8 and lower.world==0)
assert(upper.x==-4 and upper.y==12 and upper.z==108 and upper.floor=='upper')
assert(lower.phase=='blue' and lower.space=='room' and lower.floor=='lower')
assert(result.positions['terrain:1'][2]==8,'no mutation of decoded data')
local tracker=W.New()
local changed,snapshot=tracker:Observe({sequence=1,worldState='ready',world=0,x=-4,y=12,z=8})
assert(changed and snapshot.quality=='world_position')
assert(select(2,W.Match(snapshot,lower))=='space_unknown',
    'a real loaded node is not a proof the player belongs to that space')
assert(select(2,W.FromTerrain({12,8},0))=='position_missing')
assert(select(2,W.FromTerrain({12,8,-4},-1))=='position_missing')
assert(select(2,W.FromTerrain({12,8,-4},0,{floor={}}))=='invalid_location_identity')
