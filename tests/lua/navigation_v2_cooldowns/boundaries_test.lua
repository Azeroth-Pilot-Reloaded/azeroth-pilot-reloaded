local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local d,o=F.Declarations(),F.Observation()
local g={complete=true,nodes={'cave','town'},edges={{id='return',from='town',to='cave',seconds=1}}}
local function Plan()
    local p=assert(F.Library.New(g,F.Options(d,o)))
    return F.Base.Finish(p:Plan({from='cave',to='town',via={'town','cave'}}))
end
d[1].kind='item';d[1].spellID=nil;d[1].itemID=904;d[1].consumable=true;d[1].itemResourceId='recall_stone'
d[1].moneyCopper=0;d[1].reagents={};d[1].cooldownSeconds=0
o.actions.recall={owned=true,loaded=true,usable=true,readyAt=0};o.items[904]=1
assert(Plan().status=='no_path','A consumed item cannot be used twice even after an arbitrary wait')
o.items[904]=nil;assert(Plan().status=='unknown')
o.items[904]=2;assert(Plan().estimatedSeconds==11)
-- Non-unit/missing recharge cannot be fabricated; known remaining charges can.
d,o=F.Declarations(),F.Observation();d[1].chargeBased=true;d[1].moneyCopper=0;d[1].reagents={}
local a=o.actions.recall;a.charges=2;a.maxCharges=3;a.rechargeRate=2;a.rechargeSeconds=10;a.rechargeStart=99
assert(Plan().estimatedSeconds==11,'Uncertain future regeneration does not erase two known usable charges')
a.charges=1
assert(Plan().status=='unknown','No replenishment forecast for a non-unit playback rate')
a.rechargeRate=1;a.rechargeStart=0
assert(Plan().status=='unknown','Zero means no observed active recharge')
a.rechargeStart=80
assert(Plan().status=='unknown','An already expired recharge with a partial public count is inconsistent')
-- Missing clock, absent data and overflow stay explicit without blocking walking.
local normal={complete=true,nodes={'cave','town'},edges={{id='normal',from='cave',to='town',seconds=30}}}
for _,field in ipairs({'readyAt','loaded','known','usable'}) do
    d,o=F.Declarations(),F.Observation();o.actions.recall[field]=nil
    local p=assert(F.Library.New(normal,F.Options(d,o)))
    assert(F.Base.Finish(p:Plan({from='cave',to='town'})).estimatedSeconds==30)
end
d,o=F.Declarations(),F.Observation();d[1].cooldownSeconds=1e308
o.actions.recall.readyAt=1e308
local p=assert(F.Library.New(normal,F.Options(d,o)))
assert(F.Base.Finish(p:Plan({from='cave',to='town'})).estimatedSeconds==30)
