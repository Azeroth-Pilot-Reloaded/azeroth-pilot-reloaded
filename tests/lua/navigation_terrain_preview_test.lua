-- Terrain shape points belong to the line, independently of the moving arrow target.
local ui = dofile("tests/lua/route_ui_test_env.lua")
local function noop() end
APR.ActiveRoute, APR.PlayerID, APR.stepRevision = "synthetic", "player", 1
APR.RouteQuestStepList = { synthetic = { mapID = 10 } }
APR.settings.profile = {}
function APR:NewModule() return { RegisterMessage = noop } end
local hbd = { GetZoneCoordinatesFromWorldInstance = function(_, x, y, world, map)
    if world == 1 and map == 10 then return x / 1000, y / 1000 end
end }
local placed = { world = {}, minimap = {} }
local pins = {
    RemoveAllWorldMapIcons = function() placed.world = {} end,
    RemoveAllMinimapIcons = function() placed.minimap = {} end,
    AddWorldMapIconMap = function(_, _, pin) placed.world[#placed.world + 1] = pin end,
    AddMinimapIconMap = function(_, _, pin) placed.minimap[#placed.minimap + 1] = pin end,
}
function LibStub(name)
    if name == "HereBeDragons-2.0" then return hbd end
    if name == "HereBeDragons-Pins-2.0" then return pins end
end
function CreateVector2D(x, y) return { x = x, y = y } end
C_Map = {
    GetBestMapForUnit = function() return 10 end,
    GetWorldPosFromMapPos = function(_, position) return 1, position end,
    GetMapInfo = function(id) return { mapID = id, parentMapID = 0, mapType = 3 } end,
}
local step = { NoArrow = true }
local steps = { step }
function APR:GetCurrentStep() return step, 1, steps end
function APR:GetStepCoord(value) return value.Coord, 10 end
dofile("APR-Core/features/navigation/Preview.lua")
local preview = APR.navigationPreview
local function position(x, y, z, floor, world)
    return { x = x, y = y, z = z or 0, floor = floor or 1, instanceID = world or 1, uiMapID = 10 }
end
local line = { position(100, 100), position(300, 100), position(300, 400) }
local row = { kind = "walk", terrain = true, polyline = line, Coord = { x = 175, y = 225 },
    to = line[3], uiMapID = 10, instanceID = 1, instruction = "Follow the corridor" }
local queue = { row }
local points = preview:Build(queue, step, 1, steps, 1)
assert(#points == 3, "The preview must retain the corner instead of drawing a chord to the moving arrow target")
assert(points[1].Coord.x == 100 and points[1].Coord.y == 100)
assert(points[2].Coord.x == 100 and points[2].Coord.y == 300)
assert(points[3].Coord.x == 400 and points[3].Coord.y == 300)
assert(points[1].shape and points[2].shape and not points[3].shape,
    "Shape vertices must not become objective markers")
assert(points[1].breakBefore and preview:CanConnect(points[1], points[2]) and preview:CanConnect(points[2], points[3]))
row.Coord = { x = 200, y = 250 }
assert(preview:Build(queue, step, 1, steps, 1) == points,
    "The moving arrow target must not rebuild immutable terrain geometry")
assert(line[1].Coord == nil and line[2].shape == nil, "Preview conversion must not mutate library geometry")

local function geometry(polyline)
    return preview:Build({ { kind = "walk", terrain = true, polyline = polyline,
        Coord = { x = 200, y = 250 }, uiMapID = 10, instanceID = 1 } }, step, 1, steps)
end
local floors = geometry({ position(100, 100, 0, 1), position(100, 100, 20, 2) })
assert(#floors == 2 and floors[1].z == 0 and floors[2].z == 20,
    "Coincident XY on different floors must not collapse into one point")
assert(not preview:CanConnect(floors[1], floors[2]), "A map line must not bridge unrelated floors")
local worlds = geometry({ position(100, 100, 0, 1, 1), position(200, 100, 0, 1, 2) })
assert(not preview:CanConnect(worlds[1], worlds[2]), "Terrain lines must not cross world spaces")
local broken = geometry({ position(100, 100), {}, position(300, 400) })
assert(#broken == 2 and not preview:CanConnect(broken[1], broken[2]),
    "Missing shape geometry must create a discontinuity rather than a shortcut")
assert(#geometry({}) == 0, "Incomplete terrain cannot fall back to its moving target as a verified line")

WorldMapFrame, Minimap = ui.widget(), ui.widget()
WorldMapFrame:SetSize(1000, 800)
Minimap:SetSize(200, 200)
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return 10 end
function Minimap:GetZoom() return 0 end
function ui.methods:CreateAnimationGroup() return ui.widget() end
function ui.methods:CreateAnimation() return ui.widget() end
function ui.methods:Play() end
function GetMinimapShape() return "ROUND" end
function GetPlayerFacing() return 0 end
function GetCVar() return "0" end
function UnitPosition() return 100, 100, 0, 1 end
APR.settings.profile = {
    enableAddon = true, mapshowNextSteps = true, minimapshowNextSteps = true,
    mapshowNextStepsCount = 0, minimapshowNextStepsCount = 0,
    mapshowNextStepsSize = 16, minimapshowNextStepsSize = 16,
    mapshowNextStepsColor = { 1, 1, 1 }, minimapshowNextStepsColor = { 1, 1, 1 },
    showMiniMapLine = true, showMapLine = true, showMiniMapLineColor = { 1, 1, 1 },
    showMapLineColor = { 1, 1, 1 }, showMiniMapLineThickness = 2, showMapLineThickness = 2,
}
local originalGetPoints = preview.GetPoints
function preview:GetPoints() return points end
dofile("APR-Core/features/navigation/Map.lua")
APR.map:OnInit()
APR.map:AddMapPins()
assert(#placed.world == 1 and #placed.minimap == 1,
    "Only the terrain destination gets a pin; shape vertices remain line geometry")
preview.GetPoints = originalGetPoints
print("Terrain preview: exact corridor, immutable cache, floors/worlds/gaps and line-only shape vertices passed")
