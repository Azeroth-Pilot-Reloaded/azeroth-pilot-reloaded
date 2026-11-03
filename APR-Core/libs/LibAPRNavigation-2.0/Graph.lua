-- Pure Lua 5.1 input boundary. One declaration is validated/copied per Advance.
local _, namespace = ...
local Graph, Preparation = {}, {}
Preparation.__index = Preparation
local MAX_VIA = 64
Graph.SAFE_INTEGER = 9007199254740991

function Graph.Finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function Identifier(value)
    return type(value) == "string" and value ~= ""
end

local function ArrayKey(value)
    return Graph.Finite(value) and value >= 1 and value % 1 == 0
end

-- Request capture is capped independently of graph size, even for malformed
-- tables with a huge number of extra fields. Node references are checked later.
function Graph.CaptureRequest(request)
    if type(request) ~= "table" or not Identifier(request.from) or not Identifier(request.to) then return nil end
    local source = request.via
    if source == nil then source = {} end
    if type(source) ~= "table" then return nil end
    local via, cursor, count, maximum = {}, nil, 0, 0
    for _ = 1, MAX_VIA + 1 do
        local key, id = next(source, cursor)
        if key == nil then
            if count ~= maximum then return nil end
            return { from = request.from, to = request.to, via = via }
        end
        if not ArrayKey(key) or key > MAX_VIA or not Identifier(id) then return nil end
        count, maximum, cursor, via[key] = count + 1, math.max(maximum, key), key, id
    end
end

function Graph.New(source)
    if type(source) == "table" and source.partitioned == true then
        if not namespace.NavigationV2Sectors then return nil, "sectors_unavailable" end
        local graph, reason = namespace.NavigationV2Sectors.New(source)
        if not graph then return nil, reason end
        return setmetatable({ phase = "ready", compiled = graph }, Preparation)
    end
    if type(source) ~= "table" or type(source.complete) ~= "boolean"
        or type(source.nodes) ~= "table" or type(source.edges) ~= "table" then return nil, "invalid_graph" end
    return setmetatable({ sourceNodes = source.nodes, sourceEdges = source.edges,
        phase = "prepare_nodes", count = 0, maximum = 0, seen = {},
        compiled = { complete = source.complete, nodes = {}, index = {}, outgoing = {} } }, Preparation)
end

local function Node(preparation, key, id)
    local graph = preparation.compiled
    if not Identifier(id) or graph.index[id] then return "invalid_node" end
    graph.nodes[key], graph.index[id], graph.outgoing[key] = id, key, {}
end

local function Edge(preparation, _, declaration)
    if type(declaration) ~= "table" or not Identifier(declaration.id) or preparation.seen[declaration.id] then
        return "invalid_edge"
    end
    local graph = preparation.compiled
    local from, to = graph.index[declaration.from], graph.index[declaration.to]
    local access = declaration.access
    if access == nil then access = "available" end
    if not from or not to or not Graph.Finite(declaration.seconds) or declaration.seconds < 0
        or (access ~= "available" and access ~= "unavailable" and access ~= "unknown") then return "invalid_edge" end
    preparation.seen[declaration.id] = true
    local movement
    if declaration.movement ~= nil then
        if not namespace.NavigationV2Forever then return 'movement_unavailable' end
        movement = namespace.NavigationV2Forever.CaptureMovement(declaration.movement)
        if not movement then return 'invalid_movement' end
    end
    local resources
    if declaration.resources ~= nil then
        resources = namespace.NavigationV2Resources.Capture(declaration.resources)
        if not resources then return 'invalid_edge_resources' end
        graph.resourceCosts = true
    end
    local outgoing = graph.outgoing[from]
    outgoing[#outgoing + 1] = { id = declaration.id, from = from, to = to,
        seconds = declaration.seconds, access = access, movement = movement, resources = resources }
end

local function AdvanceArray(preparation, source, copy)
    local key, value = next(source, preparation.cursor)
    if key == nil then
        if preparation.count ~= preparation.maximum then return nil, "invalid_graph" end
        return true
    end
    if not ArrayKey(key) then return nil, "invalid_graph" end
    local reason = copy(preparation, key, value)
    if reason then return nil, reason end
    preparation.count = preparation.count + 1
    preparation.maximum, preparation.cursor = math.max(preparation.maximum, key), key
    return false
end

function Preparation:Advance()
    if self.reason then return "invalid", self.reason end
    if self.phase == "ready" then return "ready" end
    local nodes = self.phase == "prepare_nodes"
    local done, reason = AdvanceArray(self, nodes and self.sourceNodes or self.sourceEdges, nodes and Node or Edge)
    if done and nodes and self.count == 0 then reason = "invalid_graph" end
    if reason then
        self.reason, self.compiled, self.sourceNodes, self.sourceEdges, self.seen = reason, nil, nil, nil, nil
        return "invalid", reason
    end
    if done then
        self.cursor, self.count, self.maximum = nil, 0, 0
        if nodes then
            self.phase, self.sourceNodes = "prepare_edges", nil
        else
            self.phase, self.sourceEdges, self.seen = "ready", nil, nil
            return "ready"
        end
    else
        return nodes and "node" or "edge"
    end
end

namespace.NavigationV2Graph = Graph
return Graph
