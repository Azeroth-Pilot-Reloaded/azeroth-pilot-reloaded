-- Run with Lua 5.1, or python tools/validation/run_lua_tests.py --skins-only.
local combat = false
function InCombatLockdown() return combat end
local frames = {}
local function noop() end
function CreateFrame()
    local frame = { scripts = {}, width = 30, height = 24, attributes = { type = "item", item = "item:239142" } }
    function frame:RegisterEvent(event) self.event = event end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:HookScript(event, callback) self.scripts[event] = callback end
    function frame:GetSize() return self.width, self.height end
    function frame:SetSize(width, height) assert(not combat); self.width, self.height = width, height end
    function frame:SetTemplate(template) assert(not combat); self.template = template end
    frame.StripTextures = noop
    frames[#frames + 1] = frame
    return frame
end
function hooksecurefunc() end
APR = { settings = { profile = { elvuiSkin = false } } }
function APR:NewModule() return {} end
dofile("APR-Core/integrations/SkinRegistry.lua")
local events = frames[1]
local calls = {}
local S = {}
local function record(kind, frame)
    assert(not combat, "Never skin protected controls in combat")
    calls[kind] = (calls[kind] or 0) + 1
    frame.skin = kind
end
function S:HandleButton(frame) record("button", frame) end
function S:HandleNextPrevButton(frame, direction)
    record("arrow", frame)
    frame.direction = direction
    frame:SetSize(18, 18) -- ElvUI's default must not alter APR layout.
end
function S:HandleScrollBar(frame) record("scrollbar", frame) end
function S:HandleCloseButton(frame) record("close", frame); frame:SetSize(20, 20) end
function S:HandleIcon(texture) record("icon", texture) end
function S:HandleEditBox(frame) record("editbox", frame) end
ElvUI = { { GetModule = function() return S end } }
dofile("APR-Core/integrations/ElvUISkin.lua")
local preset, arrow, scroll, close, item, icon = CreateFrame(), CreateFrame(), CreateFrame(), CreateFrame(), CreateFrame(), CreateFrame()
local clicked = 0
local onClick = function() clicked = clicked + 1 end
arrow:SetScript("OnClick", onClick)
APR:RegisterSkinTarget(preset, "button")
APR:RegisterSkinTarget(arrow, "arrow", { direction = "left" })
APR:RegisterSkinTarget(scroll, "scrollbar")
APR:RegisterSkinTarget(close, "close")
APR:RegisterSkinTarget(item, "icon", { texture = icon })
APR.ElvUISkin:OnEnable()
assert(not next(calls), "Disabled skin leaves native art and behavior alone")
APR.settings.profile.elvuiSkin = true
APR.ElvUISkin:OnEnable()
assert(calls.button == 1 and calls.arrow == 1 and calls.scrollbar == 1 and calls.close == 1 and calls.icon == 1)
assert(arrow.width == 30 and arrow.height == 24 and arrow.direction == "left")
assert(close.width == 30 and close.height == 24)
assert(arrow.scripts.OnClick == onClick)
arrow.scripts.OnClick()
assert(clicked == 1)
assert(item.attributes.type == "item" and item.attributes.item == "item:239142" and not item.skin,
    "The item texture is skinned without rewriting its secure button")
for _ = 1, 20 do
    APR:RegisterSkinTarget(preset, "button")
    APR.ElvUISkin:ApplySkins()
end
assert(calls.button == 1 and calls.arrow == 1, "Reopening pooled windows cannot stack skin hooks")
local nestedPopupButton = CreateFrame()
APR:RegisterSkinTarget(nestedPopupButton, "button")
assert(calls.button == 2, "Anonymous buttons created after login are styled immediately")
combat = true
local deferred = CreateFrame()
APR:RegisterSkinTarget(deferred, "arrow", { direction = "down" })
assert(not deferred.skin)
combat = false
events.scripts.OnEvent()
assert(deferred.skin == "arrow" and deferred.direction == "down")
APR:RegisterSkinTarget(CreateFrame(), "borderedPanel")
local panel = frames[#frames]
assert(panel.template == "Transparent", "XP overlay and its new header use the provider border")
APR.settings.profile.elvuiSkin = false
local native = CreateFrame()
APR:RegisterSkinTarget(native, "button")
assert(not native.skin)
assert(not APR:RegisterSkinProvider("Other", function() error("Must not stack providers") end, function() return true end))
print("PASS: ElvUI late/nested controls, arrows, scrollbars, XP borders, disabled skin, idempotence and combat deferral")

-- EllesmereUI owns registration timing and its per-addon preference.
ElvUI, EllesmereUI = nil, nil
dofile("APR-Core/integrations/EllesmereUISkin.lua")
EllesmereUI = {} -- Older versions without the public API remain harmless.
dofile("APR-Core/integrations/EllesmereUISkin.lua")
assert(not APR.EllesmereUISkin)
dofile("APR-Core/integrations/SkinRegistry.lua")
events = frames[#frames]
local callback, euiEnabled
EllesmereUI.RegisterSkin = function(name, apply)
    assert(name == "APR")
    callback = apply
end
dofile("APR-Core/integrations/EllesmereUISkin.lua")
assert(callback, "Register through the public API, not private EUI globals")
local eui = { IsEnabled = function() return euiEnabled end }
for _, kind in ipairs({ "Button", "PageButton", "ScrollBar", "CloseButton", "SquareIcon",
    "Panel", "Shell", "EditBox", "Font", "StateButtonLabel" }) do
    local method = kind
    eui[method] = function(frame, options)
        record(method, frame)
        frame.options = options
    end
end
euiEnabled = true
APR.settings.profile.ellesmereuiSkin = false
local latePreset = CreateFrame()
APR:RegisterSkinTarget(latePreset, "button")
callback(eui)
assert(not latePreset.skin, "APR's EllesmereUI switch is respected")
APR.settings.profile.ellesmereuiSkin = true
ElvUI = {}
APR.settings.profile.elvuiSkin = true
callback(eui)
assert(not latePreset.skin, "ElvUI takes precedence when both are enabled")
ElvUI = nil
callback(eui)
assert(latePreset.skin == "Button")
local nextButton, vertical, overlayPanel, imagePanel, secureIcon = CreateFrame(), CreateFrame(), CreateFrame(), CreateFrame(), CreateFrame()
function vertical:CreateFontString()
    local label = CreateFrame()
    label.SetPoint = noop
    function label:SetText(text) self.text = text end
    return label
end
function vertical:SetFontString(label) self.label = label end
APR:RegisterSkinTarget(nextButton, "arrow", { direction = "right" })
APR:RegisterSkinTarget(vertical, "arrow", { direction = "up" })
APR:RegisterSkinTarget(overlayPanel, "borderedPanel")
APR:RegisterSkinTarget(imagePanel, "panel", { preserveBackground = true })
APR:RegisterSkinTarget(secureIcon, "icon", { texture = icon })
assert(nextButton.skin == "PageButton" and nextButton.options == ">")
assert(vertical.label.text == "▲" and vertical.width == 30 and vertical.height == 24)
assert(overlayPanel.skin == "Panel")
assert(not imagePanel.skin, "Skinning must not fade the preview image or APR-managed backgrounds")
assert(icon.skin == "SquareIcon" and not secureIcon.skin and secureIcon.attributes.item == "item:239142")
local minimize = CreateFrame()
local normal, pushed, disabled = {}, {}, {}
function minimize:GetNormalTexture() return normal end
function minimize:GetPushedTexture() return pushed end
function minimize:GetDisabledTexture() return disabled end
minimize:SetScript("OnClick", onClick)
APR:RegisterSkinTarget(minimize, "headerButton")
assert(minimize.APRNormalIcon == normal and minimize.APRPushedIcon == pushed and minimize.APRDisabledIcon == disabled)
assert(minimize.scripts.OnClick == onClick, "Keep APR collapse actions and live atlas states")
combat = true
local deferredEUI = CreateFrame()
APR:RegisterSkinTarget(deferredEUI, "editbox")
assert(not deferredEUI.skin)
combat = false
events.scripts.OnEvent()
assert(deferredEUI.skin == "EditBox")
euiEnabled = false
local euiNative = CreateFrame()
APR:RegisterSkinTarget(euiNative, "button")
assert(not euiNative.skin, "EllesmereUI's own per-addon switch is respected")
euiEnabled = true
APR:RefreshRegisteredSkins()
assert(euiNative.skin == "Button")
local count = calls.Button
APR:RefreshRegisteredSkins()
assert(calls.Button == count, "No duplicate styling or theme hooks")
print("PASS: EllesmereUI public API, optional/old clients, late controls, provider priority, images and secure actions")
