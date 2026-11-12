-- Real AceConfig rendering into APR's custom host must refresh after external changes.
local env = dofile("tests/lua/route_ui_test_env.lua")
function env.methods:GetScript(event) return self.scripts[event] end
function env.methods:IsVisible() return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
local now, timers, inSetter = 0, {}, false
function securecallfunction(fn, ...) return fn(...) end
function geterrorhandler()
    return function(message) error(message) end
end
function CloseSpecialWindows() end
local originalXpcall = xpcall
function xpcall(fn, handler, ...)
    local arguments = { ... }
    return originalXpcall(function() return fn(unpack(arguments)) end, handler)
end
table.wipe, strmatch = wipe, string.match
C_Timer = {
    NewTimer = function(delay, callback)
        local timer = { at = now + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end,
}

LibStub = nil
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/HereBeDragons/CallbackHandler-1.0/CallbackHandler-1.0.lua")
local strings = {
    REWARD_WEIGHT_SCALE_DESC = "Choose a scale",
    REWARD_WEIGHT_DEFAULT_DESC = "APR: %s",
    REWARD_PAWN_UNAVAILABLE = "Unavailable: %s",
}
local locale = LibStub:NewLibrary("AceLocale-3.0", 1)
function locale:GetLocale() return strings end

local controlMethods = {}
for _, method in ipairs({
    "SetLabel",
    "SetTitle",
    "SetLayout",
    "PauseLayout",
    "ResumeLayout",
    "DoLayout",
    "PerformLayout",
    "SetWidth",
    "SetStatusTable",
    "SetFontObject",
    "SetDisabled",
}) do
    controlMethods[method] = function() end
end
function controlMethods:SetUserData(key, value) self.user[key] = value end
function controlMethods:GetUserData(key) return self.user[key] end
function controlMethods:GetUserDataTable() return self.user end
function controlMethods:SetCallback(event, callback) self.callbacks[event] = callback end
function controlMethods:AddChild(child) self.children[#self.children + 1] = child end
function controlMethods:SetList(values) self.values = values end
function controlMethods:SetValue(value) self.value = value end
function controlMethods:SetText(text) self.text = text end
function controlMethods:Show() end
function controlMethods:ReleaseChildren()
    assert(not inSetter, "External notifications cannot recycle controls inside their setter")
    self.children = {}
    self.releases = (self.releases or 0) + 1
end
local function control(kind)
    return setmetatable({ type = kind, user = {}, callbacks = {}, children = {} }, { __index = controlMethods })
end
local gui = LibStub:NewLibrary("AceGUI-3.0", 1)
function gui:Create(kind) return control(kind) end
function gui:GetWidgetVersion() return 1 end
dofile("APR-Core/libs/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua")
dofile("APR-Core/libs/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua")
local registry, dialog = LibStub("AceConfigRegistry-3.0"), LibStub("AceConfigDialog-3.0")
local function advance(seconds)
    local untilTime = now + seconds
    for _ = 1, 100 do
        local nextTimer
        for _, timer in ipairs(timers) do
            if
                not timer.cancelled
                and not timer.fired
                and timer.at <= untilTime
                and (not nextTimer or timer.at < nextTimer.at)
            then
                nextTimer = timer
            end
        end
        if nextTimer then
            now, nextTimer.fired = nextTimer.at, true
            nextTimer.callback()
        else
            local update = dialog.frame:GetScript("OnUpdate")
            if update then
                update(dialog.frame)
            else
                now = untilTime
                return
            end
        end
    end
    error("A settings refresh cannot keep scheduling itself")
end

APR.UI = {}
APR.settings = { db = { char = {} }, profile = { enableAddon = true, autoHandIn = true, autoHandInChoice = false } }
function APR:GetSettingsProfile() return self.settings.profile end
function APR:NewModule()
    return { RegisterEvent = function() end, UnregisterEvent = function() end, UnregisterAllEvents = function() end }
end
APR.RewardScoring = { GetProfileDescription = function() return "Synthetic class" end }
UnitClass = function() return "Synthetic class", "FIXTURE", 8 end
C_SpecializationInfo =
    { GetSpecialization = function() return 1 end, GetSpecializationInfo = function() return 901 end }
function hooksecurefunc(name, callback)
    local previous = _G[name]
    _G[name] = function(...)
        local results = { previous(...) }
        callback(...)
        return unpack(results)
    end
end
PawnCommon = { Scales = { Existing = { Values = { Intellect = 2 }, ClassID = 8 } } }
function PawnIsReady() return true end
function PawnGetAllScalesEx()
    local result = {}
    for name in pairs(PawnCommon.Scales) do
        result[#result + 1] = { Name = name, LocalizedName = name }
    end
    return result
end
function PawnGetAllStatValues(name) return PawnCommon.Scales[name].Values end
function PawnGetItemData() return { UnenchantedStats = {} } end
function PawnGetSingleValueFromItem() return 0, 0 end
function PawnImportScale(name) PawnCommon.Scales[name] = { Values = { Intellect = 4 }, ClassID = 8 } end
function PawnDeleteScale(name) PawnCommon.Scales[name] = nil end
dofile("APR-Core/utils/ProfileUtils.lua")
dofile("APR-Core/integrations/Pawn.lua")
dofile("APR-Core/ui/panels/OptionsPanel.lua")
local pawn, panel = APR.PawnRewards, APR.OptionsPanel
pawn:OnEnable()
local app = "Fixture/Options/rewards"
registry:RegisterOptionsTable(app, {
    type = "group",
    name = "Synthetic rewards",
    args = {
        scale = {
            type = "select",
            order = 1,
            name = "Scale",
            values = function() return pawn:GetScaleOptions() end,
            get = function() return pawn:GetSelectedScale() end,
            set = function(_, value)
                inSetter = true
                pawn:SetSelectedScale(value)
                inSetter = false
            end,
        },
        status = { type = "description", order = 2, name = function() return pawn:GetStatusText() end },
    },
})
panel.frame = CreateFrame("Frame")
panel.host = control("APRSettingsHost")
panel.view = { app = app }
dialog:Open(app, panel.host)
assert(
    not dialog.OpenFrames[app] and not dialog.BlizOptions[app],
    "The custom APR host is deliberately outside AceConfig's standard window registry"
)
local function visible()
    local dropdown, status
    local function visit(parent)
        for _, child in ipairs(parent.children) do
            if child.type == "Dropdown" then dropdown = child end
            if child.type == "Label" then status = child end
            visit(child)
        end
    end
    visit(panel.host)
    assert(dropdown and status, "The real AceConfig renderer must produce both controls")
    return dropdown, status.text
end
local dropdown, status = visible()
assert(dropdown.value == "apr" and status == "APR: Synthetic class")
PawnImportScale("Imported")
advance(1)
dropdown = visible()
assert(dropdown.values["pawn:Imported"], "An import must refresh the existing real custom-host selector")

dropdown.callbacks.OnValueChanged(dropdown, "OnValueChanged", "pawn:Imported")
advance(0)
dropdown, status = visible()
assert(
    dropdown.value == "pawn:Imported" and status:find("Imported", 1, true),
    "A choice must refresh the displayed selection and status together"
)
PawnDeleteScale("Imported")
advance(1)
dropdown, status = visible()
assert(
    dropdown.values["pawn:Imported"] and dropdown.value == "pawn:Imported" and status == "Unavailable: Imported",
    "Deletion preserves the explicit selection and publishes unavailability without closing the page"
)

-- Bursts coalesce, and getters never trigger a self-sustaining rebuild.
local releases = panel.host.releases
for _ = 1, 20 do
    pawn:NotifyOptions()
end
assert(panel.host.releases == releases, "Notifications leave the current control alive until the callback returns")
advance(0)
assert(panel.host.releases == releases + 1, "One burst causes one deferred reconstruction")
releases = panel.host.releases
for _ = 1, 20 do
    pawn:GetScaleOptions()
    pawn:GetSelectedScale()
    pawn:GetStatusText()
end
advance(1)
assert(panel.host.releases == releases, "Reading values cannot schedule another refresh")

-- A queued refresh never opens an old page or rebuilds a hidden/replaced host.
pawn:NotifyOptions()
local oldView, oldHost = panel.view, panel.host
panel.view = { app = "Fixture/Options/other" }
advance(0)
assert(panel.host.releases == releases, "Switching views retires the old request")
panel.view = oldView
pawn:NotifyOptions()
local ancestor = CreateFrame("Frame")
panel.frame.parent = ancestor
ancestor:Hide()
advance(0)
assert(panel.host.releases == releases, "Hidden ancestors retire deferred work")
ancestor:Show()
pawn:NotifyOptions()
local retired = panel.refreshRequest
panel:CancelRefresh()
assert(retired.timer.cancelled, "Closing the page cancels its owned request")
pawn:NotifyOptions()
local currentRequest = panel.refreshRequest
retired.timer.callback()
assert(panel.refreshRequest == currentRequest, "A retired callback cannot consume a newer refresh")
advance(0)
releases = panel.host.releases
pawn:NotifyOptions()
panel.host = control("APRSettingsHost")
advance(0)
assert(not panel.host.releases and oldHost.releases == releases, "A replacement host cannot consume an older request")
print("Pawn options: real AceConfig custom-host rendering, deferred refresh, current choices and stale requests passed")
