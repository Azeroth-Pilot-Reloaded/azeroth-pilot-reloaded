local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local ns=F.Load()
-- Exhaustive enumeration over tiny DAGs is independent of labels/dominance/heap.
local seed=37
local function Random(maximum)
    seed=(seed*48271)%2147483647
    return seed%maximum
end
for trial=1,80 do
    local graph={complete=true,nodes={'a','b','c','d','e','f'},edges={}}
    local outgoing={}
    for i=1,6 do outgoing[i]={} end
    for a=1,5 do for b=a+1,6 do
        if Random(3)~=0 then
            local e={id='edge '..a..' '..b,from=graph.nodes[a],to=graph.nodes[b],seconds=Random(9),
                resources={money=Random(5),dust=Random(3)}}
            graph.edges[#graph.edges+1]=e
            outgoing[a][#outgoing[a]+1]={to=b,time=e.seconds,money=e.resources.money,dust=e.resources.dust}
        end
    end end
    local best
    local function Visit(node,time,money,dust)
        if money>5 or dust>3 then return end
        if node==6 then if not best or time<best then best=time end;return end
        for _,edge in ipairs(outgoing[node])do Visit(edge.to,time+edge.time,money+edge.money,dust+edge.dust)end
    end
    Visit(1,0,0,0)
    local planner=assert(ns.LibAPRNavigationV2.New(graph,{resources={money=5,dust=3},
        clock=function()return 0 end,profileClock=function()return 0 end}))
    local result=F.Finish(planner:Plan({from='a',to='f'}))
    if best then assert(result.status=='complete' and result.estimatedSeconds==best,'Resource oracle mismatch')
    else assert(result.status=='no_path') end
end
