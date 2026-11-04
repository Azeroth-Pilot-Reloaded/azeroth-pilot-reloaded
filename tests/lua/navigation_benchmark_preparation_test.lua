local ns={}
assert(loadfile('APR-Core/features/navigation/NavigationBenchmarkPreparation.lua'))('test',ns)
local prepare=ns.NavigationV2PrepareBenchmark
local reads,raw,seen={},{config={},connections={},bindings={}}
local currentProfile='retail'
local data={}
function data:GetProfile()return {name=currentProfile}end
for _,entry in ipairs({{'GetConfig','config'},{'GetConnections','connections'},{'GetBindings','bindings'}}) do
 local method,key=entry[1],entry[2]
 data[method]=function(self)assert(self==data);reads[key]=(reads[key] or 0)+1;return raw[key]end
end
for _,method in ipairs({'BuildEdges','CanWalk','NormalizeLocation','Plan','Enable'}) do
 data[method]=function()error('Only data getters are authorized')end
end
local character={faction='Alliance',level=35,class='MAGE'}
local mapToWorld=function(map,x,y)return map,x*100,y*100 end
local clock=function()return 125 end
local ctx={profile='retail',data=data,clock=clock,walkSpeed=7,
 budgets={sliceMs=1,cpuMs=80,elapsedMs=4500},movement={diagnostic='captured'},
 environment={getCharacter=function()return character end,mapToWorld=mapToWorld}}
local request={coordinateUnit='map-percent',startMode='manual',
 from={mapID=71,x=12.5,y=0,identity={z=3,worldID=1,floorID='floor-a'}},
 to={mapID=72,x=100,y=87.5,identity={worldID=2}}}
local calls,cancels=0,0
ns.NavigationV2RetailData={Prepare=function(source,input,options)
 seen={source=source,request=input,options=options}
 return {Step=function()
  calls=calls+1
  if calls==1 then return {status='running'}end
  return {status='complete',graph={complete=false,nodes={'a','b'},edges={}},
   request={from='a',to='b'},options={movement=options.movement},provenance={scope='synthetic'}}
 end,Cancel=function()cancels=cancels+1 end}
end}
local job=assert(prepare(request,ctx))
assert(calls==0 and reads.config==1 and reads.connections==1 and reads.bindings==1)
assert(seen.source.config==raw.config and seen.source.connections==raw.connections and seen.source.bindings==raw.bindings)
assert(seen.request.from.space=='map' and seen.request.from.uiMapID==71)
assert(seen.request.from.x==.125 and seen.request.to.y==.875 and seen.request.to.x==1)
assert(seen.request.from.identity.z==3 and seen.request.from.identity.floorID=='floor-a')
assert(seen.options.actor.faction=='Alliance' and seen.options.movement==ctx.movement)
assert(seen.options.mapToWorld==mapToWorld and seen.options.clock()==125 and seen.options.profileClock()==125)
assert(seen.options.budgets.cpuMs==80 and seen.options.budgets.elapsedMs==4500)
request.from.x=99;character.level=99
assert(seen.request.from.x==.125 and seen.options.actor.level==35)
assert(job:Step(4,1).status=='running')
local result=job:Step(4,1)
assert(result.status=='complete' and result.request.from=='a')
assert(job:Step(4,1)==result and calls==2)
job:Cancel();assert(cancels==0)

-- Capture and continuation cannot silently mix profile data.
currentProfile='forever'
local unavailable,reason=prepare(request,ctx)
assert(unavailable==nil and reason=='benchmark_v2_data_profile_mismatch')
currentProfile='retail';job=assert(prepare(request,ctx));currentProfile='forever'
result=job:Step(4,1)
assert(result.status=='unknown' and result.reason=='benchmark_v2_data_profile_mismatch' and cancels==1)
job:Step();job:Cancel();assert(cancels==1)
currentProfile='retail'
local configGetter=data.GetConfig
data.GetConfig=function(self)currentProfile='forever';return configGetter(self)end
unavailable,reason=prepare(request,ctx)
assert(unavailable==nil and reason=='benchmark_v2_data_profile_mismatch')
data.GetConfig=configGetter;currentProfile='retail'

-- Missing inputs/capabilities are explicit; no invented source or observation.
local producer=ns.NavigationV2RetailData
ns.NavigationV2RetailData=nil
unavailable,reason=prepare(request,ctx)
assert(unavailable==nil and reason=='benchmark_v2_retail_preparation_unavailable')
ns.NavigationV2RetailData=producer
local inputProfile=ctx.profile;ctx.profile='forever'
unavailable,reason=prepare(request,ctx)
assert(unavailable==nil and reason=='benchmark_v2_forever_preparation_unavailable')
ctx.profile=inputProfile
local foreverCalls=0
ns.NavigationV2ForeverData={Prepare=function(captured,options)
 foreverCalls=foreverCalls+1
 assert(captured.from.world==71 and captured.from.x==99 and captured.from.y==0)
 assert(captured.from.z==3 and captured.from.floor=='floor-a' and captured.to.world==72)
 assert(options.data==data and options.clock()==125 and options.budgets.cpuMs==80)
 assert(options.roads==raw.roads and options.terrain==raw.terrain and options.terrainStatus=='ready')
 return {Step=function()return {status='unknown',reason='source_loading'}end,Cancel=function()end}
end}
ctx.profile='forever';currentProfile='forever'
raw.roads={networks={},collision={}};raw.terrain={}
data.GetRoadData=function()return raw.roads end
ctx.api={LibStub=function()return {terrainDatasets={forever=raw.terrain}}end}
local loadRequests=0
ctx.terrainHost={RequestData=function(self,profile,world,point)
 assert(profile=='forever' and world==point.world);loadRequests=loadRequests+1;return 'ready'
end}
request.from.identity.worldID=nil;request.to.identity.worldID=nil
job=assert(prepare(request,ctx))
assert(foreverCalls==0 and loadRequests==0)
for _=1,3 do assert(job:Step().status=='running')end
assert(foreverCalls==1 and job:Step().reason=='source_loading' and loadRequests==2)
currentProfile='retail'
unavailable,reason=prepare(request,ctx)
assert(unavailable==nil and reason=='benchmark_v2_data_profile_mismatch' and foreverCalls==1)
ctx.profile=inputProfile;ns.NavigationV2ForeverData=nil
local getter=data.GetConnections
data.GetConnections=function()error('Getter unavailable')end
unavailable,reason=prepare(request,ctx)
assert(unavailable==nil and reason=='benchmark_v2_data_unavailable')
data.GetConnections=getter
ctx.environment=nil;job=assert(prepare(request,ctx))
assert(seen.options.actor==nil and seen.options.mapToWorld==nil)
job:Cancel();job:Cancel();assert(job:Step().status=='cancelled' and cancels==2)
request.to.x=101
unavailable,reason=prepare(request,ctx)
assert(unavailable==nil and reason=='benchmark_v2_request_invalid')

-- Real producer + real search through the same public host, invented data only.
local _,actual=dofile('tests/lua/navigation_v2/fixture.lua').Load()
if not actual.NavigationV2RetailData then
 assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Data/Retail.lua'))('test',actual)
end
APR={}
for _,name in ipairs({'NavigationBenchmarkCase','NavigationBenchmarkRun','NavigationBenchmarkV2',
 'NavigationBenchmarkPreparation','NavigationBenchmarkHost'})do
 assert(loadfile('APR-Core/features/navigation/'..name..'.lua'))('test',actual)
end
local connection={id='invented-crossing',kind='passage',seconds=11,bidirectional=false,
 from={space='map',uiMapID=801,x=.25,y=.5},to={space='map',uiMapID=802,x=.75,y=.25},
 requirements={minLevel=20}}
local level,characterReads=35,0
local public={GetProfile=function()return {name='retail'}end,
 GetConfig=function()return {IsolatedAreas={[801]='left',[802]='right'}}end,
 GetConnections=function()return {connection}end,GetBindings=function()return {}end}
local apr={NavigationData=public,NavigationAdapter={environment={getCharacter=function()
 characterReads=characterReads+1;return {level=level,faction='Alliance'}
end}},NavigationV2={Enable=function()error('No normal navigation')end}}
local api={GetBuildInfo=function()return 'diagnostic','synthetic','',120105 end,
 GetTimePreciseSec=function()return 0 end,debugprofilestop=function()return 0 end}
