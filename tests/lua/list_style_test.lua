-- Recycled list rows share palette/radius controls without replacing callbacks or semantic text colors.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
function env.methods:SetVertexColor(...) self.vertex = {...} end
function env.methods:SetColorTexture(...) self.fill = {...} end
function env.methods:SetTexture(path) self.texture = path end
function env.methods:GetChildren() return unpack(self.children or {}) end
function hooksecurefunc(object, key, callback)
    local previous = object[key]
    object[key] = function(...) previous(...); callback(...) end
end
local hide, show = env.methods.Hide, env.methods.Show
function env.methods:Hide() hide(self); if self.scripts.OnHide then self.scripts.OnHide(self) end end
function env.methods:Show() show(self); if self.scripts.OnShow then self.scripts.OnShow(self) end end
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
local profile, UI = APR.settings.profile, APR.UI
profile.uiTheme, profile.uiThemeCustomization = "modern", {rounded = true, radius = 8}
local plain = UI:ListButton(UIParent, "No decorative icon", 240, function() end)
UI:SetListRowState(plain, true)
assert(not plain.aprListRow.iconHost and plain.aprListRow.background.backdropColor[4] == 0.13,
    "Lists without category icons retain rounded selection without allocating an icon gutter")
UI:StyleListRow(plain, "appearance")
UI:StyleListRow(plain)
assert(not plain.aprListRow.iconHost:IsShown() and not plain.aprListRow.iconName,
    "Rebinding a previously decorated row without an icon hides its old artwork")
local scroll = CreateFrame("ScrollFrame", nil, UIParent)
scroll:SetSize(240, 110)
local chosen
local list = APR.VirtualList:New(scroll, function(parent)
    return UI:ListButton(parent, "", 240, function(row) chosen = row.item.id end, "routes")
end, function(row, item)
    row:SetText(item.label)
    UI:StyleListRow(row, item.icon)
    UI:SetButtonActive(row, item.id == chosen)
end, 30)
local items = {}
for index = 1, 1000 do items[index] = {id = index, label = "Route " .. index, icon = index % 2 == 0 and "steps" or "routes"} end
list:SetItems(items)
local row, look = list.active[1], list.active[1].aprListRow
local click = row.scripts.OnClick
assert(look.background:GetParent() == row:GetParent() and look.background:GetFrameLevel() < row:GetFrameLevel(),
    "Rounded fill remains behind the original row text and action")
assert(look.separator:IsShown() and look.background.backdropColor[4] == 0)
row.scripts.OnClick(row)
list:RefreshVisible(true)
assert(chosen == 1 and row.scripts.OnClick == click and look.selected and not look.separator:IsShown())
assert(look.background.backdrop.edgeSize == 4 and look.background.backdropColor[4] == 0.13
    and look.background.borderColor[4] == 0.7)
for _, palette in ipairs({"modern", "wowModern", "emeraldModern", "violetModern", "redModern", "graphiteModern"}) do
    profile.uiTheme = palette
    APR:RefreshThemeRegions()
    assert(look.background.backdropColor[2] == APR.Themes[palette].accent[2])
    assert(look.icon.vertex[2] == APR.Themes[palette].accent[2])
end
profile.uiThemeCustomization = {customColor = true, color = {0.8, 0.2, 0.4, 1}, rounded = true, radius = 16}
APR:RefreshThemeRegions()
assert(look.background.backdrop.edgeSize == 8 and look.background.backdropColor[1] == 0.8)
profile.uiThemeCustomization.rounded = false
APR:RefreshThemeRegions()
assert(look.radius == 0 and look.background.backdrop.edgeSize == 1 and not look.background.aprRoundedFill.enabled)
profile.uiThemeCustomization.rounded = true
APR:RefreshThemeRegions()
local frames = env.frames()
for _ = 1, 10 do list:ScrollToIndex(800); list:ScrollToIndex(1) end
local afterWarmup = env.frames()
for _ = 1, 40 do list:ScrollToIndex(950); list:ScrollToIndex(1) end
assert(env.frames() == afterWarmup and afterWarmup - frames < 12, "Scrolling reuses icon/chrome frames with the viewport rows")
list:ScrollToIndex(1000)
local last = list.active[1000]
assert(last.aprListRow.last and not last.aprListRow.separator:IsShown(), "The final data row has no trailing separator")
last:SetEnabled(false)
UI:SetListRowState(last, true)
assert(last.aprListRow.background.backdropColor[4] == 0 and last.aprListRow.icon.vertex[4] == 0.45,
    "A disabled option does not acquire an actionable selection")

-- Opening a list in combat defers its new artwork but retains the bound selection until regen.
env.setCombat(true)
local combatRow = UI:ListButton(UIParent, "Combat", 240, function() chosen = "combat" end, "debug")
UI:SetListRowState(combatRow, true)
assert(combatRow.aprListRow and not combatRow.aprListRow.background)
env.setCombat(false)
UI:RefreshListRows()
assert(combatRow.aprListRow.background and combatRow.aprListRow.selected
    and combatRow.aprListRow.background.backdropColor[4] == 0.13)
