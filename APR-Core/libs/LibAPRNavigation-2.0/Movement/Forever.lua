-- Pure movement costs/access. The existing planner owns search and cancellation.
local _, ns = ...
local Forever, Profile = {}, {}
Profile.__index = Profile
local MODES = {walk=true, mount=true, swim=true}
local ACCESS = {available=true, unavailable=true, unknown=true}
-- Estimates, not observed timings. false explicitly means unknown; overrides win.
local DEFAULTS = {walkSpeed=7, mountSpeed=11.2, swimSpeed=4.7,
    mountSeconds=3, dismountSeconds=0, enterSwimSeconds=0.75, exitSwimSeconds=0.75}
local MOUNT_LEVEL = 40

local function Number(value, minimum)
    return type(value)=='number' and value==value and value>=minimum and value<math.huge
end

local function OptionalBoolean(value)
    return value==nil or type(value)=='boolean'
end

local function ValidSetting(key,value)
    if value==false then return true end
    if not Number(value,0) then return false end
    return not key:find('Speed',1,true) or value>0
end

local function Settings(source)
    if source~=nil and type(source)~='table' then return nil end
    local copy={}
    for key, default in pairs(DEFAULTS) do
        local value=source and source[key]
        if value==nil then value=default end
        if not ValidSetting(key,value) then return nil end
        copy[key]=value
    end
    for key in pairs(source or {}) do if DEFAULTS[key]==nil then return nil end end
    return copy
end

local function Observation(observation)
    if type(observation)~='table' then return false end
    local level=observation.level
    if level~=nil and (not Number(level,1) or level%1~=0) then return false end
    for _,key in ipairs({'mountOwned','mountUsable','canMountHere'}) do
        if not OptionalBoolean(observation[key]) then return false end
    end
    return observation.initialMode==nil or MODES[observation.initialMode]==true
end

local function MountAccess(observation)
    local level=observation.level
    if (level and level<MOUNT_LEVEL) or observation.mountOwned==false or observation.mountUsable==false then
        return 'unavailable'
    end
    if not level or observation.mountOwned==nil or observation.mountUsable==nil then return 'unknown' end
    return 'available'
end

function Forever.New(observation, settings)
    if not Observation(observation) then return nil,'invalid_movement_observation' end
    local costs=Settings(settings)
    if not costs then return nil,'invalid_movement_settings' end
    local origin='unknown'
    if observation.canMountHere==true then origin='available'
    elseif observation.canMountHere==false then origin='unavailable' end
    return setmetatable({initialMode=observation.initialMode, dynamic=true, identity={},
        mountAccess=MountAccess(observation), originMountAccess=origin, costs=costs},Profile)
end

function Forever.IsProfile(value)
    return type(value)=='table' and getmetatable(value)==Profile
end

function Forever.Same(a,b)
    if not Forever.IsProfile(a) or not Forever.IsProfile(b) then return false end
    for _,key in ipairs({'initialMode','mountAccess','originMountAccess'}) do
        if a[key]~=b[key] then return false end
    end
    for key,value in pairs(a.costs) do if b.costs[key]~=value then return false end end
    return true
end

-- The graph input boundary calls this once. No mode or mounted clearance is
-- inferred from legacy seconds or from the existence of a walking corridor.
function Forever.CaptureMovement(value)
    if type(value)~='table' or not MODES[value.mode] or not Number(value.distance,0)
        or (value.canMount~=nil and not ACCESS[value.canMount]) then return nil,'invalid_movement' end
    for key in pairs(value) do
        if key~='mode' and key~='distance' and key~='canMount' then return nil,'invalid_movement' end
    end
    return {mode=value.mode,distance=value.distance,canMount=value.canMount or 'unknown'}
end

local function Access(a,b)
    if a=='unavailable' or b=='unavailable' then return 'unavailable' end
    if a=='unknown' or b=='unknown' then return 'unknown' end
    return 'available'
end

local function Transition(costs, source, target)
    if source==target then return 0 end
    local total=0
    local keys={}
    if source=='mount' then keys[#keys+1]='dismountSeconds' end
    if source=='swim' then keys[#keys+1]='exitSwimSeconds' end
    if target=='mount' then keys[#keys+1]='mountSeconds' end
    if target=='swim' then keys[#keys+1]='enterSwimSeconds' end
    for _,key in ipairs(keys) do
        if costs[key]==false then return nil end
        total=total+costs[key]
    end
    return total
end

local function LegAccess(profile,edge,currentMode,mode,atStart)
    local access=edge.access or 'available'
    if mode=='mount' then
        access=Access(access,profile.mountAccess)
        if currentMode~='mount' then
            access=Access(access,edge.movement.canMount or 'unknown')
            if atStart then access=Access(access,profile.originMountAccess) end
        end
    end
    return access
end

local function Travel(costs,edge,mode)
    if not edge.movement then return edge.seconds end
    local speed=costs[mode..'Speed']
    if speed then return edge.movement.distance/speed end
end

function Profile:Evaluate(edge,currentMode,atStart)
    if not MODES[currentMode] then return nil,'movement_state_unknown' end
    local mode=edge.movement and edge.movement.mode or 'walk'
    local access=LegAccess(self,edge,currentMode,mode,atStart)
    local transition=Transition(self.costs,currentMode,mode)
    local travel=Travel(self.costs,edge,mode)
    if not travel or not transition then access=Access(access,'unknown') end
    local seconds=(travel or 0)+(transition or 0)
    if not Number(seconds,0) then return nil,'cost_overflow' end
    return {mode=mode,seconds=seconds,access=access,transitionSeconds=transition}
end

ns.NavigationV2Forever=Forever
return Forever
