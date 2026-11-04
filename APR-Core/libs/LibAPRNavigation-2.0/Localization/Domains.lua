-- Logical localization and implicit walking policy; no collision or client API.
local _,ns=...
local Domains,Resolver={},{}
Resolver.__index=Resolver
local Finite=ns.NavigationV2Graph.Finite
local Copy=ns.NavigationV2WaypointTarget.Copy
local function Name(v) return type(v)=='string' and v~='' end
local function Integer(v) return Finite(v) and v>=0 and v%1==0 and v<=9007199254740991 end
local function Identity(v) return Name(v) or Integer(v) end

local function Bounds(b)
    if b==nil then return true end
    if type(b)~='table' then return false end
    for _,axis in ipairs({'X','Y','Z'}) do
        local a,c=b['min'..axis],b['max'..axis]
        if a~=nil or c~=nil then
            if not Finite(a) or not Finite(c) or a>c then return false end
        end
    end
    return true
end

local function Within(b,p,xyOnly)
    if not b then return true end
    for _,axis in ipairs(xyOnly and {'X','Y'} or {'X','Y','Z'}) do
        local v=p[axis:lower()]
        if v~=nil and b['min'..axis]~=nil and (v<b['min'..axis] or v>b['max'..axis]) then return false end
    end
    return true
end

local function Listed(values,value)
    if values==nil or #values==0 then return true end
    for _,v in ipairs(values) do if v==value then return true end end
    return false
end

local function Selectors(s,p)
    if s.worldID~=p.world or not Within(s.bounds,p,true) then return false end
    if p.uiMapID and not Listed(s.mapIDs,p.uiMapID) then return false end
    if p.areaID and not Listed(s.areaIDs,p.areaID) then return false end
    if not p.uiMapID and not p.areaID and not s.bounds and #(s.mapIDs or {})>0 then return false end
    return true
end

function Domains.New(data)
    if type(data)~='table' or type(data.spaces)~='table' then return nil,'invalid_domains' end
    local self=setmetatable({spaces={},worlds={},isolations={}},Resolver)
    local count=0
    for _,source in pairs(data.spaces) do
        count=count+1
        if count>ns.NavigationV2Graph.Limits.zones or type(source)~='table' or not Name(source.id)
            or self.spaces[source.id] or not Integer(source.worldID) or not Name(source.kind)
            or not Bounds(source.bounds) then return nil,'invalid_domain' end
        for _,key in ipairs({'floor','phase'}) do
            if source[key]~=nil and not Identity(source[key]) then return nil,'invalid_domain' end
        end
        local s=Copy(source);self.spaces[s.id]=s
        local row=self.worlds[s.worldID] or {};self.worlds[s.worldID]=row;row[#row+1]=s
    end
    for _,s in pairs(self.spaces) do
        local seen,current={},s
        while current do
            if seen[current.id] then return nil,'cyclic_parent_space' end
            seen[current.id]=true
            if current.parentSpace then
                current=self.spaces[current.parentSpace]
                if not current then return nil,'unresolved_space_reference' end
                if current.worldID~=s.worldID then return nil,'parent_world_mismatch' end
            else current=nil end
        end
    end
    for _,v in pairs(data.isolation or {}) do
        if type(v)~='table' or not Integer(v.uiMapID) or not Name(v.key) then return nil,'invalid_isolation' end
        if self.isolations[v.uiMapID] then return nil,'duplicate_isolation' end
        self.isolations[v.uiMapID]=v.key
    end
    return self
end

function Resolver:IsDescendant(id,parent)
    local current=self.spaces[id]
    while current do
        if current.id==parent then return true end
        current=current.parentSpace and self.spaces[current.parentSpace]
    end
    return false
end

local function Constraints(self,s,p)
    local current=s
    while current do
        if not Within(current.bounds,p) then return false,'bounds_mismatch' end
        for _,key in ipairs({'floor','phase','accessKey'}) do
            if current[key]~=nil then
                if p[key]==nil then return nil,key=='floor' and 'floor_ambiguous' or key..'_unknown' end
                if p[key]~=current[key] then return false,key..'_mismatch' end
            end
        end
        current=current.parentSpace and self.spaces[current.parentSpace]
    end
    return true
end

local function Inherit(self,s,p)
    local r=Copy(p);r.space,r.kind,r.ancestors=s.id,s.kind,{}
    local current=s
    while current do
        r.ancestors[current.id]=true
        r.groundOnly=r.groundOnly or current.groundOnly==true
        r.requiresExit=r.requiresExit or current.requiresExit==true
        r.transitRegion=r.transitRegion or current.transitRegion
        r.transitFaction=r.transitFaction or current.transitFaction
        current=current.parentSpace and self.spaces[current.parentSpace]
    end
    r.region=self.isolations[r.uiMapID] or ('world:'..r.world)
    return r
end

function Resolver:Resolve(point)
    if type(point)~='table' or not Integer(point.world) or not Finite(point.x) or not Finite(point.y)
        or (point.z~=nil and not Finite(point.z)) then return nil,'position_missing' end
    for _,key in ipairs({'floor','phase'}) do
        if point[key]~=nil and not Identity(point[key]) then return nil,'invalid_location_identity' end
    end
    if point.space and not self.spaces[point.space] then return nil,'space_unknown' end
    local matches,pending={},{}
    for _,s in ipairs(self.worlds[point.world] or {}) do
        if Selectors(s,point) and (not point.space or self:IsDescendant(s.id,point.space)) then
            local ok,reason=Constraints(self,s,point)
            if ok then matches[#matches+1]=s
            elseif ok==nil then pending[#pending+1]={space=s,reason=reason}
            elseif point.floor~=nil and point.floor==s.floor then return nil,reason end
        end
    end
    local selected
    for _,s in ipairs(matches) do
        local ancestor=false
        for _,other in ipairs(matches) do
            if s~=other and self:IsDescendant(other.id,s.id) then ancestor=true;break end
        end
        if not ancestor then
            if selected then return nil,'space_ambiguous' end
            selected=s
        end
    end
    for _,v in ipairs(pending) do
        if not selected or not self:IsDescendant(selected.id,v.space.id) then return nil,v.reason end
    end
    if not selected then return nil,'space_unknown' end
    return Inherit(self,selected,point)
end

local function Transit(p,context)
    if not p.transitFaction then return 'available' end
    local faction=context.actor and context.actor.faction
    if not faction then return 'unknown','faction_unknown' end
    if faction==p.transitFaction then return 'available' end
    for _,v in ipairs({context.origin or false,context.objective or false}) do
        if v and v.transitRegion and v.transitRegion==p.transitRegion then return 'available' end
    end
    return 'unavailable','hostile_transit'
end

function Resolver:TransitAccess(point,context)
    return Transit(point,context or {})
end

function Resolver:CanConnect(a,b,context)
    context=context or {}
    if a.world~=b.world then return 'unavailable','world_mismatch' end
    if a.region~=b.region then return 'unavailable','isolation_mismatch' end
    if a.noAutoconnect or b.noAutoconnect then return 'unavailable','no_autoconnect' end
    if (a.requiresExit or b.requiresExit) and a.space~=b.space then return 'unavailable','exit_required' end
    for _,p in ipairs({a,b}) do
        local access,why=Transit(p,context)
        if access~='available' then return access,why end
    end
    if a.requiresExit or b.requiresExit then return 'unknown','geometry_required' end
    return 'available','authorized_region_model'
end

ns.NavigationV2Domains=Domains
return Domains
