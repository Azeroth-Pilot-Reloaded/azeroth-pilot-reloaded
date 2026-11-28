-- Controlled timelines, stacked access, events and rotating neighborhood links.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, id in ipairs({ 101, 102, 103, 104, 105, 109 }) do
    fixture.maps[id] = { mapID = id, mapType = 3, parentMapID = 13 }
end
fixture.currentMap = 101
local function point(map, x, z, private)
    return { space = "world", instanceID = 0, uiMapID = map, x = x, y = 0, z = z, noAutoconnect = private }
end
local street, top, bottom, city, remote =
    point(101, 0, 50), point(101, 10, 50, true), point(102, 10, -50), point(102, 20, -50), point(103, 100, 0)
local past = { phase = { group = "fixture", phase = "past" } }
local data = fixture:Load({
    config = {
        AccessMapAliases = { [110] = 101 },
        IsolatedAreas = { [102] = "city", [103] = "remote" },
        PhaseGroups = {
            fixture = {
                localMaps = { [101] = "past", [104] = "present" },
                sides = { { mapID = 101, artID = 11, phase = "past" }, { mapID = 104, artID = 22, phase = "present" } },
            },
            sharedArtwork = {
                sides = { { mapID = 105, artID = 33, phase = "past" }, { mapID = 105, artID = 44, phase = "present" } },
            },
        },
        MapRequirements = { [102] = past, [109] = { phase = past.phase, faction = "Horde" }, [119] = past },
    },
    connections = {
        {
            id = "approach",
            kind = "passage",
            from = street,
            to = top,
            seconds = 2,
            bidirectional = true,
            requirements = past,
        },
        {
            id = "lift",
            kind = "elevator",
            from = top,
            to = bottom,
            seconds = 13,
            bidirectional = true,
            requirements = past,
            arrivalZTolerance = 8,
        },
        { id = "city-portal", kind = "portal", from = city, to = remote, seconds = 3 },
        {
            id = "festival",
            kind = "portal",
            from = street,
            to = remote,
            seconds = 1,
            requirements = { holiday = "festival" },
        },
        {
            id = "rotating",
            kind = "portal",
            from = street,
            to = remote,
            seconds = 1,
            requirements = { housingInitiative = { id = 7 } },
        },
    },
    unlockRoutes = {
        {
            id = "observer",
            goal = { key = "phase", value = { group = "fixture", phase = "past" } },
            steps = {
                {
                    kind = "action",
                    actionType = "phase_past",
                    npcID = 9,
                    positions = {
                        { space = "world", instanceID = 0, uiMapID = 101, x = 30, y = 0, phaseAgnostic = true },
                        { space = "world", instanceID = 7, uiMapID = 104, x = 30, y = 0, phaseAgnostic = true },
                    },
                    completeWhen = past,
                },
            },
        },
    },
})
local art = { [101] = 11, [104] = 22 }
data.env.getMapArtID = function(id) return art[id] end
local holiday, initiative = false, { isLoaded = true, initiativeID = 0 }
data.env.isHolidayActive = function() return holiday end
data.env.getHousingInitiative = function() return initiative end
assert(data:GetWorldPhase("fixture") == "past")
assert(
    data:CheckRequirements(past, { mapID = 104 }) == true,
    "A simulated departure never changes the actual player's timeline"
)
assert(not data:CanWalk(street, city), "The underground city cannot connect through the surface")

local function search(start, goal, edges)
    local job = data:CreateSearch({
        start = start,
        goal = goal,
        edges = edges,
        canWalk = function(a, b) return data:CanWalk(a, b) end,
        walkSpeed = 10,
    })
    local status, route
    repeat
        status, route = job:Step(32)
    until status ~= "planning"
    return status, route
