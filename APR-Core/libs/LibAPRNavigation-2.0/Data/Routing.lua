-- Prepared routing pages: bounded native decoding, no positions or graph copies.
local _, ns = ...
local Finite, Cache = ns.NavigationV2Graph.Finite, ns.NavigationV2Sectors
local Routing, Page = {}, {}
Routing.__index, Page.__index = Routing, Page
local VERSION, MAX_LANDMARKS, MAX_ROWS = 1, 8, 128
local MAX_NODES, MAX_EDGES, CAP = 4096, 1024, 4294967295
local MAX_RAW, MAX_PAYLOAD, ROWS_PER_CACHE_UNIT = 16384, 22000, 128
local MAX_SAFE = ns.NavigationV2Graph.SAFE_INTEGER
local POTENTIAL_ROWS, POTENTIAL_CACHE_ROWS, WITNESS_CACHE_ROWS = 128, 1024, 1024

local function Integer(value, lo, hi)
    return Finite(value) and value >= lo and value <= hi and value % 1 == 0
end

local function Array(value, maximum)
    if type(value) ~= 'table' then return nil end
    local count = 0
    for key in pairs(value) do
        count = count + 1
        if count > maximum or not Integer(key, 1, maximum) then return nil end
    end
    if count == #value then return count end
end

local function Slug(value)
    return type(value) == 'string' and value:match('^[a-zA-Z][a-zA-Z0-9_%-]*$') ~= nil
end

local function Identity(value)
    return type(value) == 'string' and #value == 64 and value:match('^[a-f0-9]+$') ~= nil
end

local function NodeId(sector, node)
    return sector..':terrain:'..node
end

function Routing.New(source)
    local atlas, units = source.routing, source.cacheSize
    local pages=source.loader and source.loader.pages
    if pages and type(atlas)=='table' then
        local header={}
        for _,key in ipairs({'version','identity','names','ordinals','landmarks','landmarkNodes',
            'rowsPerBlock','potentialRowsPerBlock','witnessRowsPerBlock'}) do header[key]=atlas[key] end
        header.sectors=pages.bootstrap;atlas=header
    end
    if units == nil then units = 2 end
    if type(atlas) ~= 'table' or atlas.version ~= VERSION or not Identity(atlas.identity)
        or type(atlas.names) ~= 'table' or type(atlas.sectors) ~= 'table' or type(atlas.ordinals)~='table'
        or not Integer(atlas.landmarks, 0, MAX_LANDMARKS) or not Integer(atlas.rowsPerBlock, 1, MAX_ROWS)
        or not Integer(atlas.potentialRowsPerBlock,1,POTENTIAL_ROWS)
        or not Integer(atlas.witnessRowsPerBlock,1,POTENTIAL_ROWS) or type(atlas.landmarkNodes)~='table'
        or type(source.index) ~= 'table' or type(source.complete) ~= 'boolean'
        or type(source.loader) ~= 'table' or type(source.loader.options) ~= 'table'
        or not Integer(units, 1, 8) then return nil, 'invalid_routing' end
    if source.routingIdentity ~= atlas.identity then return nil, 'routing_identity_mismatch' end
    local maxRows = units * ROWS_PER_CACHE_UNIT
    return setmetatable({partitioned=true, routing=true, integerCosts=true, complete=source.complete,
        index=source.index, atlas=atlas, pages=pages, checkedMetadata=setmetatable({},{__mode='k'}),
        options=source.loader.options, maxRows=maxRows,
        capacity=math.floor(maxRows / atlas.rowsPerBlock), cache={},
        potentialCache={capacity=math.floor(POTENTIAL_CACHE_ROWS/atlas.potentialRowsPerBlock),cache={},stats={resident=0,evictions=0}},
        witnessCache={capacity=math.floor(WITNESS_CACHE_ROWS/atlas.witnessRowsPerBlock),cache={},stats={resident=0,evictions=0}},
        stats={resident=0, residentRows=0, loads=0, hits=0, evictions=0, geometryLoads=0,
            operations=0, nativeDecodes=0, rowsValidated=0, edgesValidated=0,
            potentialLoads=0,potentialHits=0,potentialEvictions=0,potentialRows=0,potentialsValidated=0,
            witnessLoads=0,witnessHits=0,witnessRows=0,witnessEvictions=0}}, Routing)
