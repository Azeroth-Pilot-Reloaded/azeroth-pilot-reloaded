local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local ns=F.Load()
local route=F.Route('flight','west','east',4,10)
local graph={complete=true,nodes={'start','west','east','goal'},edges={
    {id='approach',from='start',to='west',seconds=5},
    {id='final walk',from='east',to='goal',seconds=2},
    {id='whole walk',from='start',to='goal',seconds=40}}}
local planner=assert(ns.LibAPRNavigationV2.New(graph,F.Options({route},4)))
local result=F.Finish(planner:Plan({from='start',to='goal'}))
assert(result.estimatedSeconds==19 and #result.segments==3)
local travel=assert(planner:StartTravel(result))
local action=travel:GetAction()
assert(action.kind=='walk' and action.node=='west' and action.position and action.position.mapID==77,
    'The real walking approach can target the declared flight master')
assert(action.title=='Flight master')
action.position.x=.9
assert(travel:GetAction().position.x==.2,'Approach output is isolated from catalogue data')
