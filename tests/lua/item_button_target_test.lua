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
print("Item targets: identity, secure attributes, combat deferral and pooled cleanup passed")
