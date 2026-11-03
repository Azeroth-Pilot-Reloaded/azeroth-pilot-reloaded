-- Lazy partition adapter. The shared cache owns only fully validated sectors;
-- partial decode/compilation belongs to its requesting search, never the world.
local _, ns = ...
local Graph = ns.NavigationV2Graph
local Sectors = {}
Sectors.__index = Sectors
local MAX_NODES, MAX_LINKS, MAX_CACHE = 4096, 256, 8

local function Integer(value, maximum)
    return Graph.Finite(value) and value >= 1 and value <= maximum and value % 1 == 0
end

local function Slug(value)
    return type(value) == 'string' and value:match('^[a-zA-Z][a-zA-Z0-9_%-]*$') ~= nil
end

local function Name(value)
    return type(value) == 'string' and value:match('%S') ~= nil
end

local function NodeId(sector, node)
    return sector..':terrain:'..node
end

function Sectors.New(source)
    if source.routing ~= nil then
        if not ns.NavigationV2Routing then return nil, 'routing_unavailable' end
        return ns.NavigationV2Routing.New(source)
    end
    local capacity = source.cacheSize
    if capacity == nil then capacity = 2 end
    if type(source.index) ~= 'table' or type(source.complete) ~= 'boolean'
        or type(source.loader) ~= 'table' or type(source.loader.Load) ~= 'function'
        or not Integer(capacity, MAX_CACHE) then return nil, 'invalid_sector_graph' end
    return setmetatable({partitioned=true, complete=source.complete, index=source.index,
        loader=source.loader, pages=source.loader.pages, capacity=capacity, cache={},
        stats={resident=0, loads=0, hits=0, evictions=0}}, Sectors)
end

local function Metadata(graph, id)
    if graph.pages then
        local value,_,reason=graph.pages:Lookup(id)
        return value,reason
    end
    local entry = graph.index[id]
    if entry == nil then return nil, 'sector_absent' end
    if type(entry) ~= 'table' or not Name(entry.name) or not Integer(entry.nodes, MAX_NODES)
        or type(entry.complete) ~= 'boolean' or type(entry.links) ~= 'table' then
        return nil, 'invalid_sector_index'
    end
    return entry
end

function Sectors:Locate(id)
    local sector, suffix = id:match('^([^:]+):terrain:(%d+)$')
    if not sector or not Slug(sector) then return nil, 'invalid', 'invalid_request' end
    local metadata, reason = Metadata(self, sector)
    if not metadata then return nil, reason == 'sector_absent' and 'unknown' or 'invalid', reason end
    local node = tonumber(suffix)
    if not Integer(node, metadata.nodes) or tostring(node) ~= suffix then return nil, 'invalid', 'invalid_request' end
    return id, sector, metadata
end

local function Unlink(graph, entry)
    if entry.previous then entry.previous.next = entry.next else graph.first = entry.next end
    if entry.next then entry.next.previous = entry.previous else graph.last = entry.previous end
    entry.previous, entry.next = nil, nil
end

local function Touch(graph, entry)
    if graph.last == entry then return end
    if graph.first == entry or entry.previous then Unlink(graph, entry) end
    entry.previous = graph.last
    if graph.last then graph.last.next = entry else graph.first = entry end
    graph.last = entry
end

local function Store(graph, entry)
    local removed
    if graph.stats.resident == graph.capacity then
        local oldest = graph.first
        removed = oldest
        Unlink(graph, oldest)
        graph.cache[oldest.id] = nil
        graph.stats.resident = graph.stats.resident - 1
        graph.stats.evictions = graph.stats.evictions + 1
    end
    graph.cache[entry.id] = entry
    Touch(graph, entry)
    graph.stats.resident = graph.stats.resident + 1
    return removed
end

-- Shared bounded LRU mechanics; prepared routing caches pages with this owner.
Sectors.CacheTouch, Sectors.CacheStore = Touch, Store

local function Boundary(graph, state, key, link)
    if not Integer(key, MAX_LINKS) or type(link) ~= 'table' or not Slug(link.id)
        or not Name(link.name) or state.seen[link.id] or not Integer(link.from, state.metadata.nodes)
        or not Slug(link.sector) or not Integer(link.to, MAX_NODES)
        or not Graph.Finite(link.seconds) or link.seconds < 0 then return 'invalid_boundary' end
    local access = link.access
    if access == nil then access = 'available' end
    if access ~= 'available' and access ~= 'unavailable' and access ~= 'unknown' then return 'invalid_boundary' end
    local target, reason = Metadata(graph, link.sector)
    if not target and reason ~= 'sector_absent' then return reason end
    if target and link.to > target.nodes then return 'invalid_boundary' end
    state.seen[link.id] = true
    local from = NodeId(state.id, link.from)
    local row = state.boundaries[from] or {}
    state.boundaries[from] = row
    row[#row + 1] = {id=state.id..':'..link.id, name=link.name, from=from,
        to=NodeId(link.sector, link.to), seconds=link.seconds, access=access}
