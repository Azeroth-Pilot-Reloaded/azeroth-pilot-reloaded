-- Real Forever context, Pawn selection, scorer, bags and slash command.
local timers, inventory, messages, popup = {}, {}, {}, nil
local combat, dead, ready, interface = false, false, true, 16001
local boots = "item:8201:starter"
local bagLink, location, armor, stamina, spellPower = boots, "INVTYPE_FEET", 5, 0, 0
local equips, pendingEquipmentID = 0, nil
local profile = { enableAddon = true }
APR = { settings = { profile = profile, db = { char = { bagUpgradeSuggestions = true } } },
    GAME_VERSIONS = { Forever = "forever" }, questionDialog = {} }
function APR:GetGameVersion() return "forever" end
function APR:GetSettingsProfile() return profile end
function APR:NewModule() return { RegisterEvent = function() end, UnregisterEvent = function() end,
    UnregisterAllEvents = function() end } end
function APR:PrintInfo(text) messages[#messages + 1] = text end
function APR:TrimString(text) return text:match("^%s*(.-)%s*$") end
function APR:RemoveContiguousSpaces(text) return text end
function APR.settings:OpenSettings() end
LibStub = function() return { GetLocale = function() return setmetatable({
    REWARD_WEIGHT_DEFAULT_DESC = "APR: %s", REWARD_PAWN_UNAVAILABLE = "Pending: %s",
}, {
    __index = function(_, key) return key end }) end } end
EQUIPMENT, EMPTY, SEARCHING, UNAVAILABLE, DISABLED, SCORE = "Equipment", "Empty", "Searching", "Unavailable", "Disabled", "Score"
ERR_NOT_IN_COMBAT, DEAD = "In combat", "Dead"
NUM_BAG_SLOTS = 0
function UnitClass() return "Paladin", "PALADIN", 2 end
function UnitLevel() return 3 end
function GetBuildInfo() return nil, nil, nil, interface end
function InCombatLockdown() return combat end
function UnitIsDeadOrGhost() return dead end
function GetInventoryItemLink(_, slot) return inventory[slot] end
function GetInventoryItemID(_, slot) return inventory[slot] and 8201 or pendingEquipmentID end
C_PlayerInfo = { CanUseItem = function() return true end }
C_Item = {
    GetItemInfo = function(link) return "Fixture", link, 1, 1, 0, "", "", 1, location, 0, 1, 4, 1 end,
    GetItemStats = function() return { RESISTANCE0_NAME = armor, ITEM_MOD_STAMINA_SHORT = stamina,
        ITEM_MOD_SPELL_POWER_SHORT = spellPower } end,
    IsEquippableItem = function() return true end, GetItemUniqueness = function() end,
    EquipItemByName = function(link, slot)
        assert(not combat)
        equips = equips + 1
        inventory[slot], bagLink = link, nil
    end,
}
C_Container = { GetContainerNumSlots = function() return 1 end,
    GetContainerItemLink = function() return bagLink end,
    GetContainerItemInfo = function() return { isLocked = false } end }
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
    error("Starter scans must settle")
end
function StaticPopup_Visible() return popup end
function StaticPopup_Hide() popup = nil end
function APR.questionDialog:CreateQuestionPopup(_, text, accept, cancel)
    popup = { text = text, accept = accept, cancel = cancel }
end
APR.UI = {}
function APR.UI:ShowConfirmationDialog(settings, accept, cancel)
    popup = { text = settings.description, accept = accept, cancel = cancel, shown = true }
    function popup:IsShown() return self.shown end
    function popup:Hide() self.shown = false; cancel() end
    return popup
end
PawnCommon = { Scales = { ZeroArmor = { ClassID = 2, SpecID = 3, Values = { Strength = 1 } } } }
function PawnIsReady() return ready end
function PawnGetAllScalesEx() return { { Name = "ZeroArmor", IsVisible = true, IsProvider = true } } end
function PawnGetAllStatValues() return PawnCommon.Scales.ZeroArmor.Values end
function PawnGetItemData() return { UnenchantedStats = {} } end
function PawnGetSingleValueFromItem() return 0, 0 end
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/features/questing/RewardScoring.lua")
dofile("APR-Core/integrations/Pawn.lua")
dofile("APR-Core/features/player/BagUpgrades.lua")
dofile("APR-Core/core/Commands.lua")
local bags, pawn = APR.BagUpgrades, APR.PawnRewards
pawn:OnEnable()
assert(APR:GetRewardBuildContext().pawnSpec == nil and not APR.RewardScoring:GetDefaultScale())
bags:OnEnable()
flush()
assert(bags.prompt and bags.prompt.plan.slot == 8 and equips == 0,
    "A level-three Forever character without a chosen build must see armor-only boots for empty feet")
assert(not popup.text:find(UNAVAILABLE, 1, true), "A conservative offer must not claim to use an unavailable build")
assert(not popup.text:find(SCORE, 1, true) and not popup.text:find("APR:", 1, true)
    and not popup.text:find("Pawn:", 1, true) and not popup.text:find(EQUIPMENT .. ": " .. EMPTY, 1, true),
    "Empty armor has no weighted source, score or repeated description of its empty square")
popup.accept()
flush()
assert(inventory[8] == boots and equips == 1 and not bags.prompt, "Only the explicit click equips starter boots")
inventory[8], bagLink = nil, boots
bags:QueueScan("PLAYER_EQUIPMENT_CHANGED")
flush()
assert(bags.prompt and equips == 1, "Removing boots and the equipment event must restore the offer")
popup.cancel(nil, nil, "clicked")
flush()
bags:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(not bags.prompt, "The conservative comparison must retain an unchanged refusal")
armor = 6
APR.command:SlashCmd("gear")
flush()
assert(bags.prompt and messages[#messages]:find(SEARCHING, 1, true), "The real gear command starts a useful scan")
inventory[8] = "item:8202:occupied"
bags:QueueScan("PLAYER_EQUIPMENT_CHANGED")
flush()
assert(not bags.prompt, "The starter policy never replaces occupied armor")
inventory[8] = nil
pendingEquipmentID = 8202
bags:QueueScan("PLAYER_EQUIPMENT_CHANGED")
flush()
assert(not bags.prompt, "An item ID without its loaded link is not an empty destination")
pendingEquipmentID = nil
armor, stamina, spellPower = 0, 0, 100
bags:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(not bags.prompt, "Unknown builds must not acquire speculative spell-power weights")
armor, stamina, spellPower = 0, 2, 0
bags:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(bags.prompt, "Certain stamina benefit can fill empty armor too")
armor, stamina = 10, -1
bags:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(not bags.prompt, "An armor gain cannot hide a stamina loss without a build")
armor, stamina, spellPower = 5, 0, -1
bags:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(not bags.prompt, "Even an unweighted negative stat prevents a conservative offer")
spellPower = 0
for _, loc in ipairs({ "INVTYPE_BODY", "INVTYPE_TABARD", "INVTYPE_TRINKET", "INVTYPE_HOLDABLE" }) do
    location = loc
    bags:QueueScan("BAG_UPDATE_DELAYED")
    flush()
    assert(not bags.prompt, "Non-armor destinations never use the conservative policy")
end
armor, stamina = 5, 0
location = "INVTYPE_WEAPON"
bags:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(not bags.prompt, "The conservative policy never proposes a weapon")
location, armor, stamina = "INVTYPE_FEET", 5, 0
assert(pawn:SetSelectedScale("pawn:ZeroArmor"))
flush()
assert(not bags.prompt, "An explicitly chosen zero-armor Pawn scale stays authoritative")
ready = false
APR.command:SlashCmd("gear")
flush()
assert(not bags.prompt and not messages[#messages]:find(SEARCHING, 1, true), "Pending explicit Pawn never falls back")
ready = true
assert(pawn:SetSelectedScale("apr"))
combat = true
APR.command:SlashCmd("gear")
flush()
assert(not bags.prompt and messages[#messages]:find(ERR_NOT_IN_COMBAT, 1, true))
combat = false
dead = true
APR.command:SlashCmd("gear")
assert(messages[#messages]:find(DEAD, 1, true))
dead = false
APR.settings.db.char.bagUpgradeSuggestions = false
APR.command:SlashCmd("gear")
assert(messages[#messages]:find(DISABLED, 1, true))
APR.settings.db.char.bagUpgradeSuggestions = true
interface = 999999
APR.command:SlashCmd("gear")
assert(messages[#messages]:find(UNAVAILABLE, 1, true), "Unknown client patches do not gain a fallback")
local count = #messages
bags:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(#messages == count, "Automatic scans stay silent")
APR.BagUpgrades = nil
APR.command:SlashCmd("gear")
assert(messages[#messages]:find(UNAVAILABLE, 1, true), "An absent module is reported by the real command")
print("Starter gear: no-build empty armor, explicit equip, events, refusal, Pawn choice and command feedback passed")
