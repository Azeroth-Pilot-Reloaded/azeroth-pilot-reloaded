-- Entry policy, adoption and persistence use invented declarations only.
local env = dofile("tests/lua/route_prefab_test_env.lua")
dofile("APR-Core/utils/RouteConditions.lua")
dofile("APR-Core/features/questing/StepTransitions.lua")
local kind, map, spec, quests = APR.PREFAB_TYPES, 81, 71, {}
APR.Race, APR.RaceID, APR.ClassName, APR.ClassId = "Tauren", 6, "DRUID", 11
APR.MinBoostLvl, APR.MaxLevel = 10, 60
function APR:GetPlayerParentMapID() return map end
function APR:CheckRouteChanges() end
C_Map = { GetBestMapForUnit = function() return map end }
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return quests[id] or false end }
C_SpecializationInfo =
    { GetSpecialization = function() return 1 end, GetSpecializationInfo = function() return spec end }
local function starter(key, race, zone)
    local data = env.route(key, "Invented " .. key, { Faction = "Horde", Race = race }, {
        [kind.StartingZone] = 1,
        [kind.Leveling] = 1,
        [kind.Dungeons] = 1,
        [kind.Speedrun] = { index = 1, conditions = { SkipForLvl = 12 } },
    }, APR.CATEGORIES.Leveling)
    data.mapID = zone
    return data
end
local foreign = starter("a-foreign", "Orc", 81)
local original = foreign.conditions
assert(APR:GetRouteVisibility("a-foreign") == "visible" and APR:GetRouteVisibility("a-foreign", true) == "visible")
assert(APR:CanStartRoute("a-foreign") and APR:IsRequiredRouteApplicable("a-foreign"))
assert(foreign.conditions == original and original.Race == "Orc", "Entry policy cannot mutate shared declarations")
foreign.steps[1].Race = "Orc"
foreign.parallelSteps = { { conditions = { Race = "Orc" }, steps = { { Note = "Invented optional action" } } } }
assert(not APR:AreConditionalFiltersMet(foreign.steps[1]))
assert(
    not APR:AreConditionalFiltersMet(foreign.parallelSteps[1].conditions),
    "Step and parallel race filters remain strict"
)
for _, conditions in ipairs({
    { Faction = "Alliance", Race = "Orc" },
    { Race = "Orc" },
    { Faction = "Neutral", Race = "Orc" },
    { Race = "Orc", AnyOf = { { Faction = "Horde" }, { Faction = "Alliance" } } },
    { Race = "Orc", AnyOf = { { Faction = "Horde" }, { Class = "DRUID" } } },
    { Race = "Orc", Not = { Faction = "Alliance" } },
    { Faction = "Horde", Race = "Orc", Class = "MAGE" },
    { Faction = "Horde", Race = "Orc", ClassNot = "DRUID" },
    { Faction = "Horde", Race = "Orc", ClassSpec = 72 },
    { Faction = "Horde", Race = "Orc", AlliedRace = true },
    { Faction = "Horde", Race = "Orc", IsQuestCompleted = 107 },
    { Faction = "Horde", Race = "Orc", MinLevel = 2 },
    { Faction = "Horde", Race = "Orc", MaxLevel = 0.5 },
    { Faction = "Horde", Race = "Orc", Not = { AllOf = { { Race = "Tauren" }, { Class = "DRUID" } } } },
}) do
    foreign.conditions = conditions
    assert(
        not APR:CanStartRoute("a-foreign"),
        "An entry exception cannot bypass a missing/ambiguous faction or a non-racial gate"
    )
end
local nested = {
    AllOf = {
        { Not = { Not = { Faction = "Horde" } } },
        {
            AnyOf = {
                { Race = "Orc", Class = "DRUID", IsQuestCompleted = 107 },
                { Faction = "Alliance", Race = "Human" },
            },
        },
    },
}
foreign.conditions = nested
assert(not APR:CanStartRoute("a-foreign"))
quests[107] = true
assert(APR:CanStartRoute("a-foreign"), "A nested effective faction retains its matching class and quest gate")
APR.ClassName, APR.ClassId = "MAGE", 8
assert(not APR:CanStartRoute("a-foreign"))
APR.ClassName, APR.ClassId = "DRUID", 11
foreign.conditions = { Faction = "Horde", Not = { AnyOf = { { Race = "Tauren" }, { IsQuestCompleted = 107 } } } }
assert(not APR:CanStartRoute("a-foreign"))
quests[107] = nil
assert(APR:CanStartRoute("a-foreign"), "A negated race can be waived without waiving a negated quest")
foreign.conditions = original
APR.Level = 12
foreign.conditions.MinLevel = 13
assert(not APR:CanStartRoute("a-foreign"), "Higher starter levels remain actual entry gates")
foreign.conditions.MinLevel, APR.Level = nil, 1
foreign.conditions.MinLevel, APR.Level = 1.5, 1.49
assert(not APR:CanStartRoute("a-foreign"))
APR.Level = 1.5
assert(APR:CanStartRoute("a-foreign"), "Starter entry retains fractional level boundaries")
foreign.conditions.MinLevel, APR.Level = nil, 1
env.gameVersion = APR.GAME_VERSIONS.Retail
assert(
    APR:GetRouteSelectionConditions("a-foreign", foreign, true) == original,
    "Retail cannot project even directly supplied Forever metadata"
)
local retail = starter("retail", "Orc", 81)
retail.gameVersion, retail.expansion = APR.GAME_VERSIONS.Retail, APR.EXPANSIONS.Vanilla
assert(not APR:CanStartRoute("retail") and APR:GetRouteVisibility("retail") == "hidden")
env.gameVersion = APR.GAME_VERSIONS.Forever
local chapter = env.route("ordinary", "Ordinary invented chapter", { Race = "Orc", Class = "MAGE" })
assert(
    APR:GetRouteSelectionConditions("ordinary", chapter, true) == chapter.conditions,
    "Non-starter recommendation policy stays unchanged"
)

