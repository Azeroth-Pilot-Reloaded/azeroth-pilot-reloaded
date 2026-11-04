local F=dofile('tests/lua/navigation_v2_retail_movement/fixture.lua')
local D=assert(F.ns.NavigationV2RetailData)
local function Point(x,y,world)
    return {space='world',instanceID=world or 0,x=x,y=y,noAutoconnect=true}
end
local function Passage()
    return {id='invented-ground-entry',kind='passage',costMode='ground',
        from=Point(0,0),to=Point(30,40)}
end
local function Prepare(record,options,config)
    options=options or {};options.clock=function()return 0 end
    if options.walkSpeed==nil then options.walkSpeed=5 end
    local request={from=record.from,to=record.to}
    local job=assert(D.Prepare({config=config or {},connections={record},bindings={}},request,options))
    local prepared=F.Finish(job,1)
    assert(prepared.status=='complete',prepared.reason)
    return prepared
end
local function Solve(prepared,reverse)
    local options=prepared.options;options.clock=function()return 0 end;options.profileClock=function()return 0 end
    local planner=assert(F.Library.New(prepared.graph,options))
    local request=prepared.request
    if reverse then request={from=request.to,to=request.from} end
    return F.Finish(planner:Plan(request),1)
end
local source=Passage()
local prepared=Prepare(source)
local result=Solve(prepared)
assert(result.status=='complete' and result.estimatedSeconds==10 and #result.segments==1,
    'same-world declared ground passage must cost50yards / explicit5yards-per-second')
assert(result.segments[1].edgeId=='declared:invented-ground-entry:forward')
assert(Solve(prepared,true).status=='unknown','estimated ground cost cannot add a reverse declaration')
source.bidirectional=true
assert(Solve(Prepare(source),true).estimatedSeconds==10)
assert(Solve(Prepare(source,{walkSpeed=10})).estimatedSeconds==5,'use the supplied walking model')
assert(source.seconds==nil and source.from.z==nil and source.to.z==nil,
    'estimation must not write seconds or invent altitude in source data')
local mounted=assert(F.Retail.New(F.Observation()))
assert(Solve(Prepare(source,{movement=mounted})).estimatedSeconds==10,
    'the declared ground leg cannot become a mounted skyriding shortcut')
source.requirements={quest=42001}
assert(Solve(Prepare(source)).status=='unknown')
local yes={conditionObservation={sequence=1,worldState='ready',quests={[42001]=true}}}
assert(Solve(Prepare(source,yes)).estimatedSeconds==10)
yes.conditionObservation.quests[42001]=false
assert(Solve(Prepare(source,yes)).status=='unknown','estimated cost cannot erase the actual access condition')
source.requirements=nil
source.seconds=0
assert(Solve(Prepare(source)).estimatedSeconds==0,'declared zero overrides the distance once')
source.seconds=13
assert(Solve(Prepare(source)).estimatedSeconds==13,'declared total is not added to the estimate')
for _,invalid in ipairs({-1,false,'13'})do
    source.seconds=invalid
    assert(Solve(Prepare(source)).status=='unknown','invalid explicit cost cannot be replaced by an estimate')
end
source.seconds=nil;source.to.instanceID=1
assert(Solve(Prepare(source)).status=='unknown','different world frames cannot provide a distance')
source.seconds=0
assert(Solve(Prepare(source)).estimatedSeconds==0,'explicit transition cost does not require same-world geometry')
source.seconds=nil;source.to.instanceID=0
source.path={Point(0,40)}
assert(Solve(Prepare(source)).status=='unknown','a declared path cannot be silently replaced by its chord')
source.path=nil;source.via={Point(0,40)}
assert(Solve(Prepare(source)).status=='unknown','declared via geometry must not be skipped')
source.via=nil;source.kind='boat'
assert(Solve(Prepare(source)).status=='unknown','ground cost projection is scoped to declared passages')
source.kind='passage';source.costMode='other'
assert(Solve(Prepare(source)).status=='unknown')
source.costMode='ground';source.from.x=-1e308;source.to.x=1e308
assert(Solve(Prepare(source)).status=='unknown','overflowing geometry cannot yield a usable infinite cost')
source.from.x=0
source.costMode='ground';source.to.x=0;source.to.y=0
source.to.accessKey='other-side'
assert(Solve(Prepare(source)).estimatedSeconds==0,'real zero planar distance is valid for distinct declared access endpoints')
-- Normalized map values only yield yards through the existing conversion seam.
local mapped={id='invented-map-entry',kind='passage',costMode='ground',
    from={space='map',uiMapID=11,x=0,y=0,noAutoconnect=true},
    to={space='map',uiMapID=22,x=.03,y=.04,noAutoconnect=true}}
assert(Solve(Prepare(mapped)).status=='unknown','map fractions are not world yards without conversion')
mapped.seconds=0
assert(Solve(Prepare(mapped)).estimatedSeconds==0,'explicit zero also works without a world conversion')
mapped.seconds=nil
local conversion={mapToWorld=function(_,x,y)return 0,x*1000,y*1000 end}
assert(Solve(Prepare(mapped,conversion)).estimatedSeconds==10)
assert(mapped.to.x==.03 and mapped.to.y==.04 and mapped.to.instanceID==nil,
    'projected geometry does not mutate the declaration')
assert(Solve(Prepare(mapped,{mapToWorld=function(map,x,y)return map==11 and 0 or 1,x*1000,y*1000 end})).status=='unknown')
assert(Solve(Prepare(mapped,{mapToWorld=function()return 0,nil,40 end})).status=='unknown')
assert(Solve(Prepare(mapped,{mapToWorld=function()error('unavailable')end})).status=='unknown')
-- A required room exit must use the ground declaration before free approach.
local door=Passage();door.from.noAutoconnect=nil;door.to.noAutoconnect=nil
local data={config={NavigationSpaces={{id='invented-room',kind='building',worldID=0,requiresExit=true,
    bounds={minX=-31,maxX=1,minY=-41,maxY=1}}}},connections={door},bindings={}}
local request={from=Point(-30,-40),to=Point(30,40)};request.from.noAutoconnect=nil;request.to.noAutoconnect=nil
local job=assert(D.Prepare(data,request,{clock=function()return 0 end,walkSpeed=5}))
local exit=Solve(F.Finish(job,1))
assert(exit.status=='complete' and exit.estimatedSeconds==20 and #exit.segments==2)
assert(exit.segments[2].edgeId=='declared:invented-ground-entry:forward',
    'known local distance cannot bypass the mandatory declared exit')
