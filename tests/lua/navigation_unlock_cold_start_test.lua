-- Real generated acquisition sources contain shared prerequisites and cycles.
-- A blank character must reach the first real campaign action within a bounded
-- number of cooperative slices, without pre-observing any NPC quest offer.
APR, APRData, LibStub = nil, nil, nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a"); manifest:close()
for file in xml:gmatch('file="([^"]+)"') do dofile(root .. file) end
local Lib = LibStub("LibAPRNavigation-1.0")
local completed, active, offers, reads = {}, {}, 0, 0
local env = {
    getCharacter = function() return { faction = "Horde", class = "PALADIN", raceID = 10,
        level = 90, mapID = 2339, inGroup = false, indoors = false, inInstance = false } end,
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
    mapToWorld = function(map) return map == 629 and 1220 or 2601 end,
}
local data = Lib:New({ profile = "retail", environment = env })
assert(#data:GetUnlockRoutes() >= 600, "The cold-start regression exercises the full acquisition catalogue")
local destination = { uiMapID = 2472, instanceID = 2738, x = -1343, y = -515.6 }
local run = data:CreateUnlockSession({ destination = destination, blockers = {
    { id = "cold-karesh", from = { uiMapID = 2248 }, blockedRequirements = {
        minLevel = 80, any = { { quest = 84957 }, { questActive = 84957 } },
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
assert(status == "action" and action.questID == 78717 and action.kind == "accept")
assert(action.target and action.target.uiMapID == 629 and action.target.instanceID == 1220)
assert(action.target.x == -844.7 and action.target.y == 4467.6, "The first pickup keeps its actual recorded position")
assert(offers > 0 and offers < 4000 and reads < 100000,
    "Shared prerequisite scoring does not repeatedly poll every source's client flags")

-- Progress invalidates the transient ranking snapshot. A newly observed direct
-- gate prerequisite must retire the deep detour instead of using stale ranks.
completed[79573] = true
run:Retry()
status, action = nextAction(run, 1500)
assert(status == "action" and action.questID == 84956 and action.kind == "accept")
assert(run:ExportState().destination.uiMapID == 2472)
assert(APR == nil and APRData == nil)
print("Cold unlock: full generated acquisition graph reaches sourced 78717 in " .. slices
    .. " bounded slices; progress invalidates shared scores and resumes the shorter chain")
