-- Exercise registration and recycling through the real renderer, not just pad fixtures.
local fixture = dofile("tests/lua/gamepad_test.lua")
local pad, step, selectAction = fixture.pad, APR.currentStep, fixture.selectAction
local profile = APR.settings.profile
profile.currentStepShow, profile.currentStepbackgroundColorAlpha = true, {0, 0, 0, 1}
step.UpdateStepButtonCooldowns, step.UpdateStepButtonUsability = function() end, function() end
step:PreviousNextStepButton()
local function render(first, second)
    step:BeginContentUpdate()
    step:Reset()
    step:PrepareRaidIcon({RaidIcon = 42})
    -- Deliberately create bottom row first.
    step:AddQuestSteps(20, "Second action", 1)
    step:AddStepButton("20-1", second, "item")
    step:AddQuestSteps(10, "First action", 1)
    step:AddStepButton("10-1", first, "item")
    step:EndContentUpdate(true)
end
render(100, 200)
local row = step.questsList["10-1"]
assert(row.layoutOffset < step.questsList["20-1"].layoutOffset)
assert(selectAction(pad.itemProxy) == "item" and pad.itemProxy:GetAttribute("item") == "item:100")
assert(step.questsList["20-1"].RaidIconButton, "Targeting shares a row with an action")
assert(selectAction(pad.targetProxy) == "macro" and pad.targetProxy:GetAttribute("macrotext") == "/target NPC")
local registered = #pad.actionButtons
for _ = 1, 20 do render(101, 201) end
assert(#pad.actionButtons == registered, "Pooled buttons must never accumulate duplicate refs")
assert(pad.itemProxy:GetAttribute("item") == "item:100", "Payloads are resolved on the hardware click")
assert(selectAction(pad.itemProxy) == "item" and pad.itemProxy:GetAttribute("item") == "item:101")
step:ReleaseRow(step.questsList, "10-1")
assert(selectAction(pad.itemProxy) == "item" and pad.itemProxy:GetAttribute("item") == "item:201")
step:ReleaseRow(step.questsList, "20-1")
assert(selectAction(pad.itemProxy) == nil and selectAction(pad.targetProxy) == nil)
step:PrepareRaidIcon({})
step:AddQuestSteps(5, "Replacement", 1)
step:AddStepButton("5-1", 500, "item")
assert(#pad.actionButtons == registered, "Recycled row controls retain their refs")
assert(selectAction(pad.itemProxy) == "item" and pad.itemProxy:GetAttribute("item") == "item:500")
assert(selectAction(pad.targetProxy) == nil, "A pooled target must not leak into a step without targeting")
print("Quest action bindings: real rendering, visible priority, targeting, pooling and empty steps passed")
