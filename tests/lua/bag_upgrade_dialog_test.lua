local inventory, private, shown, combat = {}, false, nil, false
local identity, status = "confirmed", "APR: Invented tank"
local scale = {}
CURRENTLY_EQUIPPED, EQUIP, EQUIPMENT, EMPTY, SCORE = "Equipped", "Equip", "Equipment", "Empty", "Score"
MAINHANDSLOT, SECONDARYHANDSLOT, HEADSLOT = "Main hand", "Off hand", "Head"
FINGER0SLOT, FINGER1SLOT = "Finger", "Finger"
ACCEPT, CANCEL, IGNORE = "Accept", "Cancel", "Ignore"
LibStub = function()
    return { GetLocale = function() return { CHOOSE_USABLE_GEAR_UPGRADE = "Compare equipment" } end }
end
APR = { Gamepad = { IsAvailable = function() return private end }, UI = {}, questionDialog = {},
    PawnRewards = {}, RewardScoring = {} }
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return { enableAddon = true } end
function APR:GetBagUpgradeSuggestions() return true end
function APR.PawnRewards:GetScorer() return scale.score, nil, identity end
function APR.PawnRewards:GetStatusText() return status end
function APR.RewardScoring:GetDefaultScale() return scale end
function GetInventoryItemLink(_, slot) return inventory[slot] end
function InCombatLockdown() return combat end
function StaticPopup_Visible() return shown end
function APR.questionDialog:CreateQuestionPopup(_, text, accept, cancel)
    shown = { text = text, accept = accept, cancel = cancel }
end
function APR.UI:ShowConfirmationDialog(settings, accept, cancel)
    shown = { text = settings.description, accept = accept, cancel = cancel, IsShown = function() return true end }
    return shown
end
dofile("APR-Core/features/player/BagUpgrades.lua")
local module = APR.BagUpgrades
module.active, module.dismissed = true, {}
local rescans = 0
function module:QueueScan() rescans = rescans + 1 end
local function offer(plan, gain)
    local links = {}
    for slot = 1, 19 do links[slot] = inventory[slot] or "" end
    local candidate = { link = "item:901:new", plan = plan, gain = gain or 7,
        scoringIdentity = identity, signature = table.concat(links, "\031") }
    shown = nil
    module:Offer(candidate)
    return shown and shown.text, candidate
end
local function contains(text, value)
    assert(text and text:find(value, 1, true), "Missing dialog content: " .. value)
end
for _, usePrivate in ipairs({ false, true }) do
    private = usePrivate
    inventory = { [16] = "item:902:retained", [17] = "item:903:removed" }
    local plan = { slot = 16, replacedSlots = { 17 },
        move = { from = 16, to = 17, link = inventory[16] } }
    local text = offer(plan)
    contains(text, "Equipped:\nMain hand: item:902:retained\nOff hand: item:903:removed")
    contains(text, "Equip:\nMain hand: item:901:new\nOff hand: item:902:retained")
    contains(text, "APR: Invented tank")
    contains(text, "Score: +7")
    assert(not text:find("%%"), "A loadout delta must not use the replaced-items baseline as a percentage")

    plan = { slot = 17, replacedSlots = { 16 }, move = { from = 17, to = 16, link = inventory[17] } }
    text = offer(plan)
    contains(text, "Equip:\nMain hand: item:903:removed\nOff hand: item:901:new")

    text = offer({ slot = 16, replacedSlots = { 16, 17 } })
    contains(text, "Equip:\nMain hand: item:901:new\nOff hand: Empty")
    text = offer({ slot = 17, replacedSlots = { 17 } })
    contains(text, "Equip:\nMain hand: item:902:retained\nOff hand: item:901:new")

    inventory = {}
    text = offer({ slot = 1, replacedSlots = { 1 } })
    contains(text, "Equipped:\nHead: Empty")
    contains(text, "Equip:\nHead: item:901:new")
    inventory = { [12] = "item:904:old-ring" }
    text = offer({ slot = 12, replacedSlots = { 12 } })
    contains(text, "Equipped:\nFinger 2: item:904:old-ring")
    contains(text, "Equip:\nFinger 2: item:901:new")
    status = "Pawn: Invented healer"
    scale.score = function() return 1, true end
    text = offer({ slot = 1, replacedSlots = { 1 } })
    contains(text, "Pawn: Invented healer")
    assert(not text:find("APR:", 1, true))
    for _, gain in ipairs({ 0, -1, math.huge, 0/0 }) do
        text = offer({ slot = 1, replacedSlots = { 1 } }, gain)
        assert(not text:find("Score:", 1, true), "Unavailable/nonpositive scores have no displayed gain")
    end

    -- A missing scoring label cannot lend meaning to an arbitrary numeric delta.
    status = nil
    text = offer({ slot = 1, replacedSlots = { 1 } })
    assert(not text:find("Score:", 1, true))
    status, scale.score = "APR: Invented tank", nil
    combat = true
    assert(offer({ slot = 1, replacedSlots = { 1 } }) == nil)
    combat = false

    local ordinaryStatus = APR.PawnRewards.GetStatusText
    function APR.PawnRewards:GetStatusText()
        identity = identity .. ":changed"
        return status
    end
    local before = rescans
    assert(offer({ slot = 1, replacedSlots = { 1 } }) == nil and rescans == before + 1,
        "A changed scoring context withdraws the offer before publishing its gain")
    APR.PawnRewards.GetStatusText = ordinaryStatus
end
print("Bag dialog: both confirmation paths show complete hand configurations, empty slots, active profiles and scoped score gains")
