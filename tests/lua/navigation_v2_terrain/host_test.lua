local ns={}
local file=assert(io.open('APR-Core/libs/LibAPRNavigation-2.0/LibAPRNavigation.xml'))
local xml=file:read('*a');file:close()
for name in xml:gmatch('<Script%s+file="([^"]+)"') do
    assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/'..name))('APR',ns)
end
local legacy={sentinel=true}
local function Forbidden() error('Terrain loading must not publish guidance or change quest progress') end
APR={navigation=legacy,NextQuestStep=Forbidden}
local observation=dofile('tests/lua/navigation_v2_waypoint/fixture.lua').EventEnvironment()
CreateFrame,WaypointUIAPI=observation.CreateFrame,{Navigation={Set=Forbidden}}
assert(loadfile('APR-Core/features/navigation/NavigationV2.lua'))('APR',ns)
local host=APR.NavigationV2
local count=0
local data={2,1,{{0,0,0},{7000,0,0}},{{1,2,1000}}}
ns.NavigationV2TerrainCatalog={synthetic={complete=false,blocks={{first=1,nodes=2,edges=1,rawBytes=1,payload='data'}}}}
local options={profileClock=function()return 0 end,
    decodeBase64=function()count=count+1;return 'x' end,
    inflate=function()return 'x' end,deserialize=function()return data end}
local loading=assert(host:LoadTerrain('synthetic',options))
assert(count==0 and not host.enabled and APR.navigation==legacy)
local result=loading:Step()
assert(result.status=='complete' and count==1 and not host.enabled)
assert(#observation.frames==0,'Loading terrain alone creates no world observation or guidance')
assert(host:Enable(result.graph,{clock=function()return 0 end,profileClock=options.profileClock}))
host:ObserveWorld(false)
assert(#observation.frames==1 and observation:OnlyWorldEvents())
host:Plan({from='terrain:1',to='terrain:2'})
local planned=host:Step()
assert(planned.status=='complete' and planned.estimatedSeconds==1 and APR.navigation==legacy)
assert(host:LoadTerrain('missing',options):Step().reason=='sector_absent')
assert(host.enabled and host:GetResult()==planned)
local partial=host:LoadTerrain('synthetic',options);partial:Step(1)
assert(partial:Cancel().status=='cancelled' and partial:Step().status=='cancelled')
assert(select(2,host:LoadTerrain('synthetic'))=='decoder_unavailable')
debugprofilestop=options.profileClock
Enum={Base64Variant={Standard=0},CompressionMethod={Deflate=0}}
C_EncodingUtil={DecodeBase64=function(s,v)assert(v==0);return 'x' end,
    DecompressString=function(s,v)assert(v==0);return 'x' end,DeserializeCBOR=function()return data end}
assert(host:LoadTerrain('synthetic'):Step().status=='complete')
host:Disable();assert(APR.navigation==legacy and next(observation.events)==nil)
