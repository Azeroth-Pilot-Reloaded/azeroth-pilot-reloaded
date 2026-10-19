local L = {
    ACTION_ITEM_MISSING = "Item missing", ACTION_SPELL_UNKNOWN = "Spell not learned",
    ACTION_COOLDOWN = "On cooldown", ACTION_AVAILABLE_IN = "Available in %s",
}
function LibStub() return { GetLocale = function() return L end } end
local secret = setmetatable({}, { __tostring = function() error("Formatted a secret") end,
    __lt = function() error("Compared a secret") end, __le = function() error("Compared a secret") end })
APR = { CanAccessValue = function(_, value) return not rawequal(value, secret) end }
dofile("APR-Core/utils/PlayerUtils.lua")
local reason
function APR:GetRouteActionUsability(_, _, ignoreCooldown)
    assert(ignoreCooldown, "Availability checks must not inspect numeric cooldowns before accessibility guards")
    return reason == nil, reason
end
local cooldown = { startTime = 100, duration = 200, isEnabled = true, isActive = true }
C_Spell = { GetSpellCooldown = function() return cooldown end }
C_Item = { GetItemCooldown = function() return cooldown.startTime, cooldown.duration, cooldown.isEnabled end }
local now = 120
function GetTime() return now end
assert(APR:GetActionAvailabilityText("item", 1) == "On cooldown")
assert(APR:GetActionAvailabilityText("spell", 1, true) == "Available in 3:00")
now = 121
assert(APR:GetActionAvailabilityText("item", 1, true) == "Available in 2:59", "Hover reads fresh time")
reason = "missing"
assert(APR:GetActionAvailabilityText("item", 1) == "Item missing")
reason = "unknown"
assert(APR:GetActionAvailabilityText("spell", 1) == "Spell not learned")
reason = nil
cooldown.startTime = secret
assert(APR:GetActionAvailabilityText("spell", 1, true) == "On cooldown")
assert(APR:GetActionAvailabilityText("item", 1, true) == nil, "Restricted timing alone does not prove an active cooldown")
cooldown.isActive = false
assert(APR:GetActionAvailabilityText("spell", 1, true) == nil, "The public inactive flag takes precedence over secret timing")
cooldown.isActive = true
cooldown.startTime, cooldown.duration = 100, secret
assert(APR:GetActionAvailabilityText("spell", 1, true) == "On cooldown")
cooldown.duration = 1.5
assert(APR:GetActionAvailabilityText("spell", 1) == nil, "Global cooldown should not rewrite the instruction")
cooldown.duration, now = 200, 301
assert(APR:GetActionAvailabilityText("spell", 1) == nil, "Expired cooldown disappears")
now, cooldown.isActive = 120, false
assert(APR:GetActionAvailabilityText("spell", 1) == nil)
cooldown.isActive, cooldown.isEnabled = true, false
assert(APR:GetActionAvailabilityText("item", 1) == nil)
C_Spell.GetSpellCooldown = nil
assert(APR:GetActionAvailabilityText("spell", 1) == nil)

-- Real row/button updates: state changes preserve the instruction, button and
-- action attributes, and repeated events avoid unnecessary layout work.
local env = dofile("tests/lua/route_ui_test_env.lua")
local status = "Item missing"
function APR:GetActionAvailabilityText() return status end
local step = APR.currentStep
step:BeginContentUpdate()
step:AddQuestSteps("ITEM_1", "Use item", "UseItem", false, true)
step:AddStepButton("ITEM_1-UseItem", 1, "item")
step:EndContentUpdate(true)
local row = step.questsList["ITEM_1-UseItem"]
local button = row.IconButton
assert(row.font:GetText():find("Use item\nItem missing", 1, true))
assert(row.objectiveText == "Use item" and button.attributes.item == "item:1")
local layouts = env.layouts()
for _ = 1, 20 do step:UpdateStepButtonUsability() end
assert(env.layouts() == layouts, "Unchanged availability must not relayout the guide")
status = "On cooldown"
step:UpdateStepButtonUsability()
assert(row.font:GetText():find("Use item\nOn cooldown", 1, true))
status = nil
step:UpdateStepButtonUsability()
assert(not row.font:GetText():find("cooldown") and row.objectiveText == "Use item")
assert(row.IconButton == button and button.attributes.item == "item:1")
print("Action availability: missing/unknown, cooldown expiry, secret timing, live row refresh and stable buttons passed")
