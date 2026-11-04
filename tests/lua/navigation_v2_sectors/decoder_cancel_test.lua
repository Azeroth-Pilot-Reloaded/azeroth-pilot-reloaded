local ns={}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Data/Loader.lua'))('test',ns)
local catalog={garden={complete=true,blocks={{first=1,nodes=1,edges=0,rawBytes=1,payload='x'}}}}
local job,decodes
local options={decodeBase64=function(s) decodes=decodes+1;return s end,
    inflate=function(s)return s end,deserialize=function()return {2,1,{{0,0,0}},{}} end}
for _,phase in ipairs({'base64','nodes'}) do
    decodes=0
    options.profileClock=function()
        if job and job.phase==phase then job:Cancel() end
        return 0
    end
    job=assert(ns.NavigationV2Terrain.New(catalog,options)):Load('garden')
    assert(job:Step().status=='cancelled', 'clock callbacks can cancel between loader operations')
    if phase=='base64' then assert(decodes==0, 'a cancelled decoder must not start') end
end
