-- Prove a physical local exit before considering a remote shortcut from an
-- isolated space. The shared search owns routing; this job only limits inputs.
local Lib=LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("local-exit-routing",4) then return end
local Job={}; Job.__index=Job
local EMPTY={}
local PHYSICAL={walk=true,passage=true,portal=true,elevator=true,lift=true,boat=true,
    ship=true,zeppelin=true,tram=true,taxi=true,transport=true}
local ENCLOSED={underground=true,cave=true,building=true,floor=true,instance=true,transport=true}
local function Finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
local function ActionOnly(action)
    return action and (action.type=="item" or action.type=="spell" or action.sourceFree or action.positionOptional)
end
local function Contained(self,container,source,point,space)
    if not container then return false end
    local fromAccess=source.accessKey or container.accessKey
    local toAccess=point.accessKey or space.accessKey
    if fromAccess~=toAccess then return false end
    local contained=space.id==container.id or (self.owner.IsNavigationSpaceDescendant
        and self.owner:IsNavigationSpaceDescendant(space,container.id))
    if not contained then return false end
    -- A floor can contain rooms; a building can contain several floors. Only
    -- an origin that is itself a floor keeps its observed floor boundary here.
    if container.kind=="floor" then
        local first,last=source.floor or container.floor,point.floor or space.floor
        if first~=nil and last~=nil and first~=last then return false end
    end
    return true
end
local function Outside(self,point)
    local space=self.owner:ResolveNavigationSpace(point)
    if not space then self.metadata.waitingSpace=true; return false end
    if Contained(self,self.origin,self.request.start,point,space) then return false end
    if self.owner.IsNavigationSpaceDescendant and self.owner:IsNavigationSpaceDescendant(self.origin,space.id) then return true end
    local destination=self.destination
    if destination and (space.id==destination.id or ENCLOSED[destination.kind])
        and Contained(self,destination,self.request.goal,point,space) then return true end
    -- A neighboring enclosed room may lead onward, but ending there can bounce
    -- the next replan back into the origin. Only a real open space is an exit.
    return not space.requiresExit and (space.kind=="outdoor" or space.kind=="subzone")
end
local function Eligible(self,edge)
    local from,to=edge and edge.from,edge and edge.to
    return type(edge)=="table" and PHYSICAL[edge.kind] and not edge.sourceFree and not ActionOnly(edge.action)
        and not edge.itemID and not edge.spellID and type(from)=="table" and type(to)=="table"
        and not from.dynamic and not to.dynamic
        and self.owner:GetWorldInstanceID(from.instanceID)==self.world
        and self.owner:GetWorldInstanceID(to.instanceID)==self.world
end
function Job:Finish(status)
    self.status=status
    if status~="ready" then self.metadata.reason="navigation_exit_unavailable" end
    self.search,self.pending,self.edges=nil,nil,nil
    self.rawRoute,self.prefix=nil,nil
end
function Job:Missing()
    local request=self.request
    local coverage=request.coverage or request.terrainCoverage or EMPTY
    self:Finish((request.waitingData or coverage.waitingData or self.metadata.waitingSpace) and "waiting_data" or "missing_data")
