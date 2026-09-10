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
