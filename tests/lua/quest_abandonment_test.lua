-- Journal selection and the prepared abandonment target are separate client state.
local L = {}
function LibStub()
    return { GetLocale = function() return L end }
end
APR = {}

local quests = { [41001] = true, [41002] = true }
local selected, abandonTarget = 41001, 41001
local events = {}
C_QuestLog = {
    IsOnQuest = function(id) return quests[id] == true end,
    SetSelectedQuest = function(id)
        selected = id
        events[#events + 1] = "select:" .. id
    end,
    SetAbandonQuest = function()
        abandonTarget = selected
        events[#events + 1] = "prepare:" .. abandonTarget
    end,
    AbandonQuest = function()
        assert(abandonTarget and quests[abandonTarget], "Abandonment needs a prepared live quest")
        events[#events + 1] = "abandon:" .. abandonTarget
        quests[abandonTarget], abandonTarget = nil, nil
    end,
}
dofile("APR-Core/utils/QuestUtils.lua")

APR:LeaveQuest(41002)
assert(quests[41001] and not quests[41002], "Abandon the requested quest while preserving an older prepared target")
assert(
    table.concat(events, ",") == "select:41002,prepare:41002,abandon:41002",
    "Select, prepare and abandon must target the same quest"
)

events = {}
APR:LeaveQuest(41002)
APR:LeaveQuest(nil)
assert(#events == 0 and quests[41001], "Missing quests must not mutate native selection or abandonment")

APR:LeaveQuest(41001)
assert(
    not quests[41001] and table.concat(events, ",") == "select:41001,prepare:41001,abandon:41001",
    "A later abandonment prepares its own target again"
)

print("Quest abandonment: separate native selection/target, absent quests and repeated calls passed")
