local combat, enabled = false, true
function InCombatLockdown() return combat end
local frames = {}
function CreateFrame()
    local f = { scripts = {}, shown = true, regions = {}, children = {} }
    function f:GetRegions() return unpack(self.regions) end
    function f:GetChildren() return unpack(self.children) end
    function f:IsShown() return self.shown end
    function f:RegisterEvent() end
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:SetSize() end
    function f:SetHeight() end
    function f:SetPoint() end
    function f:SetAllPoints() end
    function f:GetFrameLevel() return 1 end
    function f:SetFrameLevel() end
    function f:EnableMouse() end
    function f:SetAlpha(alpha) self.alpha = alpha end
    function f:SetColorTexture(...) self.color = { ... } end
    f.SetVertexColor, f.SetTextColor = f.SetColorTexture, f.SetColorTexture
    function f:SetTexture(texture) self.texture = texture end
    function f:GetThumbTexture() return self.thumb end
    frames[#frames + 1] = f
    return f
end
function hooksecurefunc(object, key, callback)
    local previous = object[key]
    object[key] = function(...) previous(...); callback(...) end
end
local gui = { WidgetRegistry = {}, objPools = {}, versions = {} }
function gui:GetWidgetVersion(kind) return self.versions[kind] or 1 end
function gui:RegisterWidgetType(kind, fn, version) self.WidgetRegistry[kind], self.versions[kind] = fn, version end
function gui:Create(kind)
    self.objPools[kind] = self.objPools[kind] or {}
    local w = next(self.objPools[kind])
    if w then self.objPools[kind][w] = nil else w = self.WidgetRegistry[kind]() end
    w.frame.shown = true
    return w
end
function gui:Release(w)
    if w.isQueuedForRelease then return end
    for _, child in ipairs(w.children or {}) do self:Release(child) end
    w.children = nil
    w.frame.shown = false
    self.objPools[w.type] = self.objPools[w.type] or {}
    self.objPools[w.type][w] = true
end
for _, kind in ipairs({ "Button", "SimpleGroup" }) do
    gui:RegisterWidgetType(kind, function()
        return { type = kind, frame = CreateFrame(), SetDisabled = function(self, value) self.disabled = value end }
    end, 1)
end
local dialog = { OpenFrames = {} }
function dialog:AddToBlizOptions() end
function dialog:FeedGroup(app, options, container)
    container.children = {}
    for _, kind in ipairs(options.types or { "Button" }) do
        table.insert(container.children, gui:Create(kind))
    end
    if options.fail then error("deliberate creation failure") end
end
function dialog:Open(app)
    local root = gui:Create("SimpleGroup")
    self.OpenFrames[app] = root
    self:FeedGroup(app, {}, root)
end
function LibStub(name) return name == "AceGUI-3.0" and gui or dialog end
APR = { title = "APR", EllesmereUISkin = { GetFont = function() if enabled then return "font.ttf" end end } }
local changes = {}
local S = { OnLooksChanged = function(fn) changes[#changes + 1] = fn end }
function S.GetAccentColor() return 0, 0.8, 0.6 end
for _, name in ipairs({ "Panel", "Dropdown", "EditBox", "ScrollBar", "Tab", "CloseButton" }) do
    S[name] = function(frame) assert(frame.GetRegions, "Expected a frame, not an AceGUI widget"); frame.themed = true end
end
local fontCalls = 0
function S.Font(frame)
    fontCalls = fontCalls + 1
    frame.themed = true
    -- Mirrors PrimeFontShadow adding a helper object during font styling.
    if frame.owner then
        local helper = CreateFrame()
        helper.children[1] = helper
        frame.owner.children[#frame.owner.children + 1] = helper
    end
end
function S.Button(frame) assert(not combat); frame.themed = true end
function S.StateButtonLabel() end
dofile("APR-Core/integrations/EllesmereUISettings.lua")
APR:EnableEllesmereUISettings(S)
local native = gui:Create("Button")
gui:Release(native)
dialog:Open("APR")
local root = dialog.OpenFrames.APR
local button = root.children[1]
assert(button.frame.themed and button ~= native and button.type == "Button")
local fontRegion = { owner = root.frame, IsObjectType = function(_, kind) return kind == "FontString" end }
root.frame.regions[1] = fontRegion
root.frame.children[1] = root.frame
for _, callback in ipairs(changes) do callback() end
assert(fontCalls == 1, "Font shadow helpers and cyclic frame references must not recurse")
assert(gui.objPools.Button[native], "APR cannot acquire a widget from another addon's pool")
gui:Release(root)
assert(not gui.objPools.Button[button], "APR themed widgets cannot leak into the shared pool")
assert(gui:Create("Button") == native and not native.frame.themed)
dialog:Open("APR/Route")
local route = dialog.OpenFrames["APR/Route"]
assert(route == root and route.children[1] == button, "APR reuses its isolated pool across pages")
dialog:Open("APR-other-addon")
assert(not dialog.OpenFrames["APR-other-addon"].children[1].frame.themed)
combat = true
dialog:Open("APR/Profile")
local deferred = dialog.OpenFrames["APR/Profile"].children[1]
assert(not deferred.frame.themed)
combat = false
frames[1].scripts.OnEvent()
assert(deferred.frame.themed)
local ok = pcall(dialog.FeedGroup, dialog, "APR", { fail = true }, root)
assert(not ok)
assert(not gui:Create("Button").frame.themed, "Failure must restore the creation scope")
enabled = false
dialog:Open("APR/About")
assert(not dialog.OpenFrames["APR/About"].children[1].frame.themed)
enabled = true
for _, kind in ipairs({ "CheckBox", "Slider", "ColorPicker", "Dropdown", "DropdownGroup", "Heading", "MultiLineEditBox", "CyclicDropdown" }) do
    gui:RegisterWidgetType(kind, function()
        local widget = { type = kind, frame = CreateFrame() }
        for _, key in ipairs({ "checkbg", "check", "colorSwatch", "slider", "editBox", "scrollBG", "scrollBar", "left", "right", "label" }) do
            widget[key] = CreateFrame()
        end
        widget.slider.thumb = CreateFrame()
        if kind == "Dropdown" then widget.dropdown = CreateFrame() end
        if kind == "DropdownGroup" then
            widget.dropdown, widget.border = gui:Create("Dropdown"), CreateFrame()
        end
        if kind == "CyclicDropdown" then
            local pullout = { type = "Dropdown-Pullout", frame = CreateFrame() }
            function pullout:IterateItems()
                local yielded = false
                return function()
                    if yielded then return end
                    yielded = true
                    return 1, widget
                end
            end
            widget.pullout = pullout
        end
        return widget
    end, 1)
end
dialog:FeedGroup("APR", { types = { "CheckBox", "Slider", "ColorPicker", "DropdownGroup", "Heading", "MultiLineEditBox", "CyclicDropdown" } }, root)
assert(root.children[1].checkbg.alpha == 0 and root.children[1].check.color[2] == 0.8)
assert(root.children[2].slider.thumb.alpha == 1 and root.children[2].editBox.themed)
assert(root.children[4].dropdown.dropdown.themed, "Dropdown groups contain widgets, not raw dropdown frames")
assert(root.children[6].scrollBG.themed and root.children[6].scrollBar.themed)
assert(root.children[7].pullout.frame.themed, "Cyclic dropdown ownership must terminate after one style pass")
for _, callback in ipairs(changes) do callback() end
assert(fontCalls == 1, "Already styled fonts remain idempotent across theme refreshes")
assert(#changes == 1)
APR:EnableEllesmereUISettings(S)
assert(#changes == 1, "Installing twice must not stack wrappers")
print("PASS: EllesmereUI settings pages, private widget pools, reuse, errors, combat deferral and disabled skin")
