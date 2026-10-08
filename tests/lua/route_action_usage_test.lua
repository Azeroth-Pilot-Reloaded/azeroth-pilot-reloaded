-- Exercise native use progression and supporting buttons, including questless steps.
dofile("APR-Core/utils/SecretUtils.lua")
local function noop() end
local L = setmetatable({ USE_ITEM = "Use %s", USE_SPELL = "Cast %s" },
    { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end

function UnitIsDeadOrGhost() return false end

function IsInInstance() return false end

function debugprofilestop() return 0 end

function CreateFrame() return { SetScript = noop, RegisterEvent = noop } end

UNKNOWN = "Unknown"
local timers, current, advanced = {}, {}, 0
C_Timer = {
    NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = noop }
        timers[#timers + 1] = timer
        return timer
    end
}
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id)
        assert(type(id) == "number"); return id == 99
    end,
    ReadyForTurnIn = function(id)
        assert(id ~= nil); return id == 10
    end,
}
C_Item = {
    GetItemInfo = function(id) return "Item " .. id end,
    GetItemSpell = function(id) return "Item effect", id + 1000 end,
}
C_Spell = { GetSpellInfo = function(id) if id ~= 404 then return { name = "Spell " .. id } end end }
APRData = { player = { route = 1 } }
APR = {
    PlayerID = "player",
    ActiveRoute = "route",
    IsInRouteZone = true,
    settings = { profile = { enableAddon = true, currentStepShow = true } },
    RouteQuestStepList = { route = { expansion = "Forever" } },
    EXPANSIONS = { WarlordsOfDraenor = "WoD", BattleForAzeroth = "BfA", Shadowlands = "SL" },
    currentStep = {
        previousState = {},
        questsList = {},
        fillersList = {},
        ButtonEnable = noop,
        PrepareRaidIcon = noop,
        SetProgressBar = noop,
        UpdateStepButtonCooldowns = noop,
        AddExtraLineText = noop
    },
    Buff = { RemoveAllBuffIcon = noop },
    AFK = { HideFrame = noop },
    Arrow = { SetCoord = noop },
    currentStepImagePreview = { ClearPreviewImages = noop },
    questOrderList = { DelayedUpdate = noop },
    party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop },
    StartPerformanceSample = noop,
    FinishPerformanceSample = noop,
    Debug = noop,
    DebugEvent = noop,
    ResetMissingQuests = noop,
    SendMessage = noop,
    SkipStepCondition = noop,
    ShouldSojournerSkipStep = noop,
    MaybeSojournerPrompt = noop,
    CheckSojournerPartySync = noop,
    ShowLevelConsumableReminders = noop,
    RefreshInstanceUIVisibility = noop,
    MaybePromptInstanceUIPreference = noop,
}
function APR:GetStep() return current end

function APR:GetRouteSteps() return { current } end

function APR:GetSettingsProfile() return self.settings.profile end

function APR:IsInstanceWithUI() return false end

function APR:HasRouteResourceFilters() return false end

function APR:NewModule() return {} end

function APR:Contains(values, wanted)
    for _, value in ipairs(values or {}) do if value == wanted then return true end end
    return false
end

local buttons = {}
function APR.currentStep:Reset()
    self.questsList = {}; buttons = {}
end

function APR.currentStep:AddQuestSteps(id, label, objective, _, noTooltip)
    assert(id ~= nil and type(label) == "string")
    self.questsList[id .. "-" .. objective] = { noTooltip = noTooltip, label = label }
end

