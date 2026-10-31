-- Activation must let the event owner install validation before callers can act.
-- These routes describe writer contracts; no shipped itinerary is a fixture.
local function fixture()
    APR = {
        PlayerID = "player", ActiveRoute = "alpha", stepRevision = 7,
        RouteQuestStepList = {
            alpha = { steps = { {}, {}, {}, {} } },
            beta = { steps = { {}, {}, {}, {} } },
        },
    }
    APRData = { player = { alpha = 2, beta = 3 } }
    local state = { releases = 0, cancels = 0, requests = 0, refreshes = 0 }
    APR.NavigationData = { ReleaseWaypoints = function() state.releases = state.releases + 1 end }
    APR.navigation = {
        Cancel = function(_, reason)
            assert(reason == "step_changed")
            state.cancels = state.cancels + 1
        end,
        RequestUpdate = function() state.requests = state.requests + 1 end,
    }
    function APR:UpdateStep() state.refreshes = state.refreshes + 1 end
    function APR:UpdateQuestAndStep() self:UpdateStep() end
    dofile("APR-Core/features/questing/StepTransitions.lua")
    return state
end

-- Optional Event support, rejected routes and identical selections retain the
-- ordinary writer behavior. Neither a rejection nor a no-op notifies the owner.
fixture()
assert(APR:ActivateRoute("beta", "without_event") and APR.stepRevision == 8)
APR.event = {}
assert(APR:ActivateRoute("alpha", "without_hook") and APR.stepRevision == 9)
local calls = 0
function APR.event:OnRouteActivated() calls = calls + 1 end
function APR:CanStartRoute(route) return route ~= "denied" end
local context = APR:CaptureStepContext()
assert(not APR:ActivateRoute({}) and not APR:ActivateRoute("denied"))
assert(not APR:ActivateRoute("alpha") and calls == 0 and APR:IsStepContextCurrent(context))

-- The hook sees the complete new context and synchronously puts up its barrier.
-- A caller that immediately renders or advances after selection cannot pass it.
local state = fixture()
local oldContext = APR:CaptureStepContext()
local timerCancels, hookCalls = 0, 0
APR.transportArrivalTimer = { Cancel = function() timerCancels = timerCancels + 1 end }
APR.stepUpdateTimer = { Cancel = function() timerCancels = timerCancels + 1 end }
APR.runtimeRouteStep, APR.routeActionState, APR.manualSkipUndo = {}, {}, {}
APR.event = {}
function APR.event:OnRouteActivated(route, previous, reason)
    hookCalls = hookCalls + 1
    assert(self == APR.event and route == "beta" and previous == "alpha" and reason == "manual_selection")
    assert(APR.ActiveRoute == route and APR.stepRevision == 8)
    assert(not APR:IsStepContextCurrent(oldContext) and not APR.manualSkipUndo)
    assert(not APR.runtimeRouteStep and not APR.routeActionState)
    assert(not APR.transportArrivalTimer and not APR.stepUpdateTimer and timerCancels == 2)
    assert(state.releases == 1 and state.cancels == 1 and state.requests == 1)
    local transition = APR:GetRecentTransitions()[1]
    assert(transition.from == previous and transition.to == route and transition.reason == reason)
    APR.routeValidationPending = { player = APR.PlayerID, data = APRData.player, route = route }
end
assert(APR:ActivateRoute("beta", "manual_selection") and hookCalls == 1)
assert(not APR:TransitionStep(4, "automatic", false) and not APR:CommitManualSkip(4))
local selectedContext = APR:CaptureStepContext()
assert(not APR:AdvanceStep(false, selectedContext) and APRData.player.beta == 3)
local request = APR.routeValidationPending
assert(request.advance == selectedContext)
assert(not APR:AdvanceStep(false) and request.advance == selectedContext,
    "Repeated completion observations keep one contextual receipt")
assert(not APR:AdvanceStep(false, oldContext) and request.advance == selectedContext,
    "A stale callback cannot replace the selected route's receipt")
APR.routeValidationPending = nil
assert(not APR:ActivateRoute("beta", "validated_activation") and hookCalls == 1,
    "An already selected route does not invoke its activation hook a second time")
assert(APR:AdvanceStep(false, request.advance) and APRData.player.beta == 4)
assert(not APR:AdvanceStep(false, request.advance), "A consumed receipt is stale after the writer advances")

-- Nil selections must reach the owner and retain the original optional reason.
local pending = { advance = APR:CaptureStepContext() }
APR.routeValidationPending = pending
function APR.event:OnRouteActivated(route, previous, reason)
    assert(route == nil and previous == "beta" and reason == nil and APR.ActiveRoute == nil)
    assert(pending.selectionChanged and pending.selectedRoute == nil)
    assert(not APR:IsStepContextCurrent(pending.advance))
    assert(APR:GetRecentTransitions()[1].reason == "route_changed")
