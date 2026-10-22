-- Exercise the real skip, QpartPart completion and update dispatcher without WoW.
local function noop() end
local L = { TEST_HINT = "[COLOR:#00ff00]Localized hint" }
function LibStub() return { GetLocale = function() return L end } end

function UnitIsDeadOrGhost() return false end

local now, timers = 0, {}
function debugprofilestop() return now end

C_Timer = {
    NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end
}
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return id == 1 end }
APRData = { player = { route = 1 } }
local route = { { Note = "Skip me" } }
for _ = 1, 1250 do route[#route + 1] = { QpartPart = { [1] = { 1 } } } end
route[#route + 1] = { QpartPart = { [2] = { 1 } } }
APR = {
    StartPerformanceSample = noop,
    FinishPerformanceSample = noop,
    ShowLevelConsumableReminders = noop,
    PlayerID = "player",
    ActiveRoute = "route",
    ActiveQuests = {},
    Buff = { RemoveAllBuffIcon = noop },
    settings = { profile = { enableAddon = true } },
    currentStep = { previousState = {}, ButtonEnable = noop, PrepareRaidIcon = noop, SetProgressBar = noop },
    AFK = { HideFrame = noop },
    Arrow = { SetCoord = noop },
    currentStepImagePreview = { ClearPreviewImages = noop },
    RouteQuestStepList = { route = route },
    EXPANSIONS = { WarlordsOfDraenor = "WoD", BattleForAzeroth = "BfA", Shadowlands = "SL" },
    QUEST_STATUS = { COMPLETE = "complete" },
    questOrderList = { DelayedUpdate = noop },
    party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop },
    Debug = noop,
    ResetMissingQuests = noop,
    SendMessage = noop,
    SkipStepCondition = noop,
    ShouldSojournerSkipStep = noop,
    MaybeSojournerPrompt = noop,
    CheckSojournerPartySync = noop,
    StepFilterQuestHandler = noop,
    UpdateQpartPartWithQuestText = noop,
}
function APR:GetRouteSteps() return route end

dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
local visited = {}
function APR:GetStep(index)
    visited[index] = (visited[index] or 0) + 1
    now = now + 1
    return route[index]
end

dofile("APR-Core/features/questing/StepInstructions.lua")
dofile("APR-Core/features/questing/StepQuestHandlers.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
dofile("APR-Core/features/questing/StepActionHandlers.lua")
dofile("APR-Core/features/questing/StepRenderer.lua")
dofile("APR-Core/features/questing/QuestCache.lua")
dofile("APR-Core/features/questing/QuestHandler.lua")
APR.UpdateQuest = noop
local mapUpdates = 0
function APR:SendMessage(message)
    assert(message == "APR_MAP_UPDATE")
    mapUpdates = mapUpdates + 1
end
APR:SkipQuestStep()
assert(APRData.player.route > 2 and APRData.player.route < #route, "A long skip yields before processing the whole route")
assert(mapUpdates == 0, "Intermediate completed steps do not rebuild map pins")
assert(not APR.lastRenderedStepContext, "Pending catch-up is not reusable by navigation")
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
assert(mapUpdates == 1, "1250 completed objectives publish the map only at the final playable step")
assert(APR:IsStepContextCurrent(APR.lastRenderedStepContext), "Only the settled step can be reused by navigation")

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
assert(not APR.lastRenderedStepContext, "Failed presentations cannot suppress navigation synchronization")
APR.ResetMissingQuests = reset
APR:UpdateStep()
print("Step progression: Note skip + 1250 completed objectives; bounded batches, cancellation and error recovery passed")

-- Keep the historical Tirisfal regression as a stable fixture: the original
-- route was replaced by the race-based collection, but this UI bug must stay covered.
dofile("APR-Core/utils/Utils.lua")
APR.Debug = noop
APR.ActiveRoute = "test-tirisfal-navigation"
APRData.player[APR.ActiveRoute] = 14
route = {}
route[14] = { Waypoint = 404, NonSkippableWaypoint = true, Note = { "Travel to Brill" } }
APR.RouteQuestStepList[APR.ActiveRoute] = { steps = route }
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end

function APR:NewModule() return {} end

dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
APR.navigation.ScheduleRouteCheck = noop
APR.navigation.showOutOfZoneStepContent = true
APR.IsInRouteZone = false
APR.currentStep.RemoveStepContentPreservingNavigationUi = noop
APR.currentStep.Reset = noop
APR.currentStep.UpdateStepButtonCooldowns = noop
APR.CheckWaypointText = function() return "Waypoint" end

local hints, hintKeys = {}, {}
function APR.currentStep:AddExtraLineText(key, text, color)
    assert(type(key) == "string" and type(text) == "string")
    assert(not key:find("table:", 1, true) and not text:find("table:", 1, true))
    if key:find("ExtraLineText", 1, true) or key:match("^NOTE_") then
        assert(not hintKeys[key], "Each rendered hint needs its own key")
        hintKeys[key] = true
        hints[#hints + 1] = { key = key, text = text, color = color }
    end
end

local function refreshHints()
    hints, hintKeys = {}, {}
    APR.navigation:RefreshStepForNavigation()
    assert(not APR.stepUpdateRunning and not APR.stepUpdatePending)
end
refreshHints()
assert(#hints == 1 and hints[1].text == "Travel to Brill")
assert(APRData.player[APR.ActiveRoute] == 14, "Showing travel hints must not advance the quest step")
local firstKey = hints[1].key
refreshHints()
assert(hints[1].key == firstKey, "Refreshing the same hint keeps a stable UI key")

-- Lists and legacy numbered scalar fields both preserve localization and color.
local originalStep = route[14]
route[14] = {
    Waypoint = 404,
    NonSkippableWaypoint = true,
    ExtraLineText = { "TEST_HINT", "Second hint", "", "Second hint" },
    ExtraLineText2 = "[COLOR:#ff0000]Final hint"
}
for _, inZone in ipairs({ false, true }) do
    APR.IsInRouteZone = inZone
    refreshHints()
    assert(#hints == 4)
    assert(hints[1].text == "Localized hint" and hints[1].color == "00ff00")
    assert(hints[2].text == "Second hint" and hints[3].text == "Second hint")
    assert(hints[4].text == "Final hint" and hints[4].color == "ff0000")
end
APR.IsInRouteZone = false
APR.navigation.showOutOfZoneStepContent = false
refreshHints()
assert(#hints == 4, "Transient navigation preserves the authored objective and hints")
route[14] = originalStep
print(
"Extra line text: historical Tirisfal step 14 fixture, navigation refresh, lists, legacy fields, colors and visibility passed")

-- Global War Mode reminder coverage lives in xp_overlay_persistence_test.lua.

-- Completing a route publishes one path change. It must not leave a delayed
-- duplicate that resets whichever route the player selects next.
local completedRoute = APR.ActiveRoute
APRCustomPath, APRZoneCompleted = { player = { "Completed route" } }, { player = {} }
tremove = table.remove
function APR:IsTemporaryRouteActive() return false end
route[14] = { RouteCompleted = true }
local pathChanges, delayedChanges, finalize = 0, 0, nil
C_Timer.After = function() delayedChanges = delayedChanges + 1 end
APR.routeconfig = {
    CheckIsCustomPathEmpty = noop,
    SendMessage = function(_, message)
        assert(message == "APR_Custom_Path_Update")
        pathChanges = pathChanges + 1
        APR:ActivateRoute(nil)
    end,
}
function APR:SuggestNextRoutes(key, callback)
    assert(key == completedRoute and APRZoneCompleted.player["Completed route"])
    finalize = callback
    callback()
end
APR:UpdateStep()
assert(pathChanges == 1 and delayedChanges == 0 and #APRCustomPath.player == 0,
    "Route completion publishes exactly one path change without a delayed reset")
finalize()
assert(pathChanges == 1, "A stale completion callback cannot reset the successor route")
