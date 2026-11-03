local F=dofile('tests/lua/navigation_v2_portals/fixture.lua')
local S=dofile('tests/lua/navigation_v2_scheduled/fixture.lua')
local route=S.Route();route.access='available';route.wait={mode='periodic',firstDeparture=110,periodSeconds=30}
local function Planner(approach,walk,movement,clock)
    local graph={complete=true,nodes={'start','west pier','east pier','goal'},edges={
        {id='approach',from='start',to='west pier',seconds=approach,
            movement=movement and {mode='mount',distance=approach,canMount='available'}},
        {id='exit',from='east pier',to='goal',seconds=3},
        {id='walk',from='start',to='goal',seconds=walk or 80}}}
    return assert(F.Library.New(graph,{clock=clock or function()return 100 end,profileClock=function()return 0 end,
        scheduled={route},movement=movement}))
end
local function Plan(p) return F.Finish(p:Plan({from='start',to='goal'})) end
local p=Planner(5,60)
local r=Plan(p)
assert(r.estimatedSeconds==60 and r.segments[1].edgeId=='walk','periodic wait is evaluated after approach')
p=Planner(5);r=Plan(p)
assert(r.estimatedSeconds==79 and r.segments[2].kind=='scheduled')
assert(r.segments[2].transportId=='river crossing' and r.segments[2].costDetail.waitSeconds==29)
assert(r.segments[2].costDetail.departureAt==140)
assert(Plan(Planner(4)).estimatedSeconds==49,'exact departure is usable')
assert(math.abs(Plan(Planner(4.001)).estimatedSeconds-79)<1e-8,'missed departure waits for the next service')
local wall=100
local frozen=Planner(5,80,nil,function()return wall end)
local job=frozen:Plan({from='start',to='goal'})
wall=104
assert(F.Finish(job).estimatedSeconds==79,'the timetable epoch stays frozen for the query')

local profile=assert(F.Library.NewForeverMovement({initialMode='mount',level=40,mountOwned=true,
    mountUsable=true,canMountHere=true},{mountSpeed=1,dismountSeconds=2}))
r=Plan(Planner(4,100,profile))
assert(r.estimatedSeconds==79,'dismount before timetable must miss departure110, not cost51')
assert(r.segments[2].transitionSeconds==2 and r.segments[2].seconds==72)
assert(r.segments[2].costDetail.waitSeconds==28 and r.segments[2].mode=='walk')
assert(r.segments[3].transitionSeconds==0,'dismount charged once')
r=Plan(Planner(2,100,profile))
assert(r.estimatedSeconds==49 and r.segments[2].costDetail.waitSeconds==0)

local old=Plan(p)
local replacement=S.Route();replacement.access='unavailable'
assert(p:SetScheduled({replacement}))
assert(not p:IsCurrent(old) and Plan(p).estimatedSeconds==80)
local revision=p.revision
assert(p:SetScheduled({replacement})==false and p.revision==revision)
replacement.access='available'
assert(p:SetScheduled({replacement},{['river crossing']={ride=0,wait={mode='known',seconds=0}}}))
assert(Plan(p).estimatedSeconds==20)

local unknown=assert(F.Library.NewForeverMovement({initialMode='mount'}, {dismountSeconds=false}))
local u=Planner(0,100,unknown)
local unknownResult=Plan(u)
assert(unknownResult.status=='unknown','unknown transition terminates honestly without a retry loop')
