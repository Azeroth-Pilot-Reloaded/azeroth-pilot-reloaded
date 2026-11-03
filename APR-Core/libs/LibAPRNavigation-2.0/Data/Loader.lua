-- Pure Lua 5.1 sector loader. Native decoding is injected; no events or timers.
local _, ns = ...
local Terrain, Loader, Job = {}, {}, {}
Loader.__index, Job.__index = Loader, Job
local MAX_BLOCKS, MAX_NODES, MAX_EDGES = 32, 128, 768
local MAX_RAW, MAX_PAYLOAD = 16384, 22000
local BUDGETS=ns.NavigationV2Graph and ns.NavigationV2Graph.Budgets

local function Integer(v, lo, hi)
    return type(v)=='number' and v==v and v>=lo and v<=hi and v%1==0
end

local function Array(t, maximum)
    if type(t)~='table' then return nil end
    local count = 0
    for k in pairs(t) do
        count=count+1
        if count>maximum or not Integer(k,1,maximum) then return nil end
    end
    if count~=#t then return nil end
    return count
end

local function Clock(options,wall)
    local ok, time = pcall(wall and options.clock or options.profileClock)
    if ok and type(time)=='number' and time==time and time>=0 and time<math.huge then return time end
end

function Terrain.New(catalog, options)
    if type(catalog)~='table' or type(options)~='table' then return nil,'invalid_loader' end
    local copy = {}
    for _, key in ipairs({'profileClock','decodeBase64','inflate','deserialize'}) do
        if type(options[key])~='function' then return nil,'decoder_unavailable' end
        copy[key]=options[key]
    end
    if options.clock~=nil and type(options.clock)~='function' then return nil,'invalid_clocks' end
    copy.clock=options.clock or function()return options.profileClock()/1000 end
    local loader=setmetatable({catalog=catalog,options=copy},Loader)
    if rawget(catalog,'format')=='apr-flat-pages-1' then
        if not ns.NavigationV2Pages then return nil,'pages_unavailable' end
        local reason
        loader.pages,reason=ns.NavigationV2Pages.New(catalog,copy)
        if not loader.pages then return nil,reason end
    end
    return loader
end

-- API signatures verified in Forever and Retail EncodingUtilDocumentation.
-- Call this only for trusted packaged data: native decompression has no size argument.
function Terrain.ClientOptions(api, enums, profileClock)
    if type(api)~='table' or type(enums)~='table' or type(enums.CompressionMethod)~='table'
        or type(enums.Base64Variant)~='table' then return nil,'decoder_unavailable' end
    if type(api.DecodeBase64)~='function' or type(api.DecompressString)~='function'
        or type(api.DeserializeCBOR)~='function' then return nil,'decoder_unavailable' end
    return {profileClock=profileClock,
        decodeBase64=function(s) return api.DecodeBase64(s,enums.Base64Variant.Standard) end,
        inflate=function(s) return api.DecompressString(s,enums.CompressionMethod.Deflate) end,
        deserialize=api.DeserializeCBOR}
end

local function Finish(job, status, reason)
    if job.metadataJob then job.metadataJob:Cancel();job.metadataJob=nil end
    if job.flatRead then job.flatRead:Cancel();job.flatRead=nil end
    job.result={status=status,reason=reason,diagnostics=job.diagnostics}
    if status=='complete' then job.result.graph,job.result.positions=job.graph,job.positions end
    job.graph,job.positions,job.decoded,job.bytes,job.sector=nil,nil,nil,nil,nil
    return job.result
end

function Loader:Load(id, qualified)
    local cached=self.pages and self.pages:Peek(id)
    local sector=cached and cached.catalog or type(id)=='string' and self.catalog[id]
    local job=setmetatable({loader=self,sector=sector,block=1,phase='envelope',cursor=1,
        prefix=qualified == true and type(id)=='string' and (id..':') or '',
        graph={complete=false,nodes={},edges={}},positions={},
        started=Clock(self.options,true),cpuMs=0,
        diagnostics={blocks=0,nodes=0,edges=0,decodeMs=0,operations=0}},Job)
    if self.pages and not cached then
        job.metadataJob=self.pages:LoadMetadata(id);job.phase='metadata'
    elseif not sector then Finish(job,'unknown','sector_absent') end
    return job