end
local edges = data:BuildEdges({ start = street, goal = remote })
assert(#edges == 5, "Only the physical approach, lift and city portal are available")
local status, route = search(street, remote, edges)
assert(status == "ready")
local kinds = {}
for _, edge in ipairs(route.segments) do
    if edge.kind ~= "walk" then kinds[#kinds + 1] = edge.kind end
end
assert(
    table.concat(kinds, ",") == "passage,elevator,portal",
    "A city portal requires the entire mandatory access chain"
)
assert(search(city, street, edges) == "ready", "The city exit uses the lift in reverse")
assert(search(street, remote, { edges[5] }) == "no_path", "A city portal alone cannot bypass the lift")

fixture.currentMap = 104
local blocked, metadata = data:BuildEdges({ start = street, goal = remote })
assert(#blocked == 0 and #metadata.blockedEdges == 7)
assert(edges[5].canStart(city, true) == false, "A retained portal rechecks a phase change live")
assert(not data:CanWalk(bottom, city), "Walking within an absent timeline is also rejected")
local sharedObserver = point(102, 25, -50)
sharedObserver.phaseAgnostic = true
assert(not data:CanWalk(city, sharedObserver), "A remote phase cannot supply a departure to a shared observer")
fixture.currentMap = 102
assert(data:CanWalk(city, sharedObserver), "A shared observer remains reachable from the observed map")
assert(not data:CanWalk(sharedObserver, city), "A shared observer cannot open the restricted endpoint in reverse")
fixture.maps[106] = { mapID = 106, mapType = 5, parentMapID = 101 }
fixture.maps[107] = { mapID = 107, mapType = 4, parentMapID = 101 }
fixture.maps[108] = { mapID = 108, mapType = 6, parentMapID = 101 }
fixture.currentMap = 106
assert(data:GetWorldPhase("fixture") == "past", "A native child map inherits its timeline identity")
fixture.currentMap = 110
assert(data:GetWorldPhase("fixture") == "past", "An alternate map observes the same timeline")
for _, mapID in ipairs({ 107, 108 }) do
    fixture.currentMap = mapID
    assert(data:GetWorldPhase("fixture") == nil, "A separate instance does not observe its parent's timeline")
end
fixture.maps[116] = { mapID = 116, mapType = 5, parentMapID = 102 }
fixture.maps[117] = { mapID = 117, mapType = 4, parentMapID = 102 }
fixture.maps[118] = { mapID = 118, mapType = 6, parentMapID = 102 }
fixture.maps[119] = { mapID = 119, mapType = 4, parentMapID = 102 }
assert(data:GetMapAccessRequirements(116), "A local floor inherits access from its outdoor parent")
assert(not data:GetMapAccessRequirements(117) and not data:GetMapAccessRequirements(118),
    "A separate instance does not inherit outdoor access from its presentation parent")
assert(data:GetMapAccessRequirements(119), "A separate instance still honors its own explicit gate")
fixture.currentMap = 105
assert(data:GetWorldPhase("fixture") == nil, "Two matching static map artworks do not identify the selected timeline")
art[104] = 0
assert(data:GetWorldPhase("fixture") == nil, "One matching static artwork also cannot prove a remote phase")
art[104] = 22
art[105] = 33
assert(data:GetWorldPhase("sharedArtwork") == "past")
art[105] = 44
assert(data:GetWorldPhase("sharedArtwork") == "present", "Different artworks for one shared map report its phase")
local snapshot, departure = data:CreatePlanningSnapshot()
departure.mapID = 101
assert(
    snapshot:GetWorldPhase("fixture") == nil,
    "Physical graph departure simulation cannot overwrite the native phase snapshot"
)
local getCharacter = data.env.getCharacter
fixture.currentMap = 101
data.env.getCharacter = function() return { faction = "Horde" } end
local snapshotWithoutMap = data:CreatePlanningSnapshot()
fixture.currentMap = 104
assert(snapshotWithoutMap:GetWorldPhase("fixture") == "past",
    "A snapshot falls back to the native player map when character fields are still loading")
data.env.getCharacter = function() return { faction = "Horde", mapID = 101 } end
local snapshotWithStaleMap = data:CreatePlanningSnapshot()
assert(snapshotWithStaleMap:GetWorldPhase("fixture") == "present",
    "An older character map cannot override the native player map")
data.env.getCharacter = getCharacter
local restricted = point(109, 110, 0)
local open = point(105, 115, 0)
fixture.currentMap = 101
assert(not data:CanWalk(restricted, open) and not data:CanWalk(open, restricted),
    "The wrong faction cannot walk into or plan a departure from a restricted map")
fixture.faction = "Horde"
assert(data:CanWalk(restricted, open) and data:CanWalk(open, restricted))
fixture.currentMap = 104
assert(not data:CanWalk(restricted, open) and not data:CanWalk(open, restricted),
    "A faction match cannot authorize a different phase")
fixture.faction, fixture.currentMap = "Alliance", 105
data.env.getPlayerPosition = function()
    return {
        space = "world", instanceID = fixture.currentMap == 104 and 7 or 0,
        uiMapID = fixture.currentMap, x = 10, y = 0,
    }
end
local session =
    data:CreateUnlockSession({ blockers = { { from = street, blockedRequirements = past } }, destination = remote })
local action
for _ = 1, 1000 do
    status, action = session:Step(64)
    if status ~= "planning" then break end
end
assert(
    status == "action" and action.npcID == 9 and action.target.phaseAgnostic
        and action.target.uiMapID == 101 and action.target.instanceID == 0,
    "An unobserved reversible phase uses the observer's continental approach"
)
assert(data:CanWalk(data.env.getPlayerPosition(), action.target))
fixture.currentMap = 104
status, action = session:Step(64)
assert(status == "action" and action.target.uiMapID == 104 and action.target.instanceID == 7,
    "The observed active map selects the observer in that world without proving a phase switch")
assert(data:CanWalk(data.env.getPlayerPosition(), action.target))
fixture.currentMap = 101
assert(session:Step(64) == "resume", "Only native phase evidence resumes the original journey")

holiday = true
edges = data:BuildEdges({ start = street, goal = remote })
local festival
for _, edge in ipairs(edges) do
    if edge.id:find(":festival:", 1, true) then festival = edge end
end
assert(festival and festival.canStart(street, true))
holiday = false
assert(festival.canStart(street, true) == false)
holiday = nil
assert(festival.canStart(street, true) == nil, "Missing calendar data cannot authorize an event portal")
initiative = { isLoaded = true, initiativeID = 7, neighborhoodGUID = "one", currentCycleID = 3 }
assert(data:CheckRequirements({ housingInitiative = { id = 7, neighborhoodGUID = "one", cycleID = 3 } }, {}))
assert(data:CheckRequirements({ housingInitiative = { id = 8 } }, {}) == false)
assert(data:CheckRequirements({ housingInitiative = { id = 7, cycleID = 4 } }, {}) == false)
initiative = { isLoaded = false, initiativeID = 7 }
assert(data:CheckRequirements({ housingInitiative = { id = 7 } }, {}) == nil)
for _, invalid in ipairs({ { phase = {} }, { holiday = false }, { housingInitiative = { id = -1 } } }) do
    assert(data:CheckRequirements(invalid, {}) == false)
end
print(
    "Conditional access: timelines, observer detours, mandatory lift, event boundaries and initiative rotation passed"
)
