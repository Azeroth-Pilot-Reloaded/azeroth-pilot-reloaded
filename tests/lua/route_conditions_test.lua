local function noop() end
function LibStub() return { GetLocale = function() return {} end } end

APR = {
    interfaceVersion = 16001,
    Race = "Orc",
    ClassName = "WARRIOR",
    ClassId = 1,
    Faction = "Horde",
    PlayerID = "player",
    ActiveRoute = "route",
    RouteQuestStepList = {},
    Debug = noop
}
dofile("APR-Core/utils/Utils.lua")
function APR:NewModule() return {} end

local level, currentMap = 12, 1411
function UnitLevel() return level end

function tContains(t, v)
    for _, x in ipairs(t) do if x == v then return true end end
    return false
end

C_Map = { GetBestMapForUnit = function() return currentMap end }
local copper, hardcore, count, dps = 99, false, 2, 2.04
function GetMoney() return copper end

C_GameRules = { IsHardcoreActive = function() return hardcore end }
C_Item = {
    GetItemCount = function(_, bank) return count + (bank and 1 or 0) end,
    GetItemStats = function() return { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = dps } end,
}
function GetInventoryItemLink() return "item:123" end

dofile("APR-Core/utils/PlayerUtils.lua")
dofile("APR-Core/data/models/Enums.lua")
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/RouteManager.lua")
local filters = {
    Money = { operator = "<", copper = 100 },
    ItemCount = { itemID = 10, count = 2 },
    EquippedItemStat = { slot = 16, stat = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", operator = "<", value = 2.05, precision = 1 }
}
-- Vendor eligibility counts cash, bag stacks and only the selected equipment.
do
    dofile("APR-Core/utils/LootUtils.lua")
    local oldItem, oldLink, oldCopper = C_Item, GetInventoryItemLink, copper
    local weapon, cached = "item:weapon", true
    local rule = { VendorMoney = { copper = 102, equippedSlots = { 16, 16 } } }
    local function price(item)
        local value = 20
        if item == "item:weapon" then value = cached and 12 or nil end
        return nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, value
    end
    GetInventoryItemLink = function(_, slot) return slot == 16 and weapon or nil end
    for _, modern in ipairs({ true, false }) do
        local function slots(bag) return bag == 0 and 2 or 0 end
        local function info(_, slot)
            if modern then return { itemID = slot, stackCount = 2, hasNoValue = slot == 2 } end
            return 1, 2, false, 0, false, false, nil, false, slot == 2, slot
        end
        C_Item = modern and { GetItemInfo = price } or nil
        C_Container = modern and { GetContainerNumSlots = slots, GetContainerItemInfo = info } or nil
        GetItemInfo, GetContainerNumSlots, GetContainerItemInfo = price, slots, info
        copper = 49
        assert(not APR:AreConditionalFiltersMet(rule), "101 copper skips the step")
        copper = 50
        assert(APR:AreConditionalFiltersMet(rule), "102 copper includes stacks and weapon once")
        assert(not APR:AreConditionalFiltersMet({ Money = { copper = 102 } }), "Money remains cash-only")
        copper = 51
        assert(APR:AreConditionalFiltersMet(rule), "More than 102 also qualifies")
        rule.VendorMoney.operator = "<"
        assert(not APR:AreConditionalFiltersMet(rule))
        rule.VendorMoney.operator = nil
        weapon = nil
        assert(not APR:AreConditionalFiltersMet(rule), "Missing weapon contributes zero")
        weapon, cached = "item:weapon", false
        assert(not APR:AreConditionalFiltersMet(rule), "Uncached prices contribute zero")
        cached = true
        assert(APR:AreConditionalFiltersMet({ AnyOf = { rule } }))
    end
    C_Item, GetInventoryItemLink, copper = oldItem, oldLink, oldCopper
    C_Container, GetItemInfo, GetContainerNumSlots, GetContainerItemInfo = nil, nil, nil, nil
end
assert(APR:AreConditionalFiltersMet(filters))
copper = 100
assert(not APR:AreConditionalFiltersMet(filters), "Money skip threshold is exclusive")
copper, count = 99, 1
assert(not APR:AreConditionalFiltersMet(filters))
filters.ItemCount.includeBank = true
assert(APR:AreConditionalFiltersMet(filters))
dps = 2.08
assert(not APR:AreConditionalFiltersMet(filters), "Equipment uses specified source precision")
dps = nil
assert(not APR:AreConditionalFiltersMet(filters))
filters.EquippedItemStat.allowMissing = true
assert(APR:AreConditionalFiltersMet(filters))
assert(APR:AreConditionalFiltersMet({ Hardcore = false }))
hardcore = true
assert(not APR:AreConditionalFiltersMet({ Hardcore = false }))
assert(APR:AreConditionalFiltersMet({ Hardcore = true }))
C_GameRules = nil
assert(not APR:IsHardcoreCharacter())
C_Item = nil
assert(not APR:MeetsItemCount({ itemID = 10, count = 1 }))
function GetItemCount() return 3 end

assert(APR:MeetsItemCount({ itemIDs = { 10, 11 }, operator = "==", count = 6 }))
assert(not APR:CompareRouteNumber(3, "invalid", 3))
assert(APR:StepUsesAnyOption({ AnyOf = { { Money = filters.Money } } }, { 'Money' }))

-- Class-specific follow-up branches use the existing step condition evaluator.
APR.RouteQuestStepList.route = {
    expansion = APR.EXPANSIONS.Forever,
    nextRoute = { { route = "warrior", conditions = { Class = "WARRIOR" } },
        { route = "mage",    conditions = { Class = "MAGE" } }, "shared" }
}
for _, key in ipairs({ "warrior", "mage", "shared" }) do
    APR.RouteQuestStepList[key] = { expansion = APR.EXPANSIONS.Forever, label = key }
end

-- Recursive predicates and quest/spell conditions use synthetic state on both clients.
do
    dofile("APR-Core/utils/RouteConditions.lua")
    dofile("APR-Core/utils/QuestUtils.lua")
    local known, petAbilities, active, completed, ready, warband = {}, {}, {}, {}, {}, {}
    local previousEnum = Enum
    local function isSpellKnown(id, isPetSpell)
        if C_SpellBook and Enum and Enum.SpellBookSpellBank then
            assert(isPetSpell == nil or isPetSpell == Enum.SpellBookSpellBank.Pet,
                "Modern spellbook requires a spell bank instead of a boolean")
            isPetSpell = isPetSpell == Enum.SpellBookSpellBank.Pet
        else
            assert(isPetSpell == nil or type(isPetSpell) == "boolean")
        end
        local abilities = isPetSpell and petAbilities or known
        return abilities[id] == true
    end
    C_Spell = { GetSpellInfo = function() return { name = "Cuisine" } end }
    C_QuestLog = {
        IsOnQuest = function(id) return active[id] == true end,
        IsComplete = function(id) return ready[id] == true end,
        IsQuestFlaggedCompleted = function(id) return completed[id] == true end,
        IsQuestFlaggedCompletedOnAccount = function(id) return warband[id] == true end,
    }
    function GetNumSkillLines() return 1 end

    function GetSkillLineInfo() return "Cuisine", false, false, 20, 0, 0, 75 end

    function GetInventoryItemID(_, slot) return slot == 16 and 100 or nil end

    for _, client in ipairs({ 16001, 110200, 120100 }) do
        APR.interfaceVersion = client
        Enum = client == 120100 and { SpellBookSpellBank = { Player = 0, Pet = 1 } } or nil
        C_SpellBook = client ~= 16001 and { IsSpellKnown = isSpellKnown } or nil
        _G.IsSpellKnown = client == 16001 and isSpellKnown or nil
        assert(APR:AreConditionalFiltersMet(nil))
        assert(APR:AreConditionalFiltersMet({ AllOf = {} }))
        assert(not APR:AreConditionalFiltersMet({ AnyOf = {} }))
        assert(APR:GetRouteSkill({ skill = 'cooking' }) == 20, 'Localized profession name')
        assert(APR:AreConditionalFiltersMet({ Not = { Skill = { skill = 'cooking', rank = 21 } } }))
        assert(not APR:AreConditionalFiltersMet({ Not = { Skill = { skill = 'cooking', rank = 20 } } }))
        assert(APR:AreConditionalFiltersMet({
            AllOf = {
                { Skill = { skill = 'cooking', rank = 20 } },
                { AnyOf = { { EquippedItem = { slot = 16, itemID = 101 } }, { EquippedItem = { slot = 16, itemID = 100 } } } },
            }
        }))
        assert(not APR:AreConditionalFiltersMet({ EquippedItem = { slot = 16, itemID = 101 } }))
        assert(APR:AreConditionalFiltersMet({ EquippedItem = { slot = 17, invert = true } }))
        local equipment = { EquippedItem = { { slot = 16, itemID = 100 }, { slot = 17, invert = true } } }
        assert(APR:AreConditionalFiltersMet(equipment))
        equipment.EquippedItem[2].invert = false
        assert(not APR:AreConditionalFiltersMet(equipment), "Every equipped item requirement must pass")
        assert(APR:AreConditionalFiltersMet({ Not = equipment }))
        assert(APR:AreConditionalFiltersMet({ AnyOf = { equipment, { EquippedItem = { { slot = 16 } } } } }))
        assert(not APR:AreConditionalFiltersMet({ EquippedItem = {} }))

        local quality = 6
        GetInventoryItemQuality = function() return quality end
        GetItemStats = function() return { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = dps } end
        dps = 1.84
        local stats = { EquippedItemStat = {
            { slot = 16, stat = "QUALITY", operator = "<", value = 7, allowMissing = true },
            { slot = 16, stat = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", operator = "<", value = 1.9, precision = 1 },
        } }
        assert(APR:AreConditionalFiltersMet(stats))
        quality = 7
        assert(not APR:AreConditionalFiltersMet(stats), "First list requirement must also pass")
        quality, dps = 6, 1.86
        assert(not APR:AreConditionalFiltersMet(stats), "List entries retain precision")
        quality, dps = nil, nil
        assert(not APR:AreConditionalFiltersMet(stats), "allowMissing belongs to each entry")
        stats.EquippedItemStat[2].allowMissing = true
        assert(APR:AreConditionalFiltersMet({ AllOf = { stats } }))
        assert(APR:EvaluateRouteConditions(stats))
        assert(not APR:AreConditionalFiltersMet({ EquippedItemStat = {} }))
        assert(APR:AreConditionalFiltersMet({ DontHaveSpell = { 1, 2 } }))
        assert(not APR:AreConditionalFiltersMet({ HasSpell = 2 }))
        known[2] = true
        assert(APR:AreConditionalFiltersMet({ HasSpell = 2 }))
        assert(not APR:AreConditionalFiltersMet({ DontHaveSpell = { 1, 2 } }))
        assert(not APR:EvaluateRouteConditions({ DontHaveSpell = { 1, 2 } }))
        assert(not APR:AreConditionalFiltersMet({ DontHaveSpell = 2 }))
        known[2] = nil
        petAbilities[2] = true
        assert(APR:AreConditionalFiltersMet({ HasSpell = 2 }), "Pet abilities satisfy HasSpell")
        assert(not APR:AreConditionalFiltersMet({ DontHaveSpell = 2 }), "Pet abilities fail DontHaveSpell")
        assert(not APR:AreConditionalFiltersMet({ DontHaveSpell = { 1, 2 } }))
        assert(not APR:EvaluateRouteConditions({ DontHaveSpell = { 1, 2 } }))
        petAbilities[2] = nil
        assert(not APR:AreConditionalFiltersMet({ HasSpell = 2 }))
        assert(APR:AreConditionalFiltersMet({ DontHaveSpell = 2 }))
        warband[1] = true
        assert(not APR:AreConditionalFiltersMet({ IsQuestReadyForTurnIn = 1 }))
        active[1] = true
        assert(not APR:AreConditionalFiltersMet({ IsQuestReadyForTurnIn = 1 }))
        ready[1] = true
        local strict = { IsQuestOnQuest = 1, IsQuestReadyForTurnIn = 1, IsQuestUncompleted = 1 }
        assert(APR:AreConditionalFiltersMet(strict))
        assert(not APR:AreConditionalFiltersMet({ IsQuestReadyForTurnIn = { 1, 2 } }))
        completed[2] = true
        assert(APR:AreConditionalFiltersMet({ IsQuestReadyForTurnIn = { 1, 2 } }))
        assert(APR:EvaluateRouteConditions({ IsQuestReadyForTurnIn = { 1, 2 } }))
        completed[1], active[1], ready[1] = true, nil, nil
        assert(not APR:AreConditionalFiltersMet(strict))
        assert(APR:AreConditionalFiltersMet({ IsQuestReadyForTurnIn = 1 }))
        known, active, completed, ready, warband = {}, {}, {}, {}, {}
    end
    APR.interfaceVersion = 16001
    Enum = previousEnum
    _G.IsSpellKnown = nil
end
local suggestions = APR:GetNextRouteSuggestions("route")
assert(#suggestions == 2 and suggestions[1].key == "warrior" and suggestions[2].key == "shared")

-- Resource events only refresh a relevant active step, coalescing bursts.
APRData = { player = { route = 1 } }
local currentStep, updates, timers = filters, 0, {}
function APR:GetStep(index)
    assert(index == 1); return currentStep
end

function APR:UpdateStep() updates = updates + 1 end

C_Timer = {
    NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end
}
function wipe(t) for k in pairs(t) do t[k] = nil end end

local registrations = {}
function CreateFrame()
    return {
        SetScript = noop,
        RegisterEvent = function(_, name)
            registrations[name] = (registrations[name] or 0) + 1
        end,
        UnregisterAllEvents = noop
    }
end

dofile("APR-Core/core/Event.lua")
for _ = 1, 10 do APR.event.functions.money() end
assert(#timers == 1)
timers[1].callback()
assert(updates == 1)
currentStep = { PickUp = { 1 } }
APR.event.functions.money()
assert(#timers == 1, "Unrelated quest steps do not rebuild on money/bag changes")
currentStep = filters
APR.event.functions.money()
-- Specific event ownership: each new event has only one subscription.
APR.event:RegisterEvents()
for _, name in ipairs({ 'CHAT_MSG_LOOT', 'BAG_UPDATE_DELAYED', 'PLAYER_MONEY',
    'UNIT_SPELLCAST_START', 'UNIT_SPELLCAST_SUCCEEDED', 'TRAINER_SHOW', 'BANKFRAME_OPENED',
    'PLAYERBANKSLOTS_CHANGED', 'SKILL_LINES_CHANGED', 'PLAYER_EQUIPMENT_CHANGED' }) do
    assert(registrations[name] == 1, name .. ' must have one owner')
end
assert(not APR.event.functions.routeActions and not APR.event.functions.routeResources)
APR.event:CleanupEvents()
assert(timers[2].cancelled and not APR.event.stepRefreshTimer)
currentStep = { Collection = { itemID = 10, quantity = 3 } }
APR.event.functions.money()
assert(#timers == 2, 'Money cannot refresh an inventory-only condition')
function APR:SaveBankItemCounts() end

function APR:RefreshLevelProfileTargets() end

APR.event.functions.inventory('BAG_UPDATE_DELAYED')
assert(#timers == 3, 'Inventory changes refresh Collection')
APR.event.functions.bank('BANKFRAME_OPENED')
assert(APR.routeBankOpen and #timers == 3, 'Bank event shares coalesced refresh')
APR.event.functions.bank('BANKFRAME_CLOSED')
assert(not APR.routeBankOpen)
currentStep = { AnyOf = { { VendorMoney = { copper = 102, equippedSlots = { 16 } } } } }
for _, event in ipairs({ "money", "equipment", "inventory" }) do
    APR.event:CleanupEvents()
    local before = #timers
    APR.event.functions[event]()
    assert(#timers == before + 1, event .. " refreshes nested VendorMoney conditions")
end
print("Route resources: money, inventory, equipment, Hardcore, branching and coalesced events passed")

-- Primary-profession limits control both visibility and automatic progression.
do
    local first, second
    GetProfessions = function() return first, second, 3, 4, 5 end
    for count = 0, 2 do
        first, second = count >= 1 and 1 or nil, count >= 2 and 2 or nil
        for threshold = 1, 3 do
            local condition = { SkipForPrimaryProfessions = threshold }
            assert(APR:StepFilterQoL(condition) == (count < threshold))
            assert(APR:StepFilterQuestHandler(condition) == (count >= threshold))
            assert(APR:AreConditionalFiltersMet({ Not = condition }) == (count >= threshold))
            assert(APR:AreConditionalFiltersMet({ AllOf = { condition } }) == (count < threshold))
        end
    end
    GetProfessions = nil
    currentStep = { AnyOf = { { SkipForPrimaryProfessions = 2 } } }
    for _, event in ipairs({ "skill", "spellbook" }) do
        APR.event:CleanupEvents()
        local before = #timers
        APR.event.functions[event]()
        assert(#timers == before + 1, event .. " refreshes nested primary-profession limits")
    end
end

-- Zone conditions use the same evaluator for progression and list visibility.
do
    level = 88
    local function check(condition, mapID, visible)
        currentMap = mapID
        assert(not not APR:StepFilterQoL(condition) == visible, "Unexpected list visibility")
        assert(APR:StepFilterQuestHandler(condition) == not visible, "Unexpected automatic skip")
    end
    check({ SkipInZones = { 2393 } }, 2393, false)
    check({ SkipInZones = { 2393 } }, 2413, true)
    check({ SkipInZones = { 2393, 2413 } }, 2413, false)
    check({ SkipInZones = { 2393 } }, nil, true)
    check({ OnlyInZones = { 2541 } }, 2541, true)
    check({ OnlyInZones = { 2541 } }, 2393, false)
    check({ OnlyInZones = { 2393, 2541 } }, 2393, true)
    check({ OnlyInZones = { 2541 } }, nil, false)
    check({ Zones = { 2393, 2413 }, SkipInZones = { 2393 } }, 2393, false)
    check({ Zones = { 2393, 2413 }, SkipInZones = { 2393 } }, 2413, true)
    check({ OnlyInZones = { 2541 }, SkipForLvl = 88 }, 2541, false)
    check({ Zone = 2541 }, 2393, true)
    print(
        "Zone conditions: inclusion/exclusion, multiple maps, missing map, composition and navigation-only Zone passed")
end
