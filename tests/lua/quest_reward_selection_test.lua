-- Real NPC reward handling against invented rewards and controlled score/data responses.
local function noop() end
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub()
    return { GetLocale = function() return L end }
end

local clock, timers, choices, items, selected, profile = 0, {}, {}, {}, {}, {}
local questID, revision, modifier, deferred, visible, manual = 7301, 1, false, false, true, false
local scoringCalls, scorerCalls = {}, 0
local pawnScorer = function()
    scorerCalls = scorerCalls + 1
    return 17
end
APR = {
    NewModule = function() return {} end,
    event = { TalkToDenyNpcLogic = noop },
    GAME_VERSIONS = { Retail = "retail", Forever = "forever" },
    ProfessionTrainingItems = {},
    ActiveRoute = "Synthetic reward route",
    PawnRewards = { GetScorer = function() return pawnScorer end },
}
function APR:GetSettingsProfile() return profile end
function APR:GetGameVersion() return self.GAME_VERSIONS.Retail end
function APR:CaptureStepContext() return revision end
function APR:IsStepContextCurrent(context) return revision == context end
function APR:GetCurrentStep() return {} end
function APR:IsQuestTurnInDeferred() return deferred end
function APR:RequiresManualQuestReward()
    if manual then return true end
    for _, link in ipairs(choices) do
        if not link then return true end
    end
    return false
