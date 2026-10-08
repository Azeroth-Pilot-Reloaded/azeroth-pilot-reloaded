-- State transitions must invalidate delayed work without rewriting route definitions.
local route = { { Note = "first" }, { Note = "second" }, { Note = "third" } }
APR = { PlayerID = "player", ActiveRoute = "route", RouteQuestStepList = { route = route, other = {} } }
APRData = { player = { route = 1, other = 1 } }
function GetTime() return 42 end
dofile("APR-Core/features/questing/StepTransitions.lua")
local refreshes = 0
function APR:UpdateStep() refreshes = refreshes + 1 end
function APR:UpdateQuestAndStep() self:UpdateStep() end

local cancelled = false
APR.stepUpdateTimer = { Cancel = function() cancelled = true end }
APR.runtimeRouteStep = {}
local stale = APR:CaptureStepContext()
assert(APR:AdvanceStep(false, stale))
assert(APRData.player.route == 2 and cancelled and not APR.runtimeRouteStep)
assert(not APR:AdvanceStep(false, stale), "A delayed action cannot advance a different step")
assert(not APR:SetRouteProgress("route", 0 / 0))
assert(not APR:SetRouteProgress("route", math.huge))
assert(not APR:SetRouteProgress("route", 1.5))
assert(not APR:SetRouteProgress("route", 0))

APR:SetRouteProgress("route", 1)
assert(APR:CommitManualSkip(2) and APR:CanUndoManualSkip())
assert(APR:UndoManualSkip() and APRData.player.route == 1 and not APR:CanUndoManualSkip())
assert(not APR:UndoManualSkip(), "Undo is consumed once")

-- Synchronous automatic completions during a manual skip form one undo operation.
function APR:UpdateQuestAndStep()
    if APRData.player.route == 2 then self:AdvanceStep(false) end
    self:UpdateStep()
end
assert(APR:CommitManualSkip(2) and APRData.player.route == 3)
assert(APR:UndoManualSkip() and APRData.player.route == 1)
assert(APR:CommitManualSkip(2))
APR:AdvanceStep(false)
assert(not APR:CanUndoManualSkip(), "New gameplay progress expires the manual undo")

APR:SetRouteProgress("route", 1)
APR:CommitManualSkip(2)
APR.RouteQuestStepList.route = { { Note = "replacement" } }
assert(not APR:CanUndoManualSkip(), "An import cannot undo into a previous definition")
APR:ActivateRoute("other")
assert(not APR:CanUndoManualSkip())
for index = 2, 100 do APR:SetRouteProgress("other", index) end
local history = APR:GetRecentTransitions()
assert(#history == 40 and history[1].to == 100 and history[40].to == 61)

-- Optional-group dialogs capture their original route and step.
function LibStub() return { GetLocale = function() return { OPTIONAL_SUGGESTED_PLAYERS = "%d players" } end } end
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
APR.GetCurrentStep = function() return { Group = { questID = 10, Number = 3 } } end
APRData.player.WantedQuestList = {}
local accept
APR.questionDialog = { CreateQuestionPopup = function(_, _, _, callback) accept = callback end }
APR.UpdateNextStep = function() error("Stale dialog changed progress") end
dofile("APR-Core/features/questing/StepInstructions.lua")
APR.stepHandlers.GroupQuestPopup()
APR:ActivateRoute("route")
accept()
assert(APRData.player.WantedQuestList[10] == nil)
-- The existing rollback command/button uses the same previous-step path.
dofile("APR-Core/utils/StepUtils.lua")
APR.RouteQuestStepList.route = route
function APR:GetRouteSteps() return route end
function APR:StepFilterQuestHandler() return false end
function APR:UpdateQuestAndStep() self:UpdateStep() end
APR:SetRouteProgress("route", 1)
assert(APR:CommitManualSkip(3))
assert(APR:PreviousQuestStep() and APRData.player.route == 1,
    "Rollback must undo the whole manual skip, not just return one step")
APR:SetRouteProgress("route", 3)
assert(APR:PreviousQuestStep() and APRData.player.route == 2,
    "Without a valid skip, rollback keeps its normal previous-step behavior")
assert(APR:PreviousQuestStep() and APRData.player.route == 1)
assert(not APR:PreviousQuestStep() and APRData.player.route == 1)
print("Transitions: context guards, rollback undo/fallback, expiry, bounded history and stale dialogs passed")
