-- Dropdowns dismiss without consuming the outside click or keeping a hidden keyboard/event listener.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local methods = env.methods
local show, hide = methods.Show, methods.Hide
function methods:Show()
    local changed = not self:IsShown()
    show(self)
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    local changed = self:IsShown()
    hide(self)
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:RegisterEvent(event)
    self.events = self.events or {}; self.events[event] = true
end
function methods:UnregisterEvent(event) if self.events then self.events[event] = nil end end
function methods:IsMouseOver() return self.mouseOver == true end
function methods:GetEffectiveScale() return self:GetScale() end
function methods:GetBottom() return self.bottom or 800 end
function methods:GetTop() return self:GetBottom() + self:GetHeight() end
function methods:SetPropagateKeyboardInput(value)
    assert(not InCombatLockdown(), "Keyboard propagation cannot be changed during combat")
    self.propagate = value
end
function methods:EnableKeyboard(value) self.keyboard = value end
function methods:SetTexture(value) assert(value, "Functional icon needs an asset"); self.texture = value end
function methods:SetAtlas(value) assert(value); self.atlas = value end
function methods:SetVertexColor(...) self.vertexColor = {...} end
function APR:RegisterFontString(region, _, options) region.textRole = options.role end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
local selected, clicks = nil, 0
local select = APR.UI:Select(UIParent, 180, function(value) selected = value; clicks = clicks + 1 end)
select:SetOptions({{value = false, label = "All"}, {value = "one", label = "One"}}, false)
local function open() select.scripts.OnClick(); return select.menu end
local menu = open()
assert(menu:GetParent() == UIParent and menu:GetFrameStrata() == "TOOLTIP",
    "Dropdowns escape clipping containers and render above dialog content")
assert(menu.events.GLOBAL_MOUSE_DOWN and APR.UI.activeMenu == menu and menu.propagate)
assert(menu:GetHeight() == 60 and not menu.scripts.OnUpdate)
assert(not menu.list.scroll.ScrollBar:IsShown() and menu.list.scroll:GetWidth() == 172,
    "Fitting choices use the full menu width without a scrollbar gutter")
