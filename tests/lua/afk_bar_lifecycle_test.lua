-- The AFK timer owns a native bar and never touches another addon's libraries.
local function noop() end
local now, frames, timers = 100, {}, {}
local methods = {}
setmetatable(methods, { __index = function(_, key)
    if key:match("^Set") or key:match("^Enable") then return noop end
end })
local function widget(parent)
    return setmetatable({ parent = parent, shown = true, scripts = {}, width = 250, height = 30 },
        { __index = methods })
end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetParent(parent) self.parent = parent end
function methods:GetParent() return self.parent end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetAllPoints(target) self.allPoints = target or self.parent end
function methods:GetWidth() return self.allPoints and self.allPoints:GetWidth() or self.width end
function methods:GetHeight() return self.allPoints and self.allPoints:GetHeight() or self.height end
function methods:SetPoint(...) self.point = { ... } end
function methods:ClearAllPoints() self.point = nil end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:CreateFontString() return widget(self) end
function methods:CreateAnimationGroup() return widget(self) end
function methods:CreateAnimation() return widget(self) end
function methods:Stop() self.playing = false end
function methods:SetText(text) self.text = text end
function methods:SetFormattedText(format, ...) self.text = string.format(format, ...) end
function methods:SetStatusBarColor(...) self.color = { ... } end
function methods:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
function methods:SetValue(value) self.value = value end
function CreateFrame(kind, name, parent)
    local frame = widget(parent)
    frame.kind = kind
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
function GetTime() return now end
function UnitOnTaxi() return false end
function LibStub(name)
    assert(name ~= "LibCandyBar-3.0", "APR must not obtain a shared bar or callback registry")
    return {
        GetLocale = function() return { AFK = "AFK" } end,
        RegisterConfig = noop, MakeDraggable = noop, RestorePosition = noop,
    }
end
UIParent = widget()
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function drain()
    local pending = timers
    timers = {}
    for _, callback in ipairs(pending) do callback() end
end

local refreshes = 0
APR = {
    Color = { defaultBackdrop = { 0, 0, 0, 1 }, blue = { 0, 0.5, 1 }, orange = { 1, 0.6, 0.1 } },
    settings = { profile = { enableAddon = true, afkWidth = 310, afkHeight = 24,
        afkBarColor = { 0.2, 0.4, 0.6, 0.8 } } },
    textStyleRegistry = {},
    fillersFrame = { RefreshFillersFrame = function() refreshes = refreshes + 1 end },
    questOrderList = { ApplySnapAnchor = noop },
}
function APR:NewModule() return {} end
function APR:GetSettingsProfile() return self.settings and self.settings.profile end
function APR:RegisterFontString(font, scope) self.textStyleRegistry[font] = scope end
function APR:SnapFrameToAnchor(frame, anchor) frame:SetPoint("TOP", anchor, "BOTTOM") end
dofile("APR-Core/ui/foundations/StatusBars.lua")
dofile("APR-Core/features/player/AFK.lua")
local afk, bar = APR.AFK
for _, frame in ipairs(frames) do if frame.kind == "StatusBar" then assert(not bar); bar = frame end end
assert(bar and bar:GetParent() == AfkFrameScreen)
afk:AFKFrameOnInit()
local allocated = #frames
afk:HideFrame()
afk:HideFrame()
assert(not AfkFrameScreen:IsShown() and not bar.scripts.OnUpdate)
drain()

local function tick(elapsed)
    now = now + elapsed
    if bar.scripts.OnUpdate then bar.scripts.OnUpdate(bar, elapsed) end
end
local function checkAppearance(width, height)
    assert(bar.Text.text == "AFK" and bar:GetWidth() == width and bar:GetHeight() == height)
    assert(bar.color[1] == 0.2 and bar.color[4] == 0.8)
    assert(APR.textStyleRegistry[bar.Text] == "afk" and APR.textStyleRegistry[bar.Duration] == "afk")
end
afk:SetAfkTimer(30)
checkAppearance(310, 24)
assert(bar.value == 30 and bar.maximum == 30 and bar.Duration.text == "30")
tick(5)
assert(bar.value == 25 and bar.Duration.text == "25")
afk:SetAfkTimer(60)
assert(bar.value == 60 and afk.timerEnd == now + 60)
tick(0.01)
assert(bar.value == 60, "Throttle countdown updates to the previous 40 ms cadence")
tick(0.04)
assert(bar.value < 60 and bar.value > 59)
for _, sample in ipairs({ { 3661, "1:01:01" }, { 61, "1:01" }, { 10.6, "11" }, { 9.4, "9.4" } }) do
    afk:SetAfkTimer(sample[1])
    assert(bar.Duration.text == sample[2])
end
afk:SetAfkTimer(10)
tick(20)
assert(not AfkFrameScreen:IsShown() and not bar.scripts.OnUpdate and not afk.timerEnd,
    "Natural expiry clears the timer and its update script")
afk:HideFrame()
for _ = 1, 50 do
    afk:SetAfkTimer(15)
    afk:HideFrame()
    afk:HideFrame()
end
assert(#frames == allocated, "Restarting a timer reuses its native bar and font strings")
drain()

afk:ToggleFakeTimer()
assert(afk.fakeTimerActive and bar.value == 300)
afk:ToggleFakeTimer()
assert(not afk.fakeTimerActive and not AfkFrameScreen:IsShown())
afk:ToggleFakeTimer()
APR.settings.profile.enableAddon = false
afk:SetAfkTimer(60)
assert(not afk.fakeTimerActive and not bar.scripts.OnUpdate and not AfkFrameScreen:IsShown())
local previousRefreshes = refreshes
drain()
assert(refreshes == previousRefreshes, "Deferred refresh respects addon disable")
afk:SetAfkTimer(60)
afk:ToggleFakeTimer()
assert(not afk.fakeTimerActive and not bar.scripts.OnUpdate)
APR.settings = nil
afk:SetAfkTimer(60)
drain()

APR.settings = { profile = { enableAddon = true, afkSnapToCurrentStep = true, afkHeight = 30,
    afkBarColor = { 0.2, 0.4, 0.6, 0.8 } } }
CurrentStepScreenPanel = widget()
CurrentStepScreenPanel:SetSize(420, 100)
afk:SetAfkTimer(15)
checkAppearance(420, 20)
CurrentStepScreenPanel:SetWidth(460)
afk:RefreshFrameAnchor()
assert(bar:GetWidth() == 460 and bar:GetHeight() == 20)
APR.settings.profile.afkBarColor = { 0.7, 0.8, 0.9, 1 }
afk:UpdateBarColor()
assert(bar.color[1] == 0.7)
afk:HideFrame()
APR.settings.profile.afkBarColor = { 0.3, 0.2, 0.1, 0.5 }
afk:UpdateBarColor()
afk:SetAfkTimer(20)
assert(bar.color[1] == 0.3 and bar.color[4] == 0.5, "Hidden bars keep new option colors when restarted")
for _, invalid in ipairs({ 0, -1, "60", math.huge, 0 / 0, false }) do
    afk:SetAfkTimer(invalid)
    assert(not bar.scripts.OnUpdate and not AfkFrameScreen:IsShown())
end
afk:SetAfkTimer(nil)
assert(not bar.scripts.OnUpdate)
afk:SetAfkTimer(1e-20)
assert(not bar.scripts.OnUpdate and not AfkFrameScreen:IsShown(),
    "A duration already expired during startup must not leave a stale update script")
drain()
print("PASS: native AFK ownership, countdown formatting, restarts, expiry, settings, snapping and invalid durations")
