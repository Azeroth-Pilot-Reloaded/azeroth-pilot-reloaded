-- Pure Lua 5.1 public API, job lifecycle and shared preparation/search budgets.
local _, namespace = ...
local Graph, Search = namespace.NavigationV2Graph, namespace.NavigationV2Search
local Finite = Graph.Finite
local Navigation, Planner, Job = {}, {}, {}
Planner.__index, Job.__index = Planner, Job

local DEFAULTS = Graph.Budgets
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

function Navigation.NewRetailMovement(observation, settings)
    if not namespace.NavigationV2Retail then return nil,'movement_unavailable' end
    return namespace.NavigationV2Retail.New(observation, settings)
end

local function MovementModule(profile)
    for _,name in ipairs({'NavigationV2Forever','NavigationV2Retail'}) do
        local api=namespace[name]
        if api and api.IsProfile(profile) then return api end
    end
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
    local limits=Graph.CaptureLimits(type(options)=='table' and options.limits)
    if not limits then return nil,'invalid_limits' end
    local context={tracker=namespace.NavigationV2Conditions.New(),bindings={},transports={},
        unlockProofs=type(options)=='table' and options.unlocks~=nil}
    local preparation, reason = Graph.New(graph,context,limits)
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
    if options.movement ~= nil and not MovementModule(options.movement) then return nil, 'invalid_movement_profile' end
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
    local unlocks
    if options.unlocks~=nil then
        if not namespace.NavigationV2Unlocks then return nil,'unlocks_unavailable' end
        unlocks,reason=namespace.NavigationV2Unlocks.New(options.unlocks,context)
        if not unlocks then return nil,reason end
    end
    return setmetatable({ preparation = preparation, clock = options.clock, profileClock = options.profileClock,
        unlocks=unlocks,
        conditions=context.tracker,conditionContext=context,deferConditions=options.deferConditions==true,conditionObservedCount=0,
        movement = options.movement, scheduled = scheduled, taxi=taxi, resources=resources,personal=personal,
        scheduledDeclarations=scheduled and namespace.NavigationV2WaypointTarget.Copy(options.scheduled),
        scheduledOverrides=scheduled and namespace.NavigationV2WaypointTarget.Copy(options.scheduledOverrides or {}),
        portals = portals, budgets = budgets,limits=limits, revision = 1, routeRevision=1, identity = {} }, Planner)
end

function Planner:ObserveConditions(observation)
    local changed,reason,recovered=self.conditions:Observe(observation)
    if changed==nil or reason then return changed,reason,recovered end
    if self.unlocks and self.unlocks:ObserveProofs() then changed=true end
    self.conditionObservedCount=self.conditions.dependencyCount
    if changed or recovered then self:Invalidate(not changed) end
    return changed,nil,recovered
end

function Planner:MarkConditionsDirty(dependencies)
    local changed,reason=self.conditions:MarkDirty(dependencies)
    if changed then self:Invalidate(true) end
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
    local api=MovementModule(profile)
    if not api then return nil, 'invalid_movement_profile' end
    if api.Same(self.movement, profile) then return false end
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
    self.scheduledDeclarations=namespace.NavigationV2WaypointTarget.Copy(declarations)
    self.scheduledOverrides=namespace.NavigationV2WaypointTarget.Copy(overrides or {})
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
    local actions=namespace.NavigationV2Actions
    if actions then
        if status=='complete' then
            if not actions.PublishResult(job,result) then status,reason='unknown','execution_snapshot_unavailable' end
        else actions.AbortResult(job) end
    end
    result.status, result.reason, result.optimal = status, reason, status == "complete"
    if status == "complete" then
        result.estimatedSeconds, result.segments, result.nodes = job.search.total, job.search.segments, job.search.nodes
        result.resourcesSpent = job.search.resourcesSpent
        if job.unlock then
            result.unlock={id=job.unlock.id,node=job.unlock.node,title=job.unlock.title}
            result.travelObjective=Graph.CaptureRequest(job.travelObjective)
            result.unlockEntry,result.unlockSequence=job.unlock,job.unlockSequence
            result.unlockPlan=job.unlockPlan
            result.optimal,result.reason,result.estimateScope=false,'prerequisite_approach','unlock_approach'
        end
    else
        result.estimatedSeconds, result.segments, result.nodes = nil, nil, nil
        result.unlock,result.unlockEntry,result.unlockSequence,result.travelObjective,result.estimateScope=nil,nil,nil,nil,nil
        result.unlockPlan=nil
    end
    job.result, job.search, job.chain = result, nil, nil
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

