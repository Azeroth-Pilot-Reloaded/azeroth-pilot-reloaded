-- A reset must skip travel anchored to a rewarded quest, using real handlers.
local function noop() end
function LibStub() return {GetLocale=function() return {} end} end
local rewarded=false
C_QuestLog={IsQuestFlaggedCompleted=function(q) assert(q==42);return rewarded end}
APRData={player={route=1}}
local advances=0
local function advance()
    advances=advances+1
    APRData.player.route=APRData.player.route+1
end
APR={stepHandlers={},PlayerID='player',ActiveRoute='route',Debug=noop,
    settings={profile={}},GetHearthstoneItemID=function() return 6948 end,
    NextQuestStep=advance,UpdateNextStep=advance}
dofile('APR-Core/features/questing/StepTravelHandlers.lua')
for _,kind in ipairs({'Waypoint','SetHS','UseHS','UseFlightPath'}) do
    local step={[kind]=42,NonSkippableWaypoint=true}
    rewarded=false;advances=0;APRData.player.route=1
    APR.stepHandlers[kind](step,false)
    assert(advances==0 and APRData.player.route==1,'An unfinished quest must retain its action: '..kind)
    rewarded=true
    for reset=1,3 do
        advances=0;APRData.player.route=1
        APR.stepHandlers[kind](step,false)
        assert(advances==1 and APRData.player.route==2,'A rewarded quest must skip after every reset: '..kind)
    end
end
APR.GetRouteActionUsability=function() return false,'cooldown' end
rewarded=false;advances=0
APR.stepHandlers.UseHS({UseHS=42,UseHSIfAvailable=true},false)
assert(advances==1,'The explicit optional-HS condition retains its fallback')
local arrivals=0
APR.stepHandlers.Transport=function(step) assert(step.ZoneStepTrigger);arrivals=arrivals+1 end
rewarded=true;advances=0
APR.stepHandlers.Waypoint({Waypoint=42,ZoneStepTrigger={mapID=1445}},false)
APR.stepHandlers.UseFlightPath({UseFlightPath=42,ZoneStepTrigger={mapID=1445}},false)
assert(arrivals==2 and advances==0,'Explicit arrival conditions retain their normal precedence')
print('Quest anchors: repeated route resets, unfinished quests and other travel conditions passed')
