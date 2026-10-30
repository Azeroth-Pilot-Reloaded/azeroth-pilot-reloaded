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
    frame.kind = kind
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
OKAY, APPLY, CLOSE = "OK", "Apply", "Close"
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
local elvDropdownSkin = false
local registerWidget = gui.RegisterAsWidget
function gui:RegisterAsWidget(widget)
    if elvDropdownSkin and widget.type == "Dropdown" then
        -- ElvUI's Ace3 skin moves the value and arrow onto a backdrop below the dropdown.
        -- APR later paints the dropdown itself, which would cover those borrowed regions.
        local backdrop = CreateFrame("Frame", nil, widget.dropdown)
        backdrop:SetFrameLevel(math.max(0, widget.dropdown:GetFrameLevel() - 1))
        backdrop:SetBackdrop({external = true})
        backdrop:SetBackdropColor(0.05, 0.05, 0.05, 1)
        widget.dropdown.backdrop = backdrop
        widget.text:SetParent(backdrop)
        widget.button:SetParent(backdrop)
    end
    return registerWidget(self, widget)
end
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
local feeding, fontsDuringFeed = false, 0
function dialog:FeedGroup(app, options, container)
    feeding = true
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
    local option = control:GetUserData("option")
    if option then option.arg = options.presentation end
    if options.width then control:SetWidth(options.width) end
    group:AddChild(control)
    feeding = false
    if options.fail then error("Deliberate failure") end
end
function dialog:Open(app, container) self:FeedGroup(app, {fail = container.fail}, container) end
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
function APR:GetSkinScope() return "general" end
function APR:RegisterSkinTarget(frame, kind, options)
    frame.themed, frame.skinOptions = true, options
    if elvDropdownSkin and frame.name and frame.name:match("^AceGUI30DropDown%d+$") then
        local externalBackdrop = frame.backdrop
        self:ApplyNativeTheme(frame, kind, options)
        -- WoW's SetBackdrop does not overwrite ElvUI's separate .backdrop child.
        frame.nativeBackdrop, frame.backdrop = frame.backdrop, externalBackdrop
    end
end
dofile("APR-Core/ui/foundations/SettingsRows.lua")
dofile("APR-Core/ui/foundations/SettingsWidgets.lua")
APR:EnableWorkspaceWidgets()
local create = gui.Create
APR:EnableWorkspaceWidgets()
assert(gui.Create == create, "Repeated setup cannot stack wrappers")
local native = gui:Create("Button")
gui:Release(native)
local host = APR.UI:SettingsHost(UIParent)
local registerFont = APR.RegisterFontString
function APR:RegisterFontString(...)
    if feeding then fontsDuringFeed = fontsDuringFeed + 1 end
    return registerFont(self, ...)
end
local rowPasses, applyRows = 0, APR.SettingsRows.Apply
function APR.SettingsRows:Apply(widget)
    if widget == host then rowPasses = rowPasses + 1 end
    return applyRows(self, widget)
end
local refreshes = 0
host:SetCallback("OnOptionsRefreshed", function() refreshes = refreshes + 1 end)
dialog:Open("APR/Workspace/Options/general", host)
local group, button = host.children[1], host.children[1].children[1]
assert(group.frame:GetFrameStrata() == host.frame:GetFrameStrata())
assert(group.frame.skinOptions.surface == "inset", "Settings boxes use the same background as release-note sections")
assert(button.frame.themed and button.type == "Button" and button ~= native)
assert(refreshes == 1, "Header action state refreshes after AceConfig updates the form")
assert(rowPasses == 1, "Nested Open/FeedGroup must style and lay out the final settings tree once")
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
host.fail = true
assert(not pcall(dialog.Open, dialog, "APR/Workspace/Options/general", host))
host.fail = nil
local beforeRecovery = rowPasses
dialog:Open("APR/Workspace/Options/general", host)
assert(rowPasses == beforeRecovery + 1, "Nested errors restore the styling depth for subsequent opens")
dialog:Open("AnotherAddon", host)
assert(not host.children[1].children[1].frame.themed)
provider = "EllesmereUI"
dialog:Open("APR/Workspace/Options/general", host)
assert(not host.children[1].children[1].frame.themed, "EllesmereUI must retain control of its own settings widgets")
provider = nil
dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true}, host)
assert(fontsDuringFeed == 0, "Rebuilding settings must defer font styling until the final tree is ready")
local checkbox = host.children[1].children[1]
local rowMeasurements, rowMeasurementsDuringFeed = 0, 0
local measureNote = checkbox.aprRow.note.GetStringHeight
function checkbox.aprRow.note:GetStringHeight(...)
    rowMeasurements = rowMeasurements + 1
    if feeding then rowMeasurementsDuringFeed = rowMeasurementsDuringFeed + 1 end
    return measureNote(self, ...)
