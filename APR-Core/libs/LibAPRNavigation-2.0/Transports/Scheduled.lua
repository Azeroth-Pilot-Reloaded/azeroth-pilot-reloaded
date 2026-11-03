-- Pure Lua 5.1 scheduled transport data, FIFO costs and bounded execution.
-- Observations are trusted host evidence, never guesses from proximity/loading.
local _, namespace = ...
local Finite = namespace.NavigationV2Graph.Finite
local Target = namespace.NavigationV2WaypointTarget
local Scheduled, Execution, Catalog = {}, {}, {}
Execution.__index, Catalog.__index = Execution, Catalog
local MAX_ROUTES = 256
local COST_FIELDS = { "approach", "boarding", "ride", "loading", "disembark", "final" }
local KINDS = { boat = true, zeppelin = true, elevator = true, tram = true }

local function Identifier(value)
    return type(value) == "string" and value ~= ""
end

local function Nonnegative(value)
    return Finite(value) and value >= 0
end

local function Integer(value)
    return Nonnegative(value) and value % 1 == 0
end

local function Position(value)
    if type(value) ~= "table" or not Integer(value.mapID) or value.mapID == 0
        or not Finite(value.x) or value.x < 0 or value.x > 1
        or not Finite(value.y) or value.y < 0 or value.y > 1 then return nil end
    return { mapID = value.mapID, x = value.x, y = value.y }
end

local function Stop(value)
    if type(value) ~= "table" or not Identifier(value.id) or not Integer(value.worldID)
        or not Integer(value.floorID) or not Identifier(value.phaseID) then return nil end
    local position = value.position and Position(value.position)
    if value.position ~= nil and not position then return nil end
    return { id = value.id, worldID = value.worldID, floorID = value.floorID,
        phaseID = value.phaseID, title = Target.Text(value.title), position = position }
end

local function Wait(value)
    if type(value) ~= "table" then return nil end
    if value.mode == "known" or value.mode == "estimated" then
        if not Nonnegative(value.seconds) or (value.mode == "estimated" and value.seconds == 0) then return nil end
        return { mode = value.mode, seconds = value.seconds }
    end
    if value.mode == "periodic" and Nonnegative(value.firstDeparture)
        and Finite(value.periodSeconds) and value.periodSeconds > 0 then
        return { mode = value.mode, firstDeparture = value.firstDeparture,
            periodSeconds = value.periodSeconds }
    end
end

local function Costs(source, overrides)
    if type(source) ~= "table" or type(overrides) ~= "table" then return nil end
    local allowed, costs, total = { wait = true }, {}, 0
    for _, field in ipairs(COST_FIELDS) do
        allowed[field] = true
        local value = overrides[field]
        if value == nil then value = source[field] end
        if not Nonnegative(value) then return nil end
        costs[field], total = value, total + value
    end
    for key in pairs(overrides) do if not allowed[key] then return nil end end
    if not Finite(total) then return nil end
    return costs, total
end

-- A declared total is an alternative model, never a fabricated timetable or
-- decomposition. Component overrides cannot partially modify an aggregate.
local function CostModel(declaration, overrides)
    if declaration.totalSeconds~=nil then
        if not Nonnegative(declaration.totalSeconds) or declaration.costs~=nil or declaration.wait~=nil then
            return nil,'invalid_scheduled_total'
        end
        for key in pairs(overrides) do
            if key~='totalSeconds' then return nil,'invalid_scheduled_total_override' end
        end
        local total=overrides.totalSeconds
        if total==nil then total=declaration.totalSeconds end
        if not Nonnegative(total) then return nil,'invalid_scheduled_total' end
        return {totalSeconds=total,seconds=total}
    end
    local costs,base=Costs(declaration.costs,overrides)
    if not costs then return nil,'invalid_scheduled_costs' end
    local source=overrides.wait
    if source==nil then source=declaration.wait end
    local wait=Wait(source)
    if not wait then return nil,'unknown_scheduled_wait' end
    local seconds=wait.seconds and base+wait.seconds
    if seconds and not Finite(seconds) then return nil,'scheduled_cost_overflow' end
    return {costs=costs,baseSeconds=base,wait=wait,seconds=seconds}
end

