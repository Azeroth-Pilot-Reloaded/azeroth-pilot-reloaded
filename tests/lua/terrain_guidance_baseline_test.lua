-- Prioritize a validated local corridor while the complete journey is pending.
local function fixture(profile)
    local s = {now=10, milliseconds=0, timers={}, pathJobs={}, worldJobs={},
        pathState="planning", worldState="planning", allowed=true, covered=true,
        position={x=0,y=0,z=0,instanceID=1,uiMapID=101}}
    local function noop() end
    function GetTime() return s.now end
    function debugprofilestop() return s.milliseconds end
    function UnitIsDeadOrGhost() return false end
    function UnitOnTaxi() return false end
    function IsIndoors() return false end
    function GetMoney() return 100 end
    function CreateFrame()
        return {RegisterEvent=noop, SetScript=function(_, name, callback)
            if name=="OnUpdate" then s.poll=callback end
        end}
    end
    function LibStub() return {GetLocale=function() return setmetatable({}, {__index=function(_, key) return key end}) end} end
    C_Map, C_PlayerInfo, C_MountJournal = nil, nil, nil
    C_Timer = {NewTimer=function(delay, callback)
        local timer = {delay=delay, callback=callback, Cancel=function(self) self.cancelled=true end}
        s.timers[#s.timers+1] = timer
        return timer
    end}
    s.step = {PickUp={777}, Zone=101, Range=3, Coord={x=0,y=100,z=0,instanceID=1,mapID=101}}
    APR = {ActiveRoute="r", PlayerID="p", stepRevision=0, GAME_VERSIONS={Forever="forever"},
        RouteQuestStepList={r={steps={s.step},mapID=101}}, settings={profile={enableAddon=true}},
        currentStep={AddQuestSteps=noop}, Arrow={SetCoord=noop}, SendMessage=noop}
    APRData = {p={r=1}}
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetCurrentStep() return s.step, 1, self.RouteQuestStepList.r.steps end
    function APR:PeekCurrentStep() return s.step end
    function APR:GetStepCoord(step) return step.Coord, 101 end
    function APR:GetPreferredStepZone() return 101 end
    function APR:GetCurrentRouteMapIDsAndName() return {101}, 101 end
    function APR:GetNavigationPlayerPosition() return s.position end
    function APR:CheckNavigationZoneReady() return true end
    dofile("APR-Core/features/questing/StepTransitions.lua")
    s.provider = {HasMap=function(_, map) return s.covered and map==1 end}
    function s.provider:CreatePathJob(from, to, context)
        assert(s.allowed, "Permission must be checked before asking for a local path")
        assert(context.walkSpeed==7 and context.walkSpeedFor and context.walkSpeedAt and context.clock==debugprofilestop)
        local job = {from=from,to=to,context=context,steps=0,workLastStep=3}
        function job:Cancel() self.cancelled=true end
        function job:Step(operations, milliseconds)
            assert(operations>0 and operations<=4096 and milliseconds>0 and milliseconds<=(s.localLimit or 1))
            self.steps=self.steps+1
            self.operations,self.milliseconds=operations,milliseconds
            s.milliseconds=s.milliseconds+(s.pathCost or 0.6)
            if s.onPathStep then s.onPathStep(self) end
            if s.pathState~="ready" then return s.pathState,s.pathResult end
            if s.readyPathResult then return "ready", s.readyPathResult end
            local yards = s.pathYards or 260
            return "ready", {path={from,{x=0,y=80,z=0,instanceID=1,uiMapID=101},
                {x=100,y=80,z=0,instanceID=1,uiMapID=101},to},seconds=yards/7,yards=yards}
        end
        s.pathJobs[#s.pathJobs+1]=job
        return job
    end
    APR.NavigationData = {GetWalkingProvider=function() return s.provider end,
        CanWalk=function() return s.allowed end, IsSameAccessRegion=function() return true end}
    APR.NavigationPlanner = {Create=function(_, request)
        local job = {request=request,steps=0,startedAt=s.milliseconds}
        function job:Cancel() self.cancelled=true end
        function job:Step(operations,milliseconds)
            assert(milliseconds>0 and milliseconds<=(s.worldLimit or 1))
            self.operations,self.milliseconds=operations,milliseconds
            self.steps=self.steps+1
            self.waitingData=s.worldState=="waiting_data"
            self.unresolvedSurface=s.unresolvedSurface
            self.unresolvedStartSurface=s.unresolvedStartSurface
            self.otherDataPending=s.otherDataPending
            s.milliseconds=s.milliseconds+math.min(milliseconds,0.4)
            self.elapsedMilliseconds=s.milliseconds-self.startedAt
            return s.worldState,s.worldResult
        end
        s.worldJobs[#s.worldJobs+1]=job
        return job
    end}
    dofile("APR-Core/features/navigation/Navigation.lua")
    s.nav = APR.navigation
    function s:tick()
        repeat
            local timer=table.remove(self.timers,1)
            assert(timer,"The shared controller timer must schedule the next slice")
            if not timer.cancelled then
                assert(timer.delay==(s.expectedDelay or 0.01),"Both jobs use the same controller timer")
                timer.callback()
                return timer
            end
        until false
    end
    return s
end

do
    local s = fixture("forever")
    local token = {deferred=true}
    APR.NavigationData.profile = "forever"
    function APR.NavigationData:HasDeferredTerrainImports(world) return world == 1 end
    function APR.NavigationData:BeginTerrainFrame() return token end
    s.expectedDelay, s.worldLimit, s.pathState = 0, 1, "no_path"
    s.nav:Update()
    assert(s.pathJobs[1].steps == 0 and s.worldJobs[1].steps == 0)
    token = {}
    s.onPathStep = function() token.deferred = true end
    s:tick()
    assert(s.pathJobs[1].steps == 1 and s.worldJobs[1].steps == 0,
        "A deferred local import keeps the world planner out of the same frame")
    token = {}
    s:tick()
    assert(s.worldJobs[1].steps == 1, "A fresh frame resumes the same world search")
    s.nav:Cancel("cleared")

    s = fixture("forever")
    APR.NavigationData.profile = "forever"
    function APR.NavigationData:HasDeferredTerrainImports() return false end
    function APR.NavigationData:BeginTerrainFrame() error("Monolithic terrain has no imports to defer") end
    s.nav:Update()
    assert(s.pathJobs[1].steps == 1)
    s.nav:Cancel("cleared")
end

do
    local timed = fixture("forever")
    APR.NavigationData.profile = "forever"
    timed.provider.RequiresWalkingProof = function() return true end
    timed.localLimit, timed.pathState, timed.expectedDelay = 4, "no_path", 0
    timed.nav:Update()
    assert(timed.pathJobs[1].milliseconds == 4 and timed.worldJobs[1].milliseconds <= 1)
    timed.milliseconds, timed.worldLimit = 30, 6
    timed:tick()
    assert(timed.worldJobs[1].milliseconds == 6, "An unpublished route can use at most six milliseconds on a long frame")
    timed.milliseconds = 39
    timed:tick()
    assert(timed.worldJobs[1].milliseconds == 3, "A short frame reduces the budget for the next transport search slice")
    timed.nav:Cancel("cleared")
end

do
    local manual = fixture("forever")
    manual.step._service, manual.step._mapWaypoint = true, true
    manual.step.target = {x=100,y=0,instanceID=1,uiMapID=101}
    local context = {service=true}
    APR.Services = {GetStep=function() return manual.step end, IsContextCurrent=function() return true end,
        CaptureContext=function() return context end, GetLabel=function() return "Pin" end}
    manual.pathState = "no_path"
    manual.nav:Update(context)
    local job = manual.worldJobs[1]
    assert(manual.nav.state == "planning" and manual.pathJobs[1].context.walkingPartialGoal)
    job.phase, job.searchFailed = "explain", true
    manual:tick()
    assert(manual.nav.state == "no_path" and manual.nav.search == job and manual.nav.destination == manual.step.target,
        "A pin can show that accessible transport failed while blocked-transport explanations continue")
    manual.nav:Cancel("cleared")
end

do
    local pin = fixture("forever")
    APR.NavigationData.profile = "forever"
    pin.provider.RequiresWalkingProof = function() return true end
    pin.step._service, pin.step._mapWaypoint = true, true
    pin.step.target = {x=1500,y=0,instanceID=1,uiMapID=102}
    pin.allowed, pin.expectedDelay, pin.worldLimit = false, 0, 4
    local context = {service=true}
    APR.Services = {GetStep=function() return pin.step end, IsContextCurrent=function() return true end,
        CaptureContext=function() return context end, GetLabel=function() return "Pin" end}
    pin.nav:Update(context)
    local job = pin.worldJobs[1]
    assert(#pin.pathJobs == 0 and pin.nav.state == "planning")
    job.phase = "search"
    pin.milliseconds = 6
    pin:tick()
    assert(job.milliseconds == 4, "An explicit map pin gets the foreground search allowance")
    pin.milliseconds = 9
    pin:tick()
    assert(job.milliseconds == 2, "The allowance still scales down after a short frame")
    pin.milliseconds = 39
    pin.worldLimit = 6
    pin:tick()
    assert(job.milliseconds == 6, "A long frame cannot raise the departure allowance above its cap")
    job.phase = "probe"
    pin.milliseconds = 45
    pin:tick()
    assert(job.milliseconds == 2, "Taxi exploration uses the ordinary foreground allowance")
    assert(job.request.previewEntryWalk)
    pin.provider.CanFollowWalkingSegment = function() return true end
    job.phase = "search"
    local entrance = {x=70,y=0,z=0,instanceID=1,uiMapID=101}
    job.entryWalkPreview = {{path={pin.position, entrance}, departure=true}}
    pin.milliseconds = 51
    pin:tick()
    local departure = pin.nav:GetActiveStep()
    assert(departure and departure.kind == "walk" and departure.path[2].x == 70 and departure.arrivalRadius == 2)
    assert(pin.nav.search == job and job.firstGuidanceMilliseconds > 0 and #pin.nav.queue == 1)
    pin.milliseconds = 57
    pin:tick()
    assert(job.milliseconds == 4 and pin.nav:GetActiveStep() == departure,
        "Publishing the departure must not throttle or restart the remaining search")
    local landing = {x=500,y=0,z=0,instanceID=1,uiMapID=102}
    local shore = {x=1000,y=0,z=0,instanceID=1,uiMapID=103}
    job.travelPreview = {
        {kind="walk", from=pin.position, to=entrance, path={pin.position, entrance}, seconds=10},
        {kind="portal", from=entrance, to=landing, seconds=3},
        {kind="boat", from=landing, to=shore, seconds=15},
    }
    pin.milliseconds = 63
    pin:tick()
    assert(pin.nav.search == job and #pin.nav.queue == 3 and pin.nav.queue[2].kind == "portal",
        "A proved approach and chain appear together before the global itinerary finishes")
    local stale = pin.nav._searchTimer.callback
    pin.position = entrance
    pin.nav:PollArrival()
    assert(pin.nav:GetActiveStep().kind == "portal" and job.cancelled)
    pin.nav:PollArrival()
    pin.position = landing
    pin.nav:PollArrival()
    assert(pin.nav:GetActiveStep().kind == "boat" and pin.nav.destination == pin.step.target,
        "An intermediate arrival retains the crossings and the original destination")
    pin.nav:PollArrival()
    pin.position = shore
    pin.nav:PollArrival()
    assert(not pin.nav:GetActiveStep() and pin.nav._stepCheckTimer and pin.nav.reason == "transport_arrived",
        "The final crossing restarts planning from the observed landing")
    pin.nav:Cancel("cleared")
    stale()
    assert(not pin.nav:GetActiveStep() and not pin.nav.search, "Cancellation discards the preliminary travel")
end

do
    local pin = fixture("forever")
    APR.NavigationData.profile = "forever"
    pin.step._service, pin.step._mapWaypoint = true, true
    pin.step.target = {x=5000,y=0,instanceID=1,uiMapID=102}
    local context = {service=true}
    APR.Services = {GetStep=function() return pin.step end, IsContextCurrent=function() return true end,
        CaptureContext=function() return context end, GetLabel=function() return "Pin" end}
    pin.nav:Update(context)
    assert(#pin.pathJobs == 0, "A new distant pin starts with the complete transport comparison")
    pin.nav:Cancel("transport_arrived")
    pin.nav:ForceRefresh("transport_arrived")
    pin.nav:Update(context)
    assert(pin.pathJobs[1].context.walkingGoalApproach == APR.NavigationConstants.Navigation.MAP_WAYPOINT_APPROACH_RADIUS,
        "A distant pin within walking access gets a budgeted approach after the final crossing")
    local stop = {x=4995,y=0,z=0,instanceID=1,uiMapID=102}
    pin.pathState = "ready"
    pin.readyPathResult = {path={pin.position,stop},seconds=730,yards=4995,partial=true,geometryVerified=false}
    pin:tick()
    assert(pin.nav.search and pin.nav:GetActiveStep().to == stop and pin.nav.waypointApproach.residualYards == 5,
        "A proved nearby stop can guide while the full trip comparison runs")
    pin.nav:Cancel("cleared")
end

for _, profile in ipairs({"forever", "retail"}) do
    local area = fixture(profile)
    APR.NavigationData.profile = profile
    area.provider.HasWalkingCoverage = function() return true end
    area.step.PickUp, area.step.Qpart, area.step.Coord.z, area.step.Range = nil, {[901]={1}}, nil, 30
    area.position.x = 84
    area.nav:Update()
    assert(area.nav.state == "ready" and not area.nav:GetActiveStep() and #area.worldJobs == 0 and #area.pathJobs == 0,
        "Starting inside an accessible outdoor objective needs no local or world route")
    local generation = area.nav.generation
    for index = 1, 20 do
        area.position.x = 90 + index
        area.nav:InvalidatePathCache("QUEST_LOG_UPDATE")
        area.nav:Update()
    end
    assert(area.nav.generation == generation and #area.worldJobs == 0 and #area.pathJobs == 0 and APRData.p.r == 1,
        "Quest refreshes within the radius reuse arrival without advancing the objective")
    area.position.x = 130
    area.nav:Update()
    assert(#area.worldJobs == 1, "The strict Range boundary restarts guidance")
    area.nav:Cancel("cleared")
end

do
    local area = fixture("forever")
    APR.NavigationData.profile = "forever"
    area.step.PickUp, area.step.Qpart, area.step.Coord.z, area.step.Range = nil, {[901]={1}}, nil, 30
    area.pathState = "ready"
    area.nav:Update()
    assert(area.nav:IsNavigating())
    area.position.x = 80
    area.allowed = false
    area.nav:PollArrival()
    assert(area.nav:IsNavigating(), "Matching XY cannot finish an objective whose access is closed")
    area.allowed = true
    area.nav:PollArrival()
    assert(area.nav.state == "ready" and not area.nav:GetActiveStep() and area.worldJobs[1].cancelled and APRData.p.r == 1,
        "Entering an accessible outdoor objective retires guidance and its remaining work")
    area.nav:Cancel("cleared")
end

local s=fixture("forever")
s.nav:Update()
assert(#s.pathJobs==1 and s.pathJobs[1].steps==1,"A nearby covered objective starts its path immediately")
assert(s.worldJobs[1].request.walkingSpeedCeiling==7,"Terrain planning receives the explicit ceiling of the current walking speed model")
assert(s.nav.state=="planning" and not s.nav:IsNavigating(),"An unfinished local query cannot publish direct guidance")
s.pathState="ready"
local before=s.milliseconds
s:tick()
assert(s.milliseconds-before<=1.000001,"Local and world jobs share one millisecond, not one each")
assert(s.nav:IsNavigating() and s.nav:GetActiveStep().path and s.nav.search==s.worldJobs[1],
    "A validated baseline guides while the same world search is still pending")
assert(not s.worldJobs[1].cancelled and s.nav.recomputeKeepingPath and APRData.p.r==1 and s.step.Range==3)
assert(s.nav:GetGuidanceTarget().y==80 and s.nav:GetRemainingWalkYards()==260)
assert(s.worldJobs[1].steps>0 and s.worldJobs[1].milliseconds<0.401,
    "The remaining slice budget continues complete transport planning")
assert(s.worldJobs[1].operations==4093,"The local work is deducted from the shared operation limit")
local first=s.worldJobs[1].firstGuidanceMilliseconds
assert(first and math.abs(first-1.2)<0.00001, "Initial guidance includes the earlier incomplete local slice")
local baseline=s.nav:GetActiveStep()
s.worldState="ready"
s.worldResult={segments={{kind="portal",from=s.position,to={x=100,y=0,z=0,instanceID=1,uiMapID=101},seconds=2}},totalSeconds=2,totalCopper=0}
s:tick()
assert(s.nav:GetActiveStep().kind=="portal" and s.nav:GetActiveStep()~=baseline and not s.nav.search,
    "A faster transport replaces the provisional walking corridor")
assert(s.nav.lastComparison and not s.nav.lastComparison.retained and APRData.p.r==1)
assert(s.nav.lastPlanning.firstGuidanceMilliseconds==first and s.nav.lastPlanning.elapsedMilliseconds>first,
    "Complete planning retains both publication and completion timestamps")
s.nav:Cancel("cleared")

do
    local background = fixture("forever")
    local calculations = 0
    function APR.currentStep:AddQuestSteps(_, text)
        if text == "NAVIGATION_CALCULATING" then calculations = calculations + 1 end
    end
    background.provider.CanFollowWalkingSegment = function() return true end
    background.pathState = "ready"
    background.nav:Update()
    local active = assert(background.nav:GetActiveStep())
    local obsolete = assert(background.nav.search)
    assert(calculations == 1, "An objective starts with visible planning feedback")
    background.nav:RefreshStalePlanningInputs()
    assert(obsolete.cancelled and background.nav:GetActiveStep() == active and background.nav:IsNavigating())
    background.nav:Update()
    assert(background.nav.search and background.nav:GetActiveStep() == active and calculations == 1,
        "Refreshing a background calculation keeps the verified path and its guidance")

    APR.navigationGeometryRevision = 1
    background.pathState = "planning"
    background.nav:Update()
    assert(background.nav.state == "planning" and not background.nav:GetActiveStep() and calculations == 1,
        "Replacing a path invalidated by geometry does not repeat the calculation message")
    background.step.Coord.y = 200
    background.nav:Update()
    assert(background.nav.state == "planning" and calculations == 2,
        "A different objective gets its own calculation message")
    background.nav:Cancel("cleared")

    local prefix = fixture("forever")
    calculations = 0
    function APR.currentStep:AddQuestSteps(_, text)
        if text == "NAVIGATION_CALCULATING" then calculations = calculations + 1 end
    end
    prefix.pathState = "ready"
    prefix.nav:Update()
    prefix.nav.walkingPrefix = assert(prefix.nav:GetActiveStep())
    prefix.position = prefix.nav.walkingPrefix.to
    prefix.nav:PollArrival()
    assert(prefix.nav.state == "planning" and prefix.nav.search and calculations == 1,
        "Finishing a verified prefix does not announce the remaining background work")
    prefix.nav:Cancel("cleared")
end

-- The ordinary guide uses a short, physically verified walk on the same
-- map without comparing unrelated transport. A long detour still compares.
for _, yards in ipairs({599, 601}) do
    s=fixture("forever")
    APR.NavigationData.profile="forever"
    s.pathState,s.pathYards="ready",yards
    s.nav:Update()
    local active=assert(s.nav:GetActiveStep())
    assert(active.path and s.pathJobs[1].context.quick and s.nav:GetGuidanceTarget().y==80)
    if yards<600 then
        assert(s.worldJobs[1].cancelled and s.worldJobs[1].steps==0 and not s.nav.search)
        s.nav:InvalidatePathCache("QUEST_LOG_UPDATE")
        s.nav:Update()
        assert(#s.pathJobs==1 and s.nav:GetActiveStep()==active)
        s.step.Coord.y=200
        s.nav:Update()
        assert(#s.pathJobs==2 and s.nav:GetActiveStep().to.x==200 and s.nav:GetActiveStep()~=active)
    else
        assert(s.worldJobs[1].steps==1 and s.nav.search==s.worldJobs[1])
    end
    s.nav:Cancel("cleared")
end

-- Two stacked walking surfaces can share an XY when the client omits Z.
for _, observation in ipairs({"cell", "altitude", "catalogue", "destination"}) do
    s=fixture("forever")
    s.position.z=nil
    s.pathState,s.pathResult="unavailable",{unresolvedSurface=true}
    s.unresolvedSurface=true
    s.unresolvedStartSurface=observation~="destination"
    s.otherDataPending=observation=="catalogue"
    s.provider.IsSameWalkingCell=function(_, a, b) return math.floor(a.x/4)==math.floor(b.x/4) end
    s.nav:Update()
    assert(not s.nav:IsNavigating() and s.nav:BlocksDirectGuidance())
    APR.Arrow.Active,APR.Arrow.x,APR.Arrow.y=true,100,12
    function APR.Arrow:SetArrowActive(active) self.Active=active end
    s.worldState="waiting_data"
    s:tick()
    assert(s.nav.state=="waiting_data" and #s.nav:GetPreview()==0 and not s.nav:GetRetainedArrow() and not APR.Arrow.Active,
        "An unknown floor cannot leave a straight line or a stale arrow on screen")
    s.now=s.now+8
    s.poll(nil,0.5)
    if s.otherDataPending then
        assert(s.nav._stepCheckTimer,"Missing catalogue data can still become ready while standing still")
    else
        s.position.x=1
        s.poll(nil,0.5)
        assert(not s.nav._stepCheckTimer,"Standing still or moving inside the same cell cannot resolve the floor")
        if observation=="destination" then
            s.position.x=5
            s.poll(nil,0.5)
            assert(not s.nav._stepCheckTimer,"Moving one cell cannot identify the floor of a distant objective")
            s.step.Coord.z=12
        elseif observation=="cell" then s.position.x=5 else s.position.z=0 end
        s.poll(nil,0.5)
        assert(s.nav._stepCheckTimer,"A new cell or an observed floor triggers a retry after a short movement")
    end
    s.pathState,s.worldState="ready","planning"
    s.nav._stepCheckTimer.callback()
    assert(#s.pathJobs==2 and s.nav:IsNavigating() and s.nav:GetGuidanceTarget().y==80,
        "Resolved terrain publishes the bend on the new route")
    s.nav:Cancel("cleared")
end

do
    local service = fixture("retail")
    APR.NavigationData.profile = "retail"
    function service.provider:HasWalkingCoverage() return true end
    function IsIndoors() return true end
    service.position.z, service.position.indoors = nil, true
    service.step._service = true
    service.step.target = {x=40,y=0,z=0,instanceID=1,uiMapID=101}
    local context = {service=true}
    APR.Services = {GetStep=function() return service.step end, IsContextCurrent=function() return true end,
        CaptureContext=function() return context end, GetLabel=function() return "Service" end}
    local otherMap = {x=1000,y=0,instanceID=1,uiMapID=102}
    service.pathState, service.pathResult = "unavailable", {unresolvedSurface=true, ambiguousFrom=true}
    service.worldState = "ready"
    service.worldResult = {segments={{kind="item",from=service.position,to=otherMap,sourceFree=true},
        {kind="walk",from=otherMap,to=service.step.target}},totalSeconds=100}
    service.nav:Update(context)
    assert(service.nav.state == "waiting_data" and service.nav.reason == "terrain_origin")
    assert(not service.nav:GetActiveStep(), "A personal travel item is no substitute for an unresolved nearby exit")
    service.nav:Cancel("cleared")
end

do
    local manual = fixture("forever")
    APR.NavigationData.profile = "forever"
    function manual.provider:CanFollowWalkingSegment() return true end
    manual.step._service, manual.step._mapWaypoint = true, true
    manual.step.target = {x=30,y=0,instanceID=1,uiMapID=101}
    local context = {service=true}
    APR.Services = {GetStep=function() return manual.step end, IsContextCurrent=function() return true end,
        CaptureContext=function() return context end, GetLabel=function() return "Pin" end}
    manual.pathState = "ready"
    manual.onPathStep = function()
        local job = manual.worldJobs[1]
        assert(job.request.allowTaxiStops)
        function job:BeginTaxiStops() error("A direct indoor pin cannot require a taxi stop") end
        local point = {x=30,y=0,instanceID=1,uiMapID=101,sharedFloorChord=true}
        manual.readyPathResult = {path={manual.position,point},seconds=5,yards=30}
    end
    manual.nav:Update(context)
    assert(manual.nav:IsNavigating() and manual.nav:GetGuidanceTarget().sharedFloorChord)
    assert(not manual.nav.search and manual.worldJobs[1].cancelled)
    manual.nav:Cancel("cleared")
end

s=fixture("forever")
debugprofilestop=nil
s.pathState="ready"
s.nav:Update()
assert(s.pathJobs[1].operations==64 and s.worldJobs[1].operations==61,
    "Clients without a profiling clock keep the combined 64-operation fallback")
s.nav:Cancel("cleared")

s=fixture("forever")
s.pathState,s.pathCost="ready",1.1
s.nav:Update()
assert(s.nav:IsNavigating() and s.worldJobs[1].steps==0,"An exhausted local slice cannot grant the world job another full millisecond")
s:tick()
assert(s.worldJobs[1].steps==1,"World work resumes in the ordinary next controller slice")
s.nav:Cancel("cleared")

s=fixture("forever")
s.pathState="ready"
s.nav:Update()
baseline=s.nav:GetActiveStep()
s.worldState="ready"
s.worldResult={segments={{kind="walk",from=s.position,to=baseline.to}},totalSeconds=100}
s:tick()
assert(s.nav:GetActiveStep()==baseline and s.nav.lastComparison.retained,"A slower complete result retains the validated baseline")
s.nav:Cancel("cleared")

s=fixture("forever")
s.pathState="ready"
s.step.Range,s.step.Coord.floor,s.position.floor=200,1,1
APR.NavigationData.IsSameAccessRegion=function(_,a,b) return a.floor==b.floor end
s.nav:Update()
baseline=s.nav:GetActiveStep()
s.nav:PollArrival()
assert(s.nav:IsNavigating() and baseline.pathCursor==2,"A large authored interaction range cannot skip terrain bends")
for _, invalid in ipairs({
    {x=100,y=0,z=0,floor=2,instanceID=1,uiMapID=101},
    {x=100,y=0,z=30,floor=1,instanceID=1,uiMapID=101},
    {x=100,y=0,floor=1,instanceID=1,uiMapID=101},
    {x=100,y=0,z=0,floor=1,instanceID=2,uiMapID=101},
    {x=100,y=0,z=0,floor=1,instanceID=1,uiMapID=102},
}) do
    s.position=invalid
    s.nav:PollArrival()
    assert(s.nav:IsNavigating() and baseline.pathCursor==2,"The final XY without matching height/access/map/world is not proof of arrival")
end
s.position={x=100,y=0,z=0,floor=1,instanceID=1,uiMapID=101}
s.nav:PollArrival()
assert(s.nav.state=="ready" and s.worldJobs[1].cancelled and APRData.p.r==1,
    "A confirmed final arrival through another path does not require visiting obsolete bends or advance the authored guide")
s.nav:Cancel("cleared")

for _, reason in ipairs({"cleared","step_changed","disabled"}) do
    s=fixture("forever")
    s.nav:Update()
    local oldTimer=s.timers[#s.timers]
    s.nav:Cancel(reason)
    assert(s.pathJobs[1].cancelled and s.worldJobs[1].cancelled,"Cancellation must stop both jobs: "..reason)
    s.pathState="ready"
    oldTimer.callback()
    assert(not s.nav:IsNavigating() and #s.nav.queue==0 and APRData.p.r==1,"An obsolete callback cannot resurrect a baseline")
end

s=fixture("forever")
s.nav:Update()
s.nav:BeginWorldLoading("PLAYER_LEAVING_WORLD")
assert(s.pathJobs[1].cancelled and s.worldJobs[1].cancelled and not s.nav.localPathJob,
    "A native world departure discards both unpublished candidates")
s.pathState="ready"
s.timers[#s.timers].callback()
assert(not s.nav:IsNavigating(),"A loading-screen callback cannot publish the retired local baseline")
s.nav:Cancel("cleared")

s=fixture("forever")
s.nav:Update()
APR.settings.profile.enableAddon=false
s:tick()
assert(s.pathJobs[1].cancelled and s.worldJobs[1].cancelled,"Disabling the addon cancels local and world work through the shared scheduler")

s=fixture("forever")
s.nav:Update()
s.pathState="ready"
s.onPathStep=function() s.step.Coord.y=200 end
s:tick()
assert(s.pathJobs[1].cancelled and s.worldJobs[1].cancelled and not s.nav:IsNavigating(),
    "A changed objective inside the provider cannot publish the old local result")
s.nav:Cancel("cleared")

s=fixture("forever")
s.pathState="unavailable"
s.nav:Update()
local fallback=s.nav:GetActiveStep()
assert(s.nav.state=="guiding" and fallback and fallback.kind=="walk" and fallback.path==nil,
    "Unavailable collision data restores authorized legacy guidance while the world search continues")
assert(math.abs(s.nav.totalSeconds-100/7)<0.00001 and not s.nav:BlocksDirectGuidance(),
    "Fallback ETA follows the ordinary walking model, without fabricating a collision polyline")
assert(not s.worldJobs[1].cancelled and s.worldJobs[1].steps==1 and APRData.p.r==1)
s.worldState="ready"
s.worldResult={segments={{kind="walk",from=s.position,to=fallback.to,
    path={s.position,{x=0,y=80,z=0,instanceID=1,uiMapID=101},fallback.to},seconds=40}},totalSeconds=40,totalCopper=0}
s:tick()
assert(s.nav:GetActiveStep()~=fallback and s.nav:GetActiveStep().path and s.nav.totalSeconds==40,
    "An estimated baseline cannot defeat a measured detour merely because its chord ETA was shorter")
s.nav:Cancel("cleared")

s=fixture("forever")
s.pathState="unavailable"
s.nav:Update()
s.worldState="no_path"
s:tick()
assert(s.nav.state=="no_path" and not s.nav:IsNavigating(),
    "A complete graph refusal retires the provisional estimate")
s.nav:Cancel("cleared")

for _, state in ipairs({"ready", "unavailable"}) do
    s=fixture("forever")
    s.pathState=state
    s.onPathStep=function() s.allowed=false end
    s.nav:Update()
    assert(not s.nav:IsNavigating(), "A revoked access permission forbids either kind of local baseline")
    s.nav:Cancel("cleared")
end

do
    s=fixture("forever")
    s.pathState="no_path"
    s.nav:Update()
    assert(s.nav.state=="planning" and not s.nav:IsNavigating() and not s.worldJobs[1].cancelled,
        "No local baseline may be fabricated after a proven no_path")
    assert(s.worldJobs[1].steps==1,"The full transport search continues after a refused local path")
    s.nav:Cancel("cleared")
end

for _, mode in ipairs({"retail","uncovered","forbidden","distant","boundary","old_provider"}) do
    s=fixture(mode=="retail" and "retail" or "forever")
    if mode=="uncovered" then s.covered=false end
    if mode=="forbidden" then s.allowed=false end
    if mode=="distant" then s.step.Coord.y=2001 end
    if mode=="boundary" then s.step.Coord.y=2000 end
    if mode=="old_provider" then s.provider.CreatePathJob=nil end
    s.nav:Update()
    assert(#s.pathJobs==0 and s.worldJobs[1].steps==1,"Baseline eligibility respects the existing contract: "..mode)
    if mode=="retail" then assert(s.worldJobs[1].request.walkingProvider==nil and s.worldJobs[1].request.walkingSpeedCeiling==nil) end
    s.nav:Cancel("cleared")
end
do
    s=fixture("forever")
    function s.provider:CanFollowWalkingSegment() return false end
    s.nav:Update()
    s.position.x = 15
    s.pathState = "ready"
    s:tick()
    assert(not s.nav:IsNavigating() and s.worldJobs[1].cancelled,
        "Moving behind a wall before publication cannot attach the player to an old corridor")
    s.nav:Cancel("cleared")
end
for _, isWaypoint in ipairs({true, false}) do
    s=fixture("forever")
    s.step.Coord.z = nil
    if isWaypoint then s.step.Waypoint, s.step.PickUp = 1, nil end
    s.nav:Update()
    local localRequest, worldRequest = s.pathJobs[1].context, s.worldJobs[1].request
    assert(localRequest.walkingGoal == s.pathJobs[1].to and worldRequest.walkingGoal == worldRequest.goal)
    assert(localRequest.walkingGoalXY and worldRequest.walkingGoalXY)
    local expectedRange = isWaypoint and 3 or nil
    assert(localRequest.walkingGoalRange == expectedRange and worldRequest.walkingGoalRange == expectedRange,
        "An authored interaction can resolve its exact surface but only a waypoint accepts an offset arrival")
    s.nav:Cancel("cleared")
end

s = fixture("forever")
APR.NavigationData.profile = "forever"
function s.provider:CanFollowWalkingSegment() return true end
local prefixEnd = {x=20,y=0,z=0,instanceID=1,uiMapID=101}
local suffixStart = {x=95,y=0,z=0,instanceID=1,uiMapID=101}
s.onPathStep = function(job)
    job.walkingPreview = {
        {kind="walk",path={job.from,prefixEnd}},
        {kind="walk",path={suffixStart,job.to},breakBefore=true},
    }
end
s.nav:Update()
assert(s.nav:IsNavigating() and s.nav:GetGuidanceTarget() == prefixEnd and s.nav.search == s.worldJobs[1],
    "The arrow starts on the verified prefix while the goal and world search stay pending")
assert(s.nav:GetPreview()[2].breakBefore, "The detached suffix cannot steer the arrow")
s.position = prefixEnd
s.nav:PollArrival()
assert(s.nav.state == "planning" and not s.nav:GetActiveStep() and s.nav.search == s.worldJobs[1],
    "Reaching the last confirmed point is neither arrival at the objective nor cancellation")
s.nav:Cancel("cleared")

s = fixture("forever")
s.pathState = "no_path"
s.nav:Update()
local departure = s.position
local arrival = {x=30,y=5,z=0,instanceID=2,uiMapID=102}
local world = s.worldJobs[1]
world.travelPreview = {{kind="zeppelin",from=departure,to=arrival,seconds=20}}
s:tick()
assert(s.nav:GetActiveStep().kind == "zeppelin" and s.nav.search == world)
s.worldState = "waiting_data"
s:tick()
assert(s.nav:GetActiveStep().kind == "zeppelin", "Missing destination terrain must not discard a verified departure")
s.position = arrival
s.nav:PollArrival()
assert(s.nav.reason == "transport_arrived" and not s.nav:GetActiveStep() and s.nav.dirty,
    "Disembarkation schedules a new plan from the observed world")
s.nav:Cancel("cleared")

s = fixture("forever")
s.nav:Update()
s.pathState = "ready"
s:tick()
assert(s.nav:IsNavigating() and s.nav.totalSeconds, "The first objective has a published itinerary")
s.nav.lastComparison = { candidateSeconds = 10 }
s.nav:Cancel("service_started")
assert(s.nav.totalSeconds == nil and s.nav.totalCopper == nil and s.nav.plannedWalkSpeed == nil
    and s.nav.lastComparison == nil and s.nav.lastPlanning == nil,
    "A new objective must not report the previous itinerary's cost or comparison while it plans")

do
    local indoor = fixture("forever")
    APR.NavigationData.profile = "forever"
    function IsIndoors() return true end
    indoor.position.z = nil
    indoor.pathState, indoor.pathResult = "unavailable", {unresolvedSurface=true, unresolvedFrom=true, ambiguousFrom=true}
    local recall = {kind="item", hearthstone=true, sourceFree=true, from=indoor.position,
        to={x=180,y=0,z=0,instanceID=1,uiMapID=101}, seconds=15}
    indoor.worldState, indoor.worldResult = "ready", {segments={recall}, totalSeconds=15}
    indoor.nav:Update()
    assert(indoor.nav.state == "waiting_data" and indoor.nav.reason == "terrain_origin" and not indoor.nav:GetActiveStep(),
        "An ambiguous indoor floor cannot make recall the default for a nearby guide objective")
    indoor.position.x = 2
    indoor.pathState = "ready"
    function indoor.provider:GetWalkingObservationHeight(point, previous)
        if point.x == 2 then return 0 end
        if point.x == 3 and previous and previous.x == 2 then return previous.z end
    end
    indoor.nav:Update()
    assert(indoor.nav:GetActiveStep().kind == "walk" and indoor.pathJobs[2].from.z == 0,
        "New floor evidence resumes local guidance on the same guide step")
    indoor.nav:Cancel("step_changed")
    indoor.position.x, indoor.now = 3, indoor.now + 0.5
    indoor.nav:Update()
    assert(indoor.pathJobs[3].from.z == 0 and indoor.position.z == nil,
        "A nearby observation remains available to the next guide step without changing native position data")
    indoor.nav:Cancel("cleared")
end

print("Terrain local baseline: validated early guidance, one shared budget/scheduler, faster transport replacement, stable retention, cancellation and Retail passed")
