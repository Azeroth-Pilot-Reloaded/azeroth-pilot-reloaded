local F=dofile('tests/lua/navigation_v2_retail_movement/fixture.lua')
local D=assert(F.ns.NavigationV2RetailData)
local function Observation(changes)
    local value={revision=1,observedAt=100,loading=false,combat=false,casting=false,moneyCopper=0,
        origin={node='retail-point:1',reliable=true},items={},actions={
            ['spell:41']={known=true,loaded=true,usable=true,readyAt=100,castSeconds=3},
            ['item:51']={owned=true,loaded=true,usable=true,readyAt=100,castSeconds=3}}}
    for k,v in pairs(changes or {})do value[k]=v end
    return value
end
local function Source(kind,action)
    return {id='invented-recall',kind=kind,from={dynamic='player'},
        to={space='map',uiMapID=22,x=.3,y=.4},actions={action or {id=41,type='spell'}}}
end
local function Prepare(records,options,bindings,goal)
    options=options or {};options.clock=function()return 0 end
    local request={from={mapID=11,x=.1,y=.2},to=goal or {mapID=22,x=.3,y=.4}}
    local job=assert(D.Prepare({config={actionLoadingSeconds=2},connections=records,bindings=bindings or {}},request,options))
    local prepared=F.Finish(job,1)
    assert(prepared.status=='complete',prepared.status..':'..tostring(prepared.reason))
    return prepared,job
end
local function Solve(prepared)
    local o=prepared.options;o.clock=function()return 100 end;o.profileClock=function()return 0 end
    local planner=assert(F.Library.New(prepared.graph,o))
    return F.Finish(planner:Plan(prepared.request),1),planner
end
local spell=Source('spell')
assert(Solve(Prepare({spell})).status=='unknown')
local prepared,job=Prepare({spell},{personalObservation=Observation()})
local first=Solve(prepared)
assert(first.status=='complete' and first.estimatedSeconds==5,'observed spell cast + declared loading must make a usable first TP')
assert(prepared.guidance and prepared.guidance[first.segments[1].edgeId],
    'first-use TP must expose guidance for its actually represented alternative')
local firstHint=prepared.guidance[first.segments[1].edgeId]
assert(firstHint.kind=='spell' and firstHint.connectionID=='invented-recall' and firstHint.sourceFree==true)
assert(firstHint.action.type=='spell' and firstHint.action.id==41)
assert(firstHint.instruction==nil and firstHint.arrivalRange==nil and firstHint.arrivalZTolerance==nil)
firstHint.action.id=999
assert(spell.actions[1].id==41,'guidance action cannot mutate source action facts')
local unitSpell=Source('spell');unitSpell.to.y=.7142
local unitRequest={coordinateUnit='map-percent',from={mapID=11,x=10,y=20},to={mapID=22,x=30,y=.7142*100}}
local function UnitProof(request)
    local job=assert(D.Prepare({config={actionLoadingSeconds=2},connections={unitSpell},bindings={}},request,
        {clock=function()return 0 end,personalObservation=Observation()}))
    return Solve(F.Finish(job,1))
end
assert(UnitProof(unitRequest).estimatedSeconds==5,'last binary bit from a percent roundtrip cannot split a declared endpoint')
assert(unitRequest.to.y==.7142*100 and unitSpell.to.y==.7142,'input capture and maintained source facts remain unchanged')
unitSpell.to.floor='upper';unitRequest.to.identity={floorID='lower'}
assert(UnitProof(unitRequest).status=='unknown','unit codec cannot merge conflicting floors')
unitSpell.to.floor=nil;unitSpell.to.phase='blue';unitRequest.to.identity={phaseID='red'}
assert(UnitProof(unitRequest).status=='unknown','unit codec cannot merge conflicting phases')
unitSpell.to.phase=nil;unitSpell.to.accessKey='room-a';unitRequest.to.identity=nil;unitRequest.to.accessKey='room-b'
assert(UnitProof(unitRequest).status=='unknown','unit codec cannot merge conflicting access identities')
unitSpell.to.accessKey=nil;unitRequest.to.accessKey=nil;unitSpell.to.worldID=0;unitRequest.to.identity={worldID=1}
assert(UnitProof(unitRequest).status=='unknown','world0 remains valid and distinct from world1')
unitSpell.to.worldID=nil;unitRequest.to.identity=nil
unitRequest.to.y=.71420000001*100
assert(UnitProof(unitRequest).status=='unknown','numerical unit canonicalization must not add a proximity connector')
assert(job:GetObservationRequests().actions['spell:41'].spellID==41)
local unready=Observation();unready.actions['spell:41'].readyAt=105
assert(Solve(Prepare({spell},{personalObservation=unready})).status=='unknown')
local exact=Prepare({spell},{personalObservation=unready,actionPolicies={['spell:41']={cooldownSeconds=10,chargeBased=false}}})
local waited=Solve(exact)
assert(waited.status=='complete' and waited.estimatedSeconds==10 and waited.segments[1].personalId,
    'known cooldown uses the existing Personal wait planner')
