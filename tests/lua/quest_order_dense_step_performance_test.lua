-- One synthetic step can contain many objectives. Its model preparation and
-- viewport binding must both yield without publishing incomplete content.
local env = dofile("tests/lua/route_ui_test_env.lua")
local function noop() end
local now, charge, failures = 0, false, {}
local failText
function debugprofilestop() return now end
function geterrorhandler() return function(err) failures[#failures + 1] = err end end
local createFont = env.methods.CreateFontString
function env.methods:CreateFontString(...)
    if charge then now = now + 0.2 end
    return createFont(self, ...)
end
local setText = env.methods.SetText
function env.methods:SetText(text)
    if charge then now = now + 0.05 end
    if failText and text == failText then error("synthetic dense font failure") end
    return setText(self, text)
end
local stringHeight = env.methods.GetStringHeight
function env.methods:GetStringHeight(...)
    if charge then now = now + 0.1 end
    return stringHeight(self, ...)
end
local hide = env.methods.Hide
function env.methods:Hide(...)
    if charge then now = now + 0.05 end
    return hide(self, ...)
end
function APR:SetFontStringRole(font, role)
    if charge then now = now + 0.1 end
    font.role = role
end
local profile = APR.settings.profile
profile.enableAddon, profile.showQuestOrderList = true, true
profile.questOrderListScale, profile.questOrderListSnapToCurrentStep = 1, false
profile.questOrderListbackgroundColorAlpha = { 0, 0, 0, 1 }
APR.StartPerformanceSample, APR.FinishPerformanceSample = noop, noop
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
function APR:IsSojournerSkipActive() return false end
function APR:IsTransportStep() return false end
function APR:StepFilterQoL() return true end
function APR:ResolveStepText(text) return text end
function APR:GetQuestTitle(id)
    if charge then now = now + 0.2 end
    return "Quest " .. id
end
C_QuestLog.IsQuestFlaggedCompleted = function()
    if charge then now = now + 0.2 end
    return false
end
local timers = {}
C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = timer
    return timer
end }
APR.ActiveRoute, APR.PlayerID, APR.ActiveQuests = "synthetic-dense", "player", {}
APRData = { player = { [APR.ActiveRoute] = 1 } }
local route = { { Note = "Old publication" }, { Note = "Old tail" } }
APR.RouteQuestStepList = { [APR.ActiveRoute] = route }
APR.routeconfig = { HasRouteInCustomPath = function() return true end }
function APR:GetRouteSteps() return route end
dofile("APR-Core/ui/route/QuestOrderListSupport.lua")
dofile("APR-Core/ui/foundations/VirtualList.lua")
dofile("APR-Core/ui/route/QuestOrderList.lua")
dofile("APR-Core/ui/route/QuestOrderListRows.lua")
local list, support = APR.questOrderList, APR.questOrderListSupport
QuestOrderListFrame_ScrollFrame:SetSize(236, 300)
local largestModelBatch, largestViewportBatch = 0, 0
local function renderModel()
    local before = now
    list.renderFrame.scripts.OnUpdate()
    local elapsed = now - before
    largestModelBatch = math.max(largestModelBatch, elapsed)
    assert(elapsed < 4, "A model batch stops within 3 ms plus one small atomic operation")
end
local function renderViewport()
    local before = now
    list.virtualList.renderFrame.scripts.OnUpdate()
    local elapsed = now - before
    largestViewportBatch = math.max(largestViewportBatch, elapsed)
    assert(elapsed < 3, "A viewport batch stops within 2 ms plus one small atomic operation")
end
local function drainModel()
    local batches = 0
    while list.renderFrame and list.renderFrame.scripts.OnUpdate do
        renderModel(); batches = batches + 1
        assert(batches < 2000, "A dense model must eventually finish")
    end
    return batches
end
local function drainViewport()
    local batches = 0
    while list.virtualList.renderFrame.scripts.OnUpdate do
        renderViewport(); batches = batches + 1
        assert(batches < 2000, "A dense viewport row must eventually finish")
    end
    return batches
end
list:AddStepFromRoute(true); drainModel(); drainViewport()
local oldPublication = list.stepList
local ids = {}
for index = 1, 300 do ids[index] = index end
local dense = { PickUp = ids }
route = { dense, { Note = "Tail two" }, { Note = "Tail three" } }
APR.RouteQuestStepList[APR.ActiveRoute] = route
charge = true
list:AddStepFromRoute(true)
local batches = 0
while list.renderFrame.scripts.OnUpdate do
    assert(list.stepList == oldPublication, "An incomplete dense model cannot replace the published route")
    renderModel(); batches = batches + 1
