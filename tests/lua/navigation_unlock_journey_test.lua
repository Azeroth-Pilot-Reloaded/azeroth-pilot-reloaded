-- End-to-end native guidance must reach 84957 without an offer pre-observed.
-- Load the shipped library alone; the host route engine is deliberately absent.
APR, APRData, LibStub = nil, nil, nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a"); manifest:close()
for file in xml:gmatch('file="([^"]+)"') do dofile(root .. file) end
local Lib = LibStub("LibAPRNavigation-1.0")
local completed, active, objectives = {}, {}, {}
local availableCalls, renownAmount = 0, 4
local mapInstances = { [2248] = 2552, [2339] = 2552, [2255] = 2601 }
local maps = {
    [947] = { mapType = 0, parentMapID = 0 },
    [2274] = { mapType = 2, parentMapID = 947 },
    [2248] = { mapType = 3, parentMapID = 2274 },
    [2339] = { mapType = 3, parentMapID = 2248 },
    [2255] = { mapType = 3, parentMapID = 2274 },
}
local env = {
    getCharacter = function() return { faction = "Horde", class = "PALADIN", raceID = 10,
        level = 90, mapID = 2339, inGroup = false, indoors = false, inInstance = false } end,
    getLocale = function() return "frFR" end,
    isQuestCompleted = function(id) return completed[id] == true end,
    isQuestActive = function(id) return active[id] == true end,
    isQuestCompletedOnAccount = function() return false end,
    isQuestAvailable = function() availableCalls = availableCalls + 1; return nil end,
    isQuestReadyForTurnIn = function() return false end,
    isQuestObjectiveCompleted = function(id, index) return objectives[id .. ":" .. index] == true end,
    getQuestName = function(id) return "Quest " .. id end,
    getQuestObjectiveText = function(_, index) return "Objective " .. index end,
    getCurrencyQuantity = function(id)
        if id == 2900 or id == 2898 or id == 2901 or id == 2904 then return renownAmount end
        return 0
    end,
    getReputationAmount = function(id) return id == 2600 and 3 or 0 end,
    getReputationStanding = function(id) return id == 2600 and 3 or 4 end,
    getMapInfo = function(id) return maps[id] end,
    mapToWorld = function(id, x, y) return mapInstances[id] or 2601, (x or 0) * 1000, (y or 0) * 1000 end,
    isAchievementCompleted = function() return false end,
}
local navigator = Lib:New({ profile = "retail", environment = env })
local destination = { uiMapID = 2472, instanceID = 2738, x = -1343, y = -515.6 }
local blockers = { { id = "journey-karesh", from = { uiMapID = 2248 },
    blockedRequirements = { minLevel = 80, any = { { quest = 84957 }, { questActive = 84957 } } } } }
local function create()
    return navigator:CreateUnlockSession({ blockers = blockers, destination = destination })
end
local function nextAction(session)
    for _ = 1, 10000 do
        local status, action, original = session:Step(16, 1)
        if status ~= "planning" then return status, action, original end
    end
    error("A native unlock journey did not finish a planning slice")
end
local function expect(session, kind, questID)
    local status, action = nextAction(session)
    assert(status == "action", "Expected real guidance for " .. questID .. ", got " .. tostring(status)
        .. " (" .. tostring(action and action.reason) .. ")")
    assert(action.kind == kind and action.questID == questID,
        "Expected " .. kind .. " " .. questID .. ", got " .. tostring(action.kind) .. " " .. tostring(action.questID))
    assert(action.target or action.positionOptional == true, "An action must have a real target or a sourced coordinate-free instruction")
    return action
end
local function finishInvitation(session)
    local action = expect(session, "accept", 84956)
    assert(action.target and action.target.x == 2923.7 and action.target.y == -2423.3,
        "The actual invitation coordinates are preserved")
    active[84956] = true
    expect(session, "turnin", 84956)
    completed[84956], active[84956] = true, nil
    expect(session, "accept", 84957)
    active[84957] = true
    local status, _, original = nextAction(session)
    assert(status == "resume" and original.uiMapID == destination.uiMapID
        and original.x == destination.x and original.y == destination.y,
        "The destination resumes immediately when the original gate becomes usable")
