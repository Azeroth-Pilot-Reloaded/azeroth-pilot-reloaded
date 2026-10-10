local function noop() end
function LibStub() return {GetLocale = function() return {} end} end
function wipe(t) for k in pairs(t) do t[k] = nil end end
local bag, skill, professions = 0, 0, 0
APR = { PlayerID = 'p', ActiveRoute = 'r', RouteQuestStepList = {}, Debug = noop }
APRData = {p = {r = 1}}
function APR:IsDelveRoute() return false end
function APR:GetPrimaryProfessionCount() return professions end
function UnitLevel() return 5 end
C_Item = { GetItemCount = function() return bag end }
C_Map = { GetBestMapForUnit = function() return 1411 end }
C_SkillInfo = { GetSkillLineInfoByID = function() return {rank = skill} end }
dofile('APR-Core/data/models/Enums.lua')
dofile('APR-Core/utils/PlayerUtils.lua')
dofile('APR-Core/utils/RouteUtils.lua')
dofile('APR-Core/utils/RouteConditions.lua')
function APR:GetPrimaryProfessionCount() return professions end
dofile('APR-Core/features/questing/RouteManager.lua')
local group = {repeatable = true, conditions = {
    ItemCount = {itemID = 247840, count = 1}, Skill = {skillID = 186, operator = '<', rank = 15},
    AnyOf = {{Skill = {skillID = 186, operator = '>=', rank = 1}}, {SkipForPrimaryProfessions = 2}}
}, steps = {{UseItem = {itemID = 247840}, _index = 3}}}
local main = {Note = {'Continue'}}
APR.RouteQuestStepList.r = {steps = {main, {RouteCompleted = true}}, parallelSteps = {group}}
assert(#APR:GetRouteSteps('r') == 2, 'No book: no interruption')
bag, professions = 1, 2
assert(#APR:GetRouteSteps('r') == 2, 'Two other professions: do not offer an unusable book')
skill = 1
local steps = APR:GetRouteSteps('r')
assert(#steps == 3 and steps[1].UseItem, 'Owned profession can still be improved with two slots occupied')
assert(APR:AreConditionalFiltersMet(steps[1]), 'Group conditions remain live on the step')
APRData.p.r = 2
assert(#APR:GetRouteSteps('r') == 3, 'Cast event before bag update must not immediately reactivate')
bag = 0
assert(not APR:AreConditionalFiltersMet(steps[1]), 'Consumed or removed item skips the pending action')
APR:GetRouteSteps('r')
bag, skill = 1, 3
steps = APR:GetRouteSteps('r')
assert(#steps == 4 and steps[2].UseItem and steps[3] == main, 'A later reward inserts a fresh action before current main step')
APR:InvalidateEffectiveRouteStepsCache('r')
assert(#APR:GetRouteSteps('r') == 4, 'Rebuilding after reload preserves both activations without duplicates')
assert(not group.steps[1].AllOf and not group.steps[1]._parallelGroupIndex, 'Saved route definitions remain immutable')
APRData.p.r = 3
bag = 0; APR:GetRouteSteps('r')
bag, skill = 1, 15
assert(#APR:GetRouteSteps('r') == 4, 'No further use at the skill cap')
print('Profession books: possession, profession slots, live conditions, repeat rewards and reload passed')
