local fixture = dofile("tests/lua/gamepad_test.lua")
local pad, env, UI = fixture.pad, fixture.env, APR.UI
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
L.GAMEPAD_BIND_CONFIRM, L.GAMEPAD_BIND_REPLACE, L.GAMEPAD_BIND_SAVED = "Assign %s?", "Replaces %s", "Saved %s"
function UI:Window()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.content = CreateFrame("Frame", nil, frame)
    frame:Hide(); pad:RegisterWindow(frame)
    return frame
end
function UI:Label(parent, text)
    local label = parent:CreateFontString(); label:SetText(text); return label
end
function UI:Button(parent, text, width, callback)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetScript("OnClick", callback); frame:SetText(text)
    return frame
end
local confirmation
function UI:ShowConfirmationDialog(message, accept, cancel) confirmation = {message = message, accept = accept, cancel = cancel} end
function env.methods:EnableGamePadButton(value) self.padEnabled = value end
function env.methods:SetValue(value)
    local old = self.value; self.value = value
    if old ~= value and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function APR:RegisterSupportedEvent(frame, event) frame:RegisterEvent(event) end
dofile("APR-Core/integrations/GamepadControls.lua")
local bindings, saves = {["CTRL-PAD4"] = "JUMP"}, 0
function GetCVar(name) return name == "GamePadEmulateCtrl" and "PADLTRIGGER" or "none" end
function GetConvertedKeyOrButton(key) return key end
function IsKeyPressIgnoredForBinding(key) return key == "PADIGNORE" end
function CreateKeyChordStringUsingMetaKeyState(key) return "CTRL-" .. key end
C_KeyBindings = {GetBindingContextForAction = function(action) assert(action == "APR_MENU"); return 2 end}
function GetBindingAction(key, checkOverride, context) assert(context == 2 and not checkOverride); return bindings[key] or "" end
function SetBinding(key, action, context) assert(context == 2); bindings[key] = action; return true end
function GetCurrentBindingSet() return 2 end
function SaveBindings(set) assert(set == 2); saves = saves + 1 end

pad:CaptureMenuBinding()
local capture = pad.bindingCapture
assert(capture:IsShown() and capture.padEnabled)
local press = capture:GetScript("OnGamePadButtonDown")
press(capture, "PADLTRIGGER"); assert(not confirmation and capture:IsShown())
press(capture, "PADIGNORE"); assert(not confirmation and capture:IsShown())
press(capture, "PAD4")
assert(not capture:IsShown() and not capture.padEnabled)
assert(confirmation.message:find("CTRL%-PAD4") and confirmation.message:find("JUMP"))
assert(bindings["CTRL-PAD4"] == "JUMP" and saves == 0, "Capturing must not silently steal a binding")
confirmation.accept()
assert(bindings["CTRL-PAD4"] == "APR_MENU" and saves == 1)
pad:CaptureMenuBinding(); press(capture, "PADBACK")
assert(not capture:IsShown() and saves == 1, "Back cancels capture")
pad:CaptureMenuBinding(); press(capture, "PAD3")
env.setCombat(true); confirmation.accept(); env.setCombat(false)
assert(not bindings["CTRL-PAD3"] and saves == 1, "A stale confirmation cannot bind in combat")
pad:CaptureMenuBinding(); capture:GetScript("OnEvent")(capture, "GAME_PAD_DISCONNECTED")
assert(not capture:IsShown() and not capture.padEnabled)

local target = {frame = CreateFrame("Button", nil, fixture.window), r = 0.2, g = 0.4, b = 0.6, a = 0.8, HasAlpha = true}
function target:SetColor(r, g, b, a) self.r, self.g, self.b, self.a = r, g, b, a end
local commits = 0
function target:Fire(event) assert(event == "OnValueConfirmed"); commits = commits + 1 end
pad:ShowColor(target)
local color = pad.colorEditor
assert(color.channels[4].slider:IsShown())
color.channels[1].slider.overrides.right()
assert(math.abs(color.values[1] - 52/255) < 0.0001 and target.r == 0.2)
color:SmartNavigationCloseHandler()
assert(not color:IsShown() and commits == 0 and target.r == 0.2, "Back discards colour changes")
pad:ShowColor(target); color.channels[1].slider.overrides.right()
local apply
for _, button in ipairs({color.content:GetChildren()}) do if button:GetText() == APPLY then apply = button end end
apply:GetScript("OnClick")(apply)
assert(commits == 1 and math.abs(target.r - 52/255) < 0.0001)
assert(not color:IsShown() and not color.target)
target.HasAlpha = false; pad:ShowColor(target)
assert(not color.channels[4].slider:IsShown() and color.values[4] == 1)
color:GetScript("OnEvent")(color, "PLAYER_REGEN_DISABLED")
assert(not color:IsShown() and commits == 1)
print("Gamepad controls: binding conflicts, modifier chords, cancellation/combat/disconnect and transactional RGBA editing passed")