local exactHint=exact.guidance[waited.segments[1].personalId]
assert(exactHint and exactHint.action.type=='spell' and exactHint.action.id==41 and exactHint.sourceFree==true,
    'exact Personal descriptor ID must have the same guidance contract')
local missingCost=Observation();missingCost.actions['spell:41'].castSeconds=nil
assert(Solve(Prepare({spell},{personalObservation=missingCost})).status=='unknown')
local revoked=Observation();revoked.actions['spell:41'].known=false
assert(Solve(Prepare({spell},{personalObservation=revoked})).status=='unknown')
local localDenied=Observation();localDenied.actions['spell:41'].usable=false
local deniedGraph=Prepare({spell},{personalObservation=localDenied})
local currentDenied,futureUnknown=false,false
for _,edge in ipairs(deniedGraph.graph.edges)do
    if edge.from==deniedGraph.request.from then currentDenied=edge.access=='unavailable' end
    if edge.from==deniedGraph.request.to then futureUnknown=edge.access=='unknown' end
end
assert(currentDenied and futureUnknown,'current local unusability cannot become a proved denial at every future departure')
local malformed=Observation();malformed.actions['spell:41'].known='yes'
assert(Solve(Prepare({spell},{personalObservation=malformed})).status=='unknown','nonboolean capability cannot authorize a TP')
local grouped=Source('spell',{id=41,type='spell',groupSpellID=42})
local groupObservation=Observation();groupObservation.actions['spell:41'].known=false
groupObservation.actions['spell:42']={known=true,loaded=true,usable=true,readyAt=100,castSeconds=3}
assert(Solve(Prepare({grouped},{personalObservation=groupObservation,actor={inGroup=true}})).estimatedSeconds==5,
    'the existing group spell is a separately observed alternative')
assert(Solve(Prepare({grouped},{personalObservation=groupObservation,actor={inGroup=false}})).status=='unknown')
local groupedPrepared=Prepare({grouped},{personalObservation=groupObservation,actor={inGroup=true}})
local groupedResult=Solve(groupedPrepared)
assert(groupedPrepared.guidance[groupedResult.segments[1].edgeId].action.id==42,
    'group alternative metadata cannot claim that the unavailable original spell was selected')
local item=Source('item',{id=51,type='item',consumable=true})
local inventory=Observation();inventory.items[51]=0
assert(Solve(Prepare({item},{personalObservation=inventory})).status=='unknown')
inventory.items[51]=1
assert(Solve(Prepare({item},{personalObservation=inventory})).estimatedSeconds==5)
inventory.items[51]=nil
assert(Solve(Prepare({item},{personalObservation=inventory})).status=='unknown','absent inventory is not free consumption')
inventory.items[51]=1
local reagent=Source('spell',{id=41,type='spell',reagentID=61})
assert(Solve(Prepare({reagent},{personalObservation=inventory})).status=='unknown','declared reagent without quantity stays unknown')
inventory.items[61]=1
assert(Solve(Prepare({reagent},{personalObservation=inventory,
    actionPolicies={['spell:41']={reagentCount=2}}})).status=='unknown')
