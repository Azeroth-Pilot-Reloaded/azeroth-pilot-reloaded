local env = dofile("tests/lua/route_ui_test_env.lua")
local step = APR.currentStep
step.UpdateStepButtonCooldowns = function() end
step.UpdateStepButtonUsability = function() end
step:AddQuestSteps(1, "Use the synthetic item", 1)
local row = step.questsList["1-1"]

step:AddStepButton("1-1", 50, "item", nil, "player")
assert(row.IconButton.attributes.unit == "player")
assert(row.IconButton.attributes.item == "item:50" and row.IconButton.attributes.type1 == "item")
local button = row.IconButton
step:AddStepButton("1-1", 50, "item", nil, "player")
assert(row.IconButton == button, "An unchanged targeted action reuses its button")
step:AddStepButton("1-1", 50, "item")
assert(row.IconButton.attributes.unit == nil, "A pooled button must not retain self targeting")

env.setCombat(true)
step:AddStepButton("1-1", 50, "item", nil, "player")
assert(row.IconButton.attributes.unit == nil, "Combat cannot mutate secure target attributes")
env.setCombat(false)
step:ProcessPendingStepButtons()
assert(row.IconButton.attributes.unit == "player", "Deferred requests retain their explicit target")
step:AddStepButton("1-1", 50, "item")
assert(row.IconButton.attributes.unit == nil)

-- A learned toy has no bag copy; explicit targeting must still use the toy box.
function PlayerHasToy(id) return id == 51 end
function C_Item.GetItemCount() return 0 end
step:AddStepButton("1-1", 51, "item")
assert(row.IconButton == button)
assert(button.attributes.type1 == "toy" and button.attributes.toy == 51)
assert(button.attributes.item == nil and button.attributes.unit == nil)

env.setCombat(true)
step:AddStepButton("1-1", 51, "item", nil, "player")
assert(
    button.attributes.type1 == "toy" and button.attributes.macrotext == nil,
    "A targeted toy request must not mutate its secure button in combat"
)
env.setCombat(false)
step:ProcessPendingStepButtons()
assert(row.IconButton == button)
assert(
    button.attributes.type1 == "macro" and button.attributes.macrotext == "/use [@player] item:51",
    "A learned toy with an explicit target needs a targeted use macro"
)
assert(
    button.attributes.toy == nil and button.attributes.item == nil and button.attributes.unit == nil,
    "The targeted toy must not retain attributes from earlier actions"
)
assert(
    button.attribute == "item" and button.itemID == 51 and button.itemTarget == "player",
    "Targeted toys retain their item identity for tooltips, usability and cooldowns"
)
step:AddStepButton("1-1", 51, "item", nil, "player")
assert(row.IconButton == button and button.attributes.macrotext == "/use [@player] item:51")

step:AddStepButton("1-1", 51, "item")
assert(button.attributes.type1 == "toy" and button.attributes.toy == 51)
assert(
    button.attributes.macrotext == nil and button.attributes.unit == nil,
    "Removing a toy target clears its macro when the pooled button is reused"
)
step:AddStepButton("1-1", 50, "item", nil, "player")
assert(button.attributes.type1 == "item" and button.attributes.item == "item:50")
assert(
    button.attributes.unit == "player" and button.attributes.toy == nil and button.attributes.macrotext == nil,
    "An ordinary item keeps native targeting without stale toy attributes"
)

step:AddStepButton("1-1", 51, "item", 16, "player")
assert(
    button.attributes.type1 == "macro" and button.attributes.macrotext == "/equipslot [nocombat] 16 item:51",
    "An explicit equipment slot still takes precedence over toy use"
)
PlayerHasToy = nil
step:AddStepButton("1-1", 51, "item", nil, "player")
assert(button.attributes.type1 == "item" and button.attributes.item == "item:51")
assert(
    button.attributes.unit == "player" and button.attributes.macrotext == nil,
    "Clients without toy support retain ordinary item targeting"
)
print("Item targets: items, learned toys, combat deferral, equipment and pooled cleanup passed")
