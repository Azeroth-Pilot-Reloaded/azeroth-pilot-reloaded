-- Native quest synchronization must not invent activation/rearm edges or
-- permanently omit a prerequisite. Every declaration here is synthetic.
local locale = setmetatable({}, { __index = function(_, key) return key end })
function LibStub() return { GetLocale = function() return locale end } end
tinsert, tremove = table.insert, table.remove
function tContains(values, wanted)
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end
function wipe(values) for key in pairs(values) do values[key] = nil end end

local state
local function fixture()
    state = { active = {}, complete = {}, account = {}, ready = {}, reads = 0 }
    C_QuestLog = {
        IsOnQuest = function(id) state.reads = state.reads + 1; return state.active[id] == true end,
        IsQuestFlaggedCompleted = function(id) state.reads = state.reads + 1; return state.complete[id] == true end,
        IsQuestFlaggedCompletedOnAccount = function(id) state.reads = state.reads + 1; return state.account[id] == true end,
    }
    APR = { PlayerID = "player", Faction = "Horde", Race = "Orc", RaceID = 2,
        ClassName = "WARRIOR", ClassId = 1, Level = 30, RouteQuestStepList = {} }
    APRData, APRCustomPath, APRZoneCompleted = { player = {} }, { player = {} }, { player = {} }
    dofile("APR-Core/data/models/Enums.lua")
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/utils/QuestUtils.lua")
    dofile("APR-Core/utils/RouteConditions.lua")
    dofile("APR-Core/utils/RouteUtils.lua")
    dofile("APR-Core/features/questing/RouteManager.lua")
    function APR:GetGameVersion() return self.GAME_VERSIONS.Retail end
    function APR:GetPlayerEffectiveLevel() return self.Level end
    function APR:IsDelveRoute() return false end
    function APR:IsQuestReadyForTurnIn(ids)
        state.reads = state.reads + 1
        if type(ids) == "number" then return state.ready[ids] == true end
        for _, id in ipairs(ids) do if not state.ready[id] then return false end end
        return true
    end
end
local function route(key, conditions, required)
    local value = { label = "Invented " .. key, expansion = APR.EXPANSIONS.Custom,
        conditions = conditions, requiredRoute = required,
        steps = { { Note = "First" }, { Note = "Second" }, { Note = "Third" } } }
    APR.RouteQuestStepList[key] = value
    return value
end
local function parallel(conditions, repeatable)
    local value = route("parallel")
    value.parallelSteps = { { conditions = conditions, repeatable = repeatable,
        steps = { { UseItem = { itemID = 4102 } } } } }
    APR.ActiveRoute, APRData.player.parallel = "parallel", 1
    return value
end
local function savedState()
    return APRData.player["parallel-ParallelStepsState"]
end

