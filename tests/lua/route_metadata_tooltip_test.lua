-- Exercise attribution through real catalogue/custom-path hover callbacks, including recycled rows.
local env = dofile("tests/lua/route_ui_test_env.lua")
local locale = setmetatable({}, {__index = function(_, key) return key end})
function LibStub() return {GetLocale = function() return locale end} end
function GetLocale() return "enUS" end
tinsert, tremove = table.insert, table.remove
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/ui/foundations/InterfaceStrings.lua")
APR.Color.grayAlpha = {0.4, 0.4, 0.4, 0.4}
APR.PlayerID, APR.EXPANSIONS = "test", {Test = "Test"}
APR.PREFAB_TYPES = {Leveling = "Leveling", AllQuests = "AllQuests", Speedrun = "Speedrun"}
function APR:GetRouteSelectionExpansions() return {"Test"} end
function APR:GetRouteVisibility(key) return key == "second" and "disabled" or "visible" end
function APR:GetRouteData(key) return self.RouteQuestStepList[key] end
function APR:GetUnmetConditions() return {"Requires level 20"} end
APR.RouteQuestStepList = {
    first = {label = "First by Someone", expansion = "Test"},
    second = {label = "Second", expansion = "Test", author = "  Test author  ", community = true,
        description = "A route description", authors = {"Ignored coauthor"}},
}
APRCustomPath, APRData, APRZoneCompleted = {test = {}}, {test = {}}, {test = {}}
local author, community, description = APR:GetRouteAttribution("first")
assert(author == "APR" and not community and not description, "Do not infer authors from the route name")
author, community, description = APR:GetRouteAttribution("second")
assert(author == "Test author" and community and description == "A route description")
assert(APR:GetRouteAttribution("missing") == "APR")
local lines = {}
function GameTooltip:SetOwner() lines = {} end
function GameTooltip:AddLine(text) lines[#lines + 1] = text end
function APR:AddTooltipLine(tooltip, text) tooltip:AddLine(text) end
dofile("APR-Core/config/Config_Route.lua")
local catalogue = {frame = env.widget()}
SetRouteListTab(catalogue, "Test")
local function hover(row)
    row.scripts.OnEnter(row)
    return table.concat(lines, "\n")
end
local text = hover(catalogue.fontStringsContainer[1])
assert(text:find("Author: APR", 1, true) and text:find("Source: APR", 1, true))
assert(text:find("MOVE_ROUTE_TO_CUSTOM_PATH", 1, true))
text = hover(catalogue.fontStringsContainer[2])
assert(text:find("Author: Test author", 1, true) and text:find("Source: Community", 1, true))
assert(text:find("A route description", 1, true) and text:find("Requires level 20", 1, true))
assert(not catalogue.fontStringsContainer[2].scripts.OnMouseDown, "Metadata cannot enable an unavailable route")
-- Resolve metadata at hover, even if an import replaced the definition after rendering.
APR.RouteQuestStepList.second = {label = "Second", expansion = "Test", authors = {"One", "  Two "}, source = "community"}
text = hover(catalogue.fontStringsContainer[2])
assert(text:find("Author: One, Two", 1, true) and not text:find("A route description", 1, true))
APRCustomPath.test = {"Second", "First by Someone"}
local custom = {frame = env.widget()}
custom.frame.contentFrame = env.widget()
custom.frame.scrollFrame = env.widget()
SetCustomPathListFrame(custom)
text = hover(custom.fontStringsContainer[1])
assert(text:find("Author: One, Two", 1, true) and text:find("REMOVE_ZONE_FROM_CUSTOM_PATH", 1, true))
local recycled = custom.fontStringsContainer[2]
APRCustomPath.test = {"Second"}
SetCustomPathListFrame(custom)
assert(custom.fontStringsContainer[1] == recycled)
text = hover(recycled)
assert(text:find("Author: One, Two", 1, true) and not text:find("Author: APR", 1, true))
APR.RouteQuestStepList.second.author = "  "
APR.RouteQuestStepList.second.authors = {"", "  ", false}
APR.RouteQuestStepList.second.description = "  "
author, community, description = APR:GetRouteAttribution("second")
assert(author == "APR" and community and not description)
print("Route tooltips: data-only attribution, APR fallback, coauthors, descriptions, prerequisites and recycled rows passed")
