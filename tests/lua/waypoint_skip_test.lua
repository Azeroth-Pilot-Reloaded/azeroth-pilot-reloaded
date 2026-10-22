-- Manual skip belongs to one authored step, independently of transient guidance.
local env = dofile("tests/lua/route_ui_test_env.lua")
APR.currentStep:PreviousNextStepButton()
local nextClick = CurrentStepFrame_StepHolder.skipButton.scripts.OnClick
local previousClick = CurrentStepFrame_StepHolder.rollbackButton.scripts.OnClick
local function noop() end
local timers, position = {}, { x = 0, y = 0, instanceID = 2601, uiMapID = 2215 }
function UnitPosition() return position.x, position.y, 0, position.instanceID end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function GetTime() return 10 end
function IsFlyableArea() return true end
function IsIndoors() return false end
function LibStub()
    return { GetLocale = function() return setmetatable({}, { __index = function(_, key) return key end }) end }
end
C_Map = { GetBestMapForUnit = function() return position.uiMapID end }
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
local route = {}
for index = 1, 5 do
    route[index] = { Waypoint = 1, NonSkippableWaypoint = true, Zone = 2215, Range = 20,
        Coord = { x = index * 1000, y = 100 },
        ZoneStepTrigger = { mapID = 2215, x = index * 1000, y = 100, Range = 20 } }
end
APR = { PlayerID = "player", ActiveRoute = "route", RouteQuestStepList = { route = route },
    settings = { profile = { enableAddon = true } }, stepHandlers = {}, IsInRouteZone = true,
    GAME_VERSIONS = { Forever = "forever" },
    currentStep = { AddQuestSteps = noop, AddExtraLineText = noop, AddQuestDivider = noop },
    Arrow = { SetCoord = noop, SetArrowActive = noop }, event = { QueueStepRefresh = noop },
    PrintInfo = noop, UpdateMapId = noop, UpdateQuest = noop, SendMessage = noop, Debug = noop }
APRData = { player = { route = 1 } }
function APR:NewModule() return {} end
function APR:GetRouteSteps() return route end
function APR:GetPlayerParentMapID() return position.uiMapID end
function APR:GetMapInfoCached() return { name = "Destination" } end
function APR:StepFilterQuestHandler(step) return step.hidden == true end
function APR:TrimString(text) return text:match("^%s*(.-)%s*$") end
function APR:RemoveContiguousSpaces(text) return text:gsub("%s+", " ") end
function APR:CheckFlySkill() return true end
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
dofile("APR-Core/core/Commands.lua")
function APR:UpdateStep()
    local step, index = self:GetCurrentStep()
    if step and step.Waypoint then self.stepHandlers.Waypoint(step, true, index) end
end
local function progress() return APRData.player.route end
local function reset(index)
    position.x, position.y = 0, 0
    APR:SetRouteProgress("route", index or 1, "reset")
    APR:UpdateStep()
end
local nav = APR.navigation

for _, command in ipairs({ "skip", "s", "skippiedoodaa" }) do
    reset()
    local transitions = #APR:GetRecentTransitions()
    APR.command:SlashCmd(command)
    assert(progress() == 2, command .. " must skip one waypoint, even on an all-waypoint route")
    assert(#APR:GetRecentTransitions() == transitions + 1,
        "The command and navigation cancellation must write authored progress exactly once")
    assert(APR:PreviousQuestStep() and progress() == 1, "Rollback restores the skipped authored waypoint")
end

reset()
nextClick()
assert(progress() == 2, "The current-step next button uses the same one-step skip")
previousClick()
assert(progress() == 1, "The current-step previous button undoes the skip")
for index = 2, #route do
    nextClick()
    assert(progress() == index, "Successive manual skips must stop on every authored waypoint")
