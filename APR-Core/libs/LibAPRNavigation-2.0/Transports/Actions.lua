-- Explicit path execution and transport dispatch. No WoW globals or interactions.
local _, ns = ...
local Finite = ns.NavigationV2Graph.Finite
local Copy = ns.NavigationV2WaypointTarget.Copy
local Actions, Travel, Journey = {}, {}, {}
Travel.__index, Journey.__index = Travel, Journey
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

function Journey:RemainingRequest()
    if not self.node then return nil end
    local via = {}
    for i=self.viaIndex+1,#self.objective.via do via[#via+1] = self.objective.via[i] end
    return {from=self.node,to=self.objective.to,via=via}
end

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
    if options ~= nil and type(options) ~= 'table' then return nil, 'invalid_travel_options' end
    options = options or {}
    local timeout = options.scheduledTimeoutSeconds
    local objectiveID = options.objectiveID
    if timeout == nil then timeout = 120 end
    if objectiveID == nil then objectiveID = 'navigation' end
    if not Finite(timeout) or timeout <= 0 or type(objectiveID) ~= 'string' or objectiveID == '' then
        return nil, 'invalid_travel_options'
    end
    if journey == nil then journey = Actions.NewJourney(result.objective) end
    if getmetatable(journey) ~= Journey then return nil, 'invalid_journey' end
    if not journey.node then return nil, 'location_unknown' end
    if journey.node ~= result.objective.from then return nil, 'location_changed' end
    local travel = setmetatable({planner=planner,revision=planner.revision,segments=Copy(result.segments),
        journey=journey,
        index=1,sequence=0,state='moving',scheduledTimeoutSeconds=timeout,objectiveID=objectiveID}, Travel)
    return travel
end

function Travel:Cancel(reason)
    if self.scheduledExecution then self.scheduledExecution:Cancel() end
    self.state, self.reason, self.deadline = 'cancelled', reason or 'cancelled', nil
    return self:GetAction()
end

local function Current(travel)
    if travel.revision ~= travel.planner.revision and travel.state ~= 'cancelled' then
        if travel.scheduledExecution then travel.scheduledExecution:Cancel() end
        travel.state, travel.reason, travel.deadline = 'cancelled', 'invalidated', nil
    end
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

function Travel:GetAction()
    Current(self)
    local state = self.state
    if state == 'cancelled' or state == 'failed' then return {kind=state,reason=self.reason} end
    local segment = self.segments[self.index]
    if not segment then self.state='complete'; return {kind='complete'} end
    if segment.kind == 'scheduled' then return ScheduledAction(self, segment) end
    if segment.kind == 'portal' then
        local portal = self.planner.portals.byId[segment.portalId]
        return {kind=state == 'awaiting_transition' and state or (self.atEntry and 'use_portal' or 'approach'),
            portalId=portal.id,node=portal.from,title=portal.name,position=portal.entry and Copy(portal.entry),
            deadline=self.deadline,timeoutSeconds=portal.timeoutSeconds,attempt=self.attempt,
            remainingSeconds=self.deadline and self.deadline-self.lastClock,
            mode=segment.mode,transitionSeconds=segment.transitionSeconds}
    end
    local nextSegment = self.segments[self.index+1]
    local portal = nextSegment and nextSegment.kind == 'portal' and self.planner.portals.byId[nextSegment.portalId]
    return {kind='walk',node=segment.to,position=portal and portal.entry and Copy(portal.entry),
        title=portal and portal.name,mode=segment.mode,transitionSeconds=segment.transitionSeconds}
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
    return self:GetAction()
end

function Travel:Observe(observation)
    local action = self:Tick()
    if action.kind == 'failed' or action.kind == 'cancelled' or action.kind == 'complete' then return action end
    if action.kind == 'scheduled' then
        local segment = self.segments[self.index]
        local state = self.scheduledExecution:Observe(observation, self.scheduledNow)
        if state.status == 'complete' then self.journey:Locate(segment.to) else self.journey:Unlocate() end
        return self:GetAction()
    end
    if type(observation) ~= 'table' or not Revision(observation.sequence)
        or observation.sequence <= self.sequence then return action, 'stale_observation' end
    self.sequence = observation.sequence
    if observation.reliable ~= true or observation.loading == true then self.journey:Unlocate();return action end
    local segment = self.segments[self.index]
    if segment.kind ~= 'portal' then
        if observation.node == segment.to then self.journey:Locate(segment.to);self.index = self.index+1
        elseif observation.node == segment.from then self.journey:Locate(segment.from)
        else self.journey:Unlocate() end
        segment = self.segments[self.index]
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
