local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
local Lib = LibStub("LibAPRNavigation-1.0")

-- Real catalogue identities span every expansion without storing a guessed
-- interior landing. World IDs and journal IDs are independent metadata.
local kinds, confirmed, instances = {}, 0, {}
for _, definition in ipairs(data:GetEntrances()) do
    kinds[definition.kind] = true
    if definition.reviewStatus == "confirmed" then
        confirmed = confirmed + 1
        assert(definition.exterior and definition.exterior.uiMapID)
        assert(not definition.to and not definition.interiorPosition)
        for _, mapID in ipairs(definition.interiorMapIDs) do instances[mapID] = true end
    end
end
assert(confirmed > 0)
assert(not data:GetEntranceDefinitionForMap(0), "Zero is not a native interior map")
local saved = data:GetEntrances()
saved[1].kind = "changed"
assert(data:GetEntrances()[1].kind ~= "changed", "Consumers cannot mutate another lookup through an inventory copy")

local maps = {
    [10] = { mapType = 3, parentMapID = 20 },
    [20] = { mapType = 2, parentMapID = 0 },
    [30] = { mapType = 4, parentMapID = 10 },
    [31] = { mapType = 4, parentMapID = 30 },
    [32] = { mapType = 4, parentMapID = 10 },
}
local mapCalls = 0
Lib:RegisterData("entrance-spec", "entrances", { entrances = {
    { id = "observed-cave", kind = "dungeon", reviewStatus = "confirmed", instanceID = 900,
        interiorMapIDs = { 30, 31 }, exterior = { uiMapID = 10, instanceID = 0, x = 300, y = 0 },
        approach = {
            { uiMapID = 10, instanceID = 0, x = 100, y = 0 },
            { uiMapID = 10, instanceID = 0, x = 200, y = 100 },
            { uiMapID = 10, instanceID = 0, x = 300, y = 0 },
        } },
    { id = "fixture-gated", kind = "scenario", reviewStatus = "confirmed", interiorMapIDs = { 40 },
        requirements = { faction = "Alliance", questActive = 1 }, exterior = { uiMapID = 10, instanceID = 0, x = 100, y = 0 } },
    { id = "fixture-candidate", kind = "scenario", reviewStatus = "candidate", interiorMapIDs = { 41 } },
} }, 1)
local test = Lib:New({ profile = "entrance-spec", environment = {
    getMapInfo = function(id) mapCalls = mapCalls + 1; return maps[id] end,
} })
test.env.isQuestActive = function() return true end
assert(test:GetEntranceForMap(40, { faction = "Alliance" }))
local gated, reason = test:GetEntranceForMap(40, { faction = "Horde" })
assert(not gated and reason == "requirements_unmet")
test.env.isQuestActive = function() return nil end
gated, reason = test:GetEntranceForMap(40, { faction = "Alliance" })
assert(not gated and reason == "pending_data" and test:GetEntranceDefinitionForMap(40).kind == "scenario")
gated, reason = test:GetEntranceForMap(41)
assert(not gated and reason == "candidate", "Unreviewed metadata cannot authorize a public entrance")
local goal = test:GetEntranceForMap(31).position
local start = test:NormalizeLocation({ uiMapID = 10, instanceID = 0, x = 0, y = 0 })
assert(goal.noAutoconnect and not test:CanWalk(start, goal), "No straight walking shortcut through a cave wall")
assert(test:IsSameAccessRegion(start, goal), "Private graph nodes still accept actual arrival observations")
local edges, metadata = test:BuildEdges({ walkSpeed = 10 })
assert(#edges == 2, "Only real approach legs are generated; no interior travel edge is fabricated")
local search = test:CreateSearch({ start = start, goal = goal, edges = edges, walkSpeed = 10,
    canWalk = function(a, b) return test:CanWalk(a, b) end, walkingIsTransitive = true })
local status, result
repeat status, result = search:Step(32) until status ~= "planning"
assert(status == "ready" and result and #result.segments == 3)
assert(result.segments[2].mandatory and result.segments[3].mandatory)
assert(math.abs(result.totalSeconds - (10 + 2 * math.sqrt(20000) / 10)) < 0.001,
    "The full approach distance contributes to the fastest-path comparison")
local inside = test:NormalizeLocation({ uiMapID = 30, instanceID = 0, x = 0, y = 0 })
local floor = test:NormalizeLocation({ uiMapID = 31, instanceID = 0, x = 0, y = 0 })
assert(not test:CanWalk(start, inside) and test:IsSameAccessRegion(inside, floor),
    "Native interior identity isolates outdoor goals even without isInstance=true")
assert(not test:CanWalk(inside, test:NormalizeLocation({ uiMapID = 32, instanceID = 0, x = 0, y = 0 })))
assert(not test:GetEntranceDefinitionForMap(999))
maps[999] = { mapType = 5, parentMapID = 30 }
assert(test:GetEntranceDefinitionForMap(999), "Missing ancestry is retryable after client loading")
local before = mapCalls
for _ = 1, 100 do assert(test:GetEntranceDefinitionForMap(999)) end
assert(mapCalls == before, "Warm metadata recognition does not keep walking map parents")
assert(test:GetEntranceDefinitionForInstance(900).kind == "dungeon")
assert(test:GetEntranceForInstance(900).position.noAutoconnect)

-- An addon may have constructed a Core 10 consumer before a newer embedding
-- upgrades the shared method table. Its independent old data stays usable.
local old = setmetatable({ env = test.env, config = {}, positions = {}, mapInfos = {}, regions = {} }, Lib.Instance)
local oldStart = old:NormalizeLocation({ uiMapID = 10, instanceID = 0, x = 0, y = 0 })
local oldEnd = old:NormalizeLocation({ uiMapID = 10, instanceID = 0, x = 50, y = 0 })
assert(old:CanWalk(oldStart, oldEnd))
assert(not old:CanWalk(oldStart, old:NormalizeLocation({ uiMapID = 30, instanceID = 0, x = 0, y = 0 })))
assert(#old:GetEntrances() == 0 and not old:GetEntranceDefinitionForMap(30))
assert(not old:GetEntranceDefinitionForInstance(900))
entry, reason = old:GetEntranceForMap(30)
assert(not entry and reason == "unknown_entrance")
entry, reason = old:GetEntranceForInstance(900)
assert(not entry and reason == "unknown_entrance")

fixture.profile = "forever"
data = fixture:Load()
for _, definition in ipairs(data:GetEntrances()) do
    assert(#definition.interiorMapIDs == 0, "The Classic source's fabricated 9001+ maps are never native UI identities")
    assert(definition.instanceID and definition.exterior or definition.reviewStatus ~= "confirmed")
end
assert(data:GetEntranceDefinitionForInstance(389), "Forever retains Ragefire's explicit world-instance identity")
assert(data:GetEntranceForInstance(389).position.uiMapID == 1454)
assert(not data:GetEntranceDefinitionForMap(9010), "Shared upstream fake IDs must not alias Onyxia and Ragefire")
print("Instance entrances: native identities, all content kinds, gates, loading, mandatory cave approaches and Forever world-only identities passed")