end
assert(APR:ActivateRoute(nil))
assert(not APR:AdvanceStep(false) and APRData.player.beta == 4)

-- Background maintenance is not a writer barrier and ordinary progress must not
-- turn into manual reset intentions or invalidate its existing intentions.
fixture()
local maintenance = { player = APR.PlayerID, data = APRData.player,
    manualResets = { untouched = true }, manualClears = { beta = true } }
APR.event = { routeMaintenanceJob = maintenance }
assert(APR:AdvanceStep(false) and APRData.player.alpha == 3)
assert(APR:CommitManualSkip(4) and APR:CanUndoManualSkip())
assert(APR:UndoManualSkip() and APRData.player.alpha == 3)
assert(APR:SetRouteProgress("beta", 2, "initialization"))
assert(APR:SetRouteProgress("beta", 1, "definition_changed"))
assert(maintenance.manualResets.untouched and not maintenance.manualResets.alpha
    and not maintenance.manualResets.beta and maintenance.manualClears.beta,
    "Only an explicit reset may supersede the maintenance job's saved intentions")

-- Foreground and background jobs both retain explicit resets, including no-op
-- writes, while each receipt is retired only by a reset of its own route.
fixture()
local receipt = APR:CaptureStepContext()
local foreground = { advance = receipt, manualResets = { other = true },
    manualClears = { alpha = true, beta = true, other = true } }
maintenance = { player = APR.PlayerID, data = APRData.player, advance = receipt,
    manualClears = { alpha = true, beta = true, other = true } }
APR.routeValidationPending = foreground
APR.event = { routeMaintenanceJob = maintenance }
assert(APR:SetRouteProgress("beta", 1, "reset"))
assert(foreground.advance == receipt and maintenance.advance == receipt,
    "Resetting an inactive route cannot lose the current route's one-shot completion")
assert(foreground.manualResets.beta and maintenance.manualResets.beta)
assert(not foreground.manualClears.beta and not maintenance.manualClears.beta)
assert(foreground.manualResets.other and foreground.manualClears.other and maintenance.manualClears.other)
assert(APR:IsStepContextCurrent(receipt), "An inactive reset does not invalidate the active step")
assert(APR:SetRouteProgress("alpha", 1, "reset"))
assert(not foreground.advance and not maintenance.advance)
assert(foreground.manualResets.alpha and maintenance.manualResets.alpha)
assert(not foreground.manualClears.alpha and not maintenance.manualClears.alpha)
assert(not APR:IsStepContextCurrent(receipt))
foreground.manualResets.alpha, maintenance.manualResets.alpha = nil, nil
foreground.manualClears.alpha, maintenance.manualClears.alpha = true, true
local revision = APR.stepRevision
assert(not APR:SetRouteProgress("alpha", 1, "reset"))
assert(foreground.manualResets.alpha and maintenance.manualResets.alpha
    and not foreground.manualClears.alpha and not maintenance.manualClears.alpha)
assert(APR.stepRevision == revision, "A no-op reset signals intentions without fabricating a transition")

-- Suspended foreground validation retains the same reset/receipt contract.
APR.routeValidationPending = nil
APR.event.routeValidationResume = { advance = { route = "beta" } }
assert(not APR:SetRouteProgress("alpha", 1, "reset"))
assert(APR.event.routeValidationResume.manualResets.alpha
    and APR.event.routeValidationResume.advance.route == "beta")

-- Invalid writes and a stale maintenance snapshot cannot acquire intentions for
-- a different player or a replacement SavedVariables dictionary.
fixture()
maintenance = { player = APR.PlayerID, data = APRData.player }
APR.event = { routeMaintenanceJob = maintenance }
assert(not APR:SetRouteProgress("alpha", 0, "reset"))
assert(not APR:SetRouteProgress("alpha", 0 / 0, "reset"))
assert(not APR:SetRouteProgress("alpha", math.huge, "reset"))
assert(not APR:SetRouteProgress("alpha", 1.5, "reset"))
assert(not APR:SetRouteProgress(nil, 1, "reset"))
assert(not maintenance.manualResets)
maintenance.player = "previous_player"
assert(APR:SetRouteProgress("alpha", 1, "reset") and not maintenance.manualResets)
maintenance.player, maintenance.data = APR.PlayerID, {}
assert(APR:SetRouteProgress("beta", 1, "reset") and not maintenance.manualResets)

print("Startup activation: synchronous optional hook, contextual receipts and independent maintenance resets passed")
