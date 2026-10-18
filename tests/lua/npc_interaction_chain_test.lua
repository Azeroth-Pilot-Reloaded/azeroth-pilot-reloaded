-- Exercise real event dispatch, purchase receipts and settled step transitions.
local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
function geterrorhandler() return error end
local timers, modifier, npc = {}, false, 100
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
C_Timer.After = C_Timer.NewTimer
local function flush()
    local pending = timers
    timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
function IsModifierKeyDown() return modifier end
local function frame() return { visible = false, IsVisible = function(self) return self.visible end } end
MerchantFrame, GossipFrame, QuestFrameGreetingPanel, QuestFrameDetailPanel = frame(), frame(), frame(), frame()
local steps, bags, purchases = {}, {}, {}
APRData = { player = { route = 1 } }
APR = {
    PlayerID = "player", ActiveRoute = "route", currentStep = {},
    settings = { profile = { enableAddon = true, autoAcceptQuestRoute = true } },
    Debug = noop, DebugEvent = noop, StartPerformanceSample = noop, FinishPerformanceSample = noop,
    RefreshInstanceUIVisibility = noop, MaybePromptInstanceUIPreference = noop,
    IsInstanceWithUI = function() return true end, NewModule = function() return {} end,
    GetSettingsProfile = function(self) return self.settings.profile end,
    GetCurrentStep = function() return steps[APRData.player.route] end,
    GetCollectionItemCount = function(_, id) return bags[id] or 0 end,
    GetTargetID = function() return npc end,
    RenderCurrentStep = noop,
}
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/questing/QuestHandler.lua")
dofile("APR-Core/utils/BuyMerchantUtils.lua")
dofile("APR-Core/core/Event.lua")
dofile("APR-Core/features/questing/NPCInteraction.lua")
APR.event.TalkToDenyNpcLogic = noop
APR.UpdateNextStep = APR.AdvanceStep
local function dispatch(tag, event, ...)
    APR.event.EventHandler({ tag = tag, callback = APR.event.functions[tag] }, event, ...)
