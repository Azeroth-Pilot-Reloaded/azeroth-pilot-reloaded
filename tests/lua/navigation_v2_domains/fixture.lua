local F=dofile('tests/lua/navigation_v2/fixture.lua')
local library,ns=F.Load()
local root='APR-Core/libs/LibAPRNavigation-2.0/'
for name,field in pairs({['Localization/Domains.lua']='NavigationV2Domains',
    ['Data/DomainGraph.lua']='NavigationV2DomainGraph'}) do
    if not ns[field] then assert(loadfile(root..name))('test',ns) end
end
F.Library,F.ns=library,ns
function F.Geography()
    return {client='forever',spaces={
        mainland={id='mainland',worldID=0,kind='outdoor',mapIDs={701},bounds={minX=0,maxX=20,minY=-2,maxY=2}},
        cove={id='cove',worldID=0,kind='outdoor',mapIDs={702},bounds={minX=20,maxX=60,minY=-2,maxY=2}},
        other={id='other',worldID=1,kind='outdoor',mapIDs={703}},
    },isolation={{id='cove-isolation',uiMapID=702,key='cove-isolation'}}}
end
function F.Point(x,world,map)
    return {world=world or 0,x=x,y=0,uiMapID=map or 701}
end
return F
