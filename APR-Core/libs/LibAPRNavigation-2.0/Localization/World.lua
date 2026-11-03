-- Pure observation ownership. World localization does not require a UI map.
local _, ns = ...
local World, Tracker = {}, {}
Tracker.__index = Tracker
local FIELDS = {'sequence','worldState','world','x','y','z','uiMapID','space','floor','phase'}

local function Finite(value)
    return type(value)=='number' and value==value and value>-math.huge and value<math.huge
end

local function Integer(value, minimum)
    return Finite(value) and value>=minimum and value<=9007199254740991 and value%1==0
end

local function Identity(value)
    return (type(value)=='string' and value~='') or Integer(value,0)
end

local function Copy(value)
    local result={}
    for key,item in pairs(value) do result[key]=item end
    return result
end

local function Capture(source)
    if type(source)~='table' or not Integer(source.sequence,1)
        or (source.worldState~='ready' and source.worldState~='loading' and source.worldState~='unknown') then return end
    for _,key in ipairs({'world','uiMapID'}) do
        if source[key]~=nil and not Integer(source[key],key=='world' and 0 or 1) then return end
    end
    for _,key in ipairs({'x','y','z'}) do
        if source[key]~=nil and not Finite(source[key]) then return end
    end
    for _,key in ipairs({'space','floor','phase'}) do
        if source[key]~=nil and not Identity(source[key]) then return end
    end
    local result={}
    for _,key in ipairs(FIELDS) do result[key]=source[key] end
    return result
end

local function Quality(snapshot)
    if snapshot.worldState=='loading' then return 'loading' end
    if snapshot.worldState~='ready' then return 'world_unknown' end
    if snapshot.world==nil or snapshot.x==nil or snapshot.y==nil then return 'position_missing' end
    return 'world_position'
end

local function SameContext(a,b)
    if a.quality~=b.quality or a.worldState~=b.worldState then return false end
    if b.quality~='world_position' then return true end
    for _,key in ipairs({'world','space','floor','phase'}) do
        if a[key]~=b[key] then return false end
    end
    return (a.z==nil)==(b.z==nil)
end

function World.New()
    local self=setmetatable({revision=0,planRevision=0,identity={}},Tracker)
    self.snapshot={sequence=0,worldState='unknown',quality='world_unknown',mapReason='map_missing',
        revision=0,planRevision=0,owner=self.identity}
    return self
end

-- Existing compact terrain positions use Recast Y-up [world-Y,height,world-X].
-- Adapt one explicitly loaded node, without searching geometry or asserting
-- that the player belongs to it. Identity comes from its trusted data scope.
function World.FromTerrain(position,world,identity)
    if type(position)~='table' or not Integer(world,0)
        or not Finite(position[1]) or not Finite(position[2]) or not Finite(position[3]) then
        return nil,'position_missing'
    end
    if identity~=nil and type(identity)~='table' then return nil,'invalid_location_identity' end
    local result={world=world,x=position[3],y=position[1],z=position[2]}
    for _,key in ipairs({'space','floor','phase'}) do
        local value=identity and identity[key]
        if value~=nil and not Identity(value) then return nil,'invalid_location_identity' end
        result[key]=value
    end
    return result
end

function Tracker:Observe(observation)
    local snapshot=Capture(observation)
    if not snapshot then return nil,'invalid_position_observation' end
    if snapshot.sequence<=self.snapshot.sequence then return false,'stale_observation' end
    self.revision=self.revision+1
    snapshot.revision,snapshot.owner=self.revision,self.identity
    snapshot.quality=Quality(snapshot)
    if not snapshot.uiMapID then snapshot.mapReason='map_missing' end
    local changed=not SameContext(self.snapshot,snapshot)
    if changed then self.planRevision=self.planRevision+1 end
    snapshot.planRevision=self.planRevision
    self.snapshot=snapshot
    return changed,self:GetSnapshot()
end

function Tracker:GetSnapshot()
    return Copy(self.snapshot)
end

function Tracker:IsCurrent(snapshot)
    return type(snapshot)=='table' and snapshot.owner==self.identity and snapshot.revision==self.revision
end

-- Exact observations advance independently of planning. XY/Z motion and a
-- newly displayable map refresh guidance/progression, not graph-wide search.
function Tracker:IsPlanCurrent(snapshot)
    return type(snapshot)=='table' and snapshot.owner==self.identity and snapshot.planRevision==self.planRevision
end

-- This compares proven identities. Z, a nearby centroid or map projection
-- cannot establish floor membership, connectivity, phase compatibility or arrival.
function World.Match(snapshot, expected)
    if type(expected)~='table' then return nil,'invalid_location_identity' end
    if expected.world~=nil and not Integer(expected.world,0) then return nil,'invalid_location_identity' end
    for _,key in ipairs({'space','floor','phase'}) do
        if expected[key]~=nil and not Identity(expected[key]) then return nil,'invalid_location_identity' end
    end
    if type(snapshot)~='table' then return nil,'world_unknown' end
    local quality=Quality(snapshot)
    if quality~='world_position' then return nil,quality end
    for _,key in ipairs({'world','space','floor','phase'}) do
        if expected[key]~=nil then
            if snapshot[key]==nil then return nil,key=='floor' and 'floor_ambiguous' or key..'_unknown' end
            if expected[key]~=snapshot[key] then return false,key..'_mismatch' end
        end
    end
    return true
end

ns.NavigationV2World=World
return World
