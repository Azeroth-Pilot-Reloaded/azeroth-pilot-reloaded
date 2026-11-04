local F=dofile('tests/lua/navigation_v2_movement/fixture.lua')
local speeds={walk=2,mount=4,swim=1}
local settings={walkSpeed=2,mountSpeed=4,swimSpeed=1,mountSeconds=3,
    dismountSeconds=2,enterSwimSeconds=0.5,exitSwimSeconds=0.75}
local function transition(a,b)
    if a==b then return 0 end
    return (a=='mount' and 2 or 0)+(a=='swim' and 0.75 or 0)
        +(b=='mount' and 3 or 0)+(b=='swim' and 0.5 or 0)
end
local function exhaustive(graph,observation)
    local best=math.huge
    local function visit(node,mode,cost)
        if node=='n6' then best=math.min(best,cost);return end
        for _,edge in ipairs(graph.edges) do
            local target=edge.movement.mode
            local ride=observation.level>=40 and observation.mountOwned==true and observation.mountUsable==true
            if edge.from==node and edge.access=='available'
                and (target~='mount' or (ride and (mode=='mount' or edge.movement.canMount=='available'))) then
                visit(edge.to,target,cost+edge.movement.distance/speeds[target]+transition(mode,target))
            end
        end
    end
    visit('n1','walk',0)
    return best
end
math.randomseed(7019)
for case=1,100 do
    local nodes,edges={},{}
    for i=1,6 do nodes[i]='n'..i end
    for i=1,5 do
        for j=i+1,6 do
            for _,mode in ipairs({'walk','mount','swim'}) do
                if math.random(1,3)==1 then
                    edges[#edges+1]=F.Edge('edge-'..(#edges+1),nodes[i],nodes[j],mode,math.random(0,30),
                        math.random(1,4)==1 and 'unavailable' or 'available',
                        math.random(1,4)==1 and 'unavailable' or 'available')
                end
            end
        end
    end
    edges[#edges+1]=F.Edge('fallback','n1','n6','walk',100)
    local observation={level=case%2==0 and 40 or 39,mountOwned=case%3~=0,
        mountUsable=case%5~=0,initialMode='walk',canMountHere=true}
    local graph=F.Graph(nodes,edges)
    local expected=exhaustive(graph,observation)
    local result=F.Plan(graph,observation,settings,{from='n1',to='n6'})
    assert(result.status=='complete',result.status)
    assert(math.abs(result.estimatedSeconds-expected)<0.000001,
        'case '..case..': '..tostring(result.estimatedSeconds)..' vs independent '..expected)
end