end
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
rowMeasurements, rowMeasurementsDuringFeed = 0, 0
dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true}, host)
assert(fontsDuringFeed == 0, "Reacquiring a styled checkbox must not restyle it on every initialization setter")
assert(rowMeasurementsDuringFeed == 0,
    "Rebuilding a pooled form must not measure and anchor intermediate control states")
assert(rowMeasurements > 0, "The completed form still measures its description for the final layout")
assert(host.children[1].children[1] == checkbox and not checkbox.check:IsShown(),
    "A pooled checkbox resets its value without losing its drawing layer")
local formFrames = env.frames()
for attempt = 1, 12 do
    dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true}, host)
    local control = host.children[1].children[1]
    control:SetDisabled(attempt % 2 == 0)
    assert(control == checkbox and control.disabled == (attempt % 2 == 0))
end
assert(env.frames() == formFrames and rowMeasurementsDuringFeed == 0,
    "Repeated option refreshes reuse frames and only lay out the completed form")
dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true, presentation = {aprCompact = true}}, host)
local compactCheck = host.children[1].children[1]
assert(compactCheck == checkbox and not compactCheck.aprRow.note:IsShown() and compactCheck.frame:GetHeight() <= 48,
    "Compact settings keep help in the tooltip instead of reserving a description line")
dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true, presentation = {aprInline = true}, width = 110}, host)
assert(checkbox.frame:GetWidth() == 110 and checkbox.frame:GetHeight() <= 48
    and checkbox.aprCheckBox.point[1] == "LEFT" and not checkbox.aprRow.separator:IsShown(),
    "Inline sound switches retain their cell width and share one event row")
dialog:FeedGroup("APR/Workspace/Options/general", {checkbox = true}, host)
assert(checkbox.aprRow.note:IsShown() and checkbox.aprRow.separator:IsShown()
    and checkbox.aprCheckBox.point[1] == "TOPRIGHT",
    "Reusing a compact switch in another settings page restores its full form layout")
elvDropdownSkin, provider = true, "ElvUI"
APR.settings.profile.uiTheme = "ElvUI"
APR.ElvUISkin = {GetThemeColor = function(_, role)
    if role == "surface" or role == "background" then return {0.05, 0.05, 0.05, 1} end
    if role == "border" then return {0.2, 0.2, 0.2, 1} end
    if role == "accent" then return {0, 0.6, 1, 1} end
end}
local media = LibStub:NewLibrary("LibSharedMedia-3.0", 1)
function media:GetDefault() return "Native" end
function media:Fetch() return "native.ttf" end
function APR:ResolveUIFileAsset(path) return path end
function env.methods:SetFont(path, size, flags) self.font, self.fontSize, self.flags = path, size, flags; return true end
function env.methods:SetTextColor(...) self.textColor = {...} end
dofile("APR-Core/ui/foundations/TextStyles.lua")
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Dropdown"}, host)
local dropdown = host.children[1].children[1]
assert(dropdown.dropdown.themed and dropdown.text:GetParent() == dropdown.dropdown and dropdown.text.layer == "OVERLAY",
    "The selected text must render on its skinned background, not beneath another child panel")
assert(dropdown.text:GetText() == "Left")
assert(dropdown.dropdown.backdropColor[1] == 0.05 and dropdown.dropdown.backdropColor[4] == 1)
assert(not dropdown.dropdown.backdrop:IsShown() and dropdown.button:GetParent() == dropdown.dropdown,
    "APR retires ElvUI's redundant backdrop after rescuing the selected value and arrow")
assert(dropdown.text.textColor[1] > 0.8 and dropdown.text.textColor[4] == 1,
    "ElvUI selected values keep readable Modern text on their opaque background")
