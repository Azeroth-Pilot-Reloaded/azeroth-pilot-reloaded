-- Real entrance catalogue -> APR compatibility view -> route target/controller.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.translations = { ENTER_IN = "Enter %s %s", COMPLETE_SOMETHING = "Complete %s %s",
    DELVE = "delve", DUNGEON = "dungeon", RAID = "raid", SCENARIO = "scenario" }
for _, record in ipairs({ { 2274, 947, 2 }, { 2248, 2274, 3 }, { 2269, 2248, 4 },
    { 2215, 2274, 3 }, { 2300, 2215, 4 }, { 2301, 2215, 4 },
    { 129, 114, 4 }, { 114, 113, 3 }, { 113, 947, 2 }, { 306, 22, 4 }, { 22, 13, 3 },
    { 889, 831, 4 }, { 890, 831, 4 }, { 831, 13, 3 },
    { 900001, 2269, 5 }, { 900002, 900001, 5 } }) do
    fixture.maps[record[1]] = { mapID = record[1], parentMapID = record[2], mapType = record[3], name = "Map " .. record[1] }
end
local missingProjection = {}
C_Map.GetWorldPosFromMapPos = function(mapID, pos)
    if missingProjection[mapID] then return nil end
    local world = mapID == 2248 and 2552 or mapID == 2215 and 2601 or mapID == 2269 and 90001 or 0
    return world, { x = pos.x * 10000, y = pos.y * 10000 }
end
fixture.currentMap, fixture.player = 2248, { x = 929.3, y = -1631.8, z = 0, instanceID = 2552, uiMapID = 2248 }
local completed, active, ready, questReads = {}, {}, {}, 0
C_QuestLog.IsQuestFlaggedCompleted = function(id)
    assert(type(id) == "number", "Map-only visits must never call quest APIs with a nil quest ID")
    questReads = questReads + 1
    return completed[id]
end
C_QuestLog.IsOnQuest = function(id)
    assert(type(id) == "number")
    questReads = questReads + 1
    return active[id]
end
local data = fixture:Load() -- This deliberately resets APR before the bridge loads.
local function noop() end
function tContains(values, expected)
    for _, value in ipairs(values or {}) do if value == expected then return true end end
    return false
end
function APR:Contains(values, expected) return tContains(values, expected) end
function APR:NewModule() return {} end
function APR:GetRouteData(key) return self.RouteQuestStepList[key] end
function APR:GetGameVersion() return "retail" end
function APR:GetMapInfoCached(mapID) return C_Map.GetMapInfo(mapID) end
function APR:GetContinent(mapID)
    local seen = {}
    mapID = mapID or fixture.currentMap
    while mapID and mapID ~= 0 and not seen[mapID] do
        seen[mapID] = true
        local info = C_Map.GetMapInfo(mapID)
        if info.mapType == 2 then return mapID end
        mapID = info.parentMapID
    end
end
function APR:GetPlayerParentMapID() return fixture.currentMap end
function APR:GetCurrentRouteMapIDsAndName() return { 2248 }, 2248 end
function APR:IsQuestReadyForTurnIn(id)
    assert(type(id) == "number")
    questReads = questReads + 1
    return ready[id] == true
