local function noop() end
function LibStub() return {GetLocale = function() return {} end} end
function CreateFrame() return {RegisterEvent = noop, SetScript = noop} end
local current, now, playerX, playerY, world, inInstance = 1411, 0, 100, 200, 1, false
local maps = {
    [1411] = {mapID = 1411, parentMapID = 1414, mapType = 3},
    [1454] = {mapID = 1454, parentMapID = 1414, mapType = 3},
    [1420] = {mapID = 1420, parentMapID = 1415, mapType = 3},
    [1414] = {mapID = 1414, parentMapID = 947, mapType = 2},
    [1415] = {mapID = 1415, parentMapID = 947, mapType = 2},
    [947] = {mapID = 947, parentMapID = 0, mapType = 0},
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
print('Nearby zones: shared parent, distance boundary, world instance, scenarios and missing data passed')
