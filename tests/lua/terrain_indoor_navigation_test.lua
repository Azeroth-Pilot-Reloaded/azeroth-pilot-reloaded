local F = dofile("tests/lua/terrain_runtime_fixture.lua")

for _, profile in ipairs({ "retail", "forever" }) do
    LibStub = nil
    local lib = F.load()
    if profile == "retail" then
        function GetBuildInfo() return "99.0.0", "1", nil, 990000 end
        assert(lib:MatchesGeneratedTerrain("retail", "99.0.0.1"))
    end
    dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")
    local map = F.map({ class = "E" })
    local cell = 9
    local upperFloor = F.number(1, 3) .. F.number(cell, 3) .. "BB" .. F.number(2068, 2) .. "AAAAA"
    map.floor[1], map.class[1] = upperFloor, map.class[1] .. "E"
    lib:RegisterTerrainData(profile, 900, map, 1)
    local instance = setmetatable({
        profile = profile, env = { getCharacter = function() return { faction = "Alliance" } end },
    }, lib.Instance)
    local provider = assert(instance:GetWalkingProvider())
    function instance:CanWalk(a, b) return a.instanceID == b.instanceID end
    instance.IsSameAccessRegion = instance.CanWalk

    local origin, pin = F.point(1, 1), F.point(1, 1)
    origin.indoors, pin.x = true, pin.x + 24
    origin.uiMapID, pin.uiMapID = 901, 901
    local options = { walkingGoalXY = true, walkingPartialGoal = true }
    local state, result = F.finish(provider:CreatePathJob(origin, pin, options), 1)
    assert(state == "ready" and #result.path == 2)
    assert(result.path[1].z == nil and result.path[2].z == nil)
    F.near(result.yards, 24)
    assert(provider:CanFollowWalkingSegment(origin, result.path[2]))
    assert(F.finish(provider:CreatePathJob(origin, pin, { walkingGoalXY = true }), 1) == "unavailable")

    -- The same XY on another storey cannot satisfy an observed-height target.
    local upperGoal = F.point(1, 1, 20)
    upperGoal.x = pin.x
    assert(F.finish(provider:CreatePathJob(origin, upperGoal, {}), 1) == "unavailable")

    local locale = LibStub:NewLibrary("AceLocale-3.0", 1)
    function locale:GetLocale() return {} end
    local position, context = origin, { service = true }
    local service = { target = pin }
    local function noop() end
    APR = { ActiveRoute = "synthetic", settings = { profile = { enableAddon = true } }, NavigationData = instance,
        GAME_VERSIONS = { Forever = "forever" } }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:IsStepContextCurrent(value) return value == context end
    function APR:GetNavigationPlayerPosition() return position end
    APR.Services = {
        GetStep = function() return service end,
        IsContextCurrent = function(_, value) return value == context end,
        Cancel = function() service = nil end,
    }
    function IsIndoors() return true end
    function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav = APR.navigation
    nav.Notify = noop
    local row = nav:PrepareGuidanceStep({ kind = "walk", from = origin, to = pin, path = result.path }, 1, 1, origin)
    row.arrivalRange = 5
    nav.queue, nav.cursor, nav.state, nav.context = { row }, 1, "guiding", context
    nav:PollArrival()
    assert(nav.state == "guiding" and nav:GetGuidanceTarget() == result.path[2])
    position = pin
    nav:PollArrival()
    assert(not service and position.z == nil)

    -- An indoor observation distinguishes a lower room from an outdoor roof.
    map.class[1] = string.rep("E", 64) .. "A"
    lib:RegisterTerrainData(profile, 900, map, 2)
    assert(F.finish(provider:CreatePathJob(origin, pin, options), 1) == "ready")
    assert(provider:GetWalkingObservationHeight(origin) == 0)

    map.class[1] = string.rep("E", 65)
    map.clearance = { F.number(64, 3) .. F.number(65535, 3) }
    lib:RegisterTerrainData(profile, 900, map, 3)
    assert(F.finish(provider:CreatePathJob(origin, pin, options), 1) == "unavailable")
    assert(not provider:CanFollowWalkingSegment(origin, result.path[2]))

    map.clearance, map.factionCosts = nil, true
    map.class[1] = string.rep("U", 64) .. "E"
    lib:RegisterTerrainData(profile, 900, map, 4)
    assert(F.finish(provider:CreatePathJob(origin, pin, options), 1) == "unavailable")
    assert(not provider:CanFollowWalkingSegment(origin, result.path[2]))
end

print("Indoor navigation: overlapping floors, blocked and hostile chords, observed floor and XY arrival passed")
