-- Independent acquisition graph. These IDs/positions are fixture values, not
-- copies of a campaign: two offers, a tracker, shared prerequisites and cycles.
local function position(map, world, x, y)
    return { space = "world", uiMapID = map, instanceID = world, x = x, y = y }
end
local pickup, reward = position(101, 1, 300, 400), position(101, 1, 350, 450)
local function quest(id, requirements, point, objectives, goal, npc)
    local steps = { { kind = "accept", questID = id, position = point or pickup,
        acceptance = { known = true, complete = false, requirements = requirements or {},
            starterNPCIDs = { npc or 21 }, sources = { "synthetic fixture" } } } }
    if objectives then steps[#steps + 1] = { kind = "objective", questID = id,
        objectiveIndices = objectives, position = point or pickup } end
    steps[#steps + 1] = { kind = "turnin", questID = id, position = reward }
    return { id = "quest:" .. (goal or id), goal = { key = "quest", value = goal or id },
        prerequisitesKnown = false, steps = steps }
end
local recipes = {
    quest(11, { minLevel = 80, quest = 13 }),
    quest(12, { minLevel = 80, quest = 11 }, nil, { 1, 2 }, nil, 22),
    quest(14, { all = { { quest = 16 }, { quest = 17 } } }, position(103, 2, -100, -200), { 1 }, 13),
    quest(16, { quest = 15 }), quest(17, { quest = 15 }),
    quest(15, nil, position(106, 4, -500, 600)),
}
recipes[3].guidanceQuestID = 14
local activeRecipe = quest(12, { quest = 11 }, nil, { 1, 2 }, nil, 22)
activeRecipe.id, activeRecipe.goal.key = "active:12", "questActive"
recipes[#recipes + 1] = activeRecipe
-- Controlled scale and cyclic alternatives exercise discovery independently of
-- the number of acquisitions shipped by any release.
for index = 101, 800 do recipes[#recipes + 1] = quest(index, { quest = index }) end
for index = 1, 2 do
    local receipt = 40 + index
    recipes[#recipes + 1] = { id = "activity-" .. index, goal = { key = "currency", value = { id = 31, amount = 4 } },
        progressive = true, availability = { notCondition = { quest = receipt } }, steps = {
            { kind = "action", actionType = "npc_activity", position = pickup,
                parameters = { npcID = 21, trackerQuestID = receipt }, completeWhen = { quest = receipt } },
        } }
end
return { unlockRoutes = recipes, unlockCoverage = {
    quests = { { questID = 11, gaps = { "fixture gap" } } }, accesses = { { id = "fixture-access" } },
} }
