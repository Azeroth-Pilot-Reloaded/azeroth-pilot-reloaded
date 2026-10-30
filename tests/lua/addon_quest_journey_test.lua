-- Cross-module behavior, using invented route/quest data only. Native APIs and
-- presentation endpoints are simulated; dispatch, trigger indexing, conditions,
-- effective steps, quest synchronization, rendering and progression are real.
local function noop() end
local state = { clock = 0, timers = {}, errors = {}, popups = {}, log = {}, quests = {},
    rewarded = {}, level = 12, zone = 10, rendered = {}, fillerUpdates = {} }
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
function GetTime() return state.clock end
function debugprofilestop() return state.clock * 1000 end
function UnitLevel() return state.level end
function UnitXP() return 0 end
function UnitXPMax() return 100 end
function UnitIsDeadOrGhost() return false end
function IsInGroup() return false end
function IsInRaid() return false end
function IsInInstance() return false, "none" end
function IsModifierKeyDown() return false end
function InCombatLockdown() return false end
function geterrorhandler() return function(err) state.errors[#state.errors + 1] = err end end
function wipe(values) for key in pairs(values) do values[key] = nil end end
function tContains(values, target) for _, value in ipairs(values) do if value == target then return true end end return false end
tinsert, tremove, getn = table.insert, table.remove, table.getn
C_Timer = { NewTimer = function(delay, callback)
    local timer = { at = state.clock + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    state.timers[#state.timers + 1] = timer
    return timer
end }
C_Timer.After = C_Timer.NewTimer
function state:drain()
    local iterations = 0
    while #self.timers > 0 do
        table.sort(self.timers, function(a, b) return a.at < b.at end)
        local timer = table.remove(self.timers, 1)
        self.clock = math.max(self.clock, timer.at)
        if not timer.cancelled then timer.callback() end
        iterations = iterations + 1
        assert(iterations < 2000, "The journey cannot retain an endless callback chain")
    end
    assert(#self.errors == 0, self.errors[1])
end
function CreateFrame()
    return { scripts = {}, RegisterEvent = noop, UnregisterAllEvents = noop,
        SetScript = function(self, name, callback) self.scripts[name] = callback end }
end
C_Map = { GetBestMapForUnit = function() return state.zone end }
C_QuestLog = {
    GetNumQuestLogEntries = function() return #state.log end,
    GetInfo = function(index) return state.log[index] end,
    IsComplete = function(id) return state.quests[id] and state.quests[id].ready or false end,
    IsOnQuest = function(id) return state.quests[id] ~= nil end,
    IsQuestFlaggedCompleted = function(id) return state.rewarded[id] == true end,
    IsQuestFlaggedCompletedOnAccount = function() return false end,
    GetNumQuestObjectives = function(id) return state.quests[id] and #state.quests[id].objectives or 0 end,
    GetQuestObjectives = function(id) return state.quests[id] and state.quests[id].objectives end,
    GetTitleForQuestID = function(id) return "Synthetic quest " .. id end,
    IsPushableQuest = function() return false end,
    AddQuestWatch = noop,
}
C_SuperTrack = { SetSuperTrackedQuestID = noop }
APR = { PlayerID = "player", Faction = "Alliance", Level = 12, MaxLevel = 80,
    interfaceVersion = 120105, RouteQuestStepList = {}, ActiveQuests = {}, BonusObj = {}, MissingQuests = {},
    IsInRouteZone = true, QUEST_STATUS = { COMPLETE = "complete", PROGRESS = "progress" },
    settings = { profile = { enableAddon = true, autoAccept = false, autoAcceptQuestRoute = false,
        pickupQuestLookahead = 0 } },
    currentStep = { previousState = {}, Reset = noop, ButtonEnable = noop, PrepareRaidIcon = noop,
        SetProgressBar = noop, UpdateStepButtonCooldowns = noop },
    currentStepImagePreview = { ClearPreviewImages = noop },
    AFK = { HideFrame = noop }, Arrow = { SetCoord = noop },
    Buff = { RemoveAllBuffIcon = noop },
    party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop },
    questOrderList = { DelayedUpdate = noop, AddStepFromRoute = noop },
    fillersFrame = { UpdateFillerStep = function(_, id, text, index)
        state.fillerUpdates[id .. ":" .. index] = text
    end },
    StartPerformanceSample = noop, FinishPerformanceSample = noop, Debug = noop,
    DebugEvent = noop, PrintInfo = noop, SendMessage = noop,
    MaybePromptInstanceUIPreference = noop, RefreshInstanceUIVisibility = noop,
    IsInstanceWithUI = function() return true end,
    IsDelveRoute = function() return false end,
    IsTemporaryRouteActive = function() return false end,
    IsSojournerSkipActive = function() return false end,
    ShouldSojournerSkipStep = function() return false end,
    MaybeSojournerPrompt = noop, CheckSojournerPartySync = noop,
    ShowLevelConsumableReminders = noop,
    TrackQuest = noop, SetButton = noop,
    ResetMissingQuests = noop,
    GetRouteSuggestionDontAsk = function() return state.dontAsk end,
    SetRouteSuggestionDontAsk = function(_, value) state.dontAsk = value end,
}
function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
function APR.currentStep:AddQuestSteps(id, text, index) state.rendered[id .. ":" .. tostring(index)] = text end
function APR.currentStep:AddQuestStepsWithDetails(action, _, ids) state.lastAction, state.lastIDs = action, ids end
function APR.currentStep:AddExtraLineText(key, text) state.rendered[key] = text end
function APR.currentStep:UpdateQuestStep(id, text, index) state.rendered[id .. ":" .. index] = text end
APR.questionDialog = { CreateRouteTriggerPopup = function(_, _, routes, accept, _, dismiss)
    state.popups[#state.popups + 1] = { routes = routes, accept = accept, dismiss = dismiss }
end }
APRData = { player = { BonusSkips = {}, WantedQuestList = {} } }
APRCustomPath, APRZoneCompleted = { player = {} }, { player = {} }
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/features/questing/StepInstructions.lua")
dofile("APR-Core/features/questing/StepQuestHandlers.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
dofile("APR-Core/features/questing/StepActionHandlers.lua")
dofile("APR-Core/features/questing/StepRenderer.lua")
dofile("APR-Core/features/questing/QuestCache.lua")
dofile("APR-Core/features/questing/QuestHandler.lua")
dofile("APR-Core/features/questing/RouteSuggestions.lua")
dofile("APR-Core/core/Event.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")
-- Peripheral layout/navigation endpoints are outside this quest journey. Native
-- travel/controller behavior is exercised by the navigation journey suites.
function APR:UpdateMapId() state.mapRefreshes = (state.mapRefreshes or 0) + 1 end
APR.routeconfig = { CheckIsCustomPathEmpty = noop, SendMessage = noop }
local function event(tag, name, ...)
    APR.event.EventHandler({ tag = tag, callback = APR.event.functions[tag] }, name, ...)
    assert(#state.errors == 0, state.errors[1])
end
local function progress(index)
    assert(APRData.player.journey == index, "Expected journey step " .. index .. ", got " .. tostring(APRData.player.journey))
end
APR.RouteQuestStepList = {
    journey = { label = "Synthetic journey", expansion = APR.EXPANSIONS.Custom, steps = {
        { PickUp = { 7001 } },
        { Note = "Other faction only", Faction = "Horde" },
        { Qpart = { [7001] = { 1 } }, AnyOf = { { MinLevel = 12 }, { Faction = "Horde" } } },
        { Done = { 7001 } },
        { PickUp = { 7002 } },
        { QpartPart = { [7002] = { 1 } } },
        { SetHS = 7002 },
        { Note = "Playable end" },
    } },
    hidden = { label = "Hidden", hiddenFromSelection = true, steps = { { PickUp = { 7001 } } } },
    temporary = { label = "Temporary", temporary = true, steps = { { PickUp = { 7001 } } } },
    noMatch = { label = "Different quest", steps = { { PickUp = { 9999 } } } },
}

-- Accept before the cooperative index has visited the declaration. The real
-- native event dispatcher must retain a single suggestion request until ready.
APR:InitRouteTriggersSuggestion()
state.quests[7001] = { objectives = { { text = "Collect 0/2", finished = false } } }
state.log = { { questID = 7001, isHeader = false } }
event("accept", "QUEST_ACCEPTED", 7001)
assert(#state.popups == 0 and APR._routeTriggerBuild.pending[7001])
state:drain()
assert(#state.popups == 1 and #state.popups[1].routes == 1)
assert(state.popups[1].routes[1].key == "journey", "Hidden/temporary/unrelated guides cannot be suggested")
state.popups[1].accept(state.popups[1].routes[1])
event("updateQuest", "QUEST_LOG_UPDATE")
state:drain()
assert(APR.ActiveRoute == "journey" and APRCustomPath.player[1] == "Synthetic journey")
progress(3)
assert(APRData.player["journey-SkippedStep"] == 1, "Faction conditions skip exactly the inapplicable step")
assert(APR.ActiveQuests[7001].objectives[1].text == "Collect 0/2")

-- Foreign unit traffic, unknown payloads and repeated quest events cannot
-- consume objectives, and an active path must suppress new suggestion popups.
for _ = 1, 100 do event("updateQuest", "UNIT_QUEST_LOG_CHANGED", "party1") end
event("accept", "QUEST_ACCEPTED", 7001)
assert(#state.popups == 1)
local objective = APR.ActiveQuests[7001].objectives[1]
for _ = 1, 100 do event("updateQuest", "QUEST_LOG_UPDATE") end
state:drain()
progress(3)
assert(APR.ActiveQuests[7001].objectives[1] == objective, "Unchanged quest refreshes reuse the existing objective")
state.quests[7001].objectives[1].text = "Collect 2/2"
state.quests[7001].objectives[1].finished = true
state.quests[7001].ready = true
event("updateQuest", "QUEST_LOG_UPDATE")
state:drain()
progress(4)
assert(state.fillerUpdates["7001:1"] == "Collect 2/2", "Quest synchronization also updates optional-objective consumers")

-- A missing objective table stays pending, then a rewarded quest and removal
-- move the real renderer through turn-in to the next pickup exactly once.
state.rewarded[7001], state.quests[7001], state.log = true, nil, {}
event("remove", "QUEST_REMOVED", 7001, false)
state:drain()
progress(5)
assert(APR.ActiveQuests[7001] == nil and state.lastAction == "PickUp")
state.quests[7002] = { objectives = {} }
state.log = { { questID = 7002, isHeader = false } }
event("accept", "QUEST_ACCEPTED", 7002)
event("updateQuest", "QUEST_LOG_UPDATE")
state:drain()
progress(6)
assert(APR.ActiveQuests[7002].objectives[1].status == APR.QUEST_STATUS.PROGRESS)
state.quests[7002].objectives = { { text = "Speak to the witness", finished = true } }
event("updateQuest", "QUEST_LOG_UPDATE")
state:drain()
progress(7)

-- Native one-shot completion must not advance during validation. A real worker
-- continuation (covered separately with historical hash goldens) releases this
-- barrier, after which the preserved receipt is checked against current state.
local request = {}
APR.routeValidationPending = request
for _ = 1, 20 do event("setHS", "HEARTHSTONE_BOUND") end
progress(7)
assert(request.advance and request.advance.index == 7)
APR.routeValidationPending = nil
assert(APR:AdvanceStep(false, request.advance))
APR:UpdateStep()
state:drain()
progress(8)
event("setHS", "HEARTHSTONE_BOUND")
progress(8)

-- A stale user choice cannot advance a different path, and opt-out preferences
-- are re-read when an index finishes rather than frozen when it started.
local stale = APR:CaptureStepContext()
APR:ActivateRoute(nil)
assert(not APR:TransitionStep(9, "stale", false, stale))
APRCustomPath.player = {}
APR:InitRouteTriggersSuggestion()
event("accept", "QUEST_ACCEPTED", 9999)
state.dontAsk = true
state:drain()
assert(#state.popups == 1)
state.dontAsk = false
event("accept", "QUEST_ACCEPTED", 9999)
assert(#state.popups == 2 and state.popups[2].routes[1].key == "noMatch")
state.popups[2].dismiss()
event("accept", "QUEST_ACCEPTED", 7001)
assert(#state.popups == 2 and state.dontAsk)
assert(#state.errors == 0)
print("Quest journey: accepted quest -> queued suggestion -> route/conditions -> cache/objectives/fillers -> turn-in -> next pickup -> native completion; bursts, opt-out and stale contexts passed")
