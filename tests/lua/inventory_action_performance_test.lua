local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
APR = { ResolveStepText = function(_, value) return value end }
local reads, slotsAvailable = 0, true
local bags = {}
NUM_BAG_SLOTS = 4
for bag = 0, 4 do
    bags[bag] = {}
    for slot = 1, 40 do
        bags[bag][slot] = { itemID = (slot - 1) % 20 + 1, stackCount = 3 }
    end
end
C_Container = {
    GetContainerNumSlots = function(bag)
        if not slotsAvailable and bag == 4 then return nil end
        return bags[bag] and 40 or 0
    end,
    GetContainerItemInfo = function(bag, slot)
        reads = reads + 1
        return bags[bag] and bags[bag][slot]
    end,
}
C_Item = { GetItemInfo = function(id) return "item " .. id end }
dofile("APR-Core/features/questing/RouteActions.lua")
local items, expected = {}, {}
for id = 1, 20 do items[id], expected[id] = id, "30 × item " .. id end
local rule = { items = items }
local text = APR:GetRouteActionText("BankDeposit", rule, true)
assert(text == "BANKDEPOSIT: " .. table.concat(expected, ", "))
assert(reads == 200, "20 item labels must share one 200-slot snapshot")

reads = 0
bags[0][1] = nil
expected[1] = "27 × item 1"
assert(APR:GetRouteActionText("DestroyItems", rule, true) == "DESTROYITEMS: " .. table.concat(expected, ", "))
assert(reads == 200, "The next render must take a fresh snapshot after inventory changes")
assert(APR:GetRouteItemActionCount("BankDeposit", 1) == 27)
assert(APR:GetRouteItemActionCount("DestroyItems", 999) == 0)

reads = 0
local preview = APR:GetRouteActionText("BankDeposit", { items = { 1, 999 } })
assert(preview == "BANKDEPOSIT: item 1, item 999" and reads == 0,
    "Future previews must not inspect today's bags")
local closed = APR:GetRouteActionText("BankWithdraw", { items = { 1, 999 } }, true)
assert(closed == "BANKWITHDRAW: item 1, item 999" and reads == 0,
    "A closed bank has unknown quantities, not zero counts")

bags[-1], bags[5], bags[11] = { [1] = { itemID = 1, stackCount = 7 } },
    { [1] = { itemID = 1, stackCount = 2 } }, { [40] = { itemID = 2, stackCount = 4 } }
APR.routeBankOpen = true
reads = 0
assert(APR:GetRouteActionText("BankWithdraw", { items = { 1, 2, 999 } }, true)
    == "BANKWITHDRAW: 9 × item 1, 4 × item 2, 0 × item 999")
assert(reads == 120, "Withdrawals scan only bank containers once")

slotsAvailable, reads = false, 0
assert(APR:GetRouteActionText("BankDeposit", { items = { 1, 2 } }, true)
    == "BANKDEPOSIT: item 1, item 2",
    "A partially unavailable container invalidates all counts instead of showing partial totals")
assert(reads == 160)
slotsAvailable, reads = true, 0
assert(APR:GetRouteActionText("BankDeposit", { items = {} }, true) == "BANKDEPOSIT" and reads == 0,
    "Empty target lists do not scan inventory")
print("Inventory action labels: 20 items share one 200-slot scan; fresh inventory, unknown banks, partial data and previews passed")