-- Continuations retain original ordered visits and the selected subobjective.
function Planner:PlanJourney(journey,context)
    if not namespace.NavigationV2Actions.IsJourney(journey) then return nil,'invalid_journey' end
    if journey.unlock and journey.unlock.owner==self.identity
        and not self.unlocks:CurrentProof(namespace.NavigationV2Actions.UnlockEntry(journey.unlock)) then
        journey.unlock=nil
    end
    local request=journey:OriginalRequest()
    if not request then return nil,'location_unknown' end
    local job=self:Plan(request,context)
    if journey.unlock then
        if journey.unlock.owner~=self.identity then job:Cancel();return nil,'stale_unlock' end
        journey.unlock.planRevision,journey.unlock.routeRevision=self.revision,self.routeRevision
    end
    return job
end

function Planner:UnlockReady(journey)
    if not namespace.NavigationV2Actions.IsJourney(journey) or not journey.unlock then return nil,'no_unlock' end
    local session=journey.unlock
    if session.owner~=self.identity or not self.unlocks then return nil,'stale_unlock' end
    if not journey.node then return nil,'location_unknown' end
    if not self.unlocks:Proven(namespace.NavigationV2Actions.UnlockEntry(session),session.sequence) then return false,'unlock_proof_required' end
    return true
end

function Planner:ResumeUnlock(journey,context)
    local mode,reason=self:UnlockContinuation(journey)
    if not mode then return nil,reason end
    if mode=='original' then journey.unlock=nil end
    return self:PlanJourney(journey,context)
end

function Planner:UnlockContinuation(journey)
    local ready,reason=self:UnlockReady(journey)
    if ready then return 'original' end
    if ready~=false then return nil,reason end
    local session=journey.unlock
    local entry=namespace.NavigationV2Actions.UnlockEntry(session)
    if self.conditions:IsCurrent(self.conditions:GetToken()) and (session.routeRevision~=self.routeRevision
        or (journey.node~=entry.node and session.planRevision~=self.revision
            and self.unlocks:Approachable(entry))) then return 'reconsider' end
    return nil,reason
end

function Planner:Invalidate(proofOnly)
    if self.costBatch then self.costBatchChanged=true;return end
    self.revision = self.revision + 1
    if not proofOnly then self.routeRevision=self.routeRevision+1 end
end

-- Adapter-generated numeric payloads, applied through existing catalogue
-- setters. Keep replacement-style settings whole and invalidate once per batch.
function Planner:ApplyCalibrationCosts(updates,revisionAtBoundary)
    local Copy=namespace.NavigationV2WaypointTarget.Copy
    local scheduled,reason
    self.costBatch,self.costBatchChanged=true,nil
    for _,update in ipairs(updates)do
        local changed
        if update.kind=='portal' then changed,reason=self:SetPortalCosts(update.id,update.costs)
        elseif update.kind=='personal' then changed,reason=self:SetPersonalCosts(update.id,update.costs)
        elseif update.kind=='taxi' then
            local costs=Copy(self.taxi.settings[update.id] or {})
            for key,value in pairs(update.costs)do costs[key]=value end
            changed,reason=self:SetTaxiCosts(update.id,costs)
        elseif update.kind=='scheduled' then
            scheduled=scheduled or Copy(self.scheduledOverrides)
            scheduled[update.id]=scheduled[update.id] or {}
            for key,value in pairs(update.costs)do scheduled[update.id][key]=value end
        else reason='invalid_calibration_update' end
        if reason then break end
    end
    if not reason and scheduled then
        local _
        _,reason=self:SetScheduled(self.scheduledDeclarations,scheduled)
    end
    local changed=self.costBatchChanged==true
    self.costBatch,self.costBatchChanged=nil,nil
    if changed and (revisionAtBoundary==nil or self.revision==revisionAtBoundary) then self:Invalidate() end
    if reason then return nil,reason end
    return changed
end

function Planner:IsCurrent(result)
    return type(result) == "table" and result.owner == self.identity and result.revision == self.revision
        and result.status == "complete" and self.conditions:IsCurrent(result.conditionToken)
        and (not namespace.NavigationV2Actions or namespace.NavigationV2Actions.CurrentResult(self,result))
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

