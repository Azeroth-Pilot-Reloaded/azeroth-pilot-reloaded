-- Movement state is part of a location; only an explicit edge changes it.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
for _, name in ipairs({ "Core", "Geography", "Search", "Terrain", "LocalRouting" }) do dofile(root .. name .. ".lua") end
local lib = LibStub("LibAPRNavigation-1.0")
local instance = lib:New({ profile = "fixture", environment = {} })
local function point(x, mode)
    return { instanceID = 8, uiMapID = 18, region = "outside", x = x, y = 0, z = 100, movementMode = mode }
end
local function finish(job)
    for _ = 1, 20000 do
        local state, result = job:Step(5, 1)
        assert((job.workLastStep or 0) <= 5, "mode-aware routing remains cooperative")
        if state ~= "planning" then return state, result end
    end
    error("movement search did not finish")
end
local sky, ground, destination = point(0, "skyriding"), point(0, "ground"), point(1000, "ground")
local portal = { from = ground, to = destination, kind = "portal", seconds = 5 }
local state = finish(instance:CreateSearch({ start = sky, goal = destination, edges = { portal },
    canWalk = function() return false end }))
assert(state == "no_path", "an airborne arrival cannot alias a ground portal departure")

local landing = { from = sky, to = ground, kind = "walk", terrain = true, movementMode = "ground", seconds = 3 }
local result
state, result = finish(instance:CreateSearch({ start = sky, goal = destination, edges = { portal, landing },
    canWalk = function() return false end }))
assert(state == "ready" and result.totalSeconds == 8 and #result.segments == 2,
    "an explicit landing restores the portal itinerary and its cost")

state = finish(instance:CreateSearch({ start = sky, goal = ground }))
assert(state == "no_path", "default walking cannot change mode at identical coordinates")
state = finish(instance:CreateSearch({ start = sky, goal = point(10, "ground"), canWalk = function() return true end }))
assert(state == "no_path", "a permissive host walking predicate cannot replace a mode transition")
state, result = finish(instance:CreateSearch({ start = point(0), goal = ground }))
assert(state == "ready" and result.totalSeconds == 0, "legacy untyped endpoints retain ground identity")

-- Source-free actions remain explicit transitions, subject to their host predicates.
state, result = finish(instance:CreateSearch({ start = sky, goal = destination,
    edges = { { from = ground, to = destination, kind = "teleport", seconds = 5, sourceFree = true } },
    canWalk = function() return false end }))
assert(state == "ready" and result.totalSeconds == 5)

local observed = point(0)
local profile = { currentMode = "skyriding", canSkyriding = true }
state = finish(instance:CreateSearch({ start = observed, goal = destination, edges = { portal },
    movementProfile = profile, canWalk = function() return false end }))
assert(state == "no_path", "an untyped observed start uses its supplied current movement mode")
local observedLanding = { from = observed, to = ground, kind = "walk", seconds = 3 }
state, result = finish(instance:CreateSearch({ start = observed, goal = destination,
    edges = { portal, observedLanding }, movementProfile = profile, canWalk = function() return false end }))
assert(state == "ready" and result.totalSeconds == 8 and observed.movementMode == nil,
    "connector endpoints share effective start identity without mutating caller data")
assert(instance:NormalizeLocation(sky).movementMode == "skyriding", "normalization preserves explicit movement state")

-- Standalone local routing forwards the same current mode into its search.
lib:RegisterTerrainData("fixture", 8, { format = 1, nodes = {
    { id = "air", instanceID = 8, uiMapID = 18, region = "outside", x = 0, y = 0, z = 100, movementMode = "skyriding" },
    { id = "ground", instanceID = 8, uiMapID = 18, region = "outside", x = 0, y = 0, z = 100 },
}, edges = {} }, 1, "modes")
state = finish(instance:CreateLocalRoute({ start = observed, goal = ground, movementProfile = profile }))
assert(state == "no_path", "local routing cannot complete an unproved landing at the current position")
lib:RegisterTerrainData("fixture", 8, { format = 1, nodes = {
    { id = "air", instanceID = 8, uiMapID = 18, region = "outside", x = 0, y = 0, z = 100, movementMode = "skyriding" },
    { id = "ground", instanceID = 8, uiMapID = 18, region = "outside", x = 0, y = 0, z = 100 },
}, edges = { { from = "air", to = "ground", mode = "ground", transitionSeconds = 3 } } }, 2, "modes")
state, result = finish(instance:CreateLocalRoute({ start = observed, goal = ground, movementProfile = profile }))
assert(state == "ready" and result.totalSeconds == 3, "local routing preserves an explicit landing cost")
print("Movement identity: explicit transitions, host walking guards, current mode and normalized endpoints passed")