end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
C_Timer = { NewTimer = function(_, callback)
    return { callback = callback, Cancel = function(self) self.cancelled = true end }
end }
UNKNOWN, LEAVE_ZONE = "Unknown", "Leave %s"
APR.PlayerID, APR.ActiveRoute, APR.ActiveQuests = "p", "r", {}
APR.GAME_VERSIONS, APR.QUEST_STATUS = { Forever = "forever" }, { COMPLETE = "complete" }
APR.settings, APR.stepHandlers = { profile = { enableAddon = true } }, {}
APR.currentStep = { AddQuestSteps = noop, AddQuestDivider = noop }
APR.Arrow, APR.event = { SetCoord = noop, SetArrowActive = noop }, { QueueStepRefresh = noop }
APR.SendMessage, APR.UpdateStep, APR.UpdateQuest = noop, noop, noop
APRData, APRScenarioMapIDCompleted = { p = { r = 1 } }, { p = { 2269, 129, 2300 } }
APR.RouteQuestStepList = {}
dofile("APR-Core/integrations/NavigationEntrances.lua")
dofile("APR-Core/features/questing/DelveRoutes.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
function APR:GetRouteSteps(key) return self.RouteQuestStepList[key].steps end
local function selectStep(step)
    nav:Cancel("test_case")
    APR.RouteQuestStepList.r = { mapID = 2248, steps = { step, { Note = "Next" } } }
    APRData.p.r, APR.runtimeRouteStep = 1, nil
    APR.stepRevision = (APR.stepRevision or 0) + 1
    return APR:GetCurrentStep()
end
local function outside()
    fixture.currentMap = 2248
    fixture.player = { x = 929.3, y = -1631.8, z = 0, instanceID = 2552, uiMapID = 2248 }
end
local function near(actual, expected)
    assert(actual and math.abs(actual - expected) < 0.000001, tostring(actual) .. " ~= " .. tostring(expected))
end

-- The old Earthcrawl Mines APR coordinate is preserved, with native exterior
-- map/world identity supplied by the owned library rather than a second table.
local migrated = assert(APR.ScenarioEntrances[2269])
assert(migrated.type == "DELVE" and migrated.zone == 2248 and not migrated.unavailable)
near(migrated.Coord.x, -1631.8); near(migrated.Coord.y, 929.3)
assert(migrated.Coord.mapID == 2248 and migrated.Coord.instanceID == 2552)
assert(migrated == APR.ScenarioEntrances[2269], "The lazy compatibility view reuses a stable entry")
for _, key in ipairs({ "EnterScenario", "DoScenario", "LeaveScenario", "EnterInstance", "LeaveInstance" }) do
    assert(APR:GetScenarioMapIDForStep({ [key] = { mapID = 2269 } }) == 2269,
        "An explicit action must work without earlier sparse fields or a Zone: " .. key)
end
local original = { Zone = 2269, Coord = { x = 111, y = 222, mapID = 2269, instanceID = 90001,
    accessKey = "native-interior", noAutoconnect = true, floor = "lower" } }
local runtime = selectStep(original)
local coord, mapID = APR:GetStepCoord(runtime, 2248)
assert(coord == migrated.Coord and mapID == 2248, "An exterior player targets the actual entrance")
local destination = assert(nav:GetDestination(runtime))
near(destination.x, 929.3); near(destination.y, -1631.8)
assert(destination.instanceID == 2552 and destination.uiMapID == 2248)
assert(original.Coord.x == 111 and original.Coord.mapID == 2269, "Entrance resolution never overwrites authored interior coordinates")
fixture.currentMap = 900002
assert(APR:IsInScenarioMap(2269), "Deeply nested native floors are inside their registered delve")
coord = APR:GetStepCoord(runtime, 2248)
assert(coord == original.Coord, "An interior player retains the actual authored floor target")
destination = assert(nav:GetDestination(runtime))
assert(destination.x == 222 and destination.y == 111 and destination.instanceID == 90001
    and destination.uiMapID == 2269 and destination.accessKey == "native-interior"
    and destination.noAutoconnect and destination.floor == "lower",
    "The controller preserves native world/access/floor metadata at its coordinate boundary")
fixture.currentMap = 2301
assert(APR:IsInScenarioMap(2300), "Registered sibling floors are one delve even without a parent-child relation")
assert(not APR:IsInScenarioMap(2269), "A different delve's native floor cannot validate Earthcrawl Mines")

-- Map-only entry/exit visits ignore old completion history and never query a
-- missing quest anchor. Standing directly on an exterior portal is not entry.
for _, action in ipairs({ "EnterScenario", "EnterInstance" }) do
    for _, interior in ipairs({ 2269, 129 }) do
        outside()
        local source = { [action] = { mapID = interior } }
        runtime = selectStep(source)
        local before = questReads
        APR.stepHandlers.RenderScenarioTravel(runtime, 1)
        assert(APRData.p.r == 1 and source.Coord == nil and source.NoArrow == nil,
            "Exterior proximity/history cannot consume a fresh map-only instance visit")
        assert(questReads == before, "Map-only entry uses physical maps, not nil quest API calls")
        assert(nav:GetDestination(runtime).uiMapID == (interior == 2269 and 2248 or 114))
        fixture.currentMap = interior == 2269 and 900002 or 129
        APR.stepHandlers.RenderScenarioTravel(runtime, 1)
        assert(APRData.p.r == 2, "Entering a native descendant completes exactly the original entry step")
    end
end
for _, action in ipairs({ "LeaveScenario", "LeaveInstance" }) do
    for _, interior in ipairs({ 2269, 129 }) do
        fixture.currentMap = interior == 2269 and 900002 or 129
        runtime = selectStep({ [action] = { mapID = interior }, NoArrow = true })
        local before = questReads
        APR.stepHandlers.RenderScenarioTravel(runtime, 1)
        assert(APRData.p.r == 1 and questReads == before, "Leaving waits while any registered native floor is still active")
        outside(); APR.stepHandlers.RenderScenarioTravel(runtime, 1)
        assert(APRData.p.r == 2, "A real exterior arrival completes map-only leave without a quest anchor")
    end
end
outside()
local scenarioSource = { DoScenario = { mapID = 2269 } }
runtime = selectStep(scenarioSource)
APR.stepHandlers.RenderScenarioTravel(runtime, 1)
assert(APRData.p.r == 1 and runtime.NoArrow == false and scenarioSource.NoArrow == nil)
fixture.currentMap = 900002
APR.stepHandlers.RenderScenarioTravel(runtime, 1)
assert(APRData.p.r == 1 and runtime.NoArrow == true and scenarioSource.Coord == nil,
    "DoScenario uses interior visibility without copying an exterior coordinate into the route")

-- Requirements and missing geometry stay in the compatibility view so callers
-- recognise an instance instruction but never reinterpret its interior XY.
outside()
local blocked = { EnterInstance = { mapID = 306 }, Coord = { x = 444, y = 555 } }
completed[76249] = false
runtime = selectStep(blocked)
local goal, _, reason = nav:GetDestination(runtime)
assert(goal == nil and reason == "requirements_unmet", "A locked native entrance fails closed")
assert(APR:GetStepCoord(runtime, 2248) == nil and blocked.Coord.x == 444)
nav:Update()
assert(nav.state == "no_path" and nav.reason == "requirements_unmet" and APRData.p.r == 1)
completed[76249] = nil
goal, _, reason = nav:GetDestination(runtime)
assert(goal == nil and reason == "pending_data", "An unknown quest prerequisite is not an unlocked entrance")
completed[76249] = true
missingProjection[22] = true; data:InvalidatePositionCache()
goal, _, reason = nav:GetDestination(runtime)
assert(goal == nil and reason == "pending_data", "Unavailable exterior projection cannot fall through to interior XY")
missingProjection[22] = nil
goal = assert(nav:GetDestination(runtime))
assert(goal.uiMapID == 22, "Missing projection is retryable once the native map becomes available")

local unknown = { EnterScenario = { mapID = 999991 }, Coord = { x = 600, y = 700 } }
runtime = selectStep(unknown)
goal, _, reason = nav:GetDestination(runtime)
assert(goal == nil and reason == "unknown_entrance" and APR:GetStepCoord(runtime, 2248) == nil,
    "An unknown explicit entrance must never fabricate an outside destination")
fixture.currentMap = 999991
assert(APR:GetStepCoord(runtime, 2248) == unknown.Coord,
    "An already observed unknown interior may still use its authored native target")

-- Returning to the same numeric route index cannot revive a cancelled travel
-- callback; both the route definition and revision belong to its original step.
outside()
runtime = selectStep({ Waypoint = 1, ZoneStepTrigger = { mapID = 2269, x = 0, y = 0, Range = 20 } })
APR.stepHandlers.Transport(runtime, false)
local stale = APR.transportArrivalTimer
selectStep({ EnterScenario = { mapID = 2269 } })
fixture.currentMap, fixture.player = 2269, { x = 0, y = 0, instanceID = 90001 }
stale.callback()
assert(APRData.p.r == 1, "A stale prior arrival cannot skip a replacement authored instance action")

-- Forever uses real world-instance identity when no native interior UI map
-- exists. A dungeon key must resolve through the library without a fake map.
outside()
local library = LibStub("LibAPRNavigation-1.0")
APR.NavigationData = library:New({ profile = "forever", environment = data.env })
fixture.maps[1454] = { mapID = 1454, parentMapID = 1414, mapType = 3 }
fixture.currentMap = 1454
local inDungeon = false
function APR:GetDungeonDefinition(key) return key == "RFC" and { instanceID = 389 } end
function APR:IsInsideDungeon(key) return key == "RFC" and inDungeon end
function APR:IsInDungeonStepContext(step) return step.Dungeon == "RFC" and inDungeon end
runtime = selectStep({ Dungeon = "RFC", InstanceQuest = true, NoArrow = true,
    EnterInstance = { dungeonKey = "RFC" } })
local nativeMap, entrance = APR:GetScenarioStepTarget(runtime)
assert(nativeMap == nil and entrance and entrance.type == "DUNGEON" and entrance.zone == 1454,
    "A world-only Forever entrance must not fabricate an interior UI map")
goal = assert(nav:GetDestination(runtime))
assert(goal.uiMapID == 1454 and not APR:IsInScenarioStep(runtime),
    "The registered exterior remains a routing target while outside the dungeon")
inDungeon = true
assert(APR:IsInScenarioStep(runtime) and APR:GetStepCoord(runtime) == nil,
    "Actual world-instance membership takes over after entry")
nav:Update()
assert(nav.state == "ready" and not nav._routeInputs,
    "Inside dungeon steps retain their exemption without repeatedly planning an exterior return")
print("Instance integration: real delve migration, explicit actions, nested/sibling floors, physical entry/exit, native metadata and unavailable/stale guards passed")
