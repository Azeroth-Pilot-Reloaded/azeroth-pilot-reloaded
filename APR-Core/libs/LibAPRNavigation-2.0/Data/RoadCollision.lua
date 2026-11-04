-- Pure Lua 5.1. A local mask proof, not a pathfinder or a physical floor oracle.
local _, ns = ...
local Road, Source, Job = {}, {}, {}
Source.__index, Job.__index = Source, Job
local budgets = ns.NavigationV2Graph and ns.NavigationV2Graph.Budgets or {sliceMs=1,cpuMs=100,elapsedMs=5000}
local ceilings = {maxMasks=512,maxRowSpans=4096,maxCachedRows=256,maxCachedSpans=65536,
    maxRuns=65536,maxCells=65536,maxWalls=4096,maxJobs=8}
local states = {open=true,water=true,blocked=true,inherit=true,['unknown-floor']=true}
local identityKeys = {'space','floor','phase'}
local scope = 'declared_collision_cells_2d'
local Yield = coroutine.yield

local function Finite(n)
    return type(n)=='number' and n==n and n>-math.huge and n<math.huge
end
local function Integer(n,lo,hi)
    return Finite(n) and n%1==0 and n>=lo and n<=hi
end
local function Plain(value) return type(value)=='table' and getmetatable(value)==nil end
local function Fields(value,allowed)
    if not Plain(value) then return false end
    for key in pairs(value) do if not allowed[key] then return false end end
    return true
end
local function Need(ok,reason) if not ok then error(reason,0) end end
local function Named(value) return type(value)=='string' and #value>0 and #value<=128 end
local function Identity(value) return Named(value) or Integer(value,0,9007199254740991) end
local function Point(value)
    if not Fields(value,{x=true,y=true,z=true,worldID=true,space=true,floor=true,phase=true}) then return nil end
    if not Finite(value.x) or not Finite(value.y) or math.abs(value.x)>2147483.647
        or math.abs(value.y)>2147483.647 or (value.z~=nil and not Finite(value.z))
        or (value.worldID~=nil and not Integer(value.worldID,0,9007199254740991)) then return nil end
    local result={x=value.x,y=value.y,z=value.z,worldID=value.worldID}
    for _,key in ipairs(identityKeys) do
        if value[key]~=nil and not Identity(value[key]) then return nil end
        result[key]=value[key]
    end
    return result
end

-- Array validation itself yields; no hidden whole-row scan in New/Query.
local function Dense(raw,maximum)
    if not Plain(raw) then return nil end
    local size,count=#raw,0
    if size>maximum then return nil end
    for key in pairs(raw) do
        count=count+1
        if count>maximum or not Integer(key,1,size) then return nil end
        Yield()
    end
    if count~=size then return nil end
    return size
end

local function Clock(fn)
    local ok,value=pcall(fn)
    if ok and Finite(value) and value>=0 then return value end
end
local function Finish(self,status,reason)
    self.status,self.reason,self.thread=status,reason,nil
    if self.owner then self.owner.jobs=self.owner.jobs-1; self.owner=nil; self.candidates=nil end
    return self:GetState()
end
local function Sample(self)
    local wall,cpu=Clock(self.options.clock),Clock(self.options.profileClock)
    if self.status~='running' then return nil end
    if not wall or not cpu then return 'clock_unavailable' end
    if self.lastWall and (wall<self.lastWall or cpu<self.lastCPU) then return 'clock_regressed' end
    self.started=self.started or wall
    self.lastWall,self.lastCPU=wall,cpu
    self.elapsedMs=(wall-self.started)*1000
    return nil,cpu
