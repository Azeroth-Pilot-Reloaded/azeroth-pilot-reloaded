-- Business-declared taxi arcs; API identifiers are attributes only. Pure Lua.
local _, ns = ...
local Finite = ns.NavigationV2Graph.Finite
local Target = ns.NavigationV2WaypointTarget
local Taxi, Catalog = {}, {}
Catalog.__index = Catalog
local MAX_ROUTES = 256
local COST_FIELDS = {'approach','boarding','ride','loading','disembark','final'}
local DEFAULT_RIDE_SECONDS = 180

local function Name(value)
    return type(value) == 'string' and value:match('%S') ~= nil
end
local function Amount(value)
    return Finite(value) and value >= 0 and value % 1 == 0 and value <= ns.NavigationV2Graph.SAFE_INTEGER
end
local function Stop(source)
    if type(source) ~= 'table' or not Name(source.id) or not Amount(source.worldID)
        or not Amount(source.floorID) or not Name(source.phaseID)
        or (source.taxiNodeID ~= nil and (not Amount(source.taxiNodeID) or source.taxiNodeID == 0)) then return end
    local target = Target.Capture({key=source.id,title=source.title,position=source.position})
    if source.position ~= nil and not target.mapID then return end
    return {id=source.id,worldID=source.worldID,floorID=source.floorID,phaseID=source.phaseID,
        taxiNodeID=source.taxiNodeID,title=target.name,
        position=target.mapID and {mapID=target.mapID,x=target.x,y=target.y}}
end

local function Capture(source)
    if type(source) ~= 'table' or not Name(source.id) or not Name(source.from) or not Name(source.to)
        or source.from == source.to or type(source.costs) ~= 'table' then return end
    local origin, destination = Stop(source.origin), Stop(source.destination)
    if not origin or not destination or origin.id == destination.id then return end
    local costs = {}
    for _, key in ipairs(COST_FIELDS) do
        local value = source.costs[key]
        if value ~= nil and (not Finite(value) or value < 0 or (key == 'ride' and value == 0)) then return end
        if key ~= 'ride' and value == nil then return end
        costs[key] = value
    end
    if source.fareCopper ~= nil and not Amount(source.fareCopper) then return end
    if not Finite(source.timeoutSeconds) or source.timeoutSeconds <= 0 then return end
    return {id=source.id,from=source.from,to=source.to,origin=origin,destination=destination,
        costs=costs,fareCopper=source.fareCopper,timeoutSeconds=source.timeoutSeconds}
end

local function Override(source)
    if type(source) ~= 'table' then return end
    local result = {}
    for key, value in pairs(source) do
        local valid = key == 'fareCopper' and Amount(value)
        for _, field in ipairs(COST_FIELDS) do
            if key == field then valid = Finite(value) and value >= 0 and (field ~= 'ride' or value > 0) end
        end
        if not valid then return end
        result[key] = value
    end
    return result
end

