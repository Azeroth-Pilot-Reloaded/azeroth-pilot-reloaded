local F=dofile('tests/lua/navigation_v2_calibration/fixture.lua')
local c=F.New()
assert(c:SetManual('taxi/flight/ride',20)==false and c:GetRevision()==0)
local h,o,a=F.Begin(c,100)
assert(not c:Finish(h,o,a,110,true),'manual masks measured ride')
assert(c:GetRevision()==0)
assert(c:Reset('taxi/flight/ride','manual'))
assert(c:Get('taxi/flight/ride')==10 and c:GetRevision()==1)
h,o,a=F.Begin(c,200)
assert(not c:Finish(h,o,a,210,true),'equal sample no revision')
h,o,a=F.Begin(c,300)
assert(c:Finish(h,o,a,400,true))
assert(c:Get('taxi/flight/ride')==11.25,'EMA clamps huge outlier before weighting')
assert(c:GetRevision()==2)
assert(c:Reset('taxi/flight/ride','measured'))
assert(c:Get('taxi/flight/ride')==20 and c:GetRevision()==3)
assert(not c:Reset(nil,'all') and c:GetRevision()==3,'reset with no effect is idempotent')
local store=c:Export()
for _,identity in ipairs({
    {client='Retail',character='invented-character',computer='desk',build='test-build'},
    {client='Forever',character='other-character',computer='desk',build='test-build'},
    {client='Forever',character='invented-character',computer='other-pc',build='test-build'},
    {client='Forever',character='invented-character',computer='desk',build='other-build'}}) do
    local isolated=F.New(store,identity)
    assert(isolated:Get('taxi/flight/ride')==20)
    isolated:SetManual('taxi/flight/ride',7)
    local nextStore=isolated:Export()
    assert(F.New(nextStore):Get('taxi/flight/ride')==20,'other identity unchanged')
end
local zero=F.New({version=0,profiles={Forever={['test-build']={['invented-character']={desk={costs={['taxi/flight/loading']=0}}}}}}})
h,o,a=F.Begin(zero,100)
zero:Loading(h,o,a,true,101);zero:Loading(h,o,a,false,106)
assert(zero:Finish(h,o,a,120,true))
assert(zero:Get('taxi/flight/loading')==5,'zero legacy estimate must not permanently suppress learning')
for _,value in ipairs({-1,math.huge,0/0,'5',false,{}}) do
    assert(c:SetManual('taxi/flight/ride',value)==nil)
end
assert(c:SetManual('taxi/flight/ride',0)==nil,'taxi ride contract requires positive duration')
local badCost={measuredSeconds=math.huge,manualSeconds='broken',samples=-1}
local badLeaf={costs={['taxi/flight/ride']=badCost}}
local malformed=F.New({version=1,profiles={Forever={['test-build']={['invented-character']={desk=badLeaf}}}}})
assert(malformed:Get('taxi/flight/ride')==20)
