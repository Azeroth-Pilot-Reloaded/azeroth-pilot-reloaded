-- Only invented requests/providers; V1 implementation files are executed by the
-- existing fixture, never read or copied by the benchmark adapter.
local ns = {}
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkV1.lua"))("test", ns)
local Create = assert(ns.NavigationBenchmarkV1).Create
local passed = 0
local function test(name, fn)
    local ok, why = pcall(fn)
    assert(ok, name .. ": " .. tostring(why))
    passed = passed + 1
end
local function request()
    return { coordinateUnit="map-percent", startMode="manual",
        from={mapID=81,x=25,y=50}, to={mapID=82,x=100,y=0} }
end
local function fixture(states)
    local calls = { normalized={}, new=0, create=0, step=0, cancelled=0 }
    local instance = {}
    function instance:NormalizeLocation(point)
        calls.normalized[#calls.normalized+1]=point
        return { instanceID=point.instanceID or 7,uiMapID=point.uiMapID,
            x=point.x*1000,y=point.y*1000,z=point.z,floor=point.floor,spaceID=point.spaceID }
    end
    function instance:CanWalk() return true end
    function instance:GetPositionRegion() return "synthetic" end
    local library = {}
    function library:New(options)
        calls.new=calls.new+1; calls.options=options
        return instance
    end
    local planner = {}
    function planner:Create(options)
        calls.create=calls.create+1; calls.request=options
        local job={index=0}
        function job:Step(operations, milliseconds)
            calls.step=calls.step+1
            calls.operations,calls.milliseconds=operations,milliseconds
            self.index=self.index+1
            local row=states[self.index] or states[#states]
            self.waitingData,self.missingTerrain=row.waitingData,row.missingTerrain
            self.terrainReason=row.reason
            self.result=row.result
            return row.status,row.result
        end
        function job:GetResult() return self.result end
        function job:Cancel() calls.cancelled=calls.cancelled+1 end
        calls.job=job
        return job
    end
    local env={mapToWorld=function() end,
        getDynamicPosition=function() error("shared dynamic observation must not be touched") end}
    local context={library=library,planner=planner,environment=env,profile="forever",
        clock=function() return 0 end,walkSpeed=7,
        adapter={CreatePreparation=function() error("shared settings must not be touched") end},
        taxiData={CreateEdgeBuild=function() error("shared taxi must not be touched") end}}
    return context,calls,instance
end
local function complete(seconds)
    return {status="ready",result={segments={},totalSeconds=seconds}}
end

test("independent public instance, percent normalization, identity and no guidance callbacks",function()
    local ctx,calls=fixture({{status="planning"},complete(12.5)})
    local input=request()
    input.from.identity={worldID=7,floorID=0,spaceID="authored-room",z=-4}
    local driver=assert(Create(input,ctx))
    assert(calls.new==1 and calls.create==1 and calls.step==0)
    assert(calls.options.profile=="forever" and calls.options.environment~=ctx.environment)
    assert(ctx.environment.getDynamicPosition~=nil)
    assert(calls.options.environment.getDynamicPosition==nil)
    local start,goal=calls.normalized[1],calls.normalized[2]
    assert(start.space=="map" and start.uiMapID==81 and start.x==0.25 and start.y==0.5)
    assert(goal.uiMapID==82 and goal.x==1 and goal.y==0)
    assert(start.instanceID==7 and start.floor==0 and start.spaceID=="authored-room" and start.z==-4)
    assert(goal.z==nil and goal.floor==nil and goal.spaceID==nil)
    local plan=calls.request
    assert(plan.data~=nil and plan.data~=ctx.adapter and plan.start.x==250 and plan.goal.x==1000)
    assert(plan.adapter==nil and plan.taxiData~=ctx.taxiData and plan.preferZoneAccess==false)
    assert(plan.preferLocalSpaceExit==false and plan.walkSpeed==7 and plan.clock==ctx.clock)
    assert(plan.prepareSegment({kind="walk"},1)==nil)
    assert(plan.taxiData:CreateEdgeBuild():Step(64,1)=="ready")
    input.from.x=99; assert(plan.start.x==250)
    assert(driver:Step(32,0.5).status=="running" and calls.operations==32 and calls.milliseconds==0.5)
    local result=driver:Step(64,1)
    assert(result.status=="complete" and result.estimatedSeconds==12.5 and result.optimal==nil)
    assert(type(result.estimateScope)=="string")
    result.status="changed"; assert(driver:Step(64,1).status=="complete" and calls.step==2)
    local metrics=driver:GetMetrics()
    assert(metrics.newCalls==1 and metrics.stepCalls==2 and metrics.calculationsStarted==0)
    assert(metrics.operations==nil and metrics.preparationMs==nil and metrics.expandedNodes==nil)
    metrics.stepCalls=999; assert(driver:GetMetrics().stepCalls==2)
    local scope=driver:GetContext()
    assert(scope.taxiIncluded==false and scope.dynamicPositionsIncluded==false)
    assert(scope.cacheState=="shared_host_residency_unknown" and scope.profile=="forever")
    scope.profile="changed"; assert(driver:GetContext().profile=="forever")
end)

test("waiting or missing data never becomes no_path or an ETA",function()
    for _,row in ipairs({{status="no_path",waitingData=true},{status="no_path",missingTerrain=true},
        {status="ready",waitingData=true,result={segments={},totalSeconds=1}}}) do
        local ctx=fixture({row})
        local driver=assert(Create(request(),ctx))
        local result=driver:Step(64,1)
        assert(result.status=="unknown" and result.estimatedSeconds==nil)
        assert(driver:Step(64,1).status=="unknown")
    end
    local ctx=fixture({{status="no_path"}})
    local result=assert(Create(request(),ctx)):Step(64,1)
    assert(result.status=="no_path" and result.reason=="benchmark_v1_no_path_in_scope")
end)

test("shared action, cooldown, housing and unlock observers are never invoked",function()
    local ctx,calls=fixture({complete(1)})
    local mutations=0
    local function mutate() mutations=mutations+1;return true end
    local function holiday() return true end
    ctx.environment.isHolidayActive=holiday
    for _,key in ipairs({"getActionUsability","getActionUsabilityIgnoringCooldown","watchUnlockAction",
        "getHousingInitiative","isUnlockActionComplete","getPlayerPosition","getNPCName","futureMutationCallback"}) do
        ctx.environment[key]=mutate
    end
    local create=ctx.library.New
    ctx.library.New=function(self,options)
        local env=options.environment
        assert(env.isHolidayActive==holiday)
        local usable,reason=env.getActionUsability("housing",1)
        assert(usable==nil and reason=="pending_data")
        usable,reason=env.getActionUsabilityIgnoringCooldown("spell",1)
        assert(usable==nil and reason=="pending_data")
        for _,key in ipairs({"watchUnlockAction","getHousingInitiative","isUnlockActionComplete",
            "getPlayerPosition","getNPCName","futureMutationCallback"}) do assert(env[key]==nil) end
        return create(self,options)
    end
    local driver=assert(Create(request(),ctx))
    assert(driver:Step(64,1).status=="complete")
    assert(mutations==0 and ctx.environment.getActionUsability==mutate)
    assert(driver:GetContext().actionUsabilityObserved==false)
    assert(driver:GetContext().unlockObservationIncluded==false)
end)

test("provider cancellation is stale, explicit cancellation is idempotent",function()
    local ctx=fixture({{status="cancelled"}})
    assert(assert(Create(request(),ctx)):Step(64,1).status=="stale")
    local calls
    ctx,calls=fixture({{status="planning"}})
    local driver=assert(Create(request(),ctx))
    driver:Cancel(); driver:Cancel()
    assert(driver:Step(64,1).status=="cancelled" and calls.step==0 and calls.cancelled==1)
    assert(driver:GetMetrics().cancelCalls==1)
end)

test("optional and malformed API results fail without producing estimates",function()
    for _,row in ipairs({{status="unsupported"},{status="ready"},
        {status="ready",result={segments={},totalSeconds=math.huge}},
        {status="ready",result={segments={},totalSeconds=-1}},
        {status="ready",result={segments={},totalSeconds=2,localExitOnly=true}}}) do
        local ctx=fixture({row})
        local result=assert(Create(request(),ctx)):Step(64,1)
        assert(result.status=="unknown" and result.estimatedSeconds==nil)
    end
    local ctx,calls=fixture({complete(0)})
    local driver=assert(Create(request(),ctx))
    calls.job.Step=function() error("provider error") end
    local result=driver:Step(64,1)
    assert(result.status=="unknown" and result.reason=="benchmark_v1_step_failed" and calls.cancelled==1)
end)

test("validation and unsupported phase identity happen before job creation",function()
    local ctx,calls=fixture({complete(1)})
    for _,input in ipairs({{}, {coordinateUnit="world"}, request(), request(), request()}) do
        if input.from then
            if input.from.x==25 then input.from.x=-1 end
        end
        local driver,reason=Create(input,ctx)
        assert(driver==nil and type(reason)=="string")
    end
    assert(calls.new==0)
    local input=request();input.from.identity={phaseID="captured-phase"}
    local driver,reason=Create(input,ctx)
    assert(driver==nil and reason=="benchmark_v1_phase_identity_unsupported" and calls.create==0)
    for _,key in ipairs({"library","planner","environment"}) do
        local bad=fixture({complete(1)});bad[key]=nil
        assert(Create(request(),bad)==nil)
    end
    ctx.profile="unsupported";assert(Create(request(),ctx)==nil)
end)

test("normalization refusal or lost observed identity does not start a planner",function()
    local ctx,calls,instance=fixture({complete(1)})
    instance.NormalizeLocation=function() return nil end
    assert(Create(request(),ctx)==nil and calls.create==0)
    instance.NormalizeLocation=function() error("projection unavailable") end
    assert(Create(request(),ctx)==nil and calls.create==0)
    instance.NormalizeLocation=function() return {instanceID=7,uiMapID=81,x=0,y=0} end
    local input=request();input.from.identity={floorID=2}
    assert(Create(input,ctx)==nil and calls.create==0)
end)

test("normalizer cannot erase observed identity by mutating its argument",function()
    local ctx,calls,instance=fixture({complete(1)})
    instance.NormalizeLocation=function(_,point)
        point.floor=nil;point.instanceID=7
        return point
    end
    local input=request();input.from.identity={floorID=2}
    local driver,reason=Create(input,ctx)
    assert(driver==nil and reason=="benchmark_v1_identity_unresolved" and calls.create==0)
    assert(input.from.identity.floorID==2)
end)

test("absent CreateSearch cannot be counted as an actual engine call",function()
    local ctx,calls=fixture({complete(1)})
    local driver=assert(Create(request(),ctx))
    assert(not pcall(calls.request.engine.CreateSearch,calls.request.engine,{}))
    assert(driver:GetMetrics().calculationsStarted==0)
end)

test("nil, throwing or malformed CreateSearch cannot count as a created calculation",function()
    for _,factory in ipairs({function() return nil end,function() error("search creation failed") end,
        function() return {} end}) do
        local ctx,calls,instance=fixture({complete(1)})
        instance.CreateSearch=factory
        local driver=assert(Create(request(),ctx))
        calls.job.Step=function(_,operations,ms)
            return calls.request.engine:CreateSearch({}):Step(operations,ms)
        end
        local result=driver:Step(64,1)
        assert(result.status=="unknown" and result.reason=="benchmark_v1_step_failed")
        assert(driver:GetMetrics().calculationsStarted==0 and driver:GetMetrics().calculationsCompleted==0)
        driver:Cancel();driver:Cancel()
        assert(calls.cancelled==1 and driver:GetMetrics().cancelCalls==1)
    end
end)

test("search metrics count actual public search calls and exposed work only",function()
    local ctx,calls,instance=fixture({complete(1)})
    local searchCalls=0
    function instance:CreateSearch(options)
        assert(options.synthetic)
        local job={workLastStep=0,expansions=0,walkChecks=0,ingestedEdges=0}
        function job:Step(operations,ms)
            assert(operations==8 and ms==0.5)
            searchCalls=searchCalls+1
            self.workLastStep=3;self.expansions=self.expansions+2
            self.walkChecks=self.walkChecks+1;self.ingestedEdges=4
            return searchCalls==1 and "planning" or "ready",{segments={},totalSeconds=1}
        end
        function job:GetResult() return {} end
        function job:Cancel() end
        return job
    end
    local driver=assert(Create(request(),ctx))
    local search=calls.request.engine:CreateSearch({synthetic=true})
    assert(driver:GetMetrics().calculationsStarted==1 and driver:GetMetrics().searchStepCalls==0)
    search:Step(8,0.5);search:Step(8,0.5)
    local m=driver:GetMetrics()
    assert(m.stepCalls==0 and m.searchStepCalls==2 and m.operations==6)
    assert(m.calculationsCompleted==1 and m.expansions==4 and m.walkChecks==2 and m.ingestedEdges==4)
    assert(m.walkDominanceSkipped==nil and m.preparationStepCalls==nil)
    assert(search:GetResult()~=nil)
    local noCounters={Step=function() return "ready",{} end}
    instance.CreateSearch=function() return noCounters end
    calls.request.engine:CreateSearch({}):Step(8,0.5)
    assert(driver:GetMetrics().operations==nil and driver:GetMetrics().expansions==nil)
end)

test("real public planner and V1 library with invented catalogue, both profiles",function()
    local realFixture=dofile("tests/lua/navigation_fixture.lua")
    for _,profile in ipairs({"forever","retail"}) do
        realFixture.profile=profile
        local normal=realFixture:Load({config={IsolatedAreas={[91081]="invented-open-field"}},connections={}})
        dofile("APR-Core/features/navigation/NavigationPlanner.lua")
        local env={getMapInfo=function(id) return {mapID=id,parentMapID=0,mapType=3} end,
            mapToWorld=function(_,x,y) return 77,x*100,y*100 end,
            getCharacter=function() return {faction="Alliance",level=40,class="MAGE",raceID=1,mapID=91081} end,
            getActionUsability=function() error("shared action observer") end}
        local marker={};APR.navigation={search=marker};APRNavigationCharacterSettings={kept=marker}
        local library=LibStub("LibAPRNavigation-1.0")
        local independent
        local ctx={library={New=function(_,options)
                independent=library:New(options);return independent
            end},environment=env,profile=profile,
            clock=function() return 0 end,walkSpeed=7,planner=APR.NavigationPlanner,
            adapter=APR.NavigationAdapter,taxiData=APR.taxiData}
        local input={coordinateUnit="map-percent",startMode="manual",
            from={mapID=91081,x=0,y=0},to={mapID=91081,x=14,y=0}}
        local first=assert(Create(input,ctx));local second=assert(Create(input,ctx))
        assert(independent:GetActionUsability("spell",12345)~=true,
            "Missing action/cooldown observations never authorize a spell")
        local result
        for _=1,1000 do result=first:Step(64,1);if result.status~="running" then break end end
        assert(result.status=="complete" and math.abs(result.estimatedSeconds-2)<1e-9,
            profile .. " real public planner outcome " .. tostring(result.status) .. ":" .. tostring(result.reason))
        assert(first:GetMetrics().calculationsStarted>=1 and first:GetMetrics().calculationsCompleted>=1)
        assert(first:GetMetrics().operations>0 and first:GetMetrics().searchStepCalls>0)
        second:Cancel();assert(second:Step(64,1).status=="cancelled")
        assert(APR.NavigationData==normal and APR.navigation.search==marker)
        assert(APRNavigationCharacterSettings.kept==marker and next(APRNavigationCharacterSettings)=="kept")
        assert(input.from.x==0 and input.to.x==14)
    end
end)

print("Navigation benchmark V1: " .. passed .. " public synthetic scenarios passed; no live route or timing claim")
