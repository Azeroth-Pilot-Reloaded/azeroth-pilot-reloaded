-- Real route actions and bank/inventory refreshes, with independent container roles.
local function noop() end
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub()
    return { GetLocale = function() return locale end }
end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
function wipe(values)
    for key in pairs(values) do
        values[key] = nil
    end
end
local clock, timers, contents, sizes, bankBags, steps, requests, pending, accessible, tabData
local combat, cursor, unavailable
function GetTime() return clock end
function InCombatLockdown() return combat end
function CursorHasItem() return cursor end
APR = { PlayerID = "player", ActiveRoute = "synthetic", settings = { profile = { enableAddon = true } } }
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return self.settings.profile end
function APR:ResetQuestTitleRequests() end
function APR:RefreshLevelProfileTargets() end
function APR:Debug() end
function APR:ResolveStepText(text) return text end
function APR:GetStep(index) return steps[index] end
function APR:GetCurrentStepToken(route, index) return route .. ":" .. index end
function APR:NextQuestStep() APRData.player.synthetic = APRData.player.synthetic + 1 end
function APR:UpdateStep() self:HandleRouteAction(self:GetStep(APRData.player.synthetic)) end
function APR:StepUsesAnyOption(step, keys)
    for _, key in ipairs(keys) do
        if step and step[key] then return true end
    end
    return false
