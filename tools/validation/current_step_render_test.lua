local env = dofile("tools/validation/route_ui_test_env.lua")
local function noop() end
local step = APR.currentStep
step.UpdateStepButtonCooldowns, step.UpdateStepButtonUsability = noop, noop
step:PreviousNextStepButton()

local function render(text, details)
    step:BeginContentUpdate()
    step:Reset()
    step:PrepareRaidIcon({})
    step:AddExtraLineText("hint", "Follow the road")
    step:AddQuestSteps(1, text, 1)
    step:AddStepButton("1-1", 50, "item")
    step:AddQuestStepsWithDetails("PickUp", "Pick up", details or { 2, 3 })
    step:EndContentUpdate(true)
end
render("Collect 0/10")
local row, hint, detail = step.questsList["1-1"], step.questsExtraTextList.hint, step.questsList.PickUp
local button = row.IconButton
local initialFrames, initialFonts, initialLayouts = env.frames(), env.fonts(), env.layouts()
local anchors = row.anchors
for _ = 1, 100 do render("Collect 0/10") end
assert(step.questsList["1-1"] == row and step.questsExtraTextList.hint == hint)
assert(step.questsList.PickUp == detail and row.IconButton == button)
assert(env.frames() == initialFrames and env.fonts() == initialFonts, "Unchanged refreshes allocate no widgets")
assert(row.hideCount == 0 and button.hideCount == 0, "Unchanged rows and actions never blink")
assert(row.anchors == anchors, "Unchanged row anchors are not reset")
assert(env.layouts() - initialLayouts == 100, "A complete refresh performs exactly one layout")

render(string.rep("Long objective ", 10), { 4 })
assert(row:GetHeight() > 30 and row.font.width == 218, "Wrapped objective grows within the margins")
assert(detail.detailFonts[1].width == 209 and not detail.detailFonts[2]:IsShown())
row.scripts.OnEnter(row)
assert(GameTooltip.details.objectiveText == row.objectiveText, "Tooltip reads the latest objective")
detail.detailFonts[1].scripts.OnEnter(detail.detailFonts[1])
assert(GameTooltip.questID == 4, "Reused detail tooltips follow their new quest")

step:ProgressBar("a", 10, 2)
local progress, before = step.progressBar, env.frames()
step:ProgressBar("b", 50, 20)
assert(step.progressBar == progress and env.frames() == before and progress.maximum == 50)
CurrentStepScreenPanel.collapsed = true
step:ProgressBar("b", 60, 21)
assert(not progress:IsShown(), "Refresh respects collapse")
CurrentStepScreenPanel.collapsed = false
step:ProgressBar("b", 60, 21)
assert(progress:IsShown())

APR.GetQuestObjectiveProgressPercent = function() return 45 end
step:UpdateQuestStep(1, "Rescue the villagers", 1)
assert(row.font:IsShown() and row.questProgressBar.value == 45, "Percent progress keeps its objective label")
APR.GetQuestObjectiveProgressPercent = noop
step:UpdateQuestStep(1, "Done", 1)
assert(not row.questProgressBar:IsShown() and row:GetHeight() == 30)

env.setCombat(true)
render("Changed in combat")
assert(row.IconButton == button and row.hideCount == 0)
step:BeginContentUpdate()
step:Reset()
step:AddQuestSteps(2, "Next objective", 1)
step:EndContentUpdate(true)
assert(not step.questsList["1-1"] and row.hiddenInCombat, "Retired secure row is deferred by identity")
step:AddQuestSteps(1, "Replacement using the same key", 1)
local replacement = step.questsList["1-1"]
env.setCombat(false)
step:FlushPendingContainers()
step:ProcessPendingStepButtons()
assert(step.questsList["1-1"] == replacement and replacement:IsShown(), "Combat cleanup preserves replacements")

step:BeginContentUpdate()
step:Reset()
step:EndContentUpdate(false)
assert(step.questsList["1-1"] == replacement and not step.contentUpdateActive,
    "An interrupted or failed pass retains content and releases the batching guard")
