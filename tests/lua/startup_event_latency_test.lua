-- Timer zero runs on the following 60 Hz frame, never in the current drain.
-- CPU and wall time are separate; a useful row must also survive until paint.
local noop = function() end
local state = { timers = {}, frames = {}, errors = {}, frame = 0, wall = 0, cpu = 0 }
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
function wipe(values) for key in pairs(values) do values[key] = nil end end
function debugprofilestop() return state.cpu end
function GetTime() return state.wall / 1000 end
function geterrorhandler() return function(message) state.errors[#state.errors + 1] = message end end
function IsModifierKeyDown() return false end
function CreateFrame()
    local frame = { scripts = {}, RegisterEvent = noop, UnregisterAllEvents = noop }
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    state.frames[#state.frames + 1] = frame
    return frame
end
local function charge(milliseconds)
    state.cpu, state.wall = state.cpu + milliseconds, state.wall + milliseconds
end
C_Timer = {}
function C_Timer.NewTimer(delay, callback)
    local timer = { callback = callback, due = state.wall + delay * 1000, frame = state.frame + 1 }
    function timer:Cancel() self.cancelled = true end
    state.timers[#state.timers + 1] = timer
    return timer
end
C_Timer.After = C_Timer.NewTimer
local function tick()
    state.frame = state.frame + 1
    state.wall = math.max(state.wall, state.frame * 1000 / 60)
    if state.pendingPaint and APR:IsStepContextCurrent(state.pendingPaint.context) then
        state.paints[#state.paints + 1] = { route = state.pendingPaint.context.route,
            index = state.pendingPaint.context.index, line = state.pendingPaint.line, time = state.wall }
        state.pendingPaint = nil
    end
    local snapshot = state.timers
    state.timers = {}
    local before = state.cpu
    for _, timer in ipairs(snapshot) do
        if not timer.cancelled then
            if timer.frame <= state.frame and timer.due <= state.wall then timer.callback()
            else state.timers[#state.timers + 1] = timer end
        end
    end
    state.largestBatch = math.max(state.largestBatch, state.cpu - before)
    assert(state.cpu - before < 2.5, "A frame keeps its small CPU budget even with a large history")
end
local function untilCondition(condition, maximum)
    for _ = 1, maximum or 5000 do
        if condition() then return end
        tick()
    end
    error("The scheduled operation did not finish")
end

APR = { PlayerID = "player", version = "new", interfaceVersion = "test",
    EXPANSIONS = { Test = "Test" }, settings = { profile = { enableAddon = true, lastRecordedVersion = "old" } },
    NewModule = function() return {} end, Debug = noop, PrintInfo = noop,
    StartPerformanceSample = noop, FinishPerformanceSample = noop, SendMessage = noop,
    RouteSelection = { RefreshFrameAnchor = noop }, heirloom = { RefreshFrameAnchor = noop },
    coordinate = { RefreshFrameAnchor = noop }, ScheduleDelveRouteRefresh = noop,
    InvalidatePlayerZoneCache = noop, ResetQuestTitleRequests = noop,
    questionDialog = { CreateMessagePopup = noop },
    IsSojournerSkipActive = function() return false end, StepFilterQoL = function() return true end }
function APR:GetSettingsProfile() return self.settings.profile end
function APR:WrapTextWithAppearanceColor(value) return value end
APR.navigation = {}
function APR.navigation:Cancel() state.navigationCancels = state.navigationCancels + 1 end
function APR.navigation:InvalidatePathCache() end
function APR.navigation:RequestUpdate() end
function APR.navigation:RequestRouteCheck()
    if not APR.routeValidationPending and not APR.routeValidationFailed then
        state.navigationRequests = state.navigationRequests + 1
    end
end
APR.npcInteraction = { QueueResume = noop }
function APR.npcInteraction:Clear() state.npcClears = state.npcClears + 1; self.interaction = nil end
function APR:CancelAutocompleteQuest() state.autocompleteCancels = state.autocompleteCancels + 1 end
APR.currentStep = { BeginContentUpdate = function() state.renderedLine = nil end }
function APR.currentStep:EndContentUpdate(success)
    if not success then return end
    local context = APR:CaptureStepContext()
    assert(context.route == state.selection and context.index == state.expectedIndex,
        "The first committed row belongs to the selected route and its real progress")
    assert(type(state.renderedLine) == "string" and state.renderedLine ~= "", "An empty content commit is not a useful line")
    state.commits[#state.commits + 1] = { context = context, line = state.renderedLine, time = state.wall }
    state.pendingPaint = { context = context, line = state.renderedLine }
end

dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/questing/QuestHandler.lua")
dofile("APR-Core/core/Event.lua")
local loadFrame = state.frames[#state.frames]
function APR:GetCurrentRouteMapIDsAndName() return nil, 1, state.resolvedSelection or state.selection end
function APR:GetRouteData(key) return self.RouteQuestStepList[key] end
function APR:GetRouteSteps(key) return self.RouteQuestStepList[key].steps end
function APR:GetRouteDisplayName(key) return key end
function APR:GetRouteMapIDsAndName(key) return nil, 1, key end
function APR:GetRawStepCount(key) return #self.RouteQuestStepList[key].steps end
function APR:UpdateMapId() self.navigation:RequestRouteCheck() end
function APR:UpdateQuest()
    assert(self.ActiveRoute == state.selection, "Quest refresh must follow activation of the validated route")
    -- A missing native quest observation stays unknown: startup does not invent
    -- a completion or zone readiness to make its first frame look successful.
    assert(not self.IsInRouteZone and not state.questDataReady)
end
function APR:RenderCurrentStep()
    assert(self.ActiveRoute == state.selection and not self.routeValidationPending and not self.routeValidationFailed)
    assert(not self.IsInRouteZone, "No synthetic zone-ready shortcut may release the guide")
    local context = self:CaptureStepContext()
    local step = self:GetRouteSteps(context.route)[context.index]
    state.renderedLine = step and step.Note
    charge(0.08)
end
function APR:GetRouteSignature(key, checkpoint)
    state.hashes[key] = (state.hashes[key] or 0) + 1
    if key ~= state.selection then state.inactiveHashes = state.inactiveHashes + 1 end
    local definition = self.RouteQuestStepList[key]
    for _ = 1, definition.chunks or 4 do
        charge(0.07)
        if checkpoint then checkpoint() end
    end
    if state.hashHook then state.hashHook(key) end
    return definition.signature
end
-- Charge history iteration independently of hashing. A foreground implementation
-- which scans progress/completions before hashing cannot hide that cost here.
local nativePairs = pairs
function pairs(values)
    local iterator, collection, previous = nativePairs(values)
    if values ~= state.history and values ~= state.completed then return iterator, collection, previous end
    return function(_, key)
        local nextKey, value = iterator(collection, key)
        if nextKey then charge(0.002); state.historyVisits = state.historyVisits + 1 end
        return nextKey, value
    end, collection, previous
end

local function fixture()
    APR.event:CancelRouteValidation()
    APR.event.routeValidationCompleting, APR.event.validatedRouteActivation = nil, nil
    state.timers, state.errors, state.commits, state.paints, state.hashes = {}, {}, {}, {}, {}
    state.frame, state.wall, state.cpu, state.largestBatch = 0, 0, 0, 0
    state.navigationCancels, state.npcClears, state.autocompleteCancels, state.navigationRequests = 0, 0, 0, 0
    state.inactiveHashes, state.historyVisits, state.pendingPaint, state.hashHook = 0, 0, nil, nil
    state.selection, state.expectedIndex, state.questDataReady = "harbor", 3, false
    state.resolvedSelection = nil
    APR.ActiveRoute, APR.IsInRouteZone, APR.stepRevision, APR.stepUpdateTimer = nil, false, 0, nil
    APR.settings.profile = { enableAddon = true, lastRecordedVersion = "old" }
    APR.RouteQuestStepList = {
        harbor = { steps = { {}, {}, { Note = "Reach the eastern gate" }, { Note = "Leave the harbor" } },
            signature = "fresh-harbor" },
        orchard = { steps = { {}, { Note = "Visit the orchard keeper" }, {} }, signature = "fresh-orchard" },
        unvisited = { steps = { { Note = "Meet the new guide" }, {} }, signature = "fresh-unvisited" },
    }
    APRData = { player = { harbor = 3, orchard = 2, ["harbor-RawTotalSteps"] = 4,
        ["orchard-RawTotalSteps"] = 3, RouteSignatures = { harbor = "fresh-harbor", orchard = "fresh-orchard" } } }
    APRCustomPath, APRZoneCompleted = { player = { "harbor" } }, { player = {} }
    for index = 1, 1500 do
        local key = "archive-" .. index
        APR.RouteQuestStepList[key] = { steps = { {}, {} }, chunks = 35, signature = "new-archive" }
        APRData.player[key], APRData.player[key .. "-RawTotalSteps"] = 2, 2
        APRData.player.RouteSignatures[key], APRZoneCompleted.player[key] = "old-archive", true
    end
    state.history, state.completed = APRData.player, APRZoneCompleted.player
    APR.npcInteraction.interaction = { tag = "detail", context = { route = "previous" } }
end

fixture()
loadFrame.scripts.OnEvent(loadFrame, "ADDON_LOADED", "APR")
assert(#state.commits == 0 and state.cpu == 0, "Addon load only schedules the initialized-data bootstrap")
tick()
local validation = APR.routeValidationPending
assert(validation and validation.route == "harbor" and #state.commits == 0)
assert(not APR:AdvanceStep(false) and APR.ActiveRoute == nil)
tick()
assert(not APR.routeValidationPending and not APR.routeValidationFailed and #state.commits == 1)
assert(state.inactiveHashes == 0 and state.historyVisits == 0,
    "The useful row must not depend on inspecting inactive history or completion aliases")
assert(state.hashes.harbor == 1, "Internal activation of the validated guide must not validate it again")
assert(state.commits[1].time <= 100 and APRData.player.harbor == 3 and not APR.IsInRouteZone)
assert(APR.event.routeMaintenanceJob and APR.settings.profile.lastRecordedVersion == "old",
    "Current-only validation does not claim the global maintenance or version is complete")
local commitToken = state.commits[1].context
tick()
assert(state.paints[1].route == "harbor" and state.paints[1].index == 3 and state.paints[1].time <= 100)
assert(state.commits[1].line == "Reach the eastern gate" and state.paints[1].line == "Reach the eastern gate")
assert(APR:IsStepContextCurrent(commitToken) and not APR.routeValidationPending and state.navigationRequests > 0)
local firstCommitTime, firstPaintTime = state.commits[1].time, state.paints[1].time
local maintenance = APR.event.routeMaintenanceJob
local staleTimer = maintenance.timer
local beforeClears, beforeCancels = state.npcClears, state.autocompleteCancels
tick()
assert(state.npcClears == beforeClears and state.autocompleteCancels == beforeCancels,
    "Background batches leave the route's NPC and autocomplete owners alone")

-- A selected route takes priority even while a global snapshot is in flight.
state.selection, state.expectedIndex = "orchard", 2
state.resolvedSelection = "harbor" -- the route owner's custom-path refresh can follow activation.
APRCustomPath.player = { "orchard" }
local beforeSwitch = state.wall
assert(APR:ActivateRoute("orchard", "manual"))
assert(APR.routeValidationPending and not APR.event.routeMaintenanceJob,
    "The activation hook blocks new actions synchronously, before the owner returns")
local selectedValidation = APR.routeValidationPending
assert(not APR:AdvanceStep(false))
assert(selectedValidation.advance and selectedValidation.advance.route == "orchard")
selectedValidation.advance = nil -- this scenario tests unchanged progress, receipt replay is below.
APR:UpdateStep()
assert(#state.commits == 1)
local afterSwitchClears = state.npcClears
staleTimer.callback()
assert(APR.routeValidationPending == selectedValidation and state.npcClears == afterSwitchClears,
    "A stale background callback cannot publish, clear owners or release another validation token")
tick()
assert(not APR.routeValidationPending and state.commits[2].context.route == "orchard")
state.resolvedSelection = nil
tick()
assert(state.paints[2].route == "orchard" and state.paints[2].time - beforeSwitch <= 100)
assert(state.paints[2].line == "Visit the orchard keeper")
assert(APRData.player.orchard == 2 and APRData.player.harbor == 3)
assert(APR.event.routeMaintenanceJob.excludeRoutes.orchard)

-- A maintenance-only pause does not create a failed foreground barrier.
APR.settings.profile.enableAddon = false
APR.event:CancelRouteValidation(true)
assert(not APR.routeValidationPending and not APR.routeValidationFailed and APR.event.routeMaintenanceResume)
APR.settings.profile.enableAddon = true
assert(APR.event:ResumeRouteValidation() and APR.event.routeMaintenanceJob)
assert(not APR.routeValidationPending and not APR.routeValidationFailed)

-- Explicit intentions and one native receipt remain attached to their route.
APR:SetRouteProgress("orchard", 3, "automatic")
state.expectedIndex = 3
assert(not (APR.event.routeMaintenanceJob.manualResets or {}).orchard,
    "Automatic progress must not be recorded as a manual reset by background work")
APR:SetRouteProgress("archive-1", 1, "reset")
assert(APR.event.routeMaintenanceJob.manualResets["archive-1"])
APR:ClearSavedRouteData("archive-2")
assert(APR.event.routeMaintenanceJob.manualClears["archive-2"])
untilCondition(function() return not APR.event.routeMaintenanceJob end)
assert(APRData.player.orchard == 3 and APRData.player.harbor == 3)
assert(APRData.player["archive-1"] == 1 and APRData.player["archive-2"] == nil
    and APRData.player["archive-2-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures["archive-2"] == nil)
assert(APR.settings.profile.lastRecordedVersion == "new" and #state.errors == 0)

-- Newly selected progress is initialized before its first quest/render pass.
fixture()
state.selection, state.expectedIndex = "unvisited", 1
APRCustomPath.player = { "unvisited" }
loadFrame.scripts.OnEvent(loadFrame, "ADDON_LOADED", "APR")
tick(); tick(); tick()
assert(APRData.player.unvisited == 1 and state.paints[1].route == "unvisited" and state.paints[1].time <= 100)
assert(state.paints[1].line == "Meet the new guide")

-- Initialization ordering is explicit; absence of SavedVariables is not a
-- reason to add a fixed login delay once the initialized data becomes ready.
fixture()
local savedData = APRData
APRData = nil
loadFrame.scripts.OnEvent(loadFrame, "ADDON_LOADED", "APR")
tick()
assert(not APR.routeValidationPending and #state.commits == 0 and state.cpu == 0)
APRData = savedData
tick(); tick(); tick()
assert(state.paints[1].route == "harbor" and state.paints[1].time <= 100)

fixture()
APR.ActiveRoute = "harbor"
state.expectedIndex = 4
APR.event:ValidateStartupRoutes("harbor", function() APR:UpdateStep() end)
local receipt = APR:CaptureStepContext()
assert(not APR:AdvanceStep(false, receipt) and not APR:AdvanceStep(false, receipt))
tick()
assert(APRData.player.harbor == 4 and #state.commits == 1 and not APR.routeValidationPending,
    "Repeated native events retain one receipt and replay it exactly once after validation")
assert(state.commits[1].line == "Leave the harbor")
APR.event:CancelRouteValidation()

fixture()
APR.ActiveRoute = "harbor"
APR.RouteQuestStepList.harbor.chunks = 50
APR.event:ValidateStartupRoutes("harbor", function() APR:UpdateStep() end)
assert(not APR:AdvanceStep(false) and APR.routeValidationPending.advance.route == "harbor")
tick()
assert(APR.routeValidationPending)
state.selection, state.expectedIndex = "orchard", 2
APR:ActivateRoute("orchard", "manual")
assert(APR.routeValidationPending.route == "orchard" and not APR.routeValidationPending.advance)
tick()
assert(APRData.player.orchard == 2 and APRData.player.harbor == 3,
    "An old route's native receipt must never advance the newly selected guide")
APR.event:CancelRouteValidation()

fixture()
APR.ActiveRoute = "harbor"
APR.event:ValidateStartupRoutes("harbor", function() APR.event:CancelRouteValidation() end)
tick()
assert(not APR.event.routeValidationJob and not APR.event.routeMaintenanceJob,
    "Cancelling reentrantly from completion prevents a retired request from starting maintenance")

-- Cancel during hashing itself, rather than merely cancelling a queued timer.
fixture()
APR.ActiveRoute = "harbor"
local publications = 0
state.hashHook = function(key)
    if key ~= "harbor" then return end
    state.hashHook = nil
    state.selection, state.expectedIndex = "orchard", 2
    APRCustomPath.player = { "orchard" }
    APR:ActivateRoute("orchard", "manual")
end
APRData.player.RouteSignatures.harbor = "must-not-publish"
APR.event:ValidateStartupRoutes("harbor", function() publications = publications + 1; APR:UpdateStep() end)
tick()
assert(APR.routeValidationPending and APR.routeValidationPending.route == "orchard" and publications == 0)
assert(APRData.player.RouteSignatures.harbor == "must-not-publish",
    "A reentrant route activation retires the old snapshot before any publication")
tick()
assert(publications == 1 and APRData.player.orchard == 2)
APR.event:CancelRouteValidation()

-- A background error neither blocks the active guide nor loses the bounded
-- retry's ownership when an explicit cancellation arrives.
fixture()
loadFrame.scripts.OnEvent(loadFrame, "ADDON_LOADED", "APR")
tick(); tick()
local clearsBeforeFailure, autocompleteBeforeFailure = state.npcClears, state.autocompleteCancels
state.hashHook = function(key) if key ~= "harbor" then error("synthetic history failure") end end
untilCondition(function() return #state.errors > 0 end, 30)
assert(APR.event.routeMaintenanceResume and not APR.routeValidationPending and not APR.routeValidationFailed)
assert(state.npcClears == clearsBeforeFailure and state.autocompleteCancels == autocompleteBeforeFailure)
assert(APR:SetRouteProgress("harbor", 4, "automatic") and APRData.player.harbor == 4)
local retry = APR.event.routeMaintenanceResume.timer
APR.event:CancelRouteValidation()
assert(retry.cancelled and not APR.event.routeMaintenanceResume)
retry.callback()
assert(not APR.event.routeMaintenanceJob and not APR.routeValidationPending and not APR.routeValidationFailed)
print(string.format("Startup: first useful commit %.2f ms, next paint %.2f ms at 60 FPS; history, preemption and receipts passed",
    firstCommitTime, firstPaintTime))

-- The native quest phase is independent of route-validation ownership. Exercise
-- real filters, parallel activation, cache synchronization and visible rows.
local function questSnapshotFixture(loggedIn, deferStartup)
    local nativeLoad, receivers = dofile, {}
    local phase = { loggedIn = loggedIn }
    function IsLoggedIn() return phase.loggedIn end
    dofile = function(path)
        if path ~= "APR-Core/core/Event.lua" then return nativeLoad(path) end
        local create = CreateFrame
        CreateFrame = function(...)
            local frame = create(...)
            function frame:UnregisterEvent(event) self.events[event] = nil end
            receivers[#receivers + 1] = frame
            return frame
        end
        local ok, value = pcall(nativeLoad, path)
        CreateFrame = create
        if not ok then error(value, 0) end
        return value
    end
    local ok, value = pcall(nativeLoad, "tests/lua/addon_journey_quest_env.lua")
    dofile = nativeLoad
    if not ok then error(value, 0) end
    local observer = APR.event.startupQuestStateFrame
    assert(observer == receivers[#receivers])
    function phase:Emit(event) observer.scripts.OnEvent(observer, event) end
    function phase:Start()
        local before = #H.timers
        observer.scripts.OnEvent(observer, "ADDON_LOADED", "APR")
        -- These cases isolate native phase/filter/cache behavior around a
        -- directly rendered instruction. The joined login-latency suite drives
        -- the complete scheduled route-validation bootstrap independently.
        for index = before + 1, #H.timers do H.timers[index]:Cancel() end
    end
    if not deferStartup then phase:Start() end
    APR.RouteQuestStepList.snapshot = { label = "Invented native snapshot guide", mapID = 10,
        expansion = APR.EXPANSIONS.Custom, steps = {
            { PickUp = { 6101 }, IsQuestOnQuest = 6201 }, { Note = "Continue after eligibility is known" },
        } }
    APR.ActiveRoute, APRData.player.snapshot = "snapshot", 1
    APRCustomPath.player = { "Invented native snapshot guide" }
    APR.IsInRouteZone = false
    return phase, H
end
local function pickupVisible(questID)
    local row = APR.currentStep.questsList.PickUp
    assert(row and not row.stale and row.font:GetText() == "Pick up")
    assert(row.detailFonts[1]:GetText():find("Quest " .. questID, 1, true))
    local parent = row
    while parent do assert(parent:IsShown()); parent = parent:GetParent() end
end

local phase, native = questSnapshotFixture(false)
APR.RouteQuestStepList.snapshot.parallelSteps = {
    { conditions = { Not = { IsQuestOnQuest = 6301 } }, steps = { { Note = "Negative branch" } } },
    { conditions = { AnyOf = { { AllOf = { { Not = { IsQuestOnQuest = 6302 } } } }, { MinLevel = 1000 } } },
        steps = { { Note = "Nested branch" } } },
}
APR:UpdateStep()
local firstToken = APR:CaptureStepContext()
pickupVisible(6101)
assert(APR.startupQuestStatePending and not APR.routeValidationPending and not APR.routeValidationFailed)
assert(APRData.player.snapshot == 1 and not APRData.player["snapshot-SkippedStep"])
local parallel = APRData.player["snapshot-ParallelStepsState"]
assert(not parallel or not next(parallel.groups), "Unknown negative/nested predicates cannot activate parallel groups")
native.frame(1 / 60)
pickupVisible(6101)
assert(APR:IsStepContextCurrent(firstToken) and APRData.player.snapshot == 1 and not APR.IsInRouteZone,
    "The actual guarded instruction paints on the next 16.7 ms frame, with its progress intact")
native.quest(6201); native.quest(6301); native.quest(6302)
native.frame(0.5 - 1 / 60)
assert(APR.startupQuestStatePending and APRData.player.snapshot == 1 and not APR.ActiveQuests[6201],
    "Elapsed timers and future server packets cannot stand in for a native snapshot observation")
phase:Emit("QUEST_LOG_UPDATE")
assert(not APR.startupQuestStatePending and APR.ActiveQuests[6201] and APR.ActiveQuests[6301])
assert(APRData.player.snapshot == 1 and not APRData.player["snapshot-SkippedStep"])
pickupVisible(6101)
parallel = APRData.player["snapshot-ParallelStepsState"]
assert(not next(parallel.groups), "Known false negative/nested predicates remain inactive after the snapshot")
assert(APR:AreConditionalFiltersMet({ Not = { IsQuestOnQuest = 6401 } }),
    "After the native snapshot, a known negative predicate can evaluate true again")
assert(not phase.loggedIn and APR.event.startupQuestStateObserved == "QUEST_LOG_UPDATE",
    "A quest snapshot observed before PLAYER_LOGIN must remain usable")

phase, native = questSnapshotFixture(false)
APR:UpdateStep()
assert(APRData.player.snapshot == 1 and APR.startupQuestStatePending)
phase:Emit("PLAYER_LOGIN")
assert(not APR.startupQuestStatePending and not next(APR.ActiveQuests), "An observed zero-entry log is valid")
assert(APRData.player.snapshot == 2, "A known empty snapshot can correctly reject an on-quest condition")
assert(not APR.event.startupQuestStateFrame.events.PLAYER_LOGIN
    and not APR.event.startupQuestStateFrame.events.QUEST_LOG_UPDATE, "Completed native observers are unregistered")

phase, native = questSnapshotFixture(true)
assert(not APR.startupQuestStatePending and native.questReads > 0
    and APR.event.startupQuestStateObserved == "IsLoggedIn",
    "A login event which already passed requires an explicit native read, including an empty log")
assert(not next(APR.ActiveQuests) and not APR.routeValidationPending and not APR.routeValidationFailed)

phase, native = questSnapshotFixture(false, true)
local savedData, savedQuests = APRData, APR.ActiveQuests
APRData, APR.ActiveQuests = nil, nil
phase:Emit("QUEST_LOG_UPDATE")
assert(not APR.startupQuestStatePending and APR.event.startupQuestStateObserved == "QUEST_LOG_UPDATE",
    "Observing a native event before APR's bootstrap does not arm an imported module")
phase:Start()
assert(APR.startupQuestStatePending, "The actual addon bootstrap owns the unknown initial snapshot")
APRData, APR.ActiveQuests = savedData, savedQuests
assert(APR.event:ObserveStartupQuestState() and not APR.startupQuestStatePending,
    "Observations before character initialization must be consumed rather than discarded")

phase, native = questSnapshotFixture(false)
local countEntries = C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries = function() return nil end
phase:Emit("PLAYER_LOGIN")
assert(APR.startupQuestStatePending and APR.event.startupQuestStateObserved == "PLAYER_LOGIN"
    and not APR.event.startupQuestStateSyncing, "An unavailable count is unknown, not an empty snapshot")
C_QuestLog.GetNumQuestLogEntries = function() error("Transient native snapshot unavailable") end
assert(not APR.event:ObserveStartupQuestState() and APR.startupQuestStatePending)
C_QuestLog.GetNumQuestLogEntries = countEntries
assert(APR.event:ObserveStartupQuestState() and not APR.startupQuestStatePending)

phase, native = questSnapshotFixture(false)
APR:UpdateStep()
APR.settings.profile.enableAddon = false
local renders, render = 0, APR.UpdateStep
function APR:UpdateStep() renders = renders + 1; return render(self) end
native.quest(6201)
phase:Emit("QUEST_LOG_UPDATE")
assert(not APR.startupQuestStatePending and APR.ActiveQuests[6201] and renders == 0,
    "Disabled gameplay still records/synchronizes native readiness without actions or rendering")
native.quest(6401)
APR.settings.profile.enableAddon = true
APR.event:ResumeRouteValidation()
assert(APR.ActiveQuests[6401] and renders == 1 and not APR.startupQuestStatePending,
    "Enabling refreshes the observed native snapshot and current guide once before gameplay resumes")
APR.event:ResumeRouteValidation()
assert(renders == 1, "A completed startup observation is not a recurring refresh owner")
assert(#native.errors == 0)

phase, native = questSnapshotFixture(false, true)
assert(not APR.startupQuestStatePending and not APR.event.startupQuestStateStarted and native.questReads == 0,
    "Importing Event handlers alone never imposes a startup phase on ordinary engine calls")
APR:UpdateStep()
assert(APRData.player.snapshot == 2 and not APR.startupQuestStatePending,
    "Ordinary calls retain their normal known-false predicate behavior outside addon startup")
phase:Emit("PLAYER_LOGIN")
assert(not APR.startupQuestStatePending and native.questReads == 0,
    "A pre-bootstrap native phase is latched without an implicit startup cache refresh")

phase, native = questSnapshotFixture(true, true)
assert(APRData.player.snapshot == 1 and not APR.lastRenderedStepContext)
phase:Start()
assert(not APR.startupQuestStatePending and APRData.player.snapshot == 1 and not APR.lastRenderedStepContext,
    "Snapshot synchronization cannot render a restored route before its first validation owns presentation")

-- Exercise the actual queued bootstrap, rather than the isolated native-phase
-- cases above: an initial cache exception used to abort before it was queued.
local function failingBootstrapFixture(permanent)
    local startup, state = questSnapshotFixture(true, true)
    APR.ActiveRoute, APR.lastRenderedStepContext = nil, nil
    state.quest(6201)
    APR.version = "synthetic-startup"
    APR.heirloom.RefreshFrameAnchor, APR.coordinate.RefreshFrameAnchor = noop, noop
    APR.ScheduleDelveRouteRefresh, APR.InvalidatePlayerZoneCache = noop, noop
    function APR:WrapTextWithAppearanceColor(value) return tostring(value) end
    -- Fingerprint mechanics have separate exact-signature coverage; all route
    -- validation, event scheduling, quest cache and row commits remain real.
    function APR:GetRouteSignature() return "synthetic-stable-fingerprint" end
    local refresh = APR.UpdateQuest
    local attempts, reported, priorErrorHandler = 0, {}, geterrorhandler
    function geterrorhandler() return function(message) reported[#reported + 1] = message end end
    function APR:UpdateQuest(...)
        attempts = attempts + 1
        if permanent or attempts == 1 then error("Synthetic initial quest cache exception") end
        return refresh(self, ...)
    end
    local observer = APR.event.startupQuestStateFrame
    local delivered, failure = pcall(observer.scripts.OnEvent, observer, "ADDON_LOADED", "APR")
    assert(delivered, failure)
    assert(APR.startupQuestStatePending and not APR.event.startupQuestStateSyncing and APR.ActiveRoute == nil)
    assert(#reported == 1 and reported[1]:find("Synthetic initial quest cache exception", 1, true),
        "The failed snapshot must be reported without marking it known")
    local queued = false
    for _, timer in ipairs(state.timers) do if not timer.cancelled then queued = true end end
    assert(queued, "Initial snapshot failure cannot prevent installing the actual bootstrap continuation")
    if not permanent then
        APR.UpdateQuest = refresh
        startup:Emit("QUEST_LOG_UPDATE")
        assert(not APR.startupQuestStatePending and APR.ActiveQuests[6201])
    end
    local began = state.time
    for _ = 1, 6 do state.frame(1 / 60) end
    assert(state.time - began <= 0.101 and APR.ActiveRoute == "snapshot" and APRData.player.snapshot == 1
        and APR.lastRenderedStepContext and APR:IsStepContextCurrent(APR.lastRenderedStepContext)
        and not APR.routeValidationPending and not APR.routeValidationFailed,
        "A later good snapshot must still reach the correct useful guide within six 60 Hz frames")
    pickupVisible(6101)
    if permanent then
        assert(APR.startupQuestStatePending and attempts == 2 and #reported == 2)
        for _ = 1, 60 do state.frame(1 / 60) end
        assert(attempts == 2 and #reported == 2 and #state.timers == 0,
            "Repeated snapshot failures retain readiness without creating an infinite timer retry chain")
    else assert(#reported == 1 and #state.errors == 0) end
    geterrorhandler = priorErrorHandler
end
failingBootstrapFixture(false)
failingBootstrapFixture(true)
print("Startup quest state: delayed and empty snapshots, prior login, pre-init observation and native failures passed")
