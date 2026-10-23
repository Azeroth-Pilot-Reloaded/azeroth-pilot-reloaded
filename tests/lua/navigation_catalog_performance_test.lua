-- Exercise operation limits with a deterministic clock. Wall-clock timings
-- belong in a benchmark; these assertions should pass on slower test machines.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
for _, name in ipairs({ "Core", "Conditions", "Geography", "Catalog" }) do
    dofile(root .. name .. ".lua")
end
local library = LibStub("LibAPRNavigation-1.0")
local definitions = {}
for index = 1, 100 do
    definitions[index] = {
        id = "shared-action-" .. index,
        kind = "spell",
        from = { dynamic = "player" },
        to = { space = "map", uiMapID = 10, x = index / 100, y = 0.5 },
        bidirectional = index == 1,
        actions = { { type = "spell", id = 7, reagentID = 88 } },
        requirements = { quest = 123, auraSpellID = 456, mapID = 10, minLevel = 40 },
    }
end
library:RegisterData("budget-test", "spells", {
    connections = definitions,
    config = { actionLoadingSeconds = 5 },
})

local state = { quest = true, aura = true, items = 10, castSeconds = 2, clock = 0 }
local calls = {}
local function Count(name)
    calls[name] = (calls[name] or 0) + 1
end
local environment = {
    getCharacter = function()
        Count("character")
        if state.characterMissing then return nil end
        return { level = 40, mapID = 10, inGroup = false }
    end,
    isQuestCompleted = function() Count("quest"); return state.quest end,
    hasAura = function() Count("aura"); return state.aura end,
    getActionUsability = function() Count("usability"); return true end,
    getItemCount = function() Count("inventory"); return state.items end,
    getActionCastSeconds = function() Count("cast"); return state.castSeconds end,
    getSpellName = function() Count("name"); return "Portal" end,
    getText = function() Count("text"); return "%s" end,
    getMapInfo = function(id)
        Count("map:" .. id)
        if state.mapsMissing then return nil end
        return { mapType = id == 1 and 2 or 3, parentMapID = 1, name = "Map " .. id }
    end,
    mapToWorld = function(_, x, y)
        Count("projection")
        return 0, x * 1000, y * 1000
    end,
}
local instance = library:New({ profile = "budget-test", environment = environment })
local context = {
    start = { instanceID = 0, uiMapID = 10, x = 0, y = 0 },
    resources = { external = 3 },
    clock = function()
        state.clock = state.clock + 0.1
        return state.clock
    end,
}

local build = instance:CreateEdgeBuild(context)
assert(calls.character == 1 and calls.quest == nil and calls.projection == nil,
    "Creating a job must not scan definitions or project endpoints")
local status, edges = build:Step(0, 1)
assert(status == "planning" and edges == nil and calls.quest == nil)
status = build:Step(1, 1)
assert(status == "planning" and #build.edges == 1 and build.reverse,
    "A bidirectional connection can yield between its directions")
status = build:Step(1, 1)
assert(status == "planning" and #build.edges == 2 and not build.reverse)
local before = #build.edges
status = build:Step(1000, 1)
assert(status == "planning" and #build.edges > before and #build.edges - before <= 10,
    "Elapsed budget limits a slice even when its operation allowance is large")
while status == "planning" do
    status, edges = build:Step(17, 1)
end
assert(status == "ready" and #edges == 101)
local result, metadata = build:GetResult()
assert(result == edges and metadata.resources.external == 3 and metadata.resources["item:88"] == 10)
assert(context.resources["item:88"] == nil, "Resource collection must not mutate caller input")
assert(calls.quest == 1 and calls.aura == 1 and calls.usability == 1 and calls.inventory == 1)
assert(calls.cast == 1 and calls.name == 1 and calls.text == nil,
    "Repeated actions share API answers only within this build")
assert(calls["map:10"] == 1 and calls["map:1"] == 1,
    "Different positions on the same map share its ancestry and display lookup")
assert(edges[1].seconds == 7 and edges[1].durationSource == "client-cast-estimated-loading")
build:Cancel()
assert(build:GetResult() == edges, "Cancelling a completed build keeps its published result")

-- Planning checks use the same snapshot; retained guidance explicitly asks for
-- fresh state. Unknown map IDs must not inherit the character's current map.
assert(edges[1].canStart(context.start))
state.quest = false
assert(edges[1].canStart(context.start) and not edges[1].canStart(context.start, true))
assert(edges[1].canStart({ instanceID = 0, x = 0, y = 0 }) == nil)
local freshEdges = instance:BuildEdges(context)
assert(#freshEdges == 0, "A later build must observe changed quest state")

state.quest = true
state.characterMissing = true
assert(edges[1].canStart(context.start, true) == nil,
    "A missing live character answer must not reuse a previously known level")
state.characterMissing = false
local cancelled = instance:CreateEdgeBuild(context)
cancelled:Step(2, 1)
cancelled:Cancel()
local previousCalls = calls.quest
status, result = cancelled:Step(1000, 1)
assert(status == "cancelled" and result == nil and calls.quest == previousCalls)

-- Two consumers may build concurrently. Advancing one must not substitute its
-- inventory or quest answers into the other's planning snapshot.
local left = instance:CreateEdgeBuild(context)
left:Step(1, 1)
state.items = 0
local right = instance:CreateEdgeBuild(context)
while right.status == "planning" do right:Step(20, 1) end
while left.status == "planning" do left:Step(20, 1) end
local leftEdges, leftMetadata = left:GetResult()
assert(#leftEdges == 101 and leftMetadata.resources["item:88"] == 10)
assert(#right:GetResult() == 0, "Insufficient reagents remove the action in a fresh build")

-- Empty and unsupported profiles return complete results without special
-- handling in the caller's scheduler.
library:RegisterData("empty", "world", { connections = {} })
local empty = library:New({ profile = "empty", environment = environment }):CreateEdgeBuild(context)
assert(empty:Step() == "ready")
local unsupported = library:New({ profile = "missing", environment = environment }):CreateEdgeBuild(context)
local _, unsupportedEdges, unsupportedMetadata = unsupported:Step()
assert(#unsupportedEdges == 0 and unsupportedMetadata.reason == "unsupported_client")

print("Navigation catalogue performance: incremental construction, operation/time budgets, cancellation, shared API reads and live departure checks passed")
