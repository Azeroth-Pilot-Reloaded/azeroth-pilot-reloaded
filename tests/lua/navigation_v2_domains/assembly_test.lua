local F=dofile('tests/lua/navigation_v2_domains/fixture.lua')
local NewPositionJob=F.ns.NavigationV2DomainGraph.Plan
assert(type(NewPositionJob)=='function','The domain module position entry must own the whole pipeline')
local data=F.Geography()
local request={from=F.Point(0),to=F.Point(21,1,703)}
local passages={
    {id='entry',kind='walk',costMode='ground',bidirectional=false,
        from={space='world',instanceID=0,x=14,y=0,uiMapID=701},
        to={space='world',instanceID=0,x=21,y=0,uiMapID=702,noAutoconnect=true}},
    {id='exit',kind='walk',costMode='ground',bidirectional=false,
        from={space='world',instanceID=0,x=21,y=0,uiMapID=702,noAutoconnect=true},
        to={space='world',instanceID=0,x=28,y=0,uiMapID=702}},
}
local transport={id='crossing',kind='boat',seconds=17,bidirectional=false,
    from={space='world',instanceID=0,x=42,y=0,uiMapID=702},
    to={space='world',instanceID=1,x=0,y=0,uiMapID=703}}
local time={wall=0,cpu=0}
local options={geography=data,transports={routes={crossing=transport},excluded={}},passages=passages,
    walkSpeed=7,clock=function()return time.wall end,profileClock=function()return time.cpu end,
    transportAccess={crossing='available'}}
local job=assert(NewPositionJob(request,options))
local result=F.Finish(job,1)
assert(result.status=='complete' and result.estimatedSeconds==26 and result.reason=='optimal_known_graph')
assert(result.positions and result.provenance.scope=='declared_model')
local used={}
for _,segment in ipairs(result.segments) do used[segment.edgeId or segment.id]=true end
assert(#result.nodes>=6,'No isolation/noAutoconnect shortcut may skip the passage')
assert(result.from.x==0 and result.to.x==21 and result.from.z==nil)
assert(job:Step(1).estimatedSeconds==26,'Terminal jobs do not rerun')
options.passages={passages[1]}
assert(F.Finish(assert(NewPositionJob(request,options))).status=='unknown')
options.passages=passages;options.transportAccess={crossing='unknown'}
assert(F.Finish(assert(NewPositionJob(request,options))).status=='unknown')
options.transportAccess={crossing='available'}
job=assert(NewPositionJob(request,options));job:Cancel()
assert(job:Step(64).status=='cancelled')
