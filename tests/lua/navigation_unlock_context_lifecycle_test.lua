-- Quest-interaction context is not the same as ordinary gossip context. The
-- native QuestFrame identifies its actor through `questnpc`, and a no-op quest
-- log/UI refresh cannot turn a directly rejected offer back into an unknown.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load()
local env, adapter = data.env, APR.NavigationAdapter
local acceptance
for _, recipe in ipairs(data:GetUnlockRoutes()) do
    if recipe.id == "quest:84956" then acceptance = recipe.steps[1].acceptance; break end
end
assert(acceptance and acceptance.starterNPCIDs[1] == 227758)
local open, mode, npc, offers = false, "gossip", 227758, {}
GossipFrame = { IsShown = function() return open and mode == "gossip" end }
QuestFrameGreetingPanel = { IsShown = function() return open and mode == "greeting" end }
QuestFrameDetailPanel = { IsShown = function() return false end }
function UnitGUID(unit)
    local expected = mode == "greeting" and "questnpc" or "npc"
    if unit == expected then return "Creature-0-1-2-3-" .. npc .. "-0000000000" end
end
C_GossipInfo = { GetAvailableQuests = function() return offers end }
function GetNumAvailableQuests() return #offers end
function GetAvailableQuestInfo(index)
    return false, nil, false, false, offers[index].questID
end
local failures = {}
local function check(name, fn)
    local ok, reason = pcall(fn)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(reason) end
end

check("native greeting actor token", function()
    open, mode, offers = true, "greeting", {}
    assert(env.isQuestAvailable(84956, acceptance) == false,
        "A complete empty greeting from the sourced questnpc proves this offer is absent")
    offers = { { questID = 84956 } }
    assert(env.isQuestAvailable(84956, acceptance) == true)
end)

check("rejection survives no-op quest log refresh", function()
    open, mode, offers = true, "gossip", {}
    assert(env.isQuestAvailable(84956, acceptance) == false)
    open = false
    assert(env.isQuestAvailable(84956, acceptance) == false)
    adapter.frame.OnEvent(adapter.frame, "QUEST_LOG_UPDATE")
    assert(env.isQuestAvailable(84956, acceptance) == false,
        "An unchanged quest log event cannot erase a direct server rejection after the dialogue closes")
end)

check("rejection survives unrelated currency refresh", function()
    open, mode, offers = true, "gossip", {}
    assert(env.isQuestAvailable(84956, acceptance) == false)
    open = false
    adapter.frame.OnEvent(adapter.frame, "CURRENCY_DISPLAY_UPDATE", 999999)
    assert(env.isQuestAvailable(84956, acceptance) == false,
        "Refreshing an unrelated currency is not evidence that this quest offer became available")
end)

check("native interaction survives hidden Blizzard panels", function()
    open, mode, npc, offers = false, "gossip", 227758, {}
    adapter.frame.OnEvent(adapter.frame, "QUEST_TURNED_IN", 1)
    assert(env.isQuestAvailable(84956, acceptance) == nil)
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_SHOW")
    assert(env.isQuestAvailable(84956, acceptance) == false,
        "Native gossip events provide observations even when another addon hides GossipFrame")
    local evidence = env.getQuestAvailabilityEvidence(84956)
    assert(evidence.npcID == 227758 and evidence.questID == 84956 and evidence.offered == false
        and evidence.kind == "gossip" and evidence.source == "GOSSIP_SHOW")
    evidence.npcID = 1
    assert(env.getQuestAvailabilityEvidence(84956).npcID == 227758, "Diagnostics receive detached technical evidence")
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_CLOSED")
    adapter.frame.OnEvent(adapter.frame, "QUEST_LOG_UPDATE")
    assert(env.isQuestAvailable(84956, acceptance) == false)
end)

check("known prerequisite progress retires rejection", function()
    local campaignDone = true
    env.isQuestCompleted = function(id) return id == 79573 and campaignDone end
    mode, offers = "gossip", {}
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_SHOW")
    assert(env.isQuestAvailable(84956, acceptance) == false)
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_CLOSED")
    campaignDone = false
    assert(env.isQuestAvailable(84956, acceptance) == nil,
        "A changed known prerequisite invalidates the old availability snapshot")
    assert(env.getQuestAvailabilityEvidence(84956).invalidatedBy == "requirements_changed")
end)

check("native quest context and positive offer", function()
    mode, offers = "greeting", { { questID = 84956 } }
    adapter.frame.OnEvent(adapter.frame, "QUEST_GREETING")
    assert(env.isQuestAvailable(84956, acceptance) == true)
    local evidence = env.getQuestAvailabilityEvidence(84956)
    assert(evidence.source == "QUEST_GREETING" and evidence.npcID == 227758 and evidence.offered == true)
    adapter.frame.OnEvent(adapter.frame, "QUEST_FINISHED")
    assert(env.isQuestAvailable(84956, acceptance) == nil)
end)

check("different NPC is diagnostic evidence, not rejection", function()
    mode, npc, offers = "gossip", 233603, { { questID = 999 } }
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_SHOW")
    assert(env.isQuestAvailable(84956, acceptance) == nil,
        "A different actor cannot prove the sourced Alleria offer globally unavailable")
    local evidence = env.getQuestAvailabilityEvidence(84956)
    assert(evidence.npcID == 233603 and evidence.offered == nil and evidence.reason == "not_starter")
    assert(evidence.offeredQuestIDs[1] == 999)
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_CLOSED")
    assert(env.isQuestAvailable(84956, acceptance) == nil)
end)

check("catalogue probes cannot evict server rejection", function()
    mode, npc, offers = "gossip", 227758, {}
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_SHOW")
    assert(env.isQuestAvailable(84956, acceptance) == false)
    adapter.frame.OnEvent(adapter.frame, "GOSSIP_CLOSED")
    for id = 100001, 100250 do assert(env.isQuestAvailable(id, { requirements = {} }) == nil) end
    assert(env.isQuestAvailable(84956, acceptance) == false,
        "Unrelated unknown probes from a preflight scan cannot erase an observed rejection")
end)

assert(#failures == 0, table.concat(failures, "\n"))
print("Unlock interaction context: native questnpc identity and negative offers survive unchanged or unrelated UI events")
