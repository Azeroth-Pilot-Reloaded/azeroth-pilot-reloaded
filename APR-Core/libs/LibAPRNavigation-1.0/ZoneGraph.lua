-- Sparse physical transport topology. One vertex represents a walkable access
-- region, not every coordinate in that region. Character flags are never cached
-- in this shared geometry index; each request owns a fresh condition snapshot.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("zone_graph", 3) then return end
local Instance = Lib.Instance

local function Encode(value)
    local text = tostring(value)
    return type(value) .. #text .. ":" .. text
end

local function RegionKey(data, point)
    if not point then return end
    local region = data:GetPositionRegion(point)
    if not region and not point.noAutoconnect then return end
    local key = Encode(point.instanceID) .. Encode(region) .. Encode(point.accessKey) .. Encode(point.floor)
    if point.noAutoconnect then
        -- Mandatory passage endpoints connect only at their exact graph point.
        key = key .. string.format(":point:%.5f:%.5f:%s:%s", point.x, point.y,
            tostring(point.z or 0), tostring(point.uiMapID or ""))
    end
    return key
end

local function AddDirection(graph, data, definition, from, to, reverse)
    local source, target = RegionKey(data, from), RegionKey(data, to)
    if not source or not target then return false end
    if source == target then return true end
    local outgoing = graph.outgoing[source]
    if not outgoing then outgoing = {}; graph.outgoing[source] = outgoing end
    local link = { definition = definition, from = from, to = to, target = target,
        suffix = reverse and ":reverse" or ":forward" }
    outgoing[#outgoing + 1] = link
    local destinations = graph.direct[source]
    if not destinations then destinations = {}; graph.direct[source] = destinations end
    local parallel = destinations[target]
    if not parallel then parallel = {}; destinations[target] = parallel end
    parallel[#parallel + 1] = link
    return true
end

local function IndexDefinition(graph, data, definition, context)
    local from = data:ResolvePosition(definition.from, context)
    local to = data:ResolvePosition(definition.to, context)
    if not from or not to or not AddDirection(graph, data, definition, from, to) then return false end
    if definition.bidirectional then AddDirection(graph, data, definition, to, from, true) end
    return true
end

function Instance:CreateZoneGraphRoute(context, makeWalk)
    local graph = self.zoneGraph
    if not graph or graph.version ~= 2 or graph.source ~= self.connections or graph.count ~= #self.connections
        or graph.positions ~= self.positions then
        graph = { source = self.connections, count = #self.connections, positions = self.positions,
            index = 1, outgoing = {}, direct = {}, pending = {}, status = "planning", version = 2 }
        self.zoneGraph = graph
    end
    local job = { status = "planning", clock = context.clock or self.env.clock, graph = graph,
        checkedLinks = 0, indexedConnections = 0 }
    local function checkpoint() coroutine.yield() end
    job.worker = coroutine.create(function()
        -- Retry only unresolved geometry from an earlier request. Successful
        -- topology survives missing records without another catalogue scan.
        for index = #graph.pending, 1, -1 do
            local definition = graph.pending[index]
            if definition and IndexDefinition(graph, self, definition, context) then
                graph.pending[index] = graph.pending[#graph.pending]
                graph.pending[#graph.pending] = nil
            end
            checkpoint()
        end
        while graph.status == "planning" do
            local definition = graph.source[graph.index]
            if not definition then graph.status = "ready"; break end
            if not definition.actions and not definition.disabled
                and not (definition.reviewStatus and definition.reviewStatus ~= "confirmed")
                and not definition.from.dynamic and not definition.to.dynamic then
                if not IndexDefinition(graph, self, definition, context) then
                    graph.pending[#graph.pending + 1] = definition
                end
            end
            graph.index = graph.index + 1
            job.indexedConnections = job.indexedConnections + 1
            checkpoint()
        end
        local start, goal = RegionKey(self, context.start), RegionKey(self, context.goal)
        if not start or not goal or start == goal then return "fallback" end
        local snapshot, character = self:CreatePlanningSnapshot(context)
        local conditions = {}
        local function condition(link)
            local cached = conditions[link]
            if cached then return cached end
            character.mapID = link.from.uiMapID
            local requirements = snapshot:GetTravelRequirements(link.definition.requirements, link.from, link.to)
            cached = { requirements = requirements, possible = not Lib.RequirementsApplicable
                or Lib.RequirementsApplicable(snapshot, requirements, character) }
            if cached.possible then cached.allowed = snapshot:CheckPlanningRequirements(requirements, character) end
            conditions[link] = cached
            job.checkedLinks = job.checkedLinks + 1
            return cached
        end
        local function search(relaxed)
            -- Forever can offer a neutral boat and several faction zeppelins
            -- between the same continents. Compare their complete direct-trip
            -- times instead of picking whichever record happened to load first.
            local directWinner, directSeconds
            for _, link in ipairs((graph.direct[start] or {})[goal] or {}) do
                local state = condition(link)
                local definition, fare = link.definition, link.definition.copper or 0
                if state.possible and (state.allowed == true or relaxed) and fare <= (context.budget or 0) then
                    local crossing = definition.seconds
                    if definition.costMode == "ground" then
                        crossing = link.from.instanceID == link.to.instanceID
                            and math.max(1, makeWalk(context, link.from, link.to).seconds)
                            or definition.seconds or self.config.passageSeconds or 30
                    elseif crossing == nil then
                        crossing = definition.kind == "portal" and (self.config.actionLoadingSeconds or 5) or 0
                    end
                    local seconds = makeWalk(context, context.start, link.from).seconds
                        + crossing + (definition.waitSeconds or 0) + makeWalk(context, link.to, context.goal).seconds
                    if not directWinner or seconds < directSeconds then
                        directSeconds = seconds
                        directWinner = { key = goal, copper = fare, previous = { key = start, copper = 0 }, link = link }
                    end
                end
                checkpoint()
            end
            if directWinner then return directWinner end
            local queue = { { key = start, copper = 0 } }
            local bestCopper, cursor = { [start] = 0 }, 1
            while cursor <= #queue do
                local label = queue[cursor]
                cursor = cursor + 1
                if label.key == goal then return label end
                for _, link in ipairs(graph.outgoing[label.key] or {}) do
                    local state = condition(link)
                    local copper = label.copper + (link.definition.copper or 0)
                    -- BFS visits labels in nondecreasing transfer count. Keep
                    -- a later arrival only if it saves money for another leg.
                    if state.possible and (state.allowed == true or relaxed)
                        and copper <= (context.budget or 0)
                        and (bestCopper[link.target] == nil or copper < bestCopper[link.target]) then
                        bestCopper[link.target] = copper
                        local arrival = { key = link.target, copper = copper, previous = label, link = link }
                        if link.target == goal then return arrival end
                        queue[#queue + 1] = arrival
                    end
                    checkpoint()
                end
                checkpoint()
            end
        end
        local winner, relaxed = search(false), false
        if not winner then winner, relaxed = search(true), true end
        if not winner then return "fallback" end
        local path = {}
        while winner.previous do
            path[#path + 1] = winner.link
            winner = winner.previous
            checkpoint()
        end
        if relaxed then
            local metadata = { blockers = {}, waitingData = false }
            for index = #path, 1, -1 do
                local link = path[index]
                local state = condition(link)
                if state.allowed ~= true then
                    metadata.blockers[#metadata.blockers + 1] = {
                        id = self.profile .. ":" .. link.definition.id .. link.suffix,
                        from = link.from, to = link.to, kind = link.definition.kind,
                        blockedRequirements = state.requirements,
                        instruction = self:GetInstruction(link.definition.kind, nil, link.to),
                    }
                    if state.allowed == nil then metadata.waitingData = true end
                end
                checkpoint()
            end
            return "no_path", nil, metadata
        end
        local result = { segments = {}, totalSeconds = 0, totalCopper = 0, resourcesUsed = {} }
        local position = context.start
        for index = #path, 1, -1 do
            local link = path[index]
            local selected = setmetatable({ connectionID = link.definition.id }, { __index = context })
            job.active = self:CreateEdgeBuild(selected)
            local status, edges, metadata
            repeat
                local remaining = job.deadline and math.max(0, job.deadline - job.clock()) or 1
                status, edges, metadata = job.active:Step(1, remaining)
                checkpoint()
            until status ~= "planning"
            job.active = nil
            if status == "cancelled" then return "cancelled" end
            local id = self.profile .. ":" .. link.definition.id .. link.suffix
            local chosen
            for _, edge in ipairs(edges or {}) do if edge.id == id then chosen = edge; break end end
            if not chosen then
                local blocked = {}
                for _, edge in ipairs(metadata and metadata.blockedEdges or {}) do
                    if edge.id == id then blocked[1] = edge; break end
                end
                return "no_path", nil, { blockers = blocked, waitingData = metadata and metadata.waitingData }
            end
            if not self:CanWalk(position, chosen.from) and (position.instanceID ~= chosen.from.instanceID
                or position.x ~= chosen.from.x or position.y ~= chosen.from.y
                or position.z ~= chosen.from.z or position.uiMapID ~= chosen.from.uiMapID) then return "fallback" end
            local walk = makeWalk(context, position, chosen.from)
            result.segments[#result.segments + 1] = walk
            result.segments[#result.segments + 1] = chosen
            result.totalSeconds = result.totalSeconds + walk.seconds + chosen.seconds
            result.totalCopper = result.totalCopper + (chosen.copper or 0)
            position = chosen.to
            checkpoint()
        end
        if not self:CanWalk(position, context.goal) and (position.instanceID ~= context.goal.instanceID
            or position.x ~= context.goal.x or position.y ~= context.goal.y
            or position.z ~= context.goal.z or position.uiMapID ~= context.goal.uiMapID) then return "fallback" end
        local walk = makeWalk(context, position, context.goal)
        result.segments[#result.segments + 1] = walk
        result.totalSeconds = result.totalSeconds + walk.seconds
        return "ready", result
    end)
    function job:Step(maxOperations, milliseconds)
        if self.status ~= "planning" then return self.status, self.result, self.metadata end
        if self.graph ~= self.owner.zoneGraph then self:Cancel(); return self.status end
        self.workLastStep = 0
        maxOperations, milliseconds = math.max(0, maxOperations or 64), math.max(0, milliseconds or 1)
        if maxOperations == 0 or milliseconds == 0 then return self.status end
        self.deadline = self.clock and self.clock() + milliseconds
        for operation = 1, maxOperations do
            if operation > 1 and self.deadline and self.clock() >= self.deadline then break end
            self.workLastStep = self.workLastStep + 1
            local ok, status, result, metadata = coroutine.resume(self.worker)
            if not ok then self.worker, self.status = nil, "failed"; error(status, 0) end
            if coroutine.status(self.worker) == "dead" then
                self.worker, self.status, self.result, self.metadata = nil, status, result, metadata
                break
            end
        end
        return self.status, self.result, self.metadata
    end
    function job:Cancel()
        if self.active then self.active:Cancel() end
        self.active, self.worker, self.result, self.status = nil, nil, nil, "cancelled"
    end
    job.owner = self
    return job
end
