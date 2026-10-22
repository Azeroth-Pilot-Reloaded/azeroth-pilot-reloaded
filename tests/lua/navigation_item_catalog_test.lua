-- Exercise the shipped catalogue with real toy checks and the real search.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local owned, usable = { [253629] = true }, true
function PlayerHasToy(id) return owned[id] == true end
C_ToyBox = { IsToyUsable = function() return usable end }
C_Item.IsUsableItem = function() return true end
C_Item.GetItemCooldown = function() return 0, 0, 1 end
fixture.currentMap = 2512
local data = fixture:Load()
dofile("APR-Core/utils/PlayerUtils.lua")
local start = { x = 100, y = 200, instanceID = 0, uiMapID = 2512 }
local context = { start = start, playerPosition = start, walkSpeed = 7 }
local edges, metadata = data:BuildEdges(context)
local key, exitPortal
for _, edge in ipairs(edges) do
    if edge.action and edge.action.data == 253629 then key = edge end
    if edge.from.uiMapID == 2541 and edge.to.uiMapID == 2393 then exitPortal = edge end
end
assert(key and key.to.uiMapID == 2541 and exitPortal,
    "The Arcantina key lands inside the tavern and a separate owned-key portal reaches Silvermoon")
assert(not data:CanWalk(key.to, exitPortal.to), "Arcantina cannot autoconnect to the outside walking graph")

local search = APR.NavigationEngine:CreateSearch({
    start = start, goal = exitPortal.to, edges = edges, walkSpeed = 7,
    budget = 0, resources = metadata.resources,
    canWalk = function(from, to) return data:CanWalk(from, to) end,
})
local status, result
repeat status, result = search:Step(4096, 1) until status ~= "planning"
assert(status == "ready", "The learned toy provides a route from Coiled Isle to Silvermoon")
local usedKey, usedExit = false, false
for _, segment in ipairs(result.segments) do
    if segment.action and segment.action.data == 253629 then usedKey = true end
    if segment.from.uiMapID == 2541 and segment.to.uiMapID == 2393 then usedExit = true end
end
assert(usedKey and usedExit, "The shortest route retains both the toy and the physical exit portal")

usable = nil
edges, metadata = data:BuildEdges(context)
assert(metadata.waitingData, "Unknown character toy usability keeps planning neutral")
for _, edge in ipairs(edges) do
    assert(not edge.action or edge.action.data ~= 253629, "Unknown usability cannot publish a toy action")
end

usable, owned = true, { [172924] = true, [48933] = true }
fixture.items[167075], fixture.items[184500], fixture.items[184501], fixture.items[252607] = 1, 1, 1, 1
edges, metadata = data:BuildEdges(context)
local shadowlands, northrend, consumables = 0, 0, {}
for _, edge in ipairs(edges) do
    local itemID = edge.action and edge.action.data
    if itemID == 172924 then shadowlands = shadowlands + 1 end
    if itemID == 48933 then northrend = northrend + 1 end
    if itemID == 167075 or itemID == 184500 or itemID == 184501 or itemID == 252607 then
        consumables[itemID] = edge
        assert(edge.resources["item:" .. itemID] == 1 and metadata.resources["item:" .. itemID] == 1,
            "A consumable itinerary must reserve one real inventory item")
    end
    assert(not (edge.action and edge.to.x == 5000 and edge.to.y == 5000),
        "Owned wormholes must not reuse fabricated zone-centre landings")
end
assert(shadowlands == 5 and northrend == 3, "Only sourced fixed wormhole choices are exposed")
assert(consumables[167075] and consumables[184500] and consumables[184501] and consumables[252607],
    "New consumable destinations are available to characters carrying them")
assert(consumables[184500].resources["cooldown:attendants-pocket-portal"] == 1
    and consumables[184501].resources["cooldown:attendants-pocket-portal"] == 1,
    "One journey cannot spend several pocket portals as if their cooldowns were independent")
print("Navigation items: Arcantina two-leg route, fixed wormhole choices, toy gates and consumable budgets passed")
