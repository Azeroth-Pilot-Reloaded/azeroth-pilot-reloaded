local ns = {}
local root = "APR-Core/libs/LibAPRNavigation-2.0/"
local file = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = file:read("*a"); file:close()
for path in xml:gmatch('<Script%s+file="([^"]+)"') do assert(loadfile(root .. path))("test", ns) end
assert(loadfile("APR-Core/features/navigation/NavigationV2Position.lua"))("test", ns)
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkCase.lua"))("test", ns)
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkRun.lua"))("test", ns)
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkV2.lua"))("test", ns)
local Benchmark = ns.NavigationBenchmarkV2
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
local function request()
    return { coordinateUnit="map-percent", from={mapID=71,x=10,y=20,
        identity={worldID=1,z=3,spaceID="garden",floorID="ground",phaseID="base"}},
        to={mapID=72,x=30,y=40,
        identity={worldID=1,z=5,spaceID="garden",floorID="ground",phaseID="base"}} }
end
local function setup()
    local wire = {2,1,{{20000,3000,10000},{30000,4000,20000},{40000,5000,30000}},
        {{1,2,4000},{2,3,5000},{1,3,20000}}}
    local sector = {client="wowf",build="synthetic-build",mapId=1,complete=false,
        identity={space="garden",floor="ground",phase="base"},
        blocks={{first=1,nodes=3,edges=3,rawBytes=6,payload="garden"}}}
    ns.NavigationV2TerrainCatalog = {garden=sector}
    local spy = {loads=0,loaderSteps=0,new=0,plans=0,steps=0,cancels=0,loaderCancels=0,clock=0}
    local api = {Enum={Base64Variant={Standard=1},CompressionMethod={Deflate=1}},
        issecretvalue=function()return false end,
        CreateVector2D=function(x,y)return {x=x,y=y}end,
        C_Map={GetMapPosFromWorldPos=function(world,p,map)
            assert(world==1 and map);return map,{x=p.x/100,y=p.y/100}
        end,GetWorldPosFromMapPos=function(_,p)return 1,{x=p.x*100,y=p.y*100}end},
        C_EncodingUtil={DecodeBase64=function(s,variant)assert(variant==1);return s end,
            DecompressString=function(s,method)assert(method==1);return s end,
            DeserializeCBOR=function(s)assert(s=="garden");return wire end},
        UnitPosition=function()error("capture belongs to Case, not this driver")end,
        SetSuperTrackedUserWaypoint=function()error("no navigation output")end}
    local host = {activeJob="foreign active navigation"}
    function host:LoadTerrain(id, options)
        spy.loads=spy.loads+1
        local loader=assert(ns.NavigationV2Terrain.New(ns.NavigationV2TerrainCatalog,options))
        local job=loader:Load(id);local cancel,step=job.Cancel,job.Step
        function job:Cancel()spy.loaderCancels=spy.loaderCancels+1;return cancel(self)end
        function job:Step(...)spy.loaderSteps=spy.loaderSteps+1;return step(self,...)end
        return job
    end
    function host:Enable()error("benchmark must not enable normal host")end
    function host:Plan()error("benchmark must not replace normal request")end
    local library = {New=function(graph, options)
        spy.new=spy.new+1
        assert(#graph.nodes==#wire[3] and #graph.edges==#wire[4])
        local planner,reason=ns.LibAPRNavigationV2.New(graph,options)
        if not planner then return nil,reason end
        local plan=planner.Plan
        function planner:Plan(input)
            spy.plans=spy.plans+1
            local job=plan(self,input);local step,cancel=job.Step,job.Cancel
            function job:Step(operations,milliseconds)
                spy.steps=spy.steps+1;return step(self,operations,milliseconds)
            end
            function job:Cancel()spy.cancels=spy.cancels+1;return cancel(self)end
            return job
        end
        return planner
    end}
    return {host=host,library=library,terrain=ns.NavigationV2Terrain,world=ns.NavigationV2World,
        api=api,clock=function()if spy.onClock then spy.onClock() end;return spy.clock end,
        profile="forever",build="synthetic-build"},spy,sector,wire
end
local function finish(driver)
    for _=1,2000 do
        local result=driver:Step(64,1)
        assert(type(result)=="table")
        if result.status~="running" then return result end
    end
    error("benchmark failed to terminate")
end

-- Actual loader and actual planner: declared graph, native projections only faked.
local context,spy=setup()
local input=request();local driver=assert(Benchmark.Create(input,context))
assert(spy.loads==0 and spy.new==0) -- Create performs no decoding or graph scan.
assert(driver:GetMetrics().stepCalls==0)
assert(driver:Step(64,1).status=="running" and spy.loads==1 and spy.loaderSteps==0)
assert(driver:GetMetrics().stepCalls==0) -- Catalog selection/open is not a job Step.
input.to.x=99;input.from.identity.z=999
local result=finish(driver)
assert(result.status=="complete" and result.estimatedSeconds==9 and result.optimal==true)
assert(spy.loads==1 and spy.new==1 and spy.plans==1 and spy.steps>0)
assert(context.host.activeJob=="foreign active navigation")
local metrics=driver:GetMetrics()
assert(metrics.newCalls==1 and metrics.calculationsStarted==1 and metrics.calculationsCompleted==1)
assert(metrics.preparedNodes==3 and metrics.preparedEdges==3 and metrics.operations>0)
assert(metrics.expandedNodes>0 and metrics.relaxedEdges>0 and metrics.searchStepCalls==spy.steps)
assert(metrics.stepCalls==spy.loaderSteps+spy.steps and metrics.preparationStepCalls==spy.loaderSteps)
assert(metrics.decodingMs==0 and metrics.searchMs==nil) -- No invented phase split.
metrics.newCalls=999;assert(driver:GetMetrics().newCalls==1)
local provenance=driver:GetContext()
assert(provenance.scope=="declared_graph" and provenance.approachEdgesAdded==0)
assert(provenance.sector=="garden" and provenance.graphComplete==false)
provenance.scope="changed";assert(driver:GetContext().scope=="declared_graph")
local calls=spy.steps;assert(driver:Step(64,1).status=="complete" and spy.steps==calls)
driver:Cancel();assert(spy.cancels==0)

-- Missing physical identity permits only a unique technical graph query.
for _,field in ipairs({"worldID","z"}) do
    context,spy=setup();input=request();input.from.identity[field]=nil
    driver=assert(Benchmark.Create(input,context));result=finish(driver)
    assert(result.status=="unknown" and result.estimatedSeconds==nil and result.optimal==nil)
    assert(driver:GetContext().plannerStatus=="complete" and spy.plans==1)
end
context,spy=setup();input=request();input.from.identity=nil;input.to.identity=nil
driver=assert(Benchmark.Create(input,context));result=finish(driver)
assert(result.status=="unknown" and result.reason=="benchmark_v2_identity_unproven")
assert(result.estimatedSeconds==nil and spy.new==1 and spy.steps>0)
assert(driver:GetContext().queryScope=="graph_query_only")
for _,field in ipairs({"profile","build"}) do
    context,spy=setup();context[field]=nil
    assert(Benchmark.Create(request(),context)==nil and spy.loads==0)
end
context,spy=setup();input=request();input.from.x=101
assert(Benchmark.Create(input,context)==nil)

-- Existing metadata never becomes an admitted graph. Client/build must match.
context,spy=setup();context.build="different-build"
driver=assert(Benchmark.Create(request(),context));result=finish(driver)
assert(result.status=="unknown" and result.reason=="benchmark_v2_build_mismatch")
assert(result.estimatedSeconds==nil and result.optimal==nil and spy.plans==1)
assert(driver:GetContext().buildMatches==false and driver:GetContext().dataBuild=="synthetic-build")
context,spy=setup();context.profile="retail"
result=finish(assert(Benchmark.Create(request(),context)))
assert(result.status=="unknown" and spy.loads==0)

-- 0.01 yards is the projection roundtrip tolerance, never a node snap radius.
for _,change in ipairs({function(p)p.x=p.x+.02 end,function(p)p.identity.z=p.identity.z+.001 end}) do
    context,spy=setup();input=request();change(input.from)
    result=finish(assert(Benchmark.Create(input,context)))
    assert(result.status=="unknown" and result.reason=="benchmark_v2_node_unmapped" and spy.new==0)
end
local sector,wire
context,spy,sector,wire=setup();wire[3][4]=copy(wire[3][1]);sector.blocks[1].nodes=4
result=finish(assert(Benchmark.Create(request(),context)))
assert(result.status=="unknown" and result.reason=="benchmark_v2_node_ambiguous" and spy.new==0)
context,spy,sector,wire=setup();wire[3][4]={20000,6000,10000};sector.blocks[1].nodes=4
input=request();input.from.identity=nil;input.to.identity=nil
result=finish(assert(Benchmark.Create(input,context)))
assert(result.status=="unknown" and result.reason=="benchmark_v2_node_ambiguous" and spy.new==0)
context,spy=setup();context.api.C_Map.GetWorldPosFromMapPos=function(_,p)return 2,{x=p.x*100,y=p.y*100}end
result=finish(assert(Benchmark.Create(request(),context)))
assert(result.status=="unknown" and result.reason=="projection_unreliable" and spy.new==0)
context,spy=setup();context.api.C_Map.GetMapPosFromWorldPos=function()error("native unavailable")end
result=finish(assert(Benchmark.Create(request(),context)))
assert(result.status=="unknown" and result.reason=="projection_unavailable" and spy.new==0)

-- Prepared data binds the captured coordinates to existing graph references.
-- No terrain catalog, exact-node snapping or absent identity is required here.
local function preparedSetup()
    local observed={factory=0,prep=0,new=0,plans=0,search=0,cancel=0,clock=0}
    local ctx={profile="retail",clock=function()return observed.clock end}
    ctx.prepare=function(captured,options)
        observed.factory=observed.factory+1
        observed.capture,observed.context=captured,options
        return {Step=function()
            observed.prep=observed.prep+1
            if observed.prep==1 then return {status="running",diagnostics={operations=700}} end
            return {status="complete",graph={complete=true,nodes={"start","gate","goal"},edges={
                {id="direct",from="start",to="goal",seconds=1},
                {id="approach",from="start",to="gate",seconds=4},
                {id="exit",from="gate",to="goal",seconds=6}}},
                request={from="start",to="goal",via={"gate"}},
                provenance={scope="synthetic_passages",source="invented",nested={}},
                diagnostics={operations=701},options={resources={money=9}}}
        end,Cancel=function()observed.cancel=observed.cancel+1 end}
    end
    ctx.library={New=function(graph,options)
        observed.new=observed.new+1;observed.options=options
        local planner=assert(ns.LibAPRNavigationV2.New(graph,options))
        local plan=planner.Plan
        function planner:Plan(objective)
            observed.plans=observed.plans+1
            local job=plan(self,objective);local step,cancel=job.Step,job.Cancel
            function job:Step(...)
                observed.search=observed.search+1;return step(self,...)
            end
            function job:Cancel()observed.cancel=observed.cancel+1;return cancel(self)end
            return job
        end
        return planner
    end}
    return ctx,observed
end
local function arbitraryRequest()
    return {coordinateUnit="map-percent",startMode="manual",
        from={mapID=71,x=12.345,y=23.456,identity={worldID=1}},
        to={mapID=72,x=67.89,y=78.91,identity={worldID=2}}}
end
context,spy=preparedSetup();input=arbitraryRequest()
driver=assert(Benchmark.Create(input,context))
assert(spy.factory==0 and spy.new==0)
input.from.x=99
result=finish(driver)
assert(result.status=="complete" and result.estimatedSeconds==10)
assert(spy.capture.from.x==12.345 and spy.capture.to.identity.worldID==2)
assert(spy.capture.coordinateUnit=="map-percent" and spy.capture.startMode=="manual")
assert(spy.factory==1 and spy.prep==2 and spy.plans==1 and spy.search>0)
assert(spy.context.profile=="retail" and spy.context.budgets.cpuMs<=100)
assert(spy.options.resources.money==9 and spy.options.clock()==0)
metrics=driver:GetMetrics()
assert(metrics.preparationStepCalls==2 and metrics.searchStepCalls==spy.search)
assert(metrics.stepCalls==2+spy.search and metrics.calculationsStarted==1)
assert(metrics.preparedNodes==3 and metrics.preparedEdges==3 and metrics.operations~=701)
assert(driver:GetContext().source=="invented" and driver:GetContext().nested==nil)
assert(driver:GetContext().preparationOperations==701 and driver:GetContext().planCalls==1)
assert(driver:GetContext().preparationCalls==1)
assert(driver:GetContext().scope=="synthetic_passages")
assert(driver:Step().estimatedSeconds==10 and spy.factory==1 and spy.cancel==0)

-- Both client preparations use the same solver and the unchanged timing owner.
for _,profile in ipairs({"forever","retail"}) do
    context,spy=preparedSetup();context.profile=profile
    local snapshot=assert(ns.NavigationBenchmarkCase.Capture(arbitraryRequest()))
    local preparedRunner=assert(ns.NavigationBenchmarkRun.New({clock=function()return 0 end,
        profileClock=context.clock,factories={v2=function(r)return Benchmark.Create(r,context)end}}))
    assert(preparedRunner:Start(snapshot,"v2"))
    for _=1,100 do if preparedRunner:Step().status~="running" then break end end
    local measured=preparedRunner:GetState().engines.v2
    assert(measured.status=="complete" and measured.estimatedSeconds==10)
    assert(measured.wallMs==0 and measured.cpuMs==0 and measured.driverCalls>0)
    assert(measured.metrics.preparationStepCalls==2 and measured.metrics.newCalls==1)
    assert(measured.metrics.searchStepCalls==spy.search and measured.metrics.expandedNodes>0)
    assert(measured.metrics.preparationMs==nil and measured.metrics.searchMs==nil)
end

-- Preparation failure is terminal and cannot fall back to another data domain.
for _,case in ipairs({
    {status="unknown",reason="source_floor_ambiguous"},
    {status="invalid",reason="source_malformed"},
    {status="budget_exceeded",reason="source_budget"},
    {status="no_path",reason="declared_disconnected"}}) do
    context,spy=preparedSetup()
    context.prepare=function()return {Step=function()return case end,Cancel=function()spy.cancel=spy.cancel+1 end}end
    driver=assert(Benchmark.Create(arbitraryRequest(),context));result=finish(driver)
    assert(result.status==case.status and result.reason==case.reason and spy.new==0)
    driver:Step();assert(spy.new==0)
end

-- Malformed or throwing factories/results are refused before New/Plan.
for _,value in ipairs({"throw","nil","job","graph","request","options","provenance"}) do
    context,spy=preparedSetup()
    local prepare=context.prepare
    context.prepare=function(...)
        if value=="throw" then error("source failed") end
        if value=="nil" then return nil,"source_absent" end
        if value=="job" then return {Cancel=function()spy.cancel=spy.cancel+1 end} end
        local job=prepare(...);local step=job.Step
        job.Step=function()
            local state=step()
            if state.status=="complete" then
                if value=="request" then state.request.from={} else state[value]=false end
            end
            return state
        end
        return job
    end
    driver=assert(Benchmark.Create(arbitraryRequest(),context));result=finish(driver)
    assert(result.status=="unknown" and spy.new==0 and driver:GetMetrics().calculationsStarted==0)
end

-- Cancellation owns only the preparation or the independent search, exactly once.
context,spy=preparedSetup();driver=assert(Benchmark.Create(arbitraryRequest(),context))
assert(driver:Step().status=="running" and spy.factory==1)
driver:Cancel();driver:Cancel()
assert(driver:Step().status=="cancelled" and spy.cancel==1 and spy.prep==0)
context,spy=preparedSetup()
local prepare=context.prepare
context.prepare=function(...)local job=prepare(...);driver:Cancel();return job end
driver=assert(Benchmark.Create(arbitraryRequest(),context))
assert(driver:Step().status=="cancelled" and spy.cancel==1 and spy.prep==0)

context,spy=preparedSetup();local clockReads=0
context.clock=function()
    clockReads=clockReads+1
    if clockReads==3 then driver:Cancel() end
    return 0
end
driver=assert(Benchmark.Create(arbitraryRequest(),context))
assert(driver:Step().status=="cancelled" and spy.factory==0 and spy.new==0)

context,spy=preparedSetup();clockReads=0
context.clock=function()
    clockReads=clockReads+1
    return clockReads==3 and -1 or 0
end
driver=assert(Benchmark.Create(arbitraryRequest(),context));result=driver:Step()
assert(result.status=="unknown" and result.reason=="benchmark_v2_clock_invalid" and spy.factory==0)

-- A running source owns no geometry permission; an explicit refusal stays exact.
context,spy=preparedSetup()
context.prepare=function()
    return {Step=function()error("data callback failed")end,Cancel=function()spy.cancel=spy.cancel+1 end}
end
driver=assert(Benchmark.Create(arbitraryRequest(),context));result=finish(driver)
assert(result.status=="unknown" and result.reason=="benchmark_v2_preparation_error")
assert(spy.cancel==1 and spy.new==0)

-- A phase change cannot reset CPU/wall budgets or accept producer clocks.
context,spy=preparedSetup();prepare=context.prepare
context.prepare=function(...)
    local job=prepare(...);local step=job.Step
    job.Step=function(...)
        local state=step(...)
        if state.status=="complete" then
            spy.clock=80;state.options.clock=function()return 999 end
            state.options.profileClock=function()return 999 end
            state.options.budgets={cpuMs=100,elapsedMs=5000,sliceMs=1}
        end
        return state
    end
    return job
end
local preparedNew=context.library.New
context.library.New=function(graph,options)
    assert(options.budgets.cpuMs<=20 and options.budgets.elapsedMs<=4920)
    assert(options.clock()==.08 and options.profileClock()==80)
    local planner=preparedNew(graph,options);local plan=planner.Plan
    function planner:Plan(...)
        local job=plan(self,...);local step=job.Step
        function job:Step(...)spy.clock=101;return step(self,...)end
        return job
    end
    return planner
end
driver=assert(Benchmark.Create(arbitraryRequest(),context));result=finish(driver)
assert(result.status=="budget_exceeded" and result.estimatedSeconds==nil and spy.plans==1 and spy.cancel<=1,
    tostring(result.status)..":"..tostring(result.reason)..":"..spy.plans..":"..spy.cancel)
assert(driver:GetMetrics().preparationStepCalls==2)

context,spy=preparedSetup();driver=assert(Benchmark.Create(arbitraryRequest(),context))
driver:Step();spy.clock=5001
assert(driver:Step().status=="budget_exceeded" and spy.new==0 and spy.cancel==1)

-- A validated Plan job starts a calculation; nil/throw/incomplete results do not.
for _,outcome in ipairs({"nil","throw","incomplete"}) do
    context,spy=setup()
    context.library={New=function()
        return {Plan=function()
            if outcome=="throw" then error("Plan failed") end
            if outcome=="incomplete" then return {Cancel=function()spy.cancels=spy.cancels+1 end} end
            return nil,"plan_unavailable"
        end}
    end}
    driver=assert(Benchmark.Create(request(),context));result=finish(driver)
    assert(result.status=="unknown" and driver:GetMetrics().calculationsStarted==0)
    assert(driver:GetMetrics().newCalls==1 and driver:GetMetrics().searchStepCalls==0)
end

context,spy=setup();driver=assert(Benchmark.Create(request(),context))
while driver:GetContext().phase~="bind" do assert(driver:Step(64,1).status=="running") end
local actualSteps=driver:GetMetrics().stepCalls
assert(driver:Step(64,1).status=="running" and driver:GetContext().phase=="new")
assert(driver:GetMetrics().stepCalls==actualSteps)
assert(driver:Step(64,1).status=="running" and driver:GetContext().phase=="search")
assert(driver:GetMetrics().stepCalls==actualSteps)
finish(driver)
assert(driver:GetContext().stepCallScope=="public_loader_and_planner_job_Step")

-- Normal UI text and tostring roundtrips tolerate native arithmetic error.
context,spy,sector,wire=setup();wire[3][3][3]=14000
input=request();input.to.x="14"
local captured=assert(ns.NavigationBenchmarkCase.Capture(input)):Copy()
result=finish(assert(Benchmark.Create(captured,context)))
assert(result.status=="complete" and result.estimatedSeconds==9 and spy.plans==1)
context,spy,sector,wire=setup();wire[3][4]={20000,3000,10005};sector.blocks[1].nodes=4
result=finish(assert(Benchmark.Create(request(),context)))
assert(result.status=="unknown" and result.reason=="benchmark_v2_node_ambiguous" and spy.new==0)

-- A captured native map percentage must not lose its last bits by dividing
-- and multiplying before equality. This is unit conversion, not a snap radius.
context,spy,sector,wire=setup();wire[3][1][3]=-19999986
context.api.C_Map.GetMapPosFromWorldPos=function(_,p,map)
    return map,{x=(p.x+131072)/262144,y=(p.y+131072)/262144}
end
context.api.C_Map.GetWorldPosFromMapPos=function(_,p)
    return 1,{x=p.x*262144-131072,y=p.y*262144-131072}
end
input=request();input.from.x=(-19999.986+131072)/262144*100;input.from.y=(20+131072)/262144*100
input.to.x=(30+131072)/262144*100;input.to.y=(40+131072)/262144*100
input.from.x=tostring(input.from.x);input.from.y=tostring(input.from.y)
input.to.x=tostring(input.to.x);input.to.y=tostring(input.to.y)
input=assert(ns.NavigationBenchmarkCase.Capture(input)):Copy()
result=finish(assert(Benchmark.Create(input,context)))
assert(result.status=="complete" and result.estimatedSeconds==9 and spy.plans==1)

-- The real graph may be measured technically without claiming physical identity.
context,spy,sector=setup();sector.identity=nil
driver=assert(Benchmark.Create(request(),context));result=finish(driver)
assert(result.status=="unknown" and result.reason=="benchmark_v2_identity_unproven")
assert(result.estimatedSeconds==nil and spy.new==1 and spy.steps>0)
assert(driver:GetContext().plannerStatus=="complete" and driver:GetContext().scope=="unknown")
context,spy=setup();input=request();input.from.identity.floorID=nil
result=finish(assert(Benchmark.Create(input,context)))
assert(result.status=="unknown" and result.estimatedSeconds==nil)
context,spy=setup();input=request();input.from.identity.phaseID="other-phase"
result=finish(assert(Benchmark.Create(input,context)))
assert(result.status=="unknown" and result.reason=="phase_mismatch" and spy.new==0)

-- Bound load/cancel ownership and step budgets; no unchanged retry.
context,spy=setup();driver=assert(Benchmark.Create(request(),context))
local invalid,why=driver:Step(0,1);assert(invalid==nil and why=="invalid_step_budget")
while spy.loads==0 do assert(driver:Step(1,1).status=="running")end
driver:Cancel();driver:Cancel()
assert(driver:Step(64,1).status=="cancelled" and spy.loaderCancels==1 and spy.new==0)
context,spy=setup();driver=assert(Benchmark.Create(request(),context));spy.clock=6000
result=driver:Step(64,1)
assert(result.status=="budget_exceeded" and spy.new==0)

-- Condition observation_required cannot spin or manufacture an observation.
context,spy=setup()
context.library={New=function()
    spy.new=spy.new+1
    return {Plan=function()
        spy.plans=spy.plans+1
        return {Step=function()spy.steps=spy.steps+1;return {status="observation_required",reason="conditions_missing"}end,
            Cancel=function()spy.cancels=spy.cancels+1 end}
    end}
end}
driver=assert(Benchmark.Create(request(),context));result=finish(driver)
assert(result.status=="unknown" and result.reason=="conditions_missing")
assert(spy.steps==1 and spy.cancels==1)
driver:Step(64,1);assert(spy.steps==1)

-- Public runner consumes real adapter counters, not active game guidance.
context,spy=setup()
local capture=assert(ns.NavigationBenchmarkCase.Capture(request()))
local runner=assert(ns.NavigationBenchmarkRun.New({clock=function()return 0 end,
    profileClock=context.clock,factories={v2=function(r)return Benchmark.Create(r,context)end}}))
assert(runner:Start(capture,"v2"))
for _=1,100 do if runner:Step().status~="running" then break end end
local state=runner:GetState()
assert(state.status=="finished" and state.engines.v2.status=="complete")
assert(state.engines.v2.metrics.newCalls==1 and state.engines.v2.metrics.expandedNodes>0)
assert(state.engines.v2.estimatedSeconds==9 and context.host.activeJob=="foreign active navigation")

-- Invalid optional identities are not silently treated as absent.
context,spy=setup();input=request();input.from.identity=false
assert(Benchmark.Create(input,context)==nil)
context,spy=setup();input=request();input.from.identity.worldID=2;input.to.identity.worldID=2
result=finish(assert(Benchmark.Create(input,context)))
assert(result.status=="unknown" and result.reason=="benchmark_v2_world_uncovered" and spy.loads==0)

-- A technical disconnection is not proof of physical absence either.
context,spy,sector,wire=setup();sector.complete=true;sector.identity=nil
wire[4]={};sector.blocks[1].edges=0;input=request();input.from.identity=nil;input.to.identity=nil
driver=assert(Benchmark.Create(input,context));result=finish(driver)
assert(result.status=="unknown" and result.reason=="benchmark_v2_identity_unproven")
assert(driver:GetContext().plannerStatus=="no_path" and spy.plans==1)

-- Cancellation from native/clock callbacks cannot continue old binding work.
context,spy=setup();driver=assert(Benchmark.Create(request(),context))
spy.onClock=function()driver:Cancel()end
assert(driver:Step(64,1).status=="cancelled" and spy.loads==0)
context,spy=setup();driver=assert(Benchmark.Create(request(),context))
local project=context.api.C_Map.GetMapPosFromWorldPos
context.api.C_Map.GetMapPosFromWorldPos=function(...)driver:Cancel();return project(...)end
assert(finish(driver).status=="cancelled" and spy.new==0)

context,spy=setup()
local new=context.library.New
context.library.New=function(...)spy.clock=spy.clock+101;return new(...)end
result=finish(assert(Benchmark.Create(request(),context)))
assert(result.status=="budget_exceeded" and spy.new==1 and spy.cancels==1)

context,spy=setup();local secret={}
context.api.C_Map.GetMapPosFromWorldPos=function(_,_,map)return map,secret end
context.api.issecretvalue=function(value)return value==secret end
result=finish(assert(Benchmark.Create(request(),context)))
assert(result.status=="unknown" and result.reason=="projection_unavailable" and spy.new==0)
