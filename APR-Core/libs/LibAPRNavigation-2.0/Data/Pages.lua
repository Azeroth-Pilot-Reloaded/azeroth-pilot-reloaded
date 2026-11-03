-- Trusted packaged flat pages. All decoding is explicit work owned by a job.
local _, ns = ...
local Pages, Read, Metadata = {}, {}, {}
Pages.__index,Read.__index,Metadata.__index=Pages,Read,Metadata
local L={encodedBytes=16777216,indexBytes=4194304,bootstrapBytes=65536,sectors=1024,
    rawBytes=16384,payloadBytes=22000,sectorRawBytes=65536,metadataEntries=8,
    metadataBytes=524288,fields=4096,depth=16,links=256,linksPerChunk=16,names=4096,recordBytes=19}
Pages.Limits=L
L.packedBytes=math.floor(L.payloadBytes/4)*3

local function Integer(v,lo,hi)
    return type(v)=='number' and v==v and v%1==0 and v>=lo and v<=hi
end

local function Slug(v)
    return type(v)=='string' and #v<=256 and v:match('^[a-zA-Z][a-zA-Z0-9_%-]*$')
end

function Pages.New(pack,options)
    if type(pack)~='table' or pack.format~='apr-flat-pages-1' then return nil,'invalid_flat_pages' end
    if type(pack.bootstrap)~='table' or not Integer(pack.recordCount,0,math.floor(L.indexBytes/L.recordBytes))
        or type(pack.index)~='string' or #pack.index~=math.ceil(pack.recordCount*L.recordBytes/3)*4
        or type(pack.payloads)~='string' or type(pack.extras)~='string'
        or type(pack.attributes)~='string' or #pack.attributes>L.bootstrapBytes
        or #pack.index+#pack.payloads+#pack.extras+#pack.attributes>L.encodedBytes then return nil,'flat_storage_limit' end
    for _,key in ipairs({'decodeBase64','inflate','deserialize'}) do
        if type(options)~='table' or type(options[key])~='function' then return nil,'decoder_unavailable' end
    end
    return setmetatable({pack=pack,options=options,bootstrap=pack.bootstrap,cache={},order={},
        bootstrapCount=0,bootstrapBytes=0,stats={resident=0,residentRawBytes=0,loads=0,
        hits=0,evictions=0,indexReads=0,nativeDecodes=0,operations=0,bootstrapUnits=0}},Pages)
end

local function Names(pages)
    local atlas=pages.pack.routing
    if not atlas then pages.bootstrapReady=true;return end
    if type(atlas)~='table' or type(atlas.names)~='table' or type(atlas.ordinals)~='table' then
        return 'invalid','invalid_flat_bootstrap'
    end
    local key,name=next(atlas.names,pages.namesCursor)
    if key==nil then
        if (pages.namesCount or 0)~=(pages.namesMaximum or 0) then return 'invalid','invalid_flat_bootstrap' end
        pages.bootstrapReady=true;return
    end
    pages.namesCount=(pages.namesCount or 0)+1
    if not Integer(key,1,L.names) or not Slug(name) or atlas.ordinals[name]~=key
        or pages.namesCount>L.names then return 'invalid','invalid_flat_bootstrap' end
    pages.namesMaximum=math.max(pages.namesMaximum or 0,key)
    pages.bootstrapBytes=pages.bootstrapBytes+#name+8
    if pages.bootstrapBytes>L.bootstrapBytes then return 'invalid','flat_bootstrap_limit' end
    pages.namesCursor=key;pages.stats.bootstrapUnits=pages.stats.bootstrapUnits+1
end

function Pages:Lookup(id)
    local b=self.bootstrap[id]
    if b==nil then return nil,'unknown','sector_absent' end
    if not Slug(id) or type(b)~='table' or not Integer(b.nodes,1,4096)
        or type(b.complete)~='boolean' or not Integer(b.metadata,1,self.pack.recordCount) then
        return nil,'invalid','invalid_flat_bootstrap'
    end
    return b
end

