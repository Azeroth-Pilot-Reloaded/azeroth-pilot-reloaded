-- The shipping XML and APR opt-in entry point, not a manual module-only load.
local ns={}
local f=assert(io.open('APR-Core/libs/LibAPRNavigation-2.0/LibAPRNavigation.xml'))
local xml=f:read('*a');f:close()
for file in xml:gmatch('<Script%s+file="([^"]+)"') do
    assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/'..file))('APR',ns)
end
assert(ns.NavigationV2Sectors, 'shipping XML must load the partition adapter')
assert(type(ns.LibAPRNavigationV2.NewSectorGraph)=='function', 'public sector source factory required')
APR={navigation={sentinel=true}}
local legacy=APR.navigation
assert(loadfile('APR-Core/features/navigation/NavigationV2.lua'))('APR',ns)
local data={2,1,{{0,0,0}},{}}
local index={garden={name='Garden path',nodes=1,complete=true,links={}}}
local catalog={garden={complete=true,blocks={{first=1,nodes=1,edges=0,rawBytes=1,payload='x'}}}}
local decodes=0
local options={complete=true,profileClock=function()return 0 end,
    decodeBase64=function(s) decodes=decodes+1;return s end,inflate=function(s)return s end,
    deserialize=function()return data end}
assert(not APR.NavigationV2.enabled and APR.navigation==legacy)
assert(APR.NavigationV2:EnableSectors(index,catalog,options,{clock=function()return 0 end,
    profileClock=options.profileClock}))
assert(decodes==0 and APR.navigation==legacy)
APR.NavigationV2:Plan({from='garden:terrain:1',to='garden:terrain:1'})
for _=1,100 do
    local r=APR.NavigationV2:Step(1)
    if r.status~='running' then assert(r.status=='complete' and r.estimatedSeconds==0);break end
end
assert(decodes==1 and APR.NavigationV2:GetResult().status=='complete')
APR.NavigationV2:Disable()
assert(APR.navigation==legacy and not APR.NavigationV2.enabled)