end

function Job:Cancel()
    return self.result or Finish(self,'cancelled','cancelled')
end

local function Envelope(job)
    local sector=job.sector
    if type(sector)~='table' or type(sector.complete)~='boolean' then return 'invalid','invalid_sector' end
    local count=job.loader.pages and sector.blocks.count or Array(sector.blocks,MAX_BLOCKS)
    if not Integer(count,0,MAX_BLOCKS) then return 'invalid','block_over_limit' end
    if not count or count==0 then return 'unknown','blocks_absent' end
    job.graph.complete=sector.complete
    job.blockCount,job.phase=count,'block'
end

local function Block(job)
    if job.block>job.blockCount then return 'complete' end
    local b
    if job.loader.pages then
        if not job.flatRead then
            job.flatRead=job.loader.pages:Read(job.sector.blocks.first+job.block-1);return
        end
        local status,reason=job.flatRead:Advance()
        if status=='ready' then
            if job.flatRead.kind~=2 then return 'invalid','invalid_flat_geometry' end
            b=job.flatRead.value;job.flatRead=nil
        elseif status then return status,reason else return end
    else b=job.sector.blocks[job.block] end
    if type(b)~='table' or not Integer(b.first,1,MAX_BLOCKS*MAX_NODES)
        or not Integer(b.nodes,1,MAX_NODES) or not Integer(b.edges,0,MAX_EDGES)
        or not Integer(b.rawBytes,1,MAX_RAW) or type(b.payload)~='string' or #b.payload>MAX_PAYLOAD then
        return 'invalid','block_over_limit'
    end
    if b.first~=#job.graph.nodes+1 then return 'invalid','block_sequence' end
    job.metadata,job.bytes,job.phase=b,b.payload,'base64'
end

local function Decode(job, operation, nextPhase)
    local options=job.loader.options
    local started=Clock(options)
    if job.result then return end
    if not started then return 'unknown','clock_unavailable' end
    local ok,value=pcall(options[operation],job.bytes)
    if job.result then return end
    local stopped=Clock(options)
    if job.result then return end
    if not stopped or stopped<started then return 'unknown','clock_unavailable' end
    job.diagnostics.decodeMs=job.diagnostics.decodeMs+stopped-started
    if not ok or value==nil then return 'unknown','decode_failed' end
    if operation=='deserialize' then
        job.decoded,job.bytes=value,nil
    else
        if type(value)~='string' or #value>MAX_RAW then return 'invalid','decoded_over_limit' end
        if operation=='inflate' and #value~=job.metadata.rawBytes then return 'invalid','decoded_size_mismatch' end
        job.bytes=value
    end
    job.phase=nextPhase
end

local function Validate(job)
    local data,b=job.decoded,job.metadata
    if Array(data,4)~=4 or data[1]~=2 or data[2]~=b.first
        or Array(data[3],MAX_NODES)~=b.nodes or Array(data[4],MAX_EDGES)~=b.edges then
        return 'invalid','invalid_block'
    end
    job.phase,job.cursor='nodes',1
end

