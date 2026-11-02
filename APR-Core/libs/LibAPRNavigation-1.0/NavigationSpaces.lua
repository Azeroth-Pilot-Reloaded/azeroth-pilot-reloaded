-- Logical navigation spaces are data, separate from UI map presentation and
-- enclosure observations. Unknown spaces retain the native access boundary.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("navigation-spaces", 2) then return end
local Instance = Lib.Instance
local EMPTY = {}
local KINDS = { outdoor=true, subzone=true, underground=true, cave=true, building=true,
    floor=true, instance=true, transport=true, unknown=true }
local function Finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function Identity(value) return type(value)=="string" and value~="" end
local function Channel(value) return value==nil or Identity(value) or Finite(value) end
local function Array(value, validate)
    if type(value)~="table" then return false end
    local count=0
    for key,item in pairs(value) do
        if not Finite(key) or key<1 or key%1~=0 or not validate(item) then return false end
        count=count+1
    end
    return #value==count
end
local function MapID(value) return Finite(value) and value>0 and value%1==0 end
local function Valid(space)
    if type(space)~="table" or not Identity(space.id) or not KINDS[space.kind]
        or not Finite(space.worldID) or space.worldID<0 or space.worldID%1~=0
        or not Array(space.mapIDs,MapID) or not Channel(space.floor) or not Channel(space.accessKey) then return false end
    if space.areaIDs~=nil and not Array(space.areaIDs,MapID) then return false end
    if space.terrainScopeIDs~=nil and not Array(space.terrainScopeIDs,Identity) then return false end
    for _,key in ipairs({"groundOnly","requiresExit"}) do
        if space[key]~=nil and type(space[key])~="boolean" then return false end
    end
    for _,key in ipairs({"parentSpace","region","transitRegion"}) do
        if space[key]~=nil and not Identity(space[key]) then return false end
    end
    if space.transitFaction~=nil and space.transitFaction~="Horde" and space.transitFaction~="Alliance"
        and space.transitFaction~="Neutral" then return false end
    if space.bounds~=nil then
        if type(space.bounds)~="table" then return false end
        for _,axis in ipairs({"X","Y","Z"}) do
            local low,high=space.bounds["min"..axis],space.bounds["max"..axis]
            if not Finite(low) or not Finite(high) or low>high then return false end
        end
    end
    return #space.mapIDs>0 or (space.areaIDs and #space.areaIDs>0) or space.bounds~=nil
end
Lib.ValidateNavigationSpace = Valid