end
APR.RewardScoring = {
    GetUpgrade = function(_, link, scale)
        scoringCalls[#scoringCalls + 1] = { link = link, scale = scale }
        local item = assert(items[link], "Scoring must keep the exact item link")
        if scale and scale.score then scale.score(link) end
        return item.gain, item.scoreReady ~= false
    end,
}
function GetQuestID() return questID end
function IsModifierKeyDown() return modifier end
function GetNumQuestChoices() return #choices end
function GetQuestItemLink(_, index) return choices[index] end
function GetQuestItemInfo(_, index)
    local item = items[choices[index]]
    if item then return "Reward", 1, item.quantity or 1, 2, item.usable, item.id end
end
function GetQuestReward(index) selected[#selected + 1] = index end
function GetInventoryItemLink() return nil end
function GetTime() return clock end
function InCombatLockdown() return false end
Enum = {
    ItemQuality = { Heirloom = 7 },
    InventoryType = setmetatable({}, {
        __index = function(_, key) return key end,
    }),
}
C_Item = {
    GetItemInfo = function(link)
        local item = items[link]
        if not item or item.cached == false then return nil end
        return "Reward",
            link,
            2,
            item.ilvl or 1,
            1,
            "Armor",
            "Synthetic",
            1,
            item.equipLoc or "INVTYPE_HEAD",
            1,
            item.price or 0,
            item.classID or 4,
            item.subClassID or 1
    end,
    GetDetailedItemLevelInfo = function(link) return items[link] and items[link].ilvl end,
    GetItemInfoInstant = function(link) return items[link] and items[link].id end,
    RequestLoadItemDataByID = noop,
}
local function transmogByLink(link)
    assert(items[link], "Transmog item-info queries retain the exact synthetic item variant")
    return items[link].known == true
end
C_TransmogCollection = {
    GetItemInfo = function(itemInfo)
        local item = items[itemInfo]
        if not item then
            for _, candidate in pairs(items) do
                if candidate.id == itemInfo then
                    item = candidate
                    break
                end
            end
        end
        if item then return item.id + 100000, item.id + 200000 end
    end,
    PlayerHasTransmogByItemInfo = transmogByLink,
    PlayerHasTransmog = function(id)
        for _, item in pairs(items) do
            if item.id == id then return item.known == true end
        end
        error("PlayerHasTransmog accepts an item ID, never an appearance or source ID")
    end,
}
QuestFrameRewardPanel = { IsVisible = function() return visible end }
QuestFrame = QuestFrameRewardPanel
C_Timer = {
    NewTimer = function(delay, callback)
        local timer = { time = clock + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end,
}
function C_Timer.After(delay, callback) return C_Timer.NewTimer(delay, callback) end
dofile("APR-Core/features/questing/NPCInteraction.lua")

local function activeTimers()
    local count = 0
    for _, timer in ipairs(timers) do
        if not timer.cancelled then count = count + 1 end
    end
    return count
end
local function tick(duration)
    local untilTime, runs = clock + duration, 0
    while true do
        local index, first
        for i, timer in ipairs(timers) do
            if not timer.cancelled and timer.time <= untilTime and (not first or timer.time < first) then
                index, first = i, timer.time
            end
        end
        if not index then break end
        local timer = table.remove(timers, index)
        clock = timer.time
        timer.callback()
        runs = runs + 1
        assert(runs < 100, "Reward retries must remain bounded")
    end
    clock = untilTime
end
local function reset()
    APR.npcInteraction:Clear()
    clock, timers, choices, items, selected, scoringCalls, scorerCalls = 0, {}, {}, {}, {}, {}, 0
    questID, revision, modifier, deferred, visible, manual = 7301, revision + 1, false, false, true, false
    APR.routeValidationPending, APR.routeValidationFailed = nil, nil
    APR.PawnRewards = { GetScorer = function() return pawnScorer end }
    profile = {
        enableAddon = true,
        autoHandIn = true,
        autoHandInChoice = true,
        rewardPriority1 = "ilvl",
        rewardPriority2 = "price",
        rewardPriority3 = "cosmetic",
        rewardPriority4 = "transmog",
        autoCosmeticMulti = true,
        autoTransmogMulti = true,
    }
end
local function reward(id, attributes)
    attributes = attributes or {}
    local link = "|Hitem:"
        .. id
        .. ":0:0:0:0:0:0:0:40:0:0:1:"
        .. (attributes.variant or 731)
        .. "|h[Synthetic reward]|h"
    attributes.id = id
    if attributes.usable == nil then attributes.usable = true end
    items[link], choices[#choices + 1] = attributes, link
    return link
end
local function open(step)
    APR.npcInteraction:Track("done", "QUEST_COMPLETE")
    APR.npcInteraction:HandleQuestDone("QUEST_COMPLETE", step)
end
local function chosen(index, message)
    assert(#selected == 1 and selected[1] == index, message)
end

reset()
reward(101, { gain = 8, ilvl = 150, price = 900 })
local strongest = reward(102, { gain = 27, ilvl = 90, price = 1 })
open()
chosen(2, "Weighted improvement wins over item level and vendor price")
assert(
    scoringCalls[2].link == strongest and scoringCalls[2].scale.score == pawnScorer and scorerCalls == 2,
    "The exact reward variants and selected Pawn scorer reach the scoring contract"
)
open()
assert(#selected == 1, "Repeated completion events cannot claim the same reward twice")

reset()
reward(151, { gain = 8 })
reward(152, { gain = 20 })
local originalClaim, claimAttempts = GetQuestReward, 0
GetQuestReward = function(index)
    claimAttempts = claimAttempts + 1
    -- Model a native inventory/unique-limit refusal without closing the reward page.
    if claimAttempts > 1 then originalClaim(index) end
end
open()
local refusedInteraction = APR.npcInteraction.interaction
assert(claimAttempts == 1 and #selected == 0 and activeTimers() == 0)
open()
assert(claimAttempts == 1, "An immediate duplicate event still suppresses a refused claim burst")
tick(1.01)
open()
assert(
    APR.npcInteraction.interaction == refusedInteraction and claimAttempts == 2,
    "A later native completion event can retry a refused claim on the same open page"
)
chosen(2, "Recovery re-evaluates rewards and claims the independently better eligible choice")
GetQuestReward = originalClaim

reset()
reward(130, { gain = 3, variant = 7 })
local upgradedVariant = reward(130, { gain = 18, variant = 11 })
local previewIndex, previewReady = APR.npcInteraction:SelectQuestReward(profile)
assert(
    previewIndex == 2 and previewReady and #selected == 0,
    "Previewing a choice evaluates exact variants without claiming the quest reward"
)
assert(scoringCalls[2].link == upgradedVariant, "Two variants sharing an item ID retain distinct scoring input")
open()
chosen(2, "The exact higher-scoring variant wins even when item IDs match")

reset()
APR.PawnRewards = nil
reward(131, { gain = 4 })
reward(132, { gain = 12 })
open()
chosen(2, "APR's built-in scoring path remains available with Pawn absent")
assert(scoringCalls[1].scale == nil and scorerCalls == 0, "No Pawn scorer is passed when that integration is absent")

reset()
reward(103, { gain = 15 })
reward(104, { gain = 15 })
open()
chosen(1, "Equal improvements keep the first reward deterministically")

reset()
reward(105, { gain = 100, usable = false, price = 10 })
local eligible = reward(106, { gain = 4, price = 1 })
open()
chosen(2, "An unusable reward cannot win the equipment priority")
assert(
    #scoringCalls == 1 and scoringCalls[1].link == eligible,
    "The native usability rejection is respected before invoking item scoring"
)

reset()
reward(107, { gain = -2, price = 20 })
reward(108, { gain = 0, price = 90 })
open()
chosen(2, "Non-upgrades fall through to the configured vendor-price priority")

reset()
profile.rewardPriority1, profile.rewardPriority2 = "price", "ilvl"
reward(109, { gain = 90, price = 5 })
reward(110, { gain = 1, price = 40 })
open()
chosen(2, "An explicit vendor-price priority remains ahead of weighted equipment")

reset()
profile.rewardPriority1 = "price"
reward(133, { price = 30, quantity = 4 })
reward(134, { price = 100, quantity = 1 })
open()
chosen(1, "Vendor priority compares the complete reward stack's sale value")

reset()
profile.rewardPriority1, profile.rewardPriority2, profile.rewardPriority3 = "cosmetic", "ilvl", "price"
reward(111, { gain = 50, price = 100 })
reward(112, { gain = 0, classID = 4, subClassID = 5, equipLoc = "", price = 1 })
open()
chosen(2, "An unknown cosmetic honors its configured priority")

reset()
profile.rewardPriority1, profile.rewardPriority2 = "cosmetic", "price"
profile.autoCosmeticMulti = false
reward(113, { gain = 0, classID = 4, subClassID = 5, equipLoc = "", price = 1 })
reward(114, { gain = 0, price = 100 })
open()
assert(#selected == 0 and activeTimers() == 0, "A manual cosmetic decision remains manual without retries")

reset()
profile.rewardPriority1, profile.rewardPriority2 = "cosmetic", "ilvl"
profile.autoCosmeticMulti = false
reward(115, { gain = 2, known = true })
reward(116, { gain = 9, known = true })
open()
chosen(2, "A disabled cosmetic choice does not block unrelated equipment when no cosmetic exists")

reset()
profile.rewardPriority1, profile.rewardPriority2 = "transmog", "price"
profile.autoTransmogMulti = true
reward(117, { gain = 0, known = true, price = 100 })
reward(118, { gain = 0, known = false, price = 1 })
open()
chosen(2, "Unknown transmog remains selectable ahead of price")

reset()
profile.rewardPriority1, profile.rewardPriority2 = "transmog", "price"
reward(146, { variant = 4, known = true, price = 100 })
reward(146, { variant = 9, known = false, price = 1 })
open()
chosen(2, "Native transmog item-info queries distinguish different appearances of the same item ID")

reset()
profile.rewardPriority1, profile.rewardPriority2 = "transmog", "price"
C_TransmogCollection.PlayerHasTransmogByItemInfo = nil
reward(147, { known = true, price = 100 })
reward(148, { known = false, price = 1 })
open()
chosen(2, "Clients without the link query pass item IDs to the supported transmog fallback")
C_TransmogCollection.PlayerHasTransmogByItemInfo = transmogByLink

reset()
local delayed = reward(119, { gain = 25, scoreReady = false, price = 1 })
reward(120, { gain = 2, price = 100 })
open()
assert(#selected == 0 and activeTimers() == 1, "Missing scoring data must wait instead of choosing a fallback")
for _ = 1, 100 do
    open()
end
assert(activeTimers() == 1, "Completion bursts share one pending retry")
items[delayed].scoreReady = true
tick(10)
chosen(1, "Delayed scoring data recovers and selects its independently better reward")
assert(activeTimers() == 0, "A successful reward retires its retry chain")

reset()
local uncached = reward(121, { gain = 30, cached = false, price = 1 })
reward(122, { gain = 1, price = 100 })
open()
assert(#selected == 0, "Uncached item metadata cannot fall through to a cheaper decision")
items[uncached].cached = true
tick(10)
chosen(1, "Item metadata arrival resumes the original reward interaction")

reset()
local unknownUsability = reward(135, { gain = 30, price = 1 })
items[unknownUsability].usable = nil
reward(136, { gain = 1, price = 100 })
open()
assert(#selected == 0 and activeTimers() == 1, "Unknown native eligibility cannot authorize an equipment decision")
items[unknownUsability].usable = true
tick(10)
chosen(1, "Native eligibility arriving later resumes equipment selection")

reset()
local ordinary = reward(137, { equipLoc = "", price = 100 })
items[ordinary].usable = nil
reward(138, { gain = -1, price = 1 })
open()
chosen(1, "A non-equipment reward does not require irrelevant equipment eligibility before price fallback")

reset()
local bag = reward(141, { equipLoc = "INVTYPE_BAG", price = 100 })
items[bag].usable = nil
reward(142, { gain = -1, price = 1 })
open()
chosen(1, "An unsupported bag slot does not block the price fallback on unknown equipment eligibility")

reset()
reward(123, { gain = 30, scoreReady = false })
reward(124, { gain = 1 })
open()
tick(60)
assert(#selected == 0 and activeTimers() == 0, "Permanently unavailable data exhausts a bounded retry chain")
assert(#scoringCalls <= 20, "A missing score cannot create an unbounded stream of item evaluations")

reset()
local nextSessionItem = reward(139, { gain = 30, scoreReady = false })
reward(140, { gain = 1 })
open()
local retired
for _, timer in ipairs(timers) do
    if not timer.cancelled then retired = timer end
end
APR.npcInteraction:Track("questFinished", "QUEST_FINISHED")
questID = questID + 1
open()
assert(activeTimers() == 1, "A newly opened reward interaction owns one fresh retry")
retired.callback()
open()
assert(activeTimers() == 1, "An obsolete callback cannot consume a newer interaction's retry ownership")
items[nextSessionItem].scoreReady = true
tick(10)
chosen(1, "The current interaction still recovers after an older cancelled callback is delivered")

for _, invalidation in ipairs({ "closed", "profile", "modifier", "quest", "route", "disabled", "preference", "hidden" }) do
    reset()
    local link = reward(125, { gain = 20, scoreReady = false })
    reward(126, { gain = 1 })
    open()
    local pending
    for _, timer in ipairs(timers) do
        if not timer.cancelled then pending = timer end
    end
    assert(pending, "An incomplete reward interaction needs one cancellable retry")
    if invalidation == "closed" then
        APR.npcInteraction:Track("questFinished", "QUEST_FINISHED")
    elseif invalidation == "profile" then
        profile = { enableAddon = true, autoHandIn = true, autoHandInChoice = true }
    elseif invalidation == "modifier" then
        modifier = true
    elseif invalidation == "quest" then
        questID = questID + 1
    elseif invalidation == "route" then
        revision = revision + 1
    elseif invalidation == "disabled" then
        profile.enableAddon = false
    elseif invalidation == "preference" then
        profile.autoHandInChoice = false
    else
        visible = false
    end
    items[link].scoreReady = true
    pending.callback() -- Simulate a stale callback already delivered by a timer adapter.
    tick(10)
    assert(#selected == 0 and activeTimers() == 0, "An obsolete reward cannot commit or retry after " .. invalidation)
end

for _, guard in ipairs({ "manual", "modifier", "deferred", "routeValidation", "step", "autoHandIn", "autoHandInChoice" }) do
    reset()
    reward(127, { gain = 20 })
    reward(128, { gain = 1 })
    local step
    if guard == "manual" then
        manual = true
    elseif guard == "modifier" then
        modifier = true
    elseif guard == "deferred" then
        deferred = true
    elseif guard == "routeValidation" then
        APR.routeValidationPending = true
    elseif guard == "step" then
        step = { NoAutoTurnIn = true }
    else
        profile[guard] = false
    end
    open(step)
    assert(#selected == 0, "Existing quest automation guard remains effective: " .. guard)
end

reset()
reward(129, { gain = 0 })
profile.autoHandInChoice = false
open()
chosen(1, "A single ordinary reward still turns in without automatic multiple-choice selection")
reset()
open()
chosen(1, "A quest without reward choices still completes automatically")

-- Compose the real native equipment scorer, Pawn adapter and NPC handler.
-- The synthetic Pawn functions retain the public tuple/scale contracts.
reset()
APR.settings = { db = { char = {} } }
local inventory, popup, pawnReads = {}, nil, {}
function UnitClass() return "Warrior", "WARRIOR", 1 end
function UnitLevel() return 40 end
C_SpecializationInfo = {
    GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function() return 9001, "Synthetic specialization", nil, nil, "DAMAGER", 1 end,
}
function GetInventoryItemLink(_, slot) return inventory[slot] end
function GetInventoryItemID(_, slot) return items[inventory[slot]] and items[inventory[slot]].id end
C_PlayerInfo = { CanUseItem = function() return true end }
C_Item.IsEquippableItem = function(link) return items[link] and items[link].equipLoc ~= "" end
C_Item.GetItemUniqueness = function() return nil end
C_Item.GetItemStats = function(link) return items[link] and items[link].stats end
PawnCommon = {
    Scales = {
        Imported = {
            Values = { Strength = 0.1, CritRating = 2 },
            NormalizationFactor = 1,
            ClassID = 1,
            SpecID = 9001,
        },
    },
}
function PawnIsReady() return true end
function PawnGetAllScalesEx()
    local result = {}
    for name in pairs(PawnCommon.Scales) do
        result[#result + 1] = { Name = name, LocalizedName = "Synthetic " .. name, IsProvider = false }
    end
    return result
end
function PawnGetAllStatValues(name) return PawnCommon.Scales[name].Values end
function PawnGetItemData(link)
    pawnReads[#pawnReads + 1] = link
    local item = items[link]
    if not item or item.pawnMissing then return nil end
    return {
        UnenchantedStats = {
            Strength = item.stats.ITEM_MOD_STRENGTH_SHORT or 0,
            CritRating = item.stats.ITEM_MOD_CRIT_RATING_SHORT or 0,
        },
        Link = link,
    }
end
function PawnGetSingleValueFromItem(item, name)
    local value = 0
    for stat, weight in pairs(PawnCommon.Scales[name].Values) do
        value = value + (item.UnenchantedStats[stat] or 0) * weight
    end
    return value + 999, value -- APR must use unenchanted values for both compared items.
end
APR.questionDialog = {
    CreateQuestionPopup = function(_, _, _, accept, cancel)
        popup = { accept = accept, cancel = cancel }
    end,
}
dofile("APR-Core/features/questing/RewardScoring.lua")
dofile("APR-Core/integrations/Pawn.lua")
APR.PawnRewards.RegisterEvent, APR.PawnRewards.UnregisterEvent = noop, noop
APR.PawnRewards.UnregisterAllEvents = noop
APR.PawnRewards:OnEnable()
assert(not popup, "Initial discovery of imported Pawn scales does not manufacture an edit notification")

local equipped = reward(143, { stats = { ITEM_MOD_STRENGTH_SHORT = 10, ITEM_MOD_CRIT_RATING_SHORT = 2 } })
inventory[1] = equipped
choices = {}
local primaryReward =
    reward(144, { stats = { ITEM_MOD_STRENGTH_SHORT = 20, ITEM_MOD_CRIT_RATING_SHORT = 0 }, price = 1 })
local critReward =
    reward(145, { stats = { ITEM_MOD_STRENGTH_SHORT = 11, ITEM_MOD_CRIT_RATING_SHORT = 20 }, price = 100 })
local function freshQuest()
    APR.npcInteraction:Track("questFinished", "QUEST_FINISHED")
    questID, selected = questID + 1, {}
    open()
end
freshQuest()
chosen(1, "Real default Warrior scoring prefers the larger primary-stat improvement")
assert(APR.PawnRewards:SetSelectedScale("pawn:Imported"), "A discovered imported Pawn scale is selectable")
freshQuest()
chosen(2, "Selecting the Pawn crit scale reverses the real quest choice against equipped gear")
assert(pawnReads[#pawnReads] == equipped, "The real Pawn adapter scores the equipped exact variant as its baseline")

PawnCommon.Scales.Imported.Values = { Strength = 2, CritRating = 0.01 }
APR.PawnRewards:RefreshSettings()
assert(
    popup and APR.PawnRewards:GetSelectedScale() == "apr",
    "Changing a selected Pawn scale offers confirmation while APR temporarily uses its default"
)
popup.accept()
tick(1)
assert(
    APR.PawnRewards:GetSelectedScale() == "pawn:Imported",
    "Accepting the changed scale confirms its current fingerprint"
)
freshQuest()
chosen(1, "The accepted edited Pawn weights reverse the real quest choice again")

items[primaryReward].pawnMissing = true
freshQuest()
assert(
    #selected == 0 and activeTimers() == 1,
    "Missing Pawn item data propagates through scoring to a deferred NPC choice"
)
items[primaryReward].pawnMissing = false
tick(10)
chosen(1, "The composed Pawn-to-equipment-to-NPC path recovers from delayed exact item data")
APR.PawnRewards:OnDisable()

print(
    "Quest rewards: weighted priorities, eligibility, exact variants, delayed data, bounded retries and stale-session guards passed"
)
