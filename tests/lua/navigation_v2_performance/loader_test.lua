local ns={}
for _,name in ipairs({'Conditions','Graph','Data/Loader'})do
    assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/'..name..'.lua'))('test',ns)
end
local cpu,wall=0,0
local options={profileClock=function()return cpu end,clock=function()return wall end,
    decodeBase64=function(s)cpu=cpu+101;return s end,inflate=function(s)return s end,
    deserialize=function()return {2,1,{{0,0,0}}, {}} end}
local catalog={sample={complete=true,blocks={{first=1,nodes=1,edges=0,rawBytes=1,payload='x'}}}}
local loader=assert(ns.NavigationV2Terrain.New(catalog,options))
local job=loader:Load('sample')
local result=job:Step(64)
assert(result.status=='budget_exceeded' and result.reason=='cpu_budget' and not result.graph)
assert(job:Step()==result,'a stopped decode must not retry unchanged')
options.decodeBase64=function(s)return s end
loader=assert(ns.NavigationV2Terrain.New(catalog,options))
job=loader:Load('sample');wall=6
result=job:Step()
assert(result.status=='budget_exceeded' and result.reason=='elapsed_budget')
assert(result.diagnostics.operations==0,'elapsed limit also applies before first decode')
