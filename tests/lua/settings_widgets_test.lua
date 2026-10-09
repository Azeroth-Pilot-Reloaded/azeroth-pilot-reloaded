-- Use AceGUI's real acquire/release pool to catch styling leaks across addons and nested containers.
local env = dofile("tests/lua/route_ui_test_env.lua")
local hide = env.methods.Hide
function env.methods:Hide()
    local shown = self:IsShown()
    hide(self)
    if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function env.methods:IsMouseOver() return self.mouseOver == true end
function env.methods:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
function env.methods:UnregisterEvent(event) if self.events then self.events[event] = nil end end
function env.methods:GetFrameStrata() return self.strata or "DIALOG" end
function env.methods:SetFrameStrata(value) self.strata = value end
function env.methods:GetNumChildren() return #(self.children or {}) end
function env.methods:GetChildren() return unpack(self.children or {}) end
function env.methods:SetTexture(value) self.texture = value end
function env.methods:GetTexture() return self.texture end
function env.methods:GetName() return self.name end
function env.methods:SetDrawLayer(layer) self.layer = layer end
function env.methods:SetTextInsets(...) self.insets = {...} end
function env.methods:SetFormattedText(format, ...) self:SetText(string.format(format, ...)) end
function env.methods:GetStringHeight() return math.max(1, math.ceil(#tostring(self.text or "") / 30)) * 12 end
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "UIDropDownMenuTemplate" then
        for _, key in ipairs({"Left", "Middle", "Right"}) do _G[name .. key] = frame:CreateTexture() end
        _G[name .. "Text"] = frame:CreateFontString()
        _G[name .. "Button"] = createFrame("Button", name .. "Button", frame)
    elseif template == "InputBoxTemplate" or template == "UIPanelButtonTemplate" then
        for _, key in ipairs({"Left", "Middle", "Right"}) do frame[key] = frame:CreateTexture() end
        if template == "UIPanelButtonTemplate" then frame:SetFontString(frame:CreateFontString()) end
    end
    return frame
end
C_Timer = {After = function(_, callback) callback() end}
function PlaySound() end
function GetCursorInfo() end
OKAY, APPLY = "OK", "Apply"
local failures = {}
function geterrorhandler() return function(err) failures[#failures + 1] = err end end
local originalXpcall = xpcall
function xpcall(fn, handler, ...)
    local args = {...}
    return originalXpcall(function() return fn(unpack(args)) end, handler)
end
function hooksecurefunc(object, key, callback)
    local previous = object[key]
    object[key] = function(...) previous(...); callback(...) end
end
table.wipe = wipe
strmatch = string.match
LibStub = nil
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/AceGUI-3.0/AceGUI-3.0.lua")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-Slider.lua")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-DropDown.lua")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-DropDown-Items.lua")
dofile("APR-Core/libs/AceGUI-3.0/widgets/AceGUIWidget-EditBox.lua")
local gui = LibStub("AceGUI-3.0")
gui:RegisterWidgetType("Button", function()
    local frame = CreateFrame("Button")
    for _, key in ipairs({"Left", "Middle", "Right"}) do frame[key] = frame:CreateTexture() end
    return gui:RegisterAsWidget({type = "Button", frame = frame, OnAcquire = function() end})
end, 1)
gui:RegisterWidgetType("InlineGroup", function()
    local frame = CreateFrame("Frame")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    return gui:RegisterAsContainer({type = "InlineGroup", frame = frame, content = CreateFrame("Frame", nil, frame),
        OnAcquire = function() end})
end, 1)
local dialog = LibStub:NewLibrary("AceConfigDialog-3.0", 1)
function dialog:FeedGroup(app, options, container)
    container:ReleaseChildren()
    local group = gui:Create("InlineGroup")
    container:AddChild(group)
    local control = gui:Create(options.kind or (options.checkbox and "CheckBox" or "Button"))
    if options.checkbox then
        control:SetUserData("option", {name = "Automatic quests", desc = "Accept and turn in quests."})
        control:SetLabel("Automatic quests")
        control:SetWidth(640)
    elseif options.kind == "Slider" then
        control:SetUserData("option", {name = "Scale"})
        control:SetLabel("Scale"); control:SetWidth(640)
        control:SetIsPercent(true); control:SetSliderValues(0.01, 2, 0.05); control:SetValue(1)
    elseif options.kind == "Dropdown" then
        control:SetUserData("option", {name = "Position"})
        control:SetLabel("Position"); control:SetWidth(640)
        control:SetList({left = "Left", right = "Right"}); control:SetValue("left")
    elseif options.kind == "EditBox" then
        control:SetUserData("option", {name = "New profile", desc = "Create a profile with this name."})
        control:SetLabel("New profile"); control:SetWidth(640); control:SetText("")
    elseif options.kind == "APRSettingsAction" then
        control:SetUserData("option", {name = "Reset profile", desc = "Restore the current profile to its defaults."})
        control:SetWidth(640); control:SetText("Reset profile")
    end
    group:AddChild(control)
    if options.fail then error("Deliberate failure") end
end
function dialog:Open(app, container) self:FeedGroup(app, {}, container) end
APR.title, APR.UI = "APR", {}
function APR.UI:Panel(parent) return CreateFrame("Frame", nil, parent) end
function APR.UI:Label(parent, text)
    local label = parent:CreateFontString(); label:SetText(text); return label
end
function APR.UI:Button(parent, text, width, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetFontString(button:CreateFontString())
    button:SetText(text); button:SetWidth(width)
    button:SetScript("OnClick", callback)
    return button
end
function APR.UI:SetIcon(texture, name) texture:SetTexture(name) end
local provider
function APR:GetSkinProviderName() return provider end
function APR:RegisterSkinTarget(frame, kind, options) frame.themed, frame.skinOptions = true, options end
dofile("APR-Core/ui/foundations/SettingsRows.lua")
dofile("APR-Core/ui/foundations/SettingsWidgets.lua")
APR:EnableWorkspaceWidgets()
local create = gui.Create
APR:EnableWorkspaceWidgets()
assert(gui.Create == create, "Repeated setup cannot stack wrappers")
local native = gui:Create("Button")
gui:Release(native)
local host = APR.UI:SettingsHost(UIParent)
local refreshes = 0
host:SetCallback("OnOptionsRefreshed", function() refreshes = refreshes + 1 end)
dialog:Open("APR/Workspace/Options/general", host)
local group, button = host.children[1], host.children[1].children[1]
assert(group.frame:GetFrameStrata() == host.frame:GetFrameStrata())
assert(group.frame.skinOptions.surface == "inset", "Settings boxes use the same background as release-note sections")
assert(button.frame.themed and button.type == "Button" and button ~= native)
assert(refreshes == 1, "Header action state refreshes after AceConfig updates the form")
for _, key in ipairs({"Left", "Middle", "Right"}) do
    assert(button.frame[key].alpha == 0 and native.frame[key].alpha ~= 0, "APR hides native button art only in its own pool")
end
host:ReleaseChildren()
assert(not gui.objPools.Button[button] and gui.objPools["APRWorkspace:Button"][button])
assert(gui:Create("Button") == native and not native.frame.themed)
dialog:Open("APR/Workspace/About", host)
assert(host.children[1] == group and group.children[1] == button, "APR must reuse its private widgets")
assert(not pcall(dialog.FeedGroup, dialog, "APR/Workspace/Options/general", {fail = true}, host))
assert(not gui:Create("Button").frame.themed, "Failure cannot leave other addons inside APR's scope")
dialog:Open("AnotherAddon", host)
assert(not host.children[1].children[1].frame.themed)
provider = "EllesmereUI"
dialog:Open("APR/Workspace/Options/general", host)
assert(not host.children[1].children[1].frame.themed, "EllesmereUI must retain control of its own settings widgets")
provider = nil
dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true}, host)
local checkbox = host.children[1].children[1]
local changes, value = 0
checkbox:SetCallback("OnValueChanged", function(_, _, checked) changes, value = changes + 1, checked end)
assert(checkbox.check:GetParent() == checkbox.aprCheckBox,
    "The checked texture must sit above the new background, not behind its child frame")
