-- Request-scoped projection of existing declared facts. No V1 solver or client API.
local _,ns=...
local Data,Job={},{}
Job.__index=Job
local Graph=ns.NavigationV2Graph
local Finite=Graph.Finite
local KINDS={passage=true,portal=true,boat=true,zeppelin=true,tram=true,elevator=true}
local OUTPUT_OPTIONS={'movement','conditionObservation','deferConditions','resources'}

local function ID(v)
    return Finite(v) and v>=0 and v%1==0
end

local function Sample(clock)
    local ok,value=pcall(clock)
    if ok and Finite(value) and value>=0 then return value end
end

local function Listed(values,value)
    for _,v in ipairs(values or {})do if v==value then return true end end
    return false
end

-- One decimal representation for normalized map units, before projection.
-- Percent conversion can otherwise change a last binary bit and split the
-- same declared endpoint. This is a numeric codec, never a distance/radius join.
local function MapNumber(value)
    if value==0 then return 0 end
    return tonumber(string.format('%.15g',value))
end

local function Point(self,raw,unit)
    if type(raw)~='table' or not Finite(raw.x) or not Finite(raw.y) then return nil,'position_missing' end
    local identity=type(raw.identity)=='table' and raw.identity or {}
    local p={mapID=raw.mapID or raw.uiMapID,world=raw.instanceID or raw.worldID or raw.world or identity.worldID,
        z=raw.z or identity.z,floor=raw.floor or identity.floorID,phase=raw.phase or identity.phaseID,
        spaceID=raw.spaceID or identity.spaceID,accessKey=raw.accessKey,noAutoconnect=raw.noAutoconnect==true,
        areaID=raw.areaID}
    if p.world~=nil and not ID(p.world) then return nil,'world_invalid' end
    if p.z~=nil and not Finite(p.z) then return nil,'height_invalid' end
    if raw.space=='world' then
        p.wx,p.wy=raw.x,raw.y
    else
        if not ID(p.mapID) or p.mapID==0 then return nil,'map_missing' end
        local scale=unit=='map-percent' and 100 or 1
        p.x,p.y=raw.x/scale,raw.y/scale
        if p.x<0 or p.x>1 or p.y<0 or p.y>1 then return nil,'coordinates_invalid' end
        p.x,p.y=MapNumber(p.x),MapNumber(p.y)
        if type(self.options.mapToWorld)=='function' then
            local ok,world,x,y=pcall(self.options.mapToWorld,p.mapID,p.x,p.y)
            if self.result then return nil,'cancelled' end
            self.metrics.positionConversions=self.metrics.positionConversions+1
            if ok and ID(world) and Finite(x) and Finite(y) then
                if p.world~=nil and p.world~=world then return nil,'world_mismatch' end
                p.world,p.wx,p.wy=world,x,y
            end
        end
    end
    if p.world==nil and p.wx and p.mapID and type(self.options.mapToWorld)=='function' then
        local ok,world=pcall(self.options.mapToWorld,p.mapID,0,0)
        if self.result then return nil,'cancelled' end
        self.metrics.positionConversions=self.metrics.positionConversions+1
        if ok and ID(world) then p.world=world end
    end
    if raw.space=='world' and p.world==nil then return nil,'world_missing' end
    p.world=(self.data.config.WorldInstanceOverrides or {})[p.world] or p.world
    return p
end

local function Within(s,p)
    if s.worldID~=nil and p.world~=nil and s.worldID~=p.world then return false end
    if p.mapID and #(s.mapIDs or {})>0 and not Listed(s.mapIDs,p.mapID) then return false end
    if p.areaID and #(s.areaIDs or {})>0 and not Listed(s.areaIDs,p.areaID) then return false end
    local unknown=false
    for axis,key in pairs({X='wx',Y='wy',Z='z'})do
        local b=s.bounds
        if b and b['min'..axis]~=nil then
            if p[key]==nil then
                if axis~='Z' or (s.kind~='outdoor' and s.kind~='subzone') or s.requiresExit or s.groundOnly then unknown=true end
            elseif p[key]<b['min'..axis] or p[key]>b['max'..axis] then return false end
        end
    end
    if unknown then return nil end
    return true
end

local function Descendant(self,id,parent)
    for _=1,Graph.Limits.zones do
        if id==parent then return true end
        local s=self.spaces[id]
        id=s and s.parentSpace
        if not id then return false end
    end
    return false
end

local function SpacePolicy(self,source)
    if self.spacePolicies[source.id] then return self.spacePolicies[source.id] end
    local result={groundOnly=false,requiresExit=false,region=false}
    local s=source
    for _=1,Graph.Limits.zones do
        if not s then break end
        for _,key in ipairs({'floor','phase','accessKey','transitFaction','transitRegion'})do result[key]=result[key] or s[key] end
        result.groundOnly=result.groundOnly or s.groundOnly==true
        result.requiresExit=result.requiresExit or s.requiresExit==true
        result.inInstance=result.inInstance or s.kind=='instance'
        for _,map in ipairs(s.mapIDs or {})do result.groundOnly=result.groundOnly or (self.data.config.GroundOnlyAreas or {})[map]==true end
        local parent=s.parentSpace and self.spaces[s.parentSpace]
        for _,map in ipairs(parent and parent.mapIDs or {})do
            if (self.data.config.IsolatedContinents or {})[map] then result.region='isolated-region:'..s.id end
        end
        s=parent
    end
    self.spacePolicies[source.id]=result
    return result
end

