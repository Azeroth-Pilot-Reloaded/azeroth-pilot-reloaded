-- Ordinary settings retain their native categories; route entry points open the dedicated browser.
local env = dofile("tests/lua/route_ui_test_env.lua")
local oldLibStub = LibStub
function LibStub(name)
    if name == "AceLocale-3.0" then return {GetLocale = function() return {ROUTE = "Routes"} end} end
    return oldLibStub(name)
end
dofile("APR-Core/config/Config.lua")
APR.title, APR.Options, APR.OptionsRoute = "APR", {name = "APR"}, {}
APR.settings.category = {ID = 42}
APR.SettingsHome = {Show = function() error("Do not redirect to the removed settings home") end}
local browserOpens = 0
APR.RouteBrowser = {Show = function() browserOpens = browserOpens + 1 end}
local root, routes, selections = {}, {}, {}
local closed = 0
function routes:GetName() return "Routes" end
function root:HasSubcategories() return true end
function root:GetSubcategories() return {routes} end
SettingsPanel = {
    GetCategoryList = function() return {GetCategory = function(_, name) assert(name == "APR"); return root end} end,
    Open = function() end,
    SelectCategory = function(_, category) selections[#selections + 1] = category end,
    Hide = function() closed = closed + 1 end,
}
Settings = {OpenToCategory = function(id) assert(id == 42) end}
APR.settings:OpenSettings("Routes")
assert(browserOpens == 1 and #selections == 0)
APR.settings:OpenSettings("APR")
assert(selections[#selections] == root and browserOpens == 1)
APR.settings:CloseSettings()
assert(closed == 1)
SettingsPanel = nil
InterfaceOptionsFrame = {Hide = function() closed = closed + 1 end}
local legacy = {}
function InterfaceOptionsFrame_OpenToCategory(category) legacy[#legacy + 1] = category end
APR.settings:OpenSettings("Routes")
assert(browserOpens == 2 and #legacy == 0)
APR.settings:OpenSettings("APR")
assert(legacy[#legacy] == APR.Options and browserOpens == 2)
APR.settings:CloseSettings()
assert(closed == 2, "Opening placement or route browsing also closes legacy settings")
print("Native settings: native modern/legacy options and dedicated route-browser entry point passed")
