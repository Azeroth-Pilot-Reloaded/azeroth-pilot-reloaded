-- Trusted declared-roads pages. Existing native codec callbacks are injected.
local _,ns=...
local Pages,Reader,Job={},{},{}
Reader.__index,Job.__index=Reader,Job
local Yield=coroutine.yield
local DEFAULT=ns.NavigationV2Graph and ns.NavigationV2Graph.Budgets or {sliceMs=1,cpuMs=100,elapsedMs=5000}
local function Finite(n)return type(n)=='number' and n==n and n>-math.huge and n<math.huge end
local function Integer(n,a,b)return Finite(n) and n%1==0 and n>=a and n<=b end
local function Fail(status,reason)error({status=status,reason=reason},0)end
local function Need(ok,reason)if not ok then Fail('invalid',reason)end end
local function Clock(fn)local ok,n=pcall(fn);if ok and Finite(n) and n>=0 then return n end end
local function Finish(self,result)
    self.result,self.thread=result,nil
    if self.child then self.child:Cancel();self.child=nil end
    return self:GetState()
end
function Pages.NewJob(options,worker)
    return setmetatable({options=options,thread=coroutine.create(worker),operations=0,cpuMs=0,elapsedMs=0},Job)
end
function Job:GetState()
    local state={}
    for k,v in pairs(self.result or {status='running'})do state[k]=v end
    state.operations,state.cpuMs,state.elapsedMs=self.operations,self.cpuMs,self.elapsedMs
    return state
end
function Job:Advance()
    if self.result then return self:GetState() end
    local ok,value=coroutine.resume(self.thread)
    self.operations=self.operations+1
    if not ok then
        local result=type(value)=='table' and value or {status='invalid',reason='road_worker_failed'}
        return Finish(self,result)
    end
    if coroutine.status(self.thread)=='dead' then
        Need(type(value)=='table' and type(value.status)=='string','invalid_job_result')
        return Finish(self,value)
    end
    return self:GetState()
end
function Job:Step(operations,milliseconds)
    if self.result then return self:GetState() end
    if operations==nil then operations=64 end
    if milliseconds==nil then milliseconds=self.options.sliceMs or DEFAULT.sliceMs end
    if not Integer(operations,1,4096) or not Finite(milliseconds) or milliseconds<=0 then
        return Finish(self,{status='invalid',reason='invalid_step_budget'})
    end
    milliseconds=math.min(milliseconds,self.options.sliceMs or DEFAULT.sliceMs)
    local wall,cpu=Clock(self.options.clock),Clock(self.options.profileClock)
    if self.result then return self:GetState() end
    if not wall or not cpu then return Finish(self,{status='unknown',reason='clock_unavailable'})end
    if self.lastWall and (wall<self.lastWall or cpu<self.lastCPU) then
        return Finish(self,{status='unknown',reason='clock_regressed'})
    end
    self.started=self.started or wall
    local startCPU,previous=cpu,cpu
    for _=1,operations do
        if (wall-self.started)*1000>=(self.options.elapsedMs or DEFAULT.elapsedMs) then
            return Finish(self,{status='budget_exceeded',reason='elapsed_budget'})
        end
        local state=self:Advance()
        local nextWall,nextCPU=Clock(self.options.clock),Clock(self.options.profileClock)
        if self.result and self.result.status=='cancelled' then return self:GetState() end
        if not nextWall or not nextCPU then return Finish(self,{status='unknown',reason='clock_unavailable'}) end
        if nextWall<wall or nextCPU<previous then return Finish(self,{status='unknown',reason='clock_regressed'})end
        self.cpuMs=self.cpuMs+nextCPU-previous;previous=nextCPU;wall=nextWall
        self.elapsedMs=(wall-self.started)*1000;self.lastWall,self.lastCPU=wall,nextCPU
        if self.cpuMs>=(self.options.cpuMs or DEFAULT.cpuMs) then return Finish(self,{status='budget_exceeded',reason='cpu_budget'})end
        if self.elapsedMs>=(self.options.elapsedMs or DEFAULT.elapsedMs) then return Finish(self,{status='budget_exceeded',reason='elapsed_budget'})end
        if state.status~='running' or nextCPU-startCPU>=milliseconds then break end
    end
    return self:GetState()
