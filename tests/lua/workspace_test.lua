-- Navigation must preserve lazy pages, technical command access and the active settings category.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
GAMEOPTIONS_MENU = "Options"
APR.title = "APR"
function GetLocale() return "enUS" end
function env.methods:Raise() self.raised = true end
function env.methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/integrations/Gamepad.lua")
dofile("APR-Core/integrations/GamepadNavigation.lua")
dofile("APR-Core/ui/panels/Workspace.lua")

for _, name in ipairs({"RouteBrowser", "StatusPanel", "AboutPanel", "OptionsPanel", "PerformanceDashboard"}) do
    APR[name] = {creates = 0, refreshes = 0}
    local controller = APR[name]
    function controller:Create(parent)
        self.creates = self.creates + 1
        self.frame = APR.UI:Page(parent)
    end
    function controller:Refresh() self.refreshes = self.refreshes + 1 end
end
function APR.OptionsPanel:Select(id) self.selected = id end
SettingsPanel = CreateFrame("Frame")
APR.LayoutEditor = {active = true, Hide = function(self) self.active = false end}
local workspace = APR.Workspace
workspace:Show("route")
assert(not SettingsPanel:IsShown() and not APR.LayoutEditor.active)
assert(workspace.frame:IsShown() and workspace.pages.route:IsShown())
assert(not workspace.frame.gamepadMenu:IsShown(), "Retail without native gamepad UI must hide the controller menu")
assert(workspace.frame.header.Text.point[2] == -8, "A hidden controller menu leaves the title its full width")
assert(APR.RouteBrowser.creates == 1 and APR.StatusPanel.creates == 0)
assert(not workspace.tabs.perf:IsShown(), "Perf is hidden by default")
assert(workspace.tabs.route.point[1] == "BOTTOMRIGHT" and workspace.tabs.route.point[3] == "TOPRIGHT",
    "Navigation attaches above the shell instead of consuming the logo/title area")
assert(workspace.tabs.route.point[5] < 0 and workspace.tabs.route:GetFrameLevel() < workspace.frame:GetFrameLevel(),
    "The window must cover the tabs' overlapping lower edge")
workspace:Show("perf")
assert(workspace.pages.perf:IsShown() and not workspace.pages.route:IsShown(),
    "The technical command can open Perf without enabling its tab")
APR:GetSettingsProfile().showPerformanceTab = true
workspace:LayoutTabs()
assert(workspace.tabs.perf:IsShown())
APR.UI.activeMenu = CreateFrame("Frame")
APR.UI.selectionDialog = CreateFrame("Frame")
workspace:Show("options", "changelog")
assert(not APR.UI.activeMenu:IsShown() and not APR.UI.selectionDialog:IsShown())
assert(APR.OptionsPanel.selected == "changelog")
for _ = 1, 20 do
    workspace:Show("status"); workspace:Show("about"); workspace:Show("options"); workspace:Show("route")
end
for _, name in ipairs({"RouteBrowser", "StatusPanel", "AboutPanel", "OptionsPanel", "PerformanceDashboard"}) do
    assert(APR[name].creates == 1, "Repeated navigation must reuse each page")
end
assert(APR.OptionsPanel.selected == "changelog", "Switching tabs must retain the selected category")
workspace:Hide()
assert(not workspace.frame:IsShown())
workspace:Show("options")
assert(workspace.frame:IsShown() and workspace.pages.options:IsShown())

-- A page that refreshed through OnShow must not be rebuilt by the shell too.
local routes = APR.RouteBrowser
function routes:Refresh()
    self.refreshes = self.refreshes + 1
    self.refreshSerial = (self.refreshSerial or 0) + 1
end
local setShown = routes.frame.SetShown
function routes.frame:SetShown(value)
    local wasShown = self:IsShown()
    setShown(self, value)
    if value and not wasShown then routes:Refresh() end
end
local previous = routes.refreshes
workspace:Show("route")
assert(routes.refreshes == previous + 1, "OnShow and workspace navigation share one refresh")
workspace:Show("route")
assert(routes.refreshes == previous + 2, "An already visible page still receives an explicit refresh")
print("Workspace: lazy navigation, optional Perf tab, command access, category preservation and overlay closure passed")
