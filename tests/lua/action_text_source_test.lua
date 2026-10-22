-- The arrow consumes the guide's resolved instructions, including when the
-- guide window is hidden. Failed render passes never publish partial text.
local env = dofile("tests/lua/route_ui_test_env.lua")
local function noop() end
tinsert = table.insert
local L = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return L end } end
dofile("APR-Core/utils/StepUtils.lua")

APR.PlayerID, APR.ActiveRoute = "player", "action-text"
APR.settings.profile.arrowActionText = true
APRData = { player = { ["action-text"] = 1 } }
APR.ActiveQuests = {}
APR.GetQuestTitle = function(_, id) return "Quest " .. id end
APR.EnsureQuestPool, APR.ResetQuestPool, APR.TrackQuest = noop, noop, noop
APR.ResolveTextColorRole = function(_, color) return color == "ff0000" and "error" or "title" end
C_QuestLog.IsQuestFlaggedCompleted = function() return false end
APR.stepHandlers = {}
dofile("APR-Core/features/questing/StepQuestHandlers.lua")
local step, refreshes = APR.currentStep, 0
step:PreviousNextStepButton()
APR.Arrow = { UpdateActionText = function() refreshes = refreshes + 1 end }

local function token() return APR:GetCurrentStepToken(APR.ActiveRoute, APRData.player[APR.ActiveRoute]) end
local function render(definition, draw, success)
    step:BeginContentUpdate()
    step:SetActionTextStep(definition, token())
    if draw then draw() end
    step:EndContentUpdate(success ~= false)
    return step:GetActionTextLines()