end
local function Step(self,operations,milliseconds)
    if self.status~='running' then return self:GetState() end
    if operations==nil then operations=64 end
    if milliseconds==nil then milliseconds=self.options.sliceMs end
    if not Integer(operations,1,4096) or not Finite(milliseconds) or milliseconds<=0 then
        return Finish(self,'invalid','invalid_step_budget')
    end
    milliseconds=math.min(milliseconds,self.options.sliceMs)
    local reason,first=Sample(self)
    if self.status~='running' then return self:GetState() end
    if reason then return Finish(self,'unknown',reason) end
    local previous,startCPU=first,first
    for _=1,operations do
        if self.elapsedMs>=self.options.elapsedMs then return Finish(self,'budget_exceeded','elapsed_budget') end
        local ok,status,why=coroutine.resume(self.thread)
        self.operations=self.operations+1
        reason,first=Sample(self)
        if self.status~='running' then return self:GetState() end
        if reason then return Finish(self,'unknown',reason) end
        self.cpuMs=self.cpuMs+first-previous
        previous=first
        if self.cpuMs>=self.options.cpuMs then return Finish(self,'budget_exceeded','cpu_budget') end
        if self.elapsedMs>=self.options.elapsedMs then return Finish(self,'budget_exceeded','elapsed_budget') end
        if not ok then return Finish(self,'invalid',tostring(status)) end
        if coroutine.status(self.thread)=='dead' then return Finish(self,status,why) end
        if first-startCPU>=milliseconds then break end
    end
    return self:GetState()
end
local function Header(raw)
    Need(Fields(raw,{id=true,originX=true,originY=true,cellSize=true,width=true,height=true,
        rows=true,blockedRuns=true,splitHeight=true}),'invalid_mask_fields')
    Need(Named(raw.id) and Finite(raw.originX) and Finite(raw.originY)
        and math.abs(raw.originX)<=2147483.647 and math.abs(raw.originY)<=2147483.647
        and Finite(raw.cellSize) and raw.cellSize>=.001 and raw.cellSize<=2147483.647
        and Integer(raw.width,1,4000000) and Integer(raw.height,1,4000000)
        and Plain(raw.rows),'invalid_mask_header')
    Need(raw.splitHeight==nil or Finite(raw.splitHeight),'invalid_split_height')
    Need(raw.blockedRuns==nil or Plain(raw.blockedRuns),'invalid_blocked_runs')
    return {id=raw.id,originX=raw.originX,originY=raw.originY,size=raw.cellSize,
        width=raw.width,height=raw.height,rows=raw.rows,runs=raw.blockedRuns,
        splitHeight=raw.splitHeight,minX=raw.originX-raw.height*raw.cellSize,
        minY=raw.originY-raw.width*raw.cellSize}
end
local function Prepare(self,definition)
    local count=Dense(definition.overlays,self.options.maxMasks-1)
    Need(count~=nil,'invalid_overlays')
    local seen={}
    for index=1,count+1 do
        local mask=Header(index<=count and definition.overlays[index] or definition.base)
        Need(not seen[mask.id],'duplicate_mask')
        seen[mask.id]=true;self.masks[index]=mask
        Yield()
    end
    local walls=definition.walls
    if walls==nil then walls={} end
    count=Dense(walls,self.options.maxWalls)
    Need(count~=nil,'invalid_walls')
    for index=1,count do
        local wall=walls[index]
        Need(Fields(wall,{from=true,to=true}),'invalid_wall')
        Need(Fields(wall.from,{x=true,y=true}) and Fields(wall.to,{x=true,y=true}),'invalid_wall')
        local from,to=Point(wall.from),Point(wall.to)
        Need(from and to,'invalid_wall')
        self.walls[index]={from=from,to=to}
        Yield()
    end
    self.raw=nil
    return 'ready'
end