end
assert(batches > 50 and list.stepList ~= oldPublication and #list.stepList == 3)
local denseModel = list.stepList[1]
assert(#denseModel.questInfo == 300 and denseModel.questInfo[1].questID == 1
    and denseModel.questInfo[300].questID == 300, "Every independently chosen objective remains present and ordered")
assert(denseModel.frame == nil, "Publishing a model cannot synchronously bind its dense viewport row")
renderViewport()
local row = list.virtualList.active[1]
assert(row and row.modelBinding and not row:IsShown() and denseModel.frame == nil,
    "A partially bound row stays hidden and cannot receive tooltip/model updates")
assert(drainViewport() > 50)
assert(row:IsShown() and row.model == denseModel and denseModel.frame == row and not row.modelBinding)
assert(#row.questFonts == 300 and row.questFonts[300]:GetText() == "300 - Quest 300")

-- Step changes on an already published row must also go through the viewport
-- scheduler rather than changing hundreds of font roles in the event handler.
local beforeStyle = now
support:SetStepFrameState(denseModel, "green", false)
assert(now - beforeStyle < 0.1 and not row:IsShown(), "A published state change performs no inline dense font walk")
drainViewport()
assert(row.titleFont.role == "success" and row.questFonts[300].role == "muted")
beforeStyle = now
support:SetStepFrameState(denseModel, "gray", true)
assert(now - beforeStyle < 0.1)
drainViewport()
assert(row.titleFont.role == "activeStep" and row.questFonts[300].role == "base")

-- Progress can change while a row is still binding. Retarget the pending
-- coroutine even if the model identity and list generation remain unchanged.
list.virtualList:RefreshVisible(true); renderViewport()
local changedRequest = row.modelBinding
assert(changedRequest and denseModel.frame == nil)
support:SetStepFrameState(denseModel, "green", false)
assert(support:CollapseStepDetails(denseModel))
drainViewport()
assert(row.modelBinding ~= changedRequest and row.model == denseModel and #row.questFonts == 0
    and row.titleFont.role == "success", "A pending bind cannot revive objectives removed by current progress")

-- Cancelling during hidden measurement reuses its stored row/font pool.
list:AddStepFromRoute(true)
local waiting = 0
while #support.measureRow.questFonts == 0 or #support.measureRow.questFonts >= 300 do
    renderModel(); waiting = waiting + 1
    assert(waiting < 1000 and list.renderFrame.scripts.OnUpdate, "The dense measurement must become partially prepared")
end
route = { { Note = "After cancelled model" } }
APR.RouteQuestStepList[APR.ActiveRoute] = route
list:AddStepFromRoute(true); drainModel(); drainViewport()
assert(list.stepList[1].stepText:find("After cancelled model") and #list.stepList == 1)
local warmFrames, warmFonts = env.frames(), env.fonts()
for _ = 1, 3 do
    route = { dense }; APR.RouteQuestStepList[APR.ActiveRoute] = route
    list:AddStepFromRoute(true); drainModel()
    renderViewport()
    assert(list.virtualList.active[1].modelBinding, "The dense viewport bind is pending before replacement")
    local cancelledRequest = list.virtualList.active[1].modelBinding
    route = { { Note = "After cancelled viewport" } }; APR.RouteQuestStepList[APR.ActiveRoute] = route
    list:AddStepFromRoute(true); drainModel(); drainViewport()
    local replacement = list.virtualList.active[1]
    assert(replacement.modelBinding ~= cancelledRequest and not replacement.modelBinding
        and replacement.model == list.stepList[1] and #replacement.questFonts == 0)
end
assert(env.frames() == warmFrames and env.fonts() == warmFonts,
    "Cancelled dense work reuses measurement and viewport pools after warmup")

-- Scrolling away releases a pending bind before the recycled row gets new data.
route = { dense, { Note = "Offscreen replacement two" }, { Note = "Offscreen replacement three" } }
APR.RouteQuestStepList[APR.ActiveRoute] = route
list:AddStepFromRoute(true); drainModel(); renderViewport()
row = list.virtualList.active[1]
local pendingRequest = row.modelBinding
assert(pendingRequest)
QuestOrderListFrame_ScrollFrame:SetHeight(10)
list.virtualList:ScrollToIndex(3); drainViewport()
assert(not list.virtualList.active[1] and row.modelBinding ~= pendingRequest,
    "Recycling an offscreen row cancels its old dense binding")
QuestOrderListFrame_ScrollFrame:SetHeight(300)

-- A failed model retains the last complete route, and a retry can reuse its pool.
local beforeFailure = list.stepList
failText = "27 - Quest 27"
list:AddStepFromRoute(true); drainModel()
assert(#failures == 1 and list.renderFailed and list.stepList == beforeFailure)
failText = nil
list:AddStepFromRoute(); drainModel(); drainViewport()
assert(not list.renderFailed and list.stepList[1].questInfo[27].questID == 27)

-- A failed viewport bind releases the generic renderer guard; an explicit
-- refresh starts a fresh row request instead of resuming a failed coroutine.
list.virtualList:ScrollToIndex(1)
failText = "27 - Quest 27"
local failed = false
while list.virtualList.renderFrame.scripts.OnUpdate do
    local ok = pcall(renderViewport)
    if not ok then failed = true; break end
end
assert(failed and not list.virtualList.rendering and not list.virtualList.active[1].modelBinding)
failText = nil
list.virtualList:RefreshVisible(true); drainViewport()
assert(list.virtualList.active[1].model == list.stepList[1] and list.virtualList.active[1]:IsShown())

-- Native objective tables are per quest, not per objective. A single dense
-- QpartPart step must not allocate/request the same 300-objective table 300 times.
local objectiveReads = 0
C_QuestLog.GetQuestObjectives = function(id)
    assert(id == 1001)
    objectiveReads = objectiveReads + 1
    if charge then now = now + 0.2 end
    return nil -- Delayed native data keeps every objective pending.
end
APR.QUEST_STATUS = { COMPLETE = "complete" }
route = { { QpartPart = { [1001] = ids } } }
APR.RouteQuestStepList[APR.ActiveRoute] = route
list:AddStepFromRoute(true); drainModel(); drainViewport()
assert(objectiveReads == 1 and #list.stepList[1].questInfo == 300,
    "One native objective read supplies all pending objectives, including unavailable results")
local beforeCollapse = now
assert(support:CollapseStepDetails(list.stepList[1]))
assert(now - beforeCollapse < 0.1, "Collapsing a published dense model does not hide every font inline")
drainViewport()
assert(#list.virtualList.active[1].questFonts == 0)

-- A new generation supersedes a pending request even when the model identity
-- has not changed, as it does after external font or viewport changes.
list:UpdateFrameContents()
assert(list.updateTimer)
list.updateTimer.callback()
drainModel(); renderViewport()
local generationRequest = list.virtualList.active[1].modelBinding
assert(generationRequest)
list.virtualList:RefreshVisible(true); renderViewport()
assert(list.virtualList.active[1].modelBinding ~= generationRequest)
drainViewport()
assert(list.virtualList.active[1].model == list.stepList[1] and list.virtualList.active[1]:IsShown())

-- Real diagnostic wrappers must permit these nested yielding binders and leave
-- both coroutine and caller scopes clean after a caught rendering failure.
local diagnostics = APRInstrumentation
diagnostics.enabled = true
list.contentSignature = nil
list:AddStepFromRoute(true); drainModel(); drainViewport()
assert(diagnostics.CurrentName() == nil)
list.virtualList:RefreshVisible(true)
failed = false
-- QpartPart formats objective IDs separately from the quest title.
failText = "1001-27 - Quest 1001"
while list.virtualList.renderFrame.scripts.OnUpdate do
    local ok = pcall(renderViewport)
    if not ok then failed = true; break end
end
assert(failed and diagnostics.CurrentName() == nil and not list.virtualList.rendering,
    "A yielding viewport error unwinds diagnostic scopes and the rendering guard")
failText = nil
list.virtualList:RefreshVisible(true); drainViewport()
assert(diagnostics.CurrentName() == nil and list.virtualList.active[1]:IsShown())
diagnostics.enabled = false
assert(largestModelBatch > 0 and largestViewportBatch > 0)
print(string.format("Dense quest row: 300 objectives; model batches <= %.2f ms and viewport batches <= %.2f ms; atomic publication, cancellation, pools and failure recovery passed",
    largestModelBatch, largestViewportBatch))
