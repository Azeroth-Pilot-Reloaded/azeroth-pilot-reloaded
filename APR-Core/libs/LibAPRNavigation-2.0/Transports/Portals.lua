-- Observed portal arcs and explicit travel lifecycle. Pure Lua; no interactions.
local _, ns = ...
local Finite = ns.NavigationV2Graph.Finite
local Portals, Catalog = {}, {}
Catalog.__index = Catalog
local MAX_PORTALS = 256

local function Name(value)
    return type(value) == 'string' and value:match('%S') ~= nil
end

local function Revision(value)
    return Finite(value) and value >= 1 and value % 1 == 0
end

local function Duration(value)
    return Finite(value) and value >= 0
end

local function CaptureCosts(declaration,result)
    if declaration.totalSeconds~=nil then
        if not Duration(declaration.totalSeconds) or declaration.waitSeconds~=nil
            or declaration.useSeconds~=nil or declaration.loadingSeconds~=nil then return nil end
        result.totalSeconds=declaration.totalSeconds
        return true
    end
    for _,key in ipairs({'waitSeconds','useSeconds','loadingSeconds'}) do
        if not Duration(declaration[key]) then return nil end
        result[key]=declaration[key]
    end
    return Finite(result.waitSeconds+result.useSeconds+result.loadingSeconds)
end

local function Capture(declaration)
    if type(declaration) ~= 'table' or not Name(declaration.id) or not Name(declaration.from)
        or not Name(declaration.to) or not Name(declaration.phase)
        or type(declaration.destination) ~= 'table' or not Name(declaration.destination.space)
        or not Name(declaration.destination.phase) then return nil end
    local result = {id=declaration.id,from=declaration.from,to=declaration.to,phase=declaration.phase,
        destination={space=declaration.destination.space,phase=declaration.destination.phase}}
    if not CaptureCosts(declaration,result) then return nil end
    if not Duration(declaration.timeoutSeconds) or declaration.timeoutSeconds == 0 then return nil end
    result.timeoutSeconds = declaration.timeoutSeconds
    local target = ns.NavigationV2WaypointTarget.Capture({key='portal:'..result.id,
        title=declaration.name,position=declaration.entry})
    result.name = target.name
    if declaration.entry ~= nil then
        if not target.mapID then return nil end
        result.entry = {mapID=target.mapID,x=target.x,y=target.y}
    end
    return result
end

local function Access(portal, observation)
    local state = observation.portals and observation.portals[portal.id]
    if state ~= nil and type(state) ~= 'table' then return nil end
    if state and ((state.open ~= nil and type(state.open) ~= 'boolean')
        or (state.access ~= nil and type(state.access) ~= 'boolean')) then return nil end
    if observation.phase ~= nil and not Name(observation.phase) then return nil end
    if observation.phase and observation.phase ~= portal.phase then return 'unavailable' end
    if state and (state.open == false or state.access == false) then return 'unavailable' end
    if observation.phase and state and state.open == true and state.access == true then return 'available' end
    return 'unknown'
end

function Portals.New(declarations, observation)
    if declarations == nil then declarations = {} end
    if type(declarations) ~= 'table' then return nil, 'invalid_portals' end
    local catalog = setmetatable({byId={},outgoing={},count=0,observationRevision=0}, Catalog)
    local maximum = 0
    for key, declaration in pairs(declarations) do
        if not Revision(key) or key > MAX_PORTALS then return nil, 'invalid_portals' end
        local portal = Capture(declaration)
        if not portal or catalog.byId[portal.id] then return nil, 'invalid_portal' end
        portal.access = 'unknown'
        catalog.count, maximum = catalog.count + 1, math.max(maximum,key)
        catalog.byId[portal.id] = portal
        local row = catalog.outgoing[portal.from] or {}
        catalog.outgoing[portal.from] = row
        row[#row+1] = portal
    end
    if catalog.count ~= maximum then return nil, 'invalid_portals' end
    if observation ~= nil then
        local changed, reason = catalog:Observe(observation)
        if changed == nil then return nil, reason end
    end
    return catalog
end

function Catalog:Observe(observation)
    if type(observation) ~= 'table' or not Revision(observation.revision)
        or (observation.portals ~= nil and type(observation.portals) ~= 'table') then
        return nil, 'invalid_portal_observation'
    end
    if observation.revision <= self.observationRevision then return false, 'stale_observation' end
    local accesses, changed = {}, false
    for id, portal in pairs(self.byId) do
        local access = Access(portal, observation)
        if not access then return nil, 'invalid_portal_observation' end
        accesses[id], changed = access, changed or access ~= portal.access
    end
    for id, access in pairs(accesses) do self.byId[id].access = access end
    self.observationRevision = observation.revision
    return changed, changed and nil or 'unchanged_observation'
end

function Catalog:SetCosts(id, costs)
    local portal = self.byId[id]
    if not portal or type(costs) ~= 'table' then return nil, 'invalid_portal_costs' end
    local changed = false
    if portal.totalSeconds~=nil then
        for key,value in pairs(costs) do
            if key~='totalSeconds' or not Duration(value) then return nil,'invalid_portal_costs' end
            changed=changed or value~=portal.totalSeconds
        end
        if costs.totalSeconds~=nil then portal.totalSeconds=costs.totalSeconds end
        return changed
    end
    for key, value in pairs(costs) do
        if (key ~= 'waitSeconds' and key ~= 'useSeconds' and key ~= 'loadingSeconds')
            or not Duration(value) then return nil, 'invalid_portal_costs' end
        changed = changed or portal[key] ~= value
    end
    if not Finite((costs.waitSeconds or portal.waitSeconds) + (costs.useSeconds or portal.useSeconds)
        + (costs.loadingSeconds or portal.loadingSeconds)) then return nil, 'invalid_portal_costs' end
    for key, value in pairs(costs) do portal[key] = value end
    return changed
end

function Catalog:Edge(node, cursor)
    local portal = (self.outgoing[node] or {})[cursor]
    if not portal then return end
    local seconds = portal.totalSeconds
    if seconds==nil then seconds=portal.waitSeconds + portal.useSeconds + portal.loadingSeconds end
    return {id='portal:'..portal.id,from=portal.from,to=portal.to,seconds=seconds,
        access=portal.access,kind='portal',portalId=portal.id}
end

-- One declaration per preparation unit, after the ordinary graph boundary.
function Catalog:Prepare(graph)
    if self.prepared then return true end
    local id, portal = next(self.byId, self.cursor)
    if not id then self.prepared = true; return true end
    for _, node in ipairs({portal.from,portal.to}) do
        local found, status, reason
        if graph.partitioned then found,status,reason = graph:Locate(node)
        else found = graph.index[node] end
        if not found then return nil, status or 'invalid', reason or 'invalid_portal_node' end
    end
    self.cursor = id
    return false
end


ns.NavigationV2Portals = Portals
return Portals
