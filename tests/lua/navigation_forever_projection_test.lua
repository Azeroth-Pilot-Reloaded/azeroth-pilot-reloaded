local ui = dofile("tests/lua/route_ui_test_env.lua")
local fixture = dofile("tests/lua/navigation_forever_fixture.lua")
fixture:Load()
local translations, projections, ready = 0, 0, true
local hbd = {
    GetZoneCoordinatesFromWorldInstance = function(_, x, y, instance, map)
        projections = projections + 1
        if instance == fixture:WorldForMap(map) then return x / 1000, y / 1000 end
    end,
    TranslateZoneCoordinates = function(_, x, y, source, target)
        translations = translations + 1
        if ready then return 0.1 + x * 0.25, 0.2 + y * 0.5 end
    end,
}
local stub = LibStub
LibStub = setmetatable({}, { __call = function(_, name, ...)
    if name == "HereBeDragons-2.0" then return hbd end
    return stub(name, ...)
end })
dofile("APR-Core/features/navigation/Preview.lua")
local preview = APR.navigationPreview
local point = { Coord = { x = 250, y = 500 }, uiMapID = 1453, instanceID = 0 }
local x, y = preview:ProjectPoint(point, 1415)
assert(math.abs(x - 0.1625) < 1e-10 and math.abs(y - 0.45) < 1e-10)
assert(translations == 2 and projections == 1,
    "Forever derives one parent rectangle from HBD without a Retail rectangle API")
for _ = 1, 100 do fixture.time = fixture.time + 0.3; preview:ProjectPoint(point, 1415) end
assert(translations == 2 and projections == 1,
    "Stable Forever point projections must not expire merely because the native rectangle API is absent")
point.Coord.x = 300
x, y = preview:ProjectPoint(point, 1415)
assert(math.abs(x - 0.175) < 1e-10 and translations == 2 and projections == 2,
    "Movement reuses the composed parent transform while updating the native position")
preview:InvalidateProjectionCache()
preview:ProjectPoint(point, 1415)
assert(translations == 4 and projections == 3)

ready = false
preview:InvalidateProjectionCache()
assert(preview:ProjectPoint(point, 1415) == nil)
ready, fixture.time = true, fixture.time + 0.3
assert(preview:ProjectPoint(point, 1415) ~= nil, "Late HBD map data remains retryable on Forever")

C_Map.GetMapRectOnMap = function() return 0, 0, 0, 0 end
preview:InvalidateProjectionCache()
local beforeInvalidRect = translations
assert(preview:ProjectPoint(point, 1415) ~= nil and translations == beforeInvalidRect + 2,
    "A present but unusable native rectangle also uses the cached HBD fallback")
C_Map.GetMapRectOnMap = nil

local otherInstance = { Coord = { x = 10, y = 20 }, uiMapID = 225, instanceID = 369 }
local before = translations
preview:ProjectPoint(otherInstance, 1415)
assert(translations == before + 1,
    "A different-instance parent must not be approximated by a same-instance affine rectangle")
fixture.time = fixture.time + 0.3
preview:ProjectPoint(otherInstance, 1415)
assert(translations == before + 2, "Unsupported cross-instance translation keeps its retryable path")

-- Render both real line consumers with legacy minimap radius/zoom APIs.
WorldMapFrame, Minimap = ui.widget(), ui.widget()
WorldMapFrame:SetSize(1000, 800); Minimap:SetSize(200, 200)
WorldMapFrame:Show(); Minimap:Show()
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return 1415 end
function Minimap:GetZoom() return 0 end
function ui.methods:CreateAnimationGroup() return ui.widget() end
function ui.methods:CreateAnimation() return ui.widget() end
function ui.methods:Play() end
function CreateFrame() return ui.widget() end
function GetCVar() return "0" end
function GetMinimapShape() return "ROUND" end
function GetPlayerFacing() return 0 end
C_Map.GetPlayerMapPosition = function() return nil end
APR.settings = { profile = { enableAddon = true, showMiniMapLine = true, showMapLine = true,
    showMiniMapLineColor = { 1, 0, 0 }, showMapLineColor = { 1, 0, 0 },
    showMiniMapLineThickness = 2, showMapLineThickness = 2 } }
function APR:NewModule() return { RegisterMessage = function() end } end
function APR:IsInstanceWithUI() return true end
local pins = {}
local getLib = LibStub
function LibStub(name, ...)
    if name == "HereBeDragons-Pins-2.0" then return pins end
    return getLib(name, ...)
end
local points = {
    { Coord = { x = 220, y = 110 }, uiMapID = 1453, instanceID = 0 },
    { Coord = { x = 240, y = 120 }, uiMapID = 1453, instanceID = 0 },
}
function preview:GetPoints() return points end
fixture.player = { x = 100, y = 200, instanceID = 0 }
dofile("APR-Core/features/navigation/Map.lua")
APR.map:OnInit()
local tick = APR.map.stepLines.scripts.OnLoop
tick()
assert(APR.map.minimapSegments[1].line:IsShown() and APR.map.worldSegments[1].line:IsShown(),
    "Forever renders both line types without modern minimap or native rectangle APIs")
local beforeProjections, beforeTranslations = projections, translations
for _ = 1, 100 do
    fixture.player.x = fixture.player.x + 0.01
    fixture.time = fixture.time + 0.3
    tick()
end
assert(projections - beforeProjections <= 200 and translations == beforeTranslations,
    "Forever moving redraws reproject only the player and never expire stable parent transforms")
Minimap:SetSize(240, 240); tick()
assert(APR.map.minimapSegments[1].line:IsShown())
WorldMapFrame:Hide(); Minimap:Hide(); tick()
assert(not APR.map.minimapSegments[1].line:IsShown() and not APR.map.worldSegments[1].line:IsShown())
print("Forever projections: no native map rectangles, permanent stable cache, affine parent reuse, movement, invalidation, delayed maps and cross-instance safety passed")
