-- Invented endpoints only; neither a live route nor an actual player observation.
local ns = {}
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkCase.lua"))("test", ns)
local Capture = ns.NavigationBenchmarkCase.Capture
local function input()
    return { startMode = "manual", from = { mapID = "71", x = "0", y = "100" },
        to = { mapID = 72, x = 25.5, y = 40 } }
end
local function refuses(value, reason, player)
    local case, why = Capture(value, player)
    assert(case == nil and why == reason, tostring(why))
end

local source = input()
local case = assert(Capture(source))
source.from.mapID, source.to.x = 99, 88
local first, second = case:Copy(), case:Copy()
assert(first.coordinateUnit == "map-percent" and first.startMode == "manual")
assert(first.from.mapID == 71 and first.from.x == 0 and first.from.y == 100)
assert(first.to.mapID == 72 and first.to.x == 25.5 and first.to.y == 40)
assert(first.from.identity == nil and first.to.identity == nil)
first.from.x, first.to.mapID = 33, 88
assert(second.from.x == 0 and second.to.mapID == 72)
assert(first ~= second and first.from ~= second.from and first.to ~= second.to)

for _, bad in ipairs({ 0, -1, 2.5, true, "unknown", math.huge }) do
    local value = input(); value.from.mapID = bad
    refuses(value, "benchmark_start_map_invalid")
end
for _, bad in ipairs({ -0.001, 100.001, true, "unknown", math.huge, 0/0 }) do
    local value = input(); value.to.x = bad
    refuses(value, "benchmark_goal_coordinates_invalid")
end
local missing = input(); missing.to.y = nil
refuses(missing, "benchmark_goal_coordinates_invalid")
refuses(nil, "benchmark_input_invalid")
refuses({ startMode = "unobserved" }, "benchmark_mode_invalid")

local calls = 0
local observed = { mapID = 73, x = 12, y = 34,
    identity = { worldID = 0, floorID = 0, phaseID = "observed", spaceID = "room", z = -2 } }
local function player() calls = calls + 1; return observed end
source = input(); source.startMode = "player"; source.from = nil
case = assert(Capture(source, player))
observed.x, observed.identity.floorID = 90, 9
first, second = case:Copy(), case:Copy()
assert(calls == 1 and first.startMode == "player" and first.from.mapID == 73)
assert(first.from.x == 12 and first.from.identity.worldID == 0 and first.from.identity.floorID == 0)
assert(first.from.identity.phaseID == "observed" and first.from.identity.z == -2)
first.from.identity.phaseID = "changed"
assert(second.from.identity.phaseID == "observed" and calls == 1)

source.to.mapID = 0
refuses(source, "benchmark_goal_map_invalid", player)
assert(calls == 1) -- Invalid form does not query native position at all.
source = input(); source.startMode = "player"
refuses(source, "benchmark_player_position_unavailable")
refuses(source, "benchmark_player_position_unavailable", function() return nil end)
refuses(source, "benchmark_player_position_unavailable", function() error("unavailable") end)

case = assert(Capture(source, function() return { mapID = 73, x = 12, y = 34 } end))
assert(case:Copy().from.identity == nil) -- No invented floor, phase, world or altitude.
for _, identity in ipairs({ {worldID=-1}, {floorID=false}, {phaseID=""}, {spaceID=7},
    {z=math.huge}, {unobserved="inferred"} }) do
    local value = input(); value.from.identity = identity
    refuses(value, "benchmark_start_identity_invalid")
end
source = input(); source.to = source.from
case = assert(Capture(source)); first = case:Copy()
assert(first.from ~= first.to and first.from.mapID == first.to.mapID)
print("Benchmark capture: validation, boundaries, immutable paired endpoints, observed identity and one player read passed")
