-- Geometry must retain the logical identities that distinguish shared maps.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({config={NavigationSpaces={
    {id="inside",kind="cave",worldID=8,mapIDs={501},floor="lower",bounds={minX=-1,maxX=4,minY=-1,maxY=1,minZ=0,maxZ=2},region="cave",groundOnly=true,requiresExit=true},
    {id="outside",kind="outdoor",worldID=8,mapIDs={501},bounds={minX=5,maxX=11,minY=-1,maxY=1,minZ=0,maxZ=2},region="outside"},
}},connections={}})
data.env.requestTerrainData=function()return "ready" end
local lib=LibStub("LibAPRNavigation-1.0")
lib:RegisterTerrainData("retail",8,{format=1,nodes={
    {id="in",x=0,y=0,z=1,uiMapID=501,spaceID="inside"},
    {id="out",x=10,y=0,z=1,uiMapID=501,spaceID="outside"},
},edges={{from="in",to="out",mode="ground",polyline={
    {x=0,y=0,z=1,uiMapID=501,spaceID="inside"},
    {x=5,y=0,z=1,uiMapID=501,spaceID="outside"},
    {x=10,y=0,z=1,uiMapID=501,spaceID="outside"},
}}}},1,"identity")
local job=data:CreateTerrainEdgeBuild({start={instanceID=8,x=0,y=0,z=1,noAutoconnect=true}})
local status,edges
for _=1,1000 do status,edges=job:Step(8,10);if status~="planning" then break end end
assert(status=="ready" and #edges==1)
local edge=edges[1]
assert(edge.from.spaceID=="inside" and edge.from.region=="cave" and edge.from.groundOnly,
    "A ground node keeps its exact physical cave identity, including movement restrictions")
assert(edge.to.spaceID=="outside" and edge.to.region=="outside")
assert(edge.polyline[2].spaceID=="outside" and edge.polyline[2].region=="outside",
    "A corridor may cross a physical gate on one shared UI map without inheriting the previous room")
assert(edge.polyline[2].floor==nil,"A physical exit cannot inherit the previous room's floor selector")
print("Terrain spaces: node identity, shared-map gateways and intermediate region classification passed")
