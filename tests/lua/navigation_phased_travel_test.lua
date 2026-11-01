local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 101
fixture.player = { x = 0, y = 0, instanceID = 9 }
fixture.maps = {
    [947] = { mapType = 0, parentMapID = 0 },
    [100] = { mapType = 2, parentMapID = 947 }, [101] = { mapType = 3, parentMapID = 100 },
    [200] = { mapType = 2, parentMapID = 947 }, [201] = { mapType = 3, parentMapID = 200 },
    [300] = { mapType = 2, parentMapID = 947 }, [301] = { mapType = 3, parentMapID = 300 },
    [302] = { mapType = 3, parentMapID = 301 }, [303] = { mapType = 4, parentMapID = 302 },
}
local mapWorld = { [101] = 9, [201] = 8, [301] = 7, [302] = 70 }
function C_Map.GetWorldPosFromMapPos(map, pos)
    return mapWorld[map], { x = pos.x * 1000, y = pos.y * 1000 }
end
function C_Map.GetMapPosFromWorldPos(world)
    assert(world ~= 70, "World projections must use the canonical coordinate space")
    return world == 7 and 301 or world == 8 and 201 or 101, {}
end
local catalog = { config = { WorldInstanceOverrides = { [70] = 7 } }, connections = {
    { id = "fortress-recall", routeAction = "UseGarrisonHS", kind = "item", from = { dynamic = "player" },
        to = { space = "map", uiMapID = 302, x = 0.5, y = 0.5 },
        actions = { { type = "item", id = 61 } }, requirements = { faction = "Horde", quest = 901 } },
    { id = "direct-gateway", kind = "portal", seconds = 5,
        from = { instanceID = 9, uiMapID = 101, x = 30, y = 0 },
        to = { instanceID = 7, uiMapID = 301, x = 100, y = 500 }, requirements = { quest = 902 } },
    { id = "detour-start", kind = "portal", seconds = 5,
        from = { instanceID = 9, uiMapID = 101, x = 20, y = 0 },
        to = { instanceID = 8, uiMapID = 201, x = 0, y = 0 } },
    { id = "detour-end", kind = "portal", seconds = 5,
        from = { instanceID = 8, uiMapID = 201, x = 3000, y = 0 },
        to = { instanceID = 7, uiMapID = 301, x = 100, y = 500 } },
} }
local data = fixture:Load(catalog)
dofile("APR-Core/utils/PlayerUtils.lua")
local owned, usable, cooling, built, gateway = true, true, false, true, true
function PlayerHasToy(id) return id == 61 and owned end
C_ToyBox = { IsToyUsable = function() return usable end }
function C_Item.GetItemCount() return 0 end
function C_Item.IsUsableItem() return usable end
function C_Item.GetItemCooldown() return cooling and 1 or 0, cooling and 3600 or 0, 1 end
function C_QuestLog.IsQuestFlaggedCompleted(id) return (id == 901 and built) or (id == 902 and gateway) end
local goal = { instanceID = 7, uiMapID = 301, x = 600, y = 500 }
local function plan()
    local start = APR.NavigationAdapter.environment.getPlayerPosition()
    local edges, coverage = data:BuildEdges({ start = start, playerPosition = start, goal = goal })
    local search = data:CreateSearch({ start = start, goal = goal, edges = edges, resources = coverage.resources,
        walkSpeed = 7, canWalk = function(a, b) return data:CanWalk(a, b) end })
    local status, result
    repeat status, result = search:Step(1000) until status ~= "planning"
    assert(status == "ready", "A complete permitted route must exist")
    return result
end
local result = plan()
assert(result.segments[1].action and result.segments[1].action.data == 61,
    "An available toy-only fortress recall beats the longer physical gateways")
assert(result.segments[1].to.instanceID == 7 and result.segments[1].to.uiMapID == 302,
    "The recall lands in the phased map using the outdoor world's coordinate space")
local recallSeconds = result.totalSeconds
cooling = true
result = plan()
assert(result.segments[2].id == "retail:direct-gateway:forward" and result.totalSeconds > recallSeconds,
    "A cooling recall falls back to the faster complete physical gateway route")
cooling, built = false, false
result = plan()
assert(result.segments[2].id == "retail:direct-gateway:forward",
    "Account-wide toy ownership cannot bypass a missing character fortress unlock")
