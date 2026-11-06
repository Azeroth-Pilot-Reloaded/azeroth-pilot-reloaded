-- An interior can expose world coordinates without any native UI map.
-- Invented identities exercise the library, host and controller on both clients.
local noop = function() end
for _, profile in ipairs({ "retail", "forever" }) do
    local f = dofile("tests/lua/navigation_fixture.lua")
    f.profile = profile
    f.player = { x = 30, y = 40, z = -5, instanceID = 73 }
    local nativeMap, nativeInfo
    local getMapInfo = C_Map.GetMapInfo
    C_Map.GetBestMapForUnit = function() return nativeMap end
    C_Map.GetMapInfo = function(id)
        if id == 83001 then return nativeInfo end
        return getMapInfo(id)
    end
    local mapToWorld, worldToMap = C_Map.GetWorldPosFromMapPos, C_Map.GetMapPosFromWorldPos
    C_Map.GetWorldPosFromMapPos = function(id, position)
        if id ~= 83001 then return mapToWorld(id, position) end
    end
    C_Map.GetMapPosFromWorldPos = function(instance, position, hint)
        if instance ~= 73 then return worldToMap(instance, position, hint) end
    end
    f.translations = setmetatable({}, { __index = function(_, key) return key end })
    local data = f:Load({
        config = { UnmappedAreas = {
            [83001] = { instanceID = 73, areaID = 84001 },
        } },
        connections = {
            {
                id = "invented-exit",
                kind = "passage",
                seconds = 5,
                from = { instanceID = 73, x = 130, y = 40 },
                to = { instanceID = 0, uiMapID = 2395, x = 500, y = 600 },
            },
        },
    })
    APR.Debug = noop
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/utils/NavigationZones.lua")
    dofile("APR-Core/utils/StepUtils.lua")
    local position = APR:GetNavigationPlayerPosition()
    assert(
        position and position.uiMapID == 83001 and position.instanceID == 73 and position.x == 30 and position.y == 40,
        "A verified mapless interior keeps its observed world coordinates"
    )
    assert(
        data.env.getCurrentMapID() == 83001 and data.env.getCharacter().mapID == 83001,
        "Transport requirements share the host's observed map identity"
    )
    local report = APR:GetZoneDetectionReport()
    assert(
        report.playerCurrent == 83001 and report.playerParent == 83001 and report.playerContinent == 0,
        "Zone detection shares the verified interior identity without inventing a continent"
    )
    local goal = data:NormalizeLocation({ uiMapID = 83001, x = 330, y = 440 })
    assert(goal and goal.instanceID == 73 and data:CanWalk(position, goal))
    assert(data:GetDisplayMapName(goal) == "Area 84001", "Mapless interiors use client-localized area names")
    assert(
        data:NormalizeLocation({ space = "map", uiMapID = 83001, x = 0.5, y = 0.5 }) == nil,
        "A world identity does not invent a normalized map projection"
    )
    assert(
        not data:CanWalk(position, { instanceID = 0, uiMapID = 2395, x = 30, y = 40 }),
        "Missing UI maps never erase an interior's entrance boundary"
    )

    local step = { Done = { 930001 }, Zone = 83001, Coord = { x = 440, y = 330 } }
    local steps, timers, rows = { step }, {}, {}
    APR.PlayerID, APR.ActiveRoute = "player", "invented-interior"
    APR.RouteQuestStepList = { [APR.ActiveRoute] = steps }
    APR.settings = { profile = { enableAddon = true } }
    APR.GAME_VERSIONS = { Forever = "forever" }
    APRData = { player = { [APR.ActiveRoute] = 1 } }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetCurrentStep() return step, 1, steps end
    function APR:GetCurrentRouteMapIDsAndName() return { 83001 }, 83001 end
    function APR:GetScenarioStepTarget() return nil end
    function APR:GetScenarioMapIDForStep() return nil end
    function APR:IsInScenarioStep() return false end
    function UnitIsDeadOrGhost() return false end
    function UnitOnTaxi() return false end
    function GetUnitSpeed() return 0, 5, 0 end
    function GetMoney() return 0 end
    APR.event, APR.SendMessage = { QueueStepRefresh = noop }, noop
    APR.Arrow = {
        SetArrowActive = function(self, active) self.Active = active end,
        SetCoord = function(self)
            self.Active, self.x, self.y = true, step.Coord.x, step.Coord.y
        end,
    }
    APR.currentStep = { questsList = rows, pendingRemoval = {}, questsExtraTextList = {} }
    function APR.currentStep:AddQuestSteps(key, text, id) rows[key .. "-" .. id] = { text = text } end
    function APR.currentStep:FlushPendingContainers()
        for key in pairs(self.pendingRemoval) do
            rows[key] = nil
        end
        self.pendingRemoval = {}
    end
    APR.taxiData = { BuildEdges = function() return {} end }
    C_Timer = {
        NewTimer = function(_, callback)
            local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
            timers[#timers + 1] = timer
            return timer
        end,
    }
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav = APR.navigation
    local function drain()
        local count = 0
        while #timers > 0 do
            local timer = table.remove(timers, 1)
            if not timer.cancelled then timer.callback() end
            count = count + 1
            assert(count < 200, "Synthetic navigation must finish with bounded work")
        end
    end
    nav:Update()
    drain()
    assert(
        nav:GetState() == "ready"
            and APR.IsInRouteZone
            and APR.Arrow.Active
            and APR.Arrow.x == 440
            and APR.Arrow.y == 330
            and next(rows) == nil,
        "A local mapless quest shows its authored arrow without a waiting row"
    )
    assert(APRData.player[APR.ActiveRoute] == 1, "Readiness never completes a quest")

    step.Coord = nil
    nav:ForceRefresh()
    nav:Update()
    drain()
    assert(
        nav:GetState() == "ready" and APR.IsInRouteZone and next(rows) == nil,
        "A coordinate-free interior instruction also avoids a waiting row"
    )

    step.Coord, step.Zone = { x = 600, y = 500 }, 2395
    nav:ForceRefresh()
    nav:Update()
    drain()
    assert(
        nav:IsNavigating()
            and nav:GetActiveStep().kind == "walk"
            and nav.queue[2].connectionID == profile .. ":invented-exit:forward",
        "Leaving a mapless interior still plans its mandatory crossing"
    )
    f.player.x = 130
    nav:PollArrival()
    assert(nav:GetActiveStep().connectionID == profile .. ":invented-exit:forward")
    nav:PollArrival() -- Observe the actual departure before changing worlds.
    nativeMap, f.player = 2395, { x = 500, y = 600, z = 0, instanceID = 0 }
    APR:InvalidatePlayerZoneCache()
    nav:PollArrival()
    nav:ForceRefresh()
    nav:Update()
    drain()
    assert(
        nav:GetState() == "ready"
            and APR.IsInRouteZone
            and APR:GetNavigationPlayerPosition().uiMapID == 2395
            and APRData.player[APR.ActiveRoute] == 1,
        "Native outdoor navigation recovers after leaving the interior"
    )

    nativeMap = nil
    f.player = { x = 30, y = 40, z = 0, instanceID = 74 }
    assert(
        APR:GetNavigationPlayerPosition() == nil,
        "An unknown mapless instance stays pending instead of borrowing the route's target map"
    )
    f.player = {}
    assert(APR:GetNavigationPlayerPosition() == nil, "Missing world data remains retryable")
    f.player = { x = 30, y = 40, instanceID = 73 }
    APR.CanAccessValue = function(_, value) return value ~= 73 end
    assert(APR:GetPlayerMapID() == nil, "An inaccessible world identity cannot select an interior")
    APR.CanAccessValue = nil
    nativeMap = 0
    assert(APR:GetPlayerMapID() == 83001, "Zero is not a usable native map")
    nativeMap = 2395
    assert(APR:GetPlayerMapID() == 2395, "Native map identity always takes priority over fallback data")
    f.player = { x = 500, y = 600, instanceID = 0 }
    assert(APR:GetPlayerMapID() == 2395, "Native map identity always takes priority")

    -- Drive an authored tram through its entrance, ride and arrival. Merely
    -- entering the shared interior must not skip the journey to its far end.
    nav:Cancel("transport_case")
    step = {
        Tram = true,
        Zone = 2395,
        Coord = { x = 200, y = 100 },
        ZoneStepTrigger = { mapID = 83001, x = 40, y = 330, Range = 10 },
    }
    steps[1], steps[2] = step, { PickUp = { 930002 }, Zone = 83001, Coord = { x = 40, y = 330 } }
    function APR:GetCurrentStep()
        local index = APRData.player[self.ActiveRoute]
        return steps[index], index, steps
    end
    APR.stepHandlers, APR.UpdateQuest, APR.UpdateStep = {}, noop, noop
    dofile("APR-Core/features/questing/StepTravelHandlers.lua")
    f.player, nativeMap = { x = 100, y = 200, z = 0, instanceID = 0 }, 2395
    APR:InvalidatePlayerZoneCache()
    nav:ForceRefresh()
    nav:Update()
    drain()
    APR.stepHandlers.Transport(step, false)
    assert(
        APRData.player[APR.ActiveRoute] == 1 and APR.transportArrivalTimer,
        "Standing at a tram entrance does not finish its authored journey"
    )

    nav:BeginWorldLoading("LOADING_SCREEN_ENABLED")
    nativeMap, f.player = nil, {}
    local loadingPoll = APR.transportArrivalTimer
    loadingPoll.cancelled = true -- This one-shot callback has now fired.
    loadingPoll.callback()
    assert(APRData.player[APR.ActiveRoute] == 1, "Missing observations during loading cannot prove arrival")
    f.player = { x = 30, y = 40, z = -5, instanceID = 73 }
    APR:InvalidatePlayerZoneCache()
    nav:EndWorldLoading("LOADING_SCREEN_DISABLED")
    -- Do not drain the transport's repeating arrival poll alongside planner jobs.
    APR.transportArrivalTimer:Cancel()
    APR.transportArrivalTimer = nil
    drain()
    local goal = nav:GetDestination(step)
    assert(
        goal and goal.uiMapID == 83001 and goal.instanceID == 73 and goal.x == 330 and goal.y == 40,
        "Inside the mapless tram navigation targets arrival instead of the outside entrance"
    )
    assert(
        nav:GetState() == "ready" and APR.IsInRouteZone,
        "Mapless tram travel does not show a waiting-data navigation error"
    )
    APR.stepHandlers.Transport(step, false)
    local entrancePoll = APR.transportArrivalTimer
    entrancePoll.callback()
    assert(
        APRData.player[APR.ActiveRoute] == 1,
        "Entering the tram at its departure end must preserve the travel instruction"
    )
    f.player.x = 320
    assert(not APR:IsZoneStepTriggerReached(step.ZoneStepTrigger), "The arrival radius remains strict at its boundary")
    f.player.x = 325
    -- Identical coordinates in a different unmapped world are not an arrival.
    f.player.instanceID = 74
    APR.transportArrivalTimer.callback()
    assert(APRData.player[APR.ActiveRoute] == 1)
    f.player.instanceID = 73
    APR.transportArrivalTimer.callback()
    assert(
        APRData.player[APR.ActiveRoute] == 2 and not APR.transportArrivalTimer,
        "Only actual arrival advances the authored transport to its next quest"
    )
    entrancePoll.callback()
    assert(APRData.player[APR.ActiveRoute] == 2, "A stale transport callback cannot skip the following quest")
end
print(
    "Unmapped navigation: local quests, mandatory exits, tram entrance/ride/arrival, loading and native recovery passed"
)
