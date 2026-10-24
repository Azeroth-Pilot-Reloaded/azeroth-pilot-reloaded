local fixture = dofile("tests/lua/navigation_fixture.lua")
local art = 100
C_Map.GetMapArtID = function() return art end
local data = fixture:Load()
local adapter = APR.NavigationAdapter
local refreshes = 0
APR.navigation = { ForceRefresh = function() refreshes = refreshes + 1 end }
adapter.frame.OnEvent(adapter.frame, "QUEST_LOG_UPDATE")
local definition = { space = "map", uiMapID = 2395, x = 0.1, y = 0.2 }
local first = assert(data:ResolvePosition(definition, {}))
local positions = data.positions
local graph = {}
data.zoneGraph = graph
for _ = 1, 20 do
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "BAG_UPDATE_DELAYED", "CURRENCY_DISPLAY_UPDATE", "GOSSIP_SHOW", "GOSSIP_CLOSED" }) do
        adapter.frame.OnEvent(adapter.frame, event)
    end
end
assert(refreshes >= 100 and data.zoneGraph == graph and data.positions == positions
    and data:ResolvePosition(definition, {}) == first,
    "Character/UI events must refresh navigation without discarding static geometry")

local completed = false
C_QuestLog.IsQuestFlaggedCompleted = function() return completed end
assert(data:CheckRequirements({ quest = 1 }, {}) == false)
completed = true
adapter.frame.OnEvent(adapter.frame, "QUEST_TURNED_IN", 1)
assert(data:CheckRequirements({ quest = 1 }, {}) == true and data.zoneGraph == graph,
    "Current server quest flags remain authoritative while geometry is reused")

art = 101
adapter.frame.OnEvent(adapter.frame, "QUEST_TURNED_IN", 1)
assert(data.zoneGraph == nil and data.positions ~= positions,
    "An actual map-art change invalidates the zone index and normalized endpoints")
local phased = assert(data:ResolvePosition(definition, {}))
data.zoneGraph = graph
adapter.frame.OnEvent(adapter.frame, "QUEST_LOG_UPDATE")
assert(data.zoneGraph == graph and data:ResolvePosition(definition, {}) == phased)

C_Map.GetMapArtID = nil
adapter.frame.OnEvent(adapter.frame, "QUEST_TURNED_IN", 1)
assert(data.zoneGraph == nil, "Unreadable map art retains conservative phase-transition invalidation")
data.zoneGraph = graph
adapter.frame.OnEvent(adapter.frame, "QUEST_LOG_UPDATE")
assert(data.zoneGraph == graph, "Unreadable map art does not make every UI event a world reload")
adapter.frame.OnEvent(adapter.frame, "NEIGHBORHOOD_MAP_DATA_UPDATED")
assert(data.zoneGraph == nil)
print("Adapter geometry cache: 100 character/UI events retain static topology; fresh quest flags, real phase changes and unavailable-art recovery passed")
