-- Pure Lua 5.1 public API, job lifecycle and shared preparation/search budgets.
local _, namespace = ...
local Graph, Search = namespace.NavigationV2Graph, namespace.NavigationV2Search
local Finite = Graph.Finite
local Navigation, Planner, Job = {}, {}, {}
Planner.__index, Job.__index = Planner, Job

local DEFAULTS = { sliceMs = 1, cpuMs = 100, elapsedMs = 5000 }
local DEFAULT_OPERATIONS = 64

local function PersonalKeys(catalog)
    if not catalog then return end
    local keys={money=true}
    for _,name in pairs(catalog.itemResources) do keys['item:'..name]=true end
    for _,d in ipairs(catalog.entries) do
        if d.chargeBased or d.cooldownSeconds>0 then keys['personal:'..d.useResourceId]=true end
    end
    return keys
end

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
    local context={tracker=namespace.NavigationV2Conditions.New(),bindings={},transports={}}
    local preparation, reason = Graph.New(graph,context)
    if not preparation then return nil, reason end
    if type(options) ~= "table" or type(options.clock) ~= "function"
        or type(options.profileClock) ~= "function" then return nil, "invalid_clocks" end
    if options.deferConditions~=nil and type(options.deferConditions)~='boolean' then return nil,'invalid_condition_options' end
    if options.conditionObservation~=nil then
        local accepted
        accepted,reason=context.tracker:Observe(options.conditionObservation)
        if accepted==nil then return nil,reason end
    end
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
    local resources
    if options.resources ~= nil then
        resources, reason = namespace.NavigationV2Resources.Capture(options.resources)
        if not resources then return nil,reason end
    end
    local taxi
    if options.taxi ~= nil then
        taxi, reason = namespace.NavigationV2Taxi.New(options.taxi,options.taxiObservation,options.taxiSettings)
        if not taxi then return nil,reason end
    end
    local personal
    if options.personal~=nil then
        personal,reason=namespace.NavigationV2Personal.New(options.personal,options.personalObservation)
        if not personal then return nil,reason end
        resources,reason=namespace.NavigationV2Resources.Merge(resources or {},personal:Resources(),PersonalKeys(personal))
        if not resources then return nil,reason end
    end
    for kind,source in pairs({portal=options.portals,scheduled=options.scheduled,taxi=options.taxi,personal=options.personal}) do
        local bindings={}
        for _,declaration in ipairs(source) do
            local binding
            binding,reason=Graph.BindRequirements(context,declaration.requirements)
            if reason then return nil,reason end
            bindings[declaration.id]=binding
        end
        context.transports[kind]=bindings
    end
    return setmetatable({ preparation = preparation, clock = options.clock, profileClock = options.profileClock,
        conditions=context.tracker,conditionContext=context,deferConditions=options.deferConditions==true,conditionObservedCount=0,
        movement = options.movement, scheduled = scheduled, taxi=taxi, resources=resources,personal=personal,
        portals = portals, budgets = budgets, revision = 1, identity = {} }, Planner)
end

function Planner:ObserveConditions(observation)
    local changed,reason,recovered=self.conditions:Observe(observation)
    if changed==nil or reason then return changed,reason,recovered end
    self.conditionObservedCount=self.conditions.dependencyCount
    if changed or recovered then self:Invalidate() end
    return changed,nil,recovered
end

function Planner:MarkConditionsDirty(dependencies)
    local changed,reason=self.conditions:MarkDirty(dependencies)
    if changed then self:Invalidate() end
    return changed,reason
end

function Planner:SetResources(source)
    local resources, reason = namespace.NavigationV2Resources.Capture(source,PersonalKeys(self.personal))
    if not resources then return nil,reason end
    if namespace.NavigationV2WaypointTarget.Same(self.resources,resources) then return false end
    self.resources=resources;self:Invalidate();return true
end

function Planner:ObservePersonal(observation)
    if not self.personal then return nil,'personal_unavailable' end
    -- Validate the whole next snapshot/resource map before replacing live state.
    local candidate,reason=namespace.NavigationV2Personal.New(self.personal.entries,self.personal.observation)
    if not candidate then return nil,reason end
    local changed
    changed,reason=candidate:Observe(observation)
    if changed==nil or reason=='stale_observation' then return changed,reason end
    local resources
    resources,reason=namespace.NavigationV2Resources.Merge(self.resources or {},candidate:Resources(),PersonalKeys(candidate))
    if not resources then return nil,reason end
    local different=not namespace.NavigationV2WaypointTarget.Same(self.resources,resources)
    candidate.prepared,candidate.cursor=self.personal.prepared,self.personal.cursor
    self.personal,self.resources=candidate,resources
    if changed or different then self:Invalidate() end
    return changed or different
end

function Planner:SetPersonalCosts(id,costs)
    if not self.personal then return nil,'personal_unavailable' end
    local changed,reason=self.personal:SetCosts(id,costs)
    if changed then self:Invalidate() end
    return changed,reason
end

