-- Join the real Forever context, Pawn adapter, equipment scorer and /apr gear.
-- A single visible class scale is the user's Pawn context before talents.
local timers, inventory, bags, items, messages = {}, {}, {}, {}, {}
local popup, equipped, ready, combat = nil, 0, true, false
local classID, classToken = 2, "PALADIN"
local profile = { enableAddon = true }
APR = { GAME_VERSIONS = { Forever = "forever" },
    settings = { profile = profile, db = { char = { bagUpgradeSuggestions = true } } },
    UI = {}, questionDialog = {} }
function APR:GetGameVersion() return "forever" end
function APR:GetSettingsProfile() return profile end
function APR:NewModule() return { RegisterEvent = function() end, UnregisterEvent = function() end,
    UnregisterAllEvents = function() end } end
function APR:PrintInfo(text) messages[#messages + 1] = text end
function APR:TrimString(text) return text:match("^%s*(.-)%s*$") end
function APR:RemoveContiguousSpaces(text) return text end
function APR.settings:OpenSettings() end
LibStub = function() return { GetLocale = function() return setmetatable({
    REWARD_WEIGHT_DEFAULT_DESC = "APR: %s", REWARD_PAWN_UNAVAILABLE = "Unavailable: %s",
}, { __index = function(_, key) return key end }) end } end
EQUIPMENT, NONE, UNAVAILABLE, SEARCHING, SCORE = "Equipment", "None", "Unavailable", "Searching", "Score"
HEADSLOT, CHESTSLOT, FEETSLOT = "Head", "Chest", "Feet"
NUM_BAG_SLOTS = 0
function UnitClass() return classToken, classToken, classID end
function UnitLevel() return 3 end
function GetBuildInfo() return nil, nil, nil, 16001 end
function InCombatLockdown() return combat end
function UnitIsDeadOrGhost() return false end
function GetInventoryItemLink(_, slot) return inventory[slot] end
function GetInventoryItemID(_, slot) return inventory[slot] and items[inventory[slot]].id end
-- Forever's native class spec is not a proven Classic talent/build choice.
C_SpecializationInfo = { GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function() return 777, "Class", nil, nil, "HEALER", 4 end }
C_PlayerInfo = { CanUseItem = function() return true end }
C_Item = {
    GetItemInfo = function(link)
        local item = items[link]
        return "Fixture", link, 1, 1, 0, "", "", 1, item.loc, 0, 1, 4, item.subclass or 3
    end,
    GetItemStats = function(link) return { ITEM_MOD_STRENGTH_SHORT = items[link].strength,
        RESISTANCE0_NAME = items[link].armor or 0, ITEM_MOD_STAMINA_SHORT = items[link].stamina or 0,
        ITEM_MOD_AGILITY_SHORT = items[link].agility or 0, ITEM_MOD_SPELL_POWER_SHORT = items[link].spellPower or 0 } end,
    IsEquippableItem = function() return true end,
    GetItemUniqueness = function() end,
    EquipItemByName = function(link, slot)
        assert(not combat)
        equipped = equipped + 1
        inventory[slot] = link
        for index, old in pairs(bags) do if old == link then bags[index] = nil end end
    end,
}
C_Container = { GetContainerNumSlots = function() return 3 end,
    GetContainerItemLink = function(_, slot) return bags[slot] end,
    GetContainerItemInfo = function(_, slot)
        return bags[slot] and { isLocked = false, itemID = items[bags[slot]].id }
    end }
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local function flush()
    for _ = 1, 200 do
        if #timers == 0 then return end
        local timer = table.remove(timers, 1)
        if not timer.cancelled then timer.callback() end
    end
    error("Scans must settle")
end
function APR.UI:ShowConfirmationDialog(settings, accept, cancel)
    popup = { shown = true, text = settings.description, rows = settings.comparison }
    function popup:IsShown() return self.shown end
    function popup:Hide() self.shown = false; cancel() end
    function popup:Accept() self.shown = false; accept() end
    return popup
end
PawnCommon = { Scales = {
    ZPhysical = { ClassID = 2, SpecID = 3, Role = "DAMAGER", Provider = "Fixture", Visible = true, Values = { Strength = 2 } },
    AHiddenHealer = { ClassID = 2, SpecID = 1, Role = "HEALER", Provider = "Fixture", Visible = false, Values = { Intellect = 8 } },
    WrongClass = { ClassID = 1, SpecID = 1, Provider = "Fixture", Visible = true, Values = { Strength = 9 } },
} }
function PawnIsReady() return ready end
function PawnGetAllScalesEx()
    local list = {}
    for name, scale in pairs(PawnCommon.Scales) do
        list[#list + 1] = { Name = name, LocalizedName = name, IsProvider = true, IsVisible = scale.Visible }
    end
    return list
end
function PawnGetAllStatValues(name) return PawnCommon.Scales[name].Values end
function PawnGetItemData(link)
    return { Link = link, InvType = items[link].loc, UnenchantedStats = { Strength = items[link].strength } }
end
function PawnGetSingleValueFromItem(item, name)
    return 0, item.UnenchantedStats.Strength * (PawnCommon.Scales[name].Values.Strength or 0)
end
function PawnIsArmorBestTypeForPlayer() return true end
local function item(id, loc, strength)
    local link = "item:" .. id .. ":variant"
    items[link] = { id = id, loc = loc, strength = strength }
    return link
end
inventory[1], inventory[5], inventory[8] = item(9301, "INVTYPE_HEAD", 1), item(9302, "INVTYPE_CHEST", 1), item(9303, "INVTYPE_FEET", 1)
bags[1], bags[2], bags[3] = item(9401, "INVTYPE_HEAD", 4), item(9402, "INVTYPE_CHEST", 3), item(9403, "INVTYPE_FEET", 2)
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/features/questing/RewardScoring.lua")
dofile("APR-Core/integrations/Pawn.lua")
dofile("APR-Core/features/player/BagUpgrades.lua")
dofile("APR-Core/core/Commands.lua")
local pawn, module = APR.PawnRewards, APR.BagUpgrades
pawn:OnEnable(); module:OnEnable()
assert(not APR:GetRewardBuildContext().pawnSpec and not APR.RewardScoring:GetDefaultScale(),
    "The fixture has no guessed APR build or complete APR profile")
APR.command:SlashCmd("gear"); flush()
assert(module.prompt and module.prompt.plan.slot == 1 and module.prompt.gain == 6,
    "The real gear command must compare the best Pawn upgrade against occupied level-three armor")
assert(pawn:GetSelectedScale() == "pawn:ZPhysical" and not module:GetScale().emptyArmorOnly)
assert(equipped == 0 and popup.rows[1].current.link == inventory[1] and popup.rows[1].proposed.link == bags[1])
assert(popup.text:find("Pawn: ZPhysical", 1, true))
for _, expectedSlot in ipairs({ 1, 5, 8 }) do
    assert(module.prompt and module.prompt.plan.slot == expectedSlot)
    popup:Accept(); flush()
end
assert(equipped == 3 and not module.prompt, "Three occupied upgrades require three explicit clicks")
assert(inventory[1] == "item:9401:variant" and inventory[5] == "item:9402:variant" and inventory[8] == "item:9403:variant")
-- Forever's normal class-wide Pawn display can leave all three builds visible.
-- Prove pure armor improvements without selecting one of those three roles.
PawnCommon.Scales.AHiddenHealer.Visible = true
PawnCommon.Scales.Protection = { ClassID = 2, SpecID = 2, Role = "TANK", Provider = "Fixture", Visible = true, Values = { Stamina = 4 } }
for pass, mode in ipairs({ "auto", "apr" }) do
    assert(pawn:SetSelectedScale(mode))
    for index, slot in ipairs({ 1, 5, 8 }) do
        local current = inventory[slot]
        local replacement = item(9500 + pass * 10 + index, items[current].loc, items[current].strength)
        items[current].armor, items[replacement].armor = 2, 3
        bags[index] = replacement
    end
    assert(pawn:GetSelectedScale() == "apr", "Three active builds cannot imply a role before talents")
    APR.command:SlashCmd("gear"); flush()
    for _, slot in ipairs({ 1, 5, 8 }) do
        assert(module.prompt and module.prompt.plan.slot == slot,
            "Both automatic and explicit APR permit proven dominance on three occupied armor slots")
        assert(not popup.text:find("Pawn:", 1, true) and not popup.text:find(SCORE, 1, true),
            "A dominance proof is not a Pawn/APR weighted score")
        popup:Accept(); flush()
    end
    assert(equipped == 3 + pass * 3)
end
PawnCommon.Scales.AHiddenHealer.Visible, PawnCommon.Scales.Protection.Visible = false, false
-- No complete profile: report limited comparison capability, never a false no-gain result.
assert(pawn:SetSelectedScale("apr"))
APR.command:SlashCmd("gear"); flush()
assert(not module.prompt and messages[#messages]:find(UNAVAILABLE, 1, true))
assert(pawn:GetPreference() == "apr", "Explicit APR stays authoritative")
assert(pawn:SetSelectedScale("auto"))
local previousScorer = pawn:GetScorer()
PawnCommon.Scales.AHiddenHealer.Visible = true
assert(select(2, previousScorer("item:9401:variant")) == false, "A changed visible source invalidates the old scorer")
assert(pawn:GetSelectedScale() == "apr", "Two visible builds without a proven build remain ambiguous")
APR.command:SlashCmd("gear"); flush()
assert(not module.prompt and messages[#messages]:find(UNAVAILABLE, 1, true))
assert(APR:SetRewardBuild("3"))
assert(pawn:GetSelectedScale() == "pawn:ZPhysical", "A proven build resolves multiple visible scales")
PawnCommon.Scales.HiddenDuplicate = { ClassID = 2, SpecID = 3, Provider = "Fixture", Visible = false, Values = { Strength = 20 } }
assert(pawn:GetSelectedScale() == "pawn:ZPhysical", "An inactive matching provider does not create an ambiguity")
assert(pawn:SetSelectedScale("pawn:ZPhysical"))
ready = false
assert(select(2, pawn:GetScorer()) == "pending", "An explicit pending provider cannot fall back")
ready = true
-- A known physical build must not inherit a lone visible caster scale.
assert(pawn:SetSelectedScale("auto"))
classID, classToken = 11, "DRUID"
PawnCommon.Scales = {
    Caster = { ClassID = 11, SpecID = 1, Role = "DAMAGER", Provider = "Fixture", Visible = true, Values = { SpellPower = 9 } },
    Feral = { ClassID = 11, SpecID = 2, Role = "DAMAGER", Provider = "Fixture", Visible = false, Values = { Agility = 2 } },
}
assert(APR:SetRewardBuild("2"))
assert(pawn:GetSelectedScale() == "apr", "A visible caster cannot override the proven Feral build")
local physical = assert(APR.RewardScoring:GetDefaultScale())
assert(physical.weights.SpellPower == 0)
items[inventory[1]].agility, items[inventory[1]].subclass = 6, 2
local caster = item(9701, "INVTYPE_HEAD", 0)
items[caster].armor, items[caster].spellPower, items[caster].subclass = 3, 100, 2
local loss, known = APR.RewardScoring:GetUpgrade(caster, physical)
assert(known and loss < 0, "Replacing physical stats with SP remains a negative Feral comparison")
bags[1] = caster
APR.command:SlashCmd("gear"); flush()
assert(not module.prompt and equipped == 9)
module:OnDisable(); pawn:OnDisable()
print("Forever starter: visible Pawn source, three occupied upgrades, explicit clicks, ambiguity and authoritative overrides")
