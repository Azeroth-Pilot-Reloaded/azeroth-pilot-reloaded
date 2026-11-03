local ns={}
assert(loadfile('APR-Core/features/navigation/NavigationV2Position.lua'))('APR',ns)
local A=assert(ns.NavigationV2Position)
local api={IsPlayerInWorld=function()return true end,
    UnitPosition=function(unit)assert(unit=='player');return 12,-4,8,0 end,
    CreateVector2D=function(x,y)return {x=x,y=y}end,
    C_Map={GetBestMapForUnit=function()return nil end}}
assert(A.Ready(api)==true)
local obs=A.Observe(api,1,false,{space='room',floor='upper',phase='blue'})
assert(obs.worldState=='ready' and obs.world==0 and obs.x==12 and obs.y==-4 and obs.z==8)
assert(obs.uiMapID==nil and obs.space=='room' and obs.floor=='upper' and obs.phase=='blue')
api.IsPlayerInWorld=function()return false end
assert(A.Ready(api)==false)
api.IsPlayerInWorld=function()error('API unavailable')end
assert(A.Ready(api)==nil)
api.IsPlayerInWorld=nil
api.IsLoggedIn=function()error('logged in is not a world-readiness source')end
assert(A.Ready(api)==nil)
local unknown=A.Observe(api,2,nil)
assert(unknown.worldState=='unknown')
api.UnitPosition=function()error('position requested during loading')end
assert(A.Observe(api,3,true).worldState=='loading')
api.UnitPosition=function()return nil,nil,nil,nil end
api.C_Map.GetBestMapForUnit=function()return 42 end
local missing=A.Observe(api,4,false)
assert(missing.world==nil and missing.x==nil and missing.uiMapID==42)
local secret={}
api.issecretvalue=function(value)return value==secret end
api.UnitPosition=function()return 12,-4,secret,0 end
local partial=A.Observe(api,5,false)
assert(partial.x==12 and partial.z==nil,'a secret Z does not erase public XY')
api.UnitPosition=function()return secret,-4,8,0 end
assert(A.Observe(api,6,false).x==nil)
api.IsPlayerInWorld=function()return secret end
assert(A.Ready(api)==nil)
api.issecretvalue=function()error('secret detector unavailable')end
assert(A.Ready(api)==nil and A.Observe(api,7,false).world==nil)

api.issecretvalue=nil
api.C_Map.GetMapPosFromWorldPos=function(world,pos,map)
    assert(world==0 and pos.x==12 and pos.y==-4 and map==42)
    return 42,{x=.25,y=.75}
end
api.C_Map.GetWorldPosFromMapPos=function(map,pos)
    assert(map==42 and pos.x==.25 and pos.y==.75)
    return 0,{x=12,y=-4}
end
local world={world=0,x=12,y=-4,z=8,floor='upper',phase='blue'}
local point=A.Project(api,world,42)
assert(point.mapID==42 and point.x==.25 and point.y==.75)
assert(world.z==8 and world.floor=='upper')
assert(select(2,A.Project(api,world,nil))=='map_missing')
api.C_Map.GetWorldPosFromMapPos=function()return 1,{x=12,y=-4}end
assert(select(2,A.Project(api,world,42))=='projection_unreliable')
api.C_Map.GetWorldPosFromMapPos=function()return 0,{x=13,y=-4}end
assert(select(2,A.Project(api,world,42))=='projection_unreliable')
api.C_Map.GetMapPosFromWorldPos=function()return 43,{x=.25,y=.75}end
assert(select(2,A.Project(api,world,42))=='projection_unreliable')
api.C_Map.GetMapPosFromWorldPos=function()return 42,{x=1.1,y=.75}end
assert(select(2,A.Project(api,world,42))=='projection_unreliable')
api.C_Map.GetMapPosFromWorldPos=function()return nil end
assert(select(2,A.Project(api,world,42))=='projection_unavailable')
api.C_Map.GetMapPosFromWorldPos=function()error('map loading')end
assert(select(2,A.Project(api,world,42))=='projection_unavailable')
assert(select(2,A.Project(api,{world=0,x=0/0,y=-4},42))=='position_missing')
