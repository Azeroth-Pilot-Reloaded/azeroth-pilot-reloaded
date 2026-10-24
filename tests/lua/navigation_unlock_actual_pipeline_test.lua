-- The native offer is authoritative even when a dialogue addon hides Blizzard's
-- GossipFrame. A GOSSIP_SHOW interaction plus the matching NPC identifies the
-- live offer list; frame visibility is presentation, not server availability.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 2339
local data = fixture:Load()
local env, adapter = data.env, APR.NavigationAdapter
local completed = { [79573] = true }
C_QuestLog.IsQuestFlaggedCompleted = function(id) return completed[id] == true end
C_QuestLog.IsOnQuest = function() return false end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return false end
GossipFrame = { IsShown = function() return false end }
QuestFrameGreetingPanel = { IsShown = function() return false end }
QuestFrameDetailPanel = { IsShown = function() return false end }
local npcID, offers = 227758, {}
function UnitGUID(unit)
    if unit == "npc" then return "Creature-0-1-2-3-" .. npcID .. "-0000000000" end
end
C_GossipInfo = { GetAvailableQuests = function() return offers end }
local acceptance
for _, recipe in ipairs(data:GetUnlockRoutes()) do
    if recipe.id == "quest:84956" then acceptance = recipe.steps[1].acceptance; break end
end
assert(acceptance and acceptance.starterNPCIDs[1] == 227758)
assert(env.isQuestAvailable(84956, acceptance) == nil, "A closed dialogue cannot provide a stale server offer")
adapter.frame.OnEvent(adapter.frame, "GOSSIP_SHOW")
assert(env.isQuestAvailable(84956, acceptance) == false,
    "The matching NPC's empty live offer list is negative evidence even when a custom UI hides GossipFrame")
offers = { { questID = 84956 } }
assert(env.isQuestAvailable(84956, acceptance) == true,
    "A real positive offer is visible through custom dialogue presentation as well")
offers = {}
npcID = 233603
assert(env.isQuestAvailable(84956, acceptance) == nil,
    "Another phased NPC identity cannot prove the declared starter's quest globally unavailable")
adapter.frame.OnEvent(adapter.frame, "GOSSIP_CLOSED")
assert(env.isQuestAvailable(84956, acceptance) == nil)
print("Actual offer lifecycle: native Gossip events and NPC identity survive custom UI frame visibility")
