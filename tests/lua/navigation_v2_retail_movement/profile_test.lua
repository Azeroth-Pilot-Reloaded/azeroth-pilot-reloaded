local F=dofile('tests/lua/navigation_v2_retail_movement/fixture.lua')
local R=F.Retail
local p=assert(R.New(F.Observation()))
local function Edge(fields)
    local m={mode='skyriding',distance=600,canMount='available'}
    for k,v in pairs(fields or {})do m[k]=v end
    return {access='available',movement=assert(R.CaptureMovement(m))}
end
local e=Edge({rise=30,fall=45})
local result=assert(p:Evaluate(e,'walk',true))
assert(result.access=='available' and result.mode=='skyriding')
assert(result.seconds==16 and result.transitionSeconds==3) -- 600/60+30/15+45/45+3
assert(p:Evaluate(e,'skyriding',false).seconds==13)
assert(R.New(F.Observation({level=1})):Evaluate(e,'walk',true).access=='available',
    'Retail cannot inherit the Forever level40 rule')
for _,fields in ipairs({{groundOnly=true},{requiresExit=true},{canFly='unavailable'}})do
    assert(p:Evaluate(Edge(fields),'skyriding',false).access=='unavailable')
end
assert(p:Evaluate(Edge({canFly='unknown'}),'walk',false).access=='unknown')
assert(p:Evaluate(Edge({canMount='unavailable'}),'walk',false).access=='unavailable')
local indoors=assert(R.New(F.Observation({canSkyridingHere=false,canMountHere=false})))
assert(indoors:Evaluate(e,'walk',true).access=='unavailable')
assert(indoors:Evaluate(e,'walk',false).access=='available',
    'the current indoor observation must not forbid a future outdoor takeoff')
for _,fields in ipairs({{skyridingOwned=false},{skyridingUsable=false}})do
    local denied=assert(R.New(F.Observation(fields)))
    assert(denied:Evaluate(e,'walk',false).access=='unavailable')
end
local unknown=F.Observation();unknown.skyridingUsable=nil
assert(R.New(unknown):Evaluate(e,'walk',false).access=='unknown')
local cost=assert(R.New(F.Observation(),{skyridingSpeed=30,mountSeconds=5}))
assert(cost:Evaluate(e,'walk',true).seconds==28)
assert(R.New(F.Observation(),{skyridingSpeed=false}):Evaluate(e,'walk',false).access=='unknown')
assert(R.New(F.Observation(),{mountSeconds=false}):Evaluate(e,'walk',false).access=='unknown')
assert(R.New(F.Observation(),{landingSeconds=4}):Evaluate({seconds=2},'skyriding',false).seconds==6)
assert(R.New(F.Observation(),{swimSpeed=7}):Evaluate(Edge({mode='swim',distance=14}),'walk',false).seconds==2.75)
assert(p:Evaluate(e,nil,true)==nil)
local loading=assert(R.New(F.Observation({loading=true})))
assert(loading.initialMode==nil and loading.skyridingAccess=='unknown')
assert(R.Same(p,R.New(F.Observation())))
assert(not R.Same(p,cost))
assert(not R.Same(p,F.ns.NavigationV2Forever.New({level=40,initialMode='walk'})))
assert(R.New({initialMode='soar'})==nil)
assert(R.New(F.Observation({canMountHere='yes'}))==nil)
for _,settings in ipairs({{skyridingSpeed=0},{climbSpeed=-1},{bogus=1},{landingSeconds=0/0}})do
    assert(R.New(F.Observation(),settings)==nil)
end
for _,fields in ipairs({{mode='soar'},{distance=-1},{rise=-1},{fall=math.huge},
    {groundOnly='yes'},{canFly=true},{requiresExit=1},{extra=4}})do
    local m={mode='skyriding',distance=0}
    for k,v in pairs(fields)do m[k]=v end
    assert(R.CaptureMovement(m)==nil)
end
local original={mode='skyriding',distance=60};local captured=assert(R.CaptureMovement(original))
original.distance=600;assert(captured.distance==60)
