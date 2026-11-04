local F=dofile('tests/lua/navigation_v2_sectors/fixture.lua')
local p,decodes,_,_,ns=F.New({cacheSize=1})
local a,b=F.Route(p),F.Route(p)
for _=1,10000 do
    local ra,rb=a:Step(1),b:Step(2)
    local graph=p.preparation.compiled
    assert(graph.stats.resident<=1)
    if ra.status~='running' and rb.status~='running' then
        assert(ra.status=='complete' and rb.status=='complete')
        assert(ra.estimatedSeconds==8 and rb.estimatedSeconds==8)
        break
    end
end
assert(a:GetResult().status=='complete' and b:GetResult().status=='complete')
assert(p.preparation.compiled.stats.evictions>0)

-- An abandoned partial job cannot disturb another search or hold a cache slot.
local job=F.Route(p)
for _=1,10000 do
    job:Step(1)
    if job.search and job.search.loading and job.search.loading.job then break end
end
local partial=job.search.loading.job
job:Cancel()
-- Finish must release an in-flight decoder before dropping its search.
assert(partial:Step().status=='cancelled')
assert(F.Finish(F.Route(p)).estimatedSeconds==8)

-- Pure factory does not load data or acquire any output provider.
local source,reason=ns.NavigationV2Sectors.Source({}, {}, {})
assert(source==nil and reason=='decoder_unavailable')
