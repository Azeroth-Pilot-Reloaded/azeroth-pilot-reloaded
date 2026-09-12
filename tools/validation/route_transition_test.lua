-- Lua 5.1: malformed community translations and level-up route selection.
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

local debugCount = 0
dofile("APR-Core/utils/Utils.lua")
function APR:Debug() debugCount = debugCount + 1 end

L.LEAVE_SCENARIO = "Quitter %s"
assert(string.format(L.LEAVE_SCENARIO, "100% fini") == "Quitter 100% fini")
for _, template in ipairs({ "Quitter %S", "Quitter %1$s", "Quitter %", "Quitter %d" }) do
    L.LEAVE_SCENARIO = template
    assert(string.format(L.LEAVE_SCENARIO, "Gouffre") == "Leave Gouffre")
end
assert(debugCount == 1, "Repeated bad translations should not flood debug output")
assert(string.format(L.MISSING or "Leave %s", "Gouffre") == "Leave Gouffre")
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
print("PASS: invalid localized formats, level 80 speedrun acceptance, cancellation and route guards")
