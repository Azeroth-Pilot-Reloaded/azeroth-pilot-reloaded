-- An invented journey drives real APR navigation, adapters and transport jobs
-- through access changes, travel events, loading and temporary instance routes.
local function Run(profile)
    local fixture = dofile("tests/lua/navigation_fixture.lua")
    fixture.profile = profile
    local function point(world, map, x) return { space = "world", instanceID = world, uiMapID = map, x = x, y = 0 } end
    for _, map in ipairs({ 101, 102, 201, 301 }) do
        fixture.maps[map] = { mapID = map, parentMapID = map < 200 and 12 or 13, mapType = map == 301 and 4 or 3 }
    end
    local state = { access = false, timers = {}, speed = 10, instance = false, kind = "none", instanceID = 0 }
    C_Timer = { NewTimer = function(delay, callback)
        local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        state.timers[#state.timers + 1] = timer
        return timer
    end, NewTicker = function() return { Cancel = function() end } end }
    C_QuestLog.IsQuestFlaggedCompleted = function(id) return id ~= 44 or state.access end
    C_Map.GetMapArtID = function() return state.art or 1 end
    local data = fixture:Load({ config = { actionLoadingSeconds = 5, MapRequirements = { [201] = { quest = 44 } } },
        connections = {
            { id = "crossing", kind = "portal", seconds = 5, from = point(1, 102, 6000), to = point(2, 201, 0) },
            { id = "personal", kind = "spell", from = { dynamic = "player" }, to = point(2, 201, 100),
                actions = { { type = "spell", id = 77 } } },
        } })
    data.env.getActionCastSeconds = function() return 2 end
    local noop = function() end
    function UnitIsDeadOrGhost() return state.dead end
    function UnitOnTaxi() return state.onTaxi end
    function InCombatLockdown() return state.combat end
    function IsFlyableArea() return false end
    function IsInInstance() return state.instance, state.kind end
    function GetInstanceInfo() return "Synthetic instance", state.kind, 1, "Normal", 5, false, false, state.instanceID end
    function GetUnitSpeed() return 0, state.speed, 0 end
    function GetMoney() return 100 end
    APR.PlayerID, APR.ActiveRoute = "journey-player", "journey"
    APR.settings, APR.GAME_VERSIONS = { profile = { enableAddon = true } }, { Forever = "forever" }
    APRData, APRCustomPath = { [APR.PlayerID] = { journey = 1 } }, { [APR.PlayerID] = { "journey" } }
    local destination = { Zone = 201, Coord = { x = 0, y = 500, mapID = 201, instanceID = 2 } }
    APR.RouteQuestStepList = { journey = { label = "Invented journey", steps = { destination } },
        delve = { label = "Invented delve", temporary = true, delve = {}, scenarios = {
            { scenarioID = 9001, steps = { { Coord = { x = 0, y = 500, mapID = 201, instanceID = 2 } } } },
        } } }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetRouteData(key) return self.RouteQuestStepList[key] end
    function APR:GetRouteSteps(key)
        local route = self:GetRouteData(key)
        return route and (route.steps or route.scenarios[1].steps) or {}
    end
    function APR:GetCurrentStep()
        local steps = self:GetRouteSteps(self.ActiveRoute)
        local index = APRData[self.PlayerID][self.ActiveRoute]
        return steps[index], index, steps
    end
    function APR:GetCurrentRouteMapIDsAndName() return { 201 }, 201, self.ActiveRoute end
    function APR:GetStepCoord(step) return step.Coord, step.Zone end
    function APR:GetPreferredStepZone(step) return step.Zone end
    function APR:GetNavigationPlayerPosition()
        if state.positionMissing then return nil end
        return data:NormalizeLocation(point(fixture.player.instanceID, fixture.currentMap, fixture.player.x))
    end
    function APR:GetSettingsProfile() return self.settings.profile end
    function APR:GetRouteActionUsability(kind, id)
        if not fixture.spells[id] then return false, "missing" end
        if state.combat then return false, "restricted" end
        if state.cooldown then return false, "cooldown" end
        return true
    end
    function APR:CheckNavigationZoneReady(goal, options)
        local start = options.playerPosition
        return data:CanWalk(start, goal) == true and math.abs(start.x - goal.x) <= options.threshold
    end
    function APR:UpdateStep() state.refreshes = (state.refreshes or 0) + 1 end
    function APR:UpdateMapId() if self.navigation then self.navigation:RequestUpdate() end end
    function APR:GetMapInfoCached(id) return data:GetMapAncestryInfo(id) end
    function APR:InvalidatePlayerZoneCache(geometry)
        if geometry then
            self.navigationGeometryRevision = (self.navigationGeometryRevision or 0) + 1
            data:InvalidatePositionCache()
        end
    end
    function APR:InvalidateEffectiveRouteStepsCache() end
    function APR:GetRawStepCount(key) return #self:GetRouteSteps(key) end
    function APR:GetTotalSteps(key) return #self:GetRouteSteps(key) end
    APR.currentStep = { pendingRemoval = {}, questsList = {}, questsExtraTextList = {},
        AddQuestSteps = noop, AddQuestDivider = noop, AddStepButton = function()
            assert(not state.combat, "Combat cannot publish executable personal travel controls")
        end }
    APR.Arrow, APR.event, APR.SendMessage = { SetCoord = noop, SetArrowActive = noop }, { QueueStepRefresh = noop }, noop
    local positions = { [1] = point(1, 101, 100), [2] = point(1, 102, 5000) }
    local paths = { { fromNodeID = 1, toNodeID = 2, durationSeconds = 20, basePriceCopper = 20 } }
    LibTaxiData_API = {
        GetSource = function() return { profile = profile, build = "synthetic", paths = { fingerprint = "trip" } } end,
        GetAllPaths = function() return paths end,
        GetNodeWorldPosition = function(id) return positions[id] end,
        GetNodeName = function(id) return "Invented flight " .. id end,
        IsNodeAvailable = function() return true end,
    }
    function APR:HasTaxiNode(id) return id == 1 or id == 2 end
    dofile("APR-Core/features/navigation/NavigationTaxi.lua")
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/questing/DelveRoutes.lua")
    dofile("APR-Core/utils/DungeonUtils.lua")
    function APR:GetCurrentDelveContext() return state.delveContext end
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local createFrame, controller = CreateFrame
    function CreateFrame(...) controller = createFrame(...); return controller end
    dofile("APR-Core/features/navigation/Navigation.lua")
    CreateFrame = createFrame
    local nav, builds, originalBuild = APR.navigation, 0, data.CreateEdgeBuild
    function data:CreateEdgeBuild(context) builds = builds + 1; return originalBuild(self, context) end
    local function move(world, map, x)
        fixture.player, fixture.currentMap = { x = x, y = 0, z = 0, instanceID = world }, map
    end
    local function emit(event, ...)
        if APR.NavigationAdapter.frame.events[event] then APR.NavigationAdapter.frame:OnEvent(event, ...) end
        if controller.events[event] then controller:OnEvent(event, ...) end
    end
    local function settle()
        local iterations = 0
        while #state.timers > 0 do
            local timer = table.remove(state.timers, 1)
            if not timer.cancelled then timer.callback() end
            iterations = iterations + 1; assert(iterations < 2000, "The small invented journey must settle")
        end
        assert(not nav.search)
    end
    local function plan() nav:ForceRefresh("fixture"); nav:Update(); settle() end
    move(1, 101, 0)
    plan()
    assert(nav.state == "no_path" and not nav:IsNavigating(), "Closed destination access rejects both physical and personal travel")
    state.access = true
    emit("QUEST_LOG_UPDATE"); settle()
    assert(nav:IsNavigating() and #nav.queue == 5 and math.abs(nav.totalSeconds - 200) < 0.001,
        "The independent 10+35+100+5+50 second itinerary beats walking to the distant portal")
    assert(nav.queue[2].kind == "taxi" and nav.queue[4].kind == "portal")
    move(3, 401, 0); emit("PLAYER_ENTERING_WORLD"); settle()
    assert(nav.state == "no_path", "A disconnected world cannot borrow another world's physical departure points")
    move(1, 101, 0); emit("PLAYER_ENTERING_WORLD"); settle()
    assert(nav:IsNavigating() and nav.queue[2].kind == "taxi")
    local staticPositions, batchBuilds = data.positions, builds
    for _ = 1, 20 do emit("QUEST_LOG_UPDATE") end
    settle()
    assert(data.positions == staticPositions and builds == batchBuilds + 1,
        "A native quest burst coalesces one fresh character graph while retaining static projections")
    state.art = 2
    emit("QUEST_LOG_UPDATE"); settle()
    assert(data.positions ~= staticPositions and nav:IsNavigating(),
        "Changed native map artwork invalidates geometry before republishing a usable journey")
    local queue, before = nav.queue, builds
    nav:Update(); nav:Update()
    assert(nav.queue == queue and builds == before, "An unchanged observation cannot rebuild its catalogue")
    move(1, 101, 50); fixture.time = fixture.time + 6
    controller:OnUpdate(0.5); settle()
    assert(builds == before, "Sub-threshold movement does not invalidate the transport graph")
    move(1, 101, 170)
    controller:OnUpdate(0.5); settle()
    assert(builds > before, "Meaningful displacement eventually reevaluates complete travel times")
    move(1, 101, 100); nav:PollArrival()
    assert(nav:GetActiveStep().kind == "taxi")
    move(1, 102, 5000); nav:PollArrival()
    assert(nav:GetActiveStep().kind == "taxi", "Proximity alone cannot complete an unboarded taxi")
    move(1, 101, 100); state.onTaxi = true; nav:PollArrival()
    move(1, 102, 5000); state.onTaxi = false; nav:PollArrival()
    assert(nav:GetActiveStep().kind == "walk" and APRData[APR.PlayerID].journey == 1,
        "Manual native boarding is departure evidence even without a preceding off-taxi poll")
    move(1, 102, 6000); nav:PollArrival(); nav:PollArrival()
    assert(nav:GetActiveStep().kind == "portal")
    queue = nav.queue
    emit("PLAYER_LEAVING_WORLD"); emit("LOADING_SCREEN_ENABLED")
    move(2, 201, 0)
    emit("PLAYER_ENTERING_WORLD"); emit("LOADING_SCREEN_DISABLED"); settle()
    assert(nav.queue == queue and nav:GetActiveStep().kind == "walk",
        "A physical portal preserves the remaining precomputed trip through native world events")
    move(2, 201, 500); nav:PollArrival()
    assert(nav.state == "ready" and APRData[APR.PlayerID].journey == 1)
    move(1, 101, 0); plan()
    state.access = false
    emit("QUEST_LOG_UPDATE"); settle()
    assert(not nav:IsNavigating(), "A closed future gate cannot retain an otherwise valid taxi itinerary")
    state.access, fixture.spells[77], state.combat = true, true, true
    emit("SPELLS_CHANGED"); settle()
    assert(not nav:GetActiveStep().action, "A restricted personal action cannot be offered during combat")
    state.combat = false
    emit("SPELLS_CHANGED"); settle()
    assert(nav:GetActiveStep().kind == "spell" and nav:GetActiveStep().action.data == 77,
        "Leaving combat permits the available 7-second personal crossing")
    queue, before = nav.queue, builds
    emit("UNIT_SPELLCAST_START", "player", "cast", 77)
    emit("PLAYER_LEAVING_WORLD"); emit("LOADING_SCREEN_ENABLED")
    state.positionMissing, state.cooldown = true, true
    fixture.time = fixture.time + 90
    emit("QUEST_LOG_UPDATE"); emit("BAG_UPDATE_DELAYED")
    nav:Update(); controller:OnUpdate(90)
    assert(nav.worldLoading and nav.queue == queue and builds == before,
        "Unavailable observations and consumed cooldowns cannot erase a published trip during long loading")
    state.positionMissing = false
    move(2, 13, 100)
    emit("LOADING_SCREEN_DISABLED"); emit("PLAYER_ENTERING_WORLD"); settle()
    assert(nav.queue == queue and nav:GetActiveStep().kind == "walk" and builds == before,
        "Matching world/coordinates and real walking access validate the temporary parent-map arrival")
    move(2, 201, 100); emit("ZONE_CHANGED_NEW_AREA"); settle()
    move(2, 201, 500); nav:PollArrival()
    assert(nav.state == "ready" and APRData[APR.PlayerID].journey == 1,
        "Finishing navigation never advances an authored quest cursor")
    state.cooldown = false
    move(1, 101, 0); nav:ForceRefresh(); nav:Update()
    local stale = nav._searchTimer
    APR.settings.profile.enableAddon = false; nav:Update()
    if stale then stale.callback() end
    settle()
    assert(not nav:IsNavigating() and not nav.search, "Disabled navigation rejects callbacks from an unfinished candidate")
    APR.settings.profile.enableAddon = true
    plan()
    state.dead = true; nav:Update()
    assert(not nav:IsNavigating() and APRData[APR.PlayerID].journey == 1)
    state.dead = false
    APR.DungeonData = { [profile] = {
        party = { instanceID = 888, instanceType = "party" }, raid = { instanceID = 889, instanceType = "raid" },
        scenario = { instanceID = 890, instanceType = "scenario" },
    } }
    for _, kind in ipairs({ "party", "raid", "scenario" }) do
        state.instance, state.kind, state.instanceID = true, kind, 777
        destination.Dungeon = kind
        move(777, 301, 0)
        before = builds; plan()
        assert(not APR:IsInDungeonStepContext(destination) and builds > before,
            "An unrelated native " .. kind .. " identity cannot suppress navigation to the actual objective")
        state.instance, state.kind, state.instanceID = true, kind, APR.DungeonData[profile][kind].instanceID
        destination.Dungeon = kind
        move(state.instanceID, 301, 0)
        before = builds; plan()
        assert(nav.state == "ready" and builds == before,
            "A matching native " .. kind .. " context cannot launch global transport planning")
    end
    destination.Dungeon, state.instance = nil, false
    state.instance, state.kind, state.instanceID, state.delveContext = true, "scenario", 891, { scenarioID = 9001, mapID = 301 }
    assert(APR:ActivateTemporaryRoute("delve", { kind = "delve", previousRouteKey = "journey", mapID = 301,
        scenarioID = 9001, sessionKey = "invented-session" }))
    before = builds; settle(); nav:Update()
    assert(APR.ActiveRoute == "delve" and APR:IsInDelveRouteContext("delve") and builds == before,
        "A real temporary delve lifecycle uses its scenario block instead of replanning to outdoor coordinates")
    assert(APR:ClearTemporaryRoute({ completed = true }))
    state.delveContext, state.instance, state.kind, state.instanceID = nil, false, "none", 0
    move(2, 201, 500); settle()
    assert(APR.ActiveRoute == "journey" and APRData[APR.PlayerID].journey == 1
        and not APRData[APR.PlayerID].TemporaryRouteState,
        "Temporary completion restores the original route without inventing quest progress")
    nav:Cancel("cleared")
end

Run("retail")
Run("forever")
print("Navigation journey integration: access, movement, taxi, combat, loading, cancellation and native instance/temporary contexts passed")
