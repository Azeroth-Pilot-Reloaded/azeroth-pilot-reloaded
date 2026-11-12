-- Real Pawn, equipment scoring and bag lifecycle; only client/Pawn data are synthetic.
for _, client in ipairs({ "retail", "forever" }) do
    local timers, dialog, scalePrompt = {}, nil, nil
    local spec, ready, notifications, offers = 101, true, 0, 0
    local level, armorAllowed, armorError = 20, true, false
    local rejectEquipped = false
    local loc, dual = "INVTYPE_HEAD", true
    local hands = {}
    local equipped, upgrade = "item:7101:equipped", "item:7102:upgrade"
    local intellect = { [equipped] = 2, [upgrade] = 10 }
    local profile = { name = "Default", enableAddon = true, autoHandIn = false, autoHandInChoice = false }
    APR = {
        settings = { db = { char = { bagUpgradeSuggestions = true } } },
        GAME_VERSIONS = { Retail = "retail", Forever = "forever" },
        Gamepad = { IsAvailable = function() return true end },
        UI = {}, questionDialog = {},
        OptionsPanel = { QueueRefresh = function() notifications = notifications + 1 end },
    }
    function APR:GetGameVersion() return client end
    function APR.settings.db:GetCurrentProfile() return profile.name end
    function APR:GetSettingsProfile() return profile end
    function APR:NewModule()
        return {
            events = {},
            RegisterEvent = function(self, event, method) self.events[event] = method end,
            UnregisterEvent = function(self, event) self.events[event] = nil end,
            UnregisterAllEvents = function(self) self.events = {} end,
        }
    end
    LibStub = function()
        return { GetLocale = function() return {
            GEAR_UPGRADE_TITLE = "Gear", GEAR_UPGRADE_PROMPT = "Better gear?", CHOOSE_USABLE_GEAR_UPGRADE = "Compare", REWARD_PAWN_CHANGED = "Use %s?",
            REWARD_WEIGHT_SCALE_DESC = "Scoring profile", REWARD_WEIGHT_DEFAULT_DESC = "APR: %s",
            REWARD_PAWN_UNAVAILABLE = "Pending: %s",
        } end }
    end
    DEFAULT, EQUIPMENT, CURRENTLY_EQUIPPED = "Default", "Equipment", "Equipped"
    NUM_BAG_SLOTS = 0
    issecretvalue = nil
    function UnitClass() return "Mage", "MAGE", 8 end
    function UnitLevel() return level end
    function CanDualWield() return dual end
    function InCombatLockdown() return false end
    function UnitIsDeadOrGhost() return false end
    function GetInventoryItemLink(_, slot) return loc == "INVTYPE_HEAD" and slot == 1 and equipped or hands[slot] end
    function GetInventoryItemID(_, slot) return nil end
    C_SpecializationInfo = {
        GetSpecialization = function() return 1 end,
        GetSpecializationInfo = function() return spec, "Fixture", nil, nil, "DAMAGER", 4 end,
    }
    C_PlayerInfo = { CanUseItem = function() return true end }
    C_Item = {
        GetItemInfo = function(link)
            return "Fixture", link, 2, 20, 0, "", "", 1, loc, 0, 1, 4, 1
        end,
        GetItemStats = function(link) return { ITEM_MOD_INTELLECT_SHORT = intellect[link] } end,
        IsEquippableItem = function() return true end,
        GetItemUniqueness = function() end,
    }
    C_Container = {
        GetContainerNumSlots = function() return 1 end,
        GetContainerItemLink = function() return upgrade end,
    }
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
        error("Refreshes must settle")
    end
    function StaticPopup_OnHide() end
    function StaticPopup_Hide() scalePrompt = nil end
    function hooksecurefunc(name, callback)
        local original = _G[name]
        _G[name] = function(...) original(...); callback(...) end
    end
    function APR.questionDialog:CreateQuestionPopup(_, _, accept, cancel)
        scalePrompt = { accept = accept, cancel = cancel }
    end
    function APR.UI:ShowConfirmationDialog(_, _, cancel)
        offers = offers + 1
        dialog = { shown = true }
        function dialog:IsShown() return self.shown end
        function dialog:Hide()
            self.shown = false
            cancel()
        end
        return dialog
    end
    PawnCommon = { Scales = {
        Active = { ClassID = 8, Values = { Intellect = 2 } },
        Other = { ClassID = 8, Values = { Intellect = 3 } },
    } }
    function PawnIsReady() return ready end
    function PawnGetAllScalesEx()
        local scales = {}
        for name in pairs(PawnCommon.Scales) do
            scales[#scales + 1] = { Name = name, IsProvider = true, IsVisible = true }
        end
        return scales
    end
    function PawnGetAllStatValues(name) return PawnCommon.Scales[name].Values end
    function PawnGetItemData(link) return { Link = link, InvType = loc, UnenchantedStats = { Intellect = intellect[link] } } end
    function PawnGetSingleValueFromItem(item, name)
        return 0, item.UnenchantedStats.Intellect * PawnCommon.Scales[name].Values.Intellect
    end
    function PawnIsArmorBestTypeForPlayer(item)
        if armorError then error("Missing armor data") end
        if rejectEquipped and item.Link == equipped then return false end
        return armorAllowed and (client == "forever" or level < 27 or loc ~= "INVTYPE_HEAD")
    end
    function PawnSetShowUpgradesForWeapons(name, set, show)
        PawnCommon.Scales[name][set == 1 and "DoNotShow1HUpgrades" or "DoNotShow2HUpgrades"] = not show
    end
    function PawnSetStatValue(name, stat, value) PawnCommon.Scales[name].Values[stat] = value end
    dofile("APR-Core/utils/ProfileUtils.lua")
    dofile("APR-Core/features/questing/RewardScoring.lua")
    dofile("APR-Core/integrations/Pawn.lua")
    dofile("APR-Core/features/player/BagUpgrades.lua")
    local pawn, bags = APR.PawnRewards, APR.BagUpgrades
    pawn:OnEnable()
    assert(pawn:SetSelectedScale("pawn:Active"))
    local function gain()
        local score, state = pawn:GetScorer()
        assert(state == "pawn")
        return APR.RewardScoring:GetUpgrade(upgrade, { score = score })
    end
    assert(gain() == 16, "Unrestricted armor compares against equipped gear")
    rejectEquipped = true
    assert(gain() == 16, "A filtered equipped item still contributes its raw score")
    rejectEquipped = false
    armorAllowed = false
    local value, known = gain()
    assert(value == nil and known, "Pawn armor recommendations must be respected")
    armorAllowed, armorError = true, true
    value, known = gain()
    assert(value == nil and not known, "An armor helper error cannot authorize a recommendation")
    armorError = false
    level = 27
    value, known = gain()
    assert((client == "forever" and value == 16) or (client == "retail" and value == nil and known),
        "Armor specialization follows Pawn's client and level contract")
    level = 20
    for _, kind in ipairs({ "INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND",
        "INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_2HWEAPON", "INVTYPE_RANGED" }) do
        loc = kind
        hands = {}
        local set = kind == "INVTYPE_2HWEAPON" and 2 or 1
        PawnSetShowUpgradesForWeapons("Active", set, true)
        assert(gain() == 20, "Allowed weapon or offhand is recommended: " .. kind)
        PawnSetShowUpgradesForWeapons("Active", set, false)
        value, known = gain()
        assert((kind == "INVTYPE_RANGED" and value == 20) or (kind ~= "INVTYPE_RANGED" and value == nil and known),
            "Handedness suggestion filters include shields/frills but exclude ranged: " .. kind)
        PawnSetShowUpgradesForWeapons("Active", set, true)
    end
    PawnCommon.Scales.Active.Values.IsOffHand = -1000000
    assert(pawn:SetSelectedScale("pawn:Active"))
    loc = "INVTYPE_WEAPONOFFHAND"
    value, known = gain()
    assert(value == nil and known, "An offhand-only weapon also respects the profile restriction")
    for _, kind in ipairs({ "INVTYPE_SHIELD", "INVTYPE_HOLDABLE" }) do
        loc = kind
        assert(gain() == 20, "IsOffHand does not prohibit shields or frills")
    end
    loc = "INVTYPE_WEAPON"
    hands = { [16] = upgrade, [17] = equipped }
    intellect[upgrade] = 10
    -- The candidate now scores 8, between a strong main hand (20) and weak offhand (4).
    local candidate = "item:7103:candidate"
    intellect[candidate] = 4
    PawnCommon.Scales.Active.Values.IsOffHand = -1000000
    assert(pawn:SetSelectedScale("pawn:Active"))
    local score = pawn:GetScorer()
    value, known = APR.RewardScoring:GetUpgrade(candidate, { score = score })
    assert(value == -12 and known, "A generic weapon must not bypass the profile's offhand restriction")
    PawnSetStatValue("Active", "IsOffHand", nil)
    assert(pawn:SetSelectedScale("pawn:Active"))
    score = pawn:GetScorer()
    value, known = APR.RewardScoring:GetUpgrade(candidate, { score = score })
    assert(value == 4 and known, "Removing the offhand restriction restores that destination")
    PawnSetStatValue("Active", "IsOffHand", -999999)
    assert(pawn:SetSelectedScale("pawn:Active"))
    score = pawn:GetScorer()
    assert(APR.RewardScoring:GetUpgrade(candidate, { score = score }) == 4,
        "An offhand weight above the ignore threshold remains eligible")
    hands = {}
    bags:OnEnable()
    flush()
    assert(bags.prompt and bags.prompt.gain == 20)
    PawnSetShowUpgradesForWeapons("Active", 1, false)
    flush()
    assert(not bags.prompt and not scalePrompt, "A weapon toggle immediately retires the live offer")
    PawnSetShowUpgradesForWeapons("Active", 1, true)
    flush()
    assert(bags.prompt and bags.prompt.gain == 20, "Restoring weapon suggestions recomputes the offer")
    bags:OnDisable()
    -- Recommendation filters must not erase the equipped baseline's raw value.
    loc, hands = "INVTYPE_HEAD", {}
    bags:OnEnable()
    flush()
    assert(bags.prompt and bags.prompt.gain == 16)
    local oldScore, _, oldIdentity = pawn:GetScorer()
    PawnSetShowUpgradesForWeapons("Other", 1, false)
    flush()
    local _, _, unchanged = pawn:GetScorer()
    assert(unchanged == oldIdentity and bags.prompt, "Unused scale settings cannot change the active context")
    PawnSetShowUpgradesForWeapons("Active", 1, false)
    flush()
    local _, state, newIdentity = pawn:GetScorer()
    assert(state == "pawn" and newIdentity ~= oldIdentity and not scalePrompt,
        "Recommendation settings change context without a weight-confirmation prompt")
    value, known = oldScore(upgrade)
    assert(value == nil and not known, "An old decision cannot outlive recommendation settings")
    armorAllowed = false
    pawn:RefreshSettings()
    bags:RefreshSettings()
    flush()
    assert(not bags.prompt, "A refreshed bag offer must apply the armor filter")
    armorAllowed = true
    pawn:RefreshSettings()
    bags:RefreshSettings()
    flush()
    assert(bags.prompt and bags.prompt.gain == 16, "Filters do not corrupt the equipped baseline")
    local beforeLevel = select(3, pawn:GetScorer())
    local timerCount = #timers
    pawn[pawn.events.UNIT_LEVEL](pawn, "UNIT_LEVEL", "party1")
    assert(#timers == timerCount, "Foreign level events do not schedule provider work")
    level = 27
    pawn[pawn.events.UNIT_LEVEL](pawn, "UNIT_LEVEL", "player")
    flush()
    assert(select(3, pawn:GetScorer()) ~= beforeLevel, "Player level is part of the armor recommendation context")
    if client == "retail" then assert(not bags.prompt, "Armor specialization retires a live offer") end
    bags:OnDisable()
    pawn:OnDisable()
    assert(not next(pawn.events), "Disabling the provider unregisters level notifications")
end
print("Pawn recommendation constraints passed for both clients")
