-- Fresh defaults detect integrations; saved manual choices remain authoritative.
dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
local profile = {}
APR.settings.profile = profile
ElvUI, EllesmereUI = nil, nil
assert(APR:GetSelectedSkinName() == "wow")
EllesmereUI = {RegisterSkin = function() end}
assert(APR:GetSelectedSkinName() == "EllesmereUI", "A fresh Ellesmere installation adopts its skin automatically")
ElvUI = {}
assert(APR:GetSelectedSkinName() == "ElvUI", "ElvUI retains automatic priority when both integrations are loaded")
profile.uiTheme = "EllesmereUI"
assert(APR:GetSelectedSkinName() == "EllesmereUI", "An explicit Ellesmere choice wins over automatic ElvUI priority")
profile.uiTheme = "modern"
assert(APR:GetSelectedSkinName() == "modern")
profile.uiTheme = "wow"
assert(APR:GetSelectedSkinName() == "wow", "Explicit native WoW remains selectable with both addons loaded")
profile.uiTheme, profile.elvuiSkin = nil, false
assert(APR:GetSelectedSkinName() == "EllesmereUI")
profile.ellesmereuiSkin = false
assert(APR:GetSelectedSkinName() == "wow", "Legacy opt-outs remain respected")
profile.uiTheme = "EllesmereUI"
EllesmereUI = nil
assert(APR:GetSelectedSkinName() == "wow", "An unavailable manual integration has a safe fallback")

-- Capture the production defaults at AceDB creation, before unrelated onboarding setup.
ElvUI = nil
local originalLibStub, defaults = LibStub
local captured = {}
function LibStub(name, ...)
    if name == "AceDB-3.0" then
        return {New = function(_, _, value) defaults = value; error(captured) end}
    end
    return originalLibStub(name, ...)
end
function APR:CreateTextAppearanceDefaults(useGlobal) return {useGlobal = useGlobal} end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
APR.Color.orange = {1, 0.64, 0.1, 1}
dofile("APR-Core/utils/TextStyleUtils.lua")
dofile("APR-Core/config/Config.lua")
local ok, err = pcall(APR.settings.InitializeSettings, APR.settings)
assert(not ok and err == captured and defaults.profile.uiTheme == nil,
    "AceDB must not inject a WoW theme that masks automatic provider detection")
APR.settings.profile = defaults.profile
EllesmereUI = {RegisterSkin = function() end}
assert(APR:GetSelectedSkinName() == "EllesmereUI")
print("Theme auto selection: production defaults, both addons, manual themes, opt-outs and unavailable providers passed")
