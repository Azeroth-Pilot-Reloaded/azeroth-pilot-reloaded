-- Controlled corridor observations; no maintained guide or terrain coordinates.
local function noop() end
local function point(x, y, z)
    return {x=x,y=y,z=z,instanceID=7,uiMapID=71,region="field"}
end
local function fixture(version)
    local s = {position=point(0,0,12), height=12, clear=true, notices=0, timers=0}
    function LibStub() return {GetLocale=function() return {} end} end
    function CreateFrame() return {SetScript=noop,RegisterEvent=noop} end
    function UnitIsDeadOrGhost() return false end
    function UnitOnTaxi() return false end
    C_Timer={NewTimer=function() s.timers=s.timers+1; return {Cancel=noop} end}
    APR={ActiveRoute="synthetic",settings={profile={enableAddon=true}},GAME_VERSIONS={Forever="forever"}}
    APRData={synthetic=4}
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return version or "forever" end
    function APR:GetNavigationPlayerPosition() return s.position end
    function APR:IsStepContextCurrent(context) return context==s.context end
    function APR:GetCurrentStep() return {Range=200} end
    local provider={HasMap=function() return true end}
    function provider:GetGuidanceHeight(observed)
        s.heightReads=(s.heightReads or 0)+1
        if type(s.height)=="function" then return s.height(observed) end
        return s.height
    end
    function provider:CanFollowWalkingSegment(a,b)
        s.sightReads=(s.sightReads or 0)+1
        return s.clear
    end
    s.provider=provider
    APR.NavigationData={GetWalkingProvider=function() return provider end,
        IsSameAccessRegion=function(_,a,b)
            return a.floor==b.floor and a.accessKey==b.accessKey and a.region==b.region
        end}
    dofile("APR-Core/features/navigation/Navigation.lua")
    s.nav=APR.navigation
    function s.nav:Notify() s.notices=s.notices+1 end
    function s.nav:ClearNavigationUiLines() end
    function s.nav:RequestUpdate() end
    function s.nav:MarkRouteReady() self.state="ready" end
    function s:route(path)
        self.context={}
        self.nav.context=self.context
        self.leg={kind="walk",path=path,pathCursor=2,from=path[1],to=path[#path]}
        self.nav.queue,self.nav.cursor,self.nav.state={self.leg},1,"guiding"
        return self.leg
    end
    function s:poll(observed)
        self.position=observed
        self.nav:PollArrival()
    end
    s:route({point(0,0,12),point(20,0,12),point(20,30,12),point(60,30,12)})
    return s
end

local s=fixture()
s:poll(point(20,0))
assert(s.leg.pathCursor==3,"A unique terrain surface resolves absent player height and releases the reached bend")
assert(s.position.z==nil and s.nav:GetGuidanceTarget()==s.leg.path[3],"Height resolution owns its snapshot and updates only the guidance target")
assert(s.nav.cursor==1 and APRData.synthetic==4 and s.timers==0)
s:poll(point(20,30))
assert(s.leg.pathCursor==4)
s:poll(point(60,30))
assert(s.nav.state=="ready" and APRData.synthetic==4,"Resolved final arrival returns to the unchanged authored objective")

do
    local indoor = fixture()
    local now = 1
    function GetTime() return now end
    function IsIndoors() return true end
    function indoor.provider:GetWalkingObservationHeight(position, previous)
        if position.x == 0 then return 0 end
        if previous and position.x - previous.x == 2 then return previous.z end
    end
    local nav, provider = indoor.nav, indoor.provider
    assert(nav:ObserveWalkingPosition(point(0, 0), provider).z == 0)
    nav:Cancel("step_changed")
    now = 1.5
    assert(nav:ObserveWalkingPosition(point(2, 0), provider).z == 0)
    now = 2
    assert(nav:ObserveWalkingPosition(point(4, 0), provider).z == 0)
    now = 3
    assert(nav:ObserveWalkingPosition(point(4, 0), provider).z == 0)
    now = 13
    assert(nav:ObserveWalkingPosition(point(4, 0), provider).z == nil)
    nav:ObserveWalkingPosition(point(0, 0), provider)
    APR.navigationGeometryRevision = 1
    assert(nav:ObserveWalkingPosition(point(2, 0), provider).z == nil)
    nav:ObserveWalkingPosition(point(0, 0), provider)
    nav:BeginWorldLoading("LOADING_SCREEN_ENABLED")
    assert(nav:ObserveWalkingPosition(point(2, 0), provider).z == nil)
    GetTime, IsIndoors = nil, nil
end

do
    local radius = fixture()
    radius:poll(point(9.99,0,12))
    assert(radius.leg.pathCursor==2, "An intermediate target has a ten-yard horizontal radius")
    radius:poll(point(10,0,12))
    assert(radius.leg.pathCursor==3, "The ten-yard boundary counts at the same height")

    radius = fixture()
    radius:poll(point(30,12,12))
    assert(radius.leg.pathCursor==3, "The outgoing corridor uses the full ten-yard tolerance after passing a bend")

    radius = fixture()
    radius:poll(point(10,0,18))
    assert(radius.leg.pathCursor==2, "The wider horizontal radius cannot bypass the height check")
    local outgoing = radius.leg.path[3]
    function radius.provider:CanFollowWalkingSegment(from, to)
        return to~=outgoing or from.x>=20
    end
    radius:poll(point(10,0,12))
    assert(radius.leg.pathCursor==2, "The outgoing leg must be reachable before releasing a corner")

    radius = fixture()
    radius.leg.arrivalRange, radius.leg.pathCursor = 5, #radius.leg.path
    function APR.NavigationData:IsServiceArrival() return true end
    radius:poll(point(60,24.99,12))
    assert(radius.nav.state=="guiding", "Final arrival still needs the five-yard radius")
    radius:poll(point(60,25,12))
    assert(radius.nav.state=="ready")
end

do
    local moving = fixture()
    APR.NavigationData.profile = "forever"
    function APR.NavigationData:CanWalk(a,b) return self:IsSameAccessRegion(a,b) end
    function moving.nav:IsObjectiveCurrent() return true end
    moving.nav.dirty = false
    local start, bend, goal = point(0,0,12), point(130,0,12), point(150,30,12)
    moving:route({start,bend,goal})
    moving.nav._routeInputs = {position=start,indoors=false,startedAt=0}
    local originalTime = GetTime
    GetTime = function() return 10 end
    local observed = point(110,0,12)
    assert(not moving.nav:HasPlanningInputsChanged(observed), "Following a proven long leg should not restart the planner")
    assert(moving.nav._routeInputs.position == observed and moving.leg.pathCursor == 2)
    GetTime = function() return 20 end
    assert(moving.nav:HasPlanningInputsChanged(point(110,120,12)), "Moving off the corridor still triggers replanning")
    GetTime = originalTime
end

do
    local border = fixture()
    APR.NavigationData.profile = "forever"
    function APR.NavigationData:CanWalk(a,b) return self:IsSameAccessRegion(a,b) end
    function border.provider:RequiresWalkingProof() return true end
    function border.nav:IsObjectiveCurrent() return true end
    border.nav.dirty = false
    border.nav._routeInputs = { position=border.position, indoors=false, startedAt=0, geometryRevision=1 }
    APR.navigationGeometryRevision = 2
    local across = point(20,0)
    across.uiMapID = 72
    assert(border.nav:HasPlanningInputsChanged(across) == false)
    border:poll(across)
    assert(border.leg.pathCursor == 3, "The map label changes while the walking corridor continues")
    across = point(20,30)
    across.uiMapID, across.region = 73, "separate"
    assert(border.nav:HasPlanningInputsChanged(across) == true, "Region boundaries still require a new plan")
    border:poll(across)
    assert(border.leg.pathCursor == 3)

    local originalIndoors = IsIndoors
    IsIndoors = function() return false end
    local threshold = point(20,0)
    threshold.uiMapID = 72
    border.nav._routeInputs.indoors = true
    assert(not border.nav:HasPlanningInputsChanged(threshold), "A confirmed corridor survives crossing the threshold on the same map")
    border.nav._routeInputs.indoors = true
    border.clear = false
    assert(border.nav:HasPlanningInputsChanged(threshold), "A threshold observation cannot preserve an unproven leg")
    IsIndoors = originalIndoors
end

for _, height in ipairs({12,false}) do
    s=fixture()
    s.height=height or nil
    s:poll(point(20,0))
    assert(s.leg.pathCursor==(height and 3 or 2),"An ambiguous or unavailable surface cannot supply player height")
end

-- The poll on the incoming segment and the next poll miss the radius at the bend.
do
    s=fixture()
    s:poll(point(12,0,12))
    s:poll(point(20,9,12))
    assert(s.leg.pathCursor==3 and s.nav.cursor==1,"Passing a turn onto its outgoing corridor must release the old target")
    assert(s.nav:GetGuidanceTarget()==s.leg.path[3] and s.timers==0)
    local notices=s.notices
    s:poll(point(20,9,12))
    assert(s.leg.pathCursor==3 and s.notices==notices,"An unchanged observation cannot churn guidance notifications")
end

do
    local guarded = fixture()
    local leg = guarded.leg
    leg.path[2].mandatory = true
    guarded:poll(point(20,12,12))
    assert(leg.pathCursor == 2, "Projection cannot consume a required vertex")
    guarded:poll(point(60,30,12))
    assert(guarded.nav.state == "guiding", "Standing at the endpoint cannot bypass a required vertex")
    guarded:poll(point(20,0,12))
    assert(leg.pathCursor == 3, "Observing the required vertex releases its outgoing leg")

    guarded = fixture()
    local following = guarded.leg.path[3]
    function guarded.provider:CanFollowWalkingSegment(_, destination)
        return destination ~= following
    end
    guarded:poll(point(20,9,12))
    assert(guarded.leg.pathCursor == 2, "The outgoing edge must be accessible from the observed player")
end
s=fixture("retail")
s:poll(point(20,0,12))
assert(s.leg.pathCursor==3 and not s.heightReads and not s.sightReads,"Retail retains its known-height arrival without a terrain dependency")

-- Two adjacent bend radii overlap. XY samples miss both until the player
-- leaves stacked terrain on the far side of the second bend.
for _, scenario in ipairs({"resume", "wall", "upper", "hairpin"}) do
    s=fixture()
    local exit=scenario=="hairpin" and point(0,4,12) or point(48,4,12)
    s:route({point(1,-2,12),point(20,0,12),point(20,4,12),exit,point(60,40,12)})
    s:poll(point(8,-1))
    s.height=nil
    s:poll(point(20,3))
    assert(s.leg.pathCursor==2,"Overlapping XY must wait for a resolved surface")
    if scenario~="upper" then s.height=12 end
    if scenario=="wall" then
        function s.provider:CanFollowWalkingSegment(from) return from~=s.leg.path[2] end
    end
    s:poll(scenario=="hairpin" and point(10,2) or point(32,4,scenario=="upper" and 35 or nil))
    if scenario=="resume" then
        assert(s.nav:GetGuidanceTarget()==exit,"Recover both missed bends from the first unambiguous outgoing sample")
        local notices=s.notices
        s:poll(point(20,0))
        assert(s.leg.pathCursor==4 and s.notices==notices,"Backtracking after recovery never rewinds the cursor")
    else
        assert(s.leg.pathCursor==2,"Unsafe pair recovery: "..scenario)
    end
end

for _, mandatory in ipairs({false, true}) do
    s=fixture()
    local path={point(0,0,12),point(20,0,12),point(20,5,12),point(25,5,12),point(25,20,12),point(65,20,12)}
    path[3].mandatory=mandatory
    s:route(path)
    s:poll(point(38,20,12))
    assert(s.leg.pathCursor==(mandatory and 2 or 6),
        "A late observation projects onto a forward edge without passing required bends")
end

do
    local moving = fixture()
    APR.NavigationData.profile = "forever"
    function APR.NavigationData:CanWalk(a, b) return self:IsSameAccessRegion(a, b) end
    function moving.nav:IsObjectiveCurrent() return true end
    local path = {point(0,0,12), point(5,0,12), point(10,0,12), point(15,0,12),
        point(20,0,12), point(25,0,12), point(35,0,12), point(55,0,12)}
    for _, vertex in ipairs(path) do vertex.geometryVerified = true end
    moving:route(path)
    function moving.provider:CanFollowWalkingSegment(from, to, joining)
        if from.geometryVerified and to.geometryVerified then return true end
        if from.geometryVerified then return false end
        return joining and math.abs(from.y) < 3 and math.abs(from.x - to.x) <= 20 or from.y == 0
    end

    local observed = point(19,2)
    local _, reachable = moving.nav:AdvanceWalkingPath(moving.leg, observed, moving.provider, true)
    assert(reachable and moving.nav:GetGuidanceTarget() == path[7],
        "A path calculated from an older position must publish ahead of a player who passed several vertices")
    assert(observed.z == nil and moving.notices == 0, "Candidate alignment is silent and owns its height snapshot")

    moving:route(path)
    moving:poll(observed)
    assert(moving.nav:GetGuidanceTarget() == path[7] and moving.notices == 1,
        "A published path also follows the forward corridor after a late observation")
    assert(moving.nav.cursor == 1 and APRData.synthetic == 4 and moving.timers == 0)
    local originalTime = GetTime
    GetTime = function() return 10 end
    local bend, goal = point(150,0,12), point(170,0,12)
    bend.geometryVerified, goal.geometryVerified = true, true
    moving:route({path[1], bend, goal})
    moving.nav._routeInputs = {position=path[1], indoors=false, startedAt=0}
    local farther = point(133,2)
    assert(not moving.nav:HasPlanningInputsChanged(farther),
        "A short, proven join to the current corridor prevents an unnecessary replan after substantial movement")
    moving.nav._routeInputs.position, moving.nav._routeInputs.startedAt = path[1], 0
    assert(moving.nav:HasPlanningInputsChanged(point(133,4)), "An unproven join can still trigger replanning")
    GetTime = originalTime
end

do
    local outdoor = fixture()
    APR.NavigationData.profile = "forever"
    function APR.NavigationData:CanWalk(a, b) return self:IsSameAccessRegion(a, b) end
    function outdoor.nav:IsObjectiveCurrent() return true end
    local originalIndoors, originalTime = IsIndoors, GetTime
    IsIndoors, GetTime = function() return false end, function() return 10 end
    local path = {}
    for x = 0, 110, 10 do path[#path + 1] = point(x, 0, 12) end
    outdoor:route(path)
    local blocked, probes = false, 0
    function outdoor.provider:CanFollowWalkingSegment(from, to, joining)
        if joining == "outdoor" then
            probes = probes + 1
            return not blocked and from.z == to.z and (to.x == 70 or to.x == 30)
        end
        return false
    end

    local observed = point(38,28)
    local _, reachable = outdoor.nav:AdvanceWalkingPath(outdoor.leg, observed, outdoor.provider, true)
    assert(reachable and outdoor.leg.pathCursor == 5 and outdoor.nav:GetGuidanceTarget() == path[8],
        "A late result starts at the closest forward segment and aims further along a clear chord")
    assert(outdoor.notices == 0 and observed.z == nil)

    outdoor:route(path)
    outdoor.nav._routeInputs = {position=path[1], indoors=false, startedAt=0}
    probes = 0
    outdoor:poll(observed)
    assert(outdoor.leg.pathCursor == 5 and outdoor.nav:GetGuidanceTarget() == path[8] and outdoor.notices == 1)
    assert(math.abs(outdoor.nav:GetRemainingWalkYards() - (math.sqrt(32^2 + 28^2) + 40)) < 1e-8,
        "The ETA follows the same clear chord as the arrow")
    assert(not outdoor.nav:HasPlanningInputsChanged(observed), "A visible forward aim retains the path beyond the stray radius")
    local used = probes
    outdoor:poll(observed)
    assert(used > 0 and used <= 11 and probes == used and outdoor.notices == 1,
        "The follower bounds terrain probes and reuses an unchanged observation")

    blocked = true
    local stray = point(58,40)
    outdoor:poll(stray)
    assert(outdoor.leg.pathCursor == 5 and not outdoor.leg.pathAimIndex)
    assert(outdoor.nav:HasPlanningInputsChanged(stray), "Leaving the corridor without a clear aim requests a fresh plan")
    assert(outdoor.nav.cursor == 1 and APRData.synthetic == 4 and outdoor.timers == 0)

    blocked = false
    path[4].mandatory = true
    outdoor:route(path)
    outdoor:poll(observed)
    assert(outdoor.leg.pathCursor <= 4 and outdoor.nav:GetGuidanceTarget() == path[4],
        "Look-ahead stops at a required point even when the ground beyond it is visible")

    path[4].mandatory = nil
    outdoor:route(path)
    outdoor:poll(point(38,28,30))
    assert(outdoor.leg.pathCursor == 2 and not outdoor.leg.pathAimIndex, "A different surface cannot claim forward progress")

    outdoor:route({point(0,0,12), point(200,0,12), point(220,0,12)})
    function outdoor.provider:CanFollowWalkingSegment(from, to, joining)
        return joining == "outdoor" and math.abs(to.x - from.x) <= 80
    end
    outdoor:poll(point(100,28))
    assert(outdoor.leg.pathCursor == 2 and outdoor.nav:GetGuidanceTarget().x == 170,
        "On a sparse straight leg the aim slides along the segment")
    outdoor:poll(point(102,28))
    assert(outdoor.nav:GetGuidanceTarget().x == 172 and outdoor.leg.pathCursor == 2)

    local straight = {}
    for x = 0, 280, 10 do straight[#straight + 1] = point(x, 0, 12) end
    outdoor:route(straight)
    outdoor:poll(point(182, 2, 12))
    assert(outdoor.leg.pathCursor == 20 and outdoor.nav:GetGuidanceTarget().x == 252,
        "A live observation beyond the original recovery window aims ahead in one poll")

    outdoor:route(straight)
    outdoor.leg.pathCursor = 4
    outdoor.height = nil
    local notices = outdoor.notices
    outdoor:poll(point(55, 6))
    assert(outdoor.leg.pathCursor == 4 and outdoor.nav:GetGuidanceTarget() == nil,
        "An unresolved floor after passing several bends cannot steer back to the stale point")
    outdoor:poll(point(55, 6))
    assert(outdoor.notices == notices + 1, "A stationary unresolved observation does not republish guidance")
    outdoor:poll(point(57, 25))
    assert(outdoor.nav:GetGuidanceTarget() == nil, "Moving farther away does not restore the discarded bearing")
    outdoor:poll(point(57, 2, 12))
    assert(outdoor.nav:GetGuidanceTarget().x == 127 and outdoor.notices == notices + 2,
        "A proven forward target restores guidance as soon as the surface is observed again")
    assert(outdoor.nav.cursor == 1 and APRData.synthetic == 4 and outdoor.timers == 0)

    straight[4].mandatory = true
    outdoor:route(straight)
    outdoor.leg.pathCursor = 4
    outdoor:poll(point(55, 6))
    assert(outdoor.nav:GetGuidanceTarget() == straight[4], "A required point remains the target without floor evidence")

    local origin, behind, nextVertex, goal = point(0, 0, 12), point(-2, 0, 12), point(4, 0, 12), point(38, 0, 12)
    outdoor:route({origin, behind, nextVertex, goal})
    function outdoor.provider:CanFollowWalkingSegment(from, to)
        if from == behind or from == nextVertex then return true end
        return to == behind or (to.x >= from.x and to.x <= from.x + 1)
    end
    local _, reachable = outdoor.nav:AdvanceWalkingPath(outdoor.leg, origin, outdoor.provider, true)
    assert(reachable and outdoor.nav:GetGuidanceTarget().x == 1,
        "Publish a proven short bearing ahead when the first grid vertex is behind the departure")
    outdoor:poll(point(2, 0, 12))
    assert(outdoor.nav:GetGuidanceTarget().x == 3,
        "Moving past the short bearing uses a new point ahead on the same edge")
    behind.mandatory = true
    outdoor:route({origin, behind, nextVertex, goal})
    outdoor:poll(origin)
    assert(outdoor.nav:GetGuidanceTarget() == behind, "A mandatory bend still takes precedence over the short aim")

    IsIndoors, GetTime = originalIndoors, originalTime
end

s=fixture()
s:route({point(0,0,12),point(40,0,12),point(0,4,12),point(0,60,12)})
s:poll(point(10,0,12))
assert(s.leg.pathCursor==2,"A nearby return edge of a hairpin cannot steal progress from the incoming edge")
s:poll(point(39,12,12))
assert(s.leg.pathCursor==2,"Being beyond the turn outside its outgoing corridor is not progress")

s=fixture()
s:route({point(0,0,12),point(20,0,12),point(20,30,42),point(60,30,42)})
s.height=function(observed) return 12+observed.y end
s:poll(point(20,12,24))
assert(s.leg.pathCursor==3,"Passed-turn height follows the outgoing slope, not the old turn's altitude")

s=fixture()
s:route({point(0,0,12),point(20,0,12),point(20,50,12),point(60,50,12)})
s.height=24
s:poll(point(20,15,24))
assert(s.leg.pathCursor==3,"The cached surface at the projection handles a hill between equal-height path vertices")

for _, invalid in ipairs({
    point(20,9,35), -- wrong known floor height
    point(30.01,12,12), -- outside the ten-yard outgoing corridor
    point(20,-11,12), -- still before the turn and outside its reach radius
    {x=20,y=9,z=12,instanceID=8,uiMapID=71,region="field"},
    {x=20,y=9,z=12,instanceID=7,uiMapID=72,region="field"},
    {x=20,y=9,z=12,instanceID=7,uiMapID=71,region="other"},
    {x=20,y=9,z=12,instanceID=7,uiMapID=71,region="field",floor=2},
    {x=20,y=9,z=12,instanceID=7,uiMapID=71,region="field",accessKey="closed"},
}) do
    s=fixture()
    s:poll(invalid)
    assert(s.leg.pathCursor==2 and s.nav.cursor==1,"World, map, floor, access, height and corridor guards remain authoritative")
end
for _, clear in ipairs({false,"unavailable"}) do
    s=fixture()
    s.clear=false
    if clear=="unavailable" then s.clear=nil end
    s:poll(point(20,9,12))
    assert(s.leg.pathCursor==2,"A wall or unavailable terrain proof cannot be bypassed by projection")
    s:poll(point(20,0,12))
    assert(s.leg.pathCursor==2,"Proximity across a wall is not a reached turn")
end

s=fixture()
s.provider.GetGuidanceHeight=nil
s:poll(point(20,0))
assert(s.leg.pathCursor==2,"An old provider cannot invent an unknown height")
s:poll(point(20,0,0))
assert(s.leg.pathCursor==2 and not s.heightReads,"A known native zero height is not replaced with terrain height")

s=fixture()
s.nav.worldLoading=true
s:poll(point(20,9,12))
assert(s.leg.pathCursor==2 and not s.sightReads,"Loading cannot advance a retired corridor")
s.nav.worldLoading=false
s.context={}
s:poll(point(20,9,12))
assert(s.nav.state=="ready" and #s.nav.queue==0,"A changed guide context discards the old corridor")
s=fixture()
local retired=s.leg
s.nav:Cancel("cleared")
s:poll(point(20,9,12))
assert(retired.pathCursor==2 and #s.nav.queue==0,"Cancellation cannot resurrect a cursor")

s=fixture()
local dense={}
for i=1,150 do dense[i]=point(0,0,12) end
dense[151]=point(100,0,12)
s:route(dense)
s:poll(point(0,0))
assert(s.leg.pathCursor==66,"A poll advances at most 64 coincident nodes")
assert(s.timers==0,"Cursor following adds no timer")

-- Join the controller with the real terrain provider, rather than relying on
-- the stub's proof contract for the reported unknown-height mechanism.
LibStub=nil
local F=dofile("tests/lua/terrain_runtime_fixture.lua")
local lib=F.load()
local realProvider=F.provider(lib)
local start,bend,following,goal=F.point(1,1),F.point(1,2,0),F.point(4,2,0),F.point(4,5,0)
assert(F.finish(realProvider:CreatePathJob(F.point(1,1,0),goal,{walkSpeed=7}))=="ready")
for _,p in ipairs({start,bend,following,goal}) do p.uiMapID,p.region=71,"field" end
s=fixture()
APR.NavigationData.GetWalkingProvider=function() return realProvider end
s:route({start,bend,following,goal})
local observed={x=bend.x+9,y=bend.y,instanceID=900,uiMapID=71,region="field"}
s:poll(observed)
assert(s.leg.pathCursor==3 and observed.z==nil,"Real cached ground resolves unknown Z and recognizes the passed bend")
observed={x=following.x,y=following.y,instanceID=900,uiMapID=71,region="field"}
s:poll(observed)
assert(s.leg.pathCursor==4 and APRData.synthetic==4)
observed={x=goal.x,y=goal.y,instanceID=900,uiMapID=71,region="field"}
s:poll(observed)
assert(s.nav.state=="ready" and observed.z==nil and s.timers==0,"The real provider releases final guidance without mutating observations or guide progress")

-- Resume polling past two close bends on the resident synthetic terrain.
local closeBend={x=bend.x+3,y=bend.y+2,z=0,instanceID=900,uiMapID=71,region="field"}
s:route({start,bend,closeBend,following,goal})
s:poll({x=start.x+2,y=start.y-3,instanceID=900,uiMapID=71,region="field"})
assert(s.leg.pathCursor==2)
local beforeRecovery=s.notices
s:poll({x=closeBend.x+14,y=closeBend.y,instanceID=900,uiMapID=71,region="field"})
assert(s.nav:GetGuidanceTarget()==following and s.notices==beforeRecovery+1,
    "The resident terrain confirms both missed turns after an off-centre departure")
print("Terrain guidance cursor: unknown/known height, passed turns, blockers, access, cancellation and bounded work passed")