end

local function Metadata(graph, sector)
    if graph.pages then return graph.pages:Lookup(sector) end
    local source, item = graph.index[sector], graph.atlas.sectors[sector]
    if source == nil or item == nil then return nil, 'unknown', 'sector_absent' end
    if type(source) ~= 'table' or type(item) ~= 'table' or type(source.name) ~= 'string'
        or not source.name:match('%S') or not Integer(item.nodes, 1, MAX_NODES)
        or source.nodes ~= item.nodes or type(item.complete) ~= 'boolean' or source.complete ~= item.complete
        or type(source.links) ~= 'table' or type(item.blocks) ~= 'table' or type(item.ranges) ~= 'table'
        or type(item.potentialBlocks) ~= 'table' or type(item.witnessBlocks)~='table' then
        return nil, 'invalid', 'invalid_routing_sector'
    end
    return item
end

function Routing:Locate(id)
    local sector, suffix = id:match('^([^:]+):terrain:(%d+)$')
    if not Slug(sector) then return nil, 'invalid', 'invalid_request' end
    local item, status, reason = Metadata(self, sector)
    if not item then return nil, status, reason end
    local node = tonumber(suffix)
    if not Integer(node, 1, item.nodes) or tostring(node) ~= suffix then return nil, 'invalid', 'invalid_request' end
    return id, sector, item, node
end

local function Ranges(graph, item)
    if Array(item.ranges, MAX_LANDMARKS) ~= graph.atlas.landmarks then return nil end
    for _, row in ipairs(item.ranges) do
        if Array(row, 4) ~= 4 or not Integer(row[1], 0, CAP) or not Integer(row[2], row[1], CAP)
            or not Integer(row[3], 0, CAP) or not Integer(row[4], row[3], CAP) then return nil end
    end
    return true
end

local function Edge(job, edge)
    local graph, source = job.graph, job.index or job.graph.index[job.sector]
    if Array(edge, 5) ~= 5 or not Integer(edge[1], 1, 65535) or not Integer(edge[2], 1, MAX_NODES)
        or not Integer(edge[3], 0, CAP) or not Integer(edge[4], 0, 2)
        or not Integer(edge[5], -256, 24576) or edge[5] == 0 then return 'invalid_routing_edge' end
    local target = graph.atlas.names[edge[1]]
    if not Slug(target) then return 'invalid_routing_edge' end
    local metadata = graph.atlas.sectors[target]
    if metadata ~= nil and (type(metadata)~='table' or not Integer(metadata.nodes, 1, MAX_NODES) or edge[2] > metadata.nodes) then
        return 'invalid_routing_edge'
    end
    if edge[5] > 0 then
        if target ~= job.sector or edge[4] ~= 0 then return 'invalid_routing_edge' end
    else
        local link = source.links[-edge[5]]
        local access = link and link.access
        if access==nil then access='available' end
        local code = access == 'available' and 0 or access == 'unknown' and 1 or access == 'unavailable' and 2
        if type(link) ~= 'table' or not Slug(link.id) or type(link.name) ~= 'string' or not link.name:match('%S')
            or link.from ~= job.first + job.cursor - 1 or link.sector ~= target or link.to ~= edge[2]
            or link.seconds ~= edge[3] / 1000 or code ~= edge[4] then return 'invalid_routing_boundary' end
    end
end

function Page:Cancel()
    if self.read then self.read:Cancel();self.read=nil end
    self.cancelled, self.decoded, self.bytes, self.rows = true, nil, nil, nil
end

local function Decode(job, operation, nextPhase)
    local ok, value = pcall(job.graph.options[operation], job.bytes)
    job.graph.stats.nativeDecodes = job.graph.stats.nativeDecodes + 1
    if job.cancelled then return 'cancelled', 'cancelled' end
    if not ok or value == nil then return 'unknown', 'decode_failed' end
    if operation == 'deserialize' then job.decoded, job.bytes = value, nil
    else
        if type(value) ~= 'string' or #value > MAX_RAW then return 'invalid', 'decoded_over_limit' end
        if operation == 'inflate' and #value ~= job.metadata.rawBytes then return 'invalid', 'decoded_size_mismatch' end
        job.bytes = value
    end
    job.phase = nextPhase
end