local owner=actual.NavigationBenchmarkHost.New({api=api,apr=apr,engines={v2=actual.NavigationBenchmarkV2}})
local endpoints={from={mapID=801,x=25,y=50},to={mapID=802,x=75,y=25}}
local function finishOwner()
 for _=1,500 do local state=owner:Step();if state.status~='running' then return state.engines.v2 end end
 error('Public benchmark did not terminate')
end
assert(owner:Start(endpoints,'v2'));level=1
result=finishOwner()
assert(result.status=='complete' and result.estimatedSeconds==11 and characterReads==1)
assert(result.metrics.newCalls==1 and result.metrics.searchStepCalls>0 and result.metrics.preparationStepCalls>0)
assert(owner:GetCapture().from.x==25 and endpoints.from.x==25)
assert(owner:GetContext().engines.v2.scope=='declared_retail_request')
assert(owner:Start(endpoints,'v2'))
result=finishOwner()
assert(result.status=='unknown' and result.estimatedSeconds==nil and characterReads==2)
level=35
assert(owner:Start({from=endpoints.to,to=endpoints.from},'v2'))
result=finishOwner()
assert(result.status=='unknown' and result.estimatedSeconds==nil)

-- Manual origins keep capabilities but do not inherit the player's local ban or mode.
if not actual.NavigationV2Retail then
 assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Movement/Retail.lua'))('test',actual)
end
local observedMovement={mountOwned=true,mountUsable=true,skyridingOwned=true,skyridingUsable=true,
 initialMode='skyriding',canMountHere=false,canSkyridingHere=false,
 costs={landingSeconds=50,dismountSeconds=20}}
actual.NavigationV2Movement={Capture=function()
 return assert(actual.NavigationV2Retail.New(observedMovement,observedMovement.costs)),observedMovement
end}
assert(owner:Start(endpoints,'v2'));result=finishOwner()
assert(result.status=='complete' and result.estimatedSeconds==11)
assert(owner:GetContext().movementOrigin=='manual_walk_model_local_permissions_unknown')
assert(observedMovement.initialMode=='skyriding' and observedMovement.canSkyridingHere==false)
api.IsPlayerInWorld=function()return true end
api.C_Map={GetBestMapForUnit=function()return 801 end,
 GetPlayerMapPosition=function()return {x=.25,y=.5}end}
assert(owner:Start({startMode='player',to=endpoints.to},'v2'));result=finishOwner()
assert(result.status=='complete' and result.estimatedSeconds==81)
assert(owner:GetContext().movementOrigin=='captured_player_mode_and_local_permissions')
actual.NavigationV2Movement=nil

-- Forever reads ready raw tables after the existing loader's scoped decision.
if not actual.NavigationV2ForeverData then
 assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Data/Forever.lua'))('test',actual)
end
local survey={format=1,profile='forever',worldID=0,build='synthetic',scope={id='room'},
 nodes={{id='a',x=0,y=0,z=3},{id='b',x=4,y=0,z=3}},
 edges={{from='a',to='b',mode='ground',length=4,polyline={{x=0,y=0,z=3},{x=4,y=0,z=3}}}},
 anchors={{node='a',minX=-1,maxX=1,minY=-1,maxY=1,minZ=2,maxZ=4,mode='ground'},
 {node='b',minX=3,maxX=5,minY=-1,maxY=1,minZ=2,maxZ=4,mode='ground'}}}
local ready={terrainDatasets={forever={[0]={packs={sample={data=survey,revision=7}}}}}}
local loaderStatus,loaderReason,loaderCalls='ready',nil,0
local terrainHost={RequestData=function(self,profile,world,point)
 assert(profile=='forever' and world==0 and point.world==0 and point.z==nil)
 loaderCalls=loaderCalls+1;return loaderStatus,loaderReason
end}
local foreverData={GetProfile=function()return {name='forever'}end,
 GetRoadData=function()return {networks={},collision={}}end,
 GetConfig=function()error('Retail getter must not be used for Forever')end}
local foreverApr={NavigationData=foreverData,NavigationTerrain=terrainHost,
 NavigationAdapter={environment={mapToWorld=function(map,x,y)
  assert(map==803);return 0,x*4,y*4
 end}}}
local foreverApi={LibStub=function()return ready end,
 GetBuildInfo=function()return '1.60.1','synthetic','',16001 end,
 GetTimePreciseSec=function()return 0 end,debugprofilestop=function()return 0 end}
owner=actual.NavigationBenchmarkHost.New({api=foreverApi,apr=foreverApr,engines={v2=actual.NavigationBenchmarkV2}})
local foreverEndpoints={from={mapID=803,x=25,y=0},to={mapID=803,x=75,y=0}}
assert(owner:Start(foreverEndpoints,'v2'));result=finishOwner()
assert(result.status=='complete' and math.abs(result.estimatedSeconds-6/7)<1e-9)
assert(loaderCalls==2 and result.metrics.calculationsStarted==1 and result.metrics.preparationStepCalls>0)
assert(owner:GetContext().engines.v2.scope=='declared_model')
assert(owner:GetContext().engines.v2.dataLoadCalls==2)
loaderStatus,loaderReason='missing','terrain_build_unavailable'
assert(owner:Start(foreverEndpoints,'v2'));result=finishOwner()
assert(result.status=='unknown' and result.reason=='terrain_build_unavailable' and result.estimatedSeconds==nil)
assert(owner:GetContext().engines.v2.dataLoadCalls==1)

-- Discover only needed observations, then resume the same bounded preparation.
for _,name in ipairs({'NavigationV2Position','NavigationV2Personal','NavigationV2Conditions'})do
 assert(loadfile('APR-Core/features/navigation/'..name..'.lua'))('test',actual)
end
local realRetail=actual.NavigationV2RetailData
local function observationCase(settings)
 settings=settings or {}
 local profile=settings.forever and 'forever' or 'retail'
 local declarations={config={},connections={},bindings=settings.bindings or {[1]={space='world',world=99,x=9,y=9}}}
 local stats={factory=0,steps=0,resumes=0,cancels=0,new=0,spellInfo=0,itemCount={},quests=0,account=0,clock=0}
 stats.replaceBindings=function()declarations.bindings={}end
 local api={IsPlayerInWorld=function()
   if stats.onReady then stats.onReady()end
   return settings.ready~=false
  end,
  UnitPosition=function()return settings.nativeX or 250,500,10,settings.nativeWorld or 42 end,
  GetTime=function()return 9000 end,GetMoney=function()if not settings.missingResources then return 123 end end,
  InCombatLockdown=function()return false end,UnitCastingInfo=function()end,UnitChannelInfo=function()end,
  IsIndoors=function()return true end,
  C_Map={GetBestMapForUnit=function()return 811 end},
  C_SpellBook={IsSpellKnown=function(id)assert(id==901);return true end},
  C_Spell={GetSpellInfo=function(id)
   assert(id==901);stats.spellInfo=stats.spellInfo+1
   if stats.onSpell then stats.onSpell()end
   return {name='Invented spell',castTime=1500}
  end,IsSpellUsable=function()return true end,GetSpellCooldown=function()
   return {startTime=settings.delayed and 9000 or 0,duration=settings.delayed and 15 or 0,
    isEnabled=true,modRate=1}
  end},
  C_Item={IsItemDataCachedByID=function()return true end,IsUsableItem=function()return true end,
   GetItemCooldown=function()return 0,0,true end,GetItemCount=function(id)
    stats.itemCount[id]=(stats.itemCount[id] or 0)+1
    if not settings.missingResources then return id==902 and 1 or 4 end
   end},
  C_QuestLog={IsQuestFlaggedCompleted=function(id)assert(id==71);stats.quests=stats.quests+1;return true end},
  CreateFrame=function()error('No secure UI')end,RegisterStateDriver=function()error('No secure state')end}
 if settings.secretBind then api.issecretvalue=function(value)return value==settings.bindName end end
 if settings.bindName then api.GetBindLocation=function()
  stats.bindReads=(stats.bindReads or 0)+1
  return settings.changedBind and stats.bindReads>1 and 'Changed inn' or settings.bindName
 end end
 local requests={origin={node='a',position={mapID=811,world=42,wx=250,wy=500}},
  actions={['spell:901']={id='spell:901',kind='spell',spellID=901,reagentID=903},
   ['item:902']={id='item:902',kind='item',itemID=902,reagentID=903}},
  quests={[71]=true},access={['account-quest:72']={field='questAccount',value=72}},
  dynamic={bind={kind='bind'}}}
 if settings.forever then requests.origin.position={world=42,x=250,y=500,
  z=settings.z,space=settings.space,floor=settings.floor} end
 local fakeProducer={Prepare=function(source,input,options)
  if not settings.forever then assert(options.deferObservations==true)
  else stats.deferred=input.deferObservations;stats.bindings=input.bindings end
  stats.factory=stats.factory+1
  local resumed=false
  return {Step=function()
   stats.steps=stats.steps+1
   if not resumed then
    if settings.prepCost then stats.clock=settings.prepCost end
    return {status='running',phase='observation_required'}
   end
   return {status='complete',graph={complete=true,nodes={'a','b'},edges={
    {id='observed',from='a',to='b',seconds=3,requirements={quests={{questID=71,completed=true}},
     access={{key='account-quest:72',allowed=false}}}}}},request={from='a',to='b'},
    options={conditionObservation=stats.snapshot.conditionObservation},provenance={scope='synthetic_observed'}}
  end,GetObservationRequests=function()return requests end,ResumeObservations=function(self,snapshot)
   assert(not resumed);stats.resumes=stats.resumes+1
   if settings.refuseResume then return nil,'synthetic_observation_stale' end
   stats.snapshot=snapshot;resumed=true;return true
  end,Cancel=function()stats.cancels=stats.cancels+1 end}
 end}
 if settings.forever then actual.NavigationV2ForeverData=fakeProducer else actual.NavigationV2RetailData=fakeProducer end
 local context={profile=profile,clock=function()return stats.clock end,api=api,walkSpeed=7,
  data={GetProfile=function()return {name=profile}end,GetConfig=function()return declarations.config end,
   GetConnections=function()return declarations.connections end,GetBindings=function()return declarations.bindings end},
  environment={getCharacter=function()return {level=70,faction='Alliance'}end,
   isQuestCompletedOnAccount=function(id)assert(id==72);stats.account=stats.account+1;return false end,
   getActionCastSeconds=function(kind,id)
    assert(kind=='item' and id==902);if not settings.missingItemCast then return 2 end
   end,
   getDynamicPosition=function()error('No V1 bind lookup or candidate guessing')end},
  prepare=actual.NavigationV2PrepareBenchmark,
  library={New=function(...)stats.new=stats.new+1;return actual.LibAPRNavigationV2.New(...)end}}
 if settings.forever then context.environment.mapToWorld=function(_,x,y)return 42,x*1000,y*1000 end end
 if settings.labels then context.environment.getAreaName=function(id)
  stats.labelReads=(stats.labelReads or 0)+1
  if settings.onLabel then settings.onLabel(stats)end
  return settings.labels[id]
 end end
 local input={coordinateUnit='map-percent',startMode=settings.player and 'player' or 'manual',
  from={mapID=811,x=25,y=50},to={mapID=811,x=75,y=50}}
 local driver=assert(actual.NavigationBenchmarkV2.Create(input,context))
 return driver,stats,context