function Road.New(definition,options)
    if not Fields(definition,{worldID=true,base=true,overlays=true,identity=true,walls=true})
        or not Integer(definition.worldID,0,9007199254740991) or not Plain(definition.base)
        or not Plain(definition.overlays) or (definition.walls~=nil and not Plain(definition.walls)) or not Plain(options)
        or type(options.clock)~='function' or type(options.profileClock)~='function' then
        return nil,'invalid_source'
    end
    local copy={clock=options.clock,profileClock=options.profileClock}
    for key,maximum in pairs(budgets) do
        local value=options[key]
        if value==nil then value=maximum end
        if not Finite(value) or value<=0 or value>maximum then return nil,'invalid_budgets' end
        copy[key]=value
    end
    for key,maximum in pairs(ceilings) do
        local value=options[key]
        if value==nil then value=maximum end
        if not Integer(value,1,maximum) then return nil,'invalid_limits' end
        copy[key]=value
    end
    for key in pairs(options) do
        if copy[key]==nil then return nil,'invalid_options' end
    end
    local identity=definition.identity
    if identity==nil then identity={} end
    if not Fields(identity,{space=true,floor=true,phase=true}) then return nil,'invalid_identity' end
    local captured={}
    for _,key in ipairs(identityKeys) do
        if identity[key]~=nil and not Identity(identity[key]) then return nil,'invalid_identity' end
        captured[key]=identity[key]
    end
    local self=setmetatable({status='running',worldID=definition.worldID,identity=captured,
        options=copy,operations=0,cpuMs=0,elapsedMs=0,masks={},walls={},raw=definition,
        cache={},cacheRows=0,cacheSpans=0,sequence=0,validatedRows=0,validatedSpans=0,
        runIndexes={},indexedRuns=0,jobs=0,hasWalls=definition.walls~=nil},Source)
    self.thread=coroutine.create(function()return Prepare(self,definition)end)
    return self
end

local function Cache(self,key,row)
    self.sequence=self.sequence+1;row.used=self.sequence
    local old=self.cache[key]
    if old then self.cacheSpans=self.cacheSpans-#old.spans else self.cacheRows=self.cacheRows+1 end
    self.cache[key]=row;self.cacheSpans=self.cacheSpans+#row.spans
    while self.cacheRows>self.options.maxCachedRows or self.cacheSpans>self.options.maxCachedSpans do
        local oldest,entry
        for candidate,value in pairs(self.cache) do
            if not entry or value.used<entry.used then oldest,entry=candidate,value end
        end
        self.cache[oldest]=nil;self.cacheRows=self.cacheRows-1;self.cacheSpans=self.cacheSpans-#entry.spans
        Yield()
    end
    return row
end
local function Row(self,mask,number)
    local key=mask.id..':'..number
    local cached=self.cache[key]
    if cached then self.sequence=self.sequence+1;cached.used=self.sequence;return cached end
    local raw=rawget(mask.rows,number)
    if raw==nil then return Cache(self,key,{spans={},reason='missing_row'}) end
    if Plain(raw) and #raw>math.min(self.options.maxRowSpans,self.options.maxCachedSpans) then
        return Cache(self,key,{spans={},reason='row_span_limit'})
    end
    local count=Dense(raw,math.min(self.options.maxRowSpans,self.options.maxCachedSpans))
    if not count or count==0 then return Cache(self,key,{spans={},reason='invalid_row'}) end
    local spans,nextColumn={},1
    for index=1,count do
        local span=raw[index]
        if not Fields(span,{from=true,to=true,state=true}) or span.from~=nextColumn
            or not Integer(span.to,nextColumn,mask.width) or not states[span.state] then
            return Cache(self,key,{spans={},reason='invalid_row'})
        end
        spans[index]={from=span.from,to=span.to,state=span.state}
        nextColumn=span.to+1
        Yield()
    end
    if nextColumn~=mask.width+1 then return Cache(self,key,{spans={},reason='invalid_row'}) end
    self.validatedRows=self.validatedRows+1;self.validatedSpans=self.validatedSpans+count
    return Cache(self,key,{spans=spans})
