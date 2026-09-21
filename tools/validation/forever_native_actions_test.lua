-- Exercise real predicates/action handlers against changing game state.
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
APR = { RouteQuestStepList = {}, ActiveRoute = 'test', PlayerID = 'player', ActiveQuests = {},
    currentStep = {}, QUEST_STATUS = { COMPLETE = 1 } }
APRData = { player = { test = 1 } }
function APR.currentStep:AddQuestSteps() end
function APR.currentStep:AddStepButton() end
function APR.currentStep:AddRaidIconButton() end
function APR:ResolveStepText(text) return text end
function APR:GetCurrentStepToken(route, index) return route .. ':' .. index end
function APR:NextQuestStep() APRData.player.test = APRData.player.test + 1 end
function APR:UpdateStep() end
function APR:GetStep(index) return self.RouteQuestStepList.test.steps[index] end
function APR:IsDelveRoute() return false end
function APR:GetStepString() return 'Objective' end
local map, area, bind, clock, skill, spellKnown, target = 1, 'Goldshire', 'Goldshire', 100, 10, false, 2163
local onQuest, rewarded, finished = true, false, false
local bags, bankItems, cursor, mutated = {}, {}, nil, 0
local lockedCombat = false
function GetTime() return clock end
function UnitLevel() return 20 end
function UnitPosition() return 0, 0 end
function InCombatLockdown() return lockedCombat end
function GetSubZoneText() return area end
function GetZoneText() return 'Elwynn Forest' end
function GetBindLocation() return bind end
function GetNumSkillLines() return 1 end
function GetSkillLineInfo() return 'Cuisine', false, false, skill, 0, 0, 75 end
function GetInventoryItemID(_, slot) return slot == 16 and 100 or nil end
function tContains(t, v) for _, item in ipairs(t) do if item == v then return true end end return false end
function UnitGUID() return 'Creature-0-0-0-0-' .. target .. '-0' end
function strsplit(_, value) return value:match('([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)') end
function CursorHasItem() return cursor ~= nil end
function GetCursorInfo() return cursor and 'item', cursor and cursor.itemID end
function ClearCursor() cursor = nil end
function DeleteCursorItem() assert(cursor); mutated = mutated + 1; cursor = nil end
function UnitIsDeadOrGhost() return false end
function AcceptXPLoss() end
C_Map = { GetBestMapForUnit = function() return map end, GetAreaInfo = function(id) return id == 87 and 'Goldshire' or 'Other' end }
C_Spell = { GetSpellInfo = function(id) return { name = id == 2550 and 'Cuisine' or 'Spell', spellID = id } end,
    GetSpellCooldown = function() return { startTime = 100, duration = 10 } end }
C_QuestLog = { IsOnQuest = function() return onQuest end, IsComplete = function() return finished end,
    IsQuestFlaggedCompleted = function() return rewarded end,
    GetQuestObjectives = function() return {{ numFulfilled = 3, numRequired = 8, finished = false }} end }
C_Item = { GetItemInfo = function(id) return 'item ' .. id end,
    GetItemCount = function(id, bank)
        local n = bank and (bankItems[id] or 0) or 0
        for _, item in pairs(bags[0] or {}) do if item.itemID == id then n = n + item.stackCount end end
        return n
    end }
C_Container = {
    GetContainerNumSlots = function() return 2 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
    PickupContainerItem = function(bag, slot) cursor = bags[bag][slot]; bags[bag][slot] = nil end,
    UseContainerItem = function(bag, slot)
        mutated = mutated + 1
        local item = bags[bag][slot]; bags[bag][slot] = nil
        if APR.routeBankOpen then
            local destination = bag == -1 and 0 or -1
            bags[destination] = bags[destination] or {}; bags[destination][slot] = item
        end
    end,
}
dofile('APR-Core/utils/RouteUtils.lua')
dofile('APR-Core/utils/QuestUtils.lua')
dofile('APR-Core/utils/RouteConditions.lua')
dofile('APR-Core/utils/LootUtils.lua')
dofile('APR-Core/utils/RouteManager.lua')
dofile('APR-Core/features/questing/RouteActions.lua')
function APR:GetPlayerEffectiveLevel() return 20 end
function APR:ResolveLevelRequirement(value) return value end
function APR:IsSpellKnown() return spellKnown end
function APR:CompareRouteNumber(value, op, n)
    if op == '>=' then return value >= n elseif op == '<' then return value < n
    elseif op == '<=' then return value <= n elseif op == '>' then return value > n else return value == n end