end
local function finishObserved(driver)
 for _=1,500 do local r=driver:Step(8,1);if r.status~='running' then return r end end
 error('Observation continuation did not finish')
end
local observedDriver,observedStats=observationCase()
result=finishObserved(observedDriver)
assert(result.status=='complete' and result.estimatedSeconds==3)
assert(observedStats.factory==1 and observedStats.resumes==1 and observedStats.steps==2 and observedStats.new==1)
assert(observedStats.spellInfo==1 and observedStats.itemCount[903]==1 and observedStats.itemCount[902]==1)
assert(observedStats.quests==1 and observedStats.account==1)
local snapshot=observedStats.snapshot
assert(snapshot.personalObservation.actions['spell:901'].castSeconds==1.5)
assert(snapshot.personalObservation.actions['item:902'].castSeconds==2)
assert(snapshot.personalObservation.observedAt==0 and snapshot.personalObservation.actions['spell:901'].readyAt==0)
assert(snapshot.personalObservation.moneyCopper==123 and snapshot.personalObservation.items[903]==4)
assert(snapshot.personalObservation.origin.reliable==false and snapshot.personalObservation.origin.indoors==nil)
assert(snapshot.dynamicPositions.bind==nil and snapshot.actionPolicies==nil)
assert(snapshot.conditionObservation.quests[71]==true and snapshot.conditionObservation.access['account-quest:72']==false)
assert(observedDriver:GetContext().observationResumes==1 and observedDriver:GetContext().capturedActions==2)
assert(observedDriver:GetContext().producerStepCalls==2 and observedDriver:GetContext().captureCalls>0)

-- The shared protocol correlates Forever world x/y without promoting model identity.
local savedForeverProducer=actual.NavigationV2ForeverData
observedDriver,observedStats=observationCase({forever=true,player=true})
assert(finishObserved(observedDriver).status=='complete')
assert(observedStats.snapshot.personalObservation.origin.reliable==true)
assert(observedStats.snapshot.personalObservation.origin.node=='a' and observedStats.resumes==1)
assert(observedStats.deferred==true and type(observedStats.bindings)=='table')
observedDriver,observedStats=observationCase({forever=true})
assert(finishObserved(observedDriver).status=='complete')
assert(observedStats.snapshot.personalObservation.origin.reliable==false)
assert(observedStats.snapshot.personalObservation.origin.indoors==nil)
observedDriver,observedStats=observationCase({forever=true,player=true,floor='unobserved-model-floor'})
finishObserved(observedDriver)
assert(observedStats.snapshot.personalObservation.origin.reliable==false)
for _,settings in ipairs({{z=11},{space='unobserved-model-space'},{nativeWorld=41},{nativeX=250.02}}) do
 settings.forever,settings.player=true,true
 observedDriver,observedStats=observationCase(settings);finishObserved(observedDriver)
 assert(observedStats.snapshot.personalObservation.origin.reliable==false)
end
observedDriver,observedStats=observationCase({forever=true,player=true,z=10})
finishObserved(observedDriver);assert(observedStats.snapshot.personalObservation.origin.reliable==true)
observedDriver,observedStats=observationCase({forever=true,player=true,delayed=true})
finishObserved(observedDriver)
assert(observedStats.snapshot.personalObservation.actions['spell:901'].readyAt==15)
assert(observedStats.snapshot.personalObservation.observedAt==0 and observedStats.resumes==1)
observedDriver,observedStats=observationCase({forever=true,missingResources=true,missingItemCast=true})
finishObserved(observedDriver)
assert(observedStats.snapshot.personalObservation.items[903]==nil)
assert(observedStats.snapshot.personalObservation.actions['item:902'].castSeconds==nil)
observedDriver,observedStats=observationCase({forever=true,ready=false})
assert(finishObserved(observedDriver).status=='unknown' and observedStats.spellInfo==0)
observedDriver,observedStats=observationCase({forever=true})
observedStats.onSpell=function()observedDriver:Cancel()end
assert(finishObserved(observedDriver).status=='cancelled' and observedStats.resumes==0 and observedStats.cancels==1)
observedDriver,observedStats=observationCase({forever=true,prepCost=80})
observedStats.onSpell=function()observedStats.clock=observedStats.clock+21 end
assert(finishObserved(observedDriver).status=='budget_exceeded' and observedStats.resumes==0 and observedStats.new==0)
actual.NavigationV2ForeverData=savedForeverProducer

-- A native name identifies a declared bind area only after a complete unique scan.
local bindCandidates={[81]={areaID=81,space='world',instanceID=1,x=1,y=2},
 [82]={areaID=82,space='world',instanceID=2,x=8,y=9}}
observedDriver,observedStats=observationCase({forever=true,player=true,bindName='Second inn',
 bindings=bindCandidates,labels={[81]='First inn',[82]='Second inn'}})
finishObserved(observedDriver)
assert(observedStats.snapshot.dynamicPositions.bind and observedStats.snapshot.dynamicPositions.bind.areaID==82)
assert(observedStats.bindings==bindCandidates and observedStats.factory==1 and observedStats.resumes==1)
observedDriver,observedStats=observationCase({forever=true,player=true,bindName='Second inn',
 bindings=bindCandidates,labels={[81]='First inn',[82]='Second inn'},
 onLabel=function(s)s.replaceBindings()end})
result=finishObserved(observedDriver)
assert(result.status=='unknown' and result.reason=='data_source_changed')
assert(observedStats.resumes==0 and observedStats.cancels==1 and observedStats.new==0)
actual.NavigationV2ForeverData=savedForeverProducer
observedDriver,observedStats=observationCase({bindName='Second inn',bindings=bindCandidates,
 labels={[81]='First inn',[82]='Second inn'}})