end
local function RunIndex(self,mask)
    if self.runIndexes[mask] then return self.runIndexes[mask] end
    local index={}
    if mask.runs then
        local count=Dense(mask.runs,self.options.maxRuns-self.indexedRuns)
        Need(count~=nil,'invalid_blocked_runs')
        for i=1,count do
            local run=mask.runs[i]
            Need(Fields(run,{row=true,column=true,count=true})
                and Integer(run.row,1,mask.height) and Integer(run.column,1,mask.width)
                and Integer(run.count,1,mask.width-run.column+1),'invalid_blocked_runs')
            local row=index[run.row] or {};index[run.row]=row
            Need(#row<128,'blocked_run_row_limit')
            row[#row+1]={from=run.column,to=run.column+run.count-1}
            Yield()
        end
        if self.runIndexes[mask] then return self.runIndexes[mask] end
        Need(self.indexedRuns+count<=self.options.maxRuns,'blocked_run_limit')
        self.indexedRuns=self.indexedRuns+count
    end
    self.runIndexes[mask]=index
    return index
end
local function State(row,column)
    local lo,hi=1,#row.spans
    while lo<=hi do
        local mid=math.floor((lo+hi)/2);local span=row.spans[mid]
        if column<span.from then hi=mid-1 elseif column>span.to then lo=mid+1 else return span.state end
    end
end
local function Cell(origin,coordinate,size,sign,delta)
    local axis=(origin-coordinate)/size
    -- Only broadens the set of checked cells: subtraction/interpolation error
    -- at large world offsets must never lose a corner or a grid-line neighbor.
    local tolerance=1e-9+2e-15*(math.abs(origin)+math.abs(coordinate)+math.abs(delta)+1)/size
    local nearest=math.floor(axis+.5)
    if math.abs(axis-nearest)<=tolerance then return sign>0 and nearest or nearest+1 end
    return math.floor(axis)+1
end
local function Check(self,x,y,sx,sy)
    for _,mask in ipairs(self.candidates) do
        local row=Cell(mask.originX,x,mask.size,sx,self.dx)
        local column=Cell(mask.originY,y,mask.size,sy,self.dy)
        if row>=1 and row<=mask.height and column>=1 and column<=mask.width then
            self.cellChecks=self.cellChecks+1
            if self.cellChecks>self.options.maxCells then return 'budget_exceeded','cell_limit' end
            local data=Row(self.owner,mask,row)
            if data.reason then return 'unknown',data.reason end
            local state=State(data,column)
            if state=='blocked' then return 'blocked','blocked_cell' end
            local runs=RunIndex(self.owner,mask)[row]
            for _,run in ipairs(runs or {}) do
                if column>=run.from and column<=run.to then return 'unknown','blocked_run_unresolved' end
                Yield()
            end
            if state~='inherit' then
                if state=='unknown-floor' then return 'unknown','unknown_floor' end
                if mask.splitHeight~=nil then return 'unknown','split_height_unresolved' end
                if state=='water' and self.mode~='swim' then return 'blocked','water_requires_swim' end
                if state=='open' and self.mode~='walk' then return 'blocked','land_requires_walk' end
                Yield()
                return
            end
        end
        Yield()
    end
    return 'unknown','outside_domain'
end
local function SamplePoint(self,t)
    local x,y=self.from.x+self.dx*t,self.from.y+self.dy*t
    for _,sx in ipairs({-1,1}) do
        for _,sy in ipairs({-1,1}) do
            local status,reason=Check(self,x,y,sx,sy)
            if status then return status,reason end
        end
    end
end
local function Axis(streams,origin,size,start,delta,maximum)
    if delta==0 then return end
    local u,du=(origin-start)/size,-delta/size
    local step=du>0 and 1 or -1
    local line=du>0 and math.max(0,math.floor(u)+1) or math.min(maximum,math.ceil(u)-1)
    if line<0 or line>maximum then return end
    local t=(line-u)/du
    if t>0 and t<=1 then streams[#streams+1]={u=u,du=du,line=line,step=step,maximum=maximum,t=t} end
end
local function Advance(stream)
    stream.line=stream.line+stream.step
    if stream.line<0 or stream.line>stream.maximum then stream.t=math.huge
    else stream.t=(stream.line-stream.u)/stream.du end
end
local function Cross(a,b,c)
    local left,right=(b.x-a.x)*(c.y-a.y),(b.y-a.y)*(c.x-a.x)
    local value=left-right
    if math.abs(value)<=1e-12*(math.abs(left)+math.abs(right)+1) then return 0 end
    return value>0 and 1 or -1
end
local function Intersects(a,b,c,d)
    if math.max(a.x,b.x)<math.min(c.x,d.x) or math.max(c.x,d.x)<math.min(a.x,b.x)
        or math.max(a.y,b.y)<math.min(c.y,d.y) or math.max(c.y,d.y)<math.min(a.y,b.y) then return false end
    return Cross(a,b,c)*Cross(a,b,d)<=0 and Cross(c,d,a)*Cross(c,d,b)<=0
end
local function Trace(self)
    for _,point in ipairs({self.from,self.to}) do
        if point.worldID~=nil and point.worldID~=self.owner.worldID then return 'blocked','world_mismatch' end
    end
    for _,key in ipairs(identityKeys) do
        local expected=self.owner.identity[key] or self.from[key] or self.to[key]
        if expected~=nil then
            if self.from[key]==nil or self.to[key]==nil then return 'unknown',key..'_unknown' end
            if self.from[key]~=expected or self.to[key]~=expected then return 'blocked',key..'_mismatch' end
        end
    end
    for _,wall in ipairs(self.owner.walls) do
        if Intersects(self.from,self.to,wall.from,wall.to) then return 'blocked','wall_intersection' end
        Yield()
    end
    local streams={}
    for _,mask in ipairs(self.owner.masks) do
        if math.max(self.from.x,self.to.x)>=mask.minX and math.min(self.from.x,self.to.x)<=mask.originX
            and math.max(self.from.y,self.to.y)>=mask.minY and math.min(self.from.y,self.to.y)<=mask.originY then
            self.candidates[#self.candidates+1]=mask
            Axis(streams,mask.originX,mask.size,self.from.x,self.dx,mask.height)
            Axis(streams,mask.originY,mask.size,self.from.y,self.dy,mask.width)
        end
        Yield()
    end
    local status,reason=SamplePoint(self,0)
    if status then return status,reason end
    local current=0
    while current<1 do
        local nextT,selected=1,nil
        for _,stream in ipairs(streams) do
            if stream.t<=nextT then nextT,selected=stream.t,stream end
            Yield()
        end
        if nextT>current then
            status,reason=SamplePoint(self,(current+nextT)/2)
            if status then return status,reason end
            status,reason=SamplePoint(self,nextT)
            if status then return status,reason end
            current=nextT
        end
        if selected then Advance(selected) end
    end
    return 'complete'
end

function Source:Query(request)
    if self.status~='ready' then return nil,'source_not_ready' end
    if not Fields(request,{from=true,to=true,mode=true}) then return nil,'invalid_request' end
    local from,to=Point(request.from),Point(request.to)
    if not from or not to then return nil,'invalid_request' end
    if request.mode~='walk' and request.mode~='swim' then return nil,'invalid_mode' end
    if self.jobs>=self.options.maxJobs then return nil,'query_limit' end
    local job=setmetatable({status='running',options=self.options,owner=self,from=from,to=to,
        dx=to.x-from.x,dy=to.y-from.y,mode=request.mode,worldID=self.worldID,
        wallScope=self.hasWalls and 'supplied_barrier_segments' or 'not_supplied',
        operations=0,cpuMs=0,elapsedMs=0,cellChecks=0,candidates={}},Job)
    self.jobs=self.jobs+1
    job.thread=coroutine.create(function()return Trace(job)end)
    return job
end
function Source:GetState()
    return {status=self.status,reason=self.reason,operations=self.operations,cpuMs=self.cpuMs,
        elapsedMs=self.elapsedMs,preparedMasks=#self.masks,validatedRows=self.validatedRows,
        validatedSpans=self.validatedSpans,cachedRows=self.cacheRows,cachedSpans=self.cacheSpans,
        indexedRuns=self.indexedRuns,activeQueries=self.jobs,validationScope='mask_headers_only',globallyValidated=false}
end
function Job:GetState()
    return {status=self.status,reason=self.reason,operations=self.operations,cpuMs=self.cpuMs,
        elapsedMs=self.elapsedMs,cellChecks=self.cellChecks,scope=scope,mode=self.mode,
        worldID=self.worldID,wallScope=self.wallScope,validationScope='visited_rows_only',globallyValidated=false}
end
function Source:Cancel()
    if self.status=='running' then return Finish(self,'cancelled','cancelled') end
    return self:GetState()
end
Job.Cancel=Source.Cancel
Source.Step,Job.Step=Step,Step
ns.NavigationV2RoadCollision=Road
return Road
