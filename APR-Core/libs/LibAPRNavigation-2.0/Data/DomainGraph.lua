-- Query-local overlays over lazy source graphs. Search remains the only solver.
local _,ns=...
local Graph=ns.NavigationV2Graph
local DomainGraph,Composite,PositionJob={},{},{}
Composite.__index,PositionJob.__index=Composite,PositionJob
local Finite=Graph.Finite
local Copy=ns.NavigationV2WaypointTarget.Copy
local function Shallow(value)
    local r={};for k,v in pairs(value) do r[k]=v end;return r
end
local function Qualified(index,id) return 'p'..index..':'..id end
local function Split(self,id)
    if type(id)~='string' then return end
    local n,raw=id:match('^p(%d+):(.*)$')
    n=tonumber(n)
    if n and self.children[n] then return n,raw end
end

function DomainGraph.New(source,context,limits)
    if type(source.overlay)~='table' or type(source.readers)~='table' then return nil,'invalid_domain_graph' end
    local overlay,reason=Graph.New(source.overlay,context,limits)
    if not overlay then return nil,reason end
    local self=setmetatable({partitioned=true,complete=false,conditionContext=context,
        overlay=overlay,positions=source.positions or {},children={},readers=source.readers,
        states=setmetatable({},{__mode='k'}),geometry=source.geometry or {},resourceCosts=true},Composite)
    for i,reader in ipairs(source.readers) do
        if i>64 or type(reader)~='table' or type(reader.source)~='table' then return nil,'invalid_domain_reader' end
        local preparation;preparation,reason=Graph.New(reader.source,context,limits)
        if not preparation then return nil,reason end
        self.children[i]=preparation
    end
    return self
end

function Composite:Locate(id)
    if self.positions[id] then return id end
    local n,raw=Split(self,id)
    if not n then return nil,'invalid','unknown_domain_node' end
    local child=self.children[n].compiled
    local found,status,reason=child:Locate(raw)
    if found then return id end
    return nil,status,reason
end

local function SourceState(self,search,n)
    local states=self.states[search]
    if not states then states={};self.states[search]=states end
    if not states[n] then states[n]={diagnostics=search.diagnostics} end
    return states[n]
end

local function Prepare(preparation)
    if preparation.phase=='ready' and preparation.rootPrepared then return preparation.compiled end
    local status,reason=preparation:Advance()
    if status=='invalid' or status=='budget_exceeded' then return nil,status,reason end
    return nil,'running'
end

function Composite:Ensure(search,id)
    local overlay,status,reason=Prepare(self.overlay)
    if not overlay then return nil,status,reason end
    if self.positions[id] then return {compiled=overlay,node=id} end
    local n,raw=Split(self,id)
    if not n then return nil,'invalid','unknown_domain_node' end
    local child;child,status,reason=Prepare(self.children[n])
    if not child then return nil,status,reason end
    local state=SourceState(self,search,n)
    local entry;entry,status,reason=child:Ensure(state,raw)
    if state.sawIncomplete then search.sawIncomplete=true end
    if entry then return {compiled=entry.compiled,node=raw,entry=entry,source=n} end
    return nil,status,reason
end

function Composite:ReadEdge(search,id,cursor)
    local entry,status,reason=self:Ensure(search,id)
    if not entry then return nil,status,reason end
    local state=SourceState(self,search,'cursor')
    if state.node~=id or cursor<=(state.last or 0) then
        state.node,state.base,state.overlay,state.last=id,1,1,0
    end
    local n,raw=Split(self,id)
    if n and state.base then
        local child=self.children[n].compiled
        local edge;edge,status,reason=child:ReadEdge(SourceState(self,search,n),raw,state.base)
        if status then return nil,status,reason end
        if edge then
            state.base,state.last=state.base+1,cursor
            local result=Shallow(edge)
            result.from,result.to=Qualified(n,edge.from),Qualified(n,edge.to)
            result.id=Qualified(n,edge.id)
            return result
        end
        state.base=nil
        return nil,'running'
    end
    local compiled=self.overlay.compiled
    local index=compiled.index[id]
    local edge=index and compiled.outgoing[index][state.overlay]
    if not edge then return end
    state.overlay,state.last=state.overlay+1,cursor
    local result=Shallow(edge)
    result.from,result.to=id,compiled.nodes[edge.to]
    return result
