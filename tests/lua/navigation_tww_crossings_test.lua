-- Native TWW entrances retain their distinct access regions in both directions.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.translations = { RUN_WAYPOINT = "Walk", TRAVEL_TO = "Travel to", WAYPOINT = "Waypoint" }
fixture.maps[2274] = { mapID = 2274, mapType = 2, parentMapID = 947 }
fixture.maps[1978] = { mapID = 1978, mapType = 2, parentMapID = 947 }
for _, entry in ipairs({ { 2214, 2274, 3 }, { 2215, 2274, 3 }, { 2255, 2274, 3 },
    { 2256, 2274, 3 }, { 2213, 2255, 3 }, { 2200, 1978, 3 },
    { 2253, 2200, 5 }, { 2254, 2200, 5 } }) do
    fixture.maps[entry[1]] = { mapID = entry[1], parentMapID = entry[2], mapType = entry[3] }
end
-- Deliberately synthetic affine projections exercise native map identity and
-- endpoint costs. They cannot establish the real tunnel's distance or speed.
local origins = { [2214] = 0, [2215] = 2000, [2255] = 4000 }
local projections = 0
C_Map.GetWorldPosFromMapPos = function(mapID, point)
    if not origins[mapID] then return nil end
    assert(point.x >= 0 and point.x <= 1 and point.y >= 0 and point.y <= 1,
        "Only normalized coordinates can be projected as native map points")
    projections = projections + 1
    return 2601, { x = origins[mapID] + point.x * 10000, y = point.y * 10000 }
end
local data = fixture:Load()
local ids = {
    ["passage-ringing-deeps-hallowfall"] = true,
    ["passage-hallowfall-azj-kahet-east"] = true,
    ["passage-ringing-deeps-azj-kahet"] = true,
    ["passage-hallowfall-azj-kahet-west"] = true,
}
local definitions, nativeEdges = {}, {}
for _, definition in ipairs(data.connections) do
    if ids[definition.id] then
        definitions[definition.id] = definition
        assert(definition.kind == "passage" and definition.bidirectional and definition.costMode == "ground")
        assert(definition.from.space == "map" and definition.to.space == "map")
    end
end
local count = 0
for id in pairs(ids) do assert(definitions[id], "Missing public TWW crossing: " .. id); count = count + 1 end
assert(count == 4)
local function at(point, mapID, instanceID, dx, dy)
    return assert(data:NormalizeLocation({ space = "world", instanceID = instanceID or point.instanceID,
        uiMapID = mapID or point.uiMapID, x = point.x + (dx or 0), y = point.y + (dy or 0) }))
