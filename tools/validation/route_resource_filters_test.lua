local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
APR = { interfaceVersion = 16001, Race = "Orc", ClassName = "WARRIOR", ClassId = 1, Faction = "Horde",
    PlayerID = "player", ActiveRoute = "route", RouteQuestStepList = {}, Debug = noop }
function APR:NewModule() return {} end
function UnitLevel() return 12 end
function tContains(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
C_Map = { GetBestMapForUnit = function() return 1411 end }
local copper, hardcore, count, dps = 99, false, 2, 2.04
function GetMoney() return copper end
C_GameRules = { IsHardcoreActive = function() return hardcore end }
C_Item = {
    GetItemCount = function(_, bank) return count + (bank and 1 or 0) end,
    GetItemStats = function() return { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = dps } end,
}
function GetInventoryItemLink() return "item:123" end
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/utils/RouteManager.lua")
local filters = { Money = { operator = "<", copper = 100 },
    ItemCount = { itemID = 10, count = 2 },
    EquippedItemStat = { slot = 16, stat = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", operator = "<", value = 2.05, precision = 1 } }
assert(APR:AreConditionalFiltersMet(filters))
copper = 100
assert(not APR:AreConditionalFiltersMet(filters), "Money skip threshold is exclusive")
copper, count = 99, 1
assert(not APR:AreConditionalFiltersMet(filters))
filters.ItemCount.includeBank = true
assert(APR:AreConditionalFiltersMet(filters))
dps = 2.08
assert(not APR:AreConditionalFiltersMet(filters), "Equipment uses specified source precision")
dps = nil
assert(not APR:AreConditionalFiltersMet(filters))
filters.EquippedItemStat.allowMissing = true
assert(APR:AreConditionalFiltersMet(filters))
assert(APR:AreConditionalFiltersMet({ Hardcore = false }))
hardcore = true
assert(not APR:AreConditionalFiltersMet({ Hardcore = false }))
assert(APR:AreConditionalFiltersMet({ Hardcore = true }))
C_GameRules = nil
assert(not APR:IsHardcoreCharacter())
C_Item = nil
assert(not APR:MeetsItemCount({ itemID = 10, count = 1 }))
function GetItemCount() return 3 end
assert(APR:MeetsItemCount({ itemIDs = { 10, 11 }, operator = "==", count = 6 }))
assert(not APR:CompareRouteNumber(3, "invalid", 3))
assert(APR:StepUsesAnyOption({ AnyOf = { { Money = filters.Money } } }, {'Money'}))

-- Class-specific follow-up branches use the existing step condition evaluator.
APR.RouteQuestStepList.route = { expansion = APR.EXPANSIONS.Forever,
    nextRoute = { { route = "warrior", conditions = { Class = "WARRIOR" } },
                  { route = "mage", conditions = { Class = "MAGE" } }, "shared" } }
for _, key in ipairs({ "warrior", "mage", "shared" }) do
    APR.RouteQuestStepList[key] = { expansion = APR.EXPANSIONS.Forever, label = key }
end
local suggestions = APR:GetNextRouteSuggestions("route")
assert(#suggestions == 2 and suggestions[1].key == "warrior" and suggestions[2].key == "shared")

-- Resource events only refresh a relevant active step, coalescing bursts.
APRData = { player = { route = 1 } }
local currentStep, updates, timers = filters, 0, {}
function APR:GetStep(index) assert(index == 1); return currentStep end
function APR:UpdateStep() updates = updates + 1 end
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
function wipe(t) for k in pairs(t) do t[k] = nil end end
local registrations = {}
function CreateFrame() return { SetScript = noop, RegisterEvent = function(_, name)
    registrations[name] = (registrations[name] or 0) + 1
end, UnregisterAllEvents = noop } end
dofile("APR-Core/core/Event.lua")
for _ = 1, 10 do APR.event.functions.money() end
assert(#timers == 1)
timers[1].callback()
assert(updates == 1)
currentStep = { PickUp = { 1 } }
APR.event.functions.money()
assert(#timers == 1, "Unrelated quest steps do not rebuild on money/bag changes")
currentStep = filters
APR.event.functions.money()
-- Specific event ownership: each new event has only one subscription.
APR.event:MyRegisterEvent()
for _, name in ipairs({'CHAT_MSG_LOOT', 'BAG_UPDATE_DELAYED', 'PLAYER_MONEY',
    'UNIT_SPELLCAST_START', 'UNIT_SPELLCAST_SUCCEEDED', 'TRAINER_SHOW', 'BANKFRAME_OPENED',
    'PLAYERBANKSLOTS_CHANGED', 'SKILL_LINES_CHANGED', 'PLAYER_EQUIPMENT_CHANGED'}) do
    assert(registrations[name] == 1, name .. ' must have one owner')
end
assert(not APR.event.functions.routeActions and not APR.event.functions.routeResources)
APR.event:CleanupEvents()
assert(timers[2].cancelled and not APR.event.stepRefreshTimer)
currentStep = {Collection={itemID=10,quantity=3}}
APR.event.functions.money()
assert(#timers == 2, 'Money cannot refresh an inventory-only condition')
function APR:SaveBankItemCounts() end
function APR:RefreshLevelProfileTargets() end
APR.event.functions.inventory('BAG_UPDATE_DELAYED')
assert(#timers == 3, 'Inventory changes refresh Collection')
APR.event.functions.bank('BANKFRAME_OPENED')
assert(APR.routeBankOpen and #timers == 3, 'Bank event shares coalesced refresh')
APR.event.functions.bank('BANKFRAME_CLOSED')
assert(not APR.routeBankOpen)
print("Route resources: money, inventory, equipment, Hardcore, branching and coalesced events passed")
