local fixture = dofile("tests/lua/settings_widgets_test.lua")
local env, gui = fixture.env, fixture.gui
function env.methods:IsObjectType(kind) return self.kind == kind end
function env.methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function env.methods:GetValueStep() return self.step or 1 end
function env.methods:GetMinMaxValues() return self.minimum, self.maximum end
function env.methods:GetValue() return self.value end
function env.methods:SetValue(value)
    local old = self.value
    self.value = value
    if old ~= value and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
local show = env.methods.Show
function env.methods:Show()
    local wasShown = self.shown
    show(self)
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
local active, current
local manager = {}
function manager:FrameShown(frame) active = frame; return true end
function manager:FrameHidden(frame) if active == frame then active = nil end end
function manager:GetActiveFrame() return active end
function manager:FocusFrame(frame) active = frame end
InputUtil = {IsGamepadUIEnabled = function() return true end}
GamepadMode = {FrameControlsManager = manager}
SmartNavigation = {GetActiveFrame = function() return active end, GetCurrentButton = function() return current end,
    SelectButton = function(_, value) current = value end}
SMART_NAV_INPUT_DIRECTION = {LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down"}
function SmartNavigation_AddJumpNavigationOverride(frame, direction, callback)
    frame.overrides = frame.overrides or {}; frame.overrides[direction] = callback
end
dofile("APR-Core/integrations/Gamepad.lua")
dofile("APR-Core/integrations/GamepadNavigation.lua")
dofile("APR-Core/integrations/GamepadControls.lua")
local pad = APR.Gamepad
local window = CreateFrame("Frame", nil, UIParent)
pad:RegisterWindow(window)

-- Real AceGUI sliders write settings on mouse-up; moving the thumb alone is insufficient.
local slider = gui:Create("Slider")
slider.frame:SetParent(window)
slider:SetSliderValues(0, 2, 0.05); slider:SetValue(1)
local committed
slider:SetCallback("OnValueChanged", function(_, _, value) committed = value end)
pad:AdaptSettings(slider)
slider.slider.overrides.right()
assert(math.abs(committed - 1.05) < 0.0001)
slider.slider.OnSmartNavClick()
assert(current == slider.editbox, "Confirm must reach exact numeric entry")
slider:SetDisabled(true); committed = nil; slider.slider.overrides.left(); assert(committed == nil)
local sliderFrame = slider.slider
gui:Release(slider)
assert(sliderFrame.OnSmartNavClick == nil and sliderFrame.aprPadDirections == nil,
    "Returning a widget to AceGUI must remove its controller-specific behaviour")

-- Real dropdown pullouts and settings scrollframes use normalized offsets, not native scrolling.
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIContainer-ScrollFrame.lua")
for _, kind in ipairs({"ScrollFrame", "Dropdown-Pullout"}) do
    local widget = gui:Create(kind)
    local scroll = widget.scrollframe or widget.scrollFrame
    local content = widget.content or widget.itemFrame
    local bar = widget.scrollbar or widget.slider
    scroll:SetHeight(200); content:SetHeight(1000)
    local nativeSet, nativeGet = scroll.SetVerticalScroll, scroll.GetVerticalScroll
    pad:AdaptSettings(widget)
    scroll:SetVerticalScroll(400)
    assert(scroll:GetVerticalScroll() == 400 and scroll:GetVerticalScrollRange() == 800)
    assert(bar:GetValue() == 500, "Pixels must convert into AceGUI's 0..1000 scale")
    scroll:SetVerticalScroll(2000); assert(scroll:GetVerticalScroll() == 800)
    scroll:SetVerticalScroll(-10); assert(scroll:GetVerticalScroll() == 0)
    gui:Release(widget)
    assert(scroll.SetVerticalScroll == nativeSet and scroll.GetVerticalScroll == nativeGet)
    assert(not widget.aprPadOwned)
    widget.frame:Show(); assert(active ~= widget.frame, "A released pullout belongs to its next addon")
    widget.frame:Hide()
end

-- A colour widget keeps mouse behaviour, uses an alternate editor for pad input,
-- and restores its callbacks when released to the shared pool.
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-ColorPicker.lua")
local color = gui:Create("ColorPicker")
local original = color.frame:GetScript("OnClick")
local opened
local openColor = pad.ShowColor
pad.ShowColor = function(_, value) opened = value end
pad:AdaptSettings(color)
color.frame.OnSmartNavClick(); assert(opened == color)
opened = nil; current = color.frame
color.frame:GetScript("OnClick")(color.frame, "RightButton"); assert(opened == color)
gui:Release(color)
assert(color.frame:GetScript("OnClick") == original and color.frame.OnSmartNavClick == nil)
pad.ShowColor = openColor
print("Gamepad settings: real AceGUI slider commits, both scroll implementations, colour dispatch and pool restoration passed")
