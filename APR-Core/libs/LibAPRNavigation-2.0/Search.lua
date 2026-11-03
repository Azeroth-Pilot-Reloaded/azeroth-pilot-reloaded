-- Pure Lua 5.1 shortest-path state machine over a prepared, reusable graph.
local _, namespace = ...
local Finite = namespace.NavigationV2Graph.Finite
local SAFE_INTEGER = namespace.NavigationV2Graph.SAFE_INTEGER
local Search = {}
local Resources = namespace.NavigationV2Resources
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

local function Entry(search, node, via, cost, parent, edge, milliseconds, mode)
    local id = search.graph.partitioned and node or search.graph.nodes[node]
    while search.objective.via[via + 1] == id do via = via + 1 end
    local key = search.graph.partitioned and (via..'\0'..node) or (via * #search.graph.nodes + node)
    if mode then key = key..'\0'..mode end
    local atStart=not parent or edge.unlockEntry and parent.atStart or false
    local assumed,planState
    if search.planUnlocks then
        assumed,planState=parent and parent.assumed or {},parent and parent.planState or string.rep('0',#search.planUnlocks.entries)
        if edge and edge.unlockEntry then assumed,planState=search.planUnlocks:Activate(parent,edge.unlockEntry) end
        key=key..'\0'..planState
        if search.movement then key=key..(atStart and '\0origin' or '\0travelled') end
    end
    local rank = cost
    if milliseconds then
        rank = milliseconds
        if not search.dynamic and milliseconds <= SAFE_INTEGER - 4294967295 then
            rank = rank + search.graph:Estimate(search, node)
        end
    end
    return { node = node, via = via, key = key, rank = rank, milliseconds=milliseconds,
        cost = cost, parent = parent, edge = edge, mode = mode,assumed=assumed,planState=planState,
        atStart=atStart }
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
        not search.dynamic and search.graph.integerCosts and 0 or nil,
        search.movement and search.movement.initialMode)
    if search.resources then entry.spent={};entry.cooldowns={};search.best[entry.key]={entry} else search.best[entry.key] = entry end
    Push(search.heap, entry)
end

function Search.New(graph, objective, diagnostics, options)
    options = options or {}
    return setmetatable({ graph = graph, objective = objective, diagnostics = diagnostics,
        portals = options.portals, movement = options.movement, scheduled = options.scheduled, taxi = options.taxi,
        personal=options.personal, cooldowns=options.personal and options.personal.cooldowns,
        conditions=options.conditions,
        resources = (options.taxi or options.personal or graph.resourceCosts or options.resources or options.planUnlocks) and (options.resources or {}),
        planUnlocks=options.planUnlocks,planSnapshot=options.planUnlocks and options.conditions.tracker.snapshot,
        planBindings=options.planUnlocks and {},
        dynamic = options.portals or options.movement or options.scheduled or options.taxi or options.personal or graph.resourceCosts or options.resources
            or options.planUnlocks or (options.conditions and options.conditions.conditional),
        deniedFacts=options.conditions and options.conditions.unlockProofs and {},
        requestProof=options.conditions and options.conditions.unlockProofs and {},
        startedAt = options.startedAt, validationIndex = 0 }, Search)
end

local function RecordDenial(search,proof)
    if proof and proof.blocker and not proof.conflict and not proof.unknown then
        search.deniedFacts[proof.blocker]=search.deniedFacts[proof.blocker] or proof
    end
end

local function ValidateRequest(search)
    local id
    if search.validationIndex == 0 then id = search.objective.from
    elseif search.validationIndex == 1 then id = search.objective.to
    else id = search.objective.via[search.validationIndex - 1] end
    if not id then
        if search.requestDenied then
            RecordDenial(search,search.requestProof)
            search.provenNoPath=search.graph.complete and not search.requestUnknown and not search.conditionUnknown
            return 'no_path',search.requestDenied
        end
        if search.requestUnknown then return 'unknown',search.requestUnknown end
        if search.movement and not search.movement.initialMode then return 'unknown', 'movement_state_unknown' end
        if not search.dynamic and search.graph.PrepareRequest then
            local ready, status, reason = search.graph:PrepareRequest(search)
            if not ready then if status ~= 'running' then return status, reason end; return end
        end
        search.validationIndex = nil
        if search.build then return end
        Start(search, "known"); return
    end
    local node, status, reason = Locate(search.graph, id)
    if not node then return status or "invalid", reason or "invalid_request" end
    if search.conditions and search.conditions.conditional and (not search.planUnlocks or search.validationIndex==0) then
        local access,why=namespace.NavigationV2Graph.NodeAccess(search.graph,node,search,search.requestProof)
        if access=='unavailable' then search.requestDenied=search.requestDenied or why
        elseif access=='unknown' then search.requestUnknown=search.requestUnknown or why end
    end
    search.validationIndex = search.validationIndex + 1
end

local function Exhausted(search)
    if search.sawMissing then return "unknown", search.sawMissing end
    if not search.graph.complete or search.sawIncomplete then return "unknown", "incomplete_graph" end
    if search.phase == "known" and search.sawUnknown then Start(search, "possible"); return end
    search.provenNoPath=not search.sawUnknown and not search.conditionUnknown
    return "no_path", "disconnected"
end

local function ExpandNode(search, entry)
    if entry.node == Locate(search.graph, search.objective.to) and entry.via == #search.objective.via then
        if search.phase == "possible" then return "unknown", "unknown_access" end
        search.total, search.build, search.segments = entry.cost, entry, {}
        search.resourcesSpent={}
        search.nodes = { NodeId(search.graph, entry.node) }
        return
    end
    search.current, search.edgeIndex = entry, 1
    search.portalIndex, search.scheduledIndex = search.portals and 1, search.scheduled and 1
    search.taxiIndex = search.taxi and 1
    search.personalIndex=search.personal and 1
    search.unlockIndex=search.planUnlocks and 1
end

local function SelectNode(search)
    if #search.heap == 0 then return Exhausted(search) end
    local entry = Pop(search.heap)
    if search.resources then if entry.dominated then return end
    elseif search.best[entry.key] ~= entry then return end
    search.diagnostics.expanded = search.diagnostics.expanded + 1
    if search.graph.partitioned then search.selected = entry; return end
    return ExpandNode(search, entry)
end

local function Missing(search, status, reason)
    if status == 'unknown' then search.sawMissing = reason; return end
    return status, reason
end

local function LoadSelected(search)
    -- Dynamic arcs invalidate the atlas's potentials/witnesses, while its
    -- audited adjacency pages remain useful. Do not even decode a stale bound.
    if search.dynamic and search.graph.routing then
        local selected = search.selected
        search.selected = nil
        return ExpandNode(search, selected)
    end
    local entry, status, reason = search.graph:Ensure(search, search.selected.node)
    if status == 'running' then return end
    local selected = search.selected
    search.selected = nil
    if not entry then return Missing(search, status, reason) end
    if not search.dynamic and search.graph.Refine then
        local rank = search.graph:Refine(search, selected, entry)
        if rank > selected.rank then selected.rank = rank; Push(search.heap, selected); return end
    end
    return ExpandNode(search, selected)
end

local function Access(a, b)
    if a == 'unavailable' or b == 'unavailable' then return 'unavailable' end
    if a == 'unknown' or b == 'unknown' then return 'unknown' end
    return 'available'
end

local function ScheduledEdge(search)
    local transition, transitionReason
    if search.movement then
        local reason
        transition, reason = search.movement:Evaluate({seconds=0,access='available'},
            search.current.mode, search.current.atStart)
        if not transition then transitionReason = reason
        elseif transition.transitionSeconds == nil then transitionReason = 'movement_transition_unknown' end
    end
    local arrival = not transitionReason and search.startedAt
        and search.startedAt + search.current.cost + (transition and transition.seconds or 0)
    local edge, reason = search.scheduled:Edge(NodeId(search.graph, search.current.node),search.scheduledIndex,arrival)
    search.scheduledIndex = search.scheduledIndex + 1
    if not edge and not reason then search.scheduledIndex = nil; return nil, 'running' end
    if transitionReason or reason then return nil, 'unknown', transitionReason or reason end
    if transition then
        edge.seconds = edge.seconds + transition.seconds
        edge.mode, edge.transitionSeconds = transition.mode, transition.transitionSeconds
        edge.access = Access(edge.access, transition.access)
    end
    return edge
end

-- Each overlay item, row load or base edge is one existing search operation.
local function ReadEdge(search)
    local edge, status, reason
    local overlay = search.unlockIndex or search.portalIndex or search.scheduledIndex or search.taxiIndex or search.personalIndex
    if search.unlockIndex then
        local done
        edge,done=search.planUnlocks:Edge(search,NodeId(search.graph,search.current.node),search.unlockIndex)
        search.unlockIndex=search.unlockIndex+1
        if done then search.unlockIndex=nil end
        if not edge then return nil,'running' end
    elseif search.portalIndex then
        edge = search.portals:Edge(NodeId(search.graph, search.current.node), search.portalIndex)
        search.portalIndex = search.portalIndex + 1
        if not edge then search.portalIndex = nil; return nil, 'running' end
    elseif search.scheduledIndex then
        edge, status, reason = ScheduledEdge(search)
    elseif search.taxiIndex then
        edge, reason = search.taxi:Edge(NodeId(search.graph, search.current.node),search.taxiIndex)
        search.taxiIndex = search.taxiIndex+1
        if reason then return nil,'unknown',reason end
        if not edge then search.taxiIndex=nil;return nil,'running' end
    elseif search.personalIndex then
        edge=search.personal:Edge(NodeId(search.graph,search.current.node),search.personalIndex)
        search.personalIndex=search.personalIndex+1
        if not edge then search.personalIndex=nil;return nil,'running' end
    elseif search.graph.partitioned then
        edge, status, reason = search.graph:ReadEdge(search, search.current.node, search.edgeIndex)
    else edge = search.graph.outgoing[search.current.node][search.edgeIndex] end
    if status then
        if not overlay and status ~= 'running' then search.current = nil end
        return nil, status, reason
    end
    if not edge then search.current = nil; return end
    if overlay then
        local to, locateStatus, locateReason = Locate(search.graph, edge.to)
        if not to then return nil, locateStatus or 'invalid', locateReason or 'invalid_transport_node' end
        edge.to, edge.from = to, search.current.node
    else search.edgeIndex = search.edgeIndex + 1 end
    return edge
end

-- A single comparison per operation keeps Pareto labels inside job budgets.
local function Dominates(search,a,b)
    if not Resources.Dominates(a,b) then return false end
    return not search.cooldowns or namespace.NavigationV2Cooldowns.Dominates(search.cooldowns,
        a.cooldowns,b.cooldowns,search.startedAt+b.cost)
end

local function CompareLabel(search)
    local pending = search.pending
    local previous = pending.row[pending.index]
    if previous then
        pending.index = pending.index+1
        if not previous.dominated and Dominates(search,previous,pending.entry) then search.pending=nil;return end
        return
    end
    if pending.prune then
        pending.row[#pending.row+1]=pending.entry
        Push(search.heap,pending.entry)
        search.pending=nil
    else pending.prune=true;pending.index=1 end
end

local function PruneLabel(search)
    local pending = search.pending
    local previous = pending.row[pending.index]
    if previous then
        pending.index=pending.index+1
        if Dominates(search,pending.entry,previous) then previous.dominated=true end
    else CompareLabel(search) end
end

local function MovementEdge(search, edge)
    if not search.movement or edge.kind == 'scheduled' or edge.kind=='unlock' then return edge end
    -- Generated terrain seconds already include static mode changes. They do
    -- not prove geometry/mode and must not be reinterpreted as walking distance.
    if search.graph.partitioned and not edge.kind and not edge.movement then
        return nil, 'movement_metadata_missing'
    end
    local evaluated, reason = search.movement:Evaluate(edge,search.current.mode,search.current.atStart)
    if not evaluated then return nil, reason end
    local copy = {}
    for key, value in pairs(edge) do copy[key] = value end
    copy.seconds, copy.access, copy.mode = evaluated.seconds, evaluated.access, evaluated.mode
    copy.transitionSeconds = evaluated.transitionSeconds
    return copy
end

local function RelaxEdge(search)
    local edge, status, reason = ReadEdge(search)
    if status == 'running' then return end
    if status then return Missing(search, status, reason) end
    if not edge then return end
    if edge.kind=='personal' then edge.access=edge.forecastAccess end
    local rawAccess,proof=edge.access,search.deniedFacts and {}
    if proof and rawAccess=='unknown' then proof.unknown=true;search.conditionUnknown=true end
    if search.conditions and search.conditions.conditional then
        -- Prepared adjacency is shared across requests. A denied/unknown live
        -- conjunction must never overwrite its immutable authored access.
        local captured={}
        for key,value in pairs(edge) do captured[key]=value end
        edge=captured
        local from=namespace.NavigationV2Graph.NodeAccess(search.graph,edge.from,search,proof)
        local to=namespace.NavigationV2Graph.NodeAccess(search.graph,edge.to,search,proof)
        edge.access=namespace.NavigationV2Graph.CombineAccess(edge.access,
            namespace.NavigationV2Graph.CombineAccess(from,to))
        local transport=search.conditions.transports[edge.kind]
        local binding=edge.condition or transport and transport[edge.portalId or edge.transportId or edge.taxiId or edge.personalId]
        if binding then
            local access=namespace.NavigationV2Graph.ConditionAccess(search.graph,binding,search,proof)
            edge.access=namespace.NavigationV2Graph.CombineAccess(edge.access,access)
        end
    end
    if edge.access == "unavailable" then
        if rawAccess=='available' then RecordDenial(search,proof) end
        return
    end
    edge, reason = MovementEdge(search, edge)
    if not edge then return Missing(search, 'unknown', reason) end
    if edge.access == "unavailable" then return end
    local cooldowns=search.current.cooldowns
    if edge.kind=='personal' then
        if search.movement and edge.transitionSeconds==nil then return Missing(search,'unknown','movement_transition_unknown') end
        edge,cooldowns=search.personal:Evaluate(edge,search.startedAt+search.current.cost+(edge.transitionSeconds or 0),cooldowns)
        if not edge then return Missing(search,'unknown',cooldowns) end
    end
    if edge.access == "unknown" and search.phase == "known" then search.sawUnknown = true; return end
    search.diagnostics.relaxed = search.diagnostics.relaxed + 1
    local milliseconds = search.current.milliseconds and (search.current.milliseconds + edge.milliseconds)
    if milliseconds and milliseconds > SAFE_INTEGER then return 'unknown', 'cost_overflow' end
    local cost = milliseconds and milliseconds / 1000 or (search.current.cost + edge.seconds)
    if not Finite(cost) then return "unknown", "cost_overflow" end
    local candidate = Entry(search, edge.to, search.current.via, cost, search.current, edge, milliseconds, edge.mode)
    if search.resources then
        local spent, resourceReason = Resources.Spend(search.resources, search.current.spent, edge.resources,search.cooldowns)
        if not spent then
            if resourceReason ~= 'resources_insufficient' then return Missing(search,'unknown',resourceReason) end
            return
        end
        candidate.spent,candidate.cooldowns=spent,cooldowns
        if search.cooldowns then
            candidate.cooldowns=namespace.NavigationV2Cooldowns.Trim(search.cooldowns,cooldowns,search.startedAt+cost)
        end
        local row=search.best[candidate.key] or {}
        search.best[candidate.key]=row
        search.pending={entry=candidate,row=row,index=1}
        return
    end
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
    for key,value in pairs(edge.resources or {}) do
        search.resourcesSpent[key]=(search.resourcesSpent[key] or 0)+value
    end
    search.segments[#search.segments + 1] = { edgeId = edge.id, from = NodeId(graph, edge.from),
        to = NodeId(graph, edge.to), seconds = edge.seconds, kind = edge.kind, portalId = edge.portalId,
        transportId = edge.transportId, costDetail = edge.costDetail, taxiId=edge.taxiId,
        resources=edge.resources, fareCopper=edge.fareCopper, personalId=edge.personalId,
        mode = entry.mode, transitionSeconds = edge.transitionSeconds,unlockEntry=edge.unlockEntry }
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
    if self.pending then
        if self.pending.prune then return PruneLabel(self) end
        return CompareLabel(self)
    end
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