dropdown:SetValue("right")
assert(dropdown.text:GetText() == "Right")
dropdown:SetDisabled(true); dropdown:SetDisabled(false)
assert(dropdown.text:GetText() == "Right", "Disabling a select preserves its selected value")
local appearance = APR:CreateTextAppearanceDefaults(false)
APR.settings.profile[APR.GLOBAL_TEXT_APPEARANCE_KEY] = appearance
appearance.color, appearance.colorOverrides.color = {0.7, 0.8, 1, 1}, true
dropdown:SetValue("right")
assert(dropdown.text.textColor[1] == 0.7 and dropdown.text.textColor[4] == 1,
    "Fixing ElvUI layering must retain the user's custom text color")
appearance.colorOverrides.color = false
dropdown:SetDisabled(true)
assert(dropdown.text.textColor[1] == APR:GetThemeColor("muted")[1])
dropdown:SetDisabled(false)
assert(dropdown.text.textColor[1] == APR:GetThemeColor("base")[1])
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
assert(dropdown.text:GetParent() == dropdown.dropdown and not dropdown.dropdown.backdrop:IsShown())
local allocated = env.frames()
-- Also recover if ElvUI initializes after the APR options already exist.
dropdown.text:SetParent(dropdown.dropdown.backdrop)
dropdown.button:SetParent(dropdown.dropdown.backdrop)
dropdown.dropdown.backdrop:Show()
dropdown.text:ClearAllPoints()
dropdown.text:SetPoint("LEFT", dropdown.dropdown.backdrop, "LEFT", 2, 0)
dropdown.frame.scripts.OnShow(dropdown.frame)
assert(dropdown.text:GetParent() == dropdown.dropdown and dropdown.button:GetParent() == dropdown.dropdown
    and not dropdown.dropdown.backdrop:IsShown() and env.frames() == allocated,
    "Showing a pooled select repairs late external skinning without rebuilding it")
assert(dropdown.text.point[2] == dropdown.button_cover and dropdown.text.point[4] == -32,
    "Late external skinning also restores the reserved text width")
dropdown.button_cover.scripts.OnClick(dropdown.button_cover)
dropdown.pullout.frame.scripts.OnEvent(dropdown.pullout.frame, "GLOBAL_MOUSE_DOWN", "LeftButton")
assert(not dropdown.open, "Outside dismissal also works after pool reuse")
dialog:FeedGroup("AnotherAddon", {kind = "Dropdown"}, host)
local borrowed = host.children[1].children[1]
assert(borrowed ~= dropdown and borrowed.text:GetParent() == borrowed.dropdown.backdrop
    and borrowed.dropdown.backdrop:IsShown() and not borrowed.dropdown.themed,
    "Other addons retain their global ElvUI dropdown skin")
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
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Slider", presentation = {aprInline = true}, width = 145}, host)
assert(host.children[1].children[1] == slider and slider.frame:GetWidth() == 145
    and slider.slider:GetWidth() + slider.editbox:GetWidth() < 145,
    "A sound cooldown's track and editable value fit inside their explicit cell")
assert(not slider.lowtext:IsShown() and not slider.hightext:IsShown())
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Dropdown", presentation = {aprInline = true}, width = 204}, host)
local inlineDropdown = host.children[1].children[1]
assert(inlineDropdown.dropdown:GetWidth() < 204 and inlineDropdown.dropdown.point[5] < -18,
    "Inline sound menus place the value below the label without overflowing their cell")
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Dropdown"}, host)
assert(host.children[1].children[1] == inlineDropdown and math.abs(inlineDropdown.dropdown:GetWidth() - 217.6) < 0.01
    and inlineDropdown.dropdown.point[5] == -12,
    "A pooled inline menu restores the regular right-aligned control layout")
