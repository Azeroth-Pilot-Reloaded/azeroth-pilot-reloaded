-- The preview, pins and both line renderers share one ordered, instance-aware path.
local env = dofile("tests/lua/route_ui_test_env.lua")
local playerMap, shownMap, playerInstance = 1, 1, 10
local playerX, playerY, facing, radius = 5, 5, 0, 1000
function UnitPosition() return playerY, playerX, 0, playerInstance end
function CreateVector2D(x, y) return { x = x, y = y } end
function GetPlayerFacing() return facing end
function GetCVar() return "0" end
function GetMinimapShape() return "ROUND" end
C_Minimap = { GetViewRadius = function() return radius end }
C_Map = {
    GetBestMapForUnit = function() return playerMap end,
    GetWorldPosFromMapPos = function(map) return map == 1 and 10 or 20, {} end,
    GetPlayerMapPosition = function(map)
        if map == playerMap then return { x = playerX / 1000, y = playerY / 1000 } end
    end,
}
local steps = {}
for i = 1, 5 do steps[i] = { Waypoint = i, Coord = { x = i * 20, y = i * 20 }, Zone = 1 } end
steps[6] = { PickUp = { 1 }, Coord = { x = 150, y = 150 }, Zone = 1 }
steps[7] = { Done = { 1 }, Coord = { x = 200, y = 200 }, Zone = 1 }
APR.ActiveRoute, APR.PlayerID, APR.stepRevision = "route", "player", 0
APR.RouteQuestStepList, APRData = { route = { steps = steps, mapID = 1 } }, { player = { route = 1 } }
local coordinateReads = 0
function APR:GetCurrentStep() return steps[APRData.player.route], APRData.player.route, steps end
function APR:GetRouteSteps() return steps end
function APR:GetPlayerParentMapID() return playerMap end
function APR:GetStepCoord(step) coordinateReads = coordinateReads + 1; return step.Coord, step.Zone end
function APR:StepFilterQoL(step) return not step.hidden end
function APR:GetPlayerMapPos(_, y, x) return x / 1000, y / 1000 end
function APR:IsInstanceWithUI() return true end
function APR:CheckIsInRouteZone() error("Out-of-zone guidance pins must not be suppressed") end
dofile("APR-Core/features/navigation/Preview.lua")
local preview = APR.navigationPreview
local points = preview:BuildRoutePoints()
assert(#points == 6 and points[6].step == steps[6], "Five waypoints include their first non-waypoint objective")
local reads = coordinateReads
for _ = 1, 100 do preview:BuildRoutePoints() end
assert(coordinateReads == reads, "An unchanged preview does not rescan waypoint coordinates")
local guidance = {
    { kind = "walk", Coord = { x = 2, y = 2 }, instanceID = 10 },
    { kind = "walk", Coord = { x = 3, y = 3 }, instanceID = 10 },
}
local pointCalls = 0
local createPoint = preview.Point
function preview:Point(...)
    pointCalls = pointCalls + 1
    return createPoint(self, ...)
end
local combined = preview:Build(guidance, steps[1], 1, steps, 1)
local initialPointCalls = pointCalls
for _ = 1, 100 do
    assert(preview:Build(guidance, steps[1], 1, steps, 1) == combined)
end
assert(pointCalls == initialPointCalls, "Repeated arrow/map reads reuse the published geometry without cloning points")
local advanced = preview:Build(guidance, steps[1], 1, steps, 2)
assert(advanced ~= combined and #advanced == #combined - 1, "Advancing guidance invalidates the combined preview")
preview.routeCache = nil
assert(preview:Build(guidance, steps[1], 1, steps, 2) ~= advanced,
    "A route geometry refresh also invalidates the combined preview")
local a, b = { instanceID = 10 }, { instanceID = 20 }
assert(not preview:CanConnect(a, b), "Equal world numbers in unrelated instances never form a leg")
b.instanceID = 10
assert(preview:CanConnect(a, b), "Same-instance transport previews remain connected")
local ax, ay, bx, by = preview:ClipMinimapSegment(-2, 0, 2, 0)
assert(math.abs(ax + 0.9) < 1e-8 and math.abs(bx - 0.9) < 1e-8 and ay == 0 and by == 0,
    "A segment crossing the minimap is visible even when both endpoints are outside")
assert(preview:ClipMinimapSegment(-2, 2, 2, 2) == nil, "Off-screen legs are clipped, never pulled onto the rim")
ax, ay, bx, by = preview:ClipMinimapSegment(0, 0, 2, 2, { false, false, false, false })
assert(math.abs(bx - 0.9) < 1e-8 and math.abs(by - 0.9) < 1e-8, "Square minimaps retain their corners")
ax, ay, bx, by = preview:ClipMinimapSegment(0, 0, 2, 2)
assert(math.abs(bx * bx + by * by - 0.81) < 1e-8, "Round minimaps clip to the circle")
local probe = preview:Build({
    { kind = "walk", Coord = { x = 7, y = 7 }, instanceID = 10 },
    { kind = "verify_taxi", Coord = { x = 7, y = 7 }, instanceID = 10, mandatory = true,
        label = "Check the flight master", breakAfter = true,
        to = { x = 7, y = 7, instanceID = 10 } },
}, APR:GetCurrentStep())
assert(probe[1].kind == "verify_taxi" and probe[1].mandatory and probe[1].breakAfter
    and probe[1].label == "Check the flight master" and not preview:CanConnect(probe[1], probe[2]),
    "Coincident walking points preserve a mandatory taxi verification and its unknown continuation")

local personal = preview:Build({
    { kind = "spell", sourceFree = true, action = { type = "spell", data = 3567 },
        Coord = { x = 38, y = 38 }, instanceID = 10,
        to = { x = 500, y = 600, instanceID = 10, uiMapID = 1 } },
}, APR:GetCurrentStep())
assert(personal[1].arrival and personal[1].Coord.x == 600 and personal[1].Coord.y == 500
    and personal[1].breakBefore and not preview:CanConnect({ instanceID = 10 }, personal[1]),
    "Personal travel keeps its arrival but never draws a walk back to its old cast origin, even in the same world")
assert(preview:CanConnect(personal[1], personal[2]), "The route after the personal arrival remains connected")
personal = preview:Build({
    { kind = "walk", Coord = { x = 30, y = 40 }, instanceID = 10 },
    { kind = "item", sourceFree = true, action = { type = "item", data = 123 }, instanceID = 10,
        to = { x = 500, y = 600, instanceID = 20, uiMapID = 2 } },
}, APR:GetCurrentStep())
assert(personal[1].kind == "walk" and personal[1].Coord.x == 30 and personal[2].arrival
    and personal[2].breakBefore and not preview:CanConnect(personal[1], personal[2]),
    "A future location-restricted item retains its preceding approach without a fabricated cast marker")

WorldMapFrame, Minimap = env.widget(), env.widget()
WorldMapFrame:SetSize(1000, 800); Minimap:SetSize(200, 200)
function WorldMapFrame:GetCanvas() return self end
function WorldMapFrame:GetMapID() return shownMap end
function Minimap:GetZoom() return 0 end
function env.methods:CreateAnimationGroup() return env.widget() end
function env.methods:CreateAnimation() return env.widget() end
function env.methods:Play() end
function env.methods:SetTexture(texture) self.texture = texture end
function APR:NewModule() return { RegisterMessage = function() end } end
local worldPins, miniPins = {}, {}
local pins = {
    RemoveAllWorldMapIcons = function(_, group) worldPins[group] = {} end,
    RemoveAllMinimapIcons = function(_, group) miniPins[group] = {} end,
    AddWorldMapIconMap = function(_, group, pin, map)
        worldPins[group] = worldPins[group] or {}; table.insert(worldPins[group], pin); pin.drawnMap = map
    end,
    AddMinimapIconMap = function(_, group, pin, map)
        miniPins[group] = miniPins[group] or {}; table.insert(miniPins[group], pin); pin.drawnMap = map
    end,
}
local originalLibStub = LibStub
function LibStub(name, ...)
    if name == "HereBeDragons-Pins-2.0" then return pins end
    return originalLibStub(name, ...)
end
local profile = APR.settings.profile
profile.enableAddon, profile.showMiniMapLine, profile.showMapLine = true, true, true
profile.showMiniMapLineColor, profile.showMapLineColor = { 1, 0, 0 }, { 1, 0, 0 }
profile.showMiniMapLineThickness, profile.showMapLineThickness = 2, 2
profile.mapshowNextSteps, profile.minimapshowNextSteps = true, true
profile.mapshowNextStepsCount, profile.minimapshowNextStepsCount = 2, 2
profile.mapshowNextStepsSize, profile.minimapshowNextStepsSize = 16, 16
profile.mapshowNextStepsColor, profile.minimapshowNextStepsColor = { 1, 1, 0 }, { 1, 1, 0 }
APR.Arrow = { Active = true, x = 20, y = 20 }
dofile("APR-Core/features/navigation/Map.lua")
APR.map:OnInit()
local tick = APR.map.stepLines.scripts.OnLoop
tick()
assert(#APR.map.worldSegments == 6 and #APR.map.minimapSegments == 6,
    "Both maps show player, five waypoints and pickup, regardless of the pin-count setting")
local frames, anchors = env.frames(), APR.map.worldSegments[2].start.anchors
reads = coordinateReads
local routeReads, clipCalls, projectionCalls = 0, 0, 0
local getStep, clipMinimap, clipWorld, project = APR.GetCurrentStep, preview.ClipMinimapSegment,
    preview.ClipRectangle, APR.GetPlayerMapPos
function APR:GetCurrentStep() routeReads = routeReads + 1; return getStep(self) end
function preview:ClipMinimapSegment(...) clipCalls = clipCalls + 1; return clipMinimap(self, ...) end
function preview:ClipRectangle(...) clipCalls = clipCalls + 1; return clipWorld(self, ...) end
function APR:GetPlayerMapPos(...) projectionCalls = projectionCalls + 1; return project(self, ...) end
for _ = 1, 100 do tick() end
assert(env.frames() == frames and APR.map.worldSegments[2].start.anchors == anchors and coordinateReads == reads,
    "Unchanged chain rendering allocates no frames, resolves no coordinates and moves no anchors")
assert(routeReads == 0 and clipCalls == 0 and projectionCalls == 0,
    "One hundred stationary refreshes perform no route resolution, projection or clipping")
playerX = playerX + 1
tick()
assert(routeReads == 0 and clipCalls > 0 and projectionCalls > 0,
    "Movement redraws the path immediately without resolving the effective route again")
APR.map:AddMapPins()
assert(#worldPins[APR.map.pinlist] == 2 and #miniPins[APR.map.minimapPinlist] == 2)
assert(worldPins[APR.map.pinlist][1].stepIndex == 1, "Authored pins retain their route numbers")

local guidance = {
    { id = "walk", kind = "walk", Coord = { x = 10, y = 10 }, uiMapID = 1, instanceID = 10, label = "Reach the portal" },
    { id = "portal", kind = "portal", Coord = { x = 12, y = 12 }, uiMapID = 1, instanceID = 10,
        from = { x = 12, y = 12, instanceID = 10, uiMapID = 1 },
        to = { x = 15, y = 15, instanceID = 20, uiMapID = 2 }, mandatory = true, label = "Take the portal" },
}
APR.navigation = { GetPreview = function() return preview:Build(guidance, APR:GetCurrentStep()) end }
for _, step in ipairs(steps) do step.Zone = 2 end
APR.stepRevision = APR.stepRevision + 1
APR.IsInRouteZone = false
APR.map:AddMapPins()
assert(#worldPins[APR.map.guidancePinlist] == 2 and #miniPins[APR.map.guidanceMinimapPinlist] == 2,
    "Out-of-zone walking and mandatory portal markers are shown")
for _, pin in ipairs(worldPins[APR.map.guidancePinlist]) do
    assert(pin.stepIndex == nil and pin.text:GetText() == "", "Injected guidance never borrows route numbering")
end
local portalPin = worldPins[APR.map.guidancePinlist][2]
assert(portalPin.icon.texture:find("Teleport", 1, true), "Mandatory transport uses a distinct icon")
tick()
local visible = 0
for _, segment in ipairs(APR.map.worldSegments) do if segment.line:IsShown() then visible = visible + 1 end end
assert(visible == 2, "The world map never connects into another instance's coordinate space")
shownMap = 2
tick()
visible = 0
for _, segment in ipairs(APR.map.worldSegments) do if segment.line:IsShown() then visible = visible + 1 end end
assert(visible == 6, "A destination map shows the route from the arrival point to the original objective")
assert(#miniPins[APR.map.guidanceMinimapPinlist] == 2, "Minimap pins use the player's map independently of the open world map")
for _, pin in ipairs(miniPins[APR.map.guidanceMinimapPinlist]) do assert(pin.drawnMap == 1) end
guidance = {}
tick(); APR.map:AddMapPins()
assert(#worldPins[APR.map.guidancePinlist] == 0 and #miniPins[APR.map.guidanceMinimapPinlist] == 0,
    "Finished guidance removes synthetic markers")
assert(steps[1].Coord.x == 20 and APRData.player.route == 1, "Preview/rendering never changes authored progress or coordinates")
profile.enableAddon = false
tick()
for _, segment in ipairs(APR.map.worldSegments) do assert(not segment.line:IsShown()) end
for _, segment in ipairs(APR.map.minimapSegments) do assert(not segment.line:IsShown()) end
print("Navigation preview: waypoint chains, pooled map geometry, clipping, generated icons and cross-instance safety passed")

-- Published controller state is the cache boundary; it must refresh even if
-- the character does not move between a replan, arrival or route transition.
local previewReads = 0
local controller = {
    state = "guiding", cursor = 1,
    queue = {
        { kind = "walk", Coord = { x = 10, y = 10 }, instanceID = 10 },
        { kind = "portal", Coord = { x = 15, y = 15 }, instanceID = 10, mandatory = true },
    },
}
function controller:GetPreview()
    previewReads = previewReads + 1
    local step, index, route = APR:GetCurrentStep()
    return preview:Build(self.state == "guiding" and self.queue or {}, step, index, route, self.cursor)
end
APR.navigation = controller
local first = preview:GetPoints()
for _ = 1, 100 do assert(preview:GetPoints() == first) end
assert(previewReads == 1, "Published guidance is resolved once for one hundred unchanged map reads")
controller.cursor = 2
local afterArrival = preview:GetPoints()
assert(afterArrival ~= first and afterArrival[1].kind == "portal", "Guidance arrival updates the stationary preview")
controller.queue = { { kind = "walk", Coord = { x = 30, y = 30 }, instanceID = 10 } }
controller.cursor = 1
assert(preview:GetPoints()[1].Coord.x == 30, "A replacement itinerary invalidates the preview")
controller.state = "ready"
assert(not preview:GetPoints()[1].generated, "Finishing guidance restores the authored route")
APRData.player.route = 2
assert(preview:GetPoints()[1].routeIndex == 2, "Saved route progress is part of the cache identity")
steps[2].Coord = { x = 777, y = 888 }
preview.routeCache = nil -- Map refreshes invalidate after quest/scenario coordinate changes.
assert(preview:GetPoints()[1].Coord.x == 777, "An explicit geometry refresh is never hidden by the publication cache")
steps[2] = { Coord = { x = 444, y = 555 }, Zone = 2 }
assert(preview:GetPoints()[1].Coord.x == 444,
    "Replacing an authored step without a progress revision invalidates the preview while the arrow is disabled")
steps = { steps[1], { Coord = { x = 222, y = 333 }, Zone = 2 } }
APR.RouteQuestStepList.route.steps = steps
assert(preview:GetPoints()[1].Coord.x == 222, "Replacing the source array preserves route editor updates")

-- Scenario travel adjusts the shared runtime step after the map update event.
-- Those changes must not need another event or a saved progress revision.
APR.runtimeRouteStep = { step = steps[2] }
preview:GetPoints()
steps[2].Coord = { x = 111, y = 222 }
assert(preview:GetPoints()[1].Coord.x == 111, "Scenario coordinates refresh after the presentation event")
steps[2].NoArrow = true
assert(#preview:GetPoints() == 0, "Entering a coordinate-free scenario clears cached points immediately")
steps[2].NoArrow = nil
assert(#preview:GetPoints() == 1, "Leaving the scenario restores its target immediately")
local beforeParallelRefresh = previewReads
APR.runtimeRouteStep = nil
preview:GetPoints()
assert(previewReads == beforeParallelRefresh + 1,
    "Parallel route invalidation refreshes the preview without requiring a changed saved index")
print("Published preview: idle reads skip route resolution; arrivals, replans, progress and geometry changes invalidate immediately")
