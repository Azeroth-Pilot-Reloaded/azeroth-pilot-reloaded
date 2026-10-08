-- Exercise attribution through real catalogue/custom-path hover callbacks, including recycled rows.
local env = dofile("tests/lua/route_browser_test_env.lua")
local author, community, description = APR:GetRouteAttribution("first")
assert(author == "APR" and not community and not description, "Do not infer authors from the route name")
author, community, description = APR:GetRouteAttribution("second")
assert(author == "Test author" and community and description == "A route description")
assert(APR:GetRouteAttribution("missing") == "APR")
APR.RouteBrowser:Show()
local catalogue = APR.RouteBrowser.list
local function hover(row)
    row.scripts.OnEnter(row)
    return env.tooltip()
end
local text = hover(catalogue.active[1])
assert(text:find("APR", 1, true))
text = hover(catalogue.active[2])
assert(text:find("Test author", 1, true))
assert(text:find("A route description", 1, true) and text:find("Requires level 20", 1, true))
assert(not catalogue.active[2].add:IsEnabled(), "Metadata cannot enable an unavailable route")
-- Resolve metadata at hover, even if an import replaced the definition after rendering.
APR.RouteQuestStepList.second = {label = "Second", expansion = "Test", authors = {"One", "  Two "}, source = "community"}
text = hover(catalogue.active[2])
assert(text:find("One, Two", 1, true) and not text:find("A route description", 1, true))
APRCustomPath.test = {"Second", "First by Someone"}
APR.RouteBrowser:Refresh(true)
local custom = APR.RouteBrowser.pathList
text = hover(custom.active[1])
assert(text:find("One, Two", 1, true))
APRCustomPath.test = {"Second"}
APR.RouteBrowser:Refresh(true)
text = hover(custom.active[1])
assert(text:find("One, Two", 1, true))
APR.RouteQuestStepList.second.author = "  "
APR.RouteQuestStepList.second.authors = {"", "  ", false}
APR.RouteQuestStepList.second.description = "  "
author, community, description = APR:GetRouteAttribution("second")
assert(author == "APR" and community and not description)
print("Route tooltips: data-only attribution, APR fallback, coauthors, descriptions, prerequisites and recycled rows passed")