assert(not checkbox.check:IsShown())
checkbox.frame.scripts.OnMouseUp(checkbox.frame)
assert(changes == 1 and value == true and checkbox:GetValue() and checkbox.check:IsShown())
checkbox.frame.scripts.OnMouseUp(checkbox.frame)
assert(changes == 2 and value == false and not checkbox.check:IsShown())
checkbox:SetDisabled(true)
checkbox.frame.scripts.OnMouseUp(checkbox.frame)
assert(changes == 2 and checkbox.aprCheckBox.alpha < 1, "Disabled controls retain their native behavior")
checkbox:SetDisabled(false); checkbox:SetTriState(true); checkbox:SetValue(nil)
assert(checkbox.check:IsShown(), "AceGUI's mixed value remains visible")
host:ReleaseChildren()
dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true}, host)
assert(host.children[1].children[1] == checkbox and not checkbox.check:IsShown(),
    "A pooled checkbox resets its value without losing its drawing layer")
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Dropdown"}, host)
local dropdown = host.children[1].children[1]
assert(dropdown.dropdown.themed and dropdown.text:GetParent() == dropdown.dropdown and dropdown.text.layer == "OVERLAY",
    "The selected text must render on its skinned background, not beneath another child panel")
assert(dropdown.text:GetText() == "Left")
dropdown:SetValue("right")
assert(dropdown.text:GetText() == "Right")
dropdown:SetDisabled(true); dropdown:SetDisabled(false)
assert(dropdown.text:GetText() == "Right", "Disabling a select preserves its selected value")
local pullout = dropdown.pullout
dropdown.button_cover.scripts.OnClick(dropdown.button_cover)
assert(dropdown.open and pullout.frame.events.GLOBAL_MOUSE_DOWN)
pullout.frame.mouseOver = true
pullout.frame.scripts.OnEvent(pullout.frame, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(dropdown.open, "Clicks inside the menu must still reach its choices")
pullout.frame.mouseOver, dropdown.button_cover.mouseOver = false, true
pullout.frame.scripts.OnEvent(pullout.frame, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(dropdown.open, "The trigger handles its own toggle without closing and reopening")
dropdown.button_cover.mouseOver = false
pullout.frame.scripts.OnEvent(pullout.frame, "GLOBAL_MOUSE_DOWN", "RightButton")
assert(not dropdown.open and not pullout.frame:IsShown() and not pullout.frame.events.GLOBAL_MOUSE_DOWN)
assert(dropdown:GetValue() == "right", "Dismissing a menu cannot change its selected value")
dropdown.button_cover.scripts.OnClick(dropdown.button_cover)
host:ReleaseChildren()
assert(not pullout.frame.events.GLOBAL_MOUSE_DOWN, "Released pullouts cannot retain a global mouse listener")
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Dropdown"}, host)
assert(host.children[1].children[1] == dropdown and dropdown.text:GetText() == "Left",
    "Reused dropdowns keep the text and backdrop on the same frame")
dropdown.button_cover.scripts.OnClick(dropdown.button_cover)
dropdown.pullout.frame.scripts.OnEvent(dropdown.pullout.frame, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(not dropdown.open, "Outside dismissal also works after pool reuse")
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Slider"}, host)
local slider = host.children[1].children[1]
assert(slider.editbox:GetText() == "100%" and slider.lowtext:GetText() == "1%" and slider.hightext:GetText() == "200%")
for _, limit in ipairs({slider.lowtext, slider.hightext}) do
    assert(limit.point[2] == slider.slider and limit.point[3]:find("BOTTOM") and limit.point[5] < 0,
        "Slider limits sit below the track with a gap")
end
slider:SetSliderValues(0, 50, 1); slider:SetIsPercent(false); slider:SetValue(25)
assert(slider.editbox:GetText() == 25 and slider.lowtext:GetText() == 0 and slider.hightext:GetText() == 50,
    "Changing bounds and numeric/percent modes keeps all three values current")
local otherInput = gui:Create("EditBox")
dialog:FeedGroup("APR/Workspace/Options/profiles", {kind = "EditBox"}, host)
local input = host.children[1].children[1]
for _, edge in ipairs({"Left", "Middle", "Right"}) do
    assert(input.editbox[edge].alpha == 0 and input.button[edge].alpha == 0,
        "Native input and OK artwork must not overlap the APR controls")
    assert(otherInput.editbox[edge].alpha ~= 0, "Other addons keep their native input borders")
end
assert(input.editbox.themed and input.button:GetParent() == input.frame)
assert(input.editbox:GetHeight() == 30 and input.editbox.point[2] == input.frame)
assert(input.editbox:GetWidth() == dropdown.dropdown:GetWidth()
    and input.editbox.point[4] == dropdown.dropdown.point[4],
    "The input has exactly the same width and right edge as the selects")
assert(input.button.point[2] == input.editbox and input.button.point[3] == "BOTTOMRIGHT" and input.button.point[5] < 0,
    "OK sits below the input with a gap and cannot overlap or shorten it")
local inputHeight = input.frame:GetHeight()
local created = {}
input:SetCallback("OnEnterPressed", function(_, _, text)
    if text == "" then return true end
    created[#created + 1] = text
end)
input:SetFocus()
input.editbox:SetText("Questing profile")
input.editbox.scripts.OnTextChanged(input.editbox)
assert(input.editbox:HasFocus() and input.button:IsShown() and input.editbox.insets[1] == 8)
assert(input.frame:GetHeight() == inputHeight, "Revealing OK must not move the rest of the form")
input.editbox.scripts.OnEnterPressed(input.editbox)
assert(created[1] == "Questing profile" and not input.button:IsShown(), "Enter submits the actual editable text")
input.editbox:SetText("Alt profile")
input.editbox.scripts.OnTextChanged(input.editbox)
input.button.scripts.OnClick(input.button)
assert(created[2] == "Alt profile" and not input.button:IsShown() and not input.editbox:HasFocus(),
    "OK uses AceGUI's same validation and submission callback")
input.editbox:SetText(""); input.editbox.scripts.OnTextChanged(input.editbox)
input.button.scripts.OnClick(input.button)
assert(#created == 2 and input.button:IsShown(), "Rejected text keeps validation available")
input:SetDisabled(true)
assert(not input.button:IsEnabled() and not input.editbox:HasFocus())
host:ReleaseChildren()
dialog:FeedGroup("APR/Workspace/Options/profiles", {kind = "EditBox"}, host)
assert(host.children[1].children[1] == input and input:GetText() == "" and not input.button:IsShown(),
    "Recycled inputs reset their state without restoring the obsolete border")
dialog:FeedGroup("APR/Workspace/Options/profiles", {kind = "APRSettingsAction"}, host)
local action = host.children[1].children[1]
local applied = 0
action:SetCallback("OnClick", function() applied = applied + 1 end)
assert(action.label:GetText() == "Reset profile" and action.button:GetText() == APPLY)
assert(action.aprRow.note:GetText() == "Restore the current profile to its defaults.")
assert(action.button.point[1] == "TOPRIGHT" and action.label.point[1] == "TOPLEFT")
action.button.scripts.OnClick(action.button)
assert(applied == 1, "The action button forwards AceConfig's callback")
action:SetDisabled(true)
assert(not action.button:IsEnabled())
host:ReleaseChildren()
dialog:FeedGroup("APR/Workspace/Options/profiles", {kind = "APRSettingsAction"}, host)
assert(host.children[1].children[1] == action and not action.disabled and action.button:IsEnabled())
assert(#failures == 0, table.concat(failures, "\n"))
print("Workspace widgets: real AceGUI pool isolation, nested release, reuse, error recovery and skin delegation passed")
