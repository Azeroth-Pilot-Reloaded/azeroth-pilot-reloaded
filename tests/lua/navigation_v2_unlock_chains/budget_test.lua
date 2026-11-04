local F=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
local function At(job,phase)
    for _=1,2000 do
        local r=job:Step(1);assert(r.status=='running')
        if phase=='chains' and job.planUnlocks and not job.chain then return end
        if phase=='reconstruction' and job.chain then return end
        if phase=='proof' and job.unlock and not job.unlock.proof.ready then return end
    end
    error('Boundary not reached: '..phase)
end
for _,phase in ipairs({'chains','reconstruction','proof'})do for _,stop in ipairs({'cancel','stale','cpu','elapsed'})do
    local wall,cpu,tick=100,0,.001
    local p=F.Planner(nil,nil,{clock=function()return wall end,profileClock=function()cpu=cpu+tick;return cpu end,
        budgets={sliceMs=1,cpuMs=3,elapsedMs=1000}})
    local job=p:Plan({from='start',to='goal'})
    At(job,phase)
    local before=job.cpuMs
    assert(before>0 and job.started==100,'The original budget includes preparation and absence search')
    if stop=='cancel' then job:Cancel()elseif stop=='stale' then p:Invalidate()
    elseif stop=='cpu' then tick=3-before else wall=101 end
    local r=F.Base.Finish(job,1)
    assert(r.status==({cancel='cancelled',stale='stale',cpu='budget_exceeded',elapsed='budget_exceeded'})[stop])
    assert(not r.unlock and not r.unlockPlan and not r.segments)
    assert(job:Step(100)==r and job:Cancel()==r,'Stopped jobs are terminal')
end end
-- Each Step(1) charges exactly one existing operation, including alternatives,
-- shared prerequisites, proof registration and path reconstruction.
local job=F.Planner():Plan({from='start',to='goal'})
local operations=0
for _=1,2000 do
    local r=job:Step(1)
    assert(r.diagnostics.operations==operations+1)
    operations=operations+1
    if r.status~='running'then assert(r.unlock and r.unlockPlan.estimatedSeconds==9);break end
end
assert(job:GetResult().status=='complete')
