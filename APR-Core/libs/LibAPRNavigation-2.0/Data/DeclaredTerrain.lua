-- Declared sparse topology and convex anchor volumes. No native observations,
-- proximity links, solver or automatic publication. All payloads are immutable.
local _, ns = ...
local Terrain, Reader, Job = {}, {}, {}
Reader.__index, Job.__index = Reader, Job
local Finite = ns.NavigationV2Graph.Finite
local B = ns.NavigationV2Graph.Budgets
local function Sample(options,key)
    local ok,value=pcall(options[key])
    if ok and Finite(value) and value>=0 then return value end
end
local function Integer(n,lo,hi) return Finite(n) and n%1==0 and n>=lo and n<=hi end
local function Point(p)
    return type(p)=='table' and Integer(p.world,0,9007199254740991)
        and Finite(p.x) and Finite(p.y) and (p.z==nil or Finite(p.z))
end
local function Copy(p)
    local r={}
    for _,key in ipairs({'world','x','y','z','uiMapID','space','floor','phase'}) do r[key]=p[key] end
    return r
end
local function Inside(p,b,z)
    if type(b)~='table' then return false end
    for _,a in ipairs(z and {'x','y','z'} or {'x','y'}) do
        local lo,hi=b['min'..a:upper()],b['max'..a:upper()]
        if not Finite(lo) or not Finite(hi) or lo>hi or not Finite(p[a]) or p[a]<lo or p[a]>hi then return false end
    end
    return true
end
local function Stop(job,status,reason)
    if job.child and job.child.Cancel then job.child:Cancel() end
    if job.geometry then job.geometry:Cancel();job.geometry=nil end
    job.child,job.value,job.pending=nil,nil,nil
    job.result={status=status,reason=reason,diagnostics=job.diagnostics}
    if status=='complete' then
        if job.kind=='resolve' then job.result.connectors=job.connectors
        else job.result.polyline=job.points end
    end
    job.stack=nil
    return job.result
end
function Job:Cancel() return self.result or Stop(self,'cancelled','cancelled') end

local function Backend(reader,sector)
    local declaration=reader.data.index[sector]
    if type(declaration)~='table' or type(declaration.pack)~='string' then return nil,'sector_absent' end
    local id=declaration.pack
    local entry=reader.cache[id]
    if entry then
        reader.serial=reader.serial+1;entry.used=reader.serial;reader.stats.hits=reader.stats.hits+1
        return entry.loader
    end
    local pack=reader.data.packs[id]
    if type(pack)~='table' then return nil,'terrain_pack_absent' end
    local loader,reason=ns.NavigationV2Terrain.New(pack,reader.options)
    if not loader then return nil,reason end
    if reader.stats.resident==reader.capacity then
        local oldest
        for key,item in pairs(reader.cache) do if not oldest or item.used<reader.cache[oldest].used then oldest=key end end
        reader.cache[oldest]=nil;reader.stats.resident=reader.stats.resident-1
        reader.stats.evictions=reader.stats.evictions+1
    end
    reader.serial=reader.serial+1;reader.cache[id]={loader=loader,used=reader.serial}
    reader.stats.resident=reader.stats.resident+1;reader.stats.loads=reader.stats.loads+1
    return loader
end
function Reader:Lookup(id)
    local loader,reason=Backend(self,id)
    if not loader then return nil,'unknown',reason end
    return loader.pages:Lookup(id)
end
function Reader:Ensure(search,id)
    local loader,reason=Backend(self,id)
    if not loader then return nil,'unknown',reason end
    return loader.pages:Ensure(search,id)
end
function Reader:Load(id,qualified)
    local loader,reason=Backend(self,id)
    if loader then return loader:Load(id,qualified) end
    return {Advance=function() return {status='unknown',reason=reason} end,Cancel=function() end}
end
local function NewJob(reader,kind)
    return setmetatable({reader=reader,kind=kind,revision=reader.revision,
        started=Sample(reader.options,'clock'),cpuMs=0,diagnostics={operations=0,cpuMs=0},
        connectors={},points={},stack={}},Job)
