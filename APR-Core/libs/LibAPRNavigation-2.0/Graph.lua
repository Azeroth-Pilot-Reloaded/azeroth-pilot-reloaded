-- Pure Lua 5.1 input boundary. One declaration is validated/copied per Advance.
local _, namespace = ...
local Graph, Preparation = {}, {}
Preparation.__index = Preparation
local MAX_VIA = 64
-- Shared physical defaults. Callers may lower memory ceilings, never raise them.
Graph.Budgets = {sliceMs=1,cpuMs=100,elapsedMs=5000}
Graph.Limits = {zones=4096,nodes=65536,edges=262144,labels=65536,segments=32768,snapshotFields=262144}

function Graph.CaptureLimits(source)
    if source~=nil and type(source)~='table' then return nil end
    local result={}
    for key,maximum in pairs(Graph.Limits)do
        local value=source and source[key]
        if value==nil then value=maximum end
        if type(value)~='number' or value<1 or value>maximum or value%1~=0 then return nil end
        result[key]=value
    end
    for key in pairs(source or {})do if not Graph.Limits[key] then return nil end end
    return result
end
Graph.SAFE_INTEGER = 9007199254740991

function Graph.Finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function Identifier(value)
    return type(value) == "string" and value ~= ""
end

local function ArrayKey(value)
    return Graph.Finite(value) and value >= 1 and value % 1 == 0
end

