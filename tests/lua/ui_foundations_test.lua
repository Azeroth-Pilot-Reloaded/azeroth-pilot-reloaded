local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "enUS" end
UIParent:SetSize(1920, 1080)
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
local window = APR.UI:Window("APRTestWindow", "Test", 1000, 700)
assert(window:GetWidth() == 1000 and not window:IsShown())
window:Show()
window:SetSize(1100, 740)
window:Hide()
window.scripts.OnHide(window) -- This fixture invokes lifecycle scripts explicitly.
assert(APR.settings.profile.uiWindows.APRTestWindow.width == 1100)
assert(APR.settings.profile.uiWindows.APRTestWindow.height == 740)
local panel = APR.UI:Panel(window)
APR.settings.profile.uiTheme = "modern"
assert(select(2, APR:GetTheme()) == "wow", "Saved experimental themes are ignored on audit-clean")
local legacy = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
APR:SetPanelColor(legacy, {0.1, 0.2, 0.3, 0})
APR:RegisterSkinTarget(legacy, "panel")
assert(legacy:GetBackdrop() == nil and legacy.backdropColor[4] == 0)
env.setCombat(true)
local deferred = APR.UI:Panel(window)
assert(deferred:GetBackdrop() == nil)
env.setCombat(false)
APR:RefreshRegisteredSkins()
assert(deferred:GetBackdrop() ~= nil)
local externalCalls = 0
APR:RegisterSkinProvider("Test", function() externalCalls = externalCalls + 1 end, function() return true end)
assert(externalCalls > 0)

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
print("UI foundations: WoW surfaces/external skins, combat deferral and bounded 10000-row viewport passed")
