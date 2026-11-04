-- Explicit prerequisite declarations and isolated conditional planning effects.
local _,ns=...
local Unlocks,Catalog={},{}
Catalog.__index=Catalog
local Graph=ns.NavigationV2Graph
local MAX_ENTRIES=64

local function Name(value)return type(value)=='string' and value~='' end

local function SinglePositiveFact(source)
    if type(source)~='table' then return false end
    local group,values=next(source)
    if (group~='quests' and group~='access') or next(source,group)~=nil or type(values)~='table' then return false end
    local fact=values[1]
    if type(fact)~='table' or next(values,1)~=nil then return false end
    return group=='quests' and fact.completed==true or group=='access' and fact.allowed==true
end

function Unlocks.New(source,context)
    if type(source)~='table' then return nil,'invalid_unlocks' end
    local entries,seen,count,maximum,effects={},{},0,0,{}
    for index,d in pairs(source)do
        count=count+1
        if count>MAX_ENTRIES or not Graph.Finite(index) or index<1 or index%1~=0 or index>MAX_ENTRIES
            or type(d)~='table' then return nil,'invalid_unlocks' end
        for key in pairs(d)do
            if not ({id=true,destination=true,node=true,title=true,opens=true,requirements=true,
                completionSeconds=true,resources=true})[key] then return nil,'invalid_unlock' end
        end
        local title=ns.NavigationV2WaypointTarget.Text(d.title)
        if not Name(d.id) or seen[d.id] or not Name(d.destination) or not Name(d.node) or not title
            or not SinglePositiveFact(d.opens) or (d.completionSeconds~=nil
                and (not Graph.Finite(d.completionSeconds) or d.completionSeconds<0)) then return nil,'invalid_unlock' end
        local opens,reason=Graph.BindRequirements(context,d.opens)
        if reason then return nil,reason end
        local eligible
        eligible,reason=Graph.BindRequirements(context,d.requirements)
        if reason then return nil,reason end
        local resources
        if d.resources~=nil then
            resources,reason=ns.NavigationV2Resources.Capture(d.resources)
            if not resources then return nil,reason end
        end
        local fact=context.bindingFacts[opens][1]
        if not effects[fact.variable] then effects[fact.variable]=index end
        entries[index]={id=d.id,destination=d.destination,node=d.node,title=title,opens=opens,eligible=eligible,
            completionSeconds=d.completionSeconds,resources=resources,effectIndex=effects[fact.variable],
            effectKey=fact.variable,opensFact=fact.id}
        maximum,seen[d.id]=math.max(maximum,index),true
    end
    if count~=maximum then return nil,'invalid_unlocks' end
    return setmetatable({entries=entries,cursor=1,tracker=context.tracker,context=context,
        byNode={},watched={identity={},quests={},access={}}},Catalog)
end

