-- Drive both real public planners through the actual native-boundary owner.
-- Codec/map observations are controlled; this is no native timing/coverage proof.
local fixture=dofile('tests/lua/navigation_fixture.lua')
fixture.profile='forever'
local normal=fixture:Load({config={IsolatedAreas={[91081]='invented-field'}},connections={}})
dofile('APR-Core/features/navigation/NavigationPlanner.lua')
local ns={}
local root='APR-Core/libs/LibAPRNavigation-2.0/'
local f=assert(io.open(root..'LibAPRNavigation.xml'));local xml=f:read('*a');f:close()
for path in xml:gmatch('<Script%s+file="([^"]+)"') do assert(loadfile(root..path))('test',ns)end
for _,path in ipairs({'NavigationV2Position','NavigationBenchmarkCase','NavigationBenchmarkRun',
    'NavigationBenchmarkV1','NavigationBenchmarkV2','NavigationBenchmarkHost'})do
 assert(loadfile('APR-Core/features/navigation/'..path..'.lua'))('test',ns)
end
local wire={2,1,{{0,0,0},{0,0,14000}},{{1,2,2000}}}
ns.NavigationV2TerrainCatalog={fixture={client='wowf',build='1.60.1.70755',mapId=77,complete=false,
 blocks={{first=1,nodes=2,edges=1,rawBytes=4,payload='wire'}}}}
local api={
 LibStub=LibStub,GetBuildInfo=function()return '1.60.1','70755','',16001 end,
 GetTimePreciseSec=function()return 1 end,debugprofilestop=function()return 10 end,
 CreateVector2D=function(x,y)return {x=x,y=y}end,
 Enum={Base64Variant={Standard=1},CompressionMethod={Deflate=1}},
 C_EncodingUtil={DecodeBase64=function(s)return s end,DecompressString=function(s)return s end,
  DeserializeCBOR=function(s)assert(s=='wire');return wire end},
 C_Map={GetMapPosFromWorldPos=function(world,p,map)
  assert(world==77 and map==91081);return map,{x=p.x/100,y=p.y/100}
 end,GetWorldPosFromMapPos=function(map,p)assert(map==91081);return 77,{x=p.x*100,y=p.y*100}end},
}
local loads=0
local apr={NavigationPlanner=APR.NavigationPlanner,
 NavigationAdapter={environment={
  getMapInfo=function(id)return {mapID=id,parentMapID=0,mapType=3}end,
  mapToWorld=function(_,x,y)return 77,x*100,y*100 end,
  getCharacter=function()return {faction='Alliance',level=40,class='MAGE',raceID=1,mapID=91081}end,
 }},NavigationV2={LoadTerrain=function(_,id,options)
  loads=loads+1;return assert(ns.NavigationV2Terrain.New(ns.NavigationV2TerrainCatalog,options)):Load(id)
 end}}
local owner=ns.NavigationBenchmarkHost.New({api=api,apr=apr,
 engines={v1=ns.NavigationBenchmarkV1,v2=ns.NavigationBenchmarkV2}})
local input={from={mapID=91081,x=0,y=0},to={mapID=91081,x=14,y=0}}
assert(owner:Start(input,'both'));assert(loads==0)
local state
for _=1,2000 do state=owner:Step();if state.status~='running' then break end end
assert(state.status=='finished')
assert(state.engines.v1.status=='complete' and math.abs(state.engines.v1.estimatedSeconds-2)<1e-9,
 tostring(state.engines.v1.status)..':'..tostring(state.engines.v1.reason))
assert(state.engines.v1.metrics.calculationsStarted>=1 and state.engines.v1.metrics.searchStepCalls>0)
assert(loads==1 and state.engines.v2.metrics.calculationsStarted==1,
 tostring(loads)..':'..tostring(state.engines.v2.status)..':'..tostring(state.engines.v2.reason))
assert(state.engines.v2.metrics.calculationsCompleted==1 and state.engines.v2.metrics.searchStepCalls>0)
assert(state.engines.v2.status=='unknown' and state.engines.v2.estimatedSeconds==nil,
 'Technical graph query must not invent the missing physical endpoint identity')
