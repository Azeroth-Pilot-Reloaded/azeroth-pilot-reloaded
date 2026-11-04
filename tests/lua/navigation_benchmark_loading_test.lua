-- The shipped TOC must expose the actual diagnostic, while loading remains dormant.
local ns={NavigationV2Graph={Budgets={sliceMs=1,cpuMs=100,elapsedMs=5000}}}
local navigation,data={status='unchanged'},{marker='unchanged'}
APR={Navigation=navigation,NavigationData=data,UI={}}
local L=setmetatable({},{__index=function(_,key)return key end})
LibStub=function(name)
 assert(name=='AceLocale-3.0','Loading the benchmark must not construct an engine')
 return {GetLocale=function()return L end}
end
CreateFrame=function()error('Benchmark frames must be lazy')end
GetBuildInfo=function()error('Build queries belong to Start')end
GetTimePreciseSec=function()error('Native clocks belong to Start')end
C_Map={GetPlayerMapPosition=function()error('Player position belongs to Start')end}
local libraryRoot='APR-Core/libs/LibAPRNavigation-2.0/'
local libraryManifest=assert(io.open(libraryRoot..'LibAPRNavigation.xml','r'))
local libraryXML=libraryManifest:read('*a');libraryManifest:close()
for path in libraryXML:gmatch('<Script file="([^"]+)"') do
 assert(loadfile(libraryRoot..path))('test',ns)
end
assert(ns.NavigationV2Retail and ns.NavigationV2RetailData,'The shipped library must expose its Retail movement and data modules')
assert(ns.NavigationV2ForeverData,'The shipped library must expose its Forever data module')
local manifest=assert(io.open('APR.toc','r'))
for path in manifest:lines() do
 path=path:gsub('\r$','')
 if (path:find('/NavigationBenchmark',1,true) or path:find('/NavigationV2Planner.lua',1,true)) and path:match('%.lua$') then
  assert(loadfile(path))('test',ns)
 end
end
manifest:close()
assert(ns.NavigationBenchmarkCase and ns.NavigationBenchmarkRun)
assert(ns.NavigationBenchmarkV1 and type(ns.NavigationBenchmarkV1.Create)=='function')
assert(ns.NavigationBenchmarkV2 and type(ns.NavigationBenchmarkV2.Create)=='function')
assert(type(ns.NavigationV2PrepareBenchmark)=='function','The shipped benchmark must load its data preparation bridge')
assert(APR.NavigationV2Planner and type(APR.NavigationV2Planner.Create)=='function',
 'The shipped TOC must expose the normal APR opt-in V2 planner without starting it')
assert(APR.NavigationBenchmark and type(APR.NavigationBenchmark.Show)=='function')
assert(APR.NavigationBenchmark:GetState().status=='idle')
assert(APR.Navigation==navigation and APR.NavigationData==data)
print('Benchmark TOC: real lazy modules reachable without engine/native/player/frame work or navigation mutations passed')
