local ns={NavigationV2Graph={Budgets={sliceMs=1,cpuMs=100,elapsedMs=5000}}}
APR={}
assert(loadfile('APR-Core/features/navigation/NavigationBenchmarkCase.lua'))('test',ns)
assert(loadfile('APR-Core/features/navigation/NavigationBenchmarkRun.lua'))('test',ns)
assert(loadfile('APR-Core/features/navigation/NavigationBenchmarkHost.lua'))('test',ns)
local Host=ns.NavigationBenchmarkHost
local reads,now,cpu,positionReads=0,0,0,0
local map=5
local api={
 IsPlayerInWorld=function()return true end,
 GetBuildInfo=function()reads=reads+1;return '1.60.1','70755','',16001 end,
 GetTimePreciseSec=function()return now end,
 debugprofilestop=function()return cpu end,
 C_Map={GetBestMapForUnit=function()return map end,GetPlayerMapPosition=function(id,unit)
  assert(id==5 and unit=='player');positionReads=positionReads+1;return {x=.12,y=.34}
 end},
}
local starts,cancels={},0
local function engine(name)
 return {Create=function(request,context)
  assert(context.profile=='forever' and context.build=='1.60.1.70755')
  assert(context.walkSpeed==7 and request.coordinateUnit=='map-percent')
  starts[#starts+1]={engine=name,x=request.from.x,y=request.from.y,mapID=request.from.mapID}
  request.from.x=88
  local count=0
  return {Step=function()
   cpu=cpu+.5;count=count+1
   return {status=count<2 and 'running' or 'complete',estimatedSeconds=90}
  end,Cancel=function()cancels=cancels+1 end,
  GetMetrics=function()return {stepCalls=count,calculationsStarted=1,calculationsCompleted=count==2 and 1 or 0}end,
  GetContext=function()return {domain='controlled-test',cache='unknown',malformed={}}end}
 end}
end
local host=assert(Host.New({api=api,apr={},engines={v1=engine('v1'),v2=engine('v2')}}))
assert(reads==0 and positionReads==0 and host:GetState().status=='idle')
local input={startMode='player',from={mapID='invalid'},to={mapID='7',x='30',y='40'}}
assert(host:Start(input,'both'));assert(positionReads==1 and reads==1)
for i=1,6 do now=now+.01;host:Step()end
local state=host:GetState()
assert(state.status=='finished' and #starts==2 and positionReads==1)
assert(starts[1].x==12 and starts[2].x==12 and starts[2].y==34)
assert(host:GetCapture().from.mapID==5 and host:GetCapture().from.identity==nil)
assert(state.engines.v1.metrics.stepCalls==2 and state.engines.v2.estimatedSeconds==90)
local context=host:GetContext()
assert(context.profile=='forever' and context.build=='1.60.1.70755')
assert(context.wallClock=='GetTimePreciseSec' and context.profileClock=='debugprofilestop')
assert(context.engines.v2.domain=='controlled-test' and context.engines.v2.malformed==nil)
context.engines.v2.domain='bad';assert(host:GetContext().engines.v2.domain=='controlled-test')
local report=host:GetReport()
assert(report:find('map%-percent') and report:find('90') and report:find('stepCalls'))
assert(report:find('cache') and report:find('unknown') and report:find('non%-comparable'))
local capture=host:GetCapture();capture.from.x=99;assert(host:GetCapture().from.x==12)
assert(host:Start(input,'v1'));host:Step();host:Cancel();host:Cancel();assert(cancels==1)

-- Invalid replacement cancels the old driver and removes its results, with no native read.
assert(host:Start(input,'v1'));host:Step()
local beforeReads=positionReads
local ok,why=host:Start({startMode='player',to={mapID=7,x=101,y=4}},'both')
assert(not ok and why=='benchmark_goal_coordinates_invalid' and cancels==2)
assert(positionReads==beforeReads and host:GetCapture()==nil and next(host:GetState().engines)==nil)

-- Native nils, protected values and map transitions are explicit unavailable, never fabricated.
api.IsPlayerInWorld=function()return false end
beforeReads=positionReads
assert(not host:Start(input,'v1') and positionReads==beforeReads)
api.IsPlayerInWorld=nil
assert(not host:Start(input,'v1') and positionReads==beforeReads)
api.IsPlayerInWorld=function()return true end
api.C_Map.GetPlayerMapPosition=function()return nil end
assert(not host:Start(input,'v1'));assert(host:GetCapture()==nil)
api.C_Map.GetPlayerMapPosition=function()map=6;return {x=.1,y=.2}end
map=5;assert(not host:Start(input,'v1'));map=5
local secret={}
api.C_Map.GetPlayerMapPosition=function()return secret end
local guarded=Host.New({api=api,apr={CanAccessValue=function(_,v)return v~=secret end},engines={}})
assert(not guarded:Start(input,'v1'))
api.C_Map.GetPlayerMapPosition=function()return {x=secret,y=.2}end
assert(not guarded:Start(input,'v1'))

-- Manual runs do not need player APIs; fallback clock is identified, CPU remains N/A.
local coarse=Host.New({api={GetTime=function()return 1 end},apr={},engines={v1=engine('v1')}})
local manual={from={mapID=2,x=0,y=100},to={mapID=8,x=100,y=0}}
assert(coarse:Start(manual,'v2'));coarse:Step()
assert(coarse:GetContext().wallClock=='GetTime' and coarse:GetContext().profileClock=='unavailable')
assert(coarse:GetState().engines.v2.cpuMs==nil)
local unavailable=Host.New({api={},apr={},engines={}})
ok,why=unavailable:Start(manual,'v1');assert(not ok and why=='benchmark_clock_unavailable')
assert(unavailable:GetReport():find('unavailable'))
assert(APR.NavigationBenchmark and type(APR.NavigationBenchmark.Start)=='function')

-- The shared character observation is captured once, before the sequential attempts.
local characterReads,level,seen=0,7,{}
local characterHost=Host.New({api=api,apr={NavigationAdapter={environment={getCharacter=function()
 characterReads=characterReads+1;return {level=level,class='MAGE',raceID=1}
end}}},engines={v1={Create=function(_,context)
 local character=context.environment.getCharacter();seen[#seen+1]=character.level
 character.level=99
 return {Step=function()return {status='complete'}end}
end},v2={Create=function(_,context)
 seen[#seen+1]=context.environment.getCharacter().level
 return {Step=function()return {status='unknown'}end}
end}}})
assert(characterHost:Start(manual,'both'));level=40
for _=1,4 do characterHost:Step()end
assert(characterReads==1 and seen[1]==7 and seen[2]==7)
assert(characterHost:GetContext().characterLevel==7)
print('Benchmark host: native capture once, secrets/nils/transition, isolated measured engines, cancelled replacement and honest report passed')
