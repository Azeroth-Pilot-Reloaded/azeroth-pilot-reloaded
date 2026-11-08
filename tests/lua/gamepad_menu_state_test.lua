local fixture = dofile("tests/lua/gamepad_interface_test.lua")
local pad, env, tick = fixture.pad, fixture.env, fixture.tick
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
pad:CloseMenu(true)
local timers = {}
C_Timer = {
    After = function(delay, callback)
        assert(delay == 0)
        timers[#timers + 1] = callback
    end,
}
local function flush()
    for _ = 1, 30 do
        local pending = timers
        timers = {}
        for _, callback in ipairs(pending) do
            callback()
        end
        tick()
        if #timers == 0 then return end
    end
    error("Menu state callbacks must settle without polling")
end

-- The initial offer precedes route initialization and panel visibility. Later
-- route/visibility events must repair the same open menu without reopening it.
function APR:ActivateRoute(route)
    self.ActiveRoute = route
    return true
end
function hooksecurefunc(object, key, callback)
    local original = object[key]
    object[key] = function(...)
        local values = { original(...) }
        callback(...)
        return unpack(values)
    end
end
APR.ActiveRoute = nil
QuestOrderListPanel = CreateFrame("Frame", nil, UIParent)
QuestOrderListPanel:Hide()
pad:ObserveMenuState()
pad.menuOffered, pad.playerReady = nil, true
GetBindingKey = function() end
pad:OfferMenu()
flush()
assert(pad.menu:IsShown() and not pad.menuButtons.skip:IsEnabled() and not pad.menuButtons.steps:IsEnabled())
APR:ActivateRoute("synthetic-route")
QuestOrderListPanel:Show()
flush()
assert(
    pad.menuButtons.skip:IsEnabled() and pad.menuButtons.rollback:IsEnabled() and pad.menuButtons.steps:IsEnabled(),
    "The initial offer must track the route and panels that become available after login"
)
QuestOrderListPanel:Hide()
flush()
assert(not pad.menuButtons.steps:IsEnabled())
APR:ActivateRoute(nil)
flush()
assert(not pad.menuButtons.skip:IsEnabled() and not pad.menuButtons.rollback:IsEnabled())

local keys = {}
GetBindingKey = function(action)
    assert(action == "APR_MENU")
    return keys[1], keys[2]
end
function SetBinding() error("Closing a menu must not assign a binding") end
function SaveBindings() error("Closing a menu must not persist a binding") end
local function warning()
    flush()
    local dialog = APR.UI.selectionDialog
    assert(pad.menuClosePending and dialog and dialog:IsShown())
    assert(dialog.description:GetText() == L.GAMEPAD_MENU_UNBOUND_CONFIRM)
    return dialog
end
local function accept(dialog)
    dialog.acceptButton:GetScript("OnClick")(dialog.acceptButton)
    flush()
end
local function cancel(dialog)
    dialog.cancelButton:GetScript("OnClick")(dialog.cancelButton)
    flush()
end

pad.menu:SmartNavigationCloseHandler()
local dialog = warning()
assert(SmartNavigation:GetCurrentButton() == dialog.cancelButton, "Keep the safe choice selected by default")
cancel(dialog)
assert(pad.menu:IsShown() and not pad.menuClosePending, "Cancel leaves the unbound menu accessible")
pad.menu.close:GetScript("OnClick")(pad.menu.close)
accept(warning())
assert(not pad.menu:IsShown() and not pad.menuClosePending)

pad:ToggleMenu()
flush()
pad.menu:Hide() -- WoW's Escape list calls Hide directly.
dialog = warning()
assert(pad.menu:IsShown(), "Escape restores the popup behind its confirmation without replacing Frame:Hide")
cancel(dialog)
keys = { "F10" }
pad:CloseMenu()
accept(warning())
assert(not pad.menu:IsShown(), "A keyboard-only shortcut still needs a warning for controller access")

-- GetBindingKey may leave the first slot empty. A controller binding in either
-- slot suppresses the warning and supplies the visible label.
keys = { nil, "CTRL-PAD4" }
pad:ToggleMenu()
flush()
local binding, controller = pad:GetMenuBinding()
assert(binding == "CTRL-PAD4" and controller)
pad.menu:SmartNavigationCloseHandler()
flush()
assert(not pad.menu:IsShown() and not pad.menuClosePending and not dialog:IsShown())

keys = {}
pad:ToggleMenu()
flush()
pad.menuButtons.route:GetScript("OnClick")(pad.menuButtons.route)
flush()
assert(
    not pad.menu:IsShown() and not pad.menuClosePending and not dialog:IsShown(),
    "An action transition must not warn about closing the menu"
)
pad:ToggleMenu()
flush()
pad:CaptureMenuBinding()
flush()
pad:CancelMenuBinding()
flush()
assert(
    pad.menu:IsShown() and not pad.menuClosePending and not dialog:IsShown(),
    "Cancelling capture returns to the menu; the warning belongs to the menu's own dismissal"
)
pad:CloseMenu()
accept(warning())

pad:ToggleMenu()
flush()
pad:CloseMenu() -- Its deferred warning may be superseded by explicit navigation.
pad:CloseMenu(true)
flush()
assert(not pad.menu:IsShown() and not pad.menuClosePending and not dialog:IsShown())
pad:ToggleMenu()
flush()
env.setCombat(true)
pad:CloseMenu()
flush()
assert(not pad.menu:IsShown() and not pad.menuClosePending and not dialog:IsShown())
env.setCombat(false)
print(
    "Gamepad menu state: late login route/panels, live availability, B/cross/Escape warnings, cancel/accept, binding slots and action transitions passed"
)

-- Saved custom chords are recognized after login and displayed as separate labels.
APRData = APRData or {}
APRData.GamepadMenuChord = { "PADDUP", "PADRSHOULDER" }
local chosen, controller = pad:GetMenuBinding()
assert(controller and chosen == pad:FormatMenuChord(APRData.GamepadMenuChord))
pad:RefreshMenuBindings()
assert(pad.menu.bindingLabel:GetText() == KEY_BINDINGS .. ": " .. chosen)
APRData.GamepadMenuChord = { "PADDUP", "PADDUP" }
assert(not pad:GetMenuChord(), "Malformed saved chords are ignored")
APRData.GamepadMenuChord = nil

-- Login/reload offers respect both native bindings and saved APR chords.
local function offerWithBinding(nativeKeys, chord, expectedOpen)
    pad:CloseMenu(true)
    keys, APRData.GamepadMenuChord = nativeKeys, chord
    pad.menuOffered = nil
    pad:OfferMenu()
    flush()
    assert(pad.menu:IsShown() == expectedOpen, "Only an unbound controller menu needs an automatic offer")
    assert(pad.menuOffered, "A bound menu still completes the initial offer")
    pad:CloseMenu(true)
    pad:OfferMenu()
    flush()
    assert(not pad.menu:IsShown(), "Later restoration must not reopen a completed offer")
end
offerWithBinding({ "PAD4" }, nil, false)
offerWithBinding({ nil, "CTRL-PAD4" }, nil, false)
offerWithBinding({}, { "PADDUP", "PADRSHOULDER" }, false)
offerWithBinding({}, { "PADDUP", "PADDUP" }, true)
offerWithBinding({}, nil, true)
offerWithBinding({ "F10" }, nil, true)

-- Bindings can finish loading while the initial offer is deferred.
keys, pad.menuOffered = {}, nil
pad:OfferMenu()
keys = { "PAD4" }
flush()
assert(not pad.menu:IsShown(), "Recheck the binding immediately before opening the menu")
keys = {}
