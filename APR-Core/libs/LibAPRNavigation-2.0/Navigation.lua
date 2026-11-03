-- Pure Lua 5.1 public API, job lifecycle and shared preparation/search budgets.
local _, namespace = ...
local Graph, Search = namespace.NavigationV2Graph, namespace.NavigationV2Search
local Finite = Graph.Finite
local Navigation, Planner, Job = {}, {}, {}
Planner.__index, Job.__index = Planner, Job

local DEFAULTS = { sliceMs = 1, cpuMs = 100, elapsedMs = 5000 }
local DEFAULT_OPERATIONS = 64

-- Explicit output creation only; New/Plan and jobs never publish waypoints.
function Navigation.NewWaypointSession(options)
    return namespace.NavigationV2WaypointSession.New(options)
end

function Navigation.NewForeverMovement(observation, settings)
    return namespace.NavigationV2Forever.New(observation, settings)
end

local function ReadClock(clock)
    local ok, value = pcall(clock)
    if ok and Finite(value) and value >= 0 then return value end
end

local function Budgets(options)
    if options ~= nil and type(options) ~= "table" then return nil end
    local result = {}
    for key, default in pairs(DEFAULTS) do
        local value = options and options[key]
        if value == nil then value = default end
        if not Finite(value) or value <= 0 then return nil end
        result[key] = value
    end
    for key in pairs(options or {}) do if not DEFAULTS[key] then return nil end end
    return result
end

function Navigation.New(graph, options)
    local preparation, reason = Graph.New(graph)
    if not preparation then return nil, reason end
    if type(options) ~= "table" or type(options.clock) ~= "function"
        or type(options.profileClock) ~= "function" then return nil, "invalid_clocks" end
    local budgets = Budgets(options.budgets)
    if not budgets then return nil, "invalid_budgets" end
    if not ReadClock(options.clock) or not ReadClock(options.profileClock) then return nil, "clock_unavailable" end
    if options.movement ~= nil and (not namespace.NavigationV2Forever
        or not namespace.NavigationV2Forever.IsProfile(options.movement)) then return nil, 'invalid_movement_profile' end
    local portals
    if options.portals ~= nil then
        if not namespace.NavigationV2Portals then return nil, 'portals_unavailable' end
        portals, reason = namespace.NavigationV2Portals.New(options.portals, options.portalObservation)
        if not portals then return nil, reason end
    end
    local scheduled
    if options.scheduled ~= nil then
        if not namespace.NavigationV2Scheduled then return nil, 'scheduled_unavailable' end
        scheduled, reason = namespace.NavigationV2Scheduled.NewCatalog(options.scheduled, options.scheduledOverrides)
        if not scheduled then return nil, reason end
    end
    return setmetatable({ preparation = preparation, clock = options.clock, profileClock = options.profileClock,
        movement = options.movement, scheduled = scheduled,
        portals = portals, budgets = budgets, revision = 1, identity = {} }, Planner)
end

function Planner:SetMovement(profile)
    if not namespace.NavigationV2Forever or not namespace.NavigationV2Forever.IsProfile(profile) then
        return nil, 'invalid_movement_profile'
    end
    if namespace.NavigationV2Forever.Same(self.movement, profile) then return false end
    self.movement = profile
    self:Invalidate()
    return true
end

function Planner:SetScheduled(declarations, overrides)
    if not namespace.NavigationV2Scheduled then return nil, 'scheduled_unavailable' end
    local catalog, reason = namespace.NavigationV2Scheduled.NewCatalog(declarations, overrides)
    if not catalog then return nil, reason end
    if self.scheduled and namespace.NavigationV2WaypointTarget.Same(self.scheduled.byId, catalog.byId) then return false end
    self.scheduled = catalog
    self.scheduledPrepared,self.scheduledCursor=nil,nil
    self:Invalidate()
    return true
end

function Planner:ObservePortals(observation)
    if not self.portals then return nil, 'portals_unavailable' end
    local changed, reason = self.portals:Observe(observation)
    if changed then self:Invalidate() end
    return changed, reason
end

function Planner:SetPortalCosts(id, costs)
    if not self.portals then return nil, 'portals_unavailable' end
    local changed, reason = self.portals:SetCosts(id, costs)
    if changed then self:Invalidate() end
    return changed, reason
end

function Navigation.NewJourney(request)
    return namespace.NavigationV2Actions.NewJourney(request)
end

function Planner:StartTravel(result, options, journey)
    return namespace.NavigationV2Actions.New(self, result, options, journey)
end

function Job:GetResult()
    if self.result then return self.result end
    local diagnostics = {}
    for key, value in pairs(self.diagnostics) do diagnostics[key] = value end
    return { status = "running", optimal = false, objective = self.objective,
        revision = self.revision, owner = self.planner.identity, diagnostics = diagnostics }
end

local function Finish(job, status, reason)
    if job.search then job.search:Cancel() end
    local result = job:GetResult()
    result.status, result.reason, result.optimal = status, reason, status == "complete"
    if status == "complete" then
        result.estimatedSeconds, result.segments, result.nodes = job.search.total, job.search.segments, job.search.nodes
    else
        result.estimatedSeconds, result.segments, result.nodes = nil, nil, nil
    end
    job.result, job.search = result, nil
    return result
end

