-- Exercise the real skip, QpartPart completion and update dispatcher without WoW.
local function noop() end
local L = { TEST_HINT = "[COLOR:#00ff00]Localized hint" }
function LibStub() return { GetLocale = function() return L end } end
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

-- Reproduce the reported Forever step through Farstrider's real UI refresh.
dofile("APR-Core/utils/Utils.lua")
APR.Debug = noop
APR.CATEGORIES = { Leveling = "Leveling" }
APR.PREFAB_TYPES = { StartingZone = "StartingZone" }
APR.EXPANSIONS.Forever = "Forever"
dofile("Routes/Forever/Forever-Tirisfal-Glades.lua")
APR.ActiveRoute = "Forever-10-12-Tirisfal"
APRData.player[APR.ActiveRoute] = 14
route = APR.RouteQuestStepList[APR.ActiveRoute].steps
assert(route[14].Waypoint == 404 and route[14].Note[1] == "Travel to Brill")
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
function APR:NewModule() return {} end
dofile("APR-Core/integrations/Farstrider.lua")
APR.farstrider.ScheduleRouteCheck = noop
APR.farstrider.showOutOfZoneStepContent = true
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
    APR.farstrider:RefreshStepForNavigation()
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
route[14] = { Waypoint = 404, NonSkippableWaypoint = true,
    ExtraLineText = { "TEST_HINT", "Second hint", "", "Second hint" },
    ExtraLineText2 = "[COLOR:#ff0000]Final hint" }
for _, inZone in ipairs({ false, true }) do
    APR.IsInRouteZone = inZone
    refreshHints()
    assert(#hints == 4)
    assert(hints[1].text == "Localized hint" and hints[1].color == "00ff00")
    assert(hints[2].text == "Second hint" and hints[3].text == "Second hint")
    assert(hints[4].text == "Final hint" and hints[4].color == "ff0000")
end
APR.IsInRouteZone = false
APR.farstrider.showOutOfZoneStepContent = false
refreshHints()
assert(#hints == 0, "Hidden step details must not leak hints")
route[14] = originalStep
print("Extra line text: actual Tirisfal step 14, navigation refresh, lists, legacy fields, colors and visibility passed")

-- Global War Mode reminder coverage lives in xp_overlay_persistence_test.lua.