local function Index(owner)
    local source=owner.config.NavigationSpaces or EMPTY
    local cached=owner._navigationSpaceIndex
    if cached and cached.source==source and cached.count==#source then return cached end
    local index={source=source,count=#source,byID={},maps={},areas={},worlds={}}
    for _,space in ipairs(source) do
        if Valid(space) and not index.byID[space.id] then
            index.byID[space.id]=space
            for _,map in ipairs(space.mapIDs) do
                local entries=index.maps[map] or {}; index.maps[map]=entries; entries[#entries+1]=space
            end
            for _,area in ipairs(space.areaIDs or {}) do
                local entries=index.areas[area] or {}; index.areas[area]=entries; entries[#entries+1]=space
            end
            if #space.mapIDs==0 and #(space.areaIDs or {})==0 then
                local entries=index.worlds[space.worldID] or {}; index.worlds[space.worldID]=entries; entries[#entries+1]=space
            end
        else index.invalid=true end
    end
    owner._navigationSpaceIndex=index
    return index
end
function Instance:GetNavigationSpace(id) return Index(self).byID[id] end

local function InList(list,value)
    for _,entry in ipairs(list or {}) do if entry==value then return true end end
    return false
end
local function UnknownHeight(point)
    return not Finite(point.z) or (point.positionSource=="unit" and point.z==0 and point.heightSource~="terrain")
end
local function Matches(owner,space,point,mapDepth,areaMatch)
    if space.worldID~=owner:GetWorldInstanceID(point.instanceID) then return false end
    if space.floor~=nil and point.floor~=nil and space.floor~=point.floor then return false end
    if space.accessKey~=nil and point.accessKey~=nil and space.accessKey~=point.accessKey then return false end
    if point.areaID~=nil and space.areaIDs and #space.areaIDs>0 and not InList(space.areaIDs,point.areaID) then return false end
    if #space.mapIDs>0 and mapDepth==nil then return false end
    if #space.mapIDs==0 and space.areaIDs and #space.areaIDs>0 and not areaMatch then return false end
    local bounds=space.bounds
    if bounds then
        if not Finite(point.x) or not Finite(point.y) or point.x<bounds.minX or point.x>bounds.maxX
            or point.y<bounds.minY or point.y>bounds.maxY then return false end
        if not UnknownHeight(point) and (point.z<bounds.minZ or point.z>bounds.maxZ) then return false end
    end
    local incomplete = (space.accessKey~=nil and point.accessKey==nil)
        or (space.floor~=nil and point.floor==nil and (not bounds or UnknownHeight(point)))
    return true,incomplete
end
local function Descendant(index,space,id)
    local seen={}
    for _=1,50 do
        if not space or not space.parentSpace or seen[space.id] then return false end
        seen[space.id]=true
        if space.parentSpace==id then return true end
        space=index.byID[space.parentSpace]
    end
    return false
end
function Instance:IsNavigationSpaceDescendant(space,ancestorID)
    local index=Index(self)
    local id=type(space)=="table" and space.id or space
    local current=index.byID[id]
    if not current or current.id==ancestorID or not index.byID[ancestorID] then return false end
    local seen,found,world={},false,current.worldID
    for _=1,50 do
        if not current or seen[current.id] or current.worldID~=world then return false end
        seen[current.id]=true
        if current.id==ancestorID then found=true end
        if not current.parentSpace then return found end
        current=index.byID[current.parentSpace]
    end
    return false
end
local function Effective(index,space,point)
    local result={}
    for key,value in pairs(space) do result[key]=value end
    local current,seen,floorProved=space,{},false
    for _=1,50 do
        if seen[current.id] then return nil,"cyclic_navigation_space" end
        seen[current.id]=true
        if current.accessKey~=nil then
            if point.accessKey==nil then return nil,"navigation_space_identity_unavailable" end
            if point.accessKey~=current.accessKey or (result.accessKey~=nil and result.accessKey~=current.accessKey) then
                return nil,"navigation_space_identity_mismatch"
            end
            result.accessKey=current.accessKey
        end
        if result.floor==nil then result.floor=current.floor end
        local b=current.bounds
        if b and not UnknownHeight(point) and Finite(point.x) and Finite(point.y)
            and point.x>=b.minX and point.x<=b.maxX and point.y>=b.minY and point.y<=b.maxY
            and point.z>=b.minZ and point.z<=b.maxZ then floorProved=true end
        if not current.parentSpace then
            if result.floor~=nil then
                if point.floor~=nil and point.floor~=result.floor then return nil,"navigation_space_identity_mismatch" end
                if point.floor==nil and not floorProved then return nil,"navigation_space_identity_unavailable" end
            end
            result.known=true; return result,"declared_navigation_space"
        end
        current=index.byID[current.parentSpace]
        if not current then return nil,"navigation_space_parent_unavailable" end
        if current.worldID~=space.worldID then return nil,"navigation_space_world_mismatch" end
        if current.groundOnly then result.groundOnly=true end
        if current.requiresExit then result.requiresExit=true end
        for _,key in ipairs({"transitFaction","transitRegion"}) do
            if result[key]==nil then result[key]=current[key] end
        end
    end
    return nil,"cyclic_navigation_space"
end
local function Native(owner,point)
    local map,seen,kind,requiresExit,groundOnly,isolated=point.uiMapID,{},"unknown",false,nil,false
    for _=1,50 do
        if not map or seen[map] then break end
        seen[map]=true
        if (owner.config.GroundOnlyAreas or EMPTY)[map] then groundOnly=true end
        if (owner.config.IsolatedAreas or EMPTY)[map]~=nil or (owner.config.IsolatedContinents or EMPTY)[map] then
            isolated,requiresExit=true,true
        end
        local info=owner:GetMapAncestryInfo(map)
        if not info then break end
        local override=owner.config.MapTypeOverrides and owner.config.MapTypeOverrides[map]
        local mapType=override and override.mapType or info.mapType
        if mapType==4 or (owner.entranceMaps and owner.entranceMaps[map]) then kind,requiresExit="instance",true; break end
        if mapType==6 then requiresExit=true; break end
        if mapType==2 then kind=isolated and "unknown" or "outdoor"; break end
        if not info.parentMapID or info.parentMapID==0 then break end
        map=info.parentMapID
    end
    if point.floor~=nil then kind,requiresExit="floor",true end
    if point.accessKey~=nil then requiresExit=true end
    local region=owner:GetNativePositionRegion(point)
    if not region then return nil,"navigation_space_unavailable" end
    return {id="native:"..region..":"..tostring(point.accessKey or "")..":"..tostring(point.floor or ""),
        kind=kind,worldID=owner:GetWorldInstanceID(point.instanceID),mapIDs={point.uiMapID},
        known=false,requiresExit=requiresExit,groundOnly=groundOnly},"unknown_navigation_space"
end

function Instance:ResolveNavigationSpace(point)
    if type(point)~="table" or not Finite(point.instanceID) then return nil,"invalid_navigation_position" end
    local index=Index(self)
    local candidates,seen,depths,incomplete={},{},{},{}
    local function add(space,depth,area)
        local matches,unknown=Matches(self,space,point,depth,area)
        if not seen[space.id] and matches then
            seen[space.id]=true; candidates[#candidates+1]=space; depths[space.id]=depth or 0
            incomplete[space.id]=unknown
        end
    end
    local current,visited=point.uiMapID,{}
    for depth=0,49 do
        if not current or visited[current] then break end
        visited[current]=true
        for _,space in ipairs(index.maps[current] or {}) do add(space,depth,InList(space.areaIDs,point.areaID)) end
        local info=self:GetMapAncestryInfo(current)
        if not info or info.mapType==4 or info.mapType==6 or (self.config.IsolatedAreas or {})[current]
            or (self.entranceMaps and self.entranceMaps[current]) then break end
        current=info.parentMapID
    end
    for _,space in ipairs(index.areas[point.areaID] or {}) do
        local depth=depths[space.id]
        if #space.mapIDs==0 then add(space,depth,true) end
    end
    for _,space in ipairs(index.worlds[self:GetWorldInstanceID(point.instanceID)] or {}) do add(space,0,false) end
    local explicit=point.spaceID
    if explicit~=nil and not Identity(explicit) then return nil,"invalid_navigation_position" end
    if explicit and explicit:sub(1,7)~="native:" then
        for _,space in ipairs(candidates) do
            if space.id==explicit then
                if incomplete[space.id] then return nil,"navigation_space_identity_unavailable" end
                return Effective(index,space,point)
            end
        end
        return nil,"navigation_space_unavailable"
    end
    local selected
    for _,space in ipairs(candidates) do
        local shadowed=false
        for _,other in ipairs(candidates) do
            if other~=space and (Descendant(index,other,space.id) or depths[other.id]<depths[space.id]) then shadowed=true; break end
        end
        if not shadowed then
            if selected then return nil,"ambiguous_navigation_space" end
            selected=space
        end
    end
    if selected then
        if incomplete[selected.id] then return nil,"navigation_space_identity_unavailable" end
        return Effective(index,selected,point)
    end
    return Native(self,point)
end
