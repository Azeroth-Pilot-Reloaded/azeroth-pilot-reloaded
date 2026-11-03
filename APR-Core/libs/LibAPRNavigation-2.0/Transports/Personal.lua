-- Observed personal travel. Pure Lua: no client calls or protected interactions.
local _, ns = ...
local Finite = ns.NavigationV2Graph.Finite
local Target = ns.NavigationV2WaypointTarget
local Personal, Catalog, Execution = {}, {}, {}
Catalog.__index, Execution.__index = Catalog, Execution
local MAX_ACTIONS = 256
local Requirements

local function Name(v) return type(v)=='string' and v:match('%S')~=nil end
local function Quantity(v) return Finite(v) and v>=0 and v%1==0 end
local function ID(v) return Quantity(v) and v>0 end
local function Seconds(v) return Finite(v) and v>=0 end
local function Boolean(v) if type(v)=='boolean' then return v end end
local function Number(v) if Seconds(v) then return v end end
local function Count(v) if Quantity(v) then return v end end

local function UseKey(d)
    return 'personal:'..d.useResourceId
end

local function Capture(d)
    if type(d)~='table' or not Name(d.id) or not Name(d.to)
        or (d.from~=nil and not Name(d.from)) or (d.kind~='spell' and d.kind~='item')
        or not ID(d[d.kind=='spell' and 'spellID' or 'itemID'])
        or type(d.destination)~='table' or not Name(d.destination.space)
        or not Name(d.destination.phase) then return nil end
    local r={id=d.id,from=d.from,to=d.to,kind=d.kind,spellID=d.kind=='spell' and d.spellID or nil,
        itemID=d.kind=='item' and d.itemID or nil,name=Target.Text(d.name),
        destination={space=d.destination.space,phase=d.destination.phase},reagents={}}
    for _,key in ipairs({'useSeconds','loadingSeconds','cooldownSeconds','timeoutSeconds'}) do
        if not Seconds(d[key]) then return nil end
        r[key]=d[key]
    end
    if r.timeoutSeconds==0 or not Seconds(r.useSeconds+r.loadingSeconds) then return nil end
    r.moneyCopper=d.moneyCopper or 0
    if not Quantity(r.moneyCopper) then return nil end
    for _,key in ipairs({'consumable','rare','chargeBased'}) do
        if d[key]~=nil and type(d[key])~='boolean' then return nil end
        r[key]=d[key]==true
    end
    if r.chargeBased and r.kind~='spell' then return nil end
    if d.cooldownGroup~=nil and not Name(d.cooldownGroup) then return nil end
    r.cooldownGroup=d.cooldownGroup
    if d.reagents~=nil and type(d.reagents)~='table' then return nil end
    local count=0
    for resourceId,reagent in pairs(d.reagents or {}) do
        count=count+1
        if count>64 or not Name(resourceId) or type(reagent)~='table'
            or not ID(reagent.itemID) or not ID(reagent.count) then return nil end
        r.reagents[resourceId]={itemID=reagent.itemID,count=reagent.count}
    end
    if r.consumable and (r.kind~='item' or not Name(d.itemResourceId)) then return nil end
    r.itemResourceId=d.itemResourceId
    if d.origin~=nil then
        if type(d.origin)~='table' then return nil end
        r.origin={}
        for _,key in ipairs({'space','phase'}) do
            if d.origin[key]~=nil and not Name(d.origin[key]) then return nil end
            r.origin[key]=d.origin[key]
        end
        if d.origin.outdoorsOnly~=nil and type(d.origin.outdoorsOnly)~='boolean' then return nil end
        r.origin.outdoorsOnly=d.origin.outdoorsOnly
    end
    return r
end