menu.mouseOver = true
menu.scripts.OnEvent(menu, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(menu:IsShown() and clicks == 0, "Clicks inside the menu must reach its options")
menu.mouseOver, select.mouseOver = false, true
menu.scripts.OnEvent(menu, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(menu:IsShown(), "The trigger owns its own toggle click")
select.scripts.OnClick()
assert(not menu:IsShown() and not menu.events.GLOBAL_MOUSE_DOWN and not APR.UI.activeMenu)
select.mouseOver = false
open()
menu.scripts.OnEvent(menu, "GLOBAL_MOUSE_DOWN", "RightButton")
assert(not menu:IsShown() and not menu.events.GLOBAL_MOUSE_DOWN)
open()
menu.scripts.OnKeyDown(menu, "A")
assert(menu:IsShown() and menu.propagate)
menu.scripts.OnKeyDown(menu, "ESCAPE")
assert(not menu:IsShown() and not menu.propagate and UIParent:IsShown())
open()
menu.list.active[2].scripts.OnClick(menu.list.active[2])
assert(selected == "one" and clicks == 1 and not menu:IsShown())
open()
assert(menu.list.active[2].aprListRow.selected and not menu.list.active[1].aprListRow.selected
    and menu.list.active[2].check:IsShown() and not menu.list.active[1].check:IsShown())
menu.list.active[1].scripts.OnClick(menu.list.active[1])
assert(selected == false and clicks == 2, "A false-valued All option is still selectable")
open()
local other = APR.UI:Select(UIParent, 180, function() end)
other:SetOptions(select.options, false)
other.scripts.OnClick()
assert(not menu:IsShown() and other.menu:IsShown() and APR.UI.activeMenu == other.menu)
other:Hide()
assert(not other.menu:IsShown() and not APR.UI.activeMenu)
open()
local frames, fonts = env.frames(), env.fonts()
for _ = 1, 40 do select.scripts.OnClick(); select.scripts.OnClick() end
assert(env.frames() == frames and env.fonts() == fonts, "Reopening the menu reuses options and icons")
select:Hide()
assert(not menu:IsShown() and not menu.events.GLOBAL_MOUSE_DOWN)
select:Show(); open()
menu.mouseOver = true
env.setCombat(true)
menu.scripts.OnEvent(menu, "PLAYER_REGEN_DISABLED")
assert(not menu:IsShown() and not menu.events.PLAYER_REGEN_DISABLED)
open()
assert(not menu.keyboard, "A menu opened in combat must not capture gameplay keys")
menu.mouseOver = false
menu.scripts.OnEvent(menu, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(not menu:IsShown())
env.setCombat(false)
local many = {}
for index = 1, 16 do many[index] = {value = index, label = "Type " .. index} end
select:SetOptions(many, 1)
select.bottom = 800
open()
assert(menu:GetHeight() == 16 * 26 + 8 and menu.point[1] == "TOPLEFT",
    "The route type list can show all entries instead of stopping after eight rows")
menu:Hide()
select.bottom = 100
open()
assert(menu:GetHeight() == 16 * 26 + 8 and menu.point[1] == "BOTTOMLEFT",
    "A selector near the bottom of the screen opens upwards")
menu:Hide()
UIParent:SetHeight(400)
select.bottom = 190
open()
assert(menu:GetHeight() < 190 and menu:GetHeight() < #many * 28 + 8,
    "Small viewports retain scrolling without going beyond the screen")
assert(menu.list.scroll.ScrollBar:IsShown() and menu.list.scroll:GetWidth() == 150)
menu.list:ScrollTo(100)
assert(menu.list.scroll:GetVerticalScroll() > 0, "Overflowing choices remain reachable")
select:SetOptions({{value = 1, label = "Only choice"}}, 1)
assert(not menu.list.scroll.ScrollBar:IsShown() and menu.list.scroll:GetVerticalScroll() == 0
    and menu.list.scroll:GetWidth() == 172, "Shrinking an open list removes the bar, gutter and stale scroll offset")
menu:Hide()
select:SetOptions(many, 1)
UIParent:SetHeight(1080)
UIParent:SetScale(0.75); select:SetScale(1.5); select.bottom = 60
open()
assert(menu.point[1] == "BOTTOMLEFT" and menu:GetHeight() <= 540 - select:GetTop() - 10,
    "Available height accounts for the dropdown and root UI scales")
assert(menu:GetScale() == 2, "An independent popup preserves its trigger's effective scale")
menu:Hide()
UIParent:SetScale(1)
select:SetScale(0.8)
open()
assert(menu:GetScale() == 0.8, "Reopening applies scale changes without rebuilding the popup")
menu:Hide()
print("Dropdown: outside click, trigger toggle, Escape, false-valued selection, switch, parent hide, combat and bounded controls passed")

-- Multiple choices persist until explicit dismissal and do not mutate the caller's table.
UIParent:SetScale(1)
local changes = {}
local multi = APR.UI:Select(UIParent, 220, function(value, enabled)
    changes[#changes + 1] = {value, enabled}
end, {multiselect = true, emptyText = "Any"})
local initial = {}
multi:SetOptions({{value = false, label = "Any"}, {value = "a", label = "Alpha"},
    {value = "b", label = "Beta"}}, initial)
multi.scripts.OnClick()
local choices = multi.menu
choices.list.scroll:SetSize(190, 104)
choices.list:RefreshVisible()
assert(choices.list.active[1].check:IsShown())
choices.list.active[2].scripts.OnClick(choices.list.active[2])
choices.list.active[3].scripts.OnClick(choices.list.active[3])
assert(choices:IsShown() and choices.list.active[2].check:IsShown() and choices.list.active[3].check:IsShown())
assert(not choices.list.active[1].check:IsShown() and next(initial) == nil)
assert(multi:GetText() == "Alpha, Beta" and changes[1][1] == "a" and changes[1][2] == true)
choices.list.active[2].scripts.OnClick(choices.list.active[2])
assert(multi:GetText() == "Beta" and changes[3][2] == false)
choices.list.active[1].scripts.OnClick(choices.list.active[1])
assert(next(multi.value) == nil and multi:GetText() == "Any" and changes[4][1] == false)
multi:SetOptions(multi.options, {a = true})
assert(choices.list.active[2].check:IsShown() and not choices.list.active[1].check:IsShown(),
    "External preference changes refresh checks while the menu stays open")
assert(not choices.close and #choices.list.items == 3, "Multiselects contain only actual choices")
choices.mouseOver, multi.mouseOver = false, false
choices.scripts.OnEvent(choices, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(not choices:IsShown() and multi.value.a and #changes == 4)
multi.scripts.OnClick()
multi:SetEnabled(false)
multi.scripts.OnDisable(multi)
assert(not choices:IsShown())
multi.scripts.OnClick()
assert(not choices:IsShown(), "Disabled selectors cannot reopen their list")

multi:SetEnabled(true)
for theme in pairs(APR.Themes) do
    APR.settings.profile.uiTheme = theme
    APR:RefreshThemeRegions()
    APR.UI:RefreshListRows()
    multi.scripts.OnClick()
    local row = choices.list.active[2]
    local accent = APR:GetThemeColor("accent")
    local icon = APR:GetThemeColor("icon")
    assert(row.aprListRow.selected and row.check:IsShown() and row:GetFontString().textRole == "accent")
    assert(row.check.vertexColor[1] == icon[1] and row.check.vertexColor[2] == icon[2],
        "Checkmarks follow the theme's icon color")
    assert(row.aprListRow.background.backdropColor[1] == accent[1]
        and row.aprListRow.background.backdropColor[2] == accent[2],
        "Selected rows inherit the active palette, including after a theme change")
    choices:Hide()
end
multi:SetOptions({{value = "a", label = "Alpha"}}, {})
assert(multi:GetText() == "Any")
multi.scripts.OnClick()
choices.list.active[1].scripts.OnClick(choices.list.active[1])
choices.list.active[1].scripts.OnClick(choices.list.active[1])
assert(multi:GetText() == "Any" and not choices.list.active[1].check:IsShown())
choices:Hide()
print("Multiselect: independent toggles, reset, external refresh, close, disable and all theme palettes passed")
