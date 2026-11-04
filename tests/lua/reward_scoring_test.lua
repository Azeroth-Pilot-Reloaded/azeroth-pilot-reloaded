-- Synthetic items exercise equipment contracts independently of maintained guide data.
local items, byID, inventory = {}, {}, {}
local classID, primaryStat, role, client, dual, titan = 1, nil, nil, "retail", false, false
local level, seenStats = 20, {}
APR = { GAME_VERSIONS = { Retail = "retail", Forever = "forever" } }
function APR:GetGameVersion() return client end
UnitClass = function() return "Fixture class", "FIXTURE", classID end
UnitLevel = function() return level end
C_SpecializationInfo = {
    GetSpecialization = function() return primaryStat and 1 end,
    GetSpecializationInfo = function() return 900, "Fixture spec", nil, nil, role, primaryStat end,
}
CanDualWield = function() return dual end
C_SpellBook = { IsSpellKnown = function(id) assert(id == 46917); return titan end }
GetInventoryItemLink = function(_, slot) return inventory[slot] end
GetInventoryItemID = function(_, slot)
    local item = items[inventory[slot]]
    return item and item.id
end
C_PlayerInfo = { CanUseItem = function(id) return byID[id] and byID[id].usable ~= false end }
C_Item = {
    GetItemInfo = function(link)
        local item = items[link]
        if not item or item.missingInfo then return nil end
        return "Synthetic item", link, 2, 20, item.requiredLevel or 0, "", "", 1,
            item.loc, 0, 1, item.classID or 4, item.subclassID or 0
    end,
    GetItemStats = function(link)
        seenStats[#seenStats + 1] = link
        local item = items[link]
        return item and not item.missingStats and item.stats or nil
    end,
    IsEquippableItem = function(link) return items[link] and items[link].equippable ~= false end,
    GetItemUniqueness = function(link)
        local item = items[link]
        return item and item.category, item and item.maximum
    end,
}
GetItemInfo = function() error("Modern item API must take priority") end
GetItemStats = GetItemInfo

local nextID = 1000
local function item(loc, value, options)
    options = options or {}
    nextID = nextID + 1
    options.id = options.id or nextID
    local link = "item:" .. options.id .. ":" .. (options.variant or "0")
    options.loc, options.value = loc, value
    options.stats = options.stats or { ITEM_MOD_STRENGTH_SHORT = value }
    items[link], byID[options.id] = options, options
    return link
end
local external = { score = function(link)
    local data = items[link]
    if not data or data.missingScore then return nil, false end
    if data.excluded then return nil, true end
    return data.value, true
end }
local function expect(link, expected, ready, scale)
    local gain, actualReady = APR.RewardScoring:GetUpgrade(link, scale or external)
    assert(gain == expected and actualReady == ready,
        "Expected " .. tostring(expected) .. "," .. tostring(ready) .. "; got " .. tostring(gain) .. "," .. tostring(actualReady))
end
local function reset()
    inventory = {}
    dual, titan, client, classID, primaryStat, role, level = false, false, "retail", 1, nil, nil, 20
end
dofile("APR-Core/features/questing/RewardScoring.lua")
local scoring = APR.RewardScoring

-- An empty slot is a real upgrade. Ordinary downgrades retain their signed delta.
local head = item("INVTYPE_HEAD", 30)
expect(head, 30, true)
inventory[1] = item("INVTYPE_HEAD", 40)
expect(head, -10, true)
expect(item("INVTYPE_HEAD", 999, { usable = false }), nil, true)
expect(item("INVTYPE_HEAD", 999, { requiredLevel = 21 }), nil, true)
expect(item("INVTYPE_HEAD", 999, { equippable = false }), nil, true)
expect(item("INVTYPE_HEAD", 999, { missingInfo = true }), nil, false)
expect(item("INVTYPE_HEAD", 999, { missingScore = true }), nil, false)
expect(item("INVTYPE_HEAD", 999, { excluded = true }), nil, true)
expect(item("INVTYPE_BAG", 999, { missingScore = true, missingStats = true }), nil, true)
local missingInventory = item("INVTYPE_HEAD", 5, { missingInfo = true })
inventory[1] = missingInventory
expect(head, nil, false)
inventory[1] = item("INVTYPE_HEAD", 50, { excluded = true })
expect(head, 30, true)

-- Paired slots choose the weaker current item, unless uniqueness constrains replacement.
reset()
inventory[11], inventory[12] = item("INVTYPE_FINGER", 10), item("INVTYPE_FINGER", 25, { category = 7, maximum = 1 })
expect(item("INVTYPE_FINGER", 30), 20, true)
expect(item("INVTYPE_FINGER", 30, { category = 7, maximum = 1 }), 5, true)
inventory[1] = item("INVTYPE_HEAD", 10, { category = 7, maximum = 1 })
expect(item("INVTYPE_FINGER", 30, { category = 7, maximum = 1 }), nil, true)
inventory[1] = nil
inventory[13], inventory[14] = item("INVTYPE_TRINKET", 4, { category = 8, maximum = 2 }), item("INVTYPE_TRINKET", 7, { category = 8, maximum = 2 })
expect(item("INVTYPE_TRINKET", 10, { category = 8, maximum = 2 }), 6, true)
inventory[11] = item("INVTYPE_FINGER", 25, { id = 8000, variant = "1", category = -1, maximum = 1 })
inventory[12] = item("INVTYPE_FINGER", 2)
expect(item("INVTYPE_FINGER", 33, { id = 8000, variant = "2", category = -1, maximum = 1 }), 8, true)
inventory[11] = item("INVTYPE_FINGER", 25, { id = 8100, variant = "1", category = 0, maximum = 0 })
expect(item("INVTYPE_FINGER", 33, { id = 8100, variant = "2", category = 0, maximum = 0 }), 31, true)

-- Two-handed weapons replace both hands; one-handed/offhand alternatives remain separate.
reset()
dual = true
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 100), item("INVTYPE_WEAPONOFFHAND", 90)
expect(item("INVTYPE_2HWEAPON", 150), -40, true)
expect(item("INVTYPE_WEAPON", 110), 20, true)
expect(item("INVTYPE_WEAPONMAINHAND", 110), 20, true)
expect(item("INVTYPE_SHIELD", 110), 20, true)
dual = false
expect(item("INVTYPE_WEAPON", 110), -80, true)
expect(item("INVTYPE_WEAPONOFFHAND", 110), nil, true)
inventory[16], inventory[17] = item("INVTYPE_2HWEAPON", 100), nil
expect(item("INVTYPE_WEAPONMAINHAND", 70), -30, true)
expect(item("INVTYPE_SHIELD", 150), nil, true)
expect(item("INVTYPE_HOLDABLE", 150), nil, true)