-- One physical item has one balance, even if declarations use different aliases.
local function Canonicalize(c)
    local aliases,uses={},{}
    local function Register(name,id)
        if aliases[name] and aliases[name]~=id then return nil end
        aliases[name]=id
        c.itemResources[id]=c.itemResources[id] or name
        return c.itemResources[id]
    end
    for _,d in ipairs(c.entries) do
        if d.consumable then
            d.itemResourceId=Register(d.itemResourceId,d.itemID)
            if not d.itemResourceId then return nil end
        end
        local reagents={}
        -- Sort aliases so canonical names are deterministic within a declaration.
        local names={}
        for name in pairs(d.reagents) do names[#names+1]=name end
        table.sort(names)
        for _,name in ipairs(names) do
            local reagent=d.reagents[name]
            local canonical=Register(name,reagent.itemID)
            if not canonical then return nil end
            local entry=reagents[canonical] or {itemID=reagent.itemID,count=0}
            entry.count=entry.count+reagent.count
            if not ID(entry.count) then return nil end
            reagents[canonical]=entry
        end
        d.reagents=reagents
        local api=d.kind..':'..(d.spellID or d.itemID)
        local use=uses[api]
        if use and (use.cooldownSeconds~=d.cooldownSeconds or use.chargeBased~=d.chargeBased
            or use.cooldownGroup~=d.cooldownGroup) then return nil end
        if not use then
            use={id=d.cooldownGroup or d.id,cooldownSeconds=d.cooldownSeconds,
                chargeBased=d.chargeBased,cooldownGroup=d.cooldownGroup}
            uses[api]=use
        end
        d.useResourceId=use.id
    end
    return true
end

local function Snapshot(catalog,raw)
    if type(raw)~='table' or not ID(raw.revision) then return nil end
    local r={revision=raw.revision,observedAt=Number(raw.observedAt),combat=Boolean(raw.combat),casting=Boolean(raw.casting),
        loading=Boolean(raw.loading),moneyCopper=Count(raw.moneyCopper),allowRare=raw.allowRare==true,
        items={},actions={},origin={}}
    local origin=type(raw.origin)=='table' and raw.origin or {}
    for _,key in ipairs({'node','space','phase'}) do if Name(origin[key]) then r.origin[key]=origin[key] end end
    r.origin.reliable,r.origin.indoors=Boolean(origin.reliable),Boolean(origin.indoors)
    for _,d in ipairs(catalog.entries) do
        local s=type(raw.actions)=='table' and raw.actions[d.id]
        s=type(s)=='table' and s or {}
        r.actions[d.id]={known=Boolean(s.known),owned=Boolean(s.owned),loaded=Boolean(s.loaded),
            usable=Boolean(s.usable),readyAt=Number(s.readyAt),charges=Count(s.charges),maxCharges=Count(s.maxCharges)}
        local a=r.actions[d.id]
        for _,key in ipairs({'castSeconds','rechargeStart','rechargeSeconds','rechargeRate'}) do a[key]=Number(s[key]) end
        if a.charges and (not a.maxCharges or a.charges>a.maxCharges) then a.charges=nil end
        for _,reagent in pairs(d.reagents) do
            local id=reagent.itemID
            r.items[id]=type(raw.items)=='table' and Count(raw.items[id]) or nil
        end
        if d.itemID then r.items[d.itemID]=type(raw.items)=='table' and Count(raw.items[d.itemID]) or nil end
    end
    return r
end

local function Access(d,o,forecast)
    local s,origin=o.actions[d.id],o.origin
    if d.rare and not o.allowRare then return 'unavailable' end
    if o.combat==true or o.casting==true or s.usable==false
        or (d.kind=='spell' and s.known==false) or (d.kind=='item' and s.owned==false) then return 'unavailable' end
    if origin.reliable~=true or not origin.node then return 'unknown' end
    -- An authored source can be approached later. Restrictions observed only at
    -- the current source (space/phase/indoors) cannot be projected to another one.
    if d.from and origin.node~=d.from and (not forecast or d.origin~=nil) then return 'unknown' end
    local restriction=d.origin or {}
    for _,key in ipairs({'space','phase'}) do
        if restriction[key] and origin[key] and restriction[key]~=origin[key] then return 'unavailable' end
        if restriction[key] and not origin[key] then return 'unknown' end
    end
    if restriction.outdoorsOnly and origin.indoors==true then return 'unavailable' end
    if restriction.outdoorsOnly and origin.indoors==nil then return 'unknown' end
    if o.loading~=false or o.combat~=false or o.casting~=false or s.loaded~=true or s.usable~=true
        or (d.kind=='spell' and s.known~=true) or (d.kind=='item' and s.owned~=true)
        or not o.observedAt or not s.readyAt or (not forecast and s.readyAt>o.observedAt) then return 'unknown' end
    if d.chargeBased and (not s.charges or not s.maxCharges) then return 'unknown' end
    if d.chargeBased and s.charges==0 and not forecast then return 'unknown' end
    return 'available'
end

function Personal.New(declarations,observation)
    if type(declarations)~='table' then return nil,'invalid_personal' end
    local c=setmetatable({entries={},byId={},itemResources={},generation=0,observationRevision=0},Catalog)
    local count,maximum=0,0
    for key,d in pairs(declarations) do
        if not ID(key) or key>MAX_ACTIONS then return nil,'invalid_personal' end
        local captured=Capture(d)
        if not captured or c.byId[captured.id] then return nil,'invalid_personal_action' end
        c.entries[key],c.byId[captured.id]=captured,captured
        count,maximum=count+1,math.max(maximum,key)
    end
    if count~=maximum then return nil,'invalid_personal' end
    if not Canonicalize(c) then return nil,'invalid_personal_resource_alias' end
    for _,d in ipairs(c.entries) do d.resources=Requirements(d) end
    local changed,reason=c:Observe(observation or {revision=1})
    if changed==nil then return nil,reason end
    return c
end

function Catalog:Observe(raw)
    local o=Snapshot(self,raw)
    if not o then return nil,'invalid_personal_observation' end
    if o.revision<=self.observationRevision then return false,'stale_observation' end
    local changed=self.observation==nil
    local old=self.observation
    if old then
        local before,after=Target.Copy(old),Target.Copy(o)
        before.revision,after.revision,before.observedAt,after.observedAt=nil,nil,nil,nil
        changed=not Target.Same(before,after)
        for _,d in ipairs(self.entries) do changed=changed or Access(d,old)~=Access(d,o) end
    end
    self.observation,self.observationRevision=o,o.revision
    self.outgoing,self.unanchored={},{}
    for _,d in ipairs(self.entries) do
        local from=d.from or o.origin.node
        local row=self.unanchored
        if from then
            row=self.outgoing[from] or {}
            self.outgoing[from]=row
        end
        row[#row+1]=d
    end
    local cooldowns=ns.NavigationV2Cooldowns.Capture(self.entries,o)
    changed=changed or not Target.Same(self.cooldowns,cooldowns)
    self.cooldowns=cooldowns
    if changed then self.generation=self.generation+1 end
    for _,d in ipairs(self.entries) do
        d.access=Access(d,o,true)
        d.immediateAccess=Access(d,o)
    end
    return changed
end

function Catalog:Resources()
    local o,r=self.observation,{}
    r.money=o.moneyCopper
    for id,name in pairs(self.itemResources) do r['item:'..name]=o.items[id] end
    local unknown={}
    for _,d in ipairs(self.entries) do
        if d.chargeBased or d.cooldownSeconds>0 then
            local key=UseKey(d)
            local balance=d.chargeBased and o.actions[d.id].charges or (not d.chargeBased and 1 or nil)
            if balance==nil then unknown[key]=true
            elseif not r[key] or balance<r[key] then r[key]=balance end
        end
    end
    for key in pairs(unknown) do r[key]=nil end
    return r
end

Requirements=function(d)
    local resources={}
    if d.moneyCopper>0 then resources.money=d.moneyCopper end
    for name,reagent in pairs(d.reagents) do resources['item:'..name]=reagent.count end
    if d.consumable and d.itemID then
        local key='item:'..d.itemResourceId
        resources[key]=(resources[key] or 0)+1
    end
    if d.chargeBased or d.cooldownSeconds>0 then resources[UseKey(d)]=1 end
    return resources
end

function Catalog:Edge(node,cursor)
    local row=self.outgoing[node] or {}
    local d=row[cursor] or self.unanchored[cursor-#row]
    if not d then return end
    return {id='personal:'..d.id,kind='personal',personalId=d.id,from=node,to=d.to,
        seconds=d.useSeconds+d.loadingSeconds,access=d.immediateAccess,forecastAccess=d.access,resources=Target.Copy(d.resources)}
end

-- Called after movement approach/transition cost has been evaluated. Declarations
-- and observations are already captured; this is arithmetic over immutable data.
function Catalog:Evaluate(edge,arrival,states)
    local d=self.byId[edge.personalId]
    local key=UseKey(d)
    local profile=self.cooldowns[key]
    if not Seconds(arrival) then return nil,'cooldown_clock_unknown' end
    local ready=self.observation.actions[d.id].readyAt
    if not ready then return nil,'cooldown_unknown' end
    local useAt,nextState=math.max(arrival,ready),nil
    if profile then
        useAt,nextState=ns.NavigationV2Cooldowns.Use(profile,states[key],arrival,d.cooldownSeconds)
        if not useAt then return nil,nextState end
    end
    if not Seconds(useAt) then return nil,'cooldown_clock_unknown' end
    edge.seconds=edge.seconds+(useAt-arrival)
    if not Seconds(edge.seconds) then return nil,'cooldown_overflow' end
    edge.costDetail={waitSeconds=useAt-arrival,useAt=useAt,useSeconds=d.useSeconds,loadingSeconds=d.loadingSeconds}
    local result={}
    for id,state in pairs(states) do result[id]=state end
    if nextState then result[key]=nextState end
    return edge,result
end

function Catalog:Prepare(graph)
    if self.prepared then return true end
    local d=self.entries[(self.cursor or 0)+1]
    if not d then self.prepared=true;return true end
    local nodes={d.to}
    if d.from then nodes[#nodes+1]=d.from end
    for _,node in ipairs(nodes) do
        local found,status,reason
        if graph.partitioned then found,status,reason=graph:Locate(node) else found=graph.index[node] end
        if not found then return nil,status or 'invalid',reason or 'invalid_personal_node' end
    end
    self.cursor=(self.cursor or 0)+1
    return false
end

function Catalog:SetCosts(id,costs)
    local d=self.byId[id]
    if not d or type(costs)~='table' then return nil,'invalid_personal_costs' end
    local changed=false
    for key,value in pairs(costs) do
        if (key~='useSeconds' and key~='loadingSeconds') or not Seconds(value) then return nil,'invalid_personal_costs' end
        changed=changed or d[key]~=value
    end
    if not Seconds((costs.useSeconds or d.useSeconds)+(costs.loadingSeconds or d.loadingSeconds)) then return nil,'invalid_personal_costs' end
    for key,value in pairs(costs) do d[key]=value end
    if changed then self.generation=self.generation+1 end
    return changed
end

function Catalog:NewExecution(id,options)
    local d=self.byId[id]
    if not d or type(options)~='table' or not Name(options.objectiveID) or not Seconds(options.now)
        or options.from~=(d.from or self.observation.origin.node) then return nil,'invalid_personal_execution' end
    if d.access~='available' then return nil,'personal_unavailable' end
    if not self.observation.observedAt or options.now<self.observation.observedAt then return nil,'clock_unavailable' end
    local edge={personalId=id,seconds=d.useSeconds+d.loadingSeconds,access=d.access}
    local evaluated,reason=self:Evaluate(edge,options.now,{})
    if not evaluated then return nil,reason end
    local resources
    resources,reason=ns.NavigationV2Resources.Spend(self:Resources(),{},d.resources,self.cooldowns)
    if not resources then return nil,reason end
    local readyAt=evaluated.costDetail.useAt
    return setmetatable({catalog=self,generation=self.generation,declaration=d,from=options.from,
        objectiveID=options.objectiveID,lastClock=options.now,status='running',
        phase=readyAt>options.now and 'waiting' or 'ready',readyAt=readyAt,sequence=0},Execution)
end

function Execution:GetState()
    if self.generation~=self.catalog.generation and self.status=='running' then self:Cancel('invalidated') end
    local d=self.declaration
    local waiting=self.status=='running' and self.phase=='waiting'
    return {status=self.status,phase=self.phase,reason=self.reason,personalId=d.id,kind=d.kind,
        spellID=d.spellID,itemID=d.itemID,title=d.name,instruction=waiting and 'wait_personal' or 'use_personal',
        objectiveID=self.objectiveID,attempt=self.attempt,deadline=waiting and self.readyAt or self.deadline,
        readyAt=self.readyAt,
        usedAt=self.usedAt,
        remainingSeconds=waiting and self.readyAt-self.lastClock or self.deadline and self.deadline-self.lastClock}
end

function Execution:Cancel(reason)
    self.status,self.reason,self.deadline='cancelled',reason or 'cancelled',nil
end

function Execution:Tick(now)
    if self:GetState().status~='running' then return self:GetState() end
    if not Seconds(now) or now<self.lastClock then self.status,self.reason='failed','clock_unavailable'
    elseif self.deadline and now>=self.deadline then self.status,self.reason='failed','transition_timeout' end
    if Seconds(now) then self.lastClock=now end
    if self.status=='running' and self.phase=='waiting' and now>=self.readyAt then self.phase='ready' end
    if self.status~='running' then self.deadline=nil end
    return self:GetState()
end

function Execution:BeginUse(now)
    if self:Tick(now).status~='running' or self.phase~='ready' then return nil,'personal_not_ready' end
    local deadline=now+self.declaration.timeoutSeconds
    if not Seconds(deadline) or deadline<=now then return nil,'deadline_unavailable' end
    self.phase,self.attempt,self.deadline,self.useSequence,self.usedAt='awaiting_transition',{},deadline,self.sequence,now
    return self:GetState()
end

function Execution:Observe(o,now)
    if self:Tick(now).status~='running' then return self:GetState() end
    if type(o)~='table' or not ID(o.sequence) or o.sequence<=self.sequence then return self:GetState(),'stale_observation' end
    self.sequence=o.sequence
    local d,proof=self.declaration,o.transition
    if self.phase=='awaiting_transition' and o.reliable==true and o.loading~=true
        and o.node==d.to and o.space==d.destination.space and o.phase==d.destination.phase
        and type(proof)=='table' and proof.personalId==d.id and proof.from==self.from and proof.to==d.to
        and proof.attempt==self.attempt and proof.complete==true and o.sequence>self.useSequence then
        self.status,self.deadline='complete',nil
    end
    return self:GetState()
end

ns.NavigationV2Personal=Personal
return Personal
