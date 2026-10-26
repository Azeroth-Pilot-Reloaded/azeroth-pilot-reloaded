-- Synthetic acquisition graph; production campaign edits do not change these expectations.
-- Load the full library with no APR, AceLocale, route engine or WoW runtime.
APR, APRData, APRCustomPath, LibStub = nil, nil, nil, nil
strmatch = string.match -- LibStub's only client alias; library modules need none.
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local file = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = file:read("*a"); file:close()
for name in xml:gmatch('file="([^"]+)"') do if not name:match("^Data/") then dofile(root .. name) end end
local Lib = LibStub("LibAPRNavigation-1.0")
Lib:RegisterData("retail", "fixture", dofile("tests/lua/navigation_unlock_test_catalog.lua"))
local completed, active, objectives, achievements = { [13] = true }, {}, {}, {}
local unknown, language, time = false, "frFR", 0
local environment = {
    isQuestAvailable = function(id) return id ~= 12 or completed[11] == true end, -- Explicit server offer in these progression scenarios.
    getLocale = function() return language end,
    getCharacter = function() return { faction = "Alliance", level = 90, class = "MAGE", mapID = 101 } end,
    isQuestCompleted = function(id) if not unknown then return completed[id] == true end end,
    isQuestActive = function(id) if not unknown then return active[id] == true end end,
    isQuestCompletedOnAccount = function() return false end,
    isQuestObjectiveCompleted = function(id, index) return objectives[id .. ":" .. index] == true end,
    isQuestReadyForTurnIn = function() return false end,
    isAchievementCompleted = function(id) return achievements[id] == true end,
    getQuestName = function(id) return "Quête " .. id end,
    getQuestObjectiveText = function(id, index) return "Objectif " .. index end,
    mapToWorld = function(map, x, y) return 1, x*1000, y*1000 end,
    clock = function() time = time + 0.01; return time end,
}
local data = Lib:New({ profile = "retail", environment = environment })
local other = Lib:New({ profile = "retail", environment = environment })
assert(APR == nil and APRData == nil, "Loading autonomous unlocks cannot initialize APR")
local destination = { instanceID = 3, uiMapID = 105, x = 99, y = 44 }
local gate = { id = "karesh", from = { uiMapID = 101 },
    blockedRequirements = { minLevel = 80, any = { { quest = 12 }, { questActive = 12 } } } }
local function tick(session)
    for _ = 1, 10000 do
        local status, action, goal = session:Step(8, 1)
        if status ~= "planning" then return status, action, goal end
    end
    error("unlock failed to yield a result")
end
local session = data:CreateUnlockSession({ blockers = { gate }, destination = destination, clock = environment.clock })
destination.x = -1
assert(session:Step(1, 1) == "planning", "Catalogue discovery is incremental")
local status, action = tick(session)
assert(status == "action" and action.kind == "accept" and action.questID == 11)
assert(action.target.x == 300 and action.target.y == 400 and action.target.instanceID == 1,
    "The synthetic pickup retains its declared native world coordinates")
assert(action.label:find("Accepte", 1, true), "Library-owned French works without APR locales")
assert(action.prerequisitesKnown == false, "Unverified entry prerequisites remain visible to all consumers")
assert(tick(session) == "action", "Reaching a coordinate alone never accepts a quest")
active[11] = true
status, action = tick(session)
assert(status == "action" and action.kind == "turnin" and action.questID == 11)
completed[11], active[11] = true, nil
status, action = tick(session)
assert(action.kind == "accept" and action.questID == 12)
local restored = data:RestoreUnlockSession(session:ExportState(), { clock = environment.clock })
status, action = tick(restored)
assert(action.questID == 12 and action.kind == "accept", "Reload rereads progress from client observations")
active[12] = true
local original
status, action, original = tick(restored)
assert(status == "resume" and action == nil and original.x == 99 and original.uiMapID == 105,
    "Unlocking restores an immutable copy of the exact initial destination")
assert(tick(restored) == "resume", "Resume is stable until the consumer releases the session")
original.x = -99
assert(restored:ExportState().destination.x == 99, "Returned destinations cannot mutate the saved target")
original.x = 99

