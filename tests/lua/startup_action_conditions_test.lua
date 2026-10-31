-- Unknown startup quest state must not commit actions or action completion.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end

APR = { PlayerID = "player", ActiveRoute = "synthetic", Faction = "Alliance" }
APRData = { player = { synthetic = 1 } }
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/features/questing/RouteActions.lua")

local quests, rewarded, account, ready, bags, equipment, known, steps
local abandoned, rows, buttons, selected, questReads, advances, mutations, buys, timers
local cursor, learned, clock, target, durability, repairs, durabilityReads, resurrections
local ui = {}
function ui:AddQuestSteps(id, text, objective)
    rows[#rows + 1] = { id = id, text = text, objective = objective }
end
function ui:AddStepButton(...) buttons[#buttons + 1] = { ... } end
function ui:AddRaidIconButton(...) buttons[#buttons + 1] = { ... } end
function APR:GetCurrentStepToken(route, index) return route .. ":" .. index end
function APR:NextQuestStep()
    advances = advances + 1
    APRData.player.synthetic = APRData.player.synthetic + 1
end
function APR:ResolveStepText(text) return text end
function APR:GetSpellName(id) return "Spell " .. id end
function APR:IsSpellKnown(id) return known[id] == true end
function APR:GetTargetID() return target end
APR.AFK = { SetAfkTimer = function(_, seconds) timers[#timers + 1] = seconds end }

C_QuestLog = {
    IsOnQuest = function(id) questReads = questReads + 1; return quests[id] == true end,
    IsComplete = function(id) questReads = questReads + 1; return ready[id] == true end,
    IsQuestFlaggedCompleted = function(id) questReads = questReads + 1; return rewarded[id] == true end,
    IsQuestFlaggedCompletedOnAccount = function(id) questReads = questReads + 1; return account[id] == true end,
    SetSelectedQuest = function(id) selected = id end,
    AbandonQuest = function()
        assert(selected and quests[selected], "Only a live quest can be abandoned")
        abandoned[#abandoned + 1], quests[selected] = selected, nil
    end,
}
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 2 or 0 end,
    GetContainerItemInfo = function(bag, slot) return bag == 0 and bags[slot] or nil end,
    UseContainerItem = function(bag, slot)
        assert(bag == 0 and bags[slot]); mutations = mutations + 1; bags[slot] = nil
    end,
    PickupContainerItem = function(bag, slot)
        assert(bag == 0 and bags[slot]); cursor, bags[slot] = bags[slot], nil
    end,
}
C_Item = { GetItemInfo = function(id) return "Item " .. id end }
function DeleteCursorItem() assert(cursor); cursor = nil; mutations = mutations + 1 end
function GetCursorInfo() return cursor and "item", cursor and cursor.itemID end
function ClearCursor() cursor = nil end
function CursorHasItem() return cursor ~= nil end
function InCombatLockdown() return false end
function GetInventoryItemID(_, slot) return equipment[slot] end
function GetTime() return clock end
function GetMoney() return 100 end
function UnitCreatureID() return target end
function GetInventoryItemDurability() durabilityReads = durabilityReads + 1; return durability, 100 end
function CanMerchantRepair() return true end
function GetRepairAllCost() return 10, true end
function RepairAllItems() repairs = repairs + 1 end
function AcceptXPLoss() resurrections = resurrections + 1 end
function GetNumTrainerServices() return learned and 0 or 1 end
function GetTrainerServiceInfo() return "Synthetic service", "", "available" end
function GetTrainerServiceItemLink() return "spell:4301" end
function GetTrainerServiceCost() return 10 end
function BuyTrainerService()
    buys, learned, known[4301] = buys + 1, true, true
end

local function reset(step)
    quests, rewarded, account, ready = {}, {}, {}, {}
    bags, equipment, known = {}, {}, {}
    abandoned, rows, buttons, timers = {}, {}, {}, {}
    selected, questReads, advances, mutations, buys = nil, 0, 0, 0, 0
    cursor, learned, clock, target = nil, false, 10, 4401
    durability, repairs, durabilityReads, resurrections = 50, 0, 0, 0
    APR.currentStep, APR.routeActionState, APR.startupQuestStatePending = ui, nil, true
    APR.routeMerchantOpen, APR.routeTrainerOpen, APR.routeBankOpen = true, true, false
    APRData.player.synthetic = 1
    steps = { step, { Note = "Following instruction" } }
end
local function current() return APR:HandleRouteAction(steps[APRData.player.synthetic]) end
local function item()
    bags[1] = { itemID = 4201, stackCount = 1, quality = 1 }
end

reset({ LeaveQuest = 4101, IsQuestUncompleted = 4102 })
quests[4101] = true
assert(current() == true, "A deferred abandonment must consume the action handler")
assert(#abandoned == 0 and advances == 0, "Unknown quest conditions must not abandon or advance")
assert(questReads == 0, "Unknown quest state must not be interpreted as a native false")
assert(#rows == 1 and rows[1].id == 4101 and rows[1].text == "LEAVE_QUEST",
    "The deferred quest instruction remains visible")
APR.startupQuestStatePending = nil
assert(current() and #abandoned == 1 and abandoned[1] == 4101 and advances == 0)
assert(current() and advances == 1, "Advance only after the quest is observed absent")
assert(current() == false and #abandoned == 1 and advances == 1,
    "The following instruction must not repeat the abandoned action")

-- Every quest predicate, including nested alternatives with a true static arm,
-- must defer effects before native state is consulted. Each known outcome below
-- is chosen by the fixture, independently of the implementation's evaluator.
local predicateCases = {
    { { IsQuestReadyForTurnIn = 4102 }, function() quests[4102], ready[4102] = true, true end },
    { { IsQuestOnQuest = 4102 }, function() quests[4102] = true end },
    { { IsQuestNotOnQuest = 4102 } },
    { { IsQuestCompleted = 4102 }, function() rewarded[4102] = true end },
    { { IsQuestUncompleted = 4102 } },
    { { IsOneOfQuestsCompleted = { 4102, 4103 } }, function() rewarded[4103] = true end },
    { { IsOneOfQuestsUncompleted = { 4102, 4103 } } },
    { { IsOneOfQuestsCompletedOnAccount = { 4102, 4103 } }, function() account[4103] = true end },
    { { IsOneOfQuestsUncompletedOnAccount = { 4102, 4103 } } },
    { { IsQuestsCompleted = { 4102, 4103 } }, function() rewarded[4102], rewarded[4103] = true, true end },
    { { IsQuestsUncompleted = { 4102, 4103 } }, function() rewarded[4102] = true end },
    { { IsQuestsCompletedOnAccount = { 4102, 4103 } }, function() account[4102], account[4103] = true, true end },
    { { IsQuestsUncompletedOnAccount = { 4102, 4103 } }, function() account[4102] = true end },
    { { AnyOf = { { Faction = "Alliance" }, { IsQuestOnQuest = 4102 } } } },
    { { AllOf = { { Faction = "Alliance" }, { IsQuestOnQuest = 4102 } } }, function() quests[4102] = true end },
    { { Not = { IsQuestCompleted = 4102 } } },
    { { AnyOf = { { AllOf = { { Not = { IsQuestCompleted = 4102 } }, { Faction = "Alliance" } } } } } },
}
for index, case in ipairs(predicateCases) do
    local step = { LeaveQuest = 4101 }
    for key, value in pairs(case[1]) do step[key] = value end
    reset(step)
    quests[4101] = true
    if case[2] then case[2]() end
    assert(current() == true and #abandoned == 0 and advances == 0 and questReads == 0,
        "Pending predicate must defer abandonment: " .. index)
    APR.startupQuestStatePending = nil
    assert(current() and #abandoned == 1 and abandoned[1] == 4101 and advances == 0,
        "A known positive predicate resumes exactly one abandonment: " .. index)
    assert(current() and advances == 1 and #abandoned == 1)
    -- Inventory mutation has no intrinsic quest dependency, so this also
    -- verifies the conditional gate itself rather than only abandonment's wait.
    step.LeaveQuest, step.DestroyItems = nil, { items = { 4201 } }
    reset(step)
    item()
    if case[2] then case[2]() end
    assert(current() and mutations == 0 and advances == 0 and questReads == 0
        and APR.routeActionState == nil, "Pending predicate must defer inventory effects: " .. index)
    APR.startupQuestStatePending = nil
    assert(current() and mutations == 1 and advances == 0 and bags[1] == nil,
        "Known positive predicate resumes inventory effects: " .. index)
    assert(current() and mutations == 1 and advances == 1)
end

for _, condition in ipairs({
    { AnyOf = { { Faction = "Horde" }, { IsQuestOnQuest = 4102 } } },
    { AllOf = { { Faction = "Alliance" }, { IsQuestCompleted = 4102 } } },
    { Not = { IsQuestNotOnQuest = 4102 } },
}) do
    local step = { DestroyItems = { items = { 4201 } } }
    for key, value in pairs(condition) do step[key] = value end
    reset(step); item()
    assert(current() and mutations == 0 and advances == 0)
    APR.startupQuestStatePending = nil
    assert(current() and mutations == 0 and advances == 0 and bags[1]
        and APR.routeActionState == nil, "Known negative nested conditions must still suppress effects")
end

reset({ LeaveQuest = 4101, LeaveQuests = { 4101, 4103, 4103 }, Note = "Keep this instruction" })
assert(current() and advances == 0 and questReads == 0 and #rows == 2,
    "An unknown empty journal must not complete intrinsic abandonment; rows are deduplicated")
quests[4101], quests[4103] = true, true
APR.startupQuestStatePending = nil
assert(current() and #abandoned == 2 and abandoned[1] == 4101 and abandoned[2] == 4103)
assert(current() and advances == 1 and #abandoned == 2)
reset({ LeaveQuests = { 4101, 4103 } })
assert(current() and advances == 0)
APR.startupQuestStatePending = nil
assert(current() and advances == 1 and #abandoned == 0,
    "A synchronized empty journal is valid and completes abandonment")
reset({ LeaveQuest = 4101 })
APR.currentStep = nil
assert(current() and advances == 0 and #abandoned == 0)
quests[4101], APR.startupQuestStatePending = true, nil
assert(current() and advances == 0 and #abandoned == 1)
assert(current() and advances == 1 and #abandoned == 1,
    "Deferred abandonment resumes correctly when the optional UI is absent")

reset({ LeaveQuest = 4101, UseSpell = { spellID = 4301 } })
quests[4101] = true
assert(current() == false and #abandoned == 0 and advances == 0,
    "An independent mixed primary action keeps its normal rendering fallback")
APR.startupQuestStatePending = nil
assert(current() == false and #abandoned == 1 and advances == 0)
reset({ LeaveQuest = 4101, UseSpell = { spellID = 4301 }, IsQuestUncompleted = 4102 })
quests[4101] = true
assert(current() == true and #abandoned == 0 and #rows == 1,
    "A conditional mixed action is consumed while unknown, with its instruction visible")
rewarded[4102], APR.startupQuestStatePending = true, nil
assert(current() == true and #abandoned == 0 and advances == 0,
    "Re-evaluate changed eligibility before resuming an abandonment")

local actionCases = {
    { "DeathSkip", true },
    { "SellItems", { items = { 4201 } } },
    { "LearnSkill", { spellID = 4301 } },
    { "BankDeposit", { items = { 4201 } } },
    { "BankWithdraw", { items = { 4201 } } },
    { "TameBeast", { npcID = 4401 } },
    { "DestroyItems", { items = { 4201 } } },
    { "EquipItem", { slot = 16, itemID = 4201 } },
    { "Repair", { npcID = 4401 } },
}
for _, case in ipairs(actionCases) do
    reset({ [case[1]] = case[2], IsQuestUncompleted = 4102 })
    item(); equipment[16] = 4201
    local prior = { token = "synthetic:1", complete = true, pending = { marker = "retained" } }
    APR.routeActionState = prior
    assert(current() == true and advances == 0 and mutations == 0 and buys == 0 and repairs == 0,
        "All recognized conditional actions must be consumed without effects: " .. case[1])
    assert(questReads == 0 and #rows == 1 and rows[1].id == case[1]
        and APR.routeActionState == prior and prior.pending.marker == "retained",
        "Deferral must render without clearing or replacing existing operation state")
    APR.currentStep = nil
    assert(current() == true and advances == 0 and mutations == 0,
        "Deferred actions must also work before the optional UI exists")
end

reset({ DestroyItems = { items = { 4201 } }, Faction = "Alliance" })
item()
assert(current() and mutations == 1 and bags[1] == nil and advances == 0,
    "A static positive condition must not wait for unrelated quest synchronization")
assert(current() and advances == 1)
reset({ DestroyItems = { items = { 4201 } }, Faction = "Horde" })
item()
assert(current() and mutations == 0 and bags[1] and advances == 0,
    "A static negative condition must not commit effects or completion")
reset({ DestroyItems = { items = { 4201 } }, IsQuestUncompleted = 4102 })
item()
assert(current() and mutations == 0 and APR.routeActionState == nil)
rewarded[4102], APR.startupQuestStatePending = true, nil
assert(current() and mutations == 0 and advances == 0 and APR.routeActionState == nil)
rewarded[4102] = nil
assert(current() and mutations == 1 and advances == 0)
assert(current() and advances == 1 and mutations == 1)

-- A linked vendor visit is intrinsically quest-dependent even without filters.
reset({ SellItems = { items = { 4201 }, equippedSlots = { 16 }, questID = 4102 } })
item(); equipment[16] = 4201
assert(current() and mutations == 0 and advances == 0 and APR.routeActionState == nil and questReads == 0)
local sale = { saleNeedsRetry = true, pending = { marker = "unmodified" } }
assert(not APR:ProcessRouteItems("SellItems", steps[1].SellItems, sale))
assert(sale.saleNeedsRetry and sale.pending.marker == "unmodified" and mutations == 0 and questReads == 0,
    "Direct linked sales must defer before any persistent snapshot or pending-state mutation")
rewarded[4102], APR.startupQuestStatePending = true, nil
assert(current() and advances == 1 and mutations == 0 and bags[1] and equipment[16] == 4201,
    "A rewarded linked quest resumes by skipping the obsolete sale without selling")
reset({ SellItems = { items = { 4201 }, questID = 4102 } })
item()
assert(current() and mutations == 0)
APR.startupQuestStatePending = nil
assert(current() and mutations == 1 and advances == 0 and bags[1] == nil)
assert(current() and advances == 1 and mutations == 1)
reset({ SellItems = { items = { 4201 } } })
item()
assert(current() and mutations == 1 and questReads == 0,
    "An unlinked sale remains independent of quest initialization")

-- Event entry points must enforce the same unknown-condition boundary.
reset({ LearnSkill = { spellID = 4301 }, IsQuestUncompleted = 4102 })
APR:HandleSkillTrainer(steps[1])
assert(buys == 0 and APR.routeActionState == nil and questReads == 0)
rewarded[4102], APR.startupQuestStatePending = true, nil
APR:HandleSkillTrainer(steps[1])
assert(buys == 0 and APR.routeActionState == nil)
rewarded[4102] = nil
APR:HandleSkillTrainer(steps[1]); APR:HandleSkillTrainer(steps[1])
assert(buys == 1 and known[4301], "Only the now-eligible trainer service is purchased once")
assert(current() and advances == 1)
reset({ LearnSkill = { allAvailable = true }, IsQuestUncompleted = 4102 })
learned = true
APR:HandleSkillTrainer(steps[1])
assert(APR.routeActionState == nil and buys == 0,
    "An unknown condition cannot latch all-services-complete from an empty trainer")
learned, APR.startupQuestStatePending = false, nil
assert(current() and buys == 1 and advances == 0)
assert(current() and buys == 1 and advances == 1,
    "The trainer is re-evaluated after synchronization, then completes on observed exhaustion")

reset({ TameBeast = { npcID = 4401 }, IsQuestUncompleted = 4102 })
APR:HandleTameBeast(steps[1], "UNIT_SPELLCAST_START", "player", 1515)
APR:HandleTameBeast(steps[1], "UNIT_SPELLCAST_SUCCEEDED", "player", 1515)
assert(APR.routeActionState == nil and questReads == 0)
APR.startupQuestStatePending = nil
APR:HandleTameBeast(steps[1], "UNIT_SPELLCAST_SUCCEEDED", "player", 1515)
assert(not APR.routeActionState.complete, "A deferred cast must not leave a captured target or completion")
APR:HandleTameBeast(steps[1], "UNIT_SPELLCAST_START", "player", 1515)
APR:HandleTameBeast(steps[1], "UNIT_SPELLCAST_SUCCEEDED", "player", 1515)
assert(APR.routeActionState.complete and current() and advances == 1)

reset({ SpellETA = { spellID = 4301, seconds = 17 }, Not = { IsQuestCompleted = 4102 } })
APR:HandleSpellETA(steps[1], "player", 4301)
assert(#timers == 0 and APR.routeActionState == nil and questReads == 0)
rewarded[4102], APR.startupQuestStatePending = true, nil
APR:HandleSpellETA(steps[1], "player", 4301)
assert(#timers == 0 and APR.routeActionState == nil)
rewarded[4102] = nil
APR:HandleSpellETA(steps[1], "player", 4301); APR:HandleSpellETA(steps[1], "player", 4301)
assert(#timers == 1 and timers[1] == 17 and APR.routeActionState.timerStarted)

reset({ Repair = { npcID = 4401 }, IsQuestUncompleted = 4102 })
assert(not APR:HandleRouteRepair(steps[1]) and repairs == 0 and durabilityReads == 0 and APR.routeActionState == nil)
APR.startupQuestStatePending = nil
assert(not APR:HandleRouteRepair(steps[1]) and repairs == 1 and APR.routeActionState.repairPending)
assert(not APR:HandleRouteRepair(steps[1]) and repairs == 1, "Wait for the native repair receipt")
durability = 100
assert(current() and advances == 1 and repairs == 1)

reset({ DeathSkip = true, IsQuestUncompleted = 4102 })
APR:HandleDeathSkip(steps[1], "PLAYER_DEAD")
APR:HandleDeathSkip(steps[1], "CONFIRM_XP_LOSS")
APR:HandleDeathSkip(steps[1], "PLAYER_UNGHOST")
assert(APR.routeActionState == nil and resurrections == 0 and advances == 0)
APR.startupQuestStatePending = nil
APR:HandleDeathSkip(steps[1], "PLAYER_UNGHOST")
assert(not APR.routeActionState.complete, "Deferred death events cannot become a completed shortcut")
APR:HandleDeathSkip(steps[1], "PLAYER_DEAD")
APR:HandleDeathSkip(steps[1], "CONFIRM_XP_LOSS")
APR:HandleDeathSkip(steps[1], "PLAYER_UNGHOST")
assert(current() and advances == 1 and resurrections == 1)

-- Deferral must neither retain a stale route token nor schedule an old action.
reset({ DestroyItems = { items = { 4201 } }, IsQuestUncompleted = 4102 })
local oldState = { token = "synthetic:1", complete = true }
APR.routeActionState = oldState
item()
assert(current() and mutations == 0 and APR.routeActionState == oldState)
steps[2] = { DestroyItems = { items = { 4202 } }, IsQuestUncompleted = 4103 }
APRData.player.synthetic = 2
bags[2], APR.startupQuestStatePending = { itemID = 4202, stackCount = 1 }, nil
assert(current() and mutations == 1 and bags[1].itemID == 4201 and bags[2] == nil
    and APR.routeActionState ~= oldState and APR.routeActionState.token == "synthetic:2")
assert(current() and advances == 1 and APRData.player.synthetic == 3 and mutations == 1)

-- RouteActions also loads in small modules/fixtures without RouteUtils or UI.
local pendingHelper, filters = APR.HasPendingStartupQuestConditions, APR.AreConditionalFiltersMet
APR.HasPendingStartupQuestConditions, APR.AreConditionalFiltersMet = nil, nil
reset({ DestroyItems = { items = { 4201 } } })
item(); APR.currentStep = nil
assert(current() and mutations == 1 and advances == 0)
assert(current() and advances == 1)
assert(APR:HandleRouteAction(nil) == false and APR:HandleRouteAction({ Note = "Ordinary" }) == false)
APR.HasPendingStartupQuestConditions, APR.AreConditionalFiltersMet = pendingHelper, filters

print("Startup action conditions: unknown predicates, native effects, intrinsic dependencies, UI and state resume passed")
