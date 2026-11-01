-- Native standalone outdoor maps have no continent ancestor. Their own map
-- identity still establishes local access without connecting unrelated maps.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local originalMapInfo = C_Map.GetMapInfo
local function Run(profile, nativeMapType)
    fixture.profile = profile
    fixture.maps[81001] = { mapID = 81001, mapType = nativeMapType, parentMapID = 0 }
    fixture.maps[81002] = { mapID = 81002, mapType = 5, parentMapID = 81001 }
    fixture.maps[81003] = { mapID = 81003, mapType = 3, parentMapID = 0 }
    fixture.maps[81004] = { mapID = 81004, mapType = 5, parentMapID = 0 }
    fixture.maps[81005] = { mapID = 81005, mapType = 5, parentMapID = 81001 }
    fixture.maps[81006] = { mapID = 81006, mapType = 0, parentMapID = 0 }
    fixture.maps[81007] = { mapID = 81007, mapType = 3, parentMapID = 81008 }
    fixture.maps[81008] = { mapID = 81008, mapType = 5, parentMapID = 81007 }
    fixture.maps[81009] = nil
    fixture.maps[81010] = { mapID = 81010, mapType = 6, parentMapID = 0 }
    fixture.maps[81011] = { mapID = 81011, mapType = 6, parentMapID = 81015 }
    fixture.maps[81012] = { mapID = 81012, mapType = 5, parentMapID = 81011 }
    fixture.maps[81013] = { mapID = 81013, mapType = 6, parentMapID = 81015 }
    fixture.maps[81014] = { mapID = 81014, mapType = 5, parentMapID = 81011 }
    fixture.maps[81015] = { mapID = 81015, mapType = 2, parentMapID = 0 }
    fixture.maps[81016] = { mapID = 81016, mapType = 3, parentMapID = 81015 }
    fixture.maps[81018] = { mapID = 81018, mapType = 6, parentMapID = 81015 }
    fixture.maps[81019] = { mapID = 81019, mapType = 6, parentMapID = 81015 }
    C_Map.GetMapInfo = function(id)
        if id >= 81001 and id <= 81019 then return fixture.maps[id] end
        return originalMapInfo(id)
    end
    local data = fixture:Load({ config = { IsolatedAreas = {
        [81005] = "sealed-room", [81014] = "sealed-orphan-room",
    } }, entrances = {
        { id = "invented-interior", kind = "scenario", reviewStatus = "confirmed",
            interiorMapIDs = { 81018, 81019 },
            exterior = { instanceID = 73, uiMapID = 81016, x = 100, y = 0 } },
    } })
    local function point(mapID, overrides)
        local value = { instanceID = 73, uiMapID = mapID, x = 0, y = 0 }
        for key, field in pairs(overrides or {}) do value[key] = field end
        return value
    end
    local start = point(81001)
    local goal = point(81001, { x = 300, y = 400 })
    assert(data:GetPositionRegion(start), "A verified standalone native map supplies its own bounded walking region")
    assert(data:CanWalk(start, goal) and data:CanWalk(start, point(81002)),
        "Local points and unisolated descendants share standalone access")
    assert(data:GetPositionRegion(point(81004)) == "73:map:81004:outdoor",
        "A standalone native micro map also supplies local access")
    assert(not data:CanWalk(start, point(81003)) and not data:CanWalk(start, point(81004)),
        "Separate standalone maps cannot connect merely by sharing world coordinates")
    assert(not data:CanWalk(start, point(81001, { instanceID = 74 })))
    assert(not data:CanWalk(start, point(81001, { floor = "upper" })))
    assert(not data:CanWalk(start, point(81001, { accessKey = "private" })))
    assert(not data:CanWalk(start, point(81001, { noAutoconnect = true })))
    assert(not data:CanWalk(start, point(81005)), "An isolated descendant keeps its entrance boundary")
    assert(data:CanWalk(point(81005), point(81005, { x = 10 })),
        "Points inside the same isolated descendant remain connected")
    assert(data:GetPositionRegion(point(81006)) == nil, "A world map is not a local walking region")
    assert(data:GetPositionRegion(point(81007)) == nil, "Cyclic ancestry is not evidence of local access")
    assert(data:GetPositionRegion(point(81009)) == nil, "Missing map data remains unknown")
    fixture.maps[81009] = { mapID = 81009, mapType = 3, parentMapID = 0 }
    assert(data:GetPositionRegion(point(81009)) == "73:map:81009:outdoor",
        "A failed native lookup must be retryable when map data arrives")
    assert(data:GetPositionRegion(point(81010))
        and data:CanWalk(point(81010), point(81010, { x = 20 })),
        "A native Orphan root supports walking inside its own map")
    assert(data:CanWalk(point(81011), point(81012)), "A native child inherits its Orphan access region")
    assert(not data:CanWalk(point(81011), point(81016)),
        "An Orphan presentation parent does not grant walking access to that parent's outdoor world")
    assert(not data:CanWalk(point(81011), point(81013)) and not data:CanWalk(point(81010), point(81011)),
        "Different Orphan maps remain separate even in the same world or under the same parent")
    assert(not data:CanWalk(point(81011), point(81014))
        and data:CanWalk(point(81014), point(81014, { x = 20 })),
        "An isolated descendant retains its boundary inside an Orphan")
    assert(data:GetPositionRegion(point(81018)) == "73:instance:81018:interior"
        and data:CanWalk(point(81018), point(81019)),
        "Explicit entrance membership takes precedence over separate native Orphan identities")
    assert(not data:CanWalk(point(81018), point(81016)) and not data:CanWalk(point(81018), point(81011)),
        "An explicit interior group remains separate from its exterior and other Orphans")

    local search = data:CreateSearch({ start = start, goal = goal, edges = {}, walkSpeed = 5,
        canWalk = function(a, b) return data:CanWalk(a, b) end,
        walkingRegionFor = function(value) return data:GetPositionRegion(value) end })
    local status, result
    repeat status, result = search:Step(32) until status ~= "planning"
    assert(status == "ready" and #result.segments == 1 and result.segments[1].kind == "walk"
        and result.totalSeconds == 100, "Standalone local travel finds the direct 500-yard walk")

    -- Drive the real host and planner too: native root-map access must keep
    -- the authored arrow visible while shortcut comparison runs in slices.
    local noop, timers, rows, arrowHides = function() end, {}, {}, 0
    fixture.currentMap, fixture.player = 81001, start
    APR.Debug = noop
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/utils/NavigationZones.lua")
    local step = { Zone = 81001, Coord = { x = 400, y = 300, instanceID = 73 } }
    local steps = { step }
    APR.PlayerID, APR.ActiveRoute, APR.RouteQuestStepList = "player", "route", { route = steps }
    APR.settings, APR.GAME_VERSIONS = { profile = { enableAddon = true } }, { Forever = "forever" }
    APRData = { player = { route = 1 } }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetCurrentStep() return step, 1, steps end
    function APR:GetCurrentRouteMapIDsAndName() return { 81001 }, 81001 end
    function APR:GetStepCoord(value) return value.Coord, value.Zone end
    function APR:GetPreferredStepZone(value) return value.Zone end
    function UnitIsDeadOrGhost() return false end
    function UnitOnTaxi() return false end
    function GetUnitSpeed() return 0, 5, 0 end
    function GetMoney() return 0 end
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end }
    APR.currentStep = { AddQuestSteps = function(_, key, text) rows[key] = text or true end }
    APR.event, APR.SendMessage = { QueueStepRefresh = noop }, noop
    APR.Arrow = {
        SetArrowActive = function(self, active)
            self.Active = active
            if not active then arrowHides = arrowHides + 1 end
        end,
        SetCoord = function(self)
            self.x, self.y, self.Active = step.Coord.x, step.Coord.y, true
        end,
    }
    APR.taxiData = { BuildEdges = function() return {} end }
    dofile("APR-Core/features/questing/StepTransitions.lua")
    dofile("APR-Core/features/navigation/NavigationPlanner.lua")
    local createFrame, controller = CreateFrame
    function CreateFrame(...)
        controller = createFrame(...)
        return controller
    end
    dofile("APR-Core/features/navigation/Navigation.lua")
    CreateFrame = createFrame
    local nav, builds, createBuild = APR.navigation, 0, data.CreateEdgeBuild
    function data:CreateEdgeBuild(context)
        builds = builds + 1
        return createBuild(self, context)
    end
    nav:Update()
    assert(nav:GetState() == "ready" and nav.search and APR.IsInRouteZone and APR.Arrow.Active
        and APR.Arrow.x == 400 and APR.Arrow.y == 300 and next(rows) == nil,
        "Cold standalone guidance shows the objective immediately without a calculating or waiting row")
    local slices = 0
    while nav.search do
        local timer = table.remove(timers, 1)
        assert(timer, "The real planner must retain its scheduled continuation")
        if not timer.cancelled then timer.callback() end
        slices = slices + 1
        assert(slices < 100, "An empty catalogue with one direct walk must finish with bounded work")
    end
    assert(nav:GetState() == "ready" and nav.lastPlanning.status == "ready" and not nav:GetActiveStep()
        and builds == 1 and next(rows) == nil and APR.Arrow.Active
        and APR.Arrow.x == 400 and APR.Arrow.y == 300 and APRData.player.route == 1,
        "The completed direct journey keeps authored progress and never reports no path")
    local previousHides = arrowHides
    controller.OnEvent(controller, "QUEST_LOG_UPDATE")
    slices = 0
    while #timers > 0 do
        local timer = table.remove(timers, 1)
        if not timer.cancelled then timer.callback() end
        slices = slices + 1
        assert(slices < 100, "A native quest-log replan must finish with bounded work")
        assert(nav:GetState() == "ready" and APR.Arrow.Active and next(rows) == nil and arrowHides == previousHides,
            "Quest-log replanning cannot hide a confirmed standalone objective or add waiting/calculation rows")
    end
    assert(not nav.search and nav.lastPlanning.status == "ready" and builds == 2 and APRData.player.route == 1,
        "A native quest-log event completes one new comparison while retaining authored progress")
    local generation, completedBuilds, scheduled = nav.generation, builds, #timers
    for _ = 1, 50 do nav:Update() end
    assert(builds == completedBuilds and nav.generation == generation and #timers == scheduled and not nav.search,
        "Unchanged standalone objectives must not restart planning after publication")
end
for _, profile in ipairs({ "retail", "forever" }) do
    for _, nativeMapType in ipairs({ 3, 5, 6 }) do Run(profile, nativeMapType) end
end
print("Standalone geography: native Zone/Micro/Orphan access, boundaries and stable host guidance passed")
