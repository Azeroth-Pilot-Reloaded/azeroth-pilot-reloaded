local Base=dofile('tests/lua/navigation_v2/fixture.lua')
local Library,ns=Base.Load()
assert(ns.NavigationV2Retail,'Retail movement must load through the real XML')
local F={Library=Library,ns=ns,Finish=Base.Finish,Retail=assert(ns.NavigationV2Retail)}
function F.Observation(changes)
    local result={level=10,initialMode='walk',mountOwned=true,mountUsable=true,
        skyridingOwned=true,skyridingUsable=true,canMountHere=true,canSkyridingHere=true}
    for k,v in pairs(changes or {}) do result[k]=v end
    return result
end
function F.New(edges,observation,options)
    options=options or {}
    options.clock=function() return 0 end;options.profileClock=function() return 0 end
    options.movement=assert(F.Retail.New(observation or F.Observation()))
    local graph={complete=true,nodes={'room','door','s','g'},edges=edges}
    return assert(Library.New(graph,options)),options.movement
end
function F.Edge(id,from,to,mode,distance,extra)
    local movement={mode=mode,distance=distance,canMount='available'}
    for k,v in pairs(extra or {}) do movement[k]=v end
    return {id=id,from=from,to=to,seconds=0,movement=movement}
end
function F.Path(result,ids,seconds)
    assert(result.status=='complete',result.status..':'..tostring(result.reason))
    assert(math.abs(result.estimatedSeconds-seconds)<1e-8,tostring(result.estimatedSeconds))
    assert(#result.segments==#ids)
    for i,id in ipairs(ids) do assert(result.segments[i].edgeId==id) end
end
return F
