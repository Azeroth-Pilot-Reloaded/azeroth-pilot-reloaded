local F=dofile('tests/lua/navigation_v2/fixture.lua')
local Navigation=F.Library
local g={complete=true,nodes={},edges={}}
for i=1,3000 do
    g.nodes[i]='n'..i
    if i>1 then g.edges[#g.edges+1]={id='e'..i,from='n'..(i-1),to='n'..i,seconds=1} end
end
local p=assert(Navigation.New(g,{clock=function()return 0 end,profileClock=function()return 0 end}))
local job=p:Plan({from='n1',to='n3000',via={'n1500'}})
local result=F.Finish(job,64)
assert(result.status=='complete' and result.estimatedSeconds==2999)
local instructions=0
debug.sethook(function()instructions=instructions+100 end,'',100)
local travel=assert(p:StartTravel(result))
debug.sethook()
assert(instructions<10000,'StartTravel synchronously traversed the long trajectory: '..instructions)
-- Mutation both before and after starting must not replace the owned itinerary.
result.segments[1].to='foreign';result.segments[2].kind='portal';result.segments[2].portalId='missing'
result.objective.to='foreign';result.objective.via[1]='foreign'
assert(travel:GetAction().node=='n2')
assert(travel:Observe({sequence=1,reliable=true,loading=false,node='n2'}).node=='n3')
local second=assert(p:StartTravel(result))
assert(second:GetAction().node=='n2' and second:RemainingRequest().to=='n3000')
assert(second:RemainingRequest().via[1]=='n1500')
travel.segments={{to='foreign'}}
assert(travel:GetAction().node=='n3','public fields cannot replace the private execution data')
travel:Cancel();assert(second:GetAction().kind=='walk')
p:Invalidate();assert(second:GetAction().kind=='cancelled' and not p:StartTravel(result))

-- Capturing is part of the original job, with its original CPU/wall budget.
local function snapshotJob(limits,budgets)
    local time={wall=0,cpu=0,tick=0}
    local planner=assert(Navigation.New(g,{limits=limits,budgets=budgets,
        clock=function()return time.wall end,
        profileClock=function()local n=time.cpu;time.cpu=n+time.tick;return n end}))
    local pending=planner:Plan({from='n1',to='n3'})
    for _=1,20000 do
        local r=pending:Step(1)
        assert(r.status=='running')
        if r.diagnostics.phase=='execution_snapshot' then return planner,pending,time end
    end
    error('snapshot phase was never reached')
end
local planner,pending,time=snapshotJob({snapshotFields=8})
local stopped=F.Finish(pending,1)
assert(stopped.status=='budget_exceeded' and stopped.reason=='snapshot_limit' and not stopped.segments)
assert(not planner:StartTravel(stopped))
planner,pending,time=snapshotJob(nil,{cpuMs=2})
time.tick=0.6
assert(pending:Step(10000).status=='running','copy must yield inside a tranche')
stopped=F.Finish(pending,1)
assert(stopped.status=='budget_exceeded' and stopped.reason=='cpu_budget' and not stopped.segments)
planner,pending,time=snapshotJob()
time.wall=6
assert(pending:Step().reason=='elapsed_budget')
planner,pending,time=snapshotJob()
pending:Step(1);assert(pending:Cancel().status=='cancelled' and not planner:StartTravel(pending:GetResult()))
planner,pending,time=snapshotJob()
pending:Step(1);planner:Invalidate();assert(pending:Step().status=='stale')

-- Only observed proof can resume the original journey, even if all public
-- explanatory prerequisite metadata is edited after the result is published.
local U=dofile('tests/lua/navigation_v2_unlock_chains/fixture.lua')
planner=U.Planner();result=U.Result(planner)
local original=result.unlockEntry.node
result.unlockEntry.node='foreign';result.unlockEntry.opens={};result.unlockEntry.proof.required={}
result.unlock.id='foreign';result.unlockEntry.proof.ready=false
local journey=assert(U.Library.NewJourney({from='start',to='goal'}))
travel=assert(planner:StartTravel(result,nil,journey))
assert(travel:GetAction().node==original and journey:RemainingRequest().to==original)
journey.unlock.entry.node='foreign'
assert(journey:RemainingRequest().to==original,'display metadata is not execution proof')
assert(planner:UnlockReady(journey)==false)

local T=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local ns=T.Load()
planner=assert(ns.LibAPRNavigationV2.New({complete=true,nodes={'west','east'},edges={}},
    T.Options({T.Route('flight','west','east',6,10)},10)))
result=T.Finish(planner:Plan({from='west',to='east'}))
result.segments[1].fareCopper=999;result.segments[1].resources.money=999
travel=assert(planner:StartTravel(result))
assert(travel:GetAction().fareCopper==6)
travel:Observe({sequence=1,reliable=true,node='west',stopID='west',worldID=7,floorID=0,phaseID='shared',onTaxi=false})
local quote={confirmed=true,originID='west',destinationID='east',reachable=true,fareCopper=6}
assert(travel:BeginTaxi(quote,{money=6}).kind=='awaiting_taxi')
travel.conditionToken.revision=999
assert(planner:StartTravel(result):GetAction().fareCopper==6,'one travel token cannot mutate a captured result')
local forged={status='complete',owner=planner.identity,revision=planner.revision,
    conditionToken=planner.conditions:GetToken(),objective={from='west',to='east',via={}},segments={}}
assert(not planner:StartTravel(forged),'public ownership fields cannot install an uncaptured execution plan')

-- Private weak-key ownership must not turn completed jobs into a result cache.
local weak=setmetatable({result},{__mode='v'})
result=nil;travel=nil
collectgarbage('collect');collectgarbage('collect')
assert(not weak[1],'the private snapshot registry retained a discarded public result')
