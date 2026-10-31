-- Lua 5.1: level-up route selection and acceptance guards.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end

APR = {
    Color = {},
    PlayerID = "player",
    PreviousMaxLvl = 80,
    MaxLevelChromie = 70,
    GAME_VERSIONS = { Retail = "retail", Forever = "forever", Classic = "classic" },
    EXPANSIONS = { Midnight = "Midnight", TheWarWithin = "TWW" },
    PREFAB_TYPES = { Speedrun = "Speedrun" }
}
function APR:NewModule() return {} end
local gameVersion = APR.GAME_VERSIONS.Retail
function APR:GetGameVersion() return gameVersion end

dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/config/Config_Route.lua")
local route, popup, selected, published, available
local messages = {}
function APR:GetRouteKeyFromDisplayName(name) return name end

function APR:GetRouteData() return route end

APR.questionDialog = {
    CreateQuestionPopup = function(_, id, text, accept)
        popup = { id = id, text = text, accept = accept }
    end
}
-- Observe the real receiver applying a completed selection, rather than count
-- internal builder notifications that do not publish a replacement path.
local function noop() end
APR.currentStep = { Reset = noop }
APR.Buff = { RemoveAllBuffIcon = noop }
APR.XPBuffOverlay = { QueueRefresh = noop }
APR.RouteBrowser = { Refresh = noop }
C_Timer = { NewTimer = function(_, callback)
    return { callback = callback, Cancel = noop }
end }
function APR:Debug() end
function APR:UpdateStep() end
function APR:UpdateMapId() published = published + 1 end
function APR:GetCurrentRouteMapIDsAndName() return {}, 1, APRCustomPath.player[1] end
function APR.routeconfig:RegisterMessage(message, callback) messages[message] = callback end
function APR.routeconfig:SendMessage(message) assert(messages[message])() end
APR.routeconfig:InitRouteConfig()

function APR.routeconfig:GetSpeedRunPrefab()
    assert(next(APRCustomPath.player) == nil, "The append-only builder receives a fresh candidate path")
    if not available then return false end
    selected = "speedrun"
    APRCustomPath.player[1] = "invented-speedrun-start"
    self:SendMessage("APR_Custom_Path_Update")
end

function APR.routeconfig:BuildLevelingPrefab(expansion)
    assert(APRCustomPath.player[1] == "old-route", "Leveling preflight owns the decision to replace the path")
    if not available then return false end
    selected = expansion
    APRCustomPath.player = { "invented-leveling-start" }
    self:SendMessage("APR_Custom_Path_Update")
end

local function check(level, data)
    APR.Level, route, popup, selected = level, data, nil, nil
    published, available = 0, true
    APR.ActiveRoute = "old-route"
    APR.routeconfig.pathUiRefreshTimer = nil
    APRCustomPath = { player = { "old-route" } }
    APR.routeconfig:CheckRouteResetOnLvlUp()
end
check(80, {})
assert(popup and popup.id == "RESET_ROUTE_FOR_SPEEDRUN")
assert(APRCustomPath.player[1] == "old-route" and selected == nil, "No reset before acceptance")
popup.accept()
assert(selected == "speedrun" and APRCustomPath.player[1] == "invented-speedrun-start"
    and APRCustomPath.player[2] == nil and APR.ActiveRoute == "invented-speedrun-start" and published == 1,
    "Acceptance replaces the old path with a successfully built guide, published once")
check(80, { expansion = "Midnight", prefab = { Speedrun = true } })
assert(not popup, "Do not reset the active Midnight speedrun")
check(80, { notSkippable = true })
assert(not popup)
check(10, {})
assert(popup.id == "RESET_ROUTE_FOR_SPEEDRUN")
check(70, {})
assert(popup.id == "RESET_ROUTE_FOR_TWW")
popup.accept()
assert(selected == "TWW" and APRCustomPath.player[1] == "invented-leveling-start"
    and APRCustomPath.player[2] == nil and APR.ActiveRoute == "invented-leveling-start" and published == 1)
for _, level in ipairs({ 70, 80 }) do
    check(level, {})
    available = false
    popup.accept()
    assert(selected == nil and APRCustomPath.player[1] == "old-route"
        and APRCustomPath.player[2] == nil and published == 0,
        "An unavailable builder preserves the existing path without publishing a replacement")
end
for _, level in ipairs({ 79, 81, 90 }) do
    check(level, {}); assert(not popup)
end
for _, version in ipairs({ APR.GAME_VERSIONS.Forever, APR.GAME_VERSIONS.Classic }) do
    gameVersion = version
    for _, level in ipairs({ 10, 70, 80 }) do
        check(level, {})
        assert(not popup and selected == nil, "Route reset must only apply to Retail")
        assert(APRCustomPath.player[1] == "old-route", "Keep the current path outside Retail")
    end
end
print("PASS: Retail level-up route selection, acceptance and client guards")