local function Classify(self,p)
    p.region=(self.data.config.IsolatedAreas or {})[p.mapID] or ('world:'..tostring(p.world))
    p.groundOnly=(self.data.config.GroundOnlyAreas or {})[p.mapID]==true
    local selected,uncertain
    local worldCandidates=p.mapID and self.byWorldUnmapped[p.world] or self.byWorld[p.world]
    for _,group in ipairs({self.byMap[p.mapID] or {},worldCandidates or {}})do
        for _,s in ipairs(group)do
            local matches=Within(s,p)
            if matches and (not p.spaceID or Descendant(self,s.id,p.spaceID)) then
                local policy=SpacePolicy(self,s)
                p.groundOnly=p.groundOnly or policy.groundOnly
                if p.transitFaction and policy.transitFaction and p.transitFaction~=policy.transitFaction then uncertain=true end
                if p.transitRegion and policy.transitRegion and p.transitRegion~=policy.transitRegion then uncertain=true end
                p.transitFaction=p.transitFaction or policy.transitFaction
                p.transitRegion=p.transitRegion or policy.transitRegion
                if not selected or Descendant(self,s.id,selected.id) then selected=s
                elseif not Descendant(self,selected.id,s.id) then
                    local previous=SpacePolicy(self,selected)
                    if previous.requiresExit or policy.requiresExit or previous.floor~=policy.floor
                        or previous.phase~=policy.phase or previous.accessKey~=policy.accessKey
                        or previous.region~=policy.region then uncertain=true end
                end
            elseif matches==nil and (s.requiresExit or s.groundOnly) then uncertain=true end
        end
    end
    p.ambiguous=uncertain==true
    if selected then
        local policy=SpacePolicy(self,selected)
        p.spaceID,p.kind=p.spaceID or selected.id,selected.kind
        p.requiresExit=policy.requiresExit
        p.inInstance=policy.inInstance
        p.accessKey=p.accessKey or policy.accessKey
        if policy.region then p.region=policy.region end
        if p.floor and policy.floor and p.floor~=policy.floor then p.ambiguous=true end
        if p.phase and policy.phase and p.phase~=policy.phase then p.ambiguous=true end
    end
    return p
end

