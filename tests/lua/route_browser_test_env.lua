-- Frame fixtures and a small synthetic catalog; the UI consumes real catalog/path/row code.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
for _, key in ipairs({"ALL", "FAVORITES", "ADD", "REMOVE", "RESET", "TYPE", "STATUS", "EXPANSION_FILTER_TEXT"}) do _G[key] = key end
UIParent:SetSize(1920, 1080)
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
function APR:GetGameVersion() return self.GAME_VERSIONS.Retail end
function APR:GetRouteVisibility(key)
    local route = self:GetRouteData(key)
    return route and (route.visibility or "visible") or "hidden"
end
function APR:GetUnmetConditions(key)
    return self:GetRouteVisibility(key) == "disabled" and {"Requires level 20"} or {}
end
function APR:GetRouteSelectionExpansions() return {"Old", "Midnight", "Custom"} end
APR.PlayerID = "test"
APR.RouteQuestStepList = {
    first = {label = "First by Someone", expansion = "Midnight", category = "Campaign"},
    second = {label = "Second", expansion = "Midnight", category = "Daily", author = "  Test author  ", community = true,
        description = "A route description", visibility = "disabled"},
    old = {label = "Older route", expansion = "Old", category = "Campaign", author = "Writer"},
}
APRCustomPath, APRData, APRZoneCompleted = {test = {}}, {test = {}}, {test = {}}
local shift = false
function IsShiftKeyDown() return shift end
function env.setShift(value) shift = value end
function env.methods:Raise() end
local tooltipLines = {}
function APR:SetTooltipText(_, text) tooltipLines = {text} end
function APR:AddTooltipLine(_, text) tooltipLines[#tooltipLines + 1] = text end
function env.tooltip() return table.concat(tooltipLines, "\n") end
APR.routeconfig = {SendCustomPathUpdate = function() APR.RouteBrowser:Refresh(true) end}
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/foundations/SelectionDialog.lua")
dofile("APR-Core/features/questing/RouteCatalog.lua")
dofile("APR-Core/ui/route/RouteBrowserRows.lua")
dofile("APR-Core/ui/route/RouteBrowser.lua")
return env
