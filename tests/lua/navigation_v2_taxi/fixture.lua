local F = {}
function F.Load()
    local ns = {}
    local root = 'APR-Core/libs/LibAPRNavigation-2.0/'
    local manifest=assert(io.open(root..'LibAPRNavigation.xml'))
    local xml=manifest:read('*a');manifest:close()
    local loaded={}
    for file in xml:gmatch('<Script file="([^"]+)"') do
        assert(not loaded[file],'Duplicate module registration')
        loaded[file]=true
        assert(loadfile(root..file))('test', ns)
    end
    return ns
end
function F.Stop(id, world)
    return {id=id,worldID=world or 7,floorID=0,phaseID='shared',taxiNodeID=id == 'west' and 10 or 20,
        title='Flight master',position={mapID=77,x=0.2,y=0.4}}
end
function F.Route(id, from, to, fare, ride)
    return {id=id,from=from,to=to,origin=F.Stop(from),destination=F.Stop(to),fareCopper=fare,
        costs={approach=0,boarding=1,ride=ride,loading=0,disembark=1,final=0},timeoutSeconds=300}
end
function F.Options(routes, money)
    local nodes, observed = {}, {}
    for _, r in ipairs(routes) do
        nodes[r.origin.id],nodes[r.destination.id]={discovered=true},{discovered=true}
        observed[r.id]={reachable=true,fareCopper=r.fareCopper}
    end
    return {taxi=routes,taxiObservation={revision=1,nodes=nodes,routes=observed},resources={money=money},
        clock=function() return 100 end,profileClock=function() return 0 end}
end
function F.Finish(job)
    for _=1,10000 do local result=assert(job:Step(1));if result.status~='running' then return result end end
    error('Planner did not stop')
end
function F.Host(awp)
    local W=dofile('tests/lua/navigation_v2_waypoint/fixture.lua')
    local wui,ws=W.Provider();local aa,as=W.AWP()
    local env={time=100,context='objective',timers={},frames={},money=10,fare=4,onTaxi=false,calls=0}
    APR={navigation={legacy=true},IsStepContextCurrent=function(_,c)return c==env.context end,
        NextQuestStep=function()error('Taxi cannot advance a quest')end}
    GetTime,debugprofilestop=function()return env.time end,function()return 0 end
    MAP_PIN='Map pin';FLIGHT_MAP='Flight map';InCombatLockdown=function()return false end
    WaypointUIAPI={Navigation=wui};AzerothWaypointNS=awp and aa or nil
    C_Map={GetUserWaypoint=function()return nil end};hooksecurefunc=nil
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
        function f:UnregisterAllEvents()self.events={}end
        env.frames[#env.frames+1]=f;return f
    end
    function env:Fire(event)
        for _,frame in ipairs(self.frames) do if frame.events[event]then frame.callback(frame,event)end end
    end
    env.api={GetMoney=function()env.calls=env.calls+1;return env.money end,
        GetTaxiMapID=function()return 77 end,NumTaxiNodes=function()return 2 end,
        TaxiNodeGetType=function(slot)return slot==1 and 'CURRENT' or 'REACHABLE'end,
        TaxiNodeCost=function()env.calls=env.calls+1;return env.fare end,
        UnitOnTaxi=function()return env.onTaxi end,
        C_TaxiMap={GetAllTaxiNodes=function()return {{nodeID=10,slotIndex=1},{nodeID=20,slotIndex=2}}end}}
    local ns={}
    local toc=assert(io.open('APR.toc'));local contents=toc:read('*a');toc:close()
    local registered={}
    for file in contents:gmatch('[^\r\n]+')do
        if file=='APR-Core/libs/LibAPRNavigation-2.0/LibAPRNavigation.xml'then
            local root=file:match('^(.*/)');local mf=assert(io.open(file));local xml=mf:read('*a');mf:close()
            for name in xml:gmatch('<Script%s+file="([^"]+)"')do assert(loadfile(root..name))('APR',ns)end
        elseif file:match('^APR%-Core/features/navigation/NavigationV2%w*%.lua$')then
            assert(not registered[file]);registered[file]=true
            assert(loadfile(file))('APR',ns)
        end
    end
    assert(ns.NavigationV2TaxiAdapter,'TOC must load the taxi observer')
    return APR.NavigationV2,ns,env,ws,as
end
return F