function Planner:Plan(request, context)
    local job = setmetatable({ planner = self, revision = self.revision,
        objective = Graph.CaptureRequest(request), cpuMs = 0,
        diagnostics = { operations = 0, slices = 0, expanded = 0, relaxed = 0,
            preparedNodes = 0, preparedEdges = 0, cpuMs = 0, elapsedMs = 0,
            phase = self.preparation.phase } }, Job)
    if not job.objective then Finish(job, "invalid", "invalid_request"); return job end
    if context ~= nil and (type(context) ~= 'table'
        or (context.locationKnown ~= nil and type(context.locationKnown) ~= 'boolean')) then
        Finish(job, 'invalid', 'invalid_request_context'); return job
    end
    if context and context.locationKnown == false then
        Finish(job, 'unknown', 'location_unknown'); return job
    end
    job.started = ReadClock(self.clock)
    if not job.started then Finish(job, "unknown", "clock_unavailable"); return job end
    job.lastWall = job.started
    return job
end

function Planner:Invalidate()
    self.revision = self.revision + 1
end

function Planner:IsCurrent(result)
    return type(result) == "table" and result.owner == self.identity and result.revision == self.revision
        and result.status == "complete"
end

function Job:Cancel()
    if self.result then return self.result end
    return Finish(self, "cancelled", "cancelled")
end

local function Advance(job)
    if job.search then return job.search:Advance() end
    local preparation = job.planner.preparation
    local state, reason = preparation:Advance()
    job.diagnostics.phase = preparation.phase
    if state == "invalid" then return state, reason end
    if state == "node" then job.diagnostics.preparedNodes = job.diagnostics.preparedNodes + 1 end
    if state == "edge" then job.diagnostics.preparedEdges = job.diagnostics.preparedEdges + 1 end
    if state == "ready" then
        if job.planner.portals then
            job.diagnostics.phase = 'prepare_portals'
            local ready, status, portalReason = job.planner.portals:Prepare(preparation.compiled)
            if not ready then return status, portalReason end
        end
        if job.planner.scheduled and not job.planner.scheduledPrepared then
            local planner, graph = job.planner, preparation.compiled
            local id, route = next(planner.scheduled.byId,planner.scheduledCursor)
            job.diagnostics.phase = 'prepare_scheduled'
            if id then
                for _, node in ipairs({route.from,route.to}) do
                    local found, status, locateReason
                    if graph.partitioned then found,status,locateReason=graph:Locate(node)
                    else found=graph.index[node] end
                    if not found then return status or 'invalid',locateReason or 'invalid_transport_node' end
                end
                planner.scheduledCursor = id
                return
            end
            planner.scheduledPrepared = true
        end
        job.search = Search.New(preparation.compiled, job.objective, job.diagnostics, {
            portals = job.planner.portals, movement = job.planner.movement,
            scheduled = job.planner.scheduled, startedAt = job.started })
        job.diagnostics.phase = "validate_request"
    end
end

local function Sample(job, previousProfile)
    local wall = ReadClock(job.planner.clock)
    local profile = ReadClock(job.planner.profileClock)
    if not wall or not profile then return nil, nil, "clock_unavailable" end
    if wall < job.lastWall or (previousProfile and profile < previousProfile) then return nil, nil, "clock_regressed" end
    job.lastWall = wall
    job.diagnostics.elapsedMs = (wall - job.started) * 1000
    return wall, profile
end

local function BudgetReason(job)
    if job.diagnostics.elapsedMs >= job.planner.budgets.elapsedMs then return "elapsed_budget" end
    if job.cpuMs >= job.planner.budgets.cpuMs then return "cpu_budget" end
end

local function Stopped(job)
    if job.revision ~= job.planner.revision then return Finish(job, "stale", "invalidated") end
    return job.result
end

function Job:Step(maxOperations, maxMilliseconds)
    local stopped = Stopped(self)
    if stopped then return stopped end
    if maxOperations == nil then maxOperations = DEFAULT_OPERATIONS end
    if maxMilliseconds == nil then maxMilliseconds = self.planner.budgets.sliceMs end
    if not Finite(maxOperations) or maxOperations < 1 or maxOperations % 1 ~= 0
        or not Finite(maxMilliseconds) or maxMilliseconds <= 0 then return nil, "invalid_step_budget" end
    local _, started, clockReason = Sample(self)
    stopped = Stopped(self)
    if stopped then return stopped end
    if clockReason then return Finish(self, "unknown", clockReason) end
    local budgetReason = BudgetReason(self)
    if budgetReason then return Finish(self, "budget_exceeded", budgetReason) end
    local allowance = math.min(maxMilliseconds, self.planner.budgets.sliceMs)
    local previous, baseCpu = started, self.cpuMs
    self.diagnostics.slices = self.diagnostics.slices + 1
    for _ = 1, maxOperations do
        local status, reason = Advance(self)
        self.diagnostics.operations = self.diagnostics.operations + 1
        local _, profile, sampleReason = Sample(self, previous)
        stopped = Stopped(self)
        if stopped then return stopped end
        if sampleReason then return Finish(self, "unknown", sampleReason) end
        self.cpuMs = baseCpu + profile - started
        self.diagnostics.cpuMs, previous = self.cpuMs, profile
        budgetReason = BudgetReason(self)
        if budgetReason then return Finish(self, "budget_exceeded", budgetReason) end
        if status then return Finish(self, status, reason) end
        if profile - started >= allowance then break end
    end
    return self:GetResult()
end

function Navigation.NewSectorGraph(index, catalog, options)
    return namespace.NavigationV2Sectors.Source(index, catalog, options)
end

namespace.LibAPRNavigationV2 = Navigation
return Navigation
