local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Geography.lua")

function GetBuildInfo() return "99.0.0", "1", "", 990000 end
local frame = 1
function GetTime() return frame end
assert(lib:MatchesGeneratedTerrain("retail", "99.0.0.1"))

local world, map = 900, 60
local families = {
    Alliance = { mapID = 61, levels = { 910, 911, 912 } },
    Horde = { mapID = 62, levels = { 920, 921, 922 } },
}
local config = { WorldInstanceOverrides = {}, GarrisonPhases = { world = world, garrisonType = 7,
    Alliance = families.Alliance, Horde = families.Horde } }
local base = F.map()
base.nx = 3
for _, field in ipairs({ "grid", "height", "class" }) do
    base[field][2], base[field][3] = base[field][1], base[field][1]
end
local function portal(cell)
    return F.number(cell, 3) .. "AAAB"
end
local function link(direction, destination)
    return F.number(direction, 1) .. F.number(destination, 2)
        .. string.rep(F.number(67, 3), 3) .. F.number(67, 2)
end
base.graph = {
    "AB" .. portal(60) .. link(7, 0),
    "AC" .. portal(4) .. portal(60) .. link(1, 0) .. link(7, 0),
    "AB" .. portal(4) .. link(1, 1),
}
lib:RegisterTerrainData("retail", world, base, 1)

-- All plans use the same world coordinates. Each tier has a different
-- surface in the middle, while the unmodified border matches the parent.
for _, family in pairs(families) do
    for level, id in ipairs(family.levels) do
        config.WorldInstanceOverrides[id] = world
        local tile = F.map({ wall = level == 3 })
        tile.cx0 = family == families.Horde and 2 or 0
        local heights = {}
        for x = 0, 7 do
            for y = 0, 7 do
                if level ~= 3 or x ~= 3 or y == 7 then
                    local border = x == 0 or x == 7 or y == 0 or y == 7
                    local height = border and 0 or level * 2
                    heights[#heights + 1] = "v" .. F.number(2048 + height, 2)
                end
            end
        end
        tile.height[1] = table.concat(heights)
        lib:RegisterTerrainData("retail", id, tile, 1)
    end
end

local faction, level = "Alliance", 1
local owner = setmetatable({ profile = "retail", config = config, env = {
    getCharacter = function() return { faction = faction } end,
    getGarrisonLevel = function(kind) assert(kind == 7); return level end,
} }, lib.Instance)
local provider = assert(owner:GetWalkingProvider())
local function path(from, to)
    local state, result = F.finish(provider:CreatePathJob(from, to, { walkSpeed = 7 }), 53)
    assert(state == "ready", state)
    for _, vertex in ipairs(result.path) do assert(vertex.instanceID == world) end
    return result.path
end

for _, name in ipairs({ "Alliance", "Horde" }) do
    faction = name
    local offset = name == "Horde" and 16 or 0
    for tier = 1, 3 do
        level, frame = tier, frame + 1
        local from, to = F.point(offset + 2, 2), F.point(offset + 5, 2)
        local vertices = path(from, to)
        local height = assert(vertices[1].z)
        assert(height == tier * 2 and vertices[#vertices].z == height)
        if tier == 3 then assert(#vertices > 2, "The tier-three wall requires a detour") end
        local explicit = owner:NormalizeLocation({ space = "world", x = from.x, y = from.y,
            instanceID = families[name].levels[tier] })
        assert(explicit.instanceID == world and explicit.terrainPhase == families[name].levels[tier])
        assert(explicit.uiMapID == families[name].mapID)
        assert(owner:NormalizeLocation(explicit).terrainPhase == explicit.terrainPhase)
        assert(provider:GetGuidanceHeight(explicit) == height)
    end
end

faction, level, frame = "Alliance", 1, frame + 1
local inner, outer = F.point(6, 4), F.point(8, 4)
for _, pair in ipairs({ { inner, outer }, { outer, inner } }) do
    local vertices = path(pair[1], pair[2])
    local crossings = 0
    for i = 2, #vertices do
        local a, b = vertices[i - 1], vertices[i]
        assert(a.x ~= b.x or a.y ~= b.y, "Crossing vertices must advance the path")
        if b.phaseBoundary then
            crossings = crossings + 1
            assert(b.mandatory)
        end
        assert(provider:CanFollowWalkingSegment(a, b))
        assert(F.finish(provider:CreateWalkingSegmentJob(a, b)) == "ready")
    end
    assert(crossings == 1)
    local state, result = F.finish(provider:CreateCostJob(pair[1], { pair[2] }, { walkSpeed = 7 }))
    assert(state == "ready" and result.costs[1].state == "ready")
    F.near(result.costs[1].yards, F.cellSize + math.sqrt(F.cellSize^2 + 2^2))
end

local inside = F.point(2, 2)
local tierOneHeight = path(inside, F.point(2, 3))[1].z
local observed = owner:NormalizeLocation({ instanceID = families.Alliance.levels[1],
    uiMapID = families.Alliance.mapID, x = inside.x, y = inside.y })
level = 2
owner:InvalidatePositionCache()
local tierTwoHeight = path(inside, F.point(2, 3))[1].z
assert(tierTwoHeight > tierOneHeight)
assert(path(observed, F.point(2, 3))[1].z == tierOneHeight)

local function flightClearance(tier)
    level, frame = tier, frame + 1
    local status, route = F.finish(provider:CreatePathJob(outer, inside, {
        flight = { origin = outer, speed = 65, climbSpeed = 40, canFly = function() return true end },
    }))
    assert(status == "ready")
    return route.path.flight.climb
end
assert(flightClearance(2) > flightClearance(1), "Flight must sample the selected tier's surface")

level, frame = nil, frame + 1
assert(path(inside, F.point(2, 3))[1].z == 0)
assert(provider:RequiresWalkingProof(inside, outer))
assert(not provider:RequiresWalkingProof(inside, { instanceID = 999, x = outer.x, y = outer.y }))

-- The native phase survives the host's normal world normalization, including
-- before the native map has loaded and while the character API is unreadable.
APR = { NavigationData = owner }
local rawWorld, nativeMap = families.Alliance.levels[1], nil
function UnitPosition() return inside.x, inside.y, 0, rawWorld end
function GetInstanceInfo() return "Fixture", "party", nil, nil, nil, nil, nil, rawWorld end
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
C_Map = { GetBestMapForUnit = function() return nativeMap end }
dofile("APR-Core/utils/NavigationZones.lua")
local position = assert(APR:GetNavigationPlayerPosition())
assert(position.instanceID == world and position.terrainPhase == rawWorld)
assert(position.uiMapID == families.Alliance.mapID and not position.isInstance)
rawWorld, nativeMap = world, map
position = assert(APR:GetNavigationPlayerPosition())
assert(position.instanceID == world and not position.terrainPhase and position.uiMapID == map)
