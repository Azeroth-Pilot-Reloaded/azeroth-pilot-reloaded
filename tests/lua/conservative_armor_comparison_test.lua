-- Partial-order armor comparisons, independent of any maintained guide/weights.
local context = { client = "forever", classID = 2, key = "invented:auto" }
local inventory, items, pendingID, usable, secret = {}, {}, nil, true, {}
APR = { GAME_VERSIONS = { Forever = "forever" } }
function APR:GetGameVersion() return "forever" end
function APR:GetRewardBuildContext() return context end
function UnitLevel() return 3 end
function GetBuildInfo() return nil, nil, nil, 16001 end
function issecretvalue(value) return value == secret end
function GetInventoryItemLink(_, slot) return inventory[slot] end
function GetInventoryItemID(_, slot) return pendingID or (items[inventory[slot]] and items[inventory[slot]].id) end
C_PlayerInfo = { CanUseItem = function() return usable end }
C_Item = {
    GetItemInfo = function(link)
        local item = items[link]
        return "Fixture", link, 1, 1, 0, "", "", 1, item.loc or "INVTYPE_HEAD", 0, 1, item.class or 4, 3
    end,
    GetItemStats = function(link) return items[link].stats end,
    IsEquippableItem = function() return true end,
    GetItemUniqueness = function(link) return items[link].category, items[link].maximum end,
}
local old, new = "item:9601:old", "item:9602:new"
items[old] = { id = 9601 }
items[new] = { id = 9602 }
inventory[1] = old
local function stats(armor, stamina, strength, spellPower, resistance)
    return { RESISTANCE0_NAME = armor, ITEM_MOD_STAMINA_SHORT = stamina,
        ITEM_MOD_STRENGTH_SHORT = strength, ITEM_MOD_SPELL_POWER_SHORT = spellPower, UNKNOWN_RESISTANCE = resistance }
end
dofile("APR-Core/features/questing/RewardScoring.lua")
local scorer = APR.RewardScoring
local scale = assert(scorer:GetEmptyArmorScale())
assert(scale.armorDominanceOnly and not scorer:GetDefaultScale(), "The bag fallback cannot become a full reward profile")
items[old].stats, items[new].stats = stats(6, 2, 2, 1, 5), stats(7, 2, 2, 1, 5)
local gain, ready, plan, comparison = scorer:GetUpgrade(new, scale)
assert(ready and gain > 0 and plan.slot == 1 and plan.replacedSlots[1] == 1)
local function rejected(candidate)
    items[new].stats = candidate
    local value, known = scorer:GetUpgrade(new, scale)
    assert(known and (value == nil or value <= 0), "A loss, tradeoff or speculative benefit cannot prove dominance")
end
rejected(stats(20, 1, 2, 1, 5)) -- More armor cannot buy lost stamina.
rejected(stats(20, 2, 1, 1, 5)) -- Nor lost strength.
rejected(stats(20, 2, 2, 0, 5)) -- Nor lost spell power, even though unweighted.
rejected(stats(20, 2, 2, 1, 4)) -- Every unknown raw stat is retained too.
rejected(stats(6, 2, 2, 100, 5)) -- SP alone is not an armor/survival proof.
rejected(stats(6, 2, 2, 1, 5)) -- Equality is not improvement.
rejected(stats(20, 2, -1, 1, 5))
items[new].stats = stats(7, 2, 3, 1, 5)
local stronger, known, _, changed = scorer:GetUpgrade(new, scale)
assert(known and stronger == gain and changed ~= comparison,
    "A changed non-ranking stat still renews the comparison/refusal context")
items[new].stats = { ITEM_MOD_ARMOR_SHORT = 7, ITEM_MOD_STAMINA_SHORT = 2,
    ITEM_MOD_STRENGTH_SHORT = 2, ITEM_MOD_SPELL_POWER_SHORT = 1, UNKNOWN_RESISTANCE = 5 }
assert(scorer:GetUpgrade(new, scale) > 0, "Armor aliases denote the same quantity")
local complete = items[new].stats
for _, invalid in ipairs({ secret, { ITEM_MOD_ARMOR_SHORT = secret }, { ITEM_MOD_ARMOR_SHORT = "pending" }, { [secret] = 7 } }) do
    items[new].stats = invalid
    local value, available = scorer:GetUpgrade(new, scale)
    assert(value == nil and not available, "Opaque/incomplete stats stay pending")
end
items[new].stats = nil
assert(select(2, scorer:GetUpgrade(new, scale)) == false)
items[new].stats = complete
inventory[1], pendingID = nil, 9601
assert(select(2, scorer:GetUpgrade(new, scale)) == false, "A native ID without its link is not empty")
pendingID = nil
assert(scorer:GetUpgrade(new, scale) > 0, "Confirmed empty armor retains the safe starter path")
inventory[1] = old
usable = false
assert(scorer:GetUpgrade(new, scale) == nil, "The existing native usability contract still applies")
usable = true
for _, location in ipairs({ "INVTYPE_NECK", "INVTYPE_TRINKET", "INVTYPE_BODY", "INVTYPE_TABARD", "INVTYPE_WEAPON" }) do
    items[new].loc = location
    assert(scorer:GetUpgrade(new, scale) == nil, "Only single-slot armor uses dominance")
end
items[new].loc = nil
items[new].category, items[new].maximum = 77, 1
local other = "item:9603:other"
items[other] = { id = 9603, loc = "INVTYPE_CHEST", category = 77, maximum = 1, stats = stats(1, 0, 0, 0, 0) }
inventory[5] = other
assert(scorer:GetUpgrade(new, scale) == nil, "Dominance retains common unique-equipped checks")
print("Conservative armor: occupied/empty dominance, all-stat losses, aliases, pending/secret data, scoped identities and native constraints")
