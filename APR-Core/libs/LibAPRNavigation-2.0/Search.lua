-- Pure Lua 5.1 shortest-path state machine over a prepared, reusable graph.
local _, namespace = ...
local Finite = namespace.NavigationV2Graph.Finite
local Search = {}
Search.__index = Search

-- Lazy decrease-key. A pop or one edge relaxation is one resumable unit.
local function Push(heap, entry)
    local i = #heap + 1
    while i > 1 do
        local parent = math.floor(i / 2)
        if heap[parent].cost <= entry.cost then break end
        heap[i], i = heap[parent], parent
    end
    heap[i] = entry
end

local function Pop(heap)
    local first, last = heap[1], table.remove(heap)
    if #heap == 0 then return first end
    local i = 1
    while i * 2 <= #heap do
        local child = i * 2
        if child < #heap and heap[child + 1].cost < heap[child].cost then child = child + 1 end
        if last.cost <= heap[child].cost then break end
        heap[i], i = heap[child], child
    end
    heap[i] = last
    return first
end

local function Entry(search, node, via, cost, parent, edge)
    while search.objective.via[via + 1] == search.graph.nodes[node] do via = via + 1 end
    return { node = node, via = via, key = via * #search.graph.nodes + node,
        cost = cost, parent = parent, edge = edge }
end

local function Start(search, phase)
    search.phase, search.heap, search.best, search.current = phase, {}, {}, nil
    search.diagnostics.phase = phase
    local entry = Entry(search, search.graph.index[search.objective.from], 0, 0)
    search.best[entry.key] = entry
    Push(search.heap, entry)
end

function Search.New(graph, objective, diagnostics)
    return setmetatable({ graph = graph, objective = objective, diagnostics = diagnostics, validationIndex = 0 }, Search)
end

local function ValidateRequest(search)
    if search.validationIndex == 0 then
        if not search.graph.index[search.objective.from] or not search.graph.index[search.objective.to] then
            return "invalid", "invalid_request"
        end
    else
        local id = search.objective.via[search.validationIndex]
        if not id then search.validationIndex = nil; Start(search, "known"); return end
        if not search.graph.index[id] then return "invalid", "invalid_request" end
    end
    search.validationIndex = search.validationIndex + 1
end

local function Exhausted(search)
    if not search.graph.complete then return "unknown", "incomplete_graph" end
    if search.phase == "known" and search.sawUnknown then Start(search, "possible"); return end
    return "no_path", "disconnected"
end

local function SelectNode(search)
    if #search.heap == 0 then return Exhausted(search) end
    local entry = Pop(search.heap)
    if search.best[entry.key] ~= entry then return end
    search.diagnostics.expanded = search.diagnostics.expanded + 1
    if entry.node == search.graph.index[search.objective.to] and entry.via == #search.objective.via then
        if search.phase == "possible" then return "unknown", "unknown_access" end
        search.total, search.build, search.segments = entry.cost, entry, {}
        search.nodes = { search.graph.nodes[entry.node] }
        return
    end
    search.current, search.edgeIndex = entry, 1
end

local function RelaxEdge(search)
    local edge = search.graph.outgoing[search.current.node][search.edgeIndex]
    if not edge then search.current = nil; return end
    search.edgeIndex = search.edgeIndex + 1
    if edge.access == "unavailable" then return end
    if edge.access == "unknown" and search.phase == "known" then search.sawUnknown = true; return end
    search.diagnostics.relaxed = search.diagnostics.relaxed + 1
    local cost = search.current.cost + edge.seconds
    if not Finite(cost) then return "unknown", "cost_overflow" end
    local candidate = Entry(search, edge.to, search.current.via, cost, search.current, edge)
    local previous = search.best[candidate.key]
    if not previous or cost < previous.cost then
        search.best[candidate.key] = candidate
        Push(search.heap, candidate)
    end
end

local function BuildPath(search)
    local entry, graph = search.build, search.graph
    if not entry.parent then search.build, search.reverseIndex = nil, 1; return end
    local edge = entry.edge
    search.segments[#search.segments + 1] = { edgeId = edge.id, from = graph.nodes[edge.from],
        to = graph.nodes[edge.to], seconds = edge.seconds }
    search.nodes[#search.nodes + 1] = graph.nodes[entry.parent.node]
    search.build = entry.parent
end

local function ReversePath(search)
    local i = search.reverseIndex
    if i > math.floor(#search.nodes / 2) then return "complete", "optimal_known_graph" end
    local opposite = #search.nodes - i + 1
    search.nodes[i], search.nodes[opposite] = search.nodes[opposite], search.nodes[i]
    opposite = #search.segments - i + 1
    if i < opposite then
        search.segments[i], search.segments[opposite] = search.segments[opposite], search.segments[i]
    end
    search.reverseIndex = i + 1
end

function Search:Advance()
    if self.validationIndex then return ValidateRequest(self) end
    if self.build then return BuildPath(self) end
    if self.reverseIndex then return ReversePath(self) end
    if self.current then return RelaxEdge(self) end
    return SelectNode(self)
end

namespace.NavigationV2Search = Search
return Search
