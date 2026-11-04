local ns={}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Localization/World.lua'))('APR',ns)
local W=ns.NavigationV2World
local t=W.New()
local initial=t:GetSnapshot()
local changed,unknown=t:Observe({sequence=1,worldState='unknown'})
assert(changed==false,'freshness alone must not invalidate/restart global planning')
assert(not t:IsCurrent(initial) and t:IsPlanCurrent(initial))
local ready={sequence=2,worldState='ready',world=0,x=10,y=20,z=30}
local changed,first=t:Observe(ready)
assert(changed and not t:IsPlanCurrent(unknown))
for i=3,50 do
    ready.sequence,ready.x=i,10+i/1000
    local changed,current=t:Observe(ready)
    assert(changed==false and current.sequence==i)
    assert(t:IsPlanCurrent(first),'coordinate jitter is not semantic route invalidation')
    assert(not t:IsCurrent(first),'consumers can still reject an old precise position')
end
ready.sequence,ready.uiMapID=51,42
local changed,mapped=t:Observe(ready)
assert(changed==false and mapped.uiMapID==42,'projection refresh is distinct from global planning')
assert(t:IsPlanCurrent(first))
ready.sequence,ready.floor=52,'upper'
assert(t:Observe(ready)==true and not t:IsPlanCurrent(first))
local floor=t:GetSnapshot()
ready.sequence,ready.phase=53,'blue'
assert(t:Observe(ready)==true and not t:IsPlanCurrent(floor))
local phase=t:GetSnapshot()
ready.sequence,ready.worldState=54,'loading'
assert(t:Observe(ready)==true and not t:IsPlanCurrent(phase))
local loading=t:GetSnapshot()
ready.sequence=55
assert(t:Observe(ready)==false and t:IsPlanCurrent(loading))
ready.sequence,ready.worldState=56,'ready'
assert(t:Observe(ready)==true and not t:IsPlanCurrent(loading))
assert(not W.New():IsPlanCurrent(t:GetSnapshot()))