-- A complete-quest gate must include objective observations and actual reward.
completed, active = {}, {}
gate.blockedRequirements = { quest = 12 }
session = data:CreateUnlockSession({ blockers = { gate }, destination = original })
completed[11], active[12] = true, true
status, action = tick(session)
assert(action.kind == "objective" and #action.objectiveIndices == 2 and action.label:find("Objectif 1", 1, true))
active[12] = false
status, action = tick(session)
assert(action.kind == "accept" and action.questID == 12, "Abandoning a quest returns to its recorded pickup")
active[12] = true
objectives["12:1"] = true
status, action = tick(session)
assert(action.kind == "objective", "Every authored objective index must pass")
objectives["12:2"] = true
status, action = tick(session)
assert(action.kind == "turnin", "Objective completion is not quest reward")
completed[12] = true
assert(tick(session) == "resume")

-- Missing/unknown input never becomes a successful unlock.
completed, active, objectives = {}, {}, {}
unknown = true
session = data:CreateUnlockSession({ blockers = { gate }, destination = original })
assert(tick(session) == "missing_data")
assert(tick(session) == "missing_data", "A session without a viable plan remains safe on subsequent polls")
unknown = false
session:Retry()
assert(tick(session) == "action", "A host can retry after previously unknown client data becomes available")
gate.blockedRequirements = { notCondition = { quest = 12 } }
completed[12] = true
session = data:CreateUnlockSession({ blockers = { gate }, destination = original })
assert(tick(session) == "missing_data", "Negated completion never suggests completing the quest")
gate.blockedRequirements = { quest = 999999 }
session = data:CreateUnlockSession({ blockers = { gate }, destination = original })
assert(tick(session) == "missing_data")
session:Cancel(); assert(tick(session) == "cancelled")

local coverage = data:GetUnlockCoverage()
assert(#coverage.quests == 1 and #coverage.accesses > 0, "Quest, entrance, non-quest and action gaps ship in the library")
coverage.quests[1].gaps[1] = "changed"
assert(other:GetUnlockCoverage().quests[1].gaps[1] ~= "changed", "Consumers own their coverage copies")
local recipes = data:GetUnlockRoutes()
recipes[1].steps = {}
assert(#data:GetUnlockRoutes()[1].steps > 0, "Public catalogue copies cannot mutate a live session")

-- Declarative non-quest recipes and conjunctions use the same native runner.
Lib:RegisterData("test-unlocks", "custom", { unlockRoutes = {
    { id = "achievement", goal = { key = "achievement", value = 5 }, steps = {
        { kind = "interact", position = { space = "world", uiMapID = 101, instanceID = 1, x = 1, y = 2 },
            completeWhen = { achievement = 5 } },
    } },
    { id = "second", goal = { key = "achievement", value = 6 }, steps = {
        { kind = "interact", position = { space = "world", uiMapID = 101, instanceID = 1, x = 3, y = 4 },
            completeWhen = { achievement = 6 } },
    } },
} }, 1)
local custom = Lib:New({ profile = "test-unlocks", environment = environment })
gate.blockedRequirements = { all = { { achievement = 5 }, { achievement = 6 } } }
session = custom:CreateUnlockSession({ blockers = { gate }, destination = original })
status, action = tick(session)
assert(status == "action" and action.target.x == 1)
achievements[5] = true
status, action = tick(session)
assert(status == "action" and action.target.x == 3, "Conjunctions retain the other non-quest goal")
achievements[6] = true
assert(tick(session) == "resume")

-- Cycles do not recursively route back through the gate being unlocked.
achievements = {}
gate.id, gate.blockedRequirements = "parent", { achievement = 5 }
session = custom:CreateUnlockSession({ blockers = { gate }, destination = original })
assert(tick(session) == "action")
assert(session:BeginDetour({ gate }) == false)
local childGate = { id = "child", blockedRequirements = { achievement = 6 } }
assert(session:BeginDetour({ childGate }))
status, action = tick(session)
assert(action.target.x == 3)
achievements[6] = true
status, action = tick(session)
assert(status == "action" and action.target.x == 1, "Nested unlock resumes the parent action, preserving the final destination")
achievements[6] = nil
assert(session:BeginDetour({ childGate }))
assert(tick(session) == "action")
achievements[5] = true
assert(tick(session) == "resume", "An externally unlocked parent gate cancels unnecessary child detours immediately")

for _, locale in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
    language = locale
    for _, kind in ipairs({ "accept", "turnin", "objective", "waypoint", "missing", "interact" }) do
        local key = "NAVIGATION_UNLOCK_" .. kind
        assert(data:GetText(key) ~= key and data:GetText(key) ~= "", "All unlock wording is independently localized")
    end
end
local build = data:CreateUnlockBuild({ gate }); build:Cancel()
assert(build:Step() == "cancelled", "Cancellation releases incremental discovery")
assert(not pcall(function()
    Lib:RegisterData("invalid-unlock", "bad", { unlockRoutes = {
        { id = "bad", goal = { key = "quest", value = 1 }, steps = {
            { kind = "accept", questID = 1, position = { space = "map", uiMapID = 1, x = 20, y = 1 } },
        } },
    } })
end), "Malformed unlock positions are rejected at registration")
gate.canStart = function() error("Runtime closures must not enter persisted access evidence") end
session = data:CreateUnlockSession({ blockers = { gate }, destination = original })
assert(session:ExportState().blockers[1].canStart == nil)
print("Autonomous unlocks: synthetic chains, native progress, missing data, nested detours, reload, isolation and 11 locales passed")