function APR.currentStep:AddStepButton(key, id, kind)
    assert(self.questsList[key] or self.fillersList[key], "Button needs a rendered row")
    buttons[#buttons + 1] = { key = key, id = id, kind = kind }
end

dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
APR.ResetMissingQuests = noop
dofile("APR-Core/features/questing/StepInstructions.lua")
dofile("APR-Core/features/questing/StepQuestHandlers.lua")
dofile("APR-Core/features/questing/StepTravelHandlers.lua")
dofile("APR-Core/features/questing/StepActionHandlers.lua")
dofile("APR-Core/features/questing/StepRenderer.lua")
dofile("APR-Core/features/questing/QuestCache.lua")
dofile("APR-Core/features/questing/QuestHandler.lua")
function APR:UpdateNextStep() advanced = advanced + 1 end

current = { Waypoint = 10, NonSkippableWaypoint = true, Coord = { x = 10, y = 20 }, Range = 5 }
APR:UpdateStep()
assert(advanced == 0, "Travel with an unfinished quest waits for ordinary waypoint arrival")
current = { UseItem = { itemID = 100 } }
APR:UpdateStep()
assert(#buttons == 1 and buttons[1].id == 100 and advanced == 0)
assert(APR.currentStep.questsList[buttons[1].key].noTooltip)
current = { UseSpell = { spellID = 404 } }
APR:UpdateStep()
assert(#buttons == 1 and buttons[1].kind == "spell", "Uncached spell names must be safe")

local function checkButtons(step)
    current = step
    APR.currentStep:Reset()
    APR:SetButton()
end
checkButtons({ Button = { ["item:100"] = 100, ["item:101"] = 101 }, SpellButton = { ["spell:200"] = 200 } })
assert(#buttons == 3, "All uses on a manual step must be rendered")
checkButtons({ SpellButton = { ["spell:200"] = 200 } })
assert(#buttons == 1 and buttons[1].kind == "spell", "Spell-only maps must not be interpreted as items")
checkButtons({ Done = { 10 }, Button = { ["10"] = 100 } })
assert(#buttons == 1, "An item can be needed to reach a turn-in even when the quest is ready")
current = { Button = { ["11-1"] = 100 }, SpellButton = { ["11-1"] = 200 } }
APR.currentStep:Reset()
APR.currentStep.questsList["11-1"] = {}
APR:SetButton()
assert(#buttons == 2 and buttons[1].key ~= buttons[2].key, "Supporting items and spells must not overwrite each other")
checkButtons({ Button = { ["10-1"] = 100 } })
assert(#buttons == 0, "Completed quest objectives no longer need their action button")

checkButtons({ SpellButton = { ["5648"] = { 2050, 1243 } } })
assert(#buttons == 2 and buttons[1].id == 2050 and buttons[2].id == 1243,
    "Both spells for the same quest must render in list order")
assert(buttons[1].key ~= buttons[2].key, "Each spell must own a distinct secure-button row")
local firstKey, secondKey = buttons[1].key, buttons[2].key
checkButtons(current)
assert(buttons[1].key == firstKey and buttons[2].key == secondKey, "Refreshes must keep both button keys stable")
current = { SpellButton = { ["11-1"] = { 2050, 1243 } } }
APR.currentStep:Reset()
APR.currentStep.questsList["11-1"] = {}
APR:SetButton()
assert(#buttons == 2 and buttons[1].key == "11-1" and buttons[2].key ~= "11-1",
    "The first spell can use the objective row; the second must not overwrite it")
current = { Button = { ["11-1"] = 100 }, SpellButton = { ["11-1"] = { 2050, 1243 } } }
APR.currentStep:Reset()
APR.currentStep.fillersList["11-1"] = {}
APR:SetButton()
assert(#buttons == 3 and buttons[1].kind == "item" and buttons[2].id == 2050 and buttons[3].id == 1243)
assert(buttons[1].key ~= buttons[2].key and buttons[2].key ~= buttons[3].key,
    "An item and two spells can support the same filler objective")
APR.currentStep.fillersList = {}
checkButtons({ SpellButton = { ["10-1"] = { 2050, 1243 } } })
assert(#buttons == 0, "A completed objective suppresses every associated spell button")
checkButtons({ SpellButton = { ["5648"] = { 404, "Power Word: Fortitude" } } })
assert(#buttons == 2,
    "An uncached spell must not prevent the other spell from rendering")
assert(buttons[2].id == "Power Word: Fortitude", "Lists preserve support for client-localized spell names")

checkButtons({ Button = { ["5648"] = { 100, 101 } } })
assert(#buttons == 2 and buttons[1].id == 100 and buttons[2].id == 101,
    "Both items for the same quest must render in list order")
assert(buttons[1].kind == "item" and buttons[2].kind == "item" and buttons[1].key ~= buttons[2].key)
firstKey, secondKey = buttons[1].key, buttons[2].key
checkButtons(current)
assert(buttons[1].key == firstKey and buttons[2].key == secondKey, "Item button keys must stay stable on refresh")
current = { Button = { ["11-1"] = { 100, 101 } }, SpellButton = { ["11-1"] = { 2050, 1243 } } }
APR.currentStep:Reset()
APR.currentStep.fillersList["11-1"] = {}
APR:SetButton()
assert(#buttons == 4 and buttons[1].key == "11-1" and buttons[2].id == 101 and
    buttons[3].id == 2050 and buttons[4].id == 1243)
local seen = {}
for _, button in ipairs(buttons) do
    assert(not seen[button.key], "Item and spell lists must never overwrite another secure button")
    seen[button.key] = true
end
APR.currentStep.fillersList = {}
checkButtons({ Button = { ["10-1"] = { 100, 101 } } })
assert(#buttons == 0, "A completed objective suppresses every associated item button")
checkButtons({ Done = { 10 }, Button = { ["10"] = { 100, 101 } } })
assert(#buttons == 2, "Quest-wide item lists can still support travel to a ready turn-in")

dofile("APR-Core/core/Event.lua")
local function cast(step, spellID, unit)
    current = step
    -- Use the event dispatcher to update its active-step state, then invoke the
    -- callback directly so a Lua exception cannot be swallowed by the dispatcher.
    APR.event.EventHandler({ tag = "test", callback = noop }, "UNIT_SPELLCAST_SUCCEEDED")
    APR.event.functions.spell("UNIT_SPELLCAST_SUCCEEDED", unit or "player", "cast", spellID)
end
local before = advanced
cast({}, 200)
cast({ UseSpell = { spellID = 200 } }, 201)
cast({ UseSpell = { spellID = 200 } }, 200, "pet")
assert(advanced == before, "Unrelated casts and ordinary steps must not advance or error")
cast({ UseSpell = { spellID = 200 } }, 200)
cast({ UseItem = { itemID = 100 } }, 1100)
cast({ UseItem = { itemID = 100, itemSpellID = 300 } }, 300)
assert(advanced == before + 3, "Spell and item-only steps advance only on their use spell")
local itemAPI = C_Item
C_Item = nil
function GetItemSpell(id) return "Legacy item effect", id + 1000 end

cast({ UseItem = { itemID = 100 } }, 1100)
assert(advanced == before + 4)
C_Item = itemAPI
print("Route uses: standalone items/spells, cast completion, optional quest anchors and all supporting buttons passed")

-- Quest abandonment is now a main action. Run the real update path so it cannot
-- get stuck behind HasAnyMainStepOption, abandon twice, or complete via gossip.
dofile("APR-Core/features/questing/RouteActions.lua")
local activeQuests, abandoned = { [10] = true, [11] = true }, {}
function C_QuestLog.IsOnQuest(id) return activeQuests[id] == true end
function APR:LeaveQuest(id) abandoned[#abandoned + 1] = id end
function APR:NextQuestStep() advanced = advanced + 1 end
function APR:hasEveryGossipsCompleted() error("Main actions must not complete through gossip") end
before = advanced
current = { LeaveQuest = 10, LeaveQuests = { 10, 11 }, GossipOptionIDs = { 1 } }
APR:UpdateStep()
assert(advanced == before and #abandoned == 2 and abandoned[1] == 10 and abandoned[2] == 11)
assert(APR.currentStep.questsList["10-10"] and APR.currentStep.questsList["11-11"],
    "Pending abandonment is visible in the current step")
activeQuests = {}
APR:UpdateStep()
assert(advanced == before + 1 and #abandoned == 2, "Advance once all quests have left the log")

for _, step in ipairs({ { LeaveQuest = 10 }, { LeaveQuests = { 10, 11 } } }) do
    before, current = advanced, step
    APR:UpdateStep()
    assert(advanced == before + 1, "Each abandonment option completes independently")
end
activeQuests, abandoned = { [10] = true }, {}
before = advanced
current = { UseSpell = { spellID = 200 }, LeaveQuest = 10 }
APR:UpdateStep()
assert(advanced == before and #abandoned == 1 and #buttons == 1,
    "Abandonment accompanying another action must not advance past it")

local resetCallback, refreshed
APR.questionDialog = { CreateQuestionPopup = function(_, _, _, callback) resetCallback = callback end }
APR.PrintInfo = noop
function APR:WrapTextWithAppearanceColor(text) return text end
function APR:UpdateQuestAndStep() refreshed = true end
before, current = advanced, { ResetRoute = true, GossipOptionIDs = { 1 } }
APRData.player.route = 5
function APR:GetStep() return current end
APR:UpdateStep()
assert(advanced == before and APRData.player.route == 5 and resetCallback,
    "Reset waits for explicit popup confirmation even when gossip is complete")
assert(APR.currentStep.questsList["RESET_ROUTE-ResetRoute"], "Reset has a main action row")
resetCallback()
assert(APRData.player.route == 1 and refreshed, "Confirmed reset restarts and refreshes the route")
print("Promoted main actions: abandonment, mixed steps, gossip guards and confirmed reset passed")

-- Issue #480: run real UseHS rendering and cast completion with no hearthstone in bags.
dofile("APR-Core/data/models/Spells.lua")
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/utils/PlayerUtils.lua")
APR.Debug, APR.DebugEvent = noop, noop
local owned, unusable, bagCount = {}, {}, 0
function PlayerHasToy(id) return owned[id] == true end

C_ToyBox = { IsToyUsable = function(id) return not unusable[id] end }
function C_Item.GetItemCount(id) return id == 6948 and bagCount or 0 end

function C_Item.IsUsableItem() return true end

function C_Item.GetItemCooldown() return 1, 1800, 1 end

-- Item use effects verified from the toy tooltips; every supported toy must finish UseHS.
local toySpells = {
    [54452] = 75136, [64488] = 94719, [93672] = 136508, [142542] = 231504,
    [162973] = 278244, [163045] = 278559, [165669] = 285362, [165670] = 285424,
    [165802] = 286031, [166746] = 286331, [166747] = 286353, [168907] = 298068,
    [172179] = 308742, [180290] = 326064, [182773] = 340200, [183716] = 342122,
    [184353] = 345393, [188952] = 363799, [190196] = 366945, [190237] = 367013,
    [193588] = 375357, [200630] = 391042, [206195] = 412555, [208704] = 420418,
    [209035] = 422284, [210455] = 438606, [212337] = 401802, [228940] = 463481,
    [235016] = 1217281, [236687] = 1220729, [245970] = 1240219, [246565] = 1242509,
    [257736] = 1261979, [263489] = 1270583, [263933] = 1270814, [265100] = 1273401,
}
for itemID, spellID in pairs(toySpells) do
    owned = { [itemID] = true }
    current, before = { UseHS = 10 }, advanced
    APR:UpdateStep()
    assert(#buttons == 1 and buttons[1].id == itemID and buttons[1].kind == "item",
        "UseHS must render an owned toy even on cooldown: " .. itemID)
    assert(advanced == before, "Rendering a hearthstone must not complete the step")
    cast(current, spellID, "pet")
    cast(current, 200)
    assert(advanced == before, "Unrelated and non-player casts must not complete UseHS")
    cast(current, spellID)
    assert(advanced == before + 1, "The toy's successful cast must complete UseHS: " .. itemID)
end
local seen = {}
for _, id in ipairs(APR.hearthStoneToyItemIDs) do
    assert(toySpells[id] and not seen[id], "Toy catalog must contain verified, unique inn teleports")
    seen[id] = true
end

owned = { [180290] = true, [210455] = true, [263933] = true }
unusable = { [180290] = true, [210455] = true }
assert(APR:GetHearthstoneItemID() == 263933, "Skip toys unavailable to this character")
assert(APR:GetHearthstoneItemID() == 263933, "Repeated renders keep the same selection")
bagCount = 1
assert(APR:GetHearthstoneItemID() == 6948, "Keep using the original hearthstone when carried")
bagCount = 0
function C_Item.IsUsableItem() return false end

assert(APR:GetHearthstoneItemID() == 6948, "Respect item usability as well as toy ownership")
function C_Item.IsUsableItem() return true end

owned = { [140192] = true, [110560] = true }
assert(APR:GetHearthstoneItemID() == 6948, "Fixed-destination toys cannot replace an inn hearthstone")
owned = { [263933] = true }
C_ToyBox.IsToyUsable = function() return nil end
assert(APR:GetHearthstoneItemID() == 6948, "Wait for toy usability data")
C_ToyBox.IsToyUsable = function() return true end
assert(APR:GetHearthstoneItemID() == 263933, "Refresh selection when toy data arrives")
C_ToyBox, PlayerHasToy, C_Item = nil, nil, nil
function GetItemCount() return bagCount end

assert(APR:GetHearthstoneItemID() == 6948, "Clients without toy APIs retain the normal button")
bagCount = 1
assert(APR:GetHearthstoneItemID() == 6948, "Support the legacy bag API")
print("Hearthstones: toy-only UseHS buttons, all toy cast effects, restrictions, cooldowns and legacy fallback passed")
