-- Route repair automation and localized tame names across runtime event updates.
local function noop() end
UNKNOWN = "Unknown"
local L = setmetatable({ TAMEBEAST = "Tame the %s beast", REPAIR = "Repair your gear" },
    { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
local active, conditions, modifier, combat, npc = nil, true, false, false, 3331
local durability, money, cost, canRepair = { [1] = { 50, 100 } }, 100, 20, true
local repairs, advances, updates, listUpdates, selected = 0, 0, 0, 0, nil
local asynchronous, pendingRepair = false, false
local timers = {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = noop }
    timers[#timers + 1] = timer
    return timer
end }
function InCombatLockdown() return combat end
function IsModifierKeyDown() return modifier end
function GetInventoryItemDurability(slot)
    local item = durability[slot]
    if item then return item[1], item[2] end
end
function GetMoney() return money end
function CanMerchantRepair() return canRepair end
function GetRepairAllCost() return cost, cost > 0 end
function RepairAllItems(guild)
    assert(not guild, "Route repairs spend available personal money")
    repairs = repairs + 1
    if asynchronous then pendingRepair = true else
        for _, item in pairs(durability) do item[1] = item[2] end
    end
end
UnitCreatureID = function() return npc end
dofile("APR-Core/utils/SecretUtils.lua")
APR = { PlayerID = "player", ActiveRoute = "test", currentStep = {}, questOrderList = {},
    settings = { profile = { enableAddon = true, autoRepair = false, autoGossip = false } } }
APRData = { player = { test = 1 }, NPCList = {} }
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return self.settings.profile end
function APR:AreConditionalFiltersMet() return conditions end
function APR:StepUsesAnyOption(step, keys)
    for _, key in ipairs(keys) do if step and step[key] then return true end end
    return false
end
function APR:GetCurrentStepToken() return "test:1" end
function APR:ResolveStepText(value) return value and (rawget(L, value) or value) end
function APR:GetStep() return active end
function APR:GetRouteSteps() return { active } end
function APR:NextQuestStep() advances = advances + 1 end
function APR:UpdateStep() updates = updates + 1 end
function APR.questOrderList:DelayedUpdate(force)
    assert(force, "New NPC names must force the quest-order list to rerender at the same index")
    listUpdates = listUpdates + 1
end
local row
function APR.currentStep:AddQuestSteps(_, text) row = text end
APR.currentStep.AddRaidIconButton, APR.currentStep.AddStepButton = noop, noop
APR.currentStep.UpdateRaidIconButtonMacro = noop
APR.Debug, APR.DebugEvent, APR.StartPerformanceSample, APR.FinishPerformanceSample = noop, noop, noop, noop
APR.RefreshInstanceUIVisibility, APR.MaybePromptInstanceUIPreference = noop, noop
function APR:IsInstanceWithUI() return true end
dofile("APR-Core/utils/TargetUtils.lua")
dofile("APR-Core/features/questing/RouteActions.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/questing/Gossip.lua")
dofile("APR-Core/core/Event.lua")
function APR:GetStep() return active end
function APR:NextQuestStep() advances = advances + 1 end
local function dispatch(tag, event, ...)
    -- Prime Event.lua's current-step local, then surface callback failures directly.
    APR.event.EventHandler({ tag = "test", callback = noop }, event)
    APR.event.functions[tag](event, ...)
end
local function flush()
    local queued = timers
    timers = {}
    for _, timer in ipairs(queued) do timer.callback() end
end
local function resetRepair()
    active = { Repair = { npcID = 3331 } }
    APR.routeActionState, APR.routeMerchantOpen = nil, false
    durability, conditions, modifier, combat, npc = { [1] = { 50, 100 } }, true, false, false, 3331
    money, cost, canRepair, asynchronous = 100, 20, true, false
    repairs, advances = 0, 0
end

-- The lowest durable equipped piece decides whether the optional visit is needed.
resetRepair()
durability = { [1] = { 90, 100 }, [2] = { 95, 100 }, [16] = { 100, 100 } }
assert(APR:HandleRouteAction(active) and advances == 1 and repairs == 0)
durability[16] = { 0, 100 }
assert(APR:IsRouteRepairNeeded(active.Repair), "A broken item cannot hide behind healthy armor")
active.Repair.minDurability = 100
durability = { [1] = { 99, 100 } }
assert(APR:IsRouteRepairNeeded(active.Repair))
durability = {}
assert(not APR:IsRouteRepairNeeded(active.Repair), "No durable equipment needs no repair visit")
local api = GetInventoryItemDurability
GetInventoryItemDurability = nil
assert(APR:IsRouteRepairNeeded(active.Repair), "An absent client API must not mark repairs complete")
GetInventoryItemDurability = api

-- A route repair opens the declared NPC's vendor option even with general automation off.
resetRepair()
C_GossipInfo = { GetOptions = function() return { { gossipOptionID = 99, type = "vendor" } } end,
    SelectOption = function(id) selected = id end }
APR.gossip:HandleGossip(active)
assert(selected == 99)
selected, npc = nil, 999
APR.gossip:HandleGossip(active)
assert(selected == nil, "Do not open another NPC's merchant option")
npc, modifier = 3331, true
APR.gossip:HandleGossip(active)
assert(selected == nil)

-- Merchant events repair independently of autoRepair; only valid, affordable visits mutate gear.
resetRepair()
dispatch("merchant", "MERCHANT_SHOW")
assert(repairs == 1 and not APR:IsRouteRepairNeeded(active.Repair))
assert(APR:HandleRouteAction(active) and advances == 1)
for _, blocked in ipairs({ "merchant", "npc", "money", "repairable", "combat", "modifier", "conditions" }) do
    resetRepair()
    APR.routeMerchantOpen = blocked ~= "merchant"
    if blocked == "npc" then npc = 999 end
    if blocked == "money" then money = 1 end
    if blocked == "repairable" then canRepair = false end
    if blocked == "combat" then combat = true end
    if blocked == "modifier" then modifier = true end
    if blocked == "conditions" then conditions = false end
    assert(not APR:HandleRouteRepair(active) and repairs == 0 and advances == 0, blocked)
end
resetRepair()
APR.routeMerchantOpen, asynchronous = true, true
APR:HandleRouteAction(active)
assert(row == "Repair your gear" and advances == 0 and repairs == 1)
APR:HandleRouteAction(active)
assert(repairs == 1, "Redraws cannot repeat a repair while the client processes it")
assert(pendingRepair)
durability[1][1] = 100
dispatch("durability", "UPDATE_INVENTORY_DURABILITY")
assert(not APR.routeActionState.repairPending)
APR:HandleRouteAction(active)
assert(advances == 1)

-- Both text access paths use the fallback name until the live unit name is cached.
flush()
active = { TameBeast = { npcID = 3127, Text = "Venomtail Scorpid" } }
APR.routeActionState = nil
assert(APR:GetStepString(active) == "Tame the Venomtail Scorpid beast")
APR:HandleRouteAction(active)
assert(row == "Tame the Venomtail Scorpid beast")
local unitName = UNKNOWN
function UnitExists() return true end
function UnitIsPlayer() return false end
function UnitCanAttack() return true end
function UnitIsFriend() return false end
function UnitName() return unitName end
npc, unitName = 3127, UNKNOWN
dispatch("targetChanged", "PLAYER_TARGET_CHANGED")
assert(APRData.NPCList[3127] == nil)
unitName = "Scorpide venimeux"
dispatch("npcName", "UNIT_NAME_UPDATE", "target")
assert(APRData.NPCList[3127] == unitName and listUpdates == 1)
flush()
assert(updates > 0)
assert(APR:GetStepString(active) == "Tame the Scorpide venimeux beast")
APR:HandleRouteAction(active)
assert(row == "Tame the Scorpide venimeux beast")
dispatch("targetChanged", "PLAYER_TARGET_CHANGED")
assert(listUpdates == 1, "Cached names must not repeatedly force a route-list rebuild")
assert(APR:GetRouteActionText("TameBeast", {}) == "Tame the Unknown beast")
L.TAMEBEAST = "Old tame label"
assert(APR:GetRouteActionText("TameBeast", active.TameBeast) == "Old tame label: Scorpide venimeux")
print("Repair: threshold, merchant automation, guards and durability events; tame: fallback names and live localization passed")
