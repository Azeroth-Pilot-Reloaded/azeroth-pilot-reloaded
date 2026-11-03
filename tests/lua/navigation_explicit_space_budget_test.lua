-- A recorded point already names its space; unrelated rooms cannot affect it.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({connections={}})
fixture.maps[501]={mapID=501,mapType=3,parentMapID=502}
fixture.maps[502]={mapID=502,mapType=2,parentMapID=0}
local spaces={{id="outside",kind="outdoor",worldID=8,mapIDs={502},requiresExit=true}}
for i=1,800 do
    spaces[#spaces+1]={id="room-"..i,kind="building",worldID=8,mapIDs={501},parentSpace="outside",
        accessKey="owner",floor=2,groundOnly=true,
        bounds={minX=0,maxX=10,minY=0,maxY=10,minZ=1,maxZ=3}}
end
spaces[#spaces+1]={id="area-only",kind="subzone",worldID=8,mapIDs={},areaIDs={701},
    bounds={minX=0,maxX=10,minY=0,maxY=10,minZ=1,maxZ=3}}
spaces[#spaces+1]={id="mapless",kind="building",worldID=8,mapIDs={},
    bounds={minX=0,maxX=10,minY=0,maxY=10,minZ=1,maxZ=3}}
data.config.NavigationSpaces=spaces
assert(data:GetNavigationSpace("room-500")) -- Construct the declaration index once.
local reads=0
for _,space in ipairs(spaces) do
    if space.bounds then
        local fields=space.bounds
        space.bounds=setmetatable({}, {__index=function(_,key) reads=reads+1;return fields[key] end})
    end
end
local function point(extra)
    local p={instanceID=8,uiMapID=501,x=5,y=5,z=2,floor=2,accessKey="owner",spaceID="room-500"}
    for key,value in pairs(extra or {}) do p[key]=value end
    return p
end
for _=1,100 do
    local before=reads
    local space,reason=data:ResolveNavigationSpace(point())
    assert(space and space.id=="room-500" and space.known and space.groundOnly and space.requiresExit
        and space.floor==2 and space.accessKey=="owner" and reason=="declared_navigation_space")
    assert(reads-before<50,"An explicit point must not scan hundreds of unrelated overlapping rooms")
end
local function rejected(p,expected)
    local space,reason=data:ResolveNavigationSpace(p)
    assert(not space and reason==expected,tostring(reason).." ~= "..expected)
end
rejected(point({spaceID="missing"}),"navigation_space_unavailable")
rejected(point({spaceID=12}),"invalid_navigation_position")
rejected(point({instanceID=9}),"navigation_space_unavailable")
rejected(point({x=11}),"navigation_space_unavailable")
rejected(point({z=4}),"navigation_space_unavailable")
rejected(point({floor=3}),"navigation_space_unavailable")
rejected(point({accessKey="visitor"}),"navigation_space_unavailable")
local unknown=point();unknown.floor=nil;unknown.z=nil
rejected(unknown,"navigation_space_identity_unavailable")
unknown=point();unknown.accessKey=nil
rejected(unknown,"navigation_space_identity_unavailable")
-- Native map ancestry, area-only and bounded mapless spaces keep their gates.
assert(data:ResolveNavigationSpace(point({spaceID="outside"})).id=="outside")
assert(data:ResolveNavigationSpace(point({spaceID="area-only",areaID=701})).id=="area-only")
rejected(point({spaceID="area-only",areaID=702}),"navigation_space_unavailable")
local mapless=point({spaceID="mapless"});mapless.uiMapID=nil
assert(data:ResolveNavigationSpace(mapless).id=="mapless")
data.config.IsolatedAreas=data.config.IsolatedAreas or {}
data.config.IsolatedAreas[501]="closed"
rejected(point({spaceID="outside"}),"navigation_space_unavailable")
data.config.IsolatedAreas[501]=nil
fixture.maps[501].mapType=4
data:InvalidatePositionCache()
rejected(point({spaceID="outside"}),"navigation_space_unavailable")
fixture.maps[501].mapType=3
data:InvalidatePositionCache()
-- An unqualified lookup still detects overlapping declarations.
local unspecified=point();unspecified.spaceID=nil
rejected(unspecified,"ambiguous_navigation_space")
print("Explicit spaces: bounded indexed lookup, inherited gates, native ancestry, unknown height and ambiguity passed")