end
function Terrain.New(data,options)
    if type(data)~='table' or data.format~='apr-declared-terrain-1'
        or type(data.index)~='table' or type(data.packs)~='table'
        or not Finite(data.walkSpeed) or data.walkSpeed<=0 then return nil,'invalid_declared_terrain' end
    if type(options)~='table' then return nil,'decoder_unavailable' end
    local copy={}
    for _,key in ipairs({'profileClock','decodeBase64','inflate','deserialize'}) do
        if type(options[key])~='function' then return nil,'decoder_unavailable' end
        copy[key]=options[key]
    end
    if options.clock~=nil and type(options.clock)~='function' then return nil,'invalid_clocks' end
    copy.clock=options.clock or function() return copy.profileClock()/1000 end
    local capacity=options.cacheSize or 2
    if not Integer(capacity,1,8) then return nil,'invalid_terrain_cache' end
    local reader=setmetatable({data=data,options=copy,capacity=capacity,cache={},serial=0,revision=1,
        stats={nativeDecodes=0,resident=0,loads=0,hits=0,evictions=0}},Reader)
    local decode=copy.decodeBase64
    copy.decodeBase64=function(s) reader.stats.nativeDecodes=reader.stats.nativeDecodes+1;return decode(s) end
    reader.pages=reader
    reader.source={partitioned=true,index=data.index,loader=reader,cacheSize=capacity,complete=false}
    return reader
end
function Reader:Invalidate() self.revision=self.revision+1 end
function Reader:Resolve(point,direction)
    local job=NewJob(self,'resolve')
    if not Point(point) or (direction~='from' and direction~='to') then Stop(job,'invalid','invalid_terrain_point');return job end
    job.point,job.direction,job.phase=Copy(point),direction,'directory'
    return job
end
function Reader:Geometry(id)
    local job=NewJob(self,'geometry')
    if type(id)~='string' or #id>512 then Stop(job,'invalid','invalid_geometry_id');return job end
    local sector,index=id:match('^(.-):edge%-(%d+)$')
    if sector then
        job.sector,job.edge,job.phase=sector,tonumber(index),'edge_metadata'
    else
        local ordinal,slot,direction,x,y,z
        sector,ordinal,slot,direction,x,y,z=id:match('^(.-):anchor%-(%d+)%-(%d+)%-(%a+):([^:]+):([^:]+):([^:]+)$')
        local p={world=sector and self.data.index[sector] and self.data.index[sector].world,x=tonumber(x),y=tonumber(y),z=tonumber(z)}
        if not sector or not Point(p) or not p.z or (direction~='from' and direction~='to') then
            Stop(job,'invalid','invalid_geometry_id');return job
        end
        job.sector,job.record,job.slot,job.direction=sector,tonumber(ordinal),tonumber(slot),direction
        job.point,job.phase=p,'anchor_geometry'
    end
    return job
end

local function Child(job,ordinal,metadata)
    if not job.child then
        local loader,reason=Backend(job.reader,job.sector)
        if not loader then return nil,'unknown',reason end
        job.child=metadata and loader.pages:LoadMetadata(job.sector) or loader.pages:Read(ordinal,true)
        return nil,'running'
    end
    local status,reason=job.child:Advance()
    if status=='ready' then local value=job.child.value;job.child=nil;return value end
    return nil,status or 'running',reason
