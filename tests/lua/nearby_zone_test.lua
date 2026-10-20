local function noop() end
function LibStub() return {GetLocale = function() return {} end} end
function CreateFrame() return {RegisterEvent = noop, SetScript = noop} end
function wipe(value) for key in pairs(value) do value[key] = nil end end
local current, now, playerX, playerY, world, inInstance = 1411, 0, 100, 200, 1, false
local maps = {
    [1411] = {mapID = 1411, parentMapID = 1414, mapType = 3},
    [1454] = {mapID = 1454, parentMapID = 1414, mapType = 3},
    [1420] = {mapID = 1420, parentMapID = 1415, mapType = 3},
    [1414] = {mapID = 1414, parentMapID = 947, mapType = 2},
    [1415] = {mapID = 1415, parentMapID = 947, mapType = 2},
    [947] = {mapID = 947, parentMapID = 0, mapType = 0},
    -- Model a nested city, not an immediate sibling of its surrounding zone.
    [2393] = {mapID = 2393, parentMapID = 2395, mapType = 3},
    [2395] = {mapID = 2395, parentMapID = 2537, mapType = 3},
    [2537] = {mapID = 2537, parentMapID = 947, mapType = 2},
    [13] = {mapID = 13, parentMapID = 947, mapType = 2},
    [8001] = {mapID = 8001, parentMapID = 2393, mapType = 5},
    [8002] = {mapID = 8002, parentMapID = 2395, mapType = 4},
    [8003] = {mapID = 8003, parentMapID = 8002, mapType = 5},
}
Enum = {UIMapType = {Zone = 3}}
C_Map = {
    GetBestMapForUnit = function() return current end,
    GetMapInfo = function(id) return maps[id] end,
    GetWorldPosFromMapPos = function() return world, {} end,
}
function UnitPosition() return playerY, playerX, 0, 1 end
function CreateVector2D(x,y) return {x=x,y=y} end
function IsInInstance() return inInstance end
function GetTime() now = now + 1; return now end
APR = {ActiveRoute = 'r', Debug = noop, Arrow = {MaxDistanceWrongZone = 1000}}
dofile('APR-Core/utils/Utils.lua')
dofile('APR-Core/utils/ZoneDetectionUtils.lua')
dofile('APR-Core/utils/RouteUtils.lua')
APR:InitZoneDetectionCache()
APR.PrintZoneDebug = noop
local step = {Waypoint = 1, Coord = {x = 102, y = 200}, Zone = 1454}
function APR:GetCurrentStep() return step end
function APR:GetCurrentRouteMapIDsAndName() return {1454}, 1454 end
function APR:IsInDelveRouteContext() return false end
function APR:GetRouteData() return {} end
function APR:GetStepZoneList(s) return {s.Zone} end
function APR:GetStepCoord(s) return s.Coord end
function APR:GetPreferredStepZone(s) return s.Zone end
function APR:GetScenarioMapIDForStep(s) return s.Scenario and 1454 end
function APR:Contains(t, value) for _, v in ipairs(t or {}) do if v == value then return true end end return false end
function APR:ContainsAny(a, b) for _, v in ipairs(b or {}) do if self:Contains(a, v) then return true end end return false end
assert(APR:CheckIsInRouteZone(), 'Durotar to Orgrimmar at 2 yards uses the normal waypoint')
step.Coord.x = 1099
assert(APR:CheckIsInRouteZone(), 'Below configured maximum distance is accepted')
step.Coord.x = 1100
assert(not APR:CheckIsInRouteZone(), 'At maximum distance still requires navigation')
step.Coord.x = 102
world = 0
assert(not APR:CheckIsInRouteZone(), 'Overlapping coordinates in another world instance are rejected')
world = 1; step.Zone = 1420
assert(not APR:CheckIsInRouteZone(), 'A common world parent is not enough across continents')
step.Zone = 1454; inInstance = true
assert(not APR:CheckIsInRouteZone(), 'Nearby instance content does not bypass zone checks')
inInstance = false; step.Scenario = true
assert(not APR:CheckIsInRouteZone(), 'Scenario entrance rules remain authoritative')
step.Scenario = nil; step.Coord = nil
assert(not APR:CheckIsInRouteZone(), 'No coordinates means no proximity shortcut')
step.Coord = {x=102,y=200}; playerX = nil
assert(not APR:CheckIsInRouteZone(), 'Loading without UnitPosition does not imply arrival')
playerX = 100
current, step.Zone, step.Coord = 2395, 2393, {x = 110, y = 200}
FarstriderLib_API = { DATA = { CONFIG = {
    MapTypeOverrides = {[2537] = {mapType = 3}}, ContinentMapOverrides = {[2537] = 13},
    IsolatedAreas = {}, IsolatedContinents = {},
} } }
APR:InvalidatePlayerZoneCache()
assert(APR:CheckIsInRouteZone(), 'Surrounding zone to nested city at ten yards keeps step guidance')
current, step.Zone = 2393, 2395
APR:InvalidatePlayerZoneCache()
assert(APR:CheckIsInRouteZone(), 'City to surrounding zone keeps the same ready result')
current, step.Zone = 2395, 8001
APR:InvalidatePlayerZoneCache()
assert(APR:CheckIsInRouteZone(), 'A nearby outdoor micro map may be nested below the city')
step.Zone = 8003
assert(not APR:IsNearbyStepInConnectedZone(step, {current = current}),
    'A dungeon ancestor blocks proximity even if its floor shares world coordinates')
