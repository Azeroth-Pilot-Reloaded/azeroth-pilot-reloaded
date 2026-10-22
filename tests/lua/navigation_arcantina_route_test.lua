-- Real catalogue records with deterministic map projections. The scale below is
-- a test fixture, not a replacement for the client's world geometry.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.faction, fixture.currentMap = "Horde", 2413
fixture.maps[2393].name = "Lune-d'Argent"
fixture.maps[2395].name = "Bois des Chants eternels"
fixture.maps[2541] = { mapID = 2541, mapType = 3, parentMapID = 13, name = "Arcantina" }
local owned, usable, unlocked = true, true, true
PlayerHasToy = function(id) return id == 253629 and owned end
C_QuestLog.IsQuestFlaggedCompleted = function() return false end
C_QuestLog.IsOnQuest = function() return false end
GetAchievementInfo = function(id) return id, "Midnight", 0, id == 42045 and unlocked end
C_Map.GetWorldPosFromMapPos = function(id, point)
    if id == 2541 then return 999, { x = point.x * 100, y = point.y * 100 } end
    -- Put Wayfarer's Rest near the objective, as a distinct arrival from the Rootway.
    return 0, { x = 8485 + (point.x - 0.5641) * 1000, y = -4361 + (point.y - 0.7077) * 1000 }
end
local data = fixture:Load()
local retained = {}
for _, definition in ipairs(data.connections) do
    if definition.id == "portal-harandar-to-silvermoon-city" or definition.id == "item-253629-to-arcantina"
        or definition.id == "arcantina-silvermoon" or definition.id == "portal-silvermoon-city-to-arcantina" then
        retained[#retained + 1] = definition
    end
end
data.connections = retained
function APR:GetRouteActionUsability(kind, id) return kind == "item" and id == 253629 and usable and owned end
data.env.getActionCastSeconds = function() return 3 end
local goal = data:NormalizeLocation({ instanceID = 0, uiMapID = 2393, x = 8485, y = -4361 })
local function Route(distance, speed)
    local start = data:NormalizeLocation({ instanceID = 2694, uiMapID = 2413,
        x = -274.0710144043 + distance, y = -462.61599731445 })
    local edges, metadata = data:BuildEdges({ start = start, playerPosition = start })
    local names = {}
    for _, edge in ipairs(edges) do
        names[edge.id] = edge.instruction
        assert(not edge.id:find("supplement-1095", 1, true), "Retired quest-gated Arcantina duplicate must stay out")
    end
    if unlocked then
        assert(names["retail:portal-harandar-to-silvermoon-city:forward"]:find("Lune-d'Argent", 1, true),
            "The client city name must win over a coarse Eversong projection")
    end
    local search = data:CreateSearch({ start = start, goal = goal, edges = edges, resources = metadata.resources,
        walkSpeed = speed or 7, walkingIsTransitive = true, canWalk = function(a, b) return data:CanWalk(a, b) end })
    while search:Step(32) == "planning" do end
    local result = search:GetResult()
    local transports = {}
    for _, segment in ipairs(result and result.segments or {}) do
        if segment.kind ~= "walk" then transports[#transports + 1] = segment end
    end
    return transports, result, search.status
end

local steps, near = Route(1)
assert(#steps == 1 and steps[1].id == "retail:portal-harandar-to-silvermoon-city:forward", "A nearby direct portal is faster")
steps = Route(2000, 60)
assert(#steps == 2 and steps[1].action.data == 253629 and steps[2].id == "retail:arcantina-silvermoon:forward",
    "The key and exit beat a distant direct portal, even with fast flight")
local viaKey
steps, viaKey = Route(2000, 60)
assert(viaKey.totalSeconds > 13 and viaKey.totalSeconds < 14,
    "Compare cast, two loading estimates, interior approach and final walk; do not assign a preference bonus")
unlocked = false
steps = Route(1)
assert(#steps == 2 and steps[1].action.data == 253629, "A usable key works without this character's portal quests")
usable = false
assert(select(3, Route(1)) == "no_path", "Owned but unusable/on-cooldown toys cannot authorize a journey")
unlocked = true
steps = Route(2000)
assert(#steps == 1 and steps[1].kind == "portal", "A missing key leaves the physical portal as fallback")
owned, usable = false, true
steps = Route(2000)
assert(#steps == 1 and steps[1].kind == "portal")
print("Arcantina: localized city, near/far comparison, account toy, cast/loading/walk costs and unavailable fallback passed")