inventory.items[61]=2
assert(Solve(Prepare({reagent},{personalObservation=inventory,
    actionPolicies={['spell:41']={reagentCount=2}}})).estimatedSeconds==5)
local priced=Source('spell',{id=41,type='spell',moneyCopper=2})
inventory.moneyCopper=1
assert(Solve(Prepare({priced},{personalObservation=inventory})).status=='unknown')
inventory.moneyCopper=2
assert(Solve(Prepare({priced},{personalObservation=inventory})).estimatedSeconds==5)
priced.actions[1].moneyCopper='unknown'
assert(Solve(Prepare({priced},{personalObservation=inventory})).status=='unknown','malformed fee cannot become zero')
local charge=Observation()
charge.actions['spell:41'].readyAt=110
charge.actions['spell:41'].charges=0;charge.actions['spell:41'].maxCharges=1
charge.actions['spell:41'].rechargeStart=100;charge.actions['spell:41'].rechargeSeconds=10;charge.actions['spell:41'].rechargeRate=1
local recharged=Solve(Prepare({spell},{personalObservation=charge,
    actionPolicies={['spell:41']={cooldownSeconds=10,chargeBased=true}}}))
assert(recharged.estimatedSeconds==15,'existing Personal charge planner waits for known regeneration')
local declaredCharge=Source('spell',{id=41,type='spell',chargeBased=true})
local emptyCharge=Observation();emptyCharge.actions['spell:41'].charges=0
assert(Solve(Prepare({declaredCharge},{personalObservation=emptyCharge})).status=='unknown',
    'a declared charged action with no remaining charge cannot become a first-use token')
local bareAlias=Source('spell');bareAlias.id='same-api-without-charge-annotation'
assert(Solve(Prepare({declaredCharge,bareAlias},{personalObservation=emptyCharge})).status=='unknown',
    'another destination alias cannot erase the known charge mode of the same API action')
local recall=Source('item',{id=51,type='item'});recall.to={dynamic='bind'}
local bindings={[777]={space='map',uiMapID=22,x=.3,y=.4}}
assert(Solve(Prepare({recall},{personalObservation=inventory},bindings)).status=='unknown')
local bound=Prepare({recall},{personalObservation=inventory,
    dynamicPositions={bind={reliable=true,areaID=777}}},bindings)
assert(Solve(bound).estimatedSeconds==5,'an observed bind ID can select its existing declared candidate')
local wrong=Prepare({recall},{personalObservation=inventory,
    dynamicPositions={bind={reliable=false,areaID=777}}},bindings)
assert(Solve(wrong).status=='unknown')
-- An ordinary alternatives record preserves each action's requirements.
local choices=Source('item',{id=50,type='item'})
choices.actions={{id=50,type='item'},{id=51,type='item',requirements={any={{raceID=7},{raceID=8}}}}}
choices.selection='random'
inventory.actions['item:50']={owned=false,loaded=true,usable=true,readyAt=100,castSeconds=1}
assert(Solve(Prepare({choices},{personalObservation=inventory,actor={raceID=7}})).estimatedSeconds==5)
assert(Solve(Prepare({choices},{personalObservation=inventory,actor={raceID=9}})).status=='unknown')
local mixed=Source('item')
mixed.actions={{id=41,type='spell'},{id=51,type='item',instruction='Use this item',arrivalRange=4}}
mixed.instruction='Source instruction';mixed.arrivalZTolerance=2
local selectedObservation=Observation()
selectedObservation.actions['spell:41'].known=false
local selected=Prepare({mixed},{personalObservation=selectedObservation})
local selection=Solve(selected)
local selectedHint=selected.guidance[selection.segments[1].edgeId]
assert(selectedHint.kind=='item' and selectedHint.action.type=='item' and selectedHint.action.id==51)
assert(selectedHint.instruction=='Use this item' and selectedHint.arrivalRange==4 and selectedHint.arrivalZTolerance==2)
selectedObservation.actions['spell:41'].known=true;selectedObservation.actions['item:51'].owned=false
selected=Prepare({mixed},{personalObservation=selectedObservation})
selection=Solve(selected);selectedHint=selected.guidance[selection.segments[1].edgeId]
assert(selectedHint.kind=='item' and selectedHint.action.type=='spell' and selectedHint.action.id==41,
    'source kind is preserved while selected action can be a spell alternative')
