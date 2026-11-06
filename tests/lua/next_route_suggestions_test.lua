-- Explicit continuations use synthetic guides, independent of maintained route content.
local env = dofile("tests/lua/route_prefab_test_env.lua")
local routes = APR.RouteQuestStepList
local leveling, dungeons = APR.CATEGORIES.Leveling, APR.CATEGORIES.Dungeons
C_Map = { GetBestMapForUnit = function() return 1 end }
C_SpecializationInfo = {
    GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function() return 71 end,
}
function APR:IsDelveRoute(key) return key == "delve" end
function APR:BuildEffectiveRouteSteps() error("Suggestions must not build or activate route steps") end

local function expect(expected)
    local suggestions = APR:GetNextRouteSuggestions("finished")
    assert(#suggestions == #expected, "Unexpected next-route count: " .. #suggestions)
    for index, key in ipairs(expected) do
        assert(suggestions[index].key == key, "Unexpected next route at " .. index .. ": " .. suggestions[index].key)
        assert(suggestions[index].label == routes[key].label)
    end
    return suggestions
end

for _, version in ipairs({ APR.GAME_VERSIONS.Retail, APR.GAME_VERSIONS.Forever }) do
    APR.RouteQuestStepList = {}
    routes = APR.RouteQuestStepList
    env.gameVersion, APR.Level = version, 13
    APRData.player, APRCustomPath.player, APRZoneCompleted.player = {}, {}, {}
    local function route(key, label, conditions, category, prefab)
        local data = env.route(key, label, conditions, prefab, category or leveling)
        data.expansion, data.gameVersion = nil, version
        return data
    end
    local finished = route("finished", "Finished")
    finished.nextRoute = {
        "preferred",
        "preferred",
        "finished",
        "missing",
        "alias",
        "unlabelled",
        { route = "dungeon-leveling", conditions = { SkipForLvl = 15 } },
        { route = "dungeon-only", conditions = { SkipForLvl = 15 } },
        "outdoor",
        { route = "branch", conditions = { Class = "MAGE" } },
        { route = "alternate-branch", conditions = { Class = "MAGE" } },
        { route = "alternate-branch", conditions = { Class = "WARRIOR" } },
        "campaign",
        "hidden",
        "temporary",
        "delve",
        "done",
        "future",
        "other-client",
        "faction",
        "class",
        "race",
        "zone",
        "spec",
    }
    route("preferred", "Z preferred", { MinLevel = 13 })
    route("dungeon-leveling", "B dungeon leveling", { MinLevel = 13 }, dungeons, { [APR.PREFAB_TYPES.Dungeons] = 1 })
    route("dungeon-only", "C standalone dungeon", { MinLevel = 13 }, dungeons)
    route("outdoor", "A outdoor", { MinLevel = 12, MaxLevel = 14 })
    route("branch", "Rejected authored branch")
    route("alternate-branch", "Z alternate branch")
    route("campaign", "D campaign", nil, APR.CATEGORIES.Campaign)
    route("future", "Future", { Level = 14 })
    route("faction", "Other faction", { Faction = "Alliance" })
    route("class", "Other class", { Class = "MAGE" })
    route("race", "Other race", { Race = "Tauren" })
    route("zone", "Other zone", { Zones = { 2 } })
    route("spec", "Other spec", { ClassSpec = 72 })
    route("hidden", "Hidden").hiddenFromSelection = true
    route("temporary", "Temporary").temporary = true
    route("delve", "Delve")
    route("done", "Already completed")
    route("alias", "Finished")
    route("unlabelled", "Missing label").label = nil
    route("other-client", "Other client").gameVersion = version == APR.GAME_VERSIONS.Forever
            and APR.GAME_VERSIONS.Retail
        or APR.GAME_VERSIONS.Forever
    -- Available catalog entries must not be inserted without a declared transition.
    route("unlisted-leveling", "Unlisted leveling")
    route("unlisted-dungeon", "Unlisted dungeon", nil, dungeons)
    route("unlisted-import", "Unlisted import").category = nil
    APRZoneCompleted.player[routes.done.label] = true

    expect({ "preferred", "dungeon-leveling", "dungeon-only", "outdoor", "alternate-branch", "campaign" })
    assert(next(APRData.player) == nil and #APRCustomPath.player == 0, "Suggestions must be read-only")
    APR.Level = 12.99
    expect({ "outdoor", "alternate-branch", "campaign" })
    APR.Level = 14
    expect({ "preferred", "dungeon-leveling", "dungeon-only", "outdoor", "alternate-branch", "campaign", "future" })
    APR.Level = 14.99
    expect({ "preferred", "dungeon-leveling", "dungeon-only", "alternate-branch", "campaign", "future" })
    APR.Level = 15
    expect({ "preferred", "alternate-branch", "campaign", "future" })
    APR.Level = 13

    finished.nextRoute[#finished.nextRoute + 1] = { route = "branch", conditions = { Class = "WARRIOR" } }
    expect({ "preferred", "dungeon-leveling", "dungeon-only", "outdoor", "alternate-branch", "campaign", "branch" })
    APRZoneCompleted.player[routes.preferred.label] = true
    expect({ "dungeon-leveling", "dungeon-only", "outdoor", "alternate-branch", "campaign", "branch" })
    APRZoneCompleted.player[routes.preferred.label] = nil

    if version == APR.GAME_VERSIONS.Forever then
        route("gated", "Gated", { MinLevel = 13 }, dungeons).requiredRoute = { "finished" }
        finished.nextRoute[#finished.nextRoute + 1] = "gated"
        expect({ "preferred", "dungeon-leveling", "dungeon-only", "outdoor", "alternate-branch", "campaign", "branch" })
        APRZoneCompleted.player[finished.label] = true
        expect({
            "preferred",
            "dungeon-leveling",
            "dungeon-only",
            "outdoor",
            "alternate-branch",
            "campaign",
            "branch",
            "gated",
        })
    end

    local popup, callbackCount, popupCount = nil, 0, 0
    APR.questionDialog = {
        CreateRouteTriggerPopup = function(_, _, suggestions, selectRoute, cancel)
            popupCount = popupCount + 1
            popup = { suggestions = suggestions, selectRoute = selectRoute, cancel = cancel }
        end,
    }
    local function complete() callbackCount = callbackCount + 1 end
    APRCustomPath.player = { finished.label }
    APR:SuggestNextRoutes("finished", complete)
    assert(popupCount == 1 and callbackCount == 0)
    popup.selectRoute(popup.suggestions[3])
    assert(
        callbackCount == 1 and #APRCustomPath.player == 2 and APRCustomPath.player[2] == routes["dungeon-only"].label,
        "Standalone dungeon selection appends exactly once"
    )
    APR:SuggestNextRoutes("finished", complete)
    assert(popupCount == 1 and callbackCount == 2, "A queued continuation skips the popup")
    APRCustomPath.player = { finished.label }
    APR:SuggestNextRoutes("finished", complete)
    popup.cancel()
    assert(callbackCount == 3 and #APRCustomPath.player == 1, "Cancellation preserves the path")

    if version == APR.GAME_VERSIONS.Retail then
        route("intro", "Required intro", nil, APR.CATEGORIES.Campaign)
        routes.campaign.requiredRoute = { "intro" }
        APR:SuggestNextRoutes("finished", complete)
        popup.selectRoute(popup.suggestions[6])
        assert(
            callbackCount == 4
                and #APRCustomPath.player == 3
                and APRCustomPath.player[2] == routes.intro.label
                and APRCustomPath.player[3] == routes.campaign.label,
            "Choosing a Retail continuation preserves prerequisite insertion"
        )
    end
    APRCustomPath.player = { finished.label }
    APR:SuggestNextRoutes("finished", complete)
    APR.Level = 12
    popup.selectRoute(popup.suggestions[3])
    assert(
        #APRCustomPath.player == 2 and APRCustomPath.player[2] == routes["dungeon-only"].label,
        "An explicit dungeon choice above level 10 remains allowed outside its recommended level"
    )
    assert(#APR:GetRouteLevelWarnings("dungeon-only") == 1)

    -- Missing/empty nextRoute must not reintroduce a broad catalog fallback.
    finished.nextRoute = nil
    expect({})
    finished.nextRoute = {}
    expect({})
    assert(#APR:GetNextRouteSuggestions("missing") == 0)
    local previousPopups, previousCallbacks = popupCount, callbackCount
    APR:SuggestNextRoutes("finished", complete)
    assert(
        popupCount == previousPopups and callbackCount == previousCallbacks + 1,
        "No declared alternatives still finalizes completion"
    )

    -- Equal entry levels do not authorize skipping an authored preparation chapter.
    -- Dungeon alternatives follow the same character branch as their outdoor path.
    APR.RouteQuestStepList = {}
    routes = APR.RouteQuestStepList
    route("start", "Start").nextRoute = {
        { route = "preparation", conditions = { Class = "MAGE" } },
        { route = "plains", conditions = { Class = "HUNTER" } },
        { route = "plains-dungeon", conditions = { Class = "HUNTER" } },
    }
    route("preparation", "Preparation", { Class = "MAGE" }).nextRoute = {
        "forest",
        { route = "forest-dungeon", conditions = { Class = "MAGE" } },
    }
    route("forest", "Forest", { MinLevel = 10 })
    route("forest-dungeon", "Forest dungeon", { MinLevel = 10 }, dungeons)
    route("plains", "Plains", { MinLevel = 10 })
    route("plains-dungeon", "Plains dungeon", { MinLevel = 10 }, dungeons)
    route("aoe", "Separate class path", { MinLevel = 10, Class = "MAGE" })
    APR.ClassName, APR.ClassId, APR.Level = "MAGE", 8, 30
    local starter = APR:GetNextRouteSuggestions("start")
    assert(
        #starter == 1 and starter[1].key == "preparation",
        "Neither a later forest nor the class-specific alternate path may bypass preparation"
    )
    local prepared = APR:GetNextRouteSuggestions("preparation")
    assert(
        #prepared == 2 and prepared[1].key == "forest" and prepared[2].key == "forest-dungeon",
        "The outdoor and dungeon forest become successors at their authored transition"
    )
    APR.ClassName, APR.ClassId = "HUNTER", 3
    starter = APR:GetNextRouteSuggestions("start")
    assert(
        #starter == 2 and starter[1].key == "plains" and starter[2].key == "plains-dungeon",
        "The other class keeps its own outdoor/dungeon branch"
    )
    APR.ClassName, APR.ClassId = "WARRIOR", 1
end

print(
    "Next routes: explicit solo/dungeon choices, eligibility/XP boundaries, branches, completion and callbacks passed"
)
