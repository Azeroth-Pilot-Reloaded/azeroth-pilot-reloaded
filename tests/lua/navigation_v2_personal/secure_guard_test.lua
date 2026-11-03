local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
APR={};assert(loadfile('APR-Core/features/navigation/NavigationV2Personal.lua'))('APR',F.ns)
local A=APR.NavigationV2Personal
local combat,secure=false,false
local api={InCombatLockdown=function()return combat end,UIParent={}}
local clicks=0
local function Compile(body,args)
    local fn=assert(loadstring('return function('..args..') '..body..' end'))
    setfenv(fn,{SecureCmdOptionParse=function()return combat and 'blocked' or 'clear' end})
    return fn()
end
api.CreateFrame=function(kind,name,parent,template)
    assert(kind=='Button' and template:find('SecureActionButtonTemplate',1,true)
        and template:find('SecureHandlerStateTemplate',1,true))
    local b={attributes={},shown=false}
    function b:SetAttribute(key,value)assert(not combat or secure,'Insecure combat mutation');self.attributes[key]=value end
    function b:Show()assert(not combat or secure);self.shown=true end
    function b:Hide()assert(not combat or secure);self.shown=false end
    function b:RegisterForClicks(...)self.registered={...}end
    function b:HardwareClick()
        secure=true;local allow=self.pre(self,'LeftButton',false);secure=false
        if allow~=false and self.attributes.type then clicks=clicks+1 end
    end
    return b
end
api.RegisterStateDriver=function(button,state,conditions)
    assert(state=='personalcombat' and conditions=='[combat] blocked; clear')
    button.state=Compile(button.attributes['_onstate-'..state],'self,newstate')
end
api.SecureHandlerWrapScript=function(button,script,owner,body)
    assert(script=='OnClick' and owner==button);button.pre=Compile(body,'self,button,down')
end
local b=assert(A.CreateButton(api))
local action={kind='spell',spellID=901,status='running',phase='ready'}
assert(A.PrepareButton(b,action,api));assert(b.shown and clicks==0)
b:HardwareClick();assert(clicks==1)
-- A hardware click before the state-driver tick cannot execute the old action.
combat=true;b:HardwareClick();assert(clicks==1 and b.attributes.type==nil and not b.shown)
assert(A.PrepareButton(b,nil,api)==false)
-- Combat/cancellation/replacement cannot re-arm on the clear state transition.
secure=true;b.state(b,'blocked');secure=false
combat=false;secure=true;b.state(b,'clear');secure=false
b:HardwareClick();assert(clicks==1 and not b.shown)
assert(A.PrepareButton(b,nil,api));assert(b.attributes.spell==nil)
assert(A.PrepareButton(b,action,api));assert(b.shown)
combat=true;secure=true;b.state(b,'blocked');secure=false
assert(b.attributes.type==nil and b.attributes.spell==nil and not b.shown)
combat=false;assert(A.PrepareButton(b,nil,api));assert(clicks==1)
