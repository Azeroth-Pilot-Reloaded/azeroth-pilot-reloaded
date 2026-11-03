local ns={}
for _,module in ipairs({'Graph','Search','Navigation','Data/Loader'}) do
    assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/'..module..'.lua'))('test',ns)
end
local declarations={island={complete=false,blocks={{first=1,nodes=2,edges=0,rawBytes=1,payload='data'}}}}
local options={profileClock=function()return 0 end,decodeBase64=function()return 'x' end,
    inflate=function()return 'x' end,deserialize=function()return {2,1,{{0,0,0},{7000,0,0}},{}} end}
local job=assert(ns.NavigationV2Terrain.New(declarations,options)):Load('island')
local loaded=job:Step()
assert(loaded.status=='complete')
local planner=assert(ns.LibAPRNavigationV2.New(loaded.graph,{clock=function()return 0 end,profileClock=options.profileClock}))
local route=planner:Plan({from='terrain:1',to='terrain:2'})
local result=route:Step()
assert(result.status=='unknown' and result.objective.to=='terrain:2')
assert(result.segments==nil, 'missing terrain must never become a direct path')
