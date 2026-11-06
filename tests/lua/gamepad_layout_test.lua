-- Exercise actual preview selection and movement through the input dispatcher.
local fixture = dofile("tests/lua/gamepad_interface_test.lua")
local env, pad, tick = fixture.env, fixture.pad, fixture.tick
pad.menu:Hide()
SAVE, PREVIEW = "Save", "Preview"
local oldLeft, oldTop, oldPoint = env.methods.GetLeft, env.methods.GetTop, env.methods.SetPoint
function env.methods:GetLeft() return self.layoutLeft or (oldLeft and oldLeft(self)) or 100 end
function env.methods:GetTop() return self.layoutTop or (oldTop and oldTop(self)) or 600 end
function env.methods:SetPoint(point, relative, relativePoint, x, y)
    oldPoint(self, point, relative, relativePoint, x, y)
    if point == "TOPLEFT" and relative == UIParent and relativePoint == "BOTTOMLEFT" then
        self.layoutLeft, self.layoutTop = x, y
    end
end
APR.currentStep.RefreshCurrentStepFrameAnchor = function() end
APR.fillersFrame = { RefreshFillersFrame = function() end }
APR.AFK = { RefreshFrameAnchor = function() end }
APR.questOrderList = { RefreshFrameAnchor = function() end }
local profile = APR.settings.profile
profile.currentStepFrame = { x = 11, y = -22, point = "TOPLEFT", scale = 1 }
profile.fillersFrameSnapToCurrentStep = true
dofile("APR-Core/ui/panels/LayoutEditor.lua")
local editor = APR.LayoutEditor
assert(editor:Show())
tick()
assert(editor.controllerEditing and editor.selectedPreview == 1)
assert(
    SmartNavigation:GetCurrentButton() == editor.previews[1],
    "The actual selected preview receives native focus, including outside the toolbar's parent tree"
)
assert(pad.windows[editor.frame].extraPanels == editor.previews)
local root = editor.previews[1]
assert(
    root.focusBorder:IsShown() and editor.previews[2].focusBorder:IsShown(),
    "The selected window and its linked group must be visually identifiable"
)
local left, top = root:GetLeft(), root:GetTop()
pad:DispatchInput(editor.frame, "PADDRIGHT", true)
pad:DispatchInput(editor.frame, "PADDRIGHT", false)
assert(
    root:GetLeft() == left + 10 / root:GetScale() and profile.currentStepFrame.x == 11,
    "D-pad movement edits the preview without publishing saved positions"
)
pad:DispatchInput(editor.frame, "PADRTRIGGER", true)
tick()
assert(editor.selectedPreview == 2 and SmartNavigation:GetCurrentButton() == editor.previews[2])
left = root:GetLeft()
pad:DispatchInput(editor.frame, "PADDLEFT", true)
pad:DispatchInput(editor.frame, "PADDLEFT", false)
assert(root:GetLeft() == left - 10 / root:GetScale(), "A linked window still moves its shared draft root")
pad:DispatchInput(editor.frame, "PADLTRIGGER", true)
tick()
assert(editor.selectedPreview == 1)
assert(editor:ControllerStick("Camera", 1, 1) == true)
editor:ControllerStick("Movement", 0.1, 0.1)
assert(not editor.moveDriver:IsShown(), "Stick noise below the dead zone must not move a window")
editor:ControllerStick("Movement", 0.5, 0)
assert(editor.moveDriver:IsShown())
left = root:GetLeft()
editor.moveDriver:GetScript("OnUpdate")(editor.moveDriver, 0.05)
assert(math.abs(root:GetLeft() - left - 5.5 / root:GetScale()) < 0.0001)
editor:ControllerStick("Movement", 0, 0)
assert(not editor.moveDriver:IsShown(), "Centering the stick removes the movement update loop")
pad:DispatchInput(editor.frame, "PAD1", true)
tick()
assert(editor.selectedPreview == 2, "Confirm validates the current draft and selects the next window")
pad:DispatchInput(editor.frame, "PAD2", true)
tick()
assert(not editor.controllerEditing and SmartNavigation:GetCurrentButton() == editor.previewSelector)
left = root:GetLeft()
pad:DispatchInput(editor.frame, "PADDRIGHT", true)
assert(root:GetLeft() == left, "D-pad input returns to native toolbar navigation outside placement mode")
pad:DispatchInput(editor.frame, "PADRTRIGGER", true)
tick()
assert(editor.controllerEditing and editor.selectedPreview == 3)
editor:SelectPreview(#editor.previews, true)
tick()
pad:DispatchInput(editor.frame, "PAD1", true)
tick()
assert(
    not editor.controllerEditing and SmartNavigation:GetCurrentButton() == editor.saveButton,
    "The last confirmation reaches Save instead of silently applying every position"
)
assert(profile.currentStepFrame.x == 11)
editor.saveButton:GetScript("OnClick")(editor.saveButton)
assert(not editor.active and profile.currentStepFrame.x ~= 11)
local savedX = profile.currentStepFrame.x
editor:Show()
tick()
pad:DispatchInput(editor.frame, "PADDRIGHT", true)
editor:Hide(false)
assert(profile.currentStepFrame.x == savedX and not editor.moveDriver:IsShown(), "Cancel discards the moved draft")
editor:Show()
tick()
editor:ControllerStick("Movement", 1, 0)
env.setCombat(true)
editor.frame:GetScript("OnEvent")(editor.frame, "PLAYER_REGEN_DISABLED")
assert(not editor.active and not editor.moveDriver:IsShown() and not editor:Save())
assert(profile.currentStepFrame.x == savedX)
env.setCombat(false)
print(
    "Gamepad placement: real preview focus, linked movement, D-pad, stick/dead-zone, triggers, confirm/next, Save/Cancel and combat passed"
)
