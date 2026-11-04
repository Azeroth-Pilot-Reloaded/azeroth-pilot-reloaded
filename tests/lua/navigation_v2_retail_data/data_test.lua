local F=dofile('tests/lua/navigation_v2_retail_movement/fixture.lua')
local ns=F.ns
assert(ns.NavigationV2RetailData,'Retail data must load through the real XML')
local D=assert(ns.NavigationV2RetailData)
local function Request(x,y)
    return {coordinateUnit='map-percent',from={mapID=11,x=x or 10,y=20},to={mapID=22,x=y or 30,y=40}}
end
local function Facts(extra)
    local c={id='invented-tunnel',kind='passage',bidirectional=true,seconds=19,
        from={space='map',uiMapID=11,x=.1,y=.2},to={space='map',uiMapID=22,x=.3,y=.4}}
    for k,v in pairs(extra or {})do c[k]=v end
    return {config={IsolatedAreas={[11]='cavern-a',[22]='cavern-b'}},connections={c},bindings={}}
end
local function Prepare(data,request,options)
    options=options or {};options.clock=options.clock or function()return 0 end
    local job=assert(D.Prepare(data,request or Request(),options))
    return F.Finish(job,1),job
end
local function Solve(result,request)
    assert(result.status=='complete',result.status..':'..tostring(result.reason))
    local options=result.options or {};options.clock=function()return 0 end;options.profileClock=function()return 0 end
    local planner=assert(F.Library.New(result.graph,options))
    return F.Finish(planner:Plan(request or result.request),1),planner