finishObserved(observedDriver);snapshot=observedStats.snapshot
assert(snapshot.dynamicPositions.bind and snapshot.dynamicPositions.bind.areaID==82)
assert(snapshot.dynamicPositions.bind.reliable==true and snapshot.dynamicPositions.bind.position==nil)
assert(snapshot.dynamicPositions.bind.inference=='unique_exact_native_name_to_declared_area')
assert(observedStats.bindReads==2 and observedStats.labelReads==2 and observedStats.resumes==1)
for _,settings in ipairs({
 {labels={[81]='Same inn',[82]='Same inn'},bindName='Same inn'},
 {labels={[81]='Second inn'},bindName='Second inn'},
 {labels={[81]='First inn',[82]='Second inn'},bindName='second inn'},
 {labels={[81]='First inn',[82]='Second inn'},bindName='Second inn',changedBind=true},
 {labels={[81]='First inn',[82]='Second inn'},bindName='Second inn',secretBind=true},
 {labels={[81]='First inn',[82]='Second inn'},bindName=''},
}) do
 settings.bindings=bindCandidates
 observedDriver,observedStats=observationCase(settings)
 finishObserved(observedDriver)
 assert(observedStats.snapshot.dynamicPositions.bind==nil)
end
local scanning={bindName='Second inn',bindings=bindCandidates,labels={[81]='First inn',[82]='Second inn'},
 onLabel=function(s)s.clock=s.clock+1 end}
observedDriver,observedStats=observationCase(scanning)
for _=1,50 do
 assert(observedDriver:Step().status=='running')
 if observedStats.labelReads then break end
end
assert(observedStats.labelReads==1 and observedStats.resumes==0)
observedDriver:Cancel();assert(observedDriver:Step().status=='cancelled' and observedStats.labelReads==1)
scanning.onLabel=function(s)s.clock=101 end
observedDriver,observedStats=observationCase(scanning)
assert(finishObserved(observedDriver).status=='budget_exceeded' and observedStats.resumes==0)

observedDriver,observedStats=observationCase({missingResources=true,missingItemCast=true})
finishObserved(observedDriver);snapshot=observedStats.snapshot.personalObservation
assert(snapshot.moneyCopper==nil and snapshot.items[903]==nil and snapshot.items[902]==nil)
assert(snapshot.actions['item:902'].owned==nil and snapshot.actions['item:902'].castSeconds==nil)

observedDriver,observedStats=observationCase({player=true,delayed=true})
finishObserved(observedDriver);snapshot=observedStats.snapshot.personalObservation
assert(snapshot.origin.reliable==true and snapshot.origin.node=='a' and snapshot.origin.indoors==true)
assert(snapshot.actions['spell:901'].readyAt==15 and snapshot.observedAt==0)

observedDriver,observedStats=observationCase({ready=false})
result=finishObserved(observedDriver)
assert(result.status=='unknown' and observedStats.spellInfo==0 and observedStats.quests==0)
assert(observedStats.resumes==1 and observedStats.snapshot.conditionObservation.worldState=='unknown')

observedDriver,observedStats=observationCase()
observedStats.onSpell=function()observedDriver:Cancel()end
assert(finishObserved(observedDriver).status=='cancelled' and observedStats.resumes==0 and observedStats.new==0)
assert(observedStats.cancels==1)

observedDriver,observedStats=observationCase()
observedStats.onSpell=function()observedStats.clock=101 end
assert(finishObserved(observedDriver).status=='budget_exceeded' and observedStats.resumes==0 and observedStats.new==0)
assert(observedStats.cancels==1)

observedDriver,observedStats=observationCase({prepCost=80})
observedStats.onSpell=function()observedStats.clock=observedStats.clock+21 end
assert(finishObserved(observedDriver).status=='budget_exceeded' and observedStats.resumes==0 and observedStats.new==0)

observedDriver,observedStats=observationCase({refuseResume=true})
result=finishObserved(observedDriver)
assert(result.status=='unknown' and result.reason=='synthetic_observation_stale')
assert(observedStats.resumes==1 and observedStats.cancels==1 and observedStats.new==0)
assert(observedDriver:GetContext().observationResumeCalls==1 and observedDriver:GetContext().observationResumes==0)

local changing={}
observedDriver,observedStats=observationCase(changing)
observedStats.onSpell=function()changing.ready=false end
result=finishObserved(observedDriver)
assert(result.status=='unknown' and observedStats.resumes==1)
assert(observedStats.snapshot.conditionObservation.worldState=='unknown')
assert(next(observedStats.snapshot.conditionObservation.quests)==nil)
assert(next(observedStats.snapshot.personalObservation.actions)==nil)

local directContext
observedDriver,observedStats,directContext=observationCase()
local direct=assert(actual.NavigationV2PrepareBenchmark({coordinateUnit='map-percent',
 from={mapID=811,x=25,y=50},to={mapID=811,x=75,y=50}},directContext))
observedStats.onReady=function()direct:Cancel()end
assert(direct:Step().status=='cancelled' and observedStats.resumes==0 and observedStats.cancels==1)
actual.NavigationV2RetailData=realRetail

-- First actual producer teleport: cross-world, one native capture per action ID.
local personalStats={info=0,clock=0}
local personalKnown,personalCooldown,personalTimeKnown=true,true,true
local personalApi={GetBuildInfo=function()return '12.1.5','synthetic','',120105 end,
 GetTimePreciseSec=function()return personalStats.clock/1000 end,
 debugprofilestop=function()return personalStats.clock end,GetTime=function()if personalTimeKnown then return 9000 end end,
 IsPlayerInWorld=function()return true end,UnitPosition=function()return 250,500,10,42 end,
 GetMoney=function()return 123 end,InCombatLockdown=function()return false end,
 UnitCastingInfo=function()end,UnitChannelInfo=function()end,IsIndoors=function()return false end,
 C_Map={GetBestMapForUnit=function()return 811 end,GetPlayerMapPosition=function()return {x=.25,y=.5}end},
 C_SpellBook={IsSpellKnown=function(id)assert(id==901);return personalKnown end},
 C_Spell={GetSpellInfo=function(id)
  assert(id==901);personalStats.info=personalStats.info+1;return {name='Invented teleport',castTime=1500}
 end,IsSpellUsable=function()return true end,GetSpellCooldown=function()
  if personalCooldown then return {startTime=0,duration=0,isEnabled=true,modRate=1}end
 end},CreateFrame=function()error('No secure action')end}
local personalConnections={
 {id='invented-teleport',kind='spell',from={dynamic='player'},
  to={space='map',uiMapID=812,x=.75,y=.25},seconds=10,actions={{type='spell',id=901}}},
 {id='same-action-other-destination',kind='spell',from={dynamic='player'},
  to={space='map',uiMapID=812,x=.8,y=.25},seconds=12,actions={{type='spell',id=901}}}}
local personalData={GetProfile=function()return {name='retail'}end,
 GetConfig=function()return {}end,GetConnections=function()return personalConnections end,GetBindings=function()return {}end}
local personalApr={NavigationData=personalData,NavigationAdapter={environment={
 mapToWorld=function(map,x,y)return map==811 and 42 or 43,x*1000,y*1000 end,
 getCharacter=function()return {level=70,class='MAGE',faction='Alliance'}end}}}
owner=actual.NavigationBenchmarkHost.New({api=personalApi,apr=personalApr,engines={v2=actual.NavigationBenchmarkV2}})
assert(owner:Start({startMode='player',to={mapID=812,x=75,y=25}},'v2'))
result=finishOwner()
assert(result.status=='complete' and result.estimatedSeconds==10,tostring(result.status)..':'..tostring(result.reason))
assert(personalStats.info==1 and result.metrics.newCalls==1 and result.metrics.calculationsStarted==1)
assert(owner:GetContext().engines.v2.observationResumes==1 and owner:GetContext().engines.v2.capturedActions==1)
personalKnown=false;personalStats.info=0
assert(owner:Start({startMode='player',to={mapID=812,x=75,y=25}},'v2'));result=finishOwner()
assert(result.status=='unknown' and result.estimatedSeconds==nil and personalStats.info==1)
personalKnown=true;personalCooldown=false
assert(owner:Start({startMode='player',to={mapID=812,x=75,y=25}},'v2'));result=finishOwner()
assert(result.status=='unknown' and result.estimatedSeconds==nil)
personalCooldown=true;personalTimeKnown=false
assert(owner:Start({startMode='player',to={mapID=812,x=75,y=25}},'v2'));result=finishOwner()
assert(result.status=='unknown' and result.estimatedSeconds==nil)