end

function Composite:Cancel(search)
    for _,state in pairs(self.states[search] or {}) do
        if state.loading and state.loading.job and state.loading.job.Cancel then state.loading.job:Cancel() end
    end
    self.states[search]=nil
end

local function InlineGeometry(points)
    return {Step=function()return {status='complete',polyline=Copy(points)} end,
        Cancel=function()return {status='cancelled'} end}
end

function Composite:Geometry(id)
    if self.geometry[id] then return InlineGeometry(self.geometry[id]) end
    local n,raw=Split(self,id)
    if n and type(self.readers[n].Geometry)=='function' then return self.readers[n]:Geometry(raw) end
    return nil,'geometry_unavailable'
end

local function Distance(a,b)
    local z=a.z~=nil and b.z~=nil and b.z-a.z or 0
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+z*z)
end

local function Crosses(a,b,bounds)
    if not bounds then return true end
    local first,last=0,1
    for _,axis in ipairs({'x','y'}) do
        local minimum,maximum=bounds['min'..axis:upper()],bounds['max'..axis:upper()]
        if minimum~=nil and maximum~=nil then
            local delta=b[axis]-a[axis]
            if delta==0 then
                if a[axis]<minimum or a[axis]>maximum then return false end
            else
                local lo,hi=(minimum-a[axis])/delta,(maximum-a[axis])/delta
                if lo>hi then lo,hi=hi,lo end
                first,last=math.max(first,lo),math.min(last,hi)
                if first>last then return false end
            end
        end
    end
    return true
end

local function Managed(readers,a,b)
    for _,reader in ipairs(readers) do
        local coverage=reader.coverage or reader.source.coverage
        if coverage then
            for _,scope in pairs(coverage) do
                if (scope.world or scope.worldID)==a.world and Crosses(a,b,scope.bounds) then return true end
            end
        elseif reader.world==nil or reader.world==a.world then return true end
    end
    return false
end

