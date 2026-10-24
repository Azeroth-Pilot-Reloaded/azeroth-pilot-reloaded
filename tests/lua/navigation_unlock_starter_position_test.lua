-- The recorded pickup used to reuse Locus-Walker's turn-in point. The actual
-- starter is Alleria (227758), observed by the user at APR Coord -2423.3,2923.7.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
local active = {}
data.env.getCharacter = function() return { level = 90, faction = "Horde", class = "PALADIN", mapID = 2339 } end
data.env.isQuestCompleted = function(id) return id == 79573 end
data.env.isQuestActive = function(id) return active[id] == true end
data.env.isQuestCompletedOnAccount = function() return false end
data.env.isQuestAvailable = function() return nil end
data.env.getNPCName = function(id) if id == 227758 then return "Alleria Coursevent" end end
data.env.getLocale = function() return "frFR" end
local run = data:CreateUnlockSession({ destination = { uiMapID = 2472, instanceID = 2738, x = -1343, y = -515.6 },
    blockers = { { id = "karesh", from = { uiMapID = 2248 }, blockedRequirements = { questActive = 84957 } } } })
local function tick()
    for _ = 1, 3000 do
        local status, action = run:Step(64, 1)
        if status ~= "planning" then return status, action end
    end
    error("Starter lookup failed to finish")
end
local status, action = tick()
assert(status == "action" and action.kind == "accept" and action.questID == 84956)
assert(action.npcID == 227758 and action.label:find("Alleria Coursevent", 1, true),
    "The pickup names its sourced starter rather than leaving two nearby NPCs ambiguous")
assert(action.target.instanceID == 2552 and action.target.uiMapID == 2248)
assert(action.target.x == 2923.7 and action.target.y == -2423.3,
    "Alleria's observed APR coordinates are converted to native axes exactly once")
active[84956] = true
status, action = tick()
assert(status == "action" and action.kind == "turnin" and action.questID == 84956)
assert(action.target.x == 2923 and action.target.y == -2418.2,
    "Rewarding the quest still guides to the separate Locus-Walker position")
print("Quest starter position: Alleria pickup and Locus-Walker turn-in have separate sourced coordinates and localized actor guidance")