end
local function Distance(a,b)
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
local function GeometryPoints(job)
    local chunk=job.chunks[job.chunk]
    if not chunk then
        if job.direction=='to' then
            local last=job.points[#job.points]
            job.length=(job.length or 0)+(last and Distance(last,job.point) or 0)
            job.points[#job.points+1]=job.point
        end
        return 'complete'
    end
    if not job.value then
        local value,status,reason=Child(job,chunk.record)
        if not value then return status,reason end
        if value.kind~='terrain-rows' or type(value.rows)~='table' or #value.rows~=chunk.count then return 'invalid','invalid_geometry_page' end
        job.value,job.cursor=value,1;return
    end
    local point=job.value.rows[job.cursor]
    if not point then job.value=nil;job.chunk=job.chunk+1;return end
    if not Point(point) or not Finite(point.z) or point.world~=job.reader.data.index[job.sector].world then return 'invalid','invalid_geometry_point' end
    if #job.points>=65536 then return 'budget_exceeded','geometry_point_limit' end
    local last=job.points[#job.points]
    job.length=(job.length or 0)+(last and Distance(last,point) or 0)
    job.points[#job.points+1]=Copy(point);job.cursor=job.cursor+1
end
local function BeginPoints(job,chunks)
    if type(chunks)~='table' or #chunks>2048 then return 'invalid','invalid_geometry_span' end
    job.chunks,job.chunk,job.phase=chunks,1,'geometry_points'
end
local function GeometryUnit(job)
    if job.phase=='geometry_points' then return GeometryPoints(job) end
    if job.phase=='anchor_geometry' then
        local value,status,reason=Child(job,job.record)
        if not value then return status,reason end
        local anchor=type(value.anchors)=='table' and value.anchors[job.slot]
        if value.kind~='terrain-anchors' or type(anchor)~='table' or not Inside(job.point,anchor.bounds,true)
            or not anchor.paths[job.direction] then return 'unknown','anchor_direction_unavailable' end
        local p=Copy(anchor.centers[job.direction]);p.x,p.y,p.z=job.point.x,job.point.y,job.point.z
        job.point=p
        if job.direction=='from' then job.points[1]=Copy(p) end
        return BeginPoints(job,anchor.paths[job.direction])
    end
    if job.phase=='edge_metadata' then
        local value,status,reason=Child(job,nil,true)
        if not value then return status,reason end
        if type(value.catalog.terrain)~='table' then return 'unknown','terrain_facts_absent' end
        if type(value.catalog.terrain.edges)~='table' then return 'invalid','invalid_terrain_facts' end
        job.edgeChunks,job.cursor,job.phase=value.catalog.terrain.edges,1,'edge_chunk';return
    end
    local chunk=job.edgeChunks[job.cursor]
    if not chunk then return 'unknown','geometry_absent' end
    if job.edge<chunk.first or job.edge>=chunk.first+chunk.count then job.cursor=job.cursor+1;return end
    local value,status,reason=Child(job,chunk.record)
    if not value then return status,reason end
    local row=type(value.rows)=='table' and value.rows[job.edge-chunk.first+1]
    if type(row)~='table' then return 'invalid','invalid_geometry_reference' end
    return BeginPoints(job,row.geometry)
end
local function Compatible(point,center)
    for _,key in ipairs({'space','floor','phase'}) do
        if point[key]~=nil and center[key]~=nil and point[key]~=center[key] then return false end
    end
    return true
end
local function Domain(job,anchor,center)
    if not job.domain then job.domain={minZ=anchor.bounds.minZ,maxZ=anchor.bounds.maxZ,space=center.space,floor=center.floor};return true end
    local domain=job.domain
    for _,key in ipairs({'space','floor'}) do
        if domain[key]~=nil and center[key]~=nil and domain[key]~=center[key] then return false end
    end
    domain.minZ,domain.maxZ=math.max(domain.minZ,anchor.bounds.minZ),math.min(domain.maxZ,anchor.bounds.maxZ)
    return domain.minZ<=domain.maxZ
end
local function Anchor(job,anchor,slot)
    local center=anchor.centers and anchor.centers[job.direction]
    if not center or not Inside(job.point,anchor.bounds,false) or not Compatible(job.point,center) then return end
    local p=Copy(center);p.x,p.y,p.z=job.point.x,job.point.y,job.point.z or center.z
    if not Inside(p,anchor.bounds,true) then return end
    if not Domain(job,anchor,center) then return 'unknown','anchor_ambiguous' end
    if #job.connectors>=128 then return 'budget_exceeded','connector_limit' end
    local id=job.sector..':anchor-'..job.record..'-'..slot..'-'..job.direction..':'..
        string.format('%.17g:%.17g:%.17g',p.x,p.y,p.z)
    job.pending={node=job.sector..':terrain:'..anchor.node,access='available',edgeId=id,requirements=anchor.requirements}
    job.geometry=job.reader:Geometry(id);job.phase='connector_geometry'
end
local function ResolveUnit(job)
    if job.phase=='connector_geometry' then
        local status,reason=GeometryUnit(job.geometry)
        if status=='running' or status==nil then return end
        if status~='complete' then return status,reason end
        local length=job.geometry.length or 0
        job.pending.seconds=length/job.reader.data.walkSpeed
        job.pending.movement={mode='walk',distance=length,canMount='unavailable'}
        job.connectors[#job.connectors+1]=job.pending
        job.pending,job.geometry=nil,nil;job.phase='anchor_rows';return
    end
    if job.phase=='anchor_rows' then
        local anchor=job.value.anchors[job.cursor]
        if not anchor then job.value,job.record=nil,nil;job.phase='tree';return end
        local slot=job.cursor;job.cursor=job.cursor+1
        return Anchor(job,anchor,slot)
    end
    if job.phase=='tree' then
        if not job.record then
            job.record=table.remove(job.stack)
            if not job.record then job.phase='directory';return end
        end
        local value,status,reason=Child(job,job.record)
        if not value then return status,reason end
        if not Inside(job.point,value.bounds,false) then job.record=nil;return end
        if value.kind=='terrain-branch' then
            if type(value.children)~='table' or #value.children~=2 or #job.stack>64 then return 'invalid','invalid_anchor_tree' end
            job.stack[#job.stack+1]=value.children[1];job.stack[#job.stack+1]=value.children[2]
            job.record=nil;return
        end
        if value.kind~='terrain-anchors' or type(value.anchors)~='table' or #value.anchors>8 then return 'invalid','invalid_anchor_page' end
        job.value,job.cursor,job.phase=value,1,'anchor_rows';return
    end
    if job.phase=='metadata' then
        local value,status,reason=Child(job,nil,true)
        if not value then return status,reason end
        local terrain=value.catalog.terrain
        if type(terrain)~='table' or not Integer(terrain.anchors,0,job.reader.data.packs[job.reader.data.index[job.sector].pack].recordCount) then
            return 'invalid','invalid_anchor_root'
        end
        if terrain.anchors>0 then job.stack[1]=terrain.anchors end
        job.phase='tree';return
    end
    local sector,item=next(job.reader.data.index,job.directoryCursor)
    job.directoryCursor=sector
    if not sector then
        if #job.connectors==0 then return 'unknown','anchor_unavailable' end
        return 'complete'
    end
    job.directories=(job.directories or 0)+1
    if job.directories>1024 then return 'budget_exceeded','terrain_directory_limit' end
    if type(item)~='table' then return 'invalid','invalid_terrain_directory' end
    if item.world==job.point.world and Inside(job.point,item.bounds,false) then job.sector,job.phase=sector,'metadata' end
end
function Job:Step(operations,milliseconds)
    if self.result then return self.result end
    operations,milliseconds=operations or 64,milliseconds or B.sliceMs
    if not Integer(operations,1,4096) or not Finite(milliseconds) or milliseconds<=0 then return Stop(self,'invalid','invalid_step_budget') end
    local reader=self.reader
    local start=Sample(reader.options,'profileClock')
    if not Finite(start) or not Finite(self.started) then return Stop(self,'unknown','clock_unavailable') end
    local previous=start
    for _=1,operations do
        if self.revision~=reader.revision then return Stop(self,'unknown','source_stale') end
        local wall=Sample(reader.options,'clock')
        if not Finite(wall) or wall<self.started then return Stop(self,'unknown','clock_unavailable') end
        if (wall-self.started)*1000>=B.elapsedMs or self.cpuMs>=B.cpuMs then return Stop(self,'budget_exceeded','terrain_budget') end
        local status,reason
        if self.kind=='resolve' then status,reason=ResolveUnit(self) else status,reason=GeometryUnit(self) end
        self.diagnostics.operations=self.diagnostics.operations+1
        local now=Sample(reader.options,'profileClock')
        if not Finite(now) or now<previous then return Stop(self,'unknown','clock_unavailable') end
        self.cpuMs=self.cpuMs+now-previous;self.diagnostics.cpuMs=self.cpuMs;previous=now
        if status and status~='running' then return Stop(self,status,reason) end
        if now-start>=math.min(milliseconds,B.sliceMs) then break end
    end
    return {status='running',diagnostics=self.diagnostics}
end
ns.NavigationV2DeclaredTerrain=Terrain
return Terrain
