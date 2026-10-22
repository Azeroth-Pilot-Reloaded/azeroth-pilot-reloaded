local function noop() end
local clock, x, y, dead, inTaxi = 10, 0, 0, false, false
local timers = {}
function GetTime() return clock end
function UnitPosition() return x, y, 0, 0 end
function UnitIsDeadOrGhost() return dead end
function UnitOnTaxi() return inTaxi end
function GetMoney() return 100 end
function IsFlyableArea() return true end
function IsIndoors() return false end
function CreateVector2D(a,b) return {x=a,y=b} end
function CreateFrame() return { RegisterEvent=noop, SetScript=noop } end
function LibStub() return { GetLocale=function() return setmetatable({}, {__index=function(_,k) return k end}) end } end
C_Timer = { NewTimer=function(delay,callback)
    local timer={callback=callback,delay=delay,Cancel=function(self) self.cancelled=true end}
    timers[#timers+1]=timer; return timer
end }
C_Map = { GetBestMapForUnit=function() return x < 10000 and 2 or 3 end,
    GetWorldPosFromMapPos=function() return 0 end }
APR={ PlayerID="p", ActiveRoute="r", RouteQuestStepList={r={}}, stepRevision=0,
    settings={profile={enableAddon=true}}, GAME_VERSIONS={Forever="forever"},
    currentStep={AddQuestSteps=noop,AddQuestDivider=noop,AddStepButton=noop},
    Arrow={SetCoord=noop}, event={QueueStepRefresh=noop}, SendMessage=noop }
function APR:NewModule() return {} end
function APR:GetGameVersion() return "forever" end
local step={Zone=3,Coord={x=0,y=20000,mapID=3}}
function APR:GetCurrentStep() return step,1,{step} end
function APR:GetCurrentRouteMapIDsAndName() return {3},3 end
function APR:GetStepCoord(s) return s.Coord,3 end
function APR:GetPreferredStepZone(s) return s.Zone end
function APR:CheckNavigationZoneReady() return false end
APRData={p={r=1}}
dofile("APR-Core/features/questing/StepTransitions.lua")
APR.NavigationData={}
function APR.NavigationData:CanWalk(a,b) return a.uiMapID==b.uiMapID end
function APR.NavigationData:BuildEdges()
    return {{id="portal",from={x=100,y=0,instanceID=0,uiMapID=2},
        to={x=15000,y=0,instanceID=0,uiMapID=3},kind="portal",seconds=5,instruction="Take portal"}},{}
end
APR.taxiData={BuildEdges=function() return {},{} end}
APR.NavigationEngine = dofile("tests/lua/navigation_engine_fixture.lua").Engine
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav=APR.navigation
local function FinishPlanning()
    while nav.search do
        local timer=table.remove(timers,1)
        assert(timer,"Search must be scheduled")
        if not timer.cancelled then timer.callback() end
    end
end
nav:Update()
FinishPlanning()
assert(nav:IsNavigating() and #nav.queue==3,"Full walk/portal/walk itinerary must be retained")
assert(nav:GetActiveStep().kind=="walk")
x=100;nav:PollArrival()
assert(nav:GetActiveStep().kind=="portal" and APRData.p.r==1)
nav:PollArrival();x=15000;nav:PollArrival()
assert(nav:GetActiveStep().kind=="walk" and APRData.p.r==1)
x=20000;nav:PollArrival()
assert(nav:GetState()=="ready" and APRData.p.r==1,"Synthetic completion must never advance authored route")

x=0;nav:ForceRefresh();nav:Update()
FinishPlanning()
local generation=nav.generation
local context=APR:CaptureStepContext()
nav:ForceRefresh();nav:Update()
nav:Publish({segments={}},context,generation)
assert(nav:IsNavigating(),"A callback from a replaced itinerary at the same route step must be ignored")
dead=true;nav:Update()
assert(not nav:IsNavigating() and APRData.p.r==1,"Death cancels guidance without changing progress")
dead=false;nav:ForceRefresh();nav:Update()
APR:SetRouteProgress("r",2,"manual_skip")
assert(not nav:IsNavigating() and APRData.p.r==2,"A real route change cancels old guidance")
assert(nav:GetThreshold()==2000)
function APR:GetGameVersion() return "retail" end
C_PlayerInfo={GetGlidingInfo=function() return false,true,0 end}
assert(nav:GetThreshold()==10000)
C_PlayerInfo.GetGlidingInfo=function() return false,false,0 end
assert(nav:GetThreshold()==2000)
print("Navigation controller: complete transient itinerary, independent arrivals, generation guards, death/progress and client thresholds passed")