end
APR.RouteQuestStepList.test = { steps = {{ LearnSkill = { spellID = 6673 } }} }
assert(APR:GetRouteSkill({skill='cooking'}) == 10, 'Localized skill name from the actual profession spell')
assert(APR:HandleRouteAction(APR:GetStep(1)) and APRData.player.test == 1)
spellKnown = true
assert(APR:HandleRouteAction(APR:GetStep(1)) and APRData.player.test == 2)
spellKnown, skill = false, 20
assert(APR:AreConditionalFiltersMet({Not={Skill={skill='cooking',rank=21}}}))
assert(not APR:AreConditionalFiltersMet({Not={Skill={skill='cooking',rank=20}}}))
assert(APR:AreConditionalFiltersMet({AllOf={{Skill={skill='cooking',rank=20}}, {EquippedItem={slot=16,itemID=100}}}}))
assert(APR:AreConditionalFiltersMet({EquippedItem={slot=16,itemID=100}}))
assert(not APR:AreConditionalFiltersMet({EquippedItem={slot=16,itemID=101}}))
local strict = {IsQuestOnQuest=10,IsQuestReadyForTurnIn=10,IsQuestUncompleted=10}
rewarded, onQuest, finished = true, false, false
assert(not APR:AreConditionalFiltersMet(strict))
rewarded, onQuest, finished = false, true, true
assert(APR:AreConditionalFiltersMet(strict))
assert(APR:TrigTextValueMatch('3/', '3/8'))
assert(APR:TrigTextValueMatch('3/', '4/8'))
assert(not APR:TrigTextValueMatch('3/', '2/8'))
bags = {[0]={{itemID=100,stackCount=2}}, [-1]={{itemID=100,stackCount=8}}}; bankItems[100] = 8
assert(APR:IsRouteCollectionComplete({itemID=100,quantity=10}), 'Initial API bank fallback')
APR.routeBankOpen = true
APR:SaveBankItemCounts()
assert(APRData.player.BankItems[100] == 8)
assert(APR:GetCollectionItemCount(100) == 10, 'Do not add cached bank to API bank count')
APR.routeBankOpen = false
bags[-1] = nil; bankItems[100] = 0
APR:SaveBankItemCounts()
assert(APR:IsRouteCollectionComplete({itemID=100,quantity=10}), 'Closed bank keeps saved counts')
dofile('APR-Core/utils/LootUtils.lua')
assert(APR:GetCollectionItemCount(100) == 10, 'Counts survive module reload')
APR.routeBankOpen = true
bags[-1] = {{itemID=100,stackCount=3}}
APR:SaveBankItemCounts()
assert(APR:GetCollectionItemCount(100) == 5, 'Snapshot replaces earlier counts after withdrawal')
bags[-1] = {}
APR:SaveBankItemCounts()
assert(not APR:IsRouteCollectionComplete({itemID=100,quantity=5}), 'No remembered virtual completion')
assert(APR:AreConditionalFiltersMet({Collection={itemID=100,quantity=2}}))
local state = {}
APR.routeBankOpen = false
assert(not APR:ProcessRouteItems('BankDeposit',{items={100}},state) and mutated == 0)
APR.routeBankOpen = true
bags[0][1].isLocked = true
assert(not APR:ProcessRouteItems('BankDeposit',{items={100}},state) and mutated == 0)
bags[0][1].isLocked = false
assert(not APR:ProcessRouteItems('BankDeposit',{items={100}},state) and mutated == 1)
assert(APR:ProcessRouteItems('BankDeposit',{items={100}},state))
assert(bags[-1][1].itemID == 100)
assert(not APR:ProcessRouteItems('BankWithdraw',{items={100}},{}))
assert(bags[0][1].itemID == 100)
APR.routeBankOpen = false
cursor = {itemID=999,stackCount=1}
assert(not APR:ProcessRouteItems('DestroyItems',{items={100}},{}))
assert(cursor.itemID == 999 and bags[0][1].itemID == 100, 'Unrelated cursor must remain untouched')
cursor = nil
bags[0][2] = {itemID=200,stackCount=3}
assert(not APR:ProcessRouteItems('DestroyItems',{items={100}},{}))
assert(bags[0][1] == nil and bags[0][2].itemID == 200, 'Only listed item IDs may be destroyed')
assert(APR:ProcessRouteItems('DestroyItems',{items={100}},{}))
APR.routeMerchantOpen = false
assert(not APR:ProcessRouteItems('SellItems',{items={200}},{}))
APR.routeMerchantOpen = true
assert(not APR:ProcessRouteItems('SellItems',{items={200},npcID=999},{}))
assert(bags[0][2], 'Wrong merchant must not sell')
lockedCombat = true
assert(not APR:ProcessRouteItems('SellItems',{items={200}},{}))
lockedCombat = false
assert(not APR:ProcessRouteItems('SellItems',{items={200},npcID=2163},{}))
assert(bags[0][2] == nil)
APRData.player.test = 1
APR.RouteQuestStepList.test = { steps={{TameBeast={npcID=2163,spellID=1515}}} }
APR.routeActionState = nil
APR:HandleTameBeast(APR:GetStep(1), 'UNIT_SPELLCAST_START','player',1515)
APR:HandleTameBeast(APR:GetStep(1), 'UNIT_SPELLCAST_SUCCEEDED','player',1515)
assert(APR:GetRouteActionState(APR:GetStep(1)).complete)
APR.routeActionState = nil; target = 999
APR:HandleTameBeast(APR:GetStep(1), 'UNIT_SPELLCAST_START','player',1515)
APR:HandleTameBeast(APR:GetStep(1), 'UNIT_SPELLCAST_SUCCEEDED','player',1515)
assert(not APR:GetRouteActionState(APR:GetStep(1)).complete)
-- A corpse recovery alone is not a spirit-healer shortcut.
APR.RouteQuestStepList.test = {steps={{DeathSkip=true}}}
APR.routeActionState = nil
local resurrected = 0
function AcceptXPLoss() resurrected = resurrected + 1 end
APR:HandleDeathSkip(APR:GetStep(1), 'PLAYER_DEAD')
APR:HandleDeathSkip(APR:GetStep(1), 'PLAYER_UNGHOST')
assert(not APR:GetRouteActionState(APR:GetStep(1)).complete)
APR:HandleDeathSkip(APR:GetStep(1), 'CONFIRM_XP_LOSS')
assert(resurrected == 1)
APR:HandleDeathSkip(APR:GetStep(1), 'PLAYER_UNGHOST')
assert(APR:GetRouteActionState(APR:GetStep(1)).complete)

