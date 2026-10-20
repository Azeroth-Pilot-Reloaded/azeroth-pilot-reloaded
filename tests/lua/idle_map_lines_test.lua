local env = dofile("tests/lua/route_ui_test_env.lua")
WorldMapFrame, Minimap = env.widget(), env.widget()
WorldMapFrame:SetSize(1000, 800)
WorldMapFrame:Hide()
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return 1 end
function Minimap:GetZoom() return 0 end
function env.methods:CreateAnimationGroup() return env.widget() end
function env.methods:CreateAnimation() return env.widget() end
function env.methods:Play() end
function env.methods:CreateLine()
    local line = env.widget(self)
    self.line = line
    return line
end
local setEndPoint = env.methods.SetEndPoint
function env.methods:SetEndPoint(...)
    self.endpointWrites = (self.endpointWrites or 0) + 1
    setEndPoint(self, ...)
end
function APR:NewModule() return {RegisterMessage = function() end} end
function APR:IsInstanceWithUI() return true end
local playerX, playerY, facing, radius = 10, 20, 0, 200
function UnitPosition() return playerY, playerX end
function GetPlayerFacing() return facing end
function GetCVar() return "0" end
function GetMinimapShape() return "ROUND" end
C_Minimap = {GetViewRadius = function() return radius end}
C_Map = {GetPlayerMapPosition = function() return {x = playerX / 100, y = playerY / 100} end}
local coord = {x = 50, y = 100}
function APR:GetPlayerMapPos(_, y, x) return x / 100, y / 100 end
function APR:GetCurrentStep() return {} end
function APR:GetStep() return {} end
function APR:GetStepCoord() return coord end
APR.Arrow = {Active = true, x = coord.x, y = coord.y}
APR.Color.red = {1, 0, 0}
APR.ActiveRoute, APR.PlayerID, APRData = "route", "player", {player = {route = 1}}
local profile = APR.settings.profile
profile.enableAddon, profile.showMiniMapLine, profile.showMapLine = true, true, true
profile.showMiniMapLineColor, profile.showMapLineColor = {1, 0, 0}, {1, 0, 0}
profile.showMiniMapLineThickness, profile.showMapLineThickness = 2, 2
dofile("APR-Core/features/navigation/Map.lua")
APR.map:OnInit()
local tick = APR.map.stepLines.scripts.OnLoop
local minimapLine = Minimap.line
local worldUpdates, updateWorld = 0, APR.map.UpdateLine
function APR.map:UpdateLine() worldUpdates = worldUpdates + 1; updateWorld(self) end
tick()
local writes = minimapLine.endpointWrites
for _ = 1, 100 do tick() end
assert(worldUpdates == 0, "A closed world map never resolves route/coordinate data")
assert(minimapLine.endpointWrites == writes, "A stationary player never rewrites the minimap endpoint")
playerX = playerX + 1
tick()
assert(minimapLine.endpointWrites == writes + 1, "Movement updates the line on the next poll")
writes = minimapLine.endpointWrites
APR.Arrow.x = APR.Arrow.x + 5
tick()
assert(minimapLine.endpointWrites == writes + 1, "A changed target invalidates stationary geometry")
writes = minimapLine.endpointWrites
radius = radius / 2
APR.map.eventFrame.scripts.OnEvent(nil, "MINIMAP_UPDATE_ZOOM")
tick()
assert(minimapLine.endpointWrites == writes + 1, "Zoom updates stationary geometry")
APR.map.eventFrame.scripts.OnEvent(nil, "CVAR_UPDATE", "rotateMinimap", "1")
facing = nil
tick()
assert(not minimapLine:IsShown(), "Missing facing data hides a rotating line safely")
facing = 1
tick()
assert(minimapLine:IsShown(), "The line returns when facing data is available")

WorldMapFrame:Show()
tick()
local mapLine = WorldMapFrame.children[1].line
local start, finish = mapLine.startPoint[2], mapLine.endPoint[2]
local startWrites, finishWrites = start.anchors, finish.anchors
for _ = 1, 100 do tick() end
assert(start.anchors == startWrites and finish.anchors == finishWrites,
    "Unchanged world-map geometry never reanchors the line")
playerY = playerY + 1
tick()
assert(start.anchors == startWrites + 1 and finish.anchors == finishWrites,
    "Movement only reanchors the changed endpoint")
finishWrites = finish.anchors
APR.Arrow.y = APR.Arrow.y + 10
tick()
assert(finish.anchors == finishWrites + 1, "A changed target updates the world-map endpoint")
startWrites = start.anchors
WorldMapFrame:SetSize(500, 400)
tick()
assert(start.anchors == startWrites + 1, "Resizing redraws world-map geometry")
WorldMapFrame:Hide()
tick()
assert(not mapLine:IsShown())
local hides, updates = mapLine.hideCount, worldUpdates
for _ = 1, 100 do tick() end
assert(mapLine.hideCount == hides and worldUpdates == updates, "Closed maps do no repeated hide/update work")
WorldMapFrame:Show()
tick()
assert(mapLine:IsShown(), "Reopening the world map restores the line")
APR.Arrow.Active, coord = false, nil
tick()
assert(not minimapLine:IsShown() and not mapLine:IsShown(), "Missing step coordinates clear obsolete lines")
coord = {x = 50, y = 100}
tick()
assert(minimapLine:IsShown() and mapLine:IsShown())
profile.enableAddon = false
tick()
assert(not minimapLine:IsShown() and not mapLine:IsShown(), "Disabling APR removes both lines")
profile.enableAddon = true
tick()
assert(minimapLine:IsShown() and mapLine:IsShown(), "Re-enabling APR restores unchanged geometry")
print("Idle map lines: no redundant writes, closed-map work, stale lines or lost invalidations")
