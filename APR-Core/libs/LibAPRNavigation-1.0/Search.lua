-- Dijkstra search with separate labels for money and consumables. A slower
-- arrival can still be useful if it leaves enough resources to finish.
-- Graph loading, candidate checks and result assembly all run through Step.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("search", 5) then return end
Lib.Engine = {}
local Engine = Lib.Engine
local Search = {}
Search.__index = Search

local EMPTY = {}
local DEFAULT_SLICE_MS = 1
local WALK_CACHE_ROWS = 16

local function IsFinite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function IsPosition(position)
    return type(position) == "table" and IsFinite(position.x) and IsFinite(position.y)
        and IsFinite(position.instanceID)
end

local function PositionKey(position)
    -- Map identity matters even where two map layers share world coordinates:
    -- an item may be usable on one layer and forbidden on another.
    return string.format("%s:%.5f:%.5f:%s:%s:%s:%s:%s:%s", tostring(position.instanceID), position.x, position.y,
        tostring(position.uiMapID or ""), tostring(position.region or ""),
        tostring(position.accessKey or ""), tostring(position.noAutoconnect or false),
        tostring(position.z or 0), tostring(position.floor or ""))
end

local function Earlier(left, right)
    return left.seconds < right.seconds or (left.seconds == right.seconds and left.serial < right.serial)
end

local function Push(heap, label)
    local index = #heap + 1
    while index > 1 do
        local parent = math.floor(index / 2)
        if Earlier(heap[parent], label) then break end
        heap[index], index = heap[parent], parent
    end
    heap[index] = label
end

local function Pop(heap)
    local first, last = heap[1], table.remove(heap)
    if #heap == 0 then return first end
    local index = 1
    while index * 2 <= #heap do
        local child = index * 2
        if child < #heap and Earlier(heap[child + 1], heap[child]) then child = child + 1 end
        if Earlier(last, heap[child]) then break end
        heap[index], index = heap[child], child
    end
    heap[index] = last
    return first
end

local function Dominates(left, right)
    if left.seconds > right.seconds or left.copper > right.copper then return false end
    if left.used == right.used then return true end
    for key, count in pairs(left.used) do
        if count > (right.used[key] or 0) then return false end
    end
    return true
end

local function CopyEdge(edge, from, to)
    local copy = {}
    for key, value in pairs(edge) do copy[key] = value end
    copy.from, copy.to = from, to
    copy.mandatory = edge.mandatory == true or edge.kind ~= "walk"
    return copy
end

local function DefaultCanWalk(from, to)
    return from.region ~= nil and from.region == to.region and from.accessKey == to.accessKey and from.floor == to.floor
end

function Search:GetWalkSeconds(from, to)
    local speed = self.walkSpeedFor and self.walkSpeedFor(from, to) or self.walkSpeed
    if not IsFinite(speed) or speed <= 0 then speed = self.walkSpeed end
    local dx, dy = to.x - from.x, to.y - from.y
    local dz = IsFinite(from.z) and IsFinite(to.z) and to.z - from.z or 0
    return math.sqrt(dx * dx + dy * dy + dz * dz) / speed
end

function Search:GetWalkingBucket(position, create)
    if position.noAutoconnect then return EMPTY end
    local bucket = self.walkingByInstance[position.instanceID]
    if not bucket and create then
        bucket = {}
        self.walkingByInstance[position.instanceID] = bucket
    end
    if not bucket then return EMPTY end
    if self.defaultWalking then
        -- Only the built-in predicate can be narrowed by region and access key.
        -- A host predicate may deliberately allow walking between two regions.
        if position.region == nil then return EMPTY end
        local regions = bucket
        bucket = regions[position.region]
        if not bucket and create then bucket = {}; regions[position.region] = bucket end
        if not bucket then return EMPTY end
        local access = position.accessKey or false
        local entries = bucket[access]
        if not entries and create then entries = {}; bucket[access] = entries end
        return entries or EMPTY
    end
    return bucket
end