combatRow.scripts.OnClick(combatRow)
assert(chosen == "combat")
combatRow:Hide()
assert(not combatRow.aprListRow.background:IsShown())

-- Gameplay rows opt into Modern; switching to native WoW hides the added chrome.
local gameRow = CreateFrame("Frame", nil, CurrentStepScreenPanel, "BackdropTemplate")
UI:StyleListRow(gameRow, nil, "questOrderList", true)
UI:SetListRowState(gameRow, true)
assert(gameRow.aprListRow.background:IsShown() and not gameRow.aprListRow.iconHost)
profile.uiTheme = "wow"
UI:RefreshListRows()
assert(not gameRow.aprListRow.background:IsShown() and not gameRow.aprListRow.iconHost)

-- Actual AceGUI items keep checked values, disabled restrictions and callbacks after decoration.
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
function PlaySound() end
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-DropDown-Items.lua")
local gui = LibStub("AceGUI-3.0")
local item = gui:Create("Dropdown-Item-Toggle")
item.frame:SetParent(UIParent)
item:SetText("A font choice"); item:SetValue(false)
local changes = 0
item:SetCallback("OnValueChanged", function(_, _, value) changes = changes + 1; assert(value) end)
UI:StyleDropdownListItem(item)
local onClick = item.frame.scripts.OnClick
assert(item.frame:GetHeight() == 26 and not item.frame.aprListRow.selected and not item.frame.aprListRow.iconHost)
onClick(item.frame, "LeftButton")
assert(changes == 1 and item:GetValue() and item.frame.aprListRow.selected
    and item.frame.scripts.OnClick == onClick, "Styling retains the actual AceGUI value/callback")
item:SetDisabled(true)
UI:StyleDropdownListItem(item)
onClick(item.frame, "LeftButton")
assert(changes == 1 and item:GetValue(), "Decoration cannot unlock a disabled AceGUI choice")
gui:Release(item)
local recycled = gui:Create("Dropdown-Item-Toggle")
assert(recycled == item)
recycled.frame:SetParent(UIParent)
recycled:SetText("Another font"); recycled:SetValue(false)
UI:StyleDropdownListItem(recycled)
assert(not recycled.frame.aprListRow.selected and not recycled.frame.aprListRow.iconHost,
    "A recycled dropdown item cannot retain the previous selection or a decorative icon")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-DropDown.lua")
local pullout = gui:Create("Dropdown-Pullout")
pullout:AddItem(recycled)
for index = 2, 3 do
    local choice = gui:Create("Dropdown-Item-Toggle")
    choice:SetText("Choice " .. index); choice:SetValue(false)
    pullout:AddItem(choice)
end
pullout:SetMaxHeight(80)
UI:StyleDropdownList(pullout)
pullout:Open("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
assert(pullout.items[2].frame.point[5] == -28 and pullout.items[3].frame.point[5] == -54,
    "Real AceGUI pullouts place 26px rows without their original 16px overlap")
assert(pullout.itemFrame:GetHeight() == 86 and pullout.frame:GetHeight() == 80
    and not pullout.items[3].frame.aprListRow.separator:IsShown(), "Content height and scroll cap include every row")
local unrelated = gui:Create("Dropdown-Pullout")
for index = 1, 2 do unrelated:AddItem(gui:Create("Dropdown-Item-Toggle")) end
unrelated:Open("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
assert(unrelated.items[2].frame:GetHeight() == 17 and unrelated.items[2].frame.point[5] == -18,
    "Unstyled addons retain AceGUI's native item layout")
print("List style: theme/custom palettes, icons, live radius toggle, rounded selection, separators, pooling, disabled options, combat and native WoW passed")

-- Ending combat must not revisit every pooled row created during this session.
local manyRows = {}
for index = 1, 1000 do manyRows[index] = UI:ListButton(UIParent, "Row " .. index, 240, function() end) end
UI:RefreshPendingListRows()
local refreshed, refreshRow = 0, UI.RefreshListRow
function UI:RefreshListRow(row) refreshed = refreshed + 1; return refreshRow(self, row) end
UI:RefreshPendingListRows()
assert(refreshed == 0, "A clean combat exit must not restyle any rows")
env.setCombat(true)
for _ = 1, 20 do UI:SetListRowState(manyRows[1], true) end
UI:StyleListRow(manyRows[1], "favorite")
local lateRow = UI:ListButton(UIParent, "Late", 240, function() end, "debug")
UI:SetListRowState(lateRow, true)
refreshed = 0
UI:RefreshPendingListRows()
assert(refreshed == 0 and not lateRow.aprListRow.background, "Pending artwork remains untouched during combat")
env.setCombat(false)
UI:RefreshPendingListRows()
assert(refreshed == 2 and lateRow.aprListRow.background and lateRow.aprListRow.selected)
assert(manyRows[1].aprListRow.iconName == "favorite", "Deferred icon changes are applied along with selection")
UI:RefreshPendingListRows()
assert(refreshed == 2, "Repeated events cannot replay completed work")
refreshed = 0
UI:RefreshListRows()
assert(refreshed >= 1000, "Explicit theme refresh still visits all registered rows")
print("List combat recovery: 1,000 idle rows untouched; repeated changes coalesce into two updates")