-- A retained weapon may move to the other hand when that is a legal better pair.
for _, profile in ipairs({ "retail", "forever" }) do
    reset()
    client, dual = profile, true
    inventory[16], inventory[17] = item("INVTYPE_WEAPON", 100), item("INVTYPE_WEAPONOFFHAND", 50)
    expect(item("INVTYPE_WEAPONMAINHAND", 90), 40, true)
    inventory[16], inventory[17] = item("INVTYPE_WEAPON", 50), item("INVTYPE_WEAPON", 100)
    expect(item("INVTYPE_WEAPONOFFHAND", 70), 20, true)
end

-- A move cannot retain a main-only/offhand-only weapon in an incompatible hand.
reset()
dual = true
inventory[16], inventory[17] = item("INVTYPE_WEAPONMAINHAND", 100), item("INVTYPE_WEAPONOFFHAND", 50)
expect(item("INVTYPE_WEAPONMAINHAND", 90), -10, true)
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 50), item("INVTYPE_WEAPONOFFHAND", 100)
expect(item("INVTYPE_WEAPONOFFHAND", 70), -30, true)
dual = false
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 100), item("INVTYPE_HOLDABLE", 50)
expect(item("INVTYPE_WEAPONMAINHAND", 90), -10, true)

-- Uniqueness still sees the retained item after it changes hands.
dual = true
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 100, { category = 51, maximum = 1 }), item("INVTYPE_WEAPONOFFHAND", 50)
expect(item("INVTYPE_WEAPONMAINHAND", 90, { category = 51, maximum = 1 }), -10, true)
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 50), item("INVTYPE_WEAPON", 100, { category = 52, maximum = 1 })
expect(item("INVTYPE_WEAPONOFFHAND", 70, { category = 52, maximum = 1 }), -30, true)
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 100), item("INVTYPE_WEAPONOFFHAND", 50, { category = 53, maximum = 1 })
expect(item("INVTYPE_WEAPONMAINHAND", 90, { category = 53, maximum = 1 }), 40, true)

