-- Dijkstra search with separate labels for money and consumables. A slower
-- arrival can still be useful if it leaves enough resources to finish.
-- Graph loading, candidate checks and result assembly all run through Step.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("search", 28) then return end
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
    return type(position) == "table" and IsFinite(position.x) and IsFinite(position.y) and IsFinite(position.instanceID)
end

local function PositionKey(position, walkingProvider)
    -- Map identity matters even where two map layers share world coordinates:
    -- an item may be usable on one layer and forbidden on another.
    return string.format(
        "%s:%.5f:%.5f:%s:%s:%s:%s:%s:%s",
        tostring(position.instanceID),
        position.x,
        position.y,
        tostring(position.uiMapID or ""),
        tostring(position.region or ""),
        tostring(position.accessKey or ""),
        tostring(position.noAutoconnect or false),
        tostring(position.z or (walkingProvider and "" or 0)),
        tostring(position.floor or "")
    )
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

local function DominatesOne(candidate, left, right, futureResources)
    if left.seconds > right.seconds or left.copper > right.copper then
        candidate.resourceCursor, candidate.resourceCount = nil, nil
        return false
    end
    if left.used == right.used then
        candidate.resourceCursor, candidate.resourceCount = nil, nil
        return true
    end
    -- Origin-only cooldowns cannot constrain a later leg. An empty relevance
    -- set makes resource comparisons unnecessary, even with distinct tables.
    if futureResources == EMPTY then
        candidate.resourceCursor, candidate.resourceCount = nil, nil
        return true
    end
    local key, count = candidate.resourceCursor, candidate.resourceCount
    if key == nil then
        key, count = next(left.used)
    end
    if key == nil then return true end
    if (not futureResources or futureResources[key]) and count > (right.used[key] or 0) then
        candidate.resourceCursor, candidate.resourceCount = nil, nil
        return false
    end
    -- Look ahead once and retain the observation. The usual zero/one-resource
    -- comparison completes inline; larger maps read one new entry per resume.
    candidate.resourceCursor, candidate.resourceCount = next(left.used, key)
    if candidate.resourceCursor == nil then return true end
    -- nil denotes an unfinished comparison, not a failed dominance relation.
    return nil
end

local function CopyEdge(edge, from, to)
    local copy = {}
    for key, value in pairs(edge) do
        copy[key] = value
    end
    copy.from, copy.to = from, to
    copy.mandatory = edge.mandatory == true or edge.kind ~= "walk"
    return copy
end

local function DefaultCanWalk(from, to)
    return from.region ~= nil and from.region == to.region and from.accessKey == to.accessKey and from.floor == to.floor
end

function Search:GetWalkSeconds(from, to, fromNode, toNode)
    local speed
    if self.walkSpeedAt then
        speed = math.min(self.walkingSpeeds[fromNode], self.walkingSpeeds[toNode])
    else
        speed = self.walkSpeedFor and self.walkSpeedFor(from, to) or self.walkSpeed
    end
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
    if self.defaultWalking or self.walkingRegionFor then
        -- Only the built-in predicate can be narrowed by region and access key.
        -- A host predicate may deliberately allow walking between two regions.
        local region = self.walkingRegionFor and self.walkingRegionFor(position) or position.region
        if region == nil then return EMPTY end
        local regions = bucket
        bucket = regions[region]
        if not bucket and create then
            bucket = {}
            regions[region] = bucket
        end
        if not bucket then return EMPTY end
        local access = position.accessKey or false
        local entries = bucket[access]
        if not entries and create then
            entries = {}
            bucket[access] = entries
        end
        if not entries then return EMPTY end
        local floor = position.floor or false
        local floors = entries[floor]
        if not floors and create then
            floors = {}
            entries[floor] = floors
        end
        return floors or EMPTY
    end
    return bucket
end

function Search:PrepareNodeSpeed(index)
    if self.walkingSpeeds[index] then return end
    local position = self.nodes[index]
    local speed = self.walkSpeedAt and self.walkSpeedAt(position) or self.walkSpeed
    if not IsFinite(speed) or speed <= 0 then speed = self.walkSpeed end
    self.walkingSpeeds[index] = speed
    local bucket = self:GetWalkingBucket(position, true)
    if bucket ~= EMPTY then
        if bucket.speed and bucket.speed ~= speed then bucket.mixedSpeed = true end
        bucket.speed = speed
    end
end

