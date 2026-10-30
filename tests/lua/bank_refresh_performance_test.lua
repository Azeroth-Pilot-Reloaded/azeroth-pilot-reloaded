local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
APR = { PlayerID = "player", settings = { profile = {enableAddon = true} } }
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return self.settings.profile end
function APR:ResetQuestTitleRequests() end
function APR:Debug() end
function APR:StepUsesAnyOption() return false end
function wipe(values) for key in pairs(values) do values[key] = nil end end
APR.npcInteraction = { Clear = noop }
local timers = {}
C_Timer = { NewTimer = function(delay, callback)
    local timer = { callback = callback, delay = delay, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local contents, reads = { [1] = {itemID = 7001, stackCount = 4} }, 0
APRData = {player = {}}
C_Container = {
    GetContainerNumSlots = function(bag) return bag == -1 and 2 or 0 end,
    GetContainerItemInfo = function(_, slot) reads = reads + 1; return contents[slot] end,
}
dofile("APR-Core/utils/LootUtils.lua")
dofile("APR-Core/core/Event.lua")
APR.event.functions.bank("BANKFRAME_OPENED")
assert(APRData.player.BankItems[7001] == 4 and reads == 2)
contents[1].stackCount, contents[2] = 2, {itemID = 7002, stackCount = 3}
for _ = 1, 1000 do
    APR.event.functions.bank("PLAYERBANKSLOTS_CHANGED")
    APR.event:QueueBankRefresh() -- The bag event shares the same snapshot request.
end
assert(reads == 2 and #timers == 1, "A bank burst cannot scan every slot for every notification")
APR.event.bankRefreshTimer.callback()
assert(reads == 4 and APRData.player.BankItems[7001] == 2 and APRData.player.BankItems[7002] == 3)
assert(not APR.event.bankRefreshTimer)
APR.event:QueueBankRefresh()
local stale = APR.event.bankRefreshTimer
contents[1] = nil
APR.event.functions.bank("BANKFRAME_CLOSED")
assert(stale.cancelled and not APR.routeBankOpen and not APRData.player.BankItems[7001])
local closedReads = reads
stale.callback()
assert(reads == closedReads, "A closed-bank callback cannot overwrite the final snapshot")
APR.event:QueueBankRefresh()
assert(not APR.event.bankRefreshTimer, "A closed bank stays dormant")
APR.event.functions.bank("BANKFRAME_OPENED")
APR.event:QueueBankRefresh()
local cancelled = APR.event.bankRefreshTimer
APR.event:CleanupEvents()
cancelled.callback()
assert(cancelled.cancelled and not APR.event.bankRefreshTimer)
APR.event:QueueBankRefresh()
local pending = APR.event.bankRefreshTimer
APR.settings.profile.enableAddon = false
local before = reads
pending.callback()
assert(reads == before, "A disabled addon cannot scan bank contents from a pending callback")
print("Bank snapshots: 1000 notifications share one scan, close flushes once, stale/disabled callbacks remain inactive")
