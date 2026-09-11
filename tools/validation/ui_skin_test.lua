-- Run with Lua 5.1, or python tools/validation/run_lua_tests.py --skins-only.
local combat = false
function InCombatLockdown() return combat end
local frames = {}
local function noop() end
function CreateFrame()
    local frame = { scripts = {}, width = 30, height = 24, attributes = { type = "item", item = "item:239142" } }
    function frame:RegisterEvent(event) self.event = event end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:HookScript(event, callback)
        local previous = self.scripts[event]
        self.scripts[event] = function(...) if previous then previous(...) end; callback(...) end
    end
    function frame:GetFontString() return self.label end
    function frame:SetFontString(label) self.label = label end
    function frame:CreateFontString() return CreateFrame() end
    function frame:CreateTexture() return CreateFrame() end
    function frame:SetText(text) self.text = text end
    function frame:SetTexture(texture) self.texture = texture end
    function frame:SetDesaturated(value) self.desaturated = value end
    function frame:SetAlpha(alpha) self.alpha = alpha end
    function frame:SetShown(shown) self.shown = shown end
    function frame:SetTextColor(...) self.color = { ... } end
    function frame:SetColorTexture(...) self.color = { ... } end
    function frame:SetVertexColor(...) self.color = { ... } end
    function frame:GetFrameLevel() return 1 end
    frame.SetPoint, frame.SetHeight, frame.SetAllPoints = noop, noop, noop
    frame.SetFrameLevel, frame.EnableMouse, frame.SetBackdrop = noop, noop, noop
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
    frame.skinned = frame.skinned or {}
    frame.skinned[kind] = true
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
    "Panel", "Shell", "EditBox", "Font", "StateButtonLabel", "FadeRegions", "ApplyBarFill" }) do
    local method = kind
    eui[method] = function(frame, options)
        record(method, frame)
        frame.options = options
    end
end
local looksChanged, refreshes = nil, 0
eui.GetFont = function() return "EUI-font.ttf", "OUTLINE" end
eui.GetAccentColor = function() return 0, 0.8, 0.6 end
eui.OnLooksChanged = function(fn) looksChanged = fn end
function APR:RefreshTextAppearance() refreshes = refreshes + 1 end
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
APR:RegisterSkinTarget(nextButton, "arrow", { direction = "right" })
APR:RegisterSkinTarget(vertical, "arrow", { direction = "up" })
APR:RegisterSkinTarget(overlayPanel, "borderedPanel")
APR:RegisterSkinTarget(imagePanel, "panel", { preserveContent = true })
APR:RegisterSkinTarget(secureIcon, "icon", { texture = icon })
assert(nextButton.skin == "PageButton" and nextButton.options == ">")
assert(vertical.label.text == "▲" and vertical.width == 30 and vertical.height == 24)
assert(overlayPanel.skin == "Panel")
assert(not imagePanel.skin and frames[#frames].skin == "Panel", "A separate panel protects preview image textures")
assert(icon.skin == "SquareIcon" and not secureIcon.skin and secureIcon.attributes.item == "item:239142")
local minimize = CreateFrame()
local function atlasTexture()
    return {
        SetAtlas = function(self, atlas) self.atlas = atlas end,
        SetDesaturated = function(self, value) self.desaturated = value end,
        SetVertexColor = function(self, ...) self.color = { ... } end,
    }
end
local normal, pushed, highlight, disabled = atlasTexture(), atlasTexture(), atlasTexture(), atlasTexture()
function minimize:GetNormalTexture() return normal end
function minimize:GetPushedTexture() return pushed end
function minimize:GetHighlightTexture() return highlight end
function minimize:GetDisabledTexture() return disabled end
minimize:SetScript("OnClick", onClick)
local parent = CreateFrame()
APR:RegisterSkinTarget(parent, "panel", { preserveBackground = true })
local background = frames[#frames]
APR:RegisterSkinTarget(minimize, "headerButton", { parent = parent })
assert(normal.atlas == "UI-QuestTrackerButton-Secondary-Collapse" and normal.desaturated
    and normal.color[2] == 0.8 and minimize:GetNormalTexture() == normal)
parent.collapsed = true
minimize.scripts.OnClick()
assert(clicked == 2 and normal.atlas == "UI-QuestTrackerButton-Secondary-Expand",
    "Keep APR collapse actions while updating the Quest Tracker atlas")
assert(background.shown == false, "Collapsing a window also hides its themed body background")
local settingsButton = CreateFrame()
APR:RegisterSkinTarget(settingsButton, "settings")
local settingsIcon = frames[#frames]
assert(settingsIcon.texture == "Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\dm_settings.png"
    and settingsIcon.color[2] == 0.8 and settingsIcon.color[4] == 0.4,
    "Current Step reuses the Damage Meter settings icon and tint")
local header = CreateFrame()
header.Text = CreateFrame()
APR:RegisterSkinTarget(header, "header")
assert(header.Text.color[2] == 0.8)
assert(header.options.noBg ~= true, "Headers must have a readable theme background")
local stepRow = CreateFrame()
APR:RegisterSkinTarget(stepRow, "row")
assert(stepRow.skin == "Panel" and stepRow.options.noBg ~= true and stepRow.options.noBorder,
    "Current-step rows beyond the root frame need a continuous background")
assert(APR.EllesmereUISkin:GetFont() == "EUI-font.ttf")
assert(APR.EllesmereUISkin:GetTextColor("accent")[2] == 0.8)
assert(APR.EllesmereUISkin:GetTextColor("success")[2] == 1)
local beforeRefresh = refreshes
looksChanged()
assert(refreshes == beforeRefresh + 1, "Live theme changes refresh existing APR text")
combat = true
looksChanged()
assert(refreshes == beforeRefresh + 1, "Theme relayout is deferred during combat")
local deferredEUI = CreateFrame()
APR:RegisterSkinTarget(deferredEUI, "editbox")
assert(not deferredEUI.skin)
combat = false
events.scripts.OnEvent()
for _, frame in ipairs(frames) do
    if frame.event == "PLAYER_REGEN_ENABLED" and frame ~= events then frame.scripts.OnEvent() end
end
assert(refreshes == beforeRefresh + 2)
assert(deferredEUI.skinned.EditBox and deferredEUI.skinned.Font)
euiEnabled = false
assert(APR.EllesmereUISkin:GetFont() == nil and APR.EllesmereUISkin:GetTextColor("base") == nil)
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

-- Exercise the real text registry: later layout updates must not undo the skin.
local media = { GetDefault = function() return "Native" end, Fetch = function() return "native.ttf" end }
function LibStub() return media end
function APR:ResolveUIFileAsset(path) return path end
dofile("APR-Core/ui/foundations/TextStyles.lua")
local text = CreateFrame()
function text:SetFont(path, size, flags) self.font, self.size, self.flags = path, size, flags; return true end
local reflows = 0
APR:RegisterFontString(text, "currentStep", { role = "base", sizeDelta = 2,
    onApplied = function() reflows = reflows + 1 end })
assert(text.font == "EUI-font.ttf" and text.size == 14 and text.color[1] == 0.72 and reflows == 1)
APR:SetFontStringRole(text, "success")
assert(text.font == "EUI-font.ttf" and text.color[1] == 0.25 and reflows == 2)
APR.settings.profile.ellesmereuiSkin = false
APR:ApplyAllTextStyles()
assert(text.font == "native.ttf" and text.color[1] == 0, "Disabled EUI restores native text preferences")
print("PASS: EllesmereUI dynamic fonts, semantic colors, relayout callbacks and native fallback")
