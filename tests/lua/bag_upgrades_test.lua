local timers, inventory, bags, items, equips, prompts, hooks = {}, {}, {}, {}, {}, {}, {}
local combat, cursor, locked, missingInfo = false, false, false, false
local profile = { enableAddon = true, bagUpgradeSuggestions = true }
local secret = {}
EQUIP, ACCEPT, IGNORE, CANCEL, CURRENTLY_EQUIPPED, EQUIPMENT, EMPTY =
    "Equip", "Accept", "Ignore", "Cancel", "Equipped", "Equipment", "Empty"
NUM_BAG_SLOTS = 1
LibStub = function()
    return { GetLocale = function() return { CHOOSE_USABLE_GEAR_UPGRADE = "Compare equipment" } end }
end
APR = { questionDialog = {}, RewardScoring = {}, PawnRewards = {} }
APR.settings = { db = { char = { bagUpgradeSuggestions = true } } }
dofile("APR-Core/utils/ProfileUtils.lua")
function APR:GetSettingsProfile() return profile end
function APR:NewModule()
    return {
        events = {},
        RegisterEvent = function(self, e, m) self.events[e] = m end,
        UnregisterEvent = function(self, e) self.events[e] = nil end,
        UnregisterAllEvents = function(self) self.events = {} end,
    }
