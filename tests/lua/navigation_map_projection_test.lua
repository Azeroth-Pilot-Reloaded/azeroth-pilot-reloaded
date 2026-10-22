-- Exercise the bundled HBD math, including overlapping native maps whose
-- parent artwork uses another instance. These bounds are synthetic fixtures.
local env = dofile("tests/lua/route_ui_test_env.lua")
local function noop() end
local shownMap, playerMap, playerInstance = 2215, 2215, 2601
local playerX, playerY = -875.4, 2252.6 -- APR/HBD order; UnitPosition reverses it.
local hbd = { mapData = {}, worldMapData = {}, instanceZones = {}, transforms = {},
    callbacks = { Fire = noop }, eventFrame = env.widget() }
hbd.eventFrame.UnregisterAllEvents = noop
local maps = {
    [2215] = { 10000, 8000, 5498.6, 6137.4, instance = 2601, parent = 2274, mapType = 3 },
    [2255] = { 10000, 8000, 5498.6, 6137.4, instance = 2601, parent = 2274, mapType = 3 },
    [2274] = { 100000, 80000, 50000, 40000, instance = 2552, parent = 947, mapType = 2 },
    [947] = { 100000, 80000, 50000, 40000, instance = 0, parent = 946, mapType = 0 },
    [946] = { 0, 0, 0, 0, instance = -1, parent = 0, mapType = 0 },
    [610] = { 1000, 800, 0, 3000, instance = 2601, parent = 2215, mapType = 5 },
    [611] = { 1000, 800, 0, 3000, instance = 2601, parent = 2215, mapType = 5 },
    [700] = { 1000, 800, 0, 3000, instance = 700, parent = 2274, mapType = 3 },
}
local rects = {
    [2215] = { 0.2, 0.45, 0.4, 0.7 }, [2255] = { 0.55, 0.75, 0.6, 0.9 },
    [2274] = { 0.1, 0.3, 0.2, 0.6 }, [947] = { 0.05, 0.55, 0.1, 0.8 },
    [610] = { 0.1, 0.2, 0.3, 0.4 }, [611] = { 0.5, 0.6, 0.7, 0.8 },
    [700] = { 0.7, 0.8, 0.1, 0.2 },
}
hbd.mapData = maps
hbd.instanceZones[2601] = { [2552] = { 2255, 2215 } }
for _, mapID in ipairs({ 2215, 2255 }) do
    local r = rects[mapID]
    maps[mapID].rectOnParent = { minX = r[1], maxX = r[2], minY = r[3], maxY = r[4] }
end
function UnitPosition() return playerY, playerX, 0, playerInstance end
function CreateVector2D(x, y) return { x = x, y = y, GetXY = function(self) return self.x, self.y end } end
function IsLoggedIn() return false end
function Lerp(a, b, t) return a + (b - a) * t end
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
Enum = { UIMapType = { Zone = 3, Continent = 2, Dungeon = 4, Micro = 5 } }
local mapReads, rectReads, projections = 0, 0, 0
C_Map = {
    GetBestMapForUnit = function() return playerMap end,
    GetMapInfo = function(id)
        mapReads = mapReads + 1
        local map = maps[id]
        if map then return { mapID = id, parentMapID = map.parent, mapType = map.mapType } end
    end,
    GetWorldPosFromMapPos = function(id, pos)
        local map = maps[id]
        if not map or map[1] == 0 then return nil end
        return map.instance, CreateVector2D(map[4] - map[2] * pos.y, map[3] - map[1] * pos.x)
    end,
    GetMapRectOnMap = function(id, parent)
        rectReads = rectReads + 1
        assert(parent == maps[id].parent, "Map rectangles are composed through their actual parents")
        return unpack(rects[id])
    end,
    GetPlayerMapPosition = function() return nil end, -- Exercise the same projection as route endpoints.
}
local originalLibStub = LibStub
LibStub = setmetatable({ NewLibrary = function(_, name)
    assert(name == "HereBeDragons-2.0")
    return hbd, 35 -- The real projection methods, with map discovery already populated.
end }, { __call = function(_, name, ...)
    if name == "HereBeDragons-2.0" then return hbd end
    return originalLibStub(name, ...)
end })
dofile("APR-Core/libs/HereBeDragons/HereBeDragons-2.0.lua")
local hbdProject = hbd.GetZoneCoordinatesFromWorldInstance
function hbd:GetZoneCoordinatesFromWorldInstance(...)
    projections = projections + 1
    return hbdProject(self, ...)
