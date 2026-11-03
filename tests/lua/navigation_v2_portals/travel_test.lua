local F=dofile('tests/lua/navigation_v2_portals/fixture.lua')
local p,time=F.PortalPlanner()
local result=F.Finish(p:Plan({from='start',to='goal'}))
local wrongPhase=assert(p:StartTravel(result))
local red=F.Location(1,'gate','home');red.phase='red'
assert(wrongPhase:Observe(red).kind=='approach' and wrongPhase:BeginUse()==nil)
assert(wrongPhase:Observe(F.Location(2,'gate','home')).kind=='use_portal')
local t=assert(p:StartTravel(result))
assert(t:GetAction().kind=='walk' and t:GetAction().node=='gate')
assert(t:GetAction().position.mapID==42)
assert(t:BeginUse()==nil)
assert(t:Observe(F.Location(1,'start','home')).kind=='walk')
assert(t:Observe(F.Location(2,'gate','home')).kind=='use_portal')
assert(t:Observe(F.Location(3,'far','other')).kind=='approach','proximity must not begin or finish use')
t:Observe(F.Location(4,'gate','home'))
assert(t:BeginUse().kind=='awaiting_transition')
local proof={portalId='door',from='gate',to='far',complete=true,attempt=t:GetAction().attempt}
local loading=F.Location(5,'far','other',proof); loading.loading=true
assert(t:Observe(loading).kind=='awaiting_transition')
assert(t:Observe(F.Location(6,'far','other')).kind=='awaiting_transition')
assert(t:Observe(F.Location(7,'far','wrong',proof)).kind=='awaiting_transition')
assert(t:Observe(F.Location(8,'gate','other',proof)).kind=='awaiting_transition')
local unreliable=F.Location(9,'far','other',proof); unreliable.reliable=false
assert(t:Observe(unreliable).kind=='awaiting_transition')
assert(t:Observe(F.Location(9,'far','other',proof)).kind=='awaiting_transition')
assert(t:Observe(F.Location(10,'far','other',proof)).kind=='walk')
assert(t:GetAction().node=='goal' and t:GetAction().position==nil)
assert(t:Observe(F.Location(11,'goal','other')).kind=='complete')

local guarded=assert(p:StartTravel(result))
guarded:Observe(F.Location(1,'gate','home'));guarded:BeginUse()
local sequence=1
for _,field in ipairs({'portalId','from','to','complete','attempt'}) do
    local bad={portalId='door',from='gate',to='far',complete=true,attempt=guarded:GetAction().attempt}
    bad[field]=nil; sequence=sequence+1
    assert(guarded:Observe(F.Location(sequence,'far','other',bad)).kind=='awaiting_transition')
end
sequence=sequence+1
local redDestination=F.Location(sequence,'far','other',{
    portalId='door',from='gate',to='far',complete=true,attempt=guarded:GetAction().attempt})
redDestination.phase='red'
assert(guarded:Observe(redDestination).kind=='awaiting_transition')

local missing=assert(p:StartTravel(result))
missing:Observe(F.Location(1,'gate','home')); missing:BeginUse()
time.wall=30
assert(missing:Tick().kind=='failed' and missing:Tick().reason=='transition_timeout')
assert(missing:Observe(F.Location(2,'far','other',proof)).kind=='failed','timeout is terminal')
local cancelled=assert(p:StartTravel(result))
cancelled:Cancel()
assert(cancelled:Observe(F.Location(1,'gate','home')).kind=='cancelled')
local stale=assert(p:StartTravel(result))
p:Invalidate()
assert(stale:GetAction().kind=='cancelled' and p:StartTravel(result)==nil)

local p2,clock=F.PortalPlanner()
local r=F.Finish(p2:Plan({from='start',to='goal'}))
local previous=assert(p2:StartTravel(r));previous:Observe(F.Location(1,'gate','home'));previous:BeginUse()
local staleProof={portalId='door',from='gate',to='far',complete=true,attempt=previous:GetAction().attempt}
local current=assert(p2:StartTravel(r));current:Observe(F.Location(1,'gate','home'));current:BeginUse()
assert(current:Observe(F.Location(2,'far','other',staleProof)).kind=='awaiting_transition')
clock.wall=10;current:Tick();clock.wall=9
assert(current:Tick().reason=='clock_unavailable','regressing clocks cannot extend a use indefinitely')
local large,largeClock=F.PortalPlanner()
local largeTravel=assert(large:StartTravel(F.Finish(large:Plan({from='start',to='goal'}))))
largeTravel:Observe(F.Location(1,'gate','home'));largeClock.wall=1e308
assert(select(2,largeTravel:BeginUse())=='deadline_unavailable','unrepresentable deadlines cannot reach native timers')