-- Capture once per planning request. Treat the returned route as immutable.
-- Periodic routes deliberately have no static seconds: use Cost at relaxation.
function Scheduled.Compile(declaration, overrides)
    if type(declaration) ~= "table" or not Identifier(declaration.id) or not KINDS[declaration.kind]
        or not Identifier(declaration.from) or not Identifier(declaration.to)
        or declaration.from == declaration.to then return nil, "invalid_scheduled_route" end
    if overrides == nil then overrides = {} end
    if type(overrides)~='table' then return nil,'invalid_scheduled_costs' end
    local model,reason=CostModel(declaration,overrides)
    if not model then return nil,reason end
    local origin, destination = Stop(declaration.origin), Stop(declaration.destination)
    if not origin or not destination then return nil, "invalid_scheduled_stops" end
    if origin.id == destination.id and origin.worldID == destination.worldID
        and origin.floorID == destination.floorID and origin.phaseID == destination.phaseID then
        return nil, "identical_scheduled_stops"
    end
    local access = declaration.access
    if access == nil then access = "unknown" end
    if access ~= "available" and access ~= "unavailable" and access ~= "unknown" then return nil, "invalid_scheduled_access" end
    return { id = declaration.id, kind = declaration.kind, from = declaration.from, to = declaration.to, access = access,
        origin = origin, destination = destination,
        costs = model.costs, baseSeconds = model.baseSeconds, wait = model.wait,
        seconds = model.seconds,totalSeconds=model.totalSeconds }
end

-- elapsedSeconds is the cost of preceding legs; startedAt is a frozen epoch in
-- the timetable's clock domain. Boarding must finish before the chosen departure.
-- Only fixed waits and known FIFO periodic departures are supported.
function Scheduled.Cost(route, elapsedSeconds, startedAt)
    if type(route)=='table' and route.totalSeconds~=nil then
        if not Nonnegative(route.totalSeconds) or route.costs~=nil or route.wait~=nil then
            return nil,'invalid_scheduled_route'
        end
        if not Nonnegative(elapsedSeconds) then return nil,'invalid_elapsed_cost' end
        return route.totalSeconds,{totalSeconds=route.totalSeconds}
    end
    if type(route) ~= "table" or not Finite(route.baseSeconds) or type(route.wait) ~= "table"
        or type(route.costs) ~= "table" then return nil, "invalid_scheduled_route" end
    if not Nonnegative(elapsedSeconds) then return nil, "invalid_elapsed_cost" end
    local wait, departure = route.wait.seconds, nil
    if route.wait.mode == "periodic" then
        if not Nonnegative(startedAt) then return nil, "unknown_schedule_epoch" end
        local ready = startedAt + elapsedSeconds + route.costs.approach + route.costs.boarding
        if not Finite(ready) then return nil, "scheduled_cost_overflow" end
        local cycles = math.max(0, math.ceil((ready - route.wait.firstDeparture) / route.wait.periodSeconds))
        departure = route.wait.firstDeparture + cycles * route.wait.periodSeconds
        wait = departure - ready
    end
    local total = wait and route.baseSeconds + wait
    if not Nonnegative(wait) or not Nonnegative(total) then return nil, "scheduled_cost_overflow" end
    local detail = Target.Copy(route.costs)
    detail.waitSeconds, detail.waitMode, detail.departureAt = wait, route.wait.mode, departure
    return total, detail
end

