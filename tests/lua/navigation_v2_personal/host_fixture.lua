-- Independent public API/frame model; load actual TOC/XML order for each client.
local F=dofile('tests/lua/navigation_v2_personal/fixture.lua')
local W=dofile('tests/lua/navigation_v2_waypoint/fixture.lua')
local function Read(path)
    local f=assert(io.open(path));local value=f:read('*a');f:close();return value
end
function F.Host(client,awp)
    local e={time=100,client=client or 'Standard',combat=false,secure=false,casting=false,
        money=12,stock={[902]=5},readyAt=0,charges=2,reads=0,combatChecks=0,frames={},buttons={},timers={},
        protectedUses=0,quests=0,context='first',registered={},loaded=true,indoors=true,known=true,usable=true}
    APR={navigation={legacy=true},IsStepContextCurrent=function(_,c)return c==e.context end,
        NextQuestStep=function()e.quests=e.quests+1 end}
    GetTime=function()return e.time end;debugprofilestop=function()return 0 end
    InCombatLockdown=function()return e.combat end
    MAP_PIN,USE='Map pin','Use';hooksecurefunc=nil;APRInstrumentation=nil
    local wui,ws=W.Provider();local aa,as=W.AWP()
    WaypointUIAPI={Navigation=wui};AzerothWaypointNS=awp and aa or nil
    C_Map={GetUserWaypoint=function()return nil end}
    C_Timer={NewTicker=function()error('No polling')end,NewTimer=function(delay,callback)
        assert(delay>0);local t={delay=delay,callback=callback}
        function t:Cancel()self.cancelled=true end
        e.timers[#e.timers+1]=t;return t
    end}
    CreateFrame=function(kind)
        assert(kind=='Frame','Secure buttons use the injected APR adapter boundary')
        local f={events={}}
        function f:SetScript(k,v)assert(k=='OnEvent');self.callback=v end
        function f:RegisterEvent(name)self.events[name]=true end
        function f:UnregisterEvent(name)self.events[name]=nil end
        function f:UnregisterAllEvents()self.events={}end
        e.frames[#e.frames+1]=f;return f
    end
    function e:Fire(event,...)
        for _,f in ipairs(self.frames)do if f.events[event]then f.callback(f,event,...)end end
    end
    local function Getter(fn)return function(...)e.reads=e.reads+1;return fn(...)end end
    e.api={GetTime=Getter(function()return e.time end),GetMoney=Getter(function()return e.money end),
        InCombatLockdown=function()e.combatChecks=e.combatChecks+1;return e.combat end,
        IsIndoors=Getter(function()return e.indoors end),
        UnitCastingInfo=Getter(function()if e.casting then return 'Recall'end end),UnitChannelInfo=Getter(function()end),
        issecretvalue=function(value)return type(value)=='table' and value.secret==true end,USE='Use',UIParent={},
        C_SpellBook={IsSpellKnown=Getter(function()return e.known end)},
        C_Spell={GetSpellInfo=Getter(function()if e.loaded~=false then return {name='Recall',castTime=3000}end end),
            IsSpellUsable=Getter(function()return e.usable end),
            GetSpellCooldown=Getter(function()if e.cooldownUnknown then return nil end
                return {startTime=e.readyAt,duration=0,isEnabled=true,modRate=1}end),
            GetSpellCharges=Getter(function()return {currentCharges=e.charges,maxCharges=3,
                cooldownStartTime=0,cooldownDuration=20,chargeModRate=1}end)},
        C_Item={GetItemCount=Getter(function(id)return e.stock[id]end),
            IsItemDataCachedByID=Getter(function()return e.loaded~=false end),
            IsUsableItem=Getter(function()return e.usable end),GetItemCooldown=Getter(function()return 0,0,true end)}}
    local function Snippet(body,args)
        local fn=assert(loadstring('return function('..args..') '..body..' end'))
        setfenv(fn,{SecureCmdOptionParse=function()return e.combat and 'blocked' or 'clear'end})
        return fn()
    end
    e.api.CreateFrame=function(kind,_,_,template)
        assert(kind=='Button' and template:find('SecureActionButtonTemplate',1,true)
            and template:find('SecureHandlerStateTemplate',1,true))
        local b={attributes={},scripts={},shown=false}
        function b:SetAttribute(k,v)assert(not e.combat or e.secure,'Insecure protected mutation');self.attributes[k]=v end
        function b:SetScript(k,v)assert(not e.combat or e.secure);self.scripts[k]=v end
        function b:Show()assert(not e.combat or e.secure);self.shown=true end
        function b:Hide()assert(not e.combat or e.secure);self.shown=false end
        function b:RegisterForClicks(...)assert(not e.combat);self.clickModes={...}end
        function b:Click()error('No automatic protected action')end
        function b:HardwareClick()
            if self.scripts.PreClick then self.scripts.PreClick(self,'LeftButton',false)end
            e.secure=true;local allow=self.guard(self,'LeftButton',false);e.secure=false
            if allow~=false and self.attributes.type then
                assert(self.attributes.spell or self.attributes.item)
                e.protectedUses=e.protectedUses+1;e.casting=true
            end
            if self.scripts.PostClick then self.scripts.PostClick(self,'LeftButton',false)end
        end
        e.buttons[#e.buttons+1]=b;return b
    end
    e.api.RegisterStateDriver=function(b,state,conditions)
        assert(state=='personalcombat' and conditions=='[combat] blocked; clear')
        b.state=Snippet(b.attributes['_onstate-'..state],'self,newstate')
    end
    e.api.SecureHandlerWrapScript=function(b,script,owner,body)
        assert(script=='OnClick' and owner==b);b.guard=Snippet(body,'self,button,down')
    end
    for _,name in ipairs({'CastSpellByID','CastSpellByName','UseItemByName','RunMacroText'})do
        e.api[name]=function()error('Automatic protected interaction')end
    end
    function e:SecureTick()
        self.secure=true
        for _,b in ipairs(self.buttons)do b.state(b,self.combat and 'blocked' or 'clear')end
        self.secure=false
    end
    local ns={}
    for path in Read('APR.toc'):gmatch('[^\r\n]+')do
        path=path:gsub('%[Game%]',e.client)
        if path=='APR-Core/libs/LibAPRNavigation-2.0/LibAPRNavigation.xml' then
            for script in Read(path):gmatch('<Script%s+file="([^"]+)"')do
                local source=path:match('^(.*/)')..script
                e.registered[source]=(e.registered[source] or 0)+1
                assert(loadfile(source))('APR',ns)
            end
        elseif path:match('^APR%-Core/features/navigation/NavigationV2%w*%.lua$')then
            e.registered[path]=(e.registered[path] or 0)+1
            assert(loadfile(path))('APR',ns)
        elseif path:match('^Routes/RouteList_')then assert(io.open(path)):close()end
    end
    assert(ns.NavigationV2Personal and ns.NavigationV2PersonalAdapter and APR.NavigationV2)
    e.host,e.ns,e.ws,e.as=APR.NavigationV2,ns,ws,as
    function e:Enable(declarations,extra,graph)
        local options={personal=declarations or F.Declarations(),observePersonal=true,personalAPI=self.api,
            personalOrigin={node='cave',space='underground',phase='present',reliable=true,indoors=true},
            positionAPI={IsPlayerInWorld=function()return true end}}
        for k,v in pairs(extra or {})do options[k]=v end
        assert(self.host:Enable(graph or F.Graph(),options))
        return options
    end
    function e:Finish()
        for _=1,10000 do local r=assert(self.host:Step(3));if r.status~='running'then return r end end
        error('Host job did not terminate')
    end
    function e:Ready(request)
        assert(self.host:Plan(request or {from='cave',to='goal'},self.context))
        local result=self:Finish();assert(result.status=='complete',result.reason)
        assert(self.host:StartTravel(result).kind=='personal')
        return result
    end
    function e:Arrival(action,sequence)
        return {sequence=sequence or 1,reliable=true,loading=false,node='town',space='world',phase='present',
            transition={personalId='recall',from='cave',to='town',attempt=action.attempt,complete=true}}
    end
    return e
end
return F
