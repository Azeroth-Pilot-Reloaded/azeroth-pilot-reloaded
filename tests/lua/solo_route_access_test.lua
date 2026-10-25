-- Solo chapter ordering is advisory; explicit route dependencies still gate.
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
tinsert, tremove = table.insert, table.remove
soloAccessLevel, soloAccessMap, soloAccessKey = 25, 1, "Later"
APR = { PlayerID = "player", Faction = "Alliance", Race = "Human",
    ClassName = "WARRIOR", ClassId = 1, RouteQuestStepList = {} }
APRData, APRCustomPath, APRZoneCompleted = { player = {} }, { player = {} }, { player = {} }
C_Map = { GetBestMapForUnit = function() return soloAccessMap end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
function GetTime() return 1 end
function tContains(values, wanted)
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
function APR:GetGameVersion() return self.GAME_VERSIONS.Forever end
function APR:GetPlayerEffectiveLevel() return soloAccessLevel end
function APR:IsDelveRoute() return false end
function APR:IsTemporaryRoute() return false end
function APR:Contains(values, wanted) return tContains(values, wanted) end
-- The UI supplies the selected saved-path key; the production resume handler
-- below still decides whether the existing route/progress can be used.
function APR:GetPrimaryCustomPathRouteKey() return soloAccessKey end

local routes = APR.RouteQuestStepList
routes.Earlier = { label = "Earlier chapter", expansion = APR.EXPANSIONS.Forever,
    conditions = { Faction = "Alliance" }, nextRoute = { "Later" } }
routes.Later = { label = "Later chapter", mapID = 1, expansion = APR.EXPANSIONS.Forever,
    conditions = { Faction = "Alliance", Class = "WARRIOR", MinLevel = 25 },
    steps = { { PickUp = { 10 }, IsQuestCompleted = 9 },
        { Qpart = { [10] = { 1 } }, IsQuestOnQuest = 10 },
        { Done = { 10 }, IsQuestOnQuest = 10 }, { RouteCompleted = true } } }

assert(next(APRZoneCompleted.player) == nil)
assert(APR:GetRouteVisibility("Later") == "visible", "No APR chapter history is required to join solo")
assert(APR:CanStartRoute("Later") and APR:MeetsRoutePrerequisites("Later"))
assert(APR:AddRouteToCustomPathByKey("Later"))
assert(#APRCustomPath.player == 1 and APRCustomPath.player[1] == routes.Later.label,
    "Selecting a later chapter must not enqueue earlier chapters")
assert(APR:ActivateRoute("Later"))
assert(#APR:GetNextRouteSuggestions("Earlier") == 1, "nextRoute still supplies the continuation")
assert(not APR:AreConditionalFiltersMet(routes.Later.steps[1]), "A genuine quest prerequisite still applies")

APRData.player.Later = 2
APR.ActiveRoute = nil -- Simulate reload with the selected path and saved progress.
local _, _, key = APR:GetCurrentRouteMapIDsAndName()
assert(key == "Later" and APRData.player.Later == 2 and next(APRZoneCompleted.player) == nil)
soloAccessLevel = 24
assert(APR:GetRouteVisibility("Later") == "disabled" and not APR:CanStartRoute("Later"))
local maps = APR:GetCurrentRouteMapIDsAndName()
assert(maps == nil and APRData.player.Later == 2 and #APRCustomPath.player == 1,
    "A level gate preserves the queued route and its progress")
soloAccessLevel = 25
APR.ClassName, APR.ClassId = "MAGE", 8
assert(APR:GetRouteVisibility("Later") == "hidden", "Class eligibility remains enforced")
APR.ClassName, APR.ClassId, APR.Faction = "WARRIOR", 1, "Horde"
assert(APR:GetRouteVisibility("Later") == "hidden", "Faction eligibility remains enforced")
APR.Faction = "Alliance"

routes.Later.requiredRoute = { "Earlier" }
assert(not APR:CanStartRoute("Later"), "An explicitly declared dependency is still a real completion gate")
APRZoneCompleted.player[routes.Earlier.label] = true
assert(APR:CanStartRoute("Later"))
routes.Later.requiredRoute = nil
APRZoneCompleted.player = {}
print("Solo access: direct entry, saved progress, suggestions, level/class/faction and explicit quest/route dependencies passed")
