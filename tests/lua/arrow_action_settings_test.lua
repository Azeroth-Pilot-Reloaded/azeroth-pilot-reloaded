-- The optional arrow caption preserves existing profiles and updates without a reload.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local stub, defaults = LibStub, nil
function LibStub(name, ...)
    if name == "AceDB-3.0" then return {New = function(_, _, value)
        defaults = value
        return {profile = value.profile, char = {}, global = {}, RegisterCallback = function() end}
    end} end
    if name == "AceConfig-3.0" then return {RegisterOptionsTable = function() end} end
    if name == "AceDBOptions-3.0" then return {GetOptionsTable = function() return {args = {}} end} end
    return stub(name, ...)
end
dofile("APR-Core/utils/TextStyleUtils.lua")
dofile("APR-Core/config/Config.lua")
function APR:CreateTextAppearanceDefaults() return {} end
function APR:IsRemixCharacter() return false end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
APR.Color.green, APR.Color.yellow, APR.Color.orange = {}, {}, {}
APR.LayoutEditor = {}
APR.title, APR.version = "APR", "test"
APR.routeconfig = {InitRouteConfig = function() return {} end}
APR.settings.CreateBlizzardLauncher = function() end
APR.settings:InitializeSettings()
assert(defaults.profile.arrowActionText == false, "Action captions must default off")
APR.settings:createBlizzOptions()
local profile = APR.settings.profile
local options = APR.settings.optionsTable.args.group_Arrow.args.subgroup_Arrow.args
local caption = options.arrowActionText
assert(caption.name == "Show action text" and caption.desc:find("secondary actions", 1, true),
    "Untranslated options must retain usable labels without adding locale files")
assert(caption.get({"arrowActionText"}) == false)
profile.enableAddon, profile.showArrow = true, true
assert(not caption.disabled())
profile.showArrow = false
assert(caption.disabled(), "Caption controls require a visible arrow")
profile.showArrow, profile.enableAddon = true, false
assert(caption.disabled(), "Caption controls require APR to be enabled")
profile.enableAddon = true
local refreshes, sizes = {}, 0
function APR:UpdateStep() refreshes[#refreshes + 1] = "step" end
APR.Arrow = {
    UpdateTextAppearance = function() refreshes[#refreshes + 1] = "text" end,
    ApplySize = function() sizes = sizes + 1 end,
}
caption.set({"arrowActionText"}, true)
assert(profile.arrowActionText and table.concat(refreshes, ",") == "step,text",
    "Enabling captions refreshes current actions before applying text appearance")
caption.set({"arrowActionText"}, false)
assert(not profile.arrowActionText and table.concat(refreshes, ",") == "step,text,step,text",
    "Disabling captions refreshes immediately")
profile.arrowActionText, profile.arrowScale, profile.arrowTextScale = true, 2, 1.5
APR.ArrowFrameM = env.widget()
options.arrowReset.func()
assert(not profile.arrowActionText and profile.arrowScale == 1 and profile.arrowTextScale == 1 and sizes == 1)
assert(table.concat(refreshes, ",") == "step,text,step,text,step,text",
    "Arrow reset removes the caption and refreshes current text")
APR.UpdateStep, APR.Arrow = nil, nil
caption.set({"arrowActionText"}, true)
assert(profile.arrowActionText, "The setting remains safe before arrow initialization")
print("Arrow action settings: default, labels, enablement, immediate refresh and reset passed")
