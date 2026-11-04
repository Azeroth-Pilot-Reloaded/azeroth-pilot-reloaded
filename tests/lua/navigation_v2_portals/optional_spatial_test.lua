local F=dofile('tests/lua/navigation_v2_portals/fixture.lua')
local _,ns=F.Load()
local P=ns.NavigationV2Portals
local declarations=F.Catalog()
declarations[1].phase=nil;declarations[1].destination.phase=nil
local c=assert(P.New(declarations),'A portal need not declare a phase constraint')
assert(c.byId.door.phase==nil and c.byId.door.destination.phase==nil,'No fabricated phase')
assert(c:Observe({revision=1,portals={door={open=true,access=true}}}))
assert(c:Edge('gate',1).access=='available')
assert(c:Observe({revision=2,phase='observed',portals={door={open=true,access=true}}})==false)
assert(c:Edge('gate',1).access=='available','An unrelated observed phase is not a restriction')
assert(c:Observe({revision=3,portals={door={open=true}}}))
assert(c:Edge('gate',1).access=='unknown','Access evidence stays mandatory')
assert(c:Observe({revision=4,portals={door={open=false,access=true}}}))
assert(c:Edge('gate',1).access=='unavailable')
assert(c:Observe({revision=4,portals={door={open=true,access=true}}})==false)
assert(c:Edge('gate',1).access=='unavailable','Stale revisions cannot reopen')

declarations=F.Catalog();declarations[1].destination.phase=nil
c=assert(P.New(declarations))
assert(c:Observe({revision=1,portals={door={open=true,access=true}}})==false)
assert(c:Edge('gate',1).access=='unknown','A declared origin phase still requires observation')
assert(c:Observe({revision=2,phase='red',portals={door={open=true,access=true}}}))
assert(c:Edge('gate',1).access=='unavailable')
assert(c:Observe(F.Observation(3)))
assert(c:Edge('gate',1).access=='available')
for _,key in ipairs({'origin','destination'}) do
    for _,bad in ipairs({false,'',7,{}}) do
        declarations=F.Catalog()
        if key=='origin' then declarations[1].phase=bad else declarations[1].destination.phase=bad end
        assert(P.New(declarations)==nil,'Invalid declared phase must still fail')
    end
end
local revision=c.observationRevision
assert(c:Observe({revision=4,phase=false,portals={door={open=true,access=true}}})==nil)
assert(c.observationRevision==revision and c:Edge('gate',1).access=='available')