-- Real producer consumes the inferred declared area, never the first bind row.
personalTimeKnown=true
personalConnections={{id='invented-bind-spell',kind='spell',from={dynamic='player'},to={dynamic='bind'},
 seconds=10,actions={{type='spell',id=901}}}}
local realBindRows={[81]={areaID=81,space='world',instanceID=99,x=1,y=2},
 [82]={areaID=82,space='world',instanceID=43,x=750,y=250}}
personalData.GetBindings=function()return realBindRows end
personalApi.GetBindLocation=function()return 'Invented destination inn' end
local duplicateBindLabel=false
personalApr.NavigationAdapter.environment.getAreaName=function(id)
 if id==82 or duplicateBindLabel then return 'Invented destination inn' end
 return 'Other invented inn'
end
assert(owner:Start({startMode='player',to={mapID=812,x=75,y=25}},'v2'));result=finishOwner()
assert(result.status=='complete' and result.estimatedSeconds==10)
assert(owner:GetContext().engines.v2.capturedDynamic==1)
duplicateBindLabel=true
assert(owner:Start({startMode='player',to={mapID=812,x=75,y=25}},'v2'));result=finishOwner()
assert(result.status=='unknown' and result.estimatedSeconds==nil)

-- Cold loading is a phase of this same wrapper; no stale pre-load registry.
local productionForever=actual.NavigationV2ForeverData
local function foreverPersonalCase(settings)
 settings=settings or {}
 local s={ms=0,factory=0,resumes=0,spellReads=0,itemReads=0}
 local actionID=settings.item and 902 or 901
 local actionKind=settings.item and 'item' or 'spell'
 local point={space='world',instanceID=43,x=750,y=250}
 local connections={{id='invented-personal',kind=actionKind,from={dynamic='player'},
  to=settings.bind and {dynamic='bind'} or point,
  actions={{type=actionKind,id=actionID}}}}
 if settings.reagent~=nil then connections[1].actions[1].reagentID=903 end
 local bindings={[81]={areaID=81,space='world',instanceID=99,x=1,y=2},
  [82]={areaID=82,space='world',instanceID=43,x=750,y=250}}
 local config={actionLoadingSeconds=5}
 local data={GetProfile=function()return {name='forever'}end,GetConfig=function()return config end,
  GetConnections=function()return connections end,GetBindings=function()return bindings end,
  GetRoadData=function()return {networks={},collision={}}end}
 local native={GetBuildInfo=function()return '1.60.1','synthetic','',16001 end,
  GetTimePreciseSec=function()return s.ms/1000 end,debugprofilestop=function()return s.ms end,
  GetTime=function()return 9000 end,IsPlayerInWorld=function()return settings.ready~=false end,
  UnitPosition=function()return settings.mismatch and 260 or 250,500,10,42 end,
  GetMoney=function()return 100 end,InCombatLockdown=function()return false end,
  UnitCastingInfo=function()end,UnitChannelInfo=function()end,IsIndoors=function()return true end,
  GetBindLocation=function()return settings.bindName end,
  C_Map={GetBestMapForUnit=function()return 811 end,GetPlayerMapPosition=function()return {x=.25,y=.5}end},
  C_SpellBook={IsSpellKnown=function(id)assert(id==901);return settings.known~=false end},
  C_Spell={GetSpellInfo=function(id)
   assert(id==901);s.spellReads=s.spellReads+1
   if settings.cancel then s.owner:Cancel()end
   if settings.captureCost then s.ms=s.ms+settings.captureCost end
   return {name='Invented teleport',castTime=1500}
  end,IsSpellUsable=function()return true end,
   GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true,modRate=1}end},
  C_Item={IsItemDataCachedByID=function()return true end,IsUsableItem=function()return true end,
   GetItemCooldown=function()return 0,0,true end,GetItemCount=function(id)
    assert(id==902 or id==903);s.itemReads=s.itemReads+1
    if id==903 then
     if type(settings.reagent)=='number' then return settings.reagent end
     return
    end
    return 1
   end},CreateFrame=function()error('No native or secure UI')end}
 local aprHost={NavigationData=data,NavigationTerrain={RequestData=function()return 'missing','invented_no_terrain' end},
  NavigationAdapter={environment={getCharacter=function()return {level=35,class='MAGE',faction='Alliance'}end,
   mapToWorld=function(map,x,y)return map==811 and 42 or 43,x*1000,y*1000 end,
   getAreaName=function(id)
    if id==82 or settings.ambiguous then return 'Destination inn' end
    return 'Other inn'
   end,getActionCastSeconds=function(kind,id)assert(kind=='item' and id==902);return 2 end}}}
 actual.NavigationV2ForeverData={Prepare=function(...)
  s.factory=s.factory+1
  local child,why=productionForever.Prepare(...)
  if child and child.ResumeObservations then
   local resume=child.ResumeObservations
   function child:ResumeObservations(snapshot)
    s.resumes=s.resumes+1;s.snapshot=snapshot;return resume(self,snapshot)
   end
  end
  return child,why
 end}
 s.owner=actual.NavigationBenchmarkHost.New({api=native,apr=aprHost,engines={v2=actual.NavigationBenchmarkV2}})
 local endpoints={startMode=settings.manual and 'manual' or 'player',to={mapID=812,x=75,y=25}}
 if settings.manual then endpoints.from={mapID=811,x=25,y=50}end
 assert(s.owner:Start(endpoints,'v2'))
 local r
 for _=1,500 do local state=s.owner:Step();if state.status~='running' then r=state.engines.v2;break end end
 assert(r,'Forever personal host did not terminate')
 actual.NavigationV2ForeverData=productionForever
 return r,s
end
local function coldCase(settings)
 settings=settings or {}
 local s={loads=0,producers=0,producerCancels=0,new=0,clock=0,registrations=0}
 local registry={}
 local records=settings.fallback and {{id='independent',kind='passage',seconds=9,
  from={space='world',instanceID=0,x=1,y=0},to={space='world',instanceID=0,x=3,y=0}}} or {}
 local config={}
 local roadData={networks={},collision={}}
 if settings.road then
  roadData.networks.lane={id='lane',instanceID=0,walls={},openings={},sections={{id='section',kind='road',
   nodes={{id='a',x=1,y=0},{id='b',x=3,y=0}},edges={{id='directed',from='a',to='b',kind='road',
    bidirectional=false,points={{x=1,y=0},{x=3,y=0}}}}}}}
 end
 if settings.conditioned then records[1].requirements={faction='Alliance',quest=73} end
 local function register(id,value)
  registry.terrainDatasets=registry.terrainDatasets or {forever={[0]={packs={}}}}
  registry.terrainDatasets.forever[0].packs[id]={data=value,revision=7}
  s.registrations=s.registrations+1
 end
 if settings.refusal then register('present-but-refused',survey) end
 actual.NavigationV2ForeverData={Prepare=function(request,context)
  s.producers=s.producers+1;s.seen=context.terrain;s.status=context.terrainStatus
  s.reason=context.terrainReason;s.budget=context.budgets.cpuMs
  local child,why=productionForever.Prepare(request,context)
  if child then
   local cancel=child.Cancel
   function child:Cancel()s.producerCancels=s.producerCancels+1;return cancel(self)end
  end
  if settings.producerCost then s.clock=s.clock+settings.producerCost end
  s.replaceRecords=function()records={}end
  return child,why
 end}
 local context={profile='forever',build='synthetic',clock=function()return s.clock end,walkSpeed=7,
  api={LibStub=function()return registry end},conditionObservation=settings.conditionObservation,
  data={GetProfile=function()return {name='forever'}end,GetRoadData=function()return roadData end,
   GetConnections=function()return records end,GetConfig=function()return config end},
  environment={mapToWorld=function(_,x,y)return 0,x*4,y*4 end,
   getCharacter=function()return settings.character end},
  terrainHost={RequestData=function()
   s.loads=s.loads+1
   if settings.onLoadCost then s.clock=s.clock+settings.onLoadCost end
   if s.onLoad then s.onLoad()end
   if settings.refusal then return 'missing','terrain_build_unavailable' end
   if settings.neverReady then return 'planning','terrain_loading' end
   if s.loads==1 then register('a',survey)
    if settings.split then return 'planning','terrain_loading' end
   elseif settings.split and s.loads==2 then
    register('b',{format=1,profile='forever',worldID=0,scope={id='empty'},nodes={},edges={},anchors={}})
   end
   return 'ready'
  end},prepare=actual.NavigationV2PrepareBenchmark,
  library={New=function(...)s.new=s.new+1;return actual.LibAPRNavigationV2.New(...)end}}
 local driver=assert(actual.NavigationBenchmarkV2.Create({coordinateUnit='map-percent',
  from={mapID=803,x=25,y=0},to={mapID=803,x=75,y=0}},context))
 return driver,s
