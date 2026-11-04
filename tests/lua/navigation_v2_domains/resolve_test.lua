local F=dofile('tests/lua/navigation_v2_domains/fixture.lua')
local D=F.ns.NavigationV2Domains
local d=assert(D.New(F.Geography()))
local a=assert(d:Resolve(F.Point(0)))
assert(a.world==0 and a.space=='mainland' and a.z==nil and a.floor==nil and a.phase==nil)
local b=assert(d:Resolve(F.Point(28,0,702)))
assert(d:CanConnect(a,b,{})=='unavailable','An isolated map remains separate within world zero')
local c=assert(d:Resolve(F.Point(21,1,703)))
assert(d:CanConnect(a,c,{})=='unavailable','A common chart never merges native worlds')
local near=assert(d:Resolve(F.Point(14)))
assert(d:CanConnect(a,near,{})=='available','Declared outdoor region admits its direct model')
near.noAutoconnect=true
assert(d:CanConnect(a,near,{geometryEvidence={status='available'}})=='unavailable')

local data=F.Geography()
data.spaces.room={id='room',worldID=0,kind='building',mapIDs={701},parentSpace='mainland',
    bounds={minX=2,maxX=6,minY=-1,maxY=1,minZ=-2,maxZ=8},requiresExit=true,groundOnly=true}
d=assert(D.New(data));local room=assert(d:Resolve(F.Point(4)))
assert(room.space=='room' and room.requiresExit and room.groundOnly,
    'Unique declared indoor identity does not need external membership evidence')
assert(d:CanConnect(room,assert(d:Resolve(F.Point(14))),{})=='unavailable','Parent is not a doorway')
data.spaces.upper={id='upper',worldID=0,kind='floor',mapIDs={701},parentSpace='room',floor=2,
    bounds={minX=2,maxX=6,minY=-1,maxY=1,minZ=4,maxZ=8}}
d=assert(D.New(data));local unknown,why=d:Resolve(F.Point(4))
assert(not unknown and why=='floor_ambiguous')
local p=F.Point(4);p.floor=2;p.z=5
assert(d:Resolve(p).space=='upper')
p.z=-1;assert(d:Resolve(p)==nil,'A contradictory declared floor cannot fall back to a parent')

data=F.Geography();data.spaces.other.mapIDs={};data.spaces.other.bounds={minX=0,maxX=30,minY=-2,maxY=2}
d=assert(D.New(data));p=F.Point(10,1);p.uiMapID=nil
assert(d:Resolve(p).space=='other','Native bounded space can be mapless')
data.spaces.other.parentSpace='missing';assert(D.New(data)==nil)
data=F.Geography();data.spaces.mainland.parentSpace='mainland';assert(D.New(data)==nil)
