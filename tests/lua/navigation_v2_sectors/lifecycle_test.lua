local F=dofile('tests/lua/navigation_v2_sectors/fixture.lua')
local p,decodes,time=F.New({cacheSize=1})
assert(F.Finish(F.Route(p)).estimatedSeconds==8)

local before=decodes.meadow
assert(F.Finish(F.Route(p)).estimatedSeconds==8)
assert(decodes.meadow>before, 'evicted sectors must reload without destroying the itinerary')
local cancelled=F.Route(p)
for _=1,6 do cancelled:Step(1) end
local result=cancelled:Cancel()
assert(result.status=='cancelled' and cancelled:Step()==result)
local stale=F.Route(p);stale:Step(1);p:Invalidate()
assert(stale:Step().status=='stale')
assert(F.Finish(F.Route(p)).estimatedSeconds==8)

p,decodes,time=F.New({budgets={cpuMs=2}})
local job=F.Route(p);time.tick=0.2
result=F.Finish(job)
assert(result.status=='budget_exceeded' and result.reason=='cpu_budget' and not result.segments)
assert(job:Step()==result)
p,decodes,time=F.New()
job=F.Route(p);time.tick=0.6
result=job:Step(1000)
assert(result.status=='running' and result.diagnostics.operations<=2)
time.tick=0;time.wall=5
assert(job:Step().reason=='elapsed_budget')

-- Search and reconstruction are separately interruptible, including a cached route.
p=F.New()
job=F.Route(p)
for _=1,10000 do
    job:Step(1)
    if job.search and job.search.build then break end
end
assert(job.search and job.search.build)
assert(job:Step(1).status=='running')
assert(job:Cancel().status=='cancelled')
assert(F.Finish(F.Route(p)).estimatedSeconds==8)

p,decodes=F.New({cacheSize=2})
assert(F.Finish(F.Route(p,'meadow:terrain:1','meadow:terrain:2')).estimatedSeconds==1)
assert(F.Finish(F.Route(p,'harbor:terrain:1','harbor:terrain:2')).estimatedSeconds==1)
assert(F.Finish(F.Route(p,'meadow:terrain:1','meadow:terrain:2')).estimatedSeconds==1)
assert(F.Finish(F.Route(p,'pass:terrain:1','pass:terrain:2')).estimatedSeconds==1)
assert(F.Finish(F.Route(p,'harbor:terrain:1','harbor:terrain:2')).estimatedSeconds==1)
assert(decodes.meadow==1 and decodes.harbor==2 and decodes.pass==1, 'cache must evict the least recently used sector')

p,decodes,time=F.New({budgets={cpuMs=2}})
job=F.Route(p)
for _=1,10000 do
    job:Step(1)
    if job.search and job.search.build then break end
end
assert(job.search and job.search.build)
time.tick=1
result=F.Finish(job)
assert(result.status=='budget_exceeded' and result.reason=='cpu_budget' and not result.segments)

-- Reentrant cancellation during a native decoder leaves no cached partial data.
local reentrant, fired
p=F.New({decode=function()
    if not fired then fired=true;reentrant:Cancel() end
end})
reentrant=F.Route(p)
result=F.Finish(reentrant)
assert(result.status=='cancelled' and p.preparation.compiled.stats.resident==0)
assert(F.Finish(F.Route(p)).estimatedSeconds==8)
