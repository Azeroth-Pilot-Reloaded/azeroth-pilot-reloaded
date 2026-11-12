-- Two synthetic characters share a profile, but never their equipment preference.
dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/utils/ProfileUtils.lua")
local stub, state = LibStub
function LibStub(name, ...)
    if name == "AceDB-3.0" then
        return { New = function(_, _, defaults)
            setmetatable(state.profile, { __index = defaults.profile })
            setmetatable(state.char, { __index = defaults.char })
            return state
        end }
    end
    if name == "AceConfig-3.0" then return { RegisterOptionsTable = function() end } end
    if name == "AceDBOptions-3.0" then return { GetOptionsTable = function() return { args = {} } end } end
    return stub(name, ...)
end
function APR:CreateTextAppearanceDefaults() return {} end
function APR:IsRemixCharacter() return false end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
APR.Color.green, APR.Color.yellow, APR.Color.orange = {}, {}, {}
APR.LayoutEditor = { Hide = function() end }
APR.title, APR.version = "APR", "test"
APR.routeconfig = { InitRouteConfig = function() return {} end }
dofile("APR-Core/utils/TextStyleUtils.lua")
dofile("APR-Core/config/Config.lua")
APR.settings.CreateBlizzardLauncher = function() end
APR.RequestReload = function() end
local callbacks = {}
local function init(character, profile)
    state = { char = character, profile = profile, global = {},
        RegisterCallback = function(owner, event, method)
            callbacks[event] = function() owner[method](owner) end
        end }
    APR.settings:InitializeSettings()
end
local shared, first, second = { bagUpgradeSuggestions = false }, {}, {}
init(first, shared)
assert(first.bagUpgradeSuggestions == false, "Login must migrate an explicit legacy false")
APR.settings:createBlizzOptions()
local options = APR.settings.optionsTable.args.group_reward_automation.args
local toggle = options.bagUpgradeSuggestions
assert(toggle.get({ "bagUpgradeSuggestions" }) == false)
assert(options.rewardWeightScale.disabled(), "The scale control follows the character's disabled suggestions")
local refreshes = 0
APR.BagUpgrades = { RefreshSettings = function() refreshes = refreshes + 1 end }
toggle.set({ "bagUpgradeSuggestions" }, true)
assert(first.bagUpgradeSuggestions == true and shared.bagUpgradeSuggestions == false)
assert(refreshes == 1 and not options.rewardWeightScale.disabled(), "Enabling refreshes suggestions and the scale control")
init(second, shared)
assert(second.bagUpgradeSuggestions == false, "Each character migrates independently")
toggle.set({ "bagUpgradeSuggestions" }, false)
assert(first.bagUpgradeSuggestions == true and second.bagUpgradeSuggestions == false)
init(first, shared)
assert(toggle.get({ "bagUpgradeSuggestions" }) == true, "Reload retains a later character choice")
for _, event in ipairs({ "OnProfileChanged", "OnProfileCopied", "OnProfileReset" }) do
    state.profile = { bagUpgradeSuggestions = false, autoHandInChoice = false }
    callbacks[event]()
    assert(toggle.get({ "bagUpgradeSuggestions" }) == true and not options.rewardWeightScale.disabled(), event)
end
init(second, { bagUpgradeSuggestions = true })
assert(toggle.get({ "bagUpgradeSuggestions" }) == false, "An explicit character false survives a different profile")
state.profile.autoHandInChoice = true
assert(not options.rewardWeightScale.disabled(), "Quest reward automation can independently enable scale selection")
local legacyEnabled, fresh, alreadyDisabled = {}, {}, { bagUpgradeSuggestions = false }
init(legacyEnabled, { bagUpgradeSuggestions = true })
assert(legacyEnabled.bagUpgradeSuggestions == true)
init(fresh, {})
assert(fresh.bagUpgradeSuggestions == true, "An absent legacy value preserves the enabled default")
init(alreadyDisabled, {})
assert(alreadyDisabled.bagUpgradeSuggestions == false, "Defaults must never mask a saved character false")
APR.settings.db = nil
assert(APR:GetBagUpgradeSuggestions() == false, "Suggestions stay disabled before character settings exist")
APR:SetBagUpgradeSuggestions(true)
print("Bag upgrade settings: independent characters, migration, explicit false, reload and profile callbacks passed")
