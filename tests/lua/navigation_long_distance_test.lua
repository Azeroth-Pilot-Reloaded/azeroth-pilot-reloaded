-- Exercise APR's zone dispatch as well as the shortest-time search. The search
-- alone already finds these shortcuts; the host must actually let it run.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 2512
fixture.spells[3563], fixture.spells[3567] = true, true
fixture.maps[2512] = { mapType = 3, parentMapID = 2537 }
fixture.maps[2537] = { mapType = 2, parentMapID = 947 }
fixture.maps[85] = { mapType = 3, parentMapID = 12 }
local portalOpen = true
C_QuestLog.IsQuestFlaggedCompleted = function() return portalOpen end
C_QuestLog.IsOnQuest = function() return false end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return portalOpen end
-- Deterministic projections anchored to the real catalogue's travel points.
-- These are geometry fixtures, not measurements of live portal loading times.
C_Map.GetWorldPosFromMapPos = function(map, pos)
    if map == 2393 then
        return 0, { x = 8016.7 + (pos.x - 0.5683) * 1000,
            y = -4577.6 + (pos.y - 0.6738) * 1000 }
    end
    if map == 85 then return 1, { x = 1445.21, y = -4499.56 } end
    return 0, { x = pos.x * 10000, y = pos.y * 10000 }
end
C_Map.GetMapPosFromWorldPos = function(instance, pos)
    if instance == 1 then return 85, {} end
    if pos.x > 7000 then return 2393, {} end
    if pos.x > 4000 then return 2512, {} end
    return 18, {}
end
local data = fixture:Load()
local wanted = {
    ["spell-3563-teleport-undercity"] = true,
    ["spell-3567-teleport-orgrimmar"] = true,
    ["coiled-isle-to-astalor"] = true,
    ["portal-silvermoon-city-to-orgrimmar"] = true,
    ["portal-kalimdor-to-eastern-kingdoms-at-1842-minus-4389-arrive-1947-minus-98"] = true,
}
local connections = {}
for _, definition in ipairs(data.connections) do
    if wanted[definition.id] then connections[#connections + 1] = definition end
end
assert(#connections == 5, "Use the real mage teleports and Horde portal chain")
data.connections = connections
data.env.getActionCastSeconds = function() return 10 end
dofile("APR-Core/features/navigation/NavigationPlanner.lua")
local start = data:NormalizeLocation({ instanceID = 0, uiMapID = 2512,
    x = 5498.2001953125, y = -12742.600585938, z = 0 })
local goal = data:NormalizeLocation({ instanceID = 0, uiMapID = 25, x = 6.3, y = -929.8 })
assert(data:CanWalk(start, goal), "Reproduce two distant points in the same Eastern Kingdoms region")
local preparationCalls, taxiCalls = 0, 0
local function plan(origin, destination, speed)
    local job = APR.NavigationPlanner:Create({
        preferZoneAccess = true, data = data, engine = data,
        start = origin or start, playerPosition = origin or start, goal = destination or goal,
        walkSpeed = speed or 60, walkingIsTransitive = true,
        canWalk = function(a, b) return data:CanWalk(a, b) end,
        walkingRegionFor = function(point) return data:GetPositionRegion(point) end,
        adapter = { CreatePreparation = function()
            preparationCalls = preparationCalls + 1
            return { Step = function() return "ready" end }
        end },
        taxiData = { BuildEdges = function() taxiCalls = taxiCalls + 1; return {} end },
        prepareSegment = function(segment) return segment end,
    })
    local slices = 0
    repeat
        job:Step(8, 1)
        slices = slices + 1
        assert(slices < 1000, "Long-distance comparisons remain scheduled and bounded")
    until job.status ~= "planning"
    assert(job.status == "ready")
    local transports = {}
    for _, segment in ipairs(job.result.queue) do
        if segment.kind ~= "walk" then transports[#transports + 1] = segment end
    end
    return job, transports
end
local mage, route = plan()
assert(#route == 1 and route[1].action and route[1].action.data == 3563,
    "The reported 13,027-yard flight must compare and prefer the mage's Undercity teleport")
assert(mage.zoneFallback and not mage.zoneRouted and mage.result.totalSeconds < 70)
assert(preparationCalls == 1 and taxiCalls == 1, "APR must reach the full comparison pipeline")

fixture.spells[3563] = nil
local viaCapital
viaCapital, route = plan()
assert(#route == 2 and route[1].action.data == 3567 and route[2].kind == "portal",
    "A mage without Undercity can teleport to Orgrimmar and take its portal")

fixture.spells[3567] = nil
UnitClassBase = function() return "Warrior", 1 end
local nonMage
nonMage, route = plan()
assert(#route == 3 and route[1].id == "retail:coiled-isle-to-astalor:forward"
    and route[2].id == "retail:portal-silvermoon-city-to-orgrimmar:forward"
    and route[3].id:find("arrive%-1947%-minus%-98:forward$"),
    "Without personal teleports, use Silvermoon, Orgrimmar and Undercity before final flight")
assert(nonMage.result.queue[#nonMage.result.queue].to == goal
    and nonMage.result.totalSeconds < 130, "Include the final movement to Hillsbrad in the comparison")

portalOpen = false
fixture.faction = "Alliance" -- Neither the Horde portals nor personal teleports are available.
local direct
direct, route = plan()
assert(#route == 0 and math.abs(direct.result.totalSeconds - 217.11698423661) < 0.001,
    "Direct flight remains available when every shortcut is unavailable")

-- Local objectives retain the cheap route. Long trips on the very same map
-- must still compare transports, even at skyriding speed.
local priorPreparation, priorTaxi = preparationCalls, taxiCalls
local near = { instanceID = 0, uiMapID = 2512, x = start.x + data.config.threshold, y = start.y }
local localTrip = plan(start, near)
assert(localTrip.zoneRouted and preparationCalls == priorPreparation and taxiCalls == priorTaxi,
    "Nearby objectives keep direct guidance without catalogue, taxi or inn scans")
near.x = near.x + 1
local farther = plan(start, near)
assert(farther.zoneFallback and preparationCalls == priorPreparation + 1 and taxiCalls == priorTaxi + 1,
    "The local shortcut has a distance limit even inside one map")
local grounded = plan(start, goal, 7)
assert(grounded.zoneFallback, "Ground travel must also compare long-distance alternatives")
print("Long-distance APR planning: reported Coiled Isle/Hillsbrad mage teleport, Orgrimmar fallback, physical portal chain, unavailable shortcuts and bounded local dispatch passed")