end
function APR:NewModule() return { RegisterMessage = noop } end
function APR:GetPlayerMapPos() error("Native HBD projection must not use the displayed map's raw bounds") end
function APR:IsInstanceWithUI() return true end
function APR:GetPlayerParentMapID() return playerMap end
function APR:StepFilterQoL() return true end
local route = {
    { Waypoint = 1, Zone = 2215, Coord = { x = -975.4, y = 2252.6 } },
    { Note = "Objective", Coord = { x = -1475.4, y = 2252.6 } },
}
APR.ActiveRoute, APR.PlayerID, APR.stepRevision = "2215-Custom", "p", 0
APR.RouteQuestStepList, APRData = { [APR.ActiveRoute] = { steps = route, mapID = 2215 } }, { p = { [APR.ActiveRoute] = 1 } }
function APR:GetCurrentStep() return route[1], 1, route end
function APR:GetRouteSteps() return route end
function APR:GetStepCoord(step, fallback)
    assert(fallback == 2215, "Zooming the map must never reinterpret authored coordinates in the displayed map")
    return step.Coord, step.Zone or fallback
end
dofile("APR-Core/features/navigation/Preview.lua")
local preview = APR.navigationPreview
local point = preview:Point({ Coord = route[1].Coord, uiMapID = 2215 })
local function near(actual, expected, label)
    assert(actual and math.abs(actual - expected) < 0.000001,
        (label or "Projection") .. ": " .. tostring(actual) .. " ~= " .. expected)
end
local expected = {
    [2215] = { 0.6474, 0.4856 }, [2274] = { 0.36185, 0.54568 },
    [947] = { 0.17237, 0.418272 }, [946] = { 0.136185, 0.3927904 },
}
for _, mapID in ipairs({ 2215, 2274, 947, 946 }) do
    local x, y = preview:ProjectPoint(point, mapID)
    near(x, expected[mapID][1], "Native-to-parent X " .. mapID)
    near(y, expected[mapID][2], "Native-to-parent Y " .. mapID)
end
local ambiguousX = hbd:GetZoneCoordinatesFromWorldInstance(point.Coord.x, point.Coord.y, 2601, 2274, true)
assert(math.abs(ambiguousX - expected[2274][1]) > 0.1,
    "The fixture must expose HBD's ambiguous sibling-world lookup; native map identity resolves it")
local cave = preview:Point({ Coord = { x = -500, y = 2600 }, uiMapID = 610 })
local x, y = preview:ProjectPoint(cave, 2215)
near(x, 0.15); near(y, 0.35)
assert(preview:ProjectPoint(cave, 611) == nil, "Overlapping sibling floors do not inherit each other's markers")
local remote = preview:Point({ Coord = cave.Coord, uiMapID = 700 })
x, y = preview:ProjectPoint(remote, 2274)
near(x, 0.75); near(y, 0.15)
assert(preview:ProjectPoint({ Coord = point.Coord, instanceID = 42 }, 2215) == nil,
    "World-only points from unrelated instances cannot borrow native XY")
local withNativeCoord = preview:Point({ Coord = { x = -500, y = 2600, mapID = 610, instanceID = 2601 }, uiMapID = 2215 })
assert(withNativeCoord.uiMapID == 610, "An explicit coordinate map retains its own native identity")
APR.NavigationData = { IsSameAccessRegion = function(_, a, b) return a.uiMapID == b.uiMapID end }
assert(preview:ProjectPoint(point, 2255) == nil,
    "Isolated sibling outdoor layers must not borrow each other's overlapping world coordinates")
x, y = preview:ProjectPoint(point, 2274)
near(x, expected[2274][1]); near(y, expected[2274][2])
APR.NavigationData = nil