end
function GetMerchantNumItems() return 2 end
function GetMerchantItemID(index) return index end
function BuyMerchantItem(index, count) purchases[#purchases + 1] = { index, count } end
C_Item = { GetItemInfoInstant = function(link) return tonumber(link:match("item:(%d+)")) end }
APR.StripHyperlinks = function(_, text) return text end
local function receipt(id, count)
    bags[id] = (bags[id] or 0) + count
    dispatch("lootItems", "CHAT_MSG_LOOT", "|Hitem:" .. id .. "|h[Food]|h x" .. count)
end
steps = { { BuyMerchant = { { itemID = 1, quantity = 5 } }, MerchantNPC = 100 },
    { BuyMerchant = { { itemID = 2, quantity = 10 } }, MerchantNPC = 100 }, {} }
MerchantFrame.visible = true
dispatch("merchant", "MERCHANT_SHOW")
assert(#purchases == 1 and APRData.player.route == 1, "Buying waits for delivery")
receipt(1, 2)
assert(APRData.player.route == 1, "Partial delivery must not complete the buy")
receipt(1, 3)
assert(APRData.player.route == 2 and #purchases == 1)
APR:UpdateStep(); APR:UpdateStep()
flush()
assert(#purchases == 2 and purchases[2][1] == 2 and purchases[2][2] == 10,
    "The next buy starts once with the merchant still open")
APR:UpdateStep(); flush()
assert(#purchases == 2, "Unrelated refreshes must not repeat pending purchases")
receipt(2, 10); flush()
assert(APRData.player.route == 3)

local function resetBuy()
    APR:TransitionStep(1); flush()
    dispatch("merchant", "MERCHANT_SHOW")
    receipt(1, 5)
    return #purchases
end
local count = resetBuy()
dispatch("merchant", "MERCHANT_CLOSED"); MerchantFrame.visible = false; flush()
assert(#purchases == count, "Closing cancels the queued purchase")
MerchantFrame.visible = true
count = resetBuy(); npc = 200; flush()
assert(#purchases == count, "The next step still enforces MerchantNPC")
npc = 100
count = resetBuy(); modifier = true; flush(); modifier = false
assert(#purchases == count, "Modifier override applies to resumed interactions")
count = resetBuy(); APR:TransitionStep(3); flush()
assert(#purchases == count, "Stale queued work must not buy after another transition")
dispatch("merchant", "MERCHANT_CLOSED"); MerchantFrame.visible = false

local selected, accepted, offered = {}, 0, 42
function GetQuestID() return offered end
function QuestGetAutoAccept() return false end
APR.AcceptQuest = function() accepted = accepted + 1 end
APR.CloseQuest = function() error("The NPC should stay open") end
APR.IsARouteQuest = function(_, id)
    local current = APR:GetCurrentStep()
    return current and current.PickUp and current.PickUp[1] == id or false
end
APR.gossip = { counter = 0, HandleGossip = function() return false end }
C_GossipInfo = {
    GetAvailableQuests = function() return { { questID = offered } } end,
    GetActiveQuests = function() return {} end,
    GetOptions = function() return {} end,
    SelectAvailableQuest = function(id) selected[#selected + 1] = id end,
}
steps = { { Done = { 10 } }, { PickUp = { 42 } }, { GossipOptionIDs = { 99 } }, {} }
APR:TransitionStep(1); flush()
GossipFrame.visible = true
dispatch("gossip", "GOSSIP_SHOW") -- server opened the list before the route caught up
assert(#selected == 0)
APR:AdvanceStep(); flush()
assert(#selected == 1 and selected[1] == 42, "Turn-in to pickup reuses the open gossip list")
APR:UpdateStep(); flush(); assert(#selected == 1)
local gossips = 0
APR.gossip.HandleGossip = function(_, current)
    if current.GossipOptionIDs then gossips = gossips + 1; return true end
    return false
end
APR:AdvanceStep(); flush()
assert(gossips == 1, "A subsequent gossip step resumes in the same NPC window")
dispatch("gossip", "GOSSIP_CLOSED"); GossipFrame.visible = false

function GetNumActiveQuests() return 0 end
function GetNumAvailableQuests() return 1 end
function GetAvailableQuestInfo() return "Quest", 1, false, false, offered end
function SelectAvailableQuest() selected[#selected + 1] = offered end
APR:TransitionStep(1); flush()
QuestFrameGreetingPanel.visible = true
dispatch("greeting", "QUEST_GREETING")
count = #selected
APR:AdvanceStep(); flush()
assert(#selected == count + 1, "Legacy quest greetings also resume after turn-in")

QuestFrameGreetingPanel.visible = false; QuestFrameDetailPanel.visible = true
dispatch("detail", "QUEST_DETAIL")
dispatch("questFinished", "QUEST_FINISHED")
flush(); assert(accepted == 0, "Closed quest details cannot accept later")
dispatch("detail", "QUEST_DETAIL")
offered = 43; flush(); assert(accepted == 0, "A delayed accept cannot affect a different quest")
offered = 42
dispatch("detail", "QUEST_DETAIL"); flush()
assert(accepted == 1)
APR:TransitionStep(1); flush()
dispatch("detail", "QUEST_DETAIL"); flush()
assert(accepted == 1 and #timers == 0, "Ineligible details do not poll forever or close the window")
APR:AdvanceStep(); flush(); flush()
assert(accepted == 2, "An already visible detail becomes eligible after step advancement")

APR:TransitionStep(3)
APR.settings.profile.enableAddon = false
count = gossips; flush()
assert(gossips == count, "Disabling the addon stops deferred interactions")

-- Run the real gossip selector against an old page and then the next page.
dofile("APR-Core/features/questing/Gossip.lua")
APR.settings.profile.autoGossip = true
local options, chosen = { { gossipOptionID = 1 } }, {}
C_GossipInfo.GetOptions = function() return options end
C_GossipInfo.SelectOption = function(id) chosen[#chosen + 1] = id end
assert(not APR.gossip:HandleGossip({ GossipOptionIDs = { 2, 3 } }))
assert(#chosen == 0, "A stale gossip page must not select absent or fallback options")
options = { { gossipOptionID = 2 }, { gossipOptionID = 3 } }
assert(APR.gossip:HandleGossip({ GossipOptionIDs = { 2, 3 } }))
assert(#chosen == 1 and chosen[1] == 2, "Each page selects one offered route option")

APR.settings.profile.enableAddon = true
APR:TransitionStep(1); flush()
dispatch("detail", "QUEST_DETAIL")
APR:AdvanceStep()
local pendingResume = APR.npcInteraction.resumeTimer
assert(pendingResume and APR.npcInteraction.interaction)
APR.npcInteraction:OnDisable()
assert(pendingResume.cancelled and not APR.npcInteraction.resumeTimer and not APR.npcInteraction.interaction,
    "Disabling the NPC module releases its interaction and pending timer")
local beforeDisable = accepted
flush(); flush()
assert(accepted == beforeDisable, "Disabling cancels delayed quest acceptance too")
print("NPC chains: merchant receipts, consecutive buys, gossip, greetings, details and stale/override guards passed")