assert(selectedHint.instruction=='Source instruction' and selectedHint.arrivalRange==nil)
assert(mixed.actions[2].id==51 and mixed.actions[2].instruction=='Use this item' and mixed.arrivalRange==nil)
local selectedPolicies={['spell:41']={cooldownSeconds=10,chargeBased=false},
    ['item:51']={cooldownSeconds=10,chargeBased=false}}
local exactSelection=Prepare({mixed},{personalObservation=selectedObservation,actionPolicies=selectedPolicies})
local exactResult=Solve(exactSelection)
assert(exactSelection.guidance[exactResult.segments[1].personalId].action.id==41)
selectedObservation.actions['spell:41'].known=false;selectedObservation.actions['item:51'].owned=true
exactSelection=Prepare({mixed},{personalObservation=selectedObservation,actionPolicies=selectedPolicies})
exactResult=Solve(exactSelection)
assert(exactSelection.guidance[exactResult.segments[1].personalId].action.id==51,
    'exact Personal guidance also follows the selected item alternative')
-- Same item and cooldown group are shared across successive planned uses.
local a=Source('item',{id=51,type='item',consumable=true});a.from={space='map',uiMapID=11,x=.1,y=.2}
local b=Source('item',{id=51,type='item',consumable=true});b.id='second-recall';b.from=a.to
b.to={space='map',uiMapID=33,x=.5,y=.6};a.cooldownGroup='shared-test';b.cooldownGroup='shared-test'
inventory.items[51]=1
assert(Solve(Prepare({a,b},{personalObservation=inventory},nil,{mapID=33,x=.5,y=.6})).status=='unknown')
inventory.items[51]=2
assert(Solve(Prepare({a,b},{personalObservation=inventory},nil,{mapID=33,x=.5,y=.6})).status=='unknown',
    'unknown future cooldown cannot restore the shared first-use token')
local repeated=Prepare({a,b},{personalObservation=inventory,
    actionPolicies={['item:51']={cooldownSeconds=10,chargeBased=false}}},nil,{mapID=33,x=.5,y=.6})
local twice=Solve(repeated)
assert(repeated.guidance[twice.segments[1].personalId].sourceFree==nil,
    'a static declared departure cannot acquire a sourceFree hint')
assert(twice.estimatedSeconds==15,'known cooldown restores once and charges the wait exactly: '..tostring(twice.status)..'/'..tostring(twice.estimatedSeconds)..'/'..tostring(twice.reason))
inventory.items[51]=1
assert(Solve(Prepare({a,b},{personalObservation=inventory,
    actionPolicies={['item:51']={cooldownSeconds=10,chargeBased=false}}},nil,{mapID=33,x=.5,y=.6})).status=='unknown')
-- Captures are requested once at an explicit boundary on the same bounded job.
local deferred=assert(D.Prepare({config={actionLoadingSeconds=2},connections={spell},bindings={}},
    {from={mapID=11,x=.1,y=.2},to={mapID=22,x=.3,y=.4}},
    {clock=function()return 0 end,deferObservations=true}))
local boundary
for _=1,100 do boundary=deferred:Step(1);if boundary.phase=='observation_required' then break end end
assert(boundary.phase=='observation_required' and boundary.status=='running')
assert(deferred:ResumeObservations({personalObservation=Observation()}))
assert(Solve(F.Finish(deferred,1)).estimatedSeconds==5)
assert(deferred:ResumeObservations({personalObservation=Observation()})==nil,'no stale second capture may overwrite the finished job')
local waiting=assert(D.Prepare({config={},connections={},bindings={}},{from={mapID=11,x=.1,y=.2},to={mapID=11,x=.1,y=.2}},
    {clock=function()return 0 end,deferObservations=true}))
assert(waiting:ResumeObservations({})==nil)
waiting:Cancel();assert(waiting:ResumeObservations({})==nil)
