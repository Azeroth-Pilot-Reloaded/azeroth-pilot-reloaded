-- Synthetic acquisition graph; production campaign edits do not change these expectations.
-- Synthetic acquisition sources contain shared prerequisites and cycles.
-- A blank character reaches the first available action within a bounded
-- number of cooperative slices, without pre-observing any NPC quest offer.
APR, APRData, LibStub = nil, nil, nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a"); manifest:close()
for file in xml:gmatch('file="([^"]+)"') do if not file:match("^Data/") then dofile(root .. file) end end
local Lib = LibStub("LibAPRNavigation-1.0")
Lib:RegisterData("retail", "fixture", dofile("tests/lua/navigation_unlock_test_catalog.lua"))
local completed, active, offers, reads = {}, {}, 0, 0
local env = {
    getCharacter = function() return { faction = "Horde", class = "PALADIN", raceID = 10,
        level = 90, mapID = 102, inGroup = false, indoors = false, inInstance = false } end,
    isQuestCompleted = function(id) reads = reads + 1; return completed[id] == true end,
    isQuestActive = function(id) return active[id] == true end,
    isQuestCompletedOnAccount = function() return false end,
    isQuestAvailable = function() offers = offers + 1; return nil end,
    isQuestReadyForTurnIn = function() return false end,
    isQuestObjectiveCompleted = function() return false end,
    isAchievementCompleted = function() return false end,
    getCurrencyQuantity = function() return 0 end,
    getReputationAmount = function(id) return 0 end,
    getReputationStanding = function() return 4 end,
    getServerTime = function() return 1800000000 end,
    isChromieTimeActive = function() return false end,
    getMapInfo = function() return { mapType = 3, parentMapID = 0 } end,
    mapToWorld = function(map) return map == 106 and 4 or 2 end,
}
local data = Lib:New({ profile = "retail", environment = env })
assert(#data:GetUnlockRoutes() == 709, "The cold-start regression exercises the controlled acquisition graph")
local destination = { uiMapID = 104, instanceID = 3, x = -1343, y = -515.6 }
local run = data:CreateUnlockSession({ destination = destination, blockers = {
    { id = "cold-karesh", from = { uiMapID = 101 }, blockedRequirements = {
        minLevel = 80, any = { { quest = 12 }, { questActive = 12 } },
    } },
} })
local function nextAction(session, limit)
    for slice = 1, limit do
        local status, action = session:Step(16, 1)
        if status ~= "planning" then return status, action, slice end
    end
    error("Cold unlock planning revisited shared dependencies beyond its operation bound")
end
local status, action, slices = nextAction(run, 1500)
assert(status == "action" and action.questID == 15 and action.kind == "accept")
assert(action.target and action.target.uiMapID == 106 and action.target.instanceID == 4)
assert(action.target.x == -500 and action.target.y == 600, "The first pickup keeps its actual recorded position")
assert(offers > 0 and offers < 4000 and reads < 100000,
    "Shared prerequisite scoring does not repeatedly poll every source's client flags")

-- Progress invalidates the transient ranking snapshot. A newly observed direct
-- gate prerequisite must retire the deep detour instead of using stale ranks.
completed[13] = true
run:Retry()
status, action = nextAction(run, 1500)
assert(status == "action" and action.questID == 11 and action.kind == "accept")
assert(run:ExportState().destination.uiMapID == 104)
assert(APR == nil and APRData == nil)
print("Cold unlock: controlled acquisition graph reaches fixture quest 15 in " .. slices
    .. " bounded slices; progress invalidates shared scores and resumes the shorter chain")
