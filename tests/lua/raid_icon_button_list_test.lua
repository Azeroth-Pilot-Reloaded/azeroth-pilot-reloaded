local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/TargetUtils.lua")
local ui = APR.currentStep
ui.UpdateStepButtonCooldowns, ui.UpdateStepButtonUsability = function() end, function() end
ui:PreviousNextStepButton()
APRData = { NPCList = { [101] = "Premier", [202] = "Second", [303] = "Troisième" } }
function GetRaidTargetIndex() return nil end
local current
function APR:GetGameVersion() return "forever" end
function APR:GetCurrentStep() return current end
local function render(targets)
    current = { RaidIcon = targets, KillNPC = { npcID = 999 } }
    ui:BeginContentUpdate()
    ui:Reset()
    ui:PrepareRaidIcon(current)
    ui:AddQuestSteps(1, "Quest objective", 1)
    ui:AddQuestSteps(2, "Another objective", 1)
    ui:EndContentUpdate(true)
end
render({ 101, 202, 101 })
local button = ui.raidIconButtons[1]
assert(button and button.attributes.macrotext:find("/targetexact Premier", 1, true), "The first ID owns a useful standalone secure button")
assert(#ui.raidIconButtons == 2 and ui.raidIconButtons[2].attributes.macrotext:find("Second", 1, true))
assert(not button.attributes.macrotext:find("999", 1, true), "Explicit RaidIcon takes precedence over KillNPC")
assert(not ui.questsList["2-1"].RaidIconButton, "Only one button is attached")
local hides = button.hideCount
render({ 101, 202 })
assert(ui.raidIconButtons[1] == button and button.hideCount == hides,
    "An equivalent freshly allocated list reuses the visible button")
assert(button.attributes.macrotext:find("/targetmarker [@target,exists,nodead] !8", 1, true))
assert(not button.attributes.macrotext:find("/run", 1, true), "The macro uses native protected commands")
assert(not button.attributes.type2, "Only left-click executes the macro")

local previous = button.attributes.macrotext
env.setCombat(true)
render({ 202, 303 })
ui:UpdateRaidIconButtonMacro()
assert(button.attributes.macrotext == previous, "Secure macro attributes are frozen during combat")
render(303)
env.setCombat(false)
ui:ProcessPendingStepButtons()
button = ui.raidIconButtons[1]
assert(button.npcID == 303 and button.attributes.macrotext:find("Troisième", 1, true), "Only the latest deferred request survives")
assert(not button.attributes.macrotext:find("Second", 1, true), "Stale targets are discarded after combat")
current = {}
ui:BeginContentUpdate()
ui:Reset()
ui:PrepareRaidIcon(current)
ui:AddQuestSteps(1, "Following step", 1)
ui:EndContentUpdate(true)
assert(not ui.questsList["1-1"].RaidIconButton and not ui.raidIconButton, "The next step releases the targeting button")
assert(not button.scripts.PostClick, "A pooled button does not retain its marker callback")
print("RaidIcon UI: lists, precedence, button reuse, clicks, combat deferral and step cleanup passed")

-- Explicit bindings win over name guesses, with deterministic main-row fallbacks.
local function boundRender(targets, extrasOnly)
    ui:BeginContentUpdate()
    ui:Reset()
    ui:PrepareRaidIcon({ RaidIcon = targets })
    if extrasOnly then
        ui:AddExtraLineText("a", "First note")
        ui:AddExtraLineText("z", "Last note")
    else
        ui:AddQuestSteps(10, "Other beast", 1)
        ui:AddQuestSteps(20, "Premier slain: 0/1", 2)
    end
    ui:EndContentUpdate(true)
end
boundRender({ { npcID = 101, questID = 20, objectiveIndex = 2 }, 202 })
assert(ui.raidIconButtons[1].questID == 20 and ui.raidIconButtons[1].objectiveIndex == 2)
assert(ui.raidIconButtons[2].questID == 10)
C_QuestLog.GetQuestObjectives = function(id)
    if id == 20 then return { {}, { type = "monster", text = "Premier slain: 0/1" } } end
end
boundRender({101, 202})
assert(ui.raidIconButtons[1].questID == 20, "Localized kill objectives match the NPC name")
boundRender({101, 202}, true)
assert(select(2, ui.raidIconButtons[1]:GetPoint()) == ui.questsExtraTextList.z,
    "Without quests the last extra instruction hosts the targets")
assert(select(2, ui.raidIconButtons[2]:GetPoint()) == ui.raidIconButtons[1])

-- Optional objectives participate in matching without moving unrelated main actions.
function APR:ShouldHideFrames() return false end
function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 90 end
APR.settings.profile.fillersFrame, APR.settings.profile.currentStepScale = {}, 1
APR.settings.profile.fillersFrameSnapToCurrentStep = false
dofile("APR-Core/ui/route/FillersFrame.lua")
local function fillerRender(targets, withMain, withAction)
    ui:BeginContentUpdate()
    ui:Reset()
    ui:PrepareRaidIcon({RaidIcon = targets})
    if withMain then ui:AddQuestSteps(10, "Main action", 1) end
    APR.fillersFrame:AddFillerStep(30, "Premier slain: 0/2", 1)
    APR.fillersFrame:AddFillerStep(30, "Second slain: 0/3", 2)
    if withAction then ui:AddStepButton("30-1", 500, "item") end
    ui:EndContentUpdate(true)
end
C_QuestLog.GetQuestObjectives = function(id)
    if id == 30 then return {
        {type = "monster", text = "Premier slain: 0/2"},
        {type = "monster", text = "Second slain: 0/3"},
    } end
end
fillerRender({{npcID = 101, questID = 30, objectiveIndex = 1},
    {npcID = 202, questID = 30, objectiveIndex = 2}}, true)
local first, second = ui.raidIconButtons[1], ui.raidIconButtons[2]
assert(first.questHost == ui.fillersList["30-1"] and second.questHost == ui.fillersList["30-2"],
    "Explicit target associations must also find optional objective rows")
assert(first:GetParent() == APR.fillersFrame.StepHolder and second:GetParent() == APR.fillersFrame.StepHolder)
assert(select(2, first:GetPoint()) == ui.fillersList["30-1"] and select(2, second:GetPoint()) == ui.fillersList["30-2"])
fillerRender({101, 202}, true)
assert(first.questHost == ui.fillersList["30-1"] and second.questHost == ui.fillersList["30-2"],
    "Legacy NPC lists can match localized kill objectives in the optional panel")
fillerRender({303}, false)
assert(first.questHost == ui.fillersList["30-1"], "Filler-only steps fall back to their first quest row")
fillerRender({303}, true)
assert(first.questHost == ui.questsList["10-1"], "Unmatched targets prefer the first main quest")
print("RaidIcon optional objectives: explicit and automatic matching, parent and fallback passed")

fillerRender({101, 202}, true, true)
assert(select(2, first:GetPoint()) == ui.fillersList["30-1"].IconButton and select(5, first:GetPoint()) == 0,
    "A matching optional item action and raid icon stay on the same horizontal line")
local oldParent, oldHost = first:GetParent(), first.questHost
env.setCombat(true)
fillerRender({303}, true)
assert(first:GetParent() == oldParent and first.questHost == oldHost,
    "Combat must not reparent the secure target from an optional row")
env.setCombat(false)
ui:ProcessPendingStepButtons()
assert(first.questHost == ui.questsList["10-1"] and first:GetParent() == ui.questsList["10-1"]:GetParent(),
    "After combat the latest desired row replaces the optional association")

ui:BeginContentUpdate()
ui:Reset()
ui:PrepareRaidIcon({RaidIcon = 303})
APR.fillersFrame:AddFillerStep(20, "Later quest", 1)
APR.fillersFrame:AddFillerStep(3, "Earlier quest", 1)
ui:EndContentUpdate(true)
assert(first.questHost == ui.fillersList["3-1"], "Filler fallback follows numeric panel order")

-- Equal local dimensions alone do not imply equal rendered dimensions.
ui:BeginContentUpdate()
ui:Reset()
ui:PrepareRaidIcon({RaidIcon = {{npcID = 101, questID = 30, objectiveIndex = 1}}})
ui:AddQuestSteps(10, "Main action", 1)
ui:AddStepButton("10-1", 500, "item")
APR.fillersFrame:AddFillerStep(30, "Premier slain: 0/2", 1)
ui:EndContentUpdate(true)
local mainAction = ui.questsList["10-1"].IconButton
mainAction:GetParent():SetScale(0.75)
APR.fillersFrame.StepHolder:SetScale(1.4)
APR.RaidIconButtons:SetTargets({101})
assert(math.abs(first:GetWidth() * first:GetEffectiveScale() - mainAction:GetWidth() * mainAction:GetEffectiveScale()) < 0.0001,
    "Optional focus icons must match main quest buttons in screen pixels across different panel scales")
APR.fillersFrame.StepHolder:SetScale(0.6)
APR.RaidIconButtons:SetTargets({101})
assert(math.abs(first:GetHeight() * first:GetEffectiveScale() - mainAction:GetHeight() * mainAction:GetEffectiveScale()) < 0.0001,
    "Reused focus buttons must reconcile changed parent scaling")

assert(select(4, first:GetPoint()) == select(4, mainAction:GetPoint()),
    "A filler target and a main spell/item action use the same gap, aligning their button column")
assert(select(1, first:GetPoint()) == select(1, mainAction:GetPoint()) and
    select(3, first:GetPoint()) == select(3, mainAction:GetPoint()) and select(5, first:GetPoint()) == 0,
    "Standalone targets share the action-button edge and remain centered on their own objective row")
APR.settings.profile.currentStepQuestButtonPositionRight = true
ui:AddStepButton("10-1", 500, "item")
APR.RaidIconButtons:SetTargets({101})
assert(select(4, first:GetPoint()) == 5 and select(4, mainAction:GetPoint()) == 5,
    "The same five-pixel gap also applies on the right")
assert(select(1, first:GetPoint()) == "LEFT" and select(3, first:GetPoint()) == "RIGHT")

-- Completed/removed bound rows disappear from clicks AND the aggregate/cycle payload.
APR.settings.profile.currentStepQuestButtonPositionRight = false
local function renderBoundRows(firstPresent, secondPresent)
    ui:BeginContentUpdate()
    ui:Reset()
    ui:PrepareRaidIcon({RaidIcon = {
        {npcID = 101, questID = 40, objectiveIndex = 1},
        {npcID = 202, questID = 40, objectiveIndex = 2},
    }})
    ui:AddQuestSteps(10, "Unrelated remaining quest", 1)
    if firstPresent then APR.fillersFrame:AddFillerStep(40, "First objective", 1) end
    if secondPresent then APR.fillersFrame:AddFillerStep(40, "Second objective", 2) end
    ui:AddExtraLineText("note", "An unrelated note also remains")
    ui:EndContentUpdate(true)
end
renderBoundRows(true, true)
local removed = ui.raidIconButtons[2]
renderBoundRows(true, false)
assert(#ui.raidIconButtons == 1 and ui.raidIconButtons[1].npcID == 101,
    "A missing explicitly bound objective must not reattach its target to a surviving quest")
assert(not removed:IsShown() and not removed:GetAttribute("type1") and not removed:GetAttribute("macrotext"))
assert(not ui.raidIconButtons[1]:GetAttribute("apr-target-all-macro"):find("Second", 1, true),
    "The general targeting binding must also stop searching for the removed objective's NPC")
renderBoundRows(false, true)
local survivor = ui.raidIconButtons[1]
assert(#ui.raidIconButtons == 1 and survivor.npcID == 202 and survivor.targetIndex == 2)
assert(survivor:GetNormalTexture().texture == "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    "Removing skull's objective cannot renumber the surviving cross")
assert(survivor:GetAttribute("macrotext"):find("!7", 1, true) and
    survivor:GetAttribute("apr-target-all-macro"):find("!7", 1, true),
    "Mouse clicks and the general binding keep the surviving objective's original marker")
env.setCombat(true)
renderBoundRows(false, false)
assert(#ui.raidIconButtons == 1, "Protected controls reconcile after combat")
env.setCombat(false)
ui:ProcessPendingStepButtons()
assert(#ui.raidIconButtons == 0 and not ui.raidIconButton and not survivor:IsShown(),
    "The latest completed objectives remove all targets after combat, despite unrelated rows/notes")

-- A name-inferred relationship also survives refreshes of the same step.
local function renderInferred(context, showObjective)
    ui:BeginContentUpdate()
    ui:Reset()
    ui:PrepareRaidIcon({RaidIcon = {101}}, context)
    ui:AddQuestSteps(10, "Unrelated main row", 1)
    if showObjective then APR.fillersFrame:AddFillerStep(30, "Premier slain: 0/2", 1) end
    ui:EndContentUpdate(true)
end
renderInferred("synthetic-step-a", true)
assert(ui.raidIconButtons[1].questID == 30)
renderInferred("synthetic-step-a", false)
assert(#ui.raidIconButtons == 0,
    "An automatically matched NPC cannot migrate to an unrelated row after its objective disappears")
renderInferred("synthetic-step-b", false)
assert(#ui.raidIconButtons == 1 and ui.raidIconButtons[1].questID == 10,
    "A new step discards inferred associations and retains the ordinary unmatched-target fallback")