end
local prepared,job=Prepare(Facts())
assert(prepared.provenance.scope=='declared_retail_request' and prepared.graph.complete==false)
local result=Solve(prepared)
assert(result.status=='complete' and result.estimatedSeconds==19 and #result.segments==1)
assert(result.segments[1].edgeId=='declared:invented-tunnel:forward')
assert(prepared.guidance and prepared.guidance[result.segments[1].edgeId],
    'semantic passage edge must expose descriptive guidance by its unchanged edge ID')
assert(prepared.guidance[result.segments[1].edgeId].kind=='passage')
local reverse=Solve(prepared,{from=prepared.request.to,to=prepared.request.from})
assert(reverse.status=='complete' and reverse.estimatedSeconds==19)
assert(prepared.guidance[reverse.segments[1].edgeId].connectionID=='invented-tunnel')
local portalData=Facts({kind='portal',instruction='Use the declared portal',arrivalRange=6,arrivalZTolerance=0})
local portal=Prepare(portalData)
local portalPath=Solve(portal)
local hint=portal.guidance[portalPath.segments[1].edgeId]
assert(hint.kind=='portal' and hint.connectionID=='invented-tunnel' and hint.instruction=='Use the declared portal')
assert(hint.arrivalRange==6 and hint.arrivalZTolerance==0 and hint.sourceFree==nil and hint.action==nil)
hint.instruction='consumer copy'
assert(portalData.connections[1].instruction=='Use the declared portal',
    'guidance is detached metadata, not a mutable source declaration')
local invalidHint=Prepare(Facts({instruction={},arrivalRange=-1,arrivalZTolerance=0/0}))
local absent=invalidHint.guidance['declared:invented-tunnel:forward']
assert(absent.instruction==nil and absent.arrivalRange==nil and absent.arrivalZTolerance==nil,
    'unknown optional guidance values cannot acquire generated defaults')
local alternatives=Prepare(Facts({kind='portal',requirements={any={{quest=81},{quest=82}}}}),nil,
    {conditionObservation={sequence=1,worldState='ready',quests={[81]=false,[82]=true}}})
local alternativePath=Solve(alternatives)
assert(alternativePath.status=='complete' and alternatives.guidance[alternativePath.segments[1].edgeId].kind=='portal')
assert(alternatives.guidance['declared:invented-tunnel:forward:alternative:2'])
local directed=Prepare(Facts({bidirectional=false}))
assert(Solve(directed,{from=directed.request.to,to=directed.request.from}).status=='unknown')
assert(job:GetMetrics().sourceRecords==1 and job:GetMetrics().operations>0)
local noCost=Prepare(Facts({seconds=false}))
assert(Solve(noCost).status=='unknown','missing cost cannot become a free usable passage')
local condition=Prepare(Facts({requirements={phase={group='invented',phase='past'}}}))
assert(Solve(condition).status=='unknown','unrepresented condition stays local unknown')
local denial=Prepare(Facts({requirements={faction='Horde'}}),nil,{actor={faction='Alliance'}})
assert(Solve(denial).status=='unknown')
local quest=Prepare(Facts({requirements={quest=12345}}),nil,
    {conditionObservation={sequence=1,worldState='ready',quests={[12345]=true}}})
assert(Solve(quest).estimatedSeconds==19)
assert(next(quest.graph.edges[1].requirements)~=nil)
assert(quest.graph.edges[1].requirements.world==nil,'future endpoint world is not a global observed-world condition')
-- Free approach needs a real conversion callback. The fixture defines its own yards.
local calls=0
local function Convert(map,x,y)
    calls=calls+1;return 0,x*1000,y*1000
end
local movement=assert(F.Retail.New(F.Observation()))
local approach=Prepare({config={},connections={},bindings={}},
    {coordinateUnit='map-percent',from={mapID=11,x=0,y=0},to={mapID=11,x=60,y=0}},
    {mapToWorld=Convert,movement=movement})
local flight=Solve(approach)
assert(flight.status=='complete' and flight.estimatedSeconds==13 and #flight.segments==1)
assert(flight.segments[1].mode=='skyriding' and calls==2,'world0 and normalize exactly once')
assert(next(approach.guidance)==nil and approach.guidance[flight.segments[1].edgeId]==nil,
    'implicit local movement is not described as a portal or transport')
local futureProfile=assert(F.Retail.New(F.Observation({canMountHere=false,canSkyridingHere=false})))
local across=Prepare(Facts(),Request(10,90),{mapToWorld=Convert,movement=futureProfile})
local onwards=Solve(across)
assert(onwards.status=='complete' and onwards.estimatedSeconds==32 and #onwards.segments==2)
assert(onwards.segments[1].edgeId=='declared:invented-tunnel:forward' and onwards.segments[2].mode=='skyriding',
    'current indoor permission does not forbid the future exterior flight after a declared passage')
local restricted=Prepare({config={GroundOnlyAreas={[11]=true}},connections={},bindings={}},
    {coordinateUnit='map-percent',from={mapID=11,x=0,y=0},to={mapID=11,x=60,y=0}},
    {mapToWorld=Convert,movement=movement})
assert(Solve(restricted).segments[1].mode~='skyriding')
local room={id='invented-room',kind='building',worldID=0,mapIDs={11},requiresExit=true,groundOnly=true,
    bounds={minX=0,maxX=100,minY=0,maxY=100}}
local door={id='invented-door',kind='passage',seconds=2,
    from={space='map',uiMapID=11,x=.1,y=0},to={space='map',uiMapID=11,x=.2,y=0}}
local cave=Prepare({config={NavigationSpaces={room}},connections={door},bindings={}},
    {coordinateUnit='map-percent',from={mapID=11,x=0,y=0},to={mapID=11,x=60,y=0}},
    {mapToWorld=Convert,movement=movement})
local escaped=Solve(cave)
assert(escaped.status=='complete' and #escaped.segments==3)
assert(escaped.segments[2].edgeId=='declared:invented-door:forward')
assert(escaped.segments[3].mode=='skyriding')
local blocked=Prepare({config={NavigationSpaces={room}},connections={},bindings={}},
    {coordinateUnit='map-percent',from={mapID=11,x=0,y=0},to={mapID=11,x=60,y=0}},
    {mapToWorld=Convert,movement=movement})
assert(Solve(blocked).status=='unknown','an exit is mandatory without collision coverage')
local worldRoom=Prepare({config={NavigationSpaces={room}},connections={},bindings={}},
    {from={space='world',instanceID=0,x=0,y=0},to={space='world',instanceID=0,x=600,y=0}},
    {movement=movement})
assert(Solve(worldRoom).status=='unknown','world-only endpoints still inherit existing building exits without a new UI-map requirement')
local aliases={}
for i=1,2 do aliases[i]={id='outdoor-alias-'..i,kind='outdoor',worldID=0,mapIDs={100+i},
    bounds={minX=-1,maxX=1000,minY=-1,maxY=1}} end
local worldOutside=Prepare({config={NavigationSpaces=aliases},connections={},bindings={}},
    {from={space='world',instanceID=0,x=0,y=0},to={space='world',instanceID=0,x=600,y=0}},
    {movement=movement})
assert(Solve(worldOutside).estimatedSeconds==13,'unrestricted presentation-map aliases do not require a native UI-map ID')
-- Isolated continent children are separate access regions; a child city shares
-- its declared parent region. No height field is imposed on outdoor maps.
local spaces={{id='island',kind='outdoor',worldID=0,mapIDs={50}},
    {id='west',kind='outdoor',worldID=0,mapIDs={11},parentSpace='island',
        bounds={minX=0,maxX=400,minY=0,maxY=100,minZ=-1000000,maxZ=1000000}},
    {id='east',kind='outdoor',worldID=0,mapIDs={22},parentSpace='island',
        bounds={minX=400,maxX=1000,minY=0,maxY=100,minZ=-1000000,maxZ=1000000}}}
local isolated=Prepare({config={NavigationSpaces=spaces,IsolatedContinents={[50]=true}},connections={},bindings={}},
    {coordinateUnit='map-percent',from={mapID=11,x=0,y=0},to={mapID=22,x=60,y=0}},
    {mapToWorld=Convert,movement=movement})
assert(Solve(isolated).status=='unknown','flight cannot bypass declared region isolation')
local oneFloor={coordinateUnit='map-percent',from={mapID=11,x=0,y=0,identity={floorID='upper'}},
    to={mapID=11,x=60,y=0}}
local floorUnknown=Prepare({config={},connections={},bindings={}},oneFloor,{mapToWorld=Convert,movement=movement})
assert(Solve(floorUnknown).status=='unknown','a required floor identity is not invented at the other endpoint')
local two=Facts();two.connections[1].from.noAutoconnect=true
local noAuto=Prepare(two,nil,{mapToWorld=Convert,movement=movement})
assert(noAuto.positions[noAuto.request.from].noAutoconnect==true,
    'matching the requested point cannot erase source noAutoconnect')
local original=Request();local capturedJob=assert(D.Prepare(Facts(),original,{clock=function()return 0 end}))
original.from.x=99
assert(Solve(F.Finish(capturedJob,1)).estimatedSeconds==19,'request captured before suspension')
local cancelled=assert(D.Prepare(Facts(),Request(),{clock=function()return 0 end}))
assert(cancelled:Cancel().status=='cancelled' and cancelled:Step(1).status=='cancelled')
assert(cancelled:Step(1).guidance==nil,'cancelled preparation cannot expose partial guidance')
local during
during=assert(D.Prepare(Facts(),Request(),{clock=function()return 0 end,mapToWorld=function()
    during:Cancel();return 0,1,2
end}))
assert(F.Finish(during,1).status=='cancelled','cancellation inside projection cannot publish partial data')
local ticks=0
local budget=assert(D.Prepare(Facts(),Request(),{clock=function()ticks=ticks+1;return ticks end,
    budgets={cpuMs=2,sliceMs=1,elapsedMs=5000}}))
assert(F.Finish(budget,1).status=='budget_exceeded')
assert(D.Prepare({},Request(),{})==nil)
assert(D.Prepare(Facts(),Request(),{clock=function()return 0 end,budgets=true})==nil)
