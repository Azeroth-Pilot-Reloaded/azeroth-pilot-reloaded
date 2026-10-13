-- The real AceGUI picker updates colors without refreshing the options page.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/ThemeCustomization.lua")
dofile("APR-Core/ui/panels/OptionsPanel.lua")

strmatch = string.match
table.wipe = wipe
function geterrorhandler() return function(err) error(err) end end
local originalXpcall = xpcall
function xpcall(fn, handler, ...)
    local args = {...}
    return originalXpcall(function() return fn(unpack(args)) end, handler)
end
LibStub = nil
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/AceGUI-3.0/AceGUI-3.0.lua")
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
ColorPickerFrame = CreateFrame("Frame", nil, UIParent)
function ColorPickerFrame:IsVisible() return self:IsShown() end
function ColorPickerFrame:SetupColorPickerAndShow(info)
    self.info = info
    self.rgb = {info.r, info.g, info.b}
    self:Show()
end
function ColorPickerFrame:GetColorRGB() return unpack(self.rgb) end
function ColorPickerFrame:GetColorAlpha() return 1 end
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-ColorPicker.lua")

local editor, panel, profile = APR.ThemeCustomization, APR.OptionsPanel, APR.settings.profile
profile.uiTheme = "modern"
profile.uiThemeCustomization = {customColor = true, color = {0, 176 / 255, 150 / 255, 1}, rounded = true, radius = 8}
local options = editor:GetOptions()
panel.actionButtons, panel.footerButtons = {}, {}
panel.footer = CreateFrame("Frame", nil, UIParent)
panel.view = {app = "APR/Workspace/Options/appearance/theme"}
panel:SetFooterActions({{option = options.themeDiscard}, {option = options.themeApply}})
local cancel, apply = panel.footerButtons[1], panel.footerButtons[2]
local registry = LibStub:NewLibrary("AceConfigRegistry-3.0", 1)
local notifications = 0
function registry:NotifyChange(app) assert(app == panel.view.app); notifications = notifications + 1 end
assert(not apply:IsEnabled() and not cancel:IsEnabled())

local picker = LibStub("AceGUI-3.0"):Create("ColorPicker")
picker:SetColor(options.themeAccent.get())
local confirmed, changed = 0, 0
-- Like AceConfig's color activation, OnValueChanged calls the setter without rebuilding the page.
picker:SetCallback("OnValueChanged", function(_, _, r, g, b)
    changed = changed + 1
    options.themeAccent.set(nil, r, g, b)
end)
picker:SetCallback("OnValueConfirmed", function(_, _, r, g, b)
    confirmed = confirmed + 1
    options.themeAccent.set(nil, r, g, b)
end)
local liveAccent = APR:GetThemeColor("accent")
local previews = 0
local preview = {Refresh = function() previews = previews + 1 end}
editor.previews[preview] = true
picker.frame.scripts.OnClick(picker.frame)
local frames = env.frames()
ColorPickerFrame.rgb = {0.8, 0.2, 0.4}
ColorPickerFrame.info.swatchFunc()
assert(editor:IsDirty() and apply:IsEnabled() and cancel:IsEnabled(),
    "Changing only the accent must enable the existing Apply/Cancel buttons immediately")
assert(ColorPickerFrame:IsShown() and env.frames() == frames and previews == 1 and notifications == 0,
    "The preview/actions refresh without releasing the picker or rebuilding the settings")
assert(profile.uiThemeCustomization.color[1] == 0 and APR:GetThemeColor("accent")[1] == liveAccent[1],
    "Choosing a color remains an isolated draft until Apply")

-- Modern pickers may suppress confirmation when the live RGB already matches the chosen RGB.
ColorPickerFrame:Hide()
ColorPickerFrame.info.swatchFunc()
ColorPickerFrame.info.opacityFunc()
assert(confirmed == 0 and changed == 1 and apply:IsEnabled(),
    "Apply cannot depend on AceGUI emitting an unchanged OnValueConfirmed")
apply.scripts.OnClick(apply)
assert(profile.uiThemeCustomization.color[1] == 0.8 and not apply:IsEnabled() and not cancel:IsEnabled())

picker:SetColor(options.themeAccent.get())
picker.frame.scripts.OnClick(picker.frame)
ColorPickerFrame.rgb = {0.1, 0.3, 0.5}
ColorPickerFrame.info.swatchFunc()
ColorPickerFrame:Hide()
ColorPickerFrame.info.cancelFunc()
assert(not editor:IsDirty() and not apply:IsEnabled() and not cancel:IsEnabled(),
    "Cancelling the native palette restores the prior draft and disables the actions again")

picker.frame.scripts.OnClick(picker.frame)
env.setCombat(true)
ColorPickerFrame.rgb = {0.3, 0.5, 0.7}
ColorPickerFrame.info.swatchFunc()
assert(editor:IsDirty() and not apply:IsEnabled() and cancel:IsEnabled(), "Live color edits retain the combat restriction")
ColorPickerFrame:Hide()
env.setCombat(false)
panel:RefreshActions()
assert(apply:IsEnabled())
cancel.scripts.OnClick(cancel)
assert(not editor:IsDirty() and not apply:IsEnabled() and profile.uiThemeCustomization.color[1] == 0.8,
    "Footer Cancel discards the color edit without changing the saved accent")
print("Theme color picker: live Apply/Cancel, missing confirmation, no rebuild, draft isolation, native cancellation and combat passed")
