-- Minimal client state; all guides are supplied by the test, never by Routes/.
local L = setmetatable({ PREFAB_TITLE = "%s" }, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
DUNGEONS = "Dungeons"
tinsert, tremove = table.insert, table.remove
function tContains(values, wanted)
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end
APR = { PlayerID = "player", Faction = "Horde", Race = "Orc", RaceID = 2,
    ClassName = "WARRIOR", ClassId = 1, Level = 1, RouteQuestStepList = {}, routeconfig = {} }
APRData, APRCustomPath, APRZoneCompleted = { player = {} }, { player = {} }, { player = {} }
function APR:NewModule() return {} end
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/data/models/Classes.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
dofile("APR-Core/config/Config_Route_Prefabs.lua")
local env = { gameVersion = APR.GAME_VERSIONS.Forever }
function APR:GetGameVersion() return env.gameVersion end
function APR:GetPlayerEffectiveLevel() return self.Level end
function APR:IsDelveRoute() return false end
function UnitFactionGroup() return APR.Faction end
function APR.routeconfig:SendCustomPathUpdate() end
function env.route(key, label, conditions, prefab, category)
    local route = { label = label, expansion = APR.EXPANSIONS.Forever,
        conditions = conditions, prefab = prefab, category = category,
        steps = { { Note = { "Synthetic instruction" }, _index = 1 }, { RouteCompleted = true, _index = 2 } } }
    APR.RouteQuestStepList[key] = route
    return route
end
return env
