local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
local map = F.map()
local lone = 2 * 8 + 1
local stacked = 3 * 8 + 1
map.grid[1] = string.rep("Q", lone) .. "A" .. string.rep("Q", 63 - lone)
map.height[1] = string.rep("X", 63)
-- The only walkable surface at the first bend is an extra-layer record.
-- It leads onto the lower of two disjoint surfaces at the next bend.
map.floor[1] = F.number(2, 3)
    .. F.number(lone, 3)
    .. "BB"
    .. F.number(2048, 2)
    .. F.number(3, 2)
    .. F.number(stacked, 3)
    .. "BB"
    .. F.number(2068, 2)
    .. "AA"
    .. "AAA"
local provider = F.provider(lib, map)
local path = { F.point(1, 1, 0), F.point(2, 1, 0), F.point(3, 1, 0), F.point(4, 1, 0) }
local status, measured = F.finish(provider:CreatePathJob(F.point(2, 1), path[4], {}))
assert(status == "ready" and measured.path[1].z == 0)
assert(provider:GetGuidanceHeight(F.point(2, 1)) == 0)
assert(provider:GetGuidanceHeight(F.point(3, 1)) == nil)
assert(F.finish(provider:CreatePathJob(F.point(3, 1), path[4], {})) == "unavailable")
for i = 2, #path do
    assert(provider:CanFollowWalkingSegment(path[i - 1], path[i]))
end

local ace = LibStub:NewLibrary("AceLocale-3.0", 1)
function ace:GetLocale() return {} end
local function noop() end
function CreateFrame() return { SetScript = noop, RegisterEvent = noop } end
APR = {
    GAME_VERSIONS = { Forever = "forever" },
    GetGameVersion = function() return "forever" end,
    NewModule = function() return {} end,
    NavigationData = { GetWalkingProvider = function() return provider end },
}
dofile("APR-Core/features/navigation/Navigation.lua")
function APR.navigation:Notify() end
local step = { kind = "walk", path = path, pathCursor = 2, from = path[1], to = path[4] }
APR.navigation:AdvanceWalkingPath(step, F.point(2, 1), provider)
assert(step.pathCursor == 3)
local xy = F.point(3, 1)
APR.navigation:AdvanceWalkingPath(step, xy, provider)
assert(step.pathCursor == 4 and xy.z == nil)
local state, height = F.finish(provider:CreateServiceOriginJob(xy, step), 1)
assert(state == "ready" and height == 0, "The already advanced cursor can still prove its departure surface")
local inside = F.point(3, 1)
inside.x = inside.x + F.cellSize / 4
assert(provider:GetGuidanceHeight(inside) == nil)
local interiorState, interiorHeight = F.finish(provider:CreateServiceOriginJob(inside, step), 1)
assert(interiorState == "ready" and interiorHeight == 0 and inside.z == nil)

-- A declared upper walk which the current raster cannot follow is not evidence.
local stale = { kind = "walk", path = { F.point(3, 1, 20), path[4] }, pathCursor = 2 }
assert(provider:GetWalkingCorridorHeight(xy, stale) == nil)
-- The observed XY is no longer on the single-witness corridor.
local sideways = F.point(3, 1)
sideways.y = sideways.y + 8
assert(provider:GetWalkingCorridorHeight(sideways, step) == nil)

-- Both stacked nodes can reach the unique endpoint. Even an exact XY match
-- with the planned vertex cannot select which one the player is standing on.
map.floor[1] = F.number(1, 3) .. F.number(stacked, 3) .. "BB" .. F.number(2068, 2) .. F.number(1, 2) .. "AAA"
lib:RegisterTerrainData("forever", 900, map, 2)
assert(F.finish(provider:CreatePathJob(path[3], path[4], {})) == "ready")
assert(F.finish(provider:CreatePathJob(F.point(3, 1, 20), path[4], {})) == "ready")
assert(provider:GetWalkingCorridorHeight(xy, step) == nil)

-- The two surfaces diverge before the observed XY. A line follower can
-- select the gentler branch for a planned path, but that cannot identify
-- which of the reachable branches the player actually followed.
local fork = F.map()
fork.floor[1] = F.number(2, 3)
    .. F.number(lone, 3) .. "BB" .. F.number(2068, 2) .. F.number(3, 2)
    .. F.number(stacked, 3) .. "BB" .. F.number(2068, 2) .. F.number(2, 2) .. "AAA"
lib:RegisterTerrainData("forever", 900, fork, 3)
local forkWalk = {kind = "walk", pathCursor = 2, path = {path[1], path[3]}}
assert(F.finish(provider:CreatePathJob(path[1], path[3], {})) == "ready")
assert(F.finish(provider:CreatePathJob(path[1], F.point(3, 1, 20), {})) == "ready")
assert(provider:CanFollowWalkingSegment(path[1], path[3]))
assert(provider:GetWalkingCorridorHeight(xy, forkWalk) == nil)
