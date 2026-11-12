-- Real Pawn, equipment scoring and bag lifecycle; only client/Pawn data are synthetic.
for _, client in ipairs({ "retail", "forever" }) do
    local timers, dialog, scalePrompt = {}, nil, nil
    local spec, ready, notifications, offers = 101, true, 0, 0
    local equipped, upgrade = "item:7101:equipped", "item:7102:upgrade"
    local intellect = { [equipped] = 2, [upgrade] = 10 }
    local profile = { enableAddon = true, autoHandIn = false, autoHandInChoice = false }
    APR = {
        settings = { db = { char = { bagUpgradeSuggestions = true } } },
        GAME_VERSIONS = { Retail = "retail", Forever = "forever" },
        Gamepad = { IsAvailable = function() return true end },
        UI = {}, questionDialog = {},
        OptionsPanel = { QueueRefresh = function() notifications = notifications + 1 end },
    }
    function APR:GetGameVersion() return client end
    function APR:GetSettingsProfile() return profile end
    function APR:NewModule()
        return {
            RegisterEvent = function() end, UnregisterEvent = function() end, UnregisterAllEvents = function() end,
        }
    end
    LibStub = function()
        return { GetLocale = function() return {
            CHOOSE_USABLE_GEAR_UPGRADE = "Compare", REWARD_PAWN_CHANGED = "Use %s?",
        } end }
    end
    DEFAULT, EQUIPMENT, CURRENTLY_EQUIPPED = "Default", "Equipment", "Equipped"
    NUM_BAG_SLOTS = 0
    issecretvalue = nil
    function UnitClass() return "Mage", "MAGE", 8 end
    function UnitLevel() return 20 end
    function InCombatLockdown() return false end
    function UnitIsDeadOrGhost() return false end
    function GetInventoryItemLink(_, slot) return slot == 1 and equipped or nil end
    function GetInventoryItemID(_, slot) return slot == 1 and 7101 or nil end
    C_SpecializationInfo = {
        GetSpecialization = function() return 1 end,
        GetSpecializationInfo = function() return spec, "Fixture", nil, nil, "DAMAGER", 4 end,
    }
    C_PlayerInfo = { CanUseItem = function() return true end }
    C_Item = {
        GetItemInfo = function(link)
            return "Fixture", link, 2, 20, 0, "", "", 1, "INVTYPE_HEAD", 0, 1, 4, 1
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
    function PawnGetItemData(link) return { UnenchantedStats = { Intellect = intellect[link] } } end
    function PawnGetSingleValueFromItem(item, name)
        return 0, item.UnenchantedStats.Intellect * PawnCommon.Scales[name].Values.Intellect
    end
    function PawnSetStatValue(name, stat, value) PawnCommon.Scales[name].Values[stat] = value end
    dofile("APR-Core/utils/ProfileUtils.lua")
    dofile("APR-Core/features/questing/RewardScoring.lua")
    dofile("APR-Core/integrations/Pawn.lua")
    dofile("APR-Core/features/player/BagUpgrades.lua")
    local pawn, bags = APR.PawnRewards, APR.BagUpgrades
    pawn:OnEnable()
    assert(pawn:SetSelectedScale("pawn:Active"))
    bags:OnEnable()
    flush()
    assert(bags.prompt and bags.prompt.gain == 16, "The real Pawn score drives the real equipment comparison")
    local function dismiss()
        assert(dialog:IsShown() and bags.prompt)
        dialog:Hide()
        flush()
        assert(not bags.prompt and bags.dismissed[upgrade], "Ignoring equipment must remember the exact item")
    end
    dismiss()
    local count, previousNotifications = offers, notifications
    pawn:RefreshSettings()
    flush()
    assert(offers == count and not bags.prompt and bags.dismissed[upgrade],
        "An unchanged Pawn refresh must preserve dismissed equipment")
    assert(notifications > previousNotifications, "Options still refresh independently of scoring")
    pawn:NotifyOptions()
    flush()
    assert(offers == count and bags.dismissed[upgrade], "An options notification cannot invalidate a refusal")
    PawnSetStatValue("Other", "Intellect", 4)
    flush()
    assert(offers == count and bags.dismissed[upgrade], "Editing an unused scale must preserve refusals")
    assert(pawn:SetSelectedScale("pawn:Active"))
    flush()
    assert(offers == count and bags.dismissed[upgrade], "Reselecting the same confirmed weights is idempotent")
    assert(pawn:SetSelectedScale("pawn:Other"))
    flush()
    assert(offers == count + 1 and bags.prompt.gain == 32, "Selecting other weights recomputes the gain")
    dismiss()
    PawnSetStatValue("Other", "Intellect", 5)
    flush()
    assert(scalePrompt and not bags.prompt, "Unconfirmed active weights suspend bag suggestions")
    scalePrompt.accept()
    flush()
    assert(bags.prompt and bags.prompt.gain == 40, "Confirming changed active weights recomputes suggestions")
    dismiss()
    profile = { enableAddon = true, autoHandIn = false, autoHandInChoice = false }
    bags:RefreshSettings()
    pawn:RefreshSettings()
    flush()
    assert(bags.prompt and bags.prompt.gain == 40, "Switching the active APR settings profile recomputes suggestions")
    dismiss()
    ready = false
    pawn:RefreshSettings()
    flush()
    assert(not bags.prompt, "A pending Pawn choice must never use APR defaults")
    ready = true
    pawn:RefreshSettings()
    flush()
    assert(bags.prompt and bags.prompt.gain == 40, "Restored scoring availability resumes suggestions")
    dismiss()
    spec = 102
    pawn:OnSpecializationChanged(nil, "player")
    flush()
    assert(bags.prompt and bags.prompt.gain == 8, "A new spec with no Pawn choice uses its APR context")
    dismiss()
    pawn:RefreshSettings()
    flush()
    assert(not bags.prompt and bags.dismissed[upgrade], "APR context identity must also remain stable")
    bags:OnDisable()
    pawn:OnDisable()
end
print("Pawn/bags: stable refusals, independent options, relevant scale/profile/spec and availability changes passed")