-- Real Classic trainer matching uses localized spell name AND rank.
local learned, money = {}, 50
function GetNumTrainerServices() return 3 end
function GetTrainerServiceInfo(index)
    return index == 3 and 'Unrelated' or 'Spell', index == 2 and 'Rank 2' or 'Rank 1', 'available'
end
C_Spell.GetSpellSubtext = function() return 'Rank 1' end
function GetTrainerServiceCost() return 100 end
function GetMoney() return money end
function BuyTrainerService(index) learned[#learned + 1] = index end
APR.RouteQuestStepList.test = {steps={{LearnSkill={spellID=6673,npcID=2163}}}}
APR.routeActionState = nil; target = 999
APR.routeTrainerOpen = true
APR:HandleSkillTrainer(APR:GetStep(1))
assert(#learned == 0, 'Wrong trainer must not buy')
target = 2163
APR:HandleSkillTrainer(APR:GetStep(1))
assert(#learned == 0, 'Unaffordable service must wait')
money = 100
APR:HandleSkillTrainer(APR:GetStep(1))
assert(#learned == 1 and learned[1] == 1, 'Exact localized service/rank only')
lockedCombat = true
APR:HandleSkillTrainer(APR:GetStep(1))
assert(#learned == 1, 'Do not buy in combat')
lockedCombat = false

-- Spell ETA starts only for the expected player spell, once per step.
APR.routeActionState = nil
local timers = {}
APR.AFK = { SetAfkTimer = function(_, seconds) timers[#timers + 1] = seconds end }
local timed = {SpellETA={spellID=1515,seconds=30}}
APR:HandleSpellETA(timed, 'target', 1515)
APR:HandleSpellETA(timed, 'player', 99)
assert(#timers == 0)
APR:HandleSpellETA(timed, 'player', 1515)
APR:HandleSpellETA(timed, 'player', 1515)
assert(#timers == 1 and timers[1] == 30)
-- Targeted and untargeted emotes start the renamed timer, once per step.
dofile('APR-Core/utils/TargetUtils.lua')
local emotes, emoteTarget = 0, 2163
function APR:GetTargetID() return emoteTarget end
function APR:PerformEmote() emotes = emotes + 1 end
APR.routeActionState = nil
APR:DoEmote({Emote={emote='salute',npcID=999},EmoteETA=10})
assert(emotes == 0 and #timers == 1)
APR:DoEmote({Emote={emote='salute',npcID=2163},EmoteETA=10})
APR:DoEmote({Emote={emote='salute',npcID=2163},EmoteETA=10})
assert(emotes == 2 and #timers == 2 and timers[2] == 10)
APR.routeActionState = nil; emoteTarget = nil
APR:DoEmote({Emote={emote='sit'},EmoteETA=5})
assert(emotes == 3 and #timers == 3 and timers[3] == 5)
print('Forever native actions: inventory snapshots, safeguards, partial objectives, tame, spirit healer, spell ETA and localized trainer passed')
