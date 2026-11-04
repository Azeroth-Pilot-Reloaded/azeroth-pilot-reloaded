local ns = {}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Data/Loader.lua'))('test', ns)
local Loader = ns.NavigationV2Terrain
local raw = {2, 1, {{0,0,0}, {7000,0,0}}, {{1,2,1000}}}
local decoded = 0
local options = {
    profileClock = function() return 0 end,
    decodeBase64 = function(s) decoded=decoded+1; assert(s=='payload'); return 'deflate' end,
    inflate = function(s) assert(s=='deflate'); return 'cbor' end,
    deserialize = function(s) assert(s=='cbor'); return raw end,
}
local catalog = { sector = {complete=false, blocks={{first=1,nodes=2,edges=1,rawBytes=4,payload='payload'}}} }
local loader = assert(Loader.New(catalog, options))
local job = loader:Load('sector')
assert(decoded==0, 'Load must defer native decoding')
local r = job:Step(1)
assert(r.status=='running' and decoded==0)
job:Step(1)
r=job:Step(1)
assert(r.status=='running' and decoded==1)
for i=1,30 do r=job:Step(1); if r.status~='running' then break end end
assert(r.status=='complete' and #r.graph.nodes==2 and #r.graph.edges==1)
assert(r.graph.complete==false and r.graph.edges[1].seconds==1)
assert(r.positions['terrain:2'][1]==7)
assert(loader:Load('missing'):Step().reason=='sector_absent')
local cancelled=loader:Load('sector');cancelled:Cancel();assert(cancelled:Step().status=='cancelled')
local partial=loader:Load('sector')
for i=1,7 do partial:Step(1) end
local before=decoded
assert(partial:Cancel().status=='cancelled')
assert(partial:Step().status=='cancelled' and decoded==before)
local count=decoded
catalog.sector.blocks[1].rawBytes=65537
assert(loader:Load('sector'):Step().reason=='block_over_limit' and decoded==count)
catalog.sector.blocks[1].rawBytes=4
options.inflate=function() return nil end
local broken=assert(Loader.New(catalog, options)):Load('sector')
for i=1,5 do r=broken:Step(1);if r.status~='running' then break end end
assert(r.status=='unknown' and r.reason=='decode_failed')
options.inflate=function() return 'cbor' end
raw[4]={{1,3,1000}}
local invalid=assert(Loader.New(catalog,options)):Load('sector')
for i=1,30 do r=invalid:Step(1);if r.status~='running' then break end end
assert(r.status=='invalid' and r.reason=='invalid_edge')
raw[4]={{1,2,1000}}
local reentrant
options.inflate=function() reentrant:Cancel();return 'cbor' end
reentrant=assert(Loader.New(catalog,options)):Load('sector')
assert(reentrant:Step().status=='cancelled')
options.inflate=function() return 'cbor' end
local timed=assert(Loader.New(catalog,options)):Load('sector')
assert(select(2,timed:Step(0))=='invalid_step_budget')
options.profileClock=function() return nil end
assert(assert(Loader.New(catalog,options)):Load('sector'):Step().reason=='clock_unavailable')
local calls=0
options.profileClock=function() calls=calls+1;return calls end
local sliced=assert(Loader.New(catalog,options)):Load('sector')
assert(sliced:Step(4096).status=='running')
assert(sliced.diagnostics.operations==1, 'time limit must stop between units')
local api={DecodeBase64=function(s,v) assert(v==17);return s end,
    DecompressString=function(s,v) assert(v==29);return s end,DeserializeCBOR=function(s) return s end}
local client=assert(Loader.ClientOptions(api,{Base64Variant={Standard=17},CompressionMethod={Deflate=29}},function()return 0 end))
assert(client.decodeBase64('input')=='input' and client.inflate('data')=='data')
assert(Loader.ClientOptions({}, {},function()return 0 end)==nil)