local function PointKey(p)
    local fields={}
    for _,k in ipairs({'world','x','y','z','uiMapID','space','floor','phase','accessKey'}) do
        local v=p[k];local text=type(v)..':'..tostring(v)
        fields[#fields+1]=#text..':'..text
    end
    fields[#fields+1]=p.noAutoconnect and 'blocked' or 'open'
    return table.concat(fields,'|')
end

local function Normalize(self,p)
    if type(p)~='table' then return nil,'position_missing' end
    if p.dynamic=='player' then return Copy(self.request.from) end
    if p.dynamic=='bind' then return self.options.bindPosition and Copy(self.options.bindPosition) or nil,'bind_unobserved' end
    local r={world=p.world or p.instanceID,x=p.x,y=p.y,z=p.z,uiMapID=p.uiMapID,
        areaID=p.areaID,floor=p.floor,phase=p.phase,accessKey=p.accessKey,noAutoconnect=p.noAutoconnect}
    if p.space~='world' and p.space~='map' then r.space=p.space end
    if p.space=='map' then
        if type(self.options.mapToWorld)~='function' then return nil,'map_projection_missing' end
        local ok,world,x,y=pcall(self.options.mapToWorld,p.uiMapID,p.x,p.y)
        if not ok then return nil,'map_projection_unavailable' end
        r.world,r.x,r.y=world,x,y
    end
    return self.domains:Resolve(r)
end

local function AddPoint(self,point)
    local key=PointKey(point)
    if self.pointKeys[key] then return self.pointKeys[key] end
    if #self.pointOrder>=512 then return nil,'position_limit' end
    local id='q:'..(#self.pointOrder+1)
    self.pointOrder[#self.pointOrder+1]=id;self.pointKeys[key]=id;self.positions[id]=point
    self.nodes[#self.nodes+1]=id
    return id
end

local function AddEdge(self,edge,polyline)
    if #self.edges>=self.limits.edges then return nil,'edge_limit' end
    local e=Shallow(edge);e.id='a:'..(#self.edges+1)
    self.edges[#self.edges+1]=e
    if polyline then self.geometry[e.id]=polyline end
    return true
end

local function BindIdentity(id,p)
    return {node=id,space=p.space,worldID=p.world,floorID=p.floor,phase=p.phase}
end

local function CaptureRecord(self,record)
    if type(record)~='table' or record.disabled or record.reviewStatus=='candidate'
        or record.reviewStatus=='disabled' then return end
    local from,why=Normalize(self,record.from)
    local to,reason=Normalize(self,record.to)
    if not from or not to then
        self.gaps[#self.gaps+1]={id=record.id,reason=why or reason};return
    end
    local a,b=AddPoint(self,from),AddPoint(self,to)
    if not a or not b then return 'budget_exceeded','position_limit' end
    local binding={from=BindIdentity(a,from),to=BindIdentity(b,to),timeoutSeconds=self.options.transportTimeoutSeconds or 120}
    if record.kind=='walk' then binding.ground={distance=Distance(from,to),speed=self.options.walkSpeed or 7} end
    if record.kind=='boat' or record.kind=='zeppelin' or record.kind=='tram' or record.kind=='elevator' then
        binding.access=(self.options.transportAccess or {})[record.id] or record.access or 'available'
    end
    for _,key in ipairs({'from','to'}) do
        local access=self.domains:TransitAccess(key=='from' and from or to,self.policy)
        if access~='available' then binding.access=access end
    end
    for k,v in pairs((self.options.personalPolicy or {})[record.id] or {}) do binding[k]=v end
    local bundle;bundle,why=ns.NavigationV2ForeverTransports.BindRecord(record,binding)
    if not bundle then self.gaps[#self.gaps+1]={id=record.id,reason=why};return end
    for _,edge in ipairs(bundle.graph.edges) do
        local path=edge.from==a and {from,to} or {to,from}
        local ok;ok,why=AddEdge(self,edge,path)
        if not ok then return 'budget_exceeded',why end
    end
    for kind,values in pairs(bundle.options) do
        local target=self.catalogues[kind] or {};self.catalogues[kind]=target
        for _,v in ipairs(values) do target[#target+1]=v end
    end
end

local function RecordUnit(self)
    local groups=self.recordGroups
    local group=groups[self.group]
    if not group then self.phase='attachments';self.pointIndex,self.readerIndex,self.direction=1,1,'from';return end
    local key,value=next(group,self.recordKey)
    self.recordKey=key
    if not key then self.group,self.recordKey=self.group+1,nil;return end
    if value.reason=='ground_cost_missing' then value=value.declaration
    elseif value.reason then return end
    return CaptureRecord(self,value)
end

local function AttachUnit(self)
    local id=self.pointOrder[self.pointIndex]
    if not id then self.phase='search';return end
    local reader=self.readers[self.readerIndex]
    if not reader then self.pointIndex,self.readerIndex=self.pointIndex+1,1;return end
    local point=self.positions[id]
    if point.noAutoconnect then self.readerIndex=self.readerIndex+1;return end
    if not self.attachment then
        local job,reason=reader:Resolve(point,self.direction)
        if not job then self.gaps[#self.gaps+1]={point=id,reason=reason};self.readerIndex=self.readerIndex+1;return end
        self.attachment=job
    end
    local state=self.attachment:Step(1,self.budgets.sliceMs)
    self.metrics.providerSteps=self.metrics.providerSteps+1
    if state.status=='running' then return end
    if state.status~='complete' then
        self.gaps[#self.gaps+1]={point=id,reason=state.reason or state.status}
    else
        for _,connector in ipairs(state.connectors or {}) do
            if self.metrics.connectors>=128 then return 'budget_exceeded','connector_limit' end
            if type(connector.node)~='string' or not Finite(connector.seconds) or connector.seconds<0 then
                return 'invalid','invalid_connector'
            end
            local node=Qualified(self.readerIndex,connector.node)
            if not self.foreignNodes[node] then self.foreignNodes[node]=true;self.nodes[#self.nodes+1]=node end
            local edge={from=self.direction=='from' and id or node,to=self.direction=='from' and node or id,
                seconds=connector.seconds,access=connector.access or 'available',movement=connector.movement,
                requirements=connector.requirements}
            local ok,why=AddEdge(self,edge)
            if not ok then return 'budget_exceeded',why end
            self.connectorGeometry[self.edges[#self.edges].id]={reader=self.readerIndex,id=connector.edgeId}
            self.metrics.connectors=self.metrics.connectors+1
        end
    end
    self.attachment=nil
    if self.direction=='from' then self.direction='to'
    else self.direction='from';self.readerIndex=self.readerIndex+1 end
end

local function OpenSearch(self)
    local source={partitioned=true,kind='domains',complete=false,readers=self.readers,positions=self.positions,
        overlay={complete=false,nodes=self.nodes,edges=self.edges},geometry=self.geometry,
        implicit={domains=self.domains,policy=self.policy,order=self.pointOrder,speed=self.options.walkSpeed or 7},
        connectorGeometry=self.connectorGeometry}
    local options=Shallow(self.options)
    for k,v in pairs(self.catalogues) do options[k]=v end
    options.budgets=self.budgets
    self.planner,self.reason=ns.LibAPRNavigationV2.New(source,options)
    if not self.planner then return 'invalid',self.reason end
    self.search=self.planner:Plan({from=self.fromID,to=self.toID,via={}})
    self.phase='searching'
end

local function FinishPosition(self,status,reason)
    if not self.result then
        self.result={status=status,reason=reason,diagnostics={operations=self.operations,cpuMs=self.cpuMs,
            elapsedMs=(self.lastWall-self.started)*1000},provenance={scope='declared_model',gaps=self.gaps}}
    end
    if self.attachment and self.attachment.Cancel then self.attachment:Cancel() end
    if self.search and status~='complete' then self.search:Cancel() end
    if self.geometryJob and self.geometryJob.Cancel then self.geometryJob:Cancel() end
    return self.result
end

local function AdvancePosition(self)
    if self.phase=='init' then
        local why;self.domains,why=ns.NavigationV2Domains.New(self.options.geography)
        if not self.domains then return 'invalid',why end
        local a,b;a,why=Normalize(self,self.request.from)
        if not a then return 'unknown',why end
        b,why=Normalize(self,self.request.to)
        if not b then return 'unknown',why end
        self.fromID,self.toID=AddPoint(self,a),AddPoint(self,b)
        self.policy={origin=a,objective=b,actor=self.options.actor}
        self.phase='records';return
    elseif self.phase=='records' then return RecordUnit(self)
    elseif self.phase=='attachments' then return AttachUnit(self)
    elseif self.phase=='search' then return OpenSearch(self)
    elseif self.phase=='searching' then
        local result=self.search:Step(1,self.budgets.sliceMs)
        if result.status=='running' then return end
        if result.status~='complete' then return result.status,result.reason end
        self.route=Copy(result);self.segmentIndex=1;self.phase='geometry';return
    end
    local segment=self.route.segments[self.segmentIndex]
    if not segment then
        self.result=self.route
        self.result.positions=Copy(self.positions)
        self.result.from,self.result.to=Copy(self.request.from),Copy(self.request.to)
        self.result.provenance={scope='declared_model',gaps=self.gaps,connectors=self.metrics.connectors}
        return 'complete',self.result.reason
    end
    if segment.kind=='scheduled' or segment.kind=='portal' or segment.kind=='personal' or segment.kind=='taxi' then
        self.segmentIndex=self.segmentIndex+1;return
    end
    if not self.geometryJob then
        local graph=self.planner.preparation.compiled
        self.geometryJob,self.reason=graph:Geometry(segment.edgeId)
        if not self.geometryJob then return 'unknown',self.reason end
    end
    local state=self.geometryJob:Step(1,self.budgets.sliceMs)
    if state.status=='running' then return end
    if state.status~='complete' then return state.status,state.reason end
    segment.polyline=Copy(state.polyline)
    self.geometryJob=nil;self.segmentIndex=self.segmentIndex+1
end

function DomainGraph.Plan(request,options)
    if type(request)~='table' or type(options)~='table' or type(options.clock)~='function'
        or type(options.profileClock)~='function' then return nil,'invalid_position_options' end
    local speed=options.walkSpeed or 7
    if not Finite(speed) or speed<=0 then return nil,'invalid_walk_speed' end
    local now=options.clock()
    if not Finite(now) or now<0 then return nil,'clock_unavailable' end
    local budgets={}
    for k,v in pairs(Graph.Budgets) do
        budgets[k]=options.budgets and options.budgets[k] or v
        if not Finite(budgets[k]) or budgets[k]<=0 or budgets[k]>v then return nil,'invalid_budgets' end
    end
    local data=options.transports or ns.NavigationV2ForeverTransportsData or {routes={},excluded={}}
    local captured=Shallow(options)
    captured.geography=options.geography or ns.NavigationV2ForeverGeographyData
    return setmetatable({request=Copy(request),options=captured,budgets=budgets,
        limits=Graph.CaptureLimits(options.limits) or Graph.Limits,readers=options.readers or {},
        started=now,lastWall=now,cpuMs=0,operations=0,phase='init',nodes={},edges={},geometry={},positions={},
        pointKeys={},pointOrder={},foreignNodes={},connectorGeometry={},catalogues={},gaps={},
        recordGroups={options.passages or {},data.routes or {},data.excluded or {}},group=1,
        metrics={providerSteps=0,connectors=0}},PositionJob)
end

function PositionJob:Step(operations,milliseconds)
    if self.result then return self.result end
    local limit=operations or 64
    if not Finite(limit) or limit<1 or limit%1~=0 then return FinishPosition(self,'invalid','invalid_step_budget') end
    local start=self.options.profileClock();local previous=start
    for _=1,limit do
        local wall=self.options.clock();local cpu=self.options.profileClock()
        if not Finite(wall) or not Finite(cpu) or wall<self.lastWall or cpu<previous then
            return FinishPosition(self,'unknown','clock_unavailable')
        end
        self.cpuMs=self.cpuMs+cpu-previous;previous=cpu;self.lastWall=wall
        if self.cpuMs>=self.budgets.cpuMs then return FinishPosition(self,'budget_exceeded','cpu_budget') end
        if (wall-self.started)*1000>=self.budgets.elapsedMs then return FinishPosition(self,'budget_exceeded','elapsed_budget') end
        local status,reason=AdvancePosition(self)
        self.operations=self.operations+1
        local after=self.options.profileClock()
        if not Finite(after) or after<previous then return FinishPosition(self,'unknown','clock_unavailable') end
        self.cpuMs=self.cpuMs+after-previous;previous=after
        if status then return FinishPosition(self,status,reason) end
        if after-start>=math.min(milliseconds or self.budgets.sliceMs,self.budgets.sliceMs) then break end
    end
    return {status='running',phase=self.phase}
end

function PositionJob:Cancel()
    return self.result or FinishPosition(self,'cancelled','cancelled')
end

function PositionJob:GetMetrics()
    local r=Shallow(self.metrics);r.operations=self.operations;r.cpuMs=self.cpuMs
    r.elapsedMs=(self.lastWall-self.started)*1000
    return r
end

ns.NavigationV2DomainGraph=DomainGraph
return DomainGraph
