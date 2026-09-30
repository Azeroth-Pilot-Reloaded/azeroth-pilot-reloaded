-- Every primary action must survive a read-only preview, including future steps.
-- Localization keys identify labels; synthetic formats expose the arguments
-- used by the renderer without maintaining a copy of packaged translations.
local L = setmetatable({
    SWITCH_TO_CHROMIE = "SWITCH_TO_CHROMIE(%s)",
    GROUP_QUEST_TASK = "GROUP_QUEST_TASK(%s)",
    BUY_ITEM = "BUY_ITEM(%s, %s)",
}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
UNKNOWN, ABANDON_QUEST, LEAVE_VEHICLE, DISMOUNT = "Unknown", "Abandon quest", "Leave vehicle", "Dismount"
INSTANCE = "Localized instance"
format = string.format
local function no() return false end
local function forbidden() error("A preview must not perform actions or mutate action state") end
APR = { questOrderList = {}, questOrderListUtils = {}, PlayerID = "player", ActiveRoute = "test",
    ActiveQuests = {}, QUEST_STATUS = { COMPLETE = 1 }, MaxLevel = 60 }
APRData = { player = { test = 1 }, NPCList = { [54] = "Vendor" } }
local known, equipped, onQuest = {}, {}, { [10] = true }
function GetInventoryItemID(_, slot) return equipped[slot] end
function UnitLevel() return 10 end
function tContains(values, wanted)
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end
C_Item = { GetItemInfo = function(id) if id ~= 404 then return "Item " .. id end end }
C_Spell = { GetSpellInfo = function(id) if id ~= 404 then return { name = "Spell " .. id } end end }
C_QuestLog = { GetTitleForQuestID = function(id) return "Quest " .. id end,
    IsQuestFlaggedCompleted = no, IsOnQuest = function(id) return onQuest[id] end,
    GetQuestObjectives = function() return {} end }
C_Map = { GetBestMapForUnit = function() return 1 end }
C_PvP = { IsWarModeDesired = no }
C_ScenarioInfo = { GetScenarioInfo = function() return { name = "Scenario" } end,
    GetCriteriaInfoByStep = function() return { description = "Objective", completed = false } end }
C_ChromieTime = { GetChromieTimeExpansionOption = function() return { name = "Legion" } end }
dofile("APR-Core/utils/StepUtils.lua")
dofile("APR-Core/utils/QuestUtils.lua")
dofile("APR-Core/features/questing/RouteActions.lua")
APR.ProcessRouteItems, APR.HandleRouteAction, APR.GetRouteActionState = forbidden, forbidden, forbidden
APR.IsSojournerSkipActive, APR.IsDelveRoute, APR.HasTaxiNode = no, no, no
APR.IsReputationLevelReached, APR.hasEveryGossipsCompleted = no, no
function APR:StepFilterQoL(step) return not step.hidden end
function APR:ResolveStepText(text) return text end
function APR:IsSpellKnown(id) return known[id] == true end
function APR:GetCurrentStepToken(route, index) return route .. ":" .. index end
function APR:GetMapInfoCached() return { name = "Zone" } end
function APR:GetScenarioZoneInfo() return { type = "SCENARIO" } end
function APR:GetPlayerParentMapID() return 1 end
function APR:GetTaxiNodeName() return "Flight destination" end
function APR:IsAchievementStepComplete() return false, "Achievement progress" end
function APR:GetLootMoneyProgress() return 0, 0, 100 end
function APR:GetLootMoneyStepText() return "Loot money" end
function APR:GetCollectionItemCount() return 0 end
function APR:GetPlayerEffectiveLevel() return 10 end
function APR:ResolveLevelRequirement(value) return value end
function APR:GetGrindStepText() return "Grind" end
function APR:GetReputationStepText() return "Reputation" end
local utils = APR.questOrderListUtils
utils.IsQuestCompletedOrActive, utils.IsQuestCompleted = no, no
function utils:AddStepFrameWithQuest(_, index, title, quests, color, current)
    assert(type(title) == "string" and title ~= "", "Every row needs a readable title")
    return { title = title, quests = quests, color = color, current = current }
end
function utils:AddStepFrame(layout, index, title, color, current)
    return self:AddStepFrameWithQuest(layout, index, title, {}, color, current)
end
dofile("APR-Core/ui/route/QuestOrderListRows.lua")
local function render(steps, index)
    APRData.player.test = index or 1
    local target = { visibilityParts = {}, stepList = {}, rawStepContainers = {} }
    local worker = coroutine.create(APR.questOrderList:CreateRouteRenderer({}, steps, APRData.player.test, target))
    repeat
        local ok, err = coroutine.resume(worker)
        assert(ok, err)
    until coroutine.status(worker) == "dead"
    return target
end

local fixtures = {
    ExitTutorial = 10, PickUp = { 10 }, DropQuest = 10, Qpart = { [10] = { 1 } },
    QpartPart = { [10] = { 1 } }, Treasure = { questID = 10 }, Group = { questID = 10, Number = 3 },
    Done = { 10 }, Scenario = { stepID = 1, criteriaIndex = 1 },
    EnterInstance = { mapID = 2 }, LeaveInstance = { mapID = 2 },
    EnterScenario = { mapID = 2 }, DoScenario = { mapID = 2 }, LeaveScenario = { mapID = 2 },
    UseHS = 10, UseDalaHS = 10, UseGarrisonHS = 10, UseItem = { itemID = 20, questID = 10 },
    UseSpell = { spellID = 20, questID = 10 }, GetFP = 20, UseFlightPath = 10, TakePortal = { mapID = 2 },
    LearnProfession = 20, LootItems = { { itemID = 20 } }, WarMode = 10, Grind = 20,
    Reputation = { factionID = 20, level = 4 }, LootMoney = { copper = 100 }, Emote = { emote = "wave" },
    Achievement = { achievementID = 20 }, RouteCompleted = true, Note = "Hello",
    DeathSkip = true, SellItems = { items = { 20 }, junk = true }, LearnSkill = { spellIDs = { 20, 21 } },
    BankDeposit = { items = { 20 } }, BankWithdraw = { items = { 20 } }, TameBeast = { npcID = 54 },
    DestroyItems = { items = { 20 } }, EquipItem = { slot = 16, itemID = 20 },
}
fixtures.SetHS = 10
fixtures.LeaveQuest, fixtures.LeaveQuests, fixtures.ResetRoute = 10, { 10, 11 }, true
fixtures.PickUpDB, fixtures.DoneDB, fixtures.QpartDB = { 11 }, { 11 }, { 11 }
local companions = {
    DoneDB = "Done", PickUpDB = "PickUp", QpartDB = "Qpart", DropQuest = "DroppableQuest",
}
local steps = {}
for _, key in ipairs(APR.mainStepOptions) do
    assert(fixtures[key] ~= nil, "Add a preview fixture for main action " .. key)
    local step = { [key] = fixtures[key] }
    if companions[key] then step[companions[key]] = fixtures[companions[key]] end
    steps[#steps + 1] = step
end
local preview = render(steps)
assert(#preview.stepList == #steps, "All main actions must be visible")
for index in ipairs(steps) do
    assert(preview.rawStepContainers[index], "Missing main action at " .. index)
end
assert(APR.routeActionState == nil, "Preview must not create action state")
C_ScenarioInfo.GetScenarioInfo = function() end
C_ScenarioInfo.GetScenarioStepInfo = function() end
C_ScenarioInfo.GetCriteriaInfoByStep = function() end
assert(#render({ { Scenario = { stepID = 1, criteriaID = 2 } }, { Note = "After scenario" } }).stepList == 2,
    "Unavailable future scenario details must not interrupt later rows")
C_ScenarioInfo.GetScenarioInfo = function() return { name = "Scenario" } end
assert(#render({ { Scenario = { stepID = 1, criteriaID = 2 } } }).stepList == 1)

local extras = {
    { LeaveQuest = 10 }, { LeaveQuests = { 10, 11 } }, { ChromiePick = 6 }, { ResetRoute = true },
    { MountVehicle = true }, { VehicleExit = true },
    { Waypoint = 10 }, { SetHS = 10 }, { BuyMerchant = { { itemID = 20, quantity = 2 } } },
    { GossipOptionIDs = { 1 } },
}
preview = render(extras)
assert(#preview.stepList == #extras)
assert(preview.stepList[1].color == "gray" and preview.stepList[2].quests[2].questName == "Quest 11")
assert(preview.stepList[3].title == format(L.SWITCH_TO_CHROMIE, "Legion"))
onQuest = {}
assert(render(extras).stepList[1].color == "green")
C_ChromieTime = nil
assert(render({ extras[3] }).stepList[1].title == format(L.SWITCH_TO_CHROMIE, "Unknown (6)"))

-- Promoted main actions retain their own title, details and completion even
-- when a waypoint, merchant or completed gossip accompanies the step.
for _, key in ipairs({ "LeaveQuest", "LeaveQuests", "ResetRoute" }) do
    local step = { [key] = fixtures[key], BuyMerchant = { { itemID = 20, quantity = 1 } },
        GossipOptionIDs = { 1 }, Waypoint = 10 }
    local expected = key == "ResetRoute" and L.RESET_ROUTE or L.LEAVE_QUEST
    assert(APR:GetStepString(step) == expected)
    assert(APR:HasAnyMainStepOption(step))
    local row = render({ step }).stepList[1]
    assert(row.title:sub(1, #expected) == expected, "Main action must take priority over merchant/gossip/travel")
    assert(row.title:find(format(L.BUY_ITEM, 1, "Item 20"), 1, true), "Merchant instructions remain secondary")
    assert(render({ step }, 2).stepList[1].color == "green")
end
onQuest = { [11] = true }
local abandon = render({ { LeaveQuest = 10, LeaveQuests = { 10, 11 }, VehicleExit = true } }).stepList[1]
assert(#abandon.quests == 2 and abandon.color == "gray", "Both abandonment fields are merged without duplicates")
assert(abandon.title == L.LEAVE_QUEST .. "\n" .. L.LEAVE_VEHICLE)
onQuest = {}
assert(render({ { LeaveQuests = { 10, 11 } } }).stepList[1].color == "green")
assert(render({ { ResetRoute = true } }).stepList[1].color == "gray", "Reset requires confirmation")

local actions = {
    { SellItems = { items = { 20, 404 }, junk = true, text = "Sell supplies" } },
    { LearnSkill = { spellIDs = { 20, 21 } } }, { DeathSkip = true }, { TameBeast = { npcID = 999 } },
    { BankDeposit = { items = { 404 } } }, { DestroyItems = { items = { 20 } } },
    { EquipItem = { slot = 16, itemID = 20 } }, { LearnSkill = { allAvailable = true } },
}
equipped[16], known[20] = 20, true
preview = render(actions)
assert(preview.stepList[1].title ==
    "SELLITEMS: Item 20 (SELL_ITEM_EQUIPPED), Unknown (404)\nSell supplies\nVENDOR_TRASH")
assert(preview.stepList[2].color == "gray", "Every requested skill must be known")
assert(preview.stepList[7].color == "green")
known[21] = true
assert(render(actions).stepList[2].color == "green")
APR.routeActionState = { token = "test:3", complete = true }
preview = render(actions, 3)
assert(preview.stepList[1].color == "green" and preview.stepList[3].color == "green")
assert(preview.stepList[4].color == "gray" and preview.stepList[8].color == "gray",
    "Current action state must not complete future actions")
APR.routeActionState.token = "other:3"
assert(render(actions, 3).stepList[3].color == "gray", "Ignore stale completion from another route")
assert(APR.routeActionState.token == "other:3", "Preview must not reset stale state")

preview = render({ { SellItems = { junk = true }, hidden = true }, { Note = "Visible" } })
assert(#preview.stepList == 1 and preview.rawStepContainers[2].displayIndex == 1)
preview = render({ { PickUp = { 10 }, LeaveQuest = 11, VehicleExit = true },
    { SellItems = { junk = true }, Note = "Vendor advice" } })
assert(preview.stepList[1].title:find("PICK_UP_Q\nLEAVE_QUEST: 11 - Quest 11\nLEAVE_VEHICLE", 1, true))
assert(preview.stepList[2].title == "VENDOR_TRASH")

local linkedSale = { SellItems = { junk = true, questID = 4641 } }
assert(APR:GetStepQuestIDs(linkedSale)[1] == 4641, "Tooltips recognize the sale's linked quest")
assert(#APR:GetStepQuestIDs({ SellItems = { junk = true } }) == 0)
assert(render({ linkedSale }).stepList[1].color == "gray")
C_QuestLog.IsQuestFlaggedCompleted = function(id) return id == 4641 end
assert(render({ linkedSale }).stepList[1].color == "green",
    "A rewarded quest marks the sale complete without running merchant actions")
assert(render({ { Note = "First" }, linkedSale }).stepList[2].color == "green",
    "Future sales also reflect their linked quest after a route reset")
assert(render({ { SellItems = { junk = true, questID = 4642 } } }).stepList[1].color == "gray")
C_QuestLog.IsQuestFlaggedCompleted = no

-- Audit the actual wiki table, not just APR.mainStepOptions: companion fields
-- must have visible content unless they are fillers or automatic actions.
fixtures.BuyMerchant = { { itemID = 20, quantity = 2 } }
fixtures.ChromiePick, fixtures.DoneDB, fixtures.PickUpDB, fixtures.QpartDB = 6, { 11 }, { 11 }, { 11 }
fixtures.DroppableQuest = { Qid = 11, MobId = 54, Text = "Vendor fallback" }
fixtures.Fillers, fixtures.GroupTask = { [11] = { 1, 2 } }, 11
fixtures.LeaveQuest, fixtures.LeaveQuests = 11, { 11, 12 }
fixtures.MountVehicle, fixtures.NpcDismount, fixtures.ResetRoute = true, 54, true
fixtures.SetHS, fixtures.VehicleExit = 10, true
local wikiFile = assert(io.open("wiki.md", "r"))
local wiki = wikiFile:read("*a")
wikiFile:close()
local actionTable = assert(wiki:match("## Action / Progression Options(.-)\nAn action waits"))
local documented = {}
for line in actionTable:gmatch("[^\n]+") do
    local key = line:match("^|%s*`(%w+)`%s*|")
    if key then documented[#documented + 1] = key end
end
assert(#documented == 54, "Review coverage when the action table changes")
local hiddenOptions = { DroppableQuest = true, Fillers = true, NpcDismount = true }

-- Optional and automatic fields never become the primary action or a preview row.
for key in pairs(hiddenOptions) do
    local value = fixtures[key]
    assert(APR:GetStepString({ [key] = value }) == "")
    assert(not APR:HasAnyMainStepOption({ [key] = value }))
    local result = render({ { [key] = value }, { PickUp = { 10 }, [key] = value } })
    assert(#result.stepList == 1 and result.rawStepContainers[1] == nil)
    assert(result.stepList[1].title == L.PICK_UP_Q)
end
for alias, base in pairs({ PickUpDB = "PickUp", DoneDB = "Done", QpartDB = "Qpart" }) do
    local originalRow = render({ { [base] = fixtures[base] } }).stepList[1]
    local variantRow = render({ { [base] = fixtures[base], [alias] = fixtures[alias] } }).stepList[1]
    assert(variantRow.title == originalRow.title and #variantRow.quests == #originalRow.quests,
        "Quest variants use the normal row without additional instructions")
    assert(APR:GetStepString({ [alias] = fixtures[alias] }) == APR:GetStepString({ [base] = fixtures[base] }))
end
for _, key in ipairs(APR.secondaryStepOptions) do
    local label, selected = APR:GetStepString({ [key] = fixtures[key] or { 1 } })
    assert(label ~= "" and selected == key, "Missing secondary action label: " .. key)
    local _, primary = APR:GetStepString({ PickUp = { 10 }, [key] = fixtures[key] or { 1 } })
    assert(primary == "PickUp", "Companion fields must not replace the primary action")
end
assert(APR:GetStepString({ EnterInstance = { mapID = 2 } }) == INSTANCE)

for _, key in ipairs(documented) do
    assert(fixtures[key] ~= nil, "Missing wiki fixture: " .. key)
    local step = { [key] = fixtures[key] }
    if companions[key] then step[companions[key]] = fixtures[companions[key]] end
    local result = render({ step, { Note = "After " .. key } })
    if hiddenOptions[key] then
        assert(#result.stepList == 1 and result.rawStepContainers[1] == nil,
            "filler or automatic action must stay hidden: " .. key)
    else
        assert(#result.stepList == 2, "missing row for " .. key)
        assert(result.rawStepContainers[1].title ~= "", "empty action " .. key)
    end
end

local combined = { Qpart = { [10] = { 1 } }, BuyMerchant = fixtures.BuyMerchant,
    Fillers = fixtures.Fillers, DroppableQuest = fixtures.DroppableQuest,
    GroupTask = 11, LeaveQuest = 12, LeaveQuests = { 12, 13 }, ChromiePick = 6,
    MountVehicle = true, NpcDismount = 54, VehicleExit = true, ResetRoute = true,
    PickUpDB = { 11 }, DoneDB = { 12 }, QpartDB = { 13 } }
local result = render({ combined })
assert(#result.stepList == 1, "Companion actions belong on the same step")
local title = result.stepList[1].title
local expected = {
    L.Q_PART,
    format(L.GROUP_QUEST_TASK, "11 - Quest 11"), L.LEAVE_QUEST .. ": 12 - Quest 12",
    L.LEAVE_QUEST .. ": 13 - Quest 13", format(L.SWITCH_TO_CHROMIE, "Unknown (6)"),
    L.RESET_ROUTE, L.MOUNT_VEHICLE, L.LEAVE_VEHICLE,
    format(L.BUY_ITEM, 2, "Item 20"),
}
assert(title == table.concat(expected, "\n"), "only actionable instructions belong in the title")
local _, abandoned = title:gsub(L.LEAVE_QUEST .. ": 12 %- Quest 12", "")
assert(abandoned == 1, "A quest in both abandonment fields is only displayed once")
local sale = render({ { SellItems = { items = { 20 }, junk = true } } }).stepList[1].title
assert(sale == L.SELLITEMS .. ": Item 20 (" .. L.SELL_ITEM_EQUIPPED .. ")\n" .. L.VENDOR_TRASH)

local cachedTitle = C_QuestLog.GetTitleForQuestID
local requested = {}
function GetTime() return 0 end
C_QuestLog.GetTitleForQuestID = function() return nil end
C_QuestLog.RequestLoadQuestByID = function(id) requested[id] = (requested[id] or 0) + 1 end
local missing = render({ combined }).stepList[1].title
assert(missing:find("11 - Unknown", 1, true), "Uncached companion titles keep a readable fallback")
render({ combined })
assert(requested[11] == 1, "Repeated renders must not duplicate a quest title request")
C_QuestLog.GetTitleForQuestID = cachedTitle
assert(render({ combined }).stepList[1].title == title, "Loaded titles replace the fallback on refresh")
print("Quest order actions: every primary action, standalone helpers, sale details, completion, filters and read-only preview passed")
