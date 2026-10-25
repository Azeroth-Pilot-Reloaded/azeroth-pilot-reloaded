-- Preferred authored zone entrances bypass whole-world transport searches.
-- The host opts in; the generic shortest-time engine keeps its existing API.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("zone_routing", 3) then return end
local Instance = Lib.Instance
local Job = {}
Job.__index = Job

local function Walk(context, from, to)
    local speed = context.walkSpeedFor and context.walkSpeedFor(from, to) or context.walkSpeed or 7
    if type(speed) ~= "number" or speed ~= speed or speed <= 0 or speed == math.huge then speed = 7 end
    local dx, dy = to.x - from.x, to.y - from.y
    local dz = type(from.z) == "number" and type(to.z) == "number" and to.z - from.z or 0
    return { kind = "walk", from = from, to = to, copper = 0,
        seconds = math.sqrt(dx * dx + dy * dy + dz * dz) / speed }
end

function Instance:CreateZoneRoute(context)
    return setmetatable({ owner = self, context = context, status = "planning", phase = "lookup",
        mapID = context.goal and context.goal.uiMapID, seen = {}, depth = 0 }, Job)
end

function Job:AdvanceLookup()
    local data, context = self.owner, self.context
    local start, goal = context.start, context.goal
    if self.phase == "lookup" then
        if not start or not goal then self.status = "fallback"; return self.status end
        local id = (data.config.ZoneRoutes or {})[self.mapID]
        if data:CanWalk(start, goal) then
            -- Sharing a continent permits direct travel; it does not prove
            -- that travel beats a teleport or a chain of physical portals.
            -- Only nearby objectives can bypass the complete time comparison.
            local dx, dy = goal.x - start.x, goal.y - start.y
            local dz = type(start.z) == "number" and type(goal.z) == "number" and goal.z - start.z or 0
            local threshold = data.config.threshold or 2000
            if dx * dx + dy * dy + dz * dz > threshold * threshold then
                self.status = "fallback"
                return self.status
            end
            local walk = Walk(context, start, goal)
            self.result = { segments = { walk }, totalSeconds = walk.seconds, totalCopper = 0, resourcesUsed = {} }
            self.status = "ready"
            return self.status, self.result
        end
        if not id then
            -- Child maps inherit the listed outdoor entrance. Resolve one
            -- ancestor per operation; unknown/cyclic map records stay retryable.
            if not self.mapID or self.seen[self.mapID] or self.depth >= 50 then
                self.active, self.phase = data:CreateZoneGraphRoute(context, Walk), "graph"
                return "planning"
            end
            self.seen[self.mapID] = true
            self.depth = self.depth + 1
            local info = data:GetMapAncestryInfo(self.mapID)
            self.mapID = info and info.parentMapID
            if not self.mapID or self.mapID == 0 then
                self.active, self.phase = data:CreateZoneGraphRoute(context, Walk), "graph"
            end
            return self.status
        end
        local definition = data.connectionLookup[id]
        if not definition or definition.actions or definition.disabled
            or (definition.reviewStatus and definition.reviewStatus ~= "confirmed") then
            self.active, self.phase = data:CreateZoneGraphRoute(context, Walk), "graph"
            return self.status
        end
        local selected = {}
        for key, value in pairs(context) do selected[key] = value end
        selected.connectionID = id
        self.active, self.phase = data:CreateEdgeBuild(selected), "entrance"
        return "planning"
    end
end

function Job:Step(maxOperations, milliseconds)
    if self.status ~= "planning" then return self.status, self.result, self.metadata end
    maxOperations, milliseconds = math.max(0, maxOperations or 64), math.max(0, milliseconds or 1)
    self.workLastStep = 0
    if maxOperations == 0 or milliseconds == 0 then return self.status end
    local data, context = self.owner, self.context
    local start, goal = context.start, context.goal
    local clock = context.clock or data.env.clock
    local deadline = clock and clock() + milliseconds
    while self.phase == "lookup" and self.workLastStep < maxOperations do
        if self.workLastStep > 0 and deadline and clock() >= deadline then return "planning" end
        self.workLastStep = self.workLastStep + 1
        self:AdvanceLookup()
        if self.status ~= "planning" then return self.status, self.result, self.metadata end
    end
    local remaining = deadline and math.max(0, deadline - clock()) or milliseconds
    if self.phase == "lookup" or self.workLastStep >= maxOperations or remaining <= 0 then return "planning" end
    local status, edges, metadata = self.active:Step(maxOperations - self.workLastStep, remaining)
    self.workLastStep = self.workLastStep + (self.active.workLastStep or 1)
    if self.phase == "graph" then
        self.status, self.result, self.metadata = status, edges, metadata
        return status, edges, metadata
    end

    if status == "planning" then return status end
    if status == "cancelled" then self.status = status; return status end
    self.active = nil
    local blockers = metadata and metadata.blockedEdges
    if blockers and #blockers > 0 then
        self.status, self.metadata = "no_path", { blockers = blockers, waitingData = metadata.waitingData }
    elseif metadata and metadata.waitingData then
        self.status, self.metadata = "no_path", { waitingData = true }
    else
        local edge = edges and edges[1]
        if not edge or (edge.copper or 0) > (context.budget or 0) then
            self.status = "fallback"
        elseif not data:CanWalk(start, edge.from) or not data:CanWalk(edge.to, goal) then
            self.active, self.phase = data:CreateZoneGraphRoute(context, Walk), "graph"
        else
            local approach, arrival = Walk(context, start, edge.from), Walk(context, edge.to, goal)
            self.result = { segments = { approach, edge, arrival },
                totalSeconds = approach.seconds + edge.seconds + arrival.seconds,
                totalCopper = edge.copper or 0, resourcesUsed = {} }
            self.status = "ready"
        end
    end
    return self.status, self.result, self.metadata
end

function Job:Cancel()
    if self.active then self.active:Cancel() end
    self.active, self.context, self.result, self.status = nil, nil, nil, "cancelled"
end
