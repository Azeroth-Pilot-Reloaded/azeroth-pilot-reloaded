-- Exercise native use progression and supporting buttons, including questless steps.
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
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = noop }
    timers[#timers + 1] = timer
    return timer
end }
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) assert(type(id) == "number"); return id == 99 end,
    ReadyForTurnIn = function(id) assert(id ~= nil); return id == 10 end,
}
C_Item = {
    GetItemInfo = function(id) return "Item " .. id end,
    GetItemSpell = function(id) return "Item effect", id + 1000 end,
}
C_Spell = { GetSpellInfo = function(id) if id ~= 404 then return { name = "Spell " .. id } end end }
APRData = { player = { route = 1 } }
APR = {
    PlayerID = "player", ActiveRoute = "route", IsInRouteZone = true,
    settings = { profile = { enableAddon = true, currentStepShow = true } },
    RouteQuestStepList = { route = { expansion = "Forever" } },
    EXPANSIONS = { WarlordsOfDraenor = "WoD", BattleForAzeroth = "BfA", Shadowlands = "SL" },
    currentStep = { previousState = {}, questsList = {}, fillersList = {},
        ButtonEnable = noop, PrepareRaidIcon = noop, SetProgressBar = noop, UpdateStepButtonCooldowns = noop,
        AddExtraLineText = noop },
    Buff = { RemoveAllBuffIcon = noop }, AFK = { HideFrame = noop }, Arrow = { SetCoord = noop },
    currentStepImagePreview = { ClearPreviewImages = noop },
    questOrderList = { DelayedUpdate = noop }, party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop },
    StartPerformanceSample = noop, FinishPerformanceSample = noop, Debug = noop, DebugEvent = noop,
    ResetMissingQuests = noop, SendMessage = noop, SkipStepCondition = noop, ShouldSojournerSkipStep = noop,
    MaybeSojournerPrompt = noop, CheckSojournerPartySync = noop, ShowLevelConsumableReminders = noop,
    RefreshInstanceUIVisibility = noop, MaybePromptInstanceUIPreference = noop,
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
function APR.currentStep:Reset() self.questsList = {}; buttons = {} end
function APR.currentStep:AddQuestSteps(id, label, objective, _, noTooltip)
    assert(id ~= nil and type(label) == "string")
    self.questsList[id .. "-" .. objective] = { noTooltip = noTooltip }
end
function APR.currentStep:AddStepButton(key, id, kind)
    assert(self.questsList[key] or self.fillersList[key], "Button needs a rendered row")
    buttons[#buttons + 1] = { key = key, id = id, kind = kind }
end
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
APR.ResetMissingQuests = noop
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