end
C_Timer = {
    NewTimer = function(delay, fn)
        local t = { delay = delay, fn = fn, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = t
        return t
    end,
}
local function flush()
    local budget = 200
    while #timers > 0 do
        budget = budget - 1
        assert(budget > 0, "Timers must terminate")
        local t = table.remove(timers, 1)
        if not t.cancelled then t.fn() end
    end
end
function GetInventoryItemLink(_, slot) return inventory[slot] end
function InCombatLockdown() return combat end
function CursorHasItem() return cursor end
function issecretvalue(v) return v == secret end
local requests, custom, scoringState, scoringIdentity = {}, nil, nil, "initial"
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 20 or 0 end,
    GetContainerItemLink = function(bag, slot) return bag == 0 and bags[slot] end,
    GetContainerItemInfo = function()
        if not missingInfo then return { isLocked = locked } end
    end,
}
C_Item = {
    RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end,
    EquipItemByName = function(link, slot)
        assert(not combat and not cursor)
        equips[#equips + 1] = { link, slot }
        for from, old in pairs(inventory) do
            if old == link then
                inventory[from] = nil
                break
            end
        end
        inventory[slot] = link
        for s, old in pairs(bags) do
            if old == link then
                bags[s] = nil
                break
            end
        end
    end,
}
function APR.RewardScoring:GetDefaultScale() return { name = "default" } end
function APR.PawnRewards:GetScorer() return custom, scoringState, scoringIdentity end
function APR.RewardScoring:GetUpgrade(link, scale)
    assert(scale and (scale.name == "default" or scale.score == custom))
    local item = items[link]
    if not item then return nil, true end
    if item.pending then return nil, false end
    if inventory[item.slot or 1] == link then return 0, true end
    return item.gain,
        true,
        { slot = item.slot or 1, replacedSlots = { item.replaced or item.slot or 1 }, move = item.move,
            steps = item.move and { { link = item.move.link, slot = item.move.to }, { link = link, slot = item.slot } },
            intermediate = item.move and { [item.move.from] = false, [item.move.to] = item.move.link },
        },
        tostring(item.gain) .. ":" .. (inventory[item.slot or 1] or "")
end
local visible, inPopupCallback
function StaticPopup_Visible() return visible end
function StaticPopup_Hide()
    assert(not inPopupCallback, "APR must leave accepted/cancelled popup teardown to Blizzard")
    if visible then
        visible = nil
        if hooks.hide then hooks.hide() end
    end
end
function StaticPopup_OnHide() end
function hooksecurefunc(_, fn) hooks.hide = fn end
function APR.questionDialog:CreateQuestionPopup(_, text, accept, cancel)
    local popup = { text = text }
    local function click(callback, ...)
        inPopupCallback = true
        callback(...)
        inPopupCallback = false
        -- Model StaticPopup_OnClick: the native owner hides after the callback.
        -- A stale callback must never close a newer offer.
        if visible == popup then
            visible = nil
            if hooks.hide then hooks.hide() end
        end
    end
    popup.accept = function(...) click(accept, ...) end
    popup.cancel = function(...) click(cancel, ...) end
    visible = popup
    prompts[#prompts + 1] = visible
end
dofile("APR-Core/features/player/BagUpgrades.lua")
local module = APR.BagUpgrades
module:OnEnable()
local weak, strong = "item:501:weak", "item:502:strong"
items[weak], items[strong] = { gain = 2 }, { gain = 8, slot = 11 }
bags[3], bags[18] = weak, strong
module:QueueScan("BAG_UPDATE_DELAYED")
module:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(#equips == 0 and #prompts == 1 and visible.text:find(strong, 1, true))
local saved = visible
bags[18], bags[19] = nil, strong
saved.accept()
flush()
assert(#equips == 0 and visible.text:find(strong, 1, true), "A moved bag item invalidates the old action")
locked = true
visible.accept()
flush()
assert(#equips == 0)
locked = false
module:QueueScan()
flush()
missingInfo = true
visible.accept()
flush()
assert(#equips == 0)
missingInfo = false
module:QueueScan()
flush()
visible.cancel({}, nil, "clicked")
flush()
assert(visible.text:find(weak, 1, true), "Ignoring one item advances to the next")
local count = #prompts
visible.cancel({}, nil, "escape")
flush()
module:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(#prompts == count, "Dismissed links survive unrelated bag events")
custom = function() return 1, true end
scoringIdentity = "custom-1"
module:OnScoringChanged()
flush()
assert(visible.text:find(strong, 1, true))
combat = true
visible.accept()
flush()
assert(#equips == 0)
module:QueueScan("PLAYER_REGEN_DISABLED")
flush()
combat = false
module:QueueScan("PLAYER_REGEN_ENABLED")
flush()
assert(#equips == 0, "Leaving combat never equips")
cursor = true
visible.accept()
flush()
assert(#equips == 0)
cursor = false
module:QueueScan()
flush()
visible.accept()
flush()
assert(#equips == 1 and equips[1][1] == strong and equips[1][2] == 11)
local withdrawn = visible
APR:SetBagUpgradeSuggestions(false)
flush()
withdrawn.accept()
assert(
    #equips == 1 and next(module.events) == nil and not visible and not module:IsEnabledForCharacter(),
    "A character opt-out cancels offers and listeners even while the shared profile is enabled"
)
APR:SetBagUpgradeSuggestions(true)
flush()
assert(module:IsEnabledForCharacter() and next(module.events) ~= nil and visible)
profile.bagUpgradeSuggestions = false
assert(module:IsEnabledForCharacter(), "An enabled character must ignore the legacy profile preference")
profile.bagUpgradeSuggestions = true
local stale = visible
profile.enableAddon = false
module:RefreshSettings()
flush()
stale.accept()
assert(#equips == 1 and next(module.events) == nil and not visible)
profile.enableAddon = true
bags, inventory = { [1] = "item:503:pending", [2] = secret }, {}
items[bags[1]] = { pending = true, gain = 10 }
module:OnEnable()
flush()
assert(requests[503] == 2 and #timers == 0, "Missing data has bounded retries")
items[bags[1]].pending = false
module:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(visible.text:find("item:503:pending", 1, true))
module:QueueScan()
local oldTimer = module.timer
module:OnDisable()
oldTimer.fn()
flush()
assert(not visible and #equips == 1 and not module.job)
local retained, candidate = "item:504:retained", "item:505:main-only"
inventory, bags = { [16] = retained, [17] = "item:506:old" }, { [1] = candidate }
items[candidate] = { gain = 7, slot = 16, replaced = 17, move = { from = 16, to = 17, link = retained } }
module:OnEnable()
flush()
visible.accept()
flush()
assert(equips[2][1] == retained and equips[2][2] == 17 and equips[3][1] == candidate and equips[3][2] == 16)
assert(inventory[17] == retained and inventory[16] == candidate)
-- Cached item events can arrive synchronously inside the load request.
inventory, bags = {}, { [1] = "item:507:synchronous" }
items[bags[1]] = { gain = 4, pending = true }
C_Item.RequestLoadItemDataByID = function(id)
    assert(id == 507)
    items[bags[1]].pending = false
    module:OnItemData("ITEM_DATA_LOAD_RESULT", id, true)
end
module:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(visible and visible.text:find("item:507:synchronous", 1, true) and not module.timer)
-- Native gamepad popups must not initialize/cache Blizzard's shared bindings
-- from an addon-owned dialog definition. Use an independent APR confirmation.
module:OnDisable()
local padEnabled, privateDialog = true, nil
APR.Gamepad = { IsAvailable = function() return true end, IsEnabled = function() return padEnabled end }
APR.UI = { ShowConfirmationDialog = function(_, settings, accept, cancel)
    local dialog = { shown = true, text = settings.description, accept = accept, cancel = cancel }
    function dialog:IsShown() return self.shown end
    function dialog:Hide()
        if not self.shown then return end
        self.shown = false
        local callback = self.cancel
        self.cancel = nil
        if callback then callback() end
    end
    function dialog:Accept()
        local callback = self.accept
        self.cancel = nil
        self:Hide()
        callback()
    end
    privateDialog = dialog
    return dialog
end }
StaticPopup_Visible = function() error("Gamepad offers must not query a shared native popup") end
StaticPopup_Hide = function() error("Gamepad offers must not close a shared native popup") end
APR.questionDialog.CreateQuestionPopup = function() error("Gamepad offers must not enter StaticPopup_Show") end
local upgrade = "item:601:pad-upgrade"
inventory, bags = {}, { [1] = upgrade }
items[upgrade] = { gain = 6, slot = 11 }
module:OnEnable()
flush()
assert(privateDialog:IsShown() and module.dialog == privateDialog and privateDialog.text:find(upgrade, 1, true))
local withdrawn = privateDialog
local equippedBefore = #equips
module:QueueScan("BAG_UPDATE_DELAYED")
assert(not withdrawn:IsShown() and not module.dismissed[upgrade], "Withdrawing a stale offer does not ignore the item")
withdrawn.accept()
assert(#equips == equippedBefore, "An obsolete private confirmation cannot equip")
flush()
privateDialog:Hide()
flush()
assert(module.dismissed[upgrade] and #equips == equippedBefore, "Back/Ignore dismisses without equipping")
scoringIdentity = "custom-2"
module:OnScoringChanged()
flush()
combat = true
module:QueueScan("PLAYER_REGEN_DISABLED")
flush()
assert(not privateDialog:IsShown() and #equips == equippedBefore)
combat = false
module:QueueScan("PLAYER_REGEN_ENABLED")
flush()
assert(privateDialog:IsShown() and #equips == equippedBefore, "Combat recovery only offers equipment")
privateDialog:Accept()
flush()
assert(#equips == equippedBefore + 1 and equips[#equips][1] == upgrade and equips[#equips][2] == 11)
inventory, bags = {}, { [1] = upgrade }
module:QueueScan("BAG_UPDATE_DELAYED")
flush()
padEnabled = false
module:QueueScan("BAG_UPDATE_DELAYED")
flush()
assert(privateDialog:IsShown(), "Mouse mode on a native gamepad client also avoids StaticPopup adoption")
module:OnDisable()
assert(not privateDialog:IsShown() and not module.dialog, "Input-mode changes still withdraw the private offer")
print(
    "Bag suggestions: bounded scans/retries, Pawn, dismissals, stale bags/timers, missing/locked/secret data, combat/cursor/profile guards and explicit equipment plans passed"
)

-- Open confirmations and sliced scans retain the scoring decision they displayed.
inventory, bags = {}, { [1] = upgrade }
module:OnEnable()
flush()
local oldOffer, before = privateDialog, #equips
custom, scoringState = nil, "pending"
oldOffer:Accept()
flush()
assert(#equips == before and not privateDialog:IsShown(),
    "A Pawn offer cannot equip via APR when the selected provider becomes unavailable")
assert(not module.job and not module.timer, "Pending providers cannot start fallback scans or retry forever")
custom, scoringState, scoringIdentity = function() return 1, true end, "pawn", "confirmed-v1"
module:OnScoringChanged()
flush()
assert(privateDialog:IsShown(), "The returned provider can offer an upgrade again")
oldOffer = privateDialog
scoringIdentity = "confirmed-v2"
oldOffer:Accept()
flush()
assert(#equips == before, "A confirmation for old weights cannot equip with newly confirmed weights")
privateDialog:Accept()
flush()
assert(#equips == before + 1, "A fresh confirmation uses the current weights")
inventory, bags = {}, { [1] = upgrade }
module:QueueScan()
-- Start a multi-slice scan, then suspend its provider before publication.
local start = table.remove(timers, 1)
start.fn()
custom, scoringState = nil, "pending"
flush()
assert(not privateDialog:IsShown() and not module.job,
    "A partial scan cannot publish an offer after its provider disappears")
scoringState, scoringIdentity = "apr", "apr"
module:OnScoringChanged()
flush()
assert(privateDialog:IsShown(), "An explicit APR choice still permits default suggestions")
module:OnDisable()
