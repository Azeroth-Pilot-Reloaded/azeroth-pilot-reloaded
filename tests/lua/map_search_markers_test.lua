local fixture = dofile("tests/lua/map_pin_performance_test.lua")
local profile = fixture.profile
local steps = APR:GetRouteSteps()
local step = steps[4]
function APR:GetStepCoord(value) return value.Coord end
step.MapMarkers = { { x = 20, y = 30 }, { x = 40, y = 50 }, { x = 60, y = 70 } }
local originalCoord = step.Coord
local projected = {}
function APR:GetPlayerMapPos(mapID, y, x)
    projected[x .. ":" .. y] = true
    return x / 100, y / 100
end
APR.map:AddMapPins()
assert(#fixture.worldPins() == 8 and #fixture.miniPins() == 5,
    "All search locations appear alongside normal step markers without consuming the step limit")
for _, key in ipairs({ "search-1", "search-2", "search-3" }) do
    local pin = APR.map.pinlist[key]
    assert(pin and pin.step == step and pin.stepIndex == 3,
        "Every search location belongs to the same filtered quest step")
end
assert(projected["20:30"] and projected["40:50"] and projected["60:70"],
    "Every independently authored location is projected using its actual coordinates")
local retained = APR.map.pinlist["search-1"]
APR.map:AddMapPins()
assert(APR.map.pinlist["search-1"] == retained and #fixture.worldPins() == 8,
    "Refreshing reuses the same marker pool without duplicate map pins")
assert(step.Coord == originalCoord and APRData.player.route == 4,
    "Map locations never replace arrow guidance or advance the quest")
APRData.player.route = 5
APR.map:AddMapPins()
assert(#fixture.worldPins() == 5 and #fixture.miniPins() == 2,
    "Search markers disappear when their step is no longer active")
APRData.player.route = 4
profile.minimapshowNextSteps = false
APR.map:AddMapPins()
assert(#fixture.worldPins() == 8 and #fixture.miniPins() == 0)
profile.enableAddon = false
APR.map:AddMapPins()
assert(#fixture.worldPins() == 0 and #fixture.miniPins() == 0)
profile.enableAddon, profile.minimapshowNextSteps = true, true
step.MapMarkers = { { x = 200, y = 30 } }
APR.map:AddMapPins()
assert(#fixture.worldPins() == 5, "Locations projected outside the displayed map are not shown there")
print("Static search locations: simultaneous markers, quest ownership, unchanged arrow/progress and cleanup passed")
