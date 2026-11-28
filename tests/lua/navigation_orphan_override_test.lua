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

-- Retail reports the outdoor garrison maps as Orphans and uses a phased
-- world ID for the player's coordinates. Exercise those client observations
-- against the shipped geography, without depending on any travel catalogue.
fixture.profile = "retail"
fixture.maps[572] = { mapID = 572, mapType = 2, parentMapID = 947 }
local data = fixture:Load()
dofile("APR-Core/utils/NavigationZones.lua")
for _, maps in ipairs({
    { garrison = 582, mine = 579, zone = 539, phase = 1158 },
    { garrison = 590, mine = 585, zone = 525, phase = 1152 },
}) do
    fixture.maps[maps.zone] = { mapID = maps.zone, mapType = 3, parentMapID = 572 }
    fixture.maps[maps.garrison] = { mapID = maps.garrison, mapType = 6, parentMapID = maps.zone }
    fixture.maps[maps.mine] = { mapID = maps.mine, mapType = 5, parentMapID = maps.garrison }
    fixture.player = { instanceID = maps.phase, x = 100, y = 200 }
    local outdoor = { instanceID = 1116, uiMapID = maps.zone, x = 150, y = 200 }
    for _, mapID in ipairs({ maps.garrison, maps.mine }) do
        fixture.currentMap = mapID
        local player = APR:GetNavigationPlayerPosition()
        assert(player and player.uiMapID == mapID and player.instanceID == outdoor.instanceID)
        assert(data:CanWalk(player, outdoor), "The garrison must connect to its outdoor zone: " .. mapID)
        assert(data:CanWalk(outdoor, player), "The outdoor zone must connect back to the garrison: " .. mapID)
    end
end
print("Native Orphan outdoor overrides: parent portals, planning and access boundaries passed")