local function Header(job)
    local raw = job.metadata
    if type(raw) ~= 'table' or raw.first ~= job.first or raw.rows ~= job.count
        or not Integer(raw.rawBytes, 1, MAX_RAW) or type(raw.payload) ~= 'string' or #raw.payload > MAX_PAYLOAD then
        return 'invalid', 'invalid_routing_block'
    end
    if not job.graph.pages and not Ranges(job.graph, job.item) then return 'invalid', 'invalid_routing_potentials' end
    job.bytes, job.phase = raw.payload, 'base64'
end

local function Block(job)
    local data = job.decoded
    if Array(data, 3) ~= 3 or data[1] ~= VERSION or data[2] ~= job.first
        or Array(data[3], job.potential and POTENTIAL_ROWS or MAX_ROWS) ~= job.count then
        return 'invalid', 'invalid_routing_block'
    end
    job.rows, job.decoded = data[3], nil
    return 'ready'
end

local function Potential(graph,entry,cursor,item)
    if entry.validatedRows[cursor] then return true end
    local row,k=entry.rows[cursor],graph.atlas.landmarks
    if Array(row,2)~=2 or Array(row[1],MAX_LANDMARKS)~=k or Array(row[2],MAX_LANDMARKS)~=k then return nil end
    for i=1,k do
        local bounds=item.ranges[i]
        if not Integer(row[1][i],bounds[1],bounds[2]) or not Integer(row[2][i],bounds[3],bounds[4]) then return nil end
    end
    entry.validatedRows[cursor]=true
    graph.stats.potentialsValidated=graph.stats.potentialsValidated+1
    return true
end

function Page:Advance()
    if self.cancelled then return 'cancelled', 'cancelled' end
    self.graph.stats.operations = self.graph.stats.operations + 1
    if self.phase=='flat' then
        local status,reason=self.read:Advance()
        if status=='ready' then
            if self.read.kind~=1 then return 'invalid','invalid_flat_routing' end
            self.metadata,self.read,self.phase=self.read.value,nil,'header';return
        end
        return status,reason
    end
    if self.phase == 'header' then return Header(self) end
    if self.phase == 'base64' then return Decode(self, 'decodeBase64', 'inflate') end
    if self.phase == 'inflate' then return Decode(self, 'inflate', 'deserialize') end
    if self.phase == 'deserialize' then return Decode(self, 'deserialize', 'block') end
    if self.phase == 'block' then return Block(self) end
end

local function FlatMetadata(graph,search,sector)
    local metadata,status,reason=graph.pages:Ensure(search,sector)
    if not metadata then return nil,status,reason end
    if graph.checkedMetadata[metadata] then return metadata end
    local item=metadata.routing
    local b=graph.pages.bootstrap[sector]
    if type(item)~='table' or item.nodes~=b.nodes or item.complete~=b.complete or not Ranges(graph,item)
        or not graph.pages.ValidSpan(graph.pages,item.blocks) or not graph.pages.ValidSpan(graph.pages,item.potentialBlocks)
        or Array(item.witnessBlocks,MAX_LANDMARKS)~=graph.atlas.landmarks then return nil,'invalid','invalid_routing_sector' end
    for _,pair in ipairs(item.witnessBlocks) do
        if Array(pair,2)~=2 or not graph.pages.ValidSpan(graph.pages,pair[1])
            or not graph.pages.ValidSpan(graph.pages,pair[2]) then return nil,'invalid','invalid_routing_sector' end
    end
    graph.checkedMetadata[metadata]=true
    return metadata
end

local function PageRow(entry,localNode,metadata)
    local cursor=localNode-entry.first+1
    local row=entry.rows[cursor]
    if type(row)~='table' then return nil,'invalid','invalid_routing_row' end
    return row,nil,nil,entry,cursor,metadata
end

