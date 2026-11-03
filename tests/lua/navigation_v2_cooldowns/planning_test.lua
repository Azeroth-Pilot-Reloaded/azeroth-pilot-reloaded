local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local function Plan(ready,normal)
    local graph=F.Graph();graph.edges[1].seconds=normal
    local o=F.Observation();o.actions.recall.readyAt=ready
    local p=assert(F.Library.New(graph,F.Options(nil,o)))
    return F.Base.Finish(p:Plan({from='cave',to='goal'}))
end
local r=Plan(108,40)
assert(r.status=='complete' and r.estimatedSeconds==20,'Wait eight seconds then use and finish beats forty seconds walking')
assert(r.segments[1].costDetail.waitSeconds==8 and r.segments[1].costDetail.useAt==108)
r=Plan(140,40)
assert(r.estimatedSeconds==40 and r.segments[1].edgeId=='normal','An expensive wait loses to walking')
r=Plan(108.125,40)
assert(r.estimatedSeconds==20.125,'No temporal discretization')
