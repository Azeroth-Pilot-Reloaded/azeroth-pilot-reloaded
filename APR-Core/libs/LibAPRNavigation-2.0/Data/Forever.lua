-- Raw, ready declarations only. No V1 search, factory invocation or native API.
local _,ns=...
local Data,Job={},{ }
Job.__index=Job
local Limits=ns.NavigationV2Graph.Limits
local Defaults=ns.NavigationV2Graph.Budgets
local Yield=coroutine.yield
local function Finite(n)return type(n)=='number' and n==n and n>-math.huge and n<math.huge end
local function Need(ok,reason)if not ok then error({status='invalid',reason=reason},0)end end
local function Stop(status,reason)error({status=status,reason=reason},0)end
local function Sample(fn)local ok,n=pcall(fn);if ok and Finite(n) and n>=0 then return n end end
local function Copy(value,depth)
    if type(value)~='table' then Need(type(value)~='function','non_declarative_data');return value end
    Need((depth or 0)<12,'declaration_depth')
    local result,count={},0
    for k,v in pairs(value)do
        count=count+1;Need(count<=256,'declaration_fields')
        result[k]=Copy(v,(depth or 0)+1);Yield()
    end
    return result
end
local function FillMissing(supplied,captured,depth)
    if supplied==nil then return Copy(captured,depth) end
    if type(supplied)~='table' or type(captured)~='table' then return Copy(supplied,depth) end
    Need((depth or 0)<12,'declaration_depth')
    local result=Copy(supplied,depth)
    local count=0
    for key,value in pairs(captured)do
        count=count+1;Need(count<=256,'declaration_fields')
        result[key]=FillMissing(supplied[key],value,(depth or 0)+1);Yield()
    end
    return result
