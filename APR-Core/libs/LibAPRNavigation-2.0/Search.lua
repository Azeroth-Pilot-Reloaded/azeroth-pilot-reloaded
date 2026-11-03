-- Pure Lua 5.1 shortest-path state machine over a prepared, reusable graph.
local _, namespace = ...
local Finite = namespace.NavigationV2Graph.Finite
local SAFE_INTEGER = namespace.NavigationV2Graph.SAFE_INTEGER
local Search = {}
Search.__index = Search

local function Before(a, b)
    return a.rank < b.rank or (a.rank == b.rank and a.cost > b.cost)
end

-- Lazy decrease-key. A pop or one edge relaxation is one resumable unit.
local function Push(heap, entry)
    local i = #heap + 1
    while i > 1 do
        local parent = math.floor(i / 2)
        if not Before(entry, heap[parent]) then break end
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
        if child < #heap and Before(heap[child + 1], heap[child]) then child = child + 1 end
        if not Before(heap[child], last) then break end
        heap[i], i = heap[child], child
    end
    heap[i] = last
    return first
end

local function Entry(search, node, via, cost, parent, edge, milliseconds)
    local id = search.graph.partitioned and node or search.graph.nodes[node]
    while search.objective.via[via + 1] == id do via = via + 1 end
    local key = search.graph.partitioned and (via..'\0'..node) or (via * #search.graph.nodes + node)
    local rank = cost
    if milliseconds then
        rank = milliseconds
        if milliseconds <= SAFE_INTEGER - 4294967295 then rank = rank + search.graph:Estimate(search, node) end
    end
    return { node = node, via = via, key = key, rank = rank, milliseconds=milliseconds,
        cost = cost, parent = parent, edge = edge }
end

local function Locate(graph, id)
    if graph.partitioned then return graph:Locate(id) end
    return graph.index[id]
end

local function NodeId(graph, node)
    return graph.partitioned and node or graph.nodes[node]
end

local function Start(search, phase)
    search.phase, search.heap, search.best, search.current = phase, {}, {}, nil
    search.diagnostics.phase = phase
    local entry = Entry(search, Locate(search.graph, search.objective.from), 0, 0, nil, nil,
        search.graph.integerCosts and 0 or nil)
    search.best[entry.key] = entry
    Push(search.heap, entry)
end

function Search.New(graph, objective, diagnostics)
    return setmetatable({ graph = graph, objective = objective, diagnostics = diagnostics, validationIndex = 0 }, Search)
end

local function ValidateRequest(search)
    local id
    if search.validationIndex == 0 then id = search.objective.from
    elseif search.validationIndex == 1 then id = search.objective.to
    else id = search.objective.via[search.validationIndex - 1] end
    if not id then
        if search.graph.PrepareRequest then
            local ready, status, reason = search.graph:PrepareRequest(search)
            if not ready then if status ~= 'running' then return status, reason end; return end
        end
        search.validationIndex = nil
        if search.build then return end
        Start(search, "known"); return
    end
    local node, status, reason = Locate(search.graph, id)
    if not node then return status or "invalid", reason or "invalid_request" end
    search.validationIndex = search.validationIndex + 1
end

local function Exhausted(search)
    if search.sawMissing then return "unknown", search.sawMissing end
    if not search.graph.complete or search.sawIncomplete then return "unknown", "incomplete_graph" end
    if search.phase == "known" and search.sawUnknown then Start(search, "possible"); return end
    return "no_path", "disconnected"
end

local function ExpandNode(search, entry)
    if entry.node == Locate(search.graph, search.objective.to) and entry.via == #search.objective.via then
        if search.phase == "possible" then return "unknown", "unknown_access" end
        search.total, search.build, search.segments = entry.cost, entry, {}
        search.nodes = { NodeId(search.graph, entry.node) }
        return
    end
    search.current, search.edgeIndex = entry, 1
end

local function SelectNode(search)
    if #search.heap == 0 then return Exhausted(search) end
    local entry = Pop(search.heap)
    if search.best[entry.key] ~= entry then return end
    search.diagnostics.expanded = search.diagnostics.expanded + 1
    if search.graph.partitioned then search.selected = entry; return end
    return ExpandNode(search, entry)
end

local function Missing(search, status, reason)
    if status == 'unknown' then search.sawMissing = reason; return end
    return status, reason
end

local function LoadSelected(search)
    local entry, status, reason = search.graph:Ensure(search, search.selected.node)
    if status == 'running' then return end
    local selected = search.selected
    search.selected = nil
    if not entry then return Missing(search, status, reason) end
    if search.graph.Refine then
        local rank = search.graph:Refine(search, selected, entry)
        if rank > selected.rank then selected.rank = rank; Push(search.heap, selected); return end
    end
    return ExpandNode(search, selected)
end

local function RelaxEdge(search)
    local edge, status, reason
    if search.graph.partitioned then
        edge, status, reason = search.graph:ReadEdge(search, search.current.node, search.edgeIndex)
    else edge = search.graph.outgoing[search.current.node][search.edgeIndex] end
    if status == 'running' then return end
    if status then search.current = nil; return Missing(search, status, reason) end
    if not edge then search.current = nil; return end
    search.edgeIndex = search.edgeIndex + 1
    if edge.access == "unavailable" then return end
    if edge.access == "unknown" and search.phase == "known" then search.sawUnknown = true; return end
    search.diagnostics.relaxed = search.diagnostics.relaxed + 1
    local milliseconds = search.current.milliseconds and (search.current.milliseconds + edge.milliseconds)
    if milliseconds and milliseconds > SAFE_INTEGER then return 'unknown', 'cost_overflow' end
    local cost = milliseconds and milliseconds / 1000 or (search.current.cost + edge.seconds)
    if not Finite(cost) then return "unknown", "cost_overflow" end
    local candidate = Entry(search, edge.to, search.current.via, cost, search.current, edge, milliseconds)
    local previous = search.best[candidate.key]
    local value = milliseconds or cost
    if not previous or value < (previous.milliseconds or previous.cost) then
        search.best[candidate.key] = candidate
        Push(search.heap, candidate)
    end
end

local function BuildPath(search)
    local entry, graph = search.build, search.graph
    if not entry.parent then search.build, search.reverseIndex = nil, 1; return end
    local edge = entry.edge
    search.segments[#search.segments + 1] = { edgeId = edge.id, from = NodeId(graph, edge.from),
        to = NodeId(graph, edge.to), seconds = edge.seconds }
    search.nodes[#search.nodes + 1] = NodeId(graph, entry.parent.node)
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
    if self.selected then return LoadSelected(self) end
    if self.current then return RelaxEdge(self) end
    return SelectNode(self)
end

function Search:Cancel()
    if self.loading and self.loading.job then self.loading.job:Cancel() end
    self.loading = nil
end

namespace.NavigationV2Search = Search
return Search
