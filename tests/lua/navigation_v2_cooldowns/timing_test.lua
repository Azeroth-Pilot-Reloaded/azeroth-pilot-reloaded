local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local function Plan(extra,graph,ready)
    local d,o=F.Declarations(),F.Observation();d[1].from='gate';o.actions.recall.readyAt=ready
    local options=F.Options(d,o)
    for k,v in pairs(extra)do options[k]=v end
    return F.Base.Finish(assert(F.Library.New(graph,options)):Plan({from='cave',to='town'}))
end
local graph={complete=true,nodes={'cave','gate','town'},edges={
    {id='normal',from='cave',to='town',seconds=80}}}
local stop={id='dock',worldID=1,floorID=0,phaseID='present'}
local destination={id='harbor',worldID=1,floorID=0,phaseID='present'}
local extra={scheduled={{id='boat',kind='boat',from='cave',to='gate',origin=stop,destination=destination,
    access='available',costs={approach=2,boarding=3,ride=10,loading=4,disembark=1,final=0},
    wait={mode='periodic',firstDeparture=110,periodSeconds=30}}}}
local r=Plan(extra,graph,130)
assert(r.estimatedSeconds==35 and r.segments[1].seconds==25 and r.segments[2].costDetail.waitSeconds==5,
    'Approach, boarding, departure wait, ride and loading all elapse before personal use')
-- A required mode transition precedes use. It is neither free nor charged twice.
local movement=assert(F.ns.NavigationV2Forever.New({initialMode='mount',level=50,mountOwned=true,
    mountUsable=true,canMountHere=true},{dismountSeconds=4}))
graph.edges[2]={id='approach',from='cave',to='gate',seconds=6,movement={mode='mount',distance=67.2,canMount='available'}}
r=Plan({movement=movement},graph,110)
assert(r.estimatedSeconds==15 and r.segments[2].seconds==9 and r.segments[2].costDetail.waitSeconds==0,
    'Six seconds approach plus four seconds dismount reach the cooldown exactly')
-- Missing transition time cannot be erased by a known cooldown estimate.
movement=assert(F.ns.NavigationV2Forever.New({initialMode='mount',level=50,mountOwned=true,
    mountUsable=true,canMountHere=true},{dismountSeconds=false}))
r=Plan({movement=movement},graph,110)
assert(r.status=='unknown','No invented use time when the required mode transition is unknown')
