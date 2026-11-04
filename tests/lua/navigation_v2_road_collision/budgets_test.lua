local H=assert(loadfile('tests/lua/navigation_v2_road_collision/support.lua'))()
local api=H.Load()
local mask=H.Mask('clock',{'....','....','....','....'})
local source,time=H.Source(api,mask)
local request={from={x=3.8,y=3.8},to={x=.2,y=.2},mode='walk'}
local job=assert(source:Query(request))
assert(job:Step(1).operations==1)
local before=job:GetState().operations
assert(job:Cancel().status=='cancelled')
assert(job:Step(4096).operations==before and job:Cancel().status=='cancelled')
assert(H.Query(source,{x=3.8,y=3.8},{x=3.2,y=3.2}).status=='complete','Cancel retains shared source')
job=assert(source:Query(request));time.wall=2;job:Step(1);time.wall=1
assert(job:Step(1).reason=='clock_regressed')
job=assert(source:Query(request));time.wall=2;job:Step(1);time.wall=7
local state=job:Step(1)
assert(state.status=='budget_exceeded' and state.reason=='elapsed_budget','Exact elapsed deadline is terminal')
job=assert(source:Query(request));time.wall=0/0
assert(job:Step(1).reason=='clock_unavailable')

local tick=false
time={wall=0,cpu=0}
local options={clock=function()return time.wall end,profileClock=function()
    if tick then time.cpu=time.cpu+.6 end
    return time.cpu
end,cpuMs=2}
source=assert(api.New({worldID=0,base=mask,overlays={}},options))
assert(H.Finish(source).status=='ready');tick=true
job=assert(source:Query(request));state=job:Step(4096)
assert(state.status=='running' and state.operations==2,'Cooperative slice yields after measured work')
state=job:Step(4096)
assert(state.status=='budget_exceeded' and state.reason=='cpu_budget')
local terminal=state.operations;assert(job:Step().operations==terminal)

source=H.Source(api,mask);job=assert(source:Query(request))
request.from.x=-5
assert(H.Finish(job).status=='complete','Query captures endpoint input')
local copy=job:GetState();copy.status='running'
assert(job:GetState().status=='complete','State is returned by value')
options=H.Clocks();options.maxCells=1
source=assert(api.New({worldID=0,base=mask,overlays={}},options));H.Finish(source)
assert(H.Query(source,{x=3.8,y=3.8},{x=3.2,y=3.2}).reason=='cell_limit')

-- Cancelling while a row is only partly validated cannot publish a partial row.
options=H.Clocks();source=assert(api.New({worldID=0,base=mask,overlays={}},options));H.Finish(source)
job=assert(source:Query({from={x=3.8,y=3.8},to={x=3.2,y=3.2},mode='walk'}))
job:Step(3);job:Cancel()
assert(source:GetState().validatedRows==0)
assert(H.Query(source,{x=3.8,y=3.8},{x=3.2,y=3.2}).status=='complete')
local held={}
for i=1,8 do held[i]=assert(source:Query({from={x=3.8,y=3.8},to={x=3.2,y=3.2},mode='walk'})) end
local extra,reason=source:Query({from={x=3.8,y=3.8},to={x=3.2,y=3.2},mode='walk'})
assert(not extra and reason=='query_limit')
for _,pending in ipairs(held) do pending:Cancel() end
assert(source:GetState().activeQueries==0)
local target
options={clock=function()if target then target:Cancel() end;return 0 end,profileClock=function()return 0 end}
source=assert(api.New({worldID=0,base=mask,overlays={}},options));H.Finish(source)
target=assert(source:Query({from={x=3.8,y=3.8},to={x=3.2,y=3.2},mode='walk'}))
assert(target:Step(64).status=='cancelled','Reentrant clock cannot revive cancelled work')
print('Road collision: cancellation, input capture, clocks, operation/slice/total budgets passed')
