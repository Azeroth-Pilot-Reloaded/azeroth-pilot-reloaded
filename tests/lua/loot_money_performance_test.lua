function LibStub() return { GetLocale = function() return {} end } end
APR = {}
NUM_BAG_SLOTS = 4
local reads, prices, bags, equipped = 0, {}, {}, {}
local function itemInfo(item)
    reads = reads + 1
    return nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, prices[item]
end
local function slots(bag) return bags[bag] and 40 or 0 end
local function info(bag, slot)
    local item = bags[bag] and bags[bag][slot]
    if not item then return end
    if C_Container then return item end
    return nil, item.stackCount, false, item.quality, nil, nil, item.hyperlink, nil, item.hasNoValue, item.itemID
end
function GetMoney() return 7 end
function GetInventoryItemLink(_, slot) return equipped[slot] end
function GetInventoryItemCount() return 1 end
GetItemInfo, GetContainerNumSlots, GetContainerItemInfo = itemInfo, slots, info
dofile("APR-Core/utils/LootUtils.lua")
for _, modern in ipairs({ true, false }) do
    C_Item = modern and { GetItemInfo = itemInfo } or nil
    C_Container = modern and { GetContainerNumSlots = slots, GetContainerItemInfo = info } or nil
    bags, prices, equipped, reads = {}, { ["item:one"] = 5, ["item:variant"] = 13 }, { [16] = "item:one" }, 0
    for bag = 0, 4 do
        bags[bag] = {}
        for slot = 1, 40 do
            bags[bag][slot] = { itemID = 1, hyperlink = "item:one", quality = 0, stackCount = 2 }
        end
    end
    local cash, resale, required = APR:GetLootMoneyProgress({ copper = 100, equippedSlots = { 16, 16 } })
    assert(cash == 7 and resale == 2005 and required == 100)
    assert(reads == 1, "200 identical stacks plus equipped copies need one price query per estimate")

    bags[4][40].hyperlink = "item:variant"
    reads = 0
    _, resale = APR:GetLootMoneyProgress({ copper = 100, includeEquipped = true })
    assert(resale == 2021 and reads == 2, "Different links for the same item ID retain distinct prices")
    prices["item:variant"], reads = nil, 0
    _, resale = APR:GetLootMoneyProgress({ copper = 100, equippedSlots = { 16 } })
    assert(resale == 1995 and reads == 2, "An uncached variant contributes zero")
    prices["item:variant"], reads = 13, 0
    _, resale = APR:GetLootMoneyProgress({ copper = 100, equippedSlots = { 16 } })
    assert(resale == 2021 and reads == 2, "Loaded prices are visible on the next estimate")

    bags[0][1].quality, bags[0][2].hasNoValue, reads = 1, true, 0
    _, resale = APR:GetLootMoneyProgress({ copper = 100, junkOnly = true })
    assert(resale == 1996 and reads == 2, "Junk and no-value filtering still precede valuation")
    prices["item:one"], prices["item:variant"], reads = nil, nil, 0
    _, resale = APR:GetLootMoneyProgress({ copper = 100, junkOnly = true })
    assert(resale == 0 and reads == 2, "Missing prices are also queried once per distinct variant")
    bags[0][3].hyperlink, reads = nil, 0
    prices[1] = 9
    _, resale = APR:GetLootMoneyProgress({ copper = 100, junkOnly = true })
    assert(resale == 18 and reads == 3, "Items without a link keep their numeric-ID fallback")
end
print("Loot money: 200 stacks share one price query; distinct variants, late/missing prices and modern/legacy filtering passed")