end
local player = assert(data:NormalizeLocation({ space = "map", uiMapID = 2215, x = 0.5, y = 0.5 }))
local allEdges = data:BuildEdges({ playerPosition = player, walkSpeed = 10 })
for _, edge in ipairs(allEdges) do
    local id, direction = edge.id:match("^retail:(.-):(%a+)$")
    if ids[id] then
        nativeEdges[#nativeEdges + 1] = edge
        local definition = definitions[id]
        local from = direction == "forward" and definition.from or definition.to
        local to = direction == "forward" and definition.to or definition.from
        assert(edge.from.uiMapID == from.uiMapID and edge.to.uiMapID == to.uiMapID)
        assert(edge.from.instanceID == 2601 and edge.to.instanceID == 2601)
        assert(edge.mandatory and edge.seconds > 0 and not data:CanWalk(edge.from, edge.to),
            "A public crossing remains a costed mandatory edge between isolated regions")
        local dx, dy = edge.to.x - edge.from.x, edge.to.y - edge.from.y
        assert(math.abs(edge.seconds - math.sqrt(dx * dx + dy * dy) / 10) < 0.000001)
    end
end
assert(#nativeEdges == 8 and projections > 0, "All four catalogue passages must build forward and reverse edges")

local function search(start, goal)
    local job = data:CreateSearch({ start = start, goal = goal, edges = nativeEdges, walkSpeed = 10,
        canWalk = function(a, b) return data:CanWalk(a, b) end })
    local status, result, slices = nil, nil, 0
    repeat
        status, result = job:Step(32)
        slices = slices + 1
        assert(slices < 1000, "The small native passage graph must settle in bounded slices")
    until status ~= "planning"
    return status, result
end
for _, edge in ipairs(nativeEdges) do
    local start, goal = at(edge.from, nil, nil, -30), at(edge.to, nil, nil, 40)
    local status, result = search(start, goal)
    assert(status == "ready", "Both directions must connect through public native entrances: " .. edge.id)
    local crossing
    for _, segment in ipairs(result.segments) do
        if segment.id == edge.id then crossing = segment end
    end
    assert(crossing and crossing.mandatory and crossing.from.uiMapID == start.uiMapID
        and crossing.to.uiMapID == goal.uiMapID, "The route must retain its actual native entrance: " .. edge.id)
    assert(result.totalSeconds >= edge.seconds + 7,
        "Connector distance is charged in addition to the mandatory passage")
end

local azj
for _, edge in ipairs(nativeEdges) do
    if edge.id == "retail:passage-hallowfall-azj-kahet-east:forward" then azj = edge end
end
assert(azj)
local outdoorChild = at(azj.to, 2213)
assert(data:CanWalk(azj.to, outdoorChild) and data:CanWalk(outdoorChild, azj.to),
    "Ordinary outdoor City of Threads descendants share Azj-Kahet access")
assert(search(at(azj.from), outdoorChild) == "ready", "A passage can serve an ordinary destination subzone")
for _, mapID in ipairs({ 2253, 2254, 2256 }) do
    local isolated = at(azj.to, mapID)
    assert(not data:CanWalk(azj.to, isolated) and not data:CanWalk(isolated, azj.to),
        "Overlapping XY cannot connect unrelated interiors or the lower layer: " .. mapID)
    assert(search(at(azj.from), isolated) == "no_path",
        "Public TWW entrances do not invent access to an unrelated interior or lower map: " .. mapID)
end
assert(not data:CanWalk(azj.to, at(azj.to, nil, 0)), "Matching native map/XY in another instance is inaccessible")
local private = at(azj.to); private.accessKey = "private"
local floor = at(azj.to); floor.floor = "lower"
local closed = at(azj.to); closed.noAutoconnect = true
assert(not data:CanWalk(azj.to, private) and not data:CanWalk(azj.to, floor) and not data:CanWalk(azj.to, closed),
    "Private access keys, floors and non-autoconnecting endpoints retain their restrictions")

-- Feed a real searched itinerary to the real controller. Its passage cursor and
-- native-map arrival checks remain independent from the authored waypoint.
local function noop() end
local timers = {}
C_Timer = { NewTimer = function(delay, callback)
    local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function APR:NewModule() return {} end
APR.PlayerID, APR.ActiveRoute, APR.stepHandlers = "p", "r", {}
APR.settings = { profile = { enableAddon = true } }
APR.currentStep = { AddQuestSteps = noop, AddQuestDivider = noop }
APR.Arrow = { SetCoord = noop, SetArrowActive = noop }
APR.event, APR.SendMessage = { QueueStepRefresh = noop }, noop
APR.IsInRouteZone = true
function APR:GetPlayerParentMapID() return fixture.currentMap end
function APR:GetMapInfoCached(mapID) return C_Map.GetMapInfo(mapID) end
function APR:GetMapParentChain(mapID)
    local chain = {}
    for _ = 1, 20 do
        if not mapID or mapID == 0 then break end
        chain[#chain + 1] = mapID
        mapID = C_Map.GetMapInfo(mapID).parentMapID
    end
    return chain
end
function APR:GetNavigationPlayerPosition() return fixture.player end
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
APR.UpdateQuest = noop
local route
function APR:GetRouteSteps() return route end
function APR:UpdateStep()
    local step = self:GetCurrentStep()
    if step then self.stepHandlers.Transport(step, false) end
end
local nav = APR.navigation
for _, edge in ipairs(nativeEdges) do
    local start, goal = at(edge.from, nil, nil, -30), at(edge.to, nil, nil, 200)
    nav:Cancel("test_case")
    fixture.player, fixture.currentMap = start, start.uiMapID
    route = { { Waypoint = 1, NonSkippableWaypoint = true, Zone = goal.uiMapID,
        Coord = { x = goal.y, y = goal.x },
        ZoneStepTrigger = { mapID = goal.uiMapID, x = goal.y, y = goal.x, Range = 20 } },
        { Waypoint = 1, ZoneStepTrigger = { mapID = goal.uiMapID, x = goal.y + 3000, y = goal.x, Range = 20 } } }
    APR.RouteQuestStepList, APR.runtimeRouteStep = { r = route }, nil
    APRData = { p = { r = 1 } }
    APR:UpdateStep()
    local context, generation = APR:CaptureStepContext(), nav.generation
    nav.context = context
    local status, result = search(start, goal)
    assert(status == "ready")
    nav:Publish(result, context, generation)
    assert(nav:GetActiveStep().kind == "walk", "Guidance must first reach the source entrance")
    fixture.player, fixture.currentMap = at(edge.from), edge.from.uiMapID
    nav:PollArrival()
    assert(nav:GetActiveStep().connectionID == edge.id and APRData.p.r == 1)
    nav:PollArrival() -- Observe departure at the actual entrance.
    fixture.player = at(edge.to, edge.from.uiMapID)
    nav:PollArrival()
    assert(nav:GetActiveStep().connectionID == edge.id,
        "Destination XY on the source map cannot complete a mandatory cavern crossing")
    fixture.player = at(edge.to, nil, 0)
    nav:PollArrival()
    assert(nav:GetActiveStep().connectionID == edge.id, "Another world instance cannot complete the passage")
    if edge.to.uiMapID == 2255 then
        for _, mapID in ipairs({ 2253, 2254, 2256 }) do
            fixture.player, fixture.currentMap = at(edge.to, mapID), mapID
            nav:PollArrival()
            assert(nav:GetActiveStep().connectionID == edge.id,
                "Interior/lower map XY is not proof that the public passage arrived: " .. mapID)
        end
    end
    fixture.player, fixture.currentMap = at(edge.to), edge.to.uiMapID
    if edge == azj then
        fixture.player, fixture.currentMap = at(edge.to, 2213), 2213
    end
    nav:PollArrival()
    assert(nav:GetActiveStep().kind == "walk" and APRData.p.r == 1,
        "Actual native arrival completes only the mandatory passage, not the final authored waypoint")
    APR.transportArrivalTimer.callback()
    assert(APRData.p.r == 1, "The original trigger still waits for its own destination beyond the entrance")
    fixture.player, fixture.currentMap = goal, goal.uiMapID
    nav:PollArrival()
    assert(not nav:IsNavigating() and APRData.p.r == 1,
        "Completing temporary guidance never increments authored route progress")
    APR.transportArrivalTimer.callback()
    assert(APRData.p.r == 2, "Only the authored destination's arrival trigger advances the original waypoint")
    APR.transportArrivalTimer.callback()
    assert(APRData.p.r == 2, "The next distant waypoint cannot validate at the preceding destination")
end
print("TWW crossings: four real native passages in both directions; descendants, isolated layers, costs and authored/controller arrivals passed")
