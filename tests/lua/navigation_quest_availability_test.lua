local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
local env = data.env
local open, mode, npc, offers = false, "gossip", 227758, {}
GossipFrame = { IsShown = function() return open and mode == "gossip" end }
QuestFrameGreetingPanel = { IsShown = function() return open and mode == "greeting" end }
QuestFrameDetailPanel = { IsShown = function() return open and mode == "detail" end }
function UnitGUID() return "Creature-0-1-2-3-" .. npc .. "-0000000000" end
C_GossipInfo = { GetAvailableQuests = function() return offers end }
function GetNumAvailableQuests() return #offers end
function GetAvailableQuestInfo(index) return "Quest", 1, 1, false, offers[index].questID end
function GetQuestID() return offers[1] and offers[1].questID end
local acceptance = { starterNPCIDs = { 227758 } }
offers = { { questID = 84956 } }
assert(env.isQuestAvailable(84956, acceptance) == nil, "Closed NPC interactions never provide stale offers")
open = true
assert(env.isQuestAvailable(84956, acceptance) == true)
offers = {}
assert(env.isQuestAvailable(84956, acceptance) == false, "The matching NPC's complete offer list can prove absence")
npc = 100
assert(env.isQuestAvailable(84956, acceptance) == nil, "A different NPC cannot prove a quest globally unavailable")
npc, mode, offers = 227758, "greeting", { { questID = 84956 } }
assert(env.isQuestAvailable(84956, acceptance) == true, "The greeting API's fifth result identifies the offer")
offers = {}
assert(env.isQuestAvailable(84956, acceptance) == false)
mode, offers = "detail", { { questID = 84956 } }
assert(env.isQuestAvailable(84956, acceptance) == true)
offers = { { questID = 100 } }
assert(env.isQuestAvailable(84956, acceptance) == nil, "Another quest detail is not a complete NPC offer list")
mode = "gossip"
C_GossipInfo.GetAvailableQuests = function() error("Client data restricted") end
assert(env.isQuestAvailable(84956, acceptance) == nil)
print("Quest availability adapter: current server offers, NPC identity, greetings, details, closed UI and restricted APIs passed")
