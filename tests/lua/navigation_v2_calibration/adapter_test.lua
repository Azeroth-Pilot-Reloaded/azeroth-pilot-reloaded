local F=dofile('tests/lua/navigation_v2_calibration/fixture.lua')
assert(loadfile('APR-Core/features/navigation/NavigationV2Calibration.lua'))('test',F.ns)
local A=F.ns.NavigationV2CalibrationAdapter
local time,reads=100,0
local api={GetTime=function()reads=reads+1;return time end,UnitGUID=function(unit)assert(unit=='player');return 'invented' end}
local identity=assert(A.Identity('Forever','build','desk',api))
assert(identity.character=='invented')
local root={oldTaxiDurations={flight=99},foreign={keep=true}}
local d={{key='taxi/flight/ride',kind='taxi',id='flight',component='ride',field='ride',defaultSeconds=20,currentSeconds=20},
    {key='taxi/flight/loading',kind='taxi',id='flight',component='loading',field='loading',defaultSeconds=2,currentSeconds=2}}
local a=assert(A.New({store=root,identity=identity,definitions=d,api=api}))
assert(#a:Pending()==0 and reads==0)
assert(a:SetManual('taxi/flight/ride',8))
assert(a:SetManual('taxi/flight/loading',5))
local update=a:Pending()
assert(#update==1 and update[1].kind=='taxi' and update[1].id=='flight')
assert(update[1].costs.ride==8 and update[1].costs.loading==5)
assert(a:Acknowledge(update[1]))
assert(#a:Pending()==0)
local exported=assert(a:Export(root))
assert(exported~=root and root.navigationV2Costs==nil and exported.foreign==root.foreign)
assert(exported.oldTaxiDurations==root.oldTaxiDurations)
local reloaded=assert(A.New({store=exported,identity=identity,definitions=d,api=api}))
assert(reloaded:Get('taxi/flight/ride')==8)
local owner,attempt={},{}
local handle=assert(a:Begin('taxi','flight',owner,attempt))
time=102;assert(a:Loading(handle,owner,attempt,true))
time=105;assert(a:Loading(handle,owner,attempt,false))
time=113;assert(a:Finish(handle,owner,attempt,true)==false,'manual masks both measured costs')
assert(reads==4 and #a:Pending()==0)
assert(a:Reset(nil,'manual'))
assert(a:Get('taxi/flight/ride')==10 and a:Get('taxi/flight/loading')==3)
assert(a:GetStats().clockReads==4)
-- Missing/secret clocks never become zero-second observations.
api.GetTime=nil
assert(a:Begin('taxi','flight',owner,attempt)==nil)
api.GetTime=function()return {}end;api.issecretvalue=function()return true end
assert(a:Begin('taxi','flight',owner,attempt)==nil)
assert(A.Identity('Forever','build','desk',api)==nil)
