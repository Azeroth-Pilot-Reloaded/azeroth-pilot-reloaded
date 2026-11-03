local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
APR={};assert(loadfile('APR-Core/features/navigation/NavigationV2Personal.lua'))('APR',F.ns)
local A=APR.NavigationV2Personal
local combat=false
local api={InCombatLockdown=function()return combat end,USE='Use',SPELLS='Spells',ITEMS='Items'}
local button={attributes={},writes=0}
function button:SetAttribute(key,value)assert(not combat);self.attributes[key]=value;self.writes=self.writes+1 end
function button:Click()error('Must never click/cast/use automatically')end
assert(A.PrepareButton(button,{kind='spell',spellID=901,status='running',phase='ready'},api))
assert(button.attributes.type=='spell' and button.attributes.spell==901 and not button.attributes.item)
assert(A.PrepareButton(button,{kind='item',itemID=902,status='running',phase='ready'},api))
assert(button.attributes.type=='item' and button.attributes.item=='item:902' and not button.attributes.spell)
assert(A.Label({kind='spell',title='Recall 12,34'},api)=='Use')
assert(A.Label({kind='spell',title='Recall'},api)=='Recall')
local writes=button.writes;combat=true
local ok,reason=A.PrepareButton(button,nil,api)
assert(ok==false and reason=='combat_lockdown' and button.writes==writes)
combat=false;assert(A.PrepareButton(button,nil,api));assert(button.attributes.type==nil and button.attributes.item==nil)
assert(A.PrepareButton(button,{kind='spell',spellID=901,status='cancelled'},api)==nil)
assert(button.attributes.type==nil)
assert(A.PrepareButton(button,{kind='spell',spellID=-1,status='running',phase='ready'},api)==nil)
assert(A.PrepareButton(button,nil,{})==false,'Unknown combat state must not mutate protected attributes')
