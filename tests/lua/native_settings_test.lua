-- Regressions for the restored settings entry points; route row/reorder behavior lives in memory_recycling_test.
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
APR.RouteBrowser = {Show = function() error("Do not redirect to the removed route browser") end}
local root, routes, selections = {}, {}, {}
function routes:GetName() return "Routes" end
function root:HasSubcategories() return true end
function root:GetSubcategories() return {routes} end
SettingsPanel = {
    GetCategoryList = function() return {GetCategory = function(_, name) assert(name == "APR"); return root end} end,
    Open = function() end,
    SelectCategory = function(_, category) selections[#selections + 1] = category end,
}
Settings = {OpenToCategory = function(id) assert(id == 42) end}
APR.settings:OpenSettings("Routes")
assert(selections[#selections] == routes)
APR.settings:OpenSettings("APR")
assert(selections[#selections] == root)
SettingsPanel = nil
local legacy = {}
function InterfaceOptionsFrame_OpenToCategory(category) legacy[#legacy + 1] = category end
APR.settings:OpenSettings("Routes")
assert(legacy[1] == APR.Options and legacy[2] == APR.OptionsRoute)
print("Native settings: modern and legacy categories restored without experimental redirects passed")
