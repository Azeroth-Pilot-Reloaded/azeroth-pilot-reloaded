-- Normal APR adapter: invented world geometry, manual transports and one solver.
local F=dofile('tests/lua/navigation_v2/fixture.lua')
local library,ns=F.Load()
APR={}
local counts={prepare=0,steps=0,new=0,plan=0,cancel=0}
local now=0
local a={world=1,x=0,y=0,z=10,uiMapID=101}
local corner={world=1,x=0,y=3,z=10,uiMapID=101}
local b={world=1,x=4,y=3,z=10,uiMapID=101}
local c={world=2,x=9,y=8,z=20,uiMapID=202,floor='upper'}
local prepared={status='complete',graph={complete=true,nodes={'a','b','c'},edges={
 {id='ground',from='a',to='b',seconds=2}, {id='portal',from='b',to='c',seconds=5}}},
 request={from='a',to='c'},positions={a=a,b=b,c=c},geometry={ground={a,corner,b},portal={b,c}},
 guidance={portal={kind='portal',connectionID='invented-door'}},options={}}
local source={}
local data={GetProfile=function()return {name='forever'}end}
function ns.NavigationV2PrepareWorld(request,context)
 counts.prepare=counts.prepare+1
 assert(request.from.instanceID==1 and request.from.z==10)
 if request.to.instanceID==2 then assert(request.to.floor=='upper')end
 assert(context.clock()==now and context.budgets.cpuMs<=100)
 return {originReliable=true,Step=function(_,ops,ms)
  counts.steps=counts.steps+1;assert(ms<=1)
  if source.onStep then source.onStep()end
  return prepared
 end,Cancel=function()counts.cancel=counts.cancel+1 end,
 IsCurrent=function()return not source.changed,source.changed and 'data_source_changed' or nil end}
end
local rawNew=library.New
library.New=function(...)
 counts.new=counts.new+1
 if source.onNew then source.onNew()end
 local planner,reason=rawNew(...)
 if planner then
  local rawPlan=planner.Plan
  function planner:Plan(...)counts.plan=counts.plan+1;return rawPlan(self,...)end
 end
 return planner,reason
end
assert(loadfile('APR-Core/features/navigation/NavigationV2Planner.lua'))('test',ns)
local planner=assert(APR.NavigationV2Planner)
local request={start={instanceID=1,x=0,y=0,z=10,uiMapID=101},
 goal={instanceID=2,x=9,y=8,z=20,uiMapID=202,floor='upper'},data=data,
 adapter={environment={mapToWorld=function()error('Already world coordinates')end}},
 clock=function()return now end,contextKey='invented',generation=4,api={}}
local function finish(job)
 for _=1,1000 do local status,result=job:Step(64,3);if status~='planning' then return status,result end end
 error('Normal adapter did not terminate')
