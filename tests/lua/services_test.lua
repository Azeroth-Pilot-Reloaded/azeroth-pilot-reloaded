local function noop() end
local timers, messages, frames = {}, {}, {}
local player = {x = 0, y = 0, z = 0, instanceID = 0, uiMapID = 1}
local character = {faction = "Alliance", class = "MAGE", level = 20}
local money, now = 100, 1
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
        return {x = point.x * 1000, y = point.y * 1000, z = point.z, instanceID = 0, uiMapID = point.uiMapID}
    end
    return point
end
function APR.NavigationData:CanWalk(a, b) return a.instanceID == b.instanceID and a.uiMapID == b.uiMapID end
function APR.NavigationData:IsSameAccessRegion(a, b) return self:CanWalk(a, b) end
function APR.NavigationData:BuildEdges() return edges, {} end
local nodes = {}
local taxiAPI = {GetAllNodes = function() return nodes end, IsNodeAvailable = true, IsNodeVisible = true}
APR.taxiData = {BuildEdges = function() return {}, {} end}
function APR.taxiData:CreateEdgeBuild()
    return {Step = function() return "ready", {}, {} end, Cancel = noop}
end
function APR.taxiData:GetAPI() return taxiAPI end
function APR.taxiData:IsNodeAvailable(id) return nodes[id].available end
function APR.taxiData:IsNodeVisible(id) return nodes[id].visible end
function APR.taxiData:GetNodeWorldPosition(id) return nodes[id].point end
function APR.taxiData:GetNodeName(id) return "Flight " .. id end
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
function APR.taxiData:GetAllNodes() return taxiAPI and taxiAPI.GetAllNodes() end
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
APR.NavigationData.serviceLocations = {service(1, 8, 1), service(2, 1, 2), service(3, 0.1, 3)}
-- The distant portal destination wins on travel time; the closest point has no path.
edges = {{id = "portal", kind = "portal", from = point(0, 1), to = point(10, 2), seconds = 1, instruction = "Portal"}}
services:Find({service = "repair"})
drain()
assert(services.active.record.npcID == 2, "Rank complete accessible journeys, not straight-line proximity")
assert(nav:IsNavigating() and nav.queue[#nav.queue].arrivalRange == 5)
assert(APRData.p.guide == 1 and APR.ActiveRoute == "guide")
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
player.x, player.uiMapID = 10, 2
nav:PollArrival() -- portal receipt
nav:PollArrival() -- final walk
drain()
assert(not services.active and APRData.p.guide == 1)

-- No active guide is required. Arrival outside five yards must not stop guidance.
APR.ActiveRoute = nil
player.x, player.uiMapID = 0, 1
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
    [13] = {point = point(2, 1), available = true, visible = false}}
services:Find({service = "flight"}); drain()
assert(services.active.record.nodeID == 11, "An undiscovered accessible master remains a valid destination")
assert(not nodes[11].discovered, "Searching never discovers flights")
services:Cancel(); drain()
taxiAPI = nil
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
