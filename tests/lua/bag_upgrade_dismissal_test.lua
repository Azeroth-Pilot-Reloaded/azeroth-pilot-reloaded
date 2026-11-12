-- Real scoring and offer lifecycle with invented equipment on both clients.
for _, client in ipairs({ "retail", "forever" }) do
    local inventory, bag, items, timers, dialog = {}, nil, {}, {}, nil
    local identity, offers, dual, titan = "build-a", 0, true, false
    local useDefault, role = false, "DAMAGER"
    local profileName = "Default"
    local character = { bagUpgradeSuggestions = true, rewardBuilds = {["forever:1"]="1"} }
    APR = {
        GAME_VERSIONS = { Retail = "retail", Forever = "forever" },
        settings = { db = { char = character, GetCurrentProfile = function() return profileName end } },
        PawnRewards = {}, UI = {}, Gamepad = { IsAvailable = function() return true end },
    }
    function APR:GetGameVersion() return client end
    function APR:GetSettingsProfile() return { enableAddon = true } end
    function APR:NewModule()
        return { RegisterEvent = function() end, UnregisterEvent = function() end, UnregisterAllEvents = function() end }
    end
    LibStub = function() return { GetLocale = function() return { CHOOSE_USABLE_GEAR_UPGRADE = "Compare" } end } end
    NUM_BAG_SLOTS = 0
    EQUIPMENT, CURRENTLY_EQUIPPED, EMPTY = "Equipment", "Equipped", "Empty"
    function InCombatLockdown() return false end
    function UnitLevel() return 20 end
    function GetBuildInfo() return nil, nil, nil, client == "forever" and 16001 or 120105 end
    function UnitClass() return "Warrior", "WARRIOR", 1 end
    C_SpecializationInfo = {
        GetSpecialization = function() return role == "TANK" and 3 or 1 end,
        GetSpecializationInfo = function() return 900, "Fixture", nil, nil, role, 1 end,
    }
    function GetInventoryItemLink(_, slot) return inventory[slot] end
    function GetInventoryItemID(_, slot) return inventory[slot] and items[inventory[slot]].id end
    function CanDualWield() return dual end
    C_SpellBook = { IsSpellKnown = function() return titan end }
    C_PlayerInfo = { CanUseItem = function() return true end }
    C_Item = {
        GetItemInfo = function(link)
            local data = items[link]
            return "Fixture", link, 2, 20, 0, "", "", 1, data.loc, 0, 1, 2, data.subclass or 0
        end,
        IsEquippableItem = function() return true end,
        GetItemUniqueness = function(link) return items[link].category, items[link].maximum end,
        GetItemStats = function(link) return { ITEM_MOD_STRENGTH_SHORT = items[link].value } end,
    }
    C_Container = { GetContainerNumSlots = function() return 1 end, GetContainerItemLink = function() return bag end }
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end }
    local function flush()
        for _ = 1, 100 do
            if #timers == 0 then return end
            local timer = table.remove(timers, 1)
            if not timer.cancelled then timer.callback() end
        end
        error("Scans must settle")
    end
    function APR.PawnRewards:GetScorer()
        if useDefault then return nil, "apr", "apr:fixture" end
        return function(link) return items[link].value, true end, "pawn", identity
    end
    function APR.UI:ShowConfirmationDialog(_, _, cancel)
        offers = offers + 1
        dialog = { shown = true, cancel = cancel }
        function dialog:IsShown() return self.shown end
        function dialog:Hide() self.shown = false; self.cancel() end
        return dialog
    end
    local nextID = 9000
    local function item(loc, value, category, maximum, subclass)
        nextID = nextID + 1
        local link = "item:" .. nextID .. ":variant"
        items[link] = { id = nextID, loc = loc, value = value, category = category, maximum = maximum, subclass = subclass }
        return link
    end
    dofile("APR-Core/utils/ProfileUtils.lua")
    dofile("APR-Core/features/questing/RewardScoring.lua")
    dofile("APR-Core/features/player/BagUpgrades.lua")
    local module = APR.BagUpgrades
    local function scan() module:QueueScan("PLAYER_EQUIPMENT_CHANGED"); flush() end
    local function ignore()
        assert(module.prompt and dialog:IsShown(), "Expected an offer before ignoring")
        dialog:Hide(); flush()
        assert(not module.prompt, "Ignoring suppresses the same comparison")
    end
    local function unchanged(message, change)
        local count = offers
        change(); scan()
        assert(offers == count and not module.prompt, message)
    end
    local function renewed(message, change)
        local count = offers
        change(); scan()
        assert(offers == count + 1 and module.prompt, message)
    end
    inventory[1], bag = item("INVTYPE_HEAD", 2), item("INVTYPE_HEAD", 20)
    module:OnEnable(); flush(); ignore()
    unchanged("A tabard must not revive an ignored helmet", function() inventory[19] = item("INVTYPE_TABARD", 1) end)
    unchanged("Reload preserves the character refusal", function()
        module:OnDisable()
        local restored = { bagUpgradeSuggestions = true, bagUpgradeDismissals = {}, rewardBuilds = {["forever:1"]="1"} }
        for link, refusal in pairs(character.bagUpgradeDismissals or {}) do
            assert(type(link) == "string" and type(refusal) == "string", "Refusals contain only SavedVariables data")
            restored.bagUpgradeDismissals[link] = refusal
        end
        character = restored
        APR.settings.db.char = character
        dofile("APR-Core/features/player/BagUpgrades.lua")
        module = APR.BagUpgrades
        module:OnEnable()
    end)
    renewed("A different character has independent refusals", function() APR.settings.db.char = { bagUpgradeSuggestions = true } end)
    ignore()
    unchanged("Returning to the first character restores its refusal", function() APR.settings.db.char = character end)
    renewed("A changed helmet permits a new offer", function() inventory[1] = item("INVTYPE_HEAD", 3) end)
    ignore()
    renewed("Edited scores with unchanged item links permit a new offer", function() items[bag].value = 21 end)
    ignore()
    renewed("Distinct fractional scores cannot collide in a rounded refusal identity", function() items[bag].value = 21 + 1e-13 end)
    ignore()
    renewed("Another scoring build permits a new offer", function() identity = "build-b"; module:OnScoringChanged() end)
    ignore()
    unchanged("An unchanged scoring notification preserves the refusal", function() module:OnScoringChanged() end)
    renewed("A different profile has its own comparison context", function() profileName = "Other" end)
    ignore()
    renewed("An exact variant is a separate candidate", function()
        local previous = bag
        bag = previous .. ":bonus"
        items[bag] = items[previous]
    end)
    ignore()
    for _, pair in ipairs({ { "INVTYPE_FINGER", 11, 12 }, { "INVTYPE_TRINKET", 13, 14 } }) do
        inventory, bag = {}, item(pair[1], 30)
        inventory[pair[2]], inventory[pair[3]] = item(pair[1], 5), item(pair[1], 10)
        scan(); ignore()
        renewed("The other paired slot is relevant even when it was not replaced", function()
            inventory[pair[3]] = item(pair[1], 12)
        end)
        ignore()
    end
    inventory, bag = {}, item("INVTYPE_WEAPONMAINHAND", 40)
    inventory[16], inventory[17] = item("INVTYPE_WEAPON", 20), item("INVTYPE_WEAPONOFFHAND", 10)
    scan(); ignore()
    renewed("The retained hand is part of the weapon comparison", function() inventory[16] = item("INVTYPE_WEAPON", 22) end)
    ignore()
    renewed("Weapon capability changes permit a new comparison", function() dual = false end)
    ignore()
    dual = true
    inventory, bag = {}, item("INVTYPE_2HWEAPON", 50, nil, nil, 1)
    inventory[16], inventory[17] = item("INVTYPE_WEAPON", 20), item("INVTYPE_WEAPONOFFHAND", 10)
    scan(); ignore()
    renewed("Titan's Grip changes the legal weapon alternatives", function() titan = true end)
    ignore()
    if client == "forever" then
        inventory, bag = {}, item("INVTYPE_RANGED", 30)
        inventory[16], inventory[18] = item("INVTYPE_WEAPON", 10), item("INVTYPE_RANGED", 5)
        scan(); ignore()
        unchanged("Forever ranged refusals ignore the independent main hand", function() inventory[16] = item("INVTYPE_WEAPON", 12) end)
        unchanged("Forever ranged refusals ignore dual-wield capabilities", function() dual = false; titan = false end)
        renewed("Forever ranged refusals follow the ranged slot", function() inventory[18] = item("INVTYPE_RANGED", 7) end)
        ignore()
    end
    inventory, bag = {}, item("INVTYPE_FINGER", 30, 7, 2)
    inventory[11], inventory[12] = item("INVTYPE_FINGER", 5), item("INVTYPE_FINGER", 10)
    inventory[1] = item("INVTYPE_HEAD", 2, 7, 2)
    scan(); ignore()
    unchanged("Unrelated uniqueness categories do not revive an offer", function() inventory[19] = item("INVTYPE_TABARD", 2, 8, 1) end)
    renewed("Equipment in the same unique category is relevant outside destination slots", function() inventory[1] = nil end)
    -- A callback retained after a programmatic withdrawal cannot record a refusal.
    local stale = dialog
    module:QueueScan()
    stale.cancel()
    flush()
    assert(module.prompt, "Programmatic cancellation and stale callbacks must not ignore the candidate")
    -- Also reject a callback whose scoring inputs changed without an event yet.
    local count = offers
    items[bag].value = 31
    dialog:Hide(); flush()
    assert(offers == count + 1 and module.prompt, "An obsolete comparison cannot dismiss a newly scored offer")
    inventory, bag, useDefault = {}, item("INVTYPE_HEAD", 30), true
    scan(); ignore()
    renewed("Default APR weight changes renew offers even when these items' scores stay equal", function()
        role = "TANK"
        character.rewardBuilds["forever:1"] = "3"
    end)
    ignore()
    unchanged("Recreated default APR scale closures have a stable refusal identity", function() end)
    module:OnDisable()
end
print("Bag refusals: character reload, exact variants, relevant slots, uniqueness, scoring and stale callbacks passed")