function Routing:GetPage(search, node, potential, witness, forward)
    local located, sector, item, localNode = self:Locate(node)
    if not located then return nil, sector, item end
    local flatMetadata
    if self.pages then
        local status,reason
        flatMetadata,status,reason=FlatMetadata(self,search,sector)
        if not flatMetadata then return nil,status,reason end
        item=flatMetadata.routing
    end
    local size=witness and self.atlas.witnessRowsPerBlock or potential and self.atlas.potentialRowsPerBlock or self.atlas.rowsPerBlock
    local owner=witness and self.witnessCache or potential and self.potentialCache or self
    local page = math.floor((localNode - 1) / size) + 1
    local prefix=witness and ('w:'..witness..(forward and ':f:' or ':b:')) or potential and 'p:' or 'r:'
    local key = prefix..sector..':'..page
    local entry = owner.cache[key]
    if entry then
        if search.loading then search.loading.job:Cancel(); search.loading = nil end
        Cache.CacheTouch(owner, entry)
        if witness then self.stats.witnessHits=self.stats.witnessHits+1
        elseif potential then self.stats.potentialHits=self.stats.potentialHits+1
        else self.stats.hits = self.stats.hits + 1 end
        if not item.complete then search.sawIncomplete = true end
        return PageRow(entry,localNode,flatMetadata)
    end
    if search.routingFailures and search.routingFailures[key] then return nil, 'unknown', search.routingFailures[key] end
    if not search.loading then
        local first = (page - 1) * size + 1
        local blocks
        if witness then
            local directions=item.witnessBlocks[witness]
            if directions==nil then return nil,'unknown','routing_block_absent' end
            if type(directions)~='table' then return nil,'invalid','invalid_routing_block' end
            blocks=directions[forward and 1 or 2]
        elseif potential then blocks=item.potentialBlocks
        else blocks=item.blocks end
        if blocks==nil then return nil,'unknown','routing_block_absent' end
        if type(blocks)~='table' then return nil,'invalid','invalid_routing_block' end
        local raw=not self.pages and blocks[page]
        if self.pages and (page>blocks.count) then return nil,'unknown','routing_block_absent' end
        local read=self.pages and self.pages:Read(blocks.first+page-1)
        if raw == nil and not read then return nil, 'unknown', 'routing_block_absent' end
        search.loading = {id=key, job=setmetatable({graph=self, sector=sector, item=item,
            metadata=raw,read=read, first=first, potential=potential or witness,
            count=math.min(size,item.nodes-first+1), phase=read and 'flat' or 'header'}, Page),
            sector=sector,sectorMetadata=flatMetadata}
        if witness then self.stats.witnessLoads=self.stats.witnessLoads+1
        elseif potential then self.stats.potentialLoads=self.stats.potentialLoads+1
        else self.stats.loads = self.stats.loads + 1 end
        return nil, 'running'
    end
    local job = search.loading.job
    local status, reason = job:Advance()
    if status == 'ready' then
        entry = {id=key, rows=job.rows, first=job.first,validatedRows={},checkedEdges={}}
        local removed = Cache.CacheStore(owner, entry)
        if witness then
            self.stats.witnessRows=self.stats.witnessRows+#entry.rows-(removed and #removed.rows or 0)
            self.stats.witnessEvictions=owner.stats.evictions
        elseif potential then
            self.stats.potentialRows=self.stats.potentialRows+#entry.rows-(removed and #removed.rows or 0)
            self.stats.potentialEvictions=owner.stats.evictions
        else self.stats.residentRows=self.stats.residentRows+#entry.rows-(removed and #removed.rows or 0) end
        search.loading = nil
        if not item.complete then search.sawIncomplete = true end
        return PageRow(entry,localNode,flatMetadata)
    end
    if status then
        search.loading = nil
        if status == 'unknown' then
            search.routingFailures = search.routingFailures or {}
            search.routingFailures[key] = reason
        end
        return nil, status, reason
    end
    return nil, 'running'
end

function Routing:Ensure(search,node)
    local row,status,reason,entry,cursor,metadata=self:GetPage(search,node,true)
    if not row then return nil,status,reason end
    local sector=node:match('^([^:]+):')
    local item=metadata and metadata.routing or self.atlas.sectors[sector]
    if not Potential(self,entry,cursor,item) then
        return nil,'invalid','invalid_routing_potentials'
    end
    return row
end