end

local function Advance(graph, state)
    if state.job then
        local result = state.job:Advance()
        if result.status == 'running' then return end
        if result.status ~= 'complete' then return result.status, result.reason end
        local preparation, reason = Graph.New(result.graph)
        if not preparation then return 'invalid', reason end
        state.preparation = preparation
        state.positions, state.job = result.positions, nil
        return
    end
    if state.preparation.phase ~= 'ready' then
        local status, reason = state.preparation:Advance()
        if status == 'invalid' then return status, reason end
        return
    end
    local compiled = state.preparation.compiled
    if #compiled.nodes ~= state.metadata.nodes or compiled.complete ~= state.metadata.complete then
        return 'invalid', 'sector_index_mismatch'
    end
    local key, link = next(state.metadata.links, state.cursor)
    if key == nil then
        if state.count ~= state.maximum then return 'invalid', 'invalid_boundary' end
        return 'ready'
    end
    local reason = Boundary(graph, state, key, link)
    if reason then return 'invalid', reason end
    state.count, state.maximum, state.cursor = state.count + 1, math.max(state.maximum, key), key
end

-- One loading, preparation or boundary-validation unit per caller Advance.
function Sectors:Ensure(search, node)
    local sector = node:match('^([^:]+):')
    local entry = self.cache[sector]
    if entry then
        if search.loading and search.loading.job then search.loading.job:Cancel() end
        search.loading = nil
        self.stats.hits = self.stats.hits + 1
        Touch(self, entry)
        if not entry.compiled.complete then search.sawIncomplete = true end
        return entry
    end
    local located, metadata
    located, sector, metadata = self:Locate(node)
    if not located then return nil, sector, metadata end
    local failure = search.sectorFailures and search.sectorFailures[sector]
    if failure then return nil, 'unknown', failure end
    local flatMetadata
    if self.pages then
        local status,reason
        flatMetadata,status,reason=self.pages:Ensure(search,sector)
        if not flatMetadata then return nil,status,reason end
        metadata=flatMetadata.index
    end
    local state = search.loading
    if not state then
        search.loading = {id=sector, metadata=metadata, job=self.loader:Load(sector, true),
            sector=sector,sectorMetadata=flatMetadata,boundaries={}, seen={}, count=0, maximum=0}
        self.stats.loads = self.stats.loads + 1
        search.diagnostics.sectorLoads = (search.diagnostics.sectorLoads or 0) + 1
        return nil, 'running'
    end
    local status, reason = Advance(self, state)
    if status == 'ready' then
        entry = {id=sector, compiled=state.preparation.compiled, positions=state.positions,
            boundaries=state.boundaries}
        Store(self, entry)
        search.loading = nil
        if not entry.compiled.complete then search.sawIncomplete = true end
        return entry
    end
    if status then
        search.loading = nil
        if status == 'unknown' then
            search.sectorFailures = search.sectorFailures or {}
            search.sectorFailures[sector] = reason
        end
        return nil, status, reason
    end
    return nil, 'running'
end

-- Explicit development factory; constructing a source performs no decoding.
function Sectors.Source(index, catalog, options)
    local loader, reason = ns.NavigationV2Terrain.New(catalog, options)
    if not loader then return nil, reason end
    if loader.pages and index~=loader.pages.bootstrap then return nil,'invalid_flat_bootstrap' end
    local complete = options.complete
    if complete == nil then complete = false end
    local source = {partitioned=true, index=index, loader=loader,
        cacheSize=options.cacheSize, complete=complete,
        routing=options.routing, routingIdentity=options.routingIdentity}
    local validated
    validated, reason = Sectors.New(source)
    if not validated then return nil, reason end
    return source
end

function Sectors:ReadEdge(search, node, cursor)
    local entry, status, reason = self:Ensure(search, node)
    if not entry then return nil, status, reason end
    local compiled = entry.compiled
    local row = compiled.outgoing[compiled.index[node]]
    local edge = row[cursor]
    if edge then
        return {id=edge.id, from=node, to=compiled.nodes[edge.to], seconds=edge.seconds, access=edge.access}
    end
    return (entry.boundaries[node] or {})[cursor - #row]
end

ns.NavigationV2Sectors = Sectors
return Sectors
