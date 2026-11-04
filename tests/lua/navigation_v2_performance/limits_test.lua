local ns={}
for _,name in ipairs({'Conditions','Graph','Resources','Search','Navigation'})do
    assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/'..name..'.lua'))('test',ns)
end
local function graph(count)
    local g={complete=true,nodes={},edges={}}
    for i=1,count do
        g.nodes[i]='n'..i
        if i>1 then g.edges[#g.edges+1]={id='e'..i,from='n'..(i-1),to='n'..i,seconds=2} end
    end
    return g
end
local function planner(g,limits,resources)
    return ns.LibAPRNavigationV2.New(g,{clock=function()return 0 end,profileClock=function()return 0 end,limits=limits,resources=resources})
end
local function finish(p,to)
    local job=p:Plan({from='n1',to=to})
    for _=1,10000 do
        local r=assert(job:Step(8))
        if r.status~='running' then
            assert(job:Step()==r,'terminal jobs must never restart unchanged')
            return r
        end
    end
    error('bounded fixture did not terminate')
end
local p=assert(planner(graph(5),{nodes=4}))
local r=finish(p,'n5')
assert(r.status=='budget_exceeded' and r.reason=='node_limit' and not r.segments)
assert(r.diagnostics.preparedNodes==4,'stop before allocating the excess node')
p=assert(planner(graph(5),{edges=3}))
r=finish(p,'n5')
assert(r.status=='budget_exceeded' and r.reason=='edge_limit' and r.diagnostics.preparedEdges==3)
p=assert(planner(graph(5),{labels=4}))
r=finish(p,'n5')
assert(r.status=='budget_exceeded' and r.reason=='label_limit' and not r.segments)
p=assert(planner(graph(5),{segments=3}))
r=finish(p,'n5')
assert(r.status=='budget_exceeded' and r.reason=='segment_limit' and not r.segments)
p=assert(planner(graph(5),{nodes=5,edges=4,labels=5,segments=4}))
r=finish(p,'n5')
assert(r.status=='complete' and r.estimatedSeconds==8 and #r.segments==4)
-- Dominated duplicates do not consume retained-label capacity or lose optimality.
local g=graph(3)
for i=1,40 do g.edges[#g.edges+1]={id='slow'..i,from='n1',to='n2',seconds=100+i} end
r=finish(assert(planner(g,{labels=3})),'n3')
assert(r.status=='complete' and r.estimatedSeconds==4)
p=assert(planner(graph(5),{labels=4},{money=10}))
r=finish(p,'n5')
assert(r.status=='budget_exceeded' and r.reason=='label_limit' and not r.segments)
for _,limits in ipairs({{labels=0},{labels=false},{segments=1.5},{nodes=math.huge},{bogus=1},{labels=1000000000}})do
    local rejected,why=planner(graph(2),limits)
    assert(not rejected and why=='invalid_limits')
end
