-- Alternative actions belong to the catalogue's per-frame work budget too.
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
for _, module in ipairs({ "Core", "Conditions", "Geography", "Catalog" }) do dofile(root .. module .. ".lua") end
local library = LibStub("LibAPRNavigation-1.0")
local options = {}
for index = 1, 500 do options[index] = { type = "spell", id = 1000 + index } end
library:RegisterData("selection-budget", "actions", { connections = {
    { id = "many-alternatives", kind = "spell", bidirectional = true, actions = options,
        from = { space = "world", instanceID = 0, uiMapID = 10, x = 0, y = 0 },
        to = { space = "world", instanceID = 0, uiMapID = 10, x = 200, y = 0 } },
} })
local state = { clock = 0, cost = 0.25, probes = 0, available = { [1500] = true } }
local data = library:New({ profile = "selection-budget", environment = {
    getCharacter = function() return { level = 10, mapID = 10 } end,
    getActionUsability = function(_, id)
        state.probes, state.clock = state.probes + 1, state.clock + state.cost
        if state.pending then return false, "pending_data" end
        return state.available[id] == true
    end,
    getMapInfo = function(id) return { mapID = id, parentMapID = id == 10 and 1 or 0, mapType = id == 10 and 3 or 2 } end,
    getActionCastSeconds = function() return 2 end,
    getSpellName = function(id) return "Synthetic spell " .. id end,
    random = function(count) state.randomCount = count; return 4 end,
} })
local context = { clock = function() return state.clock end }
local function finish(build, operationLimit)
    local status, edges, metadata
    local slices = 0
    repeat
        local before = state.probes
        status, edges, metadata = build:Step(operationLimit or 1000, 1)
        assert(state.probes - before <= 4, "An action catalogue slice obeys its 1 ms native-query budget")
        if operationLimit then assert(state.probes - before <= operationLimit) end
        slices = slices + 1; assert(slices < 2000, "The action selection must eventually finish")
    until status ~= "planning"
    assert(status == "ready")
    return edges, metadata
end

local build = data:CreateEdgeBuild(context)
assert(state.probes == 0)
assert(build:Step(1000, 1) == "planning" and state.probes <= 4,
    "One large action list cannot hide hundreds of native queries inside a single definition operation")
state.available[1001] = true
local edges = finish(build)
assert(state.probes == 500 and #edges == 2 and edges[1].action.data == 1500 and edges[2].action.data == 1500,
    "Both directions share the first selection and retain already-observed false answers")
local before = state.probes
edges = finish(data:CreateEdgeBuild(context))
assert(state.probes == before + 1 and edges[1].action.data == 1001,
    "A fresh build sees a newly usable higher-priority action")

state.available = { [1500] = true }
build = data:CreateEdgeBuild(context)
before = state.probes
assert(build:Step(0, 1) == "planning" and state.probes == before)
assert(build:Step(1, 0) == "planning" and state.probes == before)
assert(build:Step(1, 100) == "planning" and state.probes == before,
    "Preparing a long selection yields before the first native action query")
assert(build:Step(1, 100) == "planning" and state.probes == before + 1,
    "An operation allowance of one probes at most one alternative")
build:Cancel()
before = state.probes
assert(build:Step(1000, 100) == "cancelled" and state.probes == before and not build.preparation,
    "Cancellation releases the suspended selector and performs no more native work")

data.connections[1].selection = "random"
for index = 1, 500 do state.available[1000 + index] = index % 2 == 1 end
before = state.probes
edges = finish(data:CreateEdgeBuild(context), 3)
assert(state.probes == before + 500 and state.randomCount == 250
    and edges[1].action.data == 1007 and edges[2].action.data == 1007,
    "Random selection still considers every usable alternative exactly once and shares the chosen action")
state.available = {}
local metadata
edges, metadata = finish(data:CreateEdgeBuild(context))
assert(#edges == 0 and #metadata.blockedActionEdges == 2 and not metadata.waitingData,
    "A completely rejected alternative list retains both diagnostic directions")
state.pending = true
edges, metadata = finish(data:CreateEdgeBuild(context))
assert(#edges == 0 and metadata.waitingData, "Unavailable native action data retains its retryable status")

data.connections[1].actions, data.connections[1].bidirectional = { options[1] }, false
state.pending, state.available = false, { [1001] = true }
build = data:CreateEdgeBuild(context)
before = state.probes
local status = build:Step(1, 1)
assert(status == "ready" and state.probes == before + 1 and not build.preparation,
    "Ordinary single-action definitions preserve direct preparation without an extra coroutine")
print("Catalogue action budgets: long alternatives, time/operation slices, shared selection, randomness and cancellation passed")