-- One reference per preparation operation, including partitioned data loading.
function Catalog:Prepare(graph)
    local entry=self.entries[self.cursor]
    if not entry then return true end
    local id=self.destination and entry.destination or entry.node
    local found,status,reason
    if graph.partitioned then found,status,reason=graph:Locate(id) else found=graph.index[id] end
    if not found then return false,status or 'invalid',reason or 'invalid_unlock_node' end
    if self.destination then
        local row=self.byNode[entry.node] or {};self.byNode[entry.node]=row;row[#row+1]=entry
        self.cursor=self.cursor+1;self.destination=nil
    else self.destination=true end
    return false
end

function Catalog:HasTimed(objective)
    for _,entry in ipairs(self.entries)do
        if entry.destination==objective.to and entry.completionSeconds~=nil then return true end
    end
    return false
end

-- One declaration is considered per existing search operation. Only an observed
-- false positive fact can be granted, at its declared node, for this objective.
function Catalog:Edge(search,node,index)
    local entry=(self.byNode[node] or {})[index]
    if not entry then return nil,true end
    if entry.destination~=search.objective.to or search.current.assumed[entry.effectKey] then return end
    local fact=self.context.bindingFacts[entry.opens][1]
    search.planBindings[entry.opens]=true
    if search.planSnapshot[fact.group][fact.key]~=false then return end
    if entry.completionSeconds==nil then search.unknownUnlockCosts=true;return end
    return {id=entry.id,from=node,to=node,kind='unlock',access='available',seconds=entry.completionSeconds,
        resources=entry.resources,condition=entry.eligible,unlockEntry=entry,mode=search.current.mode}
end

function Catalog:Activate(current,entry)
    local assumed={}
    for key,value in pairs(current.assumed)do assumed[key]=value end
    assumed[entry.effectKey]=true
    local signature=current.planState
    return assumed,signature:sub(1,entry.effectIndex-1)..'1'..signature:sub(entry.effectIndex+1)
end

function Catalog:PlanSelection(search,entry)
    local selected={}
    for key,value in pairs(entry)do selected[key]=value end
    selected.proof={bindings=search.planBindings,snapshot=search.planSnapshot,plan=true,
        required={identity={},quests={},access={}}}
    return selected
end

function Catalog:Select(search,objective)
    if not search.provenNoPath then return nil,'absence_unproven' end
    local candidate,refusal
    for _,entry in ipairs(self.entries)do
        if entry.destination==objective.to and search.deniedFacts[entry.opensFact] then
            local access=self.tracker:Get(entry.opens)
            local eligibility=entry.eligible and self.tracker:Get(entry.eligible) or 'available'
            if eligibility~='available' then
                refusal=eligibility=='unknown' and 'unlock_eligibility_unknown' or refusal or 'unlock_eligibility_denied'
            elseif access=='unavailable' then
                if candidate then return nil,'ambiguous_unlock' end
                candidate=entry
            end
        end
    end
    if candidate then
        local selected={}
        for key,value in pairs(candidate)do selected[key]=value end
        local bindings=search.deniedFacts[candidate.opensFact].bindings
        if candidate.eligible then bindings[candidate.eligible]=true end
        selected.proof={bindings=bindings,required={identity={},quests={},access={}}}
        return selected
    end
    return nil,refusal or 'no_simple_unlock'
end

-- Register one binding (at most64 primitive facts) per existing job operation.
-- Selected entries own their proof; no mutable catalogue entry is reused by a
-- later result. Already registered support is dependency-indexed for observation.
function Catalog:TrackProof(entry)
    local proof=entry.proof
    local binding=next(proof.bindings,proof.cursor)
    if not binding then proof.ready=true;return true end
    proof.cursor=binding
    local gate=self.context.bindingFacts[entry.opens][1]
    local snapshot=self.tracker.snapshot
    for _,fact in ipairs(self.context.bindingFacts[binding])do
        local value=snapshot[fact.group][fact.key]
        if proof.plan then
            if value~=proof.snapshot[fact.group][fact.key] then return false,'stale','unlock_proof_changed' end
            if fact.group~=gate.group or fact.key~=gate.key then
                proof.required[fact.group][fact.key]={value=value}
                local watched=self.watched[fact.group]
                if not watched[fact.key] then watched[fact.key]={value=value} end
            end
        elseif fact.group==gate.group and fact.key==gate.key then
            if fact.expected~=true or value~=false then return false,'stale','unlock_proof_changed' end
        else
            if value~=fact.expected then return false,'stale','unlock_proof_changed' end
            proof.required[fact.group][fact.key]=value
            local watched=self.watched[fact.group]
            if not watched[fact.key] then watched[fact.key]={value=value} end
        end
    end
    return false
end

-- Only useful supporting dependencies are visited, capped by Conditions'4096
-- distinct keys. An identical accepted capture does not invalidate anything.
function Catalog:ObserveProofs()
    local changed=false
    for group,keys in pairs(self.watched)do
        for key,record in pairs(keys)do
            local value=self.tracker.snapshot[group][key]
            if value~=record.value then record.value=value;changed=true end
        end
    end
    return changed
end

function Catalog:CurrentProof(entry)
    local proof=entry.proof
    if not proof or not proof.ready then return false end
    for group,keys in pairs(proof.required)do
        for key,value in pairs(keys)do
            if proof.plan then value=value.value end
            if self.tracker.snapshot[group][key]~=value then return false end
        end
    end
    return true
end

function Catalog:Proven(entry,sequence)
    return self:CurrentProof(entry) and self.tracker.snapshot.sequence>sequence and self.tracker:Get(entry.opens)=='available'
        and self.tracker:IsCurrent(self.tracker:GetToken())
end

function Catalog:Approachable(entry)
    return self:CurrentProof(entry) and self.tracker:IsCurrent(self.tracker:GetToken()) and self.tracker:Get(entry.opens)=='unavailable'
        and (not entry.eligible or self.tracker:Get(entry.eligible)=='available')
end

ns.NavigationV2Unlocks=Unlocks
return Unlocks