assert(state.engines.v2.metrics.operations>0)
assert(owner:GetCapture().from.x==0 and owner:GetCapture().to.x==14)
assert(APR.NavigationData==normal)
local context=owner:GetContext()
assert(context.engines.v1.scope and context.engines.v2.scope)
assert(owner:GetReport():find('calculationsCompleted') and owner:GetReport():find('non%-comparable'))
print('Benchmark integration: actual V1/V2 public planners, actual V2 loader, paired map inputs and unknown physical identity passed; no native latency claim')

-- Both real public planners on an immutable synthetic captured request.
-- A declared directed portal joins two worlds; no ground/proximity edge can do so.
do
    local f=dofile('tests/lua/navigation_fixture.lua')
    f.profile='forever'
    local original=f:Load({config={},connections={{id='invented-paired-portal',kind='portal',seconds=3,
        from={space='world',instanceID=77,uiMapID=91081,x=0,y=0},
        to={space='world',instanceID=78,uiMapID=91082,x=14,y=0}}}})
    dofile('APR-Core/features/navigation/NavigationPlanner.lua')
    local n={}
    local root='APR-Core/libs/LibAPRNavigation-2.0/'
    local file=assert(io.open(root..'LibAPRNavigation.xml'));local xml=file:read('*a');file:close()
    for path in xml:gmatch('<Script%s+file="([^"]+)"')do assert(loadfile(root..path))('test',n)end
    for _,name in ipairs({'NavigationV2Position','NavigationV2Personal','NavigationV2Conditions',
        'NavigationBenchmarkCase','NavigationBenchmarkRun','NavigationBenchmarkV1',
        'NavigationBenchmarkV2','NavigationBenchmarkPreparation','NavigationBenchmarkHost'})do
        assert(loadfile('APR-Core/features/navigation/'..name..'.lua'))('test',n)
    end
    local environment={mapToWorld=function(map,x,y)
        return map==91081 and 77 or 78,x*100,y*100
    end,getMapInfo=function(id)return {mapID=id,parentMapID=0,mapType=3}end,
    getCharacter=function()return {faction='Alliance',level=40,class='MAGE',raceID=1}end}
    local api={LibStub=LibStub,GetBuildInfo=function()return '1.60.1','70755','',16001 end,
        GetTimePreciseSec=function()return 1 end,GetTime=function()return 1 end,
        debugprofilestop=function()return 10 end,
        CreateFrame=function()error('Paired calculation must not create a frame or action')end}
    local marker={}
    local hostAPR={NavigationPlanner=APR.NavigationPlanner,NavigationData=original,
        NavigationAdapter={environment=environment},Navigation=marker}
    local host=n.NavigationBenchmarkHost.New({api=api,apr=hostAPR,
        engines={v1=n.NavigationBenchmarkV1,v2=n.NavigationBenchmarkV2}})
    local input={startMode='manual',from={mapID=91081,x=0,y=0},to={mapID=91082,x=14,y=0}}
    assert(host:Start(input,'both'))
    input.from.x=99;input.to.x=99
    local state
    for _=1,2000 do state=host:Step();if state.status~='running' then break end end
    assert(state.status=='finished')
    for _,key in ipairs({'v1','v2'})do
        local engine=state.engines[key]
        assert(engine.status=='complete',key..':'..tostring(engine.status)..':'..tostring(engine.reason))
        assert(engine.estimatedSeconds==3,'Declared portal total remains independently chosen3s')
        assert(engine.metrics.calculationsStarted==1 and engine.metrics.calculationsCompleted==1)
        assert(engine.metrics.searchStepCalls>0 and engine.cpuMs~=nil and engine.wallMs~=nil)
    end
    assert(state.engines.v2.metrics.preparationStepCalls>0,'Use actual prepared data, not old codec fallback')
    assert(host:GetCapture().from.x==0 and host:GetCapture().to.x==14)
    assert(hostAPR.Navigation==marker and hostAPR.NavigationData==original and APR.NavigationData==original)
    print('Paired public preparation: both planners complete the same captured directed portal; active navigation untouched')
end
