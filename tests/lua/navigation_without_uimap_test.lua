-- A proved navigation space can exist in a native world with no UI map.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local nativeMap=C_Map
local opaque,inaccessible={},{}
function issecretvalue(value)return rawequal(value,opaque)end
local function bounded(id,world,minX,maxX,minZ,maxZ)
    return {id=id,kind="instance",worldID=world,mapIDs={},groundOnly=true,requiresExit=true,
        bounds={minX=minX,maxX=maxX,minY=0,maxY=40,minZ=minZ,maxZ=maxZ}}
end
local spaces={bounded("interior",7,0,40,10,20),bounded("other-room",7,80,120,10,20),
    bounded("lower",8,0,40,0,5),bounded("upper",8,0,40,20,25),bounded("explicit-region",9,0,40,10,20)}
spaces[5].region="authored-access-region"
spaces[3].kind,spaces[3].floor="floor","lower"
spaces[4].kind,spaces[4].floor="floor","upper"
for _,profile in ipairs({"retail","forever"})do
    C_Map=nativeMap
    fixture.profile,fixture.player=profile,{instanceID=71,x=10,y=20,z=15}
    local data=fixture:Load({config={NavigationSpaces=spaces,WorldInstanceOverrides={[71]=7}},connections={}})
    function APR:CanAccessValue(value)return not rawequal(value,inaccessible)end
    dofile("APR-Core/utils/NavigationZones.lua")
    local mapCalls=0
    data.env.worldToMap=function()mapCalls=mapCalls+1;return 13 end
    C_Map.GetBestMapForUnit=function()return nil end
    local observed=APR:GetNavigationPlayerPosition()
    assert(observed and observed.uiMapID==nil and observed.instanceID==7 and observed.spaceID=="interior",
        "A bounded native instance remains observable without inventing a UI map")
    assert(observed.x==10 and observed.y==20 and observed.z==15 and observed.observedZ==15
        and observed.positionSource=="unit" and observed.groundOnly and observed.requiresExit)
    assert(observed.region=="7:space:interior","A mapless space has its own stable physical access identity")
    assert(mapCalls==0,"Known mapless spaces must not project onto an unrelated continent")
    local normalized=data:NormalizeLocation(observed)
    assert(normalized.uiMapID==nil and normalized.spaceID=="interior" and normalized.region==observed.region)
    local authored=data:NormalizeLocation({instanceID=71,x=12,y=20,z=15,spaceID="interior"})
    assert(authored.uiMapID==nil and authored.region==observed.region and mapCalls==0,
        "Explicit mapless authored points keep world coordinates and skip automatic UI projection")
    local implicit=data:NormalizeLocation({instanceID=7,x=15,y=20,z=15})
    assert(implicit.uiMapID==nil and implicit.spaceID=="interior" and mapCalls==0)
    assert(data:CanWalk(observed,implicit) and not data:CanWalk(observed,{instanceID=7,x=90,y=20,z=15}),
        "Two distinct mapless interiors require a physical connector")
    assert(data:GetPositionRegion({instanceID=9,x=10,y=20,z=15})=="authored-access-region",
        "A declared explicit access region takes precedence over the mapless fallback")
    function APR:ResolvePlayerZoneContext()error("No UI context exists for this native world")end
    local ready,why=APR:CheckNavigationZoneReady(implicit,{playerPosition=observed,threshold=6})
    assert(ready and why=="nearby_connected","Zone readiness uses the proved world-space connection")
    ready,why=APR:CheckNavigationZoneReady(implicit,{playerPosition=observed,threshold=5})
    assert(not ready and why=="too_far","Mapless readiness keeps the existing strict distance boundary")
    local search=data:CreateSearch({start=normalized,goal=implicit,edges={},walkSpeed=5,
        canWalk=function(a,b)return data:CanWalk(a,b)end})
    local status,route
    for _=1,1000 do status,route=search:Step(8,100);if status~="planning"then break end end
    assert(status=="ready" and #route.segments==1 and route.segments[1].kind=="walk"
        and math.abs(route.totalSeconds-1)<0.00001 and route.segments[1].to.uiMapID==nil,
        "The ordinary coordinate search can route inside an attested world without a UI map")
    for _,getMap in ipairs({false,function()error("map not available")end})do
        C_Map.GetBestMapForUnit=getMap or nil
        assert(APR:GetNavigationPlayerPosition().spaceID=="interior","Optional map API failures retain proved world observations")
    end
    C_Map=nil
    assert(APR:GetNavigationPlayerPosition().spaceID=="interior","The optional map namespace may be absent")
    C_Map=nativeMap
    for _,value in ipairs({false,0,-1,1.5,math.huge,0/0,"unknown",opaque,inaccessible})do
        C_Map.GetBestMapForUnit=function()return value end
        assert(APR:GetNavigationPlayerPosition()==nil,"A nonnil invalid or protected map identity cannot be bypassed by spatial matching")
    end
    C_Map.GetBestMapForUnit=function()return nil end
    fixture.player={instanceID=8,x=10,y=20,z=0}
    observed=APR:GetNavigationPlayerPosition()
    assert(observed and observed.uiMapID==nil and observed.spaceID==nil and observed.region==nil and observed.observedZ==0,
        "Ambiguous mapless floors retain the raw observation while waiting for height proof")
    normalized=data:NormalizeLocation(observed)
    assert(normalized and normalized.uiMapID==nil and normalized.region==nil and mapCalls==0,
        "An ambiguous bounded world must not be flattened onto a guessed continent")
    ready,why=APR:CheckNavigationZoneReady({instanceID=8,x=15,y=20,z=22},{playerPosition=observed})
    assert(not ready and why=="waiting_data","Unknown floor identity cannot declare the target zone ready")
    fixture.player.z=22
    observed=APR:GetNavigationPlayerPosition()
    assert(observed.spaceID=="upper" and observed.region=="8:space:upper","A later proven height recovers without restarting navigation")
    fixture.player={instanceID=10,x=10,y=20,z=15}
    assert(APR:GetNavigationPlayerPosition()==nil,"A missing UI map in an undeclared world remains unavailable")
    fixture.player={instanceID=7,x=60,y=20,z=15}
    assert(APR:GetNavigationPlayerPosition()==nil,"Being outside the declared bounds cannot borrow a mapless space identity")
    fixture.player={instanceID=7,x=10,y=20,z=30}
    assert(APR:GetNavigationPlayerPosition()==nil,"Known incompatible altitude cannot be discarded")
    C_Map.GetBestMapForUnit=function()return 501 end
    assert(APR:GetNavigationPlayerPosition().uiMapID==501,"Native map availability can recover normally")
end
print("Mapless navigation: native observations, physical regions, ambiguous floors, strict map validation and API recovery")
