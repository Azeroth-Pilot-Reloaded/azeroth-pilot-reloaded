-- Stateful native API boundary for full quest/suggestion/progression journeys.
-- The route engine, event dispatch, quest cache, popup callbacks and both row
-- renderers below are production code, not substitutes for the behavior tested.
local env = dofile("tests/lua/route_ui_test_env.lua")
local function noop() end
H = { clock = 0, charge = 0.01, bytes = 0, time = 10, timers = {}, errors = {}, quests = {}, order = {},
    rewarded = {}, items = {}, missingInfo = {}, missingTitles = {}, missingObjectives = {}, map = 10,
    questReads = 0, mapRequests = 0, events = 0 }
local locale = setmetatable({ Q_ACCEPTED = "Accepted %d", PICK_UP_Q = "Pick up", TURN_IN_Q = "Turn in",
    ERROR_MISSING_Q = "Missing %s", DO_BONUS_OBJECTIVE = "Bonus %s", SET_HEARTHSTONE = "Bind %s" },
    { __index = function(_, key) return key end })
local originalLib = LibStub
function LibStub(name, ...)
    if name == "AceLocale-3.0" then return { GetLocale = function() return locale end } end
    return originalLib(name, ...)
end
function debugprofilestop() return H.clock end
function GetTime() return H.time end
function UnitLevel() return H.level or 20 end
function UnitIsDeadOrGhost() return false end
function IsInInstance() return false end
function IsInGroup() return false end
function IsModifierKeyDown() return false end
function GetBindLocation() return "Synthetic inn" end
function geterrorhandler() return function(err) H.errors[#H.errors + 1] = err end end
tinsert, tremove, getn = table.insert, table.remove, table.getn
function tContains(values, wanted)
    for _, value in ipairs(values or {}) do if value == wanted then return true end end
    return false
end
function env.methods:RegisterEvent(event)
    self.events = self.events or {}; self.events[event] = true
end
function env.methods:RegisterUnitEvent(event, unit)
    self:RegisterEvent(event); self.units = self.units or {}; self.units[event] = unit
end
function env.methods:UnregisterAllEvents() self.events = {} end
C_Timer = { NewTimer = function(delay, callback)
    local timer = { due = H.time + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    H.timers[#H.timers + 1] = timer
    return timer
end }
function C_Timer.After(delay, callback) C_Timer.NewTimer(delay, callback) end
function H.frame(elapsed)
    H.time = H.time + (elapsed or 0)
    local pending = H.timers
    H.timers = {}
    for _, timer in ipairs(pending) do
        if not timer.cancelled then
            if timer.due <= H.time then timer.callback() else H.timers[#H.timers + 1] = timer end
        end
    end
    assert(#H.errors == 0, table.concat(H.errors, "\n"))
end
function H.settle()
    for _ = 1, 2000 do
        if #H.timers == 0 then return end
        H.frame(0.05)
    end
    error("Synthetic journey left an unbounded timer chain")
end
function H.emit(event, ...)
    local tags = {}
    for tag, frame in pairs(APR.event.framePool) do if frame.events and frame.events[event] then tags[#tags + 1] = tag end end
    table.sort(tags)
    for _, tag in ipairs(tags) do
        local frame = APR.event.framePool[tag]
        frame.scripts.OnEvent(frame, event, ...)
    end
    H.events = H.events + 1
    assert(#H.errors == 0, table.concat(H.errors, "\n"))
end
function H.quest(id, text)
    if not H.quests[id] then H.order[#H.order + 1] = id end
    H.quests[id] = { onQuest = true, objectives = { { text = text or "Collect 0/3", finished = false } } }
end
function H.objective(id, text, finished)
    H.quests[id].objectives[1].text, H.quests[id].objectives[1].finished = text, finished
    H.quests[id].complete = finished
end
C_Map = { GetBestMapForUnit = function() return H.map end,
    GetMapInfo = function(id) return { mapID = id, name = "Synthetic map " .. id, parentMapID = 0 } end }
C_Item.GetItemCount = function(id) return H.items[id] or 0 end
C_QuestLog.GetNumQuestLogEntries = function() H.questReads = H.questReads + 1; return #H.order end
C_QuestLog.GetInfo = function(index)
    if H.missingInfo[index] then return nil end
    local id = H.order[index]
    return id and H.quests[id].onQuest and { questID = id } or nil
end
C_QuestLog.GetTitleForQuestID = function(id) if not H.missingTitles[id] then return "Quest " .. id end end
C_QuestLog.GetNumQuestObjectives = function(id) return #(H.quests[id] and H.quests[id].objectives or {}) end
C_QuestLog.GetQuestObjectives = function(id)
    if not H.missingObjectives[id] then return H.quests[id] and H.quests[id].objectives end
end
C_QuestLog.IsComplete = function(id) return H.quests[id] and H.quests[id].complete or false end
C_QuestLog.IsOnQuest = function(id) return H.quests[id] and H.quests[id].onQuest or false end
C_QuestLog.IsQuestFlaggedCompleted = function(id) return H.rewarded[id] == true end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.RequestLoadQuestByID = noop
C_QuestLog.SetSelectedQuest = noop
C_QuestLog.AddQuestWatch = noop
C_SuperTrack = { SetSuperTrackedQuestID = noop }
C_QuestLog.GetLogIndexForQuestID = function(id)
    for index, current in ipairs(H.order) do if current == id and C_QuestLog.IsOnQuest(id) then return index end end
end
function GetQuestLogSpecialItemInfo() return nil end
WOW_PROJECT_MAINLINE, WOW_PROJECT_ID = 1, 1
APR.PlayerID, APR.ActiveRoute, APR.Faction, APR.ClassName, APR.ClassId = "player", nil, "Alliance", "WARRIOR", 1
APR.Race, APR.RaceID, APR.Level, APR.MaxLevel, APR.interfaceVersion = "Human", 1, 20, 90, 120105
APR.ActiveQuests, APR.RouteQuestStepList, APR.MissingQuests, APR.BonusObj = {}, {}, {}, {}
APRData = { player = { BonusSkips = {}, WantedQuestList = {} }, NPCList = {} }
APRCustomPath, APRZoneCompleted, APRGossipValidated = { player = {} }, { player = {} }, { player = {} }
local profile = APR.settings.profile
profile.enableAddon, profile.currentStepShow, profile.currentStepScale = true, true, 1
profile.currentStepFrame, profile.fillersFrame, profile.fillersFrameSnapToCurrentStep = {}, {}, false
profile.pickupQuestLookahead, profile.autoAccept, profile.autoAcceptQuestRoute = 0, false, false
profile.autoHandIn, profile.fillersFrameShowHeader = false, true
APR.IsInRouteZone = true
APR.StartPerformanceSample, APR.FinishPerformanceSample = noop, noop
APR.Debug, APR.DebugEvent = noop, noop
APR.PrintInfo, APR.PrintError = noop, noop
APR.RefreshInstanceUIVisibility, APR.MaybePromptInstanceUIPreference = noop, noop
APR.IsInstanceWithUI = function() return true end
APR.IsPetBattleActive = function() return false end
APR.SendMessage = noop -- Map and party transports are separate integration boundaries.
APR.navigation = { Cancel = noop, InvalidatePathCache = noop, Render = noop,
    RequestRouteCheck = function() H.mapRequests = H.mapRequests + 1 end,
    ScheduleRouteCheck = function() H.mapRequests = H.mapRequests + 1 end }
APR.RouteSelection, APR.heirloom, APR.coordinate = { RefreshFrameAnchor = noop }, {}, {}
APR.party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop }
APR.AFK, APR.Buff = { HideFrame = noop }, { RemoveAllBuffIcon = noop }
APR.Arrow = { SetCoord = noop, UpdateActionText = noop, ButtonShow = noop }
APR.currentStepImagePreview = { ClearPreviewImages = noop }
APR.questOrderList.DelayedUpdate = noop
APR.questOrderList.AddStepFromRoute = noop
APR.routeconfig = { CheckIsCustomPathEmpty = noop, CheckRouteResetOnLvlUp = noop, SendMessage = noop }
APR.ShowLevelConsumableReminders, APR.MaybeSojournerPrompt, APR.CheckSojournerPartySync = noop, noop, noop
function APR:RegisterButtonText(button)
    button.Text = button.Text or button:CreateFontString()
    button:SetFontString(button.Text)
end
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/Utils.lua")
APR.Debug, APR.DebugEvent, APR.PrintInfo, APR.PrintError = noop, noop, noop, noop
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/utils/LootUtils.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/utils/SojournerUtils.lua")
dofile("APR-Core/utils/RouteHashUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/features/questing/DelveRoutes.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/questing/StepInstructions.lua")
dofile("APR-Core/features/questing/StepQuestHandlers.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
dofile("APR-Core/features/questing/StepActionHandlers.lua")
dofile("APR-Core/features/questing/StepRenderer.lua")
dofile("APR-Core/features/questing/QuestCache.lua")
dofile("APR-Core/features/questing/QuestHandler.lua")
dofile("APR-Core/features/questing/RouteSuggestions.lua")
dofile("APR-Core/ui/route/QuestionPopUp.lua")
dofile("APR-Core/ui/route/FillersFrame.lua")
dofile("APR-Core/core/Event.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")
APR.currentStep:PreviousNextStepButton()
APR.event:RegisterEvents()
APR.RouteQuestStepList.journey = {
    label = "Synthetic quest path", mapID = 10, expansion = APR.EXPANSIONS.Custom, conditions = { MinLevel = 10 },
    steps = {
        { PickUp = { 701 }, Note = string.rep("Synthetic introduction. ", 30) },
        { Note = "Excluded faction instruction", Faction = "Horde" },
        { Qpart = { [701] = { 1 } }, Fillers = { [702] = { 1 } }, Zones = { 10 } },
        { Done = { 701 } }, { SetHS = 10 }, { Note = "Synthetic finish" },
    },
    parallelSteps = { { conditions = { ItemCount = { itemID = 901, count = 2 } },
        steps = { { Qpart = { [703] = { 1 } }, Fillers = { [702] = { 1 } } } } } },
}
APR.RouteQuestStepList.other = { label = "Other quest path", mapID = 10, expansion = APR.EXPANSIONS.Custom,
    steps = { { PickUp = { 888 } }, { Note = "Other finish" } } }
local scan = {}
for index = 1, 200 do scan[index] = { Note = "Synthetic index padding " .. index } end
APR.RouteQuestStepList.padding = { label = "No trigger", steps = scan }
return env
