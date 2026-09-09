-- Exercise the real skip, QpartPart completion and update dispatcher without WoW.
local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
function UnitIsDeadOrGhost() return false end
local now, timers = 0, {}
function debugprofilestop() return now end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return id == 1 end }
APRData = { player = { route = 1 } }
local route = { { Note = "Skip me" } }
for _ = 1, 1250 do route[#route + 1] = { QpartPart = { [1] = { 1 } } } end
route[#route + 1] = { QpartPart = { [2] = { 1 } } }
APR = {
    StartPerformanceSample = noop, FinishPerformanceSample = noop, ShowLevelConsumableReminders = noop,
    PlayerID = "player", ActiveRoute = "route", ActiveQuests = {}, Buff = { RemoveAllBuffIcon = noop },
    settings = { profile = { enableAddon = true } },
    currentStep = { previousState = {}, ButtonEnable = noop, PrepareRaidIcon = noop, SetProgressBar = noop },
    AFK = { HideFrame = noop }, Arrow = { SetCoord = noop },
    currentStepImagePreview = { ClearPreviewImages = noop },
    RouteQuestStepList = { route = route },
    EXPANSIONS = { WarlordsOfDraenor = "WoD", BattleForAzeroth = "BfA", Shadowlands = "SL" },
    QUEST_STATUS = { COMPLETE = "complete" },
    questOrderList = { DelayedUpdate = noop }, party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop },
    Debug = noop, ResetMissingQuests = noop, SendMessage = noop, SkipStepCondition = noop,
    ShouldSojournerSkipStep = noop, MaybeSojournerPrompt = noop, CheckSojournerPartySync = noop,
    StepFilterQuestHandler = noop, UpdateQpartPartWithQuesText = noop,
}
function APR:GetRouteSteps() return route end
dofile("APR-Core/utils/StepUtils.lua")
local visited = {}
function APR:GetStep(index)
    visited[index] = (visited[index] or 0) + 1
    now = now + 1
    return route[index]
end
dofile("APR-Core/features/questing/QuestHandler.lua")
APR.UpdateQuest = noop
APR:SkipQuestStep()
assert(APRData.player.route > 2 and APRData.player.route < #route, "A long skip yields before processing the whole route")
local function drain()
    local index = 1
    while timers[index] do
        local timer = timers[index]
        if not timer.cancelled then timer.callback() end
        index = index + 1
        assert(index < 2000, "Progression must settle on the first unfinished objective")
    end
    timers = {}
end
drain()
assert(APRData.player.route == #route, "Skip stops on the unfinished objective")
for i = 2, #route - 1 do
    assert(visited[i] == 1, "Completed objective " .. i .. " processed " .. tostring(visited[i]) .. " times")
end
assert(not APR.stepUpdateRunning and not APR.stepUpdateTimer, "Settled progression leaves no worker active")

-- A manual navigation during a pending batch supersedes the old continuation.
APRData.player.route = 2
APR:UpdateStep()
local oldTimer = APR.stepUpdateTimer
APRData.player.route = #route
APR:UpdateStep()
assert(oldTimer.cancelled, "A fresh update cancels the pending continuation")
drain()
assert(APRData.player.route == #route, "Cancelled work cannot advance the new selection")

-- An unrelated error cannot leave all subsequent updates locked out.
local reset = APR.ResetMissingQuests
APR.ResetMissingQuests = function() error("test failure") end
assert(not pcall(APR.UpdateStep, APR), "Update errors still propagate")
assert(not APR.stepUpdateRunning, "Errors release the reentrancy guard")
APR.ResetMissingQuests = reset
APR:UpdateStep()
print("Step progression: Note skip + 1250 completed objectives; bounded batches, cancellation and error recovery passed")

-- A completed reference quest must not skip a disabled War Mode instruction.
local desired, displayed = false, 0
C_PvP = {
    IsWarModeDesired = function() return desired end,
    CanToggleWarModeInArea = function() return true end,
    ToggleWarMode = function() error("Protected War Mode toggle must never be called") end,
    SetWarModeDesired = function() error("Protected War Mode setter must never be called") end,
}
APR.currentStep.AddQuestSteps = function() displayed = displayed + 1 end
route[1] = { WarMode = 1 }
APRData.player.route = 1
APR:UpdateStep()
assert(APRData.player.route == 1 and displayed == 1,
    "Completed quest and out-of-route location still show the disabled War Mode step")
for _ = 1, 100 do APR:UpdateStep() end
drain()
assert(APRData.player.route == 1, "Repeated refreshes wait for manual activation even in an allowed area")
desired = true
APR:UpdateStep()
drain()
assert(APRData.player.route == #route,
    "Enabling War Mode completes the instruction without toggling it off")
print("War Mode step: completed quest ignored, no protected calls, manual activation advances")
