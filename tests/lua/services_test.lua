local function noop() end
local timers, messages, frames = {}, {}, {}
local player = {x = 0, y = 0, z = 0, instanceID = 0, uiMapID = 1}
local character = {faction = "Alliance", class = "MAGE", level = 20}
local money, now = 100, 1
local remoteMaps
function GetTime() return now end
debugprofilestop = nil -- Exercise the bounded operation fallback, not a frozen clock.
function UnitPosition() return player.x, player.y, player.z, player.instanceID end
function UnitIsDeadOrGhost() return false end
function UnitOnTaxi() return false end
function GetMoney() return money end
function InCombatLockdown() return false end
function IsIndoors() return false end
function GetLocale() return "enUS" end
function CreateFrame()
    local frame = {RegisterEvent = noop, SetScript = function(self, name, fn) self[name] = fn end}
    frames[#frames + 1] = frame
    return frame
end
function LibStub() return {GetLocale = function() return setmetatable({}, {__index = function(_, k) return k end}) end} end
C_Map = {GetBestMapForUnit = function() return player.uiMapID end, GetMapInfo = function(id) return {name = "Map " .. id} end}
C_Timer = {NewTimer = function(_, callback)
    local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
    timers[#timers + 1] = timer
    return timer
end}
APR = {PlayerID = "p", ActiveRoute = "guide", stepRevision = 0, RouteQuestStepList = {guide = {}},
    settings = {profile = {enableAddon = true}}, GAME_VERSIONS = {Forever = "forever"},
    currentStep = {AddQuestSteps = noop, AddQuestDivider = noop, AddStepButton = noop,
        RemoveStepContentPreservingNavigationUi = noop},
    Arrow = {SetCoord = noop, SetArrowActive = noop}, event = {QueueStepRefresh = noop}, SendMessage = noop}
APRData = {p = {guide = 1}}
local authored = {Coord = {x = 0, y = 100, mapID = 1, instanceID = 0}, Zone = 1}
function APR:NewModule() return {} end
function APR:GetGameVersion() return "forever" end
function APR:GetNavigationPlayerPosition() return player end
function APR:GetCurrentStep() return authored, 1, {authored} end
function APR:GetCurrentRouteMapIDsAndName() return {1}, 1 end
function APR:GetStepCoord(step) return step.Coord, step.Zone end
function APR:GetStepZoneForPlayer(step, fallback) return step.Zone or fallback end
function APR:CheckNavigationZoneReady() return false end
function APR:PrintInfo(message) messages[#messages + 1] = message end
dofile("APR-Core/features/questing/StepTransitions.lua")
local edges = {}
APR.NavigationData = {profile = "forever", env = {getCharacter = function() return character end}}
function APR.NavigationData:NormalizeLocation(point)
    if point.uiMapID == 99 then return end
    if point.space == "map" then
        local instanceID = remoteMaps and point.uiMapID ~= 1 and 1 or 0
        return {x = point.x * 1000, y = point.y * 1000, z = point.z, instanceID = instanceID, uiMapID = point.uiMapID}
    end
    return point
end
function APR.NavigationData:CanWalk(a, b) return a.instanceID == b.instanceID and a.uiMapID == b.uiMapID end
function APR.NavigationData:IsSameAccessRegion(a, b) return self:CanWalk(a, b) end
function APR.NavigationData:BuildEdges() return edges, {} end
local nodes = {}
LibTaxiData_API = {
    FLAGS = {END_POINT_ONLY = 32, IGNORE_FOR_FIND_NEAREST = 64},
    GetAllNodes = function() return nodes end,
    IsNodeAvailable = function(id) return nodes[id].available end,
    IsNodeVisible = function(id) return nodes[id].visible end,
    GetNodeWorldPosition = function(id) return nodes[id].point end,
    GetNodeName = function(id) return "Flight " .. id end,
}
dofile("APR-Core/features/navigation/NavigationTaxi.lua")
local library = dofile("tests/lua/navigation_engine_fixture.lua")
APR.NavigationEngine = library.Engine
local localeStub = LibStub
function LibStub(name)
    if name == "LibAPRNavigation-1.0" then return library end
    return localeStub(name)
end
dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")
setmetatable(APR.NavigationData, {__index = library.Instance})
function APR.NavigationData:GetText(key) return key end
function APR.NavigationData:CreateEdgeBuild()
    return {Step = function() return "ready", edges, {} end, Cancel = noop}
end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
dofile("APR-Core/features/navigation/Navigation.lua")
dofile("APR-Core/features/navigation/Services.lua")
local services, nav = APR.Services, APR.navigation
local function drain()
    local count = 0
    while #timers > 0 do
        count = count + 1
        assert(count < 10000, "Service planning must terminate")
        local timer = table.remove(timers, 1)
        if not timer.cancelled then timer.callback() end
    end
end
local function point(x, map) return {x = x, y = 0, z = 0, instanceID = 0, uiMapID = map} end
local function service(id, x, map)
    return {service = "repair", npcID = id, name = "Repair " .. id, x = x, y = 0, mapID = map, faction = "A"}
end
-- Without a point in the player's world, compare reachable journeys to remote services.
remoteMaps = true
APR.NavigationData.serviceLocations = {service(2, 1, 2), service(3, 0.1, 3)}
edges = {{id = "portal", kind = "portal", from = point(0, 1), to = point(10, 2), seconds = 1, instruction = "Portal"}}
edges[1].to.instanceID = 1
services:Find({service = "repair"})
drain()
assert(services.active.record.npcID == 2, "Remote selection uses an accessible journey across worlds")
assert(nav:IsNavigating() and nav.queue[#nav.queue].arrivalRange == 5)
assert(APRData.p.guide == 1 and APR.ActiveRoute == "guide")
assert(messages[#messages] == services:GetLabel(), "Publish the selected destination when ranking finishes")
local original = services.active
services:Find({service = "bank"})
drain()
assert(messages[#messages] == "SERVICE_NOT_FOUND" and services.active == original, "Failed requests preserve guidance")
-- Late completion of a cancelled request cannot replace the current detour.
services:Find({service = "repair"})
local stale = services.request.timer.callback
services:CancelSearch()
stale()
assert(services.active == original)
-- A service arrival only completes its own destination, on the correct floor.
player.x, player.uiMapID, player.instanceID = 10, 2, 1
nav:PollArrival() -- portal receipt
nav:PollArrival() -- final walk
drain()
assert(not services.active and APRData.p.guide == 1)

-- No active guide is required. Arrival outside five yards must not stop guidance.
APR.ActiveRoute = nil
remoteMaps = nil
player.x, player.uiMapID, player.instanceID = 0, 1, 0
edges = {}
APR.NavigationData.serviceLocations = {service(4, 5, 1)}
services:Find({service = "repair"}); drain()
assert(services.active and nav:IsNavigating())
player.x = 44
nav:PollArrival()
assert(services.active, "Six yards is outside the service arrival radius")
player.x, player.z = 50, 20
services.active.step.target.z = 0
nav.queue[#nav.queue].arrivalZTolerance = 5
nav:PollArrival()
assert(services.active, "A different floor is not arrival")
player.z = 0
nav:PollArrival(); drain()
assert(not services.active and APR.ActiveRoute == nil and APRData.p.guide == 1)

-- Faction, own class, profession and expansion are independent filters.
assert(not APR.NavigationData:ServiceMatches({service = "class", class = "PRIEST"}, {service = "class"}, character))
assert(APR.NavigationData:ServiceMatches({service = "class", class = "MAGE"}, {service = "class"}, character))
assert(not APR.NavigationData:ServiceMatches({service = "bank", faction = "H"}, {service = "bank"}, character))
assert(not APR.NavigationData:ServiceMatches({service = "trainer", skill = 171, expansion = 2}, {service = "trainer", skill = 171, expansion = 3}, character))
assert(APR.NavigationData:ServiceMatches({service = "weapon", skill = 43}, {service = "weapon", skill = 43}, character))
assert(APR.NavigationData:ServiceMatches({service = "bank", faction = "H"}, {service = "bank"}, {}) == nil)
assert(APR.NavigationData:ServiceMatches({service = "bank", faction = "H"}, {service = "repair"}, {}) == false)
APR.NavigationData.profile = "retail"
APR.NavigationData.serviceLocations = {{service = "trainer", skill = 171, expansion = 2}, {service = "trainer", skill = 171, expansion = 9}}
assert(#services:GetChoices({service = "trainer", skill = 171}) == 2)
local retail = {}
for _, choice in ipairs(services:GetChoices()) do retail[choice.query.service] = true end
assert(retail.flight and retail.trainer and retail.mailbox and not retail.weapon and not retail.class and not retail.vendor)

-- Taxi availability is independent of discovery. Hidden/unknown nodes are not selected.
APR.NavigationData.profile = "forever"
APR.NavigationData.serviceLocations = {service(4, 5, 1)}
player.x = 0
nodes = {[11] = {point = point(30, 1), available = true, visible = true, discovered = false},
    [12] = {point = point(1, 1), available = false, visible = true},
    [13] = {point = point(2, 1), available = true, visible = false},
    [14] = {point = point(3, 1), available = true, visible = true, flags = 33},
    [15] = {point = point(4, 1), available = true, visible = true, flags = 65},
    [16] = {available = true, visible = true},
    [17] = {point = point(1, 1), available = true, visible = true, characterBitNumber = 0,
        hordeMountCreatureID = 0, allianceMountCreatureID = 0}}
services:Find({service = "flight"}); drain()
assert(services.active.record.nodeID == 11, "An undiscovered accessible master remains a valid destination")
assert(not nodes[11].discovered, "Searching never discovers flights")
services:Cancel(); drain()
nodes = {[16] = nodes[16]}
services:Find({service = "flight"}); drain()
assert(not services.active and not services.request and messages[#messages] == "SERVICE_WAITING_DATA",
    "Missing taxi coordinates do not subscribe to movement retries")
LibTaxiData_API = nil
assert(not services:Find({service = "flight"}) and messages[#messages] == "SERVICE_TAXI_UNAVAILABLE")

-- A real route change invalidates detours and queued searches.
services:Find({service = "repair"}); drain()
APR.ActiveRoute = "other"
services:Validate()
assert(not services.active and not services.request)
APR.ActiveRoute = nil
drain()
services:Find({service = "repair"})
APR.settings.profile.enableAddon = false
drain()
assert(not services.request and not services.active)

-- Selection and guidance must both honor a mandatory crossing inside one map.
APR.settings.profile.enableAddon = true
APR.ActiveRoute = "guide"
player.x, player.y, player.z, player.uiMapID = 0, 0, 0, 1
local ordinaryCanWalk = APR.NavigationData.CanWalk
function APR.NavigationData:CanWalk(a, b)
    return ordinaryCanWalk(self, a, b) and ((a.x < 50) == (b.x < 50))
end
APR.NavigationData.serviceLocations = {service(50, 10, 1)}
edges = {{id = "mandatory-gate", kind = "passage", from = point(30, 1), to = point(70, 1),
    seconds = 2, instruction = "Cross the gate"}}
services:Find({service = "repair"}); drain()
assert(nav:IsNavigating() and #nav.queue == 3)
assert(nav.queue[1].kind == "walk" and nav.queue[1].to.x == 30, "The arrow first approaches the mandatory gate")
assert(nav.queue[2].connectionID == "mandatory-gate" and nav.queue[2].kind == "passage")
assert(nav.queue[3].to.x == 100 and nav.queue[3].arrivalRange == 5)

nav:MarkRouteReady()
assert(not nav:IsNavigating() and #nav.queue == 0, "An unfinished service cannot fall back to a direct arrow")
drain()
assert(nav.queue[1].to.x == 30 and nav.queue[2].connectionID == "mandatory-gate", "Recovery recalculates the mandatory passage through the library")

local partial = {queue = {nav.queue[1]}}
nav:Publish(partial, nav.context, nav.generation)
assert(not nav:IsNavigating(), "A truncated itinerary cannot be completed with a fabricated direct walk")
drain()
assert(#nav.queue == 3 and nav.queue[2].connectionID == "mandatory-gate")

edges = {}
nav:MarkRouteReady(); drain()
assert(not nav:IsNavigating() and nav.state == "no_path", "A missing mandatory crossing stays blocked")
assert(services.active and APRData.p.guide == 1, "Blocked service guidance cannot advance the guide")
APR.NavigationData.CanWalk = ordinaryCanWalk
services:Cancel(); drain()

-- A permitted long-trip recall must disappear when a replan becomes local,
-- even if retaining the old recall would still have the shortest raw time.
player.x = 0
function APR.NavigationData:NormalizeLocation(p)
    if p.space == "map" then return point(p.x * 10000, p.uiMapID) end
    return p
end
APR.NavigationData.serviceLocations = {service(60, 50, 1)}
edges = {{id = "synthetic-inn-recall", kind = "item", from = point(0, 1), to = point(5000, 1),
    seconds = 5, sourceFree = true, hearthstone = true, action = {type = "item", data = 900001}}}
services:Find({service = "repair"}); drain()
assert(nav.queue[1].hearthstone and nav.queue[1].action, "Long service journeys may offer a useful recall")
player.x = 4700
nav:ForceRefresh("moved-near-service")
nav:Update(); drain()
assert(nav:IsNavigating() and nav:GetActiveStep().kind == "walk")
for index = nav.cursor, #nav.queue do
    assert(not nav.queue[index].hearthstone, "A local service replan cannot retain an old recall shortcut")
end
services:Cancel(); drain()

-- The current-step window must not repeat the destination as its walking instruction.
player.x, player.uiMapID = 0, 1
edges = {}
APR.NavigationData.serviceLocations = {service(70, 3, 1)}
local visibleRows, dividers, buttons = {}, 0, 0
function APR.currentStep:AddQuestSteps(key, label) visibleRows[key] = label end
function APR.currentStep:AddQuestDivider() dividers = dividers + 1 end
function APR.currentStep:AddStepButton() buttons = buttons + 1 end
services:Find({service = "repair"}); drain()
assert(nav:IsNavigating() and nav:GetActiveStep().kind == "walk")
assert(visibleRows["00_SERVICE_DESTINATION"] == services:GetLabel())
visibleRows[nav.NavigationStepKey], dividers = nil, 0
nav:Render()
assert(not visibleRows[nav.NavigationStepKey] and dividers == 0,
    "A direct service approach displays its destination once, without an empty divider")

-- A distinct passage instruction still accompanies the destination.
local guidance = nav:GetActiveStep()
guidance.label = "Cross a synthetic passage"
nav:Render()
assert(visibleRows[nav.NavigationStepKey] == "Cross a synthetic passage" and dividers == 1)

-- Action instructions retain their row/button even if their label matches the destination.
guidance.kind, guidance.label = "item", services:GetLabel()
guidance.action, guidance.sourceFree = {type = "item", data = 900002}, true
nav:Render()
assert(visibleRows[nav.NavigationStepKey] == services:GetLabel() and buttons == 1)
services:Cancel(); drain()
print("Services: accessible-time ranking, cancellation, failure retention, standalone guidance, five-yard/floor arrival, filters and undiscovered taxi masters passed")

-- Manual controls move only the transient itinerary, including with no guide.
APR.ActiveRoute = nil
services:Start(service(80, 25, 1), point(25, 1))
nav.state, nav.cursor = "guiding", 1
nav.queue = {
    {kind = "walk", from = point(0, 1), to = point(10, 1), label = "Approach"},
    {kind = "portal", from = point(10, 1), to = point(0, 2), label = "Cross"},
    {kind = "walk", from = point(0, 2), to = point(25, 2), label = "Destination"},
}
local index, total, label = services:GetProgress()
assert(index == 1 and total == 3 and label == "Approach")
assert(not services:MoveStep(-1) and nav.cursor == 1, "Rollback stops at the first step")
local cancelledSearch = false
nav.search = {Cancel = function() cancelledSearch = true end}
local generation = nav.generation
assert(services:MoveStep(1) and nav.cursor == 2 and cancelledSearch and nav.search == nil)
assert(nav.generation == generation + 1, "Manual movement invalidates an in-flight plan")
assert(not services:MoveStep(1) and nav.cursor == 2, "Skip cannot bypass the mandatory crossing")
assert(services:MoveStep(-1) and nav.cursor == 1, "Rollback returns to an accessible waypoint")
assert(services:MoveStep(1))
UnitOnTaxi = function() return true end
assert(not services:MoveStep(-1), "Controls preserve a live transport receipt")
UnitOnTaxi = function() return false end
nav.queue[2].actionCommittedUntil = now + 10
assert(not services:MoveStep(-1), "Controls preserve a committed cast")
nav.queue[2].actionCommittedUntil = nil
player.uiMapID = 2
assert(services:MoveStep(1) and nav.cursor == 3)
assert(not services:MoveStep(-1), "Rollback cannot invent a reverse crossing")
index, total, label = services:GetProgress()
assert(index == 3 and total == 3 and label == "Destination")
nav.queue[3].approachOnly = true
local previousX = player.x
player.x = nav.queue[3].to.x - 4
assert(not services:GetStepCursor(1) and not services:MoveStep(1) and services.active and nav.cursor == 3,
    "Next keeps a partial approach active even four yards from the destination")
player.x = previousX
nav.queue[3].approachOnly = nil
assert(services:MoveStep(1) and not services.active, "Skipping the final destination cancels the detour")
assert(APRData.p.guide == 1 and APR.ActiveRoute == nil, "Controls never mutate guide progress")
local emptyIndex, emptyTotal = APR.NavigationData:GetServiceProgress({}, 1)
assert(emptyIndex == 0 and emptyTotal == 0)

-- The existing header/slash commands must dispatch to the detour first.
function APR:TrimString(value) return value end
function APR:RemoveContiguousSpaces(value) return value end
function APR:SkipQuestStep() error("Must not skip a saved guide during a detour") end
function APR:PreviousQuestStep() error("Must not roll back a saved guide during a detour") end
dofile("APR-Core/core/Commands.lua")
player.uiMapID = 1
services:Start(service(81, 25, 1), point(25, 1))
nav.state, nav.cursor = "guiding", 1
nav.queue = {
    {kind = "walk", to = point(10, 1), label = "First"},
    {kind = "walk", to = point(25, 1), label = "Second"},
}
APR.command:SlashCmd("s")
assert(nav.cursor == 2 and services.active)
APR.command:SlashCmd("rb")
assert(nav.cursor == 1)
InCombatLockdown = function() return true end
APR.command:SlashCmd("skip")
assert(nav.cursor == 1, "Combat-deferred controls cannot move the itinerary")
InCombatLockdown = function() return false end
APR.command:SlashCmd("rollback")
assert(nav.cursor == 1)
APR.command:SlashCmd("skippiedoodaa")
assert(nav.cursor == 2)
APR.command:SlashCmd("skip")
assert(not services.active and APRData.p.guide == 1)
local testQueue = {
    {kind = "walk", to = point(10, 1)},
    {kind = "item", sourceFree = true, canStart = function(_, live) return live == true and false end},
}
assert(not APR.NavigationData:GetServiceStepCursor(testQueue, 1, 1, player),
    "Manual navigation rechecks departure restrictions")
do
    local data = APR.NavigationData
    local previous = data.GetWalkingProvider
    local bend = point(6, 1)
    local visible = false
    local terrain = {RequiresWalkingProof = function() return true end,
        CanFollowWalkingSegment = function(_, _, target) return target == bend and visible end}
    function data:GetWalkingProvider() return terrain end
    local queue = {{kind = "walk", path = {point(0,1), bend, point(10,1)}, to = point(10,1)}, testQueue[1]}
    assert(not data:GetServiceStepCursor(queue, 2, -1, player), "Rollback cannot cut through an obstacle on the same map")
    visible = true
    assert(data:GetServiceStepCursor(queue, 2, -1, player) == 1, "Rollback can resume at a verified bend")
    local source, destination = point(1,1), point(2,1)
    source.z, destination.z = nil, nil
    terrain.GetGuidanceHeight = function() return nil end
    terrain.CanFollowWalkingSegment = function() return true end
    assert(not data:IsServiceArrival(source,destination), "Unknown stacked floors do not complete a service")
    terrain.GetGuidanceHeight = function() return 0 end
    terrain.CanFollowWalkingSegment = function() return false end
    assert(not data:IsServiceArrival(source,destination), "Interaction radius does not reach through a wall")
    terrain.CanFollowWalkingSegment = function(_,a,b) return a.z==0 and b.z==0 end
    assert(data:IsServiceArrival(source,destination) and source.z==nil and destination.z==nil,
        "A unique floor and a clear interaction complete the service without changing observed coordinates")
    data.GetWalkingProvider = previous
end

-- Coordinate-free learning remains part of its guide on both supported clients.
services:Cancel(); drain()
edges = {}
function APR.NavigationData:NormalizeLocation(p)
    if p.space == "map" then return point(p.x * 1000, p.uiMapID) end
    return p
end
local function trainer(id, x, spells, category, klass)
    return {service = category or "trainer", npcID = id, mapID = 1, x = x, y = 0,
        faction = "A", spellIDs = spells, class = klass}
end
local function learning(step)
    nav:Cancel("step_changed")
    authored = step
    APR.ActiveRoute, APRData.p.guide = "guide", 1
    APR.RouteQuestStepList.guide = {steps = {step}}
    APR.stepRevision = APR.stepRevision + 1
    player.x, player.y, player.z, player.uiMapID = 0, 0, 0, 1
end
function APR:AreConditionalFiltersMet() return true end
for _, profile in ipairs({"forever", "retail"}) do
    APR.NavigationData.profile = profile
    -- These spell IDs test the public skill/spell contract, not shipped routes.
    learning({LearnProfession = 2259})
    local initial = trainer(71, 4)
    initial.skill = 171
    APR.NavigationData.serviceLocations = {trainer(70, 1), initial}
    nav:GetDestination(authored); drain()
    assert(services.training.record.npcID == 71,
        "Initial profession learning reuses the existing skill catalog without spell metadata")
    learning({LearnSkill = {spellID = 900099}})
    APR.NavigationData.serviceLocations = {trainer(72, 4, nil, "class", "MAGE")}
    nav:GetDestination(authored); drain()
    assert(services.training.record.npcID == 72, "Ordinary class training works without capability metadata")
    learning({LearnProfession = 900101}) -- No Zone is necessary.
    APR.NavigationData.serviceLocations = {
        trainer(1, 1, {900100}), -- Earlier rank is insufficient.
        trainer(2, 5, {900101}),
        trainer(3, 2, {900101}, "class", "MAGE"), -- Wrong profession category.
    }
    local _, _, reason = nav:GetDestination(authored)
    assert(reason == "pending_data")
    drain()
    local target = nav:GetDestination(authored)
    assert(target.x == 50 and services.training.record.npcID == 2)
    assert(not services.active, "Learning must not replace the guide with a manual detour")
    nav:ForceRefresh(); nav:Update(); drain()
    assert(nav:IsNavigating() and nav.queue[#nav.queue].arrivalRange == 5)
    player.x = 44
    nav:PollArrival()
    assert(nav:IsNavigating(), "Six yards cannot finish the trainer approach")
    player.x = 50
    nav:PollArrival(); drain()
    assert(nav.state == "ready" and APRData.p.guide == 1 and authored.LearnProfession == 900101,
        "Arrival leaves learning completion to native spell evidence")

    learning({LearnSkill = {spellIDs = {900201, 900202}, npcID = 12}})
    APR.NavigationData.serviceLocations = {
        trainer(11, 1, {900201, 900202}, "class", "MAGE"),
        trainer(12, 2, {900201}, "class", "MAGE"),
        trainer(12, 4, {900201, 900202}, "class", "PRIEST"),
        trainer(12, 6, {900201, 900202}, "class", "MAGE"),
    }
    nav:GetDestination(authored); drain()
    assert(services.training.target.x == 60, "NPC, own class and every exact spell must match")

    learning({LearnSkill = {allAvailable = true}})
    APR.NavigationData.serviceLocations = {trainer(21, 1, nil, "class", "PRIEST"),
        trainer(22, 3, nil, "class", "MAGE")}
    nav:GetDestination(authored); drain()
    assert(services.training.record.npcID == 22, "All-available training uses the character's class")

    learning({LearnProfession = 900301})
    APR.NavigationData.serviceLocations = {trainer(31, 1)}
    nav:GetDestination(authored); drain()
    assert(services.training.status == "waiting_data" and not services.training.target,
        "Unknown trainer capabilities cannot prove a requested profession or rank")
    APR.NavigationData.serviceLocations[1].spellIDs = {900301}
    nav:GetDestination(authored); drain()
    assert(services.training.target, "Late capability data can recover")

    learning({LearnProfession = 900401})
    APR.NavigationData.serviceLocations = {trainer(41, 1, {900402})}
    nav:GetDestination(authored); drain()
    assert(services.training.status == "no_path")
    local _, _, absent = nav:GetDestination(authored)
    assert(absent == "service_not_found" and not services.request)

    learning({LearnProfession = 900501})
    APR.NavigationData.serviceLocations = {trainer(51, 1, {900501})}
    nav:GetDestination(authored)
    local retired = services.request.timer.callback
    nav:Cancel("step_changed")
    retired()
    assert(not services.training and not services.request, "Step changes cancel suspended searches")
    nav:GetDestination(authored)
    retired = services.request.timer.callback
    APR.ActiveRoute = "other"
    retired()
    assert(not services.training and not services.request, "Route changes reject stale callbacks")

    learning({LearnProfession = 900601, Coord = {x = 0, y = 70, mapID = 1, instanceID = 0}})
    local explicit = nav:GetDestination(authored)
    assert(explicit.x == 70 and not services.training and not services.request,
        "Authored coordinates have priority over service discovery")
    learning({LearnSkill = {allAvailable = true}, Coords = {}})
    nav:GetDestination(authored)
    assert(not services.training, "Even unresolved explicit Coords must not select another trainer")
end
print("Trainer objectives: Retail/Forever, exact spells/ranks/NPC/class, missing data, arrival and cancellation passed")

-- The selected waypoint must reach the arrow and map before any path work.
services:CancelTraining()
services:Cancel()
local baseServiceSearch=APR.NavigationData.CreateServiceSearch
local baseServiceEdgeBuild=APR.NavigationData.CreateEdgeBuild
dofile("APR-Core/features/navigation/Preview.lua")
function nav:GetMovementSpeed() return 7 end
function APR:GetGameVersion() return APR.NavigationData.profile end
for _, profile in ipairs({"forever","retail"}) do
    player.x,player.y,player.uiMapID=0,0,1
    APR.ActiveRoute,APR.NavigationData.profile,edges="guide",profile,{}
    local many={}
    for i=1,1000 do many[i]=service(i,50+i*0.01,1) end
    many[#many+1]=service(9001,7,1)
    many[#many+1]=service(9003,1,1)
    many[#many].faction="H"
    APR.NavigationData.serviceLocations=many
    local waypointShown, pathJobs, costJobs = false, 0, 0
    function APR.NavigationData:CreateEdgeBuild(options)
        assert(waypointShown, "Transport preparation cannot delay the first waypoint")
        return baseServiceEdgeBuild(self, options)
    end
    function APR.Arrow:SetCoord()
        local waypoint = nav:GetRetainedArrow()
        if not waypoint then return end
        assert(waypoint.Coord.x == 0 and waypoint.Coord.y == 70 and not nav:IsNavigating())
        local preview = nav:GetPreview()
        assert(#preview == 1 and preview[1].generated and preview[1].breakBefore and preview[1].Coord.y == 70)
        waypointShown = true
    end
    local terrain={HasMap=function() return true end}
    function terrain:CreateCostJob(_,targets)
        costJobs = costJobs + 1
        assert(waypointShown and #targets==1 and math.abs(targets[1].x-70)<0.000001,
            "Only the fixed destination can reach the terrain cost provider")
        return {Step=function() return "ready",{costs={{state="unavailable"}}} end,Cancel=noop}
    end
    function terrain:CreatePathJob(start, target)
        pathJobs = pathJobs + 1
        assert(waypointShown and start.x == 0 and target.x == 70)
        local pending = true
        return {Step=function()
            assert(nav:GetRetainedArrow() and not nav:IsNavigating())
            if pending then pending = false; return "planning" end
            return "ready", {path={start,point(20,1),target}, yards=70, seconds=10}
        end,Cancel=noop}
    end
    function APR.NavigationData:GetWalkingProvider() return self.profile=="forever" and terrain or nil end
    function APR.NavigationData:CreateServiceSearch(options)
        assert(options.walkingSpeedCeiling==(self.profile=="forever" and 7 or nil),
            "Only the Forever host supplies its explicit bounded walking model")
        assert(options.nearestByCoordinates)
        return baseServiceSearch(self,options)
    end
    assert(services:Find({service="repair"}))
    drain()
    assert(services.active and services.active.record.npcID==9001 and not services.request
        and services.active.step.target.x==70 and APRData.p.guide==1,
        "Find nearest finishes, starts the selected detour and preserves the authored route")
    assert(waypointShown and not nav:GetRetainedArrow() and costJobs == 0)
    if profile == "forever" then
        assert(pathJobs == 1 and nav:GetGuidanceTarget().x == 20, "The first bend takes over the arrow")
        player.x = 20
        nav:PollArrival()
        assert(nav:GetGuidanceTarget().x == 70, "Reaching the bend moves the arrow to the next segment")
    else
        assert(pathJobs == 0 and nav:GetGuidanceTarget().x == 70)
    end
    APR.NavigationData.CreateEdgeBuild = baseServiceEdgeBuild
    services:Cancel();drain()
end
APR.Arrow.SetCoord = noop
print("Find nearest publishes its pin before path work and updates guidance from the player through each bend")

-- A service selection retires the previous queue. Its verified departure
-- must survive that handoff into the new local and world guidance jobs.
do
    local F = dofile("tests/lua/terrain_runtime_fixture.lua")
    local root = "APR-Core/libs/LibAPRNavigation-1.0/"
    for _, name in ipairs({"Terrain/Namespace.lua", "Terrain/Costs.lua", "Terrain/PathGrid.lua",
        "Terrain/Path.lua", "Terrain.lua"}) do dofile(root .. name) end
    local map = F.map({wall=true})
    local cell = 2*8+1
    map.floor[1] = F.number(1,3) .. F.number(cell,3) .. "BB" .. F.number(2068,2) .. "AA" .. "AAA"
    library:RegisterTerrainData("forever", 0, map)
    APR.NavigationData.GetWalkingProvider = library.Instance.GetWalkingProvider
    APR.NavigationData.profile, APR.ActiveRoute, edges = "forever", "guide", {}
    player.x, player.y, player.z, player.uiMapID = 2.5*F.cellSize, 1.5*F.cellSize, nil, 1
    local function anchor(x,y)
        return {x=x,y=y,z=0,instanceID=0,uiMapID=1}
    end
    -- Two witnesses in adjacent unambiguous cells; the player is near the
    -- corner shared by their cells and the stacked one.
    player.x, player.y = 2.1*F.cellSize, 1.1*F.cellSize
    local active = {kind="walk",pathCursor=2,path={anchor(player.x-15,player.y),anchor(player.x,player.y-15)}}
    nav.state,nav.queue,nav.cursor = "guiding",{active},1
    local shop = service(9002, 5.5*F.cellSize/10, 1)
    shop.y,shop.z = 1.5*F.cellSize/10,0
    APR.NavigationData.serviceLocations={shop}
    -- The coordinate waypoint can be published without a guide or a resolved floor.
    nav.state,nav.queue,APR.ActiveRoute = "ready",{},nil
    assert(APR.NavigationData:GetWalkingProvider():GetGuidanceHeight(player)==nil)
    APR.stepUpdateRunning = true
    assert(services:Find({service="repair"}))
    table.remove(timers, 1).callback()
    assert(services.active and services.active.record==shop and not services.request)
    assert(not nav:IsNavigating() and nav:GetRetainedArrow(), "Unknown height does not delay the bearing")
    APR.stepUpdateRunning = nil
    player.x=1.9*F.cellSize
    drain()
    assert(services.active and services.active.record==shop and nav:IsNavigating(),
        "Crossing into a resolved cell resumes guidance to the selected waypoint")
    APR.ActiveRoute="guide"
    services:Validate()
    assert(not services.request and not services.active, "A route switch cancels the selected detour")
    player.x=2.1*F.cellSize
    nav.state,nav.queue,nav.cursor = "guiding",{active},1
    assert(services:Find({service="repair"}))
    drain()
    assert(services.active and services.active.record==shop and nav:IsNavigating())
    local leg = nav:GetActiveStep()
    assert(leg.path and #leg.path>2 and leg.path[1].z==0 and player.z==nil,
        "Selection publishes the measured detour from the corroborated floor, preserving the native XY observation")
    services:Cancel(); drain()

    local function little(value, size)
        local bytes = {}
        for i = 1, size do
            bytes[i] = string.char(value % 256)
            value = math.floor(value / 256)
        end
        return table.concat(bytes)
    end
    local function double(value)
        if value == 0 then return string.rep("\0", 8) end
        local fraction, exponent = math.frexp(value)
        return little(0, 4) .. little((exponent + 1022 + 2 * fraction - 1) * 1048576, 4)
    end
    local function gallery(first, last, step, z, wall, y, extra)
        local nodes, vertices, faces = {}, {}, {}
        local width = step == .5 and 4 or 2
        local function vertex(x, vy, vz)
            vertices[#vertices + 1] = double(x) .. double(vy) .. double(vz)
        end
        local function face(a, b, c)
            faces[#faces + 1] = string.char(1) .. little(a, 4) .. little(b, 4) .. little(c, 4)
        end
        local function floor(height)
            local index = #vertices
            vertex(first-2, y-2, height)
            vertex(last+2, y-2, height)
            vertex(first-2, y+2, height)
            vertex(last+2, y+2, height)
            face(index, index+1, index+2)
            face(index+1, index+3, index+2)
        end
        floor(z)
        if wall then
            vertex(wall, y-2, z)
            vertex(wall, y+2, z)
            vertex(wall, y, z+3)
            face(4, 5, 6)
        end
        local missing = extra and extra.missing or {}
        if extra and extra.upper then floor(extra.upper) end
        for x = first, last, step do
            if not missing[x] then
                local east = x < last and not missing[x+step] and string.char(0, 0) or ""
                local west = x > first and not missing[x-step] and string.char(1, 0) or ""
                local exits = east .. west
                nodes[#nodes + 1] = little(x / step, width) .. little(y / step, width)
                    .. double(z) .. string.char(0) .. little(#exits / 2, 2) .. exits
            end
        end
        local window = (step == .5 and "SFC2" or "SFC1")
            .. little(first, 2) .. little(y - 1, 2) .. little(last, 2) .. little(y + 1, 2)
            .. little(#nodes, 4) .. little(#vertices, 4) .. little(#faces, 4)
            .. table.concat(nodes) .. table.concat(vertices) .. table.concat(faces)
        return little(#window, 4) .. window
    end
    local function atlas(...)
        return "SFA1" .. little(select("#", ...), 4) .. table.concat({...})
    end

    -- Adjacent extracts on different terrain pages, with no canonical grid
    -- route. The entrance lies between the half-yard and one-yard samples.
    local mixed = F.map({wall=true, disconnected=true})
    mixed.nx = 2
    for _, field in ipairs({"grid", "height", "class", "graph"}) do mixed[field][2] = mixed[field][1] end
    mixed.surface = {atlas(gallery(518, 533, .5, 0, nil, 10)),
        atlas(gallery(534, 548, 1, 0, nil, 10, {upper=8}))}
    library:RegisterTerrainData("forever", 0, mixed, 2)
    APR.ActiveRoute, player.x, player.y, player.z = nil, 519.5, 10, nil
    local indoorShop = service(9030, 54.625, 1)
    indoorShop.y, indoorShop.z = 1, .25
    local normalize = APR.NavigationData.NormalizeLocation
    function APR.NavigationData:NormalizeLocation(p)
        if p.space ~= "map" then return p end
        return {x=p.x*1000, y=p.y*1000, z=p.z, instanceID=0, uiMapID=p.uiMapID}
    end
    APR.NavigationData.serviceLocations = {indoorShop}
    assert(services:Find({service="repair"}))
    drain()
    assert(services.active and services.active.record==indoorShop and not services.request and nav:IsNavigating())
    leg = nav:GetActiveStep()
    local provider = APR.NavigationData:GetWalkingProvider()
    assert(leg.path and leg.path[1].geometryVerified and player.z==nil and APR.ActiveRoute==nil)
    F.near(leg.path[#leg.path].z, 0)
    F.near(leg.path[#leg.path].x, 546.25)
    local start = {x=player.x, y=player.y, instanceID=0, uiMapID=1}
    local target = services.active.step.target
    local function serviceWalk(a, b)
        return F.finish(provider:CreatePathJob(a, b, {serviceWalking=true}), 64)
    end
    for i = 2, #leg.path do
        assert(provider:CanFollowWalkingSegment(leg.path[i - 1], leg.path[i]), "Every published seam remains verifiable")
    end
    local status, measured = serviceWalk(start, target)
    assert(status=="ready" and measured.geometryVerified)
    F.near(measured.yards, 26.75)
    assert(serviceWalk(leg.path[#leg.path], start)=="ready")
    player.x = 533.5
    nav:PollArrival()
    assert(nav:IsNavigating() and nav:GetActiveStep() == leg and player.z == nil,
        "The verified corridor guides through the seam even when the client supplies no height")
    player.x, player.z = target.x, 8
    nav:PollArrival()
    assert(services.active, "The upper floor cannot complete the service")
    player.z = nil
    assert(provider:GetGuidanceHeight(player) == nil)
    nav:PollArrival(); drain()
    assert(not services.active and APR.ActiveRoute == nil and player.z == nil,
        "Finishing the verified corridor carries the resolved floor into the service arrival check")
    APR.NavigationData.NormalizeLocation = normalize

    for i, scenario in ipairs({
        {first=534, z=0, wall=533.5},
        {first=534, z=4},
        {first=536, z=0},
    }) do
        mixed.surface[2] = atlas(gallery(scenario.first, 548, 1, scenario.z, scenario.wall, 10))
        library:RegisterTerrainData("forever", 0, mixed, 2+i)
        local endpoint = {x=546.25, y=10, z=scenario.z+2, instanceID=0, uiMapID=1}
        local state, refusal = serviceWalk(start, endpoint)
        assert(state=="unavailable" and refusal.unverifiedGeometry=="interior",
            "A blocked entrance, another storey or missing coverage cannot certify a seam")
    end

    -- Overlapping resolutions carry independent graph nodes at the same XY.
    local overlap = F.map()
    overlap.surface = {atlas(gallery(20, 35, .5, 0, nil, 10), gallery(30, 50, 1, 0, nil, 10))}
    library:RegisterTerrainData("forever", 0, overlap, 6)
    status, measured = serviceWalk({x=20, y=10, instanceID=0}, {x=50, y=10, z=0, instanceID=0})
    assert(status=="ready" and measured.geometryVerified)
    F.near(measured.yards, 30)

    -- Both endpoints choose the broad window. Its narrower overlay supplies
    -- the missing lattice samples around the entrance.
    overlap.surface = {atlas(gallery(20, 50, 1, 0, nil, 10,
        {missing={[33]=true,[34]=true,[35]=true,[36]=true}}), gallery(31, 38, .5, 0, nil, 10))}
    library:RegisterTerrainData("forever", 0, overlap, 7)
    status, measured = serviceWalk({x=20, y=10, instanceID=0}, {x=50, y=10, z=0, instanceID=0})
    assert(status=="ready" and measured.geometryVerified)
    F.near(measured.yards, 30)

    -- A certified coarse approach can enter a fine window from outside it.
    local entrance = F.map()
    entrance.surface = {atlas(gallery(34, 49, 1, 0, nil, 33))}
    entrance.canonical = {"PCG1" .. little(8, 2) .. little(1, 4)
        .. little(0, 2) .. string.char(0) .. double(0) .. string.char(0)}
    library:RegisterTerrainData("forever", 0, entrance, 8)
    local outside = {x=30, y=F.cellSize / 2, instanceID=0}
    local inside = {x=48, y=33, z=2, instanceID=0}
    for _ = 1, 2 do
        status, measured = serviceWalk(outside, inside)
        assert(status=="ready" and measured.geometryVerified and measured.path[1].coarseEndpoint)
        F.near(measured.path[#measured.path].z, 0)
        for i = 2, #measured.path do
            assert(provider:CanFollowWalkingSegment(measured.path[i - 1], measured.path[i]))
        end
    end
    APR.ActiveRoute = "guide"
    player.x,player.y,player.z=0,0,0
end

-- A menu click during a transient position loss survives until the native
-- position returns. Cancelling or replacing it must still take effect.
do
    local observe = APR.GetNavigationPlayerPosition
    APR.GetNavigationPlayerPosition = noop
    assert(services:Find({service="repair"}) and services.request.waitingForOrigin)
    services:Validate()
    assert(not services.request.timer)
    APR.ActiveRoute = "other"
    services:Validate()
    assert(not services.request and not services.active, "A route switch cancels a pending click")
    APR.ActiveRoute = "guide"
    assert(services:Find({service="repair"}) and services.request.waitingForOrigin)
    local wasDead = UnitIsDeadOrGhost
    UnitIsDeadOrGhost = function() return true end
    services:Validate()
    UnitIsDeadOrGhost = wasDead
    assert(not services.request and not services.active, "Death cancels a pending click")
    assert(services:Find({service="repair"}) and services.request.waitingForOrigin)
    services:Cancel()
    APR.GetNavigationPlayerPosition = observe
    services:Validate()
    assert(not services.request and not services.active)

    APR.GetNavigationPlayerPosition = noop
    assert(services:Find({service="repair"}))
    assert(services:Find({service="bank"}))
    APR.GetNavigationPlayerPosition = observe
    services:Validate()
    assert(services.request and services.request.job and services.request.query.service=="bank")
    drain()
    assert(not services.request and messages[#messages]=="SERVICE_NOT_FOUND")
end

-- A pending terrain job gets frequent slices but takes fresh planning inputs
-- before publishing, even when the sampling interval has not elapsed.
do
    APR.NavigationData.profile = "forever"
    local reads, searches, slices, selected = 0, 0, 0, nil
    function APR.NavigationData.env.getCharacter()
        reads = reads + 1
        return character
    end
    function APR.NavigationData:CreateServiceSearch(options)
        searches = searches + 1
        local origin = options.start
        return {Cancel = noop, Step = function()
            slices = slices + 1
            if slices < 12 then return "planning" end
            return "ready", {record = {}, target = origin}
        end}
    end
    function services:Start(_, target) selected = target end
    local function tick()
        now = now + 0.01
        table.remove(timers, 1).callback()
    end
    services:Find({service = "bank"})
    for i = 1, 11 do tick() end
    assert(slices == 11 and reads <= 2 and not selected)
    player.x = player.x + 125
    tick()
    assert(searches == 2 and not selected, "A move before completion invalidates the result")
    tick()
    assert(selected and selected.x == player.x and not services.request)
end

-- A provider can invalidate its own calculation. A manual request with
-- unchanged inputs must finish visibly instead of restarting forever.
do
    local attempts = 0
    function APR.NavigationData:CreateServiceSearch()
        attempts = attempts + 1
        return {Cancel = noop, Step = function() return "cancelled" end}
    end
    services:Find({service = "repair"})
    drain()
    assert(attempts == 1 and not services.request and messages[#messages] == "SERVICE_WAITING_DATA")
end

-- Phase boundaries can yield early. Consume the remaining time in this
-- frame, then yield to the client before starting another slice.
do
    local elapsed, calls = 0, 0
    debugprofilestop = function() return elapsed end
    function APR.NavigationData:CreateServiceSearch()
        return {Cancel = noop, Step = function(_, _, remaining)
            assert(remaining > 0 and remaining <= 1)
            calls = calls + 1
            elapsed = elapsed + math.min(0.25, remaining)
            return calls == 6 and "no_path" or "planning"
        end}
    end
    services:Find({service = "repair"})
    table.remove(timers, 1).callback()
    assert(calls == 4 and elapsed == 1 and services.request)
    drain()
    assert(calls == 6 and not services.request and messages[#messages] == "SERVICE_NOT_FOUND")
    debugprofilestop = nil
end

-- A deferred import belongs to the client frame. A replacement click must
-- still be cancellable, and an older worker must never resume for that click.
do
    local data, frame = APR.NavigationData, {deferred = false}
    local elapsed, grants, jobs = 0, {}, {}
    local function tick(delta)
        now = now + delta
        local timer = table.remove(timers, 1)
        if not timer.cancelled then timer.callback() end
    end
    local function nextFrame()
        frame = {deferred = false}
        tick(0.02)
    end
    debugprofilestop = function() return elapsed end
    nav.state, nav.queue, nav.zoneReady, nav.retainedArrow = "ready", nil, false, nil
    nav.recomputeKeepingPath, nav.recomputeKeepingDirect = nil, nil
    function data:HasDeferredTerrainImports(world) return world == player.instanceID end
    function data:BeginTerrainFrame() return frame end
    function data:CreateServiceSearch()
        local job = {Cancel = function(self) self.cancelled = true end}
        jobs[#jobs + 1] = job
        function job:Step(_, remaining)
            assert(not self.cancelled)
            grants[#grants + 1] = remaining
            elapsed = elapsed + 0.1
            frame.deferred = true
            return "planning"
        end
        return job
    end
    services:Find({service = "repair"})
    tick(0)
    assert(#grants == 1 and grants[1] == 3 and services.request, "A deferred first slice yields immediately")
    local stale = services.request.timer.callback
    services:Find({service = "bank"})
    assert(jobs[1].cancelled)
    stale()
    tick(0) -- cancelled timer
    tick(0) -- replacement request, same deferred frame
    assert(#grants == 1, "A new click shares the outstanding import deferral")
    nextFrame()
    assert(#grants == 2 and grants[2] == 5, "A fresh frame resumes the current request at its bounded grant")
    nav.state, nav.queue, nav.cursor = "guiding", {{kind = "walk", path = {point(0, 1), point(4, 1)}}}, 1
    nextFrame()
    assert(#grants == 3 and grants[3] == 1, "An existing line keeps its background budget")
    stale = services.request.timer.callback
    services:CancelSearch()
    stale()
    assert(#grants == 3 and not services.request)
    tick(0)
    nav.state, nav.queue = "ready", nil

    local function checkLegacy()
        local calls = 0
        function data:CreateServiceSearch()
            return {Cancel = noop, Step = function(_, _, remaining)
                calls = calls + 1
                assert(remaining == 1, "Legacy and monolithic providers retain their budget")
                return "no_path"
            end}
        end
        services:Find({service = "repair"})
        tick(0)
        assert(calls == 1 and not services.request)
    end
    function data:HasDeferredTerrainImports() return false end
    checkLegacy()
    data.BeginTerrainFrame, data.HasDeferredTerrainImports = nil, nil
    checkLegacy()
    local searches, published, taxi = 0, 0, APR.taxiData
    local oldRevision = taxi.edgeRevision
    function services:Start() published = published + 1 end
    function data:CreateServiceSearch(options)
        searches = searches + 1
        local attempt = searches
        return {Cancel = noop, Step = function()
            if attempt == 1 then
                taxi.edgeRevision = (oldRevision or 0) + 1
                return "ready", {record = {}, target = options.start}
            end
            return "no_path"
        end}
    end
    services:Find({service = "flight"})
    tick(0)
    assert(searches == 2 and published == 0, "A change of flight offers during the last slice discards its winner")
    tick(0)
    assert(not services.request and published == 0)
    taxi.edgeRevision = oldRevision
    debugprofilestop = nil
end
