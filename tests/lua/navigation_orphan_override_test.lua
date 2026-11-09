-- A verified outdoor override must connect a native Orphan city to a
-- portal whose world coordinates resolve to its parent continent.
local fixture = dofile("tests/lua/navigation_fixture.lua")
for _, profile in ipairs({ "retail", "forever" }) do
    fixture.profile = profile
    fixture.maps[82001] = { mapID = 82001, mapType = 2, parentMapID = 947 }
    fixture.maps[82002] = { mapID = 82002, mapType = 6, parentMapID = 82001 }
    fixture.maps[82003] = { mapID = 82003, mapType = 6, parentMapID = 82001 }
    fixture.maps[82004] = { mapID = 82004, mapType = 5, parentMapID = 82002 }
    fixture.maps[82005] = { mapID = 82005, mapType = 2, parentMapID = 947 }
    local function point(map, world, x)
        return { uiMapID = map, instanceID = world, x = x, y = 0 }
    end
    local start = point(82002, 81, 0)
    local departure = point(82001, 81, 30)
    local arrival = point(82005, 82, 0)
    local goal = point(82005, 82, 40)
    for _, override in ipairs({ false, true }) do
        local data = fixture:Load({
            config = {
                MapTypeOverrides = override and { [82002] = { mapType = 3 } } or {},
                IsolatedAreas = { [82004] = "private-room" },
            },
        })
        assert(data:CanWalk(start, departure) == override)
        assert(not data:CanWalk(start, point(82003, 81, 0)), "Unverified Orphans remain isolated")
        assert(not data:CanWalk(start, point(82004, 81, 0)), "Explicit interiors remain isolated")
        assert(not data:CanWalk(start, point(82001, 83, 0)), "World identity still gates access")
        assert(not data:CanWalk(start, {
            uiMapID = 82001, instanceID = 81, x = 0, y = 0, accessKey = "private",
        }))
        dofile("APR-Core/features/navigation/NavigationPlanner.lua")
        local job = APR.NavigationPlanner:Create({
            start = start,
            goal = goal,
            walkSpeed = 5,
            engine = APR.NavigationEngine,
            data = { BuildEdges = function()
                return { { id = "exit", kind = "portal", from = departure, to = arrival, seconds = 6 } }, {}
            end },
            taxiData = { BuildEdges = function() return {}, {} end },
            canWalk = function(a, b) return data:CanWalk(a, b) end,
            walkingRegionFor = function(p) return data:GetPositionRegion(p) end,
            prepareSegment = function(segment) return segment end,
        })
        local slices = 0
        while job.status == "planning" do
            job:Step(8, 1)
            slices = slices + 1
            assert(slices < 100, "The synthetic crossing must terminate")
        end
        if override then
            local result = job:GetResult()
            assert(job.status == "ready" and #result.queue == 3 and result.totalSeconds == 20)
            assert(result.queue[1].kind == "walk" and result.queue[2].id == "exit"
                and result.queue[3].kind == "walk", "Publish approach, crossing and final walk")
        else
            assert(job.status == "no_path", "A parent alone cannot prove access from an Orphan")
        end
    end
end
print("Native Orphan outdoor overrides: parent portals, planning and access boundaries passed")
