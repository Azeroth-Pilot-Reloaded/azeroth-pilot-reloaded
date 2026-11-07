local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.translations = { PATH_NOT_FOUND = "No path" }
local retail = fixture:Load()
local locale = LibStub("AceLocale-3.0")
function locale:NewLocale(_, language)
    if language == "enUS" then return fixture.translations end
end
dofile("APR-Core/locales/enUS.lua")
local completed, active, achievement, unknown = {}, {}, false, false
C_QuestLog.IsQuestFlaggedCompleted = function(id)
    if not unknown then return completed[id] == true end
end
C_QuestLog.IsOnQuest = function(id)
    if not unknown then return active[id] == true end
end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return false end
C_QuestLog.GetTitleForQuestID = function(id) return id == 41001 and "Synthetic gate quest" end
function GetAchievementInfo(id) return id, "Test achievement", 0, achievement end
-- Access rules are contracts of the engine, independent of portal identities.
local gateQuest = 41002
local gate = { any = { { quest = gateQuest }, { questActive = gateQuest } } }
local gatedLevel = { all = { { minLevel = 40 }, gate } }
assert(retail:CheckRequirements(gate, { level = 90 }) == false)
active[gateQuest] = true
assert(retail:CheckRequirements(gate, { level = 90 }) == true)
assert(retail:CheckRequirements(gatedLevel, { level = 39 }) == false)
assert(retail:CheckRequirements(gatedLevel, { level = 40 }) == true)
active[gateQuest], completed[gateQuest] = nil, true
assert(retail:CheckRequirements(gate, { level = 90 }) == true)
assert(retail:CheckRequirements(gatedLevel, { level = 40 }) == true)
completed[gateQuest] = nil
assert(retail:CheckRequirements(gate, { level = 90 }) == false)
unknown = true
assert(retail:CheckRequirements(gate, { level = 90 }) == nil)
unknown = false
local function point(world, map) return { space = "world", instanceID = world, uiMapID = map, x = 0, y = 0 } end
local start, middle, goal = point(0, 84), point(1, 85), point(2, 86)
local lib = LibStub("LibAPRNavigation-1.0")
lib:RegisterData("access-test", "transport", {
    connections = {
        {
            id = "rift",
            kind = "portal",
            from = start,
            to = middle,
            seconds = 5,
            requirements = { any = { { quest = 41001 }, { questActive = 41001 } } },
        },
        {
            id = "raid-gate",
            kind = "portal",
            from = middle,
            to = goal,
            seconds = 5,
            requirements = { achievement = 123 },
        },
        {
            id = "unrelated",
            kind = "boat",
            from = point(4, 87),
            to = point(5, 88),
            seconds = 1,
            requirements = { quest = 999 },
        },
        {
            id = "unowned-shortcut",
            kind = "item",
            from = start,
            to = goal,
            seconds = 1,
            actions = { { type = "item", id = 42 } },
        },
        {
            id = "wrong-level-shortcut",
            kind = "item",
            from = { dynamic = "player" },
            to = goal,
            seconds = 0,
            actions = { { type = "item", id = 43 } },
            requirements = { maxLevel = 49 },
        },
        {
            id = "departure",
            kind = "portal",
            from = point(6, 84),
            to = point(7, 85),
            seconds = 1,
            bidirectional = true,
            requirements = { mapID = 85 },
        },
    },
})
lib:RegisterData("alias-test", "transport", {
    connections = {
        {
            id = "alternate-door",
            kind = "portal",
            from = start,
            to = goal,
            requirements = { all = { { questActive = 41003 }, { achievement = 123 } } },
        },
    },
})
local alias = lib:New({ profile = "alias-test", environment = APR.NavigationData.env })
assert(#alias:BuildEdges() == 0, "An alternate entrance cannot bypass its access rules")
active[41003] = true
assert(#alias:BuildEdges() == 0, "Every access condition is required")
achievement = true
assert(#alias:BuildEdges() == 1, "A permitted alternate entrance remains usable")
active[41003], achievement = nil, false
local data = lib:New({ profile = "access-test", environment = APR.NavigationData.env })
APR.NavigationData = data
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local rows = 0
local function plan()
    local job = APR.NavigationPlanner:Create({
        data = data,
        engine = lib.Engine,
        taxiData = { BuildEdges = function() return {}, {} end },
        start = start,
        goal = goal,
        playerPosition = start,
        walkSpeed = 7,
        canWalk = function(a, b) return a.instanceID == b.instanceID end,
        prepareSegment = function(edge)
            rows = rows + 1
            return edge
        end,
    })
    local slices = 0
    while job:Step(2, 1) == "planning" do
        slices = slices + 1
        assert(slices < 1000)
    end
    return job
end
local job = plan()
assert(
    job.status == "no_path" and #job.blockers == 2 and rows == 0,
    "Only gates on a connected potential itinerary explain failure; diagnostic edges never become guidance"
)
local text = APR.NavigationAdapter:GetBlockedRouteText(job.blockers)
assert(
    text:find("Synthetic gate quest", 1, true)
        and text:find("41001", 1, true)
        and text:find("Test achievement", 1, true)
        and text:find("\n  or\n", 1, true)
)
assert(not text:find("999", 1, true), "Unrelated locked transports are not reported")
local edges, metadata = data:BuildEdges({ start = start, playerPosition = start })
local reverse = false
for _, edge in ipairs(edges) do
    assert(not edge.blockedRequirements and not edge.blockedActions)
    assert(not edge.id:find("rift", 1, true))
    reverse = reverse or edge.id == "access-test:departure:reverse"
end
assert(reverse, "A blocked first direction cannot contaminate the usable reverse direction")
active[41001] = true
job = plan()
assert(job.status == "no_path" and #job.blockers == 1 and job.blockers[1].blockedRequirements.achievement == 123)
achievement = true
job = plan()
assert(job.status == "ready" and not job.blockers and #job:GetResult().queue > 0)
active[41001], unknown, achievement = nil, true, false
job = plan()
assert(job.status == "no_path" and job.waitingData and #job.blockers == 2)
assert(
    APR.NavigationAdapter:GetBlockedRouteText(job.blockers):find("Unverified client data", 1, true),
    "Unavailable client data never masquerades as a completed or definitely missing quest"
)
local negated = data:GetRequirementFailures({ notCondition = { quest = 123 } }, {}, true)
unknown, completed[123] = false, true
negated = data:GetRequirementFailures({ notCondition = { quest = 123 } }, {})
assert(negated.children[1].children[1].negated, "Negated requirements retain their meaning")

data.connections = {
    { id = "item", kind = "item", from = start, to = goal, actions = { { type = "item", id = 42 } }, seconds = 1 },
    {
        id = "unrelated",
        kind = "boat",
        from = point(4, 87),
        to = point(5, 88),
        seconds = 1,
        requirements = { quest = 999 },
    },
}
data.env.getActionUsability = function() return false, "cooldown" end
job = plan()
assert(job.status == "no_path" and #job.blockers == 1 and job.blockers[1].blockedActions)
text = APR.NavigationAdapter:GetBlockedRouteText(job.blockers)
assert(
    text:find("cooldown", 1, true) and text:find("[42]", 1, true),
    "Unavailable personal transports explain their action restriction without entering the live graph"
)
print(
    "Access diagnostics: intermediate gates, alternatives, unknowns, directional isolation, localized client names and live exclusion passed"
)
