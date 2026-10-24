-- Collection goals follow the live profession rank, including zero remaining work.
local rank, carried, advanced = 7, 0, 0
local L = { LOOT_ITEM = "Collect %s" }
function LibStub() return { GetLocale = function() return L end } end
UNKNOWN, format = "Unknown", string.format
C_SkillInfo = { GetSkillLineInfoByID = function(id)
    assert(id == 185)
    return { rank = rank, maxRank = 75 }
end }
C_Item = { GetItemCount = function() return carried end, GetItemInfo = function() return "Reagent" end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
APR = { PlayerID = "player", stepHandlers = {}, Buff = { RemoveAllBuffIcon = function() end } }
APRData = { player = {} }
local displayed
APR.currentStep = { AddQuestSteps = function(_, _, text) displayed = text end }
function APR:NextQuestStep() advanced = advanced + 1 end
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/utils/LootUtils.lua")
dofile("APR-Core/features/questing/StepInstructions.lua")

local item = { itemID = 769, quantityFromSkill = { skill = "cooking", rank = 10 } }
assert(APR:GetCollectionRequiredQuantity(item) == 3)
assert(not APR:IsRouteCollectionComplete(item))
assert(not APR.stepHandlers.RenderRequirements({ LootItems = { item } }, true, 1))
assert(displayed == "Collect Reagent (0/3)" and advanced == 0)
carried = 2
rank = 8
assert(APR:GetCollectionRequiredQuantity(item) == 2)
assert(APR.stepHandlers.RenderRequirements({ LootItems = { item } }, true, 1))
assert(advanced == 1 and APR:IsRouteCollectionComplete(item))
rank, carried = 10, 0
assert(APR:GetCollectionRequiredQuantity(item) == 0)
assert(APR.stepHandlers.RenderRequirements({ LootItems = { item } }, true, 1))
rank = 20
assert(APR:GetCollectionRequiredQuantity(item) == 0, "A completed skill goal cannot require another reagent")
rank = 1
item.quantity = 4
assert(APR:GetCollectionRequiredQuantity(item) == 4, "An explicit quantity caps the skill requirement")
assert(APR:GetCollectionRequiredQuantity({ itemID = 769 }) == 1)
assert(APR:GetCollectionRequiredQuantity({ itemID = 769, quantity = 5 }) == 5)
print("Skill collection: live rank, decreasing quantities, completion without reagents, caps and current-step rendering passed")