end
local function text(lines)
    local values = {}
    for _, line in ipairs(lines) do values[#values + 1] = line.text end
    return table.concat(values, "\n")
end

local lines = render({ PickUp = { 10 } }, function()
    step:SetActionTextScope("secondary")
    step:AddExtraLineText("hint", "Talk to the quest giver", "ff0000")
    step:SetActionTextScope(nil)
    step:AddQuestSteps("01_NAVIGATION_PATH", "Transient portal instruction", 1)
    step:SetActionTextScope("primary")
    APR.stepHandlers.PickUp({ PickUp = { 10 } }, true, 1)
end)
assert(text(lines) == "PICK_UP_Q\nQuest 10", "Primary pickup text and quest details share the rendered source")
assert(lines[1].role == "title" and lines[2].role == "base")
assert(step.questsList.PickUp.subTexts[1].text == "- " .. lines[2].text,
    "Guide and arrow use the same detail resolution")

APR.settings.profile.currentStepShow = false
APR.ActiveQuests[10] = {}
local before = env.frames()
lines = render({ Done = { 10 } }, function()
    step:SetActionTextScope("primary")
    APR.stepHandlers.Done({ Done = { 10 } }, true, 1)
end)
assert(text(lines) == "TURN_IN_Q\nQuest 10" and env.frames() == before,
    "Turn-in labels remain available without allocating hidden guide widgets")

lines = render({ Note = { "First", "Second" } }, function()
    step:SetActionTextScope("secondary")
    step:AddExtraLineText("hint", "Companion instruction")
    step:SetActionTextScope("primary")
    step:AddExtraLineText("NOTE_1", "First")
    step:AddExtraLineText("NOTE_2", "Second", "ff0000")
end)
assert(text(lines) == "First\nSecond" and lines[2].role == "error", "Note is a primary action with resolved text roles")

lines = render({ ExtraLineText = "Hint", BuyMerchant = {} }, function()
    step:SetActionTextScope("secondary", "BuyMerchant")
    step:AddExtraLineText("hint", "Hint", "ff0000")
    step:AddQuestSteps("BUY_ITEM", "Buy 2 Apples", "Apple")
end)
assert(text(lines) == "Hint\nBuy 2 Apples" and lines[1].role == "error",
    "Extra lines and secondary actions are the fallback when no primary action exists")

lines = render({ Qpart = { [10] = { 1 } } }, function()
    step:SetActionTextScope("primary")
    step:AddQuestSteps(10, "Collect 0/5", 1)
    step:AddQuestSteps(10, "Collect 1/5", 1)
end)
assert(text(lines) == "Collect 1/5", "Repeated row updates replace their text instead of duplicating it")
step:UpdateQuestStep(10, "Collect 2/5", 1)
assert(text(step:GetActionTextLines()) == "Collect 2/5", "Live progress updates also work with the guide hidden")
render({ Qpart = { [10] = { 1 } } }, function()
    step:SetActionTextScope("primary")
    step:AddQuestSteps(10, "Uncommitted progress", 1)
    step:UpdateQuestStep(10, "Uncommitted live progress", 1)
    assert(text(step:GetActionTextLines()) == "Collect 2/5", "Live changes inside a pass cannot leak before commit")
end, false)
assert(text(step:GetActionTextLines()) == "Collect 2/5", "Failed passes preserve the last committed presentation")
APRData.player[APR.ActiveRoute] = 2
assert(#step:GetActionTextLines() == 0, "A step change immediately invalidates the previous action text")
render({ Note = "Not published" }, function()
    step:SetActionTextScope("primary")
    step:AddExtraLineText("note", "Not published")
end, false)
assert(#step:GetActionTextLines() == 0, "A failed new step never republishes the previous step's text")

for key, expected in pairs({ ExitTutorial = "SKIP_TUTORIAL", Group = "GROUP_Q", WarMode = "TURN_ON_WARMODE",
    VehicleExit = "LEAVE_VEHICLE", MountVehicle = "MOUNT_VEHICLE" }) do
    assert(text(render({ [key] = true })) == expected, "Existing summary fallback covers rowless action " .. key)
end
assert(#render({ Fillers = { [10] = { 1 } }, NpcDismount = 10 }) == 0,
    "Fillers and automatic companion fields never become arrow instructions")
lines = render({ GroupTask = 10, ChromiePick = 6, MountVehicle = true, VehicleExit = true })
assert(#lines == 4 and lines[1].text == APR:GetStepString({ GroupTask = 10 }) and
    lines[2].text == APR:GetStepString({ ChromiePick = 6 }), "Every rowless secondary action shares its existing label")

-- Exercise the real renderer, real requirement classification, and real quest
-- handlers together instead of supplying the collector's scopes in the test.
L.BUY_ITEM = "Buy %s %s"
format = string.format
local definition
APR.IsInRouteZone, APR.settings.profile.enableAddon = true, true
APR.RouteQuestStepList = { [APR.ActiveRoute] = {} }
APR.EXPANSIONS = {}
APR.AFK = { lastStep = 2, HideFrame = noop }
APR.Buff = { RemoveAllBuffIcon = noop }
APR.party = { SendGroupMessage = noop, RefreshPartyFrameAnchor = noop }
APR.currentStepImagePreview = { ClearPreviewImages = noop }
APR.navigation = { ScheduleRouteCheck = noop, Render = function()
    step:AddQuestSteps("01_NAVIGATION_PATH", "Transient navigation instruction", 0)
end }
APR.Arrow.SetCoord = noop
APR.questOrderList.DelayedUpdate = noop
APR.SendMessage, APR.ResetMissingQuests = noop, noop
APR.MaybeSojournerPrompt, APR.CheckSojournerPartySync = noop, noop
APR.SkipStepCondition, APR.ShouldSojournerSkipStep = function() return false end, function() return false end
APR.CaptureStepContext = function() return {} end
APR.IsStepContextCurrent = function() return true end
APR.GetStep, APR.GetCurrentStep = function() return definition end, function() return definition end
step.SetProgressBar, step.UpdateStepButtonCooldowns = noop, noop
C_Item.GetItemCount = function() return 0 end
function UnitIsDeadOrGhost() return false end
function VehicleExit() end
dofile("APR-Core/features/questing/StepInstructions.lua")
APR.stepHandlers.RenderScenarioTravel, APR.stepHandlers.CheckCooldownSkips = noop, noop
APR.stepHandlers.RenderScenarioProgress = noop
dofile("APR-Core/features/questing/StepRenderer.lua")
local function renderCurrent(value)
    definition = value
    step:BeginContentUpdate()
    APR:RenderCurrentStep()
    step:EndContentUpdate(true)
    return text(step:GetActionTextLines())
end
APR.ActiveQuests[10] = nil
assert(renderCurrent({ PickUp = { 10 }, Note = "Accept the quest", ExtraLineText = "Extra hint",
    BuyMerchant = { { itemID = 20, quantity = 2 } } }) == "Accept the quest\nPICK_UP_Q\nQuest 10",
    "The actual renderer keeps Note and pickup primary while excluding merchant and extra hints")
APR.ActiveQuests[10] = {}
assert(renderCurrent({ Done = { 10 }, BuyMerchant = { { itemID = 20, quantity = 2 } } }) == "TURN_IN_Q\nQuest 10",
    "The actual renderer keeps turn-in ahead of its secondary merchant action")
assert(renderCurrent({ ExtraLineText = { "Hint one", "Hint two" } }) == "Hint one\nHint two",
    "Standalone authored extra lines render under the arrow with the guide hidden")
assert(renderCurrent({ BuyMerchant = { { itemID = 20, quantity = 2 } }, VehicleExit = true }) ==
    "Buy 2 Item 20\nLEAVE_VEHICLE", "Captured merchant text and rowless secondary labels have no duplicates")

L.Q_DROP = "Loot the quest from %s"
APRData.NPCList = { [54] = "Quest dropper" }
local dropped = { DropQuest = 42, DroppableQuest = { Qid = 42, MobId = 54 } }
assert(renderCurrent(dropped) == "Loot the quest from Quest dropper")
assert(APR:GetStepString(dropped) == "Loot the quest from Quest dropper",
    "Dropped-quest guide rows and summary fallback share their resolved label")
assert(renderCurrent({ DropQuest = 42 }) == "Loot the quest from Unknown",
    "A rowless dropped quest never displays a raw format placeholder")

APR.settings.profile.arrowActionText = false
local lookups, originalTitle = 0, APR.GetQuestTitle
APR.GetQuestTitle = function(...) lookups = lookups + 1; return originalTitle(...) end
step:BeginContentUpdate()
step:SetActionTextScope("primary")
step:AddQuestStepsWithDetails("PickUp", "Pick up", { 99 })
step:EndContentUpdate(true)
assert(not step.pendingActionText and lookups == 0,
    "The disabled option adds no detail resolution or collection to a hidden guide")
APR.settings.profile.arrowActionText = true
step:BeginContentUpdate()
step:EndContentUpdate(true)
assert(#step:GetActionTextLines() == 0, "A successful pass without an authored step clears the previous source")
assert(refreshes > 10, "Stable commits and live updates refresh the arrow")
print("Action text source: shared pickup/turn-in details, primary/secondary scopes, notes, hidden guide, live progress, tokens and failed passes passed")