-- Small immutable adjacency overlay, not a graph or a search engine. Installing
-- another catalogue/settings snapshot requires planner invalidation by its owner.
function Scheduled.NewCatalog(declarations, overrides)
    if type(declarations) ~= "table" or (overrides ~= nil and type(overrides) ~= "table") then
        return nil, "invalid_scheduled_catalog"
    end
    local catalog = setmetatable({ byId = {}, outgoing = {} }, Catalog)
    local count, maximum = 0, 0
    for key, declaration in pairs(declarations) do
        if not Integer(key) or key < 1 or key > MAX_ROUTES then return nil, "invalid_scheduled_catalog" end
        local settings = type(declaration) == "table" and overrides and overrides[declaration.id]
        local route, reason = Scheduled.Compile(declaration, settings)
        if not route then return nil, reason end
        if catalog.byId[route.id] then return nil, "duplicate_scheduled_route" end
        count, maximum = count + 1, math.max(maximum, key)
        catalog.byId[route.id] = route
        local outgoing = catalog.outgoing[route.from] or {}
        catalog.outgoing[route.from] = outgoing
        outgoing[#outgoing + 1] = route
    end
    if count ~= maximum then return nil, "invalid_scheduled_catalog" end
    return catalog
end

-- arrivalSeconds is the absolute label arrival epoch BEFORE this edge's own
-- approach/boarding, not the initial request time. nil+reason is an unknown cost,
-- distinct from nil alone (end of adjacency); a planner must preserve that reason.
function Catalog:Edge(node, cursor, arrivalSeconds)
    local route = (self.outgoing[node] or {})[cursor]
    if not route then return nil end
    local seconds, detail = Scheduled.Cost(route, 0, arrivalSeconds)
    if not seconds then return nil, detail end
    return { id = "scheduled:" .. route.id, from = route.from, to = route.to, seconds = seconds,
        access = route.access, kind = "scheduled", transportId = route.id, costDetail = detail }
end

function Catalog:NewExecution(id, options)
    local route = self.byId[id]
    if not route then return nil, "unknown_scheduled_route" end
    return Scheduled.New(route, options)
end

function Scheduled.New(declaration, options)
    if type(options) ~= "table" or not Identifier(options.objectiveID) or not Nonnegative(options.now)
        or not Finite(options.timeoutSeconds) or options.timeoutSeconds <= 0
        or not Finite(options.now + options.timeoutSeconds) then return nil, "invalid_execution_options" end
    local route, reason = Scheduled.Compile(declaration, options.overrides)
    if not route then return nil, reason end
    return setmetatable({ route = route, objectiveID = options.objectiveID,
        status = "running", phase = "approach", revision = 1, sequence = 0,
        attempt = {},
        lastTime = options.now, deadline = options.now + options.timeoutSeconds }, Execution)
end

local function GuidanceTarget(execution)
    local stop
    if execution.phase == "approach" or execution.phase == "boarding" then stop = execution.route.origin end
    if execution.phase == "disembarking" then stop = execution.route.destination end
    if not stop or not stop.position or execution.status ~= "running" then return nil end
    return { key = execution.route.id .. ":" .. execution.phase,
        title = stop.title, position = Target.Copy(stop.position) }
end

function Execution:GetState()
    return { status = self.status, phase = self.phase, reason = self.reason, revision = self.revision,
        routeID = self.route.id, objectiveID = self.objectiveID, deadline = self.deadline, attempt = self.attempt,
        instruction = { kind = self.route.kind, phase = self.phase },
        wait = self.route.wait and Target.Copy(self.route.wait), target = GuidanceTarget(self) }
end

local function Finish(execution, status, reason)
    execution.status, execution.reason = status, reason
    execution.revision = execution.revision + 1
    if status == "complete" then execution.phase = "complete" end
    return execution:GetState()
end

function Execution:Tick(now)
    if self.status ~= "running" then return self:GetState() end
    if not Nonnegative(now) then return Finish(self, "unknown", "clock_unavailable") end
    if now < self.lastTime then return Finish(self, "unknown", "clock_regressed") end
    self.lastTime = now
    if now >= self.deadline then return Finish(self, "timeout", "transport_deadline") end
    return self:GetState()
end

function Execution:Cancel()
    if self.status ~= "running" then return self:GetState() end
    return Finish(self, "cancelled", "cancelled")
end

local function AtStop(observation, stop)
    return observation.stopID == stop.id and observation.worldID == stop.worldID
        and observation.floorID == stop.floorID and observation.phaseID == stop.phaseID
end

local function Advance(execution, observation)
    local phase, kind = execution.phase, observation.kind
    local origin, destination = execution.route.origin, execution.route.destination
    if phase == "approach" and kind == "origin" and observation.onTransport == false then
        if not AtStop(observation, origin) then return nil, "wrong_origin" end
        return "waiting"
    end
    if phase == "waiting" and kind == "transport_ready" and observation.onTransport == false
        and AtStop(observation, origin) then return "boarding" end
    if phase == "boarding" and kind == "boarded" and observation.onTransport == true
        and AtStop(observation, origin) then return "riding" end
    if phase == "riding" and kind == "departed" and observation.onTransport == true then
        execution.departed = true
    end
    if phase == "riding" and kind == "destination" and execution.departed
        and observation.onTransport == true and AtStop(observation, destination) then return "disembarking" end
    if phase == "disembarking" and kind == "disembarked" and observation.onTransport == false
        and AtStop(observation, destination) then return "complete" end
end

function Execution:Observe(observation, now)
    local state = self:Tick(now)
    if self.status ~= "running" or type(observation) ~= "table" then return state end
    if observation.objectiveID ~= self.objectiveID then
        if Identifier(observation.objectiveID) then return Finish(self, "stale", "objective_changed") end
        return state, "unconfirmed_observation"
    end
    if not Integer(observation.sequence) or observation.sequence <= self.sequence then return state, "old_observation" end
    if observation.routeID ~= self.route.id or observation.confirmed ~= true
        or observation.attempt ~= self.attempt or observation.loading == true then return state, "unconfirmed_observation" end
    self.sequence = observation.sequence
    local phase, reason = Advance(self, observation)
    if phase == "complete" then return Finish(self, "complete", "disembarkation_confirmed") end
    if phase then self.phase, self.revision = phase, self.revision + 1 end
    return self:GetState(), reason
end

namespace.NavigationV2Scheduled = Scheduled
return Scheduled