end
nextClick()
assert(progress() == #route + 1, "Skipping the final waypoint advances to the end exactly once")
previousClick()
assert(progress() == #route, "Undo from the route end restores its final waypoint")

-- Hidden route conditions retain their existing lookahead behavior, while a
-- visible waypoint is never treated as a hidden instruction.
reset()
route[2].hidden = true
nextClick()
assert(progress() == 3, "Conditional filtering still excludes hidden steps")
assert(APR:PreviousQuestStep() and progress() == 1)
route[2].hidden = nil

-- Old timer callbacks may be delivered even after cancellation. Their captured
-- route revision must keep them from validating whichever waypoint is active now.
reset()
local staleArrival = APR.transportArrivalTimer
nav:RequestUpdate()
local staleNavigation = nav._stepCheckTimer
nextClick()
assert(progress() == 2 and staleArrival.cancelled and staleNavigation.cancelled)
position.x, position.y = route[1].Coord.y, route[1].Coord.x
staleArrival.callback()
staleNavigation.callback()
nav:PollArrival()
assert(progress() == 2, "Cancelled arrival/navigation callbacks cannot consume the next waypoint")
position.x, position.y = 0, 0
assert(APR:PreviousQuestStep() and progress() == 1)
position.x, position.y = route[1].Coord.y, route[1].Coord.x
staleArrival.callback()
assert(progress() == 1, "Returning to the same index must not reactivate its old arrival callback")

-- Arrival is still automatic, including protected waypoints. Each fresh timer
-- evaluates only its own coordinates, not the following distant checkpoint.
reset()
position.x, position.y = route[1].Coord.y, route[1].Coord.x
APR.transportArrivalTimer.callback()
assert(progress() == 2, "Reaching the active waypoint still advances automatically once")
APR.transportArrivalTimer.callback()
assert(progress() == 2, "The following distant waypoint cannot validate at the preceding arrival")
position.x, position.y = route[2].Coord.y, route[2].Coord.x
APR.transportArrivalTimer.callback()
assert(progress() == 3, "The next waypoint requires its own arrival")

-- Optional waypoint QoL remains automatic. Protected waypoints opt out of both
-- settings, while an explicit manual skip remains possible.
reset()
local trigger = route[1].ZoneStepTrigger
route[1].ZoneStepTrigger = nil
APR.runtimeRouteStep = nil
APR.settings.profile.autoSkipAllWaypoints, APR.settings.profile.autoSkipWaypointsFly = true, true
APR:UpdateStep()
assert(progress() == 1, "NonSkippableWaypoint preserves automatic skip restrictions")
nextClick()
assert(progress() == 2, "NonSkippableWaypoint allows an explicit manual skip")
APR.settings.profile.autoSkipAllWaypoints, APR.settings.profile.autoSkipWaypointsFly = false, false
route[1].NonSkippableWaypoint = nil
for _, option in ipairs({ "autoSkipAllWaypoints", "autoSkipWaypointsFly" }) do
    reset()
    APR.settings.profile[option] = true
    APR:UpdateStep()
    assert(progress() == 2, "Ordinary waypoint automatic skip remains available: " .. option)
    APR.settings.profile[option] = false
end
route[1].NonSkippableWaypoint = true
route[1].ZoneStepTrigger = trigger

-- A real controller itinerary owns its own cursor. Completing a mandatory
-- passage does not change the authored route, and skipping/back cancels it.
reset()
local context, generation = APR:CaptureStepContext(), nav.generation
nav.context = context
local first = { x = 100, y = 0, instanceID = 2601, uiMapID = 2215 }
local second = { x = 200, y = 0, instanceID = 2601, uiMapID = 2255 }
local segments = {
    { kind = "walk", from = position, to = first },
    { kind = "passage", from = first, to = second, seconds = 5 },
    { kind = "walk", from = second, to = { x = 100, y = 1000, instanceID = 2601, uiMapID = 2255 } },
}
nav:Publish({ segments = segments }, context, generation)
assert(nav:IsNavigating() and nav.cursor == 1 and progress() == 1)
position.x = 100; nav:PollArrival()
assert(nav.cursor == 2 and nav:GetActiveStep().mandatory and progress() == 1)
nav:PollArrival() -- Observe the mandatory passage's departure before its arrival.
position.x = 200; nav:PollArrival()
assert(nav.cursor == 2, "A mandatory passage cannot complete from the wrong map")
position.uiMapID = 2255; nav:PollArrival()
assert(nav.cursor == 3 and progress() == 1, "Temporary passage arrival only advances its guidance cursor")
nextClick()
assert(progress() == 2 and not nav:IsNavigating() and nav.cursor == 1)
nav:Publish({ segments = segments }, context, generation)
nav:PollArrival()
assert(progress() == 2 and not nav:IsNavigating(), "A stale itinerary cannot republish after manual skip")
previousClick()
assert(progress() == 1 and not nav:IsNavigating(), "Undo cancels guidance and returns to the skipped authored index")
print("Waypoint skip: command aliases/next button, protected consecutive steps, undo, stale timers, arrivals and transient cursors passed")
