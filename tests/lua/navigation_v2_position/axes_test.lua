-- Existing APR authoring boundary independently relates C_Map axes to APR's
-- historical pair. No V1 navigation implementation is loaded.
local ns={}
local locale=setmetatable({}, {__index=function(_,key)return key end})
LibStub=function()return {GetLocale=function()return locale end}end
APR={NewModule=function()return {}end}
local nativeX,nativeY=123,-987
CreateVector2D=function(x,y)return {x=x,y=y}end
C_Map={GetWorldPosFromMapPos=function(map,point)
    assert(map==42 and point.x==.25 and point.y==.75)
    return 0,{x=nativeX,y=nativeY}
end}
assert(loadfile('APR-Core/features/navigation/WorldCoordinateConverter.lua'))()
local apr=assert(APR.worldCoordinateConverter:ConvertMapCoordinate(42,25,75))
assert(apr.x==nativeY and apr.y==nativeX,'existing APR coordinate contract')
assert(loadfile('APR-Core/features/navigation/NavigationV2Position.lua'))('APR',ns)
local api={CreateVector2D=CreateVector2D,UnitPosition=function()return apr.y,apr.x,17,0 end,C_Map={}}
api.C_Map.GetMapPosFromWorldPos=function(world,point,map)
    assert(world==0 and map==42)
    assert(point.x==123 and point.y==-987,'C_Map vector uses native X,Y order')
    return 42,{x=.25,y=.75}
end
api.C_Map.GetWorldPosFromMapPos=C_Map.GetWorldPosFromMapPos
local observation=ns.NavigationV2Position.Observe(api,1,false)
assert(observation.x==123 and observation.y==-987 and observation.z==17)
assert(ns.NavigationV2Position.Project(api,observation,42).x==.25)
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Localization/World.lua'))('APR',ns)
local terrain=ns.NavigationV2World.FromTerrain({-987,17,123},0)
assert(terrain.x==123 and terrain.y==-987 and terrain.z==17)
