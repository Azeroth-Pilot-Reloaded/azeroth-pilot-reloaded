local env = dofile("tools/validation/route_ui_test_env.lua")
local function noop() end
local step, profile = APR.currentStep, APR.settings.profile
step.UpdateStepButtonCooldowns, step.UpdateStepButtonUsability = noop, noop
step:PreviousNextStepButton()
profile.enableAddon, profile.showQuestOrderList = true, true
profile.currentStepScale, profile.questOrderListScale = 1, 1
profile.questOrderListbackgroundColorAlpha = { 0, 0, 0, 1 }
function APR:ShouldHideFrames() return not profile.enableAddon or not profile.currentStepShow end
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 100 end
function APR:SnapFrameToAnchor(frame, anchor, height, gap, header)
    frame:ClearAllPoints()
    frame:SetPoint("TOP", anchor, "TOP", 0, -(height + gap + (header or 0)))
    frame:SetScale(anchor:GetScale())
    return true
end
dofile("APR-Core/ui/route/FillersFrame.lua")
local fillers, fillerPasses = APR.fillersFrame, 0
local refresh = fillers.RefreshFillersFrame
fillers.RefreshFillersFrame = function(self, ...)
    fillerPasses = fillerPasses + 1
    return refresh(self, ...)
end
local function renderFillers()
    step:BeginContentUpdate()
    step:Reset()
    fillers:AddFillerStep(20, "Bonus objective", 2)
    fillers:AddFillerStep(10, "First bonus objective", 1)
    step:AddStepButton("20-2", 50, "item")
    step:EndContentUpdate(true)
end
renderFillers()
local first, second = step.fillersList["10-1"], step.fillersList["20-2"]
local icon = second.IconButton
local initialFrames, initialFonts = env.frames(), env.fonts()
local hidden, positioned, passes = fillers.Frame.hideCount, first.anchors, fillerPasses
for _ = 1, 100 do renderFillers() end
assert(env.frames() == initialFrames and env.fonts() == initialFonts)
assert(step.fillersList["20-2"] == second and second.IconButton == icon)
assert(first.layoutOffset < second.layoutOffset and first.anchors == positioned)
assert(first.hideCount == 0 and icon.hideCount == 0 and fillers.Frame.hideCount == hidden)
assert(fillerPasses - passes == 100, "One filler layout/visibility update per content pass")
fillers:UpdateFillerStep(10, string.rep("Long bonus objective ", 8), 1)
assert(first:GetHeight() > 22 and second.layoutOffset == first.layoutOffset + first:GetHeight())
first.scripts.OnEnter(first)
assert(GameTooltip.details.objectiveText == first.objectiveText, "Bonus tooltip uses updated text")

fillers.FrameHeader.MinimizeButton.scripts.OnClick()
renderFillers()
assert(not fillers.StepHolder:IsShown() and fillers.Frame:GetHeight() == 1, "Refresh preserves independent collapse")
fillers.FrameHeader.MinimizeButton.scripts.OnClick()
profile.fillersFrameSnapToCurrentStep, profile.fillersFrameShowHeader = true, true
fillers:RefreshFillersFrame(true)
local anchorChanges = fillers.Frame.anchors
fillers:RefreshFillersFrame(true)
assert(fillers.Frame.anchors == anchorChanges, "Unchanged snap geometry is not reapplied")
fillers:Hide()
renderFillers()
assert(not fillers.Frame:IsShown(), "Current-step collapse survives background refreshes")
fillers:Show()
assert(fillers.Frame:IsShown())

env.setCombat(true)
renderFillers()
step:BeginContentUpdate()
step:Reset()
step:EndContentUpdate(true)
assert(not next(step.fillersList) and second.hiddenInCombat)
fillers:AddFillerStep(20, "Replacement", 2)
local replacement = step.fillersList["20-2"]
env.setCombat(false)
step:FlushPendingContainers()
step:ProcessPendingStepButtons()
assert(step.fillersList["20-2"] == replacement and fillers.Frame:IsShown())
assert(not fillers.pendingRefresh and not fillers.layoutDirty)
fillers:RemoveFillerSteps()
assert(not fillers.Frame:IsShown(), "Empty bonus list hides once the content pass completes")
print("Fillers: stable rows/actions, 100 refreshes without allocation or hide/show, wrapping, order, collapse, snap and combat passed")

