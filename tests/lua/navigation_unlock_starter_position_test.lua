-- Synthetic acquisition graph; production campaign edits do not change these expectations.
-- Pickup and reward have distinct actors and positions in the fixture.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load(dofile("tests/lua/navigation_unlock_test_catalog.lua"))
local active = {}
data.env.getCharacter = function() return { level = 90, faction = "Horde", class = "PALADIN", mapID = 102 } end
data.env.isQuestCompleted = function(id) return id == 13 end
data.env.isQuestActive = function(id) return active[id] == true end
data.env.isQuestCompletedOnAccount = function() return false end
data.env.isQuestAvailable = function() return nil end
data.env.getNPCName = function(id) if id == 21 then return "PNJ de départ" end end
data.env.getLocale = function() return "frFR" end
local run = data:CreateUnlockSession({ destination = { uiMapID = 104, instanceID = 3, x = -1343, y = -515.6 },
    blockers = { { id = "karesh", from = { uiMapID = 101 }, blockedRequirements = { questActive = 12 } } } })
local function tick()
    for _ = 1, 3000 do
        local status, action = run:Step(64, 1)
        if status ~= "planning" then return status, action end
    end
    error("Starter lookup failed to finish")
end
local status, action = tick()
assert(status == "action" and action.kind == "accept" and action.questID == 11)
assert(action.npcID == 21 and action.label:find("PNJ de départ", 1, true),
    "The pickup names its sourced starter rather than leaving two nearby NPCs ambiguous")
assert(action.target.instanceID == 1 and action.target.uiMapID == 101)
assert(action.target.x == 300 and action.target.y == 400,
    "The pickup keeps its independently specified native coordinates")
active[11] = true
status, action = tick()
assert(status == "action" and action.kind == "turnin" and action.questID == 11)
assert(action.target.x == 350 and action.target.y == 450,
    "Rewarding the quest guides to the separate reward position")
print("Quest actors: distinct pickup/reward positions and localized actor guidance passed")