end
function Job:Accept(edge)
    self.edges[#self.edges+1]=edge
    self.metadata.physicalEdges=self.metadata.physicalEdges+1
    for _,point in ipairs({edge.from,edge.to}) do
        if not self.probes[point] and Outside(self,point) then
            self.probes[point]=true; self.metadata.probes=self.metadata.probes+1
            self.edges[#self.edges+1]={kind="passage",from=point,to=self.sink,seconds=0,copper=0,localExitProbe=true}
        end
    end
end
function Job:CollectOne()
    local pending=self.pending
    if pending then
        local action=(pending.edge.actions or EMPTY)[pending.index]
        if action then
            pending.index=pending.index+1
            if ActionOnly(action) then self.pending=nil end
        else self:Accept(pending.edge); self.pending=nil end
        return
    end
    local group=self.group==0 and self.request.edges or (self.request.edgeGroups or EMPTY)[self.group]
    if not group then
        if self.group==0 then self.group,self.index=1,1; return end
        if self.metadata.probes==0 then self:Missing(); return end
        local request=self.request
        self.search=self.owner:CreateSearch({start=request.start,goal=self.sink,edges=self.edges,
            budget=request.budget,resources=request.resources,clock=request.clock,movementProfile=request.movementProfile,
            walkSpeed=request.walkSpeed,walkSpeedFor=request.walkSpeedFor,walkSpeedAt=request.walkSpeedAt,
            walkSecondsFor=request.walkSecondsFor,walkingIsTransitive=request.walkingIsTransitive,
            walkingRegionFor=request.walkingRegionFor,canWalk=function(from,to)
                if from==self.sink or to==self.sink then return false end
                if request.canWalk then return request.canWalk(from,to)==true end
                return self.owner:CanWalk(from,to)
            end})
        self.phase="search"; return
    end
    local edge=group[self.index]
    if not edge then self.group,self.index=self.group+1,1; return end
    self.index=self.index+1
    if Eligible(self,edge) then self.pending={edge=edge,index=1} end
end
function Job:BeginPrefix(route)
    local segments=route and route.segments or EMPTY
    local probe=segments[#segments]
    if not probe or not probe.localExitProbe or #segments<2 then self:Missing(); return end
    local space=self.owner:ResolveNavigationSpace(probe.from)
    self.rawRoute,self.prefixIndex,self.prefixLast=route,1,#segments-1
    self.prefix={segments={},totalSeconds=route.totalSeconds,totalCopper=route.totalCopper,
        resourcesUsed=route.resourcesUsed,localExitOnly=true,exitSpace=space and space.id}
    self.phase="prefix"
end
function Job:CopyPrefixOne()
    if self.prefixIndex>self.prefixLast then
        self.metadata.exitRoute=self.prefix
        self:Finish("ready"); return
    end
    local segments=self.prefix.segments
    segments[#segments+1]=self.rawRoute.segments[self.prefixIndex]
    self.prefixIndex=self.prefixIndex+1
end
function Job:Step(operations,milliseconds)
    self.workLastStep=0
    if self.status~="planning" then return self.status,self.metadata end
    operations=Finite(operations) and math.max(0,math.floor(operations)) or 64
    milliseconds=Finite(milliseconds) and math.max(0,milliseconds) or 1
    if operations==0 or milliseconds==0 then return self.status,self.metadata end
    local clock=self.request.clock
    local deadline=clock and clock()+milliseconds
    while self.workLastStep<operations do
        if deadline and self.workLastStep>0 and clock()>=deadline then break end
        if self.phase=="collect" then
            self:CollectOne(); self.workLastStep=self.workLastStep+1
        elseif self.phase=="prefix" then
            self:CopyPrefixOne(); self.workLastStep=self.workLastStep+1
        else
            local remaining=deadline and math.max(0,deadline-clock()) or milliseconds
            if remaining<=0 then break end
            local state,result=self.search:Step(operations-self.workLastStep,remaining)
            self.workLastStep=self.workLastStep+(self.search.workLastStep or 0)
            if state=="ready" then
                if self.request.route then self:BeginPrefix(result) else self:Finish("ready") end
            elseif state~="planning" then self:Missing() end
            break
        end
        if self.status~="planning" then break end
    end
    return self.status,self.metadata
end
function Job:Cancel()
    if self.search then self.search:Cancel() end
    self.status,self.search,self.pending,self.edges="cancelled",nil,nil,nil
    self.rawRoute,self.prefix,self.metadata.exitRoute=nil,nil,nil
end
function Lib.Instance:CreateLocalExitCheck(request)
    request=type(request)=="table" and request or {}
    local job=setmetatable({owner=self,request=request,status="ready",workLastStep=0,
        metadata={applicable=false,physicalEdges=0,probes=0},edges={},probes={},group=0,index=1,phase="collect"},Job)
    local start,goal=request.start,request.goal
    if not start or not goal or not self.ResolveNavigationSpace then return job end
    local world=self:GetWorldInstanceID(start.instanceID)
    if world~=self:GetWorldInstanceID(goal.instanceID) then return job end
    local origin,reason=self:ResolveNavigationSpace(start)
    if not origin then job.status="waiting_data"; job.metadata.reason=reason; return job end
    if not origin.requiresExit then return job end
    job.origin,job.world=origin,world
    job.destination=self:ResolveNavigationSpace(goal)
    if job.destination then
        if Contained(job,origin,start,goal,job.destination) then return job end
    else job.metadata.waitingSpace=true end
    job.metadata.applicable,job.metadata.originSpace=true,origin.id
    job.sink={instanceID=world,x=start.x,y=start.y,z=start.z,noAutoconnect=true,region="local-exit-probe:"..tostring(job)}
    job.status="planning"
    return job
end
