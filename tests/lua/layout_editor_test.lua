-- Placement is a transaction: previews may move during a draft, protected panels and saved state may not.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
SAVE, PREVIEW = "SAVE", "PREVIEW"
UIParent:SetSize(1920, 1080)
local oldLibStub, configs = LibStub, {}
local window = {
    RegisterConfig = function(frame, storage) configs[frame] = storage end,
    SavePosition = function(frame)
        local storage = configs[frame]
        storage.x, storage.y, storage.point, storage.scale = frame:GetLeft(), frame:GetTop(), "TOPLEFT", frame:GetScale()
    end,
    RestorePosition = function(frame) frame.restored = configs[frame] end,
}
function LibStub(name, ...)
    if name == "LibWindow-1.1" then return window end
    return oldLibStub(name, ...)
end
function env.methods:GetLeft() return self.left or 100 end
function env.methods:GetTop() return self.top or 600 end
function env.methods:Raise() end
function APR:SetupFrameDrag(frame, guard, stopped)
    frame.beginDrag = guard
    frame.endDrag = function() stopped(frame) end
end
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/panels/LayoutEditor.lua")
APR.currentStep = {RefreshCurrentStepFrameAnchor = function() end}
APR.fillersFrame = {RefreshFillersFrame = function() end}
APR.AFK = {RefreshFrameAnchor = function() end}
APR.questOrderList = {RefreshFrameAnchor = function() end}
APR.PrintInfo = function() end
local profile = APR.settings.profile
profile.currentStepFrame = {x = 5, y = 10, point = "CENTER", scale = 1.25}
profile.fillersFrameSnapToCurrentStep = true
CurrentStepScreenPanel = env.widget(UIParent)
CurrentStepScreenPanel:SetScale(1.25)
CurrentStepScreenPanel:Hide()
FillersScreenPanel = env.widget(UIParent)
FillersScreenPanel:Hide()
local editor = APR.LayoutEditor
assert(editor:Show() and #editor.previews == 11)
assert(not CurrentStepScreenPanel:IsShown(), "Hidden gameplay panels must not be forced visible")
assert(editor.previews[1]:GetScale() == 1.25)
assert(editor.previews[2].point[2] == editor.previews[1], "Linked previews follow the primary preview")
local saved = profile.currentStepFrame
editor.previews[1].left = 420
editor.previews[1].endDrag()
editor.previews[2].endDrag()
editor:Hide()
assert(saved.x == 5 and profile.fillersFrameSnapToCurrentStep, "Cancel must not change positions or attachments")
editor:Show()
editor.previews[1].endDrag()
editor.previews[2].endDrag()
editor.previews[8].endDrag() -- A lazy XP panel can be placed before it exists.
assert(editor:Save())
assert(profile.currentStepFrame == saved and saved.x == 420 and saved.scale == 1.25)
assert(not profile.fillersFrameSnapToCurrentStep and profile.xpBuffFrame.point == "TOPLEFT")
assert(CurrentStepScreenPanel.restored == saved)
editor:Show()
editor:Recover()
assert(editor.previews[1].changed and saved.x == 420, "Recovery must remain a draft")
env.setCombat(true)
CurrentStepScreenPanel.secure = true
editor.frame.scripts.OnEvent(editor.frame, "PLAYER_REGEN_DISABLED")
assert(not editor.active and not editor.previews[1]:IsShown() and not editor:Save())
assert(not editor:Show(), "Combat cannot create or apply a layout")
env.setCombat(false)
editor:Show()
APR.settings.profile = {}
assert(not editor:Save(), "A stale draft cannot write into a different profile")
editor:Hide()
print("Layout editor: cancel/save, linked dragging, hidden/lazy panels, scale, recovery, combat and profile isolation passed")