function Planner:ObserveTaxi(observation)
    if not self.taxi then return nil,'taxi_unavailable' end
    local changed, reason = self.taxi:Observe(observation)
    if changed then self:Invalidate() end
    return changed,reason
end

function Planner:SetTaxiCosts(id,costs)
    if not self.taxi then return nil,'taxi_unavailable' end
    local changed,reason=self.taxi:SetCosts(id,costs)
    if changed then self:Invalidate() end
    return changed,reason
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
    -- Requirements are compiled configuration, like node/zone declarations.
    -- Changing their ownership needs a fresh planner, so removed facts cannot
    -- leak subscriptions or old access proof into a replacement catalogue.
    local bindings={}
    for _,declaration in ipairs(declarations) do
        local binding
        binding,reason=Graph.BindRequirements(self.conditionContext,declaration.requirements,true)
        if reason then return nil,reason end
        bindings[declaration.id]=binding
    end
    local previous=self.conditionContext.transports.scheduled or {}
    for id,binding in pairs(previous) do
        if bindings[id]~=binding then return nil,'condition_reconfiguration_requires_enable' end
    end
    for id,binding in pairs(bindings) do
        if previous[id]~=binding then return nil,'condition_reconfiguration_requires_enable' end
    end
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
    return { status = self.awaitingConditions and 'observation_required' or "running", optimal = false, objective = self.objective,
        reason=self.awaitingConditions and 'conditions' or nil,conditionToken=self.conditionToken,
        revision = self.revision, owner = self.planner.identity, diagnostics = diagnostics }
end

local function Finish(job, status, reason)
    if job.search then job.search:Cancel() end
    local result = job:GetResult()
    result.status, result.reason, result.optimal = status, reason, status == "complete"
    if status == "complete" then
        result.estimatedSeconds, result.segments, result.nodes = job.search.total, job.search.segments, job.search.nodes
        result.resourcesSpent = job.search.resourcesSpent
    else
        result.estimatedSeconds, result.segments, result.nodes = nil, nil, nil
    end
    job.result, job.search = result, nil
    return result
end

function Planner:Plan(request, context)
    local job = setmetatable({ planner = self, revision = self.revision,
        conditionToken=self.conditions:GetToken(),
        objective = Graph.CaptureRequest(request), cpuMs = 0,
        diagnostics = { operations = 0, slices = 0, expanded = 0, relaxed = 0,
            preparedNodes = 0, preparedEdges = 0, cpuMs = 0, elapsedMs = 0,
            phase = self.preparation.phase } }, Job)
    if not job.objective then Finish(job, "invalid", "invalid_request"); return job end
    if context ~= nil and (type(context) ~= 'table'
        or (context.locationKnown ~= nil and type(context.locationKnown) ~= 'boolean')
        or (context.locationReason ~= nil and type(context.locationReason) ~= 'string')) then
        Finish(job, 'invalid', 'invalid_request_context'); return job
    end
    if context and context.locationKnown == false then
        Finish(job, 'unknown', context.locationReason or 'location_unknown'); return job
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
        and result.status == "complete" and self.conditions:IsCurrent(result.conditionToken)
end

-- Only a pre-search suspended job may adopt freshly captured dependencies.
-- This is the same objective/job/budget, never a retry of an unchanged query.
function Job:ContinueConditions(observation)
    if self.result or not self.awaitingConditions then return nil,'conditions_not_requested' end
    if self.revision~=self.planner.revision then return nil,'stale_job' end
    local changed,reason,recovered=self.planner:ObserveConditions(observation)
    if changed==nil or reason then return nil,reason end
    self.revision,self.conditionToken=self.planner.revision,self.planner.conditions:GetToken()
    self.awaitingConditions=nil
    return self:GetResult(),nil,recovered
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
        if job.planner.taxi then
            local ready, status, taxiReason = job.planner.taxi:Prepare(preparation.compiled)
            if not ready then return status,taxiReason end
        end
        if job.planner.personal then
            local ready,status,personalReason=job.planner.personal:Prepare(preparation.compiled)
            if not ready then return status,personalReason end
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
        if job.planner.deferConditions and job.planner.conditionObservedCount<job.planner.conditions.dependencyCount then
            job.awaitingConditions=true;job.diagnostics.phase='observe_conditions';return
        end
        job.search = Search.New(preparation.compiled, job.objective, job.diagnostics, {
            conditions=job.planner.conditionContext,
            portals = job.planner.portals, movement = job.planner.movement,
            scheduled = job.planner.scheduled, taxi=job.planner.taxi,personal=job.planner.personal,
            resources=job.planner.resources,startedAt = job.started })
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
    if not job.planner.conditions:IsCurrent(job.conditionToken) then return Finish(job,'stale','conditions_invalidated') end
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
    if self.awaitingConditions then return self:GetResult() end
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
        if self.awaitingConditions then return self:GetResult() end
        if profile - started >= allowance then break end
    end
    return self:GetResult()
end

function Navigation.NewSectorGraph(index, catalog, options)
    return namespace.NavigationV2Sectors.Source(index, catalog, options)
end

namespace.LibAPRNavigationV2 = Navigation
return Navigation
