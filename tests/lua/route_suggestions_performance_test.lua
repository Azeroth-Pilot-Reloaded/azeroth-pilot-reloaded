local nativeTonumber = tonumber
local function fixture()
    local state = { timers = {}, reads = 0, numericReads = 0, clock = 0, cost = 0, popups = {}, errors = {} }
    function tonumber(value, ...)
        if value == "invalid-id" then
            state.numericReads, state.clock = state.numericReads + 1, state.clock + state.cost
        end
        return nativeTonumber(value, ...)
    end
    function LibStub() return { GetLocale = function() return {} end } end
    function debugprofilestop() return state.clock end
    function geterrorhandler() return function(message) state.errors[#state.errors + 1] = message end end
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        state.timers[#state.timers + 1] = timer
        return timer
    end }
    APR = { PlayerID = "player", RouteQuestStepList = {}, questionDialog = {} }
    APRData, APRCustomPath = { player = {} }, { player = {} }
    function APR:GetRouteData(key)
        state.routeReads = (state.routeReads or 0) + 1
        if state.fail or state.routeReads == state.failAt then
            state.fail = false; error("Synthetic data not ready")
        end
        local route = self.RouteQuestStepList[key]
        return route and not route.incompatible and route or nil
    end
    function APR:IsDelveRoute(key) return key == "delve" end
    function APR:GetSettingsProfile() return { enableAddon = state.enabled ~= false } end
    function APR:GetRouteSuggestionDontAsk() return state.dontAsk end
    function APR.questionDialog:CreateRouteTriggerPopup(_, routes)
        state.popups[#state.popups + 1] = routes
    end
    function state:EmptyStep()
        return setmetatable({}, { __index = function(_, key)
            if key == "PickUp" or key == "Done" then
                self.reads, self.clock = self.reads + 1, self.clock + self.cost
            end
        end })
    end
    function state:Tick()
        local timer = table.remove(self.timers, 1)
        assert(timer, "Index construction must retain one scheduled continuation")
        if not timer.cancelled then timer.callback() end
        return timer
    end
    function state:Drain()
        local count = 0
        while #self.timers > 0 do
            count = count + 1; assert(count < 2000, "Index construction must terminate")
            self:Tick()
        end
        assert(not APR._routeTriggerBuild)
    end
    dofile("APR-Core/features/questing/RouteSuggestions.lua")
    return state
end

local state = fixture()
local longSteps = {}
for index = 1, 3000 do longSteps[index] = state:EmptyStep() end
APR.RouteQuestStepList = {
    large = { label = "Invented long guide", steps = longSteps },
    alpha = { label = "Invented alpha", steps = {
        { PickUp = { 7 } }, { PickUp = { 11 }, Done = { 21, 22 } }, { Done = { 23 } } } },
    zeta = { label = "Invented zeta", steps = {
        { PickUp = { 11, 11, "12", 1 }, Done = { 31 } },
        { PickUp = { 13, 14, 15, 16, 17 }, Done = { 32 } } } },
    hidden = { label = "Hidden", hiddenFromSelection = true, steps = { { PickUp = { 11 } } } },
    temporary = { label = "Temporary", temporary = true, steps = { { PickUp = { 11 } } } },
    delve = { label = "Delve", steps = { { PickUp = { 11 } } } },
    otherClient = { label = "Other client", incompatible = true, steps = { { PickUp = { 11 } } } },
}
APRData.player["alpha-SkippedStep"] = 1
APR:InitRouteTriggersSuggestion()
assert(state.reads == 0 and #state.timers == 1,
    "Initialization schedules indexing without reading the authored step catalogue")
for _ = 1, 100 do APR:HandleTemporaryRouteTriggerQuestAccepted(11) end
APR:HandleTemporaryRouteTriggerQuestAccepted(1)
APR:HandleTemporaryRouteTriggerQuestAccepted("invalid")
assert(#state.popups == 0, "Partial indexes cannot emit incomplete suggestions")
local slices = 0
while #state.timers > 0 do
    local before = state.reads
    state:Tick()
    assert(state.reads - before <= 64, "One callback performs bounded step-field work")
    slices = slices + 1
end
assert(slices > 1 and state.reads == 6000 and not APR._routeTriggerBuild)
local triggers = APR.RouteTriggersSuggestion.routes
assert(table.concat(triggers.alpha.triggers, ",") == "11,21,22,23",
    "Skipped steps are excluded and hand-ins follow the available pickups")
assert(table.concat(triggers.zeta.triggers, ",") == "11,12,13,14,15,16",
    "Six distinct pickups take priority over every fallback hand-in")
assert(not triggers.hidden and not triggers.temporary and not triggers.delve and not triggers.otherClient)
assert(#state.popups == 1 and #state.popups[1] == 2
    and state.popups[1][1].key == "alpha" and state.popups[1][2].key == "zeta",
    "Queued bursts replay once with complete, deterministic route choices")
APR:HandleTemporaryRouteTriggerQuestAccepted(7)
assert(#state.popups == 1, "A skipped pickup cannot become a trigger")

state = fixture()
state.cost = 0.25
longSteps = {}
for index = 1, 100 do longSteps[index] = state:EmptyStep() end
APR.RouteQuestStepList.test = { label = "Time budget", steps = longSteps }
APR:InitRouteTriggersSuggestion()
while #state.timers > 0 do
    local before = state.reads
    state:Tick()
    assert(state.reads - before <= 4, "The elapsed 1 ms budget can stop before the operation limit")
end
assert(state.reads == 200)

state = fixture()
local invalidIDs = {}
for index = 1, 1000 do invalidIDs[index] = "invalid-id" end
APR.RouteQuestStepList.test = { label = "Large single step", steps = { { PickUp = invalidIDs, Done = { 61 } } } }
APR:InitRouteTriggersSuggestion()
while #state.timers > 0 do
    local before = state.numericReads
    state:Tick()
    assert(state.numericReads - before <= 64, "One oversized quest field must yield between its entries")
end
assert(state.numericReads == 1000 and APR.RouteTriggersSuggestion.routes.test.triggers[1] == 61,
    "Invalid candidate IDs cannot prevent the later valid hand-in fallback")

state = fixture()
APR.RouteQuestStepList.test = { label = "Restart", steps = { { PickUp = { 41 } } } }
APR:InitRouteTriggersSuggestion()
APR:HandleTemporaryRouteTriggerQuestAccepted(41)
local stale = state.timers[1]
APR:InitRouteTriggersSuggestion()
assert(stale.cancelled)
local before = #state.timers
stale.callback()
assert(#state.timers == before and #state.popups == 0, "A cancelled generation cannot resume or schedule work")
state:Drain()
assert(#state.popups == 1, "Reinitializing preserves a quest received during construction")

APR:InitRouteTriggersSuggestion()
APR:HandleTemporaryRouteTriggerQuestAccepted(41)
state.dontAsk = true
state:Drain()
assert(#state.popups == 1, "Replay observes preferences changed after the quest event")
state.dontAsk = false
APR:InitRouteTriggersSuggestion()
APR:HandleTemporaryRouteTriggerQuestAccepted(41)
state.enabled = false
state:Drain()
assert(#state.popups == 1, "Disabling the addon before replay suppresses pending suggestions")
state.enabled = true
APR:InitRouteTriggersSuggestion()
APR:HandleTemporaryRouteTriggerQuestAccepted(41)
APR.ActiveRoute, APRCustomPath.player = "active", { "An already selected route" }
state:Drain()
assert(#state.popups == 1, "Replay cannot suggest another route after the user starts one")
APR.ActiveRoute, APRCustomPath.player = nil, {}

state.fail = true
APR:InitRouteTriggersSuggestion()
state:Drain()
assert(#state.errors == 1, "An index failure stops its continuation and reports the actual error")
APR:InitRouteTriggersSuggestion()
state:Drain()
APR:HandleTemporaryRouteTriggerQuestAccepted(41)
assert(#state.popups == 2, "A subsequent initialization recovers from a failed build")

state = fixture()
APR.RouteQuestStepList.first = { label = "First", steps = { { PickUp = { 81 } } } }
APR.RouteQuestStepList.second = { label = "Second", steps = { { PickUp = { 82 } } } }
state.failAt = 2
APR:InitRouteTriggersSuggestion()
state:Drain()
assert(#state.errors == 1 and not next(APR.RouteTriggersSuggestion.routes)
    and not next(APR.RouteTriggersSuggestion.byQuestID),
    "A failure after registering one route discards the incomplete index")
APR:HandleTemporaryRouteTriggerQuestAccepted(81)
APR:HandleTemporaryRouteTriggerQuestAccepted(82)
assert(#state.popups == 0, "A failed generation cannot expose partial choices")
print("Route suggestions: bounded startup work, pickup priority, complete replay, cancellation and recovery passed")
