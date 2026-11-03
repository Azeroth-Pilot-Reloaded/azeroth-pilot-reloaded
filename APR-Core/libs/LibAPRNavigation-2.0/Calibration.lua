-- Pure, bounded calibration. Only the host can attest a completed journey.
local _,ns=...
local Calibration,Model={},{}
Model.__index=Model
local POLICY={version=1,maxKeys=2048,maxKeyLength=200,maxSamples=1000,
    weight=0.25,maxAdjustment=0.5,precision=100,minSample=0.05,
    maxInterval=7200,maxLoading=300,maxRide=3600}
Calibration.Policy=POLICY

local function Number(v) return type(v)=='number' and v==v and v>=0 and v<math.huge end
local function Name(v) return type(v)=='string' and #v>0 and #v<=POLICY.maxKeyLength and v:match('%S')~=nil end
local function Copy(t)
    local r={}
    for k,v in pairs(type(t)=='table' and t or {}) do r[k]=v end
    return r
end
local function Seconds(v,component)
    return Number(v) and (component=='loading' or v>0)
        and v<=(component=='loading' and POLICY.maxLoading or POLICY.maxRide)
end
local function Profile(store,path)
    if type(store)=='table' and store.version~=nil and store.version~=0 and store.version~=POLICY.version then return {} end
    local value=type(store)=='table' and store.profiles
    for _,key in ipairs(path) do value=type(value)=='table' and value[key] or nil end
    return type(value)=='table' and value or {}
end
local function Record(raw,component)
    -- Version zero stored a measured number. Migrate only our selected entries.
    if Seconds(raw,component) then return {measuredSeconds=raw,samples=1} end
    local r={}
    if type(raw)~='table' then return r end
    for _,key in ipairs({'manualSeconds','measuredSeconds'}) do
        if Seconds(raw[key],component) then r[key]=raw[key] end
    end
    if Number(raw.samples) and raw.samples%1==0 then r.samples=math.min(raw.samples,POLICY.maxSamples) end
    return r
end

