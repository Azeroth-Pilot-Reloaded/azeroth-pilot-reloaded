-- Explicit path execution and transport dispatch. No WoW globals or interactions.
local _, ns = ...
local Finite = ns.NavigationV2Graph.Finite
local Copy = ns.NavigationV2WaypointTarget.Copy
local Actions, Travel, Journey = {}, {}, {}
Travel.__index, Journey.__index = Travel, Journey
-- Values never reference their weak keys. Execution data has no public alias.
local PENDING=setmetatable({}, {__mode='k'})
local CAPTURED=setmetatable({}, {__mode='k'})
local EXECUTIONS=setmetatable({}, {__mode='k'})
local UNLOCKS=setmetatable({}, {__mode='k'})

local function BeginCapture(job)
    local entry=job.unlock
    local source={objective=job.objective,segments=job.search.segments,owner=job.planner.identity,
        revision=job.revision,conditionToken=job.conditionToken,unlockSequence=job.unlockSequence}
    local seen={[job.planner.identity]=job.planner.identity,
        [job.conditionToken.owner]=job.conditionToken.owner}
    if entry then
        -- The selected result must not expose catalogue resource prices or the
        -- live tracker snapshot. These bounded maps/support are job-owned now.
        if entry.resources then entry.resources=Copy(entry.resources) end
        entry.proof={ready=entry.proof.ready,plan=entry.proof.plan,required=entry.proof.required}
        local selected={}
        for key,value in pairs(entry)do if key~='proof' then selected[key]=value end end
        -- Only completed support is execution data, not tracker/search history.
        selected.proof={ready=entry.proof.ready,plan=entry.proof.plan,required=entry.proof.required}
        source.unlockEntry=selected
        seen[entry.opens]=entry.opens
        if entry.eligible then seen[entry.eligible]=entry.eligible end
    end
    local copy={}
    seen[source]=copy
    return {copy=copy,seen=seen,stack={{source=source,target=copy}},fields=0}
end

