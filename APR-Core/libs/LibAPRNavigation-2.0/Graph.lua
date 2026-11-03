-- Pure Lua 5.1 input boundary. One declaration is validated/copied per Advance.
local _, namespace = ...
local Graph, Preparation = {}, {}
Preparation.__index = Preparation
local MAX_VIA = 64
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
    local parts={}
    local function Part(group,key,value)
        key,value=tostring(key),type(value)..':'..tostring(value)
        parts[#parts+1]=group..#key..':'..key..#value..':'..value
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
    return binding
end

function Graph.CombineAccess(a,b)
    if a=='unavailable' or b=='unavailable' then return 'unavailable' end
    if a=='unknown' or b=='unknown' then return 'unknown' end
    return 'available'
end

function Graph.NodeAccess(graph,node)
    local status,reason='available',nil
    for _,binding in pairs({graph.condition,graph.nodeConditions and graph.nodeConditions[node],
        graph.nodeZones and graph.zoneConditions[graph.nodeZones[node]]}) do
        if binding then
            local value,why=graph.conditionContext.tracker:Get(binding)
            if value=='unavailable' then return value,why end
            if value=='unknown' then status,reason=value,reason or why end
        end
    end
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

function Graph.New(source,context)
    context=context or {tracker=namespace.NavigationV2Conditions.New(),bindings={}}
    if type(source) == "table" and source.partitioned == true then
        if not namespace.NavigationV2Sectors then return nil, "sectors_unavailable" end
        local graph, reason = namespace.NavigationV2Sectors.New(source)
        if not graph then return nil, reason end
        graph.conditionContext=context
        return setmetatable({ phase = "ready", compiled = graph,sourceRequirements=source.requirements,
            rootPrepared=source.requirements==nil }, Preparation)
    end
    if type(source) ~= "table" or type(source.complete) ~= "boolean"
        or type(source.nodes) ~= "table" or type(source.edges) ~= "table"
        or (source.zones~=nil and type(source.zones)~='table') then return nil, "invalid_graph" end
    return setmetatable({ sourceNodes = source.nodes, sourceEdges = source.edges,
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
        if not namespace.NavigationV2Forever then return 'movement_unavailable' end
        movement = namespace.NavigationV2Forever.CaptureMovement(declaration.movement)
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
    local reason = copy(preparation, key, value)
    if reason then return nil, reason end
    preparation.count = preparation.count + 1
    preparation.maximum, preparation.cursor = math.max(preparation.maximum, key), key
    return false
end

function Preparation:Advance()
    if self.reason then return "invalid", self.reason end
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
        self.reason, self.compiled, self.sourceNodes, self.sourceEdges, self.seen = reason, nil, nil, nil, nil
        return "invalid", reason
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
