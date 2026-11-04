-- Load the real V2 dependency closure in APR.toc order, with public client fakes.
local W=dofile('tests/lua/navigation_v2_waypoint/fixture.lua')
local F=dofile('tests/lua/navigation_v2_movement/fixture.lua')
local H={Edge=F.Edge,Graph=F.Graph,Path=F.Path}
local function read(path)
    local file=assert(io.open(path,'r'))
    local text=file:read('*a');file:close();return text
end

local function loadXML(path,namespace,loaded)
    local directory=path:match('^(.*)/')
    loaded[#loaded+1]=path
    for file in read(path):gmatch('<Script%s+file="([^"]+)"') do
        local full=directory..'/'..file
        assert(loadfile(full))('APR',namespace)
        loaded[#loaded+1]=full
    end
end

function H.New()
    local env={frames={},timers={},context='objective',wall=0,loaded={},scans=0,questCalls=0,
        character={level=40,owned=true,usable=true,active=false,swimming=false,run=7,swim=4.7}}
    local c=env.character
    env.api={UnitLevel=function(unit) assert(unit=='player');return c.level end,
        IsSwimming=function(unit) assert(unit=='player');return c.swimming end,
        GetUnitSpeed=function(unit) assert(unit=='player');return 0,c.run,0,c.swim end,
        C_MountJournal={GetMountIDs=function() env.scans=env.scans+1;return {71} end,
            GetMountInfoByID=function(id)
                assert(id==71)
                return 'Synthetic mount',1,1,c.active,c.usable,1,false,false,nil,false,c.owned,71,false
            end,
            GetMountInfoExtraByID=function(id) assert(id==71);return nil,'','',false,241 end,
            GetMountUsabilityByID=function(id,indoors)
                assert(id==71)
                if indoors and c.indoors then return false end
                return c.usable
            end}}
    APR={navigation={legacy=true},IsStepContextCurrent=function(_,context) return context==env.context end,
        NextQuestStep=function() env.questCalls=env.questCalls+1 end}
    GetTime,debugprofilestop=function() return env.wall end,function() return 0 end
    MAP_PIN='Map pin';InCombatLockdown=function() return env.combat==true end
    local api,provider=W.Provider()
    env.provider=provider
    WaypointUIAPI={Navigation=api};AzerothWaypointNS=nil
    C_Map={GetUserWaypoint=function() return nil end}
    CreateFrame=function(kind)
        assert(kind=='Frame')
        local frame={events={},scripts={}}
        function frame:SetScript(name,fn) self.scripts[name]=fn end
        function frame:RegisterEvent(event) self.events[event]=true end
        function frame:UnregisterEvent(event) self.events[event]=nil end
        function frame:UnregisterAllEvents() self.events={} end
        env.frames[#env.frames+1]=frame
        return frame
    end
    C_Timer={NewTimer=function(delay,callback)
        local timer={delay=delay,callback=callback}
        function timer:Cancel() self.cancelled=true end
        env.timers[#env.timers+1]=timer;return timer
    end,NewTicker=function() error('no movement polling') end}
    local namespace={}
    -- Selection restricts execution to the V2 closure. Its order comes solely
    -- from the production TOC and XML, never from a hand-authored module list.
    for line in (read('APR.toc')..'\n'):gmatch('([^\r\n]+)') do
        line=line:gsub('\\','/')
        if line:match('/LibAPRNavigation%-2%.0/[^/]+%.xml$') then loadXML(line,namespace,env.loaded)
        elseif line:match('/NavigationV2[^/]*%.lua$') then
            assert(loadfile(line))('APR',namespace);env.loaded[#env.loaded+1]=line
        end
    end
    local host=assert(APR.NavigationV2,'host must be reached through APR.toc')
    assert(namespace.NavigationV2Movement,'movement adapter must be reached through APR.toc')
    assert(namespace.NavigationV2Forever,'movement profile must be reached through XML')
    assert(not host.enabled and #env.frames==0 and #env.timers==0 and env.scans==0)
    assert(APR.navigation.legacy and #provider.creates==0)
    function env:Fire(event,...)
        for _,frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,event,...) end
        end
    end
    function env:Enable(graph,options)
        options=options or {}
        options.observeMovement=true;options.movementAPI=self.api
        assert(host:Enable(graph,options))
        host:ObserveWorld(false) -- explicit synthetic ready-world evidence after subscription
    end
    function env:Finish()
        for _=1,10000 do
            local result=assert(host:Step(1))
            if result.status~='running' then return result end
        end
        error('host planning did not terminate')
    end
    function env:Location(sequence,node,space,proof)
        return {sequence=sequence,reliable=true,node=node,space=space or 'home',phase='blue',transition=proof}
    end
    function env:Resolve(node)
        return {key=node,title='The destination',position={mapID=42,x=.2,y=.3}}
    end
    env.host,env.namespace=host,namespace
    return env,host
end

return H
