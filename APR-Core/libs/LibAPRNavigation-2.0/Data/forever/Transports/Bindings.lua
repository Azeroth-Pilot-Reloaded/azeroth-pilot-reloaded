-- Bind one factual transport to explicitly supplied graph identities and costs.
-- No localization, client reads, terrain joins, search, timers or output.
local _, ns = ...
local API = {}
local Finite = ns.NavigationV2Graph.Finite
local Copy = ns.NavigationV2WaypointTarget.Copy

local function Name(value)
    return type(value)=='string' and value:match('%S')~=nil
end

local function Integer(value)
    return Finite(value) and value>=0 and value%1==0
end

local function Identity(value)
    return type(value)=='table' and Name(value.node) and Name(value.space) and Name(value.phase)
        and Integer(value.worldID) and Integer(value.floorID)
end

local function Requirements(record)
    local result, access, seen = {}, {}, {}
    local function Add(key, allowed)
        if seen[key]==nil or seen[key]~=allowed then
            access[#access+1]={key=key,allowed=allowed};seen[key]=allowed
        end
    end
    local source=record.requirements or {}
    for _,field in ipairs({'faction','class'}) do
        if source[field] then Add(field..'-'..source[field]:lower(),true) end
    end
    for _,field in ipairs({'minLevel','level'}) do
        if source[field] then Add('minimum-level:'..tostring(source[field]),true) end
    end
    for _,entry in ipairs(source.access or {}) do Add(entry.key,entry.allowed) end
    for _,endpoint in ipairs({record.from,record.to}) do
        if endpoint.accessKey then Add('location-access:'..endpoint.accessKey,true) end
    end
    if #access>0 then result.access=access end
    if source.quests then result.quests=Copy(source.quests) end
    return next(result) and result or nil
end

local function Position(endpoint)
    if endpoint.space=='map' then return {mapID=endpoint.uiMapID,x=endpoint.x,y=endpoint.y} end
end

local function Stop(identity, endpoint, id)
    return {id=id,worldID=identity.worldID,floorID=identity.floorID,phaseID=identity.phase,
        position=Position(endpoint)}
end

local function Scheduled(record,binding,reverse)
    local origin,destination=binding.from,binding.to
    local start,finish=record.from,record.to
    if reverse then origin,destination,start,finish=destination,origin,finish,start end
    local result={id=record.id..(reverse and '-reverse' or '-forward'),kind=record.kind,
        from=origin.node,to=destination.node,origin=Stop(origin,start,record.id..(reverse and '-destination' or '-origin')),
        destination=Stop(destination,finish,record.id..(reverse and '-origin' or '-destination')),
        access=binding.access,costs=binding.costs and Copy(binding.costs),
        wait=binding.wait and Copy(binding.wait),requirements=Requirements(record)}
    if binding.costs==nil then result.totalSeconds=binding.totalSeconds or record.seconds end
    return result
end

local function Portal(record,binding,reverse)
    local origin,destination=binding.from,binding.to
    local entry=record.from
    if reverse then origin,destination,entry=destination,origin,record.to end
    local costs=binding.costs or {}
    local result={id=record.id..(reverse and '-reverse' or '-forward'),from=origin.node,to=destination.node,
        phase=origin.phase,destination={space=destination.space,phase=destination.phase},entry=Position(entry),
        waitSeconds=costs.waitSeconds,useSeconds=costs.useSeconds,
        loadingSeconds=costs.loadingSeconds,timeoutSeconds=binding.timeoutSeconds,
        requirements=Requirements(record)}
    if binding.costs==nil then result.totalSeconds=binding.totalSeconds or record.seconds end
    return result
end

local function Personal(record,binding)
    if #record.actions~=1 then return nil,'transport_action_selection_missing' end
    local action=record.actions[1]
    if action.type~=record.kind then return nil,'transport_action_kind_mismatch' end
    if record.to.dynamic=='bind' and binding.bindObserved~=true then return nil,'transport_bind_destination_unobserved' end
    for _,field in ipairs({'consumable','rare','chargeBased'}) do
        if type(binding[field])~='boolean' then return nil,'transport_personal_policy_missing' end
    end
    if binding.cooldownSeconds==nil then return nil,'transport_cooldown_missing' end
    if action.reagentID then
        local found=false
        for _,reagent in pairs(type(binding.reagents)=='table' and binding.reagents or {}) do
            if type(reagent)=='table' and reagent.itemID==action.reagentID then found=true end
        end
        if not found then return nil,'transport_reagent_quantity_missing' end
    end
    local result={id=record.id,kind=record.kind,from=binding.from.node,to=binding.to.node,
        destination={space=binding.to.space,phase=binding.to.phase},
        origin={space=binding.from.space,phase=binding.from.phase},
        useSeconds=binding.costs.useSeconds,loadingSeconds=binding.costs.loadingSeconds,
        cooldownSeconds=binding.cooldownSeconds,timeoutSeconds=binding.timeoutSeconds,
        consumable=binding.consumable,rare=binding.rare,chargeBased=binding.chargeBased,
        reagents=binding.reagents and Copy(binding.reagents),itemResourceId=binding.itemResourceId,
        cooldownGroup=record.cooldownGroup,requirements=Requirements(record)}
    result[record.kind=='spell' and 'spellID' or 'itemID']=action.id
    return result
end

local function Check(record,binding)
    if type(binding)~='table' then return 'transport_binding_missing' end
    if not Identity(binding.from) or not Identity(binding.to) then return 'transport_endpoint_identity_missing' end
    if binding.from.node==binding.to.node then return 'transport_identical_nodes' end
    for _,key in ipairs({'from','to'}) do
        local endpoint=record[key]
        if endpoint.instanceID and endpoint.instanceID~=binding[key].worldID then return 'transport_world_mismatch' end
    end
    if record.bidirectional==nil and type(binding.bidirectional)~='boolean' then return 'transport_direction_unspecified' end
    if binding.totalSeconds~=nil and (not Finite(binding.totalSeconds) or binding.totalSeconds<0) then
        return 'transport_total_invalid'
    end
    if binding.totalSeconds~=nil and (binding.costs~=nil or binding.wait~=nil) then return 'transport_mixed_cost_model' end
    if binding.costs==nil then
        if record.kind=='item' or record.kind=='spell' or binding.wait~=nil
            or not Finite(binding.totalSeconds or record.seconds) then return 'transport_cost_components_missing' end
    elseif type(binding.costs)~='table' then return 'transport_cost_components_missing' end
    if not Finite(binding.timeoutSeconds) or binding.timeoutSeconds<=0 then return 'transport_timeout_missing' end
end

-- Return an isolated graph/options bundle for the existing Navigation.New API.
-- The graph only has the two EXPLICITLY bound nodes; no approach/terrain edge.
-- A caller merging several bundles owns those exact identities and coverage.
function API.Bind(id,binding)
    local data=ns.NavigationV2ForeverTransportsData
    if type(id)~='string' then return nil,'transport_id_invalid' end
    if not data then return nil,'transport_data_unavailable' end
    local excluded=data.excluded[id]
    if excluded then return nil,excluded.reason end
    local record=data.routes[id]
    if not record then return nil,'transport_unknown' end
    local reason=Check(record,binding)
    if reason then return nil,reason end
    local options,values={},{}
    local both=record.bidirectional
    if both==nil then both=binding.bidirectional end
    if record.kind=='boat' or record.kind=='zeppelin' or record.kind=='elevator' or record.kind=='tram' then
        values[1]=Scheduled(record,binding,false)
        if both then values[2]=Scheduled(record,binding,true) end
        local checked
        checked,reason=ns.NavigationV2Scheduled.NewCatalog(values)
        if not checked then return nil,reason end
        options.scheduled=values
    elseif record.kind=='portal' or record.kind=='passage' then
        values[1]=Portal(record,binding,false)
        if both then values[2]=Portal(record,binding,true) end
        local checked
        checked,reason=ns.NavigationV2Portals.New(values)
        if not checked then return nil,reason end
        options.portals=values
    elseif record.kind=='item' or record.kind=='spell' then
        if both then return nil,'transport_personal_reverse_unsupported' end
        values[1],reason=Personal(record,binding)
        if not values[1] then return nil,reason end
        local checked
        checked,reason=ns.NavigationV2Personal.New(values)
        if not checked then return nil,reason end
        options.personal=values
    else
        return nil,'transport_kind_unsupported'
    end
    local conditions
    conditions,reason=ns.NavigationV2Conditions.Compile(values[1].requirements)
    if not conditions then return nil,reason end
    return {graph={complete=false,nodes={binding.from.node,binding.to.node},edges={}},options=options,
        travelOptions={scheduledTimeoutSeconds=binding.timeoutSeconds}}
end

ns.NavigationV2ForeverTransports=API
return API