WorldMapFrame, Minimap = env.widget(), env.widget()
WorldMapFrame:SetSize(1000, 800); Minimap:SetSize(200, 200)
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return shownMap end
function Minimap:GetZoom() return 0 end
function env.methods:CreateAnimationGroup() return env.widget() end
function env.methods:CreateAnimation() return env.widget() end
function env.methods:Play() end
function GetMinimapShape() return "ROUND" end
function GetPlayerFacing() return 0 end
function GetCVar() return "0" end
C_Minimap = { GetViewRadius = function() return 1000 end }
local worldPins, miniPins = {}, {}
local pins = {
    RemoveAllWorldMapIcons = function(_, pool) worldPins[pool] = {} end,
    RemoveAllMinimapIcons = function(_, pool) miniPins[pool] = {} end,
    AddWorldMapIconMap = function(_, pool, pin, mapID, px, py)
        worldPins[pool] = worldPins[pool] or {}
        worldPins[pool][#worldPins[pool] + 1] = { pin = pin, mapID = mapID, x = px, y = py }
    end,
    AddMinimapIconMap = function(_, pool, pin, mapID, px, py)
        miniPins[pool] = miniPins[pool] or {}
        miniPins[pool][#miniPins[pool] + 1] = { pin = pin, mapID = mapID, x = px, y = py }
    end,
}
local libCall = getmetatable(LibStub).__call
getmetatable(LibStub).__call = function(self, name, ...)
    if name == "HereBeDragons-Pins-2.0" then return pins end
    return libCall(self, name, ...)
end
local profile = APR.settings.profile
profile.enableAddon, profile.showMiniMapLine, profile.showMapLine = true, true, true
profile.showMiniMapLineColor, profile.showMapLineColor = { 1, 0, 0 }, { 1, 0, 0 }
profile.showMiniMapLineThickness, profile.showMapLineThickness = 2, 2
profile.mapshowNextSteps, profile.minimapshowNextSteps = true, true
profile.mapshowNextStepsCount, profile.minimapshowNextStepsCount = 2, 2
profile.mapshowNextStepsSize, profile.minimapshowNextStepsSize = 16, 16
profile.mapshowNextStepsColor, profile.minimapshowNextStepsColor = { 1, 1, 0 }, { 1, 1, 0 }
APR.Arrow = { Active = true }
dofile("APR-Core/features/navigation/Map.lua")
APR.map:OnInit()
local tick = APR.map.stepLines.scripts.OnLoop
for _, mapID in ipairs({ 2215, 2274, 947, 946 }) do
    shownMap = mapID; tick()
    local segment = APR.map.worldSegments[1]
    if mapID == 947 or mapID == 946 then
        for _, line in ipairs(APR.map.worldSegments) do assert(not line.line:IsShown()) end
        assert(#worldPins[APR.map.pinlist] == 0, "World/cosmic overview has no APR pins")
        for _, pin in ipairs(APR.map.pinlist) do assert(not pin:IsShown()) end
    else
        assert(segment.line:IsShown(), "Zone and continent views retain the route line")
        near(segment.bx, expected[mapID][1] * 1000, "Line pin X " .. mapID)
        near(segment.by, -expected[mapID][2] * 800, "Line pin Y " .. mapID)
        local placed = worldPins[APR.map.pinlist][1]
        near(placed.x, expected[mapID][1]); near(placed.y, expected[mapID][2])
    end
    local mini = miniPins[APR.map.minimapPinlist][1]
    assert(mini.mapID == playerMap, "Opening a parent map never rebases minimap coordinates")
    near(mini.x, expected[2215][1]); near(mini.y, expected[2215][2])
end
shownMap = 2274; tick()
local beforeProjects, beforeRects, beforeReads, frames = projections, rectReads, mapReads, env.frames()
local anchors = APR.map.worldSegments[1].finish.anchors
for _ = 1, 100 do tick() end
assert(projections == beforeProjects and rectReads == beforeRects and mapReads == beforeReads
    and env.frames() == frames and APR.map.worldSegments[1].finish.anchors == anchors,
    "Idle map hierarchy rendering performs no projection, ancestry, frame allocation or anchor writes")
WorldMapFrame:SetSize(500, 400); tick()
near(APR.map.worldSegments[1].bx, expected[2274][1] * 500)
near(worldPins[APR.map.pinlist][1].x, expected[2274][1], "Resizing preserves continent pin coordinates")
local miniX = APR.map.minimapSegments[1].bx
Minimap:SetSize(300, 300); tick()
near(APR.map.minimapSegments[1].bx, miniX * 1.5, "Minimap resize redraws stationary geometry")
shownMap = 2215; tick()
assert(#worldPins[APR.map.pinlist] == 2, "Returning to the native map re-registers both normal HBD pins")
playerInstance = 42; tick()
for _, segment in ipairs(APR.map.minimapSegments) do assert(not segment.line:IsShown()) end
playerInstance = 2601; tick()
assert(APR.map.minimapSegments[1].line:IsShown(), "A valid native world restores minimap lines")
rects[2215] = { 0.3, 0.55, 0.4, 0.7 }
APR.map.eventFrame.scripts.OnEvent(nil, "NEW_WMO_CHUNK")
shownMap = 2274; tick()
near(APR.map.worldSegments[1].bx, 230.925, "A discrete geometry change invalidates parent rectangles")
profile.enableAddon = false; tick()
for _, segment in ipairs(APR.map.worldSegments) do assert(not segment.line:IsShown()) end
print("Map projection: real HBD/native identity, cross-instance ancestors/world/cosmic, caves/floors, pins/lines, resize and idle caches passed")