end
function Job:Cancel()
    if not self.result then return Finish(self,{status='cancelled',reason='cancelled'})end
    return self:GetState()
end
function Pages.Await(parent,child)
    Need(type(child)=='table' and type(child.Advance)=='function','invalid_subjob')
    parent.child=child
    while true do
        local state=child:Advance()
        Yield()
        if state.status~='running' then
            parent.child=nil
            if state.status~='complete' and state.status~='ready' then Fail(state.status,state.reason)end
            return state
        end
    end
end
Pages.Yield,Pages.Fail,Pages.Need,Pages.Finite,Pages.Integer=Yield,Fail,Need,Finite,Integer

local function Tree(value,budget,depth)
    Need(depth<=16,'page_depth')
    if type(value)=='table' then
        Need(getmetatable(value)==nil,'page_metatable')
        for key,item in pairs(value)do
            budget[1]=budget[1]+1;Need(budget[1]<=4096,'page_fields')
            Need(type(key)=='string' or Integer(key,1,4096),'page_key')
            Tree(item,budget,depth+1);Yield()
        end
    else
        Need(type(value)=='string' or type(value)=='boolean' or Finite(value),'page_value')
    end
end
local function Record(store,key)
    Need(type(store)=='table' and store.format=='apr-road-store-1' and store.recordBytes==54
        and Integer(store.records,0,math.floor(4194304/54)) and type(store.index)=='string'
        and #store.index==store.records*54 and type(store.payloads)=='string'
        and #store.payloads<=16777216,'invalid_road_store')
    local lo,hi=0,store.records-1
    while lo<=hi do
        local mid=math.floor((lo+hi)/2);local record=store.index:sub(mid*54+1,(mid+1)*54)
        local found=record:sub(1,32):gsub(' +$','')
        if found<key then lo=mid+1 elseif found>key then hi=mid-1
        else
            local offset,size,raw=tonumber(record:sub(33,42)),tonumber(record:sub(43,48)),tonumber(record:sub(49,54))
            Need(Integer(offset,0,16777216) and Integer(size,1,22000) and Integer(raw,1,16384),'invalid_page_record')
            if offset+size>#store.payloads then Fail('unknown','page_missing')end
            return store.payloads:sub(offset+1,offset+size),raw
        end
        Yield()
    end
end
local function Native(fn,value,reason)
    local ok,result=pcall(fn,value)
    if not ok then Fail('unknown',reason)end
    return result
end
local function Put(self,key,value)
    self.sequence=self.sequence+1
    self.cache[key]={value=value,used=self.sequence}
    self.stats.loads=self.stats.loads+1;self.stats.resident=self.stats.resident+1
    if self.stats.resident>self.capacity then
        local oldest,entry
        for k,v in pairs(self.cache)do if not entry or v.used<entry.used then oldest,entry=k,v end end
        self.cache[oldest]=nil;self.stats.resident=self.stats.resident-1;self.stats.evictions=self.stats.evictions+1
    end
end
function Pages.New(pack,options)
    if type(pack)~='table' or pack.format~='apr-roads-1' or not Integer(pack.world,0,4294967295)
        or type(pack.key)~='string' or not pack.key:match('^[a-f0-9]+$') or #pack.key~=64
        or not Integer(pack.nodes,1,65536) or not Integer(pack.edges,0,65536)
        or type(pack.store)~='table' or type(pack.masks)~='table' or #pack.masks>512
        or type(options)~='table' then return nil,'invalid_road_pages' end
    for _,key in ipairs({'clock','profileClock','decodeBase64','inflate','deserialize'})do
        if type(options[key])~='function' then return nil,'decoder_unavailable'end
    end
    local capacity=options.cachePages or 8
    if not Integer(capacity,1,16)then return nil,'invalid_cache_limit'end
    return setmetatable({pack=pack,options=options,cache={},sequence=0,capacity=capacity,
        maskIDs={},stats={loads=0,hits=0,evictions=0,resident=0}},Reader)
end
function Reader:GetStats()
    local copy={};for k,v in pairs(self.stats)do copy[k]=v end;return copy
end
function Reader:Page(storeNumber,key,optional)
    local job
    job=Pages.NewJob(self.options,function()
        local cacheKey=tostring(storeNumber)..'/'..key
        local cached=self.cache[cacheKey]
        if cached then
            self.sequence=self.sequence+1;cached.used=self.sequence;self.stats.hits=self.stats.hits+1
            return {status='complete',value=cached.value}
        end
        local store=storeNumber==0 and self.pack.store or self.pack.masks[storeNumber] and self.pack.masks[storeNumber].store
        local payload,rawSize=Record(store,key)
        if not payload then
            if optional then return {status='complete',absent=true}end
            Fail('unknown','page_absent')
        end
        local bytes=Native(self.options.decodeBase64,payload,'page_base64');Yield()
        Need(type(bytes)=='string' and #bytes<=16500,'page_compressed_limit')
        bytes=Native(self.options.inflate,bytes,'page_inflate');Yield()
        Need(type(bytes)=='string' and #bytes==rawSize and #bytes<=16384,'page_raw_size')
        local value=Native(self.options.deserialize,bytes,'page_cbor');Yield()
        Tree(value,{0},0)
        Put(self,cacheKey,value)
        return {status='complete',value=value}
    end)
    return job
end
local function Indexed(self,tag,number,maximum)
    local job
    job=Pages.NewJob(self.options,function()
        Need(Integer(number,1,maximum),'invalid_road_reference')
        local block=math.floor((number-1)/32)+1
        local page=Pages.Await(job,self:Page(0,string.format('%s:%06d',tag,block))).value
        Need(type(page)=='table' and page[1]==tag and page[2]==(block-1)*32+1 and type(page[3])=='table','invalid_road_page')
        local value=page[3][number-page[2]+1]
        Need(type(value)=='table','invalid_road_reference')
        return {status='complete',value=value}
    end)
    return job
end
function Reader:Node(number)return Indexed(self,'nodes',number,self.pack.nodes)end
function Reader:Edge(number)return Indexed(self,'edges',number,self.pack.edges)end
local function ArrayPoint(value)
    Need(type(value)=='table' and (#value==2 or #value==3) and Finite(value[1]) and Finite(value[2])
        and (value[3]==nil or Finite(value[3])),'invalid_road_point')
    return value
end
function Reader:Slice(number,first,last)
    local job
    job=Pages.NewJob(self.options,function()
        local edge=Pages.Await(job,self:Edge(number)).value
        Need(Integer(edge.pointCount,2,65536) and Finite(first) and Finite(last)
            and first>=1 and first<=edge.pointCount and last>=1 and last<=edge.pointCount,'invalid_road_slice')
        local function point(index)
            local block=math.floor((index-1)/128)+1
            local page=Pages.Await(job,self:Page(0,string.format('points:%06d:%06d',number,block))).value
            Need(page[1]=='points' and page[2]==(block-1)*128+1,'invalid_polyline_page')
            return ArrayPoint(page[3][index-page[2]+1])
        end
        local function at(position)
            local index=math.floor(position)
            if position==index then local p=point(index);return {p[1],p[2],p[3]}end
            local a,b=point(index),point(index+1);local t=position-index
            return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,
                a[3]~=nil and b[3]~=nil and (a[3]+(b[3]-a[3])*t) or nil}
        end
        local points={at(first)}
        local direction=first<=last and 1 or -1
        local index=direction==1 and math.floor(first)+1 or math.ceil(first)-1
        while (direction==1 and index<last) or (direction==-1 and index>last)do
            local p=point(index);points[#points+1]={p[1],p[2],p[3]};index=index+direction;Yield()
        end
        points[#points+1]=at(last)
        local distance=0
        for i=2,#points do
            local a,b=points[i-1],points[i]
            local dz=a[3]~=nil and b[3]~=nil and b[3]-a[3] or 0
            distance=distance+math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2+dz^2);Yield()
        end
        return {status='complete',points=points,distance=distance,edge=edge}
    end)
    return job
end
function Reader:Row(maskID,number)
    local job
    job=Pages.NewJob(self.options,function()
        local index=self.maskIDs[maskID]
        if not index then
            for i,mask in ipairs(self.pack.masks)do
                Need(type(mask.header)=='table' and type(mask.header.id)=='string','invalid_mask_header')
                self.maskIDs[mask.header.id]=i
                if mask.header.id==maskID then index=i end
                Yield()
            end
        end
        if not index then Fail('unknown','mask_absent')end
        local header=self.pack.masks[index].header
        Need(Integer(number,1,header.height),'invalid_row_reference')
        local block=math.floor((number-1)/32)+1
        local meta=Pages.Await(job,self:Page(index,string.format('rows:%06d',block))).value
        Need(meta[1]=='rows' and meta[2]==(block-1)*32+1,'invalid_row_directory')
        local descriptor=meta[3][number-meta[2]+1]
        Need(type(descriptor)=='table' and Integer(descriptor.chunks,1,64)
            and Integer(descriptor.spans,1,4096) and Integer(descriptor.runs,0,128),'row_limit')
        local row,runs={},{}
        for part=1,descriptor.chunks do
            local page=Pages.Await(job,self:Page(index,string.format('row:%06d:%06d',number,part))).value
            Need(page[1]=='row' and page[2]==number and page[5]==part and page[6]==descriptor.chunks
                and type(page[3])=='table' and #page[3]<=128 and type(page[4])=='table' and #page[4]<=128,'invalid_row_page')
            for _,span in ipairs(page[3])do row[#row+1]=span;Yield()end
            for _,run in ipairs(page[4])do runs[#runs+1]=run;Yield()end
        end
        Need(#row==descriptor.spans and #runs==descriptor.runs,'incomplete_row')
        return {status='complete',row=row,blockedRuns=runs}
    end)
    return job
end
function Reader:Candidates(point,radius)
    local job
    job=Pages.NewJob(self.options,function()
        Need(type(point)=='table' and Finite(point.x) and Finite(point.y)
            and Finite(radius) and radius>=0 and radius<=1000,'invalid_attachment_radius')
        local size=self.pack.spatialSize;Need(size==256,'invalid_spatial_size')
        local edges,seen={},{}
        for x=math.floor((point.x-radius)/size),math.floor((point.x+radius)/size)do
            for y=math.floor((point.y-radius)/size),math.floor((point.y+radius)/size)do
                local part,total=1,1
                repeat
                    local page=Pages.Await(job,self:Page(0,string.format('s:%+07d:%+07d:%06d',x,y,part),true))
                    if page.absent then break end
                    local value=page.value
                    Need(value[1]=='spatial' and Integer(value[2],1,512) and type(value[3])=='table' and #value[3]<=128,'invalid_spatial_page')
                    total=value[2]
                    for _,number in ipairs(value[3])do
                        Need(Integer(number,1,self.pack.edges),'invalid_edge_reference')
                        if not seen[number] then
                            Need(#edges<4096,'candidate_limit');seen[number]=true;edges[#edges+1]=number
                        end
                        Yield()
                    end
                    part=part+1
                until part>total
            end
        end
        return {status='complete',edges=edges}
    end)
    return job
end
ns.NavigationV2RoadPages=Pages
return Pages
