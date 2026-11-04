local ns = {}
local Forever = assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Movement/Forever.lua'))('APR', ns)
local function profile(level, owned, usable, settings, initial)
    return assert(Forever.New({level=level, mountOwned=owned, mountUsable=usable,
        initialMode=initial or 'walk'}, settings))
end
local function movement(mode, distance, canMount)
    return {seconds=999,access='available',movement=assert(Forever.CaptureMovement({
        mode=mode,distance=distance,canMount=canMount}))}
end
local ride=movement('mount',112,'available')
local p=profile(39,true,true)
assert(p:Evaluate(ride,'walk').access=='unavailable', 'level 39 cannot mount')
p=profile(40,true,true)
local leg=p:Evaluate(ride,'walk')
assert(leg.access=='available' and leg.mode=='mount')
assert(math.abs(leg.seconds-13)<0.00001, '112 yards at 11.2 plus 3 seconds mounting')
assert(leg.transitionSeconds==3)
assert(p:Evaluate(ride,'mount').seconds==10, 'do not mount on every edge')
assert(profile(40,false,true):Evaluate(ride,'walk').access=='unavailable')
assert(profile(40,true,false):Evaluate(ride,'walk').access=='unavailable')
assert(profile(40,nil,true):Evaluate(ride,'walk').access=='unknown')
assert(profile(nil,true,true):Evaluate(ride,'walk').access=='unknown')
assert(profile(40,true,nil):Evaluate(ride,'walk').access=='unknown')
local cave=movement('walk',14)
local indoor=p:Evaluate(cave,'mount')
assert(indoor.mode=='walk' and indoor.seconds==2 and indoor.transitionSeconds==0)
assert(p:Evaluate(movement('mount',112,'unavailable'),'walk').access=='unavailable')
assert(p:Evaluate(movement('mount',112),'walk').access=='unknown')
assert(p:Evaluate(movement('mount',112,'unavailable'),'mount').access=='available',
    'a no-summon spot is distinct from no-riding geometry')
local lake=p:Evaluate(movement('swim',47),'mount')
assert(lake.mode=='swim' and lake.seconds==10.75)
assert(p:Evaluate(ride,'swim').seconds==13.75)
local custom=profile(40,true,true,{walkSpeed=2,mountSpeed=4,swimSpeed=1,
    mountSeconds=5,dismountSeconds=2,enterSwimSeconds=4,exitSwimSeconds=3})
assert(custom:Evaluate(ride,'swim').seconds==36)
assert(custom:Evaluate(cave,'mount').seconds==9)
assert(profile(40,true,true,{mountSpeed=false}):Evaluate(ride,'walk').access=='unknown')
assert(profile(40,true,true,{mountSeconds=false}):Evaluate(ride,'walk').access=='unknown')
local static=p:Evaluate({seconds=6,access='available'},'mount')
assert(static.mode=='walk' and static.seconds==6, 'legacy cost never implies mount geometry')
local source={level=40,mountOwned=true,mountUsable=true,initialMode='walk'}
local options={mountSpeed=4}
p=assert(Forever.New(source,options)); source.mountOwned=false; options.mountSpeed=999
assert(p:Evaluate(movement('mount',40,'available'),'walk').seconds==13,'capture caller state')
for _,value in ipairs({-1,0,math.huge,0/0,'fast'}) do
    assert(not Forever.New(source,{mountSpeed=value}))
end
assert(not Forever.CaptureMovement({mode='fly',distance=10}))
assert(not Forever.CaptureMovement({mode='walk',distance=-1}))
assert(not Forever.CaptureMovement({mode='walk',distance=1,canMount=true}))
assert(not Forever.New({level=-1}))
assert(not Forever.New({mountOwned='yes'}))
assert(not Forever.New({initialMode='fly'}))
assert(assert(Forever.New({})).initialMode==nil, 'unknown current mode stays unknown')
assert(ns.NavigationV2Forever==Forever)
assert(Forever.IsProfile(p) and not Forever.IsProfile({}))
local first=profile(40,true,true)
assert(Forever.Same(first,profile(40,true,true)))
assert(not Forever.Same(first,profile(39,true,true)))
assert(not Forever.Same(first,profile(40,true,true,{mountSeconds=4})))
assert(not Forever.Same(first,profile(40,true,true,nil,'mount')))
