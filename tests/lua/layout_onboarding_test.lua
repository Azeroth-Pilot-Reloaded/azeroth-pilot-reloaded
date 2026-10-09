local env = dofile("tests/lua/route_ui_test_env.lua")
local stub, state, defaults = LibStub, nil, nil
function LibStub(name, ...)
    if name == "AceDB-3.0" then return {New = function(_, _, value)
        defaults = value
        return state
    end} end
    return stub(name, ...)
end
function APR:CreateTextAppearanceDefaults() return {} end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
APR.Color.green, APR.Color.yellow, APR.Color.orange = {}, {}, {}
APR.LayoutEditor = {}
dofile("APR-Core/config/Config.lua")
local function init(saved, profile, global)
    APRSettings = saved
    state = {profile = profile or {}, global = global or {}, char = {}, RegisterCallback = function() end}
    APR.settings:InitializeSettings()
    return state
end
local fresh = init(nil)
assert(APR.LayoutEditor.firstUsePending and fresh.profile.currentStepTrackerSide == "above")
assert(defaults.profile.currentStepTrackerSide == nil, "AceDB defaults must not mask legacy attachment migration")
local old = init({profiles = {Default = {}}}, {currentStepAttachFrameToQuestLog = true})
assert(not APR.LayoutEditor.firstUsePending and old.global.layoutEditorSeen and old.profile.currentStepTrackerSide == "below")
init({profileKeys = {alt = "Default"}}, {}, {layoutEditorSeen = true})
assert(not APR.LayoutEditor.firstUsePending, "New characters and profiles cannot repeat account-wide onboarding")

dofile("APR-Core/ui/panels/LayoutEditor.lua")
local editor, pending, opens = APR.LayoutEditor, {}, 0
APR.RegisterSupportedEvent = function(_, frame, event) frame:RegisterEvent(event) end
function APR:IsPetBattleActive() return false end
function IsLoggedIn() return true end
C_Timer = {After = function(_, fn) pending[#pending + 1] = fn end}
function editor:Show() opens = opens + 1; self.firstUsePending = nil; return true end
function env.methods:UnregisterAllEvents() self.unregistered = true end
local function flush() local tasks = pending; pending = {}; for _, fn in ipairs(tasks) do fn() end end
editor.firstUsePending = true
env.setCombat(true)
editor:InitializeOnboarding()
flush()
assert(opens == 0 and editor.firstUsePending, "First-use placement waits for combat to end")
env.setCombat(false)
editor.onboarding.scripts.OnEvent(editor.onboarding, "PLAYER_REGEN_ENABLED")
editor.onboarding.scripts.OnEvent(editor.onboarding, "PLAYER_ENTERING_WORLD")
flush()
assert(opens == 1 and editor.onboarding.unregistered)
editor.onboarding.scripts.OnEvent(editor.onboarding, "PLAYER_ENTERING_WORLD")
flush()
assert(opens == 1)
print("Placement onboarding: account-wide detection, legacy migration, delayed login and combat deferral passed")