-- Run the actual route-list window, presenter and scheduler with a long route.
local timers, ticks, failures = {}, 0, {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
local function drainTimers()
    local pending = timers
    timers = {}
    for _, timer in ipairs(pending) do if not timer.cancelled then timer.callback() end end
end
function debugprofilestop() ticks = ticks + 1; return ticks end
function geterrorhandler() return function(err) failures[#failures + 1] = err end end
APR.StartPerformanceSample, APR.FinishPerformanceSample, APR.SetFontStringRole = noop, noop, noop
APR.ActiveRoute, APR.PlayerID = "route", "player"
APRData = { player = { route = 1, other = 1 } }
local route = {}
for index = 1, 1200 do route[index] = { Note = "Step " .. index } end
APR.RouteQuestStepList = { route = route, other = { { Note = "Other route" } } }
APR.routeconfig = { HasRouteInCustomPaht = function() return true end }
function APR:GetRouteSteps(key) return self.RouteQuestStepList[key] end
function APR:IsSojournerSkipActive() return false end
function APR:StepFilterQoL(entry) return not entry.hidden end
function APR:ResolveStepText(text) return text end
dofile("APR-Core/utils/QuestOrderListUtils.lua")
dofile("APR-Core/ui/route/QuestOrderList.lua")
dofile("APR-Core/ui/route/QuestOrderListRows.lua")
local list, scroll = APR.questOrderList, QuestOrderListFrame_ScrollFrame
local function drainRender()
    local batches = 0
    while list.renderFrame and list.renderFrame.scripts.OnUpdate do
        list.renderFrame.scripts.OnUpdate()
        batches = batches + 1
        assert(batches < 2000, "Renderer must settle")
    end
    return batches
end
list:AddStepFromRoute(true)
assert(#list.stepList == 0)
assert(drainRender() > 1 and #list.stepList == 1200 and list.renderComplete)
drainTimers()
scroll:SetVerticalScroll(500)
local visibleChild, rows, swaps = scroll.scrollChild, list.stepList, scroll.swaps
GameTooltip:SetOwner(rows[1])
local tooltipHides = GameTooltip.hideCount
list:AddStepFromRoute(true)
list.renderFrame.scripts.OnUpdate()
assert(scroll.scrollChild == visibleChild and list.stepList == rows and visibleChild:IsShown(),
    "Published rows remain visible throughout a budgeted refresh")
drainRender()
assert(scroll.swaps == swaps and scroll:GetVerticalScroll() == 500,
    "An unchanged refresh neither swaps the view nor changes manual scroll")
assert(GameTooltip.hideCount == tooltipHides, "An unchanged refresh retains the hovered tooltip")
local warmFrames, warmFonts = env.frames(), env.fonts()
for _ = 1, 5 do list:AddStepFromRoute(true); drainRender() end
assert(env.frames() == warmFrames and env.fonts() == warmFonts, "The two render buffers are reused")

route[20].Note = "Changed description"
list:AddStepFromRoute(true)
list.renderFrame.scripts.OnUpdate()
assert(scroll.scrollChild == visibleChild)
drainRender()
assert(scroll.swaps == swaps + 1 and scroll:GetVerticalScroll() == 500, "Changed data publishes once without scroll jumps")
assert(GameTooltip.hideCount == tooltipHides + 1, "Publishing changed rows dismisses their old tooltip")
assert(list.rawStepContainers[20].titleFont:GetText():find("Changed description"))
local offset = 0
for _, container in ipairs(list.stepList) do
    assert(container.point[5] == -offset)
    offset = offset + container:GetHeight()
end

-- Missing row presentations cannot create array holes or lose following rows.
route[2] = {}
route[3].hidden = true
list:AddStepFromRoute(true)
drainRender()
assert(#list.stepList == 1198 and not list.rawStepContainers[2] and not list.rawStepContainers[3])
assert(list.rawStepContainers[4].displayIndex == 2)

list:AddStepFromRoute(true)
list.renderFrame.scripts.OnUpdate()
APR.ActiveRoute = "other"
list.renderFrame.scripts.OnUpdate()
assert(list.currentRouteKey == "route", "A stale job cannot replace the published view")
drainTimers()
drainRender()
drainTimers()
assert(list.currentRouteKey == "other" and #list.stepList == 1)

APR.ActiveRoute = "route"
list:AddStepFromRoute(true)
drainRender()
drainTimers()
local buildCount, originalBuild = 0, list.CreateRouteRenderer
list.CreateRouteRenderer = function(self, ...)
    buildCount = buildCount + 1
    return originalBuild(self, ...)
end
for width = 270, 300 do QuestOrderListPanel.scripts.OnSizeChanged(QuestOrderListPanel, width, 400) end
assert(buildCount == 0, "Resizing does not synchronously rebuild the route")
drainTimers()
assert(buildCount == 1, "A width burst schedules one rebuild")
drainRender()
QuestOrderListPanel.scripts.OnSizeChanged(QuestOrderListPanel, 300, 500)
assert(not list.updateTimer, "Height-only resizing does not rebuild rows")
assert(scroll.scrollChild:GetWidth() == 278, "Scrollbar space is excluded from content width")

local previousView = scroll.scrollChild
list.CreateRouteRenderer = function() return function() error("simulated row failure") end end
list:AddStepFromRoute(true)
drainRender()
assert(#failures == 1 and scroll.scrollChild == previousView and list.renderFailed)
list.CreateRouteRenderer = originalBuild
list:AddStepFromRoute()
drainRender()
assert(not list.renderFailed, "A failed refresh can retry without losing the published list")

APRData.player.route = 20
list:AddStepFromRoute()
list:RemoveSteps()
drainTimers()
assert(scroll:GetVerticalScroll() == 0 and #list.stepList == 0 and not QuestOrderListPanel:IsShown(),
    "Removing the list also cancels queued scrolling")

-- Loot rows can render before visiting any collection step. There is no
-- QuestVirtualItemCount table; use the same live/saved counts as Current Step.
dofile("APR-Core/utils/LootUtils.lua")
assert(APR.QuestVirtualItemCount == nil)
local bagCount, bankCount, questComplete = 0, 0, false
C_Item.GetItemCount = function(_, includeBank)
    return bagCount and (bagCount + (includeBank and bankCount or 0)) or nil
end
C_QuestLog.IsQuestFlaggedCompleted = function(id)
    assert(id ~= nil, "A collection without a quest must not query a nil quest ID")
    return questComplete
end
local loot = { itemID = 100, quantity = 5, questID = 123 }
APR.ActiveRoute = "loot"
APRData.player.loot = 1
APR.RouteQuestStepList.loot = { { Note = "Before collecting" }, { LootItems = { loot } } }
local errorsBeforeLoot = #failures
local function assertLootDetails(expected)
    list:AddStepFromRoute(true)
    drainRender()
    assert(#failures == errorsBeforeLoot and not list.renderFailed, "Loot rows render without an obsolete cache")
    assert(#list.rawStepContainers[2].questFonts == expected, "Loot completion agrees with current collection counts")
end
assertLootDetails(1)
loot.questID = nil
assertLootDetails(1)
bagCount = nil
assertLootDetails(1)
bagCount = 2
assertLootDetails(1)
bankCount = 3
assertLootDetails(0)
bankCount = 0
APRData.player.BankItems = { [100] = 3 }
assertLootDetails(0)
APRData.player.BankItems[100] = 0
assertLootDetails(1)
bagCount = 5
assertLootDetails(0)
bagCount, loot.questID, questComplete = 0, 123, true
assertLootDetails(0)
questComplete = false
assertLootDetails(1)
APRData.player.loot = 3
assertLootDetails(0)
print("Quest order loot: absent cache, optional quest, unavailable count, bags, saved/live bank, completion and passed steps passed")
print("Quest order: 1200 rows, bounded build/recycling, atomic publishing, buffer reuse, scroll, filters, cancellation, resize and recovery passed")
