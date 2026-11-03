-- Reuse actual native-position projection: overlapping floors remain unknown;
-- a nearby unique surface or a real altitude can resume an idle height wait.
local function fixture(reason)
    local native = dofile("tests/lua/navigation_fixture.lua")
    native.currentMap, native.player = 501, { x = 0, y = 0, z = 0, instanceID = 8 }
    local data = native:Load({ connections = {} })
    local lib = LibStub("LibAPRNavigation-1.0")
    data.env.requestTerrainData = function() return "ready" end
    data.GetPositionRegion = function() return "synthetic-room" end
    local function point(x, z)
        return { x = x, y = 0, z = z, instanceID = 8, uiMapID = 501, region = "synthetic-room" }
    end
    local nodes, anchors = {}, {}
    for index, surface in ipairs({ { 0, 10, 2 }, { 0, 30, 2 }, { 4, 10, 1 }, { 8, 0, 1 } }) do
        local node = point(surface[1], surface[2]); node.id = "surface-" .. index
        nodes[#nodes + 1] = node
        anchors[#anchors + 1] = { node = node.id, minX = node.x - surface[3], maxX = node.x + surface[3],
            minY = -surface[3], maxY = surface[3], minZ = node.z - 1, maxZ = node.z + 1,
            mode = "ground", bidirectional = true }
    end
    lib:RegisterTerrainData("retail", 8, { format = 1, nodes = nodes, anchors = anchors, edges = {} }, 1, "synthetic-floors")
    local build = data:CreateTerrainEdgeBuild({ start = nodes[1], goal = nodes[3] })
    for _ = 1, 1000 do if build:Step(64, 100) ~= "planning" then break end end
    assert(build.status == "ready", tostring(build.status) .. ": " .. tostring(build.reason))
    data._terrainGroundObservation = nil
    dofile("APR-Core/utils/NavigationZones.lua")
    local t = { native = native, data = data, lib = lib, now = 10, timers = {}, builds = 0, publications = 0 }
    local noop = function() end
    function GetTime() return t.now end
    function UnitIsDeadOrGhost() return false end
    function InCombatLockdown() return false end
    function GetMoney() return 0 end
    function CreateFrame()
        local frame = { scripts = {}, RegisterEvent = noop }
        function frame:SetScript(key, callback) self.scripts[key] = callback end
        t.frame = frame
        return frame
    end
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        t.timers[#t.timers + 1] = timer
        return timer
    end }
    APR.PlayerID, APR.ActiveRoute = "synthetic-character", "synthetic-height-wait"
    APRData = { [APR.PlayerID] = { [APR.ActiveRoute] = 1 } }
    APR.settings, APR.GAME_VERSIONS = { profile = { enableAddon = true } }, { Forever = "forever" }
    APR.NewModule, APR.Arrow = function() return {} end, { SetArrowActive = noop }
    local step = { Zone = 501, Waypoint = 1, Coord = { x = 0, y = 100, mapID = 501, instanceID = 8 } }
    local context = { route = APR.ActiveRoute, index = 1, revision = 1, definition = { steps = { step } } }
    function APR:CaptureStepContext() return context end
    function APR:IsStepContextCurrent(value) return value == context end
    function APR:GetCurrentStep() return step end
    function APR:PeekCurrentStep() return step end
    function APR:GetStepCoord(value) return value.Coord, value.Zone end
    function APR:GetCurrentRouteMapIDsAndName() return { 501 }, 501 end
    function APR:CheckNavigationZoneReady() return false end
    APR.NavigationPlanner = { Create = function(_, request)
        t.builds, t.lastStart = t.builds + 1, request.start
        local known = request.start.heightSource == "terrain" or (request.start.z and request.start.z ~= 0)
        return { status = known and "ready" or "no_path", waitingData = not known,
            terrainReason = not known and reason or nil,
            terrainCoverage = { missing = { { reason = "unrelated_optional_surface" } } },
            Step = function(self) return self.status, { queue = {} } end, Cancel = noop }
    end }
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav = APR.navigation
    nav.Notify, nav.Render, nav.ClearNavigationUiLines = noop, noop, noop
    nav.TryResumeAfterTransition = function() return false end
    nav.GetDestination = function() return point(100, 10), 501 end
    nav.GetThreshold = function() return 2000 end
    nav.GetMovementSpeed = function() return 7 end
    nav.GetMovementProfile = function() return {} end
    nav.IsItineraryValid, nav.IsDirectRouteValid = function() return false end, function() return false end
    nav.CaptureRetainedArrow = function() return nil end
    nav.Publish = function(self)
        t.publications = t.publications + 1
        self.search, self.state = nil, "ready"
    end
    t.nav = nav
    function t:drain()
        local turns = 0
        while #self.timers > 0 do
            local timer = table.remove(self.timers, 1)
            if not timer.cancelled then timer.callback() end
            turns = turns + 1; assert(turns < 10)
        end
    end
    function t:tick()
        self.now = self.now + 0.5
        self.frame.scripts.OnUpdate(self.frame, 0.5)
        self:drain()
    end
    nav:Update(context)
    assert(t.builds == 1 and nav.state == "waiting_data" and nav.reason == reason)
    assert(nav.lastPlanning.terrainReason == reason,
        "The authoritative origin height reason wins over an unrelated optional surface")
    return t
end

for _, reason in ipairs({ "ambiguous_terrain_surface", "terrain_height_unavailable",
    "terrain_altitude_missing", "aerial_altitude_unavailable" }) do
    local t = fixture(reason)
    for _ = 1, 40 do t:tick() end
    local raw = APR:GetNavigationPlayerPosition()
    assert(t.builds == 1 and t.publications == 0 and not t.nav.search and raw.z == 0 and not raw.heightSource,
        "An unchanged ambiguous origin remains idle without rebuilding or inventing a floor")
    t.native.player.x = 0.5
    t:tick()
    assert(t.builds == 1, "Nearby movement inside the same overlapping floors is still unknown")
    t.native.player.x = 4
    t:tick()
    assert(t.builds == 2 and t.publications == 1 and t.lastStart.z == 10
        and t.lastStart.heightSource == "terrain" and t.lastStart.observedZ == 0,
        "A nearby unique surface resumes planning before the ordinary movement threshold")
end

local t = fixture("ambiguous_terrain_surface")
t.native.player.z = 30
t:tick()
assert(t.builds == 2 and t.publications == 1 and t.lastStart.z == 30 and t.lastStart.observedZ == 30,
    "A real nonzero native altitude resumes without choosing a default lower floor")
t = fixture("ambiguous_terrain_surface")
t.native.player.x = 8
t:tick()
assert(t.builds == 2 and t.publications == 1 and t.lastStart.z == 0 and t.lastStart.heightSource == "terrain",
    "A proved sea-level surface is usable height evidence even though its elevation is zero")

for _, change in ipairs({ "geometry", "source", "access", "action" }) do
    t = fixture("ambiguous_terrain_surface")
    if change == "geometry" then APR.navigationGeometryRevision = (APR.navigationGeometryRevision or 0) + 1
    elseif change == "source" then t.lib.terrainRevision = t.lib.terrainRevision + 1
    elseif change == "access" then t.native.currentMap = 502
    else t.frame.scripts.OnEvent(t.frame, "BAG_UPDATE_DELAYED") end
    t:tick()
    assert(t.builds == 2 and t.publications == 0,
        "New geometry, access or action evidence can reconsider a height-blocked request")
    for _ = 1, 8 do t:tick() end
    assert(t.builds == 2, "The new failed observation returns to an idle height wait")
end

t = fixture("terrain_source_pending")
t:tick()
assert(t.builds == 2, "Ordinary pending data retains its existing retry policy")
for _ = 1, 3 do t:tick() end
assert(t.builds == 2)
t:tick()
assert(t.builds == 3, "Ordinary data retries remain spaced two seconds apart")
t.nav:Cancel("cleared")
assert(not t.nav._heightWaitPosition and not t.nav._routeInputs)
print("Height waits: idle ambiguous origins, native/nearby projected recovery, evidence invalidation and ordinary retries passed")
