local env = dofile("tests/lua/route_ui_test_env.lua")
function GetLocale() return "frFR" end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
APR.CATEGORIES = { Leveling = "Leveling" }
APR.PlayerID = "Player-Realm"
APRData = { [APR.PlayerID] = { alpha = 2 } }
APRZoneCompleted = { [APR.PlayerID] = {} }
APRCustomPath = { [APR.PlayerID] = { "Alpha" } }
APR.RouteQuestStepList = {
    alpha = { label = "Alpha", expansion = "Midnight", category = "Campaign", steps = {{}, {}, {}} },
    beta = { label = "Beta", expansion = "Midnight", category = "Leveling", authors = {"Jane", "John"}, community = true, steps = {} },
    hidden = { label = "Hidden", expansion = "Other", steps = {} },
    unavailable = { label = "Unavailable", expansion = "Other", steps = {} },
    temporary = { label = "Travel", temporary = true },
}
function APR:GetRouteVisibility(key) return key == "hidden" and "hidden" or key == "unavailable" and "disabled" or "visible" end
function APR:GetUnmetConditions() return {} end
function APR:NormalizeSearchText(value) return string.lower(value) end
function APR:AddRouteToCustomPathByKey(key) table.insert(APRCustomPath[self.PlayerID], self.RouteQuestStepList[key].label) end
local updates = 0
APR.routeconfig = { SendCustomPathUpdate = function() updates = updates + 1 end }
dofile("APR-Core/features/questing/RouteCatalog.lua")
dofile("APR-Core/ui/route/RouteBrowser.lua")
local catalog = APR.RouteCatalog
local records = catalog:Build()
assert(#records == 3)
assert(records[1].author == APR:LocalizeUI("AUTHOR_UNKNOWN"))
assert(records[2].author == "Jane, John")
assert(#catalog:Filter(records, {query = "midnight jane", facet = "community"}) == 1)
assert(#catalog:Filter(records, {query = "other jane"}) == 0)
assert(#catalog:Filter(records, {facet = "path"}) == 1)
assert(not catalog:ChangePath(records[3], "add"))
assert(catalog:ChangePath(records[2], "add") and updates == 1)
assert(catalog:ChangePath(records[2], "up") and APRCustomPath[APR.PlayerID][1] == "Beta")
assert(catalog:ChangePath(records[2], "down") and APRCustomPath[APR.PlayerID][2] == "Beta")
assert(catalog:ChangePath(records[2], "remove") and #APRCustomPath[APR.PlayerID] == 1)
APR.RouteBrowser:Show()
assert(APR.RouteBrowser.selectedKey == "alpha")
APR.RouteBrowser.filters.facet = "community"
APR.RouteBrowser:Refresh()
assert(APR.RouteBrowser.selectedKey == "beta")
APR.RouteBrowser.favorite.scripts.OnClick()
assert(APR.settings.profile.routeFavorites.beta)
APR.RouteBrowser.filters.query = "no such route"
APR.RouteBrowser:Refresh()
assert(APR.RouteBrowser.empty:IsShown() and not APR.RouteBrowser.details:IsShown())
print("Route catalog: metadata, search, availability, path mutations and browser controls passed")
