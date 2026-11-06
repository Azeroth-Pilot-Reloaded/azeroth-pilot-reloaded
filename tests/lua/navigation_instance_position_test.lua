-- World-only interiors and coordinate-restricted instances are different
-- observations. Neither can borrow coordinates from the guide or an entrance.
local noop = function() end
for _, profile in ipairs({ "retail", "forever" }) do
    local f = dofile("tests/lua/navigation_fixture.lua")
    f.profile = profile
    local nativeMap, observedID, observedKind = nil, 73, "none"
    local instanceName = "Invented interior"
    function GetInstanceInfo()
        return instanceName, observedKind, 0, "", 5, 0, false, observedID
    end
    C_Map.GetBestMapForUnit = function() return nativeMap end
    local mapToWorld, worldToMap = C_Map.GetWorldPosFromMapPos, C_Map.GetMapPosFromWorldPos
    C_Map.GetWorldPosFromMapPos = function(id, point)
        if id == 83002 then return 74, { x = point.x * 1000, y = point.y * 1000 } end
        return mapToWorld(id, point)
    end
    C_Map.GetMapPosFromWorldPos = function(id, point, hint)
        if id == 0 then return worldToMap(id, point, hint) end
    end
    f.maps[83002] = { mapID = 83002, mapType = 4, parentMapID = 0, name = "Invented dungeon map" }
    f.translations = setmetatable(
        { LEAVE_INSTANCE = "Leave the instance: %s" },
        { __index = function(_, key) return key end }
    )
    local data = f:Load({
        config = { UnmappedInstances = { [73] = true, [75] = true } },
        entrances = {
            {
                id = "invented-dungeon",
                kind = "dungeon",
                reviewStatus = "confirmed",
                instanceID = 74,
                interiorMapIDs = { 83002 },
                exterior = { instanceID = 0, uiMapID = 2395, x = 500, y = 600 },
            },
        },
        connections = {
            {
                id = "invented-world-only-exit",
                kind = "passage",
                seconds = 5,
                from = { instanceID = 73, x = 130, y = 40 },
                to = { instanceID = 0, uiMapID = 2395, x = 500, y = 600 },
            },
        },
    })
    f.player = { x = 30, y = 40, z = -5, instanceID = 73 }
    APR.Debug = noop
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/utils/NavigationZones.lua")
    dofile("APR-Core/utils/StepUtils.lua")
    local position = APR:GetNavigationPlayerPosition()
    assert(position and position.uiMapID == nil and position.instanceID == 73 and position.x == 30 and position.y == 40)
    assert(APR:GetPlayerMapID() == nil, "A world identity is never a fabricated UI map ID")
    local localGoal = data:NormalizeLocation({ instanceID = 73, x = 200, y = 40 })
    assert(localGoal.uiMapID == nil and data:CanWalk(position, localGoal))
    assert(not data:CanWalk(position, { instanceID = 75, x = 200, y = 40 }))
    assert(not data:CanWalk(position, { instanceID = 0, uiMapID = 2395, x = 200, y = 40 }))
    assert(not data:CanWalk(position, { instanceID = 73, x = 200, y = 40, accessKey = "locked" }))
    local report = APR:GetZoneDetectionReport()
    assert(
        report.worldInstanceID == 73
            and report.instanceName == instanceName
            and report.mapSource == "unavailable"
            and report.coordinatesAvailable == true
    )

    local step = { PickUp = { 930011 }, Zone = 2395, Coord = { x = 600, y = 500 } }
    local steps, timers, rows = { step }, {}, {}
    APR.PlayerID, APR.ActiveRoute = "player", "invented-guide"
    APR.RouteQuestStepList = { [APR.ActiveRoute] = steps }
    APR.settings = { profile = { enableAddon = true } }
    APR.GAME_VERSIONS = { Forever = "forever" }
    APRData = { player = { [APR.ActiveRoute] = 1 } }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetCurrentStep() return step, 1, steps end
    function APR:GetCurrentRouteMapIDsAndName() return { 2395 }, 2395 end
    function APR:GetScenarioStepTarget() return nil end
    function APR:GetScenarioMapIDForStep() return nil end
    function APR:IsInScenarioStep() return false end
    function UnitIsDeadOrGhost() return false end
    function UnitOnTaxi() return false end
    function GetUnitSpeed() return 0, 5, 0 end
    function GetMoney() return 0 end
    APR.event, APR.SendMessage = { QueueStepRefresh = noop }, noop
    APR.Arrow = { SetArrowActive = function(self, active) self.Active = active end, SetCoord = noop }
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
    local createFrame, navFrame = CreateFrame
    CreateFrame = function(...)
        navFrame = createFrame(...)
        return navFrame
    end
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav = APR.navigation
    local function drain()
        local count = 0
        while #timers > 0 do
            local timer = table.remove(timers, 1)
            if not timer.cancelled then timer.callback() end
            count = count + 1
            assert(count < 200, "Controlled navigation has bounded work")
        end
    end
    local function update()
        APR:InvalidatePlayerZoneCache()
        nav:ForceRefresh()
        nav:Update()
        drain()
    end
    update()
    assert(
        nav:IsNavigating() and nav.queue[2].connectionID == profile .. ":invented-world-only-exit:forward",
        "A world-only interior guides through its declared exit"
    )
    assert(
        nav.queue[1].to.x == 130 and nav.queue[1].to.y == 40,
        "Exit guidance uses the recorded doorway, not the target city's coordinates"
    )
    f.player.x = 130
    nav:PollArrival()
    nav:PollArrival()
    nativeMap, observedID, f.player = 2395, 0, { x = 500, y = 600, instanceID = 0 }
    nav:PollArrival()
    update()
    assert(nav:GetState() == "ready" and APR.IsInRouteZone, "Outdoor navigation resumes after crossing the exit")

    -- No coordinate API result can be replaced with an entrance landing.
    nativeMap, observedID, observedKind, f.player = nil, 74, "party", {}
    update()
    report = APR:GetZoneDetectionReport()
    assert(report.worldInstanceID == 74 and report.instanceType == "party" and report.coordinatesAvailable == false)
    assert(APR:GetNavigationPlayerPosition() == nil and APR:GetPlayerMapID() == nil)
    assert(nav:GetState() == "instance" and nav.reason == "coordinates_unavailable" and not APR.IsInRouteZone)
    assert(
        nav.queue[1] == nil and nav.search == nil and nav.start == nil,
        "A known but unpositioned instance cannot start a fabricated route"
    )
    assert(
        rows["01_NAVIGATION_PATH-0"].text == "Leave the instance: Invented interior",
        "The localized placeholder receives the instance name without appended parentheses"
    )
    f.translations.LEAVE_INSTANCE = "Quitter l'instance : %s"
    instanceName = "Intérieur inventé"
    update()
    assert(rows["01_NAVIGATION_PATH-0"].text == "Quitter l'instance : Intérieur inventé")
    for _, missing in ipairs({ false, "" }) do
        instanceName = missing or nil
        update()
        assert(
            rows["01_NAVIGATION_PATH-0"].text == "Quitter l'instance : Unknown",
            "A missing instance name still consumes the localized placeholder"
        )
    end
    f.translations.LEAVE_INSTANCE, instanceName = "Leave the instance: %s", "Invented interior"
    update()
    assert(APRData.player[APR.ActiveRoute] == 1, "An exit instruction cannot complete an authored objective")
    local generation = nav.generation
    for _ = 1, 20 do
        navFrame.OnUpdate(navFrame, 0.5)
        drain()
    end
    assert(nav.generation == generation, "Stable coordinate restrictions do not replan forever")

    for _, kind in ipairs({ "party", "raid", "scenario", "pvp", "arena", "invented_instance_type" }) do
        observedKind = kind
        nativeMap, f.player = nil, {}
        step.Zone, step.Coord = 2395, { x = 600, y = 500 }
        update()
        local observed = APR:GetNavigationPlayerContext()
        assert(
            observed.isInstance and observed.instanceType == kind and not observed.coordinatesAvailable,
            "Every non-outdoor instance type retains its public identity on " .. profile .. ": " .. kind
        )
        assert(
            nav:GetState() == "instance" and not APR.IsInRouteZone and not nav.search and #nav.queue == 0,
            "A restricted exterior objective cannot plan an invented position: " .. kind
        )
        assert(
            rows["01_NAVIGATION_PATH-0"].text == "Leave the instance: Invented interior",
            "Every instance kind formats its exit name without placeholders or parentheses: " .. kind
        )
        local stable = nav.generation
        for _ = 1, 3 do
            navFrame.OnUpdate(navFrame, 0.5)
            drain()
        end
        assert(nav.generation == stable, "A restricted instance does not continually replan: " .. kind)

        nativeMap, step.Zone, step.Coord = 83002, 83002, { x = 40, y = 330 }
        update()
        assert(
            nav:GetState() == "instance" and APR.IsInRouteZone and next(rows) == nil,
            "Local objectives remain visible in every instance kind: " .. kind
        )
        assert(APRData.player[APR.ActiveRoute] == 1, "Instance identity alone never completes a quest")

        -- A normal outdoor observation must recover without another forced
        -- refresh or loading event, even after a mapless/restricted visit.
        nativeMap, observedID, observedKind = 2395, 0, "none"
        f.player = { x = 500, y = 600, instanceID = 0 }
        step.Zone, step.Coord = 2395, { x = 600, y = 500 }
        navFrame.OnUpdate(navFrame, 0.5)
        drain()
        assert(
            nav:GetState() == "ready" and APR.IsInRouteZone and not nav.instanceContext,
            "Outdoor navigation recovers after every instance kind: " .. kind
        )
        observedID = 74
    end
    observedKind, nativeMap = "party", 83002
    f.player = {}
    step.Zone, step.Coord = 83002, { x = 40, y = 330 }
    update()
    assert(
        nav:GetState() == "instance" and APR.IsInRouteZone and next(rows) == nil,
        "Local dungeon objectives stay visible without an unnecessary exit or loading message"
    )
    assert(APRData.player[APR.ActiveRoute] == 1)

    -- Coordinates can become available without another loading event.
    f.player = { x = 30, y = 40, instanceID = 74 }
    navFrame.OnUpdate(navFrame, 0.5)
    drain()
    assert(nav:GetState() == "ready" and APR.IsInRouteZone)
    f.player, nativeMap = {}, nil
    step.Zone, step.Coord = 2395, { x = 600, y = 500 }
    update()
    nav:BeginWorldLoading("LOADING_SCREEN_ENABLED")
    observedID, observedKind = nil, nil
    nav:Update()
    assert(nav.worldLoading, "Incomplete loading observations never prove an exit")
    nativeMap, observedID, observedKind, f.player = 2395, 0, "none", { x = 500, y = 600, instanceID = 0 }
    nav:EndWorldLoading("LOADING_SCREEN_DISABLED")
    drain()
    assert(nav:GetState() == "ready" and APR.IsInRouteZone and not nav.instanceContext)

    nativeMap, f.player, observedID, observedKind = nil, {}, nil, "party"
    assert(APR:GetNavigationPlayerContext() == nil, "A missing instance ID stays genuinely pending")
    observedID = 74
    APR.CanAccessValue = function(_, value) return value ~= 74 end
    assert(APR:GetNavigationPlayerContext() == nil, "Unreadable instance identities are never used")
    APR.CanAccessValue = nil
    observedID, observedKind, f.player = 74, "party", { x = 10, y = 20, instanceID = 0 }
    local changed = APR:GetNavigationPlayerContext()
    assert(
        changed.instanceID == 0 and not changed.isInstance and not changed.instanceName,
        "Late instance metadata cannot relabel a fresh outdoor position"
    )
    observedID, observedKind = 0, "none"
    changed = APR:GetNavigationPlayerContext()
    assert(not changed.isInstance, "Outdoor identity never becomes an instance on either client")
    observedKind = ""
    assert(not APR:GetNavigationPlayerContext().isInstance, "An empty instance type is not evidence of an interior")
    GetInstanceInfo = nil
end
print(
    "Instance position: world-only exits, restricted local/exterior objectives, stable work, loading and recovery passed"
)
