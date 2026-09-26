-- Lua 5.1: level-up route selection.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end

APR = {
    Color = {},
    PlayerID = "player",
    PreviousMaxLvl = 80,
    MaxLevelChromie = 70,
    EXPANSIONS = { Midnight = "Midnight", TheWarWithin = "TWW" },
    PREFAB_TYPES = { Speedrun = "Speedrun" }
}
function APR:NewModule() return {} end
function APR:GetRouteSelectionExpansions() return {} end
function APR:IsTableEmpty(value) return next(value) == nil end
dofile("APR-Core/config/Config_Route.lua")
local route, popup, selected
function APR:GetRouteKeyFromDisplayName(name) return name end

function APR:GetRouteData() return route end

APR.questionDialog = {
    CreateQuestionPopup = function(_, id, text, accept)
        popup = { id = id, text = text, accept = accept }
    end
}
function APR.routeconfig:GetSpeedRunPrefab() selected = "speedrun" end

function APR.routeconfig:BuildLevelingPrefab(expansion) selected = expansion end

local function check(level, data)
    APR.Level, route, popup, selected = level, data, nil, nil
    APRCustomPath = { player = { "old-route" } }
    APR.routeconfig:CheckRouteResetOnLvlUp()
end
check(80, {})
assert(popup and popup.id == "RESET_ROUTE_FOR_SPEEDRUN")
assert(APRCustomPath.player[1] == "old-route" and selected == nil, "No reset before acceptance")
popup.accept()
assert(selected == "speedrun" and next(APRCustomPath.player) == nil)
check(80, { expansion = "Midnight", prefab = { Speedrun = true } })
assert(not popup, "Do not reset the active Midnight speedrun")
check(80, { notSkippable = true })
assert(not popup)
check(10, {})
assert(popup.id == "RESET_ROUTE_FOR_SPEEDRUN")
check(70, {})
assert(popup.id == "RESET_ROUTE_FOR_TWW")
popup.accept()
assert(selected == "TWW")
for _, level in ipairs({ 79, 81, 90 }) do
    check(level, {}); assert(not popup)
end
print("Route transitions: level 80 speedrun acceptance, cancellation and route guards passed")