local function reset()
    APR.RouteQuestStepList, APRData.player, APRCustomPath.player, APRZoneCompleted.player = {}, {}, {}, {}
    APR.Level, APR.ActiveRoute, map = 1, nil, 99
    foreign = starter("a-foreign", "Orc", 81)
    local native = starter("z-natural", "Tauren", 82)
    starter("b-unadopted", "Scourge", 83)
    for _, key in ipairs({ "a-foreign", "z-natural", "b-unadopted" }) do
        local finish = env.route(
            key .. "-finish",
            "Invented finish " .. key,
            { Faction = "Horde", MinLevel = 20 },
            { [kind.Leveling] = 2, [kind.Dungeons] = 2, [kind.Speedrun] = { index = 2, endLevel = 60 } },
            APR.CATEGORIES.Leveling
        )
        finish.requiredRoute = key
        APR.RouteQuestStepList[key].nextRoute = { key .. "-finish" }
    end
    return native
end
local function expect(first)
    assert(
        #APRCustomPath.player == 2 and APRCustomPath.player[1] == APR.RouteQuestStepList[first].label,
        "Choose one coherent starting branch: " .. first
    )
    assert(APRCustomPath.player[2] == APR.RouteQuestStepList[first .. "-finish"].label)
    assert(APRData.player.RouteChoices[APRCustomPath.player[1]] == first, "Persist the exact starter")
end
local builders = {
    function() return APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.Forever) end,
    function() return APR.routeconfig:GetSpeedRunPrefab() end,
    function() return APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.Forever, "forever_dungeons", kind.Dungeons) end,
}
for _, build in ipairs(builders) do
    local native = reset()
    assert(build())
    expect("z-natural")
    APRCustomPath.player, APRData.player = {}, {}
    map = 81
    assert(build())
    expect("a-foreign")
    -- A completion receipt alone must not outweigh the newly adopted map.
    APRCustomPath.player, APRData.player = {}, {}
    APRZoneCompleted.player[native.label] = true
    assert(build())
    expect("a-foreign")
    map, APRData.player["a-foreign"], APR.ActiveRoute = 99, 2, "a-foreign"
    assert(build())
    expect("a-foreign")
    assert(APRData.player["a-foreign"] == 2, "Resuming cannot reset progress")
    APR.ActiveRoute = nil
    assert(
        APR:GetRouteKeyFromDisplayName(foreign.label) == "a-foreign" and APR:ActivateRoute("a-foreign"),
        "A saved same-faction starter remains activatable after reload away from its map"
    )
    APR.ActiveRoute, APR.Level = nil, 20
    assert(not APR:CanStartRoute("a-foreign-finish"), "Planning cannot fabricate prerequisite completion")
    APRZoneCompleted.player[foreign.label] = true
    assert(APR:CanStartRoute("a-foreign-finish"))
    assert(APR:GetNextRouteSuggestions("a-foreign")[1].key == "a-foreign-finish")
    APR.RouteQuestStepList["a-foreign"].conditions.Faction = "Alliance"
    assert(not APR:CanStartRoute("a-foreign-finish"), "An incompatible completion cannot satisfy a prerequisite")
end

reset()
map = 81
assert(APR:AddRouteToCustomPathByKey("a-foreign"))
map = 99
assert(APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.Forever))
expect("a-foreign")
reset()
map = 81
foreign.autoStartOnMap, APR.Level = true, 15
APR.routeconfig:GetStartingZonePrefab()
assert(
    #APRCustomPath.player == 1 and APRCustomPath.player[1] == foreign.label,
    "Map auto-start accepts the adopted same-faction starter"
)
APRCustomPath.player, APRData.player = {}, {}
foreign.conditions.Class = "MAGE"
APR.routeconfig:GetStartingZonePrefab()
assert(#APRCustomPath.player == 0, "Map auto-start cannot waive class")

reset()
APR.ClassName, APR.ClassId, map = "MAGE", 8, 81
local mageKey, laterKey = "Forever-MageAoE-fixture-adopted", "Forever-MageAoE-fixture-later"
local mage = starter(mageKey, "Orc", 81)
mage.conditions.Class, mage.nextRoute = "MAGE", { laterKey }
env.route(
    laterKey,
    "Invented mage continuation",
    { Faction = "Horde", Class = "MAGE", MinLevel = 12 },
    { [kind.Leveling] = 2 },
    APR.CATEGORIES.Leveling
)
assert(APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.Forever, "forever_mage_aoe"))
assert(
    #APRCustomPath.player == 2
        and APRCustomPath.player[1] == mage.label
        and APRCustomPath.player[2] == "Invented mage continuation",
    "Explicit AoE scope keeps the adopted Mage branch"
)
local path, choices = APRCustomPath.player, APRData.player.RouteChoices
APR.ClassName, APR.ClassId = "DRUID", 11
assert(not APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.Forever, "forever_mage_aoe"))
assert(
    APRCustomPath.player == path and APRData.player.RouteChoices == choices,
    "A stale class choice cannot erase the existing plan"
)
APR.ClassName, APR.ClassId, APR.Faction = "MAGE", 8, "Alliance"
assert(not APR.routeconfig:BuildLevelingPrefab(APR.EXPANSIONS.Forever, "forever_mage_aoe"))
assert(APRCustomPath.player == path and APRData.player.RouteChoices == choices)
print(
    "Forever starters: race-only entry, faction proof, nested gates, steps, map/natural roots, plans and reload passed"
)
