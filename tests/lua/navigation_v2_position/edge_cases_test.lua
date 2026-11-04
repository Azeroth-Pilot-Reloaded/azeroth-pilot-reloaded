local ns={}
assert(loadfile('APR-Core/features/navigation/NavigationV2Position.lua'))('APR',ns)
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Localization/World.lua'))('APR',ns)
local A,W=ns.NavigationV2Position,ns.NavigationV2World
local api={UnitPosition=function()return 0,0,0,0 end,
    C_Map={GetBestMapForUnit=function()return 0 end}}
local observation=A.Observe(api,1,false)
local t=W.New()
local _,snapshot=t:Observe(observation)
assert(snapshot.quality=='world_position' and snapshot.uiMapID==nil and snapshot.z==0)
assert(W.Match(snapshot,{}))
assert(not W.New():IsCurrent(snapshot))
api.UnitPosition=function()return 0/0,math.huge,-math.huge,-1 end
api.C_Map.GetBestMapForUnit=function()error('no map')end
local _,bad=t:Observe(A.Observe(api,2,false))
assert(bad.quality=='position_missing' and bad.x==nil and bad.y==nil and bad.z==nil and bad.world==nil)
local calls=0
api.UnitPosition=function()calls=calls+1;return 10,20,30,0 end
assert(A.Observe(api,3,nil).worldState=='unknown')
assert(A.Observe(api,4,true).worldState=='loading')
assert(calls==0,'loading and unknown must not even query incidental coordinates')

api.CreateVector2D=function(x,y)return {x=x,y=y}end
local position={world=0,x=0,y=0,z=0}
local secret=setmetatable({}, {__index=function()error('secret vector accessed')end})
api.issecretvalue=function(value)return rawequal(value,secret)end
api.C_Map.GetMapPosFromWorldPos=function()return 42,secret end
assert(select(2,A.Project(api,position,42))=='projection_unavailable')
api.C_Map.GetMapPosFromWorldPos=function()return 42,{x=secret,y=0}end
assert(select(2,A.Project(api,position,42))=='projection_unreliable')
api.issecretvalue=nil
local opaque=setmetatable({}, {__index=function()error('restricted member')end})
api.C_Map.GetMapPosFromWorldPos=function()return 42,opaque end
assert(select(2,A.Project(api,position,42))=='projection_unreliable')
api.C_Map.GetMapPosFromWorldPos=function()return 42,{x=0,y=1}end
api.C_Map.GetWorldPosFromMapPos=function()return 0,{x=0,y=0}end
local point=assert(A.Project(api,position,42))
assert(point.x==0 and point.y==1,'normalized boundaries are valid')
-- Inverse API would successfully round-trip even for the wrong requested map
-- or out-of-range map point. Reject each independently before trusting it.
api.C_Map.GetMapPosFromWorldPos=function()return 43,{x=0,y=1}end
assert(select(2,A.Project(api,position,42))=='projection_unreliable')
api.C_Map.GetMapPosFromWorldPos=function()return 42,{x=1.1,y=1}end
assert(select(2,A.Project(api,position,42))=='projection_unreliable')
api.C_Map.GetMapPosFromWorldPos=function()return 42,{x=0,y=-.1}end
assert(select(2,A.Project(api,position,42))=='projection_unreliable')
api.C_Map.GetMapPosFromWorldPos=function()return 42,{x=0,y=1.1}end
assert(select(2,A.Project(api,position,42))=='projection_unreliable')
api.CreateVector2D=nil
assert(select(2,A.Project(api,position,42))=='projection_unavailable')
api.C_Map=nil
assert(select(2,A.Project(api,position,42))=='projection_unavailable')
