-- Runtime contracts: no fabricated NPC offers, mutable entry guards and
-- non-quest goals are resolved by the same autonomous declarative runner.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture:Load()
local Lib = LibStub("LibAPRNavigation-1.0")
local completed, active, offers, achievements, account = {}, {}, {}, {}, {}
local currency, reputation, items, spells, skills = {}, {}, {}, {}, {}
local player = { instanceID = 2552, uiMapID = 2248, x = 100, y = 100 }
local criteria, quantity, total, actionDone
local position = { space = "world", instanceID = 2552, uiMapID = 2248, x = 1, y = 2 }
local env = {
    getCharacter = function() return { faction = "Horde", class = "PALADIN", level = 90, mapID = player.uiMapID } end,
    getPlayerPosition = function() return player end,
    isQuestCompleted = function(id) return completed[id] == true end,
    isQuestActive = function(id) return active[id] == true end,
    isQuestCompletedOnAccount = function(id) return account[id] == true end,
    isQuestAvailable = function(id) return offers[id] end,
    isAchievementCompleted = function(id) return achievements[id] == true end,
    isQuestObjectiveCompleted = function() return false end,
    getQuestObjectiveProgress = function() return quantity, total end,
    getScenarioCriteria = function() return criteria end,
    isUnlockActionComplete = function() return actionDone end,
    getCurrencyQuantity = function(id) return currency[id] or 0 end,
    getReputationStanding = function(id) return reputation[id] or 0 end,
    getItemCount = function(id) return items[id] or 0 end,
    isSpellKnown = function(id) return spells[id] == true end,
    getSkillLevel = function(id) return skills[id] or 0 end,
    getLocale = function() return "frFR" end,
}
local function quest(id, requirements)
    return { id = "quest:" .. id, goal = { key = "quest", value = id }, requirements = requirements,
        steps = {
            { kind = "accept", questID = id, position = position,
                acceptance = { known = false, requirements = {}, gaps = { "prerequisites_unverified" },
                    sources = { "att:verified-record" }, starterNPCIDs = { 100 } } },
            { kind = "turnin", questID = id, position = position },
        } }
end
local function navigator(recipes)
    Lib:RegisterData("runtime-prerequisites", "test", { unlockRoutes = recipes }, (Lib.dataRevisions["runtime-prerequisites:test"] or 0) + 1)
    return Lib:New({ profile = "runtime-prerequisites", environment = env })
end
local destination = { instanceID = 2738, uiMapID = 2472, x = -1343, y = -515.6 }
local function session(data, requirements)
    return data:CreateUnlockSession({ destination = destination,
        blockers = { { id = "destination", from = { uiMapID = 2248 }, blockedRequirements = requirements } } })
end
local function tick(run)
    for _ = 1, 10000 do
        local status, action, goal = run:Step(8, 1)
        if status ~= "planning" then return status, action, goal end
    end
    error("Prerequisite resolution did not terminate")
end

local root = quest(3, { quest = 2 })
local data = navigator({ root, quest(2, { quest = 1 }), quest(1) })
local run = session(data, { quest = 3 })
local status, action = tick(run)
assert(status == "action" and action.questID == 1, "Recipe entry requirements recurse without an observed NPC offer")
completed[1] = true
status, action = tick(run)
assert(status == "action" and action.questID == 2)
completed[2] = true
status, action = tick(run)
assert(status == "action" and action.questID == 3)
offers[3] = false
status, action = tick(run)
assert(status == "missing_data" and action.reason == "quest_unavailable" and not action.target)
assert(run.acceptanceEvidence.offer == "unavailable" and run.acceptanceEvidence.requirements == "passed",
    "Diagnostics retain a server rejection separately from the known prerequisite results")
offers[3] = nil
completed[3] = true
local goal
status, action, goal = tick(run)
assert(status == "resume" and goal.uiMapID == 2472 and goal.x == -1343)

-- Distinguish advisory completeness from an unsupported real restriction.
completed, active, offers = {}, {}, {}
root = quest(3)
root.steps[1].acceptance.blockingGaps = { "unsupported_condition:minReputation" }
data = navigator({ root })
status, action = tick(session(data, { quest = 3 }))
assert(status == "missing_data" and not action.target)
root.steps[1].acceptance.blockingGaps = {}
root.steps[1].acceptance.advisoryGaps = { "not_exhaustive" }
root.steps[1].acceptance.gaps = { "not_exhaustive" }
data = navigator({ root })
assert(tick(session(data, { quest = 3 })) == "action")

