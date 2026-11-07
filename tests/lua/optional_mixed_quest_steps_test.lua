-- Independent optional quests must not make each other's missing objectives mandatory.
local function noop() end
function LibStub() return { GetLocale = function() return {} end } end
function UnitLevel() return 20 end

APR = {
    stepHandlers = {}, Debug = noop, PlayerID = "fixture", MaxLevel = 80,
    BonusObj = {}, QUEST_STATUS = { COMPLETE = "complete" }, ActiveQuests = {},
}
APRData = { fixture = { BonusSkips = {} } }
local states, advanced, missing, tracked = {}, 0, 0, nil
local activeStates = { incomplete = true, partial = true, complete = true }
C_QuestLog = {
    IsOnQuest = function(id) return activeStates[states[id]] == true end,
    IsQuestFlaggedCompleted = function(id) return states[id] == "rewarded" end,
}
function APR:Contains() return false end
function APR:UpdateNextStep() advanced = advanced + 1 end
function APR:HandleMissingQuest() missing = missing + 1 end
function APR:GetQuestTextForProgressBar() return "Synthetic objective" end
function APR:TrackQuest(id) tracked = id end
APR.currentStep = { AddQuestSteps = noop }
dofile("APR-Core/utils/RouteUtils.lua")
dofile("APR-Core/features/questing/StepQuestHandlers.lua")

local first, second = 710001, 710002
local split = {
    { Qpart = { [first] = { 1 } }, IsQuestOnQuest = first },
    { Qpart = { [second] = { 2, 4 } }, IsQuestOnQuest = second },
}
local combined = {
    Qpart = { [first] = { 1 }, [second] = { 2, 4 } },
    AnyOf = { { IsQuestOnQuest = first }, { IsQuestOnQuest = second } },
}
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end

local function setState(a, b)
    states = { [first] = a, [second] = b }
    APR.ActiveQuests = {}
    for id, state in pairs(states) do
        if activeStates[state] then
            local objectives = {}
            for index = 1, 4 do
                objectives[index] = {
                    status = (state == "complete" or (state == "partial" and index == 2))
                        and "complete" or "incomplete",
                }
            end
            APR.ActiveQuests[id] = { objectives = objectives }
        end
    end
end

local function run(step)
    advanced, missing, tracked = 0, 0, nil
    if not APR:AreConditionalFiltersMet(step) then return "filtered" end
    APR.stepHandlers.Qpart(step, true, 1)
    return advanced == 1 and "advanced" or "waiting"
end

-- Reproduce the prior combined shape: the OR filter cannot change Qpart's AND contract.
for _, unavailable in ipairs({ "absent", "abandoned" }) do
    setState("complete", unavailable)
    check(run(combined) == "waiting" and missing == 2, "Missing second quest blocks a combined step")
    setState(unavailable, "complete")
    check(run(combined) == "waiting" and missing == 1, "Missing first quest also blocks a combined step")
end
setState("complete", "rewarded")
check(run(combined) == "advanced", "Rewarded and absent are distinct native states")

local expected = {
    absent = "filtered", abandoned = "filtered", rewarded = "filtered",
    incomplete = "waiting", partial = "waiting", complete = "advanced",
}
local allStates = { "absent", "abandoned", "rewarded", "incomplete", "partial", "complete" }
for _, a in ipairs(allStates) do
    for _, b in ipairs(allStates) do
        setState(a, b)
        check(run(split[1]) == expected[a], "First quest obeys only its own state")
        check(missing == 0, "First action never asks for an absent sibling")
        check(tracked == (expected[a] == "waiting" and first or nil), "First pending objective remains tracked")
        check(run(split[2]) == expected[b], "Second quest obeys only its own state")
        check(missing == 0, "Second action never asks for an absent sibling")
        check(tracked == (expected[b] == "waiting" and second or nil), "Second pending objective remains tracked")
    end
end

-- Observe fresh state on every pass: abandon, reaccept, partial progress and completion.
for _, transition in ipairs({
    { "incomplete", "waiting" }, { "abandoned", "filtered" },
    { "incomplete", "waiting" }, { "partial", "waiting" },
    { "complete", "advanced" }, { "rewarded", "filtered" },
}) do
    setState("complete", transition[1])
    check(run(split[2]) == transition[2], "Reaccepted quest must wait for all its objectives")
    check(missing == 0, "State transitions do not request the other quest")
end
print("Optional mixed quest steps: " .. checks .. " native filter/handler checks passed")
