local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local function Plan(d,o,g,via,extra)
    local options=F.Options(d,o)
    for key,value in pairs(extra or {}) do options[key]=value end
    local p=assert(F.Library.New(g,options))
    return F.Base.Finish(p:Plan({from='cave',to='town',via=via or {}})),p
end
local function Loop()
    return {complete=true,nodes={'cave','town'},edges={
        {id='normal',from='cave',to='town',seconds=100},
        {id='return',from='town',to='cave',seconds=2}}}
end
local d,o=F.Declarations(),F.Observation()
d[1].moneyCopper=0;d[1].reagents={};d[1].cooldownSeconds=10
local r=Plan(d,o,Loop(),{'town','cave'})
assert(r.estimatedSeconds==15 and r.segments[3].costDetail.waitSeconds==3,
    'Cooldown starts at use, not after cast/loading; the preceding legs consume seven seconds')
assert(r.resourcesSpent['personal:recall']==2)
d[1].cooldownSeconds=0
local g={complete=true,nodes={'cave','gate','town'},edges={{id='approach',from='cave',to='gate',seconds=6},
    {id='normal',from='cave',to='town',seconds=50}}}
d[1].from='gate';o.actions.recall.readyAt=110
r=Plan(d,o,g)
assert(r.estimatedSeconds==15 and r.segments[2].costDetail.waitSeconds==4,
    'Wait after a known authored approach, not before it')
-- Shared groups start their next cooldown at the selected action's actual use.
d,o=F.Declarations(),F.Observation();d[1].moneyCopper=0;d[1].reagents={};d[1].cooldownGroup='recalls'
d[1].cooldownSeconds=10
d[2]=F.Declarations()[1];d[2].id='other';d[2].spellID=903;d[2].cooldownGroup='recalls'
d[2].moneyCopper=0;d[2].reagents={};d[2].cooldownSeconds=10
o.actions.other={known=true,loaded=true,usable=true,readyAt=0}
r=Plan(d,o,Loop(),{'town','cave'})
assert(r.estimatedSeconds==15,'Distinct abilities cannot allocate a second shared cooldown')
o.actions.other.readyAt=120
r=Plan(d,o,Loop(),{'town','cave'})
assert(r.estimatedSeconds==35,'All public observations constrain the single shared group')
-- Recharge uses public metadata, never the unrelated configured cooldown.
d,o=F.Declarations(),F.Observation();d[1].moneyCopper=0;d[1].reagents={};d[1].chargeBased=true
local a=o.actions.recall;a.charges=1;a.maxCharges=2;a.rechargeStart=99;a.rechargeSeconds=10;a.rechargeRate=1
r=Plan(d,o,Loop(),{'town','cave'})
assert(r.estimatedSeconds==14 and r.segments[3].costDetail.useAt==109)
a.charges=2;a.rechargeStart=0
r=Plan(d,o,Loop(),{'town','cave','town','cave'})
assert(r.estimatedSeconds==19,'Full charges start one sequential recharge queue at first use')
a.charges=0;a.rechargeStart=99
r=Plan(d,o,Loop())
assert(r.estimatedSeconds==14,'Known zero-charge recharge can justify waiting')
for _,field in ipairs({'rechargeStart','rechargeSeconds','rechargeRate'}) do
    local saved=a[field];a[field]=nil
    r=Plan(d,o,Loop())
    assert(r.estimatedSeconds==100,'Unknown recharge preserves the known walking alternative')
    local impossible=Loop();impossible.edges={}
    assert(Plan(d,o,impossible).status=='unknown','Unknown regeneration is not a no-path proof')
    a[field]=saved
end
a.charges=1;a.rechargeRate=2
r=Plan(d,o,Loop(),{'town','cave'})
assert(r.estimatedSeconds==107,'Non-unit rate cannot justify a second charge')
-- Money and physical reagents remain cumulative across regeneration.
d[1].moneyCopper=4;d[1].reagents={powder={itemID=902,count=2}}
a.charges=2;a.rechargeRate=1;o.moneyCopper=4;o.items[902]=4
r=Plan(d,o,Loop(),{'town','cave'})
assert(r.estimatedSeconds==107,'Cooldown regeneration cannot regenerate money')
o.moneyCopper=8;o.items[902]=3
assert(Plan(d,o,Loop(),{'town','cave'}).estimatedSeconds==107,'Nor reagents')
o.items[902]=4
assert(Plan(d,o,Loop(),{'town','cave'}).estimatedSeconds==12)
