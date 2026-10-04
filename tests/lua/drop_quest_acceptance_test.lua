-- Item-started route quests must open from bags and use route-only acceptance.
local function noop() end
format = string.format
local L = setmetatable({ Q_DROP = "Loot %s" }, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
function wipe(values) for key in pairs(values) do values[key] = nil end end
function debugprofilestop() return 0 end

local now, modifier, combat, completed, onQuest = 10, false, false, false, false
local offeredQuest, opened, accepted, advanced = nil, 0, 0, 0
local timers, bags = {}, {}
function GetTime() return now end
function IsModifierKeyDown() return modifier end
function InCombatLockdown() return combat end
function UnitIsDeadOrGhost() return false end
function IsInInstance() return false end
function GetQuestID() return offeredQuest end
function QuestGetAutoAccept() return false end
function AcceptQuest() accepted = accepted + 1; onQuest = true end
function CloseQuest() offeredQuest = nil end
C_Timer = {
    NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end,
    After = function(delay, callback) return C_Timer.NewTimer(delay, callback) end,
}
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return id == 96876 and completed end,
    IsOnQuest = function(id) return id == 96876 and onQuest end,
    GetTitleForQuestID = function(id) return "Quest " .. id end,
}
C_Container = {
    GetContainerNumSlots = function() return 3 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
    GetContainerItemQuestInfo = function(bag, slot)
        local item = bags[bag] and bags[bag][slot]
        return { questID = item and item.questID, isActive = false }
    end,
    UseContainerItem = function(bag, slot)
        local item = bags[bag][slot]
        assert(item.itemID == 275722, "Only Ukor's quest starter may be used")
        opened = opened + 1
        offeredQuest = item.questID
        APR.event.EventHandler({ tag = "detail", callback = APR.event.functions.detail }, "QUEST_DETAIL", item.itemID)
    end,
}
APRData = { player = { route = 1, BonusSkips = {} }, NPCList = {} }
APR = {
    PlayerID = "player", ActiveRoute = "route", IsInRouteZone = true, ActiveQuests = {},
    settings = { profile = { enableAddon = true, autoAcceptQuestRoute = true, pickupQuestLookahead = 1 } },
    RouteQuestStepList = {},
    currentStep = {
        previousState = {}, Reset = noop, ButtonEnable = noop, PrepareRaidIcon = noop,
        SetProgressBar = noop, AddExtraLineText = noop, AddQuestSteps = noop,
        UpdateStepButtonCooldowns = noop, UpdateStepButtonUsability = noop,
        FlushPendingContainers = noop, ProcessPendingStepButtons = noop,
    },
    Buff = { RemoveAllBuffIcon = noop }, AFK = { HideFrame = noop }, Arrow = { SetCoord = noop },
    questOrderList = { DelayedUpdate = noop },
    currentStepImagePreview = { ClearPreviewImages = noop },
    party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop },
    StartPerformanceSample = noop, FinishPerformanceSample = noop, Debug = noop, DebugEvent = noop,
    SendMessage = noop, SkipStepCondition = noop, ShouldSojournerSkipStep = noop,
    MaybeSojournerPrompt = noop, CheckSojournerPartySync = noop, ShowLevelConsumableReminders = noop,
    RefreshInstanceUIVisibility = noop, MaybePromptInstanceUIPreference = noop,
    SaveBankItemCounts = noop, RefreshLevelProfileTargets = noop, UpdateQuest = noop,
}
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return self.settings.profile end
function APR:IsInstanceWithUI() return false end
function APR:Contains(values, wanted)
    for _, value in ipairs(values or {}) do if value == wanted then return true end end
    return false
end

dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/data/models/Classes.lua")
dofile("APR-Core/utils/Utils.lua")
APR.Debug, APR.DebugEvent = noop, noop
local ukor = {
    DropQuest = 96876,
    DroppableQuest = { MobId = 266851, Qid = 96876, Text = "Ukorsbane" },
    Coord = { x = -4565.7, y = -192.3 },
    Zone = 1411,
}
local current = ukor
function APR:GetRouteSteps() return { current, { PickUp = { 42 } } } end
dofile("APR-Core/utils/StepUtils.lua")
function APR:GetStep() return current end
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
APR.SkipStepCondition = noop
dofile("APR-Core/features/questing/QuestHandler.lua")
APR.ResetMissingQuests = noop
APR.UpdateQuest = noop
function APR:UpdateNextStep() advanced = advanced + 1 end
function APR:NextQuestStep() advanced = advanced + 1 end
dofile("APR-Core/core/Event.lua")
APR.event.TalkToDenyNpcLogic = noop