end
APR.npcInteraction = { Clear = noop }
C_Item = { GetItemInfo = function(id) return "Item " .. id end }
C_Timer = {
    NewTimer = function(delay, callback)
        local timer = { time = clock + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end,
}
local function tick(duration)
    local finish = clock + duration
    while true do
        local first, at
        for index, timer in ipairs(timers) do
            if not timer.cancelled and timer.time <= finish and (not at or timer.time < at) then
                first, at = index, timer.time
            end
        end
        if not first then break end
        local timer = table.remove(timers, first)
        clock = timer.time
        timer.callback()
    end
    clock = finish
end
local function item(bag, slot, id, count)
    contents[bag] = contents[bag] or {}
    contents[bag][slot] = { itemID = id, stackCount = count }
end
C_Container = {
    GetContainerNumSlots = function(bag)
        if bag == unavailable then return nil end
        return sizes[bag] or 0
    end,
    GetContainerItemInfo = function(bag, slot) return contents[bag] and contents[bag][slot] end,
    UseContainerItem = function(bag, slot, unit, bankType)
        assert(not pending, "Only one native transfer can be in flight")
        assert(accessible and APR.routeBankOpen and not APR.routeMerchantOpen and not combat and not cursor)
        local source = assert(contents[bag] and contents[bag][slot])
        if Enum then
            assert(
                unit == nil and bankType == Enum.BankType.Character,
                "A bank transfer must explicitly target the character bank, even with an account tab selected"
            )
        end
        pending = { bag = bag, slot = slot, item = source }
        requests[#requests + 1] = pending
        source.isLocked = true
    end,
}
dofile("APR-Core/utils/LootUtils.lua")
dofile("APR-Core/features/questing/RouteActions.lua")
dofile("APR-Core/core/Event.lua")

local function reset(profile, action)
    clock, timers, contents, sizes, bankBags, requests = 0, {}, {}, {}, {}, {}
    pending, combat, cursor, unavailable, tabData = nil, false, false, nil, nil
    accessible = true
    NUM_BAG_SLOTS, NUM_TOTAL_EQUIPPED_BAG_SLOTS, NUM_BANKBAGSLOTS = 4, 5, 7
    BANK_CONTAINER, ITEM_INVENTORY_BANK_BAG_OFFSET = nil, nil
    Enum, C_Bank, BankFrame = nil, nil, nil
    local first, last, carried, account = -1, 11, 0, nil
    if profile ~= "legacy" then
        first, last, carried, account = 6, profile == "forever" and 14 or 11, 5, profile == "forever" and 15 or 12
        Enum = { BagIndex = { Keyring = -1, Backpack = 0, ReagentBag = 5 }, BankType = { Character = 0, Account = 2 } }
        for index = 1, last - first + 1 do
            Enum.BagIndex["CharacterBankTab_" .. index] = first + index - 1
        end
        Enum.BagIndex.AccountBankTab_1 = account
        tabData = { { ID = first }, { ID = last } }
        C_Bank = {
            CanUseBank = function(kind)
                assert(kind == 0)
                return accessible
            end,
            FetchPurchasedBankTabData = function(kind)
                assert(kind == 0)
                return tabData
            end,
        }
        BankFrame = {
            GetActiveBankType = function() return Enum.BankType.Account end,
            SetTab = function() error("Automation must not change the player's selected bank tab") end,
        }
        -- The old -1 availability check accidentally succeeds on a populated keyring.
        sizes[-1] = 1
        item(-1, 1, 7101, 13)
        sizes[account] = 4
        item(account, 1, 7101, 17)
    else
        NUM_TOTAL_EQUIPPED_BAG_SLOTS, BANK_CONTAINER = 4, -1
        for bag = 5, 11 do
            bankBags[bag] = true
        end
    end
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        sizes[bag] = 4
    end
    bankBags[first], bankBags[last], sizes[first], sizes[last] = true, true, 4, 4
    APRData = { player = { synthetic = 1 } }
    APR.routeActionState, APR.routeBankOpen, APR.routeMerchantOpen = nil, false, false
    APR.event.bankRefreshTimer, APR.event.stepRefreshTimer = nil, nil
    steps = { { [action or "BankWithdraw"] = { items = { 7101, 7102 } } }, { Note = "Following instruction" } }
    return first, last, carried, account
end
local function burst()
    for _ = 1, 20 do
        APR.event.functions.bank("PLAYERBANKSLOTS_CHANGED")
        APR.event.functions.inventory("BAG_UPDATE_DELAYED")
    end
    tick(0.2)
end
local function acknowledge(quantity)
    local transfer = assert(pending)
    local source = transfer.item
    assert(contents[transfer.bag][transfer.slot] == source)
    quantity = quantity or source.stackCount
    local destination = bankBags[transfer.bag] and (Enum and 5 or 0) or (Enum and 6 or -1)
    local targetSlot = source.itemID == 7101 and 1 or 2
    local target = contents[destination] and contents[destination][targetSlot]
    if target then
        assert(target.itemID == source.itemID)
        target.stackCount = target.stackCount + quantity
    else
        item(destination, targetSlot, source.itemID, quantity)
    end
    source.stackCount, source.isLocked = source.stackCount - quantity, false
    if source.stackCount == 0 then contents[transfer.bag][transfer.slot] = nil end
    pending = nil
end

for _, profile in ipairs({ "retail", "forever", "legacy" }) do
    local first, last, carried = reset(profile)
    item(first, 1, 7101, 7)
    item(last, 2, 7102, 4)
    item(carried, 1, 7101, 2)
    item(first, 3, 7104, 9)
    APR.event.functions.bank("BANKFRAME_OPENED")
    assert(
        APRData.player.BankItems[7101] == 7 and APRData.player.BankItems[7102] == 4,
        profile .. ": snapshots must exclude carried reagents, keyring and account storage"
    )
    tick(0.2)
    assert(#requests == 1 and requests[1].bag == first and APRData.player.synthetic == 1)
    assert(APR:GetRouteItemActionCount("BankWithdraw", 7101) == 7)
    burst()
    assert(#requests == 1, "Successive events cannot duplicate a locked transfer")
    acknowledge(3)
    burst()
    assert(
        #requests == 2 and requests[2].bag == first and APRData.player.synthetic == 1,
        "A partial withdrawal must continue from the bank without redepositing its receipt"
    )
    assert(contents[carried][1].stackCount == 5 and APRData.player.BankItems[7101] == 4)
    acknowledge()
    burst()
    assert(
        #requests == 3 and requests[3].bag == last and APRData.player.synthetic == 1,
        "All purchased personal containers, including Forever's later bags, must be processed"
    )
    acknowledge()
    burst()
    assert(APRData.player.synthetic == 2 and #requests == 3)
    assert(contents[carried][1].stackCount == 9 and contents[carried][2].stackCount == 4)
    assert(
        APRData.player.BankItems[7101] == nil
            and APRData.player.BankItems[7102] == nil
            and APRData.player.BankItems[7104] == 9
    )
    burst()
    assert(
        #requests == 3 and APRData.player.synthetic == 2,
        "Late bank/bag events must not replay a completed withdrawal"
    )
    APR.event.functions.bank("BANKFRAME_CLOSED")
    accessible = false
    assert(APR:GetRouteItemActionCount("BankWithdraw", 7101) == nil)

    first, last, carried = reset(profile, "BankDeposit")
    item(carried, 1, 7101, 5)
    item(carried, 2, 7102, 2)
    APR.event.functions.bank("BANKFRAME_OPENED")
    tick(0.2)
    assert(#requests == 1 and requests[1].bag == carried, "Explicit deposits still process carried bags")
    acknowledge()
    burst()
    acknowledge()
    burst()
    assert(#requests == 2 and APRData.player.synthetic == 2 and not contents[carried][1])
    assert(APRData.player.BankItems[7101] == 5 and APRData.player.BankItems[7102] == 2)
end

-- A receipt can arrive after closing. Reopening must reconcile the same step,
-- without replaying the already acknowledged request or advancing while closed.
local closingSource = reset("forever")
item(closingSource, 1, 7101, 3)
APR.event.functions.bank("BANKFRAME_OPENED")
tick(0.2)
assert(#requests == 1)
APR.event:QueueBankRefresh()
local closingCallback = APR.event.bankRefreshTimer
APR.event.functions.bank("BANKFRAME_CLOSED")
accessible = false
acknowledge()
closingCallback.callback()
burst()
assert(#requests == 1 and APRData.player.synthetic == 1)
accessible = true
APR.event.functions.bank("BANKFRAME_OPENED")
tick(0.2)
assert(#requests == 1 and APRData.player.synthetic == 2 and APRData.player.BankItems[7101] == nil)

-- Modern access/data failures remain unknown, including an empty keyring.
local first, last = reset("forever")
sizes[-1] = 0
item(first, 1, 7101, 3)
APR.event.functions.bank("BANKFRAME_OPENED")
tick(0.2)
assert(#requests == 1 and requests[1].bag == first, "Keyring capacity does not gate modern banking")
acknowledge()
burst()
assert(APRData.player.synthetic == 2)

first, last = reset("forever")
item(first, 1, 7101, 3)
APR.routeBankOpen = true
APR:SaveBankItemCounts()
local saved = APRData.player.BankItems
unavailable = last
assert(not APR:ProcessRouteItems("BankWithdraw", steps[1].BankWithdraw, {}))
assert(APR:GetRouteItemActionCount("BankWithdraw", 7101) == nil)
APR:SaveBankItemCounts()
assert(#requests == 0 and APRData.player.BankItems == saved, "Incomplete bank data cannot replace a saved snapshot")
unavailable, tabData = nil, nil
assert(not APR:ProcessRouteItems("BankWithdraw", steps[1].BankWithdraw, {}))
APR:SaveBankItemCounts()
assert(#requests == 0 and APRData.player.BankItems == saved)
for _, invalid in ipairs({ {}, { { ID = 5 } }, { { ID = 15 } }, { {} } }) do
    tabData = invalid
    assert(not APR:ProcessRouteItems("BankWithdraw", steps[1].BankWithdraw, {}))
    APR:SaveBankItemCounts()
    assert(
        #requests == 0 and APRData.player.BankItems == saved,
        "Empty or malformed bank metadata must not enable transfers or erase saved contents"
    )
end
tabData, accessible = { { ID = first }, { ID = last } }, false
assert(not APR:ProcessRouteItems("BankWithdraw", steps[1].BankWithdraw, {}))
assert(APR:GetRouteItemActionCount("BankWithdraw", 7101) == nil)
APR:SaveBankItemCounts()
assert(#requests == 0 and APRData.player.BankItems == saved, "A remote account bank cannot enable character transfers")

-- Interaction overlap must not turn sales into deposits or transfers into sales.
accessible, APR.routeMerchantOpen = true, true
assert(not APR:ProcessRouteItems("BankWithdraw", steps[1].BankWithdraw, {}))
assert(not APR:ProcessRouteItems("BankDeposit", { items = { 7101 } }, {}))
assert(not APR:ProcessRouteItems("SellItems", { items = { 7101 } }, {}))
assert(#requests == 0)
APR.routeMerchantOpen = false
combat = true
assert(not APR:ProcessRouteItems("BankWithdraw", steps[1].BankWithdraw, {}))
combat, cursor = false, true
assert(not APR:ProcessRouteItems("BankWithdraw", steps[1].BankWithdraw, {}))
cursor = false
APR.event.functions.bank("BANK_TABS_CHANGED")
local stale = APR.event.bankRefreshTimer
APR.event.functions.bank("BANKFRAME_CLOSED")
stale.callback()
tick(0.2)
assert(
    #requests == 0 and APRData.player.synthetic == 1 and not APR.routeBankOpen,
    "Closing the bank cancels queued snapshots and prevents pending step refreshes from transferring"
)
print(
    "Bank transfers: Retail/Forever/legacy, reagent receipts, partial acknowledgements, events, deposits, unknown data and closure passed"
)