local function Bootstrap(pages)
    if pages.bootstrapFailure then return 'invalid',pages.bootstrapFailure end
    if pages.bootstrapReady then return 'ready' end
    local id=next(pages.bootstrap,pages.bootstrapCursor)
    if id==nil then
        local status,reason=Names(pages)
        if status then pages.bootstrapFailure=reason end
        return status,reason
    end
    local value,_,reason=pages:Lookup(id)
    pages.bootstrapCount=pages.bootstrapCount+1
    pages.bootstrapBytes=pages.bootstrapBytes+(type(id)=='string' and #id or 0)+24
    if not value or pages.bootstrapCount>L.sectors or pages.bootstrapBytes>L.bootstrapBytes then
        pages.bootstrapFailure=reason or 'flat_bootstrap_limit';return 'invalid',pages.bootstrapFailure
    end
    local atlas=pages.pack.routing
    if atlas and (type(atlas.ordinals)~='table' or type(atlas.names)~='table'
        or not Integer(atlas.ordinals[id],1,L.names) or atlas.names[atlas.ordinals[id]]~=id) then
        pages.bootstrapFailure='invalid_flat_bootstrap';return 'invalid',pages.bootstrapFailure
    end
    pages.bootstrapCursor=id;pages.stats.bootstrapUnits=pages.stats.bootstrapUnits+1
end

local function LinkArray(value)
    local count=0
    for key,link in pairs(value) do
        count=count+1
        if not Integer(key,1,L.linksPerChunk) or type(link)~='table' then return nil end
    end
    return count==#value
end

local function Stop(job,status,reason)
    job.status,job.reason=status,reason
    job.bytes,job.value,job.envelope,job.child,job.validation=nil,nil,nil,nil,nil
    return status,reason
end

function Read:Cancel() return Stop(self,'cancelled','cancelled') end
function Metadata:Cancel()
    if self.child then self.child:Cancel() end
    return Stop(self,'cancelled','cancelled')
end

local function Native(job,operation,bytes)
    local pages=job.pages
    local ok,value=pcall(pages.options[operation],bytes)
    pages.stats.nativeDecodes=pages.stats.nativeDecodes+1
    if job.status=='cancelled' then return nil,'cancelled','cancelled' end
    if not ok or value==nil then return nil,'unknown','decode_failed' end
    if operation~='deserialize' and type(value)~='string' then return nil,'invalid','invalid_flat_decode' end
    return value
end

local function Number(bytes,offset,count)
    local n=0
    for i=offset,offset+count-1 do n=n*256+bytes:byte(i) end
    return n
end

local function Index(job)
    local offset=(job.ordinal-1)*L.recordBytes
    local first=math.floor(offset/3)*4+1
    local last=math.ceil((offset+L.recordBytes)/3)*4
    local bytes,status,reason=Native(job,'decodeBase64',job.pages.pack.index:sub(first,last))
    if bytes==nil then return status,reason end
    if type(bytes)~='string' or #bytes>21 or #bytes<offset%3+L.recordBytes then return 'invalid','invalid_flat_index' end
    bytes=bytes:sub(offset%3+1,offset%3+L.recordBytes)
    local start,count,raw=Number(bytes,1,2),Number(bytes,3,2),Number(bytes,5,2)
    local p,size,e,extra,kind=Number(bytes,7,4),Number(bytes,11,2),Number(bytes,13,4),Number(bytes,17,2),bytes:byte(19)
    local pack=job.pages.pack
    if not Integer(start,1,4096) or not Integer(count,1,128) or not Integer(raw,1,L.rawBytes)
        or size<1 or size>L.payloadBytes or p+size>#pack.payloads or extra>L.payloadBytes
        or e+extra>#pack.extras or (kind~=1 and kind~=2 and kind~=3) then return 'invalid','invalid_flat_index' end
    job.kind=kind
    job.envelope={first=start,rawBytes=raw,payload=pack.payloads:sub(p+1,p+size)}
    job.envelope[kind==2 and 'nodes' or 'rows']=count
    job.bytes=extra>0 and pack.extras:sub(e+1,e+extra) or nil
    job.phase=job.bytes and 'extras_base64' or 'envelope'
    job.pages.stats.indexReads=job.pages.stats.indexReads+1
end

function Pages:Read(ordinal,decode)
    local job=setmetatable({pages=self,ordinal=ordinal,decode=decode,phase='index'},Read)
    if not Integer(ordinal,1,self.pack.recordCount) then Stop(job,'invalid','invalid_flat_ordinal') end
    return job
end

function Read:Advance()
    if self.status then return self.status,self.reason end
    self.pages.stats.operations=self.pages.stats.operations+1
    if self.phase=='index' then
        local status,reason=Index(self)
        if status then return Stop(self,status,reason) end
        return
    end
    if self.phase=='envelope' then
        if not self.decode then self.value,self.status=self.envelope,'ready';return 'ready' end
        if self.kind~=3 then return Stop(self,'invalid','invalid_flat_metadata') end
        self.bytes,self.phase=self.envelope.payload,'base64';return
    end
    local operation=self.phase=='extras_base64' and 'decodeBase64'
        or self.phase=='extras_decode' and 'deserialize' or self.phase=='base64' and 'decodeBase64'
        or self.phase=='inflate' and 'inflate' or 'deserialize'
    local value,status,reason=Native(self,operation,self.bytes)
    if value==nil then return Stop(self,status,reason) end
    if operation=='deserialize' then
        if type(value)~='table' then return Stop(self,'invalid','invalid_flat_metadata') end
        if self.phase=='extras_decode' then
            for key,item in pairs(self.envelope) do
                if value[key]~=nil then return Stop(self,'invalid','invalid_flat_extras') end
                value[key]=item
            end
            self.envelope,self.bytes,self.phase=value,nil,'envelope'
        else self.value,self.bytes,self.status=value,nil,'ready';return 'ready' end
    else
        local maximum=operation=='decodeBase64' and L.packedBytes or L.rawBytes
        if type(value)~='string' or #value>maximum then return Stop(self,'invalid','decoded_over_limit') end
        if operation=='inflate' and #value~=self.envelope.rawBytes then return Stop(self,'invalid','decoded_size_mismatch') end
        self.bytes=value
        self.phase=self.phase=='extras_base64' and 'extras_decode' or operation=='inflate' and 'deserialize' or 'inflate'
    end
end

local function Touch(pages,id)
    for i,value in ipairs(pages.order) do if value==id then table.remove(pages.order,i);break end end
    pages.order[#pages.order+1]=id
end

function Pages:Peek(id)
    local entry=self.cache[id]
    return entry and entry.value
end

local function Store(pages,job)
    if pages.cache[job.id] then job.value=pages.cache[job.id].value;Touch(pages,job.id);return end
    while #pages.order>=L.metadataEntries or pages.stats.residentRawBytes+job.rawBytes>L.metadataBytes do
        local id=table.remove(pages.order,1)
        local old=pages.cache[id]
        pages.stats.residentRawBytes=pages.stats.residentRawBytes-old.rawBytes
        pages.stats.resident=pages.stats.resident-1;pages.stats.evictions=pages.stats.evictions+1
        pages.cache[id]=nil
    end
    pages.cache[job.id]={value=job.value,rawBytes=job.rawBytes}
    Touch(pages,job.id)
    pages.stats.residentRawBytes=pages.stats.residentRawBytes+job.rawBytes
    pages.stats.resident=pages.stats.resident+1
end

local function Span(pages,span)
    return type(span)=='table' and Integer(span.count,0,256) and Integer(span.first,1,pages.pack.recordCount+1)
        and span.first+span.count-1<=pages.pack.recordCount
end

local function Validate(job)
    local stack=job.validation
    local frame=stack[#stack]
    if not frame then return 'ready' end
    local key,value=next(frame.value,frame.cursor)
    if key==nil then stack[#stack]=nil;return end
    frame.cursor=key;job.fields=job.fields+1
    if job.fields>L.fields or (type(key)~='string' and not Integer(key,1,L.fields)) then return 'invalid','flat_metadata_limit' end
    if type(value)=='table' then
        if #stack>=L.depth then return 'invalid','flat_metadata_limit' end
        stack[#stack+1]={value=value}
    elseif type(value)~='string' and type(value)~='boolean' and not ns.NavigationV2Graph.Finite(value) then
        return 'invalid','invalid_flat_metadata'
    end
end

function Pages:LoadMetadata(id)
    local b,status,reason=self:Lookup(id)
    local job=setmetatable({pages=self,id=id,bootstrap=b,rawBytes=0,fields=0,phase='bootstrap'},Metadata)
    if not b then Stop(job,status,reason) end
    return job
end

local function Header(job)
    local h,b=job.child.value,job.bootstrap
    if type(h.index)~='table' or type(h.catalog)~='table' or type(h.index.name)~='string'
        or not h.index.name:match('%S') or h.index.nodes~=b.nodes or h.index.complete~=b.complete
        or h.catalog.complete~=b.complete or not Span(job.pages,h.catalog.blocks)
        or not Span(job.pages,h.index.links) then return 'invalid','invalid_flat_metadata' end
    job.value,job.links,job.linkPage=h,h.index.links,0
    h.index.links={};job.child=nil;job.phase='links'
end

function Metadata:Advance()
    if self.status then return self.status,self.reason end
    local pages=self.pages
    pages.stats.operations=pages.stats.operations+1
    if self.phase=='bootstrap' then
        local status,reason=Bootstrap(pages)
        if status=='invalid' then return Stop(self,status,reason) end
        if status=='ready' then self.child=pages:Read(self.bootstrap.metadata,true);self.phase='header' end
        return
    end
    if self.phase=='validate' then
        local status,reason=Validate(self)
        if status=='ready' then Store(pages,self);self.status='ready';return 'ready' end
        if status then return Stop(self,status,reason) end
        return
    end
    if self.phase=='links' and not self.child then
        if self.linkPage==self.links.count then self.phase='validate';self.validation={{value=self.value}};return end
        self.child=pages:Read(self.links.first+self.linkPage,true);self.linkPage=self.linkPage+1
    end
    if self.phase=='append' then
        local value=self.child.value[self.linkCursor]
        if value==nil then self.child=nil;self.phase='links';return end
        if #self.value.index.links>=L.links then return Stop(self,'invalid','flat_metadata_limit') end
        self.value.index.links[#self.value.index.links+1]=value;self.linkCursor=self.linkCursor+1;return
    end
    local status,reason=self.child:Advance()
    if self.status=='cancelled' then return self.status,self.reason end
    if status=='ready' then
        self.rawBytes=self.rawBytes+self.child.envelope.rawBytes
        if self.rawBytes>L.sectorRawBytes then return Stop(self,'invalid','flat_metadata_limit') end
        if self.phase=='header' then
            status,reason=Header(self)
            if status then return Stop(self,status,reason) end
        else
            if not LinkArray(self.child.value) then return Stop(self,'invalid','invalid_flat_metadata') end
            self.phase,self.linkCursor='append',1
        end
    elseif status then return Stop(self,status,reason) end
end

function Pages:Ensure(search,id)
    local value=self:Peek(id)
    local state=search.loading
    if value then
        if state and state.kind=='metadata' then state.job:Cancel();search.loading=nil end
        self.stats.hits=self.stats.hits+1;Touch(self,id);return value
    end
    if search.metadataFailures and search.metadataFailures[id] then return nil,'unknown',search.metadataFailures[id] end
    if state and state.sector==id and state.sectorMetadata then return state.sectorMetadata end
    if not state then
        search.loading={kind='metadata',sector=id,job=self:LoadMetadata(id)}
        self.stats.loads=self.stats.loads+1;return nil,'running'
    end
    if state.kind~='metadata' or state.sector~=id then return nil,'invalid','flat_loading_conflict' end
    local status,reason=state.job:Advance()
    if status=='ready' then search.loading=nil;return state.job.value end
    if status then
        search.loading=nil
        if status=='unknown' then search.metadataFailures=search.metadataFailures or {};search.metadataFailures[id]=reason end
        return nil,status,reason
    end
    return nil,'running'
end

Pages.ValidSpan=Span

ns.NavigationV2Pages=Pages
return Pages