local function Key(p)
    local fields={}
    for _,key in ipairs({'mapID','x','y','world','wx','wy','z','spaceID','floor','phase','accessKey'})do
        local v=p[key]
        fields[#fields+1]=type(v)..':'..(type(v)=='number' and string.format('%.17g',v) or tostring(v))
    end
    return table.concat(fields,'|')
end

local function AddPoint(self,p)
    Classify(self,p)
    local key=Key(p)
    if self.keys[key] then
        local id=self.keys[key]
        self.positions[id].noAutoconnect=self.positions[id].noAutoconnect or p.noAutoconnect
        return id
    end
    if #self.nodes>=4096 then return nil,'position_limit' end
    local id='retail-point:'..(#self.nodes+1)
    self.nodes[#self.nodes+1]=id;self.keys[key]=id;self.positions[id]=p
    return id
end

local function Gap(self,id,reason)
    local key=tostring(id)..'\0'..reason
    if self.gapKeys[key] then return end
    self.gapKeys[key]=true
    self.metrics.gaps=self.metrics.gaps+1
    if #self.gaps<64 then self.gaps[#self.gaps+1]={id=id,reason=reason} end
end

local function Branch(access)
    return {access=access or 'available',quests={},accessFacts={}}
end

local function Merge(a,b)
    local result=Branch(Graph.CombineAccess(a.access,b.access))
    local count=0
    for _,field in ipairs({'quests','accessFacts'})do
        for key,value in pairs(a[field])do result[field][key]=value;count=count+1 end
        for key,value in pairs(b[field])do
            if result[field][key]~=nil and result[field][key]~=value then result.access='unavailable' end
            if result[field][key]==nil then count=count+1 end
            result[field][key]=value
        end
    end
    if count>64 then return Branch('unknown') end
    return result
end

local function Conjoin(a,b)
    local result={}
    for _,left in ipairs(a)do for _,right in ipairs(b)do
        if #result>=64 then return {Branch('unknown')} end
        result[#result+1]=Merge(left,right)
    end end
    return result
end

local function Decision(fact,expected,negated)
    if fact==nil then return 'unknown' end
    local matches=fact==expected
    if negated then matches=not matches end
    return matches and 'available' or 'unavailable'
end

local ACCESS_PREDICATES={questAccount='account-quest',questActive='active-quest',achievement='achievement',
    auraSpellID='aura',toyID='toy',holiday='holiday'}

local function Atom(self,id,key,value,point,negated)
    local result=Branch()
    local actor=self.options.actor or {}
    local fact,expected,accessKey
    if key=='quest' and ID(value) and value>0 then
        result.quests[value]=not negated
        self.observationRequests.quests[value]=true
        return {result}
    elseif ACCESS_PREDICATES[key] and (type(value)=='string' or ID(value)) then
        accessKey=ACCESS_PREDICATES[key]..':'..tostring(value)
    elseif key=='phase' and type(value)=='table' and type(value.group)=='string' and type(value.phase)=='string' then
        accessKey='phase:'..value.group..':'..value.phase
    elseif key=='mapArt' and type(value)=='table' and ID(value.mapID) and ID(value.artID) then
        accessKey='map-art:'..value.mapID..':'..value.artID
    elseif key=='garrison' and type(value)=='table' and ID(value.type) and ID(value.minLevel) then
        accessKey='garrison:'..value.type..':'..value.minLevel
    elseif key=='housing' and type(value)=='boolean' then
        accessKey='housing:available'
        result.accessFacts[accessKey]=negated and not value or not negated and value
        self.observationRequests.access[accessKey]={field=key,value=true}
        return {result}
    elseif key=='housingInitiative' and type(value)=='table' and ID(value.id) then
        accessKey='housing-initiative:'..value.id..':'..tostring(value.neighborhoodGUID or '')..':'..tostring(value.cycleID or '')
    elseif key=='faction' or key=='class' or key=='raceID' or key=='inGroup' then
        fact,expected=actor[key],value
    elseif key=='minLevel' or key=='maxLevel' then
        if Finite(actor.level) and Finite(value) then
            fact=key=='minLevel' and actor.level>=value or key=='maxLevel' and actor.level<=value
        end
        expected=true
    elseif key=='mapID' then fact,expected=point and point.mapID,value
    elseif key=='maps' or key=='notMaps' then
        if point and point.mapID and type(value)=='table' then fact=Listed(value,point.mapID) end
        expected=key=='maps'
    elseif key=='outdoors' or key=='notInstance' then
        local origin=(self.options.personalObservation or {}).origin or {}
        local observed=point and origin.reliable==true and self.keys[Key(point)]==origin.node
        if key=='notInstance' and observed and type(actor.inInstance)=='boolean' then fact=not actor.inInstance
        elseif key=='notInstance' and point and point.inInstance then fact=false
        elseif key=='outdoors' and observed and type(origin.indoors)=='boolean' then fact=not origin.indoors
        elseif point and point.kind=='outdoor' then fact=true
        elseif point and (point.kind=='building' or point.kind=='cave' or point.kind=='floor') and key=='outdoors' then fact=false
        elseif point and point.kind=='instance' then fact=false end
        expected=value
    else Gap(self,id,'predicate_unsupported:'..tostring(key)) end
    if accessKey then
        result.accessFacts[accessKey]=not negated
        self.observationRequests.access[accessKey]={field=key,value=value}
    else result.access=Decision(fact,expected,negated) end
    return {result}
end

local Expression
local function Group(self,id,values,point,negated,depth,any)
    if type(values)~='table' then return {Branch('unknown')} end
    if negated then any=not any end
    local result=any and {} or {Branch()}
    local count,maximum=0,0
    for index,source in pairs(values)do
        count=count+1
        if not ID(index) or index<1 or index>64 then return {Branch('unknown')} end
        maximum=math.max(maximum,index)
        local branches=Expression(self,id,source,point,negated,depth+1)
        if any then
            for _,branch in ipairs(branches)do
                if #result>=64 then Gap(self,id,'condition_alternative_limit');return {Branch('unknown')} end
                result[#result+1]=branch
            end
        else result=Conjoin(result,branches) end
    end
    if count~=maximum then return {Branch('unknown')} end
    if #result==0 then return {Branch('unavailable')} end
    return result
end

Expression=function(self,id,source,point,negated,depth)
    if depth>12 or type(source)~='table' then Gap(self,id,'condition_structure_unknown');return {Branch('unknown')} end
    local result=negated and {} or {Branch()}
    for key,value in pairs(source)do
        local branches
        if key=='all' or key=='any' then branches=Group(self,id,value,point,negated,depth,key=='any')
        elseif key=='questsAll' or key=='questsAny' then
            local terms={}
            if type(value)~='table' or #value>64 then return {Branch('unknown')} end
            for _,quest in ipairs(value)do terms[#terms+1]={quest=quest} end
            branches=Group(self,id,terms,point,negated,depth,key=='questsAny')
        elseif key=='notCondition' then branches=Expression(self,id,value,point,not negated,depth+1)
        else branches=Atom(self,id,key,value,point,negated) end
        if negated then
            for _,branch in ipairs(branches)do
                if #result>=64 then return {Branch('unknown')} end
                result[#result+1]=branch
            end
        else result=Conjoin(result,branches) end
    end
    if #result==0 then return {Branch('unavailable')} end
    return result
end

local function Requirements(self,record,point,destination)
    local result=Expression(self,record.id,record.requirements or {},point,false,0)
    for _,p in ipairs({point or false,destination or false})do
        local requirement=p and (self.data.config.MapRequirements or {})[p.mapID]
        if requirement then result=Conjoin(result,Expression(self,record.id,requirement,p,false,0)) end
    end
    return result
end

local function Typed(branch)
    local result={quests={},access={}}
    local keys={}
    for key in pairs(branch.quests)do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys)do result.quests[#result.quests+1]={questID=key,completed=branch.quests[key]} end
    keys={}
    for key in pairs(branch.accessFacts)do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys)do result.access[#result.access+1]={key=key,allowed=branch.accessFacts[key]} end
    if #result.quests==0 and #result.access==0 then return end
    return result
end

local function AddEdge(self,edge)
    if #self.edges>=Graph.Limits.edges then return 'edge_limit' end
    self.edges[#self.edges+1]=edge
    self.metrics.preparedEdges=#self.edges
end

local function Relevant(self,a,b)
    for _,p in ipairs({a,b})do
        if p.mapID and self.maps[p.mapID] or p.world~=nil and self.worlds[p.world] then return true end
    end
    return false
end

local function ActionKey(action)
    if type(action)=='table' and (action.type=='spell' or action.type=='item') and ID(action.id) and action.id>0 then
        return action.type..':'..action.id
    end
end

local function PersonalActions(c)
    local result={}
    for _,action in ipairs(c.actions)do
        result[#result+1]=action
        if action.type=='spell' and ID(action.groupSpellID) and action.groupSpellID>0 then
            result[#result+1]={type='spell',id=action.groupSpellID,reagentID=action.groupReagentID,
                requirements={all={action.requirements or {},{inGroup=true}}}}
        end
    end
    return result
end

local function CollectPersonal(self,c)
    if type(c.to)~='table' or type(c.actions)~='table' or #c.actions>64 then Gap(self,c.id,'personal_declaration_unknown');return end
    local projection={}
    for key,value in pairs(c)do projection[key]=value end
    projection.actions=PersonalActions(c)
    c=projection
    if not c.to.dynamic then
        local point,why=Point(self,c.to)
        if not point then Gap(self,c.id,why);return end
        local source=type(c.from)=='table' and not c.from.dynamic and Point(self,c.from) or point
        if not Relevant(self,source or point,point) then self.metrics.outsideScope=self.metrics.outsideScope+1;return end
    else self.observationRequests.dynamic[c.to.dynamic]={kind=c.to.dynamic} end
    self.pendingPersonal[#self.pendingPersonal+1]=c
    self.metrics.personalRecords=self.metrics.personalRecords+1
    local origin=self.positions[self.from]
    local destination=not c.to.dynamic and Point(self,c.to) or nil
    Requirements(self,c,origin,destination)
    for _,action in ipairs(c.actions)do
        local key=ActionKey(action)
        if key then
            local previous=self.observationRequests.actions[key] or {}
            local chargeBased=previous.chargeBased
            if chargeBased~=true and action.chargeBased~=nil then chargeBased=action.chargeBased end
            self.observationRequests.actions[key]={id=key,kind=action.type,
                spellID=action.type=='spell' and action.id or nil,itemID=action.type=='item' and action.id or nil,
                useSpellID=action.useSpellID or previous.useSpellID,reagentID=action.reagentID or previous.reagentID,
                chargeBased=chargeBased,
                requirements=action.requirements,connectionRequirements=c.requirements,
                toyID=type(c.requirements)=='table' and c.requirements.toyID==action.id and action.id or previous.toyID}
            Requirements(self,{id=c.id..':'..key,requirements=action.requirements})
        else Gap(self,c.id,'personal_action_unknown') end
    end
end

local function Seconds(value)
    return Finite(value) and value>=0
end

local function DeclaredSeconds(self,c,a,b)
    if c.seconds~=nil then
        if Seconds(c.seconds) then return c.seconds end
        return nil,'declared_cost_unknown'
    end
    if c.kind~='passage' or c.costMode~='ground' then return nil,'declared_cost_unknown' end
    -- Only endpoint geometry is represented here; never replace a declared
    -- polyline or intermediate passage with its straight endpoint chord.
    if c.path~=nil or c.via~=nil then return nil,'ground_geometry_unsupported' end
    if a.world==nil or a.world~=b.world or not Finite(a.wx) or not Finite(a.wy)
        or not Finite(b.wx) or not Finite(b.wy) then return nil,'ground_geometry_unavailable' end
    local seconds=math.sqrt((a.wx-b.wx)^2+(a.wy-b.wy)^2)/self.walkSpeed
    if Seconds(seconds) then return seconds end
    return nil,'ground_geometry_invalid'
end

-- Descriptions only: edge access and action observations remain authoritative.
local function AddGuidance(self,id,source,action)
    local hint={kind=source.kind,connectionID=source.id}
    if ActionKey(action) then hint.action={type=action.type,id=action.id} end
    if type(source.from)=='table' and source.from.dynamic=='player' then hint.sourceFree=true end
    for _,key in ipairs({'instruction','arrivalRange','arrivalZTolerance'})do
        local value=action and action[key]
        if value==nil then value=source[key] end
        if key=='instruction' then
            if type(value)=='string' then hint[key]=value end
        elseif Seconds(value) then hint[key]=value end
    end
    self.guidance[id]=hint
end

local function Connection(self,c)
    self.metrics.sourceRecords=self.metrics.sourceRecords+1
    if type(c)~='table' or type(c.id)~='string' or c.id=='' then return end
    if c.disabled or c.reviewStatus=='candidate' or c.reviewStatus=='disabled' then
        Gap(self,c.id,'declaration_not_admitted');return
    end
    if c.kind=='spell' or c.kind=='item' then return CollectPersonal(self,c) end
    if not KINDS[c.kind] then Gap(self,c.id,'declaration_not_admitted');return end
    local a,why=Point(self,c.from)
    local b,reason=Point(self,c.to)
    if not a or not b then Gap(self,c.id,why or reason);return end
    if not Relevant(self,a,b) then self.metrics.outsideScope=self.metrics.outsideScope+1;return end
    local from;from,why=AddPoint(self,a)
    local to;to,reason=AddPoint(self,b)
    if not from or not to then return 'budget_exceeded',why or reason end
    local alternatives=Requirements(self,c,a,b)
    local seconds,costReason=DeclaredSeconds(self,c,a,b)
    if seconds==nil then Gap(self,c.id,costReason) end
    local function Edges(source,target,direction,branches)
        for index,branch in ipairs(branches)do
            local access=branch.access
            if not seconds then access=Graph.CombineAccess(access,'unknown') end
            local id='declared:'..c.id..':'..direction..(index>1 and ':alternative:'..index or '')
            local reason=AddEdge(self,{id=id,
                from=source,to=target,seconds=seconds or 0,access=access,requirements=Typed(branch)})
            if reason then return reason end
            AddGuidance(self,id,c)
        end
    end
    local error=Edges(from,to,'forward',alternatives)
    if not error and c.bidirectional==true then error=Edges(to,from,'reverse',Requirements(self,c,b,a)) end
    if error then return 'budget_exceeded',error end
end

local function Quantity(value)
    return Seconds(value) and value%1==0
end

local function Dynamic(self,c)
    if not c.to.dynamic then return Point(self,c.to) end
    local observed=(self.options.dynamicPositions or {})[c.to.dynamic]
    if type(observed)~='table' or observed.reliable~=true then return nil,'dynamic_destination_unobserved:'..c.to.dynamic end
    local point=observed.position
    if not point and c.to.dynamic=='bind' and ID(observed.areaID) then point=(self.data.bindings or {})[observed.areaID] end
    if not point then return nil,'dynamic_destination_unresolved:'..c.to.dynamic end
    return Point(self,point)
end

local function Cost(self,c,a,fact,policy)
    if Seconds(c.seconds) then return c.seconds end
    local use=fact.castSeconds
    if not Seconds(use) then use=a.castSeconds end
    if not Seconds(use) then use=self.data.config[a.type=='spell' and 'defaultSpellCastSeconds' or 'defaultItemCastSeconds'] end
    local load=policy.loadingSeconds
    if load==nil then load=self.data.config.actionLoadingSeconds end
    if not Seconds(use) or not Seconds(load) then Gap(self,c.id,'personal_cost_unknown');return end
    return use+load,use,load
end

local function Readiness(self,c,a,fact,policy)
    local o=self.options.personalObservation or {}
    local access='available'
    local function Require(value)
        access=Graph.CombineAccess(access,type(value)~='boolean' and 'unknown' or value and 'available' or 'unavailable')
    end
    Require(o.loading~=nil and not o.loading or nil)
    if o.loading==true then access='unknown' end
    Require(o.combat==false and true or nil);Require(o.casting==false and true or nil)
    Require(fact.loaded==true and true or nil)
    if fact.usable==false then Require(nil) else Require(fact.usable) end
    if a.type=='spell' then Require(fact.known) else Require(fact.owned) end
    if a.rare==true and o.allowRare~=true then return 'unavailable' end
    if not Seconds(o.observedAt) or not Seconds(fact.readyAt) then return Graph.CombineAccess(access,'unknown') end
    return access
end

local function Reagents(self,c,a,policy)
    local result={}
    if policy.reagents~=nil and type(policy.reagents)~='table' then Gap(self,c.id,'reagent_quantity_unknown');return end
    if a.reagentID~=nil and (not ID(a.reagentID) or a.reagentID<1) then Gap(self,c.id,'reagent_quantity_unknown');return end
    for name,reagent in pairs(policy.reagents or {})do
        if type(name)~='string' or type(reagent)~='table' or not ID(reagent.itemID) or reagent.itemID<1
            or not ID(reagent.count) or reagent.count<1 then Gap(self,c.id,'reagent_quantity_unknown');return end
        result[name]={itemID=reagent.itemID,count=reagent.count}
    end
    if a.reagentID then
        local count=a.reagentCount or policy.reagentCount
        local found=false
        for _,reagent in pairs(result)do if reagent.itemID==a.reagentID then found=true end end
        if not found then
            if not ID(count) or count<1 then Gap(self,c.id,'reagent_quantity_unknown');return end
            result['retail-item-'..a.reagentID]={itemID=a.reagentID,count=count}
        end
    end
    return result
end

local function PersonalPolicyUnit(self)
    local c=self.pendingPersonal[self.personalIndex]
    if not c then self.phase,self.personalIndex,self.personalSource='personal_edges',1,1;return end
    local a=c.actions[self.actionIndex]
    if not a then self.personalIndex,self.actionIndex=self.personalIndex+1,1;return end
    self.actionIndex=self.actionIndex+1
    local key=ActionKey(a)
    if not key then return end
    local point,why=Dynamic(self,c)
    if not point then Gap(self,c.id,why);return end
    local source=type(c.from)=='table' and not c.from.dynamic and Point(self,c.from) or point
    if not Relevant(self,source or point,point) then self.metrics.outsideScope=self.metrics.outsideScope+1;return end
    local to;to,why=AddPoint(self,point)
    if not to then return 'budget_exceeded',why end
    local from
    if type(c.from)=='table' and c.from.dynamic=='player' then from=false
    else
        local source;source,why=Point(self,c.from)
        if not source then Gap(self,c.id,why);return end
        from,why=AddPoint(self,source)
        if not from then return 'budget_exceeded',why end
    end
    local o=self.options.personalObservation or {}
    local fact=(o.actions or {})[key] or {}
    if type(fact)~='table' then fact={} end
    local supplied=(self.options.actionPolicies or {})[key]
    local policy={}
    if type(supplied)=='table' then for k,v in pairs(supplied)do policy[k]=v end end
    if (self.observationRequests.actions[key] or {}).chargeBased==true or a.chargeBased==true then policy.chargeBased=true
    elseif policy.chargeBased==nil then
        policy.chargeBased=a.chargeBased
        if policy.chargeBased==nil then policy.chargeBased=(self.observationRequests.actions[key] or {}).chargeBased end
    end
    if policy.cooldownSeconds==nil then
        policy.cooldownSeconds=a.cooldownSeconds
        if policy.cooldownSeconds==nil then policy.cooldownSeconds=c.cooldownSeconds end
    end
    local total,use,load=Cost(self,c,a,fact,policy)
    local group=c.cooldownGroup or ('retail-action:'..key)
    if type(group)~='string' or group=='' then Gap(self,c.id,'cooldown_group_unknown');return end
    local exact=Seconds(policy.cooldownSeconds) and type(policy.chargeBased)=='boolean' and use~=nil and load~=nil
    if point.phase~=nil and type(point.phase)~='string' then exact=false end
    local origin=o.origin or {}
    if not exact or origin.reliable~=true or origin.node~=self.from then
        self.staticGroups[group]=true
        local reason='cooldown_period_unknown_single_use'
        if Seconds(policy.cooldownSeconds) then
            reason=type(policy.chargeBased)~='boolean' and 'charge_policy_unknown_single_use'
                or use==nil and 'cost_components_unknown_single_use' or 'origin_unobserved_single_use'
        end
        Gap(self,c.id,reason)
    end
    local reagents=Reagents(self,c,a,policy)
    local access=Readiness(self,c,a,fact,policy)
    if total==nil or reagents==nil then access=Graph.CombineAccess(access,'unknown') end
    if a.moneyCopper~=nil and not Quantity(a.moneyCopper) then access=Graph.CombineAccess(access,'unknown');Gap(self,c.id,'money_cost_unknown') end
    self.personalWork[#self.personalWork+1]={record=c,action=a,key=key,fact=fact,policy=policy,to=to,from=from,
        total=total,use=use,load=load,group=group,reagents=reagents or {},access=access,index=#self.personalWork+1}
    self.metrics.personalActions=self.metrics.personalActions+1
end

local function Balance(self,key,value)
    if not self.resourceKeys[key] then
        if self.metrics.resourceKeys>=32 then return 'resource_limit_exceeded' end
        self.resourceKeys[key]=true;self.metrics.resourceKeys=self.metrics.resourceKeys+1
    end
    if Quantity(value) then self.balances[key]=value end
end

local function Consumption(self,work,access)
    local o=self.options.personalObservation or {}
    local result={}
    if access~='available' then return result end
    local token='retail-use:'..work.group
    local why=Balance(self,token,1)
    if why then return nil,why end
    result[token]=1
    local function Item(id,count)
        local name='item:retail-item-'..id
        local reason=Balance(self,name,(o.items or {})[id])
        if reason then return reason end
        result[name]=(result[name] or 0)+count
    end
    if work.action.consumable then why=Item(work.action.id,1) end
    for _,reagent in pairs(work.reagents)do why=why or Item(reagent.itemID,reagent.count) end
    local money=work.action.moneyCopper or 0
    if Quantity(money) and money>0 then
        why=why or Balance(self,'money',o.moneyCopper);result.money=money
    end
    if why then return nil,why end
    return result
end

local function PersonalEdges(self)
    local work=self.personalWork[self.personalIndex]
    if not work then self.phase,self.i,self.j='local',1,1;return end
    local node=work.from or self.nodes[self.personalSource]
    if not node then self.personalIndex,self.personalSource=self.personalIndex+1,1;return end
    local c,a=work.record,work.action
    local point=self.positions[node]
    local branches=Conjoin(Requirements(self,c,point,self.positions[work.to]),
        Requirements(self,{id=c.id,requirements=a.requirements},point))
    local o=self.options.personalObservation or {}
    for index,branch in ipairs(branches)do
        local id='retail-personal:'..work.index..':'..self.personalSource..':'..index
        local access=Graph.CombineAccess(work.access,branch.access)
        if o.origin and o.origin.reliable==true and node==o.origin.node
            and (work.fact.usable==false or o.combat==true or o.casting==true) then
            access=Graph.CombineAccess(access,'unavailable')
        end
        if self.staticGroups[work.group] or access~='available' then
            if not Seconds(o.observedAt) or not Seconds(work.fact.readyAt) or work.fact.readyAt>o.observedAt then access=Graph.CombineAccess(access,'unknown') end
            if work.policy.chargeBased==true and (not Quantity(work.fact.charges) or work.fact.charges<1) then access=Graph.CombineAccess(access,'unknown') end
            local resources,why=Consumption(self,work,access)
            if not resources then return 'budget_exceeded',why end
            why=AddEdge(self,{id=id,from=node,to=work.to,seconds=work.total or 0,
                access=access,requirements=Typed(branch),resources=resources})
            if why then return 'budget_exceeded',why end
            AddGuidance(self,id,c,a)
        elseif #self.personal<256 then
            local destination=self.positions[work.to]
            local d={id=id,from=node,to=work.to,kind=a.type,
                spellID=a.type=='spell' and a.id or nil,itemID=a.type=='item' and a.id or nil,
                destination={space=destination.spaceID or destination.accessKey or
                    (destination.world~=nil and destination.region or 'map:'..destination.mapID),phase=destination.phase},
                useSeconds=work.use,loadingSeconds=work.load,cooldownSeconds=work.policy.cooldownSeconds,
                timeoutSeconds=self.options.personalTimeoutSeconds or 120,consumable=a.consumable==true,rare=a.rare==true,
                chargeBased=work.policy.chargeBased,cooldownGroup=work.group,reagents=work.reagents,
                itemResourceId='retail-item-'..a.id,moneyCopper=a.moneyCopper,requirements=Typed(branch)}
            self.personal[#self.personal+1]=d;self.personalFacts[id]=work.fact
            AddGuidance(self,id,c,a)
        else Gap(self,c.id,'personal_action_limit') end
    end
    if work.from then self.personalIndex,self.personalSource=self.personalIndex+1,1
    else self.personalSource=self.personalSource+1 end
end

local function Transit(self,p)
    if not p.transitFaction then return 'available' end
    local origin,goal=self.positions[self.from],self.positions[self.to]
    if p.transitRegion and (p.transitRegion==origin.transitRegion or p.transitRegion==goal.transitRegion) then return 'available' end
    local faction=(self.options.actor or {}).faction
    if not faction then return 'unknown' end
    return faction==p.transitFaction and 'available' or 'unavailable'
end

local function Local(self,a,b)
    if a.world==nil or a.world~=b.world or not a.wx or not b.wx or a.region~=b.region
        or a.noAutoconnect or b.noAutoconnect or a.ambiguous or b.ambiguous then return end
    if a.accessKey~=b.accessKey or a.floor~=b.floor or a.phase~=b.phase then return end
    if (a.requiresExit or b.requiresExit) and a.spaceID~=b.spaceID then return end
    local distance=math.sqrt((a.wx-b.wx)^2+(a.wy-b.wy)^2)
    local access=Graph.CombineAccess(Transit(self,a),Transit(self,b))
    local modes={'walk'}
    if self.options.movement then
        modes[#modes+1]='mount'
        if not a.groundOnly and not b.groundOnly and not a.requiresExit and not b.requiresExit then modes[#modes+1]='skyriding' end
    end
    for _,mode in ipairs(modes)do
        local movement
        if self.options.movement then movement={mode=mode,distance=distance,canMount='available',
            groundOnly=a.groundOnly or b.groundOnly} end
        local reason=AddEdge(self,{id='local:'..self.i..':'..self.j..':'..mode,
            from=self.nodes[self.i],to=self.nodes[self.j],seconds=distance/self.walkSpeed,
            access=access,movement=movement})
        if reason then return 'budget_exceeded',reason end
    end
end

local function Finish(self,status,reason)
    if self.result then return self.result end
    local result={status=status,reason=reason,diagnostics=self:GetMetrics()}
    if status=='complete' then
        local options={}
        for _,key in ipairs(OUTPUT_OPTIONS)do options[key]=self.options[key] end
        options.resources={}
        for key,value in pairs(self.options.resources or {})do options.resources[key]=value end
        for key,value in pairs(self.balances)do options.resources[key]=value end
        if #self.personal>0 then
            options.personal=self.personal
            local observation=ns.NavigationV2WaypointTarget.Copy(self.options.personalObservation or {})
            observation.revision=observation.revision or 1
            observation.actions=self.personalFacts
            options.personalObservation=observation
        end
        result.graph={complete=false,nodes=self.nodes,edges=self.edges}
        result.request={from=self.from,to=self.to}
        result.options,result.positions=options,self.positions
        result.guidance=self.guidance
        result.observationRequests=self.observationRequests
        result.provenance={scope='declared_retail_request',gaps=self.gaps,
            costModel='declared transport seconds; planar ground/local distances; explicit movement estimates',
            outsideScope=self.metrics.outsideScope,nativeValidated=false}
    end
    self.result=result
    self.data,self.nodes,self.edges,self.positions,self.spaces,self.byMap,self.byWorld,self.keys=nil,nil,nil,nil,nil,nil,nil,nil
    self.byWorldUnmapped,self.spacePolicies=nil,nil
    self.pendingPersonal,self.personalWork=nil,nil
    self.guidance=nil
    return result
end

local function Advance(self)
    if self.phase=='spaces' then
        local key,s=next(self.data.config.NavigationSpaces or {},self.cursor);self.cursor=key
        if not key then self.phase,self.cursor='requests',nil;return end
        self.metrics.spaceRecords=self.metrics.spaceRecords+1
        if self.metrics.spaceRecords>Graph.Limits.zones then return 'budget_exceeded','zone_limit' end
        if type(s)=='table' and type(s.id)=='string' then
            self.spaces[s.id]=s
            for _,map in ipairs(s.mapIDs or {})do
                self.byMap[map]=self.byMap[map] or {};table.insert(self.byMap[map],s)
            end
            if s.bounds and ID(s.worldID) then
                self.byWorld[s.worldID]=self.byWorld[s.worldID] or {};table.insert(self.byWorld[s.worldID],s)
                if #(s.mapIDs or {})==0 then
                    self.byWorldUnmapped[s.worldID]=self.byWorldUnmapped[s.worldID] or {};table.insert(self.byWorldUnmapped[s.worldID],s)
                end
            end
        end
    elseif self.phase=='requests' then
        local field=self.from and 'to' or 'from'
        local point,why=Point(self,self.request[field],self.request.coordinateUnit)
        if not point then return 'unknown',why end
        local id;id,why=AddPoint(self,point)
        if not id then return 'budget_exceeded',why end
        self[field]=id
        if point.mapID then self.maps[point.mapID]=true end
        if point.world~=nil then self.worlds[point.world]=true end
        if self.to then
            self.observationRequests.origin={node=self.from,position=self.positions[self.from]}
            self.phase='connections'
        end
    elseif self.phase=='connections' then
        local key,record=next(self.data.connections,self.cursor);self.cursor=key
        if not key then
            self.phase=self.options.deferObservations and 'observation_required' or 'personal_policy'
            self.personalIndex,self.actionIndex=1,1
            return
        end
        return Connection(self,record)
    elseif self.phase=='personal_policy' then return PersonalPolicyUnit(self)
    elseif self.phase=='personal_edges' then return PersonalEdges(self)
    elseif self.phase=='local' then
        if self.i>#self.nodes then return 'complete' end
        local status,reason
        if self.i~=self.j then status,reason=Local(self,self.positions[self.nodes[self.i]],self.positions[self.nodes[self.j]]) end
        self.j=self.j+1
        if self.j>#self.nodes then self.i,self.j=self.i+1,1 end
        return status,reason
    end
end

function Data.Prepare(data,request,options)
    if type(data)~='table' or type(data.config)~='table' or type(data.connections)~='table'
        or type(request)~='table' or type(options)~='table' or type(options.clock)~='function' then
        return nil,'invalid_retail_preparation'
    end
    if request.coordinateUnit~=nil and request.coordinateUnit~='map-percent' then return nil,'coordinate_unit_invalid' end
    if options.budgets~=nil and type(options.budgets)~='table' then return nil,'invalid_budgets' end
    if options.actor~=nil and type(options.actor)~='table' then return nil,'invalid_actor' end
    if options.deferObservations~=nil and type(options.deferObservations)~='boolean' then return nil,'invalid_retail_observation_options' end
    for _,key in ipairs({'personalObservation','dynamicPositions','actionPolicies','conditionObservation','resources'})do
        if options[key]~=nil and type(options[key])~='table' then return nil,'invalid_retail_observation_options' end
    end
    local personal=options.personalObservation or {}
    for _,key in ipairs({'actions','items','origin'})do
        if personal[key]~=nil and type(personal[key])~='table' then return nil,'invalid_retail_observation' end
    end
    for _,key in ipairs({'NavigationSpaces','IsolatedAreas','IsolatedContinents','GroundOnlyAreas','WorldInstanceOverrides','MapRequirements'})do
        if data.config[key]~=nil and type(data.config[key])~='table' then return nil,'invalid_retail_configuration' end
    end
    local budgets={}
    for key,maximum in pairs(Graph.Budgets)do
        local value=(options.budgets or {})[key] or maximum
        if not Finite(value) or value<=0 or value>maximum then return nil,'invalid_budgets' end
        budgets[key]=value
    end
    local clock=Sample(options.clock)
    if not clock then return nil,'clock_unavailable' end
    local speed=options.walkSpeed or 7
    if not Finite(speed) or speed<=0 then return nil,'invalid_walk_speed' end
    local captured={coordinateUnit=request.coordinateUnit}
    for _,field in ipairs({'from','to'})do
        if type(request[field])~='table' then return nil,'position_missing' end
        captured[field]={}
        for _,key in ipairs({'mapID','uiMapID','x','y','z','space','instanceID','worldID','world',
            'floor','phase','spaceID','accessKey','noAutoconnect','areaID'})do captured[field][key]=request[field][key] end
        if type(request[field].identity)=='table' then
            captured[field].identity={}
            for _,key in ipairs({'worldID','z','spaceID','floorID','phaseID'})do captured[field].identity[key]=request[field].identity[key] end
        end
    end
    local settings={}
    for key,value in pairs(options)do settings[key]=value end
    return setmetatable({data=data,request=captured,options=settings,budgets=budgets,walkSpeed=speed,
        started=clock,lastWall=clock,cpuMs=0,phase='spaces',nodes={},edges={},positions={},keys={},
        spaces={},byMap={},byWorld={},byWorldUnmapped={},spacePolicies={},maps={},worlds={},gaps={},gapKeys={},
        observationRequests={quests={},access={},actions={},dynamic={}},pendingPersonal={},personalWork={},
        staticGroups={},personal={},personalFacts={},balances={},resourceKeys={},guidance={},
        metrics={operations=0,sourceRecords=0,spaceRecords=0,positionConversions=0,preparedEdges=0,gaps=0,
            outsideScope=0,personalRecords=0,personalActions=0,resourceKeys=0}},Job)
end

function Job:GetMetrics()
    local result={}
    for key,value in pairs(self.metrics)do result[key]=value end
    result.cpuMs=self.cpuMs;result.elapsedMs=self.lastWall-self.started
    return result
end

function Job:Step(operations,milliseconds)
    if self.result then return self.result end
    operations=operations or 64
    milliseconds=milliseconds or self.budgets.sliceMs
    if not ID(operations) or operations<1 or not Finite(milliseconds) or milliseconds<=0 then return Finish(self,'invalid','invalid_step_budget') end
    local start=Sample(self.options.clock)
    if not start or start<self.lastWall then return Finish(self,'unknown','clock_unavailable') end
    local previous=start
    for _=1,operations do
        if self.cpuMs>=self.budgets.cpuMs then return Finish(self,'budget_exceeded','cpu_budget') end
        if previous-self.started>=self.budgets.elapsedMs then return Finish(self,'budget_exceeded','elapsed_budget') end
        local status,reason=Advance(self)
        if self.result then return self.result end
        self.metrics.operations=self.metrics.operations+1
        local now=Sample(self.options.clock)
        if not now or now<previous then return Finish(self,'unknown','clock_unavailable') end
        self.cpuMs=self.cpuMs+now-previous;self.lastWall=now;previous=now
        if self.cpuMs>=self.budgets.cpuMs then return Finish(self,'budget_exceeded','cpu_budget') end
        if now-self.started>=self.budgets.elapsedMs then return Finish(self,'budget_exceeded','elapsed_budget') end
        if status then return Finish(self,status,reason) end
        if self.phase=='observation_required' then break end
        if now-start>=math.min(milliseconds,self.budgets.sliceMs) then break end
    end
    return {status='running',phase=self.phase,diagnostics=self:GetMetrics()}
end

function Job:Cancel()
    return Finish(self,'cancelled','cancelled')
end

function Job:GetObservationRequests()
    if self.phase=='spaces' or self.phase=='requests' or self.phase=='connections' then return nil,'observations_not_discovered' end
    return self.observationRequests
end

function Job:ResumeObservations(snapshot)
    if self.result or self.phase~='observation_required' then return nil,'observation_not_requested' end
    if type(snapshot)~='table' then return nil,'invalid_retail_observation' end
    for _,key in ipairs({'personalObservation','conditionObservation','dynamicPositions','actionPolicies'})do
        if snapshot[key]~=nil and type(snapshot[key])~='table' then return nil,'invalid_retail_observation' end
    end
    local personal=snapshot.personalObservation or {}
    for _,key in ipairs({'actions','items','origin'})do
        if personal[key]~=nil and type(personal[key])~='table' then return nil,'invalid_retail_observation' end
    end
    for _,key in ipairs({'personalObservation','conditionObservation','dynamicPositions','actionPolicies'})do
        if snapshot[key]~=nil then self.options[key]=ns.NavigationV2WaypointTarget.Copy(snapshot[key]) end
    end
    self.phase='personal_policy'
    return true
end

ns.NavigationV2RetailData=Data
return Data
