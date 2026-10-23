-- Account unlocks, story phases and shortest-time routing use the real data.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 2405
fixture.player = { x = 889.3, y = -452.4, instanceID = 2771 }
local quests, active, achievements, reads = {}, {}, {}, {}
C_QuestLog.IsQuestFlaggedCompleted = function(id) return quests[id] == true end
C_QuestLog.IsOnQuest = function(id) return active[id] == true end
GetAchievementInfo = function(id)
    reads[id] = (reads[id] or 0) + 1
    return id, "Client achievement name", 0, achievements[id] == true,
        nil, nil, nil, nil, nil, nil, nil, nil, false -- Not earned by this alt.
end
local data = fixture:Load()
local family = {}
local families = {
    ["portal-eastern-kingdoms-to-harandar"] = 366,
    ["portal-eastern-kingdoms-to-voidstorm"] = 367,
    ["portal-harandar-to-silvermoon-city"] = 368,
    ["portal-voidstorm-to-silvermoon-city"] = 369,
    ["portal-harandar-to-voidstorm"] = 372,
    ["portal-voidstorm-to-harandar"] = 373,
    ["portal-voidstorm-to-silvermoon-city-at-890-minus-441-arrive-8554-minus-4326"] = 374,
    ["portal-eastern-kingdoms-to-voidstorm-at-8536-minus-4326-arrive-896-minus-449"] = 378,
}
for _, definition in ipairs(data.connections) do
    if families[definition.id] then family[#family + 1] = definition end
end
assert(#family == 8)
data.connections = family
local start = data:NormalizeLocation({ x = 889.3, y = -452.4, instanceID = 2771, uiMapID = 2405 })
local goal = data:NormalizeLocation({ x = 8016.7, y = -4577.6, instanceID = 0, uiMapID = 2395 })
local function Build()
    reads = {}
    local edges, metadata = data:BuildEdges({ start = start, playerPosition = start })
    local indexed = {}
    for _, edge in ipairs(edges) do indexed[families[edge.id:match("^retail:(.-):forward$")]] = edge end
    assert((reads[42045] or 0) <= 1, "One build must share the account achievement lookup")
    return indexed, edges, metadata
end
local function Route(edges, resources)
    local search = data:CreateSearch({ start = start, goal = goal, edges = edges,
        resources = resources, walkSpeed = 60, walkingIsTransitive = true,
        canWalk = function(a, b) return data:CanWalk(a, b) end })
    while search:Step(32) == "planning" do end
    return search:GetResult(), search.status
end
local indexed, edges, metadata = Build()
assert(not indexed[374] and not indexed[378] and not indexed[367] and not indexed[369],
    "No quest or achievement means no invented Voidstorm unlock")
assert(select(2, Route(edges, metadata.resources)) == "no_path")

quests[86549] = true
indexed = Build()
assert(indexed[367] and indexed[369] and not indexed[374] and not indexed[378],
    "The initial campaign portal and permanent Howling Ridge portal are different phases")
quests[86549], active[86549] = nil, true
assert(Build()[367], "The introductory portal is available during its opening quest")
active[86549], active[86510] = nil, true
indexed = Build()
assert(indexed[374] and indexed[378], "The permanent portal is available during its documented opening quest")
active[86510], quests[86510] = nil, true
indexed = Build()
assert(indexed[374] and indexed[378] and not indexed[367] and not indexed[369])

-- User report: all three old quest flags false; Midnight earned on the account.
quests, achievements[42045] = {}, true
indexed, edges, metadata = Build()
assert(indexed[374] and indexed[378] and indexed[366] and indexed[368] and indexed[372] and indexed[373])
assert(not indexed[367] and not indexed[369], "Account completion must not revive obsolete introductory portals")
local result, status = Route(edges, metadata.resources)
assert(status == "ready" and result.totalSeconds < 16)
local transports = {}
for _, segment in ipairs(result.segments) do
    if segment.kind ~= "walk" then transports[#transports + 1] = segment end
end
assert(#transports == 1 and transports[1].id == "retail:portal-voidstorm-to-silvermoon-city-at-890-minus-441-arrive-8554-minus-4326:forward",
    "An alt at the reported position must take the direct Silvermoon portal, not Harandar")
assert(indexed[374].canStart(start, true), "Live checks must also honour the account achievement")
achievements[42045] = false
assert(not indexed[374].canStart(start, true), "Live checks cannot retain a previously cached unlock")
GetAchievementInfo = nil
indexed, edges, metadata = Build()
assert(not indexed[374] and metadata.waitingData, "Missing achievement data stays unknown and cannot unlock a portal")
print("Midnight account portals: alt without quests, story phases, bounded lookups, live validation and direct Silvermoon routing passed")
