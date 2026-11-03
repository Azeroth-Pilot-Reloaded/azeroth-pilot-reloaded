local H=dofile('tests/lua/navigation_v2_portals/host_fixture.lua')
local F=dofile('tests/lua/navigation_v2_portals/fixture.lua')
local h,ns,env=H.Load(false)
local graph={complete=true,nodes={'start','gate','far','goal'},edges={
    {id='approach',from='start',to='gate',seconds=4},
    {id='walk',from='gate',to='far',seconds=20},
    {id='finish',from='far',to='goal',seconds=3}}}
assert(env:Enable(graph,{portals=F.Catalog(),portalObservation=F.Observation()}))
h:Plan({from='start',to='goal',via={'gate'}},env.context)
local r=H.Finish(h);h:StartTravel(r)
h:ObserveTravel(F.Location(1,'gate','home'))
assert(h:ObservePortals(F.Observation(2,false)))
r=H.Finish(h)
assert(r.objective.from=='gate' and #r.objective.via==0 and r.estimatedSeconds==23,
    'access changes must resume from confirmed progress, without revisiting a passed mandatory access')
assert(h:ObservePortals(F.Observation(3)))
r=H.Finish(h);assert(r.estimatedSeconds==9)
h:StartTravel(r);h:ObserveTravel(F.Location(1,'gate','home'));h:BeginPortalUse()
assert(h:ObservePortals(F.Observation(4,false)))
assert(h:GetResult().status=='stale' and h:GetResult().objective.to=='goal' and h:GetTravelAction()==nil,
    'an unconfirmed transition cannot supply a replan origin; goal must remain retained')
