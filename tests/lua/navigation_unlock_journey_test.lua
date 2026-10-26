-- Synthetic acquisition graph; production campaign edits do not change these expectations.
-- End-to-end native guidance must reach 12 without an offer pre-observed.
-- Load the library with synthetic data; the host route engine is absent.
APR, APRData, LibStub = nil, nil, nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a"); manifest:close()
for file in xml:gmatch('file="([^"]+)"') do if not file:match("^Data/") then dofile(root .. file) end end
local Lib = LibStub("LibAPRNavigation-1.0")
Lib:RegisterData("retail", "fixture", dofile("tests/lua/navigation_unlock_test_catalog.lua"))
local completed, active, objectives = {}, {}, {}
local availableCalls, renownAmount = 0, 4
local mapInstances = { [101] = 1, [102] = 1, [103] = 2 }
local maps = {
    [947] = { mapType = 0, parentMapID = 0 },
    [2274] = { mapType = 2, parentMapID = 947 },
    [101] = { mapType = 3, parentMapID = 2274 },
    [102] = { mapType = 3, parentMapID = 101 },
    [103] = { mapType = 3, parentMapID = 2274 },
}
local env = {
    getCharacter = function() return { faction = "Horde", class = "PALADIN", raceID = 10,
        level = 90, mapID = 102, inGroup = false, indoors = false, inInstance = false } end,
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
        if id == 32 or id == 31 or id == 33 or id == 34 then return renownAmount end
        return 0
    end,
    getReputationAmount = function(id) return id == 2600 and 3 or 0 end,
    getReputationStanding = function(id) return id == 2600 and 3 or 4 end,
    getMapInfo = function(id) return maps[id] end,
    mapToWorld = function(id, x, y) return mapInstances[id] or 2, (x or 0) * 1000, (y or 0) * 1000 end,
    isAchievementCompleted = function() return false end,
}
local navigator = Lib:New({ profile = "retail", environment = env })
local destination = { uiMapID = 104, instanceID = 3, x = -1343, y = -515.6 }
local blockers = { { id = "journey-karesh", from = { uiMapID = 101 },
    blockedRequirements = { minLevel = 80, any = { { quest = 12 }, { questActive = 12 } } } } }
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
    local action = expect(session, "accept", 11)
    assert(action.target and action.target.x == 300 and action.target.y == 400,
        "The fixture pickup coordinates are preserved")
    active[11] = true
    expect(session, "turnin", 11)
    completed[11], active[11] = true, nil
    expect(session, "accept", 12)
    active[12] = true
    local status, _, original = nextAction(session)
    assert(status == "resume" and original.uiMapID == destination.uiMapID
        and original.x == destination.x and original.y == destination.y,
        "The destination resumes immediately when the original gate becomes usable")
end

-- Being eligible must produce a pickup target, not an unknown-offer dead end.
completed[13] = true
finishInvitation(create())
assert(availableCalls > 0, "Availability can be queried but nil is not a global prohibition")

-- The preceding campaign quest must be guided first, from its authored position.
completed, active, objectives = { [16] = true, [17] = true }, {}, {}
local session = create()
local action = expect(session, "accept", 14)
assert(action.target and action.target.uiMapID == 103
    and action.target.x == -100 and action.target.y == -200,
    "The precursor uses its observed Azj-Kahet quest-giver, not the locked invitation")
active[14] = true
action = expect(session, "objective", 14)
for _, index in ipairs(action.objectiveIndices or {}) do objectives["14:" .. index] = true end
expect(session, "turnin", 14)
completed[14], active[14] = true, nil
local status, pending = nextAction(session)
assert(status ~= "resume" and (not pending or pending.questID ~= 11),
    "Rewarding the visible quest is not proof that the separate campaign tracker was received")
-- This is a distinct client observation, not an inferred completion by the library.
completed[13] = true
finishInvitation(session)

-- Progressive fixture activities use observed receipts and currency amounts.
-- Synthetic activities progress the target; their hidden receipts
-- are observed, never published as quests to pick up.
completed, active, objectives, renownAmount = {}, {}, {}, 0
local renown = navigator:CreateUnlockSession({ blockers = {
    { id = "actual-renown", blockedRequirements = { currency = { id = 31, amount = 4 } } },
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
