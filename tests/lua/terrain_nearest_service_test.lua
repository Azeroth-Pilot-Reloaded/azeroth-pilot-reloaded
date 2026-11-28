-- Invented services and transport graphs, priced by a budgeted terrain provider.
local lib = dofile("tests/lua/navigation_engine_fixture.lua")
function LibStub() return lib end
dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")
local function point(x)
    return {x=x,y=0,instanceID=1,uiMapID=2,region="fixture"}
end
local function record(id, x)
    return {service="bank",npcID=id,mapID=2,x=x/100,y=0,faction="B"}
end
local function fixture(records, costs, edges)
    local p={now=0,queries={},jobs={},paths={}}
    local function work(run)
        local j={workLastStep=0}
        function j:Step(operations, milliseconds)
            assert(operations>=1 and operations<=(p.batchLimit or 1) and milliseconds>0)
            assert(not p.deadline or milliseconds<=p.deadline-p.now+0.00001,
                "Nested service terrain work shares the caller's remaining deadline")
            self.workLastStep=1
            p.now=p.now+0.1
            if p.pause then return "planning" end
            return run()
        end
        function j:Cancel() self.cancelled=true end
        p.jobs[#p.jobs+1]=j
        return j
    end
    local function cost(a,b)
        local value=costs and costs[a.x..":"..b.x]
        if value~=nil then return value end
        return math.abs(b.x-a.x)/7
    end
    function p:CreateCostJob(a, targets)
        self.queries[#self.queries+1]={from=a,targets=targets}
        local rows,index={},1
        return work(function()
            local value=cost(a,targets[index])
            rows[index]=type(value)=="number" and {state="ready",seconds=value} or {state=value}
            index=index+1
            if index<=#targets then return "planning" end
            return "ready",{costs=rows}
        end)
    end
    function p:CreatePathJob(a,b)
        self.paths[#self.paths+1]={a,b}
        return work(function()
            local value=cost(a,b)
            if type(value)~="number" then return value end
            return "ready",{path={a,b},seconds=value}
        end)
    end
    local nav=setmetatable({profile="forever",env={},serviceLocations=records,builds=0},lib.Instance)
    function nav:GetWalkingProvider() return p end
    function nav:NormalizeLocation(value)
        return value.space=="map" and point(value.x*10000) or value
    end
    function nav:CanWalk(a,b) return a.instanceID==b.instanceID end
    function nav:CreateEdgeBuild()
        self.builds=self.builds+1
        return {Step=function() return "ready",edges or {},{} end}
    end
    local function create(extra)
        local options={start=point(0),query={service="bank"},walkSpeed=7,
            walkingSpeedCeiling=7,clock=function() return p.now end}
        for key,value in pairs(extra or {}) do options[key]=value end
        return nav:CreateServiceSearch(options)
    end
    return nav,p,create
end
local function finish(job,p)
    for _=1,20000 do
        p.deadline=p.now+0.5
        local status,result=job:Step(16,0.5)
        if status~="planning" then return status,result end
    end
    error("Nearest terrain search failed to complete")
end

local many,edges={},{}
for i=1,1000 do
    many[i]=record(i,4000+i*5)
    edges[i]={kind="boat",from=point(20000+i*14),to=point(20007+i*14),seconds=3}
end
many[#many+1]=record(7001,7)
local nav,p,create=fixture(many,{["0:7"]=5},edges)
local status,result=finish(create(),p)
assert(status=="ready" and result.record.npcID==7001 and result.totalSeconds==5)
assert(#p.queries==1 and #p.queries[1].targets==1 and math.abs(p.queries[1].targets[1].x-7)<0.000001,
    "Find nearest prices the nearby candidate before distant services and transport endpoints")
assert(nav.builds==1 and #many==1001 and #edges==1000 and result.itinerary.goalIndex==1001,
    "All original candidates and one shared graph remain available; winner indexing is unchanged")

-- A distance-only shortlist would omit the winner at the end of these
-- transfers. The first action can depart from anywhere despite its remote
-- catalogue source, and the next action starts on another part of the graph.
do
    local records = {record(31,35), record(32,9007)}
    for i=1,40 do records[#records+1]=record(100+i,20000+i*7) end
    local graph = {{kind="spell",sourceFree=true,from=point(40000),to=point(5000),seconds=1},
        {kind="boat",from=point(5000),to=point(9000),seconds=1}}
    local engine, provider, search = fixture(records,nil,graph)
    provider.batchLimit=16
    local job = search({batchTerrainWork=true})
    local state, winner = finish(job,provider)
    assert(state=="ready" and winner.record.npcID==32 and winner.totalSeconds==3)
    assert(job.trialIndices and #job.trialIndices==2 and winner.itinerary.goalIndex==2
        and winner.itinerary.segments[1].sourceFree and winner.itinerary.segments[2].kind=="boat")

    -- Both an expensive feasible local walk and a locally blocked walk must
    -- fall back to the full graph. The farther service wins in both cases.
    records[1],records[2]=record(41,7),record(42,210)
    for _, cost in ipairs({60,"no_path"}) do
        engine,provider,search=fixture(records,{["0:7"]=cost})
        provider.batchLimit=16
        job=search({batchTerrainWork=true})
        state,winner=finish(job,provider)
        assert(state=="ready" and winner.record.npcID==42 and winner.totalSeconds==30 and not job.trialIndices)
    end
end

nav,p,create=fixture({record(1,7),record(2,14)},{["0:7"]=30,["0:14"]=4})
status,result=finish(create(),p)
assert(result.record.npcID==2 and result.totalSeconds==4,
    "A physically faster farther service can beat the first measured goal")
nav,p,create=fixture({record(2,14),record(1,7)},{["0:7"]="no_path",["0:14"]=4})
status,result=finish(create(),p)
assert(result.record.npcID==2 and math.abs(p.queries[1].targets[1].x-7)<0.000001
    and math.abs(p.queries[2].targets[1].x-14)<0.000001,
    "A blocked first candidate advances to the next direct candidate without losing original indices")
local blockedMany={}
for i=1,1000 do blockedMany[i]=many[i] end
blockedMany[1001],blockedMany[1002]=record(7001,7),record(7002,14)
nav,p,create=fixture(blockedMany,{["0:7"]="no_path",["0:14"]=4},edges)
status,result=finish(create(),p)
assert(result.record.npcID==7002 and result.itinerary.goalIndex==1002
    and #p.queries==2 and #p.queries[2].targets==1,
    "A blocked local goal retries the next local goal before pricing a large distant world")
nav,p,create=fixture({record(2,14),record(1,7),record(3,7)},
    {["0:7"]="no_path",["0:14"]=4})
status,result=finish(create(),p)
assert(result.record.npcID==2 and #p.queries==2,
    "Services sharing a blocked endpoint do not repeat the same priority terrain query")
nav,p,create=fixture({record(1,7),record(2,14)},
    {["0:7"]="no_path",["0:14"]="no_path"})
assert(finish(create(),p)=="no_path" and #p.queries==4,
    "Ordinary travel and the permitted last-resort recall both terminate without fabricating a walk")

nav,p,create=fixture({record(1,7),record(2,14)},nil,
    {{kind="portal",from=point(0),to=point(14),seconds=2}})
function nav:CanWalk(a,b) return a.x==b.x end
status,result=finish(create(),p)
assert(result.record.npcID==2 and result.totalSeconds==2 and #p.queries==0,
    "Walking vetoes do not remove a destination reachable through an authorized transport")

nav,p,create=fixture(many,{["0:7"]="unavailable"},edges)
status,result=finish(create(),p)
assert(result.record.npcID==7001 and math.abs(result.totalSeconds-1)<0.000001 and #p.queries==1
    and result.itinerary.segments[1].path==nil,
    "Unavailable local terrain keeps authorized fallback without pricing the entire world")

nav,p,create=fixture({record(1,7),record(2,14)},{["0:7"]=30,["0:14"]=4})
status,result=finish(create({walkingSpeedCeiling=false}),p)
assert(result.record.npcID==2 and #p.queries[1].targets==2,
    "Without an explicit speed ceiling the complete batched behavior remains available")

-- A portal can win even when the first candidate is a nearby walk.
nav,p,create=fixture({record(1,70),record(2,700)},nil,
    {{kind="portal",from=point(0),to=point(700),seconds=2}})
status,result=finish(create(),p)
assert(result.record.npcID==2 and result.totalSeconds==2 and result.itinerary.segments[1].kind=="portal")

-- A recall cannot select a remote service, but can shorten an already selected long trip.
local recall={kind="item",hearthstone=true,sourceFree=true,from=point(0),to=point(6300),seconds=1}
nav,p,create=fixture({record(1,70),record(2,6300)},nil,{recall})
status,result=finish(create(),p)
assert(result.record.npcID==1 and not result.itinerary.hearthstoneAllowed)
recall.to=point(4900)
nav,p,create=fixture({record(2,6300),record(1,4900)},nil,{recall})
status,result=finish(create(),p)
assert(result.record.npcID==1 and result.totalSeconds==1 and result.itinerary.hearthstoneAllowed
    and result.itinerary.withoutHearthstoneSeconds==700 and result.itinerary.goalIndex==2)

nav,p,create=fixture({record(1,7),record(2,14)})
p.pause=true
local pending=create()
for _=1,1000 do
    p.deadline=p.now+0.5
    pending:Step(1,0.5)
    if #p.jobs>0 then break end
end
pending:Cancel()
assert(p.jobs[1] and p.jobs[1].cancelled and pending:Step(1,0.5)=="cancelled",
    "Cancelling Find nearest also cancels its priority terrain query")
print("Terrain nearest services: multi-goal bounds, complete ranking, fallback, transports, recall policy and cancellation passed")