-- Read one reconstructed segment per operation. Future conditional segments
-- are explanatory estimates only; execution receives the native-access prefix.
local function ChainResult(job)
    local chain,search=job.chain,job.search
    local segment=chain.segments[chain.index]
    if not segment then job.chain=nil;return 'complete','optimal_known_graph' end
    if segment.unlockEntry then
        local entry=segment.unlockEntry
        job.unlockPlan.steps[#job.unlockPlan.steps+1]={id=entry.id,node=entry.node,completionSeconds=entry.completionSeconds}
        if not job.unlock then
            job.unlock=job.planner.unlocks:PlanSelection(search,entry)
            job.unlockSequence=search.planSnapshot.sequence
            job.travelObjective={from=job.objective.from,to=entry.node,via={}}
        end
    elseif not job.unlock then
        search.segments[#search.segments+1]=segment
        search.nodes[#search.nodes+1]=chain.nodes[chain.index+1]
        search.total=search.total+segment.seconds
        for key,value in pairs(segment.resources or {})do search.resourcesSpent[key]=(search.resourcesSpent[key] or 0)+value end
    end
    chain.index=chain.index+1
end

local function Advance(job)
    if job.capturing then
        local ready,status,reason=namespace.NavigationV2Actions.PrepareResult(job)
        if ready then job.executionReady=true;return 'complete',job.completionReason end
        return status,reason
    end
    if job.unlock and not job.unlock.proof.ready then
        local ready,status,reason=job.planner.unlocks:TrackProof(job.unlock)
        if not ready then return status,reason end
        return
    end
    if job.chain then return ChainResult(job) end
    if job.search then
        local status,reason=job.search:Advance()
        if status=='complete' and job.planUnlocks then
            local search=job.search
            job.chain={segments=search.segments,nodes=search.nodes,index=1}
            job.unlockPlan={estimatedSeconds=search.total,conditional=true,
                optimal=not search.sawUnknown and not search.conditionUnknown and not search.unknownUnlockCosts
                    and not search.sawMissing and not search.sawIncomplete,
                scope='conditional_known_graph',steps={},resourcesSpent=search.resourcesSpent}
            search.total,search.segments,search.nodes,search.resourcesSpent=0,{},{job.objective.from},{}
            job.diagnostics.phase='unlock_reconstruction'
            return
        end
        if status=='no_path' and job.planner.unlocks and not job.unlockApproach and not job.planUnlocks then
            if job.search.provenNoPath and job.planner.unlocks:HasTimed(job.objective) then
                job.planUnlocks=job.planner.unlocks
                job.search:Cancel();job.search=nil
                job.diagnostics.phase='unlock_chains'
                return
            end
            local entry,why=job.planner.unlocks:Select(job.search,job.objective)
            job.diagnostics.unlockReason=why
            if entry then
                job.unlock,job.unlockSequence=entry,job.planner.conditions.snapshot.sequence
                job.travelObjective={from=job.objective.from,to=entry.node,via={}}
                job.unlockApproach=true;job.search:Cancel();job.search=nil
                job.diagnostics.phase='unlock_approach'
                return
            end
        end
        return status,reason
    end
    local preparation = job.planner.preparation
    local state, reason = preparation:Advance()
    job.diagnostics.phase = preparation.phase
    if state == "invalid" or state=='budget_exceeded' then return state, reason end
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
        if job.planner.unlocks and not job.planner.unlocksPrepared then
            job.diagnostics.phase='prepare_unlocks'
            local ready,status,why=job.planner.unlocks:Prepare(preparation.compiled)
            if not ready then return status,why end
            job.planner.unlocksPrepared=true
        end
        if job.planner.deferConditions and job.planner.conditionObservedCount<job.planner.conditions.dependencyCount then
            job.awaitingConditions=true;job.diagnostics.phase='observe_conditions';return
        end
        job.search = Search.New(preparation.compiled, job.travelObjective or job.objective, job.diagnostics, {
            planUnlocks=job.planUnlocks,limits=job.planner.limits,
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
        if status=='complete' and namespace.NavigationV2Actions and not self.executionReady then
            self.capturing,self.completionReason=true,reason
            self.diagnostics.phase='execution_snapshot'
            status=nil
        end
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
