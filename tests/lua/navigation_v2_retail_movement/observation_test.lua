local F=dofile('tests/lua/navigation_v2_retail_movement/fixture.lua')
APR={GAME_VERSIONS={Retail='retail',Forever='forever'},GetGameVersion=function()return 'retail' end}
local A=assert(loadfile('APR-Core/features/navigation/NavigationV2Movement.lua'))('APR',F.ns)
local s={owned=true,usable=true,localUsable=true,active=false,gliding=false,canGlide=false,
    flyable=true,indoors=false,swim=false,forward=100}
local calls=0
local api={UnitLevel=function()return 10 end,IsSwimming=function()return s.swim end,
    IsFlying=function()return s.gliding end,
    IsAdvancedFlyableArea=function()return s.flyable end,IsIndoors=function()return s.indoors end,
    GetUnitSpeed=function()return 0,7,100,4.7 end,
    C_PlayerInfo={GetGlidingInfo=function()return s.gliding,s.canGlide,s.forward end},
    C_MountJournal={GetMountIDs=function()return {21} end,
        GetMountInfoByID=function()calls=calls+1;return 'Invented',1,1,s.active,s.usable,1,false,false,nil,false,s.owned,21,false end,
        GetMountInfoExtraByID=function()return nil,'','',false,900001 end,
        GetMountUsabilityByID=function(_,indoors)if indoors then return s.localUsable end;return s.usable end,
        GetCollectedDragonridingMounts=function()if s.owned then return {21} end;return {} end,
        IsDragonridingUnlocked=function()error('flight-style switch unlock is not flight permission')end}}
local p,o=A.Capture(api)
assert(F.Retail.IsProfile(p) and o.client=='retail' and o.initialMode=='walk')
assert(o.skyridingOwned and o.skyridingUsable and o.canSkyridingHere)
local edge={movement={mode='skyriding',distance=600,canMount='available'}}
assert(p:Evaluate(edge,'walk',true).seconds==13)
assert(p.costs.skyridingSpeed==60,'instantaneous speed100 cannot calibrate future flight')
local _,same=A.Capture(api);assert(A.Same(o,same))
s.active=true;s.canGlide=true;s.gliding=true
local flying,flight=A.Capture(api)
assert(flight.initialMode=='skyriding' and flying.initialMode=='skyriding')
assert(flying.costs.walkSpeed==7 and flying.costs.mountSpeed==14)
s.forward=3;assert(A.Same(flight,select(2,A.Capture(api))))
s.indoors=true
local indoor,inside=A.Capture(api)
assert(inside.canSkyridingHere==false and not A.Same(flight,inside))
assert(indoor:Evaluate(edge,'walk',true).access=='unavailable')
assert(indoor:Evaluate(edge,'walk',false).access=='available')
s.indoors=false;s.flyable=nil
assert(A.Observe(api).canSkyridingHere==nil)
s.flyable=true;s.active=false;s.gliding=false;s.canGlide=false;s.localUsable=false
local blocked=A.Observe(api)
assert(blocked.skyridingUsable==true and blocked.canSkyridingHere==false,
    'local rejection must not destroy known mount capability')
s.usable=false
assert(A.Observe(api).skyridingUsable==nil,'local usability false is not a global inability proof')
s.usable=true;s.localUsable=true;s.owned=false
assert(A.Observe(api).skyridingOwned==false)
s.gliding=true;s.canGlide=true
assert(A.Observe(api).initialMode==nil,'gliding without a collected active mount is not mounted skyriding')
s.gliding=false;s.canGlide=false;s.owned=true
api.C_MountJournal.GetCollectedDragonridingMounts=function()error('not ready')end
assert(A.Observe(api).skyridingOwned==nil)
api.C_MountJournal.GetCollectedDragonridingMounts=nil
assert(A.Observe(api).canSkyridingHere==nil)
local before=calls;local loading=A.Observe(api,true)
assert(loading.loading and loading.initialMode==nil and calls==before)
assert(A.Observe({}).skyridingOwned==nil)
APR.GetGameVersion=function()return 'forever' end
assert(F.ns.NavigationV2Forever.IsProfile(A.Capture(api)))
