-- An exit prefix completes navigation's local layer, never the authored step.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({connections={}})
local function point(x,region)return {instanceID=8,uiMapID=101,x=x,y=0,z=0,region=region}end
local inside,outside,goal=point(0,"inside"),point(100,"outside"),point(500,"outside")
local context={route="invented",index=1,revision=1}
APR.settings,APR.ActiveRoute,APR.PlayerID={profile={enableAddon=true}},"invented","player"
APRData={player={invented=4}}
function APR:NewModule()return {}end
function APR:CaptureStepContext()return context end
function APR:IsStepContextCurrent(value)return value==context end
function APR:GetNavigationPlayerPosition()return fixture.player end
function UnitIsDeadOrGhost()return false end
function UnitOnTaxi()return false end
local timers={}
C_Timer={NewTimer=function(_,callback)
    local timer={callback=callback,Cancel=function(self)self.cancelled=true end}
    timers[#timers+1]=timer;return timer
end}
dofile("APR-Core/features/navigation/Navigation.lua")
local nav=APR.navigation
local ready,replans=0,0
nav.Notify=function()end
nav.MarkRouteReady=function()ready=ready+1 end
nav.Update=function(self,value)
    replans=replans+1
    assert(value==context and self.destination==goal and fixture.player==outside,
        "The next plan uses the real outside observation and retains the original authored objective")
end
local function publish(kind)
    fixture.player=inside
    nav.state,nav.context,nav._routedStepContext,nav.destination,nav.start="planning",context,context,goal,inside
    nav.zoneReady=true -- Exercise the single ordinary-walk publication shortcut.
    local row=nav:PrepareGuidanceStep({kind=kind,from=inside,to=outside,seconds=10},1,nav.generation,inside)
    local generation=nav.generation
    nav:Publish({queue={row},totalSeconds=10,localExitOnly=true,exitSpace="outside"},context,generation)
    assert(nav.state=="guiding" and nav.localExitOnly and ready==0,
        "A single local exit walk cannot trigger the authored-destination ready shortcut")
    fixture.player=outside
    nav:PollArrival()
    assert(nav.state=="planning" and nav.dirty and ready==0 and not nav.localExitOnly,
        "Reaching the exit schedules another plan instead of completing the objective")
    assert(nav.destination==goal and nav.context==context and nav.generation==generation and APRData.player.invented==4)
    local timer=table.remove(timers,1)
    assert(timer and not timer.cancelled)
    timer.callback()
end
publish("walk")
assert(replans==1)
nav:Cancel("cleared")
publish("portal")
assert(replans==2 and nav._transitionArrival==nil,
    "A completed localized portal exit cannot resume the retired prefix as though it were a complete journey")
nav:Cancel("cleared")
fixture.player=inside
nav.state,nav.context,nav._routedStepContext,nav.destination="planning",context,context,goal
nav.zoneReady=false
local row=nav:PrepareGuidanceStep({kind="walk",from=inside,to=outside,seconds=10},1,nav.generation,inside)
nav:Publish({queue={row},localExitOnly=true},context,nav.generation)
assert(nav.localExitOnly)
nav:Cancel("cleared")
assert(not nav.localExitOnly,"Cancellation cannot leak a local-only marker into a later full route")
print("Local exit controller: original objective, outside replan, single-walk guard, localized portals and cancellation")