end

-- Being eligible must produce a pickup target, not an unknown-offer dead end.
completed[79573] = true
finishInvitation(create())
assert(availableCalls > 0, "Availability can be queried but nil is not a global prohibition")

-- The preceding campaign quest must be guided first, from its authored position.
completed, active, objectives = { [84022] = true, [78248] = true }, {}, {}
local session = create()
local action = expect(session, "accept", 79197)
assert(action.target and action.target.uiMapID == 2255
    and action.target.x == -477.9 and action.target.y == -1354.5,
    "The precursor uses its observed Azj-Kahet quest-giver, not the locked invitation")
active[79197] = true
action = expect(session, "objective", 79197)
for _, index in ipairs(action.objectiveIndices or {}) do objectives["79197:" .. index] = true end
expect(session, "turnin", 79197)
completed[79197], active[79197] = true, nil
local status, pending = nextAction(session)
assert(status ~= "resume" and (not pending or pending.questID ~= 84956),
    "Rewarding the visible quest is not proof that the separate campaign tracker was received")
-- This is a distinct client observation, not an inferred completion by the library.
completed[79573] = true
finishInvitation(session)

-- Every shipped condition family must have a runtime evaluator, independently
-- of an earlier false sibling in an AND expression.
local checked = 0
local function inspect(requirements)
    for key, value in pairs(requirements or {}) do
        if key == "all" or key == "any" then
            for _, child in ipairs(value) do inspect(child) end
        elseif key == "notCondition" then inspect(value)
        else
            local _, reason = navigator:CheckRequirements({ [key] = value }, env.getCharacter())
            assert(not reason, "Shipped condition has no evaluator: " .. key .. " / " .. tostring(reason))
            checked = checked + 1
        end
    end
end
for _, connection in ipairs(navigator:GetConnections()) do inspect(connection.requirements) end
for _, recipe in ipairs(navigator:GetUnlockRoutes()) do
    inspect(recipe.requirements)
    inspect(recipe.availability)
    for _, step in ipairs(recipe.steps) do
        inspect(step.requirements)
        inspect(step.completeWhen)
        inspect(step.acceptance and step.acceptance.requirements)
    end
end
assert(checked > 100)
assert(APR == nil and APRData == nil, "Full unlock journeys remain independent of APR initialization")
print("Unlock journeys: real 79197 -> campaign tracker -> 84956 -> 84957 guidance, no pre-observed offer, exact destination and shipped condition evaluators passed")

-- Actual shipped renown activities progress the target; their hidden receipts
-- are observed, never published as quests to pick up.
completed, active, objectives, renownAmount = {}, {}, {}, 0
local renown = navigator:CreateUnlockSession({ blockers = {
    { id = "actual-renown", blockedRequirements = { currency = { id = 2898, amount = 4 } } },
}, destination = destination })
local state, activity = nextAction(renown)
assert(state == "action" and activity.kind == "action" and activity.actionType == "npc_activity",
    "An unmet renown threshold has an actual sourced NPC activity")
assert(activity.parameters.npcID and activity.parameters.trackerQuestID and activity.target)
assert(activity.label:find(tostring(activity.parameters.npcID), 1, true), "The actual NPC is named or identified")
local firstReceipt = activity.parameters.trackerQuestID
completed[firstReceipt], renownAmount = true, 1
state, activity = nextAction(renown)
assert(state ~= "resume", "One activity is not automatically four renown levels")
assert(state == "action" and activity.parameters.trackerQuestID ~= firstReceipt,
    "The next source excludes an already rewarded activity")
renownAmount = 4
assert(nextAction(renown) == "resume", "Only the observed threshold resumes the destination")
