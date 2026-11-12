local fixture = dofile("tests/lua/gamepad_test.lua")
local pad, env, UI = fixture.pad, fixture.env, APR.UI
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
L.GAMEPAD_BIND_CONFIRM, L.GAMEPAD_BIND_REPLACE, L.GAMEPAD_BIND_SAVED = "Assign %s?", "Replaces %s", "Saved %s"
function UI:Window()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.content = CreateFrame("Frame", nil, frame)
    frame:Hide()
    pad:RegisterWindow(frame)
    return frame
end
function UI:Label(parent, text)
    local label = parent:CreateFontString()
    label:SetText(text)
    return label
end
function UI:Button(parent, text, width, callback)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetScript("OnClick", callback)
    frame:SetText(text)
    return frame
end
local confirmation, confirmationCount = nil, 0
function UI:ShowConfirmationDialog(message, accept, cancel)
    confirmationCount = confirmationCount + 1
    confirmation = { message = message, accept = accept, cancel = cancel }
end
function env.methods:EnableGamePadButton(value) self.padEnabled = value end
function env.methods:SetValue(value)
    local old = self.value
    self.value = value
    if old ~= value and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function APR:RegisterSupportedEvent(frame, event) frame:RegisterEvent(event) end
dofile("APR-Core/integrations/GamepadControls.lua")
local bindings, saves = { ["CTRL-PAD4"] = "JUMP" }, 0
function GetCVar(name) return name == "GamePadEmulateCtrl" and "PADLTRIGGER" or "none" end
function GetConvertedKeyOrButton(key) return key end
function IsKeyPressIgnoredForBinding(key) return key == "PADIGNORE" end
function CreateKeyChordStringUsingMetaKeyState(key) return "CTRL-" .. key end
C_KeyBindings = {
    GetBindingContextForAction = function(action)
        assert(action == "APR_MENU")
        return 2
    end,
}
function GetBindingAction(key, checkOverride, context)
    assert(context == 2 and not checkOverride)
    return bindings[key] or ""
end
function SetBinding(key, action, context)
    assert(context == 2)
    bindings[key] = action
    return true
end
function GetCurrentBindingSet() return 2 end
function SaveBindings(set)
    assert(set == 2)
    saves = saves + 1
end

pad:CaptureMenuBinding()
local capture = pad.bindingCapture
assert(capture:IsShown() and capture.padEnabled)
local press = capture:GetScript("OnGamePadButtonDown")
local release = capture:GetScript("OnGamePadButtonUp")
press(capture, "PADLTRIGGER")
assert(not confirmation and capture:IsShown())
press(capture, "PADIGNORE")
assert(not confirmation and capture:IsShown())
press(capture, "PAD4")
assert(
    not confirmation and capture:IsShown(),
    "Button-down events should wait for a release before confirming a binding"
)
release(capture, "PAD4")
assert(not capture:IsShown() and not capture.padEnabled)
assert(confirmation.message:find("CTRL%-PAD4") and confirmation.message:find("JUMP"))
assert(bindings["CTRL-PAD4"] == "JUMP" and saves == 0, "Capturing must not silently steal a binding")
confirmation.accept()
assert(bindings["CTRL-PAD4"] == "APR_MENU" and saves == 1)
local confirmationsBeforeCancel = confirmationCount
pad:CaptureMenuBinding()
press(capture, "PADBACK")
assert(
    not capture:IsShown() and saves == 1 and confirmationCount == confirmationsBeforeCancel,
    "Leaving capture returns to the menu; the unbound warning belongs to closing that menu"
)
pad:CaptureMenuBinding()
press(capture, "PAD3")
assert(
    capture:IsShown() and confirmationCount == confirmationsBeforeCancel,
    "A fresh press should wait for the matching release before acting"
)
release(capture, "PAD3")
assert(
    not capture:IsShown() and not bindings["CTRL-PAD3"] and saves == 1,
    "Binding capture should only resolve on release, not on the press itself"
)
local confirmationsBeforeEscape = confirmationCount
pad:CaptureMenuBinding()
capture:GetScript("OnKeyDown")(capture, "ESCAPE")
assert(not capture:IsShown() and confirmationCount == confirmationsBeforeEscape)
pad:CaptureMenuBinding()
capture:Hide()
assert(
    not capture.captureListening and confirmationCount == confirmationsBeforeEscape,
    "Closing capture must neither save a shortcut nor open the menu's warning"
)
pad:CaptureMenuBinding()
local confirmationsBeforeFreshPress = confirmationCount
press(capture, "PAD3")
assert(capture:IsShown() and confirmationCount == confirmationsBeforeFreshPress)
release(capture, "PAD3")
env.setCombat(true)
confirmation.accept()
env.setCombat(false)
assert(not bindings["CTRL-PAD3"] and saves == 1, "A stale confirmation cannot bind in combat")
local confirmationsBeforeDisconnect = confirmationCount
pad:CaptureMenuBinding()
capture:GetScript("OnEvent")(capture, "GAME_PAD_DISCONNECTED")
assert(not capture:IsShown() and not capture.padEnabled)
assert(
    confirmationCount == confirmationsBeforeDisconnect,
    "Disconnect must immediately release capture without an interactive warning"
)