-- The discarded hand's missing score cannot be mistaken for an empty baseline.
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 100), item("INVTYPE_WEAPONOFFHAND", 50, { missingScore = true })
expect(item("INVTYPE_WEAPONMAINHAND", 90), nil, false)
items[inventory[17]].missingScore = false
expect(item("INVTYPE_WEAPONMAINHAND", 90), 40, true)

-- Learned Titan's Grip supports both hands, but it never turns a staff into a one-hander.
dual, titan = true, true
inventory[16], inventory[17] = item("INVTYPE_2HWEAPON", 100, { subclassID = 1 }), item("INVTYPE_2HWEAPON", 90, { subclassID = 1 })
expect(item("INVTYPE_2HWEAPON", 110, { subclassID = 1 }), 20, true)
expect(item("INVTYPE_2HWEAPON", 110, { subclassID = 10 }), -80, true)
expect(item("INVTYPE_SHIELD", 200), nil, true)
expect(item("INVTYPE_HOLDABLE", 200), nil, true)
expect(item("INVTYPE_WEAPONMAINHAND", 110), 20, true)
inventory[16], inventory[17] = item("INVTYPE_WEAPON", 1000, { category = 9, maximum = 1 }), item("INVTYPE_SHIELD", 10)
expect(item("INVTYPE_2HWEAPON", 150, { subclassID = 1, category = 9, maximum = 1 }), -860, true)
inventory[16], inventory[17] = item("INVTYPE_2HWEAPON", 100, { subclassID = 1 }), item("INVTYPE_2HWEAPON", 90, { subclassID = 1 })
C_SpellBook.IsSpellKnown = function() return false end
IsPlayerSpell = function() error("A present modern result is authoritative") end
expect(item("INVTYPE_2HWEAPON", 150), -40, true)
C_SpellBook.IsSpellKnown = nil
IsPlayerSpell = function(id) assert(id == 46917); return true end
expect(item("INVTYPE_2HWEAPON", 110, { subclassID = 1 }), 20, true)
IsPlayerSpell = nil
C_SpellBook.IsSpellKnown = function() return titan end

-- The ranged slot exists on Forever. Retail bows replace both hands; wands preserve the offhand.
reset()
inventory[16], inventory[17], inventory[18] = item("INVTYPE_WEAPON", 20), item("INVTYPE_HOLDABLE", 15), item("INVTYPE_RANGED", 10)
local bow = item("INVTYPE_RANGED", 30, { subclassID = 2 })
expect(bow, -5, true)
expect(item("INVTYPE_RANGEDRIGHT", 30, { subclassID = 19 }), 10, true)
client = "forever"
expect(bow, 20, true)
expect(item("INVTYPE_RELIC", 15), 5, true)

-- Exact variant links survive every stats lookup; missing data is never a zero baseline.
reset()
local oldVariant = item("INVTYPE_HEAD", 2, { id = 9000, variant = "111" })
local newVariant = item("INVTYPE_HEAD", 7, { id = 9000, variant = "222" })
inventory[1], seenStats = oldVariant, {}
local scale = scoring:GetDefaultScale()
local gain, ready = scoring:GetUpgrade(newVariant, scale)
assert(ready and gain > 0 and seenStats[1] == newVariant and seenStats[2] == oldVariant)
items[oldVariant].missingStats = true
local gain, ready = scoring:GetUpgrade(newVariant, scale)
assert(gain == nil and ready == false)
items[oldVariant].missingStats = false
items[newVariant].missingStats = true
local gain, ready = scoring:GetUpgrade(newVariant, scale)
assert(gain == nil and ready == false)
items[newVariant].missingStats = false