function Routing:Estimate(search, node, row)
    local sector = node:match('^([^:]+):')
    local metadata=self.pages and self.pages:Peek(sector)
    local goal, bounds = search.goalPotential, self.pages and metadata and metadata.routing or not self.pages and self.atlas.sectors[sector]
    if not goal or not bounds then return 0 end
    if not row then
        local localNode=tonumber(node:match(':terrain:(%d+)$'))
        local page=math.floor((localNode-1)/self.atlas.potentialRowsPerBlock)+1
        local entry=self.potentialCache.cache['p:'..sector..':'..page]
        if entry then
            local cursor=localNode-entry.first+1
            if Potential(self,entry,cursor,bounds) then row=entry.rows[cursor] end
            Cache.CacheTouch(self.potentialCache,entry)
        end
    end
    if not row and search.estimates[sector] then return search.estimates[sector] end
    if not row and not Ranges(self, bounds) then return 0 end
    local h = 0
    for i=1,self.atlas.landmarks do
        local a, b = row and row[1][i] or bounds.ranges[i][2], row and row[2][i] or bounds.ranges[i][3]
        h = math.max(h, goal[1][i] - a, b - goal[2][i])
    end
    if not row then search.estimates[sector] = h end
    return h
end

function Routing:Refine(search, entry, row)
    if entry.milliseconds > MAX_SAFE - CAP then return entry.milliseconds end
    return entry.milliseconds + self:Estimate(search, entry.node, row)
end

function Routing:ReadEdge(search, node, cursor)
    local active=search.adjacency
    if not active or active.node~=node then
        local row,status,reason,entry,localCursor,metadata=self:GetPage(search,node,false)
        if not row then return nil,status,reason end
        if not entry.validatedRows[localCursor] then
            if not Array(row,MAX_EDGES) then return nil,'invalid','invalid_routing_row' end
            entry.validatedRows[localCursor]=true
            entry.checkedEdges[localCursor]={}
            self.stats.rowsValidated=self.stats.rowsValidated+1
        end
        active={node=node,row=row,checked=entry.checkedEdges[localCursor],localNode=entry.first+localCursor-1,
            sector=node:match('^([^:]+):')}
        active.index=metadata and metadata.index or self.index[active.sector]
        search.adjacency=active
    end
    local row=active.row
    local edge = row[cursor]
    if not edge then return end
    local sector = active.sector
    if not active.checked[cursor] then
        local invalid=Edge({graph=self,sector=sector,index=active.index,first=active.localNode,cursor=1},edge)
        if invalid then return nil,'invalid',invalid end
        active.checked[cursor]=true
        self.stats.edgesValidated=self.stats.edgesValidated+1
    end
    local id = edge[5] > 0 and ('route:'..edge[5]) or active.index.links[-edge[5]].id
    return {id=sector..':'..id, from=node, to=NodeId(self.atlas.names[edge[1]], edge[2]),
        seconds=edge[3] / 1000, milliseconds=edge[3],
        access=edge[4] == 0 and 'available' or edge[4] == 1 and 'unknown' or 'unavailable'}
end

local function Reject(search,reason)
    if search.loading then search.loading.job:Cancel();search.loading=nil end
    search.certificate=nil
    search.diagnostics.certificateRejected=reason
    return true
end

local function Witness(graph,search,node,landmark,forward)
    local row,status,reason=graph:GetPage(search,node,false,landmark,forward)
    if not row then return nil,status,reason end
    local parent=row
    if Array(parent,5)~=5 or not Integer(parent[1],1,65535) or not Integer(parent[2],1,MAX_NODES)
        or not Integer(parent[3],0,CAP) or not Integer(parent[4],0,2)
        or not Integer(parent[5],-256,24576) or parent[5]==0 or not Slug(graph.atlas.names[parent[1]]) then
        return nil,'invalid','invalid_routing_witness'
    end
    return parent
end

local function BeginCertificate(graph,search,origin)
    search.certificateTried=true
    if #search.objective.via>0 or search.limits.labels<3 then return end
    local lower=0
    for i=1,graph.atlas.landmarks do
        lower=math.max(lower,search.goalPotential[1][i]-origin[1][i],origin[2][i]-search.goalPotential[2][i])
    end
    for i=1,graph.atlas.landmarks do
        local a,b=origin[2][i],search.goalPotential[1][i]
        if a<CAP and b<CAP and a+b==lower then
            local landmark=graph.atlas.landmarkNodes[i]
            if Array(landmark,2)~=2 or not Slug(graph.atlas.names[landmark[1]])
                or not Integer(landmark[2],1,MAX_NODES) then return end
            local goal={node=search.objective.to}
            search.certificate={index=i,landmark=NodeId(graph.atlas.names[landmark[1]],landmark[2]),
                expected=lower,total=0,goal=goal,back=goal,front={node=search.objective.from},
                seenBack={},seenFront={},retained=3,phase='back_witness'}
            search.diagnostics.phase='certificate'
            return
        end
    end