function Search:AddNode(position)
    local key = PositionKey(position)
    local index = self.nodeKeys[key]
    if index then return index end
    index = #self.nodes + 1
    self.nodes[index], self.nodeKeys[key] = position, index
    local bucket = self:GetWalkingBucket(position, true)
    if bucket ~= EMPTY then bucket[#bucket + 1] = index end
    return index
end

function Search:IngestEdge(edge)
    if type(edge) ~= "table" or not IsPosition(edge.from) or not IsPosition(edge.to)
        or not IsFinite(edge.seconds) or edge.seconds < 0
        or (edge.copper ~= nil and (not IsFinite(edge.copper) or edge.copper < 0))
        or (edge.resources ~= nil and type(edge.resources) ~= "table")
        or edge.condition == false then return end
    local tooSlow = self.directSeconds and edge.seconds > self.directSeconds
    if tooSlow and self.walkingIsTransitive and not self.keepActionOrigins then
        -- Keep references until every action has been read. A later action
        -- might need one of these positions as its only usable departure.
        self.omittedEdges = self.omittedEdges or {}
        self.omittedEdges[#self.omittedEdges + 1] = edge
        return
    end
    local from, target = self:AddNode(edge.from), self:AddNode(edge.to)
    -- A custom walking rule may require one of these points as a bridge even
    -- when its transport loses. Only a transitive rule makes removal safe.
    if tooSlow then return end
    local link = { target = target, edge = CopyEdge(edge, edge.from, edge.to) }
    if edge.sourceFree then
        link.allowedAtStart = not edge.canStart or not not edge.canStart(self.nodes[self.startNode])
        if not link.allowedAtStart then self.keepActionOrigins = true end
        self.actions[#self.actions + 1] = link
    else
        local outgoing = self.outgoing[from]
        if not outgoing then outgoing = {}; self.outgoing[from] = outgoing end
        outgoing[#outgoing + 1] = link
    end
    self.ingestedEdges = self.ingestedEdges + 1
end

function Search:PrepareDirectWalk()
    if self.startNode == self.goalNode then self.directSeconds = 0; return end
    local from, to = self.nodes[self.startNode], self.nodes[self.goalNode]
    if from.instanceID ~= to.instanceID or from.noAutoconnect or to.noAutoconnect
        or (self.defaultWalking and not DefaultCanWalk(from, to)) then return end

    -- A permitted direct walk is a complete, free route. Its duration bounds
    -- useful alternatives, but a rejected walk proves nothing about shortcuts.
    self.walkChecks = self.walkChecks + 1
    local seconds = false
    if self.canWalk(from, to) then
        seconds = self:GetWalkSeconds(from, to)
        self.directSeconds = seconds
    end
    self:GetWalkingCache(self.startNode)[self.goalNode] = seconds
end

function Search:LoadOne()
    if self.phase == "resources" then
        local key, count = next(self.sourceResources, self.resourceCursor)
        self.resourceCursor = key
        if key ~= nil then
            if IsFinite(count) and count >= 0 then self.resources[key] = count end
            return
        end
        self.sourceResources, self.phase = nil, "edges"
        self:PrepareDirectWalk()
        return
    end

    if self.phase == "action_origins" then
        local edge = self.omittedEdges[self.omittedIndex]
        if edge then
            self:AddNode(edge.from)
            self:AddNode(edge.to)
            self.omittedIndex = self.omittedIndex + 1
            return
        end
        self.omittedEdges, self.phase = nil, "search"
        self:QueueCandidate(self.startNode)
        return
    end

    -- Keep provider arrays separate. Even concatenating them up front would
    -- put work proportional to the whole taxi network on one frame.
    local group = self.edgeGroup == 0 and self.sourceEdges or self.sourceGroups[self.edgeGroup]
    local edge
    if type(group) == "table" then edge = group[self.edgeIndex] end
    if edge ~= nil then
        self.edgeIndex = self.edgeIndex + 1
        self:IngestEdge(edge)
        return
    end
    self.edgeGroup, self.edgeIndex = self.edgeGroup + 1, 1
    if self.edgeGroup <= #self.sourceGroups then return end
    self.sourceEdges, self.sourceGroups = nil, nil
    if self.keepActionOrigins and self.omittedEdges then
        self.phase, self.omittedIndex = "action_origins", 1
        return
    end
    self.omittedEdges, self.phase = nil, "search"
    self:QueueCandidate(self.startNode)
end

function Search:QueueCandidate(node, previous, edge, walkSeconds)
    local seconds = (previous and previous.seconds or 0) + (walkSeconds or (edge and edge.seconds) or 0)
    if self.directSeconds and seconds > self.directSeconds then return end
    local copper = (previous and previous.copper or 0) + (edge and edge.copper or 0)
    if copper > self.budget then return end
    local used = previous and previous.used or self.emptyUsage
    local requirements = edge and edge.resources or EMPTY
    local consumes = next(requirements) ~= nil or (edge and edge.resourceKey ~= nil)
    self.candidate = {
        node = node, previous = previous, edge = edge, walkSeconds = walkSeconds,
        copper = copper, seconds = seconds,
        used = consumes and {} or used, previousUsage = used, requirements = requirements,
        stage = consumes and "copy_resources" or "dominance", index = 1,
    }
end

function Search:AddResource(candidate, key, count)
    if not IsFinite(count) or count < 0 then self.candidate = nil; return end
    local total = (candidate.used[key] or 0) + count
    if total > (self.resources[key] or 0) then self.candidate = nil; return end
    if total > 0 then candidate.used[key] = total end
end

function Search:AcceptCandidate(candidate)
    local previous, edge = candidate.previous, candidate.edge
    if candidate.walkSeconds then
        edge = { id = "walk:" .. previous.node .. ":" .. candidate.node, kind = "walk",
            from = self.nodes[previous.node], to = self.nodes[candidate.node],
            seconds = candidate.walkSeconds, copper = 0, mandatory = false }
    elseif edge and edge.sourceFree then
        edge = CopyEdge(edge, self.nodes[previous.node], self.nodes[candidate.node])
    end
    -- Resource-free travel shares an immutable usage table. Allocate a new one
    -- only for an edge that actually consumes something.
    self.serial = self.serial + 1
    local label = { node = candidate.node, previous = previous, edge = edge, used = candidate.used,
        copper = candidate.copper, seconds = candidate.seconds, serial = self.serial }
    local labels = self.labels[candidate.node]
    if not labels then labels = {}; self.labels[candidate.node] = labels end
    labels[#labels + 1] = label
    Push(self.heap, label)
    self.candidate = nil
end

function Search:CheckCandidate()
    -- Large inventories or many competing arrivals must yield too. Each call
    -- copies one resource, checks one requirement, or compares one arrival.
    local candidate = self.candidate
    if candidate.stage == "copy_resources" then
        local key, count = next(candidate.previousUsage, candidate.cursor)
        candidate.cursor = key
        if key ~= nil then candidate.used[key] = count; return end
        candidate.stage = "edge_resources"
        return
    end
    if candidate.stage == "edge_resources" then
        local key, count = next(candidate.requirements, candidate.cursor)
        candidate.cursor = key
        if key ~= nil then self:AddResource(candidate, key, count); return end
        candidate.stage = "resource_key"
        return
    end
    if candidate.stage == "resource_key" then
        local edge = candidate.edge
        candidate.stage = "dominance"
        if edge.resourceKey ~= nil then self:AddResource(candidate, edge.resourceKey, edge.resourceCount or 1) end
        return
    end

    local labels = self.labels[candidate.node] or EMPTY
    local other = labels[candidate.index]
    if not other then self:AcceptCandidate(candidate); return end
    if not other.stale and Dominates(other, candidate) then self.candidate = nil; return end
    if other.stale or Dominates(candidate, other) then
        other.stale = true
        -- Frontier order is irrelevant. Swap removal avoids retaining stale
        -- labels and repeatedly scanning them at this destination.
        labels[candidate.index] = labels[#labels]
        labels[#labels] = nil
    else
        candidate.index = candidate.index + 1
    end
end

function Search:GetWalkingCache(node)
    local cache = self.walkingCache[node]
    if cache then return cache end
    local slot = self.walkingCacheCursor
    local oldNode = self.walkingCacheOrder[slot]
    if oldNode then self.walkingCache[oldNode] = nil end
    cache = {}
    self.walkingCache[node], self.walkingCacheOrder[slot] = cache, node
    self.walkingCacheCursor = slot % WALK_CACHE_ROWS + 1
    return cache
end

function Search:CheckWalk(pending, target)
    local label = pending.label
    if target == label.node then return end
    local cache = pending.walkCache
    local seconds = cache[target]
    if seconds == nil then
        local from, to = self.nodes[label.node], self.nodes[target]
        self.walkChecks = self.walkChecks + 1
        if self.canWalk(from, to) then
            seconds = self:GetWalkSeconds(from, to)
        else
            seconds = false
        end
        cache[target] = seconds
    else
        self.walkingCacheHits = self.walkingCacheHits + 1
    end
    if seconds then self:QueueCandidate(target, label, nil, seconds) end
end

function Search:ExpandOne()
    local pending = self.pending
    local label = pending.label
    local index = pending.index
    pending.index = index + 1
    if pending.stage == "outgoing" then
        local link = (self.outgoing[label.node] or EMPTY)[index]
        if link then self:QueueCandidate(link.target, label, link.edge); return end
        pending.stage, pending.index = "actions", 1
    elseif pending.stage == "actions" then
        local link = self.actions[index]
        if link then
            local from = self.nodes[label.node]
            local allowed
            if label.node == self.startNode then
                allowed = link.allowedAtStart
            else
                allowed = not link.edge.canStart or link.edge.canStart(from)
            end
            if allowed then
                self:QueueCandidate(link.target, label, link.edge)
            end
            return
        end
        pending.stage, pending.index = "walking", 1
        pending.walking = self:GetWalkingBucket(self.nodes[label.node])
        if #pending.walking > 0 then pending.walkCache = self:GetWalkingCache(label.node) end
    else
        local target = pending.walking[index]
        if target then self:CheckWalk(pending, target); return end
        self.pending = nil
    end
end

function Search:AssembleOne()
    local assembly = self.assembly
    if assembly.label.previous then
        assembly.segments[#assembly.segments + 1] = assembly.label.edge
        assembly.label = assembly.label.previous
        return
    end
    local segments, index = assembly.segments, assembly.index
    local opposite = #segments - index + 1
    if index < opposite then
        segments[index], segments[opposite] = segments[opposite], segments[index]
        assembly.index = index + 1
        return
    end
    self.result = { segments = segments, totalSeconds = self.winner.seconds,
        totalCopper = self.winner.copper, resourcesUsed = self.winner.used }
    self.assembly, self.status = nil, "ready"
end

function Search:AdvanceOne()
    if self.phase ~= "search" then self:LoadOne(); return end
    if self.assembly then self:AssembleOne(); return end
    if self.candidate then self:CheckCandidate(); return end
    if self.pending then self:ExpandOne(); return end
    local label = Pop(self.heap)
    if not label then self.status = "no_path"; return end
    if label.stale then return end
    self.expansions = self.expansions + 1
    if label.node == self.goalNode then
        self.winner = label
        self.assembly = { label = label, segments = {}, index = 1 }
    else
        self.pending = { label = label, stage = "outgoing", index = 1 }
    end
end

function Search:Step(maxOperations, maxMilliseconds)
    if self.status ~= "planning" then return self.status, self.result end
    maxOperations = tonumber(maxOperations)
    maxOperations = IsFinite(maxOperations) and math.max(0, math.floor(maxOperations)) or 64
    maxMilliseconds = IsFinite(maxMilliseconds) and math.max(0, maxMilliseconds) or DEFAULT_SLICE_MS
    self.workLastStep = 0
    if maxOperations == 0 or maxMilliseconds == 0 then return self.status, self.result end
    local deadline = self.clock and (self.clock() + maxMilliseconds)
    for _ = 1, maxOperations do
        -- Yield between small units of work. Host predicates are synchronous,
        -- so a slow callback can still exceed the requested slice by itself.
        if deadline and self.workLastStep > 0 and self.clock() >= deadline then break end
        self.workLastStep = self.workLastStep + 1
        self:AdvanceOne()
        if self.status ~= "planning" then break end
    end
    return self.status, self.result
end

function Search:Cancel()
    if self.status == "planning" then self.status = "cancelled" end
    self.heap, self.labels, self.pending, self.candidate, self.assembly = {}, {}, nil, nil, nil
    self.winner = nil
    self.sourceEdges, self.sourceGroups, self.sourceResources = nil, nil, nil
    self.omittedEdges = nil
    self.nodes, self.nodeKeys, self.outgoing, self.actions = {}, {}, {}, {}
    self.walkingByInstance, self.walkingCache, self.walkingCacheOrder = {}, {}, {}
end

function Search:GetResult() return self.result, self.status end

function Engine:CreateSearch(request)
    request = type(request) == "table" and request or {}
    local search = setmetatable({
        status = "planning", phase = "resources", nodes = {}, nodeKeys = {}, outgoing = {}, actions = {},
        labels = {}, heap = {}, serial = 0, expansions = 0, resources = {}, emptyUsage = {}, clock = request.clock,
        sourceResources = type(request.resources) == "table" and request.resources or EMPTY,
        sourceEdges = type(request.edges) == "table" and request.edges or EMPTY,
        sourceGroups = type(request.edgeGroups) == "table" and request.edgeGroups or EMPTY,
        edgeGroup = 0, edgeIndex = 1, ingestedEdges = 0,
        walkingByInstance = {}, walkingCache = {}, walkingCacheOrder = {}, walkingCacheCursor = 1,
        walkChecks = 0, walkingCacheHits = 0, defaultWalking = request.canWalk == nil,
        walkingIsTransitive = request.canWalk == nil or request.walkingIsTransitive == true,
        budget = IsFinite(request.budget) and math.max(0, request.budget) or 0,
        walkSpeedFor = request.walkSpeedFor,
        walkSpeed = IsFinite(request.walkSpeed) and request.walkSpeed > 0 and request.walkSpeed or 7,
        canWalk = request.canWalk or DefaultCanWalk,
    }, Search)
    if not IsPosition(request.start) or not IsPosition(request.goal) then
        search.status, search.reason = "no_path", "invalid_position"
        return search
    end
    -- Keep creation independent of catalogue size. The caller owns these input
    -- tables and must leave them unchanged until the search finishes or cancels.
    search.startNode, search.goalNode = search:AddNode(request.start), search:AddNode(request.goal)
    return search
end
