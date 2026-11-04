local ns = { NavigationV2Graph = { Budgets = { sliceMs=1, cpuMs=100, elapsedMs=5000 } } }
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkCase.lua"))("test", ns)
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkRun.lua"))("test", ns)
local Run = ns.NavigationBenchmarkRun
local function capture(x)
    return assert(ns.NavigationBenchmarkCase.Capture({startMode="manual",
        from={mapID=71,x=x or 10,y=20},to={mapID=72,x=30,y=40}}))
end
local t, cpu, started, steps, cancelled = 0, 0, {}, {}, {}
local function factory(name, duration)
    return function(request)
        started[#started+1] = name
        assert(request.from.x == 10 and request.coordinateUnit == "map-percent")
        request.from.x = 99 -- The second driver must receive the original captured endpoint.
        cpu = cpu + .2
        local count = 0
        return {
            Step=function(_, operations, milliseconds)
                assert(operations==64 and milliseconds==1)
                count=count+1;steps[name]=(steps[name] or 0)+1;cpu=cpu+.4
                return {status=count<2 and "running" or "complete",estimatedSeconds=duration}
            end,
            GetMetrics=function() return {stepCalls=count,calculationsStarted=1,
                calculationsCompleted=count==2 and 1 or 0,expandedNodes=count*3} end,
            Cancel=function() cancelled[name]=(cancelled[name] or 0)+1 end,
        }
    end
end
local runner = assert(Run.New({clock=function()return t end,profileClock=function()return cpu end,
    factories={v1=factory("v1",37),v2=factory("v2",41)}}))
assert(runner:Start(capture(),"both"))
assert(runner:GetState().status=="running" and #started==0)
runner:Step();assert(#started==1 and steps.v1==nil)
t=.01;runner:Step();assert(steps.v1==1 and steps.v2==nil)
t=.02;runner:Step();assert(steps.v1==2 and #started==1)
local state=runner:GetState()
assert(state.engines.v1.status=="complete" and state.engines.v1.metrics.stepCalls==2)
assert(state.engines.v1.estimatedSeconds==37 and state.engines.v1.wallMs==20)
assert(math.abs(state.engines.v1.cpuMs-1)<.00001)
assert(state.engines.v1.driverCalls==2 and state.engines.v2.status=="pending")
runner:Step();t=.03;runner:Step();t=.04;runner:Step()
state=runner:GetState();assert(state.status=="finished" and #started==2)
assert(state.engines.v2.status=="complete" and state.engines.v2.estimatedSeconds==41)
assert(state.engines.v2.wallMs==20 and cancelled.v1==nil and cancelled.v2==nil)
state.engines.v1.metrics.stepCalls=999
assert(runner:GetState().engines.v1.metrics.stepCalls==2)
runner:Step();assert(steps.v2==2) -- No unchanged restart after termination.

-- Missing optional counters and profiling clocks remain unavailable, not zero.
t=0
local bare=assert(Run.New({clock=function()return t end,factories={v1=function()
    return {Step=function()return {status="complete",estimatedSeconds=0}end}
end}}))
assert(bare:Start(capture(),"both"));bare:Step();t=.01;bare:Step();bare:Step()
state=bare:GetState()
assert(state.status=="finished" and state.engines.v1.cpuMs==nil)
assert(state.engines.v1.metrics.stepCalls==nil and state.engines.v1.driverCalls==1)
assert(state.engines.v1.estimatedSeconds==0)
assert(state.engines.v2.status=="unknown" and state.engines.v2.reason=="benchmark_engine_unavailable")
assert(state.engines.v2.driverCreated==false and state.engines.v2.wallMs==nil)

-- Budget stops, cancellation and stale callbacks do not publish replacement results.
t,cpu=0,0;assert(runner:Start(capture(),"v1"));runner:Step();t=6;runner:Step()
state=runner:GetState();assert(state.engines.v1.status=="budget_exceeded")
assert(state.engines.v1.reason=="benchmark_elapsed_budget" and cancelled.v1==1)
t,cpu=0,0;assert(runner:Start(capture(),"v1"));runner:Step();runner:Cancel();runner:Cancel()
assert(cancelled.v1==2 and runner:GetState().status=="cancelled")

local replacement
replacement=assert(Run.New({clock=function()return t end,profileClock=function()return cpu end,
    factories={v1=function()
        return {Step=function()
            assert(replacement:Start(capture(55),"v2"))
            return {status="complete",estimatedSeconds=999}
        end,Cancel=function()end}
    end,v2=function(request)
        assert(request.from.x==55)
        return {Step=function()return {status="unknown",reason="coverage_missing",estimatedSeconds=777}end}
    end}}))
assert(replacement:Start(capture(),"v1"));replacement:Step();replacement:Step()
assert(replacement:GetState().engines.v1==nil)
replacement:Step();replacement:Step();state=replacement:GetState()
assert(state.status=="finished" and state.engines.v2.status=="unknown")
assert(state.engines.v2.reason=="coverage_missing" and state.engines.v2.estimatedSeconds==nil)

-- A successful constructor whose measurement fails must still release its driver.
local clockReads, released = 0, 0
local failedClock=assert(Run.New({clock=function()
    clockReads=clockReads+1;return clockReads==1 and 1 or .5
end,factories={v1=function()
    return {Step=function()error("must not step")end,Cancel=function()released=released+1 end}
end}}))
assert(failedClock:Start(capture(),"v1"));failedClock:Step();state=failedClock:GetState()
assert(released==1 and state.engines.v1.status=="unknown")
assert(state.engines.v1.reason=="benchmark_clock_invalid" and state.engines.v1.wallMs==nil)

-- Cleanup callbacks may replace the case; the old refusal cannot finish that replacement.
local cleanupReplacement
cleanupReplacement=assert(Run.New({clock=function()return 0 end,factories={
    v1=function()return {Cancel=function()assert(cleanupReplacement:Start(capture(55),"v2"))end}end,
    v2=function(request)
        assert(request.from.x==55)
        return {Step=function()return {status="complete",estimatedSeconds=8}end}
    end}}))
assert(cleanupReplacement:Start(capture(),"v1"));cleanupReplacement:Step()
assert(cleanupReplacement:GetState().status=="running")
cleanupReplacement:Step();cleanupReplacement:Step()
assert(cleanupReplacement:GetState().engines.v2.estimatedSeconds==8)

local longCPU, cpuReleased=0,0
local costly=assert(Run.New({clock=function()return 0 end,profileClock=function()return longCPU end,
    factories={v1=function()
        longCPU=101
        return {Step=function()error("CPU limit must stop before firstStep")end,
            Cancel=function()cpuReleased=cpuReleased+1 end}
    end}}))
assert(costly:Start(capture(),"v1"));costly:Step();state=costly:GetState()
assert(state.engines.v1.status=="budget_exceeded" and state.engines.v1.reason=="benchmark_cpu_budget")
assert(state.engines.v1.creationCalls==1 and state.engines.v1.driverCalls==0 and cpuReleased==1)
assert(state.engines.v1.cpuMs==101 and state.engines.v1.sliceOverruns==1)

local profileTime, resetReleased=10,0
local resetProfile=assert(Run.New({clock=function()return 0 end,profileClock=function()return profileTime end,
    factories={v1=function()return {
        Step=function()profileTime=1;return {status="complete",estimatedSeconds=999}end,
        Cancel=function()resetReleased=resetReleased+1 end}
    end}}))
assert(resetProfile:Start(capture(),"v1"));resetProfile:Step();resetProfile:Step()
state=resetProfile:GetState()
assert(state.engines.v1.status=="unknown" and state.engines.v1.cpuMs==nil and resetReleased==1)
assert(state.engines.v1.reason=="benchmark_profile_clock_invalid" and state.engines.v1.estimatedSeconds==nil)

local metricTypes=assert(Run.New({clock=function()return 0 end,factories={v1=function()
    return {Step=function()return {status="complete",estimatedSeconds=3,optimal=false,
        estimateScope="unlock_approach"}end,
        GetMetrics=function()return {stepCalls=2.5,expandedNodes=-1,preparedEdges=math.huge,
            calculationsStarted=true,distanceYards=12.25,decodingMs=.125}end}
end}}))
assert(metricTypes:Start(capture(),"v1"));metricTypes:Step();metricTypes:Step()
state=metricTypes:GetState()
assert(state.engines.v1.metrics.stepCalls==nil and state.engines.v1.metrics.expandedNodes==nil)
assert(state.engines.v1.metrics.preparedEdges==nil and state.engines.v1.metrics.calculationsStarted==nil)
assert(state.engines.v1.metrics.distanceYards==12.25 and state.engines.v1.metrics.decodingMs==.125)
assert(state.engines.v1.optimal==false and state.engines.v1.estimateScope=="unlock_approach")

assert(Run.New({factories={}})==nil)
local ok,why=runner:Start(capture(),"other");assert(not ok and why=="benchmark_engine_invalid")

-- A terminal refusal can still own a suspended engine job; release it once and refresh real counters.
local refusedReleases=0
local refused=assert(Run.New({clock=function()return 0 end,factories={v2=function()
    return {Step=function()return {status="unknown",reason="observation_required"}end,
        Cancel=function()refusedReleases=refusedReleases+1 end,
        GetMetrics=function()return {cancelCalls=refusedReleases}end}
end}}))
assert(refused:Start(capture(),"v2"));refused:Step();refused:Step()
assert(refusedReleases==1 and refused:GetState().engines.v2.metrics.cancelCalls==1)
refused:Cancel();refused:Step();assert(refusedReleases==1)
print("Benchmark runner: sequential immutable cases, real optional counters/timings, cancellation, budgets and stale replacement passed")