end
local cold,cs=coldCase({split=true})
assert(cs.loads==0 and cs.producers==0 and cs.registrations==0)
assert(cold:Step().status=='running' and cs.producers==0)
assert(cold:Step().status=='running' and cs.loads==1 and cs.producers==0)
assert(cold:Step().status=='running' and cs.loads==2 and cs.producers==0)
assert(cold:Step().status=='running' and cs.loads==3 and cs.producers==0)
result=finishObserved(cold)
assert(result.status=='complete' and math.abs(result.estimatedSeconds-6/7)<1e-9)
assert(cs.producers==1 and cs.new==1 and cs.registrations==2 and cs.seen[0].packs.b)
assert(cold:GetContext().dataLoadCalls==3)

cold,cs=coldCase({refusal=true})
result=finishObserved(cold)
assert(result.status=='unknown' and result.reason=='terrain_build_unavailable' and cs.producers==1)
cold,cs=coldCase({refusal=true,fallback=true})
result=finishObserved(cold)
assert(result.status=='complete' and result.estimatedSeconds==9 and cs.status=='missing')
assert(cs.reason=='terrain_build_unavailable' and cold:GetContext().dataLoadCalls==1)
cold,cs=coldCase({refusal=true,road=true})
result=finishObserved(cold)
assert(result.status=='complete' and math.abs(result.estimatedSeconds-2/7)<1e-9)
assert(cs.status=='missing' and cs.reason=='terrain_build_unavailable')
for _,scenario in ipairs({
 {character={faction='Alliance'},conditionObservation={sequence=1,worldState='ready',quests={[73]=true}},expected='complete'},
 {character={faction='Horde'},conditionObservation={sequence=1,worldState='ready',quests={[73]=true}},expected='unknown'},
 {character={faction='Alliance'},conditionObservation={sequence=1,worldState='ready',quests={[73]=false}},expected='unknown'},
 {character={faction='Alliance'},expected='unknown'},
}) do
 scenario.refusal,scenario.fallback,scenario.conditioned=true,true,true
 cold,cs=coldCase(scenario);result=finishObserved(cold)
 assert(result.status==scenario.expected)
 if scenario.expected=='complete' then assert(result.estimatedSeconds==9)else assert(result.estimatedSeconds==nil)end
end

cold,cs=coldCase({neverReady=true})
cold:Step();cold:Step();cold:Cancel();cold:Cancel()
assert(cold:Step().status=='cancelled' and cs.loads==1 and cs.producers==0)
cold,cs=coldCase({onLoadCost=101})
assert(finishObserved(cold).status=='budget_exceeded' and cs.loads==1 and cs.producers==0 and cs.new==0)
cold,cs=coldCase({onLoadCost=40,producerCost=21})
assert(finishObserved(cold).status=='budget_exceeded' and cs.loads==2 and cs.producers==1 and cs.new==0)
assert(cs.budget<=20 and cs.producerCancels==1)
cold,cs=coldCase({fallback=true})
for _=1,30 do assert(cold:Step().status=='running');if cs.producers==1 then break end end
assert(cs.producers==1);cs.replaceRecords()
result=finishObserved(cold)
assert(result.status=='unknown' and result.reason=='data_source_changed' and cs.producerCancels==1 and cs.new==0)
actual.NavigationV2ForeverData=productionForever

-- All public input facts reach the same Forever producer through the driver.
local transitionRecords={{id='invented-map-portal',kind='portal',
 from={space='map',uiMapID=901,x=.25,y=.5},to={space='map',uiMapID=902,x=.75,y=.5},
 requirements={faction='Alliance',quest=73}},
 {id='named-elsewhere',kind='passage',from={name='invented-point'},to={name='other-point'}}}
local transitionConfig={actionLoadingSeconds=4}
local transitionFacts={sequence=1,worldState='ready',quests={[73]=true},access={}}
local capturedPositions={['named-elsewhere']={from={world=9,x=7,y=6}}}
local projectedCalls,transitionProducerCalls=0,0
local transitionSeen
local cancelOnProjection
actual.NavigationV2ForeverData={Prepare=function(input,context)
 transitionProducerCalls=transitionProducerCalls+1
 transitionSeen=context
 return {Step=function()return {status='unknown',reason='captured_boundary_verified'}end,Cancel=function()end}
end}
local transitionContext={profile='forever',clock=function()return 0 end,
 conditionObservation=transitionFacts,connectionPositions=capturedPositions,
 environment={mapToWorld=function(map,x,y)
  projectedCalls=projectedCalls+1
  if cancelOnProjection then cancelOnProjection:Cancel()end
  return map,x*100,y*100
 end,
  getCharacter=function()return {faction='Alliance',level=35}end},
 data={GetProfile=function()return {name='forever'}end,GetConnections=function()return transitionRecords end,
  GetConfig=function()return transitionConfig end},prepare=actual.NavigationV2PrepareBenchmark,
 library=actual.LibAPRNavigationV2}
local transitionDriver=assert(actual.NavigationBenchmarkV2.Create({coordinateUnit='map-percent',
 from={mapID=901,x=25,y=50},to={mapID=902,x=75,y=50}},transitionContext))
assert(finishObserved(transitionDriver).reason=='captured_boundary_verified')
assert(transitionSeen.connections==transitionRecords and transitionSeen.config==transitionConfig)
assert(transitionSeen.actor.level==35 and transitionSeen.actor.faction=='Alliance')
assert(transitionSeen.conditionObservation==transitionFacts)
assert(transitionSeen.connectionPositions['named-elsewhere']==capturedPositions['named-elsewhere'])
local p=transitionSeen.connectionPositions['invented-map-portal']
assert(p and p.from.world==901 and p.from.x==25 and p.to.world==902 and p.to.y==50)
assert(transitionProducerCalls==1 and projectedCalls==4)
assert(capturedPositions['invented-map-portal']==nil and transitionRecords[1].from.x==.25)
local cancelledTransition=assert(actual.NavigationBenchmarkV2.Create({coordinateUnit='map-percent',
 from={mapID=901,x=25,y=50},to={mapID=902,x=75,y=50}},transitionContext))
assert(cancelledTransition:Step().status=='running') -- captures the two objective projections
assert(projectedCalls==6)
cancelOnProjection=cancelledTransition
assert(finishObserved(cancelledTransition).status=='cancelled')
assert(projectedCalls==7 and transitionProducerCalls==1)
actual.NavigationV2ForeverData=productionForever
local personalForever,pfs=foreverPersonalCase()
assert(personalForever.status=='complete' and personalForever.estimatedSeconds==6.5,
 'Forever personal spell: '..tostring(personalForever.status)..':'..tostring(personalForever.reason))
assert(pfs.factory==1 and pfs.resumes==1 and pfs.spellReads==1)
assert(pfs.snapshot.personalObservation.origin.reliable==true)
assert(pfs.snapshot.personalObservation.origin.node=='query:1')
assert(pfs.snapshot.personalObservation.observedAt==0)
assert(personalForever.metrics.newCalls==1 and personalForever.metrics.calculationsStarted==1)
personalForever,pfs=foreverPersonalCase({manual=true})
assert(pfs.snapshot.personalObservation.origin.reliable==false)
assert(pfs.snapshot.personalObservation.origin.indoors==nil and pfs.resumes==1)
assert(personalForever.status=='unknown' and personalForever.estimatedSeconds==nil)
personalForever,pfs=foreverPersonalCase({mismatch=true})
assert(pfs.snapshot.personalObservation.origin.reliable==false)
assert(personalForever.status=='unknown' and personalForever.estimatedSeconds==nil)
personalForever,pfs=foreverPersonalCase({bind=true,bindName='Destination inn'})
assert(personalForever.status=='complete' and personalForever.estimatedSeconds==6.5)
assert(pfs.snapshot.dynamicPositions.bind.areaID==82 and pfs.resumes==1)
for _,settings in ipairs({{bind=true},{bind=true,bindName='Destination inn',ambiguous=true},{known=false}}) do
 personalForever,pfs=foreverPersonalCase(settings)
 assert(personalForever.status=='unknown' and personalForever.estimatedSeconds==nil)