function Calibration.New(options)
    if type(options)~='table' or type(options.identity)~='table' or type(options.definitions)~='table' then
        return nil,'invalid_calibration_options'
    end
    local identity,path=options.identity,{}
    if identity.client~='Forever' and identity.client~='Retail' then return nil,'invalid_calibration_client' end
    for _,key in ipairs({'client','build','character','computer'}) do
        if not Name(identity[key]) then return nil,'invalid_calibration_identity' end
        path[#path+1]=identity[key]
    end
    local store=options.store
    if store~=nil and type(store)~='table' then return nil,'invalid_calibration_store' end
    local profile=Profile(store,path)
    local costs=type(profile.costs)=='table' and profile.costs or {}
    local self=setmetatable({definitions={},records={},order={},path=path,store=store,
        dirty={},revision=0,stats={accepted=0,rejected=0}},Model)
    local count=0
    for index,d in pairs(options.definitions) do
        count=count+1
        if count>POLICY.maxKeys or type(index)~='number' or index%1~=0 or index<1
            or index>#options.definitions or type(d)~='table' or not Name(d.key)
            or self.definitions[d.key] or (d.component~='ride' and d.component~='loading')
            or not Seconds(d.defaultSeconds,d.component)
            or (d.manualSeconds~=nil and not Seconds(d.manualSeconds,d.component)) then
            return nil,'invalid_calibration_definition'
        end
        self.definitions[d.key]={component=d.component,defaultSeconds=d.defaultSeconds,manualSeconds=d.manualSeconds}
        self.records[d.key]=Record(costs[d.key],d.component)
        self.order[#self.order+1]=d.key
    end
    if count~=#options.definitions then return nil,'invalid_calibration_definition' end
    table.sort(self.order)
    return self
end

function Model:Get(key)
    local d,r=self.definitions[key],self.records[key]
    if not d then return nil,'unknown_calibration_key' end
    if r.manualSeconds~=nil then return r.manualSeconds,'manual' end
    if d.manualSeconds~=nil then return d.manualSeconds,'manual' end
    if r.measuredSeconds~=nil then return r.measuredSeconds,'measured' end
    return d.defaultSeconds,'default'
end
function Model:GetRevision() return self.revision end
function Model:GetStats() return Copy(self.stats) end

function Model:SetManual(key,value)
    local d=self.definitions[key]
    if not d or (value~=nil and not Seconds(value,d.component)) then return nil,'invalid_manual_cost' end
    local before=self:Get(key)
    local r=self.records[key]
    if r.manualSeconds==value then return false end
    r.manualSeconds=value;self.dirty[key]=true
    local changed=before~=self:Get(key)
    if changed then self.revision=self.revision+1 end
    return changed
end

function Model:Reset(key,mode)
    if mode~='manual' and mode~='measured' and mode~='all' then return nil,'invalid_calibration_reset' end
    if key~=nil and not self.definitions[key] then return nil,'unknown_calibration_key' end
    local changed=false
    for _,name in ipairs(key and {key} or self.order) do
        local before,r=self:Get(name),self.records[name]
        if mode~='measured' then r.manualSeconds=nil end
        if mode~='manual' then r.measuredSeconds,r.samples=nil,nil end
        self.dirty[name]=true
        changed=before~=self:Get(name) or changed
    end
    if changed then self.revision=self.revision+1 end
    return changed
end

local function Match(self,handle,owner,attempt)
    return self.active and self.active.handle==handle and self.active.owner==owner and self.active.attempt==attempt
end
local function Clock(active,now)
    if not Number(now) or now<active.last or now-active.started>POLICY.maxInterval then return false end
    active.last=now
    return true
end
function Model:Cancel()
    if not self.active then return false end
    self.active=nil;self.stats.rejected=self.stats.rejected+1
    return true
end

function Model:Begin(keys,owner,attempt,now)
    self:Cancel()
    if type(keys)~='table' or owner==nil or attempt==nil or not Number(now)
        or (keys.ride==nil and keys.loading==nil) then return nil,'invalid_measurement_start' end
    for component,key in pairs(keys) do
        if (component~='ride' and component~='loading') or not self.definitions[key]
            or self.definitions[key].component~=component then return nil,'invalid_measurement_key' end
    end
    local handle={}
    self.active={keys=Copy(keys),owner=owner,attempt=attempt,handle=handle,started=now,last=now,loading=0}
    return handle
end

function Model:Loading(handle,owner,attempt,enabled,now)
    if not Match(self,handle,owner,attempt) then return false,'stale_measurement' end
    local a=self.active
    if type(enabled)~='boolean' or not Clock(a,now) or enabled==(a.loadingAt~=nil) then
        self:Cancel();return false,'invalid_loading_interval'
    end
    if enabled then a.loadingAt=now else
        a.loading=a.loading+now-a.loadingAt;a.loadingAt=nil
        if a.loading>POLICY.maxLoading then self:Cancel();return false,'invalid_loading_interval' end
    end
    return true
end

local function Sample(self,key,seconds)
    local r=self.records[key]
    local old=r.measuredSeconds
    if old and old>=POLICY.minSample then
        local delta=math.max(-old*POLICY.maxAdjustment,math.min(old*POLICY.maxAdjustment,seconds-old))
        seconds=old+POLICY.weight*delta
    end
    r.measuredSeconds=math.floor(seconds*POLICY.precision+0.5)/POLICY.precision
    r.samples=math.min((r.samples or 0)+1,POLICY.maxSamples)
    self.dirty[key]=true
end

function Model:Finish(handle,owner,attempt,now,confirmed)
    if not Match(self,handle,owner,attempt) then return false,'stale_measurement' end
    local a=self.active
    local elapsed=Number(now) and now-a.started or nil
    if confirmed~=true or not Clock(a,now) or a.loadingAt or not elapsed
        or elapsed<POLICY.minSample or (a.keys.ride and (elapsed-a.loading<POLICY.minSample
        or elapsed-a.loading>POLICY.maxRide)) then
        self:Cancel();return false,'invalid_measurement_end'
    end
    local before={}
    for _,key in pairs(a.keys) do before[key]=self:Get(key) end
    if a.keys.ride then Sample(self,a.keys.ride,elapsed-a.loading) end
    if a.keys.loading and a.loading>=POLICY.minSample then Sample(self,a.keys.loading,a.loading) end
    local changed=false
    for _,key in pairs(a.keys) do changed=before[key]~=self:Get(key) or changed end
    self.active=nil;self.stats.accepted=self.stats.accepted+1
    if changed then self.revision=self.revision+1 end
    return changed
end

-- Copy on write: old namespaces/references and all foreign fields survive.
-- Unknown future schemas stay byte-for-byte owned by their newer writer.
function Model:Export(base)
    base=base or self.store
    if base~=nil and (type(base)~='table' or (base.version~=nil
        and base.version~=0 and base.version~=POLICY.version)) then return nil,'unsupported_calibration_version' end
    if not next(self.dirty) then return base end
    local branch=base and base.profiles
    if branch~=nil and type(branch)~='table' then return nil,'invalid_calibration_container' end
    for _,key in ipairs(self.path) do
        branch=branch and branch[key]
        if branch~=nil and type(branch)~='table' then return nil,'invalid_calibration_container' end
    end
    if branch and branch.costs~=nil and type(branch.costs)~='table' then return nil,'invalid_calibration_container' end
    local result=Copy(base);result.version=POLICY.version
    result.profiles=Copy(result.profiles)
    local target=result.profiles
    for _,key in ipairs(self.path) do target[key]=Copy(target[key]);target=target[key] end
    target.costs=Copy(target.costs)
    for key in pairs(self.dirty) do
        local record=Copy(target.costs[key])
        record.manualSeconds,record.measuredSeconds,record.samples=nil,nil,nil
        for field,value in pairs(self.records[key]) do record[field]=value end
        target.costs[key]=record
    end
    return result
end

ns.NavigationV2Calibration=Calibration
