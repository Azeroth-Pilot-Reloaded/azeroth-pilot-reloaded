local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
APR={};assert(loadfile('APR-Core/features/navigation/NavigationV2Personal.lua'))('APR',F.ns)
local A=APR.NavigationV2Personal
local calls=0
local api={GetTime=function()return 100 end,GetMoney=function()return 12 end,
    InCombatLockdown=function()return false end,IsIndoors=function()return true end,
    UnitCastingInfo=function()return nil end,UnitChannelInfo=function()return nil end,
    C_SpellBook={IsSpellKnown=function(id)assert(id==901);return true end},
    C_Spell={GetSpellInfo=function()return {name='Recall',castTime=3000} end,
        IsSpellUsable=function()calls=calls+1;return true end,
        GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true,modRate=1} end,
        GetSpellCharges=function()return {currentCharges=2,maxCharges=3,cooldownStartTime=90,cooldownDuration=10,chargeModRate=1} end},
    C_Item={GetItemCount=function(id,bank,uses,reagent,account)
        assert(id==902 and bank==false and uses==false and reagent==false and account==false);return 5 end,
        IsItemDataCachedByID=function()return true end,
        IsUsableItem=function()return true end,
        GetItemCooldown=function()return 0,0,true end}}
local declarations=F.Declarations();declarations[1].chargeBased=true
local origin=F.Observation().origin
local s=A.Observe(api,declarations,{},origin,false)
assert(s.observedAt==100 and s.moneyCopper==12 and s.combat==false and s.allowRare==false)
assert(s.origin.indoors==true and s.origin.node=='cave' and s.items[902]==5)
assert(s.actions.recall.known==true and s.actions.recall.usable==true and s.actions.recall.loaded==true)
assert(s.actions.recall.readyAt==0 and s.actions.recall.charges==2 and s.actions.recall.castSeconds==3)
assert(s.casting==false)
-- Independent counters include every gameplay read, not just spell usability.
do
    local reads=0
    local function Spy(value)
        if type(value)=='function' then return function(...)reads=reads+1;return value(...)end end
        if type(value)=='table' then
            local copy={}
            for key,item in pairs(value) do copy[key]=Spy(item) end
            return copy
        end
        return value
    end
    local unknown=A.Observe(Spy(api),declarations,{},origin,nil)
    assert(reads==0,'Unknown world state must not read gameplay APIs')
    assert(unknown.loading==nil and unknown.observedAt==nil and unknown.moneyCopper==nil)
    unknown.revision=1
    assert(F.Personal.New(declarations,unknown):Edge('cave',1).access=='unknown')
    local loading=A.Observe(Spy(api),declarations,{},origin,true)
    assert(loading.loading==true and reads==0,'Loading world must not read gameplay APIs')
    local known=A.Observe(Spy(api),declarations,{},origin,false)
    assert(known.loading==false and reads>0,'Explicit available world must collect observations')
end
api.UnitCastingInfo=function()return 'Recall' end
assert(A.Observe(api,declarations,{},origin,false).casting==true)
api.UnitCastingInfo=function()error('API unavailable')end
assert(A.Observe(api,declarations,{},origin,false).casting==nil)
api.UnitCastingInfo=function()return nil end
local same=A.Observe(api,declarations,{},origin,false);same.observedAt=101
assert(A.Same(s,same));same.actions.recall.charges=1;assert(not A.Same(s,same))
same=A.Observe(api,declarations,{},origin,false);same.actions.recall.readyAt=105;s.actions.recall.readyAt=105
same.observedAt=105;assert(not A.Same(s,same),'Readiness crossing is relevant even with unchanged absolute cooldown')
same.observedAt=nil;assert(not A.Same(s,same),'Losing a usable clock invalidates prior certainty')
origin.node='changed';assert(s.origin.node=='cave')
api.issecretvalue=function(value)return type(value)=='table' and value.secret==true end
api.C_Spell.GetSpellCooldown=function()return {secret=true} end
api.C_Spell.GetSpellCharges=function()return {currentCharges={secret=true},maxCharges=3} end
s=A.Observe(api,declarations,{},nil,false)
assert(s.actions.recall.readyAt==nil and s.actions.recall.charges==nil)
api.C_Spell.GetSpellInfo=function()return nil end
api.C_Item.GetItemCount=function()return nil end
api.GetMoney=function()error('not ready')end
s=A.Observe(api,declarations,{},nil,false)
assert(s.moneyCopper==nil and s.items[902]==nil and s.actions.recall.loaded==nil)
local before=calls;s=A.Observe(api,declarations,{},nil,true)
assert(s.loading==true and calls==before and s.moneyCopper==nil,'No scan during loading')
declarations[1].kind='item';declarations[1].spellID=nil;declarations[1].itemID=902;declarations[1].chargeBased=false
api.C_Item.IsItemDataCachedByID=function()return false end
s=A.Observe(api,declarations,{allowRare=true},nil,false)
assert(s.actions.recall.loaded==nil and s.actions.recall.owned==nil and s.allowRare==true)
local changed=A.Observe({},declarations,{},nil,false)
assert(changed.combat==nil and changed.actions.recall.readyAt==nil,'Absent APIs stay unknown')
do
    local item=F.Declarations()[1]
    item.kind,item.spellID,item.itemID,item.consumable,item.itemResourceId='item',nil,902,true,'travel_powder'
    local other=F.Declarations()[1];other.id='another_spell'
    other.reagents={another_alias={itemID=902,count=1}}
    local repeated=F.Declarations()[1];repeated.id='another_item'
    repeated.kind,repeated.spellID,repeated.itemID='item',nil,902
    local physicalReads=0
    local captureAPI={C_Item={GetItemCount=function(id)
        assert(id==902);physicalReads=physicalReads+1
        return physicalReads==1 and 5 or 99
    end}}
    local snapshot=A.Observe(captureAPI,{item,other,repeated},{},nil,false)
    assert(physicalReads==1,'One inventory read per physical object, including item/reagent/action aliases')
    assert(snapshot.items[902]==5 and snapshot.actions.recall.owned==true and snapshot.actions.another_item.owned==true)
    physicalReads=0
    captureAPI.C_Item.GetItemCount=function()physicalReads=physicalReads+1;return nil end
    snapshot=A.Observe(captureAPI,{item,other,repeated},{},nil,false)
    assert(physicalReads==1 and snapshot.items[902]==nil and snapshot.actions.recall.owned==nil,
        'Unknown inventory is captured once without becoming zero or being reread')
    physicalReads=0
    captureAPI.C_Item.GetItemCount=function()physicalReads=physicalReads+1;return {secret=true}end
    captureAPI.issecretvalue=function(value)return type(value)=='table' and value.secret==true end
    snapshot=A.Observe(captureAPI,{item,other,repeated},{},nil,false)
    assert(physicalReads==1 and snapshot.items[902]==nil and snapshot.actions.another_item.owned==nil)
end
