-- Instantiate the production shell, route browser and menu with the adapter enabled.
local env = dofile("tests/lua/route_browser_test_env.lua")
local created, createFrame = {}, CreateFrame
function CreateFrame(kind, ...)
    local frame = createFrame(kind, ...); frame.kind = kind
    created[#created + 1] = frame
    return frame
end
function env.methods:IsObjectType(kind) return self.kind == kind end
function env.methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function env.methods:GetChildren() return unpack(self.children or {}) end
function env.methods:GetScript(key) return self.scripts[key] end
local show, hide = env.methods.Show, env.methods.Hide
local function notifyShown(frame)
    if not frame:IsVisible() then return end
    if frame.scripts.OnShow then frame.scripts.OnShow(frame) end
    for _, child in ipairs(frame.children or {}) do notifyShown(child) end
end
function env.methods:Show()
    local visible = self:IsVisible(); show(self)
    -- WoW fires OnShow on shown descendants when their hidden ancestor opens.
    if not visible then notifyShown(self) end
end
function env.methods:Hide()
    local changed = self.shown; hide(self)
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
local active, current
InputUtil = {IsGamepadUIEnabled = function() return true end}
GamepadMode = {FrameControlsManager = {
    FrameShown = function(_, frame) active = frame; return true end,
    FrameHidden = function(_, frame) if active == frame then active = nil end end,
    GetActiveFrame = function() return active end,
    FocusFrame = function(_, frame) active = frame end,
}}
SmartNavigation = {
    GetActiveFrame = function() return active end, GetCurrentButton = function() return current end,
    RefreshButtonGroups = function() end, SelectFirstButton = function() end,
    SelectButton = function(_, frame) current = frame end,
}
SMART_NAV_INPUT_DIRECTION = {LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down"}
function SmartNavigation_AddJumpNavigationOverride(frame, key, callback)
    frame.overrides = frame.overrides or {}; frame.overrides[key] = callback
end
local function tick()
    for _, frame in ipairs(created) do if frame:IsVisible() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.01) end end
end
function APR:RegisterSupportedEvent(frame, event) frame:RegisterEvent(event) end
function GetLocale() return "enUS" end
GAMEOPTIONS_MENU, KEY_BINDINGS = "Options", "Key Bindings"
APR.title = "APR"
dofile("APR-Core/integrations/Gamepad.lua")
dofile("APR-Core/integrations/GamepadNavigation.lua")
dofile("APR-Core/integrations/GamepadControls.lua")
dofile("APR-Core/ui/panels/Workspace.lua")
for _, name in ipairs({"StatusPanel", "AboutPanel", "OptionsPanel", "PerformanceDashboard"}) do
    APR[name] = {Create = function(self, parent)
        self.frame = APR.UI:Page(parent)
        self.control = APR.UI:Button(self.frame.content, "Detail", 100, function() end)
    end}
end
local workspace, pad = APR.Workspace, APR.Gamepad
workspace:Show("route"); tick()
local browser = APR.RouteBrowser
assert(browser.prefabs[2].overrides.left() == browser.prefabs[1])
assert(browser.prefabs[2].overrides.right() == browser.prefabs[3])
assert(browser.search.overrides.right() == browser.category)
local row = browser.list.active[1]
assert(row and row.overrides.left() == row.favorite and row.overrides.right() == row.add)
assert(row.aprGamepadRect == row.name, "The route label must not cover its separate action hitboxes")

local tab = workspace.tabs.options
current = tab
tab:GetScript("OnClick")(tab, "RightButton"); tick()
assert(workspace.active == "options" and current == APR.OptionsPanel.control)
workspace.frame:SmartNavigationCloseHandler()
assert(current == tab and workspace.frame:IsShown())

workspace.frame.gamepadMenu:GetScript("OnClick")(workspace.frame.gamepadMenu); tick()
assert(pad.menu:IsShown() and active == pad.menu)
assert(pad.menuButtons.layout and pad.menuButtons.status and pad.menuButtons.about and pad.menuButtons.worldcoords)
assert(not pad.menuButtons.group:IsEnabled(), "Absent gameplay panels cannot be selected")
pad.menuButtons.route:GetScript("OnClick")(pad.menuButtons.route); tick()
assert(not pad.menu:IsShown() and workspace.active == "route")
-- Capture is also constructible using the real window and selection-dialog factories.
pad:CaptureMenuBinding(); assert(pad.bindingCapture:IsShown())
pad.bindingCapture:GetScript("OnKeyDown")(pad.bindingCapture, "ESCAPE")
assert(not pad.bindingCapture:IsShown())
-- Image controls manipulate the real zoom/pan layout and survive pooled reuse.
local imageTexture
function env.methods:SetTexture(value)
    self.texture = value
    if value == "test-image" then imageTexture = self end
end
function env.methods:GetTexture() return self.texture end
function APR:ResolveUIFileAsset(path) return path end
function APR:RegisterUiSpecialFrame() end
dofile("APR-Core/ui/route/CurrentStepImagePreview.lua")
APR.currentStepImagePreview:Show("test-image")
local preview = APRCurrentStepImagePreviewFrame1
local minus
for _, frame in ipairs({preview:GetChildren()}) do
    if frame:GetFontString() and frame:GetFontString():GetText() == "-" then minus = frame end
end
assert(minus and active == preview and imageTexture)
local plus = minus.overrides.right()
local baseWidth = imageTexture:GetWidth()
plus:GetScript("OnClick")(plus)
assert(imageTexture:GetWidth() > baseWidth)
local left = plus.overrides.right()
left:GetScript("OnClick")(left)
assert(imageTexture.point[4] < 0, "The left pan button must move the zoomed image")
preview:SmartNavigationCloseHandler()
assert(not preview:IsShown() and not imageTexture:GetTexture())
local allocations = #created
APR.currentStepImagePreview:Show("test-image")
assert(#created == allocations and imageTexture:GetWidth() == baseWidth and imageTexture.point[4] == 0)
preview:Hide()
print("Gamepad interface: production route neighbours, workspace detail entry, menu actions and binding window passed")