step.Zone = 2393
local config = FarstriderLib_API.DATA.CONFIG
config.IsolatedAreas[2393] = 0
assert(not APR:IsNearbyStepInConnectedZone(step, {current = current}), 'Isolation group zero is not ignored')
config.IsolatedAreas[2395] = 0
assert(APR:IsNearbyStepInConnectedZone(step, {current = current}), 'Matching isolation groups remain connected')
config.IsolatedAreas[2393] = 5
assert(not APR:IsNearbyStepInConnectedZone(step, {current = current}), 'A child isolation group is not replaced by its parent group')
config.IsolatedAreas = {}
config.IsolatedContinents[2537] = true
assert(APR:IsNearbyStepInConnectedZone(step, {current = current}), 'A city shares its surrounding outdoor region')
maps[8004] = {mapID = 8004, parentMapID = 2537, mapType = 3}
step.Zone = 8004
assert(not APR:IsNearbyStepInConnectedZone(step, {current = current}), 'Separate regions on an isolated continent stay separate')
config.IsolatedContinents = {}
maps[8004].parentMapID = 8004
assert(not APR:IsNearbyStepInConnectedZone(step, {current = current}), 'Cyclic hierarchy fails closed')
APR:InvalidateMapInfoCache()
step.Zone = 99999
assert(not APR:IsNearbyStepInConnectedZone(step, {current = current}), 'Unknown target map fails closed')
assert(not APR:CheckContinentMatch({continent = 0}, {99999}), 'Two unknown continents do not establish a match')

-- Exercise the complete APR integration with the real zone check, not a stubbed
-- "in zone" result: a direct solver result must clear the error UI both ways.
APR.PlayerID = 'test'
APRData, APRCustomPath = {test = {r = 1}}, {test = {}}
function APR:NewModule() return {} end
function APR:UpdateQuestAndStep() end
function APR:UpdateStep() end
function APR:IsInstanceWithUI() return true end
function APR:CaptureStepContext() return {route = 'r', index = 1} end
function APR:GetCurrentStepToken() return 'r:1' end
function APR:IsStepContextCurrent() return true end
function APR:GetCurrentRouteMapIDsAndName() return {step.Zone}, step.Zone, self.ActiveRoute end
function APR:ActivateRoute() end
function APR:StartPerformanceSample() end
function APR:FinishPerformanceSample() end
APR.routeconfig = {HasRouteInCustomPath = function() return true end}
local errorLines = 0
APR.currentStep = {IsShown = function() return true end, AddExtraLineText = function() errorLines = errorLines + 1 end}
C_Timer = {After = noop}
C_Map.GetMapPosFromWorldPos = function(_, _, map) return map, {x = 0.5, y = 0.5} end
FarstriderLib_API.DATA.WAYPOINTS = {true}
local solverCalls = 0
FarstriderLib_API.FindTrailTo = function()
    solverCalls = solverCalls + 1
    local loc = {mapId = step.Zone, isUI = true, pos = {x = 0.5, y = 0.5, z = 0}}
    return {{loc = loc, completionLoc = loc, locaId = 1000, loca = 'Generic provider label'}}
end
dofile('APR-Core/integrations/Farstrider.lua')
for _, pair in ipairs({{2395, 2393}, {2393, 2395}}) do
    current, step.Zone, step.Coord = pair[1], pair[2], {x = 110, y = 200}
    APR.IsInRouteZone = false
    APR:InvalidatePlayerZoneCache()
    APR.farstrider:InvalidatePathCache()
    APR.farstrider:ForceRefresh()
    APR.farstrider:GetMeToRightZone(true)
    assert(APR.IsInRouteZone and not APR.farstrider:IsNavigating(), 'Direct nearby guidance is ready in either direction')
end
assert(solverCalls == 2 and errorLines == 0, 'Nearby geography still checks the solver without displaying wrong-zone errors')
print('Nearby zones: symmetric nested-city guidance, boundaries, instances, isolation, unknown maps and cycles passed')
