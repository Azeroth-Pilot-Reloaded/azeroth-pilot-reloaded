-- Validation scopes use invented guides; history size must not delay one guide.
local noop = function() end
local nativePairs, nativeIpairs = pairs, ipairs
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
function tinsert(values, value) values[#values + 1] = value end
APR = { PlayerID = "player", version = "new", EXPANSIONS = { Test = "test" }, Debug = noop }
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
local resume = APRInstrumentation and APRInstrumentation.Resume or coroutine.resume
local yield = APRInstrumentation and APRInstrumentation.Yield or coroutine.yield
local state

function APR:GetRouteData(route) return self.RouteQuestStepList[route] end
function APR:GetRouteVisibility() return "visible" end
function APR:GetEnumKeyByValue() return "Test" end
function APR:GetRouteSignature(route, checkpoint)
    state.hashes[#state.hashes + 1] = route
    if state.failRoute == route then error("synthetic hash failure") end
    local definition = assert(self.RouteQuestStepList[route])
    for _ = 1, #definition.steps do
        state.cpu = state.cpu + 0.03
        if checkpoint then checkpoint() end
    end
    state.hashed = route
    if state.afterHash then state.afterHash(route) end
    return definition.signature
end
local function fixture()
    state = { hashes = {}, cpu = 0, popups = {}, refreshes = 0, invalidated = {} }
    APR.PlayerID, APR.ActiveRoute = "player", "swift"
    APR.routeValidationPending, APR.routeValidationFailed, APR._savedRouteClearRevision = nil, nil, nil
    APR.event, APR.stepRevision, APR.transitionHistory = {}, nil, nil
    APR.settings = { profile = { lastRecordedVersion = "old" } }
    APR.RouteQuestStepList = {
        swift = { label = "Swift", expansion = "test", steps = { {}, {}, {}, {} }, signature = "swift-current" },
        stored = { label = "Stored", expansion = "test", steps = { {}, {} }, signature = "stored-current" },
        spare = { label = "Spare", expansion = "test", steps = { {}, {}, {} }, signature = "spare-current" },
    }
    APRData = { player = { swift = 3, stored = 6, spare = 7,
        ["swift-RawTotalSteps"] = 4, ["stored-RawTotalSteps"] = 2, ["spare-RawTotalSteps"] = 3,
        ["swift-ParallelStepsState"] = { groups = { saved = true } },
        RouteSignatures = { swift = "swift-current", stored = "stored-old", spare = "spare-old" } } }
    APRCustomPath = { player = { "Swift", "Stored", "Spare" } }
    APRZoneCompleted = { player = { Stored = true, Spare = true } }
    APR.questionDialog = { CreateMessagePopup = function(_, message) state.popups[#state.popups + 1] = message end }
    APR.routeconfig = { SendMessage = function(_, message)
        assert(message == "APR_Custom_Path_Update")
        state.refreshes = state.refreshes + 1
    end }
    APR.InvalidateEffectiveRouteStepsCache = function(_, route) state.invalidated[route] = true end
end
local function checkpoint()
    state.cpu = state.cpu + 0.001
    yield()
end
local function finish(thread)
    local value, count = nil, 0
    repeat
        local ok
        ok, value = resume(thread)
        assert(ok, value)
        count = count + 1
        assert(count < 100000, "Synthetic validation must terminate")
    until coroutine.status(thread) == "dead"
    return value
end
local function pendingAfterHash(options, route)
    local thread = coroutine.create(function()
        return APR:CheckCurrentRouteUpToDate(route, checkpoint, options)
    end)
    repeat
        local ok, message = resume(thread)
        assert(ok, message)
        assert(coroutine.status(thread) ~= "dead", "Pause before publication")
    until state.hashed
    return thread
end

-- The urgent branch cannot enumerate any historical dictionary, resolve any
-- completed display name or call the hasher for an inactive guide.
fixture()
for index = 1, 6000 do
    local key = "history-" .. index
    APR.RouteQuestStepList[key] = { label = key, expansion = "test", steps = { {} }, signature = "fresh" }
    APRData.player[key], APRData.player[key .. "-RawTotalSteps"] = 9, 1
    APRData.player.RouteSignatures[key], APRZoneCompleted.player[key] = "old", true
    APRCustomPath.player[#APRCustomPath.player + 1] = key
end
local playerData, completed, paths = APRData.player, APRZoneCompleted.player, APRCustomPath.player
function pairs(values)
    assert(values ~= playerData and values ~= completed, "Current-only must not enumerate saved history")
    return nativePairs(values)
end
function ipairs(values)
    assert(values ~= paths, "An unchanged current route must not traverse custom-path history")
    return nativeIpairs(values)
end
local realResolver = APR.GetRouteMapIDsAndName
APR.GetRouteMapIDsAndName = function() error("Current-only must not resolve completed route labels") end

-- Zero-delay timers run on the following 60 FPS frame. Track the actual
-- publication/callback with its route/index, then its following paint. The
-- Event integration suite owns rendered job tokens; this tests the scoped work.
local frame, frameMs, queue, useful, paint = 0, 1000 / 60, {}, nil, nil
C_Timer = { NewTimer = function(delay, callback)
    assert(delay == 0)
    queue[#queue + 1] = { due = frame + 1, callback = callback }
end }
local thread = coroutine.create(function()
    return APR:CheckCurrentRouteUpToDate("swift", checkpoint, { currentOnly = true })
end)
local advance
advance = function()
    local started = state.cpu
    repeat
        local ok, valid = resume(thread)
        assert(ok, valid)
        if coroutine.status(thread) == "dead" then
            assert(valid and APRData.player.swift == 3 and APRData.player.RouteSignatures.swift == "swift-current")
            useful = { route = APR.ActiveRoute, index = APRData.player.swift,
                at = frame * frameMs + state.cpu - started, frame = frame }
            return
        end
    until state.cpu - started >= 2
    C_Timer.NewTimer(0, advance)
end
C_Timer.NewTimer(0, advance)
while not paint do
    frame = frame + 1
    local callbacks = queue
    queue = {}
    for _, timer in nativeIpairs(callbacks) do
        assert(timer.due == frame, "Timer zero cannot fire in its creation frame")
        timer.callback()
    end
    if useful and frame > useful.frame then paint = frame * frameMs end
    assert(frame < 100)
end
assert(useful.route == "swift" and useful.index == 3)
assert(useful.at < paint and paint <= 100, "The current guide must publish and paint within 100 ms")
assert(#state.hashes == 1 and state.hashes[1] == "swift" and state.cpu < 1)
assert(APRData.player.stored == 6 and APRData.player.RouteSignatures.stored == "stored-old"
    and APRData.player["history-6000"] == 9 and APRZoneCompleted.player["history-6000"])
assert(APRData.player["swift-ParallelStepsState"].groups.saved)
assert(APR.settings.profile.lastRecordedVersion == "old" and #state.popups == 0 and state.refreshes == 0)
pairs, ipairs, APR.GetRouteMapIDsAndName = nativePairs, nativeIpairs, realResolver

-- A changed current route resets only itself and leaves global maintenance due.
fixture()
APRData.player.RouteSignatures.swift = "swift-old"
assert(APR:CheckCurrentRouteUpToDate("swift", nil, { currentOnly = true }))
assert(APRData.player.swift == nil and APRData.player["swift-ParallelStepsState"] == nil)
assert(APRData.player["swift-RawTotalSteps"] == 4 and APRData.player.RouteSignatures.swift == "swift-current")
assert(APRData.player.stored == 6 and APRZoneCompleted.player.Stored and APRData.player.RouteSignatures.stored == "stored-old")
assert(APR.settings.profile.lastRecordedVersion == "old" and #state.popups == 1 and state.refreshes == 1)
assert(not state.popups[1]:find("Stored", 1, true), "Foreground notifications contain only its route")

-- A job that began hashing a route while inactive must leave every field alone
-- if that exact route becomes active before publication. Automatic play works.
fixture()
local request = {}
APR.event.routeMaintenanceJob = request
thread = pendingAfterHash({ background = true, intentions = request })
local selected = state.hashed
assert(selected ~= "swift")
local selectedLabel = APR:GetRouteDisplayName(selected)
local oldSignature = APRData.player.RouteSignatures[selected]
local oldRaw = APRData.player[selected .. "-RawTotalSteps"]
assert(APR:ActivateRoute(selected, "manual"))
local prior = APRData.player[selected]
assert(APR:AdvanceStep(false) and APRData.player[selected] == prior + 1,
    "Background maintenance must not lock current-route progress")
assert(finish(thread))
assert(APRData.player[selected] == prior + 1 and APRData.player.RouteSignatures[selected] == oldSignature
    and APRData.player[selected .. "-RawTotalSteps"] == oldRaw and APRZoneCompleted.player[selectedLabel])
assert(not state.invalidated[selected])
for _, message in ipairs(state.popups) do assert(not message:find(selectedLabel, 1, true)) end
assert(APRData.player.swift == 3 and APRData.player["swift-ParallelStepsState"].groups.saved)
assert(APR.settings.profile.lastRecordedVersion == "new" and not APR.routeValidationPending and not APR.routeValidationFailed)

-- An explicit exclusion added after hashing has the same publication protection.
fixture()
local excluded = {}
thread = pendingAfterHash({ background = true, excludeRoutes = excluded })
local excludedRoute = state.hashed
excluded[excludedRoute] = true
assert(finish(thread) and APRData.player[excludedRoute] ~= nil
    and APRData.player.RouteSignatures[excludedRoute] == excludedRoute .. "-old"
    and APRZoneCompleted.player[APR:GetRouteDisplayName(excludedRoute)])

-- Distinct keys can share a completion label; neither key may clear the live
-- label or report it reset. An existing exclusion also prevents hashing.
fixture()
APR.RouteQuestStepList.alias = { label = "Swift", expansion = "test", steps = { {} }, signature = "alias-new" }
APRData.player.alias, APRData.player["alias-RawTotalSteps"] = 8, 1
APRData.player.RouteSignatures.alias, APRZoneCompleted.player.Swift = "alias-old", true
assert(APR:CheckCurrentRouteUpToDate(nil, nil, { background = true, excludeRoutes = { stored = true } }))
assert(APRData.player.alias == 8 and APRData.player.RouteSignatures.alias == "alias-old" and APRZoneCompleted.player.Swift)
for _, route in ipairs(state.hashes) do assert(route == "spare") end
assert(APRData.player.stored == 6 and APRData.player.spare == nil)

-- The request passed explicitly owns its receipts. A foreground request must
-- neither override nor suppress a background cleanup of a different route.
fixture()
APR.routeValidationPending = { manualClears = { stored = true }, manualResets = { spare = true } }
request = { manualResets = { stored = true } }
assert(APR:CheckCurrentRouteUpToDate(nil, nil, { background = true, intentions = request }))
assert(APRData.player.stored == 6 and APRData.player.RouteSignatures.stored == "stored-current"
    and APRZoneCompleted.player.Stored and APRData.player.spare == nil and not APRZoneCompleted.player.Spare)

-- A manual clear reaches all live request owners and invalidates a suspended
-- snapshot. On retry its receipt prevents raw totals/signatures reappearing.
fixture()
request = { manualResets = { stored = true }, advance = { route = "swift" } }
local foreground = { manualResets = { stored = true }, advance = { route = "stored" } }
local suspended = { advance = { route = "stored" } }
APR.routeValidationPending = foreground
APR.event.routeMaintenanceJob, APR.event.routeValidationResume = request, suspended
thread = pendingAfterHash({ background = true, intentions = request })
APR:ClearSavedRouteData("stored")
for _, owner in ipairs({ foreground, suspended, request }) do
    assert(owner.manualClears.stored and not (owner.manualResets and owner.manualResets.stored))
end
assert(not foreground.advance and not suspended.advance and request.advance.route == "swift")
assert(finish(thread) == false and APR.settings.profile.lastRecordedVersion == "old")
assert(APR:CheckCurrentRouteUpToDate(nil, nil, { background = true, intentions = request }))
assert(APRData.player.stored == nil and APRData.player["stored-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures.stored == nil and APRZoneCompleted.player.Stored,
    "Maintenance must preserve an explicit clear, including its completion flag")

-- Error retry/disable pauses keep the same receipts even when there is no
-- running maintenance job. A new snapshot must not resurrect an explicit clear.
fixture()
request = { player = "player", data = APRData.player, advance = { route = "stored" } }
APR.event.routeMaintenanceResume = request
APR:ClearSavedRouteData("stored")
assert(request.manualClears.stored and not request.advance)
APR.event.routeMaintenanceResume, APR.event.routeMaintenanceJob = nil, request
assert(APR:CheckCurrentRouteUpToDate(nil, nil, { background = true, intentions = request }))
assert(APRData.player.stored == nil and APRData.player["stored-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures.stored == nil and APRZoneCompleted.player.Stored)

-- Owner retirement is independent of source identities. A stale request that
-- finishes hashing before noticing cancellation still has no right to publish.
fixture()
local current = true
request = { isCurrent = function() return current end }
thread = pendingAfterHash({ currentOnly = true, intentions = request }, "stored")
current = false
assert(finish(thread) == false and APRData.player.stored == 6
    and APRData.player.RouteSignatures.stored == "stored-old" and #state.popups == 0)
assert(APR.settings.profile.lastRecordedVersion == "old")

-- Cache invalidation can synchronously reenter a route owner. A direct clear
-- in that callback must remain cleared; activation must prevent later refreshes
-- of the newly played route's raw total/signature/completion.
fixture()
request = {}
APR.event.routeMaintenanceJob = request
local invalidating = false
APR.InvalidateEffectiveRouteStepsCache = function(_, route)
    if route == "stored" and not invalidating then
        invalidating = true
        APR:ClearSavedRouteData("stored")
    end
end
assert(APR:CheckCurrentRouteUpToDate("stored", nil, { currentOnly = true, intentions = request }) == false)
assert(APRData.player.stored == nil and APRData.player["stored-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures.stored == nil and APRZoneCompleted.player.Stored)
assert(request.manualClears.stored and #state.popups == 0 and state.refreshes == 0)

fixture()
APR.InvalidateEffectiveRouteStepsCache = function(_, route)
    if route == "stored" then
        assert(APR:ActivateRoute("stored", "manual"))
        APRData.player.stored = 1
    end
end
assert(APR:CheckCurrentRouteUpToDate(nil, nil, { background = true }))
assert(APRData.player.stored == 1 and APRData.player["stored-RawTotalSteps"] == nil
    and APRData.player.RouteSignatures.stored == nil and APRZoneCompleted.player.Stored)
for _, message in ipairs(state.popups) do assert(not message:find("Stored", 1, true)) end

-- Every source/container identity remains part of the transaction. Nothing
-- from a retired current-only snapshot may publish, including its version.
local replacements = {
    function() APR.PlayerID = "other" end,
    function() APRData.player = { swift = 17 } end,
    function() APRZoneCompleted.player = nil end,
    function() APRData.player.RouteSignatures = nil end,
    function() APR.RouteQuestStepList.swift = { steps = { {} } } end,
    function() APR.RouteQuestStepList.swift.steps = { {} } end,
    function() APR.RouteQuestStepList.swift.parallelSteps = { { steps = { {} } } } end,
    function() APR.RouteQuestStepList.swift.scenarios = { { steps = { {} } } } end,
}
for _, replace in ipairs(replacements) do
    fixture()
    local captured = APRData.player
    captured.RouteSignatures.swift = "swift-old"
    thread = pendingAfterHash({ currentOnly = true }, "swift")
    replace()
    assert(finish(thread) == false and captured.swift == 3 and #state.popups == 0 and state.refreshes == 0)
    assert(APR.settings.profile.lastRecordedVersion == "old")
end

-- A failing signature is atomic; retrying with the same request publishes once.
fixture()
state.failRoute = "spare"
request = { manualResets = { stored = true } }
local ok, message = pcall(APR.CheckCurrentRouteUpToDate, APR, nil, nil, { background = true, intentions = request })
assert(not ok and tostring(message):find("synthetic hash failure", 1, true))
assert(APRData.player.stored == 6 and APRData.player.spare == 7 and APRZoneCompleted.player.Spare
    and APRData.player.RouteSignatures.stored == "stored-old" and #state.popups == 0 and state.refreshes == 0)
assert(APR.settings.profile.lastRecordedVersion == "old")
state.failRoute = nil
assert(APR:CheckCurrentRouteUpToDate(nil, nil, { background = true, intentions = request }))
assert(APRData.player.stored == 6 and APRData.player.spare == nil and #state.popups == 1 and state.refreshes == 1)
assert(APR:CheckCurrentRouteUpToDate(nil, nil, { background = true, intentions = request }))
assert(#state.popups == 1 and state.refreshes == 1, "A second successful pass cannot repeat reset notifications")

-- The two-argument API still validates every tracked guide atomically, including
-- the active guide. The explicit current argument remains additive by default.
fixture()
APRData.player.RouteSignatures.swift = "swift-old"
assert(finish(coroutine.create(function() return APR:CheckCurrentRouteUpToDate("swift", checkpoint) end)))
assert(#state.hashes == 3 and APRData.player.swift == nil and APRData.player.stored == nil and APRData.player.spare == nil)
assert(not APRZoneCompleted.player.Stored and not APRZoneCompleted.player.Spare and #state.popups == 1)
assert(APR.settings.profile.lastRecordedVersion == "new" and state.refreshes == 1)

-- Reset receipts can arrive while the background worker is suspended. Use the
-- real progress writer so resetting an inactive guide never blocks live play.
fixture()
request = { player = "player", data = APRData.player }
APR.event.routeMaintenanceJob = request
thread = pendingAfterHash({ background = true, intentions = request })
assert(APR:SetRouteProgress("stored", 1, "reset"))
assert(request.manualResets and request.manualResets.stored, "The maintenance owner must receive manual resets")
assert(APR:AdvanceStep(false) and APRData.player.swift == 4)
assert(not request.manualResets.swift, "Automatic progress is not a manual reset receipt")
assert(finish(thread) and APRData.player.stored == 1 and APRData.player.RouteSignatures.stored == "stored-current"
    and APRZoneCompleted.player.Stored)
print("Startup validation scopes: bounded foreground, live-route isolation, receipts, atomic retirement and recovery passed")

-- Unknown initial quest state is distinct from an observed, legitimately empty
-- journal. Exercise the real renderer/cache/condition and parallel-group engine.
do
    dofile("tests/lua/addon_journey_quest_env.lua")
    local routeKey, prerequisite, pickup = "startup-conditions", 8401, 8402
    local function resetQuestRoute(conditions, groups)
        APR.ActiveRoute, APR.startupQuestStatePending = routeKey, true
        APR.routeValidationPending, APR.routeValidationFailed = nil, nil
        APRData.player[routeKey], APRData.player[routeKey .. "-SkippedStep"] = 1, 0
        APRData.player[routeKey .. "-ParallelStepsState"] = nil
        APR.RouteQuestStepList[routeKey] = { label = "Invented initial quest state", mapID = 10,
            steps = { { PickUp = { pickup }, IsQuestOnQuest = conditions and conditions.IsQuestOnQuest,
                AnyOf = conditions and conditions.AnyOf, AllOf = conditions and conditions.AllOf,
                Not = conditions and conditions.Not, Note = "Keep this instruction" },
                { PickUp = { 8403 }, Note = "Following instruction" }, { Note = "Final instruction" } },
            parallelSteps = groups }
        APR:InvalidateEffectiveRouteStepsCache(routeKey)
        H.quests, H.order, H.rewarded, APR.ActiveQuests, H.timers = {}, {}, {}, {}, {}
    end

    -- Every supported quest predicate, even under multiple nested operators,
    -- must remain unknown before consulting its native/cache implementation.
    local filters = {
        { IsQuestReadyForTurnIn = prerequisite }, { IsQuestOnQuest = prerequisite },
        { IsQuestNotOnQuest = prerequisite }, { IsQuestCompleted = prerequisite },
        { IsQuestUncompleted = prerequisite }, { IsOneOfQuestsCompleted = { prerequisite } },
        { IsOneOfQuestsUncompleted = { prerequisite } }, { IsOneOfQuestsCompletedOnAccount = { prerequisite } },
        { IsOneOfQuestsUncompletedOnAccount = { prerequisite } }, { IsQuestsCompleted = { prerequisite } },
        { IsQuestsUncompleted = { prerequisite } }, { IsQuestsCompletedOnAccount = { prerequisite } },
        { IsQuestsUncompletedOnAccount = { prerequisite } },
    }
    resetQuestRoute({ IsQuestOnQuest = prerequisite })
    local questReads, originalPredicates = 0, {}
    for _, name in ipairs({ "IsQuestReadyForTurnIn", "IsOneOfQuestsCompleted", "IsOneOfQuestsCompletedOnAccount",
        "IsQuestsCompleted", "IsQuestsCompletedOnAccount" }) do
        local original = APR[name]
        originalPredicates[name] = original
        APR[name] = function(...) questReads = questReads + 1; return original(...) end
    end
    local onQuest, flagged = C_QuestLog.IsOnQuest, C_QuestLog.IsQuestFlaggedCompleted
    C_QuestLog.IsOnQuest = function(...) questReads = questReads + 1; return onQuest(...) end
    C_QuestLog.IsQuestFlaggedCompleted = function(...) questReads = questReads + 1; return flagged(...) end
    for _, condition in ipairs(filters) do
        assert(APR:HasPendingStartupQuestConditions(condition))
        assert(not APR:AreConditionalFiltersMet(condition) and not APR:StepFilterQuestHandler(condition))
        assert(not APR:SkipStepCondition(condition))
        local nested = { Not = { AllOf = { { AnyOf = { { Faction = "Alliance" }, condition } } } } }
        assert(APR:HasPendingStartupQuestConditions(nested) and not APR:AreConditionalFiltersMet(nested))
        assert(not APR:SkipStepCondition(nested))
    end
    assert(questReads == 0, "Unknown condition trees must not read temporary native/cache quest values")
    C_QuestLog.IsOnQuest, C_QuestLog.IsQuestFlaggedCompleted = onQuest, flagged
    for name, original in pairs(originalPredicates) do APR[name] = original end
    assert(APRData.player[routeKey] == 1 and APRData.player[routeKey .. "-SkippedStep"] == 0)
    assert(APR:AreConditionalFiltersMet({ Faction = "Alliance" }) and not APR:HasPendingStartupQuestConditions({ PickUp = { pickup } }))
    assert(not APR:AreConditionalFiltersMet({ Faction = "Horde" }) and APR:StepFilterQuestHandler({ Faction = "Horde" }),
        "Known nonquest filters retain their ordinary behavior during startup")

    -- First content commit and following paint retain the real instruction;
    -- keeping this one step does not impose routeValidationPending on the guide.
    APR:UpdateStep()
    local committed = APR:CaptureStepContext()
    H.frame(1 / 60)
    local row = APR.currentStep.questsList.PickUp
    assert(row and row.font:GetText() == "Pick up" and row.detailFonts[1]:GetText():find("Quest " .. pickup, 1, true))
    assert(APR:IsStepContextCurrent(committed) and committed.route == routeKey and committed.index == 1)
    assert(APRData.player[routeKey] == 1 and APRData.player[routeKey .. "-SkippedStep"] == 0)
    assert(not APR.routeValidationPending and not APR.routeValidationFailed)

    -- A later native snapshot can make that same instruction applicable. This
    -- models the phase remaining unknown until observation, not a promise about
    -- arbitrary future server packets after a snapshot was already observed.
    H.frame(0.5 - 1 / 60)
    H.quest(prerequisite)
    APR:UpdateQuest(true)
    APR.startupQuestStatePending = nil
    APR:UpdateStep()
    assert(APR:AreConditionalFiltersMet({ IsQuestOnQuest = prerequisite }))
    assert(APRData.player[routeKey] == 1 and APR.ActiveQuests[prerequisite])
    assert(not APR:AreConditionalFiltersMet({ IsQuestNotOnQuest = prerequisite }))

    -- Negative and nested negative group conditions must not activate from an
    -- unknown log, while an unrelated group can activate immediately.
    resetQuestRoute(nil, {
        { conditions = { IsQuestNotOnQuest = prerequisite }, steps = { { PickUp = { 8411 } } } },
        { conditions = { Not = { AnyOf = { { IsQuestOnQuest = prerequisite } } } }, steps = { { PickUp = { 8412 } } } },
        { conditions = { AllOf = { { Not = { IsQuestCompleted = prerequisite } } } }, steps = { { PickUp = { 8413 } } } },
        { conditions = { Faction = "Alliance" }, steps = { { PickUp = { 8414 } } } },
    })
    APR:GetRouteSteps(routeKey)
    local parallel = assert(APRData.player[routeKey .. "-ParallelStepsState"])
    assert(not parallel.groups[1] and not parallel.groups[2] and not parallel.groups[3] and parallel.groups[4])
    assert(APRData.player[routeKey] == 1 and not APR.routeValidationPending)
    APR:UpdateQuest(true) -- zero entries is an observed snapshot too
    APR.startupQuestStatePending = nil
    APR:GetRouteSteps(routeKey)
    assert(parallel.groups[1] and parallel.groups[2] and parallel.groups[3] and parallel.activationSequence == 4)

    -- Manual next/previous must stop at an unknown quest-conditioned step,
    -- rather than silently crossing it while searching for the next visible one.
    resetQuestRoute(nil)
    APR.RouteQuestStepList[routeKey].steps[2].IsQuestOnQuest = prerequisite
    APR:SkipQuestStep()
    assert(APRData.player[routeKey] == 2)
    APR.manualSkipUndo = nil
    assert(APR:SetRouteProgress(routeKey, 3, "manual"))
    APR:PreviousQuestStep()
    assert(APRData.player[routeKey] == 2)

    -- Once the phase is known, an empty journal is sufficient to decide a
    -- positive condition is false and skip it exactly once. No positive count
    -- or synthetic synchronization delay is required.
    resetQuestRoute({ IsQuestOnQuest = prerequisite })
    local reads = H.questReads
    APR:UpdateQuest(true)
    assert(H.questReads == reads + 1 and #H.order == 0)
    APR.startupQuestStatePending = nil
    APR:UpdateStep()
    assert(APRData.player[routeKey] == 2 and APRData.player[routeKey .. "-SkippedStep"] == 1)
    assert(APR:AreConditionalFiltersMet({ IsQuestNotOnQuest = prerequisite }))
end
print("Startup quest conditions: unknown snapshots preserve rendered steps and manual stops; ready empty logs restore decisions")

do
    -- The real native observer releases only after a phase and an explicit
    -- cache read. Its native frame needs the ordinary UnregisterEvent contract.
    local prerequisite, pickup, routeKey = 8501, 8502, "native-startup-quest-phase"
    local function nativeFixture(loggedIn, seed)
        local realLoad = dofile
        IsLoggedIn = function() return loggedIn end
        dofile = function(path)
            if path ~= "APR-Core/core/Event.lua" then return realLoad(path) end
            if seed then H.quest(prerequisite) end
            local create = CreateFrame
            CreateFrame = function(...)
                local frame = create(...)
                frame.UnregisterEvent = function(self, event) self.events[event] = nil end
                return frame
            end
            local ok, value = pcall(realLoad, path)
            CreateFrame = create
            if not ok then error(value, 0) end
            return value
        end
        local ok, value = pcall(realLoad, "tests/lua/addon_journey_quest_env.lua")
        dofile = realLoad
        if not ok then error(value, 0) end
        APR.ActiveRoute = routeKey
        APR.RouteQuestStepList[routeKey] = { label = "Invented native startup phase", mapID = 10,
            steps = { { IsQuestOnQuest = prerequisite, PickUp = { pickup } }, { PickUp = { 8503 } } } }
        APRData.player[routeKey], APRData.player[routeKey .. "-SkippedStep"] = 1, 0
        APR:InvalidateEffectiveRouteStepsCache(routeKey)
        local observer = assert(APR.event.startupQuestStateFrame)
        assert(not APR.startupQuestStatePending and not APR.event.startupQuestStateStarted and H.questReads == 0,
            "Importing Event handlers alone must not arm startup or read a quest snapshot")
        -- Route validation/history scheduling is exercised above and in the
        -- login latency suite. Keep it from replacing this fixture's current
        -- route when the real ADDON_LOADED bootstrap runs on the next frame.
        APR.event.ValidateStartupRoutes = function() return false end
        assert(observer.events.ADDON_LOADED)
        observer.scripts.OnEvent(observer, "ADDON_LOADED", "APR")
        assert(APR.event.startupQuestStateStarted, "Only APR's real bootstrap arms the native snapshot observer")
        return observer
    end
    local function nativeEvent(frame, event)
        assert(frame.events[event], "The native startup event must actually be registered")
        frame.scripts.OnEvent(frame, event)
        assert(#H.errors == 0, table.concat(H.errors, "\n"))
    end

    local observer = nativeFixture(false)
    assert(APR.startupQuestStatePending and #H.order == 0)
    APR:UpdateStep()
    local context = APR.lastRenderedStepContext
    H.frame(1 / 60)
    assert(context and context.index == 1 and APR:IsStepContextCurrent(context) and APRData.player[routeKey] == 1)
    assert(APR.currentStep.questsList.PickUp.detailFonts[1]:GetText():find("Quest " .. pickup, 1, true))
    H.frame(0.5 - 1 / 60)
    assert(APR.startupQuestStatePending and APRData.player[routeKey] == 1,
        "Passing a timer deadline alone cannot certify an unobserved quest phase")
    H.quest(prerequisite)
    nativeEvent(observer, "QUEST_LOG_UPDATE")
    assert(not APR.startupQuestStatePending and APR.ActiveQuests[prerequisite] and APRData.player[routeKey] == 1)
    assert(not observer.events.PLAYER_LOGIN and not observer.events.QUEST_LOG_UPDATE)

    -- A legitimately empty native PLAYER_LOGIN snapshot is complete; it need
    -- not wait for a positive count or another QUEST_LOG_UPDATE to render.
    observer = nativeFixture(false)
    APR:UpdateStep()
    local reads = H.questReads
    nativeEvent(observer, "PLAYER_LOGIN")
    assert(not APR.startupQuestStatePending and #H.order == 0 and H.questReads > reads)
    assert(APRData.player[routeKey] == 2 and APRData.player[routeKey .. "-SkippedStep"] == 1)

    -- Demand-loaded/reloaded code can miss PLAYER_LOGIN. IsLoggedIn must cause
    -- an explicit read of both empty and nonempty journals without a new event.
    for _, seeded in ipairs({ false, true }) do
        observer = nativeFixture(true, seeded)
        assert(not APR.startupQuestStatePending and H.questReads > 0,
            "The already-observed native login phase still requires a snapshot read")
        APR:UpdateStep()
        assert(APRData.player[routeKey] == (seeded and 1 or 2))
        assert((APR.ActiveQuests[prerequisite] ~= nil) == seeded)
        assert(not observer.events.PLAYER_LOGIN and not observer.events.QUEST_LOG_UPDATE)
    end
    IsLoggedIn = nil
end
print("Startup native quest phases: delayed/vacant snapshots and already-passed login events synchronize explicitly")

-- These consumers bypass the common predicate or treat a false result as an
-- observed false condition. Keep their integration requirements visible to
-- their production-file owners instead of masking unknown as true eligibility.
do
    dofile("tests/lua/addon_journey_quest_env.lua")
    local routeKey, issues = "startup-repeatable-group", {}
    APR.ActiveRoute, APR.startupQuestStatePending = routeKey, true
    APR.RouteQuestStepList[routeKey] = { label = "Invented repeatable startup group", mapID = 10,
        steps = { { Note = "First" }, { Note = "Second" }, { Note = "Third" } },
        parallelSteps = { { repeatable = true, conditions = { Not = { IsQuestCompleted = 8601 } },
            steps = { { UseItem = { itemID = 8602 } } } } } }
    local entry = { activationOrder = 1, effectiveBeforeIndex = 2 }
    local saved = { groups = { entry }, activationSequence = 1 }
    APRData.player[routeKey], APRData.player[routeKey .. "-ParallelStepsState"] = 3, saved
    APR:GetRouteSteps(routeKey)
    if entry.rearm then issues[#issues + 1] = "RouteManager must not rearm a repeatable group from unknown quest state" end
    APR.startupQuestStatePending = nil
    APR:GetRouteSteps(routeKey)
    if saved.activationSequence ~= 1 then
        issues[#issues + 1] = "Observing startup readiness must not duplicate an already active repeatable group"
    end

    APR.startupQuestStatePending = true
    if APR:EvaluateRouteConditions({ IsQuestUncompleted = 8601 }) then
        issues[#issues + 1] = "RouteManager hard quest conditions must preserve startup uncertainty"
    end

    dofile("APR-Core/features/questing/RouteActions.lua")
    H.quest(8603)
    local abandoned = 0
    APR.LeaveQuest = function() abandoned = abandoned + 1 end
    APR:HandleRouteAction({ LeaveQuest = 8603, IsQuestOnQuest = 8604 })
    if abandoned ~= 0 then
        issues[#issues + 1] = "RouteActions must not execute a quest-conditioned abandon from unknown startup state"
    end
    assert(#issues == 0, table.concat(issues, "\n"))
end
