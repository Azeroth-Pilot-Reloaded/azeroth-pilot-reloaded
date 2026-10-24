local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
local adapter, env = APR.NavigationAdapter, data.env
local renown, raw, reaction, threshold = 2, 12000, 5, 9000
C_MajorFactions = { GetMajorFactionData = function(id) if id == 2600 then return { renownLevel = renown } end end }
C_Reputation = { GetFactionDataByID = function() return {
    reaction = reaction, currentStanding = raw, currentReactionThreshold = threshold,
} end }
C_GossipInfo = {
    GetFriendshipReputation = function(id) return { friendshipFactionID = id == 200 and 200 or 0 } end,
    GetFriendshipReputationRanks = function() return { currentLevel = 2 } end,
}
assert(env.getReputationStanding(2600) == 5 and env.getReputationAmount(2600) == 2,
    "Native major-faction level must not be confused with reaction rank")
local character = env.getCharacter()
assert(data:CheckRequirements({ reputation = { factionID = 2600, minNativeValue = 3 } }, character) == false)
renown = 3
assert(data:CheckRequirements({ reputation = { factionID = 2600, minNativeValue = 3 } }, character) == true)
assert(data:CheckRequirements({ reputation = { factionID = 10, standing = 5, minStandingAmount = 3001 } }, character) == false)
assert(data:CheckRequirements({ reputation = { factionID = 10, standing = 5, minStandingAmount = 3000 } }, character) == true)
reaction = 6
assert(data:CheckRequirements({ reputation = { factionID = 10, standing = 5, minStandingAmount = 6000 } }, character) == true)
assert(data:CheckRequirements({ reputation = { factionID = 10, minNativeValue = 15000 } }, character) == false)
assert(env.getReputationAmount(200) == 2, "A friendship's native amount is its rank, not ordinary reputation points")
assert(data:CheckRequirements({ reputation = { factionID = 200, minNativeValue = 3 } }, character) == false)

function GetServerTime() return 1800000000 end
C_PlayerInfo = { IsPlayerInChromieTime = function() return false end }
assert(data:CheckRequirements({ minTime = 1534197600 }, character) == true)
assert(data:CheckRequirements({ chromieTime = true }, character) == false)
C_PlayerInfo.IsPlayerInChromieTime = function() error("Restricted") end
assert(data:CheckRequirements({ chromieTime = true }, character) == nil)
C_SkillInfo = { GetSkillLineInfoByID = function(id) if id == 164 then return { skillID = id, rank = 75 } end end }
assert(env.getSkillLevel(164) == 75 and env.getSkillLevel(999) == 0)
C_SkillInfo.GetSkillLineInfoByID = function() error("Restricted") end
assert(env.getSkillLevel(164) == nil)

C_ScenarioInfo = {
    GetScenarioInfo = function() return { scenarioID = 2388 } end,
    GetCriteriaInfoByStep = function() return { criteriaID = 65266, completed = false, quantity = 0, totalQuantity = 1 } end,
}
local scenario = { scenarioID = 2388, stepID = 6910, criteriaID = 65266, criteriaIndex = 2 }
assert(env.getScenarioCriteria(scenario).completed == false, "An unfinished observed criterion is false, not unknown")
scenario.scenarioID = 1
assert(env.getScenarioCriteria(scenario) == nil, "A different scenario provides no completion evidence")

-- A negative server offer survives closing the same dialogue until progress
-- changes; another NPC's open dialogue is not a global negative observation.
local open = true
GossipFrame = { IsShown = function() return open end }
C_GossipInfo = { GetAvailableQuests = function() return {} end }
function UnitGUID() return "Creature-0-1-2-3-100-0000000000" end
local acceptance = { starterNPCIDs = { 100 } }
assert(env.isQuestAvailable(7, acceptance) == false)
open = false
assert(env.isQuestAvailable(7, acceptance) == false)
adapter.frame.OnEvent(adapter.frame, "QUEST_TURNED_IN", 6)
assert(env.isQuestAvailable(7, acceptance) == nil)

-- Only a successful manually observed action in the current session advances
-- a standalone item/spell instruction. It does not assert any quest flag.
local step = { kind = "action", actionType = "spell", parameters = 123,
    _unlockStepID = "recipe:1", _unlockObservationToken = 1 }
env.watchUnlockAction(step)
assert(env.isUnlockActionComplete(step) == nil)
adapter.frame.OnEvent(adapter.frame, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 321)
assert(env.isUnlockActionComplete(step) == nil)
adapter.frame.OnEvent(adapter.frame, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 123)
assert(env.isUnlockActionComplete(step) == true)
step._unlockObservationToken = 2
assert(env.isUnlockActionComplete(step) == nil, "A retired session's successful cast cannot complete a new instruction")
print("Unlock adapter observations: native reputation/ranks, time, Chromie, skill, scenario tri-state, negative offers and manual receipts passed")
