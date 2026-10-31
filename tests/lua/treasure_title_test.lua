-- Synthetic treasure actions use loaded quest titles, including late data.
local title, completed, advanced, row, details = nil, false, 0
local locale = {GET_TREASURE = "Loot the treasure"}
function LibStub() return {GetLocale = function() return locale end} end
APRData = {player = {synthetic = 1}}
APR = {PlayerID = "player", ActiveRoute = "synthetic", stepHandlers = {}, Debug = function() end,
    GetQuestTitle = function(_, id) assert(id == 990001); return title end,
    NextQuestStep = function() advanced = advanced + 1 end,
    currentStep = {
        AddQuestSteps = function(_, id, text, kind) row = {id = id, text = text, kind = kind} end,
        AddQuestStepsWithDetails = function(_, key, text, entries) row = {id = key, text = text}; details = entries end,
    },
}
UNKNOWN = "Unknown"
C_QuestLog = {IsQuestFlaggedCompleted = function() return completed end}
C_Item = {GetItemInfo = function() return "Invented reward" end}
dofile("APR-Core/features/questing/StepActionHandlers.lua")
local step = {Treasure = {questID = 990001}}
APR.stepHandlers.Treasure(step, true, 1)
assert(row.text == "Loot the treasure" and row.id == 990001)
title = "Forgotten chest"
APR.stepHandlers.Treasure(step, true, 1)
assert(row.text == "Loot the treasure: Forgotten chest" and row.kind == "Treasure")
step.Treasure.itemID = 990002
APR.stepHandlers.Treasure(step, true, 1)
assert(row.text == "Loot the treasure: Forgotten chest" and details[1].itemName == "Invented reward")
row = nil
APR.stepHandlers.Treasure(step, false, 1)
assert(not row and advanced == 0, "Hidden passes neither render nor advance incomplete treasures")
completed = true
assert(APR.stepHandlers.Treasure(step, true, 1) and advanced == 1 and not row)
print("Treasure: loaded/late quest titles, reward details, hidden passes and completion passed")
