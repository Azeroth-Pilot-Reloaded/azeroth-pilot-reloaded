local Base=dofile('tests/lua/navigation_v2/fixture.lua')
local Library,ns=Base.Load()
local Fixture={Library=Library,namespace=ns,Finish=Base.Finish}

function Fixture.New(graph,observation,settings)
    local Forever=assert(ns.NavigationV2Forever,'Forever movement must load through the real XML')
    local profile=assert(Forever.New(observation or {level=40,mountOwned=true,
        mountUsable=true,initialMode='walk',canMountHere=true},settings))
    local planner,reason=Library.New(graph,{clock=function() return 0 end,
        profileClock=function() return 0 end,movement=profile})
    return assert(planner,reason),profile
end

function Fixture.Edge(id,from,to,mode,distance,access,canMount)
    return {id=id,from=from,to=to,seconds=1,access=access or 'available',
        movement={mode=mode,distance=distance,canMount=canMount or 'available'}}
end

function Fixture.Graph(nodes,edges)
    return {complete=true,nodes=nodes,edges=edges}
end

function Fixture.Plan(graph,observation,settings,request)
    local planner=Fixture.New(graph,observation,settings)
    return Fixture.Finish(planner:Plan(request or {from='s',to='g'}),1)
end

function Fixture.Path(result,ids,seconds)
    assert(result.status=='complete',result.status..':'..tostring(result.reason))
    assert(math.abs(result.estimatedSeconds-seconds)<0.000001,
        tostring(result.estimatedSeconds)..' seconds instead of '..seconds)
    assert(#result.segments==#ids)
    for i,id in ipairs(ids) do assert(result.segments[i].edgeId==id,result.segments[i].edgeId) end
end

return Fixture
