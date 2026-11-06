-- Instantiate the production shell, route browser and menu with the adapter enabled.
local env = dofile("tests/lua/route_browser_test_env.lua")
local created, createFrame = {}, CreateFrame
function CreateFrame(kind, ...)
    local frame = createFrame(kind, ...)
    frame.kind = kind
    created[#created + 1] = frame
    return frame
end
function env.methods:IsObjectType(kind)
    return self.kind == kind or (self.kind == "CheckButton" and kind == "Button")
end
function env.methods:GetObjectType() return self.kind end
function env.methods:GetRect()
    if self.rect then return unpack(self.rect) end
end
function env.methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function env.methods:GetChildren() return unpack(self.children or {}) end
function env.methods:GetScript(key) return self.scripts[key] end
function env.methods:Raise() self.raised = true end
local show, hide = env.methods.Show, env.methods.Hide
local function notifyShown(frame)
    if not frame:IsVisible() then return end
    if frame.scripts.OnShow then frame.scripts.OnShow(frame) end
    for _, child in ipairs(frame.children or {}) do
        notifyShown(child)
    end
end
function env.methods:Show()
    local visible = self:IsVisible()
    show(self)
    -- WoW fires OnShow on shown descendants when their hidden ancestor opens.
    if not visible then notifyShown(self) end
end
function env.methods:Hide()
    local changed = self.shown
    hide(self)
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
local active, current
local enabled, transitions = true, {}
local popupReturns = {}
-- Model the modern native boundary: fields scanned by Blizzard must go through
-- its setter, and internal focus methods cannot be called from addon code.
local navigationFlags = setmetatable({}, { __mode = "k" })
SmartNavigationSecureHelper = {
    SetSecureValue = function(_, frame, key, value)
        assert(not InCombatLockdown(), "Secure navigation fields cannot change in combat")
        value = not not value -- native boolean keys use CoerceToBoolean
        navigationFlags[frame] = navigationFlags[frame] or {}
        navigationFlags[frame][key] = { value = value }
        frame[key] = value
    end,
}
local function checkNavigationFlags(frame)
    for _, key in ipairs({ "smartNavigationIgnored", "smartNavigationIgnoredDontPropagate", "smartNavigationCanFocus" }) do
        if frame[key] ~= nil then
            local flag = navigationFlags[frame] and navigationFlags[frame][key]
            assert(flag and flag.value == frame[key], "Native navigation must not read a directly assigned " .. key)
        end
    end
    for _, child in ipairs(frame.children or {}) do
        checkNavigationFlags(child)
    end
end
InputUtil = {
    IsGamepadUIEnabled = function() return enabled end,
    RegisterForInterfaceTransitions = function() end,
    RegisterGamepadInit = function(_, callback)
        transitions.init = callback
        callback()
    end,
    RegisterGamepadUninit = function(_, callback) transitions.uninit = callback end,
}
GamepadMode = {
    FrameControlsManager = {
        FrameShown = function(self, frame)
            checkNavigationFlags(frame)
            active = frame
            self.isUIFocused = true
            return true
        end,
        FrameHidden = function(_, frame)
            checkNavigationFlags(frame)
            if active == frame then active = nil end
        end,
        GetActiveFrame = function() return active end,
        FocusFrame = function() error("FocusFrame is internal; it can taint protected input updates") end,
        HandlePopupShown = function(self, frame)
            popupReturns[frame] = active
            self:FrameShown(frame)
        end,
        HandlePopupHide = function(self, frame)
            local opener = popupReturns[frame]
            popupReturns[frame] = nil
            self:FrameHidden(frame)
            if opener and opener:IsVisible() then active = opener end
        end,
    },
}
SmartNavigation = {
    GetActiveFrame = function() return active end,
    GetCurrentButton = function() return current end,
    RefreshButtonGroups = function(_, frame) checkNavigationFlags(frame) end,
    SelectFirstButton = function() end,
    SelectButton = function() error("SelectButton is secure-only; use SetTargetButtonForFrame") end,
    SetTargetButtonForFrame = function(_, owner, button)
        assert(owner == active, "Focus requests must address the active window")
        if current == button then return end
        if current and current.OnSmartNavDeselect then current:OnSmartNavDeselect() end
        current = button
        if button and button.OnSmartNavSelect then button:OnSmartNavSelect() end
    end,
}
SMART_NAV_INPUT_DIRECTION = { LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down" }
function SmartNavigation_AddJumpNavigationOverride(frame, key, callback)
    frame.overrides = frame.overrides or {}
    frame.overrides[key] = callback
end
local function tick()
    for _, frame in ipairs(created) do
        if frame:IsVisible() and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 0.01) end
    end
end
function APR:RegisterSupportedEvent(frame, event) frame:RegisterEvent(event) end
function GetLocale() return "enUS" end
GAMEOPTIONS_MENU, KEY_BINDINGS = "Options", "Key Bindings"
local function defaultMenuBinding() return "PAD4" end
GetBindingKey = defaultMenuBinding
APR.title = "APR"
dofile("APR-Core/integrations/Gamepad.lua")
dofile("APR-Core/integrations/GamepadNavigation.lua")
dofile("APR-Core/integrations/GamepadControls.lua")
dofile("APR-Core/integrations/GamepadInput.lua")
dofile("APR-Core/integrations/GamepadMenu.lua")
dofile("APR-Core/ui/panels/Workspace.lua")
for _, name in ipairs({ "StatusPanel", "AboutPanel", "OptionsPanel", "PerformanceDashboard" }) do
    APR[name] = {
        Create = function(self, parent)
            self.frame = APR.UI:Page(parent)
            self.control = APR.UI:Button(self.frame.content, "Detail", 100, function() end)
        end,
    }
end
local finderOpened = 0
APR.PartyFinderPanel = { Show = function() finderOpened = finderOpened + 1 end }
local workspace, pad = APR.Workspace, APR.Gamepad
workspace:Show("route")
tick()
pad = APR.Gamepad
pad:DispatchInput(workspace.frame, "PADRTRIGGER", true)
tick()
assert(workspace.active == "status", "RT changes the main workspace tab")
pad:DispatchInput(workspace.frame, "PADRTRIGGER", false)
assert(workspace.active == "status")
pad:DispatchInput(workspace.frame, "PADLTRIGGER", true)
tick()
assert(workspace.active == "route", "LT restores the preceding main workspace tab")
assert(workspace.frame.gamepadMenu:IsShown(), "Enabled native gamepad UI exposes the controller menu")
-- Hit testing must work even if the drag header is ahead of its sibling in
-- mouse ordering. Calling OnClick directly cannot reproduce an overlapping frame.
local function headerBox(widget)
    local point, relative, relativePoint, x, y = widget:GetPoint()
    if type(relative) ~= "table" then
        x, y, relative, relativePoint = relative or 0, relativePoint or 0, widget:GetParent(), point
    end
    local left, top, right
    if relative == workspace.frame then
        left, top, right = 0, relative:GetHeight(), relative:GetWidth()
    else
        left, top, right = headerBox(relative)
    end
    local edge = relativePoint == "TOPLEFT" and left or right
    right, top = edge + x, top + y
    return right - widget:GetWidth(), top, right, top - widget:GetHeight()
end
local function hitHeader(x, y, siblings)
    local target
    for _, widget in ipairs(siblings) do
        local left, top, right, bottom = headerBox(widget)
        if
            x >= left
            and x <= right
            and y >= bottom
            and y <= top
            and (not target or widget:GetFrameLevel() >= target:GetFrameLevel())
        then
            target = widget
        end
    end
    return target
end
local menuButton, header = workspace.frame.gamepadMenu, workspace.frame.header
local menuLeft, menuTop, menuRight, menuBottom = headerBox(menuButton)
assert(menuButton == workspace.tabs.gamepad, "Controller access belongs to the workspace tab row")
local menuPoint, menuAnchor, menuRelativePoint = menuButton:GetPoint(1)
assert(menuPoint == "BOTTOMRIGHT" and menuAnchor == workspace.frame and menuRelativePoint == "TOPRIGHT")
local _, _, _, menuX = menuButton:GetPoint(1)
local _, _, _, routeX = workspace.tabs.route:GetPoint(1)
assert(menuX < routeX, "The controller entry must precede Route in the tab row")
local _, closeAnchor = workspace.frame.close:GetPoint(1)
assert(
    closeAnchor == workspace.frame,
    "The close cross must stay attached to the shell, not overlap the controller tab"
)
enabled = false
transitions.uninit()
assert(not workspace.frame.gamepadMenu:IsShown(), "Disabling gamepad UI hides its menu immediately")
enabled = true
transitions.init()
assert(workspace.frame.gamepadMenu:IsShown(), "Enabling gamepad UI restores its menu without reopening settings")
local browser = APR.RouteBrowser
assert(browser.prefabs[2].overrides.left() == browser.prefabs[1])
assert(browser.prefabs[2].overrides.right() == browser.prefabs[3])
assert(browser.search.overrides.right() == browser.category)
local row = browser.list.active[1]
assert(row and row.overrides.left() == row.favorite and row.overrides.right() == row.add)
assert(row.aprGamepadRect == row.name, "The route label must not cover its separate action hitboxes")

local tab = workspace.tabs.options
current = tab
tab:GetScript("OnClick")(tab, "RightButton")
tick()
assert(workspace.active == "options" and current == APR.OptionsPanel.control)
workspace.frame:SmartNavigationCloseHandler()
assert(current == tab and workspace.frame:IsShown())

workspace.frame.gamepadMenu:GetScript("OnClick")(workspace.frame.gamepadMenu)
tick()
assert(pad.menu:IsShown() and active == pad.menu)
assert(
    pad.menu:GetFrameStrata() == "FULLSCREEN_DIALOG" and pad.menu.raised,
    "The controller menu must open above the workspace"
)
assert(
    pad.windows[pad.menu].popup and current == pad.menuButtons.route,
    "Opening the menu must focus its first action through the public native API"
)
assert(pad.menuButtons.layout and pad.menuButtons.status and pad.menuButtons.about and not pad.menuButtons.worldcoords)
assert(pad.menuButtons.partyfinder:IsEnabled())
pad:RunAction("partyfinder")
assert(finderOpened == 1)
assert(not pad.menuButtons.group:IsEnabled(), "Absent gameplay panels cannot be selected")
pad.menu:SmartNavigationCloseHandler()
assert(not pad.menu:IsShown() and active == workspace.frame, "Back closes the menu and restores its opener")
APR.settings.profile.showPerformanceTab = false
workspace:LayoutTabs()
workspace:Show("options")
tick()
pad:DispatchInput(workspace.frame, "PADRTRIGGER", true)
tick()
assert(
    not pad.menu:IsShown() and workspace.selectedTab == "gamepad" and current == workspace.tabs.gamepad,
    "Trigger paging selects the controller entry without opening its popup"
)
pad:DispatchInput(workspace.frame, "PADRTRIGGER", true)
tick()
assert(workspace.active == "route", "RT continues to Route after selecting the controller entry")
pad:DispatchInput(workspace.frame, "PADLTRIGGER", true)
tick()
assert(not pad.menu:IsShown() and current == workspace.tabs.gamepad)
workspace.tabs.gamepad.overrides.down()
tick()
assert(not pad.menu:IsShown(), "Only activation may open the controller popup, not Down from its tab")
workspace.tabs.gamepad:GetScript("OnClick")(workspace.tabs.gamepad)
tick()
assert(pad.menu:IsShown(), "Confirm activates the selected controller entry")
pad.menu:SmartNavigationCloseHandler()
APR.settings.profile.showPerformanceTab = true
workspace:LayoutTabs()
workspace:Show("options")
tick()
pad:DispatchInput(workspace.frame, "PADRTRIGGER", true)
tick()
assert(workspace.active == "perf", "An available Performance tab participates in trigger paging")
APR.settings.profile.showPerformanceTab = false
workspace:Show("options")
tick()
-- The controller menu has a complete grid on each page; directions retain a
-- predictable row/column and bypass unavailable actions rather than trapping focus.
pad:ToggleMenu()
tick()
assert(pad.menuPage == 1 and pad.menuButtons.route.active)
pad:DispatchInput(pad.menu, "PADRTRIGGER", true)
tick()
assert(pad.menuPage == 2 and current == pad.menuTabs[2], "RT switches to an empty page without losing its focus")
pad:DispatchInput(pad.menu, "PADLTRIGGER", true)
tick()
assert(pad.menuPage == 1 and current == pad.menuButtons.route, "LT returns to the previous page's usable actions")
pad:DispatchInput(pad.menu, "PADLTRIGGER", false)
assert(pad.menuPage == 1, "Releasing a trigger must not switch pages twice")
assert(pad.menuButtons.route.overrides.left() == true)
assert(pad.menuButtons.route.overrides.right() == pad.menuButtons.partyfinder)
assert(pad.menuButtons.route.overrides.up() == pad.menuTabs[1])
assert(pad.menuButtons.partyfinder.overrides.right() == true)
for _, action in ipairs({ "step", "steps", "skip", "rollback" }) do
    pad.menuButtons[action]:SetEnabled(false)
end
assert(
    pad.menuButtons.partyfinder.overrides.down() == pad.menu.bindingButton,
    "Unavailable gameplay tiles must not trap the main page's vertical navigation"
)
local shownActions = 0
for _, button in pairs(pad.menuButtons) do
    if button:IsVisible() then shownActions = shownActions + 1 end
end
assert(shownActions == 6, "All primary actions fit without a scroll viewport")
pad.menuTabs[3]:OnSmartNavSelect()
tick()
assert(pad.menuPage == 3 and pad.menuButtons.about:IsVisible() and not pad.menuButtons.route:IsVisible())
pad.menuTabs[3].overrides.down()
tick()
assert(
    current == pad.menuButtons.options,
    "Entering a page focuses the first available action, skipping missing optional modules"
)
pad.menuButtons.status:SetEnabled(false)
assert(
    pad.menuButtons.options.overrides.down() == pad.menuButtons.about,
    "When the next row's same-column action is unavailable, its usable neighbour remains reachable"
)
pad.menuButtons.about:OnSmartNavSelect()
assert(pad.menuButtons.about.active)
pad.menuButtons.about:OnSmartNavDeselect()
assert(not pad.menuButtons.about.active)
local initialWidth, initialHeight = UIParent:GetWidth(), UIParent:GetHeight()
UIParent:SetSize(580, 460)
pad:LayoutMenu()
local menuScale = pad.menu:GetScale()
assert(
    pad.menu:GetWidth() * menuScale <= 580 - 48 and pad.menu:GetHeight() * menuScale <= 460 - 48,
    "The complete controller menu fits a smaller UI canvas"
)
UIParent:SetSize(initialWidth, initialHeight)
pad:LayoutMenu()
-- Only inspect the existing binding; never replace it to display a hint.
local bindingKeys = { "F10", "CTRL-PAD4" }
C_KeyBindings = {
    GetBindingContextForAction = function(action)
        assert(action == "APR_MENU")
        return 3
    end,
}
GetBindingKey = function(action, mode, context)
    assert(action == "APR_MENU" and mode == nil and context == 3)
    return unpack(bindingKeys)
end
GetBindingText = function(key) return "key:" .. key end
InputIconTextureSetUtility = { GetNormalActiveInputIconButtonTexture = function(key) return "glyph:" .. key end }
local nativeTexture = env.methods.SetTexture
function env.methods:SetTexture(texture)
    assert(not texture or texture:sub(1, 6) ~= "glyph:", "An atlas cannot be rendered with SetTexture")
    self.texture = texture
end
function env.methods:SetAtlas(atlas) self.atlas = atlas end
pad:RefreshMenuBindings()
assert(pad.menu.bindingLabel:GetText() == "Key Bindings: key:CTRL-PAD4")
assert(pad.menu.inputHints[2].icon.atlas == "glyph:PAD1" and pad.menu.inputHints[3].icon.atlas == "glyph:PAD2")
bindingKeys = {}
NOT_BOUND = "Not bound"
pad.menu:GetScript("OnEvent")(pad.menu, "UPDATE_BINDINGS")
assert(pad.menu.bindingLabel:GetText() == "Key Bindings: Not bound")
InputIconTextureSetUtility = nil
pad:RefreshMenuBindings()
assert(
    pad.menu.inputHints[2].badge:IsShown()
        and pad.menu.inputHints[2].badge.text:GetText() == "A"
        and pad.menu.inputHints[3].badge.text:GetText() == "B",
    "Clients without native glyph utilities retain visible A/B button badges"
)
env.methods.SetTexture = nativeTexture
GetBindingKey = defaultMenuBinding
GetBindingText, NOT_BOUND = nil, nil
C_KeyBindings = nil
pad.menu:Hide()
local nativeWindow = CreateFrame("Frame", nil, UIParent)
GamepadMode.FrameControlsManager:FrameShown(nativeWindow)
pad:ToggleMenu()
tick()
pad.menu:SmartNavigationCloseHandler()
assert(active == nativeWindow, "The native popup lifecycle must restore an opener not registered with APR")
nativeWindow:Hide()
pad:FocusWindow(workspace.frame)
workspace.frame.gamepadMenu:GetScript("OnClick")(workspace.frame.gamepadMenu)
tick()
pad.menuButtons.route:GetScript("OnClick")(pad.menuButtons.route)
tick()
assert(not pad.menu:IsShown() and workspace.active == "route")
-- Re-enter an already registered workspace while another APR window has focus.
local other = CreateFrame("Frame", nil, UIParent)
pad:RegisterWindow(other)
assert(active == other)
pad:RunAction("options")
tick()
assert(active == workspace.frame and workspace.active == "options")
other:Hide()
GamepadMode.FrameControlsManager.isUIFocused = false
pad:RunAction("route")
tick()
assert(
    active == workspace.frame and GamepadMode.FrameControlsManager.isUIFocused,
    "A remembered window must regain input after focus was returned to the character"
)
-- Capture is also constructible using the real window and selection-dialog factories.
pad:CaptureMenuBinding()
assert(pad.bindingCapture:IsShown())
pad.bindingCapture:GetScript("OnKeyDown")(pad.bindingCapture, "ESCAPE")
assert(not pad.bindingCapture:IsShown() and not pad.bindingCapture.captureListening)
assert(
    not APR.UI.selectionDialog or not APR.UI.selectionDialog:IsShown(),
    "Leaving shortcut capture returns to its opener without a second warning"
)
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
for _, frame in ipairs({ preview:GetChildren() }) do
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
-- Diagnostics are sampled after chat closes; opening their report must not
-- accidentally measure the chat box or the report's own newly focused window.
local capturedReport, deferred
local originalTimer, originalReport = C_Timer, APR.UI.ShowTextReport
C_Timer = {
    After = function(delay, callback)
        if delay == 0.2 then
            deferred = callback
        else
            callback()
        end
    end,
}
APR.UI.ShowTextReport = function(_, _, report) capturedReport = report end
active = CreateFrame("Frame", nil, UIParent)
pad:ShowDiagnostics()
assert(not capturedReport and deferred, "The slash command must defer its snapshot until chat closes")
pad.menu:Show()
active, current = pad.menu, pad.menuButtons.route
current.rect = { 100, 100, 145, 30 }
deferred()
assert(not pad.menu:IsShown(), "The report must not open behind the controller menu")
assert(
    capturedReport:find("APR window registered: true", 1, true)
        and capturedReport:find("Selected control: Button", 1, true)
        and capturedReport:find("Selected rectangle: 100, 100, 145, 30", 1, true)
)
local originalNavigation, originalMode = SmartNavigation, GamepadMode
SmartNavigation, GamepadMode = nil, nil
assert(
    pad:GetDiagnosticReport():find("Native gamepad UI: false", 1, true),
    "Diagnostics must also explain unavailable native navigation without throwing"
)
SmartNavigation, GamepadMode = originalNavigation, originalMode
C_Timer, APR.UI.ShowTextReport = originalTimer, originalReport
-- A native input failure is observed without changing Blizzard's state, and a
-- bounded persisted snapshot survives reload for diagnosis of actual client taint.
local originalInspector = issecurevariable
local checked = 0
issecurevariable = function(object, key)
    assert(type(key) == "string", "The native API cannot inspect numeric table slots")
    checked = checked + 1
    if object == GamepadMode.FrameControlsManager and key == "isUIFocused" then return false, "SyntheticAddon" end
    return true
end
pad:RecordBlockedAction("ForeignAddon", "SetPreferredGamepadInteractTarget()")
assert(checked == 0 and not APRData.GamepadTaint)
pad:RecordBlockedAction("APR", "SetPreferredGamepadInteractTarget()")
assert(APRData.GamepadTaint.report:find("focus.isUIFocused: SyntheticAddon", 1, true))
local reads = checked
pad:RecordBlockedAction("APR", "SetPreferredGamepadInteractTarget()")
assert(checked == reads, "Repeated blocked actions retain a single bounded native-state snapshot")
issecurevariable = originalInspector

-- Offer the controller menu once per mode activation, after the player is ready.
pad.playerReady, pad.menuOffered = true, nil
pad:OfferMenu()
assert(pad.menu:IsShown() and pad.menuOffered)
pad.menu:Hide()
pad:OfferMenu()
assert(not pad.menu:IsShown(), "Closing the offer must not reopen it on later addon events")
transitions.uninit()
enabled = false
pad:OfferMenu()
assert(not pad.menu:IsShown())
enabled = true
transitions.init()
assert(pad.menu:IsShown(), "Re-enabling gamepad UI must directly offer its menu")
pad.menu:Hide()
pad.menuOffered = nil
env.setCombat(true)
pad:OfferMenu()
assert(not pad.menu:IsShown())
env.setCombat(false)
pad:OfferMenu()
assert(pad.menu:IsShown(), "An offer deferred by combat remains available afterward")
print("Gamepad interface: production route neighbours, workspace detail entry, menu actions and binding window passed")
return { env = env, pad = pad, tick = tick }