end
local job=planner:Create(request)
assert(counts.prepare==0 and counts.new==0,'Create stays lazy')
local status,result=finish(job)
assert(status=='ready' and result.totalSeconds==7 and result.totalCopper==0,tostring(status)..':'..tostring(job.reason))
assert(counts.prepare==1 and counts.new==1 and counts.plan==1)
assert(#result.queue==3 and #result.segments==3)
assert(result.queue[1].to.x==0 and result.queue[1].to.y==3)
assert(result.queue[2].to.x==4 and result.queue[2].to.y==3)
local portal=result.queue[3]
assert(portal.kind=='portal' and portal.from.instanceID==1 and portal.to.instanceID==2)
assert(portal.Coord.x==3 and portal.Coord.y==4 and portal.Coord.mapID==101)
local total=0
for i,row in ipairs(result.queue)do
 assert(row.index==i and row.generated and row.mandatory and row.v2 and row.action==nil)
 total=total+row.seconds
end
assert(math.abs(total-7)<1e-9 and job:IsCurrent())
assert(job:GetResult()==result and job.slices>0 and job.maxSliceMilliseconds<=1)
source.changed=true;local current,reason=job:IsCurrent()
assert(current==false and reason=='data_source_changed' and counts.plan==1 and counts.new==1)
source.changed=false
job:Cancel();assert(job:IsCurrent()==false)

-- A selected personal hint is descriptive; never emit legacy .action or use APIs.
prepared.guidance.portal={kind='spell',connectionID='invented-spell',action={type='spell',id=901},sourceFree=true}
job=planner:Create(request);status,result=finish(job)
assert(status=='ready' and result.queue[3].kind=='spell' and result.queue[3].sourceFree)
assert(result.queue[3].action==nil and result.queue[3].v2Action.id==901 and result.queue[3].Coord==nil)
assert(result.queue[3].label:find('901',1,true))
source.onStep=function()now=80 end
source.onNew=function()now=now+21 end
job=planner:Create(request);status,result=finish(job)
assert(status=='no_path' and job.reason=='v2_budget_exceeded' and result==nil)
source.onStep,source.onNew=nil,nil
job=planner:Create(request);job:Step();local before=counts.steps
job:Cancel();assert(job:Step()=='cancelled' and counts.steps==before)
local isCurrent=true
request.isCurrent=function()return isCurrent end
job=planner:Create(request);job:Step();isCurrent=false
assert(job:Step()=='cancelled' and job.reason=='stale_context')
request.isCurrent=nil
local originalGeometry=prepared.geometry.ground
prepared.geometry.ground={a,corner,a}
job=planner:Create(request);status,result=finish(job)
assert(status=='no_path' and job.reason=='v2_geometry_invalid' and result==nil)
prepared.geometry.ground=originalGeometry
prepared.graph.edges[2].resources={money=17};prepared.options.resources={money=20}
job=planner:Create(request);status,result=finish(job)
assert(status=='ready' and result.totalCopper==17 and result.queue[3].copper==17)
prepared.graph.edges[2].resources=nil;prepared.options.resources=nil
local originalRequest=prepared.request
prepared.request={from='a',to='a'}
local stationaryRequest={start=request.start,goal=request.start,data=data,startMode='manual',clock=request.clock}
job=planner:Create(stationaryRequest);status,result=finish(job)
assert(status=='ready' and #result.queue==1 and result.queue[1].v2 and result.queue[1].Coord.x==0)
assert(result.totalSeconds==0 and result.queue[1].to.z==10)
prepared.request=originalRequest
now=0;job=planner:Create(request);job:Step();now=5000
assert(job:Step()=='no_path' and job.reason=='v2_budget_exceeded')
now=0;source.onStep=function()now=now+80 end;source.onNew=function()now=now+19 end
local rawText=ns.NavigationV2WaypointTarget.Text
ns.NavigationV2WaypointTarget.Text=function(...)now=now+1;return rawText(...)end
job=planner:Create(request);status,result=finish(job)
assert(status=='no_path' and result==nil and job.reason=='v2_budget_exceeded' and job.workerPhase=='queue')
source.onStep,source.onNew=nil,nil;ns.NavigationV2WaypointTarget.Text=rawText
local oldHint=prepared.guidance.portal;prepared.guidance.portal=nil
job=planner:Create(request);status,result=finish(job)
assert(status=='no_path' and result==nil and job.reason=='v2_guidance_missing')
prepared.guidance.portal=oldHint

-- Real producer -> shared preparation -> one public New/Plan -> APR queue.
assert(loadfile('APR-Core/features/navigation/NavigationBenchmarkPreparation.lua'))('test',ns)
APR.NavigationTerrain={RequestData=function()return 'ready' end}
for _,profile in ipairs({'forever','retail'})do
 local facts={config={},connections={{id='declared-gate',kind='portal',seconds=5,
  from={space='world',instanceID=1,x=0,y=0,z=10,uiMapID=101},
  to={space='world',instanceID=2,x=9,y=8,z=20,uiMapID=202},instruction='Take the gate'}},
  bindings={},roads={networks={},collision={}},revision=7}
 local realData={GetProfile=function()return {name=profile}end,GetConfig=function()return facts.config end,
  GetConnections=function()return facts.connections end,GetBindings=function()return facts.bindings end,
  GetRoadData=function()return facts.roads end,GetRoadRevision=function()return facts.revision end}
 local realRequest={start=request.start,goal={instanceID=2,x=9,y=8,z=20,uiMapID=202},
  data=realData,startMode='manual',adapter=request.adapter,api={},clock=function()return 0 end}
 job=planner:Create(realRequest);status,result=finish(job)
 assert(status=='ready' and result.totalSeconds==5,profile..':'..tostring(job.reason))
 local transports=0
 for _,row in ipairs(result.queue)do
  assert(row.v2 and row.action==nil)
  if row.kind=='portal' then
   transports=transports+1
   assert(row.connectionID=='declared-gate' and row.instruction=='Take the gate')
   assert(row.from.instanceID==1 and row.to.instanceID==2 and row.seconds==5)
  end
 end
 assert(transports==1 and job:IsCurrent())
 local beforeNew,beforePlan=counts.new,counts.plan
 facts.revision=8
 local valid,why=job:IsCurrent()
 assert(valid==false and why=='data_source_changed' and counts.new==beforeNew and counts.plan==beforePlan)
end
local rawTerrain={format=1,profile='forever',worldID=1,scope={id='invented-room'},
 nodes={{id='a',x=0,y=0,z=10},{id='b',x=4,y=3,z=10}},
 edges={{from='a',to='b',mode='ground',seconds=2,polyline={a,corner,b}}},
 anchors={{node='a',minX=0,maxX=0,minY=0,maxY=0,mode='ground'},
  {node='b',minX=4,maxX=4,minY=3,maxY=3,mode='ground'}}}
local registration={data=rawTerrain,revision=7}
local registry={terrainDatasets={forever={[1]={packs={invented=registration}}}}}
local groundFacts={config={},connections={},bindings={},roads={networks={},collision={}}}
local groundData={GetProfile=function()return {name='forever'}end,
 GetConfig=function()return groundFacts.config end,GetConnections=function()return groundFacts.connections end,
 GetBindings=function()return groundFacts.bindings end,GetRoadData=function()return groundFacts.roads end}
local groundRequest={start=request.start,goal={instanceID=1,x=4,y=3,z=10,uiMapID=101},
 data=groundData,startMode='manual',clock=function()return 0 end,api={LibStub=function()return registry end}}
job=planner:Create(groundRequest);status,result=finish(job)
assert(status=='ready' and result.totalSeconds==2,tostring(job.reason))
local foundCorner,sum=false,0
for _,row in ipairs(result.queue)do
 sum=sum+row.seconds
 if row.to.x==0 and row.to.y==3 then foundCorner=true end
end
assert(foundCorner and sum==2 and job:IsCurrent())
registration.revision=8
local valid,why=job:IsCurrent();assert(not valid and why=='data_source_changed')
registration.revision=7
assert(job:IsCurrent())
registration.data={}
assert(job:IsCurrent()==false)
registration.data=rawTerrain
local oldGetter=groundData.GetConfig
groundData.GetConfig=function()return groundFacts.config end
assert(job:IsCurrent()==false,'Getter replacement invalidates the published proof')
groundData.GetConfig=oldGetter

for _,name in ipairs({'NavigationV2Position','NavigationV2Personal','NavigationV2Conditions'})do
 assert(loadfile('APR-Core/features/navigation/'..name..'.lua'))('test',ns)
end
for _,profile in ipairs({'forever','retail'})do
 local nativeZ,reads=10,0
 local function forbidden()error('Planning cannot execute client actions')end
 local native={IsPlayerInWorld=function()return true end,UnitPosition=function()return 0,0,nativeZ,1 end,
  GetTime=function()return 9000 end,GetMoney=function()return 0 end,
  InCombatLockdown=function()return false end,UnitCastingInfo=function()end,UnitChannelInfo=function()end,
  IsIndoors=function()return false end,C_Map={GetBestMapForUnit=function()return 101 end},
  C_SpellBook={IsSpellKnown=function()return true end},C_Spell={GetSpellInfo=function()
   reads=reads+1;return {name='Invented spell',castTime=1500}
  end,IsSpellUsable=function()return true end,GetSpellCooldown=function()
   return {startTime=0,duration=0,isEnabled=true,modRate=1}end},
  CastSpellByID=forbidden,UseItemByName=forbidden,CreateFrame=forbidden,
  C_SuperTrack={SetSuperTrackedUserWaypoint=forbidden}}
 local facts={config={actionLoadingSeconds=5},connections={{id='personal-test',kind='spell',from={dynamic='player'},
  to={space='world',instanceID=2,x=9,y=8,z=20,uiMapID=202},actions={{type='spell',id=901}}}},
  bindings={},roads={networks={},collision={}}}
 local realData={GetProfile=function()return {name=profile}end,GetConfig=function()return facts.config end,
  GetConnections=function()return facts.connections end,GetBindings=function()return facts.bindings end,
  GetRoadData=function()return facts.roads end}
 local realRequest={start=request.start,goal={instanceID=2,x=9,y=8,z=20,uiMapID=202},
  data=realData,startMode='player',api=native,clock=function()return 0 end}
 job=planner:Create(realRequest);status,result=finish(job)
 assert(status=='ready' and result.totalSeconds==6.5,profile..':'..tostring(job.reason))
 local spell
 for _,row in ipairs(result.queue)do if row.kind=='spell' then spell=row end end
 assert(spell and spell.sourceFree and spell.v2Action.id==901 and spell.action==nil and spell.Coord==nil)
 assert(reads==1 and job.preparation.stats.observationResumes==1)
 nativeZ=30
 job=planner:Create(realRequest);status,result=finish(job)
 assert(status=='no_path' and result==nil,profile..' must correlate explicit native height')
end
print('Normal V2 planner: world geometry, manual transport, lifecycle and cumulative budget passed')