end
personalForever,pfs=foreverPersonalCase({item=true})
assert(personalForever.status=='complete' and personalForever.estimatedSeconds==7 and pfs.itemReads==1)
personalForever,pfs=foreverPersonalCase({reagent=1})
assert(personalForever.status=='complete' and personalForever.estimatedSeconds==6.5 and pfs.itemReads==1)
assert(pfs.snapshot.personalObservation.items[903]==1)
for _,quantity in ipairs({0,'missing'}) do
 personalForever,pfs=foreverPersonalCase({reagent=quantity})
 assert(personalForever.status=='unknown' and personalForever.estimatedSeconds==nil and pfs.itemReads==1)
end
personalForever,pfs=foreverPersonalCase({cancel=true})
assert(personalForever.status=='cancelled' and pfs.resumes==0)
personalForever,pfs=foreverPersonalCase({captureCost=101})
assert(personalForever.status=='budget_exceeded' and pfs.resumes==0)
-- Cold declared neighbors use the actual APR loader; no V1 routing module.
local function neighborCase(settings)
 settings=settings or {}
 local s={loads={},calls={},clock=0,wait=settings.planning or 0}
 local saved={APR=APR,LibStub=LibStub,GetBuildInfo=GetBuildInfo,GetTime=GetTime}
 local function p(x)return {world=8,x=x,y=5}end
 local scopes={}
 for _,v in ipairs({{'A',0,2},{'B',2,5},{'C',5,7},{'D',20,22}})do
  scopes[v[1]]={id=v[1],bounds={minX=v[2],maxX=v[3],minY=4,maxY=6}}
 end
 local adjacent={A={'B'},B={'A','C'},C={'B'},D={}}
 if settings.absent then adjacent.A={'missing'} end
 local metadata,raw={},{}
 for _,id in ipairs({'A','B','C','D'})do
  local lo,hi=scopes[id].bounds.minX,scopes[id].bounds.maxX
  metadata[#metadata+1]={id=id,file='NavigationData/invented-'..id..'.lua',revision=id=='B' and settings.revision and 2 or 1,
   scope=scopes[id],neighborScopeIDs=adjacent[id]}
  raw[id]={format=1,profile='forever',worldID=8,build='1.60.1.neighbors',scope=scopes[id],
   neighborScopeIDs=adjacent[id],nodes={{id='in',x=lo,y=5},{id='out',x=hi,y=5}},
   edges={{from='in',to='out',mode='ground',seconds=hi-lo,polyline={p(lo),p(hi)}}},anchors={}}
 end
 raw.A.edges[2]={from='out',to={pack='B',node='in'},mode='ground',seconds=0,neighborScopeID='B',polyline={p(2)}}
 raw.B.edges[2]={from='out',to={pack='C',node='in'},mode='ground',seconds=0,neighborScopeID='C',polyline={p(5)}}
 raw.A.anchors={{node='in',minX=0,maxX=0,minY=5,maxY=5,mode='ground'}}
 raw.C.anchors={{node='out',minX=7,maxX=7,minY=5,maxY=5,mode='ground'}}
 if settings.localScope then
  raw.A.nodes[#raw.A.nodes+1]={id='local-goal',x=1,y=5}
  raw.A.edges[#raw.A.edges+1]={from='in',to='local-goal',mode='ground',seconds=2,polyline={p(0),p(1)}}
  raw.A.anchors[#raw.A.anchors+1]={node='local-goal',minX=1,maxX=1,minY=5,maxY=5,mode='ground'}
 end
 local registry={terrainDatasets={},Terrain={}}
 function registry.Terrain.ScopeValid(scope)return type(scope)=='table' and type(scope.id)=='string' and type(scope.bounds)=='table'end
 function registry.Terrain.ScopeContains(scope,point)
  local b=scope.bounds;return point.x>=b.minX and point.x<=b.maxX and point.y>=b.minY and point.y<=b.maxY
 end
 function registry.Terrain.NeighborIDsValid(ids,own)
  if type(ids)~='table' then return false end
  local seen={}
  for i,id in ipairs(ids)do if type(id)~='string' or id==own or seen[id] then return false end;seen[id]=true end
  return true
 end
 function registry.Terrain.IndexScopeNeighbors(packs)
  local result={known={},invalid={},neighbors={}}
  for _,m in ipairs(packs)do result.known[m.scope.id]=true;result.neighbors[m.scope.id]=m.neighborScopeIDs end
  for _,m in ipairs(packs)do
   for _,id in ipairs(m.neighborScopeIDs)do if not result.known[id] then result.invalid[m.scope.id]=true end end
  end
  return result
 end
 if settings.noNeighborMetadata then registry.Terrain.IndexScopeNeighbors=nil end
 APR={NavigationTerrainIndex={schema=1,profiles={forever={builds={['1.60.1.neighbors']=true},worlds={[8]={packs=metadata}}}}}}
 function APR:GetGameVersion()return 'forever'end
 GetBuildInfo=function()return '1.60.1',s.buildRefusal and 'wrong' or 'neighbors','',16001 end
 GetTime=function()return 9000 end
 LibStub=function()return registry end
 assert(loadfile('APR-Core/features/navigation/NavigationTerrain.lua'))()
 local loader=APR.NavigationTerrain
 local function register(id)
  registry.terrainDatasets.forever=registry.terrainDatasets.forever or {[8]={packs={}}}
  registry.terrainDatasets.forever[8].packs[id]={revision=1,data=raw[id]}
 end
 for _,m in ipairs(metadata)do
  local id=m.id
  assert(loader:RegisterSource('forever',8,id,1,function()s.loads[id]=(s.loads[id] or 0)+1;register(id)end))
 end
 if settings.stale then register('B');s.stale=registry.terrainDatasets.forever[8].packs.B end
 local realRequest,realScopes,realNeighbors=loader.RequestData,loader.GetScopes,loader.GetScopeNeighbors
 function loader:GetScopes(profile,world)
  s.scopes=(s.scopes or 0)+1;assert(world==8)
  if settings.cancelMetadata then s.host:Cancel()end
  if settings.metadataCost then s.clock=s.clock+settings.metadataCost end
  if settings.tooMany then local list={};for i=1,129 do list[i]={id='extra-'..i,bounds={minX=20,maxX=22,minY=4,maxY=6}}end;return list,false end
  if settings.noMetadata then return nil end
  return realScopes(self,profile,world)
 end
 function loader:GetScopeNeighbors(profile,world,id)
  s.neighbors=s.neighbors or {};s.neighbors[id]=(s.neighbors[id] or 0)+1
  if settings.invalid then return {17} end
  return realNeighbors(self,profile,world,id)
 end
 function loader:RequestData(profile,world,point,selection)
  s.calls[#s.calls+1]={point=point,selection=selection}
  local selected=selection and selection.scopeIDs.B
  if selected then
   assert(point==nil,'Selected middle scope must not be filtered by an endpoint point')
   s.middle=(s.middle or 0)+1
   self.sources['forever:8:B'].loading=s.wait>0 or nil
   if s.wait>0 then s.wait=s.wait-1 end
   s.buildRefusal=settings.build
  end
  local a,b=realRequest(self,profile,world,point,selection)
  self.sources['forever:8:B'].loading=nil;s.buildRefusal=false
  if selected and settings.cost then s.clock=s.clock+settings.cost end
  return a,b
 end
 local connections={}
 if settings.personal then connections={{id='independent-spell',kind='spell',from={dynamic='player'},
  to={space='world',instanceID=8,x=7,y=5},actions={{type='spell',id=901}}}}end
 local config,bindings,roads={actionLoadingSeconds=5},{},{networks={},collision={}}
 local data={GetProfile=function()return {name='forever'}end,GetConfig=function()return config end,
  GetConnections=function()return connections end,GetBindings=function()return bindings end,GetRoadData=function()return roads end}
 APR.NavigationData=data;APR.NavigationAdapter={environment={mapToWorld=function(map,x,y)return 8,x*(map==102 and 1 or 7),y*10 end,
  getCharacter=function()return {level=35,class='MAGE',faction='Alliance'}end}}
 local native={LibStub=LibStub,GetBuildInfo=GetBuildInfo,GetTime=GetTime,
  GetTimePreciseSec=function()return s.clock/1000 end,debugprofilestop=function()return s.clock end,
  IsPlayerInWorld=function()return true end,UnitPosition=function()return 0,5,0,8 end,
  GetMoney=function()return 0 end,InCombatLockdown=function()return false end,
  UnitCastingInfo=function()end,UnitChannelInfo=function()end,IsIndoors=function()return false end,
  C_Map={GetBestMapForUnit=function()return 101 end,GetPlayerMapPosition=function()return {x=0,y=.5}end},
  C_SpellBook={IsSpellKnown=function()return true end},C_Spell={GetSpellInfo=function()
   if settings.replaceAccepted then registry.terrainDatasets.forever[8].packs.C={revision=2,data=raw.C}end
   return {name='Invented teleport',castTime=1500}
  end,
   IsSpellUsable=function()return true end,GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true,modRate=1}end}}
 local host=actual.NavigationBenchmarkHost.New({api=native,apr=APR,engines={v2=actual.NavigationBenchmarkV2}})
 local input={startMode=settings.personal and 'player' or 'manual',from={mapID=101,x=settings.reverse and 100 or 0,y=50},
  to={mapID=settings.localScope and 102 or 101,x=settings.reverse and 0 or 100,y=50}}
 assert(host:Start(input,'v2'))
 function s:Step()
  local before=#self.calls
  local metadataBefore=(self.scopes or 0)
  for _,count in pairs(self.neighbors or {})do metadataBefore=metadataBefore+count end
  local r=host:Step()
  assert(#self.calls-before<=1,'Only one loader invocation per Step')
  local metadataAfter=(self.scopes or 0)
  for _,count in pairs(self.neighbors or {})do metadataAfter=metadataAfter+count end
  assert(metadataAfter-metadataBefore+#self.calls-before<=1,'One metadata or loading API unit per Step')
  return r
 end
 function s:Finish()
  for _=1,1000 do local r=self:Step();if r.status~='running' then return r.engines.v2 end end
  error('Small neighbor fixture did not terminate')
 end
 s.host,s.registry=host,registry
 function s:Restore()APR=saved.APR;LibStub=saved.LibStub;GetBuildInfo=saved.GetBuildInfo;GetTime=saved.GetTime end
 return s
end
local neighbor=neighborCase()
result=neighbor:Finish()
assert(result.status=='complete' and result.estimatedSeconds==7,'Cold declared A/B/C must reach7s; '..tostring(result.reason))
assert(neighbor.loads.B==1 and neighbor.loads.D==nil)
assert(neighbor.neighbors.A==1 and neighbor.neighbors.B==1 and neighbor.neighbors.C==1)
assert(neighbor.host:GetContext().engines.v2.dataLoadCalls==3)
neighbor:Restore()
neighbor=neighborCase({localScope=true,noNeighborMetadata=true});result=neighbor:Finish()
assert(result.status=='complete' and result.estimatedSeconds==2,'Ready local geometry survives missing neighbor metadata')
assert(neighbor.loads.A==1 and neighbor.loads.B==nil and neighbor.loads.C==nil);neighbor:Restore()
neighbor=neighborCase({reverse=true});result=neighbor:Finish()
assert(result.status=='unknown' and result.estimatedSeconds==nil and neighbor.loads.D==nil);neighbor:Restore()
neighbor=neighborCase({planning=2});result=neighbor:Finish()
assert(result.status=='complete' and result.estimatedSeconds==7 and neighbor.middle==3 and neighbor.loads.B==1)
assert(neighbor.host:GetContext().engines.v2.dataLoadCalls==5);neighbor:Restore()
for _,scenario in ipairs({{absent=true},{invalid=true},{build=true},{revision=true,stale=true}})do
 neighbor=neighborCase(scenario);result=neighbor:Finish()
 assert(result.status=='unknown' and result.estimatedSeconds==nil)
 local context=neighbor.host:GetContext().engines.v2
 assert(type(context.terrainLoadReason)=='string')
 if scenario.build then assert(context.terrainLoadReason=='terrain_build_unavailable')end
 if scenario.revision then
  assert(context.terrainLoadReason=='terrain_source_revision_mismatch')
  assert(neighbor.registry.terrainDatasets.forever[8].packs.B==neighbor.stale,'Refused cached source is not mutated or used')
 end
 assert(neighbor.loads.D==nil);neighbor:Restore()
end
for _,scenario in ipairs({{noMetadata=true},{invalid=true},{tooMany=true},{build=true},{revision=true,stale=true}})do
 scenario.personal=true
 neighbor=neighborCase(scenario);result=neighbor:Finish()
 assert(result.status=='complete' and result.estimatedSeconds==6.5,tostring(result.status)..':'..tostring(result.reason))
 if scenario.tooMany then assert(neighbor.host:GetContext().engines.v2.terrainLoadReason=='terrain_scope_limit')end
 assert(neighbor.loads.D==nil);neighbor:Restore()
end
neighbor=neighborCase({build=true,personal=true,replaceAccepted=true});result=neighbor:Finish()
assert(result.status=='unknown' and result.reason=='data_source_changed' and (result.metrics.newCalls or 0)==0)
neighbor:Restore()
neighbor=neighborCase({planning=10})
for _=1,200 do assert(neighbor:Step().status=='running');if neighbor.middle then break end end
assert(neighbor.middle==1 and neighbor.loads.B==nil)
local callsBeforeCancel=#neighbor.calls
neighbor.host:Cancel();result=neighbor:Finish()
assert(result.status=='cancelled' and #neighbor.calls==callsBeforeCancel and neighbor.loads.B==nil);neighbor:Restore()
neighbor=neighborCase({cancelMetadata=true});result=neighbor:Finish()
assert(result.status=='cancelled' and neighbor.loads.B==nil);neighbor:Restore()
for _,scenario in ipairs({{cost=101},{metadataCost=101}})do
 neighbor=neighborCase(scenario);result=neighbor:Finish()
 assert(result.status=='budget_exceeded' and (result.metrics.newCalls or 0)==0)
 neighbor:Restore()
end
-- Shared world entry preserves native Z/identity without a map roundtrip.
local worldNS={}
assert(loadfile('APR-Core/features/navigation/NavigationBenchmarkPreparation.lua'))('test',worldNS)
local worldProfile='retail'
local worldFacts={config={},connections={},bindings={},roads={networks={},collision={}}}
local worldData={GetProfile=function()return {name=worldProfile}end,
 GetConfig=function()return worldFacts.config end,GetConnections=function()return worldFacts.connections end,
 GetBindings=function()return worldFacts.bindings end,GetRoadData=function()return worldFacts.roads end}
local worldSeen
local function worldChild(input,options)
 worldSeen={input=input,options=options}
 return {Step=function()return {status='complete',graph={complete=true,nodes={'a','b'},edges={}},
  positions={},request={from='a',to='b'}}end,Cancel=function()end}
end
worldNS.NavigationV2RetailData={Prepare=function(_,input,options)return worldChild(input,options)end}
worldNS.NavigationV2ForeverData={Prepare=worldChild}
local worldContext={profile=worldProfile,data=worldData,clock=function()return 0 end,walkSpeed=7,
 budgets={sliceMs=1,cpuMs=100,elapsedMs=5000},environment={mapToWorld=function()error('No world roundtrip')end}}
local worldRequest={from={instanceID=8,x=2,y=3,z=0,uiMapID=101,spaceID='room',floor='upper',phase=4,accessKey='door'},
 to={instanceID=9,x=5,y=6,z=12,uiMapID=102},startMode='manual'}
assert(type(worldNS.NavigationV2PrepareWorld)=='function')
local worldJob=assert(worldNS.NavigationV2PrepareWorld(worldRequest,worldContext))
assert(worldSeen.input.from.space=='world' and worldSeen.input.from.instanceID==8)
assert(worldSeen.input.from.z==0 and worldSeen.input.from.floor=='upper' and worldSeen.input.from.spaceID=='room')
assert(worldJob:Step().status=='complete' and worldJob:IsCurrent())
worldFacts.connections={}
local current,changed=worldJob:IsCurrent();assert(current==false and changed=='data_source_changed')
worldProfile='forever';worldContext.profile=worldProfile
worldSeen=nil;worldJob=assert(worldNS.NavigationV2PrepareWorld(worldRequest,worldContext))
for _=1,40 do local r=worldJob:Step();if r.status~='running' then break end end
assert(worldSeen.input.from.world==8 and worldSeen.input.from.x==2 and worldSeen.input.from.z==0)
assert(worldSeen.input.from.space=='room' and worldSeen.input.from.phase==4 and worldSeen.input.from.accessKey=='door')
assert(worldJob:IsCurrent())
print('Benchmark preparation: public capture, cold neighbors, world input and source proof passed')