inlineDropdown:SetMultiselect(true)
inlineDropdown:SetUserData("option", {name = "Synthetic policy", arg = {aprCompact = true, aprEmptyText = "Unrestricted"}})
inlineDropdown:SetItemValue("left", false); inlineDropdown:SetItemValue("right", false)
assert(inlineDropdown.text:GetText() == "Unrestricted", "An unrestricted policy must not appear as a blank field")
inlineDropdown:SetItemValue("left", true)
assert(inlineDropdown.text:GetText() == "Left", "An explicit selection replaces the empty-policy caption")
inlineDropdown:SetItemValue("left", false)
assert(inlineDropdown.text:GetText() == "Unrestricted", "Clearing the final selection restores the policy caption")
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Dropdown"}, host)
dialog:FeedGroup("APR/Workspace/Options/general", {kind = "Slider"}, host)
assert(slider.lowtext:IsShown() and slider.hightext:IsShown(),
    "A pooled sound cooldown restores the visible bounds on a regular slider")
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
-- Confirmation styling must identify a newly opened APR popup, including borrowed provider widgets.
function env.methods:GetScript(key) return self.scripts[key] end
local painted, accepted = 0, 0
function APR:StyleStaticPopup(frame) assert(frame == dialog.popup); painted = painted + 1 end
dialog.popup = CreateFrame("Frame")
dialog.popup.accept, dialog.popup.cancel = CreateFrame("Button"), CreateFrame("Button")
dialog.popup:Hide()
action:SetUserData("appName", "APR/Workspace/Options/profiles")
local acceptHandler
action:SetCallback("OnClick", function()
    dialog.popup:Show()
    acceptHandler = function() accepted = accepted + 1 end
    dialog.popup.accept:SetScript("OnClick", acceptHandler)
end)
action:Fire("OnClick")
assert(painted == 1 and dialog.popup.accept:GetScript("OnClick") == acceptHandler)
action:Fire("OnEnter")
assert(painted == 1, "Unrelated widget events cannot repaint an already open shared popup")
dialog.popup.accept:GetScript("OnClick")()
assert(accepted == 1, "AceConfig retains its acceptance callback")
action:SetUserData("appName", "AnotherAddon")
action:Fire("OnClick")
assert(painted == 1, "Other addons using the same AceGUI pool never receive APR popup chrome")
assert(#failures == 0, table.concat(failures, "\n"))
local previewLocale = LibStub:NewLibrary("AceLocale-3.0", 1)
function previewLocale:GetLocale() return setmetatable({}, {__index = function(_, key) return key end}) end
dofile("APR-Core/ui/foundations/ThemeCustomization.lua")
APR.settings.profile.uiTheme = "modern"
function APR:GetSelectedSkinName() return self.settings.profile.uiTheme end
APR.ThemeCustomization:InstallPreviewWidget(gui)
local themeNotice = gui:Create("APRThemeNotice")
themeNotice:SetWidth(640)
themeNotice:SetText("Changes stay in the preview until you click Apply.")
assert(themeNotice.frame:GetHeight() >= themeNotice.label:GetStringHeight() + 40,
    "The preview explanation reserves space above and below its wrapped text")
themeNotice:SetText(string.rep("A longer translated explanation. ", 12))
assert(themeNotice.frame:GetHeight() >= themeNotice.label:GetStringHeight() + 40,
    "Long explanations grow without losing the paragraph margins")
gui:Release(themeNotice)
local noticeFrames = env.frames()
for _ = 1, 20 do
    themeNotice = gui:Create("APRThemeNotice")
    themeNotice:SetWidth(400); themeNotice:SetText("Preview changes")
    gui:Release(themeNotice)
end
assert(env.frames() == noticeFrames, "The padded explanation reuses its AceGUI widget on refresh")
local themePreview = gui:Create("APRThemePreview")
themePreview:SetText("Preview"); themePreview:SetFontObject(GameFontHighlightSmall)
themePreview:SetImage(nil); themePreview:SetImageSize(32, 32)
themePreview:SetFullWidth(true); themePreview:SetWidth(540)
assert(themePreview.preview.body:GetHeight() == 120 and themePreview.frame:GetHeight() == 192)
gui:Release(themePreview)
local previewFrames = env.frames()
for _ = 1, 20 do
    themePreview = gui:Create("APRThemePreview")
    APR.ThemeCustomization:Set("radius", 12)
    assert(themePreview.preview.header.backdrop.edgeSize == 12)
    gui:Release(themePreview)
    assert(not APR.ThemeCustomization.previews[themePreview])
end
assert(env.frames() == previewFrames, "AceGUI reuses the native theme preview without allocating on every settings refresh")
print("Workspace widgets: real AceGUI pool isolation, nested release, reuse, error recovery and skin delegation passed")
return {env = env, gui = gui, host = host, dialog = dialog}
