dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
local stub, defaults = LibStub
function LibStub(name, ...)
    if name == "AceDB-3.0" then
        return {
            New = function(_, _, value)
                defaults = value
                return { profile = value.profile, char = value.char, global = {}, RegisterCallback = function() end }
            end,
        }
    end
    if name == "AceConfig-3.0" then return { RegisterOptionsTable = function() end } end
    if name == "AceDBOptions-3.0" then return { GetOptionsTable = function() return { args = {} } end } end
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
APR.routeconfig = { InitRouteConfig = function() return {} end }
APR.settings.CreateBlizzardLauncher = function() end
APR.settings:InitializeSettings()
assert(defaults.profile.autoBuySupplies == false, "Every new or existing profile defaults to manual supply buying")
assert(defaults.profile.autoSellRouteItems == true, "Route selling preserves the existing automatic default")
APR.settings:createBlizzOptions()
dofile("APR-Core/config/WorkspaceOptions.lua")
local option, saleOption
for _, category in ipairs(APR.WorkspaceOptions:Build(APR.settings)) do
    if category.id == "automation" then
        for _, view in ipairs(APR.WorkspaceOptions:Views(category)) do
            if view.id == "main" then
                option = view.options.args.comfort.args.autoBuySupplies
                saleOption = view.options.args.comfort.args.autoSellRouteItems
            end
        end
    end
end
assert(
    option and option.type == "toggle" and option.get({ "autoBuySupplies" }) == false,
    "Automation must expose the disabled supply option"
)
local resumes, current = 0, { BuyMerchant = { { itemID = 1, quantity = 3, isSupply = true } } }
APR.GetCurrentStep = function() return current end
APR.npcInteraction = {
    HandleMerchantPurchase = function(_, step)
        assert(step == current)
        resumes = resumes + 1
    end,
}
option.set({ "autoBuySupplies" }, true)
assert(APR.settings.profile.autoBuySupplies and resumes == 0, "Changing settings away from a merchant cannot buy")
APR.routeMerchantOpen = true
option.set({ "autoBuySupplies" }, false)
assert(not APR.settings.profile.autoBuySupplies and resumes == 0, "Turning off cannot trigger another purchase")
option.set({ "autoBuySupplies" }, true)
assert(resumes == 1, "Opting in at an open merchant resumes the current purchase immediately")
APR.settings.profile.enableAddon = false
option.set({ "autoBuySupplies" }, true)
assert(resumes == 1, "The opt-in must respect the global addon switch")
print("Supply settings: default-off, Automation visibility, merchant resume and addon switch passed")

assert(saleOption and saleOption.type == "toggle" and saleOption.get({ "autoSellRouteItems" }) == true)
local cancelled, refreshed = 0, 0
APR.npcInteraction.CancelMerchantSales = function() cancelled = cancelled + 1 end
APR.event = { QueueStepRefresh = function() refreshed = refreshed + 1 end }
saleOption.set({ "autoSellRouteItems" }, false)
assert(not APR.settings.profile.autoSellRouteItems and cancelled == 1 and refreshed == 1)
saleOption.set({ "autoSellRouteItems" }, true)
assert(APR.settings.profile.autoSellRouteItems and cancelled == 2 and refreshed == 2)
assert(APR.settings.profile.autoVendor == false, "Route selling and ordinary auto-vendor are independent")
APR.npcInteraction.autoVendorState = {}
saleOption.set({ "autoSellRouteItems" }, false)
assert(cancelled == 2 and refreshed == 3, "Changing route selling must preserve an ordinary auto-vendor session")
