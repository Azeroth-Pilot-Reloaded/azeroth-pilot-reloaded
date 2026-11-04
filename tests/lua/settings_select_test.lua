-- The settings adapter keeps APR's own menu and key semantics across pooling.
local fixture = dofile("tests/lua/settings_widgets_test.lua")
local env, gui = fixture.env, fixture.gui
function GetLocale() return "enUS" end
function env.methods:GetBottom() return 600 end
function env.methods:GetTop() return 630 end
function env.methods:GetEffectiveScale() return 1 end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")

assert(gui:GetWidgetVersion("APRSettingsSelect"), "APR settings must register its own select adapter")
local selector = gui:Create("APRSettingsSelect")
local changes, enters, leaves = {}, 0, 0
selector:SetLabel("Synthetic scale")
selector:SetUserData("option", {name = "Synthetic scale", desc = "Choose a weight scale"})
selector:SetWidth(640)
selector:SetList({apr = "Default", ["pawn:beta"] = "Beta", ["pawn:alpha"] = "Alpha"})
selector:SetValue("pawn:beta")
selector:SetCallback("OnValueChanged", function(_, _, value) changes[#changes + 1] = value end)
selector:SetCallback("OnEnter", function() enters = enters + 1 end)
selector:SetCallback("OnLeave", function() leaves = leaves + 1 end)
assert(selector:GetValue() == "pawn:beta" and selector.text:GetText() == "Beta" and #changes == 0)
APR.SettingsRows:Apply(selector)
assert(selector.aprRow and selector.select:GetWidth() >= 190,
    "APR settings lays out the new select as a regular responsive control")
assert(not selector.dropdown and not selector.pullout, "The adapter cannot allocate the AceGUI/WoW dropdown")
selector.select:GetScript("OnEnter")(selector.select)
selector.select:GetScript("OnLeave")(selector.select)
assert(enters == 1 and leaves == 1, "AceConfig tooltip events cross the APR adapter")
selector.select:GetScript("OnClick")(selector.select)
local menu = selector.select.menu
assert(menu and menu:IsShown() and menu.list:GetCount() == 3)
local rows = menu.list.active
assert(rows[1]:GetText() == "Default" and rows[2]:GetText() == "Alpha" and rows[3]:GetText() == "Beta",
    "Stable key order keeps the APR default first")
rows[2]:GetScript("OnClick")(rows[2])
assert(selector:GetValue() == "pawn:alpha" and changes[1] == "pawn:alpha" and #changes == 1
    and not menu:IsShown(), "The APR row sends the real scale key once")
selector:SetValue("apr")
assert(selector.text:GetText() == "Default" and #changes == 1,
    "Programmatic selection never behaves like a player choice")

-- A rebuilt list honors an explicit order and keeps numeric keys as numbers.
local values, ordering = {[2] = "Two", [10] = "Ten", apr = "Default"}, {10, "apr", 2}
selector:SetList(values, ordering)
selector:SetValue(2)
selector.select:GetScript("OnClick")(selector.select)
rows = menu.list.active
assert(rows[1]:GetText() == "Ten" and rows[2]:GetText() == "Default" and rows[3]:GetText() == "Two")
rows[1]:GetScript("OnClick")(rows[1])
assert(selector:GetValue() == 10 and type(changes[2]) == "number" and changes[2] == 10)
assert(values[2] == "Two" and ordering[1] == 10 and #ordering == 3,
    "Preparing a menu cannot mutate the option provider's data")
selector.select:GetScript("OnClick")(selector.select)
selector:SetDisabled(true)
assert(not selector.select:IsEnabled() and not menu:IsShown())
selector.select:GetScript("OnClick")(selector.select)
assert(not menu:IsShown() and #changes == 2, "Disabled controls cannot reopen or dispatch a choice")
selector:SetDisabled(false)
selector.select:GetScript("OnClick")(selector.select)
selector:ClearFocus()
assert(not menu:IsShown())

-- Release drops references and the pooled object cannot reopen old rows.
selector.select:GetScript("OnClick")(selector.select)
gui:Release(selector)
assert(not menu:IsShown() and menu.list:GetCount() == 0 and not selector.values and not selector.options,
    "A retired settings view leaves no open list or borrowed catalog")
local reused = gui:Create("APRSettingsSelect")
assert(reused == selector and reused:GetValue() == nil and reused.text:GetText() == "")
reused:SetList({fresh = "Fresh"}); reused:SetValue("fresh")
reused.select:GetScript("OnClick")(reused.select)
assert(reused.select.menu.list:GetCount() == 1 and reused.select.menu.list.active[1]:GetText() == "Fresh")
gui:Release(reused)
local ordinary = gui:Create("Dropdown")
assert(ordinary.type == "Dropdown" and ordinary.dropdown and not ordinary.select,
    "Registering the APR adapter cannot replace other addons' dropdowns")
gui:Release(ordinary)
print("APR settings select: native APR menu, ordered typed keys, callbacks, disable, layout and pool cleanup passed")
