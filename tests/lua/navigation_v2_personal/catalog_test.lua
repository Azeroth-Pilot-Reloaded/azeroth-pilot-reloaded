local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local input,obs=F.Declarations(),F.Observation()
local c=assert(F.Personal.New(input,obs))
local e=assert(c:Edge('cave',1))
assert(e.access=='available' and e.from=='cave' and e.to=='town' and e.seconds==5)
assert(e.kind=='personal' and e.personalId=='recall' and e.position==nil)
assert(e.resources.money==4 and e.resources['item:travel_powder']==2 and e.resources['personal:recall']==1)
assert(c:Resources().money==12 and c:Resources()['personal:recall']==1)
assert(c:Edge('exit',1)==nil,'No invented cave exit or universally usable future origin')
input[1].useSeconds=999;obs.items[902]=999
assert(c:Edge('cave',1).seconds==5 and c:Resources()['item:travel_powder']==5,'Immutable capture')
e.resources.money=999;assert(c:Edge('cave',1).resources.money==4)
local fresh=F.Observation(2);fresh.actions.recall.readyAt=105
assert(c:Observe(fresh));assert(c:Edge('cave',1).access=='unknown','Do not invent future availability')
assert(c:Observe(fresh)==false)
fresh=F.Observation(3);fresh.origin.phase='other'
local decl=F.Declarations();decl[1].origin={phase='present'}
c=assert(F.Personal.New(decl,fresh));assert(c:Edge('cave',1).access=='unavailable')
fresh.origin.reliable=nil;c=assert(F.Personal.New(decl,fresh));assert(c:Edge('cave',1).access=='unknown')
decl=F.Declarations();decl[1].rare=true
c=assert(F.Personal.New(decl,F.Observation()));assert(c:Edge('cave',1).access=='unavailable')
fresh=F.Observation(2);fresh.allowRare=true;assert(c:Observe(fresh));assert(c:Edge('cave',1).access=='available')
fresh=F.Observation(3);fresh.combat=true;assert(c:Observe(fresh));assert(c:Edge('cave',1).access=='unavailable')
fresh=F.Observation(4);fresh.allowRare=true;fresh.actions.recall.loaded=nil;assert(c:Observe(fresh));assert(c:Edge('cave',1).access=='unknown')
decl=F.Declarations();decl[1].chargeBased=true
fresh=F.Observation();fresh.actions.recall.charges=2;fresh.actions.recall.maxCharges=3
c=assert(F.Personal.New(decl,fresh));assert(c:Resources()['personal:recall']==2)
fresh=F.Observation(2);assert(c:Observe(fresh));assert(c:Resources()['personal:recall']==nil)
assert(c:Edge('cave',1).access=='unknown')
decl=F.Declarations();decl[1].kind='item';decl[1].spellID=nil;decl[1].itemID=902;decl[1].consumable=true
decl[1].itemResourceId='travel_powder'
fresh=F.Observation();fresh.actions.recall={owned=true,loaded=true,usable=true,readyAt=100}
c=assert(F.Personal.New(decl,fresh));assert(c:Edge('cave',1).resources['item:travel_powder']==3)
assert(c:SetCosts('recall',{useSeconds=8}));assert(c:Edge('cave',1).seconds==10)
assert(c:SetCosts('recall',{useSeconds=-1})==nil)
assert(F.Personal.New({{id='bad'}},fresh)==nil)
fresh=F.Observation(5);fresh.casting=true
assert(c:Observe(fresh));assert(c:Edge('cave',1).access=='unavailable')
fresh=F.Observation(6);fresh.casting=nil
assert(c:Observe(fresh));assert(c:Edge('cave',1).access=='unknown')
decl=F.Declarations();decl[1].name='Recall 12, 34'
c=assert(F.Personal.New(decl,F.Observation()));assert(c.byId.recall.name==nil)
decl=F.Declarations();decl[2]=F.Declarations()[1];decl[2].id='second-destination';decl[2].to='elsewhere'
fresh=F.Observation();fresh.actions['second-destination']={known=true,loaded=true,usable=true,readyAt=0}
c=assert(F.Personal.New(decl,fresh))
assert(c:Edge('cave',2).resources['personal:recall']==1 and c:Resources()['personal:recall']==1,
    'Multiple destinations cannot reset the same ability cooldown')
decl[2].reagents={other_alias={itemID=902,count=3}}
c=assert(F.Personal.New(decl,fresh))
assert(c:Edge('cave',2).resources['item:travel_powder']==3 and c:Resources()['item:other_alias']==nil)
decl[2].reagents={travel_powder={itemID=999,count=1}}
assert(F.Personal.New(decl,fresh)==nil,'One business resource cannot identify two physical items')
