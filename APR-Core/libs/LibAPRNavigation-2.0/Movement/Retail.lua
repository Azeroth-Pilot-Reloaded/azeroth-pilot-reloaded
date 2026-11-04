-- Pure Retail movement model. No native reads, search, timers or output.
local _,ns=...
local Retail,Profile={},{}
Profile.__index=Profile
local MODES={walk=true,mount=true,swim=true,skyriding=true}
local ACCESS={available=true,unavailable=true,unknown=true}
-- Explicit estimates, not measurements. false means the cost is unknown.
local DEFAULTS={walkSpeed=7,mountSpeed=14,swimSpeed=4.7,skyridingSpeed=60,
    climbSpeed=15,descentSpeed=45,mountSeconds=3,dismountSeconds=0,
    landingSeconds=0,enterSwimSeconds=0.75,exitSwimSeconds=0.75}
local BOOLS={'mountOwned','mountUsable','skyridingOwned','skyridingUsable',
    'canMountHere','canSkyridingHere','loading'}
local FIELDS={mode=true,distance=true,rise=true,fall=true,canMount=true,canFly=true,
    groundOnly=true,requiresExit=true}

local function Number(v)
    return type(v)=='number' and v==v and v>=0 and v<math.huge
end

local function Settings(source)
    if source~=nil and type(source)~='table' then return end
    local result={}
    for key,default in pairs(DEFAULTS)do
        local value=source and source[key]
        if value==nil then value=default end
        if value~=false and (not Number(value) or (key:find('Speed',1,true) and value==0)) then return end
        result[key]=value
    end
    for key in pairs(source or {})do if DEFAULTS[key]==nil then return end end
    return result
end

local function Observation(o)
    if type(o)~='table' or (o.initialMode~=nil and not MODES[o.initialMode]) then return false end
    for _,key in ipairs(BOOLS)do
        if o[key]~=nil and type(o[key])~='boolean' then return false end
    end
    return true
end

local function Access(a,b)
    if a=='unavailable' or b=='unavailable' then return 'unavailable' end
    if a=='unknown' or b=='unknown' then return 'unknown' end
    return 'available'
end

local function Permission(value)
    if value==true then return 'available' end
    if value==false then return 'unavailable' end
    return 'unknown'
end

local function Capability(owned,usable)
    return Access(Permission(owned),Permission(usable))
end

function Retail.New(observation,settings)
    if not Observation(observation) then return nil,'invalid_movement_observation' end
    local costs=Settings(settings)
    if not costs then return nil,'invalid_movement_settings' end
    if observation.loading==true then observation={} end
    return setmetatable({initialMode=observation.initialMode,dynamic=true,identity={},costs=costs,
        mountAccess=Capability(observation.mountOwned,observation.mountUsable),
        skyridingAccess=Capability(observation.skyridingOwned,observation.skyridingUsable),
        originMountAccess=Permission(observation.canMountHere),
        originFlightAccess=Permission(observation.canSkyridingHere)},Profile)
end

function Retail.IsProfile(value)
    return type(value)=='table' and getmetatable(value)==Profile
end

function Retail.Same(a,b)
    if not Retail.IsProfile(a) or not Retail.IsProfile(b) then return false end
    for _,key in ipairs({'initialMode','mountAccess','skyridingAccess','originMountAccess','originFlightAccess'})do
        if a[key]~=b[key] then return false end
    end
    for key,value in pairs(a.costs)do if b.costs[key]~=value then return false end end
    return true
end

-- A skyriding declaration is an admitted model connection, not a geometry
-- certificate. Its optional restrictions can only narrow that declaration.
function Retail.CaptureMovement(value)
    if type(value)~='table' or not MODES[value.mode] or not Number(value.distance) then
        return nil,'invalid_movement'
    end
    for key,v in pairs(value)do
        if not FIELDS[key] then return nil,'invalid_movement' end
        if (key=='rise' or key=='fall') and not Number(v) then return nil,'invalid_movement' end
        if (key=='groundOnly' or key=='requiresExit') and type(v)~='boolean' then return nil,'invalid_movement' end
        if (key=='canMount' or key=='canFly') and not ACCESS[v] then return nil,'invalid_movement' end
    end
    return {mode=value.mode,distance=value.distance,rise=value.rise or 0,fall=value.fall or 0,
        canMount=value.canMount or 'unknown',canFly=value.canFly or 'available',
        groundOnly=value.groundOnly==true,requiresExit=value.requiresExit==true}
end

local function Mounted(mode)
    return mode=='mount' or mode=='skyriding'
end

local function Transition(costs,from,to)
    if from==to then return 0 end
    local keys={}
    if from=='skyriding' and to~='skyriding' then keys[#keys+1]='landingSeconds' end
    if Mounted(from) and not Mounted(to) then keys[#keys+1]='dismountSeconds' end
    if not Mounted(from) and Mounted(to) then keys[#keys+1]='mountSeconds' end
    if from=='swim' then keys[#keys+1]='exitSwimSeconds' end
    if to=='swim' then keys[#keys+1]='enterSwimSeconds' end
    local total=0
    for _,key in ipairs(keys)do
        if costs[key]==false then return end
        total=total+costs[key]
    end
    return total
end

local function Travel(costs,edge,mode)
    local movement=edge.movement
    if not movement then return edge.seconds end
    local speed=costs[mode..'Speed']
    if not speed then return end
    local seconds=movement.distance/speed
    if mode=='skyriding' then
        for field,key in pairs({rise='climbSpeed',fall='descentSpeed'})do
            local distance=movement[field] or 0
            if distance>0 then
                if not costs[key] then return end
                seconds=seconds+distance/costs[key]
            end
        end
    end
    return seconds
end

local function LegAccess(profile,edge,current,mode,atStart)
    local access=edge.access or 'available'
    local movement=edge.movement or {}
    if movement.requiresExit then return 'unavailable' end
    if mode=='skyriding' then
        if movement.groundOnly then return 'unavailable' end
        access=Access(access,profile.skyridingAccess)
        access=Access(access,movement.canFly or 'available')
        if atStart then access=Access(access,profile.originFlightAccess) end
    elseif mode=='mount' then access=Access(access,profile.mountAccess) end
    if Mounted(mode) and not Mounted(current) then
        access=Access(access,movement.canMount or 'unknown')
        if atStart then access=Access(access,profile.originMountAccess) end
    end
    return access
end

function Profile:Evaluate(edge,currentMode,atStart)
    if not MODES[currentMode] then return nil,'movement_state_unknown' end
    local mode=edge.movement and edge.movement.mode or 'walk'
    if not MODES[mode] then return nil,'movement_state_unknown' end
    local access=LegAccess(self,edge,currentMode,mode,atStart)
    local transition=Transition(self.costs,currentMode,mode)
    local travel=Travel(self.costs,edge,mode)
    if travel==nil or transition==nil then access=Access(access,'unknown') end
    local seconds=(travel or 0)+(transition or 0)
    if not Number(seconds) then return nil,'cost_overflow' end
    return {mode=mode,seconds=seconds,access=access,transitionSeconds=transition}
end

ns.NavigationV2Retail=Retail
return Retail
