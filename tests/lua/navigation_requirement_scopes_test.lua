-- Directional phases, account alternatives and live rechecks use fixture gates.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.currentMap = 101
local completed, active, account, achievements, reads = {}, {}, {}, {}, {}
C_QuestLog.IsQuestFlaggedCompleted = function(id) return completed[id] == true end
C_QuestLog.IsOnQuest = function(id) return active[id] == true end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function(id)
    reads[id] = (reads[id] or 0) + 1
    return account[id] == true
end
GetAchievementInfo = function(id) return id, "Client achievement", 0, achievements[id] == true end
local function point(map) return { instanceID = 0, uiMapID = map, x = 0, y = 0 } end
local accountGate = { minLevel = 40, any = { { quest = 1 }, { questActive = 1 }, { questAccount = 1 }, { achievement = 2 } } }
local data = fixture:Load({ connections = {
    { id = "later-direction", kind = "portal", from = point(101), to = point(102), requirements = accountGate },
    { id = "early-direction", kind = "portal", from = point(102), to = point(101),
        requirements = { any = { { questActive = 3 }, accountGate } } },
    { id = "intro-phase", kind = "portal", from = point(101), to = point(102),
        requirements = { all = { { quest = 4 }, { notCondition = { quest = 1 } }, { notCondition = { achievement = 2 } } } } },
} })
local player = point(101)
local function build()
    reads = {}
    local edges, metadata = data:BuildEdges({ start = player, playerPosition = player })
    local indexed = {}
    for _, edge in ipairs(edges) do indexed[edge.id] = edge end
    assert((reads[1] or 0) <= 1, "One build shares account reads between directions")
    return indexed, metadata
end
local inward, outward, intro = "retail:later-direction:forward", "retail:early-direction:forward", "retail:intro-phase:forward"
assert(next((build())) == nil)
active[3] = true
local edges = build()
assert(edges[outward] and not edges[inward], "An early directional unlock cannot authorize the later direction")
active[3], active[1] = nil, true
edges = build()
assert(edges[inward] and edges[outward])
active[1], account[1] = nil, true
edges = build()
assert(edges[inward] and edges[outward])
account[1] = nil
assert(edges[inward].canStart(player, true) == false, "Live validation rereads a lost account unlock")
completed[4] = true
edges = build()
assert(edges[intro] and not edges[inward])
achievements[2] = true
edges = build()
assert(edges[inward] and not edges[intro], "Account completion cannot revive an obsolete introduction")
local character = { faction = "Alliance", class = "MAGE", raceID = 1, level = 40 }
assert(data:CheckRequirements(accountGate, character))
character.level = 39
assert(data:CheckRequirements(accountGate, character) == false, "Account progress does not waive a level gate")
character.level = 40
assert(data:CheckRequirements({ all = { accountGate, { class = "DRUID" } } }, character) == false)
assert(data:CheckRequirements({ quest = 1 }, character) == false, "Account progress cannot satisfy a character-only introduction")
achievements[2], GetAchievementInfo, C_QuestLog.IsQuestFlaggedCompletedOnAccount = nil, nil, nil
local metadata
edges, metadata = build()
assert(not edges[inward] and metadata.waitingData, "Missing account/achievement observations remain unknown")
completed[1] = true
assert(build()[inward], "Character completion still works without account APIs")
