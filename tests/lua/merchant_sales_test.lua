-- Real merchant option/action paths against delayed, locked and rejected sales.
local function noop() end
local L = setmetatable({ ITEM_SOLD = "Sold %s" }, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
dofile("APR-Core/utils/SecretUtils.lua")

local clock, timers, bags, step, cursor, combat, modifier, npc = 0
local requests, nativeCalls, sold, printed, advances, dropNext, nativeLimit, nativeEnabled, nativeError
local prices, excluded, equipment, saleDelay = {}, {}, {}, 0.15
NUM_BAG_SLOTS, NUM_TOTAL_EQUIPPED_BAG_SLOTS = 4, 5
function GetTime() return clock end
function InCombatLockdown() return combat end
function IsModifierKeyDown() return modifier end
function CursorHasItem() return cursor end
function GetInventoryItemID(_, slot) return equipment[slot] end
function UnitCreatureID() return npc end
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
C_Timer = { NewTimer = function(delay, callback)
    local timer = { time = clock + delay, callback = callback,
        Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local function tick(duration)
    local untilTime, iterations = clock + duration, 0
    while true do
        local index, earliest
        for i, timer in ipairs(timers) do
            if not timer.cancelled and timer.time <= untilTime and (not earliest or timer.time < earliest) then
                index, earliest = i, timer.time
            end
        end
        if not index then break end
        local timer = table.remove(timers, index)
        clock = timer.time
        timer.callback()
        iterations = iterations + 1
        assert(iterations < 10000, "Merchant retries must yield to the next timer tick")
    end
    clock = untilTime
end
local function activeTimers()
    local count = 0
    for _, timer in ipairs(timers) do if not timer.cancelled then count = count + 1 end end
    return count
end

APR = { MaxBagSlots = 4, ActiveRoute = "test", PlayerID = "player", currentStep = {},
    NewModule = function() return {} end,
    settings = { profile = { enableAddon = true, autoVendor = true } },
    GetSettingsProfile = function(self) return self.settings.profile end,
    GetCurrentStep = function() return step end,
    GetCurrentStepToken = function(_, _, index) return "test:" .. index end,
    ResolveStepText = function(_, text) return text end,
    NextQuestStep = function() advances = advances + 1; APRData.player.test = APRData.player.test + 1 end,
    PrintInfo = function(_, message) printed[#printed + 1] = message end,
}
APR.currentStep.AddQuestSteps = noop
APRData = { player = { test = 1 } }
APR.event = { QueueStepRefresh = function()
    C_Timer.NewTimer(0.01, function()
        if step and step.SellItems then APR:HandleRouteAction(step) end
    end)
end }
C_Item = { GetItemInfo = function(id)
    return "Item " .. id, nil, nil, nil, nil, nil, nil, nil, nil, nil, prices[id]
end }
C_CurrencyInfo = { GetCoinTextureString = function(value) return tostring(value) end }
C_Container = {
    GetContainerNumSlots = function() return 32 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
    UseContainerItem = function(bag, slot)
        local info = bags[bag][slot]
        assert(APR.routeMerchantOpen and not combat and not cursor and not modifier)
        assert(info and not info.isLocked and not info.hasNoValue, "Revalidate each sale")
        requests = requests + 1
        if dropNext then dropNext = false; return end
        info.isLocked = true
        C_Timer.NewTimer(saleDelay, function()
            assert(bags[bag][slot] == info)
            bags[bag][slot] = nil
            sold = sold + 1
        end)
    end,
}
local containers = C_Container
-- Calling either UI entry point would require the player's confirmation.
function MerchantFrame_OnSellAllJunkButtonClicked() error("Do not click the native sell button") end
function StaticPopup_ShowCustomGenericConfirmation() error("Do not show a confirmation") end

dofile("APR-Core/features/questing/RouteActions.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")
APR.npcInteraction.HandleMerchantPurchase = noop

local function reset(rule)
    APR.npcInteraction:Clear()
    clock, timers, bags, step, cursor, combat, modifier, npc = 0, {}, {}, rule, false, false, false, 42
    requests, nativeCalls, sold, printed, advances, dropNext = 0, 0, 0, {}, 0, false
    nativeLimit, nativeEnabled, nativeError = 1000, true, false
    saleDelay = 0.15
    prices, excluded, equipment = {}, {}, {}
    APR.routeActionState, APRData.player.test = nil, 1
    APR.settings.profile.enableAddon, APR.settings.profile.autoVendor = true, true
    C_MerchantFrame, C_Container = nil, containers
end
local function item(bag, slot, id, quality, count, noValue)
    bags[bag] = bags[bag] or {}
    bags[bag][slot] = { itemID = id, quality = quality or 0, stackCount = count or 1, hasNoValue = noValue }
    prices[id] = noValue and 0 or 5
    return bags[bag][slot]
end
local function fill(count)
    for i = 1, count do item(math.floor((i - 1) / 32), (i - 1) % 32 + 1, 1000 + i, 0, 2) end
end
local function open()
    APR.npcInteraction:HandleMerchant("MERCHANT_SHOW", step)
    if step and step.SellItems then APR:HandleRouteAction(step) end
end
local function nativeAPI()
    C_MerchantFrame = {
        IsSellAllJunkEnabled = function() return nativeEnabled end,
        GetNumJunkItems = function()
            local count = 0
            for bag, contents in pairs(bags) do
                for _, info in pairs(contents) do
                    if not excluded[bag] and info.quality == 0 and not info.hasNoValue then count = count + 1 end
                end
            end
            return count
        end,
        SellAllJunkItems = function()
            nativeCalls = nativeCalls + 1
            if nativeError then error("Native sale unavailable on this merchant") end
            local batch = {}
            for bag, contents in pairs(bags) do
                for slot, info in pairs(contents) do
                    if #batch < nativeLimit and not excluded[bag] and info.quality == 0
                        and not info.hasNoValue and not info.isLocked then
                        info.isLocked = true
                        batch[#batch + 1] = { bag = bag, slot = slot, info = info }
                    end
                end
            end
            C_Timer.NewTimer(0.35, function()
                for _, entry in ipairs(batch) do
                    assert(bags[entry.bag][entry.slot] == entry.info)
                    bags[entry.bag][entry.slot] = nil
                    sold = sold + 1
                end
            end)
        end,
    }
end

-- More than the server's usual burst allowance, including the final equipped bag.
reset()
fill(160)
item(5, 1, 999, 0, 3)
item(5, 2, 998, 2)
item(5, 3, 997, 0, 1, true)
bags[0][1].isLocked = true
dropNext = true
open()
assert(requests == 1 and #printed == 0, "The option must not burst or announce unconfirmed sales")
tick(0.5)
bags[0][1].isLocked = false -- no BAG_UPDATE event: the timer must resume this sale
tick(50)
assert(sold == 161 and requests == 162 and bags[5][2] and bags[5][3])
assert(#printed == 1 and printed[1] == "Sold 1615", "Report only confirmed stacks, once")
assert(activeTimers() == 0 and not APR.npcInteraction.autoVendorState)

reset()
fill(3)
saleDelay = 1.5
open(); tick(1.2)
assert(requests == 1 and #printed == 0, "Do not abandon a locked request when the acknowledgement is slow")
tick(5)
assert(sold == 3 and requests == 3 and printed[1] == "Sold 30")

-- Native junk sales bypass the popup, finish asynchronously and preserve bag exclusions.
reset()
fill(80)
item(5, 1, 999)
excluded[5] = true
nativeAPI()
nativeLimit = 13
open()
assert(nativeCalls == 1 and requests == 0 and #printed == 0)
tick(0.2)
assert(nativeCalls == 1 and sold == 0, "Redraws/retries cannot duplicate a pending native request")
tick(10)
assert(sold == 80 and nativeCalls == 7 and requests == 0 and bags[5][1])
assert(#printed == 1 and printed[1] == "Sold 800" and activeTimers() == 0)

-- A native operation can make steady progress for longer than the retry timeout.
reset()
fill(5)
nativeAPI()
C_MerchantFrame.SellAllJunkItems = function()
    nativeCalls = nativeCalls + 1
    for slot = 1, 5 do
        C_Timer.NewTimer(slot * 0.6, function() bags[0][slot] = nil; sold = sold + 1 end)
    end
end
open(); tick(4)
assert(nativeCalls == 1 and sold == 5 and printed[1] == "Sold 50" and activeTimers() == 0)

-- Both paths use the fallback when the merchant disables the native feature or it fails.
for _, mode in ipairs({ "disabled", "missing", "error" }) do
    for _, route in ipairs({ false, true }) do
        reset(route and { SellItems = { junk = true, npcID = 42 } } or nil)
        fill(45)
        nativeAPI()
        if mode == "disabled" then nativeEnabled = false end
        if mode == "missing" then C_MerchantFrame.SellAllJunkItems = nil end
        if mode == "error" then nativeError = true end
        open(); tick(15)
        assert(sold == 45 and requests == 45 and advances == (route and 1 or 0), mode)
        assert(nativeCalls == (mode == "error" and 1 or 0))
    end
end

-- Route actions keep their NPC, explicit item and original equipment requirements.
for _, native in ipairs({ false, true }) do
    reset({ SellItems = { junk = true, items = { 200 }, equippedSlots = { 16 }, npcID = 42 } })
    fill(55)
    item(5, 1, 200, 1, 4)
    item(5, 2, 201, 2)
    equipment[16] = 202
    if native then nativeAPI(); nativeLimit = 12 end
    npc = 99
    open(); tick(0.5)
    assert(sold == 0 and requests == 0 and nativeCalls == 0 and advances == 0)
    assert(activeTimers() == 0, "A different NPC must not keep refreshing the route")
    npc = 42
    open()
    tick(20)
    assert(sold == 56 and advances == 0 and bags[5][2], "Keep waiting for equipped targets")
    assert(activeTimers() == 0, "Waiting for manual equipment removal must not poll the route UI")
    assert(not APR.npcInteraction.autoVendorState, "The option and action cannot compete")
    equipment[16] = nil
    item(5, 3, 202, 1)
    APR:HandleRouteAction(step) -- equipment/bag refresh after manual removal
    tick(1)
    assert(sold == 57 and advances == 1 and activeTimers() == 0)
    assert(native and nativeCalls > 0 and requests == 2 or not native and requests == 57)
end

-- Temporary blockers resume without bag events and never consume a foreign cursor.
for _, blocker in ipairs({ "combat", "cursor", "modifier", "locked" }) do
    reset()
    local info = item(0, 1, 100)
    if blocker == "combat" then combat = true end
    if blocker == "cursor" then cursor = true end
    if blocker == "locked" then info.isLocked = true end
    open()
    if blocker == "modifier" then modifier = true end
    tick(0.1)
    if blocker ~= "modifier" then assert(requests == 0, blocker) end
    combat, cursor, modifier, info.isLocked = false, false, false, false
    tick(2)
    assert(sold == 1 and requests == 1 and activeTimers() == 0, blocker)
end
reset()
fill(2)
modifier = true
open(); tick(1)
assert(requests == 0 and activeTimers() == 0, "Holding a modifier when opening opts out of automatic selling")
reset()
local uncached = item(0, 1, 100)
uncached.quality, prices[100] = nil, nil
open(); tick(0.5)
assert(requests == 0 and APR.npcInteraction.autoVendorState, "Unknown quality cannot complete a junk sale")
uncached.quality = 0
tick(1)
assert(sold == 1 and activeTimers() == 0, "Uncached prices cannot raise an error or prevent selling")

-- Closing, disabling, stepping away and changing the option stop queued work.
for _, stop in ipairs({ "close", "clear", "disable", "option", "step" }) do
    reset()
    fill(30)
    open()
    local oldTimer = APR.npcInteraction.vendorTimer
    if stop == "close" then APR.npcInteraction:HandleMerchant("MERCHANT_CLOSED", step) end
    if stop == "clear" then APR.npcInteraction:Clear() end
    if stop == "disable" then APR.settings.profile.enableAddon = false end
    if stop == "option" then APR.settings.profile.autoVendor = false end
    if stop == "step" then step = { SellItems = { junk = true } } end
    tick(2)
    oldTimer.callback()
    assert(requests == 1 and activeTimers() == 0, stop)
end
reset({ SellItems = { junk = true } })
fill(30)
open()
APR.routeActionState, step = nil, nil
tick(2)
assert(requests == 1 and activeTimers() == 0, "An old action timer must not refresh a different step")

-- Reopening replaces cancelled callbacks; legacy container APIs retain no-value filtering.
reset()
fill(12)
open()
local stale = APR.npcInteraction.vendorTimer
APR.npcInteraction:HandleMerchant("MERCHANT_CLOSED", nil)
tick(0.5)
open()
local before = requests
stale.callback()
assert(requests == before)
tick(5)
assert(sold == 12)
reset()
fill(8)
item(0, 9, 99, 0, 1, true)
GetContainerNumSlots, UseContainerItem = containers.GetContainerNumSlots, containers.UseContainerItem
function GetContainerItemInfo(bag, slot)
    local info = containers.GetContainerItemInfo(bag, slot)
    if info then return nil, info.stackCount, info.isLocked, info.quality, nil, nil, nil, nil,
        info.hasNoValue, info.itemID end
end
C_Container = nil
open(); tick(3)
assert(sold == 8 and bags[0][9] and activeTimers() == 0)
print("Merchant sales: native/fallback, large inventories, acknowledgements, retries and cancellation passed")