-- Prefer the viable OR branch even when a cyclic recipe has fewer steps.
local cycle = quest(3)
cycle.steps[1].acceptance.requirements = { quest = 3 }
local other = quest(4)
other.steps[#other.steps + 1] = { kind = "waypoint", position = position }
local wrongFaction = quest(4, { faction = "Alliance" })
wrongFaction.id = "wrong-faction"
wrongFaction.steps = { wrongFaction.steps[1] }
data = navigator({ cycle, wrongFaction, other })
status, action = tick(session(data, { any = { { quest = 3 }, { quest = 4 } } }))
assert(status == "action" and action.questID == 4, "An impossible shorter recipe cannot starve the available alternative")

-- Step-level mutable conditions are prerequisites, not skipped instructions.
local achievement = { id = "achievement", goal = { key = "achievement", value = 5 }, steps = {
    { kind = "interact", position = position, completeWhen = { achievement = 5 } },
} }
root = quest(3)
root.steps[1].requirements = { any = { { class = "MAGE" }, { achievement = 5 } } }
data = navigator({ root, achievement })
run = session(data, { quest = 3 })
status, action = tick(run)
assert(status == "action" and action.kind == "interact")
achievements[5] = true
status, action = tick(run)
assert(status == "action" and action.questID == 3)

-- Account state does not pretend that a character completed the same quest.
root = quest(7)
root.goal.key = "questAccount"
data = navigator({ root })
run = session(data, { questAccount = 7 })
completed[7] = true
assert(tick(run) ~= "resume")
account[7] = true
assert(tick(run) == "resume")

-- All non-quest goals use exact structured values and observed completion.
local requirements = { currency = { id = 2900, amount = 4 }, reputation = { factionID = 10, standing = 5 },
    item = { id = 12, count = 2 }, spellKnown = 14, skill = { id = 15, min = 75 } }
local recipes = {}
for key, value in pairs(requirements) do
    recipes[#recipes + 1] = { id = key, goal = { key = key, value = value }, steps = {
        { kind = "interact", position = position, completeWhen = { [key] = value } },
    } }
end
data = navigator(recipes)
run = session(data, requirements)
assert(tick(run) == "action")
currency[2900], reputation[10], items[12], spells[14], skills[15] = 4, 5, 2, true, 75
assert(tick(run) == "resume")
assert(data:CheckRequirements({ currency = { id = 2900, min = 4 }, reputation = { id = 10, minStanding = 5 } }, env.getCharacter()))

-- Active acceptance bypasses unavailable/unknown entry metadata.
root = quest(8)
root.steps[1].acceptance = { known = false, requirements = { quest = 999 } }
data = navigator({ root })
active[8] = true
status, action = tick(session(data, { quest = 8 }))
assert(status == "action" and action.kind == "turnin")

-- An active goal remains active while another conjunct is being completed.
local activeRecipe = quest(8)
activeRecipe.goal.key = "questActive"
data = navigator({ activeRecipe, quest(9) })
status, action = tick(session(data, { all = { { questActive = 8 }, { quest = 9 } } }))
assert(status == "action" and action.questID == 9, "A held quest must not be turned in to satisfy another conjunct")

-- Numerical goals can require several independent reward sources. Entry
-- availability is consumed at selection, not imposed after rewarding a quest.
currency[2900] = 0
local first, second = quest(100), quest(101)
for _, recipe in ipairs({ first, second }) do
    local sourceQuest = recipe.goal.value
    recipe.goal = { key = "currency", value = { id = 2900, amount = 4 } }
    recipe.availability = { notCondition = { quest = sourceQuest } }
    recipe.progressive = true
end
data = navigator({ first, second })
run = session(data, { currency = { id = 2900, amount = 4 } })
status, action = tick(run)
assert(action.questID == 100)
completed[100], currency[2900] = true, 2
run:Retry()
status, action = tick(run)
assert(status == "action" and action.questID == 101, "Partial progress selects another available source")
completed[101], currency[2900] = true, 4
assert(tick(run) == "resume")

-- A source can have a manual use action after its quest reward. Its now-false
-- availability cannot discard that pending action, including across reload.
currency[2900], actionDone = 0, false
first, second = quest(110), quest(111)
for _, recipe in ipairs({ first, second }) do
    local sourceQuest = recipe.goal.value
    recipe.goal = { key = "currency", value = { id = 2900, amount = 4 } }
    recipe.availability = { notCondition = { quest = sourceQuest } }
    recipe.progressive = true
end
first.steps[#first.steps + 1] = { kind = "action", actionType = "spell", parameters = 120, position = position }
second.steps[#second.steps + 1] = { kind = "waypoint", position = position }
data = navigator({ first, second })
run = session(data, { currency = { id = 2900, amount = 4 } })
status, action = tick(run)
assert(action.questID == 110)
completed[110] = true
run:Retry()
status, action = tick(run)
assert(status == "action" and action.actionType == "spell")
run = data:RestoreUnlockSession(run:ExportState())
status, action = tick(run)
assert(status == "action" and action.actionType == "spell", "Reload retains a selected acquisition's post-reward instruction")
actionDone = true
status, action = tick(run)
assert(status == "action" and action.questID == 111, "An exhausted source that did not reach the threshold is not repeated")

-- Boolean false is a real goal value, distinct from an absent quest identity.
env.isChromieTimeActive = function() return true end
data = navigator({ { id = "leave-chromie", goal = { key = "chromieTime", value = false }, steps = {
    { kind = "interact", position = position, completeWhen = { chromieTime = false } },
} } })
run = session(data, { chromieTime = false })
assert(tick(run) == "action")
env.isChromieTimeActive = function() return false end
assert(tick(run) == "resume")

print("Prerequisite runtime: recursive recipe/step guards, sourced offers, blocking gaps, OR viability, account and non-quest goals passed")
