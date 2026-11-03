local F=dofile('tests/lua/navigation_v2_calibration/fixture.lua')
assert(loadfile('APR-Core/features/navigation/NavigationV2Calibration.lua'))('test',F.ns)
local A=F.ns.NavigationV2CalibrationAdapter
local planner={portals={byId={gate={loadingSeconds=3}}},personal={byId={recall={loadingSeconds=4,useSeconds=7}}},
    taxi={byId={flight={costs={ride=8,loading=2}}},settings={flight={ride=9,fareCopper=13}},routes={flight={rideSeconds=11}}},
    scheduled={byId={ferry={costs={ride=12,loading=5}}}}}
local definitions=A.Describe(planner,{scheduledOverrides={ferry={ride=6}}})
assert(#definitions==6)
local a=assert(A.New({definitions=definitions,identity={client='Forever',character='x',computer='y',build='z'},store={foreign=true}}))
assert(a:Get('taxi/flight/ride')==9 and a:Get('scheduled/ferry/ride')==6)
assert(a:Get('personal/recall/loading')==4 and a:Get('personal/recall/use')==nil)
assert(#a:Pending()==0)
assert(not a:Reset(nil,'all'),'configured manual settings remain explicit')
assert(a:Get('taxi/flight/ride')==9)
assert(a:Export().foreign==true,'omitting latest root must not lose old fields')
assert(a:Begin({},'flight',{}, {},100)==nil)
assert(a:Acknowledge({kind={},id='flight',costs={ride=7}})==nil)
assert(a:SetManual('taxi/flight/ride',7))
local update=a:Pending()[1]
assert(a:SetManual('taxi/flight/ride',8))
assert(a:Acknowledge(update)==nil,'old applied callback does not acknowledge a newer value')
assert(a:Pending()[1].costs.ride==8)
update.costs.ride=1
assert(a:Pending()[1].costs.ride==8,'isolated setter payload')
local opts={definitions={{key='different-key',kind='taxi',id='flight',component='ride',field='ride',defaultSeconds=20}},
    identity={client='Forever',character='x',computer='y',build='z'}}
assert(A.New(opts)==nil,'binding keys have one canonical spelling')
planner.taxi.settings={}
local existing=A.Describe(planner)
local legacy=assert(A.New({definitions=existing,identity={client='Forever',character='x',computer='y',build='z'}}))
assert(legacy:Get('taxi/flight/ride')==11 and #legacy:Pending()==0,'known existing duration is preserved on opt-in')
