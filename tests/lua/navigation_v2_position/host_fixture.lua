-- Real TOC/XML closure with only public read-only client/provider fakes.
local Providers=dofile('tests/lua/navigation_v2_waypoint/fixture.lua')
local F={}
local function Read(path)
    local file=assert(io.open(path));local text=file:read('*a');file:close();return text
end
function F.Graph()
    return {complete=true,nodes={'s','a','b','g'},edges={
        {id='shortcut',from='s',to='g',seconds=1},
        {id='first',from='s',to='a',seconds=2},
        {id='second',from='a',to='b',seconds=2},
        {id='third',from='b',to='g',seconds=2}}}
end
function F.New(awp)
    local e={frames={},timers={},ready=true,readyCalls=0,positionCalls=0,mapCalls=0,
        context='objective',x=123,y=-987,z=17,world=0,uiMapID=nil,questCalls=0,loaded={}}
    local wui,ws=Providers.Provider();local aa,as=Providers.AWP()
    APR={navigation={legacy=true},IsStepContextCurrent=function(_,c)return c==e.context end,
        NextQuestStep=function()e.questCalls=e.questCalls+1;error('No quest progression')end}
    GetTime,debugprofilestop=function()return 100 end,function()return 0 end
    IsPlayerInWorld,UnitPosition,issecretvalue=nil,nil,nil
    MAP_PIN='Map pin';InCombatLockdown=function()return false end
    WaypointUIAPI={Navigation=wui};AzerothWaypointNS=awp and aa or nil;hooksecurefunc=nil
    C_Map={GetUserWaypoint=function()return nil end}
    C_Timer={NewTimer=function(delay,callback)
        local timer={delay=delay,callback=callback};function timer:Cancel()self.cancelled=true end
        e.timers[#e.timers+1]=timer;return timer
    end,NewTicker=function()error('No permanent polling')end}
    CreateFrame=function(kind)
        assert(kind=='Frame')
        local f={events={}}
        function f:SetScript(name,fn)assert(name=='OnEvent');self.callback=fn end
        function f:RegisterEvent(event)self.events[event]=true end
        function f:UnregisterEvent(event)self.events[event]=nil end
        function f:UnregisterAllEvents()self.events={}end
        e.frames[#e.frames+1]=f;return f
    end
    function e:Fire(event,...)
        for _,f in ipairs(self.frames)do if f.events[event]then f.callback(f,event,...)end end
    end
    e.api={IsPlayerInWorld=function()
        e.readyCalls=e.readyCalls+1
        local subscribed=false
        for _,f in ipairs(e.frames)do
            if f.events.PLAYER_ENTERING_WORLD and f.events.PLAYER_LEAVING_WORLD then subscribed=true end
        end
        assert(subscribed,'Fresh readiness must follow world subscription')
        if e.readyError then error('Native readiness unavailable')end
        return e.ready
    end,UnitPosition=function(unit)
        assert(unit=='player');e.positionCalls=e.positionCalls+1;return e.x,e.y,e.z,e.world
    end,CreateVector2D=function(x,y)return {x=x,y=y}end,C_Map={
        GetBestMapForUnit=function()return e.uiMapID end,
        GetMapPosFromWorldPos=function(world,point,map)
            e.mapCalls=e.mapCalls+1
            assert(world==0 and point.x==123 and point.y==-987 and map==42)
            if e.noProjection then return nil end
            return 42,{x=.25,y=.75}
        end,
        GetWorldPosFromMapPos=function(map,point)
            assert(map==42 and point.x==.25 and point.y==.75)
            return 0,{x=123,y=-987}
        end}}
    local ns={}
    for line in (Read('APR.toc')..'\n'):gmatch('([^\r\n]+)')do
        line=line:gsub('\\','/')
        if line:match('/LibAPRNavigation%-2%.0/[^/]+%.xml$')then
            local directory=line:match('^(.*)/')
            for name in Read(line):gmatch('<Script%s+file="([^"]+)"')do
                local full=directory..'/'..name
                assert(loadfile(full))('APR',ns);e.loaded[#e.loaded+1]=full
            end
        elseif line:match('^APR%-Core/features/navigation/NavigationV2[^/]*%.lua$')then
            assert(loadfile(line))('APR',ns);e.loaded[#e.loaded+1]=line
        end
    end
    local h=assert(APR.NavigationV2)
    assert(ns.NavigationV2World and ns.NavigationV2Position,'Position closure must come from real XML/TOC')
    assert(not h.enabled and #e.frames==0 and #e.timers==0 and e.readyCalls==0 and e.positionCalls==0)
    assert(APR.navigation.legacy and #ws.creates==0 and as.registrations==0)
    e.options={observePosition=true,positionAPI=e.api,positionIdentity={space='room',floor='upper',phase='blue'},
        positionExpected={world=0,space='room',floor='upper',phase='blue'}}
    e.request={from='s',to='g',via={'a','b'}}
    e.target={key='goal',title='Destination',uiMapID=42,
        worldPosition={world=0,x=123,y=-987,z=17,space='room',floor='upper',phase='blue'}}
    function e:Enable()return h:Enable(F.Graph(),self.options)end
    function e:Plan(request)return assert(h:Plan(request or self.request,self.context))end
    function e:Finish()
        for _=1,10000 do local result=assert(h:Step(1));if result.status~='running'then return result end end
        error('Host did not finish')
    end
    function e:Target()return h:SetWorldTarget(self.target,self.context)end
    function e:HasMarker()
        if awp then as:Flush();return as.record~=nil end
        return ws.current~=nil
    end
    function e:Cleanup()
        h:Disable()
        for _,f in ipairs(self.frames)do assert(next(f.events)==nil)end
        assert(self.questCalls==0)
    end
    e.host,e.namespace,e.wui,e.awp=h,ns,ws,as
    return e,h
end
return F
