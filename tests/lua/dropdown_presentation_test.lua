-- Exercise APR presentation against real AceGUI controls and their acquire/release lifecycle.
local fixture = dofile("tests/lua/settings_widgets_test.lua")
local gui = fixture.gui
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")

fixture.dialog:FeedGroup("APR/Workspace/Options/synthetic", {kind = "Dropdown"}, fixture.host)
local dropdown = fixture.host.children[1].children[1]
dropdown:SetList({a = "Alpha", b = "Beta"})
dropdown:SetMultiselect(true)
APR.UI:StyleDropdownList(dropdown.pullout)
assert(#dropdown.pullout.items == 2, "APR multiselects omit the automatic close action")
dropdown:SetItemValue("a", true)
dropdown:SetItemValue("b", true)
dropdown.pullout:Open("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
assert(#dropdown.pullout.items == 2 and dropdown.pullout.items[1]:GetValue() and dropdown.pullout.items[2]:GetValue(),
    "Opening retains independently selected choices without adding a close action")
local pullout = dropdown.pullout
pullout.scrollFrame:SetHeight(60)
pullout:FixScroll()
assert(not pullout.slider:IsShown(), "An exactly fitting native list has no scrollbar")
pullout:MoveScroll(-1)
assert(not pullout.slider:IsShown(), "Wheel input cannot show a bar for fitting choices")
pullout.scrollFrame:SetHeight(34)
pullout:FixScroll()
assert(pullout.slider:IsShown(), "Clipped native choices retain a scrollbar")
pullout.scrollFrame:SetHeight(80)
pullout:FixScroll()
assert(not pullout.slider:IsShown() and pullout.scrollStatus.offset == 0,
    "A resized viewport removes the native bar and stale offset")
dropdown:SetList({c = "Gamma"})
dropdown.pullout:Open("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
assert(#dropdown.pullout.items == 1 and dropdown.pullout.items[1]:GetText() == "Gamma",
    "Rebuilding the choices cannot reintroduce the automatic close action")
fixture.host:ReleaseChildren()

local native = gui:Create("Dropdown")
native:SetList({a = "Alpha", b = "Beta"})
native:SetMultiselect(true)
assert(#native.pullout.items == 3, "Other addons retain AceGUI's original presentation")
gui:Release(native)
print("Dropdown presentation: no close action, preserved selections, rebuilt lists and isolated native controls passed")