built, usable = true, false
assert(plan().segments[2].id == "retail:direct-gateway:forward", "Native unusability also rejects the recall")
owned, usable = false, true
assert(plan().segments[2].id == "retail:direct-gateway:forward", "An unowned recall cannot enter the plan")
gateway = false
result = plan()
assert(result.segments[2].id == "retail:detour-start:forward",
    "A permitted longer fallback is considered only when the shorter gateways are unavailable")

local raw = { instanceID = 70, uiMapID = 302, x = 500, y = 500, region = "70:300:outdoor" }
local normalized = data:NormalizeLocation(raw)
assert(raw.instanceID == 70 and raw.region == "70:300:outdoor", "Normalization never mutates an observation")
assert(normalized.instanceID == 7 and data:CanWalk(normalized, goal) and data:CanWalk(raw, goal),
    "Both observed and projected phase identities share the verified outdoor world")
assert(not data:CanWalk({ instanceID = 71, uiMapID = 302, x = 500, y = 500 }, goal),
    "An undeclared instance is never connected by matching coordinates")
assert(not data:CanWalk({ instanceID = 70, uiMapID = 303, x = 500, y = 500 }, goal),
    "An indoor map remains isolated even inside a declared phased world")
assert(not data:CanWalk(data:NormalizeLocation({ instanceID = 70, uiMapID = 302, x = 500, y = 500,
    region = "sealed-host-region" }), goal), "A host's explicit region cannot be erased by world normalization")
normalized.accessKey = "sealed"
assert(not data:CanWalk(normalized, goal), "World equivalence does not remove explicit access restrictions")
fixture.player, fixture.currentMap = { instanceID = 70, x = 500, y = 500 }, 302
assert(APR.NavigationAdapter.environment.getPlayerPosition().instanceID == 7,
    "The native player boundary uses the same world identity as graph destinations")
dofile("APR-Core/utils/Utils.lua")
function APR:Debug() end
dofile("APR-Core/utils/NavigationZones.lua")
assert(APR:GetNavigationPlayerPosition().instanceID == 7,
    "APR's live navigation position normalizes phased arrivals as well")
dofile("APR-Core/features/navigation/Preview.lua")
assert(APR.navigationPreview:GetMapInstance(302) == 7)
local projected = APR.navigationPreview:Point({ Coord = { x = 500, y = 500, mapID = 302, instanceID = 70 } })
assert(projected.instanceID == 7, "Authored and native map previews share the normalized world identity")
function APR:NewModule() return {} end
function APR:GetCurrentRouteMapIDsAndName() return {302}, 302 end
function APR:GetStepCoord(step) return step.Coord, 302 end
dofile("APR-Core/features/navigation/Navigation.lua")
local phasedStep = { Coord = { x = 500, y = 500, mapID = 302, instanceID = 70 } }
assert(APR.navigation:GetDestination(phasedStep).instanceID == 7 and phasedStep.Coord.instanceID == 70,
    "Runtime routing normalizes authored destinations without altering the guide")

-- Hidden interactions require an explicit approach, not a walk through a wall.
fixture.locale, fixture.currentMap = "frFR", 101
fixture.player = { instanceID = 9, x = 0, y = 0 }
local chamber = { instanceID = 9, uiMapID = 101, x = 200, y = 0, noAutoconnect = true }
local entrance = { instanceID = 9, uiMapID = 101, x = 100, y = 0 }
data = fixture:Load({ connections = {
    { id = "cave-approach", kind = "passage", costMode = "ground", from = entrance, to = chamber,
        instructionKey = "NAVIGATION_ENTER_UNDERWATER_CAVE" },
    { id = "hidden-crossing", kind = "portal", seconds = 5, from = chamber, to = goal,
        instructionKey = "NAVIGATION_USE_CAMPFIRE" },
} })
result = plan()
assert(#result.segments == 4 and result.segments[2].kind == "passage"
    and result.segments[3].kind == "portal", "The cave entrance precedes the hidden crossing")
assert(result.segments[2].instruction:find("grotte sous-marine", 1, true)
    and result.segments[3].instruction:find("chaise", 1, true)
    and result.segments[3].instruction:find("feu bleu", 1, true),
    "Localized interaction instructions replace the misleading ordinary portal label")
assert(not data:CanWalk(entrance, chamber), "Automatic geometry cannot bypass the explicit cave approach")
print("Phased travel: usable toy recall, locked/cooling/missing fallbacks, native arrivals, isolated interiors and explicit hidden interactions passed")
