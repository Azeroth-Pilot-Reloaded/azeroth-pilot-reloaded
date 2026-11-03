local F=dofile('tests/lua/navigation_v2_unlocks/fixture.lua')
for _,phase in ipairs({'initial','approach'})do
    local wall,cpu,tick=100,0,0
    local p=F.Planner(nil,{clock=function()return wall end,profileClock=function()cpu=cpu+tick;return cpu end,
        budgets={sliceMs=1,cpuMs=5,elapsedMs=20}})
    local job=p:Plan({from='cave',to='goal'})
    if phase=='approach' then
        for _=1,500 do
            local r=job:Step(1)
            assert(r.status=='running')
            if r.diagnostics.phase=='unlock_approach' then break end
        end
        assert(job.unlockApproach,'Fixture must reach the actual fallback boundary')
    end
    wall=100.021
    local r=job:Step(1)
    assert(r.status=='budget_exceeded' and r.reason=='elapsed_budget' and not r.unlock)
    assert(job:Step(100)==r and job:Cancel()==r)
end
for _,stop in ipairs({'cancel','stale','cpu'})do
    local cpu,tick=0,0
    local p=F.Planner(nil,{profileClock=function()cpu=cpu+tick;return cpu end,budgets={sliceMs=1,cpuMs=2,elapsedMs=5000}})
    local job=p:Plan({from='cave',to='goal'})
    for _=1,500 do
        local r=job:Step(1);assert(r.status=='running')
        if r.diagnostics.phase=='unlock_approach' then break end
    end
    if stop=='cancel' then job:Cancel()elseif stop=='stale'then p:Invalidate()else tick=1 end
    local r=F.Base.Finish(job,1)
    assert(r.status==({cancel='cancelled',stale='stale',cpu='budget_exceeded'})[stop] and not r.unlock)
end