-- Intern bounded conjunctions by meaning, not by the number of nodes/zones
-- sharing them. Compile validates once at preparation; Get is cached thereafter.
function Graph.BindRequirements(context,source,existingOnly)
    if source==nil then return nil end
    local compiled,reason=namespace.NavigationV2Conditions.Compile(source)
    if not compiled then return nil,reason end
    local parts,facts={},context.unlockProofs and {}
    local function Part(group,key,value)
        local name,expected=tostring(key),type(value)..':'..tostring(value)
        local variable=group..#name..':'..name
        local id=variable..#expected..':'..expected
        parts[#parts+1]=id
        if facts then facts[#facts+1]={group=group,key=key,expected=value,id=id,variable=variable} end
    end
    for _,key in ipairs({'world','space','floor','phase'}) do
        if source[key]~=nil then Part('identity',key,source[key]) end
    end
    for _,entry in ipairs(source.quests or {}) do Part('quests',entry.questID,entry.completed) end
    for _,entry in ipairs(source.access or {}) do Part('access',entry.key,entry.allowed) end
    if #parts==0 then return nil end
    table.sort(parts)
    local key=table.concat(parts,'\0')
    if context.bindings[key] then return context.bindings[key] end
    if existingOnly then return nil,'condition_reconfiguration_requires_enable' end
    local binding
    binding,reason=context.tracker:Track(compiled)
    if not binding then return nil,reason end
    context.bindings[key],context.conditional=binding,true
    if facts then
        context.bindingFacts=context.bindingFacts or {}
        context.bindingFacts[binding]=facts
    end
    return binding
end

function Graph.CombineAccess(a,b)
    if a=='unavailable' or b=='unavailable' then return 'unavailable' end
    if a=='unknown' or b=='unknown' then return 'unknown' end
    return 'available'
end

-- At most64 captured facts, once per denied binding/accepted snapshot. A token
-- alone is insufficient: a conjunction can stay denied when its blocker changes.
local function Denial(context,binding)
    local tracker=context.tracker
    context.denialCache=context.denialCache or {}
    local cached=context.denialCache[binding]
    if cached and cached.sequence==tracker.snapshot.sequence and cached.revision==tracker.revision then return cached end
    local snapshot,count,blocker,unknown=tracker.snapshot,0,nil,false
    if snapshot.worldState~='ready' then unknown=true end
    for _,fact in ipairs(context.bindingFacts[binding])do
        local value=snapshot[fact.group][fact.key]
        if value==nil then unknown=true
        elseif value~=fact.expected then
            count=count+1
            if count==1 and fact.expected==true and (fact.group=='quests' or fact.group=='access') then blocker=fact.id
            else blocker=false end
        end
    end
    cached={sequence=snapshot.sequence,revision=tracker.revision,blocker=blocker,unknown=unknown}
    context.denialCache[binding]=cached
    return cached
end

-- A planning label owns its assumptions. Neither the tracker nor its captured
-- native snapshot is altered; unknown facts cannot become declared effects.
local function PlannedAccess(context,binding,search)
    search.planBindings[binding]=true
    local snapshot,missing,denied=search.planSnapshot,false,false
    local assumed=search.current and search.current.assumed or {}
    if snapshot.worldState~='ready' then return 'unknown','world_unknown' end
    for _,fact in ipairs(context.bindingFacts[binding])do
        local value=snapshot[fact.group][fact.key]
        if assumed[fact.variable] then value=true end
        if value==nil then missing=true elseif value~=fact.expected then denied=true end
    end
    if missing then search.conditionUnknown=true end
    if denied then return 'unavailable','conditional_requirement_unmet' end
    if missing then return 'unknown','conditional_requirement_unknown' end
    return 'available'
end

function Graph.ConditionAccess(graph,binding,search,proof)
    local context=graph.conditionContext
    if search and search.planSnapshot then return PlannedAccess(context,binding,search) end
    local access,reason=context.tracker:Get(binding)
    if proof then
        proof.bindings=proof.bindings or {}
        proof.bindings[binding]=true
    end
    if search then
        if access=='unknown' then
            search.conditionUnknown=true
            if proof then proof.unknown=true end
        elseif access=='unavailable' and proof then
            local denial=Denial(context,binding)
            if denial.unknown then proof.unknown=true;search.conditionUnknown=true end
            if not denial.blocker or proof.blocker and proof.blocker~=denial.blocker then proof.conflict=true
            else proof.blocker=denial.blocker end
        end
    end
    return access,reason
end

function Graph.NodeAccess(graph,node,search,proof)
    local status,reason,denied='available',nil,nil
    for _,binding in pairs({graph.condition,graph.nodeConditions and graph.nodeConditions[node],
        graph.nodeZones and graph.zoneConditions[graph.nodeZones[node]]}) do
        if binding then
            local value,why=Graph.ConditionAccess(graph,binding,search,proof)
            if value=='unavailable' then
                if not search then return value,why end
                denied=denied or why
            end
            if value=='unknown' then status,reason=value,reason or why end
        end
    end
    if denied then return 'unavailable',denied end
    return status,reason
end

-- Request capture is capped independently of graph size, even for malformed
-- tables with a huge number of extra fields. Node references are checked later.
function Graph.CaptureRequest(request)
    if type(request) ~= "table" or not Identifier(request.from) or not Identifier(request.to) then return nil end
    local source = request.via
    if source == nil then source = {} end
    if type(source) ~= "table" then return nil end
    local via, cursor, count, maximum = {}, nil, 0, 0
    for _ = 1, MAX_VIA + 1 do
        local key, id = next(source, cursor)
        if key == nil then
            if count ~= maximum then return nil end
            return { from = request.from, to = request.to, via = via }
        end
        if not ArrayKey(key) or key > MAX_VIA or not Identifier(id) then return nil end
        count, maximum, cursor, via[key] = count + 1, math.max(maximum, key), key, id
    end
end

function Graph.New(source,context,limits)
    context=context or {tracker=namespace.NavigationV2Conditions.New(),bindings={}}
    if type(source) == "table" and source.partitioned == true then
        local factories={sectors=namespace.NavigationV2Sectors,roads=namespace.NavigationV2RoadDomain,
            domains=namespace.NavigationV2DomainGraph}
        local kind=source.kind or 'sectors'
        local factory=factories[kind]
        if not factory then return nil,kind=='sectors' and 'sectors_unavailable' or 'partitioned_kind_unavailable' end
        local create=kind=='roads' and factory.Compile or factory.New
        if type(create)~='function' then return nil,'partitioned_factory_unavailable' end
        local graph, reason = create(source,context,limits)
        if not graph then return nil, reason end
        graph.conditionContext=context
        return setmetatable({ phase = "ready", compiled = graph,sourceRequirements=source.requirements,
            rootPrepared=source.requirements==nil }, Preparation)
    end
    if type(source) ~= "table" or type(source.complete) ~= "boolean"
        or type(source.nodes) ~= "table" or type(source.edges) ~= "table"
        or (source.zones~=nil and type(source.zones)~='table') then return nil, "invalid_graph" end
    return setmetatable({ sourceNodes = source.nodes, sourceEdges = source.edges,limits=limits or Graph.Limits,
        sourceZones=source.zones,sourceRequirements=source.requirements,rootPrepared=source.requirements==nil,
        phase = source.zones and 'prepare_zones' or "prepare_nodes", count = 0, maximum = 0, seen = {},
        compiled = { complete = source.complete, nodes = {}, index = {}, outgoing = {},
            conditionContext=context,nodeConditions={},nodeZones={},zoneConditions={} } }, Preparation)
end

local function Zone(preparation,_,declaration)
    local graph=preparation.compiled
    if type(declaration)~='table' or not Identifier(declaration.id) or graph.zoneConditions[declaration.id]~=nil then return 'invalid_zone' end
    local binding,reason=Graph.BindRequirements(graph.conditionContext,declaration.requirements)
    if reason then return reason end
    graph.zoneConditions[declaration.id]=binding or false
end

local function Node(preparation, key, declaration)
    local graph = preparation.compiled
    local id=type(declaration)=='table' and declaration.id or declaration
    if not Identifier(id) or graph.index[id] then return "invalid_node" end
    if type(declaration)=='table' then
        local zone=declaration.zone
        if zone~=nil and (not Identifier(zone) or graph.zoneConditions[zone]==nil) then return 'invalid_node_zone' end
        local binding,reason=Graph.BindRequirements(graph.conditionContext,declaration.requirements)
        if reason then return reason end
        graph.nodeConditions[key],graph.nodeZones[key]=binding,zone
    end
    graph.nodes[key], graph.index[id], graph.outgoing[key] = id, key, {}
end

local function Edge(preparation, _, declaration)
    if type(declaration) ~= "table" or not Identifier(declaration.id) or preparation.seen[declaration.id] then
        return "invalid_edge"
    end
    local graph = preparation.compiled
    local from, to = graph.index[declaration.from], graph.index[declaration.to]
    local access = declaration.access
    if access == nil then access = "available" end
    if not from or not to or not Graph.Finite(declaration.seconds) or declaration.seconds < 0
        or (access ~= "available" and access ~= "unavailable" and access ~= "unknown") then return "invalid_edge" end
    preparation.seen[declaration.id] = true
    local movement
    if declaration.movement ~= nil then
        local source=declaration.movement
        local api=namespace.NavigationV2Forever
        if type(source)=='table' and (source.mode=='skyriding' or source.groundOnly~=nil
            or source.requiresExit~=nil or source.canFly~=nil or source.rise~=nil or source.fall~=nil) then
            api=namespace.NavigationV2Retail
        end
        if not api then return 'movement_unavailable' end
        movement = api.CaptureMovement(source)
        if not movement then return 'invalid_movement' end
    end
    local resources
    if declaration.resources ~= nil then
        resources = namespace.NavigationV2Resources.Capture(declaration.resources)
        if not resources then return 'invalid_edge_resources' end
        graph.resourceCosts = true
    end
    local outgoing = graph.outgoing[from]
    local condition,reason=Graph.BindRequirements(graph.conditionContext,declaration.requirements)
    if reason then return reason end
    outgoing[#outgoing + 1] = { id = declaration.id, from = from, to = to,
        seconds = declaration.seconds, access = access, movement = movement, resources = resources,condition=condition }
end

local function AdvanceArray(preparation, source, copy)
    local key, value = next(source, preparation.cursor)
    if key == nil then
        if preparation.count ~= preparation.maximum then return nil, "invalid_graph" end
        return true
    end
    if not ArrayKey(key) then return nil, "invalid_graph" end
    local field=copy==Node and 'nodes' or copy==Edge and 'edges' or 'zones'
    if preparation.count>=preparation.limits[field] then
        return nil,copy==Node and 'node_limit' or copy==Edge and 'edge_limit' or 'zone_limit'
    end
    local reason = copy(preparation, key, value)
    if reason then return nil, reason end
    preparation.count = preparation.count + 1
    preparation.maximum, preparation.cursor = math.max(preparation.maximum, key), key
    return false
end

function Preparation:Advance()
    if self.reason then return self.status or "invalid", self.reason end
    if not self.rootPrepared then
        local binding,reason=Graph.BindRequirements(self.compiled.conditionContext,self.sourceRequirements)
        if reason then self.reason=reason;return 'invalid',reason end
        self.compiled.condition,self.rootPrepared,self.sourceRequirements=binding,true,nil
        return self.phase=='ready' and 'ready' or 'condition'
    end
    if self.phase == "ready" then return "ready" end
    local nodes,zones = self.phase == "prepare_nodes",self.phase=='prepare_zones'
    local source=zones and self.sourceZones or nodes and self.sourceNodes or self.sourceEdges
    local done, reason = AdvanceArray(self, source, zones and Zone or nodes and Node or Edge)
    if done and nodes and self.count == 0 then reason = "invalid_graph" end
    if reason then
        self.reason, self.compiled, self.sourceNodes, self.sourceEdges, self.seen, self.sourceZones = reason, nil, nil, nil, nil, nil
        self.status=(reason=='node_limit' or reason=='edge_limit' or reason=='zone_limit') and 'budget_exceeded' or 'invalid'
        return self.status, reason
    end
    if done then
        self.cursor, self.count, self.maximum = nil, 0, 0
        if zones then self.phase,self.sourceZones='prepare_nodes',nil
        elseif nodes then
            self.phase, self.sourceNodes = "prepare_edges", nil
        else
            self.phase, self.sourceEdges, self.seen = "ready", nil, nil
            return "ready"
        end
    else
        return zones and 'zone' or nodes and "node" or "edge"
    end
end

namespace.NavigationV2Graph = Graph
return Graph
