local F=dofile('tests/lua/navigation_v2_retail_movement/fixture.lua')
local E=F.Edge
local walk=E('foot','s','g','walk',140)
local sky=E('sky','s','g','skyriding',600)
local planner=F.New({walk,sky})
F.Path(F.Finish(planner:Plan({from='s',to='g'}),1),{'sky'},13)
assert(F.Finish(planner:Plan({from='g',to='s'}),1).status=='no_path','no implicit reverse flight')
for _,extra in ipairs({{groundOnly=true},{requiresExit=true},{canFly='unavailable'}})do
    local restricted=F.New({walk,E('blocked','s','g','skyriding',60,extra)})
    F.Path(F.Finish(restricted:Plan({from='s',to='g'}),1),{'foot'},20)
end
local cave=F.New({E('door','room','door','walk',7,{groundOnly=true}),
    E('exit','door','s','walk',7,{groundOnly=true}),sky,
    E('wall','room','g','skyriding',1,{requiresExit=true})})
F.Path(F.Finish(cave:Plan({from='room',to='g'}),1),{'door','exit','sky'},15)
sky.requirements={access={{key='airspace-open',allowed=true}}}
local conditional=F.New({walk,sky},{initialMode='walk',mountOwned=true,mountUsable=true,
    skyridingOwned=true,skyridingUsable=true,canMountHere=true,canSkyridingHere=true},
    {conditionObservation={sequence=1,worldState='ready',access={}}})
F.Path(F.Finish(conditional:Plan({from='s',to='g'}),1),{'foot'},20)
assert(conditional:ObserveConditions({sequence=2,worldState='ready',access={['airspace-open']=true}}))
F.Path(F.Finish(conditional:Plan({from='s',to='g'}),1),{'sky'},13)
sky.requirements=nil
local pending=planner:Plan({from='s',to='g'});assert(pending:Step(1).status=='running')
assert(planner:SetMovement(F.Retail.New(F.Observation({skyridingOwned=false}))))
assert(F.Finish(pending,1).status=='stale')
F.Path(F.Finish(planner:Plan({from='s',to='g'}),1),{'foot'},20)
assert(not planner:SetMovement(F.Retail.New(F.Observation({skyridingOwned=false}))))
assert(planner:SetMovement({})==nil)
local cancelled=planner:Plan({from='s',to='g'});assert(cancelled:Cancel().status=='cancelled')
assert(cancelled:Step(1).status=='cancelled')
-- Switching public profiles still accepts Forever, with its level contract intact.
local forever=assert(F.ns.NavigationV2Forever.New({level=39,initialMode='walk',
    mountOwned=true,mountUsable=true,canMountHere=true}))
assert(planner:SetMovement(forever))
local ground=F.New({walk,E('ride','s','g','mount',14)})
assert(ground:SetMovement(forever))
F.Path(F.Finish(ground:Plan({from='s',to='g'}),1),{'foot'},20)
