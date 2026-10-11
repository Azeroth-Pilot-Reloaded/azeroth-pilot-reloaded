-- Selection, direct activation and saved paths share the same entry gates.
local locale = setmetatable({
    COMPLETE_ONE_REQUIRED_ROUTE = "Complete one: %s",
}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
tinsert, tremove = table.insert, table.remove
local level = 9
APR = { PlayerID = "player", Faction = "Alliance", RouteQuestStepList = {} }
APR.GAME_VERSIONS = { Forever = "forever" }
function APR:GetGameVersion() return "forever" end
APRData, APRCustomPath, APRZoneCompleted = { player = {} }, { player = {} }, { player = {} }
C_Map = { GetBestMapForUnit = function() return 1 end }
function GetTime() return 1 end
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/questing/RouteSuggestions.lua")
function APR:GetPlayerEffectiveLevel() return level end
function APR:IsDelveRoute() return false end
function APR:Contains(t, value) for _, v in ipairs(t) do if v == value then return true end end end
function APR:AreConditionalFiltersMet() return true end
local routes = APR.RouteQuestStepList
routes.normal = { label = "Normal", conditions = { Faction = "Alliance" }, nextRoute = { "next" } }
routes.technical = { label = "Technical", conditions = { Faction = "Alliance" } }
routes.horde = { label = "Horde", conditions = { Faction = "Horde" } }
routes.next = { label = "Next", gameVersion = "forever", conditions = { MinLevel = 10 },
    requiredRoute = { "normal", "technical", "horde" } }
assert(APR:GetRouteVisibility("next") == "disabled")
assert(not APR:AddRouteToCustomPathByKey("next") and #APRCustomPath.player == 0)
assert(not APR:ActivateRoute("next") and APR.ActiveRoute == nil)
APR:ActivateRouteFromTemporaryTrigger("next")
assert(#APRCustomPath.player == 0, "A rejected suggestion cannot rewrite the path")
APRZoneCompleted.player.Horde = true
level = 10
assert(not APR:CanStartRoute("next"), "An incompatible completed route does not unlock an alternative")
assert(APR:GetUnmetConditions("next")[1] == "Complete one: Normal, Technical")
APRZoneCompleted.player.Technical = true
level = 9.99
assert(not APR:CanStartRoute("next"), "A prerequisite never waives the entry level")
level = 10
assert(APR:GetRouteVisibility("next") == "visible")
assert(APR:AddRouteToCustomPathByKey("next"))
assert(#APRCustomPath.player == 1 and APRCustomPath.player[1] == "Next", "Never enqueue other alternatives")
assert(APR:ActivateRoute("next"))
assert(#APR:GetNextRouteSuggestions("normal") == 1)
routes.next.requiredRoute = { "normal" }
assert(not APR:CanStartRoute("next"))
assert(APR:GetRouteVisibility("next") == "disabled", "A single prerequisite blocks without an extra mode")
APRZoneCompleted.player.Normal = true
assert(APR:CanStartRoute("next"), "The single required predecessor is complete")
routes.next.requiredRoute = { "missing" }
assert(not APR:CanStartRoute("next"), "Missing definitions cannot unlock a route")
routes.next.requiredRoute = nil
assert(APR:CanStartRoute("next"))

-- Restored or manually reordered paths cannot bypass the gate; keep the entry.
APR.ActiveRoute = nil
function APR:GetPrimaryCustomPathRouteKey() return "next" end
function APR:GetRouteMapIDsAndName() return {1}, 1, "next", "Forever" end
level = 9
local maps, mapID, key = APR:GetCurrentRouteMapIDsAndName()
assert(maps == nil and key == "" and APRCustomPath.player[1] == "Next")
assert(APR._blockedRouteKey == "next")
level = 10
maps, mapID, key = APR:GetCurrentRouteMapIDsAndName()
assert(key == "next" and APR._blockedRouteKey == nil)

-- Legacy lists preserve their auto-prepend semantics.
APRZoneCompleted.player.Normal = nil
routes.legacy = { label = "Legacy", requiredRoute = { "normal" } }
APRCustomPath.player = {}
assert(APR:AddRouteToCustomPathByKey("legacy"))
assert(APRCustomPath.player[1] == "Normal" and APRCustomPath.player[2] == "Legacy")
print("Route access: entry levels, single/alternative prerequisites, legacy paths and bypass guards passed")
