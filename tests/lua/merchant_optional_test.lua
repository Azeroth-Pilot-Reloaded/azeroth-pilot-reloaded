-- Exercise merchant policy against missing stock, limited cash and item conditions.
local bags, goods, calls, advances, epoch, cash, selected = {}, {}, {}, 0, 1, 1000, true
APR = { settings = { profile = { debug = false } }, Debug = function() end,
    CaptureStepContext = function() return epoch end,
    IsStepContextCurrent = function(_, context) return context == epoch end,
    GetCollectionItemCount = function(_, id) return bags[id] or 0 end,
    AreConditionalFiltersMet = function() return selected end,
    UpdateNextStep = function() advances = advances + 1 end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
function GetMoney() return cash end
function GetMerchantNumItems() return #goods end
function GetMerchantItemID(i) return goods[i].itemID end
function GetMerchantItemInfo(i)
    local g = goods[i]
    return 'Item', nil, g.price or 100, g.bundle or 5, g.available or -1, true, true, g.extended or false
end
function BuyMerchantItem(i, quantity)
    calls[#calls + 1] = { id = goods[i].itemID, quantity = quantity }
    bags[goods[i].itemID] = (bags[goods[i].itemID] or 0) + quantity
end
dofile('APR-Core/utils/BuyMerchantUtils.lua')
local function run(items, inventory, merchant, money)
    epoch = epoch + 1; bags = inventory or {}; goods = merchant or {}; cash = money or 1000
    calls = {}; advances = 0
    APR:StartPurchaseTracking(items); APR:BuyItemFromMerchant(items)
end
run({ { itemID = 1, quantity = 5, optional = true } })
assert(#calls == 0 and advances == 1, 'An absent optional item must not block the visit')
run({ { itemID = 1, quantity = 5 } })
assert(#calls == 0 and advances == 0, 'A mandatory absent item must still be required')
run({ { itemID = 1, quantity = 10, targetStock = true, optional = true, reserveCopper = 200 } },
    { [1] = 2 }, { { itemID = 1, price = 100, bundle = 5 } }, 300)
assert(#calls == 1 and calls[1].quantity == 5, 'Respect reserve money and the carried deficit')
assert(advances == 0, 'A partial affordable request must wait for its receipt')
APR:UpdatePurchaseTracking(1, 5)
assert(advances == 1, 'Affordable optional quantity completes after delivery')
run({ { itemID = 1, quantity = 5, optional = true } }, {}, { { itemID = 1, available = 2 } })
assert(calls[1].quantity == 2, 'Limited stock caps an optional purchase')
APR:UpdatePurchaseTracking(1, 2); assert(advances == 1)
run({ { itemID = 1, quantity = 5, optional = true } }, {}, { { itemID = 1, extended = true } })
assert(#calls == 0 and advances == 1, 'Optional purchases must not spend another currency')
selected = false
run({ { itemID = 1, quantity = 5, conditions = { Class = 'HUNTER' } },
      { itemID = 2, quantity = 3 } }, {}, { { itemID = 1 }, { itemID = 2 } })
assert(#calls == 1 and calls[1].id == 2, 'An ineligible ammo entry is neither bought nor required')
APR:UpdatePurchaseTracking(2, 3); assert(advances == 1)
selected = true
run({ { itemID = 1, quantityFromItemID = 2, targetStock = true } },
    { [1] = 2, [2] = 7 }, { { itemID = 1 } })
assert(calls[1].quantity == 5, 'Buy only the spices missing for the carried ingredients')
run({ { itemID = 1, quantityFromItemID = 2, targetStock = true } }, {}, { { itemID = 1 } })
assert(#calls == 0 and advances == 1, 'No ingredients means no spice purchase')
C_MerchantFrame = { GetItemInfo = function()
    return { price = 100, stackCount = 5, numAvailable = -1, hasExtendedCost = false }
end }
run({ { itemID = 1, quantity = 10, optional = true } }, {}, { { itemID = 1 } }, 100)
assert(calls[1].quantity == 5, 'Structured merchant API uses the actual bundle size')
local capacities, looseBags = { [0] = 16, 6, 8, 0, 0 }, { [0] = { 4496 } }
C_Container = {
    GetContainerNumSlots = function(bag) return capacities[bag] end,
    GetContainerItemID = function(bag, slot) return looseBags[bag] and looseBags[bag][slot] end,
}
run({ { itemID = 4496, quantity = 4, bagSlots = 6, targetStock = true, optional = true } },
    {}, { { itemID = 4496 } })
assert(calls[1].quantity == 1, 'Only two empty bag slots remain, and one spare bag is already carried')
capacities = { [0] = 16, 8, 8, 10, 10 }
run({ { itemID = 4496, quantity = 4, bagSlots = 6, targetStock = true, optional = true } },
    {}, { { itemID = 4496 } })
assert(#calls == 0 and advances == 1, 'Do not buy smaller bags when all four slots already have better bags')
print('Optional merchant purchases: absence, stock, reserve money, receipts, currency, conditions and ingredients passed')
