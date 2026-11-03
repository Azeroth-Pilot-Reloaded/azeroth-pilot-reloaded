-- Execute the V2 entries discovered in the real addon TOC, including XML order.
local W=dofile('tests/lua/navigation_v2_waypoint/fixture.lua')
local F={}
function F.Load(awp)
    local env={time=100,context='objective',timers={},frames={},questCalls=0}
    APR={navigation={legacy=true},IsStepContextCurrent=function(_,c)return c==env.context end,
        NextQuestStep=function()env.questCalls=env.questCalls+1 end}
    GetTime,debugprofilestop=function()return env.time end,function()return 0 end
    MAP_PIN='Map pin';InCombatLockdown=function()return false end
    local wui,ws=W.Provider();local aa,as=W.AWP()
    WaypointUIAPI={Navigation=wui};AzerothWaypointNS=awp and aa or nil
    C_Map={GetUserWaypoint=function()return nil end}
    hooksecurefunc=nil
    C_Timer={NewTimer=function(delay,callback)
        assert(delay>0);local t={delay=delay,callback=callback}
        function t:Cancel()self.cancelled=true end
        env.timers[#env.timers+1]=t;return t
    end,NewTicker=function()error('No polling')end}
    CreateFrame=function()
        local f={events={}}
        function f:SetScript(_,fn)self.callback=fn end
        function f:RegisterEvent(event)self.events[event]=true end
        function f:UnregisterEvent(event)self.events[event]=nil end
        function f:UnregisterAllEvents()self.unregistrations=(self.unregistrations or 0)+1;self.events={} end
        env.frames[#env.frames+1]=f;return f
    end
    local ns={}
    local toc=assert(io.open('APR.toc'));local contents=toc:read('*a');toc:close()
    local count=0
    for file in contents:gmatch('[^\r\n]+') do
        if file=='APR-Core/libs/LibAPRNavigation-2.0/LibAPRNavigation.xml' then
            local root=file:match('^(.*/)');local manifest=assert(io.open(file));local xml=manifest:read('*a');manifest:close()
            for name in xml:gmatch('<Script%s+file="([^"]+)"') do assert(loadfile(root..name))('APR',ns) end
            count=count+1
        elseif file=='APR-Core/features/navigation/NavigationV2Movement.lua'
            or file=='APR-Core/features/navigation/NavigationV2.lua' then
            if file:match('/NavigationV2.lua$') then assert(ns.NavigationV2Movement,'TOC must load observer before host') end
            assert(loadfile(file))('APR',ns);count=count+1
        end
    end
    assert(count==3,'TOC must register V2 library, observer and host once')
    function env:Enable(graph,options)
        assert(APR.NavigationV2:Enable(graph,options))
        APR.NavigationV2:ObserveWorld(false) -- explicit fresh synthetic evidence after subscription
        return true
    end
    return APR.NavigationV2,ns,env,ws,as
end
function F.Finish(host)
    for _=1,10000 do local r=assert(host:Step(1));if r.status~='running'then return r end end
    error('No terminal result')
end
return F