function Taxi.New(declarations, observation, settings)
    if type(declarations) ~= 'table' then return nil, 'invalid_taxi_routes' end
    if settings==nil then settings={} end
    if type(settings) ~= 'table' or (settings.routes ~= nil and type(settings.routes) ~= 'table') then
        return nil, 'invalid_taxi_settings'
    end
    for key in pairs(settings) do
        if key~='routes' and key~='defaultRideSeconds' then return nil,'invalid_taxi_settings' end
    end
    local fallback = settings.defaultRideSeconds
    if fallback==nil then fallback=DEFAULT_RIDE_SECONDS end
    if not Finite(fallback) or fallback <= 0 then return nil, 'invalid_taxi_settings' end
    local catalog = setmetatable({byId={},outgoing={},nodes={},routes={},revision=0,
        settings={},defaultRideSeconds=fallback},Catalog)
    local count, maximum, stops = 0, 0, {}
    for key, source in pairs(declarations) do
        if not Amount(key) or key < 1 or key > MAX_ROUTES then return nil, 'invalid_taxi_routes' end
        local route = Capture(source)
        if not route or catalog.byId[route.id] then return nil, 'invalid_taxi_route' end
        for _,stop in ipairs({route.origin,route.destination}) do
            if stops[stop.id] and not Target.Same(stops[stop.id],stop) then return nil,'inconsistent_taxi_stop' end
            stops[stop.id]=stop
        end
        count, maximum = count+1, math.max(maximum,key)
        catalog.byId[route.id] = route
        local row = catalog.outgoing[route.from] or {}
        catalog.outgoing[route.from],row[#row+1]=row,route
    end
    if count ~= maximum then return nil, 'invalid_taxi_routes' end
    for id, value in pairs(settings.routes or {}) do
        local override = Override(value)
        if not catalog.byId[id] or not override then return nil, 'invalid_taxi_settings' end
        catalog.settings[id] = override
    end
    if observation~=nil then
        local changed, reason = catalog:Observe(observation)
        if changed == nil then return nil, reason end
    end
    return catalog
end

function Catalog:Observe(source)
    if type(source) ~= 'table' or not Amount(source.revision) or source.revision < 1
        or type(source.nodes) ~= 'table' or type(source.routes) ~= 'table' then return nil, 'invalid_taxi_observation' end
    if source.revision <= self.revision then return false, 'stale_observation' end
    local nodes, routes = {}, {}
    for _, route in pairs(self.byId) do
        for _, stop in ipairs({route.origin,route.destination}) do
            local node = source.nodes[stop.id]
            if node ~= nil then
                if type(node) ~= 'table' or type(node.discovered) ~= 'boolean' then return nil, 'invalid_taxi_observation' end
                nodes[stop.id] = {discovered=node.discovered}
            end
        end
        local observed = source.routes[route.id]
        if observed ~= nil then
            if type(observed) ~= 'table' or (observed.reachable ~= nil and type(observed.reachable) ~= 'boolean')
                or (observed.fareCopper ~= nil and not Amount(observed.fareCopper))
                or (observed.rideSeconds ~= nil and (not Finite(observed.rideSeconds) or observed.rideSeconds <= 0)) then
                return nil, 'invalid_taxi_observation'
            end
            routes[route.id] = {reachable=observed.reachable,fareCopper=observed.fareCopper,rideSeconds=observed.rideSeconds}
        end
    end
    local changed = not Target.Same(self.nodes,nodes) or not Target.Same(self.routes,routes)
    self.nodes,self.routes,self.revision=nodes,routes,source.revision
    return changed, changed and nil or 'unchanged_observation'
end

function Catalog:Edge(node, cursor)
    local route = (self.outgoing[node] or {})[cursor]
    if not route then return end
    local origin, destination = self.nodes[route.origin.id],self.nodes[route.destination.id]
    local observation=self.routes[route.id]
    local observed, override = observation or {},self.settings[route.id] or {}
    local access = 'unknown'
    if (origin and origin.discovered == false) or (destination and destination.discovered == false)
        or observed.reachable == false then access = 'unavailable'
    elseif origin and destination and observed.reachable == true then access = 'available' end
    local fare = override.fareCopper
    if fare == nil then fare = observed.fareCopper end
    if fare == nil and not observation then fare = route.fareCopper end
    if fare == nil and access ~= 'unavailable' then access = 'unknown' end
    local detail, total = {}, 0
    for _, key in ipairs(COST_FIELDS) do
        local value = override[key]
        if value == nil and key == 'ride' then value = observed.rideSeconds end
        if value == nil then value = route.costs[key] end
        if value == nil then value = self.defaultRideSeconds;detail.estimatedRide=true end
        detail[key],total=value,total+value
    end
    if not Finite(total) then return nil, 'taxi_cost_overflow' end
    return {id='taxi:'..route.id,from=route.from,to=route.to,kind='taxi',taxiId=route.id,
        seconds=total,access=access,resources=fare ~= nil and {money=fare} or {},
        fareCopper=fare,costDetail=detail}
end

function Catalog:Prepare(graph)
    if self.prepared then return true end
    local id, route = next(self.byId,self.cursor)
    if not id then self.prepared=true;return true end
    for _, node in ipairs({route.from,route.to}) do
        local found, status, reason
        if graph.partitioned then found,status,reason=graph:Locate(node) else found=graph.index[node] end
        if not found then return nil,status or 'invalid',reason or 'invalid_taxi_node' end
    end
    self.cursor=id
    return false
end

function Catalog:SetCosts(id,source)
    local override=Override(source)
    if not self.byId[id] or not override then return nil,'invalid_taxi_costs' end
    if Target.Same(self.settings[id] or {},override) then return false end
    self.settings[id]=override
    return true
end

-- A fresh native quote may invalidate an estimate even when manually overridden.
function Catalog:Revalidate(id, expectedFare, source, balances)
    local route = self.byId[id]
    if not route or type(source) ~= 'table' or source.confirmed ~= true
        or source.originID ~= route.origin.id or source.destinationID ~= route.destination.id
        or source.reachable ~= true or not Amount(source.fareCopper) then return nil, 'taxi_quote_unknown' end
    if source.fareCopper ~= expectedFare then return nil, 'taxi_fare_changed' end
    local spent, reason = ns.NavigationV2Resources.Spend(balances,{}, {money=source.fareCopper})
    if not spent then return nil, reason end
    return true
end

ns.NavigationV2Taxi = Taxi
return Taxi
