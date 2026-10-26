-- Synthetic acquisition graph; production campaign edits do not change these expectations.
-- Accept actions must resolve their own prerequisites before publishing a target.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load(dofile("tests/lua/navigation_unlock_test_catalog.lua"))
local Lib = LibStub("LibAPRNavigation-1.0")
local completed, active, offers = {}, {}, {}
local unknownQuest
local env = {
    getCharacter = function() return { level = 90, faction = "Horde", mapID = 101 } end,
    isQuestCompleted = function(id) if id ~= unknownQuest then return completed[id] == true end end,
    isQuestActive = function(id) return active[id] == true end,
    isQuestAvailable = function(id) return offers[id] end,
    getLocale = function() return "frFR" end,
    getQuestName = function(id) return "Quête " .. id end,
}
local position = { space = "world", uiMapID = 101, instanceID = 1, x = 350, y = 450 }
local function quest(id, prerequisite)
    return { id = "quest:" .. id, goal = { key = "quest", value = id }, steps = {
        { kind = "accept", questID = id, position = position,
            acceptance = { known = true, requirements = prerequisite and { quest = prerequisite } or {} } },
        { kind = "turnin", questID = id, position = position },
    } }
end
Lib:RegisterData("acceptance-tests", "unlocks", { unlockRoutes = { quest(42, 41), quest(41, 40), quest(40) } })
local navigator = Lib:New({ profile = "acceptance-tests", environment = env })
local destination = { instanceID = 3, uiMapID = 104, x = -1343, y = -515.6 }
local gate = { id = "destination", blockedRequirements = { quest = 42 } }
local function create(instance)
    return (instance or navigator):CreateUnlockSession({ blockers = { gate }, destination = destination })
end
local function tick(session)
    for _ = 1, 10000 do
        local status, action, original = session:Step(8, 1)
        if status ~= "planning" then return status, action, original end
    end
    error("Unbounded prerequisite recursion")
end
local session = create()
local status, action = tick(session)
assert(status == "action" and action.questID == 40, "A prerequisite's prerequisite comes before quest 42")
active[40] = true
status, action = tick(session)
assert(action.questID == 40 and action.kind == "turnin")
completed[40] = true
status, action = tick(session)
assert(action.questID == 41 and action.kind == "accept")
completed[41] = true
status, action = tick(session)
assert(action.questID == 42 and action.kind == "accept")
offers[42] = false
status, action = tick(session)
assert(status == "missing_data" and action.kind == "missing" and not action.target,
    "A negative live offer suppresses acceptance even if known prerequisites pass")
assert(action.label:find("indisponible", 1, true))
offers[42] = true
status, action = tick(session)
assert(status == "action" and action.questID == 42)
completed[42] = true
local original
status, action, original = tick(session)
assert(status == "resume" and original.uiMapID == 104 and original.x == -1343)

-- An incomplete authored entry has no right to claim that a quest is available.
completed, active, offers = {}, {}, {}
navigator.unlockRoutes[3].steps[1].acceptance.known = false
session = create()
status, action = tick(session)
assert(status == "missing_data" and action.questID == 40 and not action.target)
assert(not action.label:find("Accepte", 1, true), "Unknown availability is a diagnostic, not a pickup instruction")
local blocked = session:GetBlockers()
assert(blocked[1].id == "quest-acceptance:40", "Consumers see the deepest failed prerequisite")
offers[42] = true
status, action = tick(session)
assert(status == "action" and action.questID == 42,
    "A direct server offer retires obsolete prerequisite detours, even when a tracker is incomplete")

-- Cycles and unknown flags do not degrade into a blind acceptance action.
completed, active, offers = {}, {}, {}
navigator.unlockRoutes[3].steps[1].acceptance = { known = true, requirements = { quest = 42 } }
session = create()
status, action = tick(session)
assert(status == "missing_data" and not action.target and action.reason == "cyclic_quest_prerequisites")
unknownQuest = 41
session = create()
status, action = tick(session)
assert(status == "waiting_data" and not action.target)
unknownQuest = nil

-- Independent offer metadata preserves a character-only tracker prerequisite.
data.env = env
gate = { id = "karesh", from = { uiMapID = 101 },
    blockedRequirements = { any = { { quest = 12 }, { questActive = 12 } }, minLevel = 80 } }
session = create(data)
status, action = tick(session)
assert(status ~= "action" or action.questID ~= 11,
    "The Horde level-90 character is never sent to accept 11 with missing campaign conditions")
local invitation
for _, recipe in ipairs(data:GetUnlockRoutes()) do
    for _, step in ipairs(recipe.steps) do
        if step.kind == "accept" and step.questID == 11 then invitation = step.acceptance; break end
    end
    if invitation then break end
end
assert(invitation and invitation.known == true and invitation.complete ~= true,
    "All supplied conditions are interpreted without claiming exhaustive world knowledge")
completed[13] = true
assert(data:CheckRequirements(invitation.requirements, env.getCharacter()) == true)
completed[13] = nil
assert(data:CheckRequirements(invitation.requirements, env.getCharacter()) == false,
    "The character's tracker completion is required before the next offer")
completed[14] = true
assert(data:CheckRequirements(invitation.requirements, env.getCharacter()) == false,
    "The authored upto quest does not replace the actual campaign tracker")
local marker
for _, recipe in ipairs(data:GetUnlockRoutes()) do
    if recipe.goal.key == "quest" and recipe.goal.value == 13 then marker = recipe end
end
assert(marker and marker.guidanceQuestID == 14, "Tracker guidance uses the sourced upto quest without fabricated coordinates")

for _, locale in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
    for _, suffix in ipairs({ "accept_unverified", "accept_unavailable" }) do
        local key = "NAVIGATION_UNLOCK_" .. suffix
        assert(Lib:GetText(key, locale) ~= key)
    end
end
print("Quest acceptance: recursive prerequisites, live availability, cycles, hidden trackers and original destination passed")
