-- Owns route/step changes, stale-callback contexts and the last manual-skip undo.
-- History is session-only and bounded; game quest state is never restored by an undo.

local HISTORY_LIMIT = 40

local function GetProgress(self)
    return APRData and self.PlayerID and APRData[self.PlayerID]
end

local function InvalidateStep(self)
    self.stepRevision = (self.stepRevision or 0) + 1
    self.runtimeRouteStep = nil
    self.routeActionState = nil
    if self.stepUpdateTimer then
        self.stepUpdateTimer:Cancel()
        self.stepUpdateTimer = nil
    end
end

local function RecordTransition(self, route, previous, destination, reason)
    local history = self.transitionHistory or { entries = {}, cursor = 0, count = 0 }
    self.transitionHistory = history
    history.cursor = history.cursor % HISTORY_LIMIT + 1
    history.count = math.min(history.count + 1, HISTORY_LIMIT)
    history.entries[history.cursor] = {
        route = route, from = previous, to = destination, reason = reason or "progress",
        time = GetTime and GetTime() or 0,
    }
end

function APR:GetRecentTransitions()
    local result, history = {}, self.transitionHistory
    if not history then return result end
    for offset = 0, history.count - 1 do
        result[#result + 1] = history.entries[(history.cursor - offset - 1) % HISTORY_LIMIT + 1]
    end
    return result
end

-- Capture this before opening a dialog or scheduling work that can change progress.
function APR:CaptureStepContext()
    local progress = GetProgress(self)
    local route = self.ActiveRoute
    return {
        player = self.PlayerID, route = route, index = progress and route and progress[route],
        revision = self.stepRevision or 0,
        definition = route and self.RouteQuestStepList and self.RouteQuestStepList[route],
    }
end

function APR:IsStepContextCurrent(context)
    if not context then return false end
    local current = self:CaptureStepContext()
    return current.player == context.player and current.route == context.route
        and current.index == context.index and current.revision == context.revision
        and current.definition == context.definition
end

-- Route owners still decide when to refresh navigation/UI; this method only changes state.
function APR:ActivateRoute(route, reason)
    if route ~= nil and type(route) ~= "string" then return false end
    if self.ActiveRoute == route then return false end
    local previous = self.ActiveRoute
    self.ActiveRoute = route
    self.manualSkipUndo = nil
    InvalidateStep(self)
    RecordTransition(self, route, previous, route, reason or "route_changed")
    return true
end

-- The single writer for route progress, including inactive route initialization/reset.
-- Zero, NaN and infinity are rejected before they can reach SavedVariables.
function APR:SetRouteProgress(route, index, reason)
    local progress = GetProgress(self)
    if not progress or type(route) ~= "string" or type(index) ~= "number"
        or index ~= index or index == math.huge or index < 1 or index % 1 ~= 0 then
        return false
    end
    local previous = progress[route]
    if previous == index then return false end
    progress[route] = index
    if route == self.ActiveRoute then
        InvalidateStep(self)
        if not self.manualSkipRefreshing then self.manualSkipUndo = nil end
    end
    RecordTransition(self, route, previous, index, reason)
    return true
end

function APR:TransitionStep(index, reason, refresh, context)
    if context and not self:IsStepContextCurrent(context) then return false end
    if not self:SetRouteProgress(self.ActiveRoute, index, reason) then return false end
    if refresh == "quests" then
        self:UpdateQuestAndStep()
    elseif refresh ~= false then
        self:UpdateStep()
    end
    return true
end

function APR:AdvanceStep(refresh, context)
    local progress = GetProgress(self)
    local index = progress and self.ActiveRoute and progress[self.ActiveRoute]
    if not index then return false end
    return self:TransitionStep(index + 1, "automatic", refresh, context)
end

-- Capture before the refresh: it can synchronously complete additional steps.
function APR:CommitManualSkip(destination)
    local context = self:CaptureStepContext()
    if not context.route or not context.index or context.index == destination then return false end
    self.manualSkipRefreshing = true
    local ok, changed = pcall(self.TransitionStep, self, destination, "manual_skip", "quests", context)
    self.manualSkipRefreshing = nil
    if not ok then self.manualSkipUndo = nil; error(changed, 0) end
    if changed and self.ActiveRoute == context.route then
        self.manualSkipUndo = { before = context, after = self:CaptureStepContext() }
    end
    return changed
end

function APR:CanUndoManualSkip()
    return self.manualSkipUndo ~= nil and self:IsStepContextCurrent(self.manualSkipUndo.after)
end

function APR:UndoManualSkip()
    if not self:CanUndoManualSkip() then self.manualSkipUndo = nil; return false end
    local undo = self.manualSkipUndo
    self.manualSkipUndo = nil
    return self:TransitionStep(undo.before.index, "undo_manual_skip", "quests", undo.after)
end
