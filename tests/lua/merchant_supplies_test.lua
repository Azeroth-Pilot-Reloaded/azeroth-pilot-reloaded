-- Supply opt-in changes automatic requests, while real instructions and manual
-- receipts retain the same completion contract on both merchant API variants.
local function noop() end
local locale = { BUY_ITEM = "Buy %s %s" }
function LibStub()
    return { GetLocale = function() return locale end }
end
format, UNKNOWN = string.format, "Unknown"
function IsModifierKeyDown() return false end
local bags, goods, calls, advances, epoch, rows, step, selected = {}, {}, {}, 0, 0, {}, nil, true
APRData = { player = { route = 1 } }
APR = {
    PlayerID = "player",
    ActiveRoute = "route",
    settings = { profile = {} },
    Debug = noop,
    NewModule = function() return {} end,
    CaptureStepContext = function() return epoch end,
    IsStepContextCurrent = function(_, context) return context == epoch end,
    GetCollectionItemCount = function(_, id) return bags[id] or 0 end,
    GetTargetID = function() return 100 end,
    AreConditionalFiltersMet = function() return selected end,
    UpdateNextStep = function() advances = advances + 1 end,
    NextQuestStep = function() advances = advances + 1 end,
    Buff = { RemoveAllBuffIcon = noop },
    currentStep = { AddQuestSteps = function(_, _, text) rows[#rows + 1] = text end },
}
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
C_Item = { GetItemInfo = function(id) return "Item " .. id end }
function GetMoney() return 1000 end
function GetMerchantNumItems() return #goods end
function GetMerchantItemID(index) return goods[index].itemID end
function BuyMerchantItem(index, quantity) calls[#calls + 1] = { goods[index].itemID, quantity } end
dofile("APR-Core/features/questing/NPCInteraction.lua")
dofile("APR-Core/features/questing/StepInstructions.lua")
local function render()
    rows = {}
    APR.stepHandlers.RenderRequirements(step, true, 1)
    return table.concat(rows, ";")
end
local function receipt(id, quantity)
    bags[id] = (bags[id] or 0) + quantity
    APR:UpdatePurchaseTracking(id, quantity)
end
local function start(items, inventory, merchant, enabled)
    epoch = epoch + 1
    step = { BuyMerchant = items, MerchantNPC = 100 }
    bags, goods, calls, advances = inventory or {}, merchant or { { itemID = 1 } }, {}, 0
    APR.settings.profile.autoBuySupplies = enabled
    APR.npcInteraction:HandleMerchantPurchase(step)
end

for _, modern in ipairs({ false, true }) do
    C_MerchantFrame, GetMerchantItemInfo = nil, nil
    if modern then
        C_MerchantFrame = {
            GetItemInfo = function()
                return { price = 100, stackCount = 5, numAvailable = -1, hasExtendedCost = false }
            end,
        }
    else
        function GetMerchantItemInfo() return "Item", nil, 100, 5, -1, true, true, false end
    end
    dofile("APR-Core/utils/BuyMerchantUtils.lua")

    start({ { itemID = 1, quantity = 5, targetStock = true, optional = true, isSupply = true } }, { [1] = 1 })
    assert(#calls == 0 and advances == 0, "Unset option must leave supplies to the player")
    assert(render() == "Buy 4 Item 1" and advances == 0, "Disabled automation must retain the instruction")
    receipt(1, 2)
    assert(advances == 0 and render() == "Buy 2 Item 1", "Partial manual purchases update the deficit")
    APR.npcInteraction:HandleMerchantPurchase(step)
    assert(#calls == 0 and advances == 0, "Reopening retains manual progress without buying")
    receipt(1, 2)
    assert(advances == 1, "A complete manual purchase advances the route")
    receipt(1, 2)
    assert(advances == 1, "Repeated receipts cannot advance twice")

    start({ { itemID = 1, quantity = 5, optional = true, isSupply = true } }, {}, {}, false)
    assert(
        #calls == 0 and advances == 0 and render() == "Buy 5 Item 1",
        "Missing optional stock must not silently discard manual advice"
    )

    start({ { itemID = 1, quantity = 5, targetStock = true, isSupply = true } }, { [1] = 5 }, nil, false)
    assert(#calls == 0 and advances == 1, "Already carried stock completes without buying")

    start({ { itemID = 1, quantity = 5, targetStock = true, isSupply = true } }, { [1] = 2 }, nil, true)
    assert(#calls == 1 and calls[1][2] == 3 and advances == 0, "Opt-in buys only the carried deficit")
    receipt(1, 1)
    assert(advances == 0, "Partial automatic delivery cannot complete the step")
    APR.settings.profile.autoBuySupplies = false
    APR.npcInteraction:HandleMerchantPurchase(step)
    assert(#calls == 1 and advances == 0, "Disabling stops subsequent requests without losing progress")
    receipt(1, 2)
    assert(advances == 1, "Disabling must still accept outstanding receipts")

    start({ { itemID = 1, quantity = 5, isSupply = true } }, { [1] = 10 }, nil, false)
    receipt(1, 2)
    APR.settings.profile.autoBuySupplies = true
    APR.npcInteraction:HandleMerchantPurchase(step)
    assert(#calls == 1 and calls[1][2] == 3, "Opting in retains partial additional-purchase progress")
    bags[1] = 15 -- Native inventory can arrive before the remaining loot receipt.
    APR.npcInteraction:HandleMerchantPurchase(step)
    assert(#calls == 1 and advances == 0, "Inventory delta prevents duplicate requests, but waits for receipts")
    APR:UpdatePurchaseTracking(1, 3)
    assert(advances == 1)

    start({
        { itemID = 1, quantity = 4, isSupply = true },
        { itemID = 2, quantity = 2, questID = 10 },
        { itemID = 3, quantity = 1, isSupply = false },
    }, {}, { { itemID = 1 }, { itemID = 2 }, { itemID = 3 } }, false)
    assert(
        #calls == 2 and calls[1][1] == 2 and calls[2][1] == 3,
        "Mixed visits still buy quest requirements and unmarked items"
    )
    receipt(2, 2)
    receipt(3, 1)
    assert(advances == 0, "Mixed visits retain their manual supply instruction")
    receipt(1, 4)
    assert(advances == 1, "Manual supplies can finish a mixed visit")

    selected = false
    start({ { itemID = 1, quantity = 1, isSupply = true, conditions = { Class = "HUNTER" } } }, {}, nil, true)
    assert(#calls == 0 and advances == 1, "Opt-in never overrides per-item eligibility")
    selected = true
    epoch = epoch + 1
    receipt(1, 1)
    assert(advances == 1, "Stale receipts cannot advance a later step")
end
print("Merchant supplies: manual guidance/progress, opt-in, stock, mixed visits and both APIs passed")