-- Capture the chord while held, not the modifier state after release.
local chordPrefix = ""
function CreateKeyChordStringUsingMetaKeyState(key) return chordPrefix .. key end
pad:CaptureMenuBinding()
local beforeChord = confirmationCount
release(capture, "PAD4")
assert(confirmationCount == beforeChord, "An unmatched release cannot bind")
press(capture, "PAD4")
chordPrefix = "CTRL-SHIFT-"
press(capture, "PADLTRIGGER")
assert(confirmationCount == beforeChord, "Adding a modifier must keep listening")
chordPrefix = ""
release(capture, "PADLTRIGGER")
assert(confirmationCount == beforeChord, "Releasing a modifier cannot finish capture")
release(capture, "PAD4")
assert(confirmation.message:find("CTRL-SHIFT-PAD4", 1, true), "Preserve modifiers released first")
pad:CaptureMenuBinding()
release(capture, "PAD4")
assert(capture:IsShown(), "Reopening clears the previous pending chord")
press(capture, "PAD3")
release(capture, "PAD3")
assert(confirmation.message == "Assign PAD3?", "Plain buttons remain bindable")

-- Ordinary multi-button shortcuts preserve both buttons in either press order.
for _, buttons in ipairs({ { "PADRSHOULDER", "PADDUP" }, { "PADDUP", "PADRSHOULDER" } }) do
    pad:CaptureMenuBinding()
    local before = confirmationCount
    press(capture, buttons[1])
    press(capture, buttons[2])
    release(capture, buttons[1])
    assert(confirmationCount == before and capture:IsShown(), "Wait for every captured button to release")
    release(capture, buttons[2])
    assert(confirmation.message:find("PADDUP", 1, true) and confirmation.message:find("PADRSHOULDER", 1, true))
    local savedBefore = saves
    confirmation.accept()
    assert(saves == savedBefore, "Custom chords must not be passed to native SetBinding/SaveBindings")
    assert(#pad:GetMenuChord() == 2)
end
-- Back remains usable alone, while B may participate in a combination.
pad:CaptureMenuBinding()
press(capture, "PAD2")
press(capture, "PADDLEFT")
release(capture, "PAD2")
assert(capture:IsShown())
release(capture, "PADDLEFT")
assert(confirmation.message:find("PAD2", 1, true) and confirmation.message:find("PADDLEFT", 1, true))
pad:CaptureMenuBinding()
local beforeBack = confirmationCount
press(capture, "PAD2")
release(capture, "PAD2")
assert(not capture:IsShown() and confirmationCount == beforeBack)

-- Replace the erroneous old single-button APR binding, but preserve other actions.
bindings.PADDUP, bindings.PADRSHOULDER = "APR_MENU", "JUMP"
pad:CaptureMenuBinding()
press(capture, "PADDUP")
press(capture, "PADRSHOULDER")
release(capture, "PADDUP")
release(capture, "PADRSHOULDER")
confirmation.accept()
assert(not bindings.PADDUP and bindings.PADRSHOULDER == "JUMP")
local held, menuOpens = {}, 0
function IsKeyDown(key) return held[key] == true end
local runAction = pad.RunAction
function pad:RunAction(action)
    assert(action == "menu")
    menuOpens = menuOpens + 1
end
local function poll()
    for i = 1, 6 do
        fixture.tick()
    end
end
held.PADRSHOULDER = true
poll()
held.PADDUP = true
poll()
assert(menuOpens == 0, "Holding a chord cannot open the menu")
held.PADRSHOULDER = nil
poll()
assert(menuOpens == 0, "A partial release cannot open the menu")
held.PADDUP = nil
poll()
poll()
assert(menuOpens == 1, "A complete chord opens once after release")
held.PADDUP = true
poll()
held.PADDUP = nil
poll()
assert(menuOpens == 1, "A constituent button alone cannot open the menu")
held.PADDUP, held.PADRSHOULDER = true, true
poll()
env.setCombat(true)
poll()
held = {}
env.setCombat(false)
poll()
assert(menuOpens == 1, "Combat cancels pending chords without replay")
-- A saved chord does not own an observer while keyboard/mouse mode is active.
local nativeMode, nativeKey = InputUtil.IsGamepadUIEnabled, IsKeyDown
InputUtil.IsGamepadUIEnabled = function() return false end
local keyReads, callbacks = 0, 0
function IsKeyDown() keyReads = keyReads + 1; return false end
pad:RefreshMenuChord()
for _ = 1, 120 * 165 do
    for _, frame in ipairs(fixture.created) do
        if frame:IsShown() and frame.scripts.OnUpdate then
            callbacks = callbacks + 1
            frame.scripts.OnUpdate(frame, 1 / 165)
        end
    end
end
assert(keyReads == 0 and callbacks == 0, "Saved chords must cause zero idle callbacks outside gamepad mode")
InputUtil.IsGamepadUIEnabled, IsKeyDown = nativeMode, nativeKey
pad:RefreshMenuChord()
local resumed
for _, frame in ipairs(fixture.created) do
    if frame.scripts.OnUpdate then resumed = frame end
end
assert(resumed, "Reentering gamepad mode restores the configured chord observer")
env.setCombat(true)
resumed.scripts.OnEvent(resumed, "PLAYER_REGEN_DISABLED")
assert(resumed.scripts.OnUpdate == nil, "Combat detaches chord polling")
env.setCombat(false)
resumed.scripts.OnEvent(resumed, "PLAYER_REGEN_ENABLED")
assert(resumed.scripts.OnUpdate, "Combat end restores only eligible observers")
resumed.scripts.OnEvent(resumed, "GAME_PAD_DISCONNECTED")
assert(resumed.scripts.OnUpdate == nil, "Disconnect detaches polling before the native mode transition")
pad:RefreshMenuChord()
assert(resumed.scripts.OnUpdate == nil, "An unrelated refresh cannot revive a disconnected controller")
resumed.scripts.OnEvent(resumed, "GAME_PAD_CONNECTED")
assert(resumed.scripts.OnUpdate, "Reconnecting an active controller restores its observer")
pad.RunAction = runAction
APRData.GamepadMenuChord = nil
pad:RefreshMenuChord()

local target =
    { frame = CreateFrame("Button", nil, fixture.window), r = 0.2, g = 0.4, b = 0.6, a = 0.8, HasAlpha = true }
function target:SetColor(r, g, b, a)
    self.r, self.g, self.b, self.a = r, g, b, a
end
local commits = 0
function target:Fire(event)
    assert(event == "OnValueConfirmed")
    commits = commits + 1
end
pad:ShowColor(target)
local color = pad.colorEditor
assert(color.channels[4].slider:IsShown())
color.channels[1].slider.overrides.right()
assert(math.abs(color.values[1] - 52 / 255) < 0.0001 and target.r == 0.2)
color:SmartNavigationCloseHandler()
assert(not color:IsShown() and commits == 0 and target.r == 0.2, "Back discards colour changes")
pad:ShowColor(target)
color.channels[1].slider.overrides.right()
local apply
for _, button in ipairs({ color.content:GetChildren() }) do
    if button:GetText() == APPLY then apply = button end
end
apply:GetScript("OnClick")(apply)
assert(commits == 1 and math.abs(target.r - 52 / 255) < 0.0001)
assert(not color:IsShown() and not color.target)
target.HasAlpha = false
pad:ShowColor(target)
assert(not color.channels[4].slider:IsShown() and color.values[4] == 1)
color:GetScript("OnEvent")(color, "PLAYER_REGEN_DISABLED")
assert(not color:IsShown() and commits == 1)
print(
    "Gamepad controls: binding conflicts, modifier chords, cancellation/combat/disconnect and transactional RGBA editing passed"
)