-- Native primary/role data adapts the default without freezing editorial weight constants.
for id = 1, 13 do
    classID = id
    local profile = scoring:GetDefaultScale()
    assert(profile and profile.classID == id and profile.weights[profile.primaryStat] > 0)
end
classID, primaryStat, role = 12, 4, "DAMAGER"
scale = scoring:GetDefaultScale()
assert(scale.primaryStat == "Intellect" and scale.weights.Intellect > 0 and scale.weights.WeaponDPS == 0)
assert(scoring:GetProfileDescription() == "Fixture class - Fixture spec")
local intellect = item("INVTYPE_HEAD", 0, { stats = { ITEM_MOD_INTELLECT_SHORT = 8 } })
local hybrid = item("INVTYPE_HEAD", 0, { stats = { ITEM_MOD_INTELLECT_SHORT = 8, ITEM_MOD_AGILITY_OR_INTELLECT_SHORT = 8 } })
assert(scale.score(intellect) == scale.score(hybrid), "Native and hybrid representations must count once")
local versatility = item("INVTYPE_HEAD", 0, { stats = { ITEM_MOD_VERSATILITY = 8 } })
local aliases = item("INVTYPE_HEAD", 0, { stats = { ITEM_MOD_VERSATILITY = 8, ITEM_MOD_VERSATILITY_RATING_SHORT = 8 } })
assert(scale.score(versatility) == scale.score(aliases), "Stat aliases must not double their score")
role = "TANK"
local tankScale = scoring:GetDefaultScale()
assert(tankScale.weights.Stamina > scale.weights.Stamina and tankScale.weights.Armor > scale.weights.Armor)
classID, primaryStat, role, client = 7, nil, nil, "forever"
scale = scoring:GetDefaultScale()
assert(scale.weights.Strength > 0 and scale.weights.Intellect > 0 and scale.weights.Spirit > 0)
classID = 99
assert(scoring:GetDefaultScale() == nil)

-- Native eligibility data and provider errors are authoritative and safely recoverable.
reset()
local originalCanUse = C_PlayerInfo.CanUseItem
C_PlayerInfo.CanUseItem = function() return nil end
expect(head, nil, false)
C_PlayerInfo.CanUseItem = function() error("Unready native data") end
expect(head, nil, false)
C_PlayerInfo.CanUseItem = originalCanUse
expect(head, 30, true)
C_PlayerInfo.CanUseItem = nil
C_Item.IsUsableItem = function(link) assert(link == head); return true end
expect(head, 30, true)
C_Item.IsUsableItem = function() return false end
expect(head, nil, true)
C_Item.IsUsableItem = function() return nil end
expect(head, nil, false)
C_PlayerInfo.CanUseItem, C_Item.IsUsableItem = originalCanUse, nil
local originalEquippable = C_Item.IsEquippableItem
C_Item.IsEquippableItem = function() return nil end
expect(head, nil, false)
C_Item.IsEquippableItem = originalEquippable
local gain, ready = scoring:GetUpgrade(head, { score = function() error("Provider failure") end })
assert(gain == nil and ready == false)
local gain, ready = scoring:GetUpgrade(head, { score = function() return math.huge, true end })
assert(gain == nil and ready == false)
local originalLink, originalID = GetInventoryItemLink, GetInventoryItemID
GetInventoryItemLink = function() return nil end
GetInventoryItemID = function(_, slot) if slot == 1 then return 55 end end
expect(head, nil, false)
GetInventoryItemLink, GetInventoryItemID = originalLink, originalID
local secret = {}
issecretvalue = function(value) return value == secret end
items[head].stats = { ITEM_MOD_STRENGTH_SHORT = secret }
local gain, ready = scoring:GetUpgrade(head, scoring:GetDefaultScale())
assert(gain == nil and ready == false)
issecretvalue = nil
print("Reward scoring: valid slots, exact variants, class defaults, native eligibility and incomplete data passed")
