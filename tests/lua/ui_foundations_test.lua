local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "frFR" end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
assert(APR:LocalizeUI("AUTHOR") == "Auteur")
local window = APR.UI:Window("APRTestWindow", "Test", 1000, 700)
assert(window:GetWidth() == 1000 and not window:IsShown())
window:Show()
window:SetSize(1100, 740)
window:Hide()
window.scripts.OnHide(window) -- This fixture invokes lifecycle scripts explicitly.
assert(APR.settings.profile.uiWindows.APRTestWindow.width == 1100)
assert(APR.settings.profile.uiWindows.APRTestWindow.height == 740)
local panel = APR.UI:Panel(window)
local original = panel.backdropColor[1]
assert(APR:SetTheme("modern") and panel.backdropColor[1] ~= original)
assert(APR:GetThemeColor("accent")[2] > 0.7)
for _, theme in ipairs(APR.ThemeOrder) do assert(APR:SetTheme(theme)) end
assert(not APR:SetTheme("missing"))
local legacy = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
APR:SetTheme("wow")
APR:RegisterSkinTarget(legacy, "panel")
APR:SetTheme("modern")
assert(legacy:GetBackdrop() ~= nil)
APR:SetTheme("wow")
assert(legacy:GetBackdrop() == nil, "Returning to WoW restores an originally absent backdrop")
local collapsed = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
APR:SetPanelColor(collapsed, {0, 0, 0, 0})
APR:RegisterSkinTarget(collapsed, "panel")
APR:SetTheme("modern")
assert(collapsed.backdropColor[4] == 0, "Themes preserve a collapsed panel's transparent background")
APR:SetTheme("wow")
local before = panel.backdropColor[1]
env.setCombat(true)
APR:SetTheme("modern")
assert(panel.backdropColor[1] == before)
env.setCombat(false)
APR:RefreshRegisteredSkins()
assert(panel.backdropColor[1] == APR.Themes.modern.background[1])
local externalCalls = 0
APR:RegisterSkinProvider("Test", function() externalCalls = externalCalls + 1 end, function() return true end)
local externalColor = panel.backdropColor[1]
APR:SetTheme("forever")
assert(panel.backdropColor[1] == externalColor and APR:GetNativeThemeTextColor("accent") == nil)

local scroll = CreateFrame("ScrollFrame", nil, UIParent)
scroll:SetSize(400, 400)
local allocations, bindings = 0, 0
local list = APR.VirtualList:New(scroll, function(parent)
    allocations = allocations + 1
    return CreateFrame("Frame", nil, parent)
end, function(row, item) bindings = bindings + 1; row.value = item.key end, function(item) return item.height end)
local items = {}
for i = 1, 10000 do items[i] = { key = i, height = i % 2 == 0 and 60 or 40 } end
list:SetItems(items)
assert(allocations <= 12)
for i = 1, 10000, 97 do
    list:ScrollToIndex(i)
    assert(list.active[i] and list.active[i].value == i)
end
assert(allocations <= 14, "10000 models cannot allocate 10000 frames")
local count = allocations
list:SetItems(items, true)
assert(allocations == count, "Rebuilding reuses the viewport pool")
list:SetItems({ { key = "replacement", height = 100 } })
assert(list.active[1].value == "replacement" and scroll:GetVerticalScroll() == 0)
GameTooltip:SetOwner(list.active[1])
GameTooltip:Show()
list:SetItems({ { key = "updated", height = 100 } })
assert(not GameTooltip:IsShown(), "Rebinding a visible row cannot keep its previous item's tooltip")
list:SetItems({})
assert(next(list.active) == nil and list.child:GetHeight() == 1)
assert(list:IndexAt(0) == 0)
print("UI foundations: native/external themes, combat deferral, localized controls and bounded 10000-row viewport passed")