local function dispatch(tag, event)
    -- Prime the dispatcher's local step/settings, then let callback errors surface.
    APR.event.EventHandler({ tag = "test", callback = noop }, event)
    APR.event.functions[tag](event)
end
local function drain()
    local index = 1
    while timers[index] do
        local timer = timers[index]
        if not timer.cancelled then timer.callback() end
        index = index + 1
        assert(index < 20, "Quest acceptance must settle without an endless retry")
    end
    timers = {}
end

-- An empty pickup pool must not exclude a drop quest or a supporting drop.
APR:ResetQuestPool()
assert(APR:IsARouteQuest(96876))
assert(not APR:IsARouteQuest(42) and not APR:IsARouteQuest(nil))
current = { Qpart = { [10] = { 1 } }, DroppableQuest = ukor.DroppableQuest }
assert(APR:IsARouteQuest(96876), "Supporting drops are accepted during objectives too")
current = { PickUp = { 10 } }
APR:EnsureQuestPool()
assert(APR:IsARouteQuest(10) and APR:IsARouteQuest(42), "NPC pickup lookahead is preserved")
current = ukor
APR:ResetQuestPool()

-- Loot messages can precede the bag update. Open only after the item is in bags.
APR:UpdateStep()
assert(opened == 0 and advanced == 0)
bags[0] = { [1] = { itemID = 100 }, [2] = { itemID = 999, questID = 123 },
    [3] = { itemID = 275722, questID = 96876 } }
dispatch("inventory", "BAG_UPDATE_DELAYED")
drain()
assert(opened == 1 and accepted == 1, "Loot opens Ukor's item and auto-accepts quest 96876")
assert(advanced == 0, "Owning the starter does not complete the step before quest acceptance")
APR.ActiveQuests[96876] = {}
APR:UpdateStep()
assert(advanced == 1, "The step advances once the accepted quest reaches the cache")

-- Respect manual bypasses and defer a locked item or combat until another update.
APR.ActiveQuests[96876], onQuest = nil, false
local profile = APR.settings.profile
local function blocked()
    local before = opened
    now = now + 2
    APR:UpdateStep()
    assert(opened == before, "A blocked starter must stay in bags")
end
profile.autoAcceptQuestRoute = false; blocked(); profile.autoAcceptQuestRoute = true
profile.enableAddon = false; blocked(); profile.enableAddon = true
modifier = true; blocked(); modifier = false
current = { DropQuest = 96876, NoAutoAccept = true }; blocked(); current = ukor
completed = true; blocked(); completed = false
onQuest = true; blocked(); onQuest = false
APR.IsInRouteZone = false; blocked(); APR.IsInRouteZone = true
APR.routeMerchantOpen = true; blocked(); APR.routeMerchantOpen = false
APR.routeBankOpen = true; blocked(); APR.routeBankOpen = false
bags[0][3].isLocked = true; blocked(); bags[0][3].isLocked = false
combat = true; blocked(); combat = false
dispatch("leaveCombat", "PLAYER_REGEN_ENABLED")
drain()
assert(opened == 2 and accepted == 2, "The item opens after leaving combat")

-- Frequent redraws cannot keep reopening the same pending offer.
onQuest = false
now = now + 2
APR:UpdateStep()
APR:UpdateStep()
assert(opened == 3, "Repeated updates share the pending item offer")
drain()
assert(accepted == 3)

-- A delayed offer still honors NoAutoAccept if manual navigation changed the step.
onQuest = false
now = now + 2
APR:UpdateStep()
current = { NoAutoAccept = true }
drain()
assert(accepted == 3)
current = ukor
profile.autoAcceptQuestRoute, profile.autoAccept = false, true
now = now + 2
APR:UpdateStep()
drain()
assert(opened == 5 and accepted == 4, "Global auto-accept also opens route starters")

APR.ActiveRoute = nil
assert(not APR:IsARouteQuest(96876), "No route means no item-started route quest")
print("Drop quests: Ukor loot, route-only acceptance, NPC lookahead, progression, bypasses and combat passed")