end
local function Array(value,maximum)
    Need(type(value)=='table' and #value<=maximum,'declaration_array')
    local count=0
    for k in pairs(value)do
        count=count+1;Need(type(k)=='number' and k%1==0 and k>=1 and k<=#value and count<=maximum,'declaration_array')
        Yield()
    end
    Need(count==#value,'declaration_array')
    return #value
end
local function Position(p,world)
    if type(p)~='table' or not Finite(p.x) or not Finite(p.y)
        or (p.z~=nil and not Finite(p.z)) then return nil end
    local w=p.world or p.instanceID or world
    if not Finite(w) or w<0 or w%1~=0 or (world~=nil and w~=world) or p.space=='map' then return nil end
    return {world=w,x=p.x,y=p.y,z=p.z,uiMapID=p.uiMapID,space=p.spaceID or (p.space~='world' and p.space or nil),
        floor=p.floor,phase=p.phase,accessKey=p.accessKey,indoor=p.indoor,groundOnly=p.groundOnly,
        noAutoconnect=p.noAutoconnect,terrainBoundary=p.terrainBoundary}
end
local function Spatial(point,...)
    for i=1,select('#',...)do
        local declaration=select(i,...)
        if declaration then
            for _,key in ipairs({'space','floor','phase','accessKey'})do
                local value=declaration[key]
                if key=='space' then
                    value=declaration.spaceID or (value~='world' and value~='map' and value or nil)
                end
                if point[key]==nil then point[key]=value end
            end
        end
    end
    return point
end
local function Distance(a,b)
    local z=a.z~=nil and b.z~=nil and b.z-a.z or 0
    return math.sqrt((b.x-a.x)^2+(b.y-a.y)^2+z*z)
end
local function SameCoordinate(a,b)
    -- One binary64 relative epsilon covers the two rounding operations in a
    -- percent roundtrip. No absolute floor/radius: zero and real offsets differ.
    return a==b or math.abs(a-b)<=2^-52*math.max(math.abs(a),math.abs(b))
end
local function Same(a,b)
    return a and b and a.world==b.world and SameCoordinate(a.x,b.x) and SameCoordinate(a.y,b.y)
        and (a.z==nil or b.z==nil or a.z==b.z)
end
local function SpatialCompatible(a,b)
    for _,k in ipairs({'space','floor','phase','accessKey'})do
        if a[k]~=nil and b[k]~=nil and a[k]~=b[k] then return false end
    end
    return true
end
local function Compatible(a,b)return a.world==b.world and SpatialCompatible(a,b)end
local function Inside(p,b)
    for _,axis in ipairs({'X','Y','Z'})do
        local lo,hi=b['min'..axis],b['max'..axis]
        if lo~=nil or hi~=nil then
            if not Finite(lo) or not Finite(hi) or lo>hi then return false end
            local v=p[axis:lower()]
            if v~=nil and (v<lo or v>hi) then return false end
        elseif axis~='Z' then return false end
    end
    return true
end
local function Requirements(...)
    local result={}
    for i=1,select('#',...)do
        local record=select(i,...)
        if record then
            local raw=record.requirements or {}
            Need(ns.NavigationV2Conditions.Compile(raw)~=nil,'invalid_conditions')
            for k,v in pairs(raw)do
                if k=='access' or k=='quests' then
                    local target=result[k] or {};result[k]=target
                    for _,fact in ipairs(raw[k])do
                        local field=k=='access' and 'key' or 'questID'
                        local found
                        for _,prior in ipairs(target)do
                            if prior[field]==fact[field] then
                                Need(prior[k=='access' and 'allowed' or 'completed']==fact[k=='access' and 'allowed' or 'completed'],'condition_conflict')
                                found=true
                            end
                        end
                        if not found then target[#target+1]=Copy(fact) end
                        Yield()
                    end
                else Need(result[k]==nil or result[k]==v,'condition_conflict');result[k]=v end
                Yield()
            end
        end
    end
    Need(ns.NavigationV2Conditions.Compile(result)~=nil,'invalid_conditions')
    return result
end
local function Gap(s,reason,id)
    if #s.gaps<256 then s.gaps[#s.gaps+1]={reason=reason,id=id} end
end
local function AddNode(s,id,p,requirements)
    Need(#s.graph.nodes<Limits.nodes and not s.positions[id],'node_limit_or_duplicate')
    s.graph.nodes[#s.graph.nodes+1]={id=id,requirements=requirements}
    s.positions[id]=p;s.metrics.preparedNodes=s.metrics.preparedNodes+1;Yield()
end
local function AddEdge(s,id,from,to,seconds,access,requirements,path,resources)
    Need(#s.graph.edges<Limits.edges and Finite(seconds) and seconds>=0,'edge_limit_or_cost')
    Need(access=='available' or access=='unknown' or access=='unavailable','invalid_access')
    s.graph.edges[#s.graph.edges+1]={id=id,from=from,to=to,seconds=seconds,access=access,requirements=requirements,resources=resources}
    s.geometry[id]=path;s.metrics.preparedEdges=s.metrics.preparedEdges+1;Yield()
end
local function Path(s,raw,world,reverse)
    local count=Array(raw,65536)
    local result,length={},0
    for i=1,count do
        Need(s.points<262144,'geometry_point_limit');s.points=s.points+1
        local p=Position(raw[reverse and count-i+1 or i],world);Need(p,'invalid_geometry_point')
        if result[#result] then length=length+Distance(result[#result],p) end
        result[#result+1]=p;Yield()
    end
    return result,length
end
local function Access(edge)
    if edge.disabled then return 'unavailable' end
    return edge.access or 'available'
end
local function SourceKey(world,id)return tostring(world)..':'..#id..':'..id end
local function NativeID(source,id)return 'terrain:'..source.ordinal..':'..id end
local function TerrainSources(s)
    if s.context.terrainStatus and s.context.terrainStatus~='ready' then
        s.refusal=s.context.terrainReason or s.context.terrainStatus;Gap(s,s.refusal);return
    end
    local registry=s.context.terrain or {}
    for world in pairs(s.worlds)do
        local entry=registry[world]
        for uid,registration in pairs(entry and entry.packs or {})do
            Need(#s.sources<128 and type(uid)=='string' and type(registration)=='table','terrain_source_limit')
            local data=registration.data
            Need(type(data)=='table' and data.format==1 and (data.worldID==nil or data.worldID==world)
                and (data.profile==nil or data.profile=='forever'),'invalid_terrain_registration')
            local source={uid=uid,world=world,data=data,registration=registration,owner=entry.packs,
                revision=registration.revision,ordinal=#s.sources+1,nodes={},neighbors={}}
            s.sources[#s.sources+1]=source;s.registry[SourceKey(world,uid)]=source
            s.versions[#s.versions+1]={id=uid,world=world,revision=registration.revision,build=data.build}
            for i=1,Array(data.neighborScopeIDs or {},128)do source.neighbors[data.neighborScopeIDs[i]]=true;Yield() end
            Yield()
        end
    end
end
local function TerrainNodes(s,source)
    for i=1,Array(source.data.nodes,Limits.nodes)do
        local node=source.data.nodes[i]
        Need(type(node)=='table' and type(node.id)=='string' and not source.nodes[node.id],'invalid_terrain_node')
        local p=Position(node,source.world);Need(p,'invalid_terrain_position')
        Spatial(p,source.data.scope,source.data)
        local id=NativeID(source,node.id)
        source.nodes[node.id]={id=id,point=p,raw=node}
        AddNode(s,id,p,Requirements(source.data,source.data.scope,node))
    end
end
local function Reference(s,source,ref,edge)
    local target,id=source,ref
    if type(ref)=='table' then
        target=s.registry[SourceKey(source.world,ref.pack)];id=ref.node
        if target and target~=source then
            local scope=target.data.scope and target.data.scope.id
            if edge.neighborScopeID~=scope or not source.neighbors[scope] then return nil end
        end
    end
    return target and target.nodes[id]
end
local function TerrainEdges(s,source)
    for i=1,Array(source.data.edges,Limits.edges)do
        local edge=source.data.edges[i]
        local a,b=Reference(s,source,edge.from,edge),Reference(s,source,edge.to,edge)
        if not a or not b then Gap(s,'terrain_reference_unavailable',source.uid..':'..i)
        elseif edge.mode~='ground' and edge.mode~='walk' then Gap(s,'terrain_mode_unsupported',source.uid..':'..i)
        else
            local path,length=Path(s,edge.polyline or {},source.world)
            local seconds=edge.seconds or (edge.length or length)/s.speed
            if edge.seconds==nil and edge.transitionSeconds~=nil then
                Need(Finite(edge.transitionSeconds) and edge.transitionSeconds>=0,'invalid_transition_seconds')
                seconds=seconds+edge.transitionSeconds
            end
            if #path<2 then
                Need(Same(a.point,b.point) and seconds==0 and (#path==0 or Same(path[1],a.point)),'terrain_polyline_endpoints')
                if #path==0 then path={a.point} end
            else Need(Same(path[1],a.point) and Same(path[#path],b.point),'terrain_polyline_endpoints') end
            local req=Requirements(source.data,source.data.scope,edge)
            local id='terrain-edge:'..source.ordinal..':'..i
            AddEdge(s,id,a.id,b.id,seconds,Access(edge),req,path)
            if edge.bidirectional==true then
                local reverse={};for j=#path,1,-1 do reverse[#reverse+1]=path[j];Yield() end
                AddEdge(s,id..':reverse',b.id,a.id,seconds,Access(edge),req,reverse)
            end
        end
        Yield()
    end
end
local function AnchorPath(s,source,anchor,node,direction)
    local raw=direction=='from' and anchor.path or anchor.reversePath
    local reverse=false
    if not raw and direction=='to' and anchor.bidirectional==true and anchor.path then raw=anchor.path;reverse=true end
    if not raw and not anchor.path and not anchor.reversePath and Inside(node.point,anchor)
        and not (direction=='to' and anchor.bidirectional==false) then return {node.point},node.point end
    if not raw then return nil end
    local path=Path(s,raw,source.world,reverse)
    Need(#path>0 and Same(direction=='from' and path[#path] or path[1],node.point),'anchor_path_endpoint')
    return path,direction=='from' and path[1] or path[#path]
end
local function Domain(q,anchor,center)
    q.domain=q.domain or {}
    for _,key in ipairs({'space','floor','phase','accessKey'})do
        if q.domain[key]~=nil and center[key]~=nil and q.domain[key]~=center[key] then q.ambiguous=true end
        if q.domain[key]==nil then q.domain[key]=center[key] end
    end
    if anchor.minZ then
        if q.domain.minZ then
            q.domain.minZ=math.max(q.domain.minZ,anchor.minZ);q.domain.maxZ=math.min(q.domain.maxZ,anchor.maxZ)
            if q.domain.minZ>q.domain.maxZ then q.ambiguous=true end
        else q.domain.minZ,q.domain.maxZ=anchor.minZ,anchor.maxZ end
    end
end
local function AnchorCandidates(s,q)
    for _,source in ipairs(s.sources)do
        if q.point.world==source.world then
            for i=1,Array(source.data.anchors or {},262144)do
                local anchor=source.data.anchors[i];local node=source.nodes[anchor.node]
                Need(node,'anchor_node_unavailable')
                if (anchor.mode==nil or anchor.mode=='ground' or anchor.mode=='walk') and Inside(q.point,anchor) then
                    for direction in pairs(q.directions)do
                        local path,center=AnchorPath(s,source,anchor,node,direction)
                        if center then center=Spatial(Position(center),anchor,source.data.scope,source.data) end
                        if path and Compatible(q.point,center) then
                            Need(#q.candidates<128,'connector_limit')
                            Domain(q,anchor,center)
                            q.candidates[#q.candidates+1]={node=node.id,path=path,direction=direction,center=center,
                                requirements=Requirements(source.data,source.data.scope,node.raw,anchor)}
                        end
                        Yield()
                    end
                end
                Yield()
            end
        end
    end
end
local function AnchorEdges(s,q)
    if q.ambiguous then if #q.candidates>0 then Gap(s,'anchor_ambiguous',q.id) end;return end
    for i,candidate in ipairs(q.candidates)do
        local path={};local entry=Position(q.point)
        -- Technical geometry follows the declared entry; the captured input Z stays nil.
        if entry.z==nil then entry.z=candidate.center.z end
        if candidate.direction=='from' then path[1]=entry end
        for _,p in ipairs(candidate.path)do path[#path+1]=p;Yield() end
        if candidate.direction=='to' then path[#path+1]=entry end
        local length=0;for j=2,#path do length=length+Distance(path[j-1],path[j]);Yield() end
        AddEdge(s,'anchor:'..q.id..':'..i,candidate.direction=='from' and q.id or candidate.node,
            candidate.direction=='from' and candidate.node or q.id,length/s.speed,'available',candidate.requirements,path)
    end
end
local function CaptureQueries(s)
    for i,point in ipairs(s.request.points)do
        local id='query:'..i
        local q={id=id,point=point,candidates={},directions={}}
        Domain(q,{},point)
        if i<#s.request.points then q.directions.from=true end
        if i>1 then q.directions.to=true end
        s.queries[#s.queries+1]=q;s.worlds[point.world]=true
        AddNode(s,id,point,nil)
    end
    local via={};for i=2,#s.queries-1 do via[#via+1]=s.queries[i].id end
    s.objective={from=s.queries[1].id,to=s.queries[#s.queries].id,via=via}
end
local function Conjunction(a,b)
    if a=='unavailable' or b=='unavailable' then return 'unavailable' end
    if a=='unknown' or b=='unknown' then return 'unknown' end
    return 'available'
end
local function ActorPredicate(actor,key,expected)
    local field=key
    if key=='minLevel' or key=='maxLevel' or key=='level' then field='level' end
    local actual=actor and actor[field]
    if actual==nil then return 'unknown' end
    if key=='faction' or key=='class' then
        if type(actual)~='string' or type(expected)~='string' then return 'unknown' end
        actual,expected=actual:lower(),expected:lower()
    elseif key=='minLevel' or key=='level' then
        if not Finite(actual) or not Finite(expected) then return 'unknown' end
        return actual>=expected and 'available' or 'unavailable'
    elseif key=='maxLevel' then
        if not Finite(actual) or not Finite(expected) then return 'unknown' end
        return actual<=expected and 'available' or 'unavailable'
    end
    return actual==expected and 'available' or 'unavailable'
end
local function ConnectionRequirements(s,raw,id)
    local req,access,quest={},'available',nil
    if raw~=nil and type(raw)~='table' then Gap(s,'transport_condition_invalid',id);return {},'unknown' end
    for key,value in pairs(raw or {})do
        if key=='faction' or key=='class' or key=='raceID' or key=='minLevel' or key=='maxLevel' or key=='level' or key=='inGroup' then
            access=Conjunction(access,ActorPredicate(s.context.actor,key,value))
        elseif key=='quest' and Finite(value) and value>0 and value%1==0 then
            quest=value
            if type(((s.context.conditionObservation or {}).quests or {})[value])~='boolean' then s.observationRequests.quests[value]=true end
        elseif key=='quests' or key=='access' or key=='world' or key=='space' or key=='floor'
            or key=='phase' and type(value)~='table' then
            req[key]=Copy(value)
            if key=='quests' or key=='access' then
                for _,fact in ipairs(type(value)=='table' and value or {})do
                    if type(fact)=='table' then
                        if key=='quests' and type(fact.questID)=='number' then
                            if type(((s.context.conditionObservation or {}).quests or {})[fact.questID])~='boolean' then s.observationRequests.quests[fact.questID]=true end
                        elseif key=='access' and type(fact.key)=='string' then
                            if type(((s.context.conditionObservation or {}).access or {})[fact.key])~='boolean' then s.observationRequests.access[fact.key]={field='access',value=fact.key} end
                        end
                    end
                end
            end
        else access=Conjunction(access,'unknown');Gap(s,'transport_condition_unrepresented',id) end
        Yield()
    end
    if quest then req.quests=req.quests or {};req.quests[#req.quests+1]={questID=quest,completed=true} end
    if not ns.NavigationV2Conditions.Compile(req) then
        access=Conjunction(access,'unknown');req={};Gap(s,'transport_condition_invalid',id)
    end
    return req,access
end
local function FixedCost(record,config)
    local seconds=record.seconds
    local source='declared_seconds_plus_wait'
    if seconds==nil and record.kind=='portal' then seconds=config.actionLoadingSeconds;source='declared_loading_estimate_plus_wait' end
    local wait=record.waitSeconds
    if wait==nil then wait=0 end
    if not Finite(seconds) or seconds<0 or not Finite(wait) or wait<0 then return nil end
    return seconds+wait,source
end
local function ConnectionPosition(s,record,side)
    local raw=record[side]
    if type(raw)=='table' and raw.dynamic~=nil then return nil end
    local p=Position(raw)
    if p then return p end
    local captured=s.context.connectionPositions and s.context.connectionPositions[record.id]
    p=captured and Position(captured[side])
    if p and type(raw)=='table' then
        if raw.instanceID~=nil and raw.instanceID~=p.world or raw.world~=nil and raw.world~=p.world then return nil end
        for _,key in ipairs({'accessKey','floor','phase','uiMapID'})do
            if raw[key]~=nil then
                if p[key]~=nil and p[key]~=raw[key] then return nil end
                p[key]=raw[key]
            end
        end
    end
    return p
end
local function TransitionPoint(s,id,point,direction,reverse,requirements)
    local q={id=id,point=point,candidates={},directions={[direction]=true},declaredArrival=direction=='from' or reverse==true}
    Domain(q,{},point)
    if reverse then q.directions.from,q.directions.to=true,true end
    s.queries[#s.queries+1]=q;s.worlds[point.world]=true
    AddNode(s,id,point,requirements)
end
local function ActionKey(a)
    if type(a)=='table' and (a.type=='spell' or a.type=='item') and Finite(a.id) and a.id>0 and a.id%1==0 then
        return a.type..':'..a.id
    end
end
local function SuppliedAction(s,a,key)
    local o=s.context.personalObservation or {}
    local origin=o.origin or {}
    local fact=(o.actions or {})[key] or {}
    if type(fact)~='table' then return false end
    if fact.known==false or fact.owned==false or fact.loaded==false or fact.usable==false then return true end
    if o.loading==true or o.combat==true or o.casting==true then return true end
    if origin.reliable==false then return true end
    local policy=(s.context.actionPolicies or {})[key] or {}
    if type(policy)~='table' then return false end
    local function Seconds(v)return Finite(v) and v>=0 end
    local config=s.connectionConfig or {}
    local use=fact.castSeconds or a.castSeconds or config[a.type=='spell' and 'defaultSpellCastSeconds' or 'defaultItemCastSeconds']
    local charge=policy.chargeBased;if a.chargeBased~=nil then charge=a.chargeBased end
    if origin.reliable~=true or origin.node~=s.objective.from
        or o.loading~=false or o.combat~=false or o.casting~=false or fact.loaded~=true or fact.usable~=true
        or fact[a.type=='spell' and 'known' or 'owned']~=true or not Seconds(o.observedAt) or not Seconds(fact.readyAt)
        or not Seconds(use) or not Seconds(policy.loadingSeconds or config.actionLoadingSeconds)
        or not Seconds(policy.cooldownSeconds or a.cooldownSeconds) or type(charge)~='boolean' then return false end
    if charge and (not Seconds(fact.charges) or not Seconds(fact.maxCharges)) then return false end
    if a.consumable and not Seconds((o.items or {})[a.id]) then return false end
    if a.reagentID and not Seconds((o.items or {})[a.reagentID]) then return false end
    for _,r in pairs(type(policy.reagents)=='table' and policy.reagents or {})do
        if type(r)~='table' or not Seconds((o.items or {})[r.itemID]) then return false end
    end
    return true
end
local function PersonalActions(record)
    local actions={}
    for i=1,Array(record.actions or {},64)do
        local a=record.actions[i];actions[#actions+1]=a
        if type(a)=='table' and a.type=='spell' and Finite(a.groupSpellID) and a.groupSpellID>0 and a.groupSpellID%1==0 then
            actions[#actions+1]={type='spell',id=a.groupSpellID,reagentID=a.groupReagentID,
                reagentCount=a.groupReagentCount,requirements=a.requirements,groupOnly=true}
        end
        Yield()
    end
    return actions
end
local function SuppliedDynamic(observed)
    if type(observed)~='table' then return false end
    if observed.reliable==false then return true end
    return observed.reliable==true and (Position(observed.position)~=nil
        or Finite(observed.areaID) and observed.areaID>0 and observed.areaID%1==0)
end
local function CollectPersonal(s,record,index)
    if type(record.to)~='table' or type(record.from)~='table' then Gap(s,'personal_declaration_unknown',record.id);return end
    local actions=PersonalActions(record)
    s.pendingPersonal[#s.pendingPersonal+1]={record=record,actions=actions,index=index}
    local dynamic=(s.context.dynamicPositions or {})[record.to.dynamic]
    if record.to.dynamic and not SuppliedDynamic(dynamic) then
        s.observationRequests.dynamic[record.to.dynamic]={kind=record.to.dynamic}
    end
    ConnectionRequirements(s,record.requirements,record.id)
    ConnectionRequirements(s,record.from.requirements,record.id)
    ConnectionRequirements(s,record.to.requirements,record.id)
    for _,a in ipairs(actions)do
        local key=ActionKey(a)
        if key then
            local previous=s.observationRequests.actions[key] or {}
            local chargeBased=previous.chargeBased
            if chargeBased~=true and a.chargeBased~=nil then chargeBased=a.chargeBased end
            if not SuppliedAction(s,a,key) then s.observationRequests.actions[key]={id=key,kind=a.type,spellID=a.type=='spell' and a.id or nil,
                itemID=a.type=='item' and a.id or nil,useSpellID=a.useSpellID or previous.useSpellID,
                reagentID=a.reagentID or previous.reagentID,chargeBased=chargeBased,
                requirements=a.requirements,connectionRequirements=record.requirements} end
            ConnectionRequirements(s,a.requirements,record.id)
        else Gap(s,'personal_action_unknown',record.id) end
        Yield()
    end
end
local function Guidance(record,action)
    local hint={kind=record.kind}
    if type(record.id)=='string' then hint.connectionID=record.id end
    if type(record.instruction)=='string' then hint.instruction=record.instruction end
    if type(record.from)=='table' and record.from.dynamic=='player' then hint.sourceFree=true end
    for _,key in ipairs({'arrivalRange','arrivalZTolerance'})do
        local value=record[key]
        if Finite(value) and value>=0 then hint[key]=value end
    end
    if action then hint.action={type=action.type,id=action.id} end
    return hint
end
local function Connections(s)
    local owner=s.context.data
    local records,config=s.context.connections,s.context.config
    s.connectionOwner=owner
    if not records and owner and type(owner.GetConnections)=='function' then
        local ok,value=pcall(owner.GetConnections,owner)
        if ok then records=value;s.connectionsFromOwner=true else Gap(s,'connection_data_unavailable') end
    end
    if not config and owner and type(owner.GetConfig)=='function' then
        local ok,value=pcall(owner.GetConfig,owner)
        if ok then config=value;s.configFromOwner=true else Gap(s,'connection_config_unavailable') end
    end
    s.connectionRecords,s.connectionConfig=records,config
    config=config or {}
    for i=1,Array(records or {},256)do
        local record=records[i]
        local kind=record.kind
        if kind=='portal' or kind=='passage' or kind=='boat' or kind=='zeppelin' or kind=='tram' or kind=='elevator' then
            local from,to=ConnectionPosition(s,record,'from'),ConnectionPosition(s,record,'to')
            local seconds,costSource=FixedCost(record,config)
            if not from or not to then Gap(s,'transport_position_unavailable',record.id)
            elseif not seconds then Gap(s,'transport_cost_unknown',record.id)
            elseif record.points~=nil and (type(record.points)~='table' or next(record.points)~=nil)
                or record.via~=nil and (type(record.via)~='table' or next(record.via)~=nil)
                or record.schedule~=nil then Gap(s,'transport_shape_or_schedule_unresolved',record.id)
            else
                local req,access=ConnectionRequirements(s,record.requirements,record.id)
                local fromReq,fromAccess=ConnectionRequirements(s,record.from and record.from.requirements,record.id)
                local toReq,toAccess=ConnectionRequirements(s,record.to and record.to.requirements,record.id)
                access=Conjunction(Access(record),Conjunction(access,Conjunction(fromAccess,toAccess)))
                req=Requirements({requirements=req},{requirements=fromReq},{requirements=toReq})
                local a,b='transition:'..i..':from','transition:'..i..':to'
                TransitionPoint(s,a,from,'to',record.bidirectional==true,fromReq)
                TransitionPoint(s,b,to,'from',record.bidirectional==true,toReq)
                local id='transition-edge:'..i
                AddEdge(s,id,a,b,seconds,access,req,{from,to})
                local hint=Guidance(record);s.guidance[id]=hint
                if record.bidirectional==true then
                    AddEdge(s,id..':reverse',b,a,seconds,access,req,{to,from});s.guidance[id..':reverse']=hint
                end
                s.metrics.preparedTransitions=s.metrics.preparedTransitions+1
                s.transitions[#s.transitions+1]={edgeId=id,id=record.id,kind=kind,seconds=seconds,costSource=costSource,
                    bidirectional=record.bidirectional,requirements=Copy(record.requirements or {}),from=from,to=to}
            end
        elseif kind=='spell' or kind=='item' then
            CollectPersonal(s,record,i)
        else Gap(s,'transport_kind_not_fixed',record.id) end
        Yield()
    end
end
local function BindingData(s)
    local bindings=s.context.bindings
    if not bindings and s.connectionOwner and type(s.connectionOwner.GetBindings)=='function' then
        local ok,value=pcall(s.connectionOwner.GetBindings,s.connectionOwner)
        if ok then bindings=value;s.bindingsFromOwner=true end
    end
    s.bindingRecords=bindings
    if bindings~=nil and type(bindings)~='table' then Gap(s,'binding_data_unavailable');return {} end
    return bindings or {}
end
local function PersonalDestination(s,c,bindings)
    if not c.to.dynamic then return ConnectionPosition(s,c,'to') end
    local observed=(s.context.dynamicPositions or {})[c.to.dynamic]
    if type(observed)~='table' or observed.reliable~=true then return nil end
    if observed.position then return Position(observed.position) end
    if c.to.dynamic=='bind' and Finite(observed.areaID) and observed.areaID>0 and observed.areaID%1==0 then
        local raw=bindings[observed.areaID]
        -- Arrays/candidate sets are intentionally not resolved by first entry.
        if type(raw)=='table' and (raw.areaID==nil or raw.areaID==observed.areaID) then return Position(raw) end
    end
end
local function PersonalPoints(s)
    local bindings=BindingData(s)
    for _,work in ipairs(s.pendingPersonal)do
        local c=work.record
        local point=PersonalDestination(s,c,bindings)
        local from=c.from.dynamic=='player' and false or ConnectionPosition(s,c,'from')
        if not point or c.from.dynamic~='player' and not from then Gap(s,'personal_position_unobserved',c.id)
        else
            work.to='personal:'..work.index..':to'
            TransitionPoint(s,work.to,point,'from',false)
            if from then
                work.from='personal:'..work.index..':from';TransitionPoint(s,work.from,from,'to',false)
            end
        end
        Yield()
    end
end
local function Seconds(v)return Finite(v) and v>=0 end
local function Quantity(v)return Seconds(v) and v%1==0 end
local function PersonalReagents(s,a,policy,id)
    local reagents,count={},0
    if policy.reagents~=nil and type(policy.reagents)~='table' then return nil end
    if a.reagentCount~=nil and (not Quantity(a.reagentCount) or a.reagentCount<1)
        or policy.reagentCount~=nil and (not Quantity(policy.reagentCount) or policy.reagentCount<1) then
        Gap(s,'reagent_quantity_unknown',id);return nil
    end
    for name,r in pairs(policy.reagents or {})do
        count=count+1;if count>64 then return nil end
        if type(name)~='string' or type(r)~='table' or not Quantity(r.itemID) or r.itemID<1 or not Quantity(r.count) or r.count<1 then return nil end
        local key='forever-item-'..r.itemID
        local total=(reagents[key] and reagents[key].count or 0)+r.count
        if not Quantity(total) then return nil end
        reagents[key]={itemID=r.itemID,count=total};Yield()
    end
    if a.reagentID~=nil then
        if not Quantity(a.reagentID) or a.reagentID<1 then return nil end
        local key='forever-item-'..a.reagentID
        if not reagents[key] then
            -- Legacy simple reagentID/groupReagentID already declares one unit.
            -- Typed policies above still require their explicit count.
            local count=a.reagentCount or policy.reagentCount or 1
            reagents[key]={itemID=a.reagentID,count=count}
        end
    end
    return reagents
end
local function PersonalPolicy(s,work,a)
    local c,key=work.record,ActionKey(a)
    if not key then return end
    local observation=s.context.personalObservation or {}
    local fact=(observation.actions or {})[key]
    if type(fact)~='table' then fact={} end
    local policy=(s.context.actionPolicies or {})[key]
    if type(policy)~='table' then policy={} end
    local use=fact.castSeconds
    if use==nil then use=a.castSeconds end
    if use==nil then use=(s.connectionConfig or {})[a.type=='spell' and 'defaultSpellCastSeconds' or 'defaultItemCastSeconds'] end
    local load=policy.loadingSeconds
    if load==nil then load=(s.connectionConfig or {}).actionLoadingSeconds end
    local period=policy.cooldownSeconds
    if period==nil then period=a.cooldownSeconds end
    if period==nil then period=c.cooldownSeconds end
    local charged=policy.chargeBased
    if a.chargeBased~=nil then charged=a.chargeBased end
    local reagents=PersonalReagents(s,a,policy,c.id)
    -- Legacy personal seconds is a pathfinding weight. The public data contract
    -- derives personal duration from cast plus loading, unlike fixed portals.
    local total
    if Seconds(use) and Seconds(load) then total=use+load end
    local exact=Seconds(use) and Seconds(load) and Seconds(period) and type(charged)=='boolean' and reagents~=nil
    if charged and (not Quantity(fact.charges) or not Quantity(fact.maxCharges) or fact.charges>fact.maxCharges) then exact=false end
    if charged and a.type~='spell' or a.consumable~=nil and type(a.consumable)~='boolean'
        or a.rare~=nil and type(a.rare)~='boolean' or a.moneyCopper~=nil and not Quantity(a.moneyCopper) then exact=false end
    local destination=s.positions[work.to]
    local space=destination.space or destination.accessKey
    if space~=nil and (type(space)~='string' or space=='') or destination.phase~=nil
        and (type(destination.phase)~='string' or destination.phase=='') then exact=false end
    local origin=observation.origin or {}
    if origin.reliable~=true or origin.node~=s.objective.from then exact=false;Gap(s,'personal_origin_unobserved',c.id) end
    if not exact then Gap(s,'personal_policy_unknown',c.id) end
    local group=c.cooldownGroup or ('forever-action:'..key)
    if type(group)~='string' or group=='' then exact=false;group='forever-action:'..key end
    return {record=c,action=a,key=key,fact=fact,exact=exact,use=use,load=load,period=period,
        charged=charged,reagents=reagents or {},resourceKnown=reagents~=nil,total=total,group=group}
end
local function SharedGroup(aliases,group)
    while aliases[group]do group=aliases[group];Yield() end
    return group
end
local function SingleUseAccess(s,policy)
    local o=s.context.personalObservation or {}
    local fact,a=policy.fact,policy.action
    if fact[a.type=='spell' and 'known' or 'owned']==false or fact.loaded==false or fact.usable==false
        or o.combat==true or o.casting==true or a.rare==true and o.allowRare~=true then return 'unavailable' end
    local origin=o.origin or {}
    if origin.reliable~=true or origin.node~=s.objective.from or o.loading~=false or o.combat~=false or o.casting~=false
        or fact.loaded~=true or fact.usable~=true or fact[a.type=='spell' and 'known' or 'owned']~=true
        or not Seconds(o.observedAt) or not Seconds(fact.readyAt) or fact.readyAt>o.observedAt
        or not Seconds(policy.total) or not policy.resourceKnown then return 'unknown' end
    if policy.charged==true and (not Quantity(fact.charges) or fact.charges<1) or fact.charges==0 then return 'unknown' end
    if a.moneyCopper~=nil and not Quantity(a.moneyCopper) or a.consumable~=nil and type(a.consumable)~='boolean'
        or a.rare~=nil and type(a.rare)~='boolean' then return 'unknown' end
    return 'available'
end
local function SingleUseResources(s,policy)
    local result,o={},s.context.personalObservation or {}
    local token='forever-use:'..policy.group
    s.balances[token]=1;result[token]=1
    local function Item(id,count)
        local key='item:forever-item-'..id
        local observed=(o.items or {})[id]
        if Quantity(observed) then s.balances[key]=observed end
        result[key]=(result[key] or 0)+count
    end
    if policy.action.consumable then Item(policy.action.id,1) end
    for _,r in pairs(policy.reagents)do Item(r.itemID,r.count);Yield() end
    local money=policy.action.moneyCopper
    if Quantity(money) and money>0 then
        result.money=money;if Quantity(o.moneyCopper) then s.balances.money=o.moneyCopper end
    end
    return result
end
local function PersonalEdges(s)
    local models,aliases,actions,static={},{},{},{}
    for _,work in ipairs(s.pendingPersonal)do
        work.policies={}
        if work.to then
            for index,a in ipairs(work.actions)do
                local policy=PersonalPolicy(s,work,a);work.policies[index]=policy
                if policy then
                    policy.guidance=Guidance(work.record,a)
                    local root=SharedGroup(aliases,policy.group)
                    if actions[policy.key] then
                        local other=SharedGroup(aliases,actions[policy.key])
                        if other~=root then
                            if other<root then aliases[root]=other else aliases[other]=root end
                        end
                    else actions[policy.key]=policy.group end
                    local prior=models[policy.key]
                    if prior and (prior.group~=policy.group or prior.period~=policy.period or prior.charged~=policy.charged) then prior.conflict=true
                    elseif not prior then models[policy.key]=policy end
                end
                Yield()
            end
        end
    end
    for _,work in ipairs(s.pendingPersonal)do
        for _,policy in pairs(work.policies)do
            policy.group=SharedGroup(aliases,policy.group)
            if not policy.exact or models[policy.key].conflict then static[policy.group]=true end
            Yield()
        end
    end
    for _,work in ipairs(s.pendingPersonal)do
        if work.to then
            for actionIndex,a in ipairs(work.actions)do
                local policy=work.policies[actionIndex]
                if policy then
                    if static[policy.group] then Gap(s,'personal_shared_single_use',work.record.id) end
                    for _,node in ipairs(s.graph.nodes)do
                        if not work.from or work.from==node.id then
                            local req,access=ConnectionRequirements(s,work.record.requirements,work.record.id)
                            access=Conjunction(access,Access(work.record))
                            local aReq,aAccess=ConnectionRequirements(s,a.requirements,work.record.id)
                            access=Conjunction(access,aAccess)
                            local fromReq,fromAccess=ConnectionRequirements(s,work.record.from.requirements,work.record.id)
                            local toReq,toAccess=ConnectionRequirements(s,work.record.to.requirements,work.record.id)
                            access=Conjunction(access,Conjunction(fromAccess,toAccess))
                            if a.groupOnly then access=Conjunction(access,ActorPredicate(s.context.actor,'inGroup',true)) end
                            req=Requirements({requirements=req},{requirements=aReq},{requirements=fromReq},{requirements=toReq})
                            local id='forever-personal:'..work.index..':'..actionIndex..':'..node.id
                            if static[policy.group] then
                                access=Conjunction(access,SingleUseAccess(s,policy))
                                local resources=access=='available' and SingleUseResources(s,policy) or nil
                                AddEdge(s,id,node.id,work.to,Seconds(policy.total) and policy.total or 0,access,req,nil,resources)
                                s.guidance[id]=policy.guidance
                            elseif access~='available' then
                                AddEdge(s,id,node.id,work.to,policy.use+policy.load,access,req)
                                s.guidance[id]=policy.guidance
                            elseif #s.personal<256 then
                                local point=s.positions[work.to]
                                s.personal[#s.personal+1]={id=id,from=node.id,to=work.to,kind=a.type,
                                    spellID=a.type=='spell' and a.id or nil,itemID=a.type=='item' and a.id or nil,
                                    destination={space=point.space or point.accessKey or ('world:'..point.world),phase=point.phase},
                                    useSeconds=policy.use,loadingSeconds=policy.load,cooldownSeconds=policy.period,timeoutSeconds=120,
                                    chargeBased=policy.charged,cooldownGroup=policy.group,reagents=policy.reagents,
                                    consumable=a.consumable,rare=a.rare,itemResourceId='forever-item-'..a.id,moneyCopper=a.moneyCopper,
                                    requirements=req}
                                s.personalFacts[id]=policy.fact
                                s.guidance[id]=policy.guidance
                                s.guidance['personal:'..id]=policy.guidance
                            else Gap(s,'personal_action_limit',work.record.id) end
                            Yield()
                        end
                    end
                end
            end
        end
    end
end
local function DeclaredGoalAliases(s)
    local goal=s.queries[#s.request.points]
    if goal.point.z~=nil then return end
    local arrivals={}
    for _,q in ipairs(s.queries)do
        if q.declaredArrival and Compatible(q.point,goal.point) and Same(q.point,goal.point) then
            arrivals[#arrivals+1]=q
            -- These are alternative authored destination domains, regardless of
            -- which action is currently usable. None is current-player proof.
            if q.ambiguous then goal.ambiguous=true end
            Domain(goal,q.domain,q.domain)
            Domain(goal,{minZ=q.point.z,maxZ=q.point.z},q.point)
            if q.point.z~=nil then goal.declaredGoalZ=q.point.z end
        end
        Yield()
    end
    if goal.ambiguous then Gap(s,'declared_goal_ambiguous',goal.id);return end
    for _,q in ipairs(arrivals)do
        if q.point.z~=nil then
            AddEdge(s,'declared-goal-alias:'..q.id,q.id,goal.id,0,'available',nil,{q.point,goal.point})
        end
        Yield()
    end
end
local function PointAliases(s)
    for i,a in ipairs(s.queries)do
        for j,b in ipairs(s.queries)do
            local knownZ=a.point.z~=nil and b.point.z~=nil or a.point.z==nil and b.point.z==nil
            local sameIdentity=a.point.floor==b.point.floor and a.point.phase==b.point.phase
            if i~=j and a.directions.from and b.directions.to and knownZ and sameIdentity
                and not (b.declaredGoalZ~=nil and a.point.z==nil)
                and not a.ambiguous and not b.ambiguous and SpatialCompatible(a.domain,b.domain)
                and Compatible(a.point,b.point) and Same(a.point,b.point) then
                AddEdge(s,'point-alias:'..i..':'..j,a.id,b.id,0,'available',nil,{a.point,b.point})
            end
            Yield()
        end
    end
end
local function RoadSources(s)
    local data=s.context.roads
    local owner=s.context.data
    if not data and owner and type(owner.GetRoadData)=='function' then
        local ok,value=pcall(owner.GetRoadData,owner)
        if ok then data=value else Gap(s,'road_data_unavailable') end
    end
    s.roadData=data or {networks={},collision={}}
    s.roadOwner=owner
    if owner and type(owner.GetRoadRevision)=='function' then
        local ok,value=pcall(owner.GetRoadRevision,owner)
        if not ok then Stop('unknown','road_revision_unavailable') end
        s.roadRevision=value
    end
    for id,network in pairs(s.roadData.networks or {})do
        if s.worlds[network.instanceID] then
            Need(#s.roads<128 and type(id)=='string','road_source_limit')
            local r={id=id,world=network.instanceID,data=network,nodes={},ordinal=#s.roads+1,legs={}}
            s.roads[#s.roads+1]=r
            s.versions[#s.versions+1]={id=id,world=r.world,revision=s.roadRevision,kind='roads'}
            Yield()
        end
    end
end
local function RoadNodes(s,source)
    for sectionIndex=1,Array(source.data.sections,4096)do
        local section=source.data.sections[sectionIndex]
        for i=1,Array(section.nodes,Limits.nodes)do
            local node=section.nodes[i]
            Need(type(node.id)=='string' and not source.nodes[node.id],'invalid_road_node')
            local p=Position(node,source.world);Need(p,'invalid_road_position')
            Spatial(p,section,source.data)
            local id='road:'..source.ordinal..':'..node.id
            source.nodes[node.id]={id=id,point=p,raw=node}
            AddNode(s,id,p,Requirements(source.data,section,node))
        end
    end
end
local function RoadCost(s,edge,length)
    if edge.kind=='swim' then
        if not Finite(s.context.swimSpeed) or s.context.swimSpeed<=0 then return nil,'swim_cost_unknown' end
        return (edge.costDistance or length)/s.context.swimSpeed
    end
    return edge.seconds or (edge.costDistance or length)/s.speed
end
local function RoadAccess(s,edge)
    local access=Access(edge)
    if edge.dropHeight~=nil and access=='available' then
        Need(Finite(edge.dropHeight) and edge.dropHeight>=0,'invalid_drop_height')
        if not Finite(s.context.safeDropHeight) then return 'unknown' end
        if edge.dropHeight>s.context.safeDropHeight then return 'unavailable' end
    end
    return access
end
local function RoadEdges(s,source)
    for sectionIndex,section in ipairs(source.data.sections)do
        local joins={}
        for i=1,Array(section.joins or {},Limits.nodes)do joins[section.joins[i]]=true;Yield() end
        for i=1,Array(section.edges,Limits.edges)do
            local raw=section.edges[i]
            Need(raw.kind==nil or raw.kind=='road' or raw.kind=='stairs' or raw.kind=='elevator' or raw.kind=='swim','invalid_road_kind')
            local a,b=source.nodes[raw.from],source.nodes[raw.to]
            Need(a and b,'road_reference_unavailable')
            local path,length=Path(s,raw.points,source.world)
            Need(#path>=2 and Same(a.point,path[1]) and Same(b.point,path[#path]),'road_polyline_endpoints')
            local shared={}
            for _,key in ipairs({'space','floor','phase','accessKey'})do
                if a.point[key]==b.point[key] then shared[key]=a.point[key] end
            end
            Spatial(path[1],a.point);Spatial(path[#path],b.point)
            for j=2,#path-1 do Spatial(path[j],shared);Yield() end
            local seconds,reason=RoadCost(s,raw,length)
            if not seconds then Gap(s,reason,raw.id)
            else
                local req=Requirements(source.data,section,raw)
                local access=RoadAccess(s,raw)
                local prefix='road-edge:'..source.ordinal..':'..sectionIndex..':'..i
                local from=a.id;local allocated=0
                for j=2,#path do
                    local to=j==#path and b.id or prefix..':point:'..j
                    if j<#path then AddNode(s,to,path[j],req) end
                    local cost=j==#path and seconds-allocated or (length>0 and seconds*Distance(path[j-1],path[j])/length or 0)
                    allocated=allocated+cost
                    local leg={id=prefix..':'..j,from=from,to=to,a=path[j-1],b=path[j],seconds=cost,
                        access=access,requirements=req,source=source,
                        reverse=raw.bidirectional~=false and raw.dropHeight==nil,
                        restricted=section.kind=='building' or section.kind=='cave',
                        fromRaw=j==2 and a.raw or nil,toRaw=j==#path and b.raw or nil,
                        fromJoin=j==2 and joins[raw.from],toJoin=j==#path and joins[raw.to]}
                    AddEdge(s,leg.id,from,to,cost,access,req,{leg.a,leg.b})
                    if leg.reverse then AddEdge(s,leg.id..':reverse',to,from,cost,access,req,{leg.b,leg.a}) end
                    source.legs[#source.legs+1]=leg;from=to
                end
            end
            Yield()
        end
    end
end
local function Child(s,job)
    s.job.child=job
    while true do
        local result=job:Step(1,s.job.budgets.sliceMs)
        s.metrics.collisionSteps=s.metrics.collisionSteps+1;Yield()
        if result.status~='running' then
            s.job.child=nil
            if result.status=='budget_exceeded' then Stop('budget_exceeded',result.reason) end
            return result
        end
    end
end
local function CollisionSource(s,source)
    if source.collision~=nil then return source.collision or nil end
    source.collision=false
    local network=source.data
    if #(network.walls or {})>0 or #(network.openings or {})>0 then Gap(s,'road_geometry_unresolved',source.id);return end
    local binding=network.collision
    local masks=s.roadData.collision or {}
    if not binding or not masks[binding.base] or not ns.NavigationV2RoadCollision then Gap(s,'road_collision_unavailable',source.id);return end
    local overlays={}
    for i=1,Array(binding.overlays or {},511)do
        local mask=masks[binding.overlays[i]]
        if not mask then Gap(s,'road_collision_unavailable',binding.overlays[i]);return end
        overlays[#overlays+1]=mask;Yield()
    end
    local clock=s.job.clock
    local reader,reason=ns.NavigationV2RoadCollision.New({worldID=source.world,base=masks[binding.base],overlays=overlays,walls={}},
        {clock=function()return clock()/1000 end,profileClock=clock,
            sliceMs=s.job.budgets.sliceMs,cpuMs=s.job.budgets.cpuMs-s.metrics.cpuMs,
            elapsedMs=s.job.budgets.elapsedMs-s.metrics.elapsedMs})
    if not reader then Gap(s,reason,source.id);return end
    local result=Child(s,reader)
    if result.status~='ready' then Gap(s,result.reason or result.status,source.id);return end
    if s.collisionOwner and s.collisionOwner~=source then s.collisionOwner.collision=nil end
    s.collisionOwner=source
    source.collision=reader;return reader
end
local function ScopeCrosses(a,b,bounds)
    local first,last=0,1
    for _,axis in ipairs({'x','y'})do
        local lo,hi=bounds['min'..axis:upper()],bounds['max'..axis:upper()]
        if not Finite(lo) or not Finite(hi) then return true end
        local delta=b[axis]-a[axis]
        if delta==0 then if a[axis]<=lo or a[axis]>=hi then return false end
        else
            local x,y=(lo-a[axis])/delta,(hi-a[axis])/delta
            if x>y then x,y=y,x end
            first,last=math.max(first,x),math.min(last,y)
            if first>=last then return false end
        end
    end
    return first<last
end
local function CollisionPoint(p)
    return {x=p.x,y=p.y,z=p.z,worldID=p.world,space=p.space,floor=p.floor,phase=p.phase}
end
local function CanConnect(s,source,a,b)
    if a.noAutoconnect or b.noAutoconnect or not Compatible(a,b) then return false end
    for _,terrain in ipairs(s.sources)do
        local scope=terrain.data.scope
        if terrain.world==a.world and scope and scope.bounds and ScopeCrosses(a,b,scope.bounds) then
            Gap(s,'terrain_scope_requires_declared_connection',source.id);return false
        end
        Yield()
    end
    local reader=CollisionSource(s,source)
    if not reader then return false end
    local query,reason=reader:Query({from=CollisionPoint(a),to=CollisionPoint(b),mode='walk'})
    if not query then Gap(s,reason,source.id);return false end
    s.metrics.collisionQueries=s.metrics.collisionQueries+1
    local result=Child(s,query)
    if result.status~='complete' then Gap(s,result.reason or result.status,source.id);return false end
    return true
end
local function Projection(p,leg)
    local dx,dy=leg.b.x-leg.a.x,leg.b.y-leg.a.y
    local squared=dx*dx+dy*dy
    local t=squared>0 and math.max(0,math.min(1,((p.x-leg.a.x)*dx+(p.y-leg.a.y)*dy)/squared)) or 0
    local q={world=leg.a.world,x=leg.a.x+dx*t,y=leg.a.y+dy*t,uiMapID=leg.a.uiMapID}
    if leg.a.z~=nil and leg.b.z~=nil then q.z=leg.a.z+(leg.b.z-leg.a.z)*t end
    for _,key in ipairs({'space','floor','phase','accessKey'})do
        if t==0 then q[key]=leg.a[key]
        elseif t==1 then q[key]=leg.b[key]
        elseif leg.a[key]==leg.b[key] then q[key]=leg.a[key] end
    end
    return q,t
end
local function ProjectionEdges(s,q,leg,point,t)
    local id='projection:'..q.id..':'..leg.id
    local req=Requirements({requirements=leg.requirements},t==0 and leg.fromRaw or t==1 and leg.toRaw or nil)
    AddNode(s,id,point,req)
    leg.attachments=leg.attachments or {{id=leg.from,t=0,point=leg.a},{id=leg.to,t=1,point=leg.b}}
    local current={id=id,t=t,point=point}
    for i,prior in ipairs(leg.attachments)do
        local a,b=prior,current
        if a.t>b.t then a,b=b,a end
        local cost=leg.seconds*(b.t-a.t)
        AddEdge(s,id..':join:'..i,a.id,b.id,cost,leg.access,leg.requirements,{a.point,b.point})
        if leg.reverse or a.t==b.t then
            AddEdge(s,id..':join-reverse:'..i,b.id,a.id,cost,leg.access,leg.requirements,{b.point,a.point})
        end
    end
    leg.attachments[#leg.attachments+1]=current
    local seconds=Distance(q.point,point)/s.speed
    if q.directions.from then AddEdge(s,id..':from',q.id,id,seconds,'available',leg.requirements,{q.point,point}) end
    if q.directions.to then AddEdge(s,id..':to',id,q.id,seconds,'available',leg.requirements,{point,q.point}) end
end
local function RoadCandidates(s)
    for _,q in ipairs(s.queries)do
        q.roadCandidates={};q.memberships={}
        for _,source in ipairs(s.roads)do
            if source.world==q.point.world then
                for _,leg in ipairs(source.legs)do
                    local point,t=Projection(q.point,leg)
                    local exact=Same(q.point,point)
                    local allowed=not leg.restricted or t==0 and leg.fromJoin or t==1 and leg.toJoin
                    if Compatible(q.point,point) and (exact or allowed) then
                        if exact then
                            q.memberships[leg]=t
                            Domain(q,{minZ=point.z,maxZ=point.z},point)
                            if q.ambiguous then q.roadAmbiguous=true end
                        end
                        Need(#q.roadCandidates<4096,'road_connector_limit')
                        q.roadCandidates[#q.roadCandidates+1]={leg=leg,point=point,t=t,exact=exact}
                    end
                    Yield()
                end
            end
        end
    end
end
local function RoadAttachments(s)
    for _,q in ipairs(s.queries)do
        if q.ambiguous then
            if #q.roadCandidates>0 then Gap(s,'road_spatial_ambiguous',q.id) end
        elseif next(q.memberships) then
            -- An input already on a declared segment needs no fresh free chord.
            for _,candidate in ipairs(q.roadCandidates)do
                if candidate.exact then ProjectionEdges(s,q,candidate.leg,candidate.point,candidate.t) end
                Yield()
            end
        else
            -- Nearest-first candidate selection grants nothing: every new chord
            -- still needs the mask proof. Keep one proved entry per network.
            for _,source in ipairs(s.roads)do
                while true do
                    local selected,distance
                    for _,candidate in ipairs(q.roadCandidates)do
                        if candidate.leg.source==source and not candidate.tried then
                            local d=Distance(q.point,candidate.point)
                            if not distance or d<distance then selected,distance=candidate,d end
                        end
                        Yield()
                    end
                    if not selected then break end
                    selected.tried=true
                    if SpatialCompatible(q.domain,selected.point) and CanConnect(s,source,q.point,selected.point) then
                        ProjectionEdges(s,q,selected.leg,selected.point,selected.t);break
                    end
                end
                Yield()
            end
        end
    end
end
local function SharedLeg(a,b)
    for leg in pairs(a.memberships)do if b.memberships[leg] then return true end;Yield() end
end
local function DeclaredEntrance(q,source)
    for leg,t in pairs(q.memberships)do
        if leg.source==source and leg.restricted and not (t==0 and leg.fromJoin or t==1 and leg.toJoin) then return false end
        Yield()
    end
    return true
end
local function FreeChords(s)
    for i,a in ipairs(s.queries)do
        for j,b in ipairs(s.queries)do
            if i~=j and a.directions.from and b.directions.to and a.point.world==b.point.world
                and not a.roadAmbiguous and not b.roadAmbiguous and (not next(a.memberships) or not next(b.memberships))
                and not a.ambiguous and not b.ambiguous and SpatialCompatible(a.domain,b.domain)
                and not SharedLeg(a,b) then
                for _,source in ipairs(s.roads)do
                    if source.world==a.point.world and DeclaredEntrance(a,source) and DeclaredEntrance(b,source)
                        and CanConnect(s,source,a.point,b.point) then
                        AddEdge(s,'free:'..i..':'..j..':'..source.ordinal,a.id,b.id,Distance(a.point,b.point)/s.speed,
                            'available',Requirements(source.data),{a.point,b.point})
                    end
                    Yield()
                end
            end
        end
    end
end
local function CheckSources(s)
    for _,source in ipairs(s.sources)do
        if source.owner[source.uid]~=source.registration or source.registration.data~=source.data
            or source.registration.revision~=source.revision then Stop('unknown','data_source_changed') end
        Yield()
    end
    for _,source in ipairs(s.roads)do
        if s.roadData.networks[source.id]~=source.data then Stop('unknown','data_source_changed') end
        Yield()
    end
    if s.roadOwner and type(s.roadOwner.GetRoadRevision)=='function' then
        local ok,revision=pcall(s.roadOwner.GetRoadRevision,s.roadOwner)
        if not ok or revision~=s.roadRevision then Stop('unknown','data_source_changed') end
    end
    if s.connectionOwner~=s.inputContext.data then Stop('unknown','data_source_changed') end
    for _,field in ipairs({'connections','config'})do
        local method=field=='connections' and 'GetConnections' or 'GetConfig'
        local captured,fromOwner
        if field=='connections' then captured,fromOwner=s.connectionRecords,s.connectionsFromOwner
        else captured,fromOwner=s.connectionConfig,s.configFromOwner end
        if fromOwner then
            local ok,value=pcall(s.connectionOwner[method],s.connectionOwner)
            if not ok or value~=captured then Stop('unknown','data_source_changed') end
        elseif s.inputContext[field]~=captured then Stop('unknown','data_source_changed') end
        Yield()
    end
    if s.bindingsFromOwner then
        local ok,value=pcall(s.connectionOwner.GetBindings,s.connectionOwner)
        if not ok or value~=s.bindingRecords then Stop('unknown','data_source_changed') end
    elseif s.inputContext.bindings~=s.bindingRecords then Stop('unknown','data_source_changed') end
end
local function ApplyObservationSnapshot(s,snapshot)
    local dynamics=s.context.dynamicPositions
    for _,key in ipairs({'personalObservation','conditionObservation','dynamicPositions','actionPolicies'})do
        s.context[key]=FillMissing(s.context[key],snapshot[key])
    end
    for kind,observed in pairs(dynamics or {})do
        if SuppliedDynamic(observed) then s.context.dynamicPositions[kind]=Copy(observed) end
        Yield()
    end
    -- A requested native capture may positively revoke readiness. Sparse or
    -- unavailable captures only fill missing facts; they never erase supplied ones.
    local captured=snapshot.personalObservation or {}
    local personal=s.context.personalObservation
    if personal and next(s.observationRequests.actions) then
        for _,key in ipairs({'loading','combat','casting'})do if captured[key]==true then personal[key]=true end end
        for key in pairs(s.observationRequests.actions)do
            local fact=(captured.actions or {})[key]
            if type(fact)=='table' then
                for _,field in ipairs({'known','owned','loaded','usable'})do
                    if fact[field]==false then personal.actions[key][field]=false end
                end
                local target=personal.actions[key]
                if Seconds(fact.readyAt) and Seconds(target.readyAt) then target.readyAt=math.max(target.readyAt,fact.readyAt) end
                for _,field in ipairs({'charges','maxCharges'})do
                    if Quantity(fact[field]) and Quantity(target[field]) then target[field]=math.min(target[field],fact[field]) end
                end
            end
            Yield()
        end
        for id,count in pairs(captured.items or {})do
            if Quantity(count) and Quantity((personal.items or {})[id]) then personal.items[id]=math.min(personal.items[id],count) end
            Yield()
        end
    end
end
local function Work(s)
    CaptureQueries(s)
    local origin=(s.context.personalObservation or {}).origin or {}
    if type(origin.reliable)~='boolean' then s.observationRequests.origin={node=s.objective.from,position=s.positions[s.objective.from]} end
    Connections(s)
    s.job.observationRequests=s.observationRequests
    local snapshot={}
    if s.context.deferObservations then
        Yield('observation_required')
        snapshot=s.job.snapshot
        s.job.snapshot=nil
    end
    ApplyObservationSnapshot(s,snapshot)
    PersonalPoints(s);TerrainSources(s);RoadSources(s)
    for _,source in ipairs(s.sources)do TerrainNodes(s,source) end
    for _,source in ipairs(s.sources)do TerrainEdges(s,source) end
    for _,source in ipairs(s.roads)do RoadNodes(s,source);RoadEdges(s,source) end
    for _,q in ipairs(s.queries)do AnchorCandidates(s,q) end
    RoadCandidates(s)
    DeclaredGoalAliases(s)
    for _,q in ipairs(s.queries)do AnchorEdges(s,q) end
    RoadAttachments(s);FreeChords(s)
    PointAliases(s)
    PersonalEdges(s)
    CheckSources(s)
    if #s.sources==0 and #s.roads==0 and #s.transitions==0 and #s.pendingPersonal==0 then Stop('unknown',s.refusal or 'forever_data_unavailable') end
    local options={conditionObservation=s.context.conditionObservation}
    if s.context.resources~=nil then options.resources=Copy(s.context.resources) end
    if next(s.balances) then
        options.resources=options.resources or {}
        for key,value in pairs(s.balances)do options.resources[key]=value;Yield() end
    end
    if #s.personal>0 then
        options.personal=s.personal
        options.personalObservation=Copy(s.context.personalObservation or {})
        options.personalObservation.revision=options.personalObservation.revision or 1
        options.personalObservation.actions=s.personalFacts
    end
    return {status='complete',graph=s.graph,request=s.objective,
        positions=s.positions,geometry=s.geometry,guidance=s.guidance,options=options,observationRequests=s.observationRequests,
        provenance={scope='declared_model',sources=s.versions,gaps=s.gaps,collisionQueries=s.metrics.collisionQueries,
            preparedTransitions=s.metrics.preparedTransitions,transitions=s.transitions,
            collisionCacheSources=1,
            roadAttachmentCoverage='one_collision_proved_entry_per_network_off_segment',
            costModel={mode='walk',yardsPerSecond=s.speed},
            inputHeight='captured_only',anchorGeometryHeight='declared_entry_when_input_unknown'}}
end
local function Metrics(self)
    local r={};for k,v in pairs(self.metrics)do r[k]=v end;return r
end
function Job:GetMetrics()return Metrics(self)end
local function Finish(self,result)
    if self.child and self.child.Cancel then self.child:Cancel() end
    self.result=result;self.thread,self.child,self.state,self.snapshot=nil,nil,nil,nil
    result.diagnostics=Metrics(self)
    if result.status=='complete' then
        local clock=self.clock
        result.options.clock=function()return clock()/1000 end;result.options.profileClock=clock
        result.options.budgets={sliceMs=self.budgets.sliceMs,cpuMs=self.budgets.cpuMs-self.metrics.cpuMs,
            elapsedMs=self.budgets.elapsedMs-self.metrics.elapsedMs}
    end
    return result
end
function Job:Cancel()return self.result or Finish(self,{status='cancelled',reason='cancelled'})end
function Job:GetObservationRequests()
    if not self.observationRequests then return nil,'observations_not_discovered' end
    return self.observationRequests
end
function Job:ResumeObservations(snapshot)
    if self.result or self.phase~='observation_required' then return nil,'observation_not_requested' end
    if type(snapshot)~='table' then return nil,'invalid_forever_observation' end
    for _,key in ipairs({'personalObservation','conditionObservation','dynamicPositions','actionPolicies'})do
        if snapshot[key]~=nil and type(snapshot[key])~='table' then return nil,'invalid_forever_observation' end
    end
    local personal=snapshot.personalObservation or {}
    for _,key in ipairs({'actions','items','origin'})do
        if personal[key]~=nil and type(personal[key])~='table' then return nil,'invalid_forever_observation' end
    end
    self.snapshot=snapshot;self.phase='preparing'
    return true
end
function Job:Step(operations,milliseconds)
    if self.result then return self.result end
    operations,milliseconds=operations or 64,milliseconds or self.budgets.sliceMs
    if not Finite(operations) or operations%1~=0 or operations<1 or operations>4096 or not Finite(milliseconds) or milliseconds<=0 then
        return Finish(self,{status='invalid',reason='invalid_step_budget'}) end
    local start=Sample(self.clock)
    if not start or start<self.last then return Finish(self,{status='unknown',reason='clock_unavailable'}) end
    self.metrics.elapsedMs=start-self.started
    if self.metrics.elapsedMs>=self.budgets.elapsedMs then return Finish(self,{status='budget_exceeded',reason='preparation_budget'}) end
    if self.phase=='observation_required' then return {status='running',phase=self.phase,diagnostics=Metrics(self)} end
    self.metrics.slices=self.metrics.slices+1
    local previous=start
    for _=1,operations do
        self.metrics.elapsedMs=previous-self.started
        if self.metrics.cpuMs>=self.budgets.cpuMs or self.metrics.elapsedMs>=self.budgets.elapsedMs then
            return Finish(self,{status='budget_exceeded',reason='preparation_budget'}) end
        local ok,result=coroutine.resume(self.thread)
        self.metrics.operations=self.metrics.operations+1
        local now=Sample(self.clock)
        if not now or now<previous then return Finish(self,{status='unknown',reason='clock_unavailable'}) end
        self.metrics.cpuMs=self.metrics.cpuMs+now-previous;self.metrics.elapsedMs=now-self.started;previous=now;self.last=now
        if self.metrics.cpuMs>=self.budgets.cpuMs or self.metrics.elapsedMs>=self.budgets.elapsedMs then
            return Finish(self,{status='budget_exceeded',reason='preparation_budget'}) end
        if not ok then return Finish(self,type(result)=='table' and result or {status='invalid',reason='forever_preparation_failed'}) end
        if coroutine.status(self.thread)=='dead' then return Finish(self,result) end
        if result=='observation_required' then
            self.phase='observation_required';self.observationRequests=self.state.observationRequests;break
        end
        if now-start>=math.min(milliseconds,self.budgets.sliceMs) then break end
    end
    return {status='running',phase=self.phase,diagnostics=Metrics(self)}
end
function Data.Prepare(request,context)
    if type(context)~='table' or type(context.clock)~='function' then return nil,'invalid_preparation_context' end
    if context.profile~='forever' then return nil,'forever_profile_required' end
    local speed=context.walkSpeed
    if not Finite(speed) or speed<=0 then return nil,'invalid_walk_speed' end
    if type(request)~='table' then return nil,'invalid_position_request' end
    if context.deferObservations~=nil and type(context.deferObservations)~='boolean' then return nil,'invalid_forever_observation_options' end
    for _,key in ipairs({'personalObservation','conditionObservation','dynamicPositions','actionPolicies','resources','bindings'})do
        if context[key]~=nil and type(context[key])~='table' then return nil,'invalid_forever_observation_options' end
    end
    local personal=context.personalObservation or {}
    for _,key in ipairs({'actions','items','origin'})do
        if personal[key]~=nil and type(personal[key])~='table' then return nil,'invalid_forever_observation' end
    end
    local points={Position(request.from),Position(request.to)}
    if not points[1] or not points[2] then return nil,'position_projection_missing' end
    local via=request.via or {}
    if type(via)~='table' or #via>64 then return nil,'invalid_position_request' end
    for i=1,#via do local p=Position(via[i]);if not p then return nil,'position_projection_missing' end;table.insert(points,#points,p) end
    local budgets={}
    for k,v in pairs(Defaults)do
        budgets[k]=context.budgets and context.budgets[k] or v
        if not Finite(budgets[k]) or budgets[k]<=0 or budgets[k]>v then return nil,'invalid_budgets' end
    end
    local now=Sample(context.clock);if not now then return nil,'clock_unavailable' end
    local self=setmetatable({clock=context.clock,started=now,last=now,budgets=budgets,
        metrics={operations=0,slices=0,cpuMs=0,elapsedMs=0,preparedNodes=0,preparedEdges=0,preparedTransitions=0,collisionQueries=0,collisionSteps=0}},Job)
    local captured={};for k,v in pairs(context)do captured[k]=v end
    local state={context=captured,inputContext=context,request={points=points},speed=speed,graph={complete=false,nodes={},edges={}},
        positions={},geometry={},guidance={},queries={},sources={},roads={},transitions={},registry={},worlds={},versions={},gaps={},points=0,metrics=self.metrics,job=self}
    state.observationRequests={actions={},quests={},access={},dynamic={}}
    state.pendingPersonal,state.personal,state.personalFacts,state.balances={},{},{},{}
    self.state=state;self.thread=coroutine.create(function()return Work(state)end)
    return self
end
ns.NavigationV2ForeverData=Data
return Data