step:BeginContentUpdate()
step:Reset()
step:AddQuestSteps(1, "Recovered", 1)
step:EndContentUpdate(true)
assert(not step.questsList["2-1"], "Successful refresh removes obsolete content")

-- Actions removed by a later combat refresh must not be resurrected by an
-- earlier queued request when PLAYER_REGEN_ENABLED drains pending work.
step:AddStepButton("1-1", 50, "item")
env.setCombat(true)
step:AddStepButton("1-1", 51, "item")
step:BeginContentUpdate()
step:Reset()
step:AddQuestSteps(1, "No item needed anymore", 1)
step:EndContentUpdate(true)
assert(not step.pendingButtonRequests["1-1"])
env.setCombat(false)
step:ProcessPendingStepButtons()
assert(not replacement.IconButton)
env.setCombat(true)
step:UpdateQuestStep(1, string.rep("Long text ", 20), 1)
assert(step.layoutDirty, "Rows with retired secure children still defer geometry changes")
env.setCombat(false)
step:FlushPendingContainers()

APR.IsNavigationQuestUiKey = function(_, key) return key == "01_NAV" end
APR.IsNavigationExtraTextUiKey = function(_, key) return key == "00_DEST" end
APR.farstrider = { showOutOfZoneStepContent = true, NavigationDividerStepKey = "01_NAV",
    ErrorDestinationLineKey = "00_DEST" }
step:AddQuestDivider("01_NAV")
step:AddExtraLineText("00_DEST", "Destination", nil, false)
step:AddExtraLineText("route-hint", "Hint", nil, false)
local navigation, destination = step.questsList["01_NAV"], step.questsExtraTextList["00_DEST"]
local redirected = step.questsList["04_EXTRA_LINE_route-hint-EXTRA"]
step:BeginContentUpdate()
step:RemoveStepContentPreservingNavigationUi()
step:AddExtraLineText("route-hint", "Updated hint", nil, false)
step:EndContentUpdate(true)
assert(step.questsList["01_NAV"] == navigation and step.questsExtraTextList["00_DEST"] == destination)
assert(step.questsList["04_EXTRA_LINE_route-hint-EXTRA"] == redirected)
assert(destination.layoutOffset < navigation.layoutOffset and navigation.layoutOffset < redirected.layoutOffset)
assert(redirected.font:GetText() == "Updated hint", "Explicit dash preference survives redirection")
APR.farstrider = nil

-- Preview rows participate in reconciliation, and missing texture dimensions
-- must not leave a perpetual layout loop running on every client frame.
function APR:NormalizePreviewImages(value) return value.PreviewImages end
function APR:ResolveUIFileAsset(path) return path end
function APR:AreOrderedStringListsEqual(a, b)
    if #a ~= #b then return false end
    for index, value in ipairs(a) do if b[index] ~= value then return false end end
    return true
end
dofile("APR-Core/ui/route/CurrentStepImagePreview.lua")
APR.currentStepImagePreview:ConfigureCurrentStepPreview(CurrentStepFrame_StepHolder, 250)
local previewStep = { PreviewImages = { "test-image" } }
APR.currentStepImagePreview:SetPreviewImages(step, previewStep)
local preview
for _, container in pairs(step.questsList) do if container.previewButtons then preview = container end end
assert(preview)
step:BeginContentUpdate()
step:Reset()
APR.currentStepImagePreview:SetPreviewImages(step, previewStep)
step:EndContentUpdate(true)
assert(step.questsList[preview.key] == preview and preview.hideCount == 0)
local previewButton, beforeProbeLayouts = preview.previewButtons[1], env.layouts()
for _ = 1, 20 do
    if previewButton.scripts.OnUpdate then previewButton.scripts.OnUpdate(previewButton, 0.05) end
end
assert(not previewButton.scripts.OnUpdate and env.layouts() == beforeProbeLayouts,
    "Missing image dimensions stop probing without repeated layout")
print("Current step: 100 refreshes without allocations or hide/show; single layout, wrapping, tooltips, progress, combat and recovery passed")
