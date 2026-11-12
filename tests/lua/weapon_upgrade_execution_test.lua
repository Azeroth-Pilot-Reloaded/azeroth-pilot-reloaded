-- Real scoring and explicit equipment actions; every item is synthetic.
for _, client in ipairs({ "retail", "forever" }) do
    local inventory, bags, items, calls, timers = {}, {}, {}, {}, {}
    local mode, pending, swap, combat, offers = nil, nil, false, false, 0
    local character = {}
    NUM_BAG_SLOTS = 0
    APR = { GAME_VERSIONS = { Retail = "retail", Forever = "forever" } }
    function APR:GetGameVersion() return client end
    function APR:GetSettingsProfile() return { enableAddon = true } end
    function APR:GetBagUpgradeSuggestions() return true end
    function APR:GetCharacterSettings() return character end
    function APR:NewModule()
        return { RegisterEvent = function() end, UnregisterEvent = function() end }
    end
    LibStub = function() return { GetLocale = function() return {} end } end
    function UnitClass() return "Warrior", "WARRIOR", 1 end
    function UnitLevel() return 20 end
    function InCombatLockdown() return combat end
    function CanDualWield() return true end
    function GetInventoryItemLink(_, slot) return inventory[slot] end
    function GetInventoryItemID(_, slot) return inventory[slot] and items[inventory[slot]].id end
    C_PlayerInfo = { CanUseItem = function() return true end }
    C_Item = {
        GetItemInfo = function(link)
            local item = items[link]
            if not item then return end
            return "Fixture", link, 2, 20, 0, "", "", 1, item.loc, 0, 1, 2, 0
        end,
        GetItemStats = function(link) return { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = items[link].dps } end,
        IsEquippableItem = function() return true end,
        GetItemUniqueness = function() return nil end,
    }
    local function apply(link, slot)
        local old = inventory[slot]
        for from, equipped in pairs(inventory) do
            if equipped == link then inventory[from] = swap and old or nil; break end
        end
        for from, bag in pairs(bags) do
            if bag == link then bags[from] = old; break end
        end
        inventory[slot] = link
    end
    C_Item.EquipItemByName = function(link, slot)
        calls[#calls + 1] = { link, slot }
        if mode == "fail-first" and #calls == 1 or mode == "fail-second" and #calls == 2 then return end
        if mode == "delayed" and #calls == 1 then pending = function() apply(link, slot) end; return end
        if mode == "partial" and #calls == 1 then inventory[slot] = link; return end
        apply(link, slot)
        if mode == "combat" then combat = true end
        if mode == "foreign" then inventory[1] = "item:unexpected:change" end
    end
    C_Container = {
        GetContainerNumSlots = function() return 1 end,
        GetContainerItemLink = function(_, slot) return bags[slot] end,
        GetContainerItemInfo = function() return { isLocked = false } end,
    }
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end }
    dofile("APR-Core/features/questing/RewardScoring.lua")
    dofile("APR-Core/features/player/BagUpgrades.lua")
    local scoring, module = APR.RewardScoring, APR.BagUpgrades
    local scale = scoring:GetDefaultScale()
    scale.weights.WeaponDPS = 1
    module.active = true
    function module:GetScale() return scale, "apr" end
    function module:Offer(candidate) offers = offers + 1 end
    local function flush()
        for _ = 1, 100 do
            if #timers == 0 then return end
            local timer = table.remove(timers, 1)
            if not timer.cancelled then timer.callback() end
        end
        error("Scans must settle")
    end
    local nextID = 7000
    local function weapon(loc, dps)
        nextID = nextID + 1
        local link = "item:" .. nextID .. ":fixture"
        items[link] = { id = nextID, loc = loc, dps = dps }
        return link
    end
    local function attempt(mainDps, offDps, loc, dps, failure, mainLoc)
        local main, off, candidate = weapon(mainLoc or "INVTYPE_WEAPON", mainDps), weapon("INVTYPE_WEAPON", offDps), weapon(loc, dps)
        inventory, bags, calls, timers, mode, pending, combat = { [16] = main, [17] = off }, { [1] = candidate }, {}, {}, failure, nil, false
        local links = {}
        for slot = 1, 19 do links[slot] = inventory[slot] or "" end
        module:Equip({ link = candidate, bag = 0, slot = 1, signature = table.concat(links, "\031"), scoringIdentity = "apr" })
        return main, off, candidate
    end
    local function value()
        local main, off = items[inventory[16]], items[inventory[17]]
        return (main and main.dps or 0) + 0.5 * (off and off.dps or 0)
    end
    -- A positive final pair may require a temporary downgrade. Never start it.
    attempt(100, 10, "INVTYPE_WEAPONMAINHAND", 60)
    assert(#calls == 0 and value() == 105, "No safe first step: manual permutation only")
    flush()
    assert(offers == 0 and #calls == 0, "An unsafe permutation must not become a doomed bag offer")
    -- Replacing the main first is safe; moving it first is a partial downgrade.
    local main, _, candidate = attempt(100, 10, "INVTYPE_WEAPONMAINHAND", 110, "fail-second")
    assert(calls[1][1] == candidate and #calls == 2 and value() >= 105, "Candidate-first failure cannot downgrade")
    attempt(100, 10, "INVTYPE_WEAPONMAINHAND", 110, "fail-first")
    assert(#calls == 1 and value() == 105, "An unconfirmed candidate also stops before moving the retained weapon")
    -- The opposite orientation has a safe retained-weapon-first order.
    local _, off = attempt(20, 100, "INVTYPE_WEAPONOFFHAND", 90, "fail-first")
    assert(#calls == 1 and calls[1][1] == off and value() == 70, "A failed move stops the plan")
    attempt(20, 100, "INVTYPE_WEAPONOFFHAND", 90, "fail-second")
    assert(#calls == 2 and value() >= 70, "A failed second action leaves a non-worse loadout")
    attempt(20, 100, "INVTYPE_WEAPONOFFHAND", 90, "delayed")
    assert(#calls == 1 and value() == 70 and pending, "An unconfirmed move cannot trigger the second action")
    pending()
    assert(#calls == 1 and value() >= 70, "Later confirmation must not equip without a fresh click")
    module:QueueScan("PLAYER_EQUIPMENT_CHANGED")
    flush()
    assert(#calls == 1 and value() >= 70, "Neither events nor timers may continue the protected plan")
    for _, interruption in ipairs({ "partial", "combat", "foreign" }) do
        attempt(20, 100, "INVTYPE_WEAPONOFFHAND", 90, interruption)
        assert(#calls == 1, "The entire intermediate and combat state must be confirmed: " .. interruption)
    end
    local retained, _, candidate = attempt(100, 10, "INVTYPE_WEAPONMAINHAND", 110)
    assert(#calls == 2 and inventory[16] == candidate and inventory[17] == retained and value() == 160)
    -- Both native displacement outcomes are safe and yield the intended pair.
    for _, exchanged in ipairs({ false, true }) do
        swap = exchanged
        local _, retained, candidate = attempt(20, 100, "INVTYPE_WEAPONOFFHAND", 90)
        assert(#calls == 2 and inventory[16] == retained and inventory[17] == candidate and value() == 145)
    end
    -- An impossible swap snapshot is not confirmation of a completed move.
    -- A main-only weapon cannot be the displaced item observed in the offhand.
    attempt(20, 100, "INVTYPE_WEAPONOFFHAND", 90, nil, "INVTYPE_WEAPONMAINHAND")
    assert(#calls == 1, "An illegal intermediate layout cannot authorize the second action")
end
print("Weapon execution: safe intermediate configurations, failure and delayed confirmation passed")
