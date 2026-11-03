local F = {}
function F.New(config)
    config = config or {}
    local ns = {}
    for _, file in ipairs({'Graph','Search','Navigation','Data/Loader','Data/Sectors'}) do
        assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/'..file..'.lua'))('test', ns)
    end
    local data = {
        meadow={2,1,{{0,0,0},{7000,0,0}},{{1,2,1000}}},
        pass={2,1,{{8000,0,0},{15000,0,0}},{{1,2,1000}}},
        harbor={2,1,{{16000,0,0},{23000,0,0}},{{1,2,1000}}},
    }
    local index = {
        meadow={name='Quiet meadow',nodes=2,complete=true,links={
            {id='mountain-pass',name='Mountain pass',from=2,sector='pass',to=1,seconds=2},
            {id='slow-trail',name='Coastal trail',from=1,sector='harbor',to=2,seconds=20},
        }},
        pass={name='Mountain pass',nodes=2,complete=true,links={
            {id='harbor-road',name='Harbor road',from=2,sector='harbor',to=1,seconds=3},
        }},
        harbor={name='Sheltered harbor',nodes=2,complete=true,links={}},
        -- Indexed but never decoded for a meadow -> harbor request.
        island={name='Distant island',nodes=1,complete=true,links={}},
    }
    local catalog = {}
    for id, raw in pairs(data) do
        catalog[id]={complete=true,blocks={{first=1,nodes=#raw[3],edges=#raw[4],rawBytes=#id,payload=id}}}
    end
    if config.edit then config.edit(index,catalog,data) end
    local time, decodes = {wall=0,cpu=0,tick=0}, {}
    local options = {
        profileClock=function() local n=time.cpu; time.cpu=n+time.tick; return n end,
        decodeBase64=function(id) decodes[id]=(decodes[id] or 0)+1; return id end,
        inflate=function(id) return id end,
        deserialize=function(id) if config.decode then config.decode(id) end; return data[id] end,
    }
    local loader=assert(ns.NavigationV2Terrain.New(catalog,options))
    local source={partitioned=true,index=index,loader=loader,cacheSize=config.cacheSize or 2,complete=true}
    local planner=assert(ns.LibAPRNavigationV2.New(source,{
        clock=function() return time.wall end,profileClock=options.profileClock,budgets=config.budgets}))
    return planner,decodes,time,source,ns
end
function F.Finish(job)
    for _=1,10000 do
        local r=assert(job:Step(1))
        if r.status~='running' then return r end
    end
    error('sector request did not terminate')
end
function F.Route(planner,from,to,via)
    return planner:Plan({from=from or 'meadow:terrain:1',to=to or 'harbor:terrain:2',via=via})
end
return F
