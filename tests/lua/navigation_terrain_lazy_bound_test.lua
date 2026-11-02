-- Unknown terrain has no positive cost bound: authored metrics can be zero.
local function run(mode, preloaded)
    local fixture=dofile("tests/lua/navigation_fixture.lua")
    local data=fixture:Load({connections={}})
    local lib=LibStub("LibAPRNavigation-1.0")
    local function point(world,map,x)
        return data:NormalizeLocation({instanceID=world,uiMapID=map,x=x,y=0,z=0})
    end
    local start,goal=point(1,101,0),point(2,201,0)
    local arrival,departure=point(9,601,0),point(9,601,300)
    local unused=point(10,602,0)
    local raw={format=1,nodes={
        {id="a",x=0,y=0,z=0,uiMapID=601},{id="b",x=300,y=0,z=0,uiMapID=601}},
        edges={},anchors={}}
    if mode=="steady" then
        raw.nodes[3]={id="up-a",x=0,y=0,z=100,uiMapID=601,movementMode="steady"}
        raw.nodes[4]={id="up-b",x=300,y=0,z=100,uiMapID=601,movementMode="steady"}
        raw.edges={{from="a",to="up-a",mode="steady",seconds=1},
            {from="up-a",to="up-b",mode="steady"},
            {from="up-b",to="b",mode="steady",seconds=1}}
    elseif mode~="missing" then
        raw.edges={{from="a",to="b",mode="ground",seconds=mode=="free" and 0 or 80}}
    end
    local loads={}
    data.env.hasTerrainData=function(_,world)return world==nil or world==9 or world==10 end
    data.env.requestTerrainData=function(_,world)
        loads[world]=(loads[world] or 0)+1
        if mode=="missing" then return "missing","fixture_unavailable" end
        if not lib.terrainDatasets.retail or not lib.terrainDatasets.retail[world] then
            lib:RegisterTerrainData("retail",world,raw,1,"fixture")
        end
        return "ready"
    end
    if preloaded then lib:RegisterTerrainData("retail",9,raw,1,"fixture") end
    local edges={
        {kind="portal",id="direct",from=start,to=goal,seconds=30},
        {kind="portal",id="entry",from=start,to=arrival,seconds=1},
        {kind="portal",id="exit",from=departure,to=goal,seconds=1},
        {kind="portal",id="unused",from=start,to=unused,seconds=1000}}
    data.CreateEdgeBuild=function()return {Step=function()return "ready",edges,{resources={}} end} end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local job=APR.NavigationPlanner:Create({
        data=data,engine=lib.Engine,start=start,goal=goal,walkSpeed=7,
        movementProfile={groundSpeed=7,canSteady=true,steadySpeed=30,currentMode="ground"},
        taxiData={BuildEdges=function()return {} end},
        canWalk=function(a,b)return data:CanWalk(a,b) end,
        prepareSegment=function(segment)return segment end})
    local slices=0
    while job:Step(3,1)=="planning" do
        slices=slices+1;assert(slices<10000,"Lazy candidate refinement must terminate")
    end
    assert(job.status=="ready","The direct alternative always remains reachable")
    local result=job:GetResult()
    local expected=mode=="steady" and 14 or mode=="free" and 2 or 30
    assert(result.totalSeconds==expected,
        "Unknown terrain cannot hide a faster flight or a fixed-cost edge: "..mode.." expected "..expected.." got "..result.totalSeconds)
    assert(loads[9] and not loads[10],"Refine every competitive world, while expensive unrelated branches remain dormant")
    for _,segment in ipairs(result.segments) do
        if segment.kind=="walk" and segment.from.instanceID==9 then
            assert(segment.terrain,"An optimistic terrain chord can never become published guidance")
        end
    end
end
for _,preloaded in ipairs({false,true}) do
    for _,mode in ipairs({"steady","free","expensive"}) do run(mode,preloaded) end
end
run("missing",false)
print("Terrain lazy bound: admissible flight/fixed-cost candidates, exact refinement, missing data and dormant branches")
