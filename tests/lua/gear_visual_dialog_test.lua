-- Exercise real popup callbacks, disabled choices, recycling and constrained-screen layout.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local show, hide = env.methods.Show, env.methods.Hide
function env.methods:Show()
    local changed = not self:IsShown()
    show(self)
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function env.methods:Hide()
    local changed = self:IsShown()
    hide(self)
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function APR:SetTooltipText(_, text) GameTooltip.title = text end
function APR:AddTooltipLine(_, text) GameTooltip.description = text end
function APR:RegisterButtonText(button, group, options)
    self:RegisterFontString(button:GetFontString(), group, options)
end
UIParent:SetSize(1280, 720)
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/foundations/SelectionDialog.lua")
dofile("APR-Core/ui/route/QuestionPopUp.lua")

-- Exercise the real offer, private frame, recycled cells and native tooltip entry points.
local inventory = { [16] = "item:410:enchanted", [17] = "item:411:old" }
local bagLink = "item:412:new-variant"
CURRENTLY_EQUIPPED, EQUIP, EQUIPMENT, EMPTY, IGNORE = "Equipped", "Equip", "Equipment", "Empty", "Ignore"
MAINHANDSLOT, SECONDARYHANDSLOT = "Main hand", "Off hand"
LibStub = function() return { GetLocale = function() return { GEAR_UPGRADE_TITLE = "Gear upgrade",
    GEAR_UPGRADE_PROMPT = "Better gear?", CHOOSE_USABLE_GEAR_UPGRADE = "Compare" } end } end
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return { enableAddon = true } end
function APR:GetBagUpgradeSuggestions() return true end
function GetInventoryItemLink(_, slot) return inventory[slot] end
C_Container = { GetContainerItemLink = function() return bagLink end }
C_Item = { GetItemInfo = function(link) return nil, nil, nil, nil, nil, nil, nil, nil, nil, "icon:" .. link end }
APR.RewardScoring = { GetDefaultScale = function() return {} end }
APR.PawnRewards = { GetScorer = function() return nil, nil, "fixture" end,
    GetStatusText = function() return "APR: Fixture" end }
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:SetBagItem(bag, slot) self.bag, self.bagSlot = bag, slot; self.link = bagLink end
function GameTooltip:SetInventoryItem(_, slot) self.inventorySlot = slot; self.link = inventory[slot] end
function env.methods:SetTexture(texture) self.texture = texture end
function env.methods:SetRotation(radians) self.rotation = radians end
APR.Gamepad = {
    SetNavigationFlag = function(_, button, flag, value) button[flag] = value end,
    RegisterWindow = function(_, window) window.padRegistered = true end,
    Refresh = function() end,
    AdaptListRow = function() end,
}

dofile("APR-Core/features/player/BagUpgrades.lua")
local module = APR.BagUpgrades
module.active, module.dismissed = true, {}
local rescans, equips = 0, 0
function module:QueueScan() rescans = rescans + 1; self:CancelPrompt() end
function module:Equip() equips = equips + 1 end
function APR.RewardScoring:GetUpgrade() return 3, true, nil, "comparison" end
function module:RefusalIdentity() return "refusal" end
local function open(plan)
    local links = {}
    for slot = 1, 19 do links[slot] = inventory[slot] or "" end
    module:Offer({ link = bagLink, bag = 0, slot = 3, plan = plan,
        signature = table.concat(links, "\031"), scoringIdentity = "fixture", refusalIdentity = "refusal" })
    assert(module.dialog and module.dialog:IsShown())
    return module.dialog
end
local plan = { slot = 16, replacedSlots = {16, 17}, move = {from=16, to=17, link=inventory[16]} }
local frame = open(plan)
assert(frame == APRBagUpgradePopup and frame.acceptButton:GetText() == EQUIP and frame.cancelButton:GetText() == IGNORE)
assert(frame.padRegistered and frame.list.active[1].proposed.button.smartNavigationCanFocus,
    "Item details are reachable through the APR gamepad window")
assert(frame.description:GetText() == "Better gear?\nAPR: Fixture")
local first, second = frame.list.active[1], frame.list.active[2]
local _, currentParent, _, currentX = first.current:GetPoint()
local _, proposedParent, _, proposedX = first.proposed:GetPoint()
assert(currentParent == proposedParent and currentX + first.current:GetWidth() < proposedX,
    "Current equipment must appear entirely to the left of proposed gear")