local function Node(job)
    local point=job.decoded[3][job.cursor]
    if point==nil then job.phase,job.cursor='edges',1;return end
    if Array(point,3)~=3 then return 'invalid','invalid_position' end
    for i=1,3 do if not Integer(point[i],-2147483647,2147483647) then return 'invalid','invalid_position' end end
    local id=job.prefix..'terrain:'..(#job.graph.nodes+1)
    job.graph.nodes[#job.graph.nodes+1]=id
    job.positions[id]={point[1]/1000,point[2]/1000,point[3]/1000}
    job.cursor=job.cursor+1
    job.diagnostics.nodes=job.diagnostics.nodes+1
end

local function Edge(job)
    local edge=job.decoded[4][job.cursor]
    if edge==nil then
        job.decoded,job.metadata=nil,nil
        job.block,job.phase=job.block+1,'block'
        job.diagnostics.blocks=job.diagnostics.blocks+1
        return
    end
    if Array(edge,3)~=3 or not Integer(edge[1],1,MAX_BLOCKS*MAX_NODES)
        or not Integer(edge[2],1,MAX_BLOCKS*MAX_NODES) or not Integer(edge[3],0,4294967295) then
        return 'invalid','invalid_edge'
    end
    -- References to later blocks are checked in the final bounded pass.
    local edges=job.graph.edges
    edges[#edges+1]={id=job.prefix..'walk:'..(#edges+1),from=job.prefix..'terrain:'..edge[1],
        to=job.prefix..'terrain:'..edge[2],seconds=edge[3]/1000}
    job.cursor=job.cursor+1
    job.diagnostics.edges=job.diagnostics.edges+1
end

local function References(job)
    local edge=job.graph.edges[job.cursor]
    if not edge then return 'complete' end
    if not job.positions[edge.from] or not job.positions[edge.to] then return 'invalid','invalid_edge' end
    job.cursor=job.cursor+1
end

local function Advance(job)
    local phase=job.phase
    if phase=='metadata' then
        local status,reason=job.metadataJob:Advance()
        if status=='ready' then
            job.sector=job.metadataJob.value.catalog;job.metadataJob=nil;job.phase='envelope'
        elseif status then return status,reason end
        return
    end
    if phase=='envelope' then return Envelope(job) end
    if phase=='block' then
        local status,reason=Block(job)
        if status=='complete' then job.phase,job.cursor='references',1;return end
        return status,reason
    end
    if phase=='base64' then return Decode(job,'decodeBase64','inflate') end
    if phase=='inflate' then return Decode(job,'inflate','deserialize') end
    if phase=='deserialize' then return Decode(job,'deserialize','validate') end
    if phase=='validate' then return Validate(job) end
    if phase=='nodes' then return Node(job) end
    if phase=='edges' then return Edge(job) end
    return References(job)
end

function Job:Step(maxOperations)
    if self.result then return self.result end
    maxOperations=maxOperations or 64
    if not Integer(maxOperations,1,4096) then return nil,'invalid_step_budget' end
    local started=Clock(self.loader.options)
    local sliceStarted=started
    if self.result then return self.result end
    if not started then return Finish(self,'unknown','clock_unavailable') end
    if not self.started then return Finish(self,'unknown','clock_unavailable') end
    for _=1,maxOperations do
        local wall=Clock(self.loader.options,true)
        if self.result then return self.result end
        if not wall or wall<self.started then return Finish(self,'unknown','clock_unavailable') end
        if BUDGETS and (wall-self.started)*1000>=BUDGETS.elapsedMs then return Finish(self,'budget_exceeded','elapsed_budget') end
        if BUDGETS and self.cpuMs>=BUDGETS.cpuMs then return Finish(self,'budget_exceeded','cpu_budget') end
        local status,reason=Advance(self)
        if self.result then return self.result end
        self.diagnostics.operations=self.diagnostics.operations+1
        local now=Clock(self.loader.options)
        if self.result then return self.result end
        if not now or now<started then return Finish(self,'unknown','clock_unavailable') end
        self.cpuMs=self.cpuMs+now-started
        self.diagnostics.cpuMs=self.cpuMs
        if BUDGETS and self.cpuMs>=BUDGETS.cpuMs then return Finish(self,'budget_exceeded','cpu_budget') end
        if status then return Finish(self,status,reason) end
        if now-sliceStarted>=(BUDGETS and BUDGETS.sliceMs or 1) then break end
        started=now
    end
    return {status='running',diagnostics=self.diagnostics}
end

-- A partitioned planner already owns all three clocks/budgets. Avoid sampling
-- a second standalone budget for every decoded node and edge in that job.
function Job:Advance()
    if self.result then return self.result end
    local status,reason=Advance(self)
    if self.result then return self.result end
    self.diagnostics.operations=self.diagnostics.operations+1
    if status then return Finish(self,status,reason) end
    return {status='running',diagnostics=self.diagnostics}
end

ns.NavigationV2Terrain=Terrain
return Terrain
