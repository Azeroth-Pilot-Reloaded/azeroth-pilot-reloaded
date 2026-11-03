local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local h,ns,env,ws=F.Host(false)
assert(ns.NavigationV2PersonalAdapter,'Actual TOC must load Personal adapter')
local state={money=10,powder=2,cast=false,combat=false,readyAt=100,clicks=0,buttons={},reads=0}
local api={GetTime=function()return env.time end,GetMoney=function()return state.money end,
    InCombatLockdown=function()return state.combat end,IsIndoors=function()return true end,
    UnitCastingInfo=function()if state.cast then return 'Recall'end end,UnitChannelInfo=function()end,
    USE='Use',C_SpellBook={IsSpellKnown=function()return true end},
    C_Spell={GetSpellInfo=function()return {name='Recall',castTime=1000}end,
        IsSpellUsable=function()return true end,
        GetSpellCooldown=function()return {startTime=state.readyAt,duration=0,isEnabled=true,modRate=1}end},
    C_Item={GetItemCount=function()state.reads=state.reads+1;return state.powder end},
    RegisterStateDriver=function()end,SecureHandlerWrapScript=function(button,_,_,snippet)button.guard=snippet end}
api.CreateFrame=function(kind,_,_,template)
    assert(kind=='Button' and template:match('SecureActionButtonTemplate'))
    local b={attributes={},scripts={}}
    function b:SetAttribute(k,v)assert(not state.combat,'No protected writes in combat');self.attributes[k]=v end
    function b:RegisterForClicks(...)self.clickMode={...}end
    function b:SetScript(k,v)assert(not state.combat);self.scripts[k]=v end
    function b:Show()assert(not state.combat);self.shown=true end
    function b:Hide()assert(not state.combat);self.shown=false end
    function b:HardwareClick()
        if self.scripts.PreClick then self.scripts.PreClick(self,'LeftButton',false)end
        -- Model the verified secure combat pre-wrapper even before state-driver tick.
        if not state.combat and self.attributes.type then state.clicks=state.clicks+1;state.cast=true end
        if self.scripts.PostClick then self.scripts.PostClick(self,'LeftButton',false)end
    end
    function b:Click()error('No automatic click')end
    state.buttons[#state.buttons+1]=b;return b
end
local d={id='recall',kind='spell',spellID=901,from='cave',to='town',name='Recall',
    destination={space='world',phase='shared'},useSeconds=1,loadingSeconds=1,cooldownSeconds=60,
    timeoutSeconds=20,moneyCopper=4,reagents={powder={itemID=902,count=1}}}
local taxi=F.Route('flight','town','goal',2,1)
local options=F.Options({taxi},10)
options.personal,options.observePersonal,options.personalAPI={d},true,api
options.personalOrigin={node='cave',space='cave',phase='shared',reliable=true,indoors=true}
options.observeTaxi,options.taxiAPI=true,env.api
env.api.GetMoney=function()return state.money end
assert(h:Enable({complete=true,nodes={'cave','town','goal'},edges={{id='exit',from='town',to='goal',seconds=2}}},options))
h:ObserveWorld(false)
assert(h:ObservePersonal())
state.money=9;assert(h:ObserveTaxi())
assert(h.planner.resources.money==9 and h.planner.resources['item:powder']==2,
    'A monetary refresh must preserve the independent inventory contribution')
state.money=10
h:Plan({from='cave',to='goal',via={'town'}},env.context)
local result=F.Finish(h.job)
assert(result.estimatedSeconds==4)
local reads=state.reads
h:GetResult();h:Step();assert(state.reads==reads,'Step/GetResult never read personal inventory')
assert(h:StartTravel(result).kind=='personal' and #ws.creates==0)
local button=assert(h:GetPersonalButton())
assert(button.shown and button.attributes.type=='spell' and button.attributes.spell==901)
assert(state.clicks==0,'Preparing guidance never casts')
local calls=h.planner.revision
env:Fire('SPELL_UPDATE_COOLDOWN')
assert(not h.planner:IsCurrent(result) and button.attributes.type==nil)
assert(h.planner.revision>calls)
h:Plan({from='cave',to='goal',via={'town'}},env.context);result=F.Finish(h.job)
h:StartTravel(result);button=assert(h:GetPersonalButton())
button:HardwareClick()
local action=h:GetTravelAction()
assert(state.clicks==1 and action.phase=='awaiting_transition' and action.attempt)
assert(button.attributes.type==nil and not h.journey:RemainingRequest())
local attempt,deadline=action.attempt,action.deadline
state.readyAt=200;state.money=6;state.powder=1
env:Fire('SPELL_UPDATE_COOLDOWN');env:Fire('UNIT_SPELLCAST_START')
local proof={personalId='recall',from='cave',to='town',attempt=attempt,complete=true}
env:Fire('PLAYER_LEAVING_WORLD')
assert(h:ObserveTravel({sequence=1,reliable=true,loading=false,node='town',space='world',phase='shared',transition=proof}).kind=='personal',
    'A consumer cannot erase the host observed loading interval')
assert(not h.journey:RemainingRequest())
env:Fire('PLAYER_ENTERING_WORLD')
assert(h:GetTravelAction().attempt==attempt and h:GetTravelAction().deadline==deadline)
assert(not h.planner:IsCurrent(result))
state.cast=false
assert(h:ObserveTravel({sequence=2,reliable=true,loading=false,node='town',space='world',phase='shared',transition=proof}).kind=='replan')
assert(h.journey.objective.from=='cave' and h.journey.viaIndex==1)
assert(F.Finish(h.job).estimatedSeconds==2)
assert(state.clicks==1 and #ws.creates==0)
-- A stale action is inert in combat before the asynchronous secure state tick.
state.readyAt=100;state.cast=false
h:Plan({from='cave',to='goal'},env.context);result=F.Finish(h.job);h:StartTravel(result)
button=assert(h:GetPersonalButton());state.combat=true
h:Cancel();button:HardwareClick();assert(state.clicks==1)
state.combat=false;env:Fire('PLAYER_REGEN_ENABLED')
assert(button.attributes.type==nil and not button.shown)
h:Disable()
for _,frame in ipairs(env.frames)do assert(next(frame.events)==nil)end