end

local function Trace(graph,search)
    local c=search.certificate
    local back=c.phase=='back_witness' or c.phase=='back_edge'
    local current=back and c.back or c.front
    if current.node==c.landmark then
        if back then c.root=c.back;c.phase='front_witness';return nil,'running' end
        if c.total~=c.expected then return Reject(search,'witness_cost_mismatch') end
        c.root.parent,c.root.edge=c.front.parent,c.front.edge
        search.total,search.build,search.nodes,search.segments=c.expected/1000,c.goal,{c.goal.node},{}
        search.certificate=nil
        search.diagnostics.certificateComplete=true
        search.diagnostics.phase='reconstruct'
        return true,'prepared'
    end
    if c.phase=='back_witness' or c.phase=='front_witness' then
        if c.retained>=search.limits.labels then
            return nil,'budget_exceeded','label_limit'
        end
        local seen=back and c.seenBack or c.seenFront
        if seen[current.node] then return Reject(search,'witness_cycle') end
        local witness,status,reason=Witness(graph,search,current.node,c.index,not back)
        if not witness then if status=='running' then return nil,status end;return Reject(search,reason) end
        seen[current.node]=true
        if back then
            c.source=NodeId(graph.atlas.names[witness[1]],witness[2])
            local sector,index=current.node:match('^([^:]+):terrain:(%d+)$')
            c.edge={graph.atlas.ordinals[sector],tonumber(index),witness[3],witness[4],witness[5]}
        else c.source=current.node;c.edge=witness end
        c.phase=back and 'back_edge' or 'front_edge'
        return nil,'running'
    end
    local sector,localNode=c.source:match('^([^:]+):terrain:(%d+)$')
    local located,_,locateReason=graph:Locate(c.source)
    if not located then return Reject(search,locateReason) end
    local index=graph.index[sector]
    if graph.pages then
        local metadata,status,reason=FlatMetadata(graph,search,sector)
        if not metadata then if status=='running' then return nil,status end;return Reject(search,reason) end
        index=metadata.index
    end
    local invalid=Edge({graph=graph,sector=sector,index=index,first=tonumber(localNode),cursor=1},c.edge)
    if invalid then return Reject(search,invalid) end
    local raw=c.edge
    local id=raw[5]>0 and ('route:'..raw[5]) or index.links[-raw[5]].id
    local edge={id=sector..':'..id,from=c.source,to=NodeId(graph.atlas.names[raw[1]],raw[2]),
        milliseconds=raw[3],seconds=raw[3]/1000,
        access=raw[4]==0 and 'available' or raw[4]==1 and 'unknown' or 'unavailable'}
    graph.stats.edgesValidated=graph.stats.edgesValidated+1
    if edge.access~='available' or (back and edge.to~=current.node) then return Reject(search,'witness_unavailable') end
    c.total=c.total+edge.milliseconds
    if c.total>c.expected then return Reject(search,'witness_cost_mismatch') end
    if back then
        local parent={node=edge.from}
        current.parent,current.edge,c.back=parent,edge,parent
        c.phase='back_witness'
    else
        c.front={node=edge.to,parent=current,edge=edge}
        c.phase='front_witness'
    end
    c.retained=c.retained+1
    search.diagnostics.witnessLabels=c.retained
    search.diagnostics.witnessEdges=(search.diagnostics.witnessEdges or 0)+1
    return nil,'running'
end

function Routing:PrepareRequest(search)
    if not search.goalPotential then
        local row,status,reason=self:Ensure(search,search.objective.to)
        if not row then return nil,status,reason end
        search.goalPotential,search.estimates={row[1],row[2]},{}
        return nil,'running'
    end
    if not search.certificateTried then
        local row,status,reason=self:Ensure(search,search.objective.from)
        if not row then return nil,status,reason end
        BeginCertificate(self,search,row)
        return nil,'running'
    end
    if search.certificate then return Trace(self,search) end
    return true
end

ns.NavigationV2Routing = Routing
return Routing
