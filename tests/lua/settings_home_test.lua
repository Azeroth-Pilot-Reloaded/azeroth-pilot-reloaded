local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "enUS" end
function APR:NormalizeSearchText(value) return string.lower(value) end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/config/SettingsIndex.lua")
dofile("APR-Core/ui/panels/SettingsHome.lua")
local value, changed = true, 0
APR.settings.optionsTable = { args = {
    enableAddon = {type = "toggle", name = "Enable addon", get = function() return value end,
        set = function(info, new) assert(info[1] == "enableAddon"); value = new; changed = changed + 1 end},
    protected = {type = "toggle", name = "Confirmed", confirm = true},
    hidden = {type = "group", hidden = true, args = {bad = {type = "toggle", name = "Hidden"}}},
    nested = {type = "group", name = "Navigation", disabled = true, args = {
        scale = {type = "range", name = "Arrow scale", desc = "Adjust arrow"}}},
} }
local records = APR.SettingsIndex:Build()
assert(#records == 3 and records[1].key == "enableAddon")
assert(APR.SettingsIndex:Toggle(records[1]) and not value and changed == 1)
env.setCombat(true)
assert(not APR.SettingsIndex:Toggle(records[1]) and changed == 1)
env.setCombat(false)
for _, record in ipairs(records) do
    if record.key == "scale" then assert(record.disabled and record.search:find("navigation", 1, true)) end
end
APR.SettingsHome:Show()
assert(#APR.SettingsHome.list.items == 1)
APR.SettingsHome.query = "arrow"
APR.SettingsHome:Refresh()
assert(#APR.SettingsHome.list.items == 1 and APR.SettingsHome.list.items[1].key == "scale")
APR.SettingsHome.query = "missing option"
APR.SettingsHome:Refresh()
assert(APR.SettingsHome.empty:IsShown())

-- Missing optional panels leave holes in the preview collection: cancellation must still hide all of them.
local registered, restored = {}, 0
local window = LibStub("LibWindow-1.1")
local originalLibStub = LibStub
function LibStub(name) if name == "LibWindow-1.1" then return window end; return originalLibStub(name) end
function window.RegisterConfig(frame, config) registered[frame] = config end
function window.SavePosition(frame) registered[frame].point = "CENTER"; registered[frame].x = 42 end
function window.RestorePosition() restored = restored + 1 end
function APR:SetupFrameDrag(frame, guard, stop) frame.dragGuard, frame.dragStop = guard, stop end
CurrentStepScreenPanel = CreateFrame("Frame", nil, UIParent)
PartyScreenPanel = CreateFrame("Frame", nil, UIParent)
APR.settings.profile.currentStepFrame = {point = "TOP", x = 10}
APR.currentStep = { RefreshCurrentStepFrameAnchor = function() end }
APR.questOrderList = { RefreshFrameAnchor = function() end }
dofile("APR-Core/ui/panels/LayoutEditor.lua")
-- The widget mock has no Raise because gameplay tests do not need it.
APR.LayoutEditor:Create()
APR.LayoutEditor.frame.Raise = function() end
APR.LayoutEditor:Show()
assert(APR.LayoutEditor.previews[5]:IsShown())
APR.LayoutEditor.previews[1].changed = true
APR.LayoutEditor:Hide()
assert(APR.settings.profile.currentStepFrame.x == 10 and not APR.LayoutEditor.previews[5]:IsShown())
APR.LayoutEditor:Show()
APR.LayoutEditor.previews[1].changed = true
assert(APR.LayoutEditor:Save() and APR.settings.profile.currentStepFrame.x == 42 and restored == 1)
APR.LayoutEditor:Show()
env.setCombat(true)
APR.LayoutEditor.frame.scripts.OnEvent()
assert(not APR.LayoutEditor.active and not APR.LayoutEditor.previews[5]:IsShown())
assert(not APR.LayoutEditor:Save())
print("Settings and layout: existing setters, hidden/disabled options, search, cancel/save and combat guards passed")