-- Internal job seam: one copied table field or one stack exit per Advance.
function Actions.PrepareResult(job)
    local state=PENDING[job]
    if not state then state=BeginCapture(job);PENDING[job]=state end
    local frame=state.stack[#state.stack]
    if not frame then state.ready=true;return true end
    local key,value=next(frame.source,frame.cursor)
    if key==nil then state.stack[#state.stack]=nil;return false end
    if state.fields>=job.planner.limits.snapshotFields then return nil,'budget_exceeded','snapshot_limit' end
    state.fields=state.fields+1
    job.diagnostics.snapshotFields=state.fields
    frame.cursor=key
    if type(value)=='table' then
        local copy=state.seen[value]
        if not copy then
            copy={};state.seen[value]=copy
            state.stack[#state.stack+1]={source=value,target=copy}
        end
        value=copy
    end
    frame.target[key]=value
    return false
end

function Actions.PublishResult(job,result)
    local state=PENDING[job]
    if not state or not state.ready then return false end
    CAPTURED[result]=state.copy;PENDING[job]=nil
    return true
end

function Actions.AbortResult(job)PENDING[job]=nil end

function Actions.CurrentResult(planner,result)
    local plan=CAPTURED[result]
    return plan and plan.owner==planner.identity and plan.revision==planner.revision
        and planner.conditions:IsCurrent(plan.conditionToken) or false
end

function Actions.UnlockEntry(session)return UNLOCKS[session] end

local function Segments(travel)return EXECUTIONS[travel].segments end
local function Revision(value)
    return Finite(value) and value >= 1 and value % 1 == 0
end

function Journey:Locate(node)
    self.node = node
    while self.objective.via[self.viaIndex+1] == node do self.viaIndex = self.viaIndex+1 end
end

function Journey:Unlocate()
    self.node = nil
end

function Journey:OriginalRequest()
    if not self.node then return nil end
    local via = {}
    for i=self.viaIndex+1,#self.objective.via do via[#via+1] = self.objective.via[i] end
    return {from=self.node,to=self.objective.to,via=via}
end

function Journey:RemainingRequest()
    if self.unlock then
        if not self.node then return nil end
        return {from=self.node,to=UNLOCKS[self.unlock].node,via={}}
    end
    return self:OriginalRequest()
end

function Actions.IsJourney(journey)return getmetatable(journey)==Journey end

-- Localization belongs to the request, not to a replaceable guidance session.
function Actions.NewJourney(request)
    local objective = ns.NavigationV2Graph.CaptureRequest(request)
    if not objective then return nil, 'invalid_request' end
    local journey = setmetatable({objective=objective,viaIndex=0}, Journey)
    journey:Locate(objective.from)
    return journey
end

function Actions.New(planner, result, options, journey)
    if not planner:IsCurrent(result) then return nil, 'stale_result' end
    local plan=CAPTURED[result]
    if not plan then return nil,'stale_result' end
    if options ~= nil and type(options) ~= 'table' then return nil, 'invalid_travel_options' end
    options = options or {}
    local timeout = options.scheduledTimeoutSeconds
    local objectiveID = options.objectiveID
    if timeout == nil then timeout = 120 end
    if objectiveID == nil then objectiveID = 'navigation' end
    if not Finite(timeout) or timeout <= 0 or type(objectiveID) ~= 'string' or objectiveID == '' then
        return nil, 'invalid_travel_options'
    end
    if journey == nil then journey = Actions.NewJourney(plan.objective) end
    if getmetatable(journey) ~= Journey then return nil, 'invalid_journey' end
    if not journey.node then return nil, 'location_unknown' end
    if journey.node ~= plan.objective.from then return nil, 'location_changed' end
    if journey.unlock and journey.unlock.owner~=planner.identity then return nil,'stale_unlock' end
    if plan.unlockEntry then
        local entry=plan.unlockEntry
        journey.unlock={entry={id=entry.id,node=entry.node,title=entry.title},sequence=plan.unlockSequence,owner=planner.identity,
            planRevision=planner.revision,routeRevision=planner.routeRevision}
        UNLOCKS[journey.unlock]=entry
    else journey.unlock=nil end
    local travel = setmetatable({planner=planner,revision=planner.revision,
        conditionToken={owner=plan.conditionToken.owner,revision=plan.conditionToken.revision},
        journey=journey,
        preserveCommitted=options.preserveCommitted==true,
        index=1,sequence=0,state='moving',scheduledTimeoutSeconds=timeout,objectiveID=objectiveID}, Travel)
    EXECUTIONS[travel]=plan
    return travel
end

function Travel:Cancel(reason)
    if self.scheduledExecution then self.scheduledExecution:Cancel() end
    if self.personalExecution then self.personalExecution:Cancel(reason) end
    self.state, self.reason, self.deadline = 'cancelled', reason or 'cancelled', nil
    if self.measurement and not self.measurement.confirmed then self.measurement.cancelled=true end
    return self:GetAction()
end

function Travel:IsCommitted()
    if self.state=='cancelled' or self.state=='failed' then return false end
    if self.taxiPhase or self.state=='awaiting_transition' then return true end
    if self.personalExecution then
        local state=self.personalExecution:GetState()
        if state.status=='running' and state.phase=='awaiting_transition' then return true end
    end
    return self.scheduledExecution and self.scheduledExecution.status=='running'
        and self.scheduledExecution.departed==true or false
end

-- Receipts describe accepted execution boundaries, never native-event guesses.
local function MeasureStart(travel,kind,id,owner,attempt,now)
    travel.measurement={kind=kind,id=id,owner=owner,attempt=attempt,startedAt=now}
end

local function MeasureEnd(travel,now,confirmed)
    local receipt=travel.measurement
    if not receipt then return end
    receipt.endedAt=receipt.endedAt or now
    receipt.confirmed=confirmed==true
end

function Travel:GetMeasurement()return self.measurement end

local function Current(travel)
    local conditionCurrent=travel.planner.conditions:IsCurrent(travel.conditionToken)
    if (travel.revision ~= travel.planner.revision or not conditionCurrent) and travel.state ~= 'cancelled' then
        if travel.measurement and travel.measurement.confirmed
            and (travel.preserveCommitted or travel.measurement.kind=='personal') then
            if travel.state~='replan' then travel.state,travel.reason='replan','transport_arrival' end
            return
        end
        if travel.personalExecution and travel.personalExecution:GetState().status=='complete' then return end
        local personal=travel.personalExecution and travel.personalExecution:GetState()
        if personal and personal.status=='running' and personal.phase=='awaiting_transition'
            or travel.taxiPhase and travel.revision==travel.planner.revision
            or travel.preserveCommitted and travel:IsCommitted() then
            -- A bounded immutable execution receipt survives changed future plans.
            travel.revision=travel.planner.revision
            travel.conditionToken=travel.planner.conditions:GetToken()
            return
        end
        if travel.scheduledExecution then travel.scheduledExecution:Cancel() end
        travel.state, travel.reason, travel.deadline = 'cancelled', 'invalidated', nil
    end
end

local function PersonalAction(travel,segment)
    if not travel.personalExecution then
        local catalog=travel.planner.personal
        local snapshot=Copy(catalog.observation)
        snapshot.moneyCopper=travel.planner.resources and travel.planner.resources.money
        local frozen,reason=ns.NavigationV2Personal.New(catalog.entries,snapshot)
        if not frozen then travel.state,travel.reason='failed',reason;return travel:GetAction() end
        local ok,now=pcall(travel.planner.clock)
        local execution
        execution,reason=frozen:NewExecution(segment.personalId,{objectiveID=travel.objectiveID,
            now=ok and now or nil,from=segment.from})
        if not execution then travel.state,travel.reason='failed',reason;return travel:GetAction() end
        travel.personalExecution=execution
        travel.personalWaiting=execution:GetState().phase=='waiting'
    end
    local state=travel.personalExecution:GetState()
    if travel.personalWaiting and state.status=='running' and state.phase=='ready' then
        travel.state,travel.reason='replan','personal_ready'
        return travel:GetAction()
    end
    if state.status=='complete' then
        MeasureEnd(travel,travel.personalExecution.lastClock,true)
        travel.journey:Locate(segment.to)
        travel.index,travel.personalExecution,travel.state=travel.index+1,nil,'replan'
        return {kind='replan',reason='personal_arrival'}
    end
    if state.status~='running' then
        travel.state,travel.reason=state.status=='cancelled' and 'cancelled' or 'failed',state.reason
        return travel:GetAction()
    end
    return {kind='personal',actionKind=state.kind,personalId=state.personalId,phase=state.phase,
        status=state.status,title=state.title,instruction=state.instruction,spellID=state.spellID,itemID=state.itemID,
        attempt=state.attempt,deadline=state.deadline,remainingSeconds=state.remainingSeconds,readyAt=state.readyAt,
        objectiveID=state.objectiveID,innerAction=state,mode=segment.mode,transitionSeconds=segment.transitionSeconds}
end

function Travel:RemainingRequest()
    return self.journey:RemainingRequest()
end

local function ScheduledAction(travel, segment)
    local execution = travel.scheduledExecution
    if not execution then
        local ok, now = pcall(travel.planner.clock)
        if not ok then now = nil end
        local reason
        execution, reason = travel.planner.scheduled:NewExecution(segment.transportId,{
            objectiveID=travel.objectiveID,now=now,timeoutSeconds=travel.scheduledTimeoutSeconds})
        if not execution then travel.state,travel.reason='failed',reason; return travel:GetAction() end
        travel.scheduledExecution,travel.scheduledNow = execution,now
        travel.journey:Unlocate()
    end
    local state = execution:GetState()
    if state.status == 'complete' then
        travel.journey:Locate(segment.to)
        travel.index,travel.scheduledExecution = travel.index+1,nil
        return travel:GetAction()
    end
    if state.status ~= 'running' then
        travel.state,travel.reason = state.status == 'cancelled' and 'cancelled' or 'failed',state.reason
        return travel:GetAction()
    end
    return {kind='scheduled',phase=state.phase,transportId=state.routeID,
        objectiveID=state.objectiveID,attempt=state.attempt,instruction=state.instruction,target=state.target,wait=state.wait,
        deadline=state.deadline,remainingSeconds=state.deadline-travel.scheduledNow,mode=segment.mode,
        transitionSeconds=segment.transitionSeconds}
end

local function TaxiAction(travel, segment)
    local route=travel.planner.taxi.byId[segment.taxiId]
    local kind=travel.taxiPhase or (travel.atEntry and 'board_taxi' or 'approach')
    local approach=kind=='approach'
    return {kind=kind,taxiId=route.id,node=approach and route.from or nil,
        title=route.origin.title,position=approach and route.origin.position and Copy(route.origin.position) or nil,
        fareCopper=segment.fareCopper,deadline=travel.deadline,attempt=travel.attempt,
        remainingSeconds=travel.deadline and travel.deadline-travel.lastClock,
        mode=segment.mode,transitionSeconds=segment.transitionSeconds}
end

function Travel:GetAction()
    Current(self)
    local state = self.state
    if state == 'cancelled' or state == 'failed' then return {kind=state,reason=self.reason} end
    if state=='replan' then return {kind='replan',reason=self.reason or 'personal_arrival'} end
    local segment = Segments(self)[self.index]
    if not segment then
        local session=self.journey.unlock
        local unlock=session and UNLOCKS[session]
        if unlock then
            return {kind='unlock',unlockId=unlock.id,node=unlock.node,title=unlock.title,
                reason='unlock_proof_required'}
        end
        self.state='complete'; return {kind='complete'}
    end
    if segment.kind == 'scheduled' then return ScheduledAction(self, segment) end
    if segment.kind == 'taxi' then return TaxiAction(self,segment) end
    if segment.kind=='personal' then return PersonalAction(self,segment) end
    if segment.kind == 'portal' then
        local portal = self.planner.portals.byId[segment.portalId]
        return {kind=state == 'awaiting_transition' and state or (self.atEntry and 'use_portal' or 'approach'),
            portalId=portal.id,node=portal.from,title=portal.name,position=portal.entry and Copy(portal.entry),
            deadline=self.deadline,timeoutSeconds=portal.timeoutSeconds,attempt=self.attempt,
            remainingSeconds=self.deadline and self.deadline-self.lastClock,
            mode=segment.mode,transitionSeconds=segment.transitionSeconds}
    end
    local nextSegment = Segments(self)[self.index+1]
    local portal = nextSegment and nextSegment.kind == 'portal' and self.planner.portals.byId[nextSegment.portalId]
    local taxi=nextSegment and nextSegment.kind=='taxi' and self.planner.taxi.byId[nextSegment.taxiId]
    local position=(portal and portal.entry or taxi and taxi.origin.position) or nil
    return {kind='walk',node=segment.to,position=position and Copy(position),
        title=(portal and portal.name or taxi and taxi.origin.title) or nil,mode=segment.mode,transitionSeconds=segment.transitionSeconds}
end

function Travel:BeginPersonal()
    local action=self:Tick()
    if action.kind~='personal' or action.phase~='ready' then return nil,'personal_not_ready' end
    local _,reason=ns.NavigationV2Resources.Spend(self.planner.resources or {},{},Segments(self)[self.index].resources)
    if reason then return nil,reason end
    local ok,now=pcall(self.planner.clock)
    local state
    state,reason=self.personalExecution:BeginUse(ok and now or nil)
    if not state then return nil,reason end
    MeasureStart(self,'personal',state.personalId,self.personalExecution,state.attempt,state.usedAt)
    self.journey:Unlocate()
    return self:GetAction()
end

-- This only authorizes guidance for APR's secure/user gesture. Never buys a ride.
function Travel:BeginTaxi(quote, balances)
    local action=self:Tick()
    if action.kind~='board_taxi' then return nil,'taxi_not_ready' end
    local segment=Segments(self)[self.index]
    local captured,reason=ns.NavigationV2Resources.Capture(balances)
    if not captured then return nil,reason end
    local ready
    ready,reason=self.planner.taxi:Revalidate(segment.taxiId,segment.fareCopper,quote,captured)
    if not ready then return nil,reason end
    local ok,now=pcall(self.planner.clock)
    if not ok or not Finite(now) or now<0 then return nil,'clock_unavailable' end
    local deadline=now+self.planner.taxi.byId[segment.taxiId].timeoutSeconds
    if not Finite(deadline) or deadline<=now then return nil,'deadline_unavailable' end
    self.deadline,self.lastClock,self.attempt=deadline,now,{}
    self.taxiPhase,self.useSequence='awaiting_taxi',self.sequence
    self.journey:Unlocate()
    return self:GetAction()
end

local function AtStop(observation,stop,node)
    return observation.node==node and observation.stopID==stop.id and observation.worldID==stop.worldID
        and observation.floorID==stop.floorID and observation.phaseID==stop.phaseID
end

local function ObserveTaxi(travel,segment,observation)
    local route=travel.planner.taxi.byId[segment.taxiId]
    if not travel.taxiPhase then
        travel.atEntry=observation.onTaxi==false and AtStop(observation,route.origin,segment.from)
        if travel.atEntry then travel.journey:Locate(segment.from) else travel.journey:Unlocate() end
    elseif observation.attempt==travel.attempt and observation.taxiId==route.id
        and observation.sequence>travel.useSequence then
        if observation.failed==true then
            travel.state,travel.reason,travel.deadline='failed','taxi_failed',nil
        elseif observation.onTaxi==true then
            if not travel.taxiBoardedAt then
                travel.taxiBoardedAt=travel.lastClock
                MeasureStart(travel,'taxi',route.id,travel,travel.attempt,travel.lastClock)
            end
            travel.taxiPhase='riding_taxi'
        elseif travel.taxiPhase=='riding_taxi' and observation.onTaxi==false and observation.loading==false
            and AtStop(observation,route.destination,segment.to) then
            travel.journey:Locate(segment.to)
            MeasureEnd(travel,travel.lastClock,true)
            local duration=travel.taxiBoardedAt and travel.lastClock-travel.taxiBoardedAt
            if duration and duration>0 then travel.measuredTaxi={id=route.id,rideSeconds=duration} end
            travel.index,travel.taxiPhase,travel.atEntry,travel.deadline=travel.index+1,nil,nil,nil
            travel.taxiBoardedAt=nil
        end
    end
    return travel:GetAction()
end

function Travel:Tick()
    Current(self)
    if self.state == 'cancelled' or self.state == 'failed' then return self:GetAction() end
    if self.scheduledExecution then
        local ok, now = pcall(self.planner.clock)
        if not ok then now = nil end
        self.scheduledExecution:Tick(now)
        if Finite(now) then self.scheduledNow = now end
    end
    if self.personalExecution then
        local ok,now=pcall(self.planner.clock)
        self.personalExecution:Tick(ok and now or nil)
    end
    if self.deadline then
        local ok, now = pcall(self.planner.clock)
        if not ok or not Finite(now) or now < self.lastClock then
            self.state,self.reason,self.deadline='failed','clock_unavailable',nil
        elseif now >= self.deadline then
            self.state,self.reason,self.deadline='failed','transition_timeout',nil
        end
        if ok and Finite(now) then self.lastClock = now end
    end
    return self:GetAction()
end

-- Called by APR at the explicit user interaction boundary, never by proximity.
function Travel:BeginUse()
    local action = self:Tick()
    if action.kind ~= 'use_portal' then return nil, 'portal_not_ready' end
    local portal = self.planner.portals.byId[action.portalId]
    if portal.access ~= 'available' then return nil, 'portal_unavailable' end
    local ok, now = pcall(self.planner.clock)
    if not ok or not Finite(now) or now < 0 then return nil, 'clock_unavailable' end
    local deadline = now + portal.timeoutSeconds
    if not Finite(deadline) or deadline <= now then return nil, 'deadline_unavailable' end
    self.state,self.started,self.deadline,self.useSequence='awaiting_transition',now,deadline,self.sequence
    self.journey:Unlocate()
    self.lastClock = now
    self.attempt = {} -- Opaque per-use identity; a previous journey's proof cannot be reused.
    MeasureStart(self,'portal',portal.id,self,self.attempt,now)
    return self:GetAction()
end

function Travel:Observe(observation)
    local action = self:Tick()
    if action.kind == 'failed' or action.kind == 'cancelled' or action.kind == 'complete' or action.kind=='replan' then return action end
    if action.kind == 'scheduled' then
        local segment = Segments(self)[self.index]
        local departed=self.scheduledExecution.departed
        local state = self.scheduledExecution:Observe(observation, self.scheduledNow)
        if not departed and self.scheduledExecution.departed then
            MeasureStart(self,'scheduled',state.routeID,self.scheduledExecution,state.attempt,self.scheduledNow)
        end
        if state.phase=='disembarking' or state.status=='complete' then
            MeasureEnd(self,self.scheduledNow,state.status=='complete')
        end
        if state.status == 'complete' then self.journey:Locate(segment.to) else self.journey:Unlocate() end
        return self:GetAction()
    end
    if type(observation) ~= 'table' or not Revision(observation.sequence)
        or observation.sequence <= self.sequence then return action, 'stale_observation' end
    self.sequence = observation.sequence
    if action.kind=='personal' then
        local execution=self.personalExecution
        local state=execution:GetState()
        local proof=observation.transition
        local correlated=state.attempt and type(proof)=='table' and proof.attempt==state.attempt
        if observation.reliable==true and correlated then
            local d=execution.declaration
            if observation.failed==true then
                execution:Cancel('personal_failed');self.state,self.reason='failed','personal_failed'
            elseif proof.complete==true and observation.loading==false
                and (proof.personalId~=d.id or proof.from~=execution.from or proof.to~=d.to
                or observation.node~=d.to or observation.space~=d.destination.space or observation.phase~=d.destination.phase) then
                execution:Cancel('personal_destination_mismatch')
                self.state,self.reason='failed','personal_destination_mismatch'
            elseif observation.loading==false then execution:Observe(observation,execution.lastClock) end
        end
        return self:GetAction()
    end
    if observation.reliable ~= true or observation.loading == true then self.journey:Unlocate();return action end
    local segment = Segments(self)[self.index]
    if segment.kind=='taxi' then return ObserveTaxi(self,segment,observation) end
    if segment.kind ~= 'portal' then
        if observation.node == segment.to then self.journey:Locate(segment.to);self.index = self.index+1
        elseif observation.node == segment.from then self.journey:Locate(segment.from)
        else self.journey:Unlocate() end
        segment = Segments(self)[self.index]
        if not segment then return self:GetAction() end
    end
    if segment.kind == 'portal' then
        local portal, proof = self.planner.portals.byId[segment.portalId], observation.transition
        if self.state == 'awaiting_transition' then
            if observation.node == portal.to and observation.space == portal.destination.space
                and observation.phase == portal.destination.phase and type(proof) == 'table'
                and proof.portalId == portal.id and proof.from == portal.from and proof.to == portal.to
                and proof.complete == true and proof.attempt == self.attempt and observation.sequence > self.useSequence then
                self.index,self.atEntry,self.deadline,self.state=self.index+1,nil,nil,'moving'
                self.journey:Locate(portal.to)
                MeasureEnd(self,self.lastClock,true)
            end
        else
            self.atEntry = observation.node == portal.from and observation.phase == portal.phase
            if self.atEntry then self.journey:Locate(portal.from) else self.journey:Unlocate() end
        end
    end
    return self:GetAction()
end

ns.NavigationV2Actions = Actions
return Actions