function Search:AddNode(position, isGoal)
    -- Input positions are immutable for this search. Repeated endpoints can
    -- reuse the canonical node without formatting their geometric key again.
    local index = self.nodeKeys[position]
    local checkArrival = isGoal and self.walkingProvider and position.z == nil
    if index and not checkArrival then return index end
    local key = PositionKey(position, self.walkingProvider)
    -- A matching XY at departure is not proof of arrival at a stacked
    -- surface. Keep that goal distinct until the provider resolves the walk.
    local separate = checkArrival and self.nodeKeys[key] == self.startNode
    if separate then key = key .. ":goal" end
    index = self.nodeKeys[key]
    if index then return index end
    index = #self.nodes + 1
    self.nodes[index], self.nodeKeys[key] = position, index
    if not separate then self.nodeKeys[position] = index end
    local bucket = self:GetWalkingBucket(position, true)
    if bucket ~= EMPTY then
        bucket[#bucket + 1] = index
        if IsFinite(position.z) then
            bucket.withZ = bucket.withZ or {}
            bucket.withZ[#bucket.withZ + 1] = index
        end
    end
    -- Start and goal are inserted by CreateSearch. Defer their host callbacks
    -- to scheduled work just like walking permissions and edge ingestion.
    if self.phase ~= "resources" then self:PrepareNodeSpeed(index) end
    return index
end

function Search:IngestEdge(edge)
    if
        type(edge) ~= "table"
        or not IsPosition(edge.from)
        or not IsPosition(edge.to)
        or not IsFinite(edge.seconds)
        or edge.seconds < 0
        or (edge.copper ~= nil and (not IsFinite(edge.copper) or edge.copper < 0))
        or (edge.resources ~= nil and type(edge.resources) ~= "table")
        or edge.condition == false
        or (self.excludeHearthstones and edge.hearthstone == true)
    then
        return
    end
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
    if self.blockedTerrainGoal == target then self.hasTransportToTerrainGoal = true end
    -- Inputs are immutable for this search. Copy only the winning itinerary,
    -- not every transport in the catalogue or every speculative arrival.
    local link = { target = target, edge = edge }
    if edge.sourceFree then
        link.allowedAtStart = not edge.canStart or not not edge.canStart(self.nodes[self.startNode])
        if link.allowedAtStart then
            -- A fixed-destination action usable at the start always beats the
            -- same action after another leg: it costs no more time, money or
            -- resources. Seed it once, rather than from every arrival label.
            self.startActions[#self.startActions + 1] = link
        else
            self.keepActionOrigins = true
            self.actions[#self.actions + 1] = link
        end
    else
        local outgoing = self.outgoing[from]
        if not outgoing then
            outgoing = {}
            self.outgoing[from] = outgoing
        end
        outgoing[#outgoing + 1] = link
    end
    if
        (not edge.sourceFree or not link.allowedAtStart)
        and (edge.resourceKey ~= nil or next(edge.resources or EMPTY) ~= nil)
    then
        self.resourceEdges[#self.resourceEdges + 1] = link.edge
    end
    self.ingestedEdges = self.ingestedEdges + 1
end

function Search:WalkingLowerBound(from, to)
    local dx, dy = to.x - from.x, to.y - from.y
    local dz = IsFinite(from.z) and IsFinite(to.z) and to.z - from.z or 0
    local context = self.walkingContext
    local radius = context.walkingGoalRange or context.walkingGoalApproach
    if context.walkingGoal == to and IsFinite(radius) and radius > 0 then
        return math.max(0, math.sqrt(dx * dx + dy * dy) - radius) / self.walkingSpeedCeiling
    end
    -- Interaction can finish directly above or below the observed service.
    -- Only the minimum required elevation change is a valid pruning bound.
    if self.serviceTargets and self.serviceTargets[to] then dz = math.max(0, math.abs(dz) - 5) end
    return math.sqrt(dx * dx + dy * dy + dz * dz) / self.walkingSpeedCeiling
end

function Search:PrepareDirectWalk(goalNode, priority)
    goalNode = goalNode or self.goalNode
    self:PrepareNodeSpeed(self.startNode)
    self:PrepareNodeSpeed(goalNode)
    -- Only an explicit speed ceiling permits the priority terrain measurement.
    -- Other terrain requests keep the original full origin batch.
    if self.walkingProvider and not self.boundedWalking then return end
    -- On a multi-service query a nearby transport may beat every long
    -- approach. Load the catalogue before paying for a speculative walk.
    if self.deferServiceWalks then return end
    if self.startNode == goalNode then
        if self.boundedWalking then self.terrainDirectSeconds = 0 else self.directSeconds = 0 end
        return
    end
    local from, to = self.nodes[self.startNode], self.nodes[goalNode]
    if
        from.instanceID ~= to.instanceID
        or from.noAutoconnect
        or to.noAutoconnect
        or (self.defaultWalking and not DefaultCanWalk(from, to))
    then
        return
    end
    if self.priorityGoals and not priority then
        -- Load every destination first, then measure the most local permitted
        -- goal. This order is only a scheduling choice, never a service filter.
        Push(self.priorityGoals, {node = goalNode, serial = self.goalIndex,
            seconds = self:WalkingLowerBound(from, to)})
        return
    end

    -- A permitted direct walk is a complete, free route. Its duration bounds
    -- useful alternatives, but a rejected walk proves nothing about shortcuts.
    self.walkChecks = self.walkChecks + 1
    local seconds = false
    if self.canWalk(from, to) then
        if self.boundedWalking then
            if self.proveCandidatePaths then return end
            self.directGoalNode = goalNode
            self.terrainJob = self.walkingProvider:CreateCostJob(from, {to}, self.walkingContext)
            self.phase = "terrain_direct"
            return
        end
        seconds = self:GetWalkSeconds(from, to, self.startNode, goalNode)
        self.directSeconds = math.min(self.directSeconds or math.huge, seconds)
    end
    self:GetWalkingCache(self.startNode)[goalNode] = seconds
end

function Search:AdvancePriorityGoal()
    if self.terrainDirectSeconds ~= nil then
        self.priorityGoals, self.phase = nil, "edges"
        return
    end
    local candidate = Pop(self.priorityGoals)
    if not candidate then
        self.priorityGoals, self.phase = nil, "edges"
        return
    end
    self:PrepareDirectWalk(candidate.node, true)
end

-- Only an unresolved request endpoint can be corrected by a fresh player
-- observation or goal. An ambiguous catalogue waypoint still forbids its edge.
function Search:RecordSurfaceRefusal(refusal, from, to)
    if refusal.independentFrom then self.closedWalkFrom[from] = true end
    if refusal.independentTo and self.nodes[to] ~= self.walkingContext.walkingGoal
        and not self.serviceTargets then self.closedWalkTo[to] = true end
    local unspecified = refusal.unresolvedFrom == nil and refusal.unresolvedTo == nil
    if from == self.startNode and refusal.unresolvedFrom then self.unresolvedStartSurface = true end
    if (from == self.startNode and (unspecified or refusal.unresolvedFrom))
        or ((to == self.goalNode or (self.goalNodes and self.goalNodes[to])) and (unspecified or refusal.unresolvedTo)) then
        self.unresolvedSurface = true
    end
end

function Search:AdvanceDirectTerrain()
    local status, result = self:StepTerrainJob()
    if status == "planning" then return end
    if status == "cancelled" then self:Cancel(); return end
    self.terrainJob, self.phase = nil, self.priorityGoals and "terrain_goals" or "edges"
    local goalNode = self.directGoalNode
    local cost = result and result.costs and result.costs[1]
    local seconds
    if cost and cost.unresolvedSurface then
        self:RecordSurfaceRefusal(cost, self.startNode, goalNode)
        if goalNode == self.goalNode and cost.unresolvedTo and not self.walkingContext.walkingGoalXY
            and not self.walkingContext.walkingGoalRange then self.blockedTerrainGoal = goalNode end
        seconds = false
    elseif (cost and cost.state == "no_path") or status == "no_path" then
        seconds = false
    elseif cost and cost.state == "ready" and IsFinite(cost.seconds) and cost.seconds >= 0 then
        seconds, self.terrainDirectSeconds = cost.seconds, cost.seconds
        -- With a feasible walk in hand, order alternatives by their physical
        -- lower bounds. Materialization validates the winning legs and retries
        -- if a detour or obstruction changes their price.
        self.lazyTerrain = self.batchTerrainWork
    elseif self:NeedsTerrainData(self.startNode, goalNode) then
        seconds = false
    else
        seconds = self:GetWalkSeconds(self.nodes[self.startNode], self.nodes[goalNode], self.startNode, goalNode)
        -- Unavailable uses this edge's authorized estimate in the ordinary
        -- graph too. It can bound that same model without claiming a measured
        -- collision path; final materialization still retries a proven no_path.
        self.terrainDirectSeconds = seconds
    end
    -- Keep this walking bound separate from directSeconds: that legacy field
    -- also prunes catalogue endpoints, which can be useful terrain waypoints.
    self:GetWalkingCache(self.startNode)[goalNode] = seconds
end

function Search:LoadOne()
    if self.phase == "goals" then
        local point = self.sourceGoals[self.goalIndex]
        if point then
            if IsPosition(point) then
                local node = self:AddNode(point, true)
                if self.serviceTargets then self.serviceTargets[self.nodes[node]] = true end
                local known = self.goalNodes[node]
                self.goalNodes[node] = self.goalNodes[node] or self.goalIndex
                if not known or not self.priorityGoals then self:PrepareDirectWalk(node) end
            end
            self.goalIndex = self.goalIndex + 1
        else
            self.sourceGoals, self.phase = nil, self.priorityGoals and "terrain_goals" or "edges"
        end
        return
    end
    if self.phase == "resources" then
        local key, count = next(self.sourceResources, self.resourceCursor)
        self.resourceCursor = key
        if key ~= nil then
            if IsFinite(count) and count >= 0 then self.resources[key] = count end
            return
        end
        self.sourceResources, self.phase = nil, self.sourceGoals and "goals" or "edges"
        if not self.sourceGoals then self:PrepareDirectWalk() end
        return
    end

    if self.phase == "resource_relevance" then
        local edge = self.resourceEdges[self.resourceIndex]
        if edge then
            local key = next(edge.resources or EMPTY, self.resourceCursor)
            self.resourceCursor = key
            if key ~= nil then
                self.futureResources[key] = true
                return
            end
            if edge.resourceKey ~= nil then self.futureResources[edge.resourceKey] = true end
            self.resourceIndex = self.resourceIndex + 1
            return
        end
        if next(self.futureResources) == nil then self.futureResources = EMPTY end
        self.resourceEdges, self.phase = nil, "search"
        self:QueueCandidate(self.startNode)
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
        self.omittedEdges = nil
        self:BeginSearch()
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
    self.omittedEdges = nil
    self:BeginSearch()
end

function Search:BeginSearch()
    if self.boundedWalking and self.batchTerrainWork and self.walkingProvider.RequiresWalkingProof then
        self.lazyTerrain = true
    end
    -- An unidentified destination surface rejects every walking origin.
    -- A transport can still reach the exact goal without a final walk.
    if self.blockedTerrainGoal and not self.hasTransportToTerrainGoal then
        self.status = "no_path"
        return
    end
    if #self.startActions > 0 then
        -- Cooldowns consumed only by start actions cannot constrain any future
        -- leg. Retain their actual usage in the result, but exclude those dead
        -- resources from Pareto comparisons. Shared reagents and map-restricted
        -- actions stay relevant. Discover one resource per scheduled operation.
        self.futureResources = {}
        self.phase, self.resourceIndex, self.resourceCursor = "resource_relevance", 1, nil
    else
        self.resourceEdges, self.phase = nil, "search"
        self:QueueCandidate(self.startNode)
    end
end

function Search:QueueCandidate(node, previous, edge, walkSeconds)
    if edge and self.passageProofs[edge] == false then return end
    local seconds = (previous and previous.seconds or 0) + (walkSeconds or (edge and edge.seconds) or 0)
    if self.directSeconds and seconds > self.directSeconds then return end
    if self.terrainDirectSeconds and seconds > self.terrainDirectSeconds then return end
    if self.bestGoalSeconds and seconds > self.bestGoalSeconds then return end
    local copper = (previous and previous.copper or 0) + (edge and edge.copper or 0)
    if copper > self.budget then return end
    local used = previous and previous.used or self.emptyUsage
    local requirements = edge and edge.resources or EMPTY
    local consumes = next(requirements) ~= nil or (edge and edge.resourceKey ~= nil)
    self.candidate = {
        node = node,
        previous = previous,
        edge = edge,
        walkSeconds = walkSeconds,
        copper = copper,
        seconds = seconds,
        used = consumes and {} or used,
        previousUsage = used,
        requirements = requirements,
        stage = consumes and "copy_resources" or "dominance",
        index = 1,
    }
end

function Search:AddResource(candidate, key, count)
    if not IsFinite(count) or count < 0 then
        self.candidate = nil
        return
    end
    local total = (candidate.used[key] or 0) + count
    if total > (self.resources[key] or 0) then
        self.candidate = nil
        return
    end
    if total > 0 then candidate.used[key] = total end
end

function Search:AcceptCandidate(candidate)
    local previous, edge = candidate.previous, candidate.edge
    -- Resource-free travel shares an immutable usage table. Allocate a new one
    -- only for an edge that actually consumes something.
    self.serial = self.serial + 1
    local label = {
        node = candidate.node,
        previous = previous,
        edge = edge,
        used = candidate.used,
        copper = candidate.copper,
        seconds = candidate.seconds,
        serial = self.serial,
        walkSeconds = candidate.walkSeconds,
    }
    local labels = self.labels[candidate.node]
    if not labels then
        labels = {}
        self.labels[candidate.node] = labels
    end
    labels[#labels + 1] = label
    Push(self.heap, label)
    -- Only a fully validated arrival proves a complete feasible itinerary.
    -- Nonnegative costs cannot improve it from a strictly slower prefix; ties
    -- remain eligible so Pareto/resource checks keep their existing order.
    if (candidate.node == self.goalNode or (self.goalNodes and self.goalNodes[candidate.node])) and (not self.bestGoalSeconds or label.seconds < self.bestGoalSeconds) then
        self.bestGoalSeconds = label.seconds
    end
    self.candidate = nil
end

function Search:CheckCandidate()
    -- Large inventories or many competing arrivals must yield too. Each call
    -- copies one resource, checks one requirement, or compares one arrival.
    local candidate = self.candidate
    if candidate.stage == "copy_resources" then
        local key, count = next(candidate.previousUsage, candidate.cursor)
        candidate.cursor = key
        if key ~= nil then
            candidate.used[key] = count
            return
        end
        candidate.stage = "edge_resources"
        return
    end
    if candidate.stage == "edge_resources" then
        local key, count = next(candidate.requirements, candidate.cursor)
        candidate.cursor = key
        if key ~= nil then
            self:AddResource(candidate, key, count)
            return
        end
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
    if not other then
        self:AcceptCandidate(candidate)
        return
    end
    if not other.stale then
        -- Scalar rejection needs no continuation. Keep ordinary incomparable
        -- arrivals on the same direct path as before the resource slicing.
        if
            not candidate.reverseDominance
            and (other.seconds > candidate.seconds or other.copper > candidate.copper)
        then
            candidate.reverseDominance = true
        end
        local dominated
        if candidate.reverseDominance then
            dominated = DominatesOne(candidate, candidate, other, self.futureResources)
        else
            dominated = DominatesOne(candidate, other, candidate, self.futureResources)
        end
        if dominated == nil then return end
        if not candidate.reverseDominance then
            if dominated then
                self.candidate = nil
            else
                candidate.reverseDominance = true
            end
            return
        end
        candidate.reverseDominance = nil
        if not dominated then
            candidate.index = candidate.index + 1
            return
        end
    end
    other.stale = true
    -- Frontier order is irrelevant. Swap removal avoids retaining stale
    -- labels and repeatedly scanning them at this destination.
    labels[candidate.index] = labels[#labels]
    labels[#labels] = nil
    candidate.resourceCursor, candidate.resourceCount, candidate.reverseDominance = nil, nil, nil
end

function Search:GetWalkingCache(node)
    local cache = self.walkingCache[node]
    if cache then return cache end
    if self.walkingProvider then
        -- A request may revisit an origin with different resource labels.
        -- Retain its batch so those arrivals share one immutable cost row.
        cache = {}
        self.walkingCache[node] = cache
        return cache
    end
    local slot = self.walkingCacheCursor
    local oldNode = self.walkingCacheOrder[slot]
    if oldNode then self.walkingCache[oldNode] = nil end
    cache = {}
    self.walkingCache[node], self.walkingCacheOrder[slot] = cache, node
    self.walkingCacheCursor = slot % WALK_CACHE_ROWS + 1
    return cache
end

function Search:StepTerrainJob()
    local remaining = self.deadline and math.max(0, self.deadline - self.clock()) or self.sliceMilliseconds
    if remaining <= 0 then return "planning" end
    -- Share the remaining work allowance with the provider. A provider that
    -- does not report its consumption is charged the entire grant.
    local allowance = self.batchTerrainWork and (self.operationLimit - self.workLastStep + 1) or 1
    local job = self.terrainJob
    local status, result = job:Step(allowance, remaining)
    local used = job.workLastStep
    used = IsFinite(used) and math.max(1, math.min(allowance, used)) or allowance
    self.workLastStep = self.workLastStep + used - 1
    return status, result
end

function Search:TerrainTargetCanImprove(label, target)
    if not self.boundedWalking then return true end
    local bound = math.min(self.terrainDirectSeconds or math.huge, self.bestGoalSeconds or math.huge)
    if bound == math.huge then return true end
    local from, to = self.nodes[label.node], self.nodes[target]
    -- This is only a lower bound on time, never an ETA or walking permission.
    return label.seconds + self:WalkingLowerBound(from, to) <= bound
end

function Search:WalkExcluded(from, to)
    local pages = self.walkApproachPages[to]
    if not (pages or self.closedWalkFrom[from] or self.closedWalkTo[to]) then return false end
    local a,b = self.nodes[from],self.nodes[to]
    if not self.strictWalking and not (self.walkingProvider.RequiresWalkingProof
        and self.walkingProvider:RequiresWalkingProof(a,b)) then return false end
    return self.closedWalkFrom[from] or self.closedWalkTo[to] or (pages and not pages[self.walkingProvider:GetWalkingPage(a)])
end

function Search:PrepareTerrainTargets(pending)
    local target = pending.walking[pending.index]
    pending.index = pending.index + 1
    if target then
        if target ~= pending.label.node and target ~= self.blockedTerrainGoal and not self:WalkExcluded(pending.label.node,target) then
            if pending.walkCache[target] ~= nil then return end
            local from, to = self.nodes[pending.label.node], self.nodes[target]
            self.walkChecks = self.walkChecks + 1
            if self.canWalk(from, to) then
                if self:TerrainTargetCanImprove(pending.label, target) then
                    pending.targets[#pending.targets + 1] = to
                    pending.targetNodes[#pending.targetNodes + 1] = target
                else
                    -- Unknown under this label's bound, not a no_path result.
                    pending.filtered = true
                end
            else
                pending.walkCache[target] = false
            end
        end
        return
    end
    if #pending.targets == 0 then
        pending.walkCache.terrainComplete = not pending.filtered
        pending.stage, pending.index = "walking", 1
        return
    end
    self.terrainJob = self.walkingProvider:CreateCostJob(self.nodes[pending.label.node], pending.targets, self.walkingContext)
    pending.stage = "terrain_costs"
end

function Search:NeedsTerrainData(from, to)
    local provider = self.walkingProvider
    local a, b = self.nodes[from], self.nodes[to]
    local covered = provider.RequiresWalkingProof and (provider:RequiresWalkingProof(a, b)
        or (self.protectWalkingCoverage and (provider:RequiresWalkingProof(a, a) or provider:RequiresWalkingProof(b, b))))
    if self.strictWalking or covered then
        self.terrainDataPending = true
        return true
    end
end

function Search:TerrainSeconds(status, cost, from, to)
    if cost and cost.approachPages and self.walkingProvider.GetWalkingPage
        and not (self.nodes[to] == self.walkingContext.walkingGoal
            and (self.walkingContext.walkingGoalRange or self.walkingContext.walkingGoalApproach)) then
        self.walkApproachPages[to] = cost.approachPages
    end
    if cost and cost.unverifiedGeometry then self.unverifiedGeometry = cost.unverifiedGeometry end
    if cost and cost.unresolvedSurface then
        self:RecordSurfaceRefusal(cost, from, to)
        return false
    end
    if status == "no_path" or (cost and cost.state == "no_path") then return false end
    if cost and cost.state == "ready" and IsFinite(cost.seconds) and cost.seconds >= 0 then return cost.seconds end
    if self:NeedsTerrainData(from, to) then return false end
    return self:GetWalkSeconds(self.nodes[from], self.nodes[to], from, to)
end

function Search:AdvanceTerrainCosts(pending)
    if not pending.costResult then
        local status, result = self:StepTerrainJob()
        if status == "planning" then return end
        if status == "cancelled" then self:Cancel(); return end
        self.terrainJob = nil
        pending.costResult = result and result.costs or EMPTY
        pending.costStatus, pending.index = status, 1
        return
    end
    local target = pending.targetNodes[pending.index]
    if not target then
        pending.walkCache.terrainComplete = not pending.filtered
        pending.targets, pending.targetNodes, pending.costResult = nil, nil, nil
        pending.stage, pending.index = "walking", 1
        return
    end
    local cost = pending.costResult[pending.index]
    pending.walkCache[target] = self:TerrainSeconds(pending.costStatus, cost, pending.label.node, target)
    pending.index = pending.index + 1
end

function Search:CheckWalk(pending, target)
    local label = pending.label
    if target == label.node then return end
    if self:WalkExcluded(label.node,target) then return end
    local cache = pending.walkCache
    local seconds = cache[target]
    if seconds == nil then
        if self.walkingProvider and not self.lazyTerrain then return end
        local from, to = self.nodes[label.node], self.nodes[target]
        self.walkChecks = self.walkChecks + 1
        if target ~= self.blockedTerrainGoal and self.canWalk(from, to) then
            if self.lazyTerrain then
                self:QueueCandidate(target, label, nil, self:WalkingLowerBound(from, to))
                return
            end
            seconds = self:GetWalkSeconds(from, to, label.node, target)
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
    if pending.stage == "terrain_targets" then self:PrepareTerrainTargets(pending); return end
    if pending.stage == "terrain_costs" then self:AdvanceTerrainCosts(pending); return end
    local label = pending.label
    local index = pending.index
    pending.index = index + 1
    if pending.stage == "outgoing" then
        local link = (self.outgoing[label.node] or EMPTY)[index]
        if link then
            self:QueueCandidate(link.target, label, link.edge)
            return
        end
        pending.stage, pending.index = "actions", 1
    elseif pending.stage == "actions" then
        local atStart = label.node == self.startNode
        local link = (atStart and self.startActions or self.actions)[index]
        if link then
            local from = self.nodes[label.node]
            local allowed
            if atStart then
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
        -- In a transitive region with one Euclidean speed, two consecutive
        -- automatic walks cannot beat the direct link already relaxed by the
        -- parent. Keep transport/action expansion, but avoid a quadratic scan
        -- of the walking clique. Mixed speeds still need all links. If a walk
        -- loses its origin's Z, only destinations with Z can improve: the
        -- intermediate point suppresses their otherwise nonzero vertical cost.
        if
            label.walkSeconds ~= nil
            and not self.walkingProvider
            and self.walkingIsTransitive
            and not pending.walking.mixedSpeed
            and (self.walkSpeedAt or not self.walkSpeedFor)
        then
            if IsFinite(self.nodes[label.previous.node].z) and not IsFinite(self.nodes[label.node].z) then
                pending.walking = pending.walking.withZ or EMPTY
                self.walkingExpansionsNarrowed = self.walkingExpansionsNarrowed + 1
            else
                self.walkingExpansionsSkipped = self.walkingExpansionsSkipped + 1
                self.pending = nil
                return
            end
        end
        if #pending.walking > 0 then
            pending.walkCache = self:GetWalkingCache(label.node)
            if self.walkingProvider and not self.lazyTerrain and not pending.walkCache.terrainComplete then
                pending.stage, pending.targets, pending.targetNodes = "terrain_targets", {}, {}
            end
        end
    else
        local target = pending.walking[index]
        if target then
            self:CheckWalk(pending, target)
            return
        end
        self.pending = nil
    end
end

function Search:AssembleOne()
    local assembly = self.assembly
    if assembly.label.previous then
        local label, edge = assembly.label, assembly.label.edge
        local previous = label.previous
        if label.walkSeconds ~= nil then
            edge = {
                id = "walk:" .. previous.node .. ":" .. label.node,
                kind = "walk",
                from = self.nodes[previous.node],
                to = self.nodes[label.node],
                seconds = label.walkSeconds,
                copper = 0,
                mandatory = false,
            }
            assembly.walks[edge] = {from = previous.node, to = label.node}
        elseif edge.sourceFree then
            edge = CopyEdge(edge, self.nodes[previous.node], self.nodes[label.node])
        else
            edge = CopyEdge(edge, edge.from, edge.to)
            local provider = self.walkingProvider
            if provider and provider.CreatePassageJob and edge.kind == "walk" and edge.from.instanceID == edge.to.instanceID
                and provider:RequiresWalkingProof(edge.from,edge.to) then
                assembly.passages = assembly.passages or {}
                assembly.passages[edge] = label.edge
            end
        end
        assembly.segments[#assembly.segments + 1] = edge
        assembly.label = previous
        return
    end
    local segments, index = assembly.segments, assembly.index
    local opposite = #segments - index + 1
    if index < opposite then
        segments[index], segments[opposite] = segments[opposite], segments[index]
        assembly.index = index + 1
        return
    end
    local result = {
        segments = segments,
        totalSeconds = self.winner.seconds,
        totalCopper = self.winner.copper,
        resourcesUsed = self.winner.used,
        goalIndex = self.goalNodes and self.goalNodes[self.winner.node],
    }
    if self.walkingProvider then
        local first, last = segments[1], segments[#segments]
        -- Prove the destination access before pricing departures for a trip
        -- between maps. An invalid final walk can reject the whole candidate.
        local backwards = self.lazyTerrain and first and (first.from.instanceID ~= last.to.instanceID
            or first.from.region ~= last.to.region or first.from.uiMapID ~= last.to.uiMapID)
        local entrance = segments[2]
        local primeEntryWalk = backwards and self.previewEntryWalk and self.proveCandidatePaths
            and not self.entryWalkAttempted and assembly.walks[first]
            and assembly.walks[first].from == self.startNode and entrance and not entrance.sourceFree
            and entrance.mandatory and (entrance.from.region ~= entrance.to.region
                or entrance.from.accessKey ~= entrance.to.accessKey or entrance.from.floor ~= entrance.to.floor)
        if primeEntryWalk then self.entryWalkAttempted = true end
        self.materialization = {result = result, walks = assembly.walks, passages = assembly.passages, index = backwards and #segments or 1,
            pricing = self.lazyTerrain, increment = backwards and -1 or 1, primeEntryWalk = primeEntryWalk}
        self.assembly = nil
    else
        self.result, self.assembly, self.status = result, nil, "ready"
    end
end

function Search:RestartLabels()
    self.heap, self.labels = {}, {}
    self.pending, self.candidate, self.winner, self.materialization = nil, nil, nil, nil
    self.bestGoalSeconds, self.directSeconds, self.terrainDirectSeconds = nil, nil, nil
    self:QueueCandidate(self.startNode)
end

function Search:ReconsiderWalkingEdge(nodes, seconds)
    self:GetWalkingCache(nodes.from)[nodes.to] = seconds
    self:RestartLabels()
end

function Search:RememberWalkingProof(nodes, result)
    if type(result.path) ~= "table" or #result.path < 2 then return end
    local proofs = self.walkingProofs or {}
    self.walkingProofs = proofs
    if #proofs == 8 then table.remove(proofs, 1) end
    proofs[#proofs + 1] = {from = nodes.from, to = nodes.to, path = result.path, approach = result.approach}
end

function Search:MaterializeOne()
    local pending = self.materialization
    local segment = pending.result.segments[pending.primeEntryWalk and 1 or pending.index]
    if not segment then
        if pending.pricing then
            pending.pricing, pending.index, pending.increment = nil, 1, 1
            return
        end
        self.result, self.materialization, self.status = pending.result, nil, "ready"
        return
    end
    local nodes = pending.walks[segment]
    local passage = pending.passages and pending.passages[segment]
    if passage then
        local path = self.passageProofs[passage]
        if not path then
            if not self.terrainJob then
                local from, to = segment.from, segment.to
                local provider = self.walkingProvider
                if from.region ~= to.region or from.accessKey ~= to.accessKey or from.floor ~= to.floor then
                    self.terrainJob = provider:CreatePassageJob(from, to, self.walkingContext)
                else
                    self.terrainJob = provider:CreatePathJob(from, to, self.walkingContext)
                end
                return
            end
            local status,result = self:StepTerrainJob()
            if status == "planning" then return end
            self.terrainJob = nil
            if status == "cancelled" then self:Cancel(); return end
            path = status == "ready" and result and result.path
            if not path or #path < 2 then
                if status ~= "no_path" then self.terrainDataPending = true end
                self.passageProofs[passage] = false
                self:RestartLabels()
                return
            end
            self.passageProofs[passage] = path
        end
        segment.path = path
    end
    if not nodes then pending.index = pending.index + pending.increment; return end
    if pending.pricing then
        local row = self:GetWalkingCache(nodes.from)
        if row[nodes.to] == nil then
            -- Only a contender pays for an exact cost. A provider may expose
            -- duration through its cost job and return only geometry hereafter.
            local status, result
            local entryProof = self.entryWalkProof
            if entryProof and entryProof.from == nodes.from and entryProof.to == nodes.to then
                status, result = entryProof.status, entryProof.result
                self.entryWalkProof = nil
            else
                if not self.terrainJob then
                    if self.proveCandidatePaths then
                        local context = self.walkingContext
                        if pending.primeEntryWalk then
                            context = {}
                            for key, value in pairs(self.walkingContext) do context[key] = value end
                            context.walkingGoal, context.previewWalking = segment.to, true
                            context.previewDeparture = true
                            context.walkingGoalRange, context.walkingGoalXY, context.walkingGoalApproach = nil, nil, nil
                        end
                        self.terrainJob = self.walkingProvider:CreatePathJob(segment.from, segment.to, context)
                    else
                        self.terrainJob = self.walkingProvider:CreateCostJob(segment.from, {segment.to}, self.walkingContext)
                    end
                    return
                end
                status, result = self:StepTerrainJob()
                if status == "planning" then
                    local preview = pending.primeEntryWalk and self.terrainJob.walkingPreview
                    local first = preview and preview[1]
                    if first and not first.breakBefore and (not self.entryWalkPreview or self.entryWalkPreview[1] ~= first) then
                        self.entryWalkPreview = {first}
                    end
                    return
                end
                if status == "cancelled" then self:Cancel(); return end
                self.terrainJob = nil
            end
            if pending.primeEntryWalk then
                -- Publish only the proved departure walk. Apply its price in
                -- the ordinary backwards order when the graph needs this leg.
                self.entryWalkProof = {from = nodes.from, to = nodes.to, status = status, result = result}
                if status == "ready" and result and type(result.path) == "table" and #result.path >= 2 then
                    self.entryWalkPreview = {{path = result.path}}
                end
                pending.primeEntryWalk = nil
                return
            end
            local cost = result and result.costs and result.costs[1]
            if self.proveCandidatePaths and result then
                cost = result
                cost.state = status
            end
            local seconds = self:TerrainSeconds(status, cost, nodes.from, nodes.to)
            if not seconds or math.abs(seconds - segment.seconds) > 0.000001 then
                self:ReconsiderWalkingEdge(nodes, seconds)
            else
                row[nodes.to] = seconds
            end
            if self.proveCandidatePaths and status == "ready" then self:RememberWalkingProof(nodes, result) end
            return
        end
        if pending.primeEntryWalk then pending.primeEntryWalk = nil; return end
        -- Price every leg before asking the provider to rebuild geometry.
        -- A later rejected walk invalidates this entire provisional winner.
        pending.index = pending.index + pending.increment
        return
    end
    for _, proof in ipairs(self.walkingProofs or EMPTY) do
        if proof.from == nodes.from and proof.to == nodes.to then
            segment.path = proof.path
            if proof.approach then segment.to, segment.approachOnly = proof.approach, true end
            pending.index = pending.index + 1
            return
        end
    end
    if not self.terrainJob then
        self.terrainJob = self.walkingProvider:CreatePathJob(segment.from, segment.to, self.walkingContext)
        return
    end
    local status, result = self:StepTerrainJob()
    if status == "planning" then return end
    if status == "cancelled" then self:Cancel(); return end
    self.terrainJob = nil
    if result and result.unverifiedGeometry then self.unverifiedGeometry = result.unverifiedGeometry end
    if status == "no_path" or (result and result.unresolvedSurface) then
        if result and result.unresolvedSurface then self:RecordSurfaceRefusal(result, nodes.from, nodes.to) end
        -- Removing a previously feasible edge invalidates every old dominance
        -- and goal bound. Re-run labels against the cached rows with that edge
        -- excluded; a slower transport may now be the only feasible journey.
        self:ReconsiderWalkingEdge(nodes, false)
        return
    end
    if status == "ready" and result and type(result.path) == "table" and #result.path >= 2 then
        if IsFinite(result.seconds) and result.seconds >= 0
            and math.abs(result.seconds - segment.seconds) > 0.000001 then
            -- A now-measured route supersedes an earlier unavailable estimate.
            -- Old labels/bounds must not suppress a newly competitive transport.
            self:ReconsiderWalkingEdge(nodes, result.seconds)
            return
        end
        segment.path = result.path
        if result.approach then segment.to, segment.approachOnly = result.approach, true end
    elseif self:NeedsTerrainData(nodes.from, nodes.to) then
        self:ReconsiderWalkingEdge(nodes, false)
        return
    end
    pending.index = pending.index + 1
end

function Search:AdvanceOne()
    if self.phase == "terrain_goals" then self:AdvancePriorityGoal(); return end
    if self.phase == "terrain_direct" then self:AdvanceDirectTerrain(); return end
    if self.phase ~= "search" then
        self:LoadOne()
        return
    end
    if self.assembly then
        self:AssembleOne()
        return
    end
    if self.materialization then self:MaterializeOne(); return end
    if self.candidate then
        self:CheckCandidate()
        return
    end
    if self.pending then
        self:ExpandOne()
        return
    end
    local label = Pop(self.heap)
    if not label then
        self.status = self.terrainDataPending and "waiting_data" or "no_path"
        return
    end
    if label.stale then return end
    self.expansions = self.expansions + 1
    if label.node == self.goalNode or (self.goalNodes and self.goalNodes[label.node]) then
        self.winner = label
        self.assembly = { label = label, segments = {}, walks = {}, index = 1 }
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
    self.deadline, self.sliceMilliseconds, self.operationLimit = deadline, maxMilliseconds, maxOperations
    while self.workLastStep < maxOperations do
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
    if self.terrainJob then self.terrainJob:Cancel() end
    self.terrainJob, self.materialization = nil, nil
    self.entryWalkProof, self.entryWalkPreview = nil, nil
    self.priorityGoals, self.directGoalNode = nil, nil
    self.heap, self.labels, self.pending, self.candidate, self.assembly = {}, {}, nil, nil, nil
    self.winner = nil
    self.sourceEdges, self.sourceGroups, self.sourceResources, self.sourceGoals = nil, nil, nil, nil
    self.omittedEdges = nil
    self.nodes, self.nodeKeys, self.outgoing, self.actions, self.startActions = {}, {}, {}, {}, {}
    self.resourceEdges, self.futureResources = nil, nil
    self.walkingByInstance, self.walkingCache, self.walkingCacheOrder, self.walkingSpeeds = {}, {}, {}, {}
end

function Search:GetResult() return self.result, self.status end

function Engine:CreateSearch(request)
    request = type(request) == "table" and request or {}
    local search = setmetatable({
        status = "planning",
        phase = "resources",
        nodes = {},
        nodeKeys = {},
        outgoing = {},
        actions = {},
        startActions = {},
        resourceEdges = {},
        labels = {},
        heap = {},
        serial = 0,
        expansions = 0,
        resources = {},
        emptyUsage = {},
        batchTerrainWork = request.batchTerrainWork == true,
        clock = request.clock,
        excludeHearthstones = request.excludeHearthstones == true,
        sourceResources = type(request.resources) == "table" and request.resources or EMPTY,
        sourceEdges = type(request.edges) == "table" and request.edges or EMPTY,
        sourceGroups = type(request.edgeGroups) == "table" and request.edgeGroups or EMPTY,
        edgeGroup = 0,
        edgeIndex = 1,
        ingestedEdges = 0,
        walkingByInstance = {},
        walkingCache = {},
        closedWalkFrom = {}, closedWalkTo = {}, walkApproachPages = {}, passageProofs = {},
        walkingCacheOrder = {},
        walkingCacheCursor = 1,
        walkChecks = 0,
        walkingCacheHits = 0,
        walkingExpansionsSkipped = 0,
        walkingExpansionsNarrowed = 0,
        walkingSpeeds = {},
        defaultWalking = request.canWalk == nil,
        walkingIsTransitive = request.canWalk == nil or request.walkingIsTransitive == true,
        budget = IsFinite(request.budget) and math.max(0, request.budget) or 0,
        walkSpeedFor = request.walkSpeedFor,
        walkSpeedAt = request.walkSpeedAt,
        walkSpeed = IsFinite(request.walkSpeed) and request.walkSpeed > 0 and request.walkSpeed or 7,
        canWalk = request.canWalk or DefaultCanWalk,
        walkingRegionFor = request.walkingRegionFor,
        walkingProvider = request.walkingProvider,
        previewEntryWalk = request.previewEntryWalk == true,
        strictWalking = request.requireVerifiedWalks == true and request.walkingProvider ~= nil,
        protectWalkingCoverage = request.protectWalkingCoverage == true,
        walkingSpeedCeiling = IsFinite(request.walkingSpeedCeiling) and request.walkingSpeedCeiling > 0
            and request.walkingSpeedCeiling or nil,
    }, Search)
    search.boundedWalking = not not search.walkingProvider and search.walkingSpeedCeiling ~= nil
    search.proveCandidatePaths = search.boundedWalking and search.batchTerrainWork
        and search.walkingProvider.RequiresWalkingProof and search.walkingProvider.proveCandidatePaths == true
    search.deferServiceWalks = request.serviceWalking and search.boundedWalking and search.batchTerrainWork
        and search.walkingProvider.RequiresWalkingProof
    search.serviceTargets = request.serviceWalking and search.walkingProvider and {} or nil
    search.walkingContext = {
        walkingGoalRange = request.walkingGoalRange, walkingGoalXY = request.walkingGoalXY, walkingGoal = request.goal,
        walkingGoalPreferRange = request.walkingGoalPreferRange,
        walkingGoalApproach = request.walkingGoalApproach,
        previewWalking = request.previewWalking,
        shareWalkingOrigin = search.batchTerrainWork,
        walkingOrigin = request.start, walkingOriginCorridor = request.walkingOriginCorridor,
        faction = request.faction, serviceWalking = request.serviceWalking, serviceTargets = search.serviceTargets,
        walkSpeed = search.walkSpeed,
        walkSpeedFor = search.walkSpeedFor,
        walkSpeedAt = search.walkSpeedAt,
        clock = search.clock,
    }
    if not IsPosition(request.start) or (not IsPosition(request.goal) and type(request.goals) ~= "table") then
        search.status, search.reason = "no_path", "invalid_position"
        return search
    end
    -- Keep creation independent of catalogue size. The caller owns these input
    -- tables and must leave them unchanged until the search finishes or cancels.
    search.startNode = search:AddNode(request.start)
    if search.walkingProvider and search.walkingProvider.RequiresWalkingProof and IsPosition(request.goal) then
        -- A covered journey cannot leave the pack via two estimated walks
        -- through an unrelated catalogue point and return to its covered goal.
        search.strictWalking = search.strictWalking or search.walkingProvider:RequiresWalkingProof(request.start, request.goal)
    end
    if type(request.goals) == "table" then
        search.sourceGoals, search.goalNodes, search.goalIndex = request.goals, {}, 1
        search.priorityGoals = search.boundedWalking and {} or nil
    else
        search.goalNode = search:AddNode(request.goal, true)
        if search.serviceTargets then search.serviceTargets[search.nodes[search.goalNode]] = true end
    end
    return search
end