-- All quest predicate families defer activation, including negative predicates
-- that would otherwise pass against a temporarily vacant native snapshot.
local cases = {
    { "IsQuestReadyForTurnIn", { 4101 }, "ready", true },
    { "IsQuestOnQuest", 4101, "active", true },
    { "IsQuestNotOnQuest", 4101, "active", false },
    { "IsQuestCompleted", 4101, "complete", true },
    { "IsQuestUncompleted", 4101, "complete", false },
    { "IsOneOfQuestsCompleted", { 4101 }, "complete", true },
    { "IsOneOfQuestsUncompleted", { 4101 }, "complete", false },
    { "IsOneOfQuestsCompletedOnAccount", { 4101 }, "account", true },
    { "IsOneOfQuestsUncompletedOnAccount", { 4101 }, "account", false },
    { "IsQuestsCompleted", { 4101 }, "complete", true },
    { "IsQuestsUncompleted", { 4101 }, "complete", false },
    { "IsQuestsCompletedOnAccount", { 4101 }, "account", true },
    { "IsQuestsUncompletedOnAccount", { 4101 }, "account", false },
}
for _, case in ipairs(cases) do
    fixture()
    local value = parallel({ [case[1]] = case[2] })
    state[case[3]][4101] = case[4]
    APR.startupQuestStatePending = true
    for _ = 1, 4 do
        assert(APR:GetRouteSteps("parallel") == value.steps, case[1] .. " must retain the main route")
    end
    assert(savedState().groups[1] == nil and savedState().activationSequence == 0)
    assert(state.reads == 0, case[1] .. " cannot consult an unknown native snapshot")
    APR.startupQuestStatePending = nil
    assert(#APR:GetRouteSteps("parallel") == 4 and savedState().activationSequence == 1)
    assert(#APR:GetRouteSteps("parallel") == 4 and savedState().activationSequence == 1,
        case[1] .. " must activate once when the matching snapshot becomes ready")
end

-- A matching static AnyOf arm cannot bypass an unknown quest sibling. Static
-- groups in the same route still activate and do not block the main steps.
for _, conditions in ipairs({
    { Not = { IsQuestCompleted = 4101 } },
    { AnyOf = { { Faction = "Horde" }, { IsQuestCompleted = 4101 } } },
    { AllOf = { { Faction = "Horde" }, { Not = { IsQuestCompleted = 4101 } } } },
    { Not = { AnyOf = { { IsQuestCompleted = 4101 }, { Faction = "Alliance" } } } },
}) do
    fixture()
    local value = parallel(conditions)
    value.parallelSteps[2] = { conditions = { Faction = "Horde" }, steps = { { Note = "Static group" } } }
    APR.startupQuestStatePending = true
    local steps = APR:GetRouteSteps("parallel")
    assert(#steps == 4 and steps[1] == value.parallelSteps[2].steps[1] and steps[2] == value.steps[1])
    assert(savedState().groups[1] == nil and savedState().groups[2].activationOrder == 1 and state.reads == 0)
    APR.startupQuestStatePending = nil
    assert(#APR:GetRouteSteps("parallel") == 5 and savedState().groups[1].activationOrder == 2)
    assert(savedState().activationSequence == 2)
end

-- Saved repeatable activations preserve both absent and explicit false rearm
-- values while unknown. Readiness itself is not a new false->true edge.
for _, initialRearm in ipairs({ "absent", false }) do
    fixture()
    parallel({ Not = { IsQuestCompleted = 4101 } }, true)
    local entry = { activationOrder = 1, effectiveBeforeIndex = 2 }
    if initialRearm ~= "absent" then entry.rearm = initialRearm end
    local previousRearm = entry.rearm
    local saved = { groups = { entry }, activationSequence = 1 }
    APRData.player["parallel-ParallelStepsState"], APRData.player.parallel = saved, 3
    APR.startupQuestStatePending = true
    for _ = 1, 5 do assert(#APR:GetRouteSteps("parallel") == 4) end
    assert(entry.rearm == previousRearm and entry.activations == nil and saved.activationSequence == 1,
        "An unknown predicate cannot mutate the saved repeatable edge")
    APR.startupQuestStatePending = nil
    assert(#APR:GetRouteSteps("parallel") == 4 and saved.activationSequence == 1 and entry.activations == nil)

    state.complete[4101] = true
    assert(#APR:GetRouteSteps("parallel") == 4 and entry.rearm == true,
        "An observed false predicate rearms the completed activation")
    state.complete[4101] = false
    assert(#APR:GetRouteSteps("parallel") == 5 and saved.activationSequence == 2)
    assert(#entry.activations == 2 and entry.activations[2].activationOrder == 2 and entry.rearm == false)
    for _ = 1, 5 do assert(#APR:GetRouteSteps("parallel") == 5) end
    assert(saved.activationSequence == 2, "One real false->true edge creates exactly one new activation")
end

-- A previously observed rearm survives startup, but may insert only after the
-- old activation is behind the cursor, including when readiness comes first.
fixture()
parallel({ IsQuestUncompleted = 4101 }, true)
local entry = { activationOrder = 1, effectiveBeforeIndex = 2, rearm = true }
local saved = { groups = { entry }, activationSequence = 1 }
APRData.player["parallel-ParallelStepsState"], APRData.player.parallel = saved, 2
APR.startupQuestStatePending = true
assert(#APR:GetRouteSteps("parallel") == 4 and entry.rearm == true and entry.activations == nil)
APR.startupQuestStatePending = nil
assert(#APR:GetRouteSteps("parallel") == 4 and saved.activationSequence == 1 and entry.rearm == true)
APRData.player.parallel = 3
assert(#APR:GetRouteSteps("parallel") == 5 and saved.activationSequence == 2 and entry.rearm == false)
assert(#APR:GetRouteSteps("parallel") == 5 and saved.activationSequence == 2)

-- Route hard filters and completed Forever prerequisites use the same startup
-- guard, while ordinary compatibility/level decisions remain available.
fixture()
route("static", { Faction = "Horde", Level = 30 })
route("foreign", { Faction = "Alliance" })
route("negative", { IsQuestUncompleted = 4101 })
route("positive", { IsQuestCompleted = 4101 })
route("reward", { IsQuestReadyForTurnIn = 4101 })
route("nested", { AnyOf = { { Faction = "Horde" },
    { AllOf = { { Not = { IsQuestCompleted = 4101 } } } } } })
local target = route("forever", nil, { "negative", "positive" })
target.gameVersion = APR.GAME_VERSIONS.Forever
function APR:GetGameVersion() return self.GAME_VERSIONS.Forever end
APRZoneCompleted.player["Invented negative"], APRZoneCompleted.player["Invented positive"] = true, true
APR.startupQuestStatePending = true
assert(APR:GetRouteVisibility("static") == "visible" and APR:GetRouteVisibility("foreign") == "hidden")
for _, key in ipairs({ "negative", "positive", "reward", "nested" }) do
    local data = APR:GetRouteData(key)
    assert(not APR:EvaluateRouteConditions(data.conditions) and APR:GetRouteVisibility(key) == "hidden")
    assert(APR:GetRouteSteps(key) == data.steps, "Unknown hard eligibility does not hide the active step array")
end
assert(not APR:MeetsRoutePrerequisites("forever") and not APR:CanStartRoute("forever"))
assert(state.reads == 0, "Direct hard quest predicates cannot bypass the common startup guard")
APR.startupQuestStatePending = nil
assert(APR:EvaluateRouteConditions({ IsQuestUncompleted = 4101 }))
assert(not APR:EvaluateRouteConditions({ IsQuestCompleted = 4101 }))
assert(APR:MeetsRoutePrerequisites("forever") and APR:CanStartRoute("forever"))
state.complete[4101], state.ready[4101] = true, true
assert(not APR:EvaluateRouteConditions({ IsQuestUncompleted = 4101 }))
assert(APR:EvaluateRouteConditions({ IsQuestCompleted = 4101 }))
assert(APR:EvaluateRouteConditions({ IsQuestReadyForTurnIn = 4101 }))
assert(APR:EvaluateRouteConditions(APR.RouteQuestStepList.nested.conditions))
assert(APR:MeetsRoutePrerequisites("forever"), "A completed compatible positive predecessor also satisfies the gate")

-- Staging preserves a path when an unknown prerequisite is encountered after
-- an eligible sibling; a retry uses the actual observed condition either way.
for _, completed in ipairs({ false, true }) do
    fixture()
    route("known", { Faction = "Horde" })
    route("uncertain", { IsQuestUncompleted = 4101 })
    route("requested", nil, { "known", "uncertain" })
    APRCustomPath.player = { "Existing" }
    local path = APRCustomPath.player
    APR.startupQuestStatePending = true
    assert(not APR:IsRequiredRouteApplicable("uncertain"))
    assert(not APR:AddRouteToCustomPathByKey("uncertain"), "An unknown target cannot be enqueued as eligible")
    assert(not APR:AddRouteToCustomPathByKey("requested"))
    assert(APRCustomPath.player == path and #path == 1 and path[1] == "Existing",
        "An unknown prerequisite cannot commit a partially evaluated selection")
    state.complete[4101] = completed
    APR.startupQuestStatePending = nil
    assert(APR:AddRouteToCustomPathByKey("requested"))
    local expected = completed and "Existing,Invented known,Invented requested"
        or "Existing,Invented known,Invented uncertain,Invented requested"
    assert(table.concat(path, ",") == expected)
    assert(not APR:AddRouteToCustomPathByKey("requested") and table.concat(path, ",") == expected)
end

-- Static shared prerequisites still expand once per declaration at startup;
-- staged labels deduplicate across branches before a single publication.
fixture()
route("leaf")
route("left", nil, { "leaf" })
route("right", nil, { "leaf" })
route("root", nil, { "left", "right" })
APR.startupQuestStatePending = true
local realRequired, visits = APR.GetRouteRequiredRouteKeys, {}
function APR:GetRouteRequiredRouteKeys(key)
    visits[key] = (visits[key] or 0) + 1
    return realRequired(self, key)
end
assert(APR:AddRouteToCustomPathByKey("root"))
assert(table.concat(APRCustomPath.player, ",") == "Invented leaf,Invented left,Invented right,Invented root")
assert(visits.leaf == 1 and visits.left == 1 and visits.right == 1 and visits.root == 1)

-- A later sibling can reenter selection after earlier labels were staged.
-- Publication rechecks the actual path and never duplicates those labels.
fixture()
route("leaf")
route("left", nil, { "leaf" })
route("right")
route("root", nil, { "left", "right" })
APR.startupQuestStatePending = true
local realData, reentered = APR.GetRouteData, false
function APR:GetRouteData(key)
    if key == "right" and not reentered then
        reentered = true
        assert(self:AddRouteToCustomPathByKey("left"))
    end
    return realData(self, key)
end
assert(APR:AddRouteToCustomPathByKey("root") and reentered)
assert(table.concat(APRCustomPath.player, ",") == "Invented leaf,Invented left,Invented right,Invented root")

-- A prerequisite callback can change the parent's label after its initial
-- guard. Preserve table.insert(nil)'s no-op and addedAny behavior, including
-- when the prerequisite was already queued and adds no label of its own.
for _, pending in ipairs({ false, true }) do
    for _, alreadyQueued in ipairs({ false, true }) do
        for _, mutation in ipairs({ {}, { label = "Renamed parent" }, { label = false } }) do
            fixture()
            local requested = route("requested", nil, { "required" })
            route("required")
            APRCustomPath.player = alreadyQueued and { "Invented required" } or {}
            local path, realApplicable, mutated = APRCustomPath.player, APR.IsRequiredRouteApplicable, false
            APR.startupQuestStatePending = pending and true or nil
            function APR:IsRequiredRouteApplicable(key)
                if key == "required" then
                    requested.label, mutated = mutation.label, true
                end
                return realApplicable(self, key)
            end
            assert(APR:AddRouteToCustomPathByKey("requested") and mutated,
                "A removed label retains the historical addedAny result even if the path was already populated")
            assert(APRCustomPath.player == path and path[1] == "Invented required")
            if mutation.label == nil then
                assert(#path == 1 and path[2] == nil,
                    "A callback removing the parent label publishes the prerequisite alone")
            else
                assert(#path == 2 and path[2] == mutation.label and path[3] == nil,
                    "A changed label uses the value observed after the prerequisite callback")
            end
            assert(not APR:AddRouteToCustomPathByKey("requested"),
                "A later call observes the changed declaration without inserting duplicates")
        end
    end
end

-- Consumers that load RouteManager without RouteUtils retain the established
-- behavior: the optional helper is never required merely because a marker exists.
fixture()
parallel({ Faction = "Horde" })
APR.HasPendingStartupQuestConditions = nil
APR.startupQuestStatePending = true
function APR:AreConditionalFiltersMet(conditions) return conditions.Faction == "Horde" end
assert(#APR:GetRouteSteps("parallel") == 4 and savedState().activationSequence == 1)
assert(APR:EvaluateRouteConditions({ IsQuestUncompleted = 4101 }))
state.complete[4101] = true
assert(not APR:EvaluateRouteConditions({ IsQuestUncompleted = 4101 }))
route("required", { IsQuestCompleted = 4101 })
route("requested", nil, { "required" })
assert(APR:IsRequiredRouteApplicable("required") and APR:AddRouteToCustomPathByKey("requested"))
assert(table.concat(APRCustomPath.player, ",") == "Invented required,Invented requested")

-- Loaded diagnostic wrappers must not recreate the membership helper for each
-- operation. Warm both modes before measuring so active logs have their rows.
local diagnostics = APRInstrumentation
if diagnostics then
    local previousEnabled, previousDebug = diagnostics.enabled, diagnostics.debug
    for _, enabled in ipairs({ false, true }) do
        for _, pending in ipairs({ false, true }) do
            fixture()
            route("required")
            route("requested", nil, "required")
            local path = { "Invented required", "Invented requested" }
            for index = 3, 2000 do path[index] = "Unrelated selection " .. index end
            APRCustomPath.player = path
            APR.startupQuestStatePending = pending and true or nil
            diagnostics.enabled, diagnostics.debug = enabled, enabled
            diagnostics.ResetLog()
            local function repeatedReads()
                for _ = 1, 100 do assert(not APR:AddRouteToCustomPathByKey("requested")) end
            end
            repeatedReads()
            collectgarbage("collect")
            collectgarbage("stop")
            local before = collectgarbage("count")
            repeatedReads()
            local bytes = (collectgarbage("count") - before) * 1024
            collectgarbage("restart")
            if not enabled then
                assert(bytes < 128000, "Diagnostic wrappers must fit the existing early membership allocation budget")
            end
            assert(APRCustomPath.player == path and #path == 2000 and path[1] == "Invented required"
                and path[2] == "Invented requested" and path[2000] == "Unrelated selection 2000")
            assert(diagnostics.CurrentName() == nil, "Instrumented lookups must leave no active diagnostic scope")
            print(string.format("Startup membership: diagnostics %s, pending %s, %.0f B / 100 early hits",
                tostring(enabled), tostring(pending), bytes))

            -- Suspend a promoted lookup, then run another selection through
            -- the same helper. Each operation must retain its own cursor.
            fixture()
            route("required")
            route("requested", nil, "required")
            path = {}
            for index = 1, 32 do path[index] = "Saved " .. index end
            APRCustomPath.player = path
            APR.startupQuestStatePending = pending and true or nil
            local nativePairs, visits, paused = pairs, 0, false
            pairs = function(values)
                local iterator, iterState, first = nativePairs(values)
                if values ~= path then return iterator, iterState, first end
                return function(iteratorState, previous)
                    local key, value = iterator(iteratorState, previous)
                    if key ~= nil then
                        visits = visits + 1
                        if visits == 20 and not paused then
                            paused = true
                            diagnostics.Yield("membership pause")
                        end
                    end
                    return key, value
                end, iterState, first
            end
            local thread = coroutine.create(function() return APR:AddRouteToCustomPathByKey("requested") end)
            local ok, result = diagnostics.Resume(thread)
            assert(ok and result == "membership pause" and coroutine.status(thread) == "suspended")
            assert(diagnostics.CurrentName() == nil)
            assert(APR:AddRouteToCustomPathByKey("required") and #path == 33 and path[33] == "Invented required")
            ok, result = diagnostics.Resume(thread)
            pairs = nativePairs
            assert(ok and result and coroutine.status(thread) == "dead")
            assert(#path == 34 and path[33] == "Invented required" and path[34] == "Invented requested")
            for index = 1, 32 do assert(path[index] == "Saved " .. index) end
            assert(diagnostics.CurrentName() == nil)

            local realContains = APR.Contains
            function APR:Contains() error("Synthetic lookup failure") end
            thread = coroutine.create(function() return APR:AddRouteToCustomPathByKey("required") end)
            ok, result = diagnostics.Resume(thread)
            APR.Contains = realContains
            assert(not ok and result:find("Synthetic lookup failure", 1, true))
            assert(diagnostics.CurrentName() == nil and #path == 34,
                "A failed lookup leaves no diagnostic scope or partial insertion")
            assert(not APR:AddRouteToCustomPathByKey("requested") and #path == 34)
        end
    end
    diagnostics.enabled, diagnostics.debug = previousEnabled, previousDebug
end
print("Startup parallel conditions: unknown eligibility preserves activations, rearm and paths; ready snapshots restore one-shot decisions")
