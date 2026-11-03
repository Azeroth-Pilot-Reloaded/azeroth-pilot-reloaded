-- Pure Lua 5.1 conjunctions and dependency-indexed observation ownership.
local _, ns = ...
local Conditions, Tracker = {}, {}
Tracker.__index = Tracker
local MAX_FACTS, MAX_OBSERVATIONS, MAX_BINDINGS = 64, 4096, 4096
local LOCATION = {'world','space','floor','phase'}
local COMPILED = setmetatable({}, {__mode='k'})

local function Integer(value, minimum)
    return type(value)=='number' and value==value and value>=minimum
        and value<=9007199254740991 and value%1==0
end

local function Name(value)
    return type(value)=='string' and value~=''
end

local function Identity(key,value)
    if key=='world' then return Integer(value,0) end
    return Name(value) or Integer(value,0)
end

local function Fields(source,allowed)
    if type(source)~='table' then return false end
    for key in pairs(source) do if not allowed[key] then return false end end
    return true
end

local function AddArray(facts,source,group,keyField,valueField)
    if source==nil then return true end
    if type(source)~='table' then return false end
    local count,maximum,seen=0,0,{}
    for index,entry in pairs(source) do
        if #facts>=MAX_FACTS or not Integer(index,1) or index>MAX_FACTS
            or not Fields(entry,{[keyField]=true,[valueField]=true}) then return false end
        local key,value=entry[keyField],entry[valueField]
        if not (group=='quests' and Integer(key,1) or group=='access' and Name(key))
            or type(value)~='boolean' or seen[key] then return false end
        seen[key]=true
        facts[#facts+1]={group=group,key=key,expected=value}
        count,maximum=count+1,math.max(maximum,index)
    end
    return count==maximum
end

-- No expression language. All declared facts must hold; false beats unknown.
function Conditions.Compile(source)
    if source==nil then source={} end
    if not Fields(source,{world=true,space=true,floor=true,phase=true,quests=true,access=true}) then
        return nil,'invalid_conditions'
    end
    local facts={}
    for _,key in ipairs(LOCATION) do
        if source[key]~=nil then
            if not Identity(key,source[key]) then return nil,'invalid_conditions' end
            facts[#facts+1]={group='identity',key=key,expected=source[key]}
        end
    end
    if not AddArray(facts,source.quests,'quests','questID','completed')
        or not AddArray(facts,source.access,'access','key','allowed') then return nil,'invalid_conditions' end
    local compiled={}
    COMPILED[compiled]=facts
    return compiled
end

local function Values(source,key,validate)
    local values=source[key]
    if values==nil then return {} end
    if type(values)~='table' then return end
    local result,count={},0
    for id,value in pairs(values) do
        count=count+1
        if count>MAX_OBSERVATIONS or not validate(id) or type(value)~='boolean' then return end
        result[id]=value
    end
    return result
end

local function Capture(source)
    if type(source)~='table' or not Integer(source.sequence,1)
        or (source.worldState~='ready' and source.worldState~='loading' and source.worldState~='unknown') then return end
    local quests=Values(source,'quests',function(id)return Integer(id,1)end)
    local access=Values(source,'access',Name)
    if not quests or not access then return end
    local identity={}
    for _,key in ipairs(LOCATION) do
        if source[key]~=nil and not Identity(key,source[key]) then return end
        identity[key]=source[key]
    end
    return {sequence=source.sequence,worldState=source.worldState,quests=quests,access=access,identity=identity}
end

local function FactReason(fact,unknown)
    if fact.group=='identity' then
        if unknown and fact.key=='floor' then return 'floor_ambiguous' end
        return fact.key..(unknown and '_unknown' or '_mismatch')
    end
    if fact.group=='quests' then return unknown and 'quest_unknown' or 'quest_requirement_unmet' end
    return unknown and 'access_unknown' or 'access_denied'
end

local function Evaluate(facts,snapshot)
    if #facts==0 then return 'available' end
    if snapshot.worldState~='ready' then
        return 'unknown',snapshot.worldState=='loading' and 'loading' or 'world_unknown'
    end
    local missing
    for _,fact in ipairs(facts) do
        local value=snapshot[fact.group][fact.key]
        if value==nil then missing=missing or FactReason(fact,true)
        elseif value~=fact.expected then return 'unavailable',FactReason(fact,false) end
    end
    if missing then return 'unknown',missing end
    return 'available'
end

function Conditions.New()
    return setmetatable({records={},pending={},index={quests={},access={},identity={}},bindingCount=0,
        dependencyCount=0,revision=0,identity={},
        snapshot={sequence=0,worldState='unknown',quests={},access={},identity={}}},Tracker)
end

function Tracker:Track(compiled)
    local facts=COMPILED[compiled]
    if not facts then return nil,'invalid_compiled_conditions' end
    if #facts==0 and self.unconditional then return self.unconditional end
    local added=0
    for _,fact in ipairs(facts) do
        if not self.index[fact.group][fact.key] then added=added+1 end
    end
    if self.bindingCount>=MAX_BINDINGS or self.dependencyCount+added>MAX_OBSERVATIONS then
        return nil,'condition_capacity_exceeded'
    end
    local binding,record={},{facts=facts}
    record.status,record.reason=Evaluate(facts,self.snapshot)
    self.records[binding]=record
    self.bindingCount,self.dependencyCount=self.bindingCount+1,self.dependencyCount+added
    if #facts==0 then self.unconditional=binding end
    for _,fact in ipairs(facts) do
        local group=self.index[fact.group]
        group[fact.key]=group[fact.key] or {}
        group[fact.key][record]=true
    end
    return binding
end

function Tracker:Dependencies()
    local result={quests={},access={},identity={}}
    for group,entries in pairs(self.index) do
        for key in pairs(entries) do result[group][key]=true end
    end
    return result
end

function Tracker:Get(binding)
    local record=self.records[binding]
    if not record then return nil,'invalid_condition_binding' end
    if record.pending then return 'unknown','condition_dirty' end
    return record.status,record.reason
end

function Tracker:GetToken()
    return {owner=self.identity,revision=self.revision}
end

function Tracker:IsCurrent(token)
    return not self.dirty and type(token)=='table' and token.owner==self.identity and token.revision==self.revision
end

-- A dirty burst retires old jobs immediately, without reading a client API.
-- Additional events before observation add affected records, not invalidations.
function Tracker:MarkDirty(dependencies)
    if type(dependencies)~='table' then return nil,'invalid_condition_dependencies' end
    local affected=false
    for group,entries in pairs(self.index) do
        local requested=dependencies[group]
        if type(requested)=='table' then
            for key in pairs(requested) do
                -- Revoke the fact itself as well as existing cached bindings:
                -- a later preparation slice must not reuse its old evidence.
                self.snapshot[group][key]=nil
                for record in pairs(entries[key] or {}) do
                    record.pending=true;self.pending[record]=true;affected=true
                end
            end
        end
    end
    if not affected or self.dirty then return false end
    self.dirty=true
    self.revision=self.revision+1
    return true
end

local function Affected(self,snapshot)
    local result={}
    if snapshot.worldState~=self.snapshot.worldState then
        for _,record in pairs(self.records) do result[record]=true end
    else
        for group,entries in pairs(self.index) do
            for key,records in pairs(entries) do
                if snapshot[group][key]~=self.snapshot[group][key] then
                    for record in pairs(records) do result[record]=true end
                end
            end
        end
    end
    for record in pairs(self.pending) do result[record]=true end
    return result
end

-- Full snapshots replace evidence, including omissions. A newer missing fact
-- must not retain an earlier known value. Stale/invalid captures are atomic.
function Tracker:Observe(source)
    local snapshot=Capture(source)
    if not snapshot then return nil,'invalid_condition_observation' end
    if snapshot.sequence<=self.snapshot.sequence then return false,'stale_observation' end
    local changed,recovered=false,self.dirty==true
    for record in pairs(Affected(self,snapshot)) do
        local status,reason=Evaluate(record.facts,snapshot)
        if status~=record.status then changed=true end
        record.status,record.reason,record.pending=status,reason,nil
    end
    self.snapshot=snapshot
    self.pending={}
    -- Dirty already retired the old token. Do not retire twice after capture.
    if changed and not self.dirty then self.revision=self.revision+1 end
    self.dirty=nil
    return changed,nil,recovered
end

Conditions.MAX_FACTS=MAX_FACTS
Conditions.MAX_BINDINGS=MAX_BINDINGS
Conditions.MAX_DEPENDENCIES=MAX_OBSERVATIONS
ns.NavigationV2Conditions=Conditions
return Conditions
