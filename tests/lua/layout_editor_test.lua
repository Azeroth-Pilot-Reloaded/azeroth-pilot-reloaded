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
APR.settings.profile = profile
local pending, opened, closed = {}, 0, 0
C_Timer = {After = function(_, callback) pending[#pending + 1] = callback end}
APR.Workspace = {active = "options", frame = env.widget(UIParent)}
function APR.settings:CloseSettings()
    closed = closed + 1
    APR.Workspace.frame:Hide()
end
function APR.settings:OpenSettings()
    opened = opened + 1
    assert(not editor.active, "The editor is closed before settings are restored")
    APR.Workspace.frame:Show()
end
local function flush()
    local callbacks = pending
    pending = {}
    for _, callback in ipairs(callbacks) do callback() end
end
editor:ShowFromSettings()
editor:ShowFromSettings()
assert(#pending == 1 and closed == 0 and not editor.active,
    "AceConfig must finish its callback before any settings widgets are released")
flush()
assert(editor.active and not APR.Workspace.frame:IsShown() and closed == 1)
editor:Hide()
assert(opened == 1 and APR.Workspace.frame:IsShown(), "Cancel returns to settings")
editor:ShowFromSettings(); flush()
assert(editor:Save() and opened == 2 and APR.Workspace.frame:IsShown(), "Save returns to settings")
editor:ShowFromSettings(); flush()
editor.frame:Hide()
editor.frame.scripts.OnHide(editor.frame)
assert(opened == 3 and not editor.active, "Escape/the close button also restore settings")
editor:ShowFromSettings(); flush()
editor:Hide(false)
assert(opened == 3, "Explicit navigation or a profile reload must not reopen the previous settings page")
APR.Workspace.frame:Show()
editor:ShowFromSettings()
env.setCombat(true)
flush()
assert(not editor.active and APR.Workspace.frame:IsShown(), "Combat before the deferred launch preserves settings")
env.setCombat(false)
editor:ShowFromSettings(); flush()
APR.settings.profile = {}
editor:Hide()
assert(opened == 3, "A stale profile cannot reopen settings")
APR.settings.profile = profile
APR.Workspace.active = "route"
editor:Show(); editor:Hide()
assert(opened == 3, "The standalone command cannot open settings that were not previously visible")

-- Exercise the reported crash through AceConfig's actual callback and AceGUI's release pool.
local failures = {}
function geterrorhandler() return function(err) failures[#failures + 1] = err end end
local originalXpcall = xpcall
function xpcall(fn, handler, ...)
    local args = {...}
    return originalXpcall(function() return fn(unpack(args)) end, handler)
end
function PlaySound() end
function CloseSpecialWindows() end
function env.methods:GetNumChildren() return 0 end
function env.methods:GetChildren() end
function env.methods:GetScript(event) return self.scripts[event] end
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "UIPanelButtonTemplate" then frame:SetFontString(frame:CreateFontString()) end
    return frame
end
table.wipe, strmatch = wipe, string.match
LibStub = nil
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/HereBeDragons/CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("APR-Core/libs/AceGUI-3.0/AceGUI-3.0.lua")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-Button.lua")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIContainer-SimpleGroup.lua")
dofile("APR-Core/libs/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua")
dofile("APR-Core/libs/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua")
local gui, dialog = LibStub("AceGUI-3.0"), LibStub("AceConfigDialog-3.0")
local host = gui:Create("SimpleGroup")
LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("PlacementTest", {
    type = "group", name = "General", args = {
        placement = {type = "execute", name = "Place windows", func = function() editor:ShowFromSettings() end},
    },
})
function APR.settings:CloseSettings()
    APR.Workspace.frame:Hide()
    host:ReleaseChildren()
    host:SetUserData("appName", nil)
end
function APR.settings:OpenSettings()
    APR.Workspace.frame:Show()
    dialog:Open("PlacementTest", host)
end
APR.Workspace.active = "options"
APR.settings:OpenSettings()
local button = host.children[1]
button.frame.scripts.OnClick(button.frame, "LeftButton")
assert(#failures == 0, table.concat(failures, "\n"))
assert(not editor.active and APR.Workspace.frame:IsShown(), "The real AceConfig callback completes before closing")
flush()
assert(editor.active and not APR.Workspace.frame:IsShown() and #host.children == 0)
editor:Hide()
assert(APR.Workspace.frame:IsShown() and #host.children == 1, "Returning to settings rebuilds usable controls")
host.children[1].frame.scripts.OnClick(host.children[1].frame, "LeftButton")
flush()
assert(editor:Save() and APR.Workspace.frame:IsShown())
assert(#failures == 0, table.concat(failures, "\n"))
print("Layout editor: cancel/save, linked dragging, hidden/lazy panels, scale, recovery, combat and profile isolation passed")
