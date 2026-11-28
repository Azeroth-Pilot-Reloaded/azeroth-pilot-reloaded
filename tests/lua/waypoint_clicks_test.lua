local function noop() end

local function Run(profile)
    local fixture = dofile("tests/lua/navigation_fixture.lua")
    fixture.profile = profile
    fixture.maps = {
        [10] = {mapID = 10, mapType = 2, parentMapID = 0},
        [11] = {mapID = 11, mapType = 3, parentMapID = 10},
        [12] = {mapID = 12, mapType = 3, parentMapID = 10},
        [20] = {mapID = 20, mapType = 2, parentMapID = 0},
        [21] = {mapID = 21, mapType = 3, parentMapID = 20},
    }
    local player = {x = 500, y = 500, z = 42, instanceID = 1, uiMapID = 11}
    fixture.currentMap = player.uiMapID
    C_Map.GetWorldPosFromMapPos = function(map, pos)
        if fixture.maps[map] then
            return map < 20 and 1 or 2, {x = 1000 * (1 - pos.y), y = 1000 * (1 - pos.x)}
        end
    end
    C_Map.GetMapPosFromWorldPos = function(world, pos, hint)
        return hint or (world == 1 and 11 or 21), {x = 1 - pos.y / 1000, y = 1 - pos.x / 1000}
    end
    local function point(world, map, x, y)
        return {instanceID = world, uiMapID = map, x = x, y = y}
    end
    local data = fixture:Load({connections = {{id = "crossing", kind = "portal", seconds = 1,
        from = point(1, 11, 600, 500), to = point(2, 21, 300, 700)}}})
    local timers = {}
    C_Timer = {NewTimer = function(_, callback)
        local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
        timers[#timers + 1] = timer
        return timer
    end}
    local function drain()
        local limit = 500
        while #timers > 0 do
            limit = limit - 1
            assert(limit > 0, "Waypoint planning should finish")
            local timer = table.remove(timers, 1)
            if not timer.cancelled then timer.callback() end
        end
    end
    local shift, ctrl, alt, rotating, ignored, facing, shape = false, false, false, false, false, 0, "ROUND"
    local mouseX, mouseY, radius = 300, 160, 100
    function IsShiftKeyDown() return shift end
    function IsControlKeyDown() return ctrl end
    function IsAltKeyDown() return alt end
    function GetCursorPosition() return mouseX, mouseY end
    function GetCVar() return rotating and "1" or "0" end
    function GetPlayerFacing() return facing end
    function GetMinimapShape() return shape end
    function GetMoney() return 0 end
    function UnitIsDeadOrGhost() return false end
    C_Minimap = {GetViewRadius = function() return radius end, IsRotateMinimapIgnored = function() return ignored end}
    local clicks, mouseUp, mapID = 0, nil, 20
    WorldMapFrame = {GetMapID = function() return mapID end, AddCanvasClickHandler = function(self, cb)
        assert(not self.handler, "Install the world map handler once")
        self.handler = cb
    end}
    Minimap = {GetCenter = function() return 100, 80 end, GetWidth = function() return 200 end,
        GetHeight = function() return 100 end, GetEffectiveScale = function() return 2 end,
        HookScript = function(_, event, cb) assert(event == "OnMouseUp" and not mouseUp); mouseUp = cb end}
    APR.PlayerID = "player"
    APR.settings = {profile = {enableAddon = true}}
    APR.GAME_VERSIONS = {Forever = "forever"}
    APRData = {player = {guide = 2}}
    APR.RouteQuestStepList = {guide = {steps = {{}, {Coord = {x = 510, y = 700, mapID = 11}, Zone = 11}}}}
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetNavigationPlayerPosition() return player end
    function APR:GetCurrentStep()
        local route = self.RouteQuestStepList[self.ActiveRoute]
        if route then return route.steps[2], 2, route.steps end
    end
    function APR:GetCurrentRouteMapIDsAndName() return {11}, 11 end
    function APR:GetStepCoord(step) return step.Coord, step.Zone end
    function APR:GetPlayerMapPos(map, x, y)
        if fixture.maps[map] then return 1 - y / 1000, 1 - x / 1000 end
    end
    function APR:CheckNavigationZoneReady() return false end
    APR.taxiData = {CreateEdgeBuild = function() return {Step = function() return "ready", {} end, Cancel = noop} end}
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local createFrame, controller = CreateFrame
    function CreateFrame(...)
        controller = createFrame(...)
        return controller
    end
    dofile("APR-Core/features/navigation/Navigation.lua")
    CreateFrame = createFrame
    dofile("APR-Core/features/navigation/Preview.lua")
    dofile("APR-Core/features/navigation/Services.lua")
    local nav, services = APR.navigation, APR.Services
    local nativeWaypoint
    function C_Map.GetUserWaypoint() return nativeWaypoint end
    function WorldMapFrame:GetCanvas() return self end
    function WorldMapFrame:IsShown() return true end
    local mapMessage
    function APR:NewModule()
        return {RegisterMessage = function(_, _, callback) mapMessage = callback end}
    end
    LibStub:NewLibrary("HereBeDragons-Pins-2.0", 1)
    dofile("APR-Core/features/navigation/Map.lua")
    local map = APR.map
    map.RefreshGuidanceLines, map.QueueMapPins = noop, noop
    function APR:SendMessage(message)
        if message == "APR_MAP_UPDATE" then mapMessage() end
    end
    function map.eventFrame:UnregisterEvent(event) self.events[event] = nil end
    local function updateNativeWaypoint(x, y)
        nativeWaypoint = x and {uiMapID = mapID, position = {x = x, y = y}} or nil
        local frame = map.eventFrame
        assert(frame.events.USER_WAYPOINT_UPDATED)
        frame:OnEvent("USER_WAYPOINT_UPDATED")
    end

    local function register()
        data:SetWaypointClickHandler(function(target, source)
            assert(source == "minimap" or source == "worldmap")
            clicks = clicks + 1
            return services:StartWaypoint(target)
        end)
    end
    register()
    local function world(button, x, y) return WorldMapFrame:handler(button, x, y) end
    local function mini() mouseUp(Minimap, "LeftButton") end

    assert(not world("LeftButton", .6, .6) and clicks == 0)
    shift, ctrl = true, true
    assert(not world("LeftButton", .6, .6) and clicks == 0)
    ctrl, alt = false, true
    mini()
    assert(clicks == 0)
    alt = false
    assert(not world("RightButton", .6, .6) and not world("LeftButton", 1.1, .6) and clicks == 0)

    APR.routeValidationPending = true -- Preview is available while the planner waits.
    assert(world("LeftButton", .75, .5))
    local preview = APR.navigationPreview:GetPoints()
    assert(#preview == 1 and preview[1].kind == "map_waypoint" and preview[1].breakBefore)
    assert(preview[1].uiMapID == 21 and preview[1].Coord.x == 250 and preview[1].Coord.y == 500)
    APR.routeValidationPending = nil
    nav:Update()
    if profile == "forever" then
        local job, generation = assert(nav.search), nav.generation
        local adapter = APR.NavigationAdapter.frame
        for _ = 1, 10 do
            adapter.OnEvent(adapter, "QUEST_LOG_UPDATE")
            controller.OnEvent(controller, "QUEST_LOG_UPDATE")
            assert(nav._stepCheckTimer).callback()
            assert(nav.search == job and nav.generation == generation, "Journal refreshes keep the pin search in progress")
        end
    end
    drain()
    assert(nav:IsNavigating() and nav.queue[2].kind == "portal" and nav.queue[#nav.queue].to.x == 500,
        "The selected destination should use the real cross-world itinerary")

    if profile == "forever" then
        local generation = nav.generation
        controller.OnEvent(controller, "QUEST_TURNED_IN", 1)
        drain()
        assert(nav.generation > generation and nav:IsNavigating(), "Quest completion can change transport access")

        function APR:InvalidatePlayerZoneCache()
            self.navigationGeometryRevision = (self.navigationGeometryRevision or 0) + 1
            data:InvalidatePositionCache()
        end
        function C_Map.GetMapArtID() return 15 end
        generation = nav.generation
        controller.OnEvent(controller, "QUEST_LOG_UPDATE")
        local adapter = APR.NavigationAdapter.frame
        adapter.OnEvent(adapter, "QUEST_LOG_UPDATE")
        drain()
        assert(nav.generation > generation and nav:IsNavigating(), "Changed map art forces a fresh route")

        local provider = {HasMap = function() return true end, RequiresWalkingProof = function() return true end}
        function provider:CreatePathJob() return {Step = function() return "planning" end, Cancel = noop} end
        local walkingProvider, canWalk = data.GetWalkingProvider, data.CanWalk
        function data:GetWalkingProvider() return provider end
        function data:CanWalk(from, to) return from.instanceID == to.instanceID end
        assert(services:StartWaypoint(point(1, 12, 5000, 500)))
        assert(nav.search and not nav.localPathJob, "A distant map pin starts the full search without a local walking job")
        assert(services:StartWaypoint(point(1, 12, 650, 500)))
        assert(nav.localPathJob, "A nearby pin across a map boundary can still show early walking guidance")
        data.GetWalkingProvider, data.CanWalk = walkingProvider, canWalk

        services:Cancel()
        local stored = point(1, 12, 650, 500)
        local region = data:GetPositionRegion(stored)
        assert(region)
        stored.region = "retired-access-region"
        APRNavigationCharacterSettings.waypoint = { target = stored, profile = "forever" }
        services.waypointRestored = false
        assert(services:RestoreWaypoint() and services:GetStep().target.region == region,
            "Saved pins keep their coordinates and recover the current access region")
        assert(services:GetStep().target.x == stored.x and services:GetStep().target.y == stored.y)
        services:Cancel()
        drain()
    end

    mini()
    drain()
    local target = services:GetStep().target
    assert(target.uiMapID == 11 and target.x == 500 and math.abs(target.y - 450) < 0.0001 and target.z == nil)
    assert(nav:IsNavigating() and #nav.queue == 1 and nav:GetGuidanceTarget().y == target.y)
    preview = APR.navigationPreview:GetPoints()
    assert(#preview == 1 and preview[1].kind == "map_waypoint" and not preview[1].breakBefore,
        "The connected destination and cancellable waypoint share a pin")

    rotating, facing = true, math.pi / 2
    mini()
    drain()
    target = services:GetStep().target
    assert(math.abs(target.x - 550) < 0.0001 and math.abs(target.y - 500) < 0.0001)
    ignored = true
    mini()
    drain()
    assert(math.abs(services:GetStep().target.y - 450) < 0.0001)
    local accepted = clicks
    mouseX, mouseY = 380, 250
    mini()
    assert(clicks == accepted, "The corner outside a round minimap is excluded")
    shape = "SQUARE"
    mini()
    drain()
    assert(clicks == accepted + 1 and math.abs(services:GetStep().target.x - 590) < 0.0001)
    radius = nil
    mini()
    assert(clicks == accepted + 1, "Missing native geometry leaves the destination intact")

    APR.ActiveRoute = "guide"
    target = services:GetStep().target
    player.x, player.y = target.x, target.y
    nav:PollArrival()
    drain()
    assert(not services:GetStep() and APRData.player.guide == 2, "Arrival resumes the guide without advancing it")
    mapID = 11
    assert(world("LeftButton", .9, .9))
    updateNativeWaypoint(.8, .8)
    updateNativeWaypoint()
    drain()
    assert(services:GetStep(), "Removing an unrelated native marker leaves the detour active")

    updateNativeWaypoint(.9, .9)
    updateNativeWaypoint()
    updateNativeWaypoint(.9, .9)
    drain()
    assert(services:GetStep(), "Replacing the native marker in the same update leaves the detour active")

    local releaseWaypoints = data.ReleaseWaypoints
    function data:ReleaseWaypoints()
        updateNativeWaypoint()
    end
    nav:Cancel("position")
    data.ReleaseWaypoints = releaseWaypoints
    drain()
    assert(services:GetStep(), "Clearing the marker during APR navigation cleanup leaves the detour active")

    updateNativeWaypoint(.9, .9)
    updateNativeWaypoint()
    assert(world("LeftButton", .8, .9))
    drain()
    assert(services:GetStep(), "A pending removal cannot cancel a newly selected detour")

    updateNativeWaypoint(.8, .9)
    updateNativeWaypoint()
    local resumedStep
    function APR:UpdateStep() resumedStep = services:GetStep() or self:GetCurrentStep() end
    drain()
    assert(not services:GetStep() and not APRNavigationCharacterSettings.waypoint
        and not map.eventFrame.events.USER_WAYPOINT_UPDATED, "Removing the matching marker clears the saved detour")
    local guide, index = APR:GetCurrentStep()
    assert(APR.ActiveRoute == "guide" and APRData.player.guide == 2 and index == 2 and resumedStep == guide,
        "Native marker removal resumes the original guide at the same step")

    data:SetWaypointClickHandler(nil)
    assert(not world("LeftButton", .75, .5))
    register()
    APR.settings.profile.enableAddon = false
    assert(not world("LeftButton", .75, .5) and not services:GetStep())
end

Run("retail")
Run("forever")
