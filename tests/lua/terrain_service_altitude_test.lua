local F = dofile("tests/lua/terrain_runtime_fixture.lua")
local lib = F.load()
dofile("APR-Core/libs/LibAPRNavigation-1.0/Search.lua")
dofile("APR-Core/libs/LibAPRNavigation-1.0/Services.lua")

-- Two stacked cells have a base corridor and isolated upper platforms.
local data = F.map()
local function storey(x)
    return F.number(x * 8 + 1, 3) .. "BB" .. F.number(2068, 2) .. "AA"
end
data.floor[1] = F.number(2, 3) .. storey(2) .. storey(5) .. "AAA"
local provider, nav = F.provider(lib, data)
local origin = F.point(2, 1)
local function nearby(offset)
    local point = F.point(2, 1, 0)
    point.x = point.x + offset
    return point
end
local walk = { kind = "walk", pathCursor = 2, path = { nearby(-40), nearby(40) } }
assert(F.finish(provider:CreatePathJob(walk.path[1], walk.path[2], {})) == "ready")
assert(provider:GetGuidanceHeight(origin) == nil)
assert(provider:GetServiceOriginHeight(origin, walk) == 0)
local disconnected = { kind = "walk", path = { F.point(2, 1, 20), F.point(5, 1, 20) } }
assert(provider:GetServiceOriginHeight(origin, disconnected) == nil)
walk.path[1].floor = 4
assert(provider:GetServiceOriginHeight(origin, walk) == nil)
walk.path[1].floor = nil

local function record(x, z, kind, id)
    return { x = x, y = 1, mapID = 90, service = kind, npcID = id, z = z }
end
function nav:NormalizeLocation(p) return F.point(p.x * 100, p.y * 100, p.z) end
function nav:CanWalk(a, b) return a.instanceID == b.instanceID end
function nav:CreateEdgeBuild()
    return { Step = function() return "ready", {}, {} end }
end
local factions = {}
local cost, path = provider.CreateCostJob, provider.CreatePathJob
function provider:CreateCostJob(a, b, context)
    factions[#factions + 1] = assert(context.faction)
    return cost(self, a, b, context)
end
function provider:CreatePathJob(a, b, context)
    factions[#factions + 1] = assert(context.faction)
    return path(self, a, b, context)
end
nav.env.getCharacter = function() return { faction = "Alliance" } end
local function find(records, service, start, active)
    nav.serviceLocations = records
    local job = nav:CreateServiceSearch({
        start = start,
        query = { service = service },
        activeWalk = active,
        character = { faction = "Horde" },
        walkSpeed = 7,
        walkingSpeedCeiling = 7,
    })
    for _ = 1, 20000 do
        local state, result = job:Step(64, 2)
        if state ~= "planning" then return state, result end
    end
    error("unfinished service search")
end
for _, kind in ipairs({ "mailbox", "repair", "inn" }) do
    local xy, observed = record(5, nil, kind, 1), record(5, 0, kind, 2)
    local state, r = find({ xy, observed }, kind, origin, walk)
    assert(state == "ready" and r.record == observed and r.origin.z == 0 and r.target.z == 0)
    F.near(r.totalSeconds, 3 * F.cellSize / 7)
    assert(#r.itinerary.segments[1].path >= 2 and origin.z == nil and xy.z == nil)
    assert(find({ observed }, kind, origin, nil) == "waiting_data")
    assert(find({ xy }, kind, nearby(40), nil) == "waiting_data")
    assert(find({ record(5, 20, kind, 3) }, kind, nearby(40), nil) == "no_path")
end
assert(
    find({ record(2, nil, "inn", 4) }, "inn", origin, nil) == "waiting_data",
    "Identical XY must not establish arrival on an unidentified platform"
)
local state, r = find({ record(12, nil, "inn", 5) }, "inn", nearby(40), nil)
assert(
    state == "ready" and not r.itinerary.segments[1].path,
    "Outside the pack the ordinary authorized estimate retains its provenance"
)
assert(#factions > 0)
for _, faction in ipairs(factions) do
    assert(faction == "Horde")
end

-- A bridge and a lower walkway both continue through the same XY corridor.
-- A planned line on the bridge alone cannot place the player on either deck.
local decks = F.map()
local entries = { F.number(5, 3) }
for x = 1, 5 do
    local links = (x < 5 and 1 or 0) + (x > 1 and 2 or 0)
    entries[#entries + 1] = F.number(x * 8 + 1, 3) .. "BB" .. F.number(2068, 2) .. F.number(links, 2)
end
decks.floor[1] = table.concat(entries) .. "AAA"
lib:RegisterTerrainData("forever", 900, decks, 2)
local function pathState(a, b)
    return F.finish(path(provider, a, b, { faction = "Horde" }))
end
assert(pathState(F.point(1, 1, 0), F.point(5, 1, 0)) == "ready")
assert(pathState(F.point(1, 1, 20), F.point(5, 1, 20)) == "ready")
assert(pathState(F.point(1, 1, 0), F.point(5, 1, 20)) == "no_path")
local bridge = { kind = "walk", path = { nearby(-40), nearby(40) } }
bridge.path[1].z, bridge.path[2].z = 20, 20
assert(find({ record(5, 20, "inn", 7) }, "inn", origin, bridge) == "waiting_data")

-- Ranking compares the physical endpoint on the floor. The NPC above it is
-- within interaction range, so its altitude is not a mandatory climb.
local departure = nearby(40)
local function along(dx, z, id)
    return record((departure.x + dx) / F.cellSize - 0.5, z, "inn", id)
end
local farther, elevated = along(4, 0, 11), along(1, 5, 12)
state, r = find({farther, elevated}, "inn", departure, nil)
assert(state == "ready" and r.record == elevated and r.target.z == 5)
F.near(r.totalSeconds, 1 / 7)
assert(r.itinerary.segments[1].path[2].z == 0)
assert(find({along(1, 6, 13)}, "inn", departure, nil) == "waiting_data",
    "The usual endpoint height tolerance cannot certify a service beyond interaction range")
