local F=dofile('tests/lua/navigation_v2_calibration/fixture.lua')
local c=F.New()
for n=1,1100 do
    local h,o,a=F.Begin(c,n*50)
    c:Loading(h,o,a,true,n*50+1)
    c:Loading(h,o,a,false,n*50+3)
    assert(not c:Finish(h,o,a,n*50+22,true),'all effective costs equal fallback')
end
assert(c:GetRevision()==0 and c:GetStats().accepted==1100 and c.active==nil)
local store=c:Export()
local costs=store.profiles.Forever['test-build']['invented-character'].desk.costs
assert(costs['taxi/flight/ride'].samples==1000 and costs['taxi/flight/loading'].samples==1000)
local count=0;for _ in pairs(costs)do count=count+1 end
assert(count==2,'no per-attempt history')
local defs={}
for n=1,2048 do defs[n]={key='synthetic-'..n,component='loading',defaultSeconds=2}end
local options={identity={client='Forever',build='test',character='test',computer='test'},definitions=defs}
assert(F.Core.New(options))
defs[2049]={key='overflow',component='loading',defaultSeconds=2}
assert(F.Core.New(options)==nil)
options.definitions={[1]=defs[1],[3]=defs[3]}
assert(F.Core.New(options)==nil,'sparse lists rejected')
