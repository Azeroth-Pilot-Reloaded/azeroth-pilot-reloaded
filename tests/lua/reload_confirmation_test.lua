-- Real themed popup lifecycle, deferred mutations, nested AceDB callbacks and conditional skin reloads.
local env = dofile("tests/lua/route_browser_test_env.lua")
local hide = env.methods.Hide
function env.methods:Hide()
    local shown = self:IsShown()
    hide(self)
    if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
local reloads, mutations = 0, 0
C_UI = {Reload = function() reloads = reloads + 1 end}
local popup = APR:RequestReload(function() mutations = mutations + 1 end)
local staleAccept = popup.onAccept
assert(popup:IsShown() and mutations == 0 and reloads == 0 and popup.title:GetText() == "UI_RELOAD_CONFIRM")
popup.cancelButton.scripts.OnClick(popup.cancelButton)
staleAccept()
assert(mutations == 0 and reloads == 0, "Cancel preserves data and invalidates stale acceptance")
APR:RequestReload(function() mutations = mutations + 1 end)
staleAccept = popup.onAccept
popup:Accept()
staleAccept()
assert(mutations == 1 and reloads == 1, "Acceptance commits and reloads exactly once")
APR:RequestReload(function() mutations = mutations + 10 end)
staleAccept = popup.onAccept
APR:RequestReload(function() mutations = mutations + 2 end)
staleAccept()
popup:Accept()
assert(mutations == 3 and reloads == 2, "Replacing a pending confirmation cancels the old action")
APR:RequestReload(function()
    APR:RequestReload(function() mutations = mutations + 1 end)
    APR:RequestReload() -- AceDB RefreshProfile callback.
end)
popup:Accept()
assert(mutations == 4 and reloads == 3 and not popup:IsShown() and not APR.reloadConfirmationAccepted,
    "Accepted profile callbacks cannot display another popup or reload twice")
APR:RequestReload(function() return false end)
popup:Accept()
assert(reloads == 3, "An obsolete profile or combat-blocked action cannot reload")
APR:RequestReload(function() error("Expected failure") end)
assert(not pcall(popup.Accept, popup) and not APR.reloadConfirmationAccepted and reloads == 3)

-- Slash resets must wait before clearing any character or custom-route data.
APR.settings.profile.enableAddon = true
dofile("APR-Core/core/Commands.lua")
APRData.test, APRZoneCompleted.test, APRCustomPath.test = {first = 4}, {first = true}, {"first"}
local progress, completed, path = APRData.test, APRZoneCompleted.test, APRCustomPath.test
APRData.other = {kept = true}
APR.command:SlashCmd("fr")
assert(APRData.test == progress and APRZoneCompleted.test == completed and APRCustomPath.test == path and reloads == 3)
popup:Hide()
assert(APRData.test == progress and APRCustomPath.test == path, "Closing the popup cancels force reset")
APR.command:SlashCmd("forcereset")
popup:Accept()
assert(reloads == 4 and not next(APRData.test) and not next(APRZoneCompleted.test)
    and not next(APRCustomPath.test) and APRData.other.kept)
APRData.CustomRoute = {kept = true}
APR.command:SlashCmd("resetcustom")
assert(APRData.CustomRoute.kept and reloads == 4)
popup:Accept()
assert(not next(APRData.CustomRoute) and reloads == 5)

-- AceDB options use a private schema; string handlers and validators remain authoritative.
local profileName, resets, copies = "Default", 0, 0
local database = {GetCurrentProfile = function() return profileName end}
APR.settings.db = database
local handler = {}
function handler:SetProfile(_, value) profileName = value; APR:RequestReload() end
function handler:CopyProfile(_, value) copies = copies + 1; assert(value == "Other"); APR:RequestReload() end
function handler:Reset() resets = resets + 1; APR:RequestReload() end
local validator = function() return true end
local source = {handler = handler, args = {
    new = {type = "input", set = "SetProfile", validate = validator},
    choose = {type = "select", set = "SetProfile", get = "GetCurrentProfile"},
    copyfrom = {type = "select", set = "CopyProfile"},
    reset = {type = "execute", func = "Reset"},
    delete = {type = "select", set = "DeleteProfile", confirm = true},
}}
local options = APR:ConfirmProfileOptions(source)
assert(options ~= source and options.handler == handler and options.args.new.validate == validator
    and source.args.choose.set == "SetProfile" and options.args.delete.confirm)
options.args.choose.set(nil, "Other")
assert(profileName == "Default" and reloads == 5)
popup:Hide()
assert(profileName == "Default")
options.args.new.set(nil, "New")
popup:Accept()
assert(profileName == "New" and reloads == 6)
options.args.copyfrom.set(nil, "Other")
assert(copies == 0)
popup:Accept()
assert(copies == 1 and reloads == 7)
options.args.reset.func()
assert(resets == 0)
popup:Accept()
assert(resets == 1 and reloads == 8)
options.args.choose.set(nil, "New")
assert(not popup:IsShown() and reloads == 8, "Choosing the active profile does not ask or reload")

-- Snap changes only confirm if the future appearance requires rebuilding the skin.
local profile = APR.settings.profile
profile.uiTheme, profile.currentStepTrackerAppearance = "wow", "EllesmereUI"
profile.currentStepAttachFrameToQuestLog = true
profile.fillersFrameSnapToCurrentStep, profile.questOrderListSnapToCurrentStep, profile.afkSnapToCurrentStep = true, true, true
EllesmereUI = {RegisterSkin = function() end}
local geometry, prepared = 0, 0
for _, entry in ipairs({{"currentStep", "currentStepAttachFrameToQuestLog"}, {"fillers", "fillersFrameSnapToCurrentStep"},
    {"questOrderList", "questOrderListSnapToCurrentStep"}, {"afk", "afkSnapToCurrentStep"}}) do
    profile.currentStepAttachFrameToQuestLog = true
    local scope, key = unpack(entry)
    profile[key] = true
    local before = reloads
    assert(APR:ChangeTrackerOption(scope, key, false, function() geometry = geometry + 1 end,
        function() prepared = prepared + 1 end))
    assert(profile[key] and reloads == before and geometry == 0 and prepared == 0)
    popup:Hide()
    assert(profile[key], "Cancel keeps attachment and geometry unchanged")
    APR:ChangeTrackerOption(scope, key, false)
    popup:Accept()
    assert(not profile[key] and reloads == before + 1)
end
profile.currentStepTrackerAppearance = "theme"
profile.currentStepAttachFrameToQuestLog = false
local before = reloads
assert(not APR:ChangeTrackerOption("currentStep", "currentStepAttachFrameToQuestLog", true,
    function() geometry = geometry + 1 end))
assert(profile.currentStepAttachFrameToQuestLog and geometry == 1 and reloads == before and not popup:IsShown(),
    "Geometry changes without a renderer change apply immediately")

print("Reload confirmation: cancellation, one-shot acceptance, reset commands, isolated profile handlers and conditional snaps passed")