-- The inspected APR asset points northeast before rotation. Check its resulting
-- direction rather than freezing a particular rotation constant.
local angle = first.arrow.rotation
assert(angle and math.cos(angle) - math.sin(angle) > 0
    and math.abs(math.sin(angle) + math.cos(angle)) < 0.000001,
    "The comparison arrow must point horizontally toward the proposed item on the right")
assert(first.proposed.button.item.link == bagLink and first.current.button.item.link == inventory[16])
assert(second.proposed.button.item.link == inventory[16] and second.current.button.item.link == inventory[17])
assert(first.proposed.button.icon.texture == "icon:" .. bagLink)
first.current.button.scripts.OnEnter(first.current.button)
assert(GameTooltip.inventorySlot == 16 and GameTooltip.link == inventory[16],
    "The left item keeps its native equipped source")
first.current.button.scripts.OnLeave(first.current.button)
first.proposed.button.scripts.OnEnter(first.proposed.button)
assert(GameTooltip:IsShown() and GameTooltip.bag == 0 and GameTooltip.bagSlot == 3 and GameTooltip.link == bagLink)
first.proposed.button.scripts.OnLeave(first.proposed.button)
assert(not GameTooltip:IsShown())
second.proposed.button.scripts.OnEnter(second.proposed.button)
assert(GameTooltip.inventorySlot == 16 and GameTooltip.link == inventory[16], "Moved objects retain their original native tooltip source")
module:CancelPrompt()
assert(not GameTooltip:IsShown() and not module.dismissed[bagLink])
assert(not second.proposed.button.item and not second.proposed.button.icon.texture)
first.proposed.button.scripts.OnEnter(first.proposed.button)
assert(not GameTooltip:IsShown(), "Closed cells cannot expose recycled links")
frame = open({slot=16, replacedSlots={16,17}})
second = frame.list.active[2]
assert(not second.proposed.button.item and not second.proposed.button.icon.texture, "Removed gear is an empty square")
assert(not second.proposed.button.smartNavigationCanFocus, "Empty squares do not capture gamepad focus")
second.proposed.button.scripts.OnEnter(second.proposed.button)
assert(not GameTooltip:IsShown())
first = frame.list.active[1]
local snapshot = bagLink
bagLink = "item:413:changed"
first.proposed.button.scripts.OnEnter(first.proposed.button)
assert(not GameTooltip:IsShown(), "A stale bag location never shows a different variant")
bagLink = snapshot
first.current.button.scripts.OnEnter(first.current.button)
assert(GameTooltip.link == inventory[16])
local original = inventory[16]
local secret = {}
function issecretvalue(value) return value == secret end
inventory[16] = secret
first.current.button.scripts.OnEnter(first.current.button)
assert(not GameTooltip:IsShown(), "An opaque live link also clears an already-owned tooltip")
inventory[16] = original
frame.close.scripts.OnClick()
assert(module.dismissed[bagLink] == "refusal" and not GameTooltip:IsShown() and equips == 0)
frame = open(plan)
frame.acceptButton.scripts.OnClick()
assert(equips == 1 and not frame:IsShown() and not GameTooltip:IsShown())
-- Simulated geometry: wrapping and viewport bounds, not a claim about native glyph rendering.
UIParent:SetSize(800, 480)
MAINHANDSLOT = string.rep("Long slot ", 15)
bagLink = "|Hitem:414|h[" .. string.rep("Long equipment name ", 18) .. "]|h"
frame = open({slot=16, replacedSlots={16,17}})
assert(frame:GetHeight() <= UIParent:GetHeight() - 38)
assert(frame.list.height > frame.scroll:GetHeight() and frame.scroll.ScrollBar:IsShown())
first = frame.list.active[1]
assert(first.proposed.name:GetWidth() > 0 and first.current.name:GetWidth() > 0)
assert(first:GetHeight() >= first.proposed:GetHeight() + first.slot:GetStringHeight() + 16)
local _, _, _, _, proposedY = first.proposed.button:GetPoint()
local _, _, _, _, currentY = first.current.button:GetPoint()
assert(proposedY == currentY, "Unequal translated headings keep both item icons aligned")
frame:Hide()
-- Reopening a short offer uses the existing row controls and replaces every link.
bagLink = "item:415:short"
MAINHANDSLOT = "Main hand"
frame = open({slot=16, replacedSlots={16,17}})
frame:Hide()
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 12 do open(plan):Hide() end
assert(env.frames() == frames and env.fonts() == fonts, "Comparison cells are pooled across offers")
print("Gear visual dialog: real offer, both hands, exact native sources, blank removal, recycling, stale locations, explicit actions and bounded layout")
